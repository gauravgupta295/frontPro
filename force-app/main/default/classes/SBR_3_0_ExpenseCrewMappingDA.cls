/*********************************************************************************************************************
* Apex Class: SBR_3_0_ExpenseCrewMappingDA
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Data Access class for Expense records
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
     1.0         Davinder Singh               2023-1-30            Initial version   
*********************************************************************************************************************/

public with sharing class SBR_3_0_ExpenseCrewMappingDA implements SBR_3_0_ExpenseCrewMappingDAInterface {

    public static List<Expense_Crew_Mapping__c> getExpenseCrewMappingForScaffoldingQuote(SBQQ__Quote__c quote) {
        return [SELECT Id,SF_Product_SKU__c,Analysis_Region_Key__c,Company_Code__c,SF_Product_SKU__r.Product_SKU__c, Expense_Crew_Type__c FROM Expense_Crew_Mapping__c WHERE 
                    Analysis_Region_Key__c=: quote.Analysis_Region_Key__c AND Company_Code__c =: quote.Company_Code__c  ]; 
    }

    public static List<Expense_Crew_Mapping__c> getExpenseCrewMappingForProductSKU(SBQQ__Quote__c quote, String productSKU) {
        return [SELECT Id,SF_Product_SKU__c,Analysis_Region_Key__c,Company_Code__c,Expense_Crew_Type__c, SF_Product_SKU__r.Product_SKU__c  FROM Expense_Crew_Mapping__c WHERE 
                    Analysis_Region_Key__c=: quote.Analysis_Region_Key__c AND Company_Code__c =: quote.Company_Code__c AND SF_Product_SKU__c =: productSKU  ]; 
    }

    public static Expense_Crew_Mapping__c getExpenseCrewMapping(SBQQ__Quote__c quote,  String type) {
        List<Expense_Crew_Mapping__c> expList = [SELECT Id,SF_Product_SKU__c,Analysis_Region_Key__c,Company_Code__c,Expense_Crew_Type__c, SF_Product_SKU__r.Product_SKU__c  FROM Expense_Crew_Mapping__c WHERE 
        Analysis_Region_Key__c=: quote.Analysis_Region_Key__c AND Company_Code__c =: quote.Company_Code__c AND Expense_Crew_Type__c =: type LIMIT 1  ]; 
        if(!expList.isEmpty()){
            return expList[0];
        }
        return null;  
    }
    
    public static List<Expense_Crew_Mapping__c> getExpenseCrewMapping(List<SBQQ__Quote__c> quotes, Set<String> types) {
        List<Expense_Crew_Mapping__c> resultMap = new List<Expense_Crew_Mapping__c>();
        
        List<String> regionKeys = new List<String>();
        List<String> companyCodes = new List<String>();
        
        for (SBQQ__Quote__c quote : quotes) {
            regionKeys.add(quote.Analysis_Region_Key__c);
            companyCodes.add(quote.Company_Code__c);
        }
        
        List<Expense_Crew_Mapping__c> expList = [SELECT Id, SF_Product_SKU__c, Analysis_Region_Key__c, Company_Code__c, Expense_Crew_Type__c, SF_Product_SKU__r.Product_SKU__c  
                                                 FROM Expense_Crew_Mapping__c 
                                                 WHERE Analysis_Region_Key__c IN :regionKeys 
                                                 AND Company_Code__c IN :companyCodes 
                                                 AND Expense_Crew_Type__c IN :types];
        
        for (Expense_Crew_Mapping__c expMapping : expList) {
            resultMap.add (expMapping);
        }
        
        return resultMap;
    }
    
    public static List<Expense_Crew_Mapping__c> getExpenseCrewMappingForProductSKU(List<SBQQ__Quote__c> quotes, Set<String> productSKUs) {
        List<Expense_Crew_Mapping__c> resultMap = new List<Expense_Crew_Mapping__c>();
        
        List<String> regionKeys = new List<String>();
        List<String> companyCodes = new List<String>();
        
        for (SBQQ__Quote__c quote : quotes) {
            regionKeys.add(quote.Analysis_Region_Key__c);
            companyCodes.add(quote.Company_Code__c);
        }
        
        List<Expense_Crew_Mapping__c> expList = [SELECT Id, SF_Product_SKU__c, Analysis_Region_Key__c, Company_Code__c, Expense_Crew_Type__c, SF_Product_SKU__r.Product_SKU__c  
                                                 FROM Expense_Crew_Mapping__c 
                                                 WHERE Analysis_Region_Key__c IN :regionKeys 
                                                 AND Company_Code__c IN :companyCodes 
                                                 AND SF_Product_SKU__c IN :productSKUs];
        
        for (Expense_Crew_Mapping__c expMapping : expList) {
            resultMap.add(expMapping);
        }
        
        return resultMap;
    }


}