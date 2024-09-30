/*********************************************************************************************************************
* Apex Class: SBR_3_0_UserDA
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Class for user Data Access
---------------------------------------------------------------------------------------------------------------------------------------
* History:
*********************************************************************************************************************/

public without sharing class SBR_3_0_UserDA implements  SBR_3_0_UserDAInterface {
    @AuraEnabled
    public static List<User> getOsrs(){
        List<PermissionSetAssignment> osrId = new List<PermissionSetAssignment>();
        osrId = [SELECT  AssigneeId FROM PermissionSetAssignment WHERE PermissionSet.Name  = 'OSR'];
        Set<Id> userIds = new Set<Id>();
        for(PermissionSetAssignment perms : osrId){
            userIds.add(perms.AssigneeId);
        }
        List<user> listOfOsr = [SELECT Id, Name, RepID__c, Rep_Type__c FROM User WHERE Id IN :userIds];
        return listOfOsr;  
    }

    public static List<User> getUsersBySalesRepIds(Set<String> repIds){
        List<User> users = [SELECT Id, RepID__c FROM User WHERE RepID__c IN :repIds];
        return users != null ? users : new List<User>();
    }
    
        public static List<User> getUsersByWynneUserNames(Set<String> wynneUserNames){
        List<User> users = [SELECT Id, Wynne_User_Name__c, Name FROM User WHERE Wynne_User_Name__c IN :wynneUserNames];
        return users != null ? users : new List<User>();
    }

    @AuraEnabled
    public static User getUserById(Id userId) {
        return [SELECT ID, FirstName, LastName, Name, ProfileId,TimeZoneSidKey, profile.Name, Tech_Rep_Type__c, UserRole.Name, CompanyName, Branch__c, Department, Rep_Type__c, Analysis_Region_Key__c, Wynne_User_Name__c FROM User WHERE Id =: userId];
    }
    
    public static User getUserContactInfoById(Id userId) {
        return [SELECT ID, Phone, Email, Rep_Type__c, RepID__c FROM User WHERE Id =: userId LIMIT 1];
    }

    public static List<User> getUsersByIds(List<String> userIds) {
        return [SELECT ID, Phone, Email, Rep_Type__c, RepID__c FROM User WHERE Id in: userIds];
    }

    public static User getUserInfoByIdForMyProflie(Id userId) {
        return [
            SELECT 
                Id, Email, Username, Communitynickname, Timezonesidkey, Languagelocalekey, 
                Firstname, Lastname, Phone, Title, Street, City, Country, Postalcode, State, 
                Localesidkey, Mobilephone, Extension, Fax, Contact.email
            FROM 
                User
            WHERE 
                Id = :userId ];
    }

    public static Map<Id, User> getUsers(Set<Id> userIds){
        return new Map<Id, User>([SELECT ID, Name, Analysis_Region_Key__c, ManagerId, Manager.Name, Manager.Email, Last_Re_rank_Date__c FROM User WHERE Id IN: userIds]);
    }

    public static Map<String, User> getUserMapBySalesRepIds(Set<String> repIds) {
        Map<String, User> users = new Map<String, User>();
        for(User u: [SELECT Id, RepID__c FROM User WHERE RepID__c IN :repIds]) {
            users.put(u.RepID__c, u);
        }
        return users;
    }

    public static Map<String, User> getUsersByRMUserName(Set<String> rmNames) {
        Map<String, User> users = new Map<String, User>();
        for(User u: [SELECT Id, Wynne_User_Name__c FROM User WHERE Wynne_User_Name__c IN :rmNames]) {
            users.put(u.Wynne_User_Name__c, u);
        }
        return users;
    }

    //23563
    public static Map<String, String> getUserRepIdMapByIds(Set<String> userIds) {
        Map<String, String> users = new Map<String, String>();
        for(User u: [SELECT Id, RepID__c FROM User WHERE Id IN :userIds]) {
            users.put(u.Id, u.RepID__c);
        }
        return users;
    }

    @AuraEnabled
    public static Boolean isFirstTimeLogin(Id userId) {
        List<LoginHistory> history = [SELECT Id FROM LoginHistory WHERE UserId =: userId LIMIT 2];
        if(history.size() > 1) {
            return false;
        } else {
            return true;
        }
    }
}