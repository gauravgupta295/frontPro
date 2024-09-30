/*********************************************************************************************************************
* Apex Class: SBR_3_0_ExpenseDAInterface
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Interface class for Expense Data Access
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Kunal Patel           2022-12-19            Initial version    
*********************************************************************************************************************/
public interface SBR_3_0_ExpenseDAInterface {
    List<SBR_Expense__c> getQuotesExpense(Id quoteId);
    List<SBR_Expense__c> getQuotesExpenseRefresh(Id quoteId);
    List<SBR_Expense__c> getQuotesExpensesForScaffoldingQuotes(Set<Id> quoteIds);
    List<AggregateResult> getExpenseAggregateList(Set<Id> quoteIds);
}