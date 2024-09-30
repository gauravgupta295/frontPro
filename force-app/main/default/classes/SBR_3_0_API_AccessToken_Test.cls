/*********************************************************************************************************************
* Apex Class: SBR_3_0_API_AccessToken_Test
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Test class for SBR_3_0_API_AccessToken
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Tyler Niggel            2022-03-11          Initial version    
*********************************************************************************************************************/
@isTest
public class SBR_3_0_API_AccessToken_Test implements HttpCalloutMock {
    static Boolean NULLRESPONSE = false;
    private static final String APINAME = 'Mule_Token_Endpoint'; // pull this from the Custom metadata  Mule_Token_Endpoint
    private static final String TOKENNAME = 'MuleJWT';

    public HTTPResponse respond(HTTPRequest req) {
        // Create a fake response
        if(NULLRESPONSE) {
            HttpResponse res = new HttpResponse();
            return res;
        } else {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type',SBR_3_0_Constants.APP_JSON);
            res.setBody('{"access_token":"test"}');
            res.setStatusCode(200);
            return res;
        }
        
    }

    @isTest static void testGetExistingToken() {
        SBR_3_0_API_AccessToken accessToken = new SBR_3_0_API_AccessToken();
        Cache.Org.put(TOKENNAME, 'testToken', 850);

        Test.startTest();
        Object token = accessToken.getAccessToken();
        Test.stopTest();

        System.assertEquals(token, 'testToken', 'Failed to retrieve existing token.');
    }

    @isTest(SeeAllData=true) static void testGetNewToken() {
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_AccessToken_Test());
        SBR_3_0_HttpCallout httpCallout = new SBR_3_0_HttpCallout(APINAME);
        SBR_3_0_API_AccessToken accessToken = new SBR_3_0_API_AccessToken();

        Test.startTest();
        Object jwt = accessToken.getNewJWT();
        Test.stopTest();

        System.assertNotEquals(jwt, null, 'Failed to retrieve a new valid JWT.');
    }

    @isTest static void testGetNullToken() {
        SBR_3_0_API_AccessToken accessToken = new SBR_3_0_API_AccessToken();

        Test.startTest();
        Object token = accessToken.getTokenFromCache(TOKENNAME);
        Test.stopTest();

        System.assertEquals(token, null, 'Should have returned a null value, not an old token.');
    }

    @isTest static void testNullResponseCheck() {
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_AccessToken_Test());
        SBR_3_0_HttpCallout httpCallout = new SBR_3_0_HttpCallout(APINAME);
        SBR_3_0_API_AccessToken accessToken = new SBR_3_0_API_AccessToken();

        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type',SBR_3_0_Constants.APP_JSON);
        res.setBody('{"keyID":"test"}');
        res.setStatusCode(200);


        Test.startTest();
        Boolean nullCheck;
        try {
            nullCheck = accessToken.checkNullResponse(res);
        } catch (Exception e) {
            System.debug('Exception thrown.');
        }
        Test.stopTest();

        System.assertEquals(true, nullCheck);
    }

    @isTest static void testNullResponseCheckWithNullRes() {
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_AccessToken_Test());
        SBR_3_0_HttpCallout httpCallout = new SBR_3_0_HttpCallout(APINAME);
        SBR_3_0_API_AccessToken accessToken = new SBR_3_0_API_AccessToken();

        HttpResponse res = new HttpResponse();
        res = null;


        Test.startTest();
        Boolean nullCheck;
        try {
            nullCheck = accessToken.checkNullResponse(res);
        } catch (Exception e) {
            System.debug('Exception thrown.');
        }
        Test.stopTest();

        System.assertEquals(true, nullCheck);
    }

    @isTest(SeeAllData=true) static void testGetNewTokenNullRes() {
        NULLRESPONSE = true;
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_AccessToken_Test());
        SBR_3_0_HttpCallout httpCallout = new SBR_3_0_HttpCallout(APINAME);
        SBR_3_0_API_AccessToken accessToken = new SBR_3_0_API_AccessToken();

        Test.startTest();
        Boolean nullCheck;
        try {
            Object jwt = accessToken.getNewJWT();
            nullCheck = false;
        } catch (Exception e) {
            nullCheck = true;
        }
        Test.stopTest();

        System.assertEquals(true, nullCheck);
    }

    @isTest static void testNullResponseCheckBadJSON() {
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_AccessToken_Test());
        SBR_3_0_HttpCallout httpCallout = new SBR_3_0_HttpCallout(APINAME);
        SBR_3_0_API_AccessToken accessToken = new SBR_3_0_API_AccessToken();

        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type',SBR_3_0_Constants.APP_JSON);
        res.setBody('testdata');
        res.setStatusCode(200);

        Test.startTest();
        Boolean nullCheck = accessToken.checkNullResponse(res);
        Test.stopTest();

        System.assertEquals(true, nullCheck);
    }


    @isTest static void testGetTokenLifetime() {
        SBR_3_0_API_AccessToken accessToken = new SBR_3_0_API_AccessToken();
        Mulesoft_jwt__c tokenSettings = new Mulesoft_jwt__c(Token_Lifetime__c = 850);
        insert tokenSettings;

        Test.startTest();
        Integer ttl = accessToken.getTokenLifetime();
        Test.stopTest();

        System.assertEquals(ttl, 850, 'Token lifetime did not retrieve correctly.');
    }

    @isTest static void testPutToken() {
        SBR_3_0_API_AccessToken accessToken = new SBR_3_0_API_AccessToken();

        Test.startTest();
        accessToken.putTokenIntoCache('testToken', 300);
        Test.stopTest();

        Object token = Cache.Org.get(TOKENNAME);

        System.assertEquals(token, 'testToken', 'Failed to retrieve correct token');
    }
}