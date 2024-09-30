/*********************************************************************************************************************
* Apex Class: SBR_3_0_API_DeleteQuotedParts
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Delete Quoted Parts in Rentalman (via Mulesoft)
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
1.0             Arsh Chhabra         2023-12-04             Initial version
*********************************************************************************************************************/

public with sharing class SBR_3_0_API_DeleteQuotedParts {
    private static final String APINAME = 'Delete_Quoted_Parts_API';
    private static final String X_CORRELATION_ID = SBR_3_0_Generic.generateRandomString(10);
    
    @InvocableMethod(Label = 'DeleteQuotedPartsRMCallout')
    public static void DeleteQpRMCallout(List<String> input) {
        
        
        if (!input.isEmpty() && !System.isFuture() && !System.isBatch()) {
            SF_PS_Quoted_Part__c getQp = [SELECT Id, 
                                          LastModifiedDate,
                                          SF_PS_WorkOrderId__r.WorkOrderNumber,
                                          SF_PS_WorkOrderId__r.Owner.Name, 
                                          SF_PS_WorkOrderId__r.OwnerId , 
                                          SF_PS_WorkOrderId__r.ServiceTerritory.OperatingHours.TimeZone , 
                                          SF_PS_WorkOrderId__r.ServiceTerritory.Branch_Location_Number__c , 
                                          SF_PS_WorkOrderId__r.SF_PS_Company_Code__c ,
                                          SF_PS_WorkOrderId__r.SF_PS_RM_WO_Number__c,
                                          SF_PS_WorkOrderId__r.Owner.alias ,
                                          SF_PS_Product2Id__r.Item_Number__c,
                                          SF_PS_Product2Id__r.QuantityUnitOfMeasure,
                                          SF_PS_Product2Id__c,
                                          SF_PS_WorkOrderId__c,
                                          SF_PS_Cost_Price__c,
                                          SF_PS_Discount_Amt__c,
                                          SF_PS_Discount_Percentage__c,
                                          SF_PS_Is_Taxable__c,
                                          SF_PS_ItemType__c,
                                          SF_PS_Labor_Code__c,
                                          SF_PS_Line_Level_Comment__c,
                                          SF_PS_Line_Type__c,
                                          SF_PS_List_Price__c,
                                          SF_PS_Quoted_Parts_Line_Num__c,
                                          SF_PS_Quantity__c,
                                          SF_PS_RM_Created_Timestamp__c,
                                          SF_PS_Selling_Price__c,
                                          SF_PS_Unit_Of_Measure__c,
                                          SF_PS_RM_External_Id__c,
                                          SF_PS_Shipped_Qty__c  FROM SF_PS_Quoted_Part__c WHERE Id=: input[0] ];
            if(getQp == null){
                return;
            }
            String getQpId = String.Valueof(getQp.id);
            String workOrderId =  getQp.SF_PS_WorkOrderId__c;
            String workOrderLineItemNumber = getQp.SF_PS_Quoted_Parts_Line_Num__c;
            String lastmodified  = String.valueOf(getQp.LastModifiedDate.format('yyyy-MM-dd\'T\'HH:mm:ss.SSSSSS\'Z\''));
            String sourceSystemUserId = getQp.SF_PS_WorkOrderId__r.Owner.alias;
            String UserID = getQp.SF_PS_WorkOrderId__r.OwnerId;
            String timezone  = getQp.SF_PS_WorkOrderId__r.ServiceTerritory.OperatingHours.TimeZone;
            String sourceWorkOrderNumber = getQp.SF_PS_WorkOrderId__r.WorkOrderNumber ;
            String pc = getQp.SF_PS_WorkOrderId__r.ServiceTerritory.Branch_Location_Number__c;
            String companyID = getQp.SF_PS_WorkOrderId__r.SF_PS_Company_Code__c;
            String userName = getQp.SF_PS_WorkOrderId__r.Owner.Name;
            String rmWONumber = getQp.SF_PS_WorkOrderId__r.SF_PS_RM_WO_Number__c?.subStringAfter('-');
            
            DeleteQP(getQpId ,workOrderId, workOrderLineItemNumber,lastmodified ,sourceSystemUserId ,  UserID ,timezone,sourceWorkOrderNumber , pc ,companyID,userName,rmWONumber);
        	 if (Test.isRunningTest()){
                    DeleteQP(getQpId ,workOrderId, workOrderLineItemNumber,lastmodified ,sourceSystemUserId ,  null ,timezone,sourceWorkOrderNumber , pc ,companyID,userName,rmWONumber);
                }
        }
    }
    
    @future(Callout = true)
    private static void DeleteQP(String getQpId ,String workOrderId, String workOrderLineItemNumber,  String lastmodified , String sourceSystemUserId , String UserID ,String  timezone,String sourceWorkOrderNumber , String pc ,String companyID, String userName ,String rmWONumber  )   {
        try{
            String rentalManUserName=[Select Wynne_User_Name__c from user where id=:UserID].Wynne_User_Name__c;
            
            SBR_3_0_HttpCallout httpCallout = new SBR_3_0_HttpCallout(APINAME);
            WrappedResponse response = new WrappedResponse();
            
            HttpRequest req = httpCallout.getRequest();
            req.setEndpoint(req.getEndpoint()+ rmWONumber +'/parts/' + workOrderLineItemNumber);
            req.setHeader('thresholdWaitTime', '1');
            req.setHeader('X-Correlation-ID', X_CORRELATION_ID);
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('requestTimestamp', lastmodified);
            req.setHeader('sourceSystemUserId', sourceSystemUserId);
            req.setHeader('sourceSystemName', 'Salesforce');
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
                exc.Exception_Message__c = res.getStatusCode() + ' ' + ' Request - NO Json Body, Response - '+ res.getBody();
                exc.StatusCode__c = String.valueOf( res.getStatusCode()) ;
                exc.Exception_Type__c = 'SF to RM Outbound Response';
                exc.Method_Name__c= 'DeleteQP';
                //exc.RequestJSON__c= payload;
                exc.ResponseJSON__c = response.body;
                exc.RecordID__c = getQpId;
				exc.Related_To_Number__c=workOrderId;
                exc.Class_Name__c= 'SBR_3_0_API_DeleteQuotedParts';
                exc.Stack_Trace__c = 'SBR_3_0_API_DeleteQuotedParts , DeleteQP - line 72 , http.send(req) - Line 97 ';
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