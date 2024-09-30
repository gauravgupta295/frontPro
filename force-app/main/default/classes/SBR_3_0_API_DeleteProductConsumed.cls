/*********************************************************************************************************************
* Apex Class: SBR_3_0_API_DeleteProductConsumed
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Send Callout(Outbound) from Salesforce to Rentalman (via Mulesoft) when Product Consumed is deleted in Salesforce
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Mayank Jain          2023-04-07             Initial version   
    2.0         Mayank Jain        	 2023-10-10             Updated code for the code cverage
*********************************************************************************************************************/
public with sharing class SBR_3_0_API_DeleteProductConsumed {
    private static final String APINAME = 'Delete_Product_Consumed_API';
    private static final String X_CORRELATION_ID = SBR_3_0_Generic.generateRandomString(10);
        
    @InvocableMethod(Label = 'DeleteProductConsumedRMCallout')
    public static void DeletePcRMCallout(List<String> input) {
  
        if (!input.isEmpty()&& !System.isFuture() && !System.isBatch()) {
            ProductConsumed getPc = [SELECT Id, SF_PS_Parts_Line_Num__c, SF_PS_Stock_Class__c, SF_PS_Quantity__c, SF_PS_Unit_Of_Measure__c, SF_PS_Selling_Price__c,
                                     SF_PS_Cost_Price__c, SF_PS_Line_Level_Comment__c,SF_PS_Labor_Code__c , LastModifiedDate,WorkOrder.Owner.alias,
                                     WorkOrder.Owner.Name, WorkOrder.OwnerId , WorkOrder.ServiceTerritory.OperatingHours.TimeZone , WorkOrder.WorkOrderNumber,
                                     workOrder.ServiceTerritory.Branch_Location_Number__c , WorkOrder.SF_PS_Company_Code__c , WorkOrder.SF_PS_RM_WO_Number__c, WorkOrderId, SF_PS_RM_External_Id__c
                                     FROM ProductConsumed WHERE Id=: input[0] ];
            if(getPc == null){
                return;
            }

            String workOrderId =  getPc.WorkOrderId;
            String workOrderLineItemNumber = getPc.SF_PS_Parts_Line_Num__c;
            String lastmodified  = String.valueOf(getPc.LastModifiedDate.format('yyyy-MM-dd\'T\'HH:mm:ss.SSSSSS\'Z\''));
            String sourceSystemUserId = getPc.WorkOrder.Owner.alias;
            String UserID = getPc.WorkOrder.OwnerId;
            String timezone  = getPc.WorkOrder.ServiceTerritory.OperatingHours.TimeZone;
            String sourceWorkOrderNumber = getPc.WorkOrder.WorkOrderNumber ;
            String pc = getPc.workOrder.ServiceTerritory.Branch_Location_Number__c;
            String companyID = getPc.WorkOrder.SF_PS_Company_Code__c;
            String userName = getPc.WorkOrder.Owner.Name;
            String rmWONumber = getPc.WorkOrder.SF_PS_RM_WO_Number__c?.subStringAfter('-');
            
            DeletePC(workOrderId, workOrderLineItemNumber,lastmodified ,sourceSystemUserId ,  UserID ,timezone,sourceWorkOrderNumber , pc ,companyID,userName,rmWONumber);
        }
    }
    
    @future(Callout = true)
    private static void DeletePC(String workOrderId, String workOrderLineItemNumber,  String lastmodified , String sourceSystemUserId , String UserID ,String  timezone,String sourceWorkOrderNumber , String pc ,String companyID, String userName ,String rmWONumber  )   {
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
        }
        else{
            Exception_Log__c exc = new Exception_Log__c();
            exc.Exception_Message__c = res.getStatusCode() + ' ' +' Response '+res.getBody();
            exc.Exception_Type__c = 'SF to RM Outbound Response';
            exc.Method_Name__c= 'DeletePC';
            exc.Class_Name__c= 'SBR_3_0_API_DeleteProductConsumed';
            insert exc;
            System.debug ('Error Response code-> ' + res.getStatusCode() + ' Error Response message-> ' + res.getBody()); // Do not remove this Debug log                
        }
    }catch(Exception error){
        SBR_3_0_LogException.LogIt(error);
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