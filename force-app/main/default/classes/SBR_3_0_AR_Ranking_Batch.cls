/********************************************************************************************************************
* Apex Class: SBR_3_0_AR_Ranking_Batch
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - This class is for Re-Ranking Account Relationships from User records
* - 
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME                        DATE                DETAIL FEATURES
    1.0         Saathvik Tulasi                    09-29-2023             Initial version 
*********************************************************************************************************************/
public class SBR_3_0_AR_Ranking_Batch implements Database.Batchable<sObject>, Database.Stateful{
    Private List<User> lUsersToProcess;
    Private list<Analysis_Region__c> lAnalysisRegions;
    Private String ObjectAPIName;
    Private Map<Id,Integer> mUsersWithLastRank = new Map<Id,Integer>();
    Private list<Id> lAccountRelationshipToRankIds = new list<Id>();
    Private Database.SaveResult[] lResult;
    
    Public SBR_3_0_AR_Ranking_Batch(List<User> lUsersToProcess,list<Analysis_Region__c> lAnalysisRegions,String ObjectAPIName){
        this.lUsersToProcess = lUsersToProcess;
        this.lAnalysisRegions = lAnalysisRegions;
        this.ObjectAPIName = ObjectAPIName;
    }
    Public Database.QueryLocator start(Database.BatchableContext BC) {
        String UserQuery =  'SELECT '+ 
                            'Id, '+
                            'Name, '+
                            'Analysis_Region_Key__c '+
                            'FROM '+
                            'User '+
                            'WHERE '+
                            'Id IN : lUsersToProcess ';
        return Database.getQueryLocator(UserQuery);
    }
    Public void execute(Database.BatchableContext BC, List<User> lUser){
        list<Account_Relationship__c> lAccountRelationshipToRank = new list<Account_Relationship__c>();
        AR_And_User_Re_Ranking_Batch_Limits__mdt oReRankingBatchLimits = AR_And_User_Re_Ranking_Batch_Limits__mdt.getInstance('Account_Relationship_Records_Limit');
        Integer AccountRelationshipRecordsLimit = Integer.valueOf(oReRankingBatchLimits.Account_Relationship_Records_Limit__c);
        
        Map<Id,User> mUser = new Map<Id,User>();
        Map<Id,list<Account_Relationship__c>> mUserWithAccountRelationship = new Map<Id,list<Account_Relationship__c>>();
        for(User oUser : lUser){
            mUser.put(oUser.id,oUser);
        }
		list<Account_Relationship__c> lAccountRelationship =  	[
            														SELECT
                                                                    Id,
                                                                    TTM__c,
                                                                    Rank__c,
                                                                    User_Account__c
                                                                    FROM
                                                                    Account_Relationship__c
                                                                    WHERE
                                                                    User_Account__c IN : mUser.keySet()
                                                                    AND
            														//SF-5886 chnages
            														Account_ID__r.RecordType.DeveloperName IN ('Credit','ERP_Link')
																	AND
                                                                    TTM__c > 0
            														//SF-6494 changes
            														AND
            														Type__c != 'Tracking'
                                                                    ORDER BY TTM__c DESC 
                                                                    LIMIT :AccountRelationshipRecordsLimit
            													];
        for(Account_Relationship__c oAccountRelationship : lAccountRelationship){
            list<Account_Relationship__c> lAccountRelationshipToProcess = new list<Account_Relationship__c>();
            if(mUserWithAccountRelationship.containsKey(oAccountRelationship.User_Account__c)){
            	lAccountRelationshipToProcess = mUserWithAccountRelationship.get(oAccountRelationship.User_Account__c);
                lAccountRelationshipToProcess.add(oAccountRelationship);
            }
            else{
                lAccountRelationshipToProcess.add(oAccountRelationship);
            }
            mUserWithAccountRelationship.put(oAccountRelationship.User_Account__c,lAccountRelationshipToProcess);
        }
        for(Id UserId : mUserWithAccountRelationship.keySet()){
           list<Account_Relationship__c> lAccountRelationshipFromMap =  mUserWithAccountRelationship.get(UserId);
           Integer Rank = 1;
           for(Account_Relationship__c oAccountRelationship : lAccountRelationshipFromMap){ 
           		oAccountRelationship.Rank__c = Rank;
               	lAccountRelationshipToRank.add(oAccountRelationship);
                lAccountRelationshipToRankIds.add(oAccountRelationship.id);
                Rank++;
           }
           mUsersWithLastRank.put(UserId,Rank);
        }
        if(!lAccountRelationshipToRank.isEmpty()){
            lResult = DATABASE.UPDATE(lAccountRelationshipToRank,false);    
        }
    }
    Public void finish(Database.BatchableContext BC){
        Database.executeBatch(new SBR_3_0_AR_Bulk_Ranking_Batch(mUsersWithLastRank,lAccountRelationshipToRankIds,lUsersToProcess,lAnalysisRegions,ObjectAPIName,lResult),200);
    }
}