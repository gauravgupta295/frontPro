/*********************************************************************************************************************
* Apex Class: SBR_3_0_ExpenseDA
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Data Access class for Expense records
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Kunal Patel          2022-12-19              Initial version    
*********************************************************************************************************************/

public with sharing class SBR_3_0_ExpenseDA implements SBR_3_0_ExpenseDAInterface {

    @AuraEnabled(cacheable=true)
    public static List<SBR_Expense__c> getQuotesExpense(Id quoteId) {
        return [SELECT Id, Name, ExpenseType__c, Quantity__c, Price__c,lastModifiedDate,Total__c, Analysis_Region_Key__c FROM SBR_Expense__c WHERE Quote_Expenses__c =: quoteId]; 
    }

    @AuraEnabled(cacheable=false)
    public static List<SBR_Expense__c> getQuotesExpenseRefresh(Id quoteId) {
        return [SELECT Id, Name, ExpenseType__c, Quantity__c, Price__c,lastModifiedDate,Total__c, Analysis_Region_Key__c FROM SBR_Expense__c WHERE Quote_Expenses__c =: quoteId]; 
    }

    public static List<SBR_Expense__c> getQuotesExpensesForScaffoldingQuotes(Set<Id> quoteIds) {
        return [SELECT Id, Name, Quote_Expenses__c, Quote_Expenses__r.Analysis_Region_Key__c,Total__c,ExpenseType__c, Quote_Expenses__r.Company_Code__c 
                FROM SBR_Expense__c WHERE Quote_Expenses__c in:quoteIds]; 
    }

    public static List<AggregateResult> getExpenseAggregateList(Set<Id> quoteIds) {
        return [SELECT Quote_Expenses__c,Sum(Total__c) total , Count(Id) quantity FROM SBR_Expense__c WHERE 
            Quote_Expenses__c in: quoteIds GROUP BY Quote_Expenses__c];
    }

    public static List<AggregateResult> getEDExpenseAggregateList(Set<Id> quoteIds) {
        return [SELECT Quote_Expenses__c,Sum(Total__c) total , Count(Id) quantity FROM SBR_Expense__c WHERE 
            Quote_Expenses__c in: quoteIds AND ExpenseType__c IN ('Mileage (Personnel)','Per Diem','Hotel','Truck Rental') GROUP BY Quote_Expenses__c];
    }

}