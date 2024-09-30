/*********************************************************************************************************************
* Apex Class: SBR_3_0_AnalysisRegionOperationsTest
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Used to test SBR_3_0_AnalysisRegionOperations
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Philippe Bilodeau       2022-05-08          Initial version    
*********************************************************************************************************************/
@isTest
public with sharing class SBR_3_0_AnalysisRegionOperationsTest {
    @isTest
    public static void testGetAnalysisRegions()
    {
        Analysis_Region__c ar = new Analysis_Region__c();
        ar.Name = 'Test Analysis Region';
        ar.Analysis_Region_Key__c = '123';
        ar.Company_Code__c = '01';
        ar.Status__c = 'Active';
        insert ar;
        
        List<SBR_3_0_AnalysisRegionOperations.ARRequest> reqList = new List<SBR_3_0_AnalysisRegionOperations.ARRequest>();
        SBR_3_0_AnalysisRegionOperations.ARRequest req = new SBR_3_0_AnalysisRegionOperations.ARRequest();
        List<Id> arList = new List<Id>();
        arList.add(ar.Id);
        req.ARIds = arList;
        reqList.add(req);
        
        SBR_3_0_AnalysisRegionOperations.getAnalysisRegions(reqList);
    }
}