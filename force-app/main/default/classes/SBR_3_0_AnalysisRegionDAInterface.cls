/*********************************************************************************************************************
* Apex Class: SBR_3_0_AnalysisRegionDAInterface
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Interface class for Analysis Region Data Access
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Philippe Bilodeau       2023-05-08          Initial version    
*********************************************************************************************************************/
public interface SBR_3_0_AnalysisRegionDAInterface {
    List<Analysis_Region__c> getAnalysisRegions(List<Id> ids);
    List<Analysis_Region__c> getAnalysisRegionsByKey(Set<String> regionKeys);
}