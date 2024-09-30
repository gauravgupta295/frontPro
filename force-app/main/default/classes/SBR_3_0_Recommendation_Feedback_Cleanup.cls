/*********************************************************************************************************************
* Apex Class: SBR_3_0_Recommendation_Feedback_Cleanup
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Batch pickups old Product Recommendation Feedback records and deleted them from the Database
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME                        DATE                DETAIL FEATURES
    1.0         Saathvik Tulasi                    2023-10-12             Initial version 
*********************************************************************************************************************/
global class SBR_3_0_Recommendation_Feedback_Cleanup implements Database.Batchable<sObject>, Database.Stateful{
	Id SinglePRFId;
    global SBR_3_0_Recommendation_Feedback_Cleanup(Id SinglePRFId){
     	this.SinglePRFId = SinglePRFId;   
    }
    global SBR_3_0_Recommendation_Feedback_Cleanup(){
     	
    }
	global Database.QueryLocator start(Database.BatchableContext BC) {
        Integer NoOfDaysFromCreatedDateLimit = Integer.valueOf(System.Label.SBR_3_0_No_Of_Days_From_Created_Date_Limit);
        System.debug('NoOfDaysFromCreatedDateLimit'+NoOfDaysFromCreatedDateLimit);
    	String query =  'SELECT '+
            			'Id, '+	
            			'Name, '+
            			'Cat_Class_Key__c, '+
            			'Model_Version__c, '+
                        'Feedback_Type__c, '+
            			'Rep_ID__c, '+
            			'Account_number__c, '+
            			'No_of_Days_from_Created_Date__c '+
            			'FROM '+
            			'Product_Recommendation_Feedback__c ';
        if(String.isNotEmpty(SinglePRFId)){
        	query = query + 'WHERE Id =: SinglePRFId ';    
        }
        else{
            query = query + 'WHERE No_of_Days_from_Created_Date__c > '+NoOfDaysFromCreatedDateLimit;
        }
        return Database.getQueryLocator(query);
    }
	global void execute(Database.BatchableContext BC, List<Product_Recommendation_Feedback__c> lPRF){
        System.debug('lPRF'+lPRF);
        Database.DELETE(lPRF);
    }
	global void finish(Database.BatchableContext BC){
        
    }
}