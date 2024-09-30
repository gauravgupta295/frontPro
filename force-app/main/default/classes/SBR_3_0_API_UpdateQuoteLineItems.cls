/*********************************************************************************************************************
* Apex Class: SBR_3_0_API_UpdateQuoteLineItems
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Send Quote Line Items to Rentalman (via Mulesoft) when it is updated in Salesforce
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
1.0             Arsh Chhabra         2023-12-04             Initial version
*********************************************************************************************************************/

public with sharing class SBR_3_0_API_UpdateQuoteLineItems {
    
    private static final String APINAME = 'Update_WorkOrder_Quote_Line_Item_API';
    private static final String X_CORRELATION_ID = SBR_3_0_Generic.generateRandomString(10);
    
    private static SyncWorkOrderLineItemsWrapper requestBody = new SyncWorkOrderLineItemsWrapper();
    private static SyncWorkOrderQuoteLineItemsMileageWrapper requestMileageBody = new SyncWorkOrderQuoteLineItemsMileageWrapper();
    private static SyncWorkOrderQuoteLineItemsOutsideLaborWrapper requestOutsideLaborBody=new SyncWorkOrderQuoteLineItemsOutsideLaborWrapper();
    private Static String relatedToId;
    @InvocableMethod(Label = 'UpdateQuoteLineItemsRMCallout')
    public static void WorkOrderRMCallout(List<String> input) {
        
        if (!input.isEmpty()&& !System.isFuture() && !System.isBatch()) {
            createqli(input);
        }
    }
    
    @future(Callout = true)
    private static void createqli(List<String> qliId) {
        try{
            Set<String> qliIdSet = new Set<String>(qliId);
            Quote_Line_Item__c getQli = SBR_3_0_WorkOrderDA.getQuoteLineItems(qliIdSet)[0];   
            relatedToId = getQli.WorkOrderId__c;
            String rentalManUserName=[Select Wynne_User_Name__c from user where id=:getQli.WorkOrderId__r.OwnerId].Wynne_User_Name__c;               
            SBR_3_0_HttpCallout httpCallout = new SBR_3_0_HttpCallout(APINAME);
            WrappedResponse response = new WrappedResponse();       
            HttpRequest req = httpCallout.getRequest(); 
            String payload;
            if(getQli != null && getQli.SF_PS_Line_Type__c == 'MC' ){
                generateMileageWrapper(getQli);
                payload=generateMileageJSONPayload();
            }else if(getQli.SF_PS_Line_Type__c=='LO'){ //outside Labor
                generateOutsideLaborWrapper(getQli);
                payload=generateOutsideLaborJSONPayload();
            }
            else if(getQli != null){
                generateWrapper(getQli);
                payload = generateJSONPayload();
            }       
            string woNumber = getQli.SF_PS_RM_WO_Number__c.subStringAfter('-');
            if(getQli.SF_PS_Line_Type__c == 'MC' ){
                req.setEndpoint(req.getEndpoint()+ woNumber +'/mileageCharges/' +getQli.SF_PS_RM_Labor_Line_Item_Number__c);
            }else if(getQli.SF_PS_Line_Type__c == 'LO'){
                req.setEndpoint(req.getEndpoint()+ woNumber +'/outsideLabor/' +getQli.SF_PS_RM_Labor_Line_Item_Number__c);
            }else{
                req.setEndpoint(req.getEndpoint()+ woNumber +'/insideLabor/' +getQli.SF_PS_RM_Labor_Line_Item_Number__c);
            }
            req.setHeader('thresholdWaitTime', '1');
            req.setHeader('X-Correlation-ID', X_CORRELATION_ID);
            req.setHeader('Content-Type', 'application/json');        
            req.setHeader('requestTimestamp', String.valueOf(getQli.LastModifiedDate.format('yyyy-MM-dd\'T\'HH:mm:ss.SSSSSS\'Z\'')));        
            req.setHeader('sourceSystemUserId', getQli.WorkOrderId__r.Owner.alias);        
            req.setHeader('sourceSystemName', 'SalesForce');
            req.setHeader('rentalmanUserId', rentalManUserName);        
            req.setHeader('requestTimeZone', getQli.WorkOrderId__r.ServiceTerritory.OperatingHours.TimeZone);
            req.setHeader('sourceWorkOrderNumber',getQli.WorkOrderId__r.WorkOrderNumber );        
            req.setHeader('pc', getQli.WorkOrderId__r.SF_PS_Current_Loc__c);
            req.setHeader('companyId', getQli.WorkOrderId__r.SF_PS_Company_Code__c);
            req.setTimeout(119000);
            req.setMethod('PUT');
            req.setBody(payload);
            system.debug('payload+ ' + payload);
            Http http = new Http();
            HTTPResponse res = http.send(req);       
            response.headers = res.getHeaderKeys();
            response.body = res.getBody();
            system.debug('response.body+ ' + response.body);
            if((res.getStatusCode() == 200 || res.getStatus()== 'OK')){
                response.status = 'Complete';
                system.debug('QuoteLineItems is Successfully Updated');
            }else{
                Exception_Log__c exc = new Exception_Log__c();
                exc.Exception_Message__c = res.getStatusCode() + ' ' +' Request - ' + payload + ' ' +' Response '+response.body;
                exc.StatusCode__c = String.valueOf( res.getStatusCode()) ;
                exc.Exception_Type__c = 'SF to RM Outbound Response';
                exc.Method_Name__c= 'createqli';
                exc.RequestJSON__c= payload;
                exc.ResponseJSON__c = response.body;
                exc.RecordID__c = getQli.id;
                exc.Related_To_Number__c=getQli.WorkOrderId__c;
                exc.Class_Name__c= 'SBR_3_0_API_UpdateQuoteLineItems';
                exc.Stack_Trace__c = 'SBR_3_0_API_UpdateQuoteLineItems , createqli - line 30 , http.send(req) - Line 73 || Error Message + ' +  response.message;
                insert exc;
                system.debug ('Error Response code-> ' + res.getStatusCode() + ' Error Response message-> ' + response.message); // Do not remove this Debug log
            }
        }catch(Exception error){
            try{
                SBR_3_0_LogException.LogIt(error,relatedToId);
            }catch(Exception err){
                SBR_3_0_LogException.LogIt(error);
            }
            System.debug('Error Line -> ' + error.getStackTraceString()); 	// do not remove this debug log
            System.debug('Error Message -> ' + error.getMessage());			// do not remove this debug log
        }
        //Logic for response will be done once we know how RM sends the respone (The Format)
    }
    
    private static String generateJSONPayload() {
        String currentWrapper = JSON.serialize(requestBody).replace('null', '""');
        return currentWrapper;
    }
    
    private static void generateWrapper(Quote_Line_Item__c qli) {
        WorkOrderQuoteLineItemsWrapper woqliWrapper = new WorkOrderQuoteLineItemsWrapper();
        woqliDetailsClass woqliDetails = new woqliDetailsClass();
        woqliDetails.sourceReferenceLineNumber = qli.id;
        //woqliDetails.mechanicId = qli.WorkOrderId__r.SF_PS_Service_Resource__r.SF_PS_Mechanic_Id__c;
        woqliDetails.mechanicId = qli.SF_PS_Mechanic_Id__c;
        woqliDetails.laborCode = qli.SF_PS_Labor_Code__c == null ? 0 : Integer.valueOf(qli.SF_PS_Labor_Code__c);
        woqliDetails.insideLaborRate = qli.SF_PS_Hourly_Internal_Rate__c  == null ? 0 :  Integer.valueOf(qli.SF_PS_Hourly_Internal_Rate__c);
        woqliDetails.insideLaborHours = qli.SF_PS_Duration__c == null ? 0.0 : qli.SF_PS_Duration__c; 
        woqliWrapper.insideLabor.add(woqliDetails);
        requestBody.workOrderQuote.add(woqliWrapper);
    }
    
    public class SyncWorkOrderLineItemsWrapper{
        public List<WorkOrderQuoteLineItemsWrapper> workOrderQuote=new List<WorkOrderQuoteLineItemsWrapper>();       
    }
    
    public class WorkOrderQuoteLineItemsWrapper{
        public List<woqliDetailsClass> insideLabor = new List<woqliDetailsClass>();
    }
    class woqliDetailsClass {
        
        public String sourceReferenceLineNumber; //workorderLineItem.Id
        public String mechanicId;	    //WorkOrder.ServiceResource.SF_PS_Mechanic_Id__c
        public Integer laborCode;	//SF_PS_Labor_Code__c
        public Integer insideLaborRate; //SF_PS_Hourly_Internal_Rate__c
        public Double insideLaborHours; //Duration
    }
    
    
    // Mileage Body Generation
    private static String generateMileageJSONPayload() {
        String currentWrapper = JSON.serialize(requestMileageBody).replace('null', '""');
        return currentWrapper;
    }
    
    private static void generateMileageWrapper(Quote_Line_Item__c qli) {        
        WorkOrderQuoteLineItemsMileageWrapper qliMileageWrapper = new WorkOrderQuoteLineItemsMileageWrapper(); 
        QliMilegeDetailsClass qliMileageDetails = new QliMilegeDetailsClass();
        qliMileageDetails.sourceReferenceLineNumber = qli.Id;
        qliMileageDetails.mileageMiles = qli.SF_PS_Duration__c == null ? 0.0 : qli.SF_PS_Duration__c;
        qliMileageDetails.mileageRate = qli.SF_PS_Hourly_Internal_Rate__c == null ? 0.0 : qli.SF_PS_Hourly_Internal_Rate__c;   
        qliMileageWrapper.mileage = qliMileageDetails;
        requestMileageBody.workOrderQuote.add(qliMileageWrapper);
    }
    
    public class SyncWorkOrderQuoteLineItemsMileageWrapper{
        public List<WorkOrderQuoteLineItemsMileageWrapper> workOrderQuote=new List<WorkOrderQuoteLineItemsMileageWrapper>();       
    }   
    
    public class WorkOrderQuoteLineItemsMileageWrapper{
        public QliMilegeDetailsClass mileage = new QliMilegeDetailsClass();
    }
    
    class QliMilegeDetailsClass {
        public String sourceReferenceLineNumber; //workorderLineItem.Id
        public Decimal mileageMiles; //Duration
        public Decimal mileageRate; //SF_PS_Hourly_Internal_Rate__c 
    }    
    
    //Outside Labor Body Generation 
    
    private static String generateOutsideLaborJSONPayload() {
        String currentWrapper = JSON.serialize(requestOutsideLaborBody).replace('null', '""');
        return currentWrapper;
    }
    
    
    private static void generateOutsideLaborWrapper(Quote_Line_Item__c qli){
        WorkOrderQuoteLineItemsOutsideLaborWrapper qliOutsideLaborWrapper = new WorkOrderQuoteLineItemsOutsideLaborWrapper();
        QliOutsidelaborDetailsClass qliOutsideLaborDetails=new QliOutsidelaborDetailsClass();
        qliOutsideLaborDetails.sourceReferenceLineNumber = qli.id;
        qliOutsideLaborDetails.laborCode = qli.SF_PS_Labor_Code__c == null ? 0 : Integer.valueOf(qli.SF_PS_Labor_Code__c);
        qliOutsideLaborDetails.outsideLaborPoNumber = qli.SF_PS_Vendor_PO_Num__c == null ? '' : (String)qli.SF_PS_Vendor_PO_Num__c;
        qliOutsideLaborDetails.outsideLaborPrice = qli.SF_PS_PO_Amount__c == null ? 0.0 : qli.SF_PS_PO_Amount__c;
        qliOutsideLaborDetails.outsideLaborCost = qli.SF_PS_PO_Cost__c == null ? 0.0 : qli.SF_PS_PO_Cost__c; //should not be 0
        qliOutsideLaborDetails.outsideLaborDescription = qli.SF_PS_Outside_Labor_Des__c;
        qliOutsideLaborWrapper.outsideLabor.add(qliOutsideLaborDetails);
        requestOutsideLaborBody.workOrderQuote.add(qliOutsideLaborWrapper);
    }
    public class SyncWorkOrderQuoteLineItemsOutsideLaborWrapper{
        public List<WorkOrderQuoteLineItemsOutsideLaborWrapper> workOrderQuote=new List<WorkOrderQuoteLineItemsOutsideLaborWrapper>();       
    }  
    
    public class WorkOrderQuoteLineItemsOutsideLaborWrapper{
        public List<QliOutsidelaborDetailsClass> outsideLabor = new List<QliOutsidelaborDetailsClass>();
    }
    
    class QliOutsidelaborDetailsClass {
        public String sourceReferenceLineNumber; //workorderLineItem.Id
        public Integer laborCode;	//9999
        public String outsideLaborPoNumber;	//99999999
        public Double outsideLaborPrice;	//99999999.99
        public Double outsideLaborCost;	
        public String outsideLaborDescription;
    }  
    
    public class WrappedResponse{
        public string workOrderNumber{get;set;}
        //   public string mode{get;set;} 
        public string message;
        public string body{get;set;}
        public string status{get;set;} 
        public list<String> headers{get;set;}
        //  public list<WorkOrderLineItems> workOrderLineItems{get;set;}
    }
    
}