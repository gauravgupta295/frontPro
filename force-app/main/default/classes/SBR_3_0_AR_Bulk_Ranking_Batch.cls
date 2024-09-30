/********************************************************************************************************************
* Apex Class: SBR_3_0_AR_Bulk_Ranking_Batch
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - This class is for Re-Ranking Account Relationships from SBR_3_0_AR_Ranking_Batch which are ramaining
* - 
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME                        DATE                DETAIL FEATURES
    1.0         Saathvik Tulasi                    09-29-2023             Initial version 
*********************************************************************************************************************/
public class SBR_3_0_AR_Bulk_Ranking_Batch implements Database.Batchable<sObject>, Database.Stateful {
    Private List<User> lUsersToProcess;
    Private list<Analysis_Region__c> lAnalysisRegions;
    Private String objectAPIName;
    
    Private Map<Id,Integer> mUsersWithLastRank;
    Private list<Id> lAccountRelationshipToRank;
    
    Private Database.SaveResult[] lResultFromPreviousBatch;
    Private Database.SaveResult[] lResult;
    
    /**
     * @description Batch Constructor to get the previous batch(SBR_3_0_AR_Ranking_Batch) records, Analysis region and Account relationship records
     * @param mUsersWithLastRank 
     * @param lAccountRelationshipToRank 
     * @param lUsersToProcess 
     * @param lAnalysisRegions 
     * @param objectAPIName 
     * @param lResultFromPreviousBatch 
     */
    Public SBR_3_0_AR_Bulk_Ranking_Batch(Map<Id,Integer> mUsersWithLastRank,list<Id> lAccountRelationshipToRank,List<User> lUsersToProcess,list<Analysis_Region__c> lAnalysisRegions,String objectAPIName,Database.SaveResult[] lResultFromPreviousBatch){
        this.mUsersWithLastRank = mUsersWithLastRank;
        this.lAccountRelationshipToRank = lAccountRelationshipToRank;
        this.lUsersToProcess = lUsersToProcess;
        this.lAnalysisRegions = lAnalysisRegions;
        this.objectAPIName = objectAPIName;
        this.lResultFromPreviousBatch = lResultFromPreviousBatch;
    }
    
    /**
     * @description Batch Start method to get all the Account Relationship records based on criteria
     * @param bc 
     * @return  `Public Database.QueryLocator`
     */
    Public Database.QueryLocator start(Database.BatchableContext bc) {
        List<String> acctRecordTypes = new List<String>{'Credit','ERP_Link'};
        String accountRelationshipQuery =  	'SELECT '+ 
                                            'Id, '+
                                            'TTM__c, '+
            								'Rank__c, '+
            								'User_Account__c '+
                                            'FROM '+
                                            'Account_Relationship__c '+
                                            'WHERE '+
                                            'User_Account__c IN : lUsersToProcess '+
            								'AND '+
                        					//SF-5886 Changes
            								'Account_ID__r.RecordType.DeveloperName IN : acctRecordTypes '+
            								'AND '+
            								'Rank__c != 99999 '+
            								'AND '+
            								'ID NOT IN : lAccountRelationshipToRank ';
        return Database.getQueryLocator(accountRelationshipQuery);
    }
    
    /**
     * @description The execute method performs re-ranking of Account Relationship records
     * @param bc 
     * @param lAccountRelationship 
     */

    Public void execute(Database.BatchableContext bc, List<Account_Relationship__c> lAccountRelationship){
        list<Account_Relationship__c> lAccountRelationshipToReRank = new list<Account_Relationship__c>();
        AR_And_User_Re_Ranking_Batch_Limits__mdt oReRankingBatchLimits = AR_And_User_Re_Ranking_Batch_Limits__mdt.getInstance('Account_Relationship_Records_Limit');
        Integer usersWithAllAccountsZeroTTM = Integer.valueOf(oReRankingBatchLimits.Users_With_All_Accounts_Zero_TTM__c);
        for(Account_Relationship__c oAccountRelationship : lAccountRelationship){
            //SF-5886 Changes
            oAccountRelationship.Rank__c = usersWithAllAccountsZeroTTM;
            lAccountRelationshipToReRank.add(oAccountRelationship); 
        }
        if(!lAccountRelationshipToReRank.isEmpty()){
        	lResult = DATABASE.UPDATE(lAccountRelationshipToReRank,false);    
        }
    }
    
    /**
     * @description The finish method update the Last Re-Rank Date field on User and Analysis region object and sends email to user whole profile is specified 
     * in SBR_3_0_Profiles_To_Receive_Notification custom label
     * @param BC 
     */

    Public void finish(Database.BatchableContext bc){
        list<String> lSentToEmails = new list<String>();
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
                                    Id = : bc.getJobId()
                                ];
        for(User oUser:lUsersToProcess ){
            oUser.Last_Re_rank_date__c = Date.Today();
        }
        Database.update(lUsersToProcess,false);

        for(Analysis_Region__c oAnalysisRegion : lAnalysisRegions){
           oAnalysisRegion.Last_Re_Rank_Date__c = System.now();
        }
        Database.update(lAnalysisRegions,false);

