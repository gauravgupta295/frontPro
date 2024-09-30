@isTest
public with sharing class SBR_3_0_BatchOppLatLongProcessor_Test implements HttpCalloutMock
{
   static Boolean successfulTest;
    @TestSetup
    static void makeData()
    {       
        Credential__c cred = SBR_3_0_TestDataFactory.createCredentials(1, false)[0];
        cred.Name = 'Mule_Token_Endpoint';
        cred.Key_Id__c = 'testKey123';
        cred.Secret__c = 'secret';
        insert cred;
    }

    public HTTPResponse respond(HTTPRequest req) {
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type',SBR_3_0_Constants.APP_JSON);
        if(req.getEndpoint().endsWithIgnoreCase('token')){
            res.setBody('{"access_token":"test"}');
        }
        else if(successfulTest)
        {
            res.setBody('{"message": "Custom Error Message", "data": {"geoInfo": {"latitude": 38.82717,"longitude": -77.439927}}}');
            //res.setBody('{ "message": "Custom Error Message", "data": { "results": [ { "addressComponents": [ { "longName": "2124", "shortName": "2124", "types": [ "street_number" ] }, { "longName": "Fake Road Drive", "shortName": "Fake Road Dr", "types": [ "route" ] }, { "longName": "Winston-Salem", "shortName": "Winston-Salem", "types": [ "locality", "political" ] }, { "longName": "Wake County", "shortName": "Wake County", "types": [ "administrative_area_level_2", "political" ] }, { "longName": "North Carolina", "shortName": "NC", "types": [ "administrative_area_level_1", "political" ] }, { "longName": "United States", "shortName": "US", "types": [ "country", "political" ] }, { "longName": "27123", "shortName": "27123", "types": [ "postal_code" ] } ], "formattedAddress": "2124 Fake Road Dr, Winston-Salem, NC 22123, USA", "geometry": { "location": { "latitude": 38.82717, "longitude": -77.439927 }, "locationType": "ROOFTOP", "viewport": { "northeast": { "latitude": 38.8286634802915, "longitude": -77.43860981970849 }, "southwest": { "latitude": 38.8259655197085, "longitude": -77.44130778029151 } } }, "placeId": "ChIJC0C2DMJEtokR4Kx6xT21ctk", "types": [ "street_address" ] } ] } }');
        } 
        else 
        {
            res.setBody('{ "data": {} }');
        }
        res.setStatusCode(200);
        return res;
    }

    
    @isTest
    static void testExecuteSuccess()
    {
       successfulTest = true;

       Set <Id> idSet = new Set<Id>();
       Opportunity opp = new Opportunity();
       opp.Name = 'Test';
       opp.City__c = 'Winston-Salem';
       opp.State__c = 'NC';
       opp.ZIP_Code__c = '27123';
       opp.Country__c = 'US';
       opp.Street__c = ' 2124 Fake Road Dr';
       opp.StageName = '--None--';
       opp.CloseDate = date.newInstance(1990, 11, 21);
       idSet.add(opp.Id);
        insert opp;

        List<Opportunity> oppList = [SELECT Id, Latitude_Longitude_Status__c
        FROM Opportunity];

        for (Opportunity o : oppList) {
            idSet.add(o.Id);
        }
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_BatchOppLatLongProcessor_Test());
        SBR_3_0_BatchOpptLatLongProcessor proc = new SBR_3_0_BatchOpptLatLongProcessor(idSet);
        Database.executeBatch(proc);
        Test.stopTest();
        List<Opportunity> updatedOpportunities = [SELECT Id, Latitude_Longitude_Status__c, Latitude_Longitude_error__c
                                                FROM Opportunity];
        System.assertEquals('Success', updatedOpportunities[0].Latitude_Longitude_Status__c,'Status should be changed to Success');
    }

    @isTest
    static void testExecuteError()
    {
        Opportunity opp = new Opportunity();
       opp.Name = 'Test';
       opp.City__c = 'Winston-Salem';
       opp.State__c = 'NC';
       opp.ZIP_Code__c = '27123';
       opp.Country__c = 'US';
       opp.Street__c = ' 2124 Fake Road Dr';
       opp.StageName = '--None--';
       opp.CloseDate = date.newInstance(1990, 11, 21);
       insert opp;
        successfulTest = false;

        Set <Id> idSet = new Set<Id>();
        List<Opportunity> oppList = [SELECT Id, Latitude_Longitude_Status__c
        FROM Opportunity];
        
        for (Opportunity o : oppList) {
            idSet.add(o.Id);
        }

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_BatchOppLatLongProcessor_Test());
        SBR_3_0_BatchOpptLatLongProcessor proc = new SBR_3_0_BatchOpptLatLongProcessor(idSet);
        Database.executeBatch(proc);
        Test.stopTest();

        List<Opportunity> updatedOpportunities = [SELECT Id, Latitude_Longitude_Status__c, Latitude_Longitude_error__c
                                                FROM Opportunity];
        System.assertEquals('Error', updatedOpportunities[0].Latitude_Longitude_Status__c,'Status should be changed to Success');
        System.assertEquals('Latitude, Longitude not captured; please contact support.', updatedOpportunities[0].Latitude_Longitude_error__c);
    }

}