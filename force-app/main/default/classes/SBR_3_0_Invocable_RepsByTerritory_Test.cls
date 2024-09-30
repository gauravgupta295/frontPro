@isTest
public with sharing class SBR_3_0_Invocable_RepsByTerritory_Test Implements HttpCalloutMock {
    
    @TestSetup
    static void makeData(){
        Credential__c cred = SBR_3_0_TestDataFactory.createCredentials(1, false)[0];
        cred.Name = 'Mule_Token_Endpoint';
        cred.Key_Id__c = 'testKey123';
        cred.Secret__c = 'secret';
        insert cred;
        
        Profile p2 = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        String adminUserName = 'systemadmin' + DateTime.now().getTime() + '@sunbeltrentals.com';
        User adminUser = new User(Alias = 'standt', Email='systemadmin@sunbeltrentals.com',
        EmailEncodingKey='UTF-8', LastName='adminTest', LanguageLocaleKey='en_US',
        LocaleSidKey='en_US', ProfileId = p2.Id,
        TimeZoneSidKey='America/Los_Angeles',
        UserName=adminUserName);
        adminUser.RepId__c = '131001';
        insert adminUser;

        List<Schema.Location> branches = SBR_3_0_TestDataFactory.createLocations(1, true, SBR_3_0_Constants.LOCATION_REC_TYPE_BRANCH);
        User_Location__c ul = new User_Location__c();
        ul.Branch__c = branches[0].Id;
        ul.User__c = adminUser.Id;
        insert ul;
    }
    public HTTPResponse respond(HTTPRequest req) {
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type',SBR_3_0_Constants.APP_JSON);
        if(req.getEndpoint().endsWithIgnoreCase('token')){
            res.setBody('{"access_token":"test"}');
            
        }else {
            res.setBody('{\"data\":{\"territories\":[{\"pcId\":1310,\"territory\":10,\"section\":1,\"territoryId\":\"1-1310-10-1\",\"mapSource\":\"GT\",\"mapAnalysisRegion\":920,\"salesRepId\":131001,\"salesRepName\":\"WOODY,TERRY(1310)\"}],\"prospectType\":\"Account\"}}');
        }
        res.setStatusCode(200);
        return res;
    }

    @isTest
    static void testFetchTerritoryReps() {
        List<SBR_3_0_Invocable_RepsByTerritory.RepRequest> repRequests = new List<SBR_3_0_Invocable_RepsByTerritory.RepRequest>();
        SBR_3_0_Invocable_RepsByTerritory.RepRequest repRequest = new SBR_3_0_Invocable_RepsByTerritory.RepRequest();
        repRequest.latitude = '38.8';
        repRequest.longitude = '38.8';
        repRequest.analysisRegion = '920';
        repRequests.add(repRequest);

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_Invocable_RepsByTerritory_Test());
        List<SBR_3_0_Invocable_RepsByTerritory.RepResponse> repResponses = SBR_3_0_Invocable_RepsByTerritory.fetchTerritoryReps(repRequests);
        SBR_3_0_Invocable_RepsByTerritory.RepResponse repResponse = repResponses[0];
        system.debug(repResponses[0].users);
        Test.stopTest();

        System.assertEquals('131001', repResponse.users[0].RepId__c, 'Rep not being returned');
        
        
    }
}