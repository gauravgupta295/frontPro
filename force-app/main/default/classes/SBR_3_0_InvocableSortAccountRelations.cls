public with sharing class SBR_3_0_InvocableSortAccountRelations implements Database.Batchable<sObject>, Database.Stateful {
    private List<Id> userIdList;
    private List<String> repNames;
    private String repLink;
    public SBR_3_0_InvocableSortAccountRelations(List<Id> userIdList)
    {
        this.userIdList = userIdList;
    }
    
    @InvocableMethod(
        label = 'Re-rank Account Relationship records'
        description = 'Re-rank Account Relationship records in desc order of TTM'
    )
    public static void getSortedAccountRelationships(List<Id> userIdList) {
        System.debug('userIdList (invocable method): ' + userIdList);
        Database.executeBatch(new SBR_3_0_InvocableSortAccountRelations(userIdList));
    }
    public Database.QueryLocator start(Database.BatchableContext BC) 
    {
        System.debug('userIdList (batchable start): ' + userIdList);
        String query = 'Select id from User where Id IN :userIdList';
        //String query = 'Select id, TTM__c, Rank__c, User_Account__c, User_Account__r.Name from Account_Relationship__c where User_Account__c IN :userIdList order by TTM__c DESC ';
        return Database.getQueryLocator(query);
    }
    //public static void getSortedAccountRelationships(List<Id> userIdList) {
    public void execute(Database.BatchableContext BC, List<User> userList) 
    {
        // 9/25/2023 Changes Start - avoid Duplicate ranking
        List<Id> userListNew = new List<Id>();
        for(User usr : userList){
            userListNew.add(usr.id);
        }
        List<Account_Relationship__c> arList = [Select id, TTM__c, Rank__c, User_Account__c, User_Account__r.Name from Account_Relationship__c where User_Account__c IN :userListNew order by TTM__c DESC];
        this.repNames = new List<String>();
        //List<Account_Relationship__c> arList = new List<Account_Relationship__c>();
        Map<Id, List<Account_Relationship__c>> userIdToARList = new Map<Id, List<Account_Relationship__c>>();
        List<Account_Relationship__c> arsToUpdate = new List<Account_Relationship__c>();
        List<User> usersToUpdate = new List<User>();
        Map<Id,User> userIdToUserMap = new Map<Id,User>();

        if(!userIdList.isEmpty()){
            
            for (Id userId : userIdList)
            {
                userIdToARList.put(userId, null);
            }
            userIdToUserMap = SBR_3_0_UserDA.getUsers(userIdToARList.keySet());
        
            //arList = [Select id, TTM__c, Rank__c from Account_Relationship__c where User_Account__c IN :userIdList order by TTM__c DESC LIMIT 10000];
            //arList = SBR_3_0_AccountRelationshipDA.getAccountRelsByUserIds(userIdList);
            for (Account_Relationship__c ar : arList)
            {
                List<Account_Relationship__c> repARList = (userIdToARList.get(ar.User_Account__c) == null ? new List<Account_Relationship__c>() : userIdToARList.get(ar.User_Account__c));
                repARList.add(ar);
                userIdToARList.put(ar.User_Account__c, repARList);
                repNames.add(ar.User_Account__r.Name);
                repLink = ar.User_Account__c;
            }
            
            for (Id userId : userIdToARList.keySet())
            {
                List<Account_Relationship__c> repARList = userIdToARList.get(userId);
                if (repARList.size() > 0)
                {
                    Integer intRank = 1;
                    for (Account_Relationship__c ar : repARList)
                    {
                        ar.Rank__c = intRank;
                        arsToUpdate.add(ar);
                        intRank++;
                    }
                    User u = userIdToUserMap.get(userId);
                    u.Last_Re_rank_date__c = Date.Today();
                    usersToUpdate.add(u);
                }
            }
            if (arsToUpdate.size() > 0)
            {
                update arsToUpdate;
            }
            if (usersToUpdate.size() > 0)
            {
                update usersToUpdate;
            }
        }
    }
    public void finish(Database.BatchableContext BC) 
    {
        AsyncApexJob oJob = [
            					SELECT 
            					TotalJobItems,
            					CreatedById,
            					CreatedBy.Email,
            					JobItemsProcessed, 
            					CompletedDate, 
            					Status,
            					numberoferrors 
            					FROM 
            					AsyncApexJob 
            					WHERE 
            					Id = : BC.getJobId()
        					];
        
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        
        List<string> toAddresses = new List<string>(); 
        List<string> lProfiles_To_Receive_Notification = new List<string>();
        String Profiles_To_Receive_Notification = System.Label.SBR_3_0_Profiles_To_Receive_Notification;
        if(Profiles_To_Receive_Notification.contains(',')){
        	lProfiles_To_Receive_Notification = Profiles_To_Receive_Notification.split(',');    
        }
        else{
            lProfiles_To_Receive_Notification.add(Profiles_To_Receive_Notification);
        }
        System.debug('lProfiles_To_Receive_Notification'+lProfiles_To_Receive_Notification);
        list<User> lUser = 	[
            					SELECT 
            					id, 
            					Email 
            					FROM 
            					User 
            					WHERE 
            					profile.name IN: lProfiles_To_Receive_Notification 
            					AND 
            					IsActive = TRUE
            					LIMIT 98
        					];
        System.debug('lUser'+lUser);
        System.debug('lUser Size'+lUser.size());
        for(User oUser: lUser){
            toAddresses.add(oUser.email);
        }
        toAddresses.add(oJob.CreatedBy.Email);
        System.debug('toAddresses'+toAddresses);
        System.debug('toAddresses size'+toAddresses.size());
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(toAddresses);
        
        mail.setBccSender(false);
        mail.setUseSignature(false);
        repLink = URL.getSalesforceBaseUrl().toExternalForm()+'/'+ repLink;
        
        if(oJob.Status =='Failed'  || oJob.numberoferrors > 0){
            mail.setSubject('Re-Rank of Accounts Failed');
            String plainTextBody = 'Re-ranking of accounts represented by ' + repNames[0] + ' has failed. Please check the batch jobs for further details.';
            mail.setPlainTextBody(plainTextBody);
            String htmlBody = '<p>Re-ranking of accounts represented by ' + repNames[0] + ' has failed. Please check the batch jobs for further details.</p>';
            mail.setHtmlBody(htmlBody);
        }
        else if(oJob.Status =='Completed'){
            mail.setSubject('Re-Rank of Accounts Complete');
            String plainTextBody = 'Re-ranking of accounts represented by ' + repNames[0] + ' has been completed. Updated rankings can be viewed on the Assigned Accounts tab on the user\'s record:' + repLink;
            mail.setPlainTextBody(plainTextBody);
            String htmlBody = '<p>Re-ranking of accounts represented by ' + repNames[0] + ' has been completed. Updated rankings can be viewed on the Assigned Accounts tab on the user\'s record:<br/><a href=\'' + repLink + '\'>' + repLink + '</a></p>';
            mail.setHtmlBody(htmlBody);
        }
        system.debug('oJobId@@ '+ oJob);
        mails.add(mail);
        if (mails.size() > 0)
        {
            Messaging.sendEmail(mails);
        }
    }
}