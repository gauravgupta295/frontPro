/*********************************************************************************************************************
* Apex Class: SBR_3_0_API_DeleteWorkOrder
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Send WorkOrder to Rentalman (via Mulesoft) when it is Status changes to Cancelled or Closed in Salesforce
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
1.0         Harry Rokad          2023-05-15             Initial version 
2.0         Arsh Chhabra         2023-12-05             Added Delete Quote  
*********************************************************************************************************************/

public with sharing class SBR_3_0_API_DeleteWorkOrder {
    
    private static final String APINAME = 'API_WorkOrder_Insert';
    private static final String X_CORRELATION_ID = SBR_3_0_Generic.generateRandomString(10);
    private static String companyId;
    private static String payload;

    @InvocableMethod(Label = 'DeleteWorkOrderRMCallout')
    public static void DeleteWorkOrderRMCallout(List<String> input) {
        // Set<String> workOrdersInput = new Set<String>(input);
        // List<WorkOrder> woToSend = SBR_3_0_WorkOrderDA.getWorkOrders(workOrdersInput);
        
        if (!input.isEmpty() && !System.isFuture() && !System.isBatch()) {
            // WorkOrder workOrder = woToSend[0];
            // generateWrapper(workOrder);
            deleteWorkOrder(input);
            // handleWOResponse(workOrder);
        }
    }
    
    @future(Callout = true)
    private static void deleteWorkOrder(List<String> woId) {
        try{
            
            Set<String> woIdSet = new Set<String>(woId);
            WorkOrder getWo = SBR_3_0_WorkOrderDA.getWorkOrders(woIdSet)[0];
            
            if(getWo != null){
                companyId = getWo.SF_PS_Company_Code__c;
                deleteWOPayload dWo = new deleteWOPayload();
                dWO.status = getWo.Status;
                payload = JSON.serialize(dWo).replace('null', '""');
                String rentalManUserName=[Select Wynne_User_Name__c from user where id=:getWo.OwnerId].Wynne_User_Name__c;
                SBR_3_0_HttpCallout httpCallout = new SBR_3_0_HttpCallout(APINAME);
                HttpRequest req = httpCallout.getRequest();
                req.setMethod('DELETE');
                req.setHeader('thresholdWaitTime', '1');
                req.setHeader('X-Correlation-ID', X_CORRELATION_ID);
                req.setHeader('Content-Type', 'application/pdf');
                if(getWo.SF_PS_Record_Type__c =='Quote'){
                    req.setEndpoint(req.getEndpoint()+'/quotes/'+getWo.SF_PS_RM_WO_Number__c); 
                }else{
                    req.setEndpoint(req.getEndpoint()+'/'+getWo.SF_PS_RM_WO_Number__c); 
                }
                req.setHeader('requestTimestamp', String.valueOf(system.now()));
                req.setHeader('sourceSystemUserId', getWo.CreatedBy.Name);
                req.setHeader('sourceSystemName', 'Salesforce');
                req.setHeader('rentalmanUserId', rentalManUserName);
                req.setHeader('requestTimeZone', getWo.ServiceTerritory.OperatingHours.TimeZone);
                req.setHeader('sourceWorkOrderNumber',getWo.WorkOrderNumber );
                req.setHeader('pc', getWo.ServiceTerritory.Branch_Location_Number__c);
                req.setHeader('companyId', companyId);  
                req.setTimeout(1000);
                req.setBody(payload);
                Http http = new Http();
                HTTPResponse res = http.send(req);
                String returnPayload = res.getBody();
                if(res.getStatusCode() == 200 || res.getStatus()== 'OK'){
                    system.debug('Delete Callout Successfull');
                }
                else{
                    Exception_Log__c exc = new Exception_Log__c();
                    exc.Exception_Message__c = res.getStatusCode() + ' ' +' Request -'+payload +' ' +' Response '+ returnPayload;
                    exc.Exception_Type__c = 'SF to RM Outbound Response';
                    exc.Method_Name__c= 'deleteWorkOrder';
                    //exc.Id = String.valueOf(getWo.id);
                    exc.Class_Name__c= 'SBR_3_0_API_DeleteWorkOrder';
                    insert exc;
                    system.debug ('Error Response code-> ' + res.getStatusCode() + ' Error Response message-> ' + returnPayload); // Do not remove this Debug log
                }
                //response = (WrappedResponse)JSON.deserialize(returnPayload, WrappedResponse.class); 
                //response = JSON.deserializeUntyped(returnPayload);
            }
        }catch(Exception error){
            SBR_3_0_LogException.LogIt(error);
            System.debug('Error Line -> ' + error.getStackTraceString()); 	// do not remove this debug log
            System.debug('Error Message -> ' + error.getMessage());			// do not remove this debug log   
        }
        
    }
    
    public class deleteWOPayload{
        public string status;
    }
    
}