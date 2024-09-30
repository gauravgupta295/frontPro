/*********************************************************************************************************************
* Apex Class: SBR_3_0_ExpenseOperations
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Class to handle Expense related calculation and operations  
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Davinder Singh        2023-01-27             Initial version    
*********************************************************************************************************************/
public with sharing class SBR_3_0_ExpenseOperations{
    
     // This Method will create or update quote line items when crew summary record is created/updated
    public static void updateQuoteLineForScaffolding(List<SBR_Expense__c> newExpenseList) {
        Set<Id> quoteIds = new Set<Id>();
        List<SBR_Expense__c> newExpensesWProductSKU = [Select Id, Quote_Expenses__c, Product_Lookup__r.Product_SKU__c from SBR_Expense__c where Id in: newExpenseList];
        String eLaborSKU = System.Label.E_Labor_Product_SKU;
        for (SBR_Expense__c expense : newExpensesWProductSKU) {
            if(expense.Quote_Expenses__c!=null && expense.Product_Lookup__r.Product_SKU__c == eLaborSKU){   //SAL-26878,27341
                quoteIds.add(expense.Quote_Expenses__c);
            }                
        }
        if(!quoteIds.isEmpty()){
            updateQuoteLines(quoteIds);
        }
    }

    @future
    public static void updateQuoteLines( Set<Id> quoteIds)
    {   
        try {
            SBR_3_0_QuoteOperations.updateQuoteLines(quoteIds);
        } catch (Exception ex) {
            SBR_3_0_Log.logException(ex);
        } finally {
            SBR_3_0_Log.saveLog();
        }   

    }
   
}