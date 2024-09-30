@isTest
public with sharing class SBR_3_0_API_FetchAlternateItems_Test implements HttpCalloutMock {
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
        }else {
            res.setBody('{ "data": { "pc": "01-0105","latitude": 48.51, "longitude": -117.62, "companyId": "01","isLastResortBranch": true,"fulfillmentPercent": 0.0 }}');
        }
        res.setStatusCode(200);
        return res;
    }

    @isTest 
    public static void testGetAlternatesTest(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_FetchAlternateItems_Test());
        SBR_3_0_WrapAlternateItems.ATIRequest obj = new SBR_3_0_WrapAlternateItems.ATIRequest();
        //obj.companyId='01';
        obj.cartId ='5242f682-13de-4b77-a654-612a62ab782e';
        obj.sellingChannel = 'SBRB2B';
        obj.fulfillmentType ='DEL';
        obj.timezoneId='America';
        obj.requestedDeliveryDate = '2025-05-10T23:00:00+00:00';
        obj.transactionType='SBR';
         
        

        SBR_3_0_WrapAlternateItems.Products p = new SBR_3_0_WrapAlternateItems.Products();
      
        p.productId = '0012394';
        p.uom='test';
        obj.products = new List<SBR_3_0_WrapAlternateItems.Products>();
        obj.products.add(p);
        String s = JSON.serializePretty(obj);
        System.debug('\n obj = ' + s);
        String resp = SBR_3_0_API_FetchAlternateItems.getAlternateItemsTest(obj,'01');
        System.debug(resp);
        System.assertEquals(resp, '{ "data": { "pc": "01-0105","latitude": 48.51, "longitude": -117.62, "companyId": "01","isLastResortBranch": true,"fulfillmentPercent": 0.0 }}');
        Test.stopTest();

    }
  

    
    
    @isTest
    public static void testGetAlternatesForNullResp(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_FetchAlternateItems_Test());
        SBR_3_0_WrapAlternateItems.ATIRequest obj = new SBR_3_0_WrapAlternateItems.ATIRequest();
       //obj.companyId='01';
        obj.cartId ='5242f682-13de-4b77-a654-612a62ab782e';
        obj.sellingChannel = 'SBRB2B';
        obj.fulfillmentType ='DEL';
        SBR_3_0_WrapAlternateItems.Products p = new SBR_3_0_WrapAlternateItems.Products();
        p.productId = '0012394';
        p.uom='test';
        obj.products = new List<SBR_3_0_WrapAlternateItems.Products>();
        obj.products.add(p);
        String s = JSON.serializePretty(obj);
        System.debug('\n obj = ' + s);
        obj = null;
        SBR_3_0_WrapAlternateItems.ATIResponse resp = SBR_3_0_API_FetchAlternateItems.getAlternateItems(obj,'');
        System.debug(resp);
        System.assertEquals(resp.data.companyId, '01');
        Test.stopTest();

    }
}