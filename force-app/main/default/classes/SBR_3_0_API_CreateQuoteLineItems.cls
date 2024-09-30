/*********************************************************************************************************************
* Apex Class: SBR_3_0_API_CreateQuoteLineItems
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Send Quoted line items to Rentalman (via Mulesoft) when it is created in Salesforce
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
1.0             Arsh Chhabra         2023-12-04             Initial version
2.0             Harry Rokad          2023-07-02             Tranformed from future to Queuable
*********************************************************************************************************************/
public with sharing class SBR_3_0_API_CreateQuoteLineItems {

    private static final String APINAME = 'Send_WorkOrder_Quote_Line_Item_API';
    private static final String X_CORRELATION_ID = SBR_3_0_Generic.generateRandomString(10);
    private static SyncWorkOrderLineItemsWrapper requestBody = new SyncWorkOrderLineItemsWrapper();
    private static SyncWorkOrderQuoteLineItemsMileageWrapper requestMileageBody = new SyncWorkOrderQuoteLineItemsMileageWrapper();
    private static SyncWorkOrderQuoteLineItemsOutsideLaborWrapper requestOutsideLaborBody = new SyncWorkOrderQuoteLineItemsOutsideLaborWrapper();

    @InvocableMethod(Label = 'CreateQuoteLineItemsRMCallout')
    public static void WorkOrderRMCallout(List<String> input) {
        if (!input.isEmpty()) {
            // Enqueue the Queueable job
            System.enqueueJob(new QuoteLineItemCalloutJob(input));
        }
    }

    public class QuoteLineItemCalloutJob implements Queueable, Database.AllowsCallouts {
        private List<String> qliIds;

        public QuoteLineItemCalloutJob(List<String> inputIds) {
            this.qliIds = inputIds;
        }

        public void execute(QueueableContext context) {
            String qliId = qliIds.remove(0);
            Set<String> qliIdSet = new Set<String>{qliId};
            List<Quote_Line_Item__c> getQliList = SBR_3_0_WorkOrderDA.getQuoteLineItems(qliIdSet);

            if (!getQliList.isEmpty()) {
                Quote_Line_Item__c getQli = getQliList[0];
                if (String.isBlank(getQli.SF_PS_RM_External_Id__c)){
                    handleQuoteLineItem(getQli);
                }
            }

            // If there are remaining QuoteLineItems, re-enqueue the job
            if (!qliIds.isEmpty()) {
                System.enqueueJob(new QuoteLineItemCalloutJob(qliIds));
            }
        }

        private void handleQuoteLineItem(Quote_Line_Item__c getQli) {
            try {
                String rentalManUserName = [SELECT Wynne_User_Name__c FROM User WHERE Id = :getQli.WorkOrderId__r.OwnerId].Wynne_User_Name__c;
                SBR_3_0_HttpCallout httpCallout = new SBR_3_0_HttpCallout(APINAME);
                HttpRequest req = httpCallout.getRequest();
                WrappedResponse response = new WrappedResponse();

                String payload;
                if (getQli != null && getQli.SF_PS_Line_Type__c == 'MC') {
                    generateMileageWrapper(getQli);
                    payload = generateMileageJSONPayload();
                } else if (getQli.SF_PS_Line_Type__c == 'LO') { // Outside Labor
                    generateOutsideLaborWrapper(getQli);
                    payload = generateOutsideLaborJSONPayload();
                } else if (getQli != null) {
                    generateWrapper(getQli);
                    payload = generateJSONPayload();
                }

                String woNumber = getQli.SF_PS_RM_WO_Number__c.subStringAfter('-');
                if (getQli.SF_PS_Line_Type__c == 'MC') {
                    req.setEndpoint(req.getEndpoint() + woNumber + '/mileageCharges');
                } else if (getQli.SF_PS_Line_Type__c == 'LO') {
                    req.setEndpoint(req.getEndpoint() + woNumber + '/outsideLabor');
                } else {
                    req.setEndpoint(req.getEndpoint() + woNumber + '/insideLabor');
                }

                req.setHeader('thresholdWaitTime', '1');
                req.setHeader('X-Correlation-ID', X_CORRELATION_ID);
                req.setHeader('Content-Type', 'application/json');
                req.setHeader('requestTimestamp', String.valueOf(getQli.LastModifiedDate.format('yyyy-MM-dd\'T\'HH:mm:ss.SSSSSS\'Z\'')));
                req.setHeader('sourceSystemUserId', getQli.WorkOrderId__r.Owner.alias);
                req.setHeader('sourceSystemName', 'SalesForce');
                req.setHeader('rentalmanUserId', rentalManUserName);
                req.setHeader('requestTimeZone', getQli.WorkOrderId__r.ServiceTerritory.OperatingHours.TimeZone);
                req.setHeader('sourceWorkOrderNumber', getQli.WorkOrderId__r.WorkOrderNumber);
                req.setHeader('pc', getQli.WorkOrderId__r.SF_PS_Current_Loc__c);
                req.setHeader('companyId', getQli.WorkOrderId__r.SF_PS_Company_Code__c);
                req.setTimeout(119000);
                req.setBody(payload);
                system.debug('payload+ ' + payload);
                Http http = new Http();
                HTTPResponse res = http.send(req);

                response.headers = res.getHeaderKeys();
                response.body = res.getBody();
                String returnPayload = res.getBody();
                system.debug('Response ' +returnPayload);
                //if (!Test.isRunningTest()) {
                    response = (WrappedResponse) JSON.deserialize(returnPayload, WrappedResponse.class);
                    if (res.getStatusCode() == 200 || res.getStatus() == 'OK') {
                        WorkOrderQuoteLineItem ExternalResp = response.workOrderQuoteLineItems[0];
                        getQli.SF_PS_RM_Labor_Line_Item_Number__c = ExternalResp.workOrderQuoteLineItemNumber;
                        getQli.SF_PS_RM_External_Id__c = ExternalResp.uniqueId;
                        update getQli;
                    } else {
                        Exception_Log__c exc = new Exception_Log__c();
                        exc.Exception_Message__c = res.getStatusCode() + ' ' +' Request - ' + payload + ' ' +' Response '+response.body;
                        exc.StatusCode__c = String.valueOf( res.getStatusCode()) ;
                        exc.Exception_Type__c = 'SF to RM Outbound Response';
                        exc.Method_Name__c= 'createqli';
                        exc.RequestJSON__c= payload;
                        exc.ResponseJSON__c = response.body;
                        exc.RecordID__c = getQli.id;
                        exc.Related_To_Number__c=getQli.WorkOrderId__c;
                        exc.Class_Name__c= 'SBR_3_0_API_CreateQuoteLineItems';
                        exc.Stack_Trace__c = 'SBR_3_0_API_CreateQuoteLineItems , createqli - line 30 , http.send(req) - Line 74 ';
                        insert exc;
                        system.debug ('Error Response code-> ' + res.getStatusCode() + ' Error Response message-> ' + response.body); // Do not remove this Debug log
                    }
                //}

                if (res.getStatusCode() == 200 || res.getStatus() == 'OK') {
                    response.status = 'Complete';
                }
            } catch (Exception error) {
                System.debug('Error Line -> ' + error.getStackTraceString());
                System.debug('Error Message -> ' + error.getMessage());
            }
        }

        private String generateJSONPayload() {
            return JSON.serialize(requestBody).replace('null', '""');
        }

        private void generateWrapper(Quote_Line_Item__c qli) {
            WorkOrderQuoteLineItemsWrapper woqliWrapper = new WorkOrderQuoteLineItemsWrapper();
            woqliDetailsClass woqliDetails = new woqliDetailsClass();
            woqliDetails.sourceReferenceLineNumber = qli.id;
            //woqliDetails.mechanicId = qli.WorkOrderId__r?.SF_PS_Service_Resource__r?.SF_PS_Mechanic_Id__c;
            woqliDetails.mechanicId = qli.SF_PS_Mechanic_Id__c;
            woqliDetails.laborCode = qli.SF_PS_Labor_Code__c == null ? 0 : Integer.valueOf(qli.SF_PS_Labor_Code__c);
            woqliDetails.insideLaborRate = qli.SF_PS_Hourly_Internal_Rate__c == null ? 0 : Integer.valueOf(qli.SF_PS_Hourly_Internal_Rate__c);
            woqliDetails.insideLaborHours = qli.SF_PS_Duration__c == null ? 0.0 : qli.SF_PS_Duration__c;
            woqliWrapper.insideLabor.add(woqliDetails);
            requestBody.workOrderQuote.add(woqliWrapper);
        }

        private String generateMileageJSONPayload() {
            return JSON.serialize(requestMileageBody).replace('null', '""');
        }

        private void generateMileageWrapper(Quote_Line_Item__c qli) {
            WorkOrderQuoteLineItemsMileageWrapper qliMileageWrapper = new WorkOrderQuoteLineItemsMileageWrapper();
            QliMilegeDetailsClass qliMileageDetails = new QliMilegeDetailsClass();
            qliMileageDetails.sourceReferenceLineNumber = qli.Id;
            qliMileageDetails.mileageMiles = qli.SF_PS_Duration__c == null ? 0.0 : qli.SF_PS_Duration__c;
            qliMileageDetails.mileageRate = qli.SF_PS_Hourly_Internal_Rate__c == null ? 0.0 : qli.SF_PS_Hourly_Internal_Rate__c;
            qliMileageWrapper.mileage = qliMileageDetails;
            requestMileageBody.workOrderQuote.add(qliMileageWrapper);
        }

        private String generateOutsideLaborJSONPayload() {
            return JSON.serialize(requestOutsideLaborBody).replace('null', '""');
        }

        private void generateOutsideLaborWrapper(Quote_Line_Item__c qli) {
            WorkOrderQuoteLineItemsOutsideLaborWrapper qliOutsideLaborWrapper = new WorkOrderQuoteLineItemsOutsideLaborWrapper();
            QliOutsidelaborDetailsClass qliOutsideLaborDetails = new QliOutsidelaborDetailsClass();
            qliOutsideLaborDetails.sourceReferenceLineNumber = qli.id;
            qliOutsideLaborDetails.laborCode = qli.SF_PS_Labor_Code__c == null ? 0 : Integer.valueOf(qli.SF_PS_Labor_Code__c);
            qliOutsideLaborDetails.outsideLaborPoNumber = qli.SF_PS_Vendor_PO_Num__c == null ? '' : (String) qli.SF_PS_Vendor_PO_Num__c;
            qliOutsideLaborDetails.outsideLaborPrice = qli.SF_PS_PO_Amount__c == null ? 0.0 : qli.SF_PS_PO_Amount__c;
            qliOutsideLaborDetails.outsideLaborCost = qli.SF_PS_PO_Cost__c == null ? 0.0 : qli.SF_PS_PO_Cost__c; //should not be 0
            qliOutsideLaborDetails.outsideLaborDescription = qli.SF_PS_Outside_Labor_Des__c;
            qliOutsideLaborWrapper.outsideLabor.add(qliOutsideLaborDetails);
            requestOutsideLaborBody.workOrderQuote.add(qliOutsideLaborWrapper);
        }
    }

    public class SyncWorkOrderLineItemsWrapper {
        public List<WorkOrderQuoteLineItemsWrapper> workOrderQuote = new List<WorkOrderQuoteLineItemsWrapper>();
    }

    public class WorkOrderQuoteLineItemsWrapper {
        public List<woqliDetailsClass> insideLabor = new List<woqliDetailsClass>();
    }

    public class woqliDetailsClass {
        public String sourceReferenceLineNumber; //workorderLineItem.Id
        public String mechanicId;
        public Integer laborCode; //SF_PS_Labor_Code__c
        public Integer insideLaborRate; //SF_PS_Hourly_Internal_Rate__c
        public Double insideLaborHours; //Duration
    }

    public class SyncWorkOrderQuoteLineItemsMileageWrapper {
        public List<WorkOrderQuoteLineItemsMileageWrapper> workOrderQuote = new List<WorkOrderQuoteLineItemsMileageWrapper>();
    }

    public class WorkOrderQuoteLineItemsMileageWrapper {
        public QliMilegeDetailsClass mileage = new QliMilegeDetailsClass();
    }

    public class QliMilegeDetailsClass {
        public String sourceReferenceLineNumber; //workorderLineItem.Id
        public Decimal mileageMiles; //Duration
        public Decimal mileageRate; //SF_PS_Hourly_Internal_Rate__c
    }

    public class SyncWorkOrderQuoteLineItemsOutsideLaborWrapper {
        public List<WorkOrderQuoteLineItemsOutsideLaborWrapper> workOrderQuote = new List<WorkOrderQuoteLineItemsOutsideLaborWrapper>();
    }

    public class WorkOrderQuoteLineItemsOutsideLaborWrapper {
        public List<QliOutsidelaborDetailsClass> outsideLabor = new List<QliOutsidelaborDetailsClass>();
    }

    public class QliOutsidelaborDetailsClass {
        public String sourceReferenceLineNumber;
        public Integer laborCode;
        public String outsideLaborPoNumber;
        public Double outsideLaborPrice;
        public Double outsideLaborCost;
        public String outsideLaborDescription;
    }

    public class WrappedResponse {
        public String workOrderNumber;
        public String mode;
        public String message;
        public String body;
        public String status;
        public List<String> headers;
        public List<WorkOrderQuoteLineItem> workOrderQuoteLineItems;
    }

    public class WorkOrderQuoteLineItem {
        public String workOrderQuoteLineItemNumber;
        public String uniqueId;
        public String referenceLineNumber;
    }
}