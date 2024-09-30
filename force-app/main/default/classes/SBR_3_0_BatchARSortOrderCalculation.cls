/*********************************************************************************************************************
* Apex Class: SBR_3_0_BatchARSortOrderCalculation
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Batch update sort Account Reationship records of Account
* - SF-165
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME                        DATE                DETAIL FEATURES
    1.0         Saathvik Tulasi                    2023-04-17             Initial version 
*********************************************************************************************************************/
global class SBR_3_0_BatchARSortOrderCalculation implements Database.Batchable<sObject>, Database.Stateful{
    Id SingleAccountId;
    Boolean AllRecords;
    String ARType = 'Tracking';
    global SBR_3_0_BatchARSortOrderCalculation(Id SingleAccountId){
        this.SingleAccountId = SingleAccountId;   
    }
    global SBR_3_0_BatchARSortOrderCalculation(Boolean AllRecords){
        this.AllRecords = AllRecords;
    }
    global SBR_3_0_BatchARSortOrderCalculation(){
        
    }
    global Database.QueryLocator start(Database.BatchableContext BC) {
        list<String> lAccount_Record_Types_to_Update_Sorting = Label.SBR_3_0_Account_Record_Types_to_Update_Sorting.split(',');
        System.debug('lAccount_Record_Types_to_Update_Sorting'+lAccount_Record_Types_to_Update_Sorting);
        String query =  'SELECT '+
                        'Id, '+
            			'Name '+
                        'FROM '+
                        'Account ';
        if(this.AllRecords == TRUE){
            query = query + 'WHERE RecordType.DeveloperName IN: lAccount_Record_Types_to_Update_Sorting';    
        }
        else if(String.isNotEmpty(SingleAccountId)){
            query = query + 'WHERE Id =: SingleAccountId ';    
        }
        else{
            query = query 	+ 	'WHERE '+
                			  	'RecordType.DeveloperName IN: lAccount_Record_Types_to_Update_Sorting '+
                				'AND '+
                				'Id IN (SELECT Account_ID__c FROM Account_Relationship__c WHERE SBR_3_0_Sync_Sorting_Order__c = FALSE and Type__c != :ARType)'; 
        }
		System.debug('query'+query);        
        return Database.getQueryLocator(query);
    }//'SBR_3_0_Sync_Sorting_Order__c = FALSE '+
    global void execute(Database.BatchableContext BC, List<Account> lAccounts){
        Map<id,list<Account_Relationship__c>> mAccountWithAR = new Map<id,list<Account_Relationship__c>>();
        try {
            Map<String, SBR_3_0_Rep_Type_Classification__mdt> mRepTypeWithStrategicType = new Map<String, SBR_3_0_Rep_Type_Classification__mdt>();
            Map<String, SBR_3_0_Rep_Type_Classification__mdt> mRepTypeClassification = SBR_3_0_Rep_Type_Classification__mdt.getAll();
            System.debug('mRepTypeClassification'+mRepTypeClassification);
            for(String NameStr : mRepTypeClassification.keySet()){
                SBR_3_0_Rep_Type_Classification__mdt oClassification = mRepTypeClassification.get(NameStr);
                mRepTypeWithStrategicType.put(oClassification.Rep_Type__c,oClassification);    
            }
            System.debug('mRepTypeWithStrategicType'+mRepTypeWithStrategicType);
            System.debug('lAccounts'+lAccounts);
            list<Account_Relationship__c> lAccountWithAR =  [
                                                                SELECT
                                                                Id,
                                                                Account_ID__c,
                                                                TTM__c,
                                                                Sort__c,
                                                                Rep_Type__c
                                                                FROM
                                                                Account_Relationship__c
                                                                WHERE
                                                                Account_ID__c IN: lAccounts
                												AND
                												Type__c != 'Tracking'
                                                                ORDER BY TTM__c DESC
                                                            ];
            System.debug('lAccountWithAR'+lAccountWithAR); 
            System.debug('lAccountWithAR size()'+lAccountWithAR.size()); 
            for(Account_Relationship__c oAccountWithAR : lAccountWithAR){
                list<Account_Relationship__c> lARNew = new list<Account_Relationship__c>();
                if(mAccountWithAR.containsKey(oAccountWithAR.Account_ID__c)){
                    lARNew = mAccountWithAR.get(oAccountWithAR.Account_ID__c);
                    lARNew.add(oAccountWithAR);
                    mAccountWithAR.put(oAccountWithAR.Account_ID__c,lARNew);
                }    
                else{
                    lARNew.add(oAccountWithAR);
                    mAccountWithAR.put(oAccountWithAR.Account_ID__c,lARNew);
                }
            }
            System.debug('mAccountWithAR'+mAccountWithAR); 
            System.debug('mAccountWithAR Size'+mAccountWithAR.size()); 
            list<Account_Relationship__c> lARToAfterSorting = new list<Account_Relationship__c>();
            for(Id AccountId : mAccountWithAR.keySet()){
                Map<String,list<Account_Relationship__c>> mARWithStrategicType = new Map<String,list<Account_Relationship__c>>();
                System.debug('____________________________________________________________________________________________________________________'+AccountId); 
                list<Account_Relationship__c> lARToSort = mAccountWithAR.get(AccountId);
                System.debug('lARToSort'+lARToSort); 
                System.debug('lARToSort size'+lARToSort.size()); 
                for(Account_Relationship__c oAR : lARToSort){
                    list<Account_Relationship__c> lARWithStrategicType = new list<Account_Relationship__c>();
                    System.debug('oAR.Rep_Type__c'+oAR.Rep_Type__c); 
                    if(oAR.Rep_Type__c == NULL){
                        if(mARWithStrategicType.containsKey('None')){
                            lARWithStrategicType = mARWithStrategicType.get('None');
                            lARWithStrategicType.add(oAR);
                            mARWithStrategicType.put('None',lARWithStrategicType); 
                        }    
                        else{
                            lARWithStrategicType.add(oAR);
                            mARWithStrategicType.put('None',lARWithStrategicType);
                        }
                    }
                    else{
                        if(mRepTypeWithStrategicType.containsKey(oAR.Rep_Type__c)){
                            SBR_3_0_Rep_Type_Classification__mdt oClassification = mRepTypeWithStrategicType.get(oAR.Rep_Type__c);
                            if(mARWithStrategicType.containsKey(oClassification.Strategic_Type__c)){
                                lARWithStrategicType = mARWithStrategicType.get(oClassification.Strategic_Type__c);
                                lARWithStrategicType.add(oAR);
                                mARWithStrategicType.put(oClassification.Strategic_Type__c,lARWithStrategicType);
                            }
                            else{
                                lARWithStrategicType.add(oAR);
                                mARWithStrategicType.put(oClassification.Strategic_Type__c,lARWithStrategicType);
                            }
                        }
                        else{
                            if(mARWithStrategicType.containsKey('None')){
                                lARWithStrategicType = mARWithStrategicType.get('None');
                                lARWithStrategicType.add(oAR);
                                mARWithStrategicType.put('None',lARWithStrategicType); 
                            }
                            else{
                                lARWithStrategicType.add(oAR);
                                mARWithStrategicType.put('None',lARWithStrategicType);
                            }
                        }
                    }
                }
                System.debug('mARWithStrategicType'+mARWithStrategicType);
                System.debug('mARWithStrategicType size'+mARWithStrategicType.size());
                Integer SortingNumber = 1;
                if(mARWithStrategicType.containsKey('National')){
                    list<Account_Relationship__c> lARNational =  mARWithStrategicType.get('National');
                    for(Account_Relationship__c oARNational : lARNational){
                        System.debug('SortingNumber'+SortingNumber);
                        oARNational.Sort__c = SortingNumber; 
                        oARNational.SBR_3_0_Sync_Sorting_Order__c = TRUE;
                        lARToAfterSorting.add(oARNational);
                        SortingNumber++;
                    }    
                }
                if(mARWithStrategicType.containsKey('Regional')){
                    list<Account_Relationship__c> lARRegional =  mARWithStrategicType.get('Regional');
                    for(Account_Relationship__c oARRegional : lARRegional){
                        System.debug('SortingNumber'+SortingNumber);
                        oARRegional.Sort__c = SortingNumber; 
                        oARRegional.SBR_3_0_Sync_Sorting_Order__c = TRUE;
                        lARToAfterSorting.add(oARRegional);
                        SortingNumber++;
                    }    
                }
                if(mARWithStrategicType.containsKey('None')){
                    list<Account_Relationship__c> lARNone =  mARWithStrategicType.get('None');
                    for(Account_Relationship__c oARNone : lARNone){
                        System.debug('SortingNumber'+SortingNumber);
                        oARNone.Sort__c = SortingNumber;  
                        oARNone.SBR_3_0_Sync_Sorting_Order__c = TRUE;
                        lARToAfterSorting.add(oARNone);
                        SortingNumber++;    
                    }
                }
           } 
            System.debug('lARToAfterSorting'+lARToAfterSorting);
            System.debug('lARToAfterSorting size Update'+lARToAfterSorting.size()); 
           	if(!lARToAfterSorting.isEmpty()){
               Database.UPDATE(lARToAfterSorting,false);
           	}
        } 
        catch (Exception e) {
            
        }
    }
    global void finish(Database.BatchableContext BC){
        
    }
}