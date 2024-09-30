@istest
public class SBR_3_0_API_AccessToken_Dodge_Test implements HttpCalloutMock{
    
 
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
    @isTest static void initNamedApiHttpCalloutWithHeaders(){
               Credential__c cred = SBR_3_0_TestDataFactory.createCredentials(1, false)[0];
        cred.Name = 'Dodge_Token_Endpoint';
        cred.Key_Id__c = 'testKey123';
        cred.Secret__c = 'secret';
        insert cred;
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_AccessToken_Dodge_Test());
        SBR_3_0_API_AccessToken_DodgeProject callout= new SBR_3_0_API_AccessToken_DodgeProject();
         HTTPRequest req = callout.getRequest();
        HttpResponse res = callout.sendRequest();
      //  Cache.Org.put('local.CurrencyCache.DollarToEuroRate', '0.91');
         callout.getAccessToken(); 
        Test.stopTest();
    }
 @isTest static void getTokenFromCache(){
               
     Test.startTest();
       Cache.Org.put('testToken', '0.91');
      SBR_3_0_API_AccessToken_DodgeProject callout= new SBR_3_0_API_AccessToken_DodgeProject();
        
         callout.getTokenFromCache('testToken'); 
        Test.stopTest();
    }

}