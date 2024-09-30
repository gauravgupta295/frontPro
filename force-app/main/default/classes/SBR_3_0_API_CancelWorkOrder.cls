/*********************************************************************************************************************
* Apex Class: SBR_3_0_API_CancelWorkOrder
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Send WorkOrder to Rentalman (via Mulesoft) when it is Status changes to Cancelled in Salesforce
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Harry Rokad             2023-05-15          Initial version
    2.0         Piyush Jindal           2024-07-01          1. Removed the logic where 'v1' endpoint is replaced with 'v2'.
                                                            This is done to avoid the hardcoding of the endpoint i.e the API version.
                                                            2. Code Cleanup - Removed unnecessary debugs, extra spaces and line breaks
*********************************************************************************************************************/

public with sharing class SBR_3_0_API_CancelWorkOrder {
    
    private static final String APINAME = 'API_WorkOrder_Insert';
    private static final String X_CORRELATION_ID = SBR_3_0_Generic.generateRandomString(10);
    private static String companyId;

    @InvocableMethod(Label = 'CancelWorkOrderRMCallout')
    public static void CancelWorkOrderRMCallout(List<String> input) {
        if (!input.isEmpty() && !System.isFuture() && !System.isBatch()) {
            cancelWorkOrder(input);
        }
    }
    
    @future(Callout = true)
    private static void cancelWorkOrder(List<String> woId) {
        Set<String> woIdSet = new Set<String>(woId);
        WorkOrder getWo = SBR_3_0_WorkOrderDA.getWorkOrders(woIdSet)[0];

        if(getWo != null){
            companyId = getWo.SF_PS_Company_Code__c;
            String rentalManUserName=[Select Wynne_User_Name__c from user where id=:getWo.OwnerId].Wynne_User_Name__c;
            SBR_3_0_HttpCallout httpCallout = new SBR_3_0_HttpCallout(APINAME);
            
            HttpRequest req = httpCallout.getRequest();
            req.setMethod('PATCH');
            req.setHeader('thresholdWaitTime', '1');
            req.setHeader('X-Correlation-ID', X_CORRELATION_ID);
            req.setHeader('Content-Type', 'application/pdf');

            String workOrderRMNumber = getWo.SF_PS_RM_WO_Number__c;
            String woNumber = workOrderRMNumber.subStringAfter('-');          
            
            if(getWo.SF_PS_Record_Type__c == 'Quote'){ 
                req.setEndpoint(req.getEndpoint() + 'quotes/'+woNumber); 
            } else{
                req.setEndpoint(req.getEndpoint() + woNumber);
            }
	        
            req.setHeader('requestTimestamp', String.valueOf(getWo.LastModifiedDate.format('yyyy-MM-dd\'T\'HH:mm:ss.SSSSSS\'Z\'')));
            req.setHeader('sourceSystemUserId', getWo.CreatedBy.alias);
            req.setHeader('sourceSystemName', 'Salesforce');
            req.setHeader('rentalmanUserId', rentalManUserName);
            req.setHeader('requestTimeZone', getWo.ServiceTerritory.OperatingHours.TimeZone);
            req.setHeader('sourceWorkOrderNumber',getWo.WorkOrderNumber );
            req.setHeader('pc', getWo.ServiceTerritory.Branch_Location_Number__c);
            req.setHeader('companyId', companyId);  
            req.setTimeout(20000);
            
            Http http = new Http();
            HTTPResponse res = http.send(req);
            String returnPayload = res.getBody();

            if (res.getStatusCode() == 200 || res.getStatus()== 'OK'){
                system.debug('Cancel WO callout successfull');  //Do not remove
                
                //Set Create Claim field to TRUE.
                WorkOrder woToUpdate = new WorkOrder();
                woToUpdate.Id = getWo.Id;
                woToUpdate.SF_PS_Create_Claim__c = true;

                update woToUpdate;
            } else {
                ErrorWrap responseError = (ErrorWrap)JSON.deserialize(returnPayload,ErrorWrap.class);
                getWo.Status = 'Cancel with Exception';
                getWo.SF_PS_Cancel_Closed_Error_Msg__c = responseError.error.message;
                getWo.SF_PS_Cancel_Closed_Error_Msg_Code__c = responseError.error.errorCode;
                update getWo;

                system.debug ('Cancel WO callout not successfull Updated Status to - Cancel with Exception');
            }   
        }   
    }
    
    public class ErrorWrap {
        public ErrorMsgWrap error;
    }
    
    public class ErrorMsgWrap {
        public String message;
        public String errorKey;
        public String errorCode;
    }
}