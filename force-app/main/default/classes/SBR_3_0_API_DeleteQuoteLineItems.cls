/*********************************************************************************************************************
* Apex Class: SBR_3_0_DeleteQuoteLineItems
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Delete Quote Line Item in Rentalman (via Mulesoft)
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
1.0             Arsh Chhabra         2023-12-04             Initial version
*********************************************************************************************************************/

public class SBR_3_0_API_DeleteQuoteLineItems {
    private static final String APINAME = 'Delete_Quote_Line_Item_API';
    private static final String X_CORRELATION_ID = SBR_3_0_Generic.generateRandomString(10);
    
    @InvocableMethod(Label = 'DeleteQuoteLineItemsRMCallout')
    public static void WorkOrderRMCallout(List<String> input) {
        
        
        if (!input.isEmpty()&& !System.isFuture() && !System.isBatch()) {
            Quote_Line_Item__c getWoli = [SELECT Id, LastModifiedDate,
                                          WorkOrderId__r.Owner.Name, 
                                          WorkOrderId__r.OwnerId,
                                          WorkOrderId__r.ServiceTerritory.OperatingHours.TimeZone, 
                                          WorkOrderId__r.WorkOrderNumber,
                                          WorkOrderId__r.Owner.alias,
                                          WorkOrderId__r.ServiceTerritory.Branch_Location_Number__c, 
                                          WorkOrderId__r.SF_PS_Current_Loc__c,
                                          WorkOrderId__r.SF_PS_Company_Code__c,
                                          WorkOrderId__r.SF_PS_RM_WO_Number__c, 
                                          WorkOrderId__r.SF_PS_Service_Resource__r.SF_PS_Mechanic_Id__c, 
                                          SF_PS_Duration__c,
                                          WorkOrderId__c,
                                          SF_PS_RM_WO_Number__c,
                                          SF_PS_Hourly_Internal_Rate__c,
                                          SF_PS_Is_Taxable__c,
                                          SF_PS_Labor_Code__c,
                                          SF_PS_Line_Type__c,
                                          SF_PS_Mechanic_Name__c,
                                          SF_PS_Mileage_Charge__c,
                                          SF_PS_RM_Created_Timestamp__c,
                                          SF_PS_RM_External_Id__c,
                                          SF_PS_RM_Item_Number__c,
                                          SF_PS_RM_Labor_Line_Item_Number__c,
                                          SF_PS_Vendor_PO_Num__c
                                          FROM Quote_Line_Item__c WHERE Id=: input[0] ];
            if(getWoli == null){
                return;
            }
            
            String woliId = String.valueof(getWoli.id);
            String workOrderId =  getWoli.WorkOrderId__c;
            String workOrderLineItemNumber = getWoli.SF_PS_RM_Labor_Line_Item_Number__c;
            String lastmodified  = String.valueOf(getWoli.LastModifiedDate.format('yyyy-MM-dd\'T\'HH:mm:ss.SSSSSS\'Z\''));
            String sourceSystemUserId = getWoli.WorkOrderId__r.Owner.alias;
            String UserID = getWoli.WorkOrderId__r.OwnerId;
            String timezone  = getWoli.WorkOrderId__r.ServiceTerritory.OperatingHours.TimeZone;
            String sourceWorkOrderNumber = getWoli.WorkOrderId__r.WorkOrderNumber ;
            String pc = getWoli.WorkOrderId__r.ServiceTerritory.Branch_Location_Number__c;
            String companyID = getWoli.WorkOrderId__r.SF_PS_Company_Code__c;
            String wiloType = getWoli.SF_PS_Line_Type__c;
            String userName = getWoli.WorkOrderId__r.Owner.Name;
            String rmWONumber = getWoli?.SF_PS_RM_WO_Number__c?.subStringAfter('-');
            
            deleteWoli(woliId, workOrderId, workOrderLineItemNumber,lastmodified ,sourceSystemUserId ,  UserID ,timezone,sourceWorkOrderNumber , pc ,companyID, wiloType,userName,rmWONumber);
        }
    }
    
    @future(Callout = true)
    private static void deleteWoli(String woliId, String workOrderId, String workOrderLineItemNumber,  String lastmodified , String sourceSystemUserId , String UserID ,String  timezone,String sourceWorkOrderNumber , String pc ,String companyID, String wiloType,  String userName ,String rmWONumber  )   {
        try{
            String rentalManUserName=[Select Wynne_User_Name__c from user where id=:UserID].Wynne_User_Name__c;       
            SBR_3_0_HttpCallout httpCallout = new SBR_3_0_HttpCallout(APINAME);
            WrappedResponse response = new WrappedResponse();
            HttpRequest req = httpCallout.getRequest();
            
            if(wiloType == 'MC' ){
                req.setEndpoint(req.getEndpoint()+ rmWONumber +'/mileageCharges/' + workOrderLineItemNumber);
            }else if(wiloType == 'LO'){
                req.setEndpoint(req.getEndpoint()+ rmWONumber +'/outsideLabor/'+ workOrderLineItemNumber);
            }else{
                req.setEndpoint(req.getEndpoint()+ rmWONumber +'/insideLabor/' + workOrderLineItemNumber);        
            }
            req.setHeader('thresholdWaitTime', '1');
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('sourceSystemName', 'SalesForce');
            req.setHeader('X-Correlation-ID', X_CORRELATION_ID);
            req.setHeader('requestTimestamp', lastmodified);
            req.setHeader('sourceSystemUserId', sourceSystemUserId);
            req.setHeader('rentalmanUserId', rentalManUserName);
            req.setHeader('requestTimeZone', timezone);
            req.setHeader('sourceWorkOrderNumber', sourceWorkOrderNumber );
            req.setHeader('sourceReferenceLineNumber', workOrderId );
            req.setHeader('pc', pc);
            req.setHeader('companyId', companyID);  
            req.setTimeout(119000); 
            Http http = new Http();
            HTTPResponse res = http.send(req);
            response.headers = res.getHeaderKeys();
            response.body = res.getBody();
            if((res.getStatusCode() == 200 || res.getStatus()== 'OK')){
                response.status = 'Complete';
            }else{
                Exception_Log__c exc = new Exception_Log__c();
                exc.Exception_Message__c = res.getStatusCode() + ' ' + ' Request - NO Json Body, Response '+ response.body;
                exc.StatusCode__c = String.valueOf( res.getStatusCode()) ;
                exc.Exception_Type__c = 'SF to RM Outbound Response';
                exc.Method_Name__c= 'deleteWoli';
                //exc.RequestJSON__c= payload;
                exc.ResponseJSON__c = response.body;
                exc.RecordID__c = woliId;
                exc.Related_To_Number__c=workOrderId;
                exc.Class_Name__c= 'SBR_3_0_API_DeleteQuoteLineItems';
                exc.Stack_Trace__c = 'SBR_3_0_API_DeleteQuoteLineItems , deleteWoli - line 69 , http.send(req) - Line 97 ';
                insert exc;
                system.debug ('Error Response code-> ' + res.getStatusCode() + ' Error Response message-> ' + response.body); // Do not remove this Debug log
            }
        }catch(Exception error){
            try{
                SBR_3_0_LogException.LogIt(error,workOrderId);
            }catch(Exception err){
                SBR_3_0_LogException.LogIt(error);
            }
            System.debug('Error Line -> ' + error.getStackTraceString()); 	// do not remove this debug log
            System.debug('Error Message -> ' + error.getMessage());			// do not remove this debug log
            
        }
    }
    public class WrappedResponse{
        public string body{get;set;}
        public string status{get;set;} 
        public list<String> headers{get;set;}
    }
}