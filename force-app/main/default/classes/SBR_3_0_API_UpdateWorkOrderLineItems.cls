/*********************************************************************************************************************
* Apex Class: SBR_3_0_API_UpdateWorkOrderLineItems
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Calss to Update Work order Line Item End Point in RM .
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION       DATE               DETAIL FEATURES
1.0          	----------        	Initial version 
2.0          	----------          Update In Functionality 
3.0				11-Jan-2024			Mayank Jain - Bulkified Code 
**********************************************************************************************************************************************/
public with sharing class SBR_3_0_API_UpdateWorkOrderLineItems {
    
    private static final String APINAME = 'Update_WorkOrder_Line_Item_API';
    private static final String X_CORRELATION_ID = SBR_3_0_Generic.generateRandomString(10);
    private static String payload;

    private static SyncWorkOrderLineItemsWrapper requestBody = new SyncWorkOrderLineItemsWrapper();
    private static SyncWorkOrderLineTravelItemsWrapper requestTravelBody = new SyncWorkOrderLineTravelItemsWrapper();
    
    
    @InvocableMethod(Label = 'UpdateWorkOrderLineItemsRMCallout')
    public static void WorkOrderUpdateRMCallout(List<String> input) {
        
        if (!input.isEmpty()&& !System.isFuture() && !System.isBatch()) {
            updateWoli(input);
        }
    }
    
    @future(Callout = true)
    private static void updateWoli(List<String> woliId) {
        try{        
        Set<String> woliIdSet = new Set<String>(woliId);
        WorkOrderLineItem getWoli = SBR_3_0_WorkOrderDA.getWorkOrderLineItems(woliIdSet)[0];
        
        //if(getWoli != null){
        //    generateWrapper(getWoli);
        //}
        
        String rentalManUserName=[Select Wynne_User_Name__c from user where id=:getWoli.WorkOrder.OwnerId].Wynne_User_Name__c;        
        SBR_3_0_HttpCallout httpCallout = new SBR_3_0_HttpCallout(APINAME);
        WrappedResponse response = new WrappedResponse();
        
        HttpRequest req = httpCallout.getRequest();


        if(getWoli != null && getWoli.SF_PS_Line_Type__c == 'MC' ){
            generateTravelWrapper(getWoli);
            payload = generateTravelJSONPayload();
            
        }else if(getWoli != null){
            generateWrapper(getWoli);
            payload = generateJSONPayload();
        }
        
        req.setMethod('PUT');
        string woNumber = getWoli.SF_PS_RM_WO_Number__c.subStringAfter('-');
        if(getWoli.SF_PS_Line_Type__c == 'MC' ){
            req.setEndpoint(req.getEndpoint()+ woNumber + '/mileageCharges/'  + getWoli.SF_PS_RM_Labor_Line_Item_Number__c);
        }else{
            req.setEndpoint(req.getEndpoint()+ woNumber +'/insideLabor/' + getWoli.SF_PS_RM_Labor_Line_Item_Number__c);
        }
        req.setHeader('thresholdWaitTime', '1');
        req.setHeader('X-Correlation-ID', X_CORRELATION_ID);
        req.setHeader('Content-Type', 'application/json'); 
        req.setHeader('requestTimestamp', String.valueOf(getWoli.LastModifiedDate.format('yyyy-MM-dd\'T\'HH:mm:ss.SSSSSS\'Z\'')));
        req.setHeader('sourceSystemUserId', getWoli.WorkOrder.Owner.alias);
        req.setHeader('sourceSystemName', 'SalesForce');
        req.setHeader('rentalmanUserId', rentalManUserName);
        req.setHeader('requestTimeZone', getWoli.WorkOrder.ServiceTerritory.OperatingHours.TimeZone);
        req.setHeader('sourceWorkOrderNumber',getWoli.WorkOrder.WorkOrderNumber );
        req.setHeader('pc', getWoli.workOrder.ServiceTerritory.Branch_Location_Number__c);
        req.setHeader('companyId', getWoli.WorkOrder.SF_PS_Company_Code__c); 
        req.setBody(payload);
        system.debug('Payload '+ payload);
        req.setTimeout(119000);
        Http http = new Http();
        
        HTTPResponse res = http.send(req);
        
        response.headers = res.getHeaderKeys();
        response.body = res.getBody();
        if((res.getStatusCode() == 200 || res.getStatus()== 'OK')){
            response.status = 'Complete';
            system.debug('Update Callout successfull');
        }
        else{
            Exception_Log__c exc = new Exception_Log__c();
            exc.Exception_Message__c = res.getStatusCode() + ' ' +' Request -'+payload +' ' +' Response '+ res.getBody();
            exc.Exception_Type__c = 'SF to RM Outbound Response';
            exc.Method_Name__c= 'UpdateWorkOrderLineItem';
            //exc.Id = String.valueOf(getWo.id);
            exc.Class_Name__c= 'SBR_3_0_API_UpdateWorkOrderLineItems';
            insert exc;
            system.debug ('Error Response code-> ' + res.getStatusCode() + ' Error Response message-> ' + res.getBody()); // Do not remove this Debug log
        }
    }catch(Exception error){
        SBR_3_0_LogException.LogIt(error);
        System.debug('Error Line -> ' + error.getStackTraceString()); 	// do not remove this debug log
        System.debug('Error Message -> ' + error.getMessage());			// do not remove this debug log
         
    }
        //Logic for response will be done once we know how RM sends the respone (The Format)
    }
    
    private static void generateWrapper(WorkOrderLineItem woli) {        
        WorkOrderLineItemsWrapper woliWrapper = new WorkOrderLineItemsWrapper();
        woliDetailsClass woliDetails = new woliDetailsClass();       
        woliDetails.sourceReferenceLineNumber = woli.id;
        woliDetails.lineNumber = woli.SF_PS_RM_Item_Number__c;
        woliDetails.mechanic = woli.SF_PS_Mechanic_Id__c;
        woliDetails.laborCode =woli.SF_PS_Labor_Code__c!=null? Integer.valueOf(woli.SF_PS_Labor_Code__c):0;
        woliDetails.insideLaborRate = woli.SF_PS_Hourly_Internal_Rate__c!=null?Integer.valueOf(woli.SF_PS_Hourly_Internal_Rate__c):0;
        woliDetails.insideLaborHours = woli.Duration; 
        woliWrapper.insideLabor.add(woliDetails);
        requestBody.workOrder.add(woliWrapper);
    }
    
    
    private static String generateJSONPayload() {
        String currentWrapper = JSON.serialize(requestBody).replace('null', '""');
        return currentWrapper;
    }
    
    public class SyncWorkOrderLineItemsWrapper{
        public List<WorkOrderLineItemsWrapper> workOrder=new List<WorkOrderLineItemsWrapper>();       
    }
    
    public class WorkOrderLineItemsWrapper{
        public List<woliDetailsClass> insideLabor = new List<woliDetailsClass>();
    }
    class woliDetailsClass {
        public String sourceReferenceLineNumber; 
        public String lineNumber; //SF_PS_RM_Item_Number__c
        public String mechanic;	
        public Integer laborCode;	//SF_PS_Labor_Code__c
        public Integer insideLaborRate; //SF_PS_Hourly_Internal_Rate__c
        public Decimal insideLaborHours; //Duration
    }
    
    
    
    
    
    // Travel Body Generation
    private static String generateTravelJSONPayload() {
        String currentWrapper = JSON.serialize(requestTravelBody).replace('null', '""');
        return currentWrapper;
    }
    
    private static void generateTravelWrapper(WorkOrderLineItem woli) {
        WorkOrderLineItemsTravelWrapper woliTravelWrapper = new WorkOrderLineItemsTravelWrapper();
        woliTravelDetailsClass woliTravelDetails = new woliTravelDetailsClass();
        woliTravelDetails.sourceReferenceLineNumber = woli.Id;
        woliTravelDetails.mileageMiles = woli.Duration;
        woliTravelDetails.mileageRate = woli.SF_PS_Hourly_Internal_Rate__c;
        woliTravelWrapper.mileage = woliTravelDetails;
        requestTravelBody.workOrder.add(woliTravelWrapper);
    }
    
    public class SyncWorkOrderLineTravelItemsWrapper{
        public List<WorkOrderLineItemsTravelWrapper> workOrder=new List<WorkOrderLineItemsTravelWrapper>();       
    }
    
    public class WorkOrderLineItemsTravelWrapper{
        public woliTravelDetailsClass mileage = new woliTravelDetailsClass();
    }
    
    class woliTravelDetailsClass {
        public String sourceReferenceLineNumber; //workorderLineItem.Id
        public Decimal mileageMiles; //SF_PS_Hourly_Internal_Rate__c
        public Decimal mileageRate; //Duration
    }    
    
    public class WrappedResponse{
        public string body{get;set;}
        public string status{get;set;} 
        public list<String> headers{get;set;}
    }
    
}