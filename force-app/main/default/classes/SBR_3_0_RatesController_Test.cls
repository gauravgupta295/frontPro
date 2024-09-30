@isTest
private class SBR_3_0_RatesController_Test {
	 @TestSetup
    static void makeData(){
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
        jobLocation.Company_Code__c = '02';
        jobLocation.Time_Zone_Id__c = 'America/Denver';
        insert jobLocation;
        // Create Branch

        String latlong = ('{"latitude": 37.739223,"longitude": -122.39922}');
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
        branchLocation.Time_Zone__c = 3;
        branchLocation.OMS_Sourcing_Enabled__c = true;
        branchLocation.Time_Zone_Id__c = 'America/Denver';
        branchLocation.Latitude_Longitude__Latitude__s = 48.56;
        branchLocation.Latitude_Longitude__Longitude__s = -117.66;

        insert branchLocation;
        //branchLocation2.Latitude_Longitude__Latitude__s = 48.56;
        //branchLocation2.Latitude_Longitude__Longitude__s = -117.66;
        // Create Job Site
        AssociatedLocation jobSite = new AssociatedLocation(
            Name__c = 'Test Job Site',
            ParentRecordId = acct.Id,
            LocationId = jobLocation.Id,
            Branch__c = branchLocation.Id,
            Latitude_Longitude__Latitude__s = 48.51,
            Latitude_Longitude__Longitude__s = -117.62,
            Job_Number__c = '20221004A',
            Time_Zone_Id__c = 'America/Denver'
        );
        insert jobSite;
        
        AssociatedLocation jobSite1 = new AssociatedLocation(
            Name__c = 'Test Job Site',
            ParentRecordId = acct.Id,
            LocationId = jobLocation.Id,
            Branch__c = branchLocation.Id,
            Job_Number__c = '20221004A',
            Time_Zone_Id__c = 'America/Denver'
        );
        insert jobSite1;
        
        // Create Price Book
        Pricebook2 priceBook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update priceBook;
        
        // Create Product
        Product2 prod = new Product2(Name = 'Test Product 1', Product_Title_Internal__c = 'Test Product 1', Product_SKU__c = '1234567', Product_Type__c = 'Cat-Class');
        Product2 prod2 = new Product2(Name = 'Test Product 2', Product_Title_Internal__c = 'Test Product 2', Product_SKU__c = '01-PIPSA-817633', Product_Type__c = 'Merchandise');
        Product2 prod3 = new Product2(Name = 'Test Product 3', Product_Title_Internal__c = 'Test Product 3', Product_SKU__c = '123003',Product_Type__c = 'Merchandise');
        insert prod;
        insert prod2;
        insert prod3;
        
        SBQQ__ProductFeature__c featureObj = new SBQQ__ProductFeature__c(
                Name = 'Rental Addons',
                Product_Feature_Load_Ext_ID__c = prod.Product_SKU__c + '_' + 'Rental Addons',
                SBQQ__ConfiguredSKU__c = prod.Id,
                SBQQ__MinOptionCount__c = 1,
                SBQQ__Number__c = 1
        );
		insert featureObj;
        
        SBQQ__ProductFeature__c salesObj = new SBQQ__ProductFeature__c(
            Name = 'Sales Addons',
            Product_Feature_Load_Ext_ID__c = prod.Product_SKU__c + '_' + 'Sales Addons',
            SBQQ__ConfiguredSKU__c = prod.Id,
            SBQQ__MinOptionCount__c = 1,
            SBQQ__Number__c = 1
        );
        insert salesObj;
        
        SBQQ__ProductOption__c prodOption = new SBQQ__ProductOption__c(
            SBQQ__ConfiguredSKU__c = prod.Id,
            SBQQ__OptionalSKU__c = prod2.Id,
            SBQQ__Number__c = 1,
            SBQQ__Feature__c = featureObj.Id,
            SBQQ__Required__c = true,
            Company_Code__c='01' ,
            SBQQ__Quantity__c = 1 
        );
        insert prodOption;
        
        SBQQ__ProductOption__c prodOption1 = new SBQQ__ProductOption__c(
            SBQQ__ConfiguredSKU__c = prod.Id,
            SBQQ__OptionalSKU__c = prod3.Id,
            SBQQ__Number__c = 1,
            SBQQ__Feature__c = salesObj.Id,
            SBQQ__Required__c = true,
            Company_Code__c='01' ,
            SBQQ__Quantity__c = 1 
        );
        insert prodOption1;
        
        
        // Create Order
        List<order> ordersList = new List<order>();
        Order order = new Order(
            Quote_Name__c = 'Test Quote',
            AccountId = acct.Id,
            Name='order1',
            Jobsite__c = jobSite.Id,
            Deliverymethod__c = 'Delivery',
            Delivery_Charge__c = 10,
            Status = 'Draft',
            Pricebook2Id = priceBook.Id,
            Start_Date__c = date.valueOf('2025-12-12 12:00:00'),
            EffectiveDate = date.valueOf('2025-12-12 12:00:00'),
            EndDate = date.valueOf('2026-10-09 8:00:00'),
            Return_Date__c = date.valueOf('2026-10-09 8:00:00'),
            Earliest_Delivery_Date__c = date.valueOf('2026-10-08 12:00:00'),
            Opt_Out_RPP__c = false,
            Order_Initiating_Channel__c = 'SLSFRC',
            Opt_Out_Fuel_Charge__c = false,
            Selling_Channel__c = 'SBRB2B',
            Duration__c = 'Custom',
            Branch__c = branchLocation.Id,
            Sourcing_Branch__c = branchLocation.Id,
            RecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('Reservation Order').getRecordTypeId()
        );
        ordersList.add(order);

        // ATP order
        Order orderNoJS = new Order(
            Quote_Name__c = 'Test Quote no JS',
            AccountId = acct.Id,
            Name='order2',
            //Jobsite__c = jobSite.Id,
            Deliverymethod__c = 'Delivery',
            Delivery_Charge__c = 10,
            Status = 'Draft',
            Pricebook2Id = priceBook.Id,
            Start_Date__c = date.valueOf('2024-12-12 12:00:00'),
            EffectiveDate = date.valueOf('2024-12-12 12:00:00'),
            EndDate = date.valueOf('2025-10-09 8:00:00'),
            Return_Date__c = date.valueOf('2025-10-09 8:00:00'),
            Earliest_Delivery_Date__c = date.valueOf('2026-10-08 12:00:00'),
            Opt_Out_RPP__c = false,
            Order_Initiating_Channel__c = 'SLSFRC',
            Opt_Out_Fuel_Charge__c = false,
            Selling_Channel__c = 'SBRB2B',
            Duration__c = 'Custom',
            Branch__c = branchLocation.Id,
            Sourcing_Branch__c = branchLocation.Id,
            RecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('Reservation Order').getRecordTypeId()
        );
        ordersList.add(orderNoJS);

        // ATP order
        Order orderNoDeliveryMeth = new Order(
            Quote_Name__c = 'Test Quote no delivery meth',
            AccountId = acct.Id,
            Name='order3',
            //Jobsite__c = jobSite.Id,
            Deliverymethod__c = '',
            Delivery_Charge__c = 10,
            Status = 'Draft',
            Pricebook2Id = priceBook.Id,
            Start_Date__c = date.valueOf('2025-12-12 12:00:00'),
            EffectiveDate = date.valueOf('2025-12-12 12:00:00'),
            EndDate = date.valueOf('2026-10-09 8:00:00'),
            Return_Date__c = date.valueOf('2026-10-09 8:00:00'),
            Earliest_Delivery_Date__c = date.valueOf('2026-10-08 12:00:00'),
            Opt_Out_RPP__c = false,
            Order_Initiating_Channel__c = 'SLSFRC',
            Opt_Out_Fuel_Charge__c = false,
            Selling_Channel__c = 'SBRB2B',
            Duration__c = 'Custom',
            Branch__c = branchLocation.Id,
            Sourcing_Branch__c = branchLocation.Id,
            RecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('Reservation Order').getRecordTypeId()
        );
        ordersList.add(orderNoDeliveryMeth);

        // ATP order
        Order orderNoSB = new Order(
            Quote_Name__c = 'Test Quote no SB',
            AccountId = acct.Id,
            Name='order4',
            //Jobsite__c = jobSite.Id,
            Deliverymethod__c = 'Delivery',
            Delivery_Charge__c = 10,
            Status = 'Draft',
            Pricebook2Id = priceBook.Id,
            Start_Date__c = date.valueOf('2025-12-12 12:00:00'),
            EffectiveDate = date.valueOf('2025-12-12 12:00:00'),
            EndDate = date.valueOf('2026-10-09 8:00:00'),
            Return_Date__c = date.valueOf('2026-10-09 8:00:00'),
            Earliest_Delivery_Date__c = date.valueOf('2026-10-08 12:00:00'),
            Opt_Out_RPP__c = false,
            Order_Initiating_Channel__c = 'SLSFRC',
            Opt_Out_Fuel_Charge__c = false,
            Selling_Channel__c = 'SBRB2B',
            Duration__c = 'Custom',
            Branch__c = branchLocation.Id,
            //Sourcing_Branch__c = branchLocation.Id,
            RecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('Reservation Order').getRecordTypeId()
        );
        ordersList.add(orderNoSB);

                Order order2 = new Order(
            Quote_Name__c = 'Test Quote no Delivery',
            AccountId = acct.Id,
            Name='order5',
            //Jobsite__c = jobSite.Id,
            Deliverymethod__c = 'Delivery',
            Delivery_Charge__c = 10,
            Status = 'Draft',
            Pricebook2Id = priceBook.Id,
            Start_Date__c = date.valueOf('2025-12-12 12:00:00'),
            EffectiveDate = date.valueOf('2025-12-12 12:00:00'),
            EndDate = date.valueOf('2026-10-09 8:00:00'),
            Return_Date__c = date.valueOf('2026-10-09 8:00:00'),
            Earliest_Delivery_Date__c = date.valueOf('2026-10-08 12:00:00'),
            Opt_Out_RPP__c = false,
            Order_Initiating_Channel__c = 'SLSFRC',
            Opt_Out_Fuel_Charge__c = false,
            Selling_Channel__c = 'SBRB2B',
            Duration__c = 'Custom',
            //Branch__c = branchLocation.Id,
            //Sourcing_Branch__c = branchLocation.Id,
            RecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('Reservation Order').getRecordTypeId()
        );
        ordersList.add(order2);
        Order pickuporder = new Order(
            Quote_Name__c = 'Test Quote Pickup',
            AccountId = acct.Id,
            Name='order6',
            Jobsite__c = jobSite.Id,
            Deliverymethod__c = 'Pickup',
            Delivery_Charge__c = 10,
            Status = 'Draft',
            Pricebook2Id = priceBook.Id,
            Start_Date__c = date.valueOf('2025-12-12 12:00:00'),
            EffectiveDate = date.valueOf('2025-12-12 12:00:00'),
            EndDate = date.valueOf('2026-10-09 8:00:00'),
            Return_Date__c = date.valueOf('2026-10-09 8:00:00'),
            Earliest_Delivery_Date__c = date.valueOf('2026-10-08 12:00:00'),
            Opt_Out_RPP__c = false,
            Order_Initiating_Channel__c = 'SLSFRC',
            Opt_Out_Fuel_Charge__c = false,
            Selling_Channel__c = 'SBRB2B',
            Duration__c = 'Custom',
            Branch__c = branchLocation.Id,
            Sourcing_Branch__c = branchLocation.Id,
            RecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('Reservation Order').getRecordTypeId()
        );
        ordersList.add(pickuporder);
        insert ordersList;

        // Create Quote
        List<SBQQ__Quote__c> quoteList = new List<SBQQ__Quote__c>();
        SBQQ__Quote__c quote = new SBQQ__Quote__c(
            Quote_Name__c = 'Test Quote',
            SBQQ__Account__c = acct.Id,
            Jobsite__c = jobSite.Id,
            SBQQ__DeliveryMethod__c = 'Delivery',
            Start_Date__c = date.valueOf('2025-10-07 12:00:00'),
            End_Date__c = date.valueOf('2025-10-07 12:00:00'),
            Delivery_Date__c  = date.valueOf('2024-10-08 12:00:00'),
            Opt_Out_RPP__c = false,
            Opt_Out_Fuel_Charge__c = false,
            Selling_Channel__c = 'SBRB2B',
            Rentalman_Quote_Id__c = 'Test QId',
            Company_Code__c = '01',
            Show_Crew_Expense_Calculator__c = true,
            Branch__c = branchLocation.Id,
            Sourcing_Branch__c = branchLocation.Id
        );
        quoteList.add(quote);

        // Quote without a jobsite
        SBQQ__Quote__c quoteWithNoJobSite = new SBQQ__Quote__c(
            Quote_Name__c = 'Test Quote no JS',
            SBQQ__Account__c = acct.Id,
            Jobsite__c = null,
            SBQQ__DeliveryMethod__c = 'Delivery',
            Start_Date__c = date.valueOf('2024-10-07 12:00:00'),
            End_Date__c = date.valueOf('2024-10-07 12:00:00'),
            Delivery_Date__c  = date.valueOf('2025-10-08 12:00:00'),
            Opt_Out_RPP__c = false,
            Opt_Out_Fuel_Charge__c = false,
            Selling_Channel__c = 'SBRB2B',
            Rentalman_Quote_Id__c = 'Test QIdNoJS',
            Company_Code__c = '01',
            Show_Crew_Expense_Calculator__c = true,
            Branch__c = branchLocation.Id,
            Sourcing_Branch__c = branchLocation.Id
        );
        quoteList.add(quoteWithNoJobSite);

        // Quote without a sourcing branch
        SBQQ__Quote__c quoteWithNoSourcingBranch = new SBQQ__Quote__c(
            Quote_Name__c = 'Test Quote no SB',
            SBQQ__Account__c = acct.Id,
            Jobsite__c = null,
            SBQQ__DeliveryMethod__c = 'Delivery',
            Start_Date__c = date.valueOf('2024-10-07 12:00:00'),
            End_Date__c = date.valueOf('2024-10-07 12:00:00'),
            Delivery_Date__c  = date.valueOf('2024-10-08 12:00:00'),
            Opt_Out_RPP__c = false,
            Opt_Out_Fuel_Charge__c = false,
            Selling_Channel__c = 'SBRB2B',
            Rentalman_Quote_Id__c = 'Test QIdNOSB',
            Company_Code__c = '01',
            Show_Crew_Expense_Calculator__c = true,
            Branch__c = branchLocation.Id,
            Sourcing_Branch__c = null
        );
        quoteList.add(quoteWithNoSourcingBranch);

        // Quote no pickup and no delivery
        SBQQ__Quote__c quoteWithNoDeliveryMeth = new SBQQ__Quote__c(
            Quote_Name__c = 'Test Quote no method',
            SBQQ__Account__c = acct.Id,
            Jobsite__c = null,
            SBQQ__DeliveryMethod__c = '',
            Start_Date__c = date.valueOf('2024-10-07 12:00:00'),
            End_Date__c = date.valueOf('2024-10-07 12:00:00'),
            Delivery_Date__c  = date.valueOf('2024-10-08 12:00:00'),
            Opt_Out_RPP__c = false,
            Opt_Out_Fuel_Charge__c = false,
            Selling_Channel__c = 'SBRB2B',
            Rentalman_Quote_Id__c = 'Test QIdNOMeth',
            Company_Code__c = '01',
            Show_Crew_Expense_Calculator__c = true,
            Branch__c = branchLocation.Id,
            Sourcing_Branch__c = null
        );
        quoteList.add(quoteWithNoDeliveryMeth);

        SBQQ__Quote__c pickupQuote = new SBQQ__Quote__c(
            Quote_Name__c = 'Pickup Quote',
            SBQQ__Account__c = acct.Id,
            Jobsite__c = jobSite.Id,
            SBQQ__DeliveryMethod__c = 'Pickup',
            Start_Date__c = date.valueOf('2024-10-07 12:00:00'),
            End_Date__c = date.valueOf('2024-10-07 12:00:00'),
            Delivery_Date__c  = date.valueOf('2024-10-08 12:00:00'),
            Opt_Out_RPP__c = false,
            Opt_Out_Fuel_Charge__c = false,
            Selling_Channel__c = 'SBRB2B',
            Rentalman_Quote_Id__c = 'Test QId123',
            Company_Code__c = '01',
            Show_Crew_Expense_Calculator__c = true,
            Branch__c = branchLocation.Id,
            Sourcing_Branch__c = branchLocation.Id
        );
        quoteList.add(pickupQuote);
        insert quoteList; 

        User_Location__c ul = new User_Location__c();
        ul.Analysis_Region__c = region.Id;
        ul.User__c = UserInfo.getUserId();
        ul.Branch__c = branchLocation.Id;
        insert ul;
        
         List<Contact> cons = SBR_3_0_TestDataFactory.createContacts(1,acct.Id,true);
        Cart__c cart = new Cart__c(
            Account__c = acct.Id, 
            Branch__c = branchLocation.Id, 
            Rental_Start_Date__c = System.now()+2,
            Rental_End_Date__c = System.now()+3,
            Rental_Period__c = '1 Day', 
            Job_Site__c = jobSite.Id );
        insert cart;
    }
    
