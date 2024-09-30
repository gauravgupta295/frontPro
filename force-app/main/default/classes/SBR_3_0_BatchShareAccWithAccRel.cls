/*********************************************************************************************************************
* Apex Class: SBR_3_0_BatchShareAccWithAccRel
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose:
* - Get List of Account Relationships
* - Insert an Account Share record for the Sales Reps on the Account relationships.
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME                        DATE                DETAIL FEATURES
    1.0         Amy                             2023-11-17             Initial version 
*********************************************************************************************************************/
public class SBR_3_0_BatchShareAccWithAccRel implements Database.Batchable<sObject>{

   public Database.QueryLocator start(Database.BatchableContext bc){
        return Database.getQueryLocator([SELECT Id, User_Account__c, Account_ID__c, User_Account__r.IsActive
                                         FROM Account_Relationship__c 
                                         WHERE User_Account__c != null 
                                         AND Account_ID__c != null
                                         AND User_Account__r.IsActive = true]);
   }

   public void execute(Database.BatchableContext bc, List<Account_Relationship__c> scope){
        List<AccountShare> shareList = new List<AccountShare>();
        for(Account_Relationship__c s : scope){
            AccountShare shareRec = new AccountShare();
            shareRec.AccountId = s.Account_ID__c;
            shareRec.AccountAccessLevel = 'Edit';
            shareRec.CaseAccessLevel = 'Read';
            shareRec.ContactAccessLevel = 'Read';
            shareRec.OpportunityAccessLevel = 'Read';
            shareRec.RowCause = 'ObligationAssigneeShare';
            shareRec.UserOrGroupId = s.User_Account__c;
            shareList.add(shareRec);
        }
        try{
            insert shareList;
        }
        catch(Exception e){
            SBR_3_0_LogException.LogIt(e, bc.getJobId());
        }
    }

   public void finish(Database.BatchableContext bc){
   }
}