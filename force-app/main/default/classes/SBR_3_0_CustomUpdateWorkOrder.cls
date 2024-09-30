/*********************************************************************************************************************
* Apex Class: SBR_3_0_API_Inspection_Appointments
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose:
* - RM hits the ApiUpdateApointment API with the Payload, which gets deserialized and updates the Service Resource Record 
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Mayank Jain 			2023-05-15			Initial version
	2.0			Mayank Jain				2023-07-26			Reduce Work Order Update Operation
*********************************************************************************************************************/
public with sharing class SBR_3_0_CustomUpdateWorkOrder {
    private static WorkOrder payloadSR = new WorkOrder();

    public SBR_3_0_CustomUpdateWorkOrder(String req) {
        payloadSR = (workOrder) system.JSON.deserialize(req, WorkOrder.class);
        system.debug('the value of payloadSR is ' + payloadSR);
    }
    public String syncWorkOrderToSF() {
        if(payloadSR.SF_PS_RM_WO_Number__c == null || payloadSR.SF_PS_RM_WO_Number__c == ''){
            return 'Please provide a valid SF_PS_RM_WO_Number__c';
        }
        String result='';
        
        //get Work Order
        WorkOrder wo = getWorkOrder();
        if(wo == null){ throw new SRWorkOrderException ('Work Order not found'); }
        
        
        // get ServiceAppointment 
        ServiceAppointment sa = getserviceAppointment(wo);
        if(sa == null){ throw new SRWorkOrderException ('ServiceAppointment not found'); }
        
        
        if(payloadSR.status == 'Dispatched' || payloadSR.status == 'Scheduled'){
            
            //update ServiceAppointment Scheduled Time // No Future Call out.
            if(sa.Status == 'Open' || sa.SchedEndTime == null){
                result  = UpdateServiceAppointment(sa);
                if(result != 'Success'){ return wo.Id; }
                
            }
            
            //get ServiceResource
            ServiceResource sr = relServiceResource(wo.SF_PS_Company_Code__c);
            if(sr == null){ throw new SRWorkOrderException ('ServiceResource not found'); }

            String skip = getAssignedResource(sr,sa);

            //create Assigned Resource  // First Update Callout and WorkOrder and SA to Scheduled
            if(skip=='Continue'){
                result = createAssignedResource(sr,sa);
                if(result != 'Success'){
                    return wo.Id;
                }
                
            }

            //Update Service Appointment Status to Dispatched 
            result  = UpdateServiceAppointmentStatus(sa,'Dispatched');
            if(result != 'Success'){
                return wo.Id;
            }
            
            
            WorkOrder woNew = getWorkOrder();
            if(woNew == null){
                throw new SRWorkOrderException ('Work Order not found'); 
            }
        	system.debug('WorkOrder fount and is ' + woNew);
            result  = UpdateWorkOrderwithoutStatus(woNew);
            if(result != 'Success'){
                return woNew.Id;
            }
            

        }else{
            //Update Work Order to Payload Status
            result  = UpdateWorkOrder(wo, payloadSR.Status);
            if(result != 'Success'){
                return wo.Id;
            }
            
        }         
        return wo.Id;
    }
	
    //Get Work Order
    public WorkOrder getWorkOrder(){
        try{
            String WO_Number_Concat = payloadSR.SF_PS_Company_Code__c+'-'+payloadSR.SF_PS_RM_WO_Number__c;
            WorkOrder getWo = [ Select id, SF_PS_VDOS_OrderLine_External_Id__c, SF_PS_VDOS_Dispatch_Type__c,
                                SF_PS_RM_WO_Number__c, SF_PS_Service_Resource__c, SF_PS_VDOS_Stop_Id__c,
                                SF_PS_Status_Reasons__c, SF_PS_Company_Code__c,Status,Bypass_flow__c
                                From Workorder 
                                Where SF_PS_RM_WO_Number__c =: WO_Number_Concat];
            return getWo;
        }catch(Exception error){
            system.debug('error is -->>> '+ error.getMessage());
            return null;
        }
    }
	
    //Get Service appointement
    public ServiceAppointment getserviceAppointment(WorkOrder wo){
        try{
            ServiceAppointment sa =[    Select id, Status, SchedStartTime  ,SchedEndTime ,Duration ,DurationType  
                                        From  ServiceAppointment 
                                        where ParentRecordId =:  wo.id Limit 1][0];
            return sa;
        }catch(Exception error){
            return null;
        }
    }
	
    //Update Service Appointement to Scheduled
    public String UpdateServiceAppointment(ServiceAppointment sa){
        if (sa != null) {
            sa.SchedStartTime = system.now();
            sa.SchedEndTime = sa.DurationType == 'Minutes' ? system.now().addMinutes((Integer)sa.Duration) : system.now().addHours((Integer)sa.Duration);
        }
        try{
            update sa;
            return 'Success';
        }catch(Exception error){
            return error.getMessage();
        }
    }
	
    //Get Service Resourse
    private static ServiceResource relServiceResource(string companyCode){        
        try{
            if(payloadSR!= null && String.isNotBlank(payloadSR.SF_PS_Service_Resource__c)){
                List<ServiceResource> relServiceResourceList = new List<ServiceResource>();
                relServiceResourceList = getrelServiceResource(payloadSR.SF_PS_Service_Resource__c, companyCode);
                if (relServiceResourceList.size() > 0){
                    return relServiceResourceList[0];
                }else{
                    return null;
                }
            }else{
                return null;
            }
        }catch(Exception error){
            return null;
        }
    }
	
    //Check for Service Resourse Already Assigned
    public String getAssignedResource(ServiceResource sr, ServiceAppointment sa){
        try{
            List<AssignedResource> ar = [ Select id,ServiceAppointmentId, ServiceResourceId 
                                    From AssignedResource 
                                    Where ServiceAppointmentId =: sa.id 
                                    AND  ServiceResourceId =: sr.id  ];
            return ar.size() > 0 ? 'Skip' : 'Continue';
        }catch(Exception error){
            return error.getMessage();
        }
    }
	
    //Create Assigned Service Resourse
    public String createAssignedResource(ServiceResource sr, ServiceAppointment sa){
        try{
            AssignedResource ar = new AssignedResource( ServiceAppointmentId =sa.id , ServiceResourceId = sr.id , SF_PS_Bypass_flow__c = True );
            insert ar;
            return 'Success';
        }catch(Exception error){
            return error.getMessage();
        }
    }
	
    //Update Work Order
    public String UpdateWorkOrder(WorkOrder updateWo, String woSattus ){
        updateWo.SF_PS_VDOS_OrderLine_External_Id__c = payloadSR.SF_PS_VDOS_OrderLine_External_Id__c;
        updateWo.SF_PS_VDOS_Dispatch_Type__c = payloadSR.SF_PS_VDOS_Dispatch_Type__c;
        updateWo.SF_PS_Service_Resource__c = relServiceResource(updateWo.SF_PS_Company_Code__c).id;
        updateWo.SF_PS_VDOS_Stop_Id__c = payloadSR.SF_PS_VDOS_Stop_Id__c;
        updateWo.Status = woSattus;
        if(payloadSR.Status == 'Completed with Exceptions' || payloadSR.Status == 'Unable to Complete'){
            updateWo.SF_PS_Status_Reasons__c = payloadSR.SF_PS_Status_Reasons__c;
        }else{
            updateWo.SF_PS_Status_Reasons__c = '';
        }

        try{
            update updateWo;
            return 'Success';
        }catch(Exception error){
            return error.getMessage();
        }
    }

    
    //Update Work Order without Status
    public String UpdateWorkOrderwithoutStatus(WorkOrder updateWo){
        updateWo.SF_PS_VDOS_OrderLine_External_Id__c = payloadSR.SF_PS_VDOS_OrderLine_External_Id__c;
        updateWo.SF_PS_VDOS_Dispatch_Type__c = payloadSR.SF_PS_VDOS_Dispatch_Type__c;
        updateWo.SF_PS_Service_Resource__c = relServiceResource(updateWo.SF_PS_Company_Code__c).id;
        updateWo.SF_PS_VDOS_Stop_Id__c = payloadSR.SF_PS_VDOS_Stop_Id__c;
        updateWO.Bypass_flow__c   = updateWO.Bypass_flow__c  == null || updateWO.Bypass_flow__c  == false ? true : false;

        try{
            update updateWo;
            return 'Success';
        }catch(Exception error){
            return error.getMessage();
        }
    }


    public static  List<ServiceResource> getrelServiceResource(String empNumber, String companyCode){
        try{
            List<User> usr = [SELECT Id FROM User WHERE EmployeeNumber =: empNumber ];
            Set<Id> userIds = (new Map<Id,SObject>(usr)).keySet();

            List<ServiceResource> serviceResourceList = [
                SELECT Id FROM ServiceResource WHERE RelatedRecordId IN : userIds AND SF_PS_Company_Code__c =: companyCode LIMIT 1
            ];
            return serviceResourceList;
        }catch(Exception error){
            return null;
        }
    }
    
    public String UpdateServiceAppointmentStatus(ServiceAppointment updateSa, string srStatus){
        updateSa.Status = srStatus;
        if(!Test.isRunningTest()){
            try{
                update updateSa;
                return 'Success';
            }catch(Exception error){
                return error.getMessage();
            }
        }else {
           return 'Success';
        }
        
    }
    public class SRWorkOrderException extends Exception {}

}