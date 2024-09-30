@isTest
public with sharing class SBR_3_0_Invocable_GetTerrNum_Test {
    @isTest
    static void testGetTerritoryNumber(){
        String testString = 'before:after';
        List<String> testStrings = new List<String>();
        testStrings.add(testString);
        List<SBR_3_0_Invocable_GetTerritoryNumber.Request> requests = new List<SBR_3_0_Invocable_GetTerritoryNumber.Request>();
        SBR_3_0_Invocable_GetTerritoryNumber.Request request = new SBR_3_0_Invocable_GetTerritoryNumber.Request();
        request.repAndTerritoryMap = testStrings;
        request.selectedRepId = 'before';
        requests.add(request);

        test.startTest();
        List<SBR_3_0_Invocable_GetTerritoryNumber.Response> responses = SBR_3_0_Invocable_GetTerritoryNumber.getTerritoryNumber(requests);
        test.stopTest();

        system.assertEquals('after', responses[0].territoryNumber);

    }
}