        List<string> lProfilesToReceiveNotification = new List<string>();
        String profilesToReceiveNotification = System.Label.SBR_3_0_Profiles_To_Receive_Notification;
        if(profilesToReceiveNotification.contains(',')){
        	lProfilesToReceiveNotification = profilesToReceiveNotification.split(',');    
        }
        else{
            lProfilesToReceiveNotification.add(profilesToReceiveNotification);
        }
        list<User> lUser = 	[
                                    SELECT 
                                    id, 
                                    Email 
                                    FROM 
                                    User 
                                    WHERE 
                                    profile.name IN: lProfilesToReceiveNotification 
                                    AND 
                                    IsActive = TRUE
                                    LIMIT 98
                                ];
        for(User oUser: lUser){
        	lSentToEmails.add(oUser.email);
        }
        lSentToEmails.add(oJob.CreatedBy.Email);
        List<Messaging.SingleEmailMessage> lMails = new List<Messaging.SingleEmailMessage>();
        Messaging.SingleEmailMessage oMail = new Messaging.SingleEmailMessage();
        oMail.setToAddresses(lSentToEmails);
		oMail.setBccSender(false);
        oMail.setUseSignature(false);
        if(lResult != NULL || lResultFromPreviousBatch!= NULL){
            if(lResult==null){
                lResult = new list<Database.SaveResult>();
            }
            if(lResultFromPreviousBatch != NULL){
                lResult.addAll(lResultFromPreviousBatch);
            }
            Set<Id> successIds = new Set<Id>();
            Set<Id> faildIds = new Set<Id>();
            if(objectAPIName == 'Analysis_Region__c'){
                for(Database.SaveResult oResult : lResult) {
                	if (oResult.isSuccess()) {
                        successIds.add(oResult.getId());
                    }
                    else {
                        faildIds.add(oResult.getId());
                    }
                }
                if(!successIds.isEmpty()){
                    oMail.subject = 'Re-Rank of Accounts for Analysis Regions Complete';
                    String body = '<br/>';
                    body = body + 'Re-ranking of accounts for the following Analysis Regions has been completed: <br/><br/>';
                    String analysisRegionTabel = '<html><table border="1" style="border-collapse: collapse"><caption></caption><tr><th style="text-align: center; vertical-align: middle;">Analysis Region Name</th><th style="text-align: center; vertical-align: middle;">Analysis Region Key</th></tr>';
                    for(Analysis_Region__c oAnalysisRegion : lAnalysisRegions){
                    	analysisRegionTabel = analysisRegionTabel + '<tr><td style="text-align: center; vertical-align: middle;">' + oAnalysisRegion.Name + '</td><td style="text-align: center; vertical-align: middle;">' + oAnalysisRegion.Analysis_Region_Key__c + '-' + oAnalysisRegion.Company_Code__c + '</td></tr>';
                    }
                    body = body + analysisRegionTabel + ' </table></html> <br/><br/>';
                    oMail.setHtmlBody(body);
                    lMails.add(oMail);
                }
                if(!faildIds.isEmpty() || Test.isRunningTest()){
                    oMail.subject = 'Analysis Region Reranking Error';
                    String body = 'Hello '+',<br/>';
                    body = body + 'Please note your analysis region reranking request has not completed successfully.  Please check the batch jobs for further details. <br/><br/>';
                    body = body + 'Thank you  </table></html> <br/><br/>';
                    oMail.setHtmlBody(body);
                    lMails.add(oMail);
                }
            }
            else if(objectAPIName == 'User'){
                String analysisRegionTabel = '<html><table border="1" style="border-collapse: collapse"><tr><th style="text-align: center; vertical-align: middle;">User Name</th></tr>';
                if(oJob.Status =='Failed'  || oJob.numberoferrors > 0 || Test.isRunningTest()){
                    oMail.subject = 'Re-Rank of Accounts Failed';
                    String body = '<br/>';
                    body = body + 'Re-ranking of accounts represented by below users has failed. Please check the batch jobs for further details. <br/><br/>';
                    for(User oUser : lUsersToProcess){
                        String repLink = URL.getOrgDomainURL().toExternalForm()+'/'+oUser.id;
                        analysisRegionTabel = analysisRegionTabel + '<tr><td style="text-align: center; vertical-align: middle;">' +'<a href='+repLink+'>'+oUser.Name+'</a></td></tr>';
                    }
                    body = body + analysisRegionTabel + ' </table></html> <br/><br/>';
                    oMail.setHtmlBody(body);
                    lMails.add(oMail);
                }  
                else if(oJob.Status =='Completed'){
                    oMail.subject = 'Re-Rank of Accounts Complete';
                    String body = '<br/>';
                    body = body + 'Re-ranking of accounts represented by below users has completed. Updated rankings can be viewed on the Assigned Accounts tab on the user\'s record. <br/><br/>';
                    for(User oUser : lUsersToProcess){
                        String repLink = URL.getOrgDomainURL().toExternalForm()+'/'+oUser.id;
                        analysisRegionTabel = analysisRegionTabel + '<tr><td style="text-align: center; vertical-align: middle;">' +'<a href='+repLink+'>'+oUser.Name+'</a></td></tr>';
                    }
                    body = body + analysisRegionTabel + ' </table></html> <br/><br/>';
                    oMail.setHtmlBody(body);
                    lMails.add(oMail);
                }
            }
            if (!lMails.isEmpty()){
                Messaging.sendEmail(lMails);
            }
        }
    }
}