    // Mocking HTTP callouts
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        private Integer statusCode;
        private Boolean noLastResortBranch;

        MockHttpResponseGenerator(Integer statusCode) {
            this.statusCode = statusCode;
        }
        
        MockHttpResponseGenerator(Integer statusCode,Boolean noLastResortBranch) {
            this.statusCode = statusCode;
            this.noLastResortBranch = noLastResortBranch;
        }

        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setStatusCode(statusCode);
            res.setHeader('Content-Type',SBR_3_0_Constants.APP_JSON);
            if(req.getEndpoint().endsWithIgnoreCase('token')){
                // Access Token Response
                res.setBody('{"access_token":"test"}');
        	}else if(req.getEndpoint().endsWithIgnoreCase('rates') && statusCode == 200){
            	// Rates Response here
            	res.setBody('{ "data": { "errorCode": "0000", "errorDesc": "Success", "company": "01", "customer": "4", "jobsite": "CO MEDIMMUNE BOULDER", "location": "0720", "items": [ { "catId": "123", "classId": "4567", "productId": "1234567", "rateFlag": "B", "rateFlagDescription": "Book Rates", "notToExceed": "", "notToExceedDescription": "No override needed for any change.", "rppPercentage": ".000", "needPassword": "FALSE", "showAllRates": "FALSE", "suggestMinimalHours": ".00", "isConsumerCatClass": "FALSE", "isSerialized": "FALSE", "customerDiscountPercentageDaily": ".00", "customerDiscountPercentageWeekly": ".00", "customerDiscountPercentageMonthly": ".00", "customerMonthly": null, "rates": { "suggestedRates": { "minimum": "10", "daily": "10", "weekly": "70", "monthly": "300" }, "bookRates": { "minimum": ".00", "daily": ".00", "weekly": ".00", "monthly": ".00" } } } ] } }');
        	}else if(req.getEndpoint().endsWithIgnoreCase('atp/location') && statusCode == 200  && noLastResortBranch == true)
            {
                res.setBody('{"data":{"companyId":"01","sellingChannel":"SBRINT","cartId":"SBRINT","transactionType":"SBR","closestBranchSite":"01-0001","lastResortBranch":"","availabilityByProducts":[{"productId":"1234567","uom":"EA","availabilityByFulfillmentTypes":[{"fulfillmentType":"DEL","availabilityDetails":[{"availabilityByLocations":[{"locationType":"PC","locationId":"01-0001","atp":0,"geoDistanceFromJobSite":570.132}]}]}]},{"productId":"0898789","uom":"EA","availabilityByFulfillmentTypes":[{"fulfillmentType":"DEL","availabilityDetails":[{"availabilityByLocations":[]}]}]}]}}');
            }else if(req.getEndpoint().endsWithIgnoreCase('atp/location') && statusCode == 200 && noLastResortBranch == false)
            {
                res.setBody('{"data":{"companyId":"01","sellingChannel":"SBRINT","cartId":"SBRINT","transactionType":"SBR","closestBranchSite":"01-0001","lastResortBranch":"0898789","availabilityByProducts":[{"productId":"0898789","uom":"EA","availabilityByFulfillmentTypes":[{"fulfillmentType":"DEL","availabilityDetails":[{"availabilityByLocations":[]}]}]}]}}');
            }else if(req.getEndpoint().endsWithIgnoreCase('consumables')){
            // Consumables Response here
            res.setBody('{"data":{"suggestedItems":[{"catId":"20","classId":"615","rentables":[],"consumables":[{"inventoryClass":"206","invClassDescription":"PPE, RESPIRATORY","specGroups":[{"specNumber":"206-0002","title":"Disposable Respirator","specDescription":"Disposable Respirator","minPrice":6,"maxPrice":6,"products":[{"productNumber":"0898789","stockClass":"PIPSA","oemStockNumber":"10102481","productDescription":"N95 HARMFUL DUST RESPIRATOR 2 PACK","priceSchedule":"","sequence":"10","forceItem":"N","minQuantity":0,"sellingPrice":6,"availQuantity":25,"binNumber1":"SC3","binNumber2":"","binNumber3":"","rentalCat":"0","rentalClass":"0","isSerialized":false}]}]}]}]}}');
        }
            return res;
        }
    }
    
    @isTest static void testGetRates() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200));
        Test.startTest();
        String formattedResponse = SBR_3_0_RatesController.findRatesForProducts(new List<String>{'1234567'},null,'4','1806',true);
        Test.stopTest();
        List<SBR_3_0_SpotlightPanelCmpController.AddOn_Details> bulkProductDetails = (List<SBR_3_0_SpotlightPanelCmpController.AddOn_Details>) JSON.deserializeStrict(formattedResponse, List<SBR_3_0_SpotlightPanelCmpController.AddOn_Details>.Class);
        System.assertEquals('300', bulkProductDetails[0].ratesMonthly,'Received Rates');
    }
    
    @isTest static void testATPRates() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200,true));
        Test.startTest();
        String formattedResponse = SBR_3_0_RatesController.findRatesForProductbyAvailabilityLocation(null,new List<String>{'1234567','0898789'},'123','1804',true);
        Test.stopTest();
        List<SBR_3_0_SpotlightPanelCmpController.AddOn_Details> bulkProductDetails = (List<SBR_3_0_SpotlightPanelCmpController.AddOn_Details>) JSON.deserializeStrict(formattedResponse, List<SBR_3_0_SpotlightPanelCmpController.AddOn_Details>.Class);
        System.assertEquals(2, bulkProductDetails.size(), 'Response Received');
    }
    
    @isTest
    static void testExecuteOrderSuccess(){
        Order ord = [SELECT ID FROM Order WHERE Quote_Name__c = 'Test Quote' LIMIT 1];
        Test.startTest();
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200,true));
        	String formattedResponse = SBR_3_0_RatesController.findRatesForProductbyAvailabilityLocation(ord.Id,new List<String>{'1234567','0898789'},'123','1804',true);
        Test.stopTest();
        List<SBR_3_0_SpotlightPanelCmpController.AddOn_Details> bulkProductDetails = (List<SBR_3_0_SpotlightPanelCmpController.AddOn_Details>) JSON.deserializeStrict(formattedResponse, List<SBR_3_0_SpotlightPanelCmpController.AddOn_Details>.Class);
        System.assertEquals(2, bulkProductDetails.size(), 'No Response');
    }
    
    @isTest
    static void testExecuteOrderNoJSSuccess(){
        Order ord = [SELECT ID FROM Order WHERE Quote_Name__c = 'Test Quote no JS' LIMIT 1];
        Test.startTest();
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200,true));
        	String formattedResponse = SBR_3_0_RatesController.findRatesForProductbyAvailabilityLocation(ord.Id,new List<String>{'1234567','0898789'},'123','1804',true);
        Test.stopTest();
        List<SBR_3_0_SpotlightPanelCmpController.AddOn_Details> bulkProductDetails = (List<SBR_3_0_SpotlightPanelCmpController.AddOn_Details>) JSON.deserializeStrict(formattedResponse, List<SBR_3_0_SpotlightPanelCmpController.AddOn_Details>.Class);
        System.assertEquals(2, bulkProductDetails.size(), 'Response Received');
    }
    
    @isTest
    static void testExecuteQuoteDeliveryNoJSSuccess(){
        SBQQ__Quote__c quote = [SELECT ID FROM SBQQ__Quote__c WHERE Quote_Name__c = 'Test Quote no JS' LIMIT 1];
        String companyCode = '01';
        Test.startTest();
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200,true));
        	String formattedResponse = SBR_3_0_RatesController.findRatesForProductbyAvailabilityLocation(quote.Id,new List<String>{'1234567','0898789'},'123','1804',true);
        Test.stopTest();
        List<SBR_3_0_SpotlightPanelCmpController.AddOn_Details> bulkProductDetails = (List<SBR_3_0_SpotlightPanelCmpController.AddOn_Details>) JSON.deserializeStrict(formattedResponse, List<SBR_3_0_SpotlightPanelCmpController.AddOn_Details>.Class);
        System.assertEquals(2, bulkProductDetails.size(), 'Response Received');
    }
    
    @isTest
    static void testExecuteQuoteSuccess(){
        SBQQ__Quote__c quote = [SELECT ID FROM SBQQ__Quote__c WHERE Quote_Name__c = 'Test Quote' LIMIT 1];
        Test.startTest();
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200,true));
        	String formattedResponse = SBR_3_0_RatesController.findRatesForProductbyAvailabilityLocation(quote.Id,new List<String>{'1234567','0898789'},'123','1804',true);
        Test.stopTest();
        List<SBR_3_0_SpotlightPanelCmpController.AddOn_Details> bulkProductDetails = (List<SBR_3_0_SpotlightPanelCmpController.AddOn_Details>) JSON.deserializeStrict(formattedResponse, List<SBR_3_0_SpotlightPanelCmpController.AddOn_Details>.Class);
        System.assertEquals(2, bulkProductDetails.size(), 'Response Received');
    }
    
    @isTest
    static void testExecuteCartSuccess(){
       Cart__c cart = [SELECT Id,Name FROM Cart__c LIMIT 1];
        Test.startTest();
        	Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200,true));
        	String formattedResponse = SBR_3_0_RatesController.findRatesForProductbyAvailabilityLocation(cart.Id,new List<String>{'1234567','0898789'},'123','1804',true);
        Test.stopTest();
        List<SBR_3_0_SpotlightPanelCmpController.AddOn_Details> bulkProductDetails = (List<SBR_3_0_SpotlightPanelCmpController.AddOn_Details>) JSON.deserializeStrict(formattedResponse, List<SBR_3_0_SpotlightPanelCmpController.AddOn_Details>.Class);
        System.assertEquals(2, bulkProductDetails.size(), 'Response Received');
    }
    
    @isTest
    static void testExecutePickUpQuoteSuccess(){
         Test.startTest();
            SBQQ__Quote__c quote = [SELECT ID FROM SBQQ__Quote__c WHERE SBQQ__DeliveryMethod__c = 'Pickup' LIMIT 1];
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200,true));
            String formattedResponse = SBR_3_0_RatesController.findRatesForProductbyAvailabilityLocation(quote.Id,new List<String>{'1234567','0898789'},'123','1804',true);
    	Test.stopTest();
        List<SBR_3_0_SpotlightPanelCmpController.AddOn_Details> bulkProductDetails = (List<SBR_3_0_SpotlightPanelCmpController.AddOn_Details>) JSON.deserializeStrict(formattedResponse, List<SBR_3_0_SpotlightPanelCmpController.AddOn_Details>.Class);
        System.assertEquals(2, bulkProductDetails.size(), 'Response Received');
    }
    
    @isTest
    static void testExecutePickupOrderSuccess(){
        Test.startTest();
        Order ord = [SELECT ID FROM Order WHERE Deliverymethod__c = 'Pickup' LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200,true));
       	String formattedResponse = SBR_3_0_RatesController.findRatesForProductbyAvailabilityLocation(ord.Id,new List<String>{'1234567','0898789'},'123','1804',true);
        Test.stopTest();
        List<SBR_3_0_SpotlightPanelCmpController.AddOn_Details> bulkProductDetails = (List<SBR_3_0_SpotlightPanelCmpController.AddOn_Details>) JSON.deserializeStrict(formattedResponse, List<SBR_3_0_SpotlightPanelCmpController.AddOn_Details>.Class);
        System.assertEquals(2, bulkProductDetails.size(), 'Response Received');
    }
    
    @isTest
    static void testExecuteQuoteDeliveryNoMethodSuccess(){
        SBQQ__Quote__c quote = [SELECT ID FROM SBQQ__Quote__c WHERE Quote_Name__c = 'Test Quote no method' LIMIT 1];
        Test.startTest();
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200,true));
            String formattedResponse = SBR_3_0_RatesController.findRatesForProductbyAvailabilityLocation(quote.Id,new List<String>{'1234567','0898789'},'123','1804',true);
        Test.stopTest();
         List<SBR_3_0_SpotlightPanelCmpController.AddOn_Details> bulkProductDetails = (List<SBR_3_0_SpotlightPanelCmpController.AddOn_Details>) JSON.deserializeStrict(formattedResponse, List<SBR_3_0_SpotlightPanelCmpController.AddOn_Details>.Class);
        System.assertEquals(2, bulkProductDetails.size(), 'Response Received');
    }
    
    @isTest
    static void testExecuteOrderNoSBSuccess(){
        Order ord = [SELECT ID FROM Order WHERE Quote_Name__c = 'Test Quote no SB' LIMIT 1];
        Test.startTest();
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200,true));
       		String formattedResponse = SBR_3_0_RatesController.findRatesForProductbyAvailabilityLocation(ord.Id,new List<String>{'1234567','0898789'},'123','1804',true);
        Test.stopTest();
        List<SBR_3_0_SpotlightPanelCmpController.AddOn_Details> bulkProductDetails = (List<SBR_3_0_SpotlightPanelCmpController.AddOn_Details>) JSON.deserializeStrict(formattedResponse, List<SBR_3_0_SpotlightPanelCmpController.AddOn_Details>.Class);
        System.assertEquals(2, bulkProductDetails.size(), 'Response Received');
    }

}