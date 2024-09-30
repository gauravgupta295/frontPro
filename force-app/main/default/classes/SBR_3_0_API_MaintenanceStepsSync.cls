/*********************************************************************************************************************
* Apex Class: SBR_3_0_API_MaintenanceStepsSync
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Class to sync completed maintenance steps on work order to rentalMan
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION       DATE           DETAIL FEATURES
1.0          2023-05-17          Initial version 
**********************************************************************************************************************************************/
public class SBR_3_0_API_MaintenanceStepsSync {
    private static final String APINAME = 'Send_Maintenance_Steps_Api';
    private static final String X_CORRELATION_ID = SBR_3_0_Generic.generateRandomString(10);
    //Getting data from flow     
    @InvocableMethod(Label='getMaintenanceStep')
    public static void getMaintenanceStep(List<String> input){
        syncMaintenanceStepsToRM(input.get(0));
    }    
    //Making callout to rentalMan Api
    @future(Callout=true)
    public static void syncMaintenanceStepsToRM(String id){
        try{
            SF_PS_Maintenance_Steps__c mst=[select LastModifiedDate,
                                            SF_PS_Work_Order__r.OwnerId,
                                            SF_PS_Work_Order__r.Owner.Name,
                                            SF_PS_Work_Order__r.SF_PS_Company_Code__c,
                                            SF_PS_Work_Order__r.SF_PS_RM_WO_Number__c,
                                            SF_PS_Work_Order__r.CreatedBy.Alias,
                                            SF_PS_Work_Order__r.ServiceTerritory.Branch_Location_Number__c,
                                            SF_PS_Work_Order__r.ServiceTerritory.OperatingHours.TimeZone,
                                            SF_PS_Work_Order__r.WorkOrderNumber,
                                            SF_PS_Work_Order__r.SF_PS_Service_Resource__r.SF_PS_Mechanic_Id__c, 
                                            SF_PS_RM_Mtce_Steps_StepNumber__c from SF_PS_Maintenance_Steps__c where id=:+id];           
            String rentalManUserName=[Select Wynne_User_Name__c from user where id=:mst.SF_PS_Work_Order__r.OwnerId].Wynne_User_Name__c;
            SBR_3_0_HttpCallout httpCallout = new SBR_3_0_HttpCallout(APINAME);
            WrappedResponse resp = new WrappedResponse();
            Http http=new Http();
            HttpRequest request=httpCallout.getRequest();
            String WO_num = mst.SF_PS_Work_Order__r.SF_PS_RM_WO_Number__c.subStringAfter('-');
            request.setEndpoint(request.getEndpoint()+WO_num+'/steps');
            request.setHeader('companyId', mst.SF_PS_Work_Order__r.SF_PS_Company_Code__c); 
            request.setHeader('sourceSystemUserId', mst.SF_PS_Work_Order__r.CreatedBy.Alias);
            request.setHeader('sourceSystemName', 'Salesforce');
            request.setHeader('rentalmanUserId', rentalManUserName);
            request.setHeader('pc', mst.SF_PS_Work_Order__r.ServiceTerritory.Branch_Location_Number__c);
            request.setHeader('sourceWorkOrderNumber', mst.SF_PS_Work_Order__r.WorkOrderNumber);
            request.setHeader('requestTimestamp', String.valueOf(mst.LastModifiedDate.format('yyyy-MM-dd\'T\'HH:mm:ss.SSSSSS\'Z\'')));
            request.setHeader('X-Correlation-ID', X_CORRELATION_ID);
            request.setHeader('Content-Type', 'application/json');       
            request.setHeader('requestTimeZone', mst.SF_PS_Work_Order__r.ServiceTerritory.OperatingHours.TimeZone);          
            SyncMaintenanceStepsWrapper requestBody=new SyncMaintenanceStepsWrapper();  
            cls_workOrder workOrder=new cls_workOrder();           
            cls_maintenanceSteps steps=new cls_maintenanceSteps();
            steps.stepNumber=mst.SF_PS_RM_Mtce_Steps_StepNumber__c !=null ? Integer.valueOf(mst.SF_PS_RM_Mtce_Steps_StepNumber__c):null;
            steps.mechanicId=mst.SF_PS_Work_Order__r.SF_PS_Service_Resource__r.SF_PS_Mechanic_Id__c;
            steps.sourceReferenceStepNumber = id;
            workOrder.maintenanceSteps.add(steps);
            requestBody.workOrder.add(workOrder);
            request.setBody(json.serialize(requestBody));
            HttpResponse response=http.send(request);
            System.debug('Endpoint '+request.getEndpoint());
            System.debug('companyId '+request.getHeader('companyId'));
            System.debug('sourceSystemUserId '+request.getHeader('sourceSystemUserId'));
            System.debug('sourceSystemName '+request.getHeader('sourceSystemName'));
            System.debug('rentalmanUserId '+request.getHeader('rentalmanUserId'));
            System.debug('pc '+request.getHeader('pc'));
            System.debug('sourceWorkOrderNumber '+request.getHeader('sourceWorkOrderNumber'));
            System.debug('requestTimestamp '+request.getHeader('requestTimestamp'));
            System.debug('X-Correlation-ID '+request.getHeader('X-Correlation-ID'));
            System.debug('Authorization '+request.getHeader('Authorization'));
            System.debug('cookie '+request.getHeader('cookie'));
            System.debug('RequestBody '+json.serialize(requestBody));
            System.debug('Response '+response.getBody());
            resp.headers = response.getHeaderKeys();
            resp.body = response.getBody();
            String returnPayload = response.getBody();
            if (!Test.isRunningTest()){
                resp = (WrappedResponse)JSON.deserialize(returnPayload, WrappedResponse.class);
                system.debug('response is'+resp);
                system.debug('response WO'+ resp.workOrderNumber);
                if (response.getStatusCode() == 200 || response.getStatus()== 'OK' ){
                    maintenanceSteps ExternalResp = resp.maintenanceSteps[0];
                    System.debug('ExternalResp is '+ ExternalResp);
                    mst.SF_PS_RM_External_Id__c = ExternalResp.uniqueId;
                    update mst;
                }
            }

        }catch(Exception e){
            System.debug(e);
            System.debug(e.getStackTraceString());
        }
    }   
    //Wrapper Classes for request and response    
    public class SyncMaintenanceStepsWrapper{
        public List<cls_workOrder> workOrder=new List<cls_workOrder>();       
    }
    class cls_workOrder {
        public List<cls_maintenanceSteps> maintenanceSteps=new List<cls_maintenanceSteps>();
    }
    class cls_maintenanceSteps {
        public Integer stepNumber;	//9999999
        public String mechanicId;	//string
        public String sourceReferenceStepNumber; 
    }
    public class WrappedResponse{
        public string workOrderNumber{get;set;}
        public string mode{get;set;} 
        public string message;
        public string body{get;set;}
        public string status{get;set;} 
        public list<String> headers{get;set;}
        public list<maintenanceSteps> maintenanceSteps{get;set;}
    }
    public class maintenanceSteps {
        public String uniqueId;
    }   
}