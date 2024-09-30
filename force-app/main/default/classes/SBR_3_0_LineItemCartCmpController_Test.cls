/*********************************************************************************************************************
* Apex Class: SBR_3_0_LineItemCmpController_Test
----------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* @description Test class for SBR_3_0_LineItemCmpController
* - SAL-6165, SAL-6859
----------------------------------------------------------------------------------------------------------------------
* History:
    
*********************************************************************************************************************/
@IsTest
public with sharing class SBR_3_0_LineItemCartCmpController_Test {
    
    static final String ZIP_VALID = '20147';
    static final String ZIP_INVALID = '55555';
    static final String COMPANY_ID = '01';
    static final String JSON_REQUEST = '{"account":1,"orderType":"Pickup","ratesToBeUsed":"SUGGESTED","startDateAndTime":"2023-01-20T12:00:00.000-10:00","endDateAndTime":"2023-01-27T12:00:00.000-10:00","pc":[{"id":5105,"latitude":47.6044,"longitude":-122.3345,"timezone":""}],"address":[{"type":"jobsite","line1":"","city":"","state":"","zip":"20147","latitude":-38.9954527,"longitude":-93.093325}],"delivery":[{"chargesOverride":true,"charges":"0.00"}],"pickup":[{"chargesOverride":false}],"orderLines":[{"salesItems":[],"products":[{"catId":"001","classId":"0220","quantity":1,"rates":{"override":true,"hourly":"0.00","minimum":"1220.00","daily":"1220.00","weekly":"3390.00","monthly":"7040.00"}}]}]}';
    static final String DELIVERY_JSON_REQUEST = '{"account":1,"orderType":"Delivery","ratesToBeUsed":"SUGGESTED","startDateAndTime":"2023-01-20T12:00:00.000-10:00","endDateAndTime":"2023-01-27T12:00:00.000-10:00","pc":[{"id":5105,"latitude":47.6044,"longitude":-122.3345,"timezone":""}],"address":[{"type":"jobsite","line1":"","city":"","state":"","zip":"20147","latitude":-38.9954527,"longitude":-93.093325}],"delivery":[{"chargesOverride":true,"charges":"0.00"}],"pickup":[{"chargesOverride":false}],"orderLines":[{"salesItems":[],"products":[{"catId":"001","classId":"0220","quantity":1,"rates":{"override":true,"hourly":"0.00","minimum":"1220.00","daily":"1220.00","weekly":"3390.00","monthly":"7040.00"}}]}]}';
    static final String PRODUCT_1_SKU = '123001';
    static final String PRODUCT_2_SKU = '123002';
    static final List<String> PRODUCT_SKUS = new List<String>{PRODUCT_1_SKU, PRODUCT_2_SKU};

    @TestSetup
    static void setUpTests(){
        Credential__c cred = SBR_3_0_TestDataFactory.createCredentials(1, false)[0];
        cred.Name = 'Mule_Token_Endpoint';
        cred.Key_Id__c = 'testKey123';
        cred.Secret__c = 'secret';
        insert cred;

        Pricebook2 priceBook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update priceBook;

        Account acct = new Account(
            RM_Account_Number__c = '12345',
            Name = SBR_3_0_API_Web_Jobsite_DA.JOBSITEACCOUNTNAME,
            BillingStreet = '123 Main Street',
            BillingCity = 'Toronto',
            BillingPostalCode = 'M9N7V5',
            BillingState = 'ON',
            BillingCountry = 'CA',
            Phone='3434343434',
            Company_Code__c = '01'
        );
        insert acct;
       /* Schema.Location jobLocation = new Schema.Location();
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
        
        Schema.Location branchLocation = new Schema.Location();
        branchLocation.Branch_Location_Number__c = '1234';
        branchLocation.Name = 'Test Branch Location';
        branchLocation.Street_Address__c = '12 Main Street';
        branchLocation.City__c = 'Toronto';
        branchLocation.Zip_Code__c = 'M7N7B3';
        branchLocation.State__c = 'ON';
        branchLocation.Country__c = 'CA';
        branchLocation.Job_Number__c='332112';
        branchLocation.RecordTypeId = SBR_3_0_Constants.LOCATION_BRANCH_RT_ID;
        branchLocation.Company_Code__c = 'X';
        branchLocation.Time_Zone_Name__c = 'America/Chicago';
        branchLocation.OMS_Sourcing_Enabled__c = true;
        branchLocation.Time_Zone__c = 3;
        insert branchLocation;*/

        List<Schema.location> jobLocation = SBR_3_0_TestDataFactory.createLocations(1,false,'Shared Job Location');
        jobLocation[0].Analysis_Region_Key__c = '921';
        jobLocation[0].Name = 'Test Job Location';
        jobLocation[0].Street_Address__c = '12 Main Street';
        jobLocation[0].City__c = 'Toronto';
        jobLocation[0].Zip_Code__c = 'M7N7B3';
        jobLocation[0].State__c = 'ON';
        jobLocation[0].Country__c = 'CA';
        jobLocation[0].OMS_Sourcing_Enabled__c = true;
        jobLocation[0].Distance_Multiplier__c = 50;
        jobLocation[0].Analysis_Region_Key__c = '001';
        jobLocation[0].Company_Code__c = '01';
        insert jobLocation;

        List<Schema.location> branchLocation = SBR_3_0_TestDataFactory.createLocations(1,false,'Branch');
        branchLocation[0].Analysis_Region_Key__c = '921';
        branchLocation[0].Branch_Location_Number__c = '1234';
        branchLocation[0].Name = 'Test Branch Location';
        branchLocation[0].Street_Address__c = '12 Main Street';
        branchLocation[0].City__c = 'Toronto';
        branchLocation[0].Zip_Code__c = 'M7N7B3';
        branchLocation[0].State__c = 'ON';
        branchLocation[0].Country__c = 'CA';
        branchLocation[0].Job_Number__c='332112';
        branchLocation[0].Company_Code__c = 'X';
        branchLocation[0].Time_Zone_Name__c = 'America/Chicago';
        branchLocation[0].OMS_Sourcing_Enabled__c = true;
        branchLocation[0].Time_Zone__c = 3;
        insert branchLocation;

        // Create Job Site
        AssociatedLocation jobSite = new AssociatedLocation(
            Name__c = 'Test Job Site',
            ParentRecordId = acct.Id,
            LocationId = jobLocation[0].Id,
            Branch__c = branchLocation[0].Id,
            Job_Number__c = '20221004A'
        );
        insert jobSite;

        Id skuType = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('SKU').getRecordTypeId();

        List<Product2> products = new List<Product2>();
        for (Integer i = 0; i < 2; i++) {
            products.add(new Product2(
                Name = 'Test Product ' + i,
                Product_Title_Internal__c = 'Test Product ' + i,
                Product_SKU__c = PRODUCT_SKUS[i],
                Make__c = 'make ' + i,
                Model__c = 'model ' + i,
                Company_Code__c = '01',
                Product_Type__c = 'Cat-Class',
                RecordTypeId = skuType
            ));
        }
        System.debug('products-->'+products);
        insert products;
        List<SBQQ__ProductFeature__c> features = new List<SBQQ__ProductFeature__c>();
        SBQQ__ProductFeature__c feature1 = new SBQQ__ProductFeature__c();
        feature1.Name = 'Sales Addons';
        feature1.SBQQ__Number__c = 1;
        feature1.SBQQ__ConfiguredSKU__c = products[0].Id;
        features.add(feature1);
        
        SBQQ__ProductFeature__c feature2 = new SBQQ__ProductFeature__c();
        feature2.Name = 'Rental Addons';
        feature2.SBQQ__Number__c = 2;
        feature2.SBQQ__ConfiguredSKU__c = products[0].Id;
        features.add(feature2);

        SBQQ__ProductFeature__c feature3 = new SBQQ__ProductFeature__c();
        feature3.Name = 'Forced Item';
        feature3.SBQQ__Number__c = 3;
        feature3.SBQQ__ConfiguredSKU__c = products[0].Id;
        features.add(feature3);
        
        insert features; 
        
        List<SBQQ__ProductOption__c> options = new List<SBQQ__ProductOption__c>();
        SBQQ__ProductOption__c option1 = new SBQQ__ProductOption__c();
        option1.SBQQ__ConfiguredSKU__c = products[0].Id;
        option1.SBQQ__OptionalSKU__c = products[0].Id;
        option1.SBQQ__Feature__c = features[0].Id;
        option1.SBQQ__Number__c = 1;
        option1.Company_Code__c = '01';
        option1.SBQQ__Required__c=true;
        options.add(option1);
        
        SBQQ__ProductOption__c option2 = new SBQQ__ProductOption__c();
        option2.SBQQ__ConfiguredSKU__c = products[0].Id;
        option2.SBQQ__OptionalSKU__c = products[0].Id;
        option2.SBQQ__Feature__c = features[1].Id;
        option2.SBQQ__Number__c = 2;
        option2.Company_Code__c = '01';
        option2.SBQQ__Required__c=true;
        options.add(option2);
        
        SBQQ__ProductOption__c option3 = new SBQQ__ProductOption__c();
        option3.SBQQ__ConfiguredSKU__c = products[0].Id;
        option3.SBQQ__OptionalSKU__c = products[0].Id;
        option3.SBQQ__Feature__c = features[2].Id;
        option3.SBQQ__Number__c = 3;
        option3.Company_Code__c = '01';
        option3.SBQQ__Required__c=true;
        options.add(option3);
        insert options;
        
        // Create Price Book Entry
        List<PricebookEntry> pbEntryList = new List<PricebookEntry>();
        
        //SBR_3_0_TestDataFactory.createPriceBookEntries(products);
        for(Product2 p: products) {
             PricebookEntry pbe = new PricebookEntry(Pricebook2Id = priceBook.Id,Product2Id = p.Id,UnitPrice = 1020,IsActive = true, currencyISOCode = 'USD');
            pbEntryList.add(pbe);
        }
        insert pbEntryList;

        /*Map<Id, Id> mapPBE = new Map<Id, Id>();
        for(PricebookEntry pbEntry : [SELECT Id,Product2Id FROM PricebookEntry WHERE Pricebook2Id = :Test.getStandardPricebookId() AND currencyISOCode = 'USD']) {
            if(pbEntry.Product2Id == products[0].Id){
                mapPBE.put(pbEntry.Product2Id, pbEntry.Id);
            }
            else if(pbEntry.Product2Id == products[1].Id){
                mapPBE.put(pbEntry.Product2Id, pbEntry.Id);
            }
            else if(pbEntry.Product2Id == products[2].Id){
                mapPBE.put(pbEntry.Product2Id, pbEntry.Id);
            }
        }*/
        Map<String, Product2> productMap = new Map<String, Product2>(products);
        System.debug('productMap--->'+productMap);
        List<PricebookEntry> pbEntries = [SELECT Id, Product2Id, UnitPrice, Product2.Make__c, currencyISOCode FROM PricebookEntry  WHERE Pricebook2Id = :priceBook.Id AND currencyISOCode = 'USD'];
        System.debug('pbEntries@@-->'+pbEntries);
        Order order = new Order(
            AccountId = acct.Id,
            Jobsite__c = jobSite.Id,
            BillingCity = 'Test City',
            Contingency_Order__c = true,
            EffectiveDate = Date.today(),
            Pricebook2Id = priceBook.Id,
            Status = 'Draft',
            Seasonal_Order__c = true,
            Apply_Standby_Rates__c = true,
            Shift_Pricing_Required__c = true,
            currencyISOCode = pbEntries[0].currencyISOCode
        );
        System.debug('order-->'+order);
        insert order;
        SBR_3_0_TriggerHandler.bypass('SBR_3_0_QuoteTriggerHandler');
        List<SBQQ__Quote__c> quoteInsertList = new List<SBQQ__Quote__c>();
        SBQQ__Quote__c quote1 = new SBQQ__Quote__c();
        quote1.Quote_Name__c = 'Test Quote1';
        quote1.SBQQ__Account__c = acct.Id;
        quote1.Branch__c = branchLocation[0].Id;
        quote1.Jobsite__c = jobSite.Id;
        quote1.SBQQ__DeliveryMethod__c = 'Delivery';
        quote1.Delivery_Charge__c = 10;
        quote1.SBQQ__Status__c = 'Draft';
        quote1.SBQQ__PriceBook__c = priceBook.Id;
        quote1.Start_Date__c = system.today() +3;
        quote1.End_Date__c = system.today() +12;
        quote1.Delivery_Date__c =  system.today();
        quote1.Opt_Out_RPP__c = false;
        quote1.Company_Code__c='01';
        quote1.Account_Record_Type_Txt__c = 'Credit';
        quote1.Opt_Out_Fuel_Charge__c = false;
        quote1.Selling_Channel__c = 'SBRB2B';
        insert quote1;
        
        List<OrderItem> orderItems = new List<OrderItem>();
        for (PricebookEntry pbEntry : pbEntries) {
            orderItems.add(new OrderItem(
                OrderId = order.Id,
                Product2Id = pbEntry.Product2Id,
                PricebookEntryId = pbEntry.Id,
                Quantity = 3,
                UnitPrice = 1.0,
                groupID__c = pbEntry.Product2.Make__c,
                Line_Name__c='Test Ord'
            ));
        }
        System.debug('OrderItems-->'+orderItems);
        insert orderItems;
        
        List<SBQQ__QuoteLine__c> quoteItems = new List<SBQQ__QuoteLine__c>();
        for (PricebookEntry pbEntry : pbEntries) {
            quoteItems.add(new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = quote1.Id,
            SBQQ__Product__c = pbEntry.Product2Id,
            SBQQ__UnitCost__c = 100,
            RM_Quote_Line_Number__c = 1,
            Min_Rate__c = 2,
            Daily_Rate__c = 2.0,
            Weekly_Rate__c = 2.0,
            Monthly_Rate__c = 2.0,
            Line_Name__c='Test QuoteLine',
            SBQQ__PricebookEntryId__c =pbEntry.Id
            ));
        }
        System.debug('quoteItems-->'+quoteItems);
        insert quoteItems;
        
        Cart__c cart = new Cart__c(
            Account__c = acct.Id, 
            Branch__c = branchLocation[0].Id, 
            Rental_Start_Date__c = System.now()+2,
            Rental_End_Date__c = System.now()+3,
            Rental_Period__c = '1 Day', 
            Job_Site__c = jobSite.Id );
        insert cart;
        
        Cart_Items__c cartItem = new Cart_Items__c(
            Cart__c = cart.Id,
            Product__c =  products[0].Id
        );
        insert cartItem;
         
    }

    public class MockHTTPResponse Implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();

            res.setHeader('Content-Type',SBR_3_0_Constants.APP_JSON);
            if (req.getEndpoint().endsWithIgnoreCase('token')) {
                res.setBody('{"access_token":"test"}');
            } else {
                if (req.getEndpoint().containsIgnoreCase('geocode')) {
                    if (req.getEndpoint().containsIgnoreCase(ZIP_VALID)) {
                        res.setBody('{ "data": { "results": [ { "addressComponents": [ { "longName": "6365", "shortName": "6365", "types": [ "street_number" ] }, { "longName": "Multiplex Drive", "shortName": "Multiplex Dr", "types": [ "route" ] }, { "longName": "Centreville", "shortName": "Centreville", "types": [ "locality", "political" ] }, { "longName": "Fairfax County", "shortName": "Fairfax County", "types": [ "administrative_area_level_2", "political" ] }, { "longName": "Virginia", "shortName": "VA", "types": [ "administrative_area_level_1", "political" ] }, { "longName": "United States", "shortName": "US", "types": [ "country", "political" ] }, { "longName": "20121", "shortName": "20121", "types": [ "postal_code" ] } ], "formattedAddress": "6365 Multiplex Dr, Centreville, VA 20121, USA", "geometry": { "location": { "latitude": 38.82717, "longitude": -77.439927 }, "locationType": "ROOFTOP", "viewport": { "northeast": { "latitude": 38.8286634802915, "longitude": -77.43860981970849 }, "southwest": { "latitude": 38.8259655197085, "longitude": -77.44130778029151 } } }, "placeId": "ChIJC0C2DMJEtokR4Kx6xT21ctk", "types": [ "street_address" ] } ] } }');
                    } else {
                        res.setBody('{}');
                    }
                }
                if (req.getEndpoint().containsIgnoreCase('estimates')) {
                    res.setBody('{ "data": { "estimate": { "itemizedCharges": { "orderLines": [ { "salesItems": [ { "itemNumber": "4FPK3", "stockClass": "GRAIN", "unitPrice": 292.000, "totalPrice": 292.00, "salesTax": 20.44, "salesTaxRate": 7.0000, "quantity": 1.00 } ] }, { "products": [ { "catId": "016", "classId": "0010", "rentalCost": 123456789.12, "unitRentalCost": 123456789.12, "quantity": 1.00, "rentalTax": 8641975.24, "rentalTaxRate": 7.0000, "rppCost": 18518518.36, "unitRPPCost": 18518518.36, "rppTax": 1296296.29, "rppTaxRate": 7.0000, "isSerialized": true }, { "catId": "008", "classId": "0007", "rentalCost": 123456789.12, "unitRentalCost": 123456789.12, "quantity": 1.00, "rentalTax": 8641975.24, "rentalTaxRate": 7.0000, "rppCost": 18518518.36, "unitRPPCost": 18518518.36, "rppTax": 1296296.29, "rppTaxRate": 7.0000, "isSerialized": true } ] } ] }, "miscCharges": [ { "type": "DELIVERY", "charge": 1234.12, "tax": 7.70, "taxExempt": false, "nonTaxable": false, "itemTaxRate": 7.0000 }, { "type": "FUEL CONVENIENCE CHARGE", "charge": 23.75, "tax": 1.66, "taxExempt": false, "nonTaxable": false, "itemTaxRate": 7.0000 }, { "type": "PICKUP", "charge": 110.00, "tax": 7.70, "taxExempt": false, "nonTaxable": false, "itemTaxRate": 7.0000 }, { "type": "SC 2.5% HEAVY EQUIP. RENTAL SURCHARGE", "charge": 6172839.46, "tax": 0, "taxExempt": false, "nonTaxable": true, "itemTaxRate": 0 }, { "type": "TRANSPORTATION SURCHARGE", "charge": 35.20, "tax": 2.46, "taxExempt": false, "nonTaxable": false, "itemTaxRate": 7.0000 } ], "taxInfo": [ { "taxRateUsed": 7.0000, "taxRateFromPC": true, "currencyCode": "USD" } ], "totals": { "rentalAmount": 246913578.24, "rppCharges": 37037036.72, "miscCharges": 6174242.53, "finalTotal": 310001732.51, "salesAmount": 292.00, "salesTax": 19876583.02 }, "otherDetails": { "distBetweenPCandSite": 90, "unitOfDistance": "miles", "unitofCurrency": [ "USD" ] } } } }');
                }
            }
            res.setStatusCode(200);
            return res;
        }
    }

    @isTest
    static void testGetLatLongFromZip(){
        

        Test.startTest();
            Test.setMock(HttpCalloutMock.class, new MockHTTPResponse());
            Map<String, String> result1 = SBR_3_0_LineItemCartCmpController.getLatLongFromZip(ZIP_INVALID);
            Map<String, String> result2 = SBR_3_0_LineItemCartCmpController.getLatLongFromZip(ZIP_VALID);
        Test.StopTest();
        //System.assert((result2.get('status') == 'success'), 'No lat/long from zip');
    }

    @isTest
    static void testGetBranchDetails(){
        SBR_3_0_TriggerHandler.bypass('SBR_3_0_LocationTriggerHandler');
        Schema.Location result = new Schema.Location();
        Id user = UserInfo.getUserID();
        List<Schema.Location> branch = SBR_3_0_TestDataFactory.createInventoryLocations(1,true,'Branch');

        User_location__c userLocation = new user_location__c(branch__c = branch[0].Id,User__c = user);
        Insert userLocation;

        Test.startTest();
            result = SBR_3_0_LineItemCartCmpController.getBranchDetails();
        Test.StopTest();
       
        System.assert(String.isNotEmpty(result.name), 'No branch locaction');
    }

    @isTest
    static void testGetLineItemEstimates(){
        SBR_3_0_TriggerHandler.bypass('SBR_3_0_LocationTriggerHandler');
        Id user = UserInfo.getUserID();
        List<Schema.Location> branch = SBR_3_0_TestDataFactory.createInventoryLocations(1,true,'Branch');
        system.debug(branch);
        Schema.Location l1 = new Schema.Location();
        l1.id=branch[0].Id;
        l1.Branch_Location_Number__c=String.valueOf(1);
        l1.Latitude_Longitude__latitude__s=37.7749;
         l1.Latitude_Longitude__longitude__s=-122.4194;
        update l1;
        
        Schema.Location l = new Schema.Location();
            l.Name = 'Location1';
            l.LocationType = SBR_3_0_Constants.LOCATION_TYPE_JOBLOCATION;
            l.Street_Address__c = 'Location1';
            l.City__c = 'Location1';
            l.State__c = 'CA';
            l.Zip_Code__c = 'Location1';
            l.IsInventoryLocation = true;
            l.Branch_Location_Number__c=String.valueOf(1);
       // insert l;

        User_location__c userLocation = new user_location__c(branch__c = branch[0].Id,User__c = user);
        Insert userLocation;

        Test.startTest();
            SBR_3_0_TriggerHandler.bypass('SBR_3_0_QuoteTriggerHandler');
            Test.setMock(HttpCalloutMock.class, new MockHTTPResponse());
            String result = SBR_3_0_LineItemCartCmpController.getLineItemEstimates(JSON_REQUEST, COMPANY_ID);
        Test.StopTest();

        System.assert(String.isNotEmpty(result), 'No estimates');
    }
    
    @isTest
    static void testGetLineItemEstimatesDelivery(){
        SBR_3_0_TriggerHandler.bypass('SBR_3_0_LocationTriggerHandler');
        Id user = UserInfo.getUserID();
        List<Schema.Location> branch = SBR_3_0_TestDataFactory.createInventoryLocations(1,true,'Branch');
        system.debug(branch);
        Schema.Location l1 = new Schema.Location();
        l1.id=branch[0].Id;
        l1.Branch_Location_Number__c=String.valueOf(1);
        l1.Latitude_Longitude__latitude__s=37.7749;
         l1.Latitude_Longitude__longitude__s=-122.4194;
        update l1;
        
        Schema.Location l = new Schema.Location();
            l.Name = 'Location1';
            l.LocationType = SBR_3_0_Constants.LOCATION_TYPE_JOBLOCATION;
            l.Street_Address__c = 'Location1';
            l.City__c = 'Location1';
            l.State__c = 'CA';
            l.Zip_Code__c = 'Location1';
            l.IsInventoryLocation = true;
            l.Branch_Location_Number__c=String.valueOf(1);
       // insert l;

        User_location__c userLocation = new user_location__c(branch__c = branch[0].Id,User__c = user);
        Insert userLocation;

        Test.startTest();
            SBR_3_0_TriggerHandler.bypass('SBR_3_0_QuoteTriggerHandler');
            Test.setMock(HttpCalloutMock.class, new MockHTTPResponse());
            String result = SBR_3_0_LineItemCartCmpController.getLineItemEstimates(DELIVERY_JSON_REQUEST, COMPANY_ID);
        Test.StopTest();

        System.assert(String.isNotEmpty(result), 'No estimates');
    }

    @IsTest
    static void deleteLineItems_givenOrderLineItemIdList_deletesItemsByGroupId() {
        String groupId = 'make 0';
        OrderItem item = [SELECT Id, groupID__c,Line_Name__c FROM OrderItem WHERE  Line_Name__c='Test Ord' LIMIT 1];

        Test.startTest();
            SBR_3_0_TriggerHandler.bypass('SBR_3_0_QuoteTriggerHandler');
            SBR_3_0_LineItemCartCmpController.deleteLineItems(new List<String> {item.Id});
        Test.stopTest();

        List<OrderItem> sameGroupIdList = [SELECT Id FROM OrderItem WHERE groupID__c = :groupId];

        System.assert(sameGroupIdList.isEmpty(), 'Order lines were not deleted by group id');
    }
    
     @IsTest
    static void deleteLineItems_givenQuoteLineItemIdList() {
          List<String> prodSkuList = new List<String>();
        String groupId = 'make 0';
        
        SBQQ__QuoteLine__c item = [SELECT Id,Line_Name__c,Product_SKU__c FROM SBQQ__QuoteLine__c WHERE  Line_Name__c='Test QuoteLine' LIMIT 1];
        prodSkuList.add(item.Product_SKU__c);
          List<SBQQ__ProductOption__c> forcedItemProds = SBR_3_0_ProductDA.getProductOptionsForProducts(prodSkuList, '01', 'Forced Item');
          System.debug('forcedItemProds'+forcedItemProds);
        Test.startTest();
            SBR_3_0_TriggerHandler.bypass('SBR_3_0_QuoteTriggerHandler');
            SBR_3_0_LineItemCartCmpController.deleteLineItems(new List<String> {item.Id});
        Test.stopTest();
    }
	
    @IsTest
    static void getLineItemBulkFlagTest(){
        
        Test.startTest();
        	OrderItem item = [SELECT Id, groupID__c,Line_Name__c FROM OrderItem WHERE  Line_Name__c='Test Ord' LIMIT 1];
        	Boolean bulkItem = SBR_3_0_LineItemCartCmpController.getLineItemBulkFlag(item.Id);
        Test.stopTest();

        Assert.areEqual(false, bulkItem);
    }
    
    @IsTest
    static void updateOrderLineItemTest(){
        Test.startTest();
        	OrderItem item = [SELECT Id, groupID__c,Line_Name__c,Quantity FROM OrderItem WHERE  Line_Name__c='Test Ord' LIMIT 1];
        	String lineItem = '[{"fields":{"Id":"'+item.Id+'","Quantity":6,"Fuel_Plan__c":false,"Kit_Number_this_Item_Belongs_to__c":""}}]';
        	List<OrderItem> updatedItems = (List<OrderItem>)SBR_3_0_LineItemCartCmpController.updateLineItems('Order',lineItem);
        Test.stopTest();

        Assert.areEqual(6, updatedItems[0].Quantity);
    }
    
    @IsTest
    static void updateQuoteLineItemTest(){
        Test.startTest();
        	SBQQ__QuoteLine__c item = [SELECT Id,Line_Name__c,Product_SKU__c FROM SBQQ__QuoteLine__c WHERE  Line_Name__c='Test QuoteLine' LIMIT 1];
        	String lineItem = '[{"fields":{"Id":"'+item.Id+'","SBQQ__Quantity__c":6,"Fuel_Plan__c":false,"Kit_Number_this_Item_Belongs_to__c":""}}]';
        	List<SBQQ__QuoteLine__c> updatedItems = (List<SBQQ__QuoteLine__c>)SBR_3_0_LineItemCartCmpController.updateLineItems('SBQQ__Quote__c',lineItem);
        Test.stopTest();

        Assert.areEqual(6, updatedItems[0].SBQQ__Quantity__c);
    }
    
    @IsTest
    static void updateCartLineItemTest(){
        Test.startTest();
        	Cart_Items__c item = [SELECT Id FROM Cart_Items__c LIMIT 1];
        	String lineItem = '[{"fields":{"Id":"'+item.Id+'","Quantity__c":6,"Fuel_Plan__c":false,"Kit_Number_this_Item_Belongs_to__c":""}}]';
        	List<Cart_Items__c> updatedItems = (List<Cart_Items__c>)SBR_3_0_LineItemCartCmpController.updateLineItems('Cart__c',lineItem);
        Test.stopTest();

        Assert.areEqual(6, updatedItems[0].Quantity__c);
    }
    
    @IsTest
    static void updateLineItemExceptionTest(){
        Test.startTest();
        	SBQQ__QuoteLine__c item = [SELECT Id,Line_Name__c,Product_SKU__c FROM SBQQ__QuoteLine__c WHERE  Line_Name__c='Test QuoteLine' LIMIT 1];
        	String lineItem = '[{"fields":{"Id":"'+item.Id+'","SBQQ__Quantity__c ":6,"Fuel_Plan__c":false,"Kit_Number_this_Item_Belongs_to__c":""}]';
        try{
        	List<SBQQ__QuoteLine__c> updatedItems = (List<SBQQ__QuoteLine__c>)SBR_3_0_LineItemCartCmpController.updateLineItems('SBQQ__Quote__c',lineItem);
        }Catch(AuraHandledException ex){
            Assert.isInstanceOfType(ex, AuraHandledException.class, 'Expected type.'); 
        }
        Test.stopTest();
    }

}