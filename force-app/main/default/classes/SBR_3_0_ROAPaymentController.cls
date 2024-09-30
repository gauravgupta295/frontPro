/*********************************************************************************************************************
* Apex Class: SBR_3_0_ROAPaymentController
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:@description This code defines a Salesforce Apex controller class named SBR_3_0_ROAPaymentController. It contains 
methods for retrieving Payments.These methods are annotated with @AuraEnabled to make them accessible from Lightning components.
The code ensures security enforcement by utilizing WITH SECURITY_ENFORCED in SOQL queries and handles exceptions 
appropriately.
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
     1          Vivek Kumar Sharma     20-01-2024           
*********************************************************************************************************************/
public with sharing class SBR_3_0_ROAPaymentController {
    
     /**
    * @description fetch Payments__c for given account ID.
    * @param accountId The ID of the order for which to calculate the deposit.
    * @return List<Payments__c> .
    */
    @AuraEnabled(cacheable=false)
    public static List<Payments__c> getPayments(Id accountId) {
       
        
        List<Payments__c> payments = [SELECT Id,Name, Type__c, Location__c, Deposit_Amount__c, Date__c, Time__c,User__c
                                      FROM Payments__c
                                      WHERE Account__c=:accountId AND Invoice_or_Comment__c != null WITH SECURITY_ENFORCED ORDER BY Date__c  DESC ];
    
        return payments;
    }
    
}