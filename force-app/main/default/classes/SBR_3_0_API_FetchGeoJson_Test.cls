/*********************************************************************************************************************
* Apex Class: SBR_3_0_API_FetchGeoJson_Test
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Test Class for SBR_3_0_API_FetchGeoJson
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Kunal Patel           2022-10-25            Initial version  
*********************************************************************************************************************/

@isTest
public with sharing class SBR_3_0_API_FetchGeoJson_Test implements HttpCalloutMock {

    @TestSetup
    static void makeData(){
        Credential__c cred = SBR_3_0_TestDataFactory.createCredentials(1, false)[0];
        cred.Name = 'Mule_Token_Endpoint';
        cred.Key_Id__c = 'testKey123';
        cred.Secret__c = 'secret';
        insert cred;

        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
        User user = new User(Alias = 'standt', Email='standardperson@testorg.com', 
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', ProfileId = p.Id, 
        TimeZoneSidKey='America/Los_Angeles', UserName='standardperson@testorg.com');

        insert user;


        Schema.Location loc = new Schema.Location();
        loc.latitude = 39.3591487;
        loc.longitude = -77.7315348;
        Territory__c terri = new Territory__c();
        terri.Name = 'Terri1';
        terri.Territory_Id__c = '123';
        //terri.Map_Analysis_Region__c = loc.Id;
        terri.OwnerId = UserInfo.getUserId();
        insert terri;

        List<Account> accountList = SBR_3_0_TestDataFactory.createAccounts(2, true, SBR_3_0_Constants.ACCOUNT_REC_TYPE_PROSPECT);


        Account_Relationship__c ar = new Account_Relationship__c();
        ar.User_Account__c = user.Id;
        ar.Account_ID__c = accountList[0].Id;
        ar.Territory__c = terri.Id;
        insert ar;
    }
    
   public HTTPResponse respond(HTTPRequest req) {
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type',SBR_3_0_Constants.APP_JSON);
        if(req.getEndpoint().endsWithIgnoreCase('token')){
            res.setBody('{"access_token":"test"}');
            
        }else {
            res.setBody('{"data":{"coordinates":[[[-80.24801028, 26.00923663], [-80.24425000, 26.00935000], [-80.23169000, 26.00965000]]], "type":"Polygon"}}');
        }
        res.setStatusCode(200);
        return res;
    }
    /*public HTTPResponse respond(HTTPRequest req) {
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type',SBR_3_0_Constants.APP_JSON);
        if(req.getEndpoint().endsWithIgnoreCase('token')){
            res.setBody('{}');
            
        }else {
            res.setBody('{}');
        }
        res.setStatusCode(200);
        return res;
    }*/
    /*public HttpResponse respond(HTTpRequest request) {
        CalloutException e = (CalloutException)CalloutException.class.newInstance();
        e.setMessage('Unauthorized endpoint, please check Setup->Security->Remote site settings.');
        throw e;
        
    }*/

    @isTest
    static void testGetTerritoryGeoJson()
    {
        Test.startTest();
       // SBR_3_0_API_FetchGeoJson fetch1 = new SBR_3_0_API_FetchGeoJson();
     //   String result1 = fetch1.getResponseBody();
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_FetchGeoJson_Test());
        SBR_3_0_API_FetchGeoJson fetch = new SBR_3_0_API_FetchGeoJson();
        String result = fetch.getTerritoryGeoJson('123');
 		System.assertNotEquals(0, result.length());
        Test.stopTest();
    }
}