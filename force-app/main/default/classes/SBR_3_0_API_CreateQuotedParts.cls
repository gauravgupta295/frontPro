/*********************************************************************************************************************
* Apex Class: SBR_3_0_API_CreateQuotedParts
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Send Quoted Parts to Rentalman (via Mulesoft) when it is created in Salesforce
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
1.0             Arsh Chhabra         2023-12-04             Initial version
*********************************************************************************************************************/
public class SBR_3_0_API_CreateQuotedParts {

    private static final String APINAME = 'Send_Quoted_Parts_API';
    private static final String X_CORRELATION_ID = SBR_3_0_Generic.generateRandomString(10);
    private static SyncQuotedPartsWrapper requestBody = new SyncQuotedPartsWrapper();

    @InvocableMethod(Label = 'CreateQuotedPartsRMCallout')
    public static void QuotedPartsCreateRMCallout(List<String> input) {
        if (!input.isEmpty()) {
            System.enqueueJob(new QuotedPartsCalloutJob(input));
        }
    }

    public class QuotedPartsCalloutJob implements Queueable, Database.AllowsCallouts {
        private List<String> qpIds;

        public QuotedPartsCalloutJob(List<String> inputIds) {
            this.qpIds = inputIds;
        }

        public void execute(QueueableContext context) {
            String qpId = qpIds.remove(0);
            Set<String> qpIdSet = new Set<String>{qpId};
            List<SF_PS_Quoted_Part__c> getQpList = SBR_3_0_WorkOrderDA.getQuotedParts(qpIdSet);

            if (!getQpList.isEmpty()) {
                SF_PS_Quoted_Part__c getQp = getQpList[0];
                if (String.isBlank(getQp.SF_PS_RM_External_Id__c)){
                    handleQuotedPart(getQp);
                }
            }

            // If there are remaining QuotedParts, re-enqueue the job
            if (!qpIds.isEmpty()) {
                System.enqueueJob(new QuotedPartsCalloutJob(qpIds));
            }
        }

        private void handleQuotedPart(SF_PS_Quoted_Part__c getQp) {
            try {
                String rentalManUserName = [SELECT Wynne_User_Name__c FROM User WHERE Id = :getQp.SF_PS_WorkOrderId__r.OwnerId].Wynne_User_Name__c;
                SBR_3_0_HttpCallout httpCallout = new SBR_3_0_HttpCallout(APINAME);
                HttpRequest req = httpCallout.getRequest();
                WrappedResponse response = new WrappedResponse();

                generateWrapper(getQp);
                String payload = generateJSONPayload();

                String rmWoNumber = getQp.SF_PS_WorkOrderId__r.SF_PS_RM_WO_Number__c?.subStringAfter('-');
                req.setMethod('POST');
                req.setEndpoint(req.getEndpoint() + rmWoNumber + '/parts');
                req.setHeader('thresholdWaitTime', '1');
                req.setHeader('X-Correlation-ID', X_CORRELATION_ID);
                req.setHeader('Content-Type', 'application/json');
                req.setHeader('requestTimestamp', String.valueOf(getQp.LastModifiedDate.format('yyyy-MM-dd\'T\'HH:mm:ss.SSSSSS\'Z\'')));
                req.setHeader('sourceSystemUserId', getQp.SF_PS_WorkOrderId__r.Owner.alias);
                req.setHeader('sourceSystemName', 'SalesForce');
                req.setHeader('rentalmanUserId', rentalManUserName);
                req.setHeader('sourceWorkOrderNumber', getQp.SF_PS_WorkOrderId__r.WorkOrderNumber);
                req.setHeader('requestTimeZone', getQp.SF_PS_WorkOrderId__r.ServiceTerritory.OperatingHours.TimeZone);
                req.setHeader('pc', getQp.SF_PS_WorkOrderId__r.ServiceTerritory.Branch_Location_Number__c);
                req.setHeader('companyId', getQp.SF_PS_WorkOrderId__r.SF_PS_Company_Code__c);
                req.setBody(payload);
                system.debug('payload+ ' + payload);
                req.setTimeout(119000);

                Http http = new Http();
                HTTPResponse res = http.send(req);

                response.headers = res.getHeaderKeys();
                response.body = res.getBody();
                String returnPayload = res.getBody();
                system.debug('response ' + returnPayload);
                response = (WrappedResponse) JSON.deserialize(returnPayload, WrappedResponse.class);
                if (res.getStatusCode() == 200 || res.getStatus() == 'OK') {
                    WorkOrderQuoteLineItem externalResp = response.workOrderQuoteLineItems[0];
                    getQp.SF_PS_Quoted_Parts_Line_Num__c = externalResp.workOrderQuoteLineItemNumber;
                    getQp.SF_PS_RM_External_Id__c = externalResp.uniqueId;
                    update getQp;
                } else {
                    Exception_Log__c exc = new Exception_Log__c();
                    exc.Exception_Message__c = res.getStatusCode() + ' ' +' Request - ' + payload + ' ' +' Response - '+res.getBody();
                    exc.StatusCode__c = String.valueOf( res.getStatusCode()) ;
                    exc.Exception_Type__c = 'SF to RM Outbound Response';
                    exc.Method_Name__c= 'createQp';
                    exc.RequestJSON__c= payload;
                    exc.ResponseJSON__c = res.getBody();
                    exc.RecordID__c = getQp.id;
                    exc.Related_To_Number__c=getQp.SF_PS_WorkOrderId__c;
                    exc.Class_Name__c= 'SBR_3_0_API_CreateQuotedParts';
                    exc.Stack_Trace__c = 'SBR_3_0_API_CreateQuotedParts , createQp - line 21 , http.send(req) - Line 59 ';
                    insert exc;
                    requestBody.workOrderQuote.clear();
                    System.debug ('Error Response code-> ' + res.getStatusCode() + ' Error Response message-> ' + res.getBody());
                }

                if (res.getStatusCode() == 200 || res.getStatus() == 'OK') {
                    response.status = 'Complete';
                }
            } catch (Exception error) {
                System.debug('Error Line -> ' + error.getStackTraceString());
                System.debug('Error Message -> ' + error.getMessage());
            }
        }

        private void generateWrapper(SF_PS_Quoted_Part__c qp) {
            PartsWrapper pcWrapper = new PartsWrapper();
            QuotedPartsDetailsWrapper qpDetails = new QuotedPartsDetailsWrapper();
            qpDetails.sourceReferenceLineNumber = qp.Id;
            qpDetails.itemNumber = qp.SF_PS_Product2Id__r.Item_Number__c;
            qpDetails.stockClass = qp.SF_PS_Stock_Class__c;
            qpDetails.quantity = qp.SF_PS_Quantity__c == null ? 0.0 : Double.valueOf(qp.SF_PS_Quantity__c);
            qpDetails.unitOfMeasure = qp.SF_PS_Product2Id__r.QuantityUnitOfMeasure;
            //qpDetails.sellingPrice = qp.SF_PS_Selling_Price__c == null ? 0.0 : (qp.SF_PS_Selling_Price__c).setScale(2);
            qpDetails.laborCode = qp.SF_PS_Labor_Code__c == null ? 0 : Integer.valueOf(qp.SF_PS_Labor_Code__c);
            qpDetails.cost = qp.SF_PS_Cost_Price__c == null ? 0.0 : (qp.SF_PS_Cost_Price__c).setScale(2);
            qpDetails.comments = qp.SF_PS_Line_Level_Comment__c;
            qpDetails.discountPercent = qp.SF_PS_Discount_Percentage__c != null ? Integer.valueOf(qp.SF_PS_Discount_Percentage__c) : 0;
            if ( Integer.valueOf(qp.SF_PS_Discount_Percentage__c) <= 0){
                qpDetails.sellingPrice = (qp.SF_PS_Selling_Price__c).setScale(2);
            }
            else{
                qpDetails.sellingPrice = (qp.SF_PS_Orig_Selling_Price__c).setScale(2);
            }
            pcWrapper.parts.add(qpDetails);
            requestBody.workOrderQuote.add(pcWrapper);
        }

        private String generateJSONPayload() {
            return JSON.serialize(requestBody).replace('null', '""');
        }
    }

    public class SyncQuotedPartsWrapper {
        public List<PartsWrapper> workOrderQuote = new List<PartsWrapper>();
    }

    public class PartsWrapper {
        public List<QuotedPartsDetailsWrapper> parts = new List<QuotedPartsDetailsWrapper>();
    }

    public class QuotedPartsDetailsWrapper {
        public String sourceReferenceLineNumber; //productconsumed.Id
        public String itemNumber; //Product2.Item_Number__c
        public String stockClass; //SF_PS_Stock_Class__c
        public Decimal quantity; //SF_PS_Quantity__c
        public String unitOfMeasure; //SF_PS_Unit_Of_Measure__c
        public Decimal sellingPrice; //SF_PS_Selling_Price__c
        public Integer laborCode; //SF_PS_Labor_Code__c
        public Decimal cost; //SF_PS_Cost_Price__c
        public String comments; //SF_PS_Line_Level_Comment__c
        public Decimal discountPercent; // SF_PS_Discount_Percentage__c
    }

    public class WrappedResponse {
        public String workOrderQuoteNumber;
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