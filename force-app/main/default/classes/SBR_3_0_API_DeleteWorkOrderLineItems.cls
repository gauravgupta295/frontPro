/*********************************************************************************************************************
* Apex Class: SBR_3_0_API_DeleteWorkOrderLineItems
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Send Callout(Outbound) from Salesforce to Rentalman (via Mulesoft) when Work order line item is deleted in Salesforce
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Mayank Jain          2023-04-07             Initial version   
    2.0         Mayank Jain        	 2023-10-10             Updated code for the code cverage
*********************************************************************************************************************/
public with sharing class SBR_3_0_API_DeleteWorkOrderLineItems {
    private static final String APINAME = 'Delete_WorkOrder_Line_Item_API';
    private static final String X_CORRELATION_ID = SBR_3_0_Generic.generateRandomString(10);
        
    @InvocableMethod(Label = 'DeleteWorkOrderLineItemsRMCallout')
    public static void WorkOrderRMCallout(List<String> input) {
        if (!input.isEmpty()&& !System.isFuture() && !System.isBatch()) {
            WorkOrderLineItem getWoli = [SELECT Id, LastModifiedDate, WorkOrder.Owner.Name, WorkOrder.OwnerId,
                                         WorkOrder.SF_PS_Company_Code__c, WorkOrder.SF_PS_RM_WO_Number__c, WorkOrder.SF_PS_Service_Resource__r.SF_PS_Mechanic_Id__c, 
                                         Duration, SF_PS_Work_Order_Description__c, Description, SF_PS_RM_Item_Number__c,SF_PS_Labor_Code__c,SF_PS_Line_Type__c,SF_PS_RM_Labor_Line_Item_Number__c,
                                         SF_PS_Hourly_Internal_Rate__c, WorkOrder.ServiceTerritory.OperatingHours.TimeZone, WorkOrder.WorkOrderNumber,WorkOrder.Owner.alias, WorkOrder.Id,
                                         WorkOrder.ServiceTerritory.Branch_Location_Number__c,  SF_PS_RM_External_Id__c , SF_PS_RM_WO_Number__c, WorkOrderId
                                         FROM WorkOrderLineItem WHERE Id=: input[0] ];

            if(getWoli == null){
                return;
            }           
                String workOrderId = (!String.isBlank(getWoli.WorkOrderId)) ? getWoli.WorkOrderId : '';
                String workOrderLineItemNumber;
                if (!String.isBlank(getWoli.SF_PS_RM_Labor_Line_Item_Number__c)) {
                    workOrderLineItemNumber = getWoli.SF_PS_RM_Labor_Line_Item_Number__c;
                } else {
  					workOrderLineItemNumber = '';
                }
    
    
                String lastmodified = (!String.isBlank(String.valueOf(getWoli.LastModifiedDate))) ? String.valueOf(getWoli.LastModifiedDate.format('yyyy-MM-dd\'T\'HH:mm:ss.SSSSSS\'Z\'')) : '';
                String sourceSystemUserId = (!String.isBlank(getWoli.WorkOrder.Owner.alias)) ? getWoli.WorkOrder.Owner.alias : '';
                String UserID = (!String.isBlank(getWoli.WorkOrder.OwnerId)) ? getWoli.WorkOrder.OwnerId : '';
                String timezone = (!String.isBlank(getWoli.WorkOrder.ServiceTerritory.OperatingHours.TimeZone)) ? getWoli.WorkOrder.ServiceTerritory.OperatingHours.TimeZone : '';
                String sourceWorkOrderNumber = (!String.isBlank(getWoli.WorkOrder.WorkOrderNumber)) ? getWoli.WorkOrder.WorkOrderNumber : '';
                String pc;
                if (!String.isBlank(getWoli.WorkOrder.ServiceTerritory.Branch_Location_Number__c)) {
                    pc = getWoli.WorkOrder.ServiceTerritory.Branch_Location_Number__c;
                } else {
                    pc ='';
                }
    
                String companyID;
                if (!String.isBlank(getWoli.WorkOrder.SF_PS_Company_Code__c)) {
                    companyID = getWoli.WorkOrder.SF_PS_Company_Code__c;
                } else {
                    companyID = '';
                }
    
                String wiloType;
                if (!String.isBlank(getWoli.SF_PS_Line_Type__c)) {
                    wiloType = getWoli.SF_PS_Line_Type__c;
                } else {
					wiloType = '';                    
                }
                
                String userName = (!String.isBlank(getWoli.WorkOrder.Owner.Name)) ? getWoli.WorkOrder.Owner.Name : '';
    
                String rmWONumber;
                if (!String.isBlank(getWoli.SF_PS_RM_WO_Number__c)) {
                    rmWONumber = getWoli.SF_PS_RM_WO_Number__c.substringAfter('-');
                } else {
                    rmWONumber = '';
                }
                
                deletewoli(workOrderId, workOrderLineItemNumber,lastmodified ,sourceSystemUserId ,  UserID ,timezone,sourceWorkOrderNumber , pc ,companyID, wiloType,userName,rmWONumber);


            
        }
    }
    
    @future(Callout = true)
    private static void deletewoli(String workOrderId, String workOrderLineItemNumber,  String lastmodified , String sourceSystemUserId , String UserID ,String  timezone,String sourceWorkOrderNumber , String pc ,String companyID, String wiloType,  String userName ,String rmWONumber  )   {
        try{
            String rentalManUserName;
            User userRecord = [SELECT Wynne_User_Name__c FROM User WHERE Id = :UserID LIMIT 1];
            if (userRecord != null && userRecord.Wynne_User_Name__c != null) {
                rentalManUserName = userRecord.Wynne_User_Name__c;
            } else {
                rentalManUserName= '';
            }
            
            SBR_3_0_HttpCallout httpCallout = new SBR_3_0_HttpCallout(APINAME);
            WrappedResponse response = new WrappedResponse();
            
            HttpRequest req = httpCallout.getRequest();
            
            if(wiloType == 'MC' ){
                req.setEndpoint(req.getEndpoint()+ rmWONumber +'/mileageCharges/' + workOrderLineItemNumber);
            }else{
                req.setEndpoint(req.getEndpoint()+ rmWONumber +'/insideLabor/' + workOrderLineItemNumber);        
            }
            
            
            req.setHeader('thresholdWaitTime', '1');
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('sourceSystemName', 'SalesForce');
            
            req.setHeader('X-Correlation-ID', X_CORRELATION_ID);
            System.debug('>> X-Correlation-ID ' + req.getHeader('X-Correlation-ID'));
            
            req.setHeader('requestTimestamp', lastmodified);
            System.debug('>> requestTimestamp' + req.getHeader('requestTimestamp'));
            
            req.setHeader('sourceSystemUserId', sourceSystemUserId);
            System.debug('>> sourceSystemUserId ' + req.getHeader('sourceSystemUserId'));
            
            req.setHeader('rentalmanUserId', rentalManUserName);
            System.debug('>> rentalmanUserId ' + req.getHeader('rentalmanUserId'));
            
            req.setHeader('requestTimeZone', timezone);
            System.debug('>> requestTimeZone ' + req.getHeader('requestTimeZone'));
            
            req.setHeader('sourceWorkOrderNumber', sourceWorkOrderNumber );
            System.debug('>> sourceWorkOrderNumber ' + req.getHeader('sourceWorkOrderNumber'));
            
            req.setHeader('sourceReferenceLineNumber', workOrderId );
            System.debug('>> sourceReferenceLineNumber' + req.getHeader('sourceReferenceLineNumber'));
            
            req.setHeader('pc', pc);
            System.debug('>> pc ' + req.getHeader('pc'));
            
            req.setHeader('companyId', companyID);  
            System.debug('>> companyId ' + req.getHeader('companyId'));
            
            system.debug('request is '+ req);
            
            req.setTimeout(119000); 
            Http http = new Http();
            
            HTTPResponse res = http.send(req);
            
            response.headers = res.getHeaderKeys();
            response.body = res.getBody();
            
            system.debug('response.headers is ' + response.headers);
            system.debug('response.body is ' + response.body);
            system.debug('res.getStatusCode is ' + res.getStatusCode());
            
            if((res.getStatusCode() == 200 || res.getStatus()== 'OK')){
                response.status = 'Complete';
                system.debug('Delete successfull');
            }else{
                Exception_Log__c exc = new Exception_Log__c();
                exc.Exception_Message__c = res.getStatusCode() + ' ' +' Response '+ res.getBody();
                exc.Exception_Type__c = 'SF to RM Outbound Response';
                exc.Method_Name__c= 'deleteWorkOrderLineItems';
                //exc.Id = String.valueOf(getWo.id);
                exc.Class_Name__c= 'SBR_3_0_API_DeleteWorkOrderLineItems';
                insert exc;
                system.debug ('Error Response code-> ' + res.getStatusCode() + ' Error Response message-> ' + res.getBody()); // Do not remove this Debug log
            }
        
    }
    catch(Exception error){
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


  public class SBR_3_0_API_DeleteWorkOrderLineItemsException extends Exception {
  }
}