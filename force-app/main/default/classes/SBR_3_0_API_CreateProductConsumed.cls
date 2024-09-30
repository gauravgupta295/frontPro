/*********************************************************************************************************************
* Apex Class: SBR_3_0_API_CreateProductConsumed
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Send ProductConsume (Parts) to Rentalman (via Mulesoft) when it is created in Salesforce
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
1.0             Mayank Jain          	-------             Initial version
2.0				Mayank Jain 			---------			Updated Functionality 
3.0				Mayank Jain				11-Jan-2024			Bulkified Product Consumed
*********************************************************************************************************************/
public with sharing class SBR_3_0_API_CreateProductConsumed {

    private static final String APINAME = 'Send_Product_Consumed_API';
    private static final String X_CORRELATION_ID = SBR_3_0_Generic.generateRandomString(10);
    private static String payload;
    private static String relatedToId;
    private static ProductConsumed getPc;
    private static SyncProductConsumedWrapper requestBody = new SyncProductConsumedWrapper();

    @InvocableMethod(Label = 'CreateProductConsumedRMCallout')
    public static void ProductConsumedCreateRMCallout(List<String> input) {
        if (!input.isEmpty()) {
            // Enqueue the Queueable job
            System.enqueueJob(new ProductConsumedCalloutJob(input));
        }
    }
    
    public class ProductConsumedCalloutJob implements Queueable, Database.AllowsCallouts {
        private List<String> pcIds;
        
        public ProductConsumedCalloutJob(List<String> inputIds) {
            this.pcIds = inputIds;
        }

        public void execute(QueueableContext context) {
            String pcId = pcIds.remove(0);
            Set<String> pcIdSet = new Set<String>{pcId};
            List<ProductConsumed> getPcList = SBR_3_0_WorkOrderDA.getProductConsumed(pcIdSet);
            if (!getPcList.isEmpty()) {
                getPc = getPcList[0];
            }
            List<ProductConsumed> responseList = new List<ProductConsumed>(); 

            try {
                if (getPc != null && String.isBlank(getPc.SF_PS_RM_External_Id__c)) {
                    // Proceed with the callout
                    sendCallout(getPc);
                }
            } catch (Exception e) {
                // Log the exception
                SBR_3_0_LogException.LogIt(e, getPc.WorkOrderId);
            }
            // If there are remaining ProductConsumeds, re-enqueue the job
            if (!pcIds.isEmpty()) {
                System.enqueueJob(new ProductConsumedCalloutJob(pcIds));
            }
        }

        private void sendCallout(ProductConsumed getPc) {
            // Set up the callout
            String rentalManUserName = [SELECT Wynne_User_Name__c FROM User WHERE Id = :getPc.WorkOrder.OwnerId].Wynne_User_Name__c;
            SBR_3_0_HttpCallout httpCallout = new SBR_3_0_HttpCallout(APINAME);
            HttpRequest req = httpCallout.getRequest();
            WrappedResponse response = new WrappedResponse();

            generateWrapper(getPc);
            payload = generateJSONPayload();
            req.setEndpoint(req.getEndpoint() + getPc.WorkOrder.SF_PS_RM_WO_Number__c.subStringAfter('-') + '/parts');
            
            // Set headers and body
            req.setHeader('thresholdWaitTime', '1');
            req.setHeader('X-Correlation-ID', X_CORRELATION_ID);       
            req.setHeader('Content-Type', 'application/json');       
            req.setHeader('requestTimestamp', String.valueOf(getPc.LastModifiedDate.format('yyyy-MM-dd\'T\'HH:mm:ss.SSSSSS\'Z\'')));        
            req.setHeader('sourceSystemUserId', getPc.WorkOrder.Owner.alias);               
            req.setHeader('sourceSystemName', 'SalesForce');
            req.setHeader('rentalmanUserId', rentalManUserName);              
            req.setHeader('requestTimeZone', getPc.WorkOrder.ServiceTerritory.OperatingHours.TimeZone);      
            req.setHeader('sourceWorkOrderNumber', getPc.WorkOrder.WorkOrderNumber);        
            req.setHeader('pc', getPc.WorkOrder.ServiceTerritory.Branch_Location_Number__c);
            req.setHeader('companyId', getPc.WorkOrder.SF_PS_Company_Code__c);
            req.setTimeout(119000);    
            req.setBody(payload);
            System.debug('Payload ' + payload);
            Http http = new Http();
            HTTPResponse res = http.send(req);

            // Process response
            if (res.getStatusCode() == 200 || res.getStatus() == 'OK') {
                response = (WrappedResponse) JSON.deserialize(res.getBody(), WrappedResponse.class);
                WorkOrderLineItems externalResp = response.workOrderLineItems[0];
                getPc.SF_PS_Parts_Line_Num__c = externalResp.workOrderLineItemNumber;
                getPc.SF_PS_RM_External_Id__c = externalResp.uniqueId;
                update getPc;
            } else {
                // Handle non-success responses
                Exception_Log__c exc = new Exception_Log__c();
                exc.Exception_Message__c = res.getStatusCode() + ' ' + 'Request -' + payload + ' ' + 'Response ' + res.getBody();
                exc.Exception_Type__c = 'SF to RM Outbound Response';
                exc.Method_Name__c = 'sendCallout';
                exc.RecordID__c = getPc.id;
                exc.Related_To_Number__c = getPc.WorkOrderId;
                exc.RequestJSON__c = payload;
                exc.ResponseJSON__c = res.getBody();
                exc.Class_Name__c = 'SBR_3_0_API_CreateProductConsumed';
                insert exc;
            }
        }
        
        private void generateWrapper(ProductConsumed pc) {
            PartsWrapper pcWrapper = new PartsWrapper();
            ProductConsumedDetailsWrapper pcDetails = new ProductConsumedDetailsWrapper();
            pcDetails.sourceReferenceLineNumber = pc.Id;
            pcDetails.itemNumber = pc.Product2.Item_Number__c;
            pcDetails.stockClass = pc.SF_PS_Stock_Class__c;
            pcDetails.quantity = pc.SF_PS_Quantity__c != null ? Integer.valueOf(pc.SF_PS_Quantity__c) : null;
            pcDetails.unitOfMeasure = pc.Product2.QuantityUnitOfMeasure;
            pcDetails.laborCode = pc.SF_PS_Labor_Code__c != null ? Integer.valueOf(pc.SF_PS_Labor_Code__c) : null;
            pcDetails.cost = (pc.SF_PS_Cost_Price__c).setScale(2);
            pcDetails.comments = pc.SF_PS_Line_Level_Comment__c;
            pcDetails.discountPercent = pc.SF_PS_Discount_Percentage__c != null ? Integer.valueOf(pc.SF_PS_Discount_Percentage__c) : 0;
            if ( Integer.valueOf(pc.SF_PS_Discount_Percentage__c) <= 0){
                pcDetails.sellingPrice = (pc.SF_PS_Selling_Price__c).setScale(2);
            }
            else{
                pcDetails.sellingPrice = (pc.SF_PS_Orig_Selling_Price__c).setScale(2);
            }
            //pcDetails.sellingPrice = (pc.SF_PS_Selling_Price__c).setScale(2);
            pcWrapper.parts.add(pcDetails);
            requestBody.workOrder.add(pcWrapper);
        }

        private String generateJSONPayload() {
            return JSON.serialize(requestBody);
        }
    }

    public class SyncProductConsumedWrapper {
        public List<PartsWrapper> workOrder = new List<PartsWrapper>();
    }

    public class PartsWrapper {
        public List<ProductConsumedDetailsWrapper> parts = new List<ProductConsumedDetailsWrapper>();
    }

    public class ProductConsumedDetailsWrapper {
        public String sourceReferenceLineNumber; // productconsumed.Id
        public String itemNumber; // Product2.Item_Number__c
        public String stockClass; // SF_PS_Stock_Class__c
        public Decimal quantity; // SF_PS_Quantity__c
        public String unitOfMeasure; // SF_PS_Unit_Of_Measure__c
        public Decimal sellingPrice; // SF_PS_Selling_Price__c
        public Integer laborCode; // SF_PS_Labor_Code__c
        public Decimal cost; // SF_PS_Cost_Price__c
        public String comments; // SF_PS_Line_Level_Comment__c
        public Decimal discountPercent; // SF_PS_Discount_Percentage__c
    }

    public class WrappedResponse {
        public String workOrderNumber { get; set; }
        public String mode { get; set; }
        public String message;
        public String body { get; set; }
        public String status { get; set; }
        public List<String> headers { get; set; }
        public List<WorkOrderLineItems> workOrderLineItems { get; set; }
    }

    public class WorkOrderLineItems {
        public String workOrderLineItemNumber; // SF_PS_Parts_Line_Num__c
        public String uniqueId; // SF_PS_RM_External_Id__c
        public String sourceReferenceLineNumber;
    }
}