/*********************************************************************************************************************
* Apex Class: SBR_3_0_AnalysisRegionDA_Test 
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Class to test SBR_3_0_AnalysisRegionDA
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME                  DATE                    DETAIL FEATURES
    1.0         Kunal Patel                     2022-08-17                Initial version    
*********************************************************************************************************************/
@isTest public class SBR_3_0_AnalysisRegionDA_Test {

    @testSetup
    public static void CreateTestData()
    {
        List<Account> lAccount = SBR_3_0_TestDataFactory.createAccounts(1,TRUE);
        Analysis_Region__c oAR = SBR_3_0_TestDataFactory.createAnalysisRegion(TRUE,'921',lAccount[0].id);
    }

    static testMethod void testGetAnalysisRegionsbyId() {
        List<Id> arIds = new List<Id>();
        List<Analysis_Region__c> regions = [SELECT ID, Analysis_Region_Key__c FROM Analysis_Region__c];
        for(Analysis_Region__c ar : regions) {
            arIds.add(ar.Id);
        }

        Test.startTest();
            List<Analysis_Region__c> result = SBR_3_0_AnalysisRegionDA.getAnalysisRegions(arIds);
        Test.stopTest();

        System.assertEquals(regions.size(), result.size());
    }

    static testMethod void testGetAnalysisRegionsByKey() {
        Set<String> arKeys = new Set<String>();
        List<Analysis_Region__c> regions = [SELECT ID, Analysis_Region_Key__c FROM Analysis_Region__c];
        for(Analysis_Region__c ar : regions) {
            arKeys.add(ar.Analysis_Region_Key__c);
        }

        Test.startTest();
            List<Analysis_Region__c> result = SBR_3_0_AnalysisRegionDA.getAnalysisRegionsByKey(arKeys);
        Test.stopTest();

        System.assertEquals(regions.size(), result.size());
    }
}