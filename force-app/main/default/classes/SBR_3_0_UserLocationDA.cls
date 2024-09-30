public with sharing class SBR_3_0_UserLocationDA implements SBR_3_0_UserLocationDAInterface{

    public static List<User_Location__c> getUserLocation(Id userId){
        return new List<User_Location__c>([SELECT Id, Branch__r.Branch_Location_Number__c, Branch__c, user__c, Analysis_Region_Key__c FROM User_Location__c WHERE User__c = :userId LIMIT 1]);
    }
    public static List<User_Location__c> getUserLocation(Set<Id> userIds){
        return new List<User_Location__c>([SELECT Id, Branch__r.Branch_Location_Number__c, Branch__c, user__c, Analysis_Region_Key__c FROM User_Location__c WHERE User__c IN: userIds]);
    }

    @AuraEnabled
    public static List<User_Location__c> getOsrs(){
        List<PermissionSetAssignment> osrId = new List<PermissionSetAssignment>();
        osrId = [SELECT  AssigneeId FROM PermissionSetAssignment WHERE PermissionSet.Name  = 'OSR'];
        Set<Id> userIds = new Set<Id>();
        for(PermissionSetAssignment perms : osrId){
            userIds.add(perms.AssigneeId);
        }
        List<User_Location__c> listOfOsr = [SELECT Id, User__r.Name, User__c, RepID__c, Rep_Type__c, Analysis_Region2__c, Analysis_Region2__r.Name FROM User_Location__c WHERE User__c IN :userIds];
        return listOfOsr;  
    }

    @AuraEnabled(cacheable=true)
    public static List<User_Location__c> getUserRecord(String userId) {
        return new List<User_Location__c>([SELECT Id, User__c FROM User_Location__c WHERE Id = :userId]);
    }
}