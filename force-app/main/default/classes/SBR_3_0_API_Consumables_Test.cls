@isTest
public with sharing class SBR_3_0_API_Consumables_Test Implements HttpCalloutMock{
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
            // Access Token Response
            res.setBody('{"access_token":"test"}');
        }else if(req.getEndpoint().endsWithIgnoreCase('consumables')){
            // Consumables Response here
            res.setBody('{"data":{"suggestedItems":[{"catId":"20","classId":"615","rentables":[],"consumables":[{"inventoryClass":"206","invClassDescription":"PPE, RESPIRATORY","specGroups":[{"specNumber":"206-0002","title":"Disposable Respirator","specDescription":"Disposable Respirator","minPrice":6,"maxPrice":6,"products":[{"productNumber":"817633","stockClass":"PIPSA","oemStockNumber":"10102481","productDescription":"N95 HARMFUL DUST RESPIRATOR 2 PACK","priceSchedule":"","sequence":"10","forceItem":"N","minQuantity":0,"sellingPrice":6,"availQuantity":25,"binNumber1":"SC3","binNumber2":"","binNumber3":"","rentalCat":"0","rentalClass":"0","isSerialized":false}]}]}]}]}}');
        }
        
        res.setStatusCode(200);
        return res;
    }

    @isTest
    static void testGetConsumableRates() {
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_Consumables_Test());
        Test.startTest();
            String requestJson = '{"pc":"0720","accountNumber":"4","jobsiteNumber":"CO MEDIMMUNE BOULDER","products":[{"catId":"020","classId":"0615"}]}';
            String response = SBR_3_0_API_Consumables.getConsumableRates(requestJson, '1');
            SBR_3_0_API_ConsumablesResponse wrappedResponse = SBR_3_0_API_ConsumablesResponse.parse(response);
        Test.stopTest();
        System.assert(String.isNotEmpty(response), 'No Consumables Rates Data Received From API');        
        System.assertEquals('20', wrappedResponse.data.suggestedItems[0].catId, 'catId does not match');
        System.assertEquals('PPE, RESPIRATORY', wrappedResponse.data.suggestedItems[0].consumables[0].invClassDescription, 'inventory class description does not match');
    }
}