/*********************************************************************************************************************
* Apex Class: SBR_3_0_API_UpdateProductConsumed
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Update (Parts)  to Rentalman (via Mulesoft) when it is Updated in Salesforce
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
1.0             Mayank Jain          	-------             Initial version
2.0				Mayank Jain 			---------			Updated Functionality 
3.0				Mayank Jain				11-Jan-2024			Bulkified Product Consumed
*********************************************************************************************************************/

public with sharing class SBR_3_0_API_UpdateProductConsumed {
    
    private static final String APINAME = 'Update_Product_Consumed_API';
    private static final String X_CORRELATION_ID = SBR_3_0_Generic.generateRandomString(10);
    private static SyncProductConsumedWrapper requestBody = new SyncProductConsumedWrapper();
    private static String payload;

    @InvocableMethod(Label = 'UpdateProductConsumedRMCallout')
    public static void ProductConsumedUpdateRMCallout(List<String> input) {
        
        if (!input.isEmpty()&& !System.isFuture() && !System.isBatch()) {
            updatePC(input);
        }
        
    }
    
    @future(Callout = true)
    private static void updatePC(List<String> pcId) {
        try {
        
        Set<String> pdIdSet = new Set<String>(pcId);
        ProductConsumed getPc = SBR_3_0_WorkOrderDA.getProductConsumed(pdIdSet)[0];        
        String rentalManUserName=[Select Wynne_User_Name__c from user where id=:getPc.WorkOrder.OwnerId].Wynne_User_Name__c;        
        if(getPc != null){
            generateWrapper(getPc);
        }
        
        payload = generateJSONPayload();
        SBR_3_0_HttpCallout httpCallout = new SBR_3_0_HttpCallout(APINAME);
        WrappedResponse response = new WrappedResponse();
		String rmWoNumber = getPc.workOrder.SF_PS_RM_WO_Number__c.subStringAfter('-');
        HttpRequest req = httpCallout.getRequest();
        req.setEndpoint(req.getEndpoint() + rmWoNumber + '/parts/'+ getPc.SF_PS_Parts_Line_Num__c);        
        req.setHeader('thresholdWaitTime', '1');
        req.setHeader('X-Correlation-ID', X_CORRELATION_ID);
        req.setHeader('Content-Type', 'application/json'); 
        req.setHeader('requestTimestamp', String.valueOf(getPc.LastModifiedDate.format('yyyy-MM-dd\'T\'HH:mm:ss.SSSSSS\'Z\'')));        
        req.setHeader('sourceSystemUserId', getPc.WorkOrder.Owner.alias);
        req.setHeader('sourceSystemName', 'SalesForce');
        req.setHeader('rentalmanUserId', rentalManUserName);
        req.setHeader('sourceWorkOrderNumber',getPc.WorkOrder.WorkOrderNumber );        
        req.setHeader('requestTimeZone', getPc.WorkOrder.ServiceTerritory.OperatingHours.TimeZone);
        req.setHeader('pc', getPc.workOrder.ServiceTerritory.Branch_Location_Number__c);
        req.setHeader('companyId', getPc.WorkOrder.SF_PS_Company_Code__c);
        req.setBody(payload);
        system.debug('payload '+payload);
        req.setTimeout(119000);
        Http http = new Http();       
        HTTPResponse res = http.send(req);        
        response.headers = res.getHeaderKeys();
        response.body = res.getBody();               
        if((res.getStatusCode() == 200 || res.getStatus()== 'OK')){
            response.status = 'Complete';
            system.debug('Update Product Consumed Successfull');
        }
        else{
            Exception_Log__c exc = new Exception_Log__c();
            exc.Exception_Message__c = res.getStatusCode() + ' ' +' Request -'+payload +' ' +' Response '+ res.getBody();
            exc.Exception_Type__c = 'SF to RM Outbound Response';
            exc.Method_Name__c= 'updatePC';
            exc.RecordID__c = getPc.id;
            exc.Related_To_Number__c = getPc.WorkOrderId;
            exc.RequestJSON__c = payload;
            exc.ResponseJSON__c = res.getBody();
            exc.Class_Name__c= 'SBR_3_0_API_UpdateProductConsumed';
            insert exc;
            system.debug ('Error Response code-> ' + res.getStatusCode() + ' Error Response message-> ' + res.getBody()); // Do not remove this Debug log
        }
    }
    catch(Exception error){
        SBR_3_0_LogException.LogIt(error);
        System.debug('Error Line -> ' + error.getStackTraceString()); 	// do not remove this debug log
        System.debug('Error Message -> ' + error.getMessage());			// do not remove this debug log     
    }
    
        //Logic for response will be done once we know how RM sends the respone (The Format)
    }
    
    private static void generateWrapper(ProductConsumed pc) {        
        PartsWrapper pcWrapper = new PartsWrapper();
        ProductConsumedDetailsWrapper pcDetails = new ProductConsumedDetailsWrapper();
        pcDetails.sourceReferenceLineNumber = pc.Id;
        pcDetails.itemNumber = pc.Product2.Item_Number__c;
        pcDetails.stockClass = pc.SF_PS_Stock_Class__c;
        pcDetails.quantity =pc.SF_PS_Quantity__c!=null ? Integer.valueOf(pc.SF_PS_Quantity__c):0 ;
        pcDetails.unitOfMeasure = pc.Product2.QuantityUnitOfMeasure;
        //pcDetails.sellingPrice = pc.SF_PS_Selling_Price__c ;
        pcDetails.laborCode =pc.SF_PS_Labor_Code__c !=null? Integer.valueOf(pc.SF_PS_Labor_Code__c):0;
        pcDetails.cost = pc.SF_PS_Cost_Price__c;
        pcDetails.comments = pc.SF_PS_Line_Level_Comment__c;  
        pcDetails.discountPercent = pc.SF_PS_Discount_Percentage__c != null ? Integer.valueOf(pc.SF_PS_Discount_Percentage__c) : 0;     
        if ( Integer.valueOf(pc.SF_PS_Discount_Percentage__c) <= 0){
            pcDetails.sellingPrice = (pc.SF_PS_Selling_Price__c).setScale(2);
        }
        else{
            pcDetails.sellingPrice = (pc.SF_PS_Orig_Selling_Price__c).setScale(2);
        }
        pcWrapper.parts.add(pcDetails);
        requestBody.workOrder.add(pcWrapper);      
    }   
    private static String generateJSONPayload() {
        String currentWrapper = JSON.serialize(requestBody).replace('null', '""');
        return currentWrapper;
    }
    
    public class SyncProductConsumedWrapper{
        public List<PartsWrapper> workOrder=new List<PartsWrapper>();       
        
    }
    
    public class PartsWrapper{
        public List<ProductConsumedDetailsWrapper> parts = new List<ProductConsumedDetailsWrapper>();
    }
    
    public class ProductConsumedDetailsWrapper{
        public String sourceReferenceLineNumber; //productconsumed.Id
        public String itemNumber; //SF_PS_Parts_Line_Num__c
        public String stockClass; //SF_PS_Stock_Class__c
        public Integer quantity; //SF_PS_Quantity__c
        public String unitOfMeasure; //SF_PS_Unit_Of_Measure__c
        public Double sellingPrice; //SF_PS_Selling_Price__c
        public Integer laborCode; //SF_PS_Labor_Code__c
        public Double cost; //SF_PS_Cost_Price__c
        public String comments; //SF_PS_Line_Level_Comment__c
        public Decimal discountPercent; // SF_PS_Discount_Percentage__c

    }
    
    public class WrappedResponse{
        public string body{get;set;}
        public string status{get;set;} 
        public list<String> headers{get;set;}
    }
    
}