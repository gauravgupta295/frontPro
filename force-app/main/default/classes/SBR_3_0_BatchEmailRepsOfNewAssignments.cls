/*********************************************************************************************************************
* Apex Class: SBR_3_0_BatchEmailRepsOfNewAssignments
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Batch sends emails to the reps od new Assignments 
* - SF-522
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME                        DATE                DETAIL FEATURES
    1.0         Saathvik Tulasi                    2023-04-24             Initial version 
*********************************************************************************************************************/
global class SBR_3_0_BatchEmailRepsOfNewAssignments implements Database.Batchable<sObject>, Database.Stateful{
    Id SingleARId;
    global SBR_3_0_BatchEmailRepsOfNewAssignments(Id SingleARId){
     	this.SingleARId = SingleARId;   
    }
    global SBR_3_0_BatchEmailRepsOfNewAssignments(){
     	
    }
	global Database.QueryLocator start(Database.BatchableContext BC) {
        
        String query =  'SELECT '+
            			'Id, '+	
            			'Account_ID__r.RM_Account_Number__c, '+
            			'Account_ID__r.Name, '+
            			'Type__c, '+
                        'SBR_3_0_New_Assignment__c, '+
            			'User_Account__c '+
            			'FROM '+
            			'Account_Relationship__c '+
            			'WHERE '+
            			'SBR_3_0_New_Assignment__c = TRUE ';
        if(String.isNotEmpty(SingleARId)){
        	query = query + 'AND Id =: SingleARId ';    
        }
        return Database.getQueryLocator(query);
    }
	global void execute(Database.BatchableContext BC, List<Account_Relationship__c> lAR){
        Map<Id,User> mUser = new Map<Id,User>();
        list<Account_Relationship__c> lARToUpdate = new list<Account_Relationship__c>();
        Map<Id,list<Account_Relationship__c>> mUserWithAR = new Map<Id,list<Account_Relationship__c>>();
        list<Messaging.SingleEmailMessage> lMails = new list<Messaging.SingleEmailMessage>();
        try {
            System.debug('lAR'+lAR); 
            System.debug('lAR Size'+lAR.size()); 
            for(Account_Relationship__c oAR : lAR){
                list<Account_Relationship__c> lARNew = new list<Account_Relationship__c>();
                if(mUserWithAR.containsKey(oAR.User_Account__c)){
                    lARNew = mUserWithAR.get(oAR.User_Account__c);
               		lARNew.add(oAR);
            		mUserWithAR.put(oAR.User_Account__c,lARNew);      
                }
                else{
                    lARNew.add(oAR);
            		mUserWithAR.put(oAR.User_Account__c,lARNew); 
                } 
            }
            System.debug('mUserWithAR'+mUserWithAR); 
            System.debug('mUserWithAR Size'+mUserWithAR.size()); 
            list<User> lUser = 	[
                					SELECT
                					Id,
                					Name,
                					Email
                					FROM
                					User
                					WHERE
                					Id IN: mUserWithAR.keySet()
                				];
            System.debug('lUser'+lUser); 
            System.debug('lUser size()'+lUser.size());
            for(User oUser : lUser){
            	mUser.put(oUser.id,oUser);    
            }
            System.debug('mUser'+mUser); 
            System.debug('mUser size()'+mUser.size());
            for(Id UserId : mUserWithAR.keySet()){
                if(mUser.containsKey(UserId)){
                    User oUser = mUser.get(UserId);
                    list<Account_Relationship__c> lARToProcess = mUserWithAR.get(UserId);
                    System.debug('lARToProcess'+lARToProcess);
                    System.debug('lARToProcess size'+lARToProcess.size());
                    Messaging.SingleEmailMessage oMail = new Messaging.SingleEmailMessage();
                    oMail.toAddresses= new String[] { 'Saathvik.tulasi@salesforce.com',oUser.Email};
                    oMail.subject = 'New Account Assignments';
                    String Body = 'Dear '+oUser.Name+',<br/>';
                    Body = Body + 'Please note you have been assigned to the following accounts:<br/><br/>';
                    String BodyOfRequests='<html><table border="1" style="border-collapse: collapse"><caption> New Assignments </caption><tr><th style="text-align: center; vertical-align: middle;">Account RM Number</th><th style="text-align: center; vertical-align: middle;">Account Name</th><th style="text-align: center; vertical-align: middle;">Assignment Type</th></tr>';
                    for(Account_Relationship__c oAR : lARToProcess){
                        BodyOfRequests = BodyOfRequests + 	'<tr><td style="text-align: center; vertical-align: middle;">' + oAR.Account_ID__r.RM_Account_Number__c + '</td>'+
                            								'<td style="text-align: center; vertical-align: middle;">' + oAR.Account_ID__r.Name + '</td>'+
                            								'<td style="text-align: center; vertical-align: middle;">' + oAR.Type__c  + '</td></tr>';
                    	oAR.SBR_3_0_New_Assignment__c = FALSE;
                        lARToUpdate.add(oAR);
                    }
                    BodyOfRequests = BodyOfRequests + '</table>';
                    Body = Body + BodyOfRequests+'<br/><br/>';
                    Body = Body + '<br/><br/></html>';
                    System.debug('Body'+Body);
                    oMail.setHtmlBody(Body);
                    lMails.add(oMail);
                }
            }
            System.debug('lARToUpdate'+lARToUpdate);
            System.debug('lARToUpdate Size'+lARToUpdate.size());
            if(!lARToUpdate.isEmpty()){
            	UPDATE lARToUpdate;    
            }
            System.debug('lMails'+lMails);
            if(!lMails.isEmpty()){
                Messaging.sendEmail(lMails);
            }
        } 
        catch (Exception e) {
            
        }
    }
	global void finish(Database.BatchableContext BC){
        
    }
}