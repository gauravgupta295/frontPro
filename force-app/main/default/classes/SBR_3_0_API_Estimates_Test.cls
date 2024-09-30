@isTest
public with sharing class SBR_3_0_API_Estimates_Test Implements HttpCalloutMock{
    @TestSetup
    static void makeData(){
        
        User admin = SBR_3_0_TestDataFactory.createUsersWithPermissions(
      1,
      true,
      'System Administrator',
      new Set<String>{
        'SalesUserPsl',
        'Integration API Access',
        'SalesforceCPQ_CPQStandardPerm'
      },
      new Set<String>{ 'Sales_User ', 'Branch_Manager1' }
    )[0];

    System.runAs(admin) 
    {
        SVMXA360__SM_TA_Template__c smTaTemplate = new SVMXA360__SM_TA_Template__c();
        	smTaTemplate.Name = 'SBR 3.0 Maintenance Template';
        	smTaTemplate.SVMXA360__DeveloperName__c = 'SBR_3_0_Maintenance_Template';
        	insert smTaTemplate;
        
        Credential__c cred = SBR_3_0_TestDataFactory.createCredentials(1, false)[0];
        cred.Name = 'Mule_Token_Endpoint';
        cred.Key_Id__c = 'testKey123';
        cred.Secret__c = 'secret';
        insert cred;
        
// Create Account
        Account acct = new Account();
        acct.RM_Account_Number__c = '4';
        acct.Company_Code__c = '01';
        acct.Name = 'Test Account';
        acct.Record_Type_Text__c = 'Credit';
        acct.E_mail_Address__c = '123@asdf.com';
        acct.Phone = '1234567890';
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
        branchLocation.Branch_Location_Number__c = '720';
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
        branchLocation.Time_Zone__c = 3;
        branchLocation.OMS_Sourcing_Enabled__c = true;
        branchLocation.Latitude_Longitude__Latitude__s = 47.09;
        branchLocation.Latitude_Longitude__Longitude__s = 47.09;
        insert branchLocation;
        // Create Job Site
        AssociatedLocation jobSite = new AssociatedLocation(
            Name__c = 'Test Job Site',
            Latitude_Longitude__Latitude__s = 48.51,
            Latitude_Longitude__Longitude__s = -117.62,
            ParentRecordId = acct.Id,
            LocationId = jobLocation.Id,
            Branch__c = branchLocation.Id,
            Job_Number__c = '20221004A'
        );
        insert jobSite;
        // Create Price Book
        Pricebook2 priceBook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update priceBook; 
        
        // Create quote
        List<SBQQ__Quote__c> quoteInsertList = new List<SBQQ__Quote__c>();
        SBQQ__Quote__c quote1 = new SBQQ__Quote__c(
            Quote_Name__c = 'Test Quote1',
            SBQQ__Account__c = acct.Id,
            Branch__c = branchLocation.Id,
            Jobsite__c = jobSite.Id,
            SBQQ__DeliveryMethod__c = 'Delivery',
            Delivery_Charge__c = 10,
            SBQQ__Status__c = 'Draft',
            SBQQ__PriceBook__c = priceBook.Id,
            Start_Date__c = system.today() +3,
            End_Date__c = system.today() +12,
            Delivery_Date__c =  system.today(),
            Opt_Out_RPP__c = false,
            Ordered_by__c = contact.Id,
            Opt_Out_Fuel_Charge__c = false,
            Selling_Channel__c = 'SBRB2B'
            //Duration__c = 'Custom'
        );
        quoteInsertList.add(quote1);
        
        SBQQ__Quote__c quote = new SBQQ__Quote__c(
            Quote_Name__c = 'Test Quote',
            SBQQ__Account__c = acct.Id,
            Branch__c = branchLocation.Id,
            Jobsite__c = jobSite.Id,
            SBQQ__DeliveryMethod__c = 'Delivery',
            Delivery_Charge__c = 10,
            SBQQ__Status__c = 'Draft',
            SBQQ__PriceBook__c = priceBook.Id,
            Start_Date__c = system.today() +2,
            End_Date__c = system.today() +12,
            Delivery_Date__c =  system.today()+3,
            Opt_Out_RPP__c = false,
            Ordered_by__c = contact.Id,
            Opt_Out_Fuel_Charge__c = false,
            Selling_Channel__c = 'SBRB2B'
           // Duration__c = 'Custom'
        );
        quoteInsertList.add(quote);
        insert quoteInsertList ;
        
        // Create Product
        List<Product2> products = new List<Product2>();
        for(Integer i = 0; i < 3; i++) {
            Product2 product = new Product2();
            product.Name = 'Test Product ' + i;
            if(i == 0) {
                product.Product_Type__c = 'Cat-Class';
                product.Product_SKU__c = '123456';
                product.Category__c = '32134';
                product.Class__c = '2039';
                product.ToolFlex__c = 'N';
            } else if (i == 1) {
                product.Product_Type__c = 'Parts';
                product.Item_Number__c = '1234GH';
                product.Stock_Class__c = 'AIMFV';
            } else {
                product.Product_Type__c = '';
                product.Item_Number__c = '1285JC';
                product.Stock_Class__c = 'MISC';
            }
            products.add(product);
        }
        insert products;

        List<PricebookEntry> pbEntryListInsert =  new  List<PricebookEntry>();

        PricebookEntry pbe1 = new PricebookEntry(
        Pricebook2Id = priceBook.Id,
        Product2Id = products[0].Id,
        UnitPrice = 1020,
        IsActive = true);
        pbEntryListInsert.add(pbe1);
        
        PricebookEntry pbe2 = new PricebookEntry(
        Pricebook2Id = priceBook.Id,
        Product2Id = products[1].Id,
        UnitPrice = 1020,
        IsActive = true);
        pbEntryListInsert.add(pbe2);
        
        PricebookEntry pbe3 = new PricebookEntry(
        Pricebook2Id = priceBook.Id,
        Product2Id = products[2].Id,
        UnitPrice = 1020,
        IsActive = true);
        pbEntryListInsert.add(pbe3);
        insert pbEntryListInsert;

        // Create Price Book Entry
        /* List<PricebookEntry> listPbe = new List<PricebookEntry>();
        Map<Id, Id> mapPBE = new Map<Id, Id>();
        List<PricebookEntry> pbEntryList = [SELECT Id,Product2Id FROM PricebookEntry WHERE Pricebook2Id = :priceBook.Id];
        System.debug('pbEntryList->'+JSON.serialize(pbEntryList));
        for(PricebookEntry pbEntry : pbEntryList) {
            if(pbEntry.Product2Id == products[0].Id){
                mapPBE.put(pbEntry.Product2Id, pbEntry.Id);
            }
            else if(pbEntry.Product2Id == products[1].Id){
                mapPBE.put(pbEntry.Product2Id, pbEntry.Id);
            }
            else if(pbEntry.Product2Id == products[2].Id){
                mapPBE.put(pbEntry.Product2Id, pbEntry.Id);
            }
        } */

        PricebookEntry pbEntry = [SELECT Id,CurrencyIsoCode FROM PricebookEntry WHERE Pricebook2Id = :priceBook.Id AND Product2Id = :products[0].Id LIMIT 1];
        PricebookEntry pbEntry2 = [SELECT Id FROM PricebookEntry WHERE Pricebook2Id = :priceBook.Id AND Product2Id = :products[1].Id LIMIT 1];
        PricebookEntry pbEntry3 = [SELECT Id FROM PricebookEntry WHERE Pricebook2Id = :priceBook.Id AND Product2Id = :products[2].Id LIMIT 1];
        
        // Create Order item
        List<SBQQ__QuoteLine__c> quoteItems = new List<SBQQ__QuoteLine__c>();
       for(Integer i = 0; i < 3; i++){
            SBQQ__QuoteLine__c quoteItem = new SBQQ__QuoteLine__c();
            quoteItem.SBQQ__Quote__c = quote.Id;
            quoteItem.SBQQ__Product__c = products[i].Id;
            quoteItem.SBQQ__UnitCost__c = 100;
            quoteItem.RM_Quote_Line_Number__c = i;
            quoteItem.Min_Rate__c = 2;
            quoteItem.Daily_Rate__c = 2.0;
            quoteItem.Weekly_Rate__c = 2.0;
            quoteItem.Monthly_Rate__c = 2.0;
            quoteItem.SBQQ__PricebookEntryId__c = pbEntry.Id;
            if(i == 0) {
                quoteItem.Hourly_Rate__c = 2.0;
                quoteItem.Min_Rate__c = 2.0;
                quoteItem.SBQQ__Quantity__c = 5;
                quoteItem.Free_Flag__c = false;
                quoteItem.Suggested_Daily_Rate__c = 2.0;
                quoteItem.Suggested_Weekly_Rate__c = 2.0;
                quoteItem.Suggested_Monthly_Rate__c = 2.0;
                quoteItem.Daily_Rate__c = 2.0;
                quoteItem.Weekly_Rate__c = 2.0;
                quoteItem.Monthly_Rate__c = 2.0;
                quoteItem.Rates_Overriden__c = false;
              //  orderItem.Line_Comments__c = 'Comments';
               // orderItem.SBQQ__Number__c = 5;
            } else if (i == 1) {
                quoteItem.SBQQ__Quantity__c = 3;
                //orderItem.ListPrice = pbEntry2.ListPrice;
            } else {
                quoteItem.SBQQ__Quantity__c = 3;
                quoteItem.Misc_Charges_Type__c = 'TRANSPORTATION CHARGE';
                quoteItem.Misc_Charge__c = 20.3;
                quoteItem.Misc_Charges_Tax__c = 2.34;
                quoteItem.SBQQ__Taxable__c = false;
                quoteItem.Misc_Charges_Non_Taxable__c = false;
                quoteItem.Misc_Charges_Item_Tax_Rate__c = 2.0;
                quoteItem.is_Forced_Item__c = true;
            }
            quoteItems.add(quoteItem);
        }
        System.debug('quoteItems->'+JSON.serialize(quoteItems));
        insert quoteItems;
        
        // Create Order
        List<Order> orderListInsert = new List<Order>();
        Order order = new Order(
            Quote_Name__c = 'Test Quote',
            AccountId = acct.Id,
            Jobsite__c = jobSite.Id,
            Deliverymethod__c = 'Delivery',
            Delivery_Charge__c = 10,
            Status = 'Draft',
            Pricebook2Id = priceBook.Id,
            Start_Date__c = system.today() +3,
            EffectiveDate = system.today() +3,
            EndDate = system.today() +12,
            Return_Date__c = system.today() +30,
            Estimated_Return_Date__c = system.today() +30,
            Earliest_Delivery_Date__c = system.today() +2,
            Opt_Out_RPP__c = false,
            Order_Initiating_Channel__c = 'SLSFRC',
            Opt_Out_Fuel_Charge__c = false,
            Selling_Channel__c = 'SBRB2B',
            Duration__c = 'Custom',
            //Reservation_Order_Number__c = '12342',
            Branch__c = branchLocation.Id,
            RecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('Reservation Order').getRecordTypeId()
        );
        orderListInsert.add(order);
        
         
        Order order1 = new Order(
            Quote_Name__c = 'Test Quote1',
            AccountId = acct.Id,
            Jobsite__c = jobSite.Id,
            Deliverymethod__c = 'Delivery',
            Delivery_Charge__c = 10,
            Status = 'Draft',
            Pricebook2Id = priceBook.Id,
            Start_Date__c = system.today() - 1,
            EffectiveDate = system.today() +1,
            EndDate = system.today() +12,
            Return_Date__c = system.today() +30,
            Estimated_Return_Date__c = system.today() +30,
            Earliest_Delivery_Date__c = system.today()-1,
            //Reservation_Order_Number__c = '12342',
            Branch__c = branchLocation.Id,
            RecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('Reservation Order').getRecordTypeId()
        );
        orderListInsert.add(order1);
		insert orderListInsert;            
        
        //Create Asset 
        Asset ast = new Asset();
        ast.Status = 'SCHEDULED FOR PICKUP';
        ast.Name = 'Test Asset';
        ast.AccountId = acct.Id;
        insert ast;
        
        
        //Create Order item details
        List<Order_Item_Detail__c> orderItemsDetails = new List<Order_Item_Detail__c>();
        Order_Item_Detail__c orderItemDetail = new Order_Item_Detail__c();
        orderItemDetail.Pickup_Ticket__c = 'Test ticket';
        insert orderItemDetail; 
        
        // Create Order item
        List<OrderItem> orderItems = new List<OrderItem>();
       for(Integer i = 0; i < 3; i++){
            OrderItem orderItem = new OrderItem();
            orderItem.OrderId = order.Id;
            orderItem.Product2Id = products[i].Id;
            orderItem.UnitPrice = 100;
            orderItem.Item_Number__c = i;
            orderItem.Min_Rate__c = 2;
            orderItem.Daily_Rate__c = 2.0;
            orderItem.Weekly_Rate__c = 2.0;
            orderItem.Monthly_Rate__c = 2.0;
            orderItem.Order_Item_Detail__c = orderItemDetail.Id;
            orderItem.SBQQ__Asset__c = ast.Id;
          
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
                orderItem.PricebookEntryId = pbEntry.Id;
            } else if (i == 1) {
                orderItem.Quantity = 3;
                orderItem.PricebookEntryId = pbEntry2.Id;
            } else {
                orderItem.Quantity = 3;
                orderItem.Misc_Charges_Type__c = 'TRANSPORTATION CHARGE';
                orderItem.Misc_Charge__c = 20.3;
                orderItem.Misc_Charges_Tax__c = 2.34;
                orderItem.Taxable__c = false;
                orderItem.Misc_Charges_Non_Taxable__c = false;
                orderItem.Misc_Charges_Item_Tax_Rate__c = 2.0;
                orderItem.PricebookEntryId = pbEntry3.Id;
                orderItem.is_Forced_Item__c = true;
            }
            orderItems.add(orderItem);
        }
        System.debug('orderItems->'+JSON.serialize(orderItems));
        insert orderItems;
    }
    }

    public HTTPResponse respond(HTTPRequest req) {
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type',SBR_3_0_Constants.APP_JSON);
        if(req.getEndpoint().endsWithIgnoreCase('token')){
            res.setBody('{"access_token":"test"}');
        }else {
            res.setBody('{ "data": { "estimate": { "itemizedCharges": { "orderLines": [ { "salesItems": [ { "itemNumber": "4FPK3", "stockClass": "GRAIN", "unitPrice": 292.000, "totalPrice": 292.00, "salesTax": 20.44, "salesTaxRate": 7.0000, "quantity": 1.00 } ] }, { "products": [ { "catId": "016", "classId": "0010", "rentalCost": 123456789.12, "unitRentalCost": 123456789.12, "quantity": 1.00, "rentalTax": 8641975.24, "rentalTaxRate": 7.0000, "rppCost": 18518518.36, "unitRPPCost": 18518518.36, "rppTax": 1296296.29, "rppTaxRate": 7.0000, "isSerialized": true }, { "catId": "008", "classId": "0007", "rentalCost": 123456789.12, "unitRentalCost": 123456789.12, "quantity": 1.00, "rentalTax": 8641975.24, "rentalTaxRate": 7.0000, "rppCost": 18518518.36, "unitRPPCost": 18518518.36, "rppTax": 1296296.29, "rppTaxRate": 7.0000, "isSerialized": true } ] } ] }, "miscCharges": [ { "type": "DELIVERY", "charge": 1234.12, "tax": 7.70, "taxExempt": false, "nonTaxable": false, "itemTaxRate": 7.0000 }, { "type": "FUEL CONVENIENCE CHARGE", "charge": 23.75, "tax": 1.66, "taxExempt": false, "nonTaxable": false, "itemTaxRate": 7.0000 }, { "type": "PICKUP", "charge": 110.00, "tax": 7.70, "taxExempt": false, "nonTaxable": false, "itemTaxRate": 7.0000 }, { "type": "SC 2.5% HEAVY EQUIP. RENTAL SURCHARGE", "charge": 6172839.46, "tax": 0, "taxExempt": false, "nonTaxable": true, "itemTaxRate": 0 }, { "type": "TRANSPORTATION SURCHARGE", "charge": 35.20, "tax": 2.46, "taxExempt": false, "nonTaxable": false, "itemTaxRate": 7.0000 } ], "taxInfo": [ { "taxRateUsed": 7.0000, "taxRateFromPC": true, "currencyCode": "USD" } ], "totals": { "rentalAmount": 246913578.24, "rppCharges": 37037036.72, "miscCharges": 6174242.53, "finalTotal": 310001732.51, "salesAmount": 292.00, "salesTax": 19876583.02 }, "otherDetails": { "distBetweenPCandSite": 90, "unitOfDistance": "miles", "unitofCurrency": [ "USD" ] } } } }');
        }
        res.setStatusCode(200);
        return res;
    }
    @isTest static void testGetEstimates() {
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_Estimates_Test());
        Test.startTest();
        String estimatesRequestJson = '{ "orderType": "Delivery", "ratesToBeUsed": "SUGGESTED", "pc": [ { "id": 5105, "latitude": 47.6044, "longitude": -122.3345, "timezone": "America/New_York" } ], "jobNumber": "1234567", "account": 1, "startDateAndTime": "2023-05-07T09:28:56.321-10:00", "endDateAndTime": "2023-05-09T09:28:56.321-10:00", "distance": 90, "address": [ { "type": "jobsite", "line1": "1151 stonecrest Blvd", "city": "Tega cay", "state": "SC", "zip": "297086555", "latitude": -38.9954527, "longitude": -93.093325 } ], "delivery": [ { "chargesOverride": true, "charges": "1234.12" } ], "pickup": [ { "chargesOverride": false, "charges": "1234.12" } ], "orderLines": [ { "salesItems": [ { "itemNumber": "4FPK3", "stockClass": "GRAIN", "unitPrice": 292, "quantity": 1 } ], "products": [ { "catId": "016", "classId": "0010", "quantity": 1 }, { "catId": "008", "classId": "0007", "quantity": 1, "rates": { "override": true, "hourly": "123456789.12", "minimum": "12456779.12", "daily": "123456789.12", "weekly": "123456789.12", "monthly": "123456789.12" } } ] } ] }';
        System.assert(String.isNotEmpty(SBR_3_0_API_Estimates.getEstimates(estimatesRequestJson, '1')), 'No Estimates Data Received From Rates API');
        Test.stopTest();
    }

    @isTest static void testGetEstimatesNoStartDate() {
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_Estimates_Test());
        Test.startTest();
        String estimatesRequestJson = '{ "orderType": "Delivery", "ratesToBeUsed": "SUGGESTED", "pc": [ { "id": 5105, "latitude": 47.6044, "longitude": -122.3345, "timezone": "America/New_York" } ], "jobNumber": "1234567", "account": 1,  "endDateAndTime": "2023-05-09T09:28:56.321-10:00", "distance": 90, "address": [ { "type": "jobsite", "line1": "1151 stonecrest Blvd", "city": "Tega cay", "state": "SC", "zip": "297086555", "latitude": -38.9954527, "longitude": -93.093325 } ], "delivery": [ { "chargesOverride": true, "charges": "1234.12" } ], "pickup": [ { "chargesOverride": false, "charges": "1234.12" } ], "orderLines": [ { "salesItems": [ { "itemNumber": "4FPK3", "stockClass": "GRAIN", "unitPrice": 292, "quantity": 1 } ], "products": [ { "catId": "016", "classId": "0010", "quantity": 1 }, { "catId": "008", "classId": "0007", "quantity": 1, "rates": { "override": true, "hourly": "123456789.12", "minimum": "12456779.12", "daily": "123456789.12", "weekly": "123456789.12", "monthly": "123456789.12" } } ] } ] }';
        System.assert(String.isNotEmpty(SBR_3_0_API_Estimates.getEstimates(estimatesRequestJson, '1')), 'No Estimates Data Received From Rates API');
        Test.stopTest();
    }
    
    @isTest static void testGetEstimatesNoEndDate() {
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_Estimates_Test());
        Test.startTest();
        String estimatesRequestJson = '{ "orderType": "Delivery", "ratesToBeUsed": "SUGGESTED", "pc": [ { "id": 5105, "latitude": 47.6044, "longitude": -122.3345, "timezone": "America/New_York" } ], "jobNumber": "1234567", "account": 1, "startDateAndTime": "2023-05-07T09:28:56.321-10:00", "distance": 90, "address": [ { "type": "jobsite", "line1": "1151 stonecrest Blvd", "city": "Tega cay", "state": "SC", "zip": "297086555", "latitude": -38.9954527, "longitude": -93.093325 } ], "delivery": [ { "chargesOverride": true, "charges": "1234.12" } ], "pickup": [ { "chargesOverride": false, "charges": "1234.12" } ], "orderLines": [ { "salesItems": [ { "itemNumber": "4FPK3", "stockClass": "GRAIN", "unitPrice": 292, "quantity": 1 } ], "products": [ { "catId": "016", "classId": "0010", "quantity": 1 }, { "catId": "008", "classId": "0007", "quantity": 1, "rates": { "override": true, "hourly": "123456789.12", "minimum": "12456779.12", "daily": "123456789.12", "weekly": "123456789.12", "monthly": "123456789.12" } } ] } ] }';
        System.assert(String.isNotEmpty(SBR_3_0_API_Estimates.getEstimates(estimatesRequestJson, '1')), 'No Estimates Data Received From Rates API');
        Test.stopTest();
    }
    
    @isTest
    static void testGetEstimate(){
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_Estimates_Test());
        
        Test.startTest();
        SBQQ__Quote__c quote = [SELECT id FROM SBQQ__Quote__c Where Quote_Name__c = 'Test Quote'];
        SBR_3_0_API_EstimatesResponseWrapper estimateResWrapper = SBR_3_0_API_Estimates.getEstimate(quote.Id);
        Test.stopTest();
        System.assert(estimateResWrapper != null);
    }
    
    @isTest
    static void testGetEstimate1(){
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_Estimates_Test());
       
        Test.startTest();
        Order order = [SELECT id FROM Order Where Quote_Name__c = 'Test Quote'];
        SBR_3_0_API_EstimatesResponseWrapper estimateResWrapper = SBR_3_0_API_Estimates.getEstimate(order.Id);
        Test.stopTest();
        System.assert(estimateResWrapper != null);
    }
    
    @isTest
    static void testGetEstimate2(){
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_Estimates_Test());
       
        Test.startTest();
        SBQQ__Quote__c quote = [SELECT id FROM SBQQ__Quote__c Where Quote_Name__c = 'Test Quote1'];
        try{
            SBR_3_0_API_EstimatesResponseWrapper estimateResWrapper = SBR_3_0_API_Estimates.getEstimate(quote.Id);
        }
        Catch(Exception e){
            System.assertEquals('Cat Class Products are required', e.getMessage(), 'Exception should be thrown');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testGetEstimate3(){
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_Estimates_Test());
       
        Test.startTest();
        Order order = [SELECT id FROM Order Where Quote_Name__c = 'Test Quote1'];
        try{
            SBR_3_0_API_EstimatesResponseWrapper estimateResWrapper = SBR_3_0_API_Estimates.getEstimate(order.Id);
        }
        Catch(Exception e){
            System.assertEquals('Start Date cannot be in the past', e.getMessage(), 'Exception should be thrown');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testGetEstimate4(){
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_Estimates_Test());
        Test.startTest();
        try{
            SBQQ__Quote__c quote = [SELECT id FROM SBQQ__Quote__c Where Quote_Name__c = 'Test Quote1'];
            quote.Start_Date__c = null;
            update quote;
            SBR_3_0_API_EstimatesResponseWrapper estimateResWrapper = SBR_3_0_API_Estimates.getEstimate(quote.Id);
        }
        Catch(Exception e){
            System.assertEquals('Start Date is required', e.getMessage(), 'Exception should be thrown');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testGetEstimate5(){
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_Estimates_Test());
        Test.startTest();
        try{
         SBQQ__Quote__c quote = [SELECT id FROM SBQQ__Quote__c Where Quote_Name__c = 'Test Quote1'];
        quote.SBQQ__DeliveryMethod__c = null;
        update quote;
            SBR_3_0_API_EstimatesResponseWrapper estimateResWrapper = SBR_3_0_API_Estimates.getEstimate(quote.Id);
        }
        Catch(Exception e){
            System.assertEquals('Delivery Method is required', e.getMessage(), 'Exception should be thrown');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testGetEstimatePipline(){
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_Estimates_Test());
        Map<String, SBR_3_0_API_EstimatesResponseWrapper> estimatesRespWrapperMap = new  Map<String, SBR_3_0_API_EstimatesResponseWrapper>();
        
        Test.startTest();
        List<Schema.Location> locationData = SBR_3_0_LocationDA.getLocation('720');
        SBQQ__Quote__c quote = [SELECT id FROM SBQQ__Quote__c Where Quote_Name__c = 'Test Quote'];
        estimatesRespWrapperMap = SBR_3_0_API_Estimates.getEstimatesFromSourcingBranch(quote.Id,locationData[0]);
        Test.stopTest();
        System.assert(estimatesRespWrapperMap != null);
    }
     @isTest
    static void testGetEstimatePiplineOrder(){
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_Estimates_Test());
        Map<String, SBR_3_0_API_EstimatesResponseWrapper> estimatesRespWrapperMap = new  Map<String, SBR_3_0_API_EstimatesResponseWrapper>();
        
        Test.startTest();
        List<Schema.Location> locationData = SBR_3_0_LocationDA.getLocation('720');
        Order order = [SELECT id FROM Order Where Quote_Name__c = 'Test Quote'];
        estimatesRespWrapperMap = SBR_3_0_API_Estimates.getEstimatesFromSourcingBranch(order.Id,locationData[0]);
        Test.stopTest();
        System.assert(estimatesRespWrapperMap != null);
    }
    
    @isTest
    static void testEstimatesStartDateInPast(){
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_Estimates_Test());
        Map<String, SBR_3_0_API_EstimatesResponseWrapper> estimatesRespWrapperMap = new  Map<String, SBR_3_0_API_EstimatesResponseWrapper>();
        
        Test.startTest();
        List<Schema.Location> locationData = SBR_3_0_LocationDA.getLocation('720');
        SBQQ__Quote__c quote = [SELECT id FROM SBQQ__Quote__c Where Quote_Name__c = 'Test Quote'];
        quote.Start_Date__c = System.today()-2;
        quote.End_Date__c = System.today()+2;
        update quote;
        try{
            estimatesRespWrapperMap = SBR_3_0_API_Estimates.getEstimatesFromSourcingBranch(quote.Id,locationData[0]);
        }Catch(Exception ex){
            System.assertEquals('Start Date cannot be in the past. Please update the Start Date field to future date/time and try again.',ex.getMessage());
        }
        
        Test.stopTest();
        System.assert(estimatesRespWrapperMap != null);
    }
    
    @isTest
    static void testGetEstimateOrderStartDateInPast(){
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_Estimates_Test());
        Map<String, SBR_3_0_API_EstimatesResponseWrapper> estimatesRespWrapperMap = new  Map<String, SBR_3_0_API_EstimatesResponseWrapper>();
        
        Test.startTest();
        List<Schema.Location> locationData = SBR_3_0_LocationDA.getLocation('720');
        Order order = [SELECT id FROM Order Where Quote_Name__c = 'Test Quote'];
        order.Start_Date__c = System.today()-2;
        order.EndDate = System.today()+5;
        order.Return_Date__c = System.today()+5;
        update order; 
        try{
        	estimatesRespWrapperMap = SBR_3_0_API_Estimates.getEstimatesFromSourcingBranch(order.Id,locationData[0]);
        }Catch(Exception ex){
            System.assertEquals('Start Date cannot be in the past',ex.getMessage());
        }
        Test.stopTest();
        System.assert(estimatesRespWrapperMap != null);
    }
    @isTest
    static void testGetEstimateOrderStartDateNull(){
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_Estimates_Test());
        Map<String, SBR_3_0_API_EstimatesResponseWrapper> estimatesRespWrapperMap = new  Map<String, SBR_3_0_API_EstimatesResponseWrapper>();
        
        Test.startTest();
        List<Schema.Location> locationData = SBR_3_0_LocationDA.getLocation('720');
        Order order = [SELECT id FROM Order Where Quote_Name__c = 'Test Quote'];
        order.Start_Date__c =System.today()+1;
        order.EndDate = System.today()+5;
        order.Return_Date__c = System.today()+5;
        update order; 
        try{
        	estimatesRespWrapperMap = SBR_3_0_API_Estimates.getEstimatesFromSourcingBranch(order.Id,locationData[0]);
        }Catch(Exception ex){
            System.assertNotEquals(null,ex.getMessage());
            
        }
        Test.stopTest();
        System.assert(estimatesRespWrapperMap != null);
    }
    @isTest
    static void testGetEstimateOrderEstimatedDateNull(){
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_Estimates_Test());
        Map<String, SBR_3_0_API_EstimatesResponseWrapper> estimatesRespWrapperMap = new  Map<String, SBR_3_0_API_EstimatesResponseWrapper>();
        
        Test.startTest();
        List<Schema.Location> locationData = SBR_3_0_LocationDA.getLocation('720');
        Order order = [SELECT id FROM Order Where Quote_Name__c = 'Test Quote'];
        //order.Estimated_Return_Date__c =null;
        //update order; 
        try{
        	estimatesRespWrapperMap = SBR_3_0_API_Estimates.getEstimatesFromSourcingBranch(order.Id,locationData[0]);
            order.Estimated_Return_Date__c =null;
            update order;
        }Catch(Exception ex){
            System.assertEquals('End Date is required',ex.getMessage());
        }
        Test.stopTest();
        System.assert(estimatesRespWrapperMap != null);
    }
    
    @isTest
    static void testGetEstimateOrderDeliveryMethodNull(){
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_Estimates_Test());
        Map<String, SBR_3_0_API_EstimatesResponseWrapper> estimatesRespWrapperMap = new  Map<String, SBR_3_0_API_EstimatesResponseWrapper>();
        
        Test.startTest();
        List<Schema.Location> locationData = SBR_3_0_LocationDA.getLocation('720');
        Order order = [SELECT id FROM Order Where Quote_Name__c = 'Test Quote'];
        order.Deliverymethod__c =null;
        update order; 
        try{
        	estimatesRespWrapperMap = SBR_3_0_API_Estimates.getEstimatesFromSourcingBranch(order.Id,locationData[0]);
        }Catch(Exception ex){
            System.assertEquals('Delivery Method is required',ex.getMessage());
        }
        Test.stopTest();
        System.assert(estimatesRespWrapperMap != null);
    }
    
}