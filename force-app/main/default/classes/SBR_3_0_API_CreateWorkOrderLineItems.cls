/*********************************************************************************************************************
* Apex Class: SBR_3_0_API_CreateWorkOrderLineItems
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Send WorkOrderLineItem (Labor) to Rentalman (via Mulesoft) when it is created in Salesforce
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION       DATE               DETAIL FEATURES
1.0          	----------        	Initial version 
2.0          	----------          Update In Functionality 
3.0				11-Jan-2024			Mayank Jain - Bulkified Code 
**********************************************************************************************************************************************/
public with sharing class SBR_3_0_API_CreateWorkOrderLineItems {

    private static final String APINAME = 'Send_WorkOrder_Line_Item_API';
    private static final String X_CORRELATION_ID = SBR_3_0_Generic.generateRandomString(10);
    private static String payload;
	private static String relatedToId;
    private static Workorderlineitem getWoli;
    private static SyncWorkOrderLineItemsWrapper requestBody = new SyncWorkOrderLineItemsWrapper();
    private static SyncWorkOrderLineTravelItemsWrapper requestTravelBody = new SyncWorkOrderLineTravelItemsWrapper();

    @InvocableMethod(Label = 'CreateWorkOrderLineItemsRMCallout')
    public static void WorkOrderRMCallout(List<String> input) {
        if (!input.isEmpty()) {
            // Enqueue the Queueable job
            System.enqueueJob(new WorkOrderLineItemCalloutJob(input));
        }
    }
    
    public class WorkOrderLineItemCalloutJob implements Queueable, Database.AllowsCallouts {
        private List<String> woliIds;
        

        public WorkOrderLineItemCalloutJob(List<String> inputIds) {
            this.woliIds = inputIds;
        }

        public void execute(QueueableContext context) {
            //Set<String> woliIdSet = new Set<String>(woliIds);
            
            String woliId = woliIds.remove(0);
            Set<String> woliIdSet = new Set<String>{woliId};
            List<WorkOrderLineItem> getWoliList = SBR_3_0_WorkOrderDA.getWorkOrderLineItems(woliIdSet);
            if (!getWoliList.isEmpty()){
                getWoli = getWoliList[0];
            }
            //List<WorkOrderLineItem> getWoliList = SBR_3_0_WorkOrderDA.getWorkOrderLineItems(woliIdSet);
            list<WorkOrderLineItem> resposelist = new list<WorkOrderLineItem>(); 

                try {
                    if (getWoli != null && String.isBlank(getWoli.SF_PS_RM_External_Id__c)) {
                        // Proceed with the callout
                        sendCallout(getWoli);
                    }
                } catch (Exception e) {
                    // Log the exception
                    SBR_3_0_LogException.LogIt(e, getWoli.WorkOrderId);
                }
                // If there are remaining WOLIs, re-enqueue the job
                if (!woliIds.isEmpty()) {
                    System.enqueueJob(new WorkOrderLineItemCalloutJob(woliIds));
                }
        }

        private void sendCallout(WorkOrderLineItem getWoli) {
            // Set up the callout as in your original method
            String rentalManUserName = [SELECT Wynne_User_Name__c FROM User WHERE Id = :getWoli.WorkOrder.OwnerId].Wynne_User_Name__c;
            SBR_3_0_HttpCallout httpCallout = new SBR_3_0_HttpCallout(APINAME);
            HttpRequest req = httpCallout.getRequest();
            WrappedResponse response = new WrappedResponse();
            
            String payload;
            if (getWoli.SF_PS_Line_Type__c == 'MC') {
                generateTravelWrapper(getWoli);
                payload = generateTravelJSONPayload();
                req.setEndpoint(req.getEndpoint() + getWoli.SF_PS_RM_WO_Number__c.subStringAfter('-') + '/mileageCharges');
            } else {
                generateWrapper(getWoli);
                payload = generateJSONPayload();
                req.setEndpoint(req.getEndpoint() + getWoli.SF_PS_RM_WO_Number__c.subStringAfter('-') + '/insideLabor');
            }

            // Set headers and body
            req.setHeader('thresholdWaitTime', '1');
            req.setHeader('X-Correlation-ID', X_CORRELATION_ID);       
            req.setHeader('Content-Type', 'application/json');       
            req.setHeader('requestTimestamp', String.valueOf(getWoli.LastModifiedDate.format('yyyy-MM-dd\'T\'HH:mm:ss.SSSSSS\'Z\'')));        
            req.setHeader('sourceSystemUserId', getWoli.WorkOrder.Owner.alias);               
            req.setHeader('sourceSystemName', 'SalesForce');
            req.setHeader('rentalmanUserId', rentalManUserName);              
            req.setHeader('requestTimeZone', getWoli.WorkOrder.ServiceTerritory.OperatingHours.TimeZone);      
            req.setHeader('sourceWorkOrderNumber',getWoli.WorkOrder.WorkOrderNumber );        
            req.setHeader('pc', getWoli.workOrder.SF_PS_Current_Loc__c);
            req.setHeader('companyId', getWoli.WorkOrder.SF_PS_Company_Code__c);
            req.setTimeout(119000);    
            req.setBody(payload);
            system.debug('payload '+ payload);
            Http http = new Http();
            HTTPResponse res = http.send(req);

            // Process response
            if (res.getStatusCode() == 200 || res.getStatus() == 'OK') {
                response = (WrappedResponse) JSON.deserialize(res.getBody(), WrappedResponse.class);
                WorkOrderLineItems externalResp = response.workOrderLineItems[0];
                getWoli.SF_PS_RM_Labor_Line_Item_Number__c = externalResp.workOrderLineItemNumber;
                getWoli.SF_PS_RM_External_Id__c = externalResp.uniqueId;
                update getWoli;
            } else {
                // Handle non-success responses
                Exception_Log__c exc = new Exception_Log__c();
                exc.Exception_Message__c = res.getStatusCode() + ' ' + 'Request -' + payload + ' ' + 'Response ' + res.getBody();
                exc.Exception_Type__c = 'SF to RM Outbound Response';
                exc.Method_Name__c = 'sendCallout';
                exc.RecordID__c = getWoli.id;
                exc.Related_To_Number__c=getWoli.WorkOrderId;
                exc.RequestJSON__c= payload;
                exc.ResponseJSON__c = response.body;
                exc.Class_Name__c = 'SBR_3_0_API_CreateWorkOrderLineItems';
                insert exc;
            }
        }
        
        private void generateWrapper(WorkOrderLineItem woli) {
            WorkOrderLineItemsWrapper woliWrapper = new WorkOrderLineItemsWrapper();
            woliDetailsClass woliDetails = new woliDetailsClass();
            woliDetails.sourceReferenceLineNumber = woli.id;
            woliDetails.mechanicId = woli.SF_PS_Mechanic_Id__c;
            woliDetails.laborCode = woli.SF_PS_Labor_Code__c != null ? Integer.valueOf(woli.SF_PS_Labor_Code__c) : 0;
            woliDetails.insideLaborRate = woli.SF_PS_Hourly_Internal_Rate__c != null ? Integer.valueOf(woli.SF_PS_Hourly_Internal_Rate__c) : 0;
            woliDetails.insideLaborHours = woli.Duration;
            woliWrapper.insideLabor.add(woliDetails);
            requestBody.workOrder.add(woliWrapper);
        }

        private String generateJSONPayload() {
            return JSON.serialize(requestBody).replace('null', '""');
        }

        private void generateTravelWrapper(WorkOrderLineItem woli) {
            WorkOrderLineItemsTravelWrapper woliTravelWrapper = new WorkOrderLineItemsTravelWrapper();
            woliTravelDetailsClass woliTravelDetails = new woliTravelDetailsClass();
            woliTravelDetails.sourceReferenceLineNumber = woli.Id;
            woliTravelDetails.mileageMiles = woli.Duration;
            woliTravelDetails.mileageRate = woli.SF_PS_Hourly_Internal_Rate__c;      
            woliTravelWrapper.mileage = woliTravelDetails;
            requestTravelBody.workOrder.add(woliTravelWrapper);
        }

        private String generateTravelJSONPayload() {
            return JSON.serialize(requestTravelBody).replace('null', '""');
        }
    }
    
    public class WorkOrderLineItemsWrapper {
        public List<woliDetailsClass> insideLabor = new List<woliDetailsClass>();
    }
    
    public class woliDetailsClass {
        public String sourceReferenceLineNumber;
        public String mechanicId;
        public Integer laborCode;
        public Integer insideLaborRate;
        public Decimal insideLaborHours;
    }

    public class WorkOrderLineItemsTravelWrapper {
        public woliTravelDetailsClass mileage = new woliTravelDetailsClass();
    }
    
    public class woliTravelDetailsClass {
        public String sourceReferenceLineNumber;
        public Decimal mileageMiles;
        public Decimal mileageRate;
    }
    
    public class WrappedResponse {
        public String workOrderNumber {get; set;}
        public String mode {get; set;} 
        public String message;
        public String body {get; set;}
        public String status {get; set;} 
        public List<String> headers {get; set;}
        public List<WorkOrderLineItems> workOrderLineItems {get; set;}
    }
    
    public class WorkOrderLineItems {
        public String workOrderLineItemNumber;
        public String uniqueId;
        public String sourceReferenceLineNumber;
    }
    
    public class SyncWorkOrderLineItemsWrapper {
        public List<WorkOrderLineItemsWrapper> workOrder = new List<WorkOrderLineItemsWrapper>();       
    }
    
    public class SyncWorkOrderLineTravelItemsWrapper {
        public List<WorkOrderLineItemsTravelWrapper> workOrder = new List<WorkOrderLineItemsTravelWrapper>();       
    }
}