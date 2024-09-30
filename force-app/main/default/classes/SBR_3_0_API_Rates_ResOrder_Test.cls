@isTest
public with sharing class SBR_3_0_API_Rates_ResOrder_Test Implements HttpCalloutMock{

    @TestSetup
    static void makeData(){
        Credential__c cred = SBR_3_0_TestDataFactory.createCredentials(1, false)[0];
        cred.Name = 'Mule_Token_Endpoint';
        cred.Key_Id__c = 'testKey123';
        cred.Secret__c = 'secret';
        insert cred;

        // Prepare Data
        // Activate Price Book
        Pricebook2 priceBook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update priceBook;
        // Create Account
        Account acct = new Account();
        acct.RM_Account_Number__c = '4';
        acct.Company_Code__c = '01';
        acct.Name = 'Test Account';
        acct.Record_Type_Text__c = 'Credit';
        acct.E_mail_Address__c = '123@asdf.com';
        acct.Phone = '1234567899';
        acct.BillingStreet = '123 Main Street';
        acct.BillingCity = 'Toronto';
        acct.BillingPostalCode = 'M9N7V5';
        acct.BillingState = 'ON';
        acct.BillingCountry = 'CA';
        acct.Drivers_License__c = 'AKF';
        acct.Driver_s_License_State__c = 'AL';
        insert acct;
        // Account acct = SBR_3_0_TestDataFactory.createAccounts(1, true, null)[0];
        // Create Contact
        Contact contact = SBR_3_0_TestDataFactory.createContacts(1, acct.Id, true)[0];
        // Create Analysis Region
        Analysis_Region__c region = new Analysis_Region__c();
        region.Analysis_Region_Key__c = '001';
        region.Name = 'Test Region';
        region.Company_Code__c = '01';
        insert region;
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
        insert jobLocation;
        // Create Branch
        Schema.Location branchLocation = new Schema.Location();
        branchLocation.Branch_Location_Number__c = '0720';
        branchLocation.Name = 'Test Branch Location';
        branchLocation.Street_Address__c = '12 Main Street';
        branchLocation.City__c = 'Toronto';
        branchLocation.Zip_Code__c = 'M7N7B3';
        branchLocation.State__c = 'ON';
        branchLocation.Country__c = 'CA';
        branchLocation.Job_Number__c = '332112';
        branchLocation.RecordTypeId = SBR_3_0_Constants.LOCATION_BRANCH_RT_ID;
        branchLocation.Company_Code__c = 'X';
        branchLocation.Time_Zone_Name__c = 'America/Chicago';
        branchLocation.Time_Zone__c = 3;
        branchLocation.Time_Zone_Id__c = 'America/Chicago';
        branchLocation.Latitude_Longitude__Latitude__s = 40.464390;
        branchLocation.Latitude_Longitude__Longitude__s = -80.601060;
        insert branchLocation;
        // Create Job Site
        AssociatedLocation jobSite = new AssociatedLocation(
            Name__c = 'Test Job Site',
            ParentRecordId = acct.Id,
            LocationId = jobLocation.Id,
            Branch__c = branchLocation.Id,
            Job_Number__c = '20221004A'
        );
        insert jobSite;
        /* // Create Product
        Product2 prod = new Product2(Name = 'Test Product 1', Product_Title_Internal__c = 'Test Product 1', Product_SKU__c = '1234567', Product_Type__c = 'Cat-Class');
        Product2 prod2 = new Product2(Name = 'Test Product 2', Product_Title_Internal__c = 'Test Product 2', Product_SKU__c = '01-PIPSA-817633', Product_Type__c = 'Merchandise');
        insert prod;
        insert prod2; */
        // Create Quote
        SBQQ__Quote__c quote = new SBQQ__Quote__c(
            Quote_Name__c = 'Test Quote',
            SBQQ__Account__c = acct.Id,
            Jobsite__c = jobSite.Id
        );
        insert quote;
    
        //12438

        Id ReservationOrderRTId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('Reservation_Order').getRecordTypeId();
        // Create Order
        Order order = new Order(
            Quote_Name__c = 'Test Quote',
            AccountId = acct.Id,
            Jobsite__c = jobSite.Id,
            Deliverymethod__c = 'Delivery',
            Delivery_Charge__c = 10,
            Status = 'Draft',
            Pricebook2Id = priceBook.Id,
            Start_Date__c = date.valueOf('2022-12-12 12:00:00'),
            EffectiveDate = date.valueOf('2022-12-12 12:00:00'),
            EndDate = date.valueOf('2023-10-09 8:00:00'),
            Return_Date__c = date.valueOf('2023-10-09 8:00:00'),
            Earliest_Delivery_Date__c = date.valueOf('2022-10-08 12:00:00'),
            Opt_Out_RPP__c = false,
            Order_Initiating_Channel__c = 'SLSFRC',
            Opt_Out_Fuel_Charge__c = false,
            Selling_Channel__c = 'SBRB2B',
            RecordTypeId = ReservationOrderRTId,
            Duration__c = 'Custom'
        );

         insert order;
        // Create Product
        List<Product2> products = new List<Product2>();
        for(Integer i = 0; i < 3; i++) {
            Product2 product = new Product2();
            product.Name = 'Test Product ' + i;
            if(i == 0) {
                product.Product_Type__c = 'Cat-Class';
                product.Product_SKU__c = '1234567';
                product.Category__c = '32134';
                product.Class__c = '2039';
                product.ToolFlex__c = 'N';
                product.Company_code__c = '01;02';
            } else if (i == 1) {
                product.Product_Type__c = 'Parts';
                product.Item_Number__c = '1234GH';
                product.Stock_Class__c = 'AIMFV';
                product.Company_code__c = '01;02';
            } else {
                product.Product_Type__c = '';
                product.Item_Number__c = '1285JC';
                product.Stock_Class__c = 'UJEKL';
                product.Company_code__c = '01;02';
            }
            products.add(product);
        }
        insert products;
        // Create Price Book Entry
        List<PricebookEntry> listPbe = new List<PricebookEntry>();

        SBR_3_0_TestDataFactory.createPriceBookEntries(products);

        Map<Id, Id> mapPBE = new Map<Id, Id>();
        for(PricebookEntry pbEntry : [SELECT Id,Product2Id FROM PricebookEntry WHERE Pricebook2Id = :Test.getStandardPricebookId()]) {
            if(pbEntry.Product2Id == products[0].Id){
                mapPBE.put(pbEntry.Product2Id, pbEntry.Id);
            }
            else if(pbEntry.Product2Id == products[1].Id){
                mapPBE.put(pbEntry.Product2Id, pbEntry.Id);
            }
            else if(pbEntry.Product2Id == products[2].Id){
                mapPBE.put(pbEntry.Product2Id, pbEntry.Id);
            }
        }
        // Create Order item
        List<OrderItem> orderItems = new List<OrderItem>();
       for(Integer i = 0; i < 3; i++){
            OrderItem orderItem = new OrderItem();
            orderItem.OrderId = order.Id;
            orderItem.Selling_Price__c = 10;
            orderItem.Product2Id = products[i].Id;
            orderItem.UnitPrice = 100;
            orderItem.Item_Number__c = i;
            orderItem.Min_Rate__c = 2;
            orderItem.Daily_Rate__c = 2.0;
            orderItem.Weekly_Rate__c = 2.0;
            orderItem.Monthly_Rate__c = 2.0;
            orderItem.PricebookEntryId = mapPBE.get(products[i].Id);
            if(i == 0) {
                orderItem.Hourly_Rate__c = 2.0;
                orderItem.Min_Rate__c = 2.0;
                orderItem.Quantity = 5;
                orderItem.Free_Flag__c = false;
                orderItem.Suggested_Daily_Rate__c = 2.0;
                orderItem.Suggested_Weekly_Rate__c = 2.0;
                orderItem.Suggested_Monthly_Rate__c = 2.0;
                orderItem.Daily_Rate__c = 2.0;
                orderItem.Weekly_Rate__c = 2.0;
                orderItem.Monthly_Rate__c = 2.0;
                orderItem.Rates_Overriden__c = false;
              //  orderItem.Line_Comments__c = 'Comments';
               // orderItem.SBQQ__Number__c = 5;
               orderItem.Global_Line_Number__c = 123;
            } else if (i == 1) {
                orderItem.Quantity = 3;
                orderItem.Global_Line_Number__c = 456;
            } else {
                orderItem.Quantity = 3;
                orderItem.Misc_Charges_Type__c = 'TRANSPORTATION CHARGE';
                orderItem.Misc_Charge__c = 20.3;
                orderItem.Misc_Charges_Tax__c = 2.34;
                orderItem.Taxable__c = false;
                orderItem.Misc_Charges_Non_Taxable__c = false;
                orderItem.Misc_Charges_Item_Tax_Rate__c = 2.0;
                orderItem.Global_Line_Number__c = 412;
            }
            orderItems.add(orderItem);
        }
        insert orderItems;
        //12438
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
    @isTest static void testRefreshResOrderRates(){
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_Rates_Test());
        Order testOrder = [SELECT ID FROM Order WHERE Quote_Name__c = 'Test Quote' LIMIT 1];
        Test.startTest();
        SBR_3_0_API_Rates_ResOrder.refreshResOrderRates(testOrder.Id);
        Test.stopTest();
        Map<Id, Order> oOrder = SBR_3_0_OrderDA.getOrders(new set<Id> {testOrder.Id});
        if(!oOrder.isEmpty()){
            Order orderRec = oOrder.values()[0];
            for(OrderItem orderLineItem : orderRec.OrderItems){
                if(orderLineItem.Product2.Name == 'Test Product 0'){
                    System.debug('orderLineItem Test Product 0->'+orderLineItem);
                    System.assert(orderLineItem.Suggested_Minimum_Rate__c == 10.0, 'Suggested_Minimum_Rate__c is not 10.0 but ' + orderLineItem.Suggested_Minimum_Rate__c);
                    System.assert(orderLineItem.Suggested_Daily_Rate__c == 10.0, 'Suggested_Daily_Rate__c is not 10.0 but ' + orderLineItem.Suggested_Daily_Rate__c);
                    System.assert(orderLineItem.Suggested_Weekly_Rate__c == 70.0, 'Suggested_Weekly_Rate__c is not 70.0 but ' + orderLineItem.Suggested_Weekly_Rate__c);                    
                    System.assert(orderLineItem.Suggested_Monthly_Rate__c == 300.0, 'Suggested_Monthly_Rate__c is not 300.0 but ' + orderLineItem.Suggested_Monthly_Rate__c);
                } else if (orderLineItem.Product2.Name == 'Test Product 1') {
                    System.debug('orderLineItem Test Product 2->'+orderLineItem);
                    System.assert(orderLineItem.Selling_Price__c == 10.0, 'Selling_Price__c is not 10.0 but ' + orderLineItem.Selling_Price__c);
                }
            }
        }
    }
}