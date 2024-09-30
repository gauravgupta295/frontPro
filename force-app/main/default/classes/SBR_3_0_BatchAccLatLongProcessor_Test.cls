/*********************************************************************************************************************
* Apex Class: SBR_3_0_BatchAccLatLongProcessor_Test
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Class to test SBR_3_0_BatchAccountLatLongProcessor
* - 
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Saathvik Tulasi      2023-01-11             Initial version    
*********************************************************************************************************************/
@isTest(seeAllData=false) 
public class SBR_3_0_BatchAccLatLongProcessor_Test Implements HttpCalloutMock{
    static Boolean SUCCESSTEST = true;
    @TestSetup
    static void makeData(){       
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
        }else if (SUCCESSTEST) {
            res.setBody('{ "message": "Custom Error Message", "data": { "results": [ { "addressComponents": [ { "longName": "6365", "shortName": "6365", "types": [ "street_number" ] }, { "longName": "Multiplex Drive", "shortName": "Multiplex Dr", "types": [ "route" ] }, { "longName": "Centreville", "shortName": "Centreville", "types": [ "locality", "political" ] }, { "longName": "Fairfax County", "shortName": "Fairfax County", "types": [ "administrative_area_level_2", "political" ] }, { "longName": "Virginia", "shortName": "VA", "types": [ "administrative_area_level_1", "political" ] }, { "longName": "United States", "shortName": "US", "types": [ "country", "political" ] }, { "longName": "20121", "shortName": "20121", "types": [ "postal_code" ] } ], "formattedAddress": "6365 Multiplex Dr, Centreville, VA 20121, USA", "geometry": { "location": { "latitude": 38.82717, "longitude": -77.439927 }, "locationType": "ROOFTOP", "viewport": { "northeast": { "latitude": 38.8286634802915, "longitude": -77.43860981970849 }, "southwest": { "latitude": 38.8259655197085, "longitude": -77.44130778029151 } } }, "placeId": "ChIJC0C2DMJEtokR4Kx6xT21ctk", "types": [ "street_address" ] } ] } }');
        } else {
            res.setBody('{ "data": {} }');
        }
        res.setStatusCode(200);
        return res;
    }
	/************************************************************* Cover SBR_3_0_BatchAccLatLongProcessor Starts*************************************************************/
    public Static testMethod void SBR_3_0_BatchAccLatLongProcessor(){
        SUCCESSTEST = true;
		Profile oProfile = [SELECT Id FROM Profile WHERE Name='System Administrator' limit 1];
        User oUsers = SBR_3_0_TestDataFactory.createUser(TRUE,oProfile);
        List<Account> lAccounts = SBR_3_0_TestDataFactory.createAccounts(10,false,SBR_3_0_Constants.ACCOUNT_REC_TYPE_PROSPECT);
        lAccounts[0].Override_Address__Street__s = '6217 Highland Ave';
        lAccounts[0].Override_Address__City__s = 'Haltom City';
        lAccounts[0].Override_Address__StateCode__s = 'TX';
        lAccounts[0].Override_Address__PostalCode__s = '76117';
        lAccounts[0].Override_Address__CountryCode__s = 'US';
        INSERT lAccounts;
        Set<Id> sStreetAddresses = new Set<Id>();
        Set<Id> sOverrideAddresses = new Set<Id>();
        Set<Id> billingAddresses = new Set<Id>();
        for(Account oAccount : lAccounts){
        	sStreetAddresses.add(oAccount.id); 
            sOverrideAddresses.add(oAccount.id);
            billingAddresses.add(oAccount.Id);
        }
        System.runAs(oUsers){
            Test.setMock(HttpCalloutMock.class, new SBR_3_0_BatchAccLatLongProcessor_Test());
            Test.startTest();
            
            SBR_3_0_BatchAccountLatLongProcessor oLatLong = new SBR_3_0_BatchAccountLatLongProcessor(sStreetAddresses,sOverrideAddresses,billingAddresses,lAccounts);
            Database.executeBatch(oLatLong, 10);
            Test.stopTest();
        }
    }
    /************************************************************* Cover SBR_3_0_BatchAccLatLongProcessor Ends*************************************************************/
}