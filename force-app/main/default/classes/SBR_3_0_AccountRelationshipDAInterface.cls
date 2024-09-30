/*********************************************************************************************************************
* Apex Class: SBR_3_0_AccountRelationshipDAInterface
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Interface class for Account Relationship Data Access
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Konrad Haight           2022-08-13          Initial version    
*********************************************************************************************************************/
public interface SBR_3_0_AccountRelationshipDAInterface {
   List<Account_Relationship__c> getAccountRelsByUserId(Id ide);
   List<Account_Relationship__c> getAccountRelsByUserIds(List<Id> ids);
   List<Account_Relationship__c> getAccountRelsByAccountId(Id id);
   Account_Relationship__c createAccountRelationship(Id accountId, Id userId);
   List<Account_Relationship__c> getTrackedAccountRelationships(Id accountId, Id userId);
   void deleteTrackedAccountRelationships(Id accountId, Id userId);
}