/*********************************************************************************************************************
* Apex Class: SBR_3_0_ServiceResourceDA
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Concrete class for ServiceResource Access
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION       DATE               DETAIL FEATURES
    1.0          2023-02-23          Initial version        
*********************************************************************************************************************/

public with sharing class SBR_3_0_ServiceResourceDA  implements SBR_3_0_ServiceResourceDAInterface{

// Get Assigned Resource
@AuraEnabled(cacheable=true)
public static Id getServiceResourceIdFromWorkOrderId(Id workOderId){
  Id Idy;
  try{
  Id serviceAppointmentId=[select Id,ParentRecordId from ServiceAppointment where ParentRecordId= :workOderId limit 1].Id;
  Idy=[select Id ,ServiceResourceId from AssignedResource  where ServiceAppointmentId =:serviceAppointmentId limit 1 ].ServiceResourceId;
  }catch(exception e){
  }
      
  return  Idy;

}
    
    
// Get Assigned Resource comp code
@AuraEnabled(cacheable=true)
public static string getServiceResourceCodeFromWorkOrderId(Id workOderId){
  String code;
  try{
  Id serviceAppointmentId=[select Id,ParentRecordId from ServiceAppointment where ParentRecordId= :workOderId limit 1].Id;
  code=[select Id ,ServiceResourceId, ServiceResource.SF_PS_Company_Code__c from AssignedResource  where ServiceAppointmentId =:serviceAppointmentId limit 1 ].ServiceResource.SF_PS_Company_Code__c;
  }catch(exception e){
  }   
  return  code;

}

// Get Service Resource with Service Resource Id
@AuraEnabled
public static List<ServiceResource> getServiceResourceById(Id serviceResId){

  List<ServiceResource> serviceResRec = new List<ServiceResource>();
  serviceResRec=[select Id,SF_PS_Mechanic_Id__c,RelatedRecord.Email ,SF_PS_Company_Code__c, RelatedRecord.Phone,RelatedRecord.Username,SF_PS_Hourly_Internal_Rate__c,RelatedRecord.Wynne_User_Name__c,SF_PS_Labor_Type__c  from ServiceResource where Id=:serviceResId];
  return serviceResRec;
}

// Validat elogged in service resource permission set group
@AuraEnabled(cacheable=true)
public static Boolean validateLoggedInResourcePermissionSetGroup(Id userId,String psgApiName){
  Boolean isValid=false;
  PermissionSetAssignment psgAss= new PermissionSetAssignment();
  try{
    psgAss=[select Id,AssigneeId, Assignee.Name,PermissionSetGroup.DeveloperName from PermissionSetAssignment where PermissionSetGroup.DeveloperName =:psgApiName and AssigneeId=:userId];
    isValid=true;
  }catch(exception e){
      isValid=false; 
  }
  return  isValid;

}
    
// To get primary service terittory of Service resource
@AuraEnabled(cacheable=true) 
    public static  List<ServiceTerritoryMember> getServiceResourcePrimaryTerittory(Id usrId){
        //Id serviceTerittoryId;
        List<ServiceTerritoryMember> allStmForSr = new List<ServiceTerritoryMember>();
         
        try{
           allStmForSr=[select id,ServiceResource.RelatedRecord.Id, ServiceResource.RelatedRecord.Name ,TerritoryType,EffectiveStartDate,EffectiveEndDate,ServiceTerritoryId
                        from ServiceTerritoryMember where ServiceResource.RelatedRecordId =:usrId];
        }catch(exception e){
           allStmForSr=null;
        }
        
        System.debug('Test: '+allStmForSr);
        
        return allStmForSr;
        
    }  

// To get Equipment Alerts form Due for service
@AuraEnabled
    public static List<DueForService__c> getEquipmentAlerts(Id assetId){
        Id serviceTerittoryId;
        List<DueForService__c> equipmentAlerts;
        try{
          string companyCode=[select Id,SM_PS_Company_Code__c from asset where id=:assetId].SM_PS_Company_Code__c;
          equipmentAlerts=[select Id,SM_PS_Equipment_Number__c,SM_PS_Step_Description__c from DueForService__c where SM_PS_Equipment_Number__c=:assetId and SM_PS_Company_Code__c=:companyCode and SM_PS_Completed__c=false order by SM_PS_Step_Number__c];
        }catch(exception e){
          equipmentAlerts=null;
        }
        
        return equipmentAlerts;
        
    }
    
}