/**
 * @description - The SBR_3_0_AccountRelationshipDA class provides methods to retrieve, create, and delete Account Relationship records.
 * Implements the SBR_3_0_AccountRelationshipDAInterface interface.
 */
public with sharing class SBR_3_0_AccountRelationshipDA implements SBR_3_0_AccountRelationshipDAInterface{
    /**
     * @description Returns a list of Account Relationship records for a given User ID.
     * @param ide -The User ID to retrieve Account Relationship records for.
     * @return  `List<Account_Relationship__c>` - A list of Account Relationship records.
     */
    public static List<Account_Relationship__c> getAccountRelsByUserId(Id ide) {
        return [SELECT Id, Account_ID__c, User_Account__c FROM Account_Relationship__c WHERE User_Account__c =: ide WITH SECURITY_ENFORCED ];
    }

    /**
     * @description - Returns a list of Account Relationship records for a given list of User IDs.
     * @param ids - The list of User IDs to retrieve Account Relationship records for.
     * @return  `List<Account_Relationship__c>` -  A list of Account Relationship records.
     */
    public static List<Account_Relationship__c> getAccountRelsByUserIds(List<Id> ids) {
        return [SELECT Id, Account_ID__c, User_Account__c, TTM__c, Rank__c FROM Account_Relationship__c WHERE User_Account__c in: ids WITH SECURITY_ENFORCED];
    }

    /**
     * @description - Returns a list of Account Relationship records for a given Account ID.
     * @param id The Account ID to retrieve Account Relationship records for.
     * @return  `List<Account_Relationship__c>` A list of Account Relationship records.
     */
    public static List<Account_Relationship__c> getAccountRelsByAccountId(Id id) {
        return [SELECT Id, Account_ID__c, Account_ID__r.Name, User_Account__c, User_Account__r.Name, Territory__c, Territory__r.Name, Type__c FROM Account_Relationship__c WHERE Account_Id__c =: id WITH SECURITY_ENFORCED];
    }

    /**
     * @description Creates a new Account Relationship record.
     * @param accountId  The Account ID to create the Account Relationship record for
     * @param userId The User ID to create the Account Relationship record for.
     * @return  `Account_Relationship__c` The newly created Account Relationship record.
     */
    @AuraEnabled
    public static Account_Relationship__c createAccountRelationship(Id accountId, Id userId) {
        Account_Relationship__c ar = new Account_Relationship__c(
                Name = 'Tracking - ' + userId + ' - ' + accountId,
                Account_Id__c = accountId,
                User_Account__c = userId,
                RecordTypeId = SBR_3_0_Constants.ACCOUNT_RELATIONSHIP_TRACKING_RT_ID,
                Type__c = 'Tracking');
        
        if(Schema.sObjectType.Account_Relationship__c.isCreateable()){
            //insert ar;
            ar = (Account_Relationship__c) SBR_3_0_WithoutSharingDML.insertRecord(ar);
        }
        return ar;
    }

    /**
     * @description Returns a list of tracked Account Relationship records for a given Account ID and User ID.
     * @param accountId The Account ID to retrieve tracked Account Relationship records for.
     * @param userId The User ID to retrieve tracked Account Relationship records for.
     * @return  `List<Account_Relationship__c>` A list of tracked Account Relationship records.
     */
    @AuraEnabled
    public static List<Account_Relationship__c> getTrackedAccountRelationships(Id accountId, Id userId) {
        return [SELECT ID FROM Account_Relationship__c WHERE Type__c = 'Tracking' AND User_Account__c =: userId AND Account_Id__c =: accountId WITH SECURITY_ENFORCED];
    }

    /**
     * @description Deletes tracked Account Relationship records for a given Account ID and User ID.
     * @param accountId The Account ID to delete tracked Account Relationship records for.
     * @param userId The User ID to delete tracked Account Relationship records for.
     */
    @AuraEnabled
    public static void deleteTrackedAccountRelationships(Id accountId, Id userId) {
        List<Account_Relationship__c> ars = [SELECT ID FROM Account_Relationship__c WHERE Type__c = 'Tracking' AND User_Account__c =: userId AND Account_Id__c =: accountId WITH SECURITY_ENFORCED];

        if(!ars.isEmpty() && Schema.sObjectType.Account_Relationship__c.isDeletable()) {
            delete ars;
        }
    }
}