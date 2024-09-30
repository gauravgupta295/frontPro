/*********************************************************************************************************************
* Apex Class: SBR_3_0_AnalysisRegionDA
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Concrete class for Analysis Data Access
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Philippe Bilodeau       2022-05-08          Initial version    
*********************************************************************************************************************/
public with sharing class SBR_3_0_AnalysisRegionDA implements SBR_3_0_AnalysisRegionDAInterface {

    public static List<Analysis_Region__c> getAnalysisRegions(List<Id> ids) {
        return [SELECT Name, Analysis_Region_Key__c, Company_Code__c, Status__c FROM Analysis_Region__c WHERE Id IN: ids];
    }

    public static List<Analysis_Region__c> getAnalysisRegionsByKey(Set<String> regionKeys) {
        return [SELECT Name, Analysis_Region_Key__c, Company_Code__c, Status__c FROM Analysis_Region__c WHERE Analysis_Region_Key__c IN: regionKeys];
    }
}