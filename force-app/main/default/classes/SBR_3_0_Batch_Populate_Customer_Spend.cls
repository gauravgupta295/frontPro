/*********************************************************************************************************************
* Apex Class: SBR_3_0_Batch_Populate_Customer_Spend 
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Batch Populated Customer Spend on Account Relationship 
* - SF-169
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME                        DATE                DETAIL FEATURES
    1.0         Saathvik Tulasi                    2023-05-03             Initial version 
    2.0.        Salesforce                         2023-09-19             Commented out Region Key condition
																		  in Customer Spend SOQL  
*********************************************************************************************************************/
global class SBR_3_0_Batch_Populate_Customer_Spend implements Database.Batchable<sObject>, Database.Stateful{
    Id SingleARId;
    global SBR_3_0_Batch_Populate_Customer_Spend(Id SingleARId){
     	this.SingleARId = SingleARId;   
    }
    global SBR_3_0_Batch_Populate_Customer_Spend(){
     	
    }
	global Database.QueryLocator start(Database.BatchableContext BC) {
        
        String query =  'SELECT '+
            			'Id, '+	
            			'Account_ID__c, '+
            			'User_Account__r.Analysis_Region_Key__c, '+
            			'User_Account__r.CompanyName, '+
            			'Customer_Spend__c '+
            			'FROM '+
            			'Account_Relationship__c '+
            			'WHERE '+
            			'Customer_Spend__c = NULL '+
            			'AND '+
            			'Account_ID__c != NULL '+
            			'AND '+
            			'User_Account__r.Analysis_Region_Key__c != NULL ';
        if(String.isNotEmpty(SingleARId)){
        	query = query + 'AND Id =: SingleARId ';    
        }
        return Database.getQueryLocator(query);
    }
	global void execute(Database.BatchableContext BC, List<Account_Relationship__c> lAR){
        Map<Id,Account_Relationship__c> mAccount = new Map<Id,Account_Relationship__c>();
        Map<String,Customer_Spend__c> mCustomerSpend = new Map<String,Customer_Spend__c>();
        Map<String,Account_Relationship__c> mUserAlayisisRegion = new Map<String,Account_Relationship__c>();
        list<Account_Relationship__c> lARToUpdate = new list<Account_Relationship__c>();
        try {
            System.debug('lAR'+lAR); 
            System.debug('lAR Size'+lAR.size()); 
            for(Account_Relationship__c oAR : lAR){
            	mAccount.put(oAR.Account_ID__c,oAR); 
                mUserAlayisisRegion.put(oAR.User_Account__r.Analysis_Region_Key__c,oAR); 
            }
            System.debug('mAccount'+mAccount);
            System.debug('mUserAlayisisRegion'+mUserAlayisisRegion);
            list<Customer_Spend__c> lCustomerSpend = 	[
                							SELECT
                							Id,
                							Account__c,
                							Analysis_Region__c,
                							Analysis_Region__r.Analysis_Region_Key__c,
                							Analysis_Region__r.Company_Code__c
                							FROM
                							Customer_Spend__c
                							WHERE 
                							Account__c IN: mAccount.keySet()
                							/*OR
                							Analysis_Region__r.Analysis_Region_Key__c IN: mUserAlayisisRegion.keySet()*/
            							];
            System.debug('lCustomerSpend'+lCustomerSpend);
            for(Customer_Spend__c oCustomerSpend : lCustomerSpend){
                if(oCustomerSpend.Account__c != NULL && oCustomerSpend.Analysis_Region__c != NULL && oCustomerSpend.Analysis_Region__r.Analysis_Region_Key__c != NULL){
                	String Key = oCustomerSpend.Account__c+oCustomerSpend.Analysis_Region__r.Analysis_Region_Key__c+'-'+oCustomerSpend.Analysis_Region__r.Company_Code__c;
                    System.debug('Key'+Key);
                    mCustomerSpend.put(Key,oCustomerSpend);    
                }
            }
            System.debug('mCustomerSpend'+mCustomerSpend);
            
            for(Account_Relationship__c oAR : lAR){
                String Key = oAR.Account_ID__c+oAR.User_Account__r.Analysis_Region_Key__c+'-'+oAR.User_Account__r.CompanyName;
                System.debug('Key'+Key);
                if(mCustomerSpend.containsKey(Key)){
                	Customer_Spend__c oCustomerSpend = mCustomerSpend.get(Key);
                    oAR.Customer_Spend__c = oCustomerSpend.id;
                    lARToUpdate.add(oAR);
                }
            }
            System.debug('lARToUpdate'+lARToUpdate);
            System.debug('lARToUpdate Size'+lARToUpdate.size());
            if(!lARToUpdate.isEmpty()){
            	UPDATE lARToUpdate;    
            }
        } 
        catch (Exception e) {
            
        }
    }
	global void finish(Database.BatchableContext BC){
        
    }
}