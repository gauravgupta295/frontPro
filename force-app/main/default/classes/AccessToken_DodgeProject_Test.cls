/*********************************************************************************************************************
* Apex Class: AccessToken_DodgeProject_Test
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Test Class
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME                        DATE                DETAIL FEATURES
    1.0         Nate Kanyok				              2022-09-07          Initial version    
*********************************************************************************************************************/
@isTest
public class AccessToken_DodgeProject_Test implements HttpCalloutMock{
    private static final String TOKENNAME = 'DodgeToken';
    private static final String SOAPAction = 'http://constructionpoints.com/2011/07/token/ISecureToken/GetToken';

    @TestSetup
    static void makeData(){
        Credential__c cred = SBR_3_0_TestDataFactory.createCredentials(1, false)[0];
        cred.Name = 'Dodge_Token_Endpoint';
        cred.Key_Id__c = 'keyid';
        cred.Secret__c ='credSecret';
        insert cred;
    }

    public HTTPResponse respond(HTTPRequest req) {
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type',SBR_3_0_Constants.TEXT_XML);
        res.setHeader('SOAPAction',SOAPAction);
        res.setBody('{"access_token":"test"}');
        res.setStatusCode(200);
        return res;
    }

    @isTest
    static void testGetNewToken(){
        Test.setMock(HttpCalloutMock.class, new AccessToken_DodgeProject_Test());
        SBR_3_0_API_AccessToken_DodgeProject accessToken = new SBR_3_0_API_AccessToken_DodgeProject();

        Test.startTest();
            Object token = accessToken.getNewToken();
        	System.debug('token ' + token);
        Test.stopTest();

        System.assertNotEquals(null, token);
    }
    
    
    @isTest 
    static void testGetAccessToken() {
        SBR_3_0_API_AccessToken_DodgeProject accessToken = new SBR_3_0_API_AccessToken_DodgeProject();
        Cache.Org.put(TOKENNAME, 'testToken', 850);

        Test.startTest();
        Object token = accessToken.getAccessToken();
    	Test.stopTest();

        System.assertEquals(token, 'testToken', 'Failed to retrieve existing token.');
    }
    
    @isTest 
    static void testGetTokenLifetime() {
        SBR_3_0_API_AccessToken_DodgeProject accessToken = new SBR_3_0_API_AccessToken_DodgeProject();
        Token_Lifetime__c tokenSettings = new Token_Lifetime__c(Dodge_Token__c = 850);
        insert tokenSettings;

        Test.startTest();
        Integer ttl = accessToken.getTokenLifetime();
        Test.stopTest();

        System.assertEquals(ttl, 850, 'Token lifetime did not retrieve correctly.');
    }
    
    @isTest 
    static void testPutToken() {
        SBR_3_0_API_AccessToken_DodgeProject accessToken = new SBR_3_0_API_AccessToken_DodgeProject();

        Test.startTest();
        accessToken.putTokenIntoCache(TOKENNAME, 300);
        Test.stopTest();

        Object token = Cache.Org.get(TOKENNAME);

        System.assertEquals(TOKENNAME, token, 'Failed to retrieve correct token');
    }
    
    @isTest 
    static void testGetToken() {
        SBR_3_0_API_AccessToken_DodgeProject accessToken = new SBR_3_0_API_AccessToken_DodgeProject();

        Test.startTest();
        accessToken.putTokenIntoCache(TOKENNAME, 300);
        Object token = accessToken.getTokenFromCache(TOKENNAME);
        Test.stopTest();

        Object cacheToken = Cache.Org.get(TOKENNAME);
        System.assertEquals(TOKENNAME, cacheToken, 'Should have returned a null value, not an old token.');
    }
    
    @isTest 
    static void testGetNullToken() {
        SBR_3_0_API_AccessToken_DodgeProject accessToken = new SBR_3_0_API_AccessToken_DodgeProject();

        Test.startTest();
        Object token = accessToken.getTokenFromCache(TOKENNAME);
        Test.stopTest();

        System.assertEquals(null, token, 'Should have returned a null value, not an old token.');
    }
}