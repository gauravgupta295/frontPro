@isTest
public with sharing class SBR_3_0_API_FetchTerritoryTest implements HttpCalloutMock{
    @TestSetup
    static void makeData(){
        Credential__c cred = SBR_3_0_TestDataFactory.createCredentials(1, false)[0];
        cred.Name = 'Mule_Token_Endpoint';
        cred.Key_Id__c = 'testKey123';
        cred.Secret__c = 'secret';
        insert cred;
        
        Territory__c terri = new Territory__c();
        terri.Name = 'Terri1';
        terri.Territory_Id__c = '1';
        terri.OwnerId = UserInfo.getUserId();
        insert terri;
    }
    public HTTPResponse respond(HTTPRequest request) {
        // Create a fake response
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        if(request.getEndpoint().endsWithIgnoreCase('token')){
            response.setBody('{"access_token":"test"}');
        } else{
            response.setBody('{ "data": { "territories": [ { "pcId": 577, "territory": 21, "section": 1, "territoryId": 1, "mapSource": "PowerCom", "mapAnalysisRegion": 922, "salesRepId": 57713, "salesRepName": "CASLER, JACOB (577) " } ], "prospectType": "Project" } }');
        }
        response.setStatusCode(200);
        return response; 
    }
    
	@isTest
    static void testGetTerritoryDetails() {       
        Test.startTest();
            Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_FetchTerritoryTest());
        	SBR_3_0_API_FetchTerritory fetchTerritory = new SBR_3_0_API_FetchTerritory();
            List<object> objLst = fetchTerritory.getTerritoryDetails('41.09', '49.09', 'Account');
        Test.stopTest();
        system.assert(objLst.size()>0);
    }
    
    @isTest
    static void testGetTerritoryIdOwnerMatch() {       
        Test.startTest();
            Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_FetchTerritoryTest());
        	SBR_3_0_API_FetchTerritory fetchTerritory = new SBR_3_0_API_FetchTerritory();
            Map<String,String> strMap = fetchTerritory.getTerritoryIdOwnerMatch('41.09', '49.09', 'Account');
        Test.stopTest();
        system.assert(!strMap.isEmpty());
    }
}