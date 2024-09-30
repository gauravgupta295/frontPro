/*********************************************************************************************************************
* Apex Class: SBR_3_0_UpdateTechnicianFeed
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose:
* - Controller Class for the SBR_3_0_API_Technician_Feed Class to Update the Service Resource matched with the combination of Company code and Mechanic id
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Mayank Jain 			2023-04-28			Initial version  
*********************************************************************************************************************/
public with sharing class SBR_3_0_UpdateTechnicianFeed {
    private static ServiceResource payloadSR = new ServiceResource();
    public static Map<String, Object> m = new Map<String, Object>();

    public SBR_3_0_UpdateTechnicianFeed(String req) {
        m = (Map<String, Object>) JSON.deserializeUntyped(req);
        payloadSR = (ServiceResource) system.JSON.deserialize(req, ServiceResource.class);
    }
    public String syncServiceResourceToSF() {
        if(m.get('SF_PS_Mechanic_Id__c') == null || m.get('SF_PS_Mechanic_Id__c') == ''){
            return 'Please provide a valid SF_PS_Mechanic_Id__c';
        }
        if(m.get('SF_PS_Company_Code__c') == null || m.get('SF_PS_Company_Code__c') == ''){
            return 'Please provide a valid SF_PS_Company_Code__c';
        }
        ServiceResource sr = getServiceResource();
        if(sr != null){
            system.debug('ServiceResource Found and is ' + sr);
            String result =  updateServiceRecource(sr);
            return result;
        }else{
            return 'Technician feed not found';
        }
    }

    public String updateServiceRecource(ServiceResource updateSR){
        updateSR.SF_PS_Hourly_Billing_Rate__c = payloadSR.SF_PS_Hourly_Billing_Rate__c;
        updateSR.SF_PS_Hourly_Internal_Rate__c = payloadSR.SF_PS_Hourly_Internal_Rate__c;
        updateSR.SF_PS_Overtime_Billing_Rate__c = payloadSR.SF_PS_Overtime_Billing_Rate__C;
        updateSR.SF_PS_Overtime_Internal_Rate__c = payloadSR.SF_PS_Overtime_Internal_Rate__c;
        updateSR.SF_PS_Labor_Type__c = payloadSR.SF_PS_Labor_Type__c;
        updateSR.SF_PS_Type__c = payloadSR.SF_PS_Type__c;
        updateSR.IsActive = payloadSR.IsActive;
        updateSR.SF_PS_Branch_Loc_Num__c = payloadSR.SF_PS_Branch_Loc_Num__c;
        updateSR.SF_PS_Comments__c = payloadSR.SF_PS_Comments__c;
        updateSR.SF_PS_RM_Created_DateTime__c = payloadSR.SF_PS_RM_Created_DateTime__c;
        updateSR.SF_PS_RM_Created_By__c = payloadSR.SF_PS_RM_Created_By__c;
        updateSR.SF_PS_RM_Update_DateTime__c = payloadSR.SF_PS_RM_Update_DateTime__c;
        updateSR.SF_PS_RM_Updated_By_User__c = payloadSR.SF_PS_RM_Updated_By_User__c;
        if(payloadSR.SF_PS_Start_Date__c != null){
        	updateSR.SF_PS_Start_Date__c = payloadSR.SF_PS_Start_Date__c;
        }

        try{
            update updateSR;
            return 'Success';
        }catch(Exception error){
            return error.getMessage();
        }
    }

    public ServiceResource getServiceResource(){
        try{
            List<ServiceResource> getSR = [   Select id, Name,SF_PS_Company_Code__c,SF_PS_Hourly_Billing_Rate__c,
                                        SF_PS_Hourly_Internal_Rate__c,SF_PS_Overtime_Billing_Rate__c,
                                        SF_PS_Overtime_Internal_Rate__c, SF_PS_Labor_Type__c,SF_PS_Type__c, IsActive ,
                                        SF_PS_Branch_Loc_Num__c,SF_PS_Comments__c, SF_PS_RM_Created_DateTime__c,
                                        SF_PS_RM_Created_By__c,SF_PS_RM_Update_DateTime__c,
                                        SF_PS_RM_Updated_By_User__c ,SF_PS_Mechanic_Id__c, SF_PS_Start_Date__c  
                                        From ServiceResource 
                                        WHERE SF_PS_Company_Code__c =:  payloadSR.SF_PS_Company_Code__c 
                                        AND SF_PS_Mechanic_Id__c =: payloadSR.SF_PS_Mechanic_Id__c  LIMIT 1];
            return getSR[0];
        }catch(Exception error){
            system.debug('error is -->>> '+ error.getMessage());
            return null;
        }
        
    }

}