/*********************************************************************************************************************
* Apex Class: SBR_3_0_API_CloseWorkOrder
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Send WorkOrder to Rentalman (via Mulesoft) when it is Status changes to Closed in Salesforce
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Harry Rokad             2023-06-12          Initial version
    2.0         Piyush Jindal           2024-07-01          Removed some debugs and commented lines of code.
*********************************************************************************************************************/

public with sharing class SBR_3_0_API_CloseWorkOrder {
    
    private static final String APINAME = 'API_WorkOrder_Update';
    private static final String X_CORRELATION_ID = SBR_3_0_Generic.generateRandomString(10);
    private static String companyId;

    @InvocableMethod(Label = 'CloseWorkOrderRMCallout')
    public static void CloseWorkOrderRMCallout(List<String> input) {
        if (!input.isEmpty() && !System.isFuture() && !System.isBatch()) {
            closeWorkOrder(input);
        }
    }
    
    @future(Callout = true)
    private static void closeWorkOrder(List<String> woId) {
        try{                    
            Set<String> woIdSet = new Set<String>(woId);
            WorkOrder getWo = SBR_3_0_WorkOrderDA.getWorkOrders(woIdSet)[0];
            
            if(getWo != null) {
                companyId = getWo.SF_PS_Company_Code__c;
                WorkOrderList wol = new WorkOrderList();
                CloseWoPayload dWo = new CloseWoPayload();
                dWO.status = getWo.Status;
                dWo.closedDate= getWo.SF_PS_Closed_Date__c == null ? '' : String.valueof(getWo.SF_PS_Closed_Date__c);
                dWo.currentMiHr = getWo.SF_PS_Current_MiHr__c == null ? 0.0 : getWo.SF_PS_Current_MiHr__c;
                dWo.externalComments = getWo.SF_PS_Labor_Des_Comments__c;
                dWo.putInShop = getWo.SF_PS_Put_Into_Shop__c;
                dWo.makeAvailable = getWo.SF_PS_Make_Available__c;
                wol.workOrder.add(dWo);
                
                String payload = JSON.serialize(wol).replace('null', '""');
                String rentalManUserName = [SELECT Wynne_User_Name__c 
                                            FROM user where Id =:getWo.OwnerId].Wynne_User_Name__c;
                SBR_3_0_HttpCallout httpCallout = new SBR_3_0_HttpCallout(APINAME);
                String rmWorkOrderNumber = getWo.SF_PS_RM_WO_Number__c;
                String woNumber = rmWorkOrderNumber.subStringAfter('-');

                HttpRequest req = httpCallout.getRequest();
                req.setEndpoint(req.getEndpoint() + woNumber);
                req.setHeader('X-Correlation-ID', X_CORRELATION_ID);
                req.setHeader('Content-Type', 'application/json');  
                req.setHeader('requestTimestamp', String.valueOf(getWo.LastModifiedDate.format('yyyy-MM-dd\'T\'HH:mm:ss.SSSSSS\'Z\'')));
                req.setHeader('sourceSystemUserId', getWo.CreatedBy.alias);
                req.setHeader('sourceSystemName', 'Salesforce');
                req.setHeader('rentalmanUserId', rentalManUserName);
                req.setHeader('requestTimeZone', getWo.ServiceTerritory.OperatingHours.TimeZone);
                req.setHeader('sourceWorkOrderNumber',getWo.WorkOrderNumber );
                req.setHeader('pc', getWo.ServiceTerritory.Branch_Location_Number__c);
                req.setHeader('companyId', companyId);  
                req.setTimeout(20000);
                req.setBody(payload);

                system.debug('Payload '+payload);// do not remove
                
                Http http = new Http();
                HTTPResponse res = http.send(req);
                String returnPayload = res.getBody();
                
                system.debug('returnPayload+'+ returnPayload);// do not remove

                if (res.getStatusCode() == 200 || res.getStatus()== 'OK'){
                    system.debug('Close WO callout successfull');
                    //Set Create Claim field to TRUE.
                    WorkOrder woToUpdate = new WorkOrder();
                    woToUpdate.Id = getWo.Id;
                    woToUpdate.SF_PS_Create_Claim__c = true;
                    update woToUpdate;
                } else {
                    ErrorWrap responseError = (ErrorWrap)JSON.deserialize(returnPayload,ErrorWrap.class);
                    getWo.Status = 'Closed with Exception';
                    getWo.SF_PS_Cancel_Closed_Error_Msg__c = responseError.error.message;
                    getWo.SF_PS_Cancel_Closed_Error_Msg_Code__c = responseError.error.errorCode;
                    update getWo;
                    system.debug ('Close WO callout not successfull Updated Status to - Closed with Exception'); // do no remove
                }
            }
        }catch(Exception error){
            SBR_3_0_LogException.LogIt(error);
            system.debug('Error Line -> ' + error.getStackTraceString()); 	// do not remove this debug log
            system.debug('Error Message -> ' + error.getMessage());			// do not remove this debug log         
        }        
    }
    
    //Payload Body Wrapper Class List
    public class WorkOrderList {
        public List<CloseWoPayload> workOrder = new List<CloseWoPayload>();
    }

    //Payload Body Wrapper Class 
    public class CloseWoPayload{
        public string status;
        public string closedDate;
        public Decimal currentMiHr;
        public string externalComments;
        public string putInShop;
        public string makeAvailable;
    }

	//Response Error Wrapper Class 
    public class ErrorWrap {
        public ErrorMsgWrap error;
    }
 
	//Response Error Wrapper helper Class
    public class ErrorMsgWrap {
        public String message;
        public String errorKey;
        public String errorCode;
    }
}