/*********************************************************************************************************************
* Apex Class: SBR_3_0_HttpCallout_Test
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Test class for SBR_3_0_HttpResponse class
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Tyler Niggel			2022-03-21			Initial version 
	1.2			Delvin Riley			2023-10-12			P2P Added Test Cases
*********************************************************************************************************************/
@isTest
public with sharing class SBR_3_0_HttpResponse_Test {
    @isTest static void testGetValueForKey() {
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', SBR_3_0_Constants.APP_JSON);
        response.setBody('{"access_token":"test"}');
        response.setStatusCode(200);

        Test.startTest();
        Object token = SBR_3_0_HttpResponse.getValueForKey(response,SBR_3_0_Constants.TOKEN_KEY);
        Test.stopTest();

        System.assertEquals(token, 'test', 'Failed to process response correctly.');
    }
    @isTest static void testNullKey() {
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', SBR_3_0_Constants.APP_JSON);
        response.setBody('{"data":"test"}');
        response.setStatusCode(200);

        Test.startTest();
        Object token = SBR_3_0_HttpResponse.getValueForKey(response,SBR_3_0_Constants.TOKEN_KEY);
        Test.stopTest();

        System.assertEquals(token, null, 'Failed to return null if key not found.');
    }
    @istest
    public static void setResponse()
    {
            RestRequest req = new RestRequest(); 
    RestResponse res = new RestResponse();

    req.requestURI = 'https://na11.salesforce.com';  // sample Endpoint
    req.httpMethod = 'GET';
    RestContext.request = req;
    RestContext.response = res;
        SBR_3_0_HttpResponse resp= new SBR_3_0_HttpResponse();
        Map<String,String> respMap = new Map<String,String>();
        respMap.put('data','test');
        SBR_3_0_HttpResponse.setRestResponse(respMap,400);
Object obj=SBR_3_0_HttpResponse.setResponseMessage('500','534');
        System.assertNotEquals(null, obj);
    }
     @istest
    public static void setResponseXML()
    {   HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/xml');
        res.setBody('<foo>tt</foo>');
        res.setStatusCode(200);
  Object data= SBR_3_0_HttpResponse.getValueFromXMLTags(res, 'foo');
     system.assertEquals(data+'','tt');
     
    }
     @istest
    public static void p2pSetResponse()
    {
            RestRequest req = new RestRequest(); 
    RestResponse res = new RestResponse();
    SBQQ__Quote__c quote = new SBQQ__Quote__c();

    req.requestURI = 'https://na11.salesforce.com';  // sample Endpoint
    req.httpMethod = 'GET';
    RestContext.request = req;
    RestContext.response = res;
    
        SBR_3_0_HttpResponse resp= new SBR_3_0_HttpResponse();
        Map<String,SObject> respMap = new Map<String,SObject>();
        respMap.put('data', quote);
        SBR_3_0_HttpResponse.p2pSetRestResponse(respMap,400);
        //System.assertNotEquals(null, obj);
    }
}