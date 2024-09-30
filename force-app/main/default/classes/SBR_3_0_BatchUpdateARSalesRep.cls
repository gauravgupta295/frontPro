/*********************************************************************************************************************
* Apex Class: SBR_3_0_BatchUpdateARSalesRep
---------------------------------------------------------------------------------------------------------------------------------------
* - SF-6742
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME                      DATE                DETAIL FEATURES
1.0             Manish Taneja                    2024-02-05             Initial version 
*********************************************************************************************************************
     * @description This class is for Batch update Sales Rep in Account Reationship Record.
 */
public class SBR_3_0_BatchUpdateARSalesRep implements Database.Batchable<sObject>, Database.Stateful {
/** 
  * @description start Method implementation
  * @param BatchableContext
  * @return - All required Account Realtionship Records
*/
    Public Database.QueryLocator start(Database.BatchableContext batchCon) {
        String query = 'SELECT Id, Sales_Rep_ID2__c, User_Account__c ' +
               'FROM Account_Relationship__c ' +
               'WHERE User_Account__c = null ' +
               'AND Sales_Rep_ID2__c != null ' ;
                return Database.getQueryLocator(Query);
    }

/** 
  * @description execute Method implementation
  * @param BatchableContext and list of Account Relationships
*/
    Public void execute(Database.BatchableContext batchCon, List<Account_Relationship__c> lAR){
        set<String> salesRepIds = new set<String>();
        
        for(Account_Relationship__c oAR : lAR){
            salesRepIds.add(oAR.Sales_Rep_ID2__c);  
        }
        
        // Query the User object to retrieve the Salesforce Id and Sales Rep Id for all active users
        Map<String, Id> salesRepIdToSalesforceIdMap = new Map<String, Id>();
        for(User u : [SELECT Id, RepID__c FROM User WHERE IsActive = true AND RepID__c IN: salesRepIds]) {
            salesRepIdToSalesforceIdMap.put(u.RepID__c, u.Id);
        }
        
        // Update the Account Relationship records with the Salesforce Id retrieved from the User object
        List<Account_Relationship__c> accountRelationshipsToUpdate = new List<Account_Relationship__c>();
        
        for(Account_Relationship__c ar : lAR) {
            if(salesRepIdToSalesforceIdMap.containsKey(ar.Sales_Rep_ID2__c)){
                ar.User_Account__c = salesRepIdToSalesforceIdMap.get(ar.Sales_Rep_ID2__c);
                // Update the Account Relationship records
                accountRelationshipsToUpdate.add(ar);
            }
        }
        Database.SaveResult[] lResult;
        if(accountRelationshipsToUpdate.size() > 0)
        {
            lResult = DATABASE.UPDATE(accountRelationshipsToUpdate,false);
        }
    }
    
/** 
 * @description finish Method implementation
 * @param BatchableContext 
*/
    Public void finish(Database.BatchableContext batchCon){

    }
}