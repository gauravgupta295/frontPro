/*********************************************************************************************************************
* Apex Class: SBR_3_0_UserDeactivationBatchable
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Class invoked on User deactivation to inactivate or revert Account Relationships to the Territory Rep

---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME                        DATE                DETAIL FEATURES
    1.0         Philippe Bilodeau                     2023-04-03             Initial version 
*********************************************************************************************************************/
public class SBR_3_0_UserDeactivationBatchable implements Database.Batchable<sObject>, Database.Stateful
{
    private List<Id> userIds;
    Map<Id,List<Account_Relationship__c>> repToARMap;
    Map<Id, User> userIdToUserMap;
    
    public SBR_3_0_UserDeactivationBatchable(List<Id> userIds)
    {
        this.userIds = userIds;
    }
    
    public Database.QueryLocator start(Database.BatchableContext BC) 
    {
        String query = 'SELECT Id, Name, Account_ID__c, Account_ID__r.Name, Account_ID__r.RM_Account_Number__c, Territory__c, Territory__r.OwnerId, Type__c, Inactive__c, User_Account__c FROM Account_Relationship__c where User_Account__c in :userIds';
        return Database.getQueryLocator(query);
    }
    public void execute(Database.BatchableContext BC, List<Account_Relationship__c> arList) 
    {
        List<Account_Relationship__c> arToUpdate = new List<Account_Relationship__c>();
        List<Account_Relationship__c> arToDelete = new List<Account_Relationship__c>();
        repToARMap = new Map<Id,List<Account_Relationship__c>>();
        for (Account_Relationship__c ar : arList)
        {
            repToARMap.put(ar.User_Account__c, null);
        }
        
        userIdToUserMap = SBR_3_0_UserDA.getUsers(repToARMap.keySet());
        
        for (Account_Relationship__c ar : arList)
        {
            List<Account_Relationship__c> repARList = (repToARMap.get(ar.User_Account__c) == null ? new List<Account_Relationship__c>() : repToARMap.get(ar.User_Account__c));
            repARList.add(ar);
            repToARMap.put(ar.User_Account__c, repARList);
            
            if (ar.Territory__c == null || ar.Territory__r.OwnerId == ar.User_Account__c)
            {
                //ar.Inactive__c = true;
                arToDelete.add(ar);
            }
            else
            {
                if (userIdToUserMap.get(ar.User_Account__c).Analysis_Region_Key__c == '920')
                {
                    ar.Type__c = 'Assigned';
                }
                else
                {
                    ar.Type__c = 'Territory';
                }
                ar.User_Account__c = ar.Territory__r.OwnerId;
            }
            
            arToUpdate.add(ar);
        }
        
        if (arToUpdate.size() > 0)
        {
            update arToUpdate;
        }
        
        if (arToDelete.size() > 0)
        {
            delete arToDelete;
        }
    }
    public void finish(Database.BatchableContext BC) 
    {
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        for (Id repId : repToARMap.keySet())
        {
            List<Account_Relationship__c> arList = repToARMap.get(repId);
            if (arList != null)
            {
                String plainTextAccountList = '';
                String htmlTableAccountList = '<table><th><td>RM Account Number</td><td>Account Name</td></th>';
                for (Account_Relationship__c ar : arList)
                {
                    plainTextAccountList = plainTextAccountList + ar.Account_ID__r.RM_Account_Number__c + ' - ' + ar.Account_ID__r.Name + '\n\n';
                    htmlTableAccountList = htmlTableAccountList + '<tr><td>' + ar.Account_ID__r.RM_Account_Number__c + '</td><td>' + ar.Account_ID__r.Name + '</td></tr>';
                }
                htmlTableAccountList = htmlTableAccountList + '</table>';
                
                User rep = userIdToUserMap.get(repId);
                
                System.debug('repId = ' + repId);
                for (Id strId : userIdToUserMap.keySet())
                {
                    System.debug('strId = ' + strId);
                }
                
                if (rep != null && rep.ManagerId != null && rep.Manager.Email != null)
                {
                    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                    String[] toAddresses = new String[] {rep.Manager.Email}; 
                    mail.setToAddresses(toAddresses);
                    mail.setSubject('Rep Deactivated: ' + rep.Name);
                    mail.setBccSender(false);
                    mail.setUseSignature(false);
                    String plainTextBody = 'Dear ' + rep.Manager.Name + ',\n\n Please note that ' + rep.Name +'\'s Salesforce account has ' +
                    'been deactivated and their Account Relationship records have been inactivated or reverted to the territory rep.\n\n' +
                    'Here is a list of affected accounts:\n\n' + plainTextAccountList;
                    mail.setPlainTextBody(plainTextBody);
                    String htmlBody = '<p>Dear ' + rep.Manager.Name + ',</p><p>Please note that ' + rep.Name +'\'s Salesforce account has ' +
                    'been deactivated and their Account Relationship records have been inactivated or reverted to the territory rep.</p>' +
                    'Here is a list of affected accounts:</p>' + htmlTableAccountList;
                    mail.setHtmlBody(htmlBody);
                    
                    mails.add(mail);
                }
            }
        }
        if (mails.size() > 0)
        {
            Messaging.sendEmail(mails);
        }
    }
}