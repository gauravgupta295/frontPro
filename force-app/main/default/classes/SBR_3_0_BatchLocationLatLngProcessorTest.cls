/*********************************************************************************************************************
* Apex Class: SBR_3_0_BatchLocationLatLngProcessorTest
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Class to test SBR_3_0_BatchLocationLatLngProcessorTest
* - 
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Kunal Patel             2023-03-13          Initial version    
*********************************************************************************************************************/
@isTest(seeAllData=false) 
public class SBR_3_0_BatchLocationLatLngProcessorTest Implements HttpCalloutMock{
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
	/************************************************************* Cover SBR_3_0_BatchLocationLatLongProcessor Starts*************************************************************/
    public Static testMethod void SBR_3_0_BatchLocationLatLongProcessor(){
        SUCCESSTEST = true;
		Profile oProfile = [SELECT Id FROM Profile WHERE Name='System Administrator' limit 1];
        User oUsers = SBR_3_0_TestDataFactory.createUser(TRUE,oProfile);

        // Create Location
        Schema.Location jobLocation = new Schema.Location();
        jobLocation.Name = 'Test Job Location';
        jobLocation.Street_Address__c = '12 Main Street';
        jobLocation.City__c = 'Toronto';
        jobLocation.Zip_Code__c = 'M7N7B3';
        jobLocation.State__c = 'ON';
        jobLocation.Country__c = 'CA';
        jobLocation.RecordTypeId = SBR_3_0_Constants.LOCATION_JOB_RT_ID;
        jobLocation.OMS_Sourcing_Enabled__c = true;
        jobLocation.Distance_Multiplier__c = 50;
        jobLocation.Analysis_Region_Key__c = '001';
        jobLocation.Company_Code__c = '01';

        List<Schema.Location> lLocation = new List<Schema.Location>();
        lLocation.add(jobLocation);
    	INSERT lLocation;
        Set<Id> sStreetAddresses = new Set<Id>();
        for(Schema.Location oLoc : lLocation){
        	sStreetAddresses.add(oLoc.id);
        }
        System.runAs(oUsers){
            Test.setMock(HttpCalloutMock.class, new SBR_3_0_BatchLocationLatLngProcessorTest());
            Test.startTest();
            
            SBR_3_0_BatchLocationLatLongProcessor oLatLong = new SBR_3_0_BatchLocationLatLongProcessor(sStreetAddresses, lLocation);
            Database.executeBatch(oLatLong, 10);
            Test.stopTest();
        }
    }
    /************************************************************* Cover SBR_3_0_BatchLocationLatLongProcessor Ends*************************************************************/
}