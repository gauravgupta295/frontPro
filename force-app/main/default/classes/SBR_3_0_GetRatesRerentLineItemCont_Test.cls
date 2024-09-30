@isTest
public class SBR_3_0_GetRatesRerentLineItemCont_Test Implements HttpCalloutMock  {
    @TestSetup
    static void testGetPOData() {
        Credential__c cred = SBR_3_0_TestDataFactory.createCredentials(1, false)[0];
        cred.Name = 'Mule_Token_Endpoint';
        cred.Key_Id__c = 'testKey123';
        cred.Secret__c = 'secret';
        insert cred;
        
        // Test data setup
   			Account testVendor = new Account(
            Name='Z Test Vendor',
            Account_Type__c = 'Non Credit',
            BillingCity = 'NY',
            BillingCountry = 'US',
            BillingCountryCode = 'US',
            BillingPostalCode = '43215',
            BillingState = 'OH',
            CurrencyIsoCode = 'USD',
            Phone = '9999991919',
            ShippingStreet = '123 Main St',
            Vendor_Status__c = 'A',
            Vendor_Number__c= '7676',
       		RM_Account_Number__c='1074584',
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Vendor').getRecordTypeId()
        );
        insert testVendor;
        Purchase_Order__c testPurchaseOrder = new Purchase_Order__c(
            Name = 'Test PO', 
            Company_Code__c='01',
            Location__c='0040',
            ShipTo_Customer__c=testVendor.Id
        	); 
        insert testPurchaseOrder;
       	System.debug('testPurchaseOrder Id >>: ' + testPurchaseOrder.Id);
        
        PO_Line_Item__c LineItem = new PO_Line_Item__c(
        Purchase_Order__c = testPurchaseOrder.Id
        );
		insert LineItem;
        
        PO_Rerent_Line_Item__c rerentLineItem = new PO_Rerent_Line_Item__c(
        Purchase_Order__c = testPurchaseOrder.Id,
         PO_Line_Item__c=LineItem.Id  
        );
        insert rerentLineItem;
    }
 
    public HTTPResponse respond(HTTPRequest req) {
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type',SBR_3_0_Constants.APP_JSON);
        if(req.getEndpoint().endsWithIgnoreCase('token')){
            // Access Token Response
            res.setBody('{"access_token":"test"}');
        }else if(req.getEndpoint().endsWithIgnoreCase('rates')){
            // Rates Response here
            res.setBody('{ "data": { "errorCode": "0000", "errorDesc": "Success", "company": "01", "customer": "4", "jobsite": "CO MEDIMMUNE BOULDER", "location": "0720", "items": [ { "catId": "123", "classId": "4567", "productId": "1234567", "rateFlag": "B", "rateFlagDescription": "Book Rates", "notToExceed": "", "notToExceedDescription": "No override needed for any change.", "rppPercentage": ".000", "needPassword": "FALSE", "showAllRates": "FALSE", "suggestMinimalHours": ".00", "isConsumerCatClass": "FALSE", "isSerialized": "FALSE", "customerDiscountPercentageDaily": ".00", "customerDiscountPercentageWeekly": ".00", "customerDiscountPercentageMonthly": ".00", "customerMonthly": null, "rates": { "suggestedRates": { "minimum": "10", "daily": "10", "weekly": "70", "monthly": "300" }, "bookRates": { "minimum": ".00", "daily": ".00", "weekly": ".00", "monthly": ".00" } } } ] } }');
        } else if(req.getEndpoint().endsWithIgnoreCase('consumables')){
            // Consumables Response here
            res.setBody('{"data":{"suggestedItems":[{"catId":"123","classId":"4567","rentables":[],"consumables":[{"inventoryClass":"206","invClassDescription":"PPE, RESPIRATORY","specGroups":[{"specNumber":"206-0002","title":"Disposable Respirator","specDescription":"Disposable Respirator","minPrice":6,"maxPrice":6,"products":[{"productNumber":"01-PIPSA-817633","stockClass":"PIPSA","oemStockNumber":"10102481","productDescription":"N95 HARMFUL DUST RESPIRATOR 2 PACK","priceSchedule":"","sequence":"10","forceItem":"N","minQuantity":0,"sellingPrice":10,"availQuantity":25,"binNumber1":"SC3","binNumber2":"","binNumber3":"","rentalCat":"0","rentalClass":"0","isSerialized":false}]}]}]}]}}');
        }
        res.setStatusCode(200);
        return res;
    }
    @isTest static void testGetRates() {
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_GetRatesRerentLineItemCont_Test());
        PO_Line_Item__c rerentLineItem = [Select Id from PO_Line_Item__c LIMIT 1];

        Test.startTest();
        String result = SBR_3_0_GetRatesRerentLineItemController.getPOData(rerentLineItem.Id);
       
        //String ratesRequestJson = '{ "pc": 720, "accountNumber": 4, "products": [ { "productId": "1234567" } ] }';
       // System.assert(String.isNotEmpty(SBR_3_0_GetRatesRerentLineItemController.getPOData(ratesRequestJson, '1')), 'No Rates Data Received From Rates API');
        Test.stopTest();
    }

    @isTest
    public static void testUpdateRerent() {
        // Test data setup
         Purchase_Order__c testPurchaseOrder = new Purchase_Order__c(Name = 'Test PO'); 
        insert testPurchaseOrder;
         PO_Line_Item__c LineItem = new PO_Line_Item__c(
        Purchase_Order__c = testPurchaseOrder.Id
        );
		insert LineItem;
       
        PO_Rerent_Line_Item__c rerentLineItem = new PO_Rerent_Line_Item__c(
            // Populate required fields here
            Purchase_Order__c = testPurchaseOrder.Id,
             PO_Line_Item__c=LineItem.Id
            
        );
        insert rerentLineItem;

        // Call the method to test
        Test.startTest();
        SBR_3_0_GetRatesRerentLineItemController.updateRerent(
            LineItem.Id, 
            0.1, // Min
            0.5, // Day
            0.5, // Week
            0.5, // fourWeek
            'Equipment', 
            'Make', 
            'Model', 
            'Serial', 
            1.2, // Meter1
            1.5 // Meter2
        );
        Test.stopTest();

        // Add assertions here based on the expected outcome
        List<PO_Rerent_Line_Item__c> polis = [SELECT Id FROM PO_Rerent_Line_Item__c WHERE Id = :LineItem.Id];
        System.assertNotEquals(1, polis.size(), 'PO_Rerent_Line_Item__c record not found');
       // Example: System.assertEquals(expectedValue, result);
    }
     @isTest
    public static void testgetRerentItems() {
        // Test data setup
         Purchase_Order__c testPurchaseOrder = new Purchase_Order__c(Name = 'Test PO'); 
        insert testPurchaseOrder;
         PO_Line_Item__c LineItem = new PO_Line_Item__c(
        Purchase_Order__c = testPurchaseOrder.Id
        );
		insert LineItem;
       
        PO_Rerent_Line_Item__c rerentLineItem = new PO_Rerent_Line_Item__c(
            // Populate required fields here
            Purchase_Order__c = testPurchaseOrder.Id,
             PO_Line_Item__c=LineItem.Id
            
        );
        insert rerentLineItem;

        // Call the method to test
       Test.startTest();
        System.debug('rerentLineItem Id >>: ' + rerentLineItem.Id);
        List<PO_Rerent_Line_Item__c> result = SBR_3_0_GetRatesRerentLineItemController.getRerentItems(rerentLineItem.Id);
        Test.stopTest();
    }

}