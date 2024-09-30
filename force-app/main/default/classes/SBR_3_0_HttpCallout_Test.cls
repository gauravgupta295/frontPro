/*********************************************************************************************************************
* Apex Class: SBR_3_0_HttpCallout_Test
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Test class for SBR_3_0_HttpCallout class
* - SAL
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Avinash Rao				2022-02-22			Initial version    
*********************************************************************************************************************/

@isTest
private class SBR_3_0_HttpCallout_Test implements HttpCalloutMock {
    @TestSetup
    static void makeData(){
        Credential__c cred = SBR_3_0_TestDataFactory.createCredentials(1, false)[0];
        cred.Name = 'Mule_Token_Endpoint';
        cred.Key_Id__c = 'testKey123';
        cred.Secret__c = 'secret';
        insert cred;
        //system.debug([select id,name from Credential__c]);
    }
    // Implement this interface method
    public HTTPResponse respond(HTTPRequest req) {
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type',SBR_3_0_Constants.APP_JSON);
        if(req.getEndpoint().endsWithIgnoreCase('token')){
            res.setBody('{"access_token":"test"}');
            
        }else {
        res.setBody('{ "data": { "results": [ { "addressComponents": [ { "longName": "6365", "shortName": "6365", "types": [ "street_number" ] }, { "longName": "Multiplex Drive", "shortName": "Multiplex Dr", "types": [ "route" ] }, { "longName": "Centreville", "shortName": "Centreville", "types": [ "locality", "political" ] }, { "longName": "Fairfax County", "shortName": "Fairfax County", "types": [ "administrative_area_level_2", "political" ] }, { "longName": "Virginia", "shortName": "VA", "types": [ "administrative_area_level_1", "political" ] }, { "longName": "United States", "shortName": "US", "types": [ "country", "political" ] }, { "longName": "20121", "shortName": "20121", "types": [ "postal_code" ] } ], "formattedAddress": "6365 Multiplex Dr, Centreville, VA 20121, USA", "geometry": { "location": { "latitude": 38.82717, "longitude": -77.439927 }, "locationType": "ROOFTOP", "viewport": { "northeast": { "latitude": 38.8286634802915, "longitude": -77.43860981970849 }, "southwest": { "latitude": 38.8259655197085, "longitude": -77.44130778029151 } } }, "placeId": "ChIJC0C2DMJEtokR4Kx6xT21ctk", "types": [ "street_address" ] } ] } }');
        }
        res.setStatusCode(200);
        return res;
    }
	/*//test default http callout
    @isTest static void initHttpCallout(){
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_HttpCallout_Test());
        SBR_3_0_HttpCallout httpCallout = new SBR_3_0_HttpCallout();
        System.debug('httpCallout--->'+httpCallout);
        HTTPRequest req = httpCallout.getRequest();
        HttpResponse res = httpCallout.sendRequest();
    }*/
    //test http callout using api name and a single header
    @isTest static void initNamedApiHttpCalloutWithHeader(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_HttpCallout_Test());
        SBR_3_0_HttpCallout httpCallout = new SBR_3_0_HttpCallout('Lat_Long_Check');
        HTTPRequest req = httpCallout.getRequest();
        HttpResponse res = httpCallout.sendRequest();
        httpCallout.setHeader('Content-Type', 'text/html');
        httpCallout.setQueryParam('color', 'blue');
        httpCallout.setRequestBody('request body as string');
        httpCallout.setPathParams(new List<String>{'home','dashboard'});
        try{
        	httpCallout.getPathParams(new Global_API_Settings__mdt(),new List<String>{'home','dashboard'});
        }
        Catch(Exception e){
            
        }
        Test.stopTest();
    }
    //test http callout using api name and a header map
    @isTest static void initNamedApiHttpCalloutWithHeaders(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_HttpCallout_Test());
        SBR_3_0_HttpCallout httpCallout = new SBR_3_0_HttpCallout('Lat_Long_Check');
        HTTPRequest req = httpCallout.getRequest();
        HttpResponse res = httpCallout.sendRequest();
        Map<String, String> headersMap = new Map<String, String>();
        headersMap.put('Content-Type','text/html');
        headersMap.put('Width','1920');
        httpCallout.setHeadersMap(headersMap);
        Map<String, String> queryParamsMap = new Map<String, String>();
        queryParamsMap.put('color', 'blue');
        queryParamsMap.put('size', 'xl');
        httpCallout.setQueryParamsMap(queryParamsMap);
        Blob blobReqBody = Blob.valueOf('request body as blob');
        httpCallout.setRequestBody(blobReqBody);
        Test.stopTest();
    }
    //test http callout using api name and a header map
    @isTest static void getCredName(){
        Test.startTest();
        SBR_3_0_HttpCallout Callout = new SBR_3_0_HttpCallout();
        Callout.getCredName();
        Test.stopTest();
    }
}