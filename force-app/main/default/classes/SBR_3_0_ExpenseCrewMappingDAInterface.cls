/*********************************************************************************************************************
* Apex Class: SBR_3_0_ExpenseCrewMappingDAInterface
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Interface class for Expense/Crew Mapping
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME            DATE                DETAIL FEATURES
    1.0         Davinder Singh               2023-1-30            Initial version    
*********************************************************************************************************************/
public interface SBR_3_0_ExpenseCrewMappingDAInterface {
    List<Expense_Crew_Mapping__c> getExpenseCrewMappingForScaffoldingQuote(SBQQ__Quote__c quote);
    List<Expense_Crew_Mapping__c> getExpenseCrewMappingForProductSKU(SBQQ__Quote__c quote, String productSKU);
    Expense_Crew_Mapping__c getExpenseCrewMapping(SBQQ__Quote__c quote, String type);

}