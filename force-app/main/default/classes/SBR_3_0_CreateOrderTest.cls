/**
 * @description Test class for SBR_3_0_CreateOrder and related functionality
 * @author James Loghry
 */
@isTest
private class SBR_3_0_CreateOrderTest {
    
    @TestSetup
    static void makeData(){
        User admin = SBR_3_0_TestDataFactory.createAdminUser();
        admin.RepId__c = '99991234';
        update admin;
        
        //Creating two different Sales Reps users.
        SBR_3_0_TestDataFactory.createUsersWithPermissions(
            2, 
            true,
            'Sales',
            new Set<String>{ 'SalesUserPsl' },
            new Set<String>{ 'Sales_User '}
        );
        
        System.runAs(admin){
            Account acct = new Account(
                RM_Account_Number__c = '01-1234',
                Company_Code__c = '01',
                Name = 'Test Account',
                Record_Type_Text__c = 'Credit',
                E_mail_Address__c = '123@asdf.com',
                Phone = '1234567899',
                BillingStreet = '123 Main Street',
                BillingCity = 'Toronto',
                BillingPostalCode = 'M9N7V5',
                BillingState = 'ON',
                BillingCountry = 'CA',
                Drivers_License__c = 'AKF',
                Driver_s_License_State__c = 'AL'
            );
            insert acct;
           
            Contact contact = SBR_3_0_TestDataFactory.createContacts(1, acct.Id, true)[0];
            
            // Create Analysis Region
            Analysis_Region__c region = new Analysis_Region__c(
            	Analysis_Region_Key__c = '001',
            	Name = 'Test Region',
            	Company_Code__c = '01'
            );
            insert region;
            
            List<Schema.Location> locations = new List<Schema.Location>{
                new Schema.Location(
                    Branch_Location_Number__c = '0720',
                    Name = 'Test Branch Location',
                    Street_Address__c = '12 Main Street',
                    City__c = 'Fort Mill',
                    Zip_Code__c = '29060',
                    State__c = 'SC',
                    Country__c = 'US',
                    Job_Number__c='332112',
                    RecordTypeId = Schema.SObjectType.Location.getRecordTypeInfosByDeveloperName().get('Branch').getRecordTypeId(),
                    Company_Code__c = '01',
                    Time_Zone_Name__c = 'America/Chicago',
                    Time_Zone__c = 3,
                    Time_Zone_Id__c = 'America/Chicago',
                    Latitude_Longitude__Latitude__s = 40.464390,
                    Latitude_Longitude__Longitude__s = -80.601060
           	    ),
                new Schema.Location(
                    Name = 'Test Job Location',
                    Street_Address__c = '12 Main Street',
                    City__c = 'Columbia',
                    Zip_Code__c = '29063',
                    State__c = 'SC',
                    Country__c = 'US',
                    RecordTypeId = Schema.SObjectType.Location.getRecordTypeInfosByDeveloperName().get('Job_Location').getRecordTypeId(),
                    OMS_Sourcing_Enabled__c = true,
                    Distance_Multiplier__c = 50,
                    Analysis_Region_Key__c = '001',
                    Company_Code__c = '01',
                    Job_Site_Id__c = '12345'
                )
            };
            insert locations;
            // Create Job Site
            AssociatedLocation jobSite = new AssociatedLocation(
                Name__c = 'Test Job Site',
                Latitude_Longitude__Latitude__s = 40.464390,
                Latitude_Longitude__Longitude__s = -80.601060,
                ParentRecordId = acct.Id,
                LocationId = locations[1].Id,
                Branch__c = locations[0].Id,
                Job_Site_Id__c = '45678',
                Job_Number__c = '20221004A'
                
            );
            insert jobSite;
                
            // Create Product
            List<Product2> products = new List<Product2>();
            for(Integer i = 0; i < 100; i++) {
                products.add(
                    new Product2(
                        Name='Prod'+i,
                        Product_Type__c = 'Cat-Class',
                        Product_SKU__c = 'SKU' + i,
                        Category__c = '32134',
                        ToolFlex__c = 'N',
                        Company_Code__c ='01',
                        Unit_Weight_in_Pounds__c = 10
                	)
                );
            }
            products.get(0).Product_SKU__c = '0000000';
            //products.get(1).Product_SKU__c = '0000000';
            
            products.addAll(
                new List<Product2>{
                    //Default product for delivery.
                    new Product2(
                        Name='2114xxx000',
                        Product_Title_Internal__c = '2114xxx000',
                        Product_Type__c = 'MISC Charge Items',
                        Product_SKU__c = 'SKU101',
                        Category__c = '32134',
                        ToolFlex__c = 'N',
                        Company_Code__c ='01',
                        Type_of_Misc_Charge_Item__c = 'MS',
                        Stock_Class__c = 'DEL',
                        Item_Number__c = 'DELIVERY',
                        Unit_Weight_in_Pounds__c = 10
                    ),
                    //Default product for a pickup.
                    new Product2(
                        Name='2114xxx000',
                        Product_Title_Internal__c = '2114xxx000',
                        Product_Type__c = 'MISC Charge Items',
                        Product_SKU__c = 'SKU102',
                        Category__c = '32134',
                        ToolFlex__c = 'N',
                        Company_Code__c ='01',
                        Type_of_Misc_Charge_Item__c = 'MS',
                        Stock_Class__c = 'DEL',
                        Item_Number__c = 'PICKUP',
                        Unit_Weight_in_Pounds__c = 10
                    ),
                    //Default product for skus that are not found
                    new Product2(
                        Name='2114xxx002',
                        Product_Title_Internal__c = '2114xxx002',
                        Product_Type__c = 'MISC Charge Items',
                        Product_SKU__c = 'SKU103',
                        Category__c = '32134',
                        ToolFlex__c = 'N',
                        Company_Code__c ='01',
                        Type_of_Misc_Charge_Item__c = 'MS',
                        Stock_Class__c = 'DEL',
                        Item_Number__c = 'ITEMNOTFOUND',
                        Unit_Weight_in_Pounds__c = 10
                    ),
                    //Pickup product
                    new Product2(
                        Name='2114xxx004',
                        Product_Title_Internal__c = '2114xxx003',
                        Product_Type__c = 'MISC Charge Items',
                        Product_SKU__c = 'SKU104',
                        Category__c = '32134',
                        ToolFlex__c = 'N',
                        Company_Code__c ='01',
                        Type_of_Misc_Charge_Item__c = 'MS',
                        Stock_Class__c = 'DEL',
                        Item_Number__c = 'PICKUP',
                        Unit_Weight_in_Pounds__c = 10
                    ),
                    //Delivery product
                    new Product2(
                        Name='2114xxx005',
                        Product_Title_Internal__c = '2114xxx004',
                        Product_Type__c = 'MISC Charge Items',
                        Product_SKU__c = 'SKU105',
                        Category__c = '32134',
                        ToolFlex__c = 'N',
                        Company_Code__c ='01',
                        Type_of_Misc_Charge_Item__c = 'MS',
                        Stock_Class__c = 'DEL',
                        Item_Number__c = 'DELIVERY',
                        Unit_Weight_in_Pounds__c = 10
                    )
                }
            );
            
            insert products;
            
            
                
            SBR_3_0_TestDataFactory.createPriceBookEntries(products);
            
            List<Asset> assets = SBR_3_0_TestDataFactory.createAssets(1, false, acct.Id, contact.Id, locations[0].Id);
            for(Integer i=0; i < assets.size(); i++){
                assets.get(i).Name = 'asset'+i; 
            }
            insert assets;
            
            Credential__c cred = SBR_3_0_TestDataFactory.createCredentials(1, false)[0];
            cred.Name = 'Mule_Token_Endpoint';
            cred.Key_Id__c = 'testKey123';
            cred.Secret__c = 'secret';
            insert cred;
        }
    }
    
    @IsTest
    static void testNewContract(){
        
        RestContext.Response = new RestResponse();
        
        Id reservationId = Schema.sObjectType.Order.getRecordTypeInfosByDeveloperName().get('Reservation_Order').getRecordTypeId();
        
        //Creating a reservation to test related reservation functionality.
        insert new Order(
        	Company_Code__c = '01',
        	Deliverymethod__c = 'Delivery',
            RecordTypeId = reservationId,
            Reservation_Order_Number__c = 'res1234',
            AccountId = [Select Id From Account]?.Id,
            Pricebook2Id = Test.getStandardPricebookId(),
            Name = 'test',
            Duration__c = 'Custom',
            Order_Discount__c = 10,
            Start_Date__c = System.Today().addDays(2),
            EffectiveDate = System.Today().addDays(2),
            Status = 'Draft'
            //This is a percent field.
            //Looks like there's a LOT of test data for discounts, where they are set to 0.1 for this field,
            //Which is actually "one tenth of a percent", and usually doesnt result in any discount at all due to rounding of 2 decimal places.
            //For 10% off, this field should be 10 or 10.0, not 0.1
        );
        
        insert new List<Invoice__c>{
            new Invoice__c(
                Total_Invoice_Amount__c = 100,
                Contract_Number__c = 1234
            ),new Invoice__c(
                Total_Invoice_Amount__c = 100,
                Contract_Number__c = 1234
            ),new Invoice__c(
                Total_Invoice_Amount__c = 100,
                Contract_Number__c = 1234
            ),new Invoice__c(
                Total_Invoice_Amount__c = 100,
                Contract_Number__c = 1234
            ),new Invoice__c(
                Total_Invoice_Amount__c = 100,
                Contract_Number__c = 1234
            )
        };
        
        Test.setMock(
            HttpCalloutMock.class,
            new SBR_3_0_CalloutMock(
                new List<SBR_3_0_CalloutMock.MockResponse>{
                    new SBR_3_0_CalloutMock.MockResponse(200,'{"access_token":"test"}'),
                    new SBR_3_0_CalloutMock.MockResponse(200,'success') // Should have the latest callout here...
                }
            )
        );
        
        RestRequest request = new RestRequest();
        
        SBR_3_0_CreateOrder.WrapOrder ordWrapper = new SBR_3_0_CreateOrder.WrapOrder();
        ordWrapper.rmAccountNumber = '1234';
        ordWrapper.branchNumber = '0720';
        ordWrapper.jobSiteId = '45678';
        //ordWrapper.jobSiteNumber = '123456';
        ordWrapper.reservationNumber = 'res1234';
        ordWrapper.contractNumber = '1234';
        ordWrapper.type = 'ContractOrder';
        ordWrapper.primarySalesRep = '12340';
        ordWrapper.secondarySalesRep = '12341';
        ordWrapper.address = new SBR_3_0_WrapAddress();
        ordWrapper.orderedBy = new SBR_3_0_ContactWrap();
        ordWrapper.orderedBy.firstName = 'Test';
        ordWrapper.orderedBy.lastName = 'Contact';
        ordWrapper.orderedBy.phone= '(800)867-5309';
        ordWrapper.orderedBy.email = 'test@testContact.com';
        ordWrapper.address.city = 'test';
        ordWrapper.address.country = 'CA';
        ordWrapper.address.state = 'ON';
        ordWrapper.address.street1 = 'test';
        ordWrapper.address.zip = 'test';
        ordWrapper.address.latitude = 0;
        ordWrapper.address.longitude = 0;
        ordWrapper.type = 'ContractOrder';
        ordWrapper.data = new Order(
        	Company_Code__c = '01',
        	Deliverymethod__c = 'Delivery'
        );
        
        for(Integer i=0; i < 100; i++){
        	SBR_3_0_CreateOrder.WrapOrderItem lineWrapper1 = new SBR_3_0_CreateOrder.WrapOrderItem();
        	lineWrapper1.productSKU = 'SKU'+i;
        	lineWrapper1.assetNumber = 'asset0';
        	lineWrapper1.orderNumber = '123456';
	        lineWrapper1.branchNumber = '1234';
    	    lineWrapper1.data = new OrderItem(
                Line_Composite_Key__c = 'line'+i,
                Reservation_Line_Number__c= 2,
                Fulfillment_Service__c= 'STANDARD',
                Delivery_Method__c= 'Delivery',
                date_time_out__c= datetime.now(),
           
                Global_Line_Number__C= i,
                Quantity= 1,
                rates_overriden__c= false,
                CommissionableYN__c= true,
                Taxable__c= true,
                Day_Rate_Source_Code__c= '0R',
                Week_Rate_Source_Code__c= 'TR',
                Month_Rate_source_code__c= 'TR',
              
                Status_Created_Qty__c= 1,
                miChg__c= 0,
                Hourly_Rate__c= 0,
                Daily_Rate__c= 0,
                Weekly_Rate__c= 0,
                Monthly_Rate__c= 0,
                Selling_price__c= 1892.00,
                Cost__c= 0,
                Hourly_Book_Rate__c= 10,
                Minimum_Book_Rate__c= 400,
                Daily_Book_Rate__c= 400,
                Weekly_Book_Rate__c= 1080,
                UnitPrice= 1892.00,
                Misc_Charges_Type__c= 'DEL',
                Misc_Charge__c= 1892.47
            );
            
            lineWrapper1.lineItemDetails = new List<SBR_3_0_CreateOrder.LineItemDetailWrapper>();
            
            
            SBR_3_0_CreateOrder.LineItemDetailWrapper lidw = new SBR_3_0_CreateOrder.LineItemDetailWrapper();
            lidw.data = new Order_Item_Detail__c(
            	Name = 'Test',
                Pickup_Ticket__c = '123',
                OMS_Order_Id__c = '1234'
            );
            lineWrapper1.lineItemDetails.add(lidw);
            
            ordWrapper.lineData.add(lineWrapper1);
        }
        
        ordWrapper.lineData.get(0).productSKU = '0000000';
        ordWrapper.lineData.get(0).data.Misc_Charges_Type__c = 'DELIVERY';
        ordWrapper.lineData.get(1).productSKU = '0000000';
        ordWrapper.lineData.get(1).data.Misc_Charges_Type__c = 'PICKUP';
        
        request.requestBody = Blob.valueOf(JSON.serialize(ordWrapper) );
        RestContext.request = request;
        
        Test.setMock(
            HttpCalloutMock.class,
            new SBR_3_0_CalloutMock(
                new List<SBR_3_0_CalloutMock.MockResponse>{
                    new SBR_3_0_CalloutMock.MockResponse(200,'{"access_token":"test"}'),
                    new SBR_3_0_CalloutMock.MockResponse(200, getMockTaxUpdate())
                }
            )
        );
        
        DateTime startTime = Datetime.now();
        boolean exceptionThrown = false;
        
        Test.startTest();
        Integer queriesBefore = Limits.getQueries();
        Integer dmlBefore = Limits.getDmlStatements();

        try{
        	SBR_3_0_API_Web_Order.createOrder();
        }catch(Exception ex){
            System.debug('Exception message: ' + ex.getMessage());
            System.debug('Exception stack trace: ' + ex.getStackTraceString());
            exceptionThrown = true;
        }
        
        System.debug('Total queries used in createOrder call: ' + (Limits.getQueries() - queriesBefore)); //NOPMD
        System.debug('Total dml used in createOrder call: ' + (Limits.getDmlStatements() - dmlBefore)); //NOPMD
		
        Test.stopTest();
        System.debug('Total time ellapsed: ' + ((Datetime.now().getTime() - startTime.getTime())));
        
        List<Exception_Log__c> exceptionLogs = [Select Id,Exception_Message__c From Exception_Log__c];
        if(!exceptionLogs.isEmpty()){
           System.assertEquals(null, exceptionLogs.get(0).Exception_Message__c, 'Encountered an exception: ' + exceptionLogs.get(0).Exception_Message__c);
        }
        
        System.assert(!exceptionThrown, 'An exception was unexpectedly thrown');
        System.assert(exceptionLogs.isEmpty(), 'Found an exception log, when none were expected');

        Order result = 
            [Select 
                Id,
                Account_Record_Type_Txt__c,
                Reservation_Order__c,
                Total_Invoiced_Amount__c,
                Email__c,
                (Select Id From OrderItems)
             From 
                Order
             Where
                RecordType.DeveloperName = 'Contract_Order'];
        
        System.assertEquals(100, result.OrderItems.size(), 'Expected 100 order items to be created');
        System.assertEquals(500, result.Total_Invoiced_Amount__c, 'Total invoiced amount did not match expected value');
        System.assertNotEquals(null, result.Reservation_Order__c, 'Reservation order was not correctly set');
        System.assertEquals('Prospect', result.Account_Record_Type_Txt__c, 'Received incorrect value for account record type text');
        System.assert(result.Email__c == 'test@testContact.com', 'Expected a valid order email address');
    }
    
    
    
    @IsTest
    static void testReservationUpdate(){
        
        RestContext.Response = new RestResponse();
        
        Id reservationId = Schema.sObjectType.Order.getRecordTypeInfosByDeveloperName().get('Reservation_Order').getRecordTypeId();
        AssociatedLocation jobSite =  [SELECT ID FROM ASSOCIATEDLOCATION];
        
        Order existing = new Order(
        	Company_Code__c = '01',
        	Deliverymethod__c = 'Delivery',
            RecordTypeId = reservationId,
            Reservation_Order_Number__c = 'res1234',
            AccountId = [Select Id From Account]?.Id,
            Pricebook2Id = Test.getStandardPricebookId(),
            Name = 'test',
            Duration__c = 'Custom',
            Order_Discount__c = 10,
            Rentalman_Quote_Id__c = '123',
            Jobsite__c = jobSite.Id,
            Start_Date__c = System.Today().addDays(2),
            EffectiveDate = System.Today().addDays(2),
            Status = 'Draft'
            //This is a percent field.
            //Looks like there's a LOT of test data for discounts, where they are set to 0.1 for this field,
            //Which is actually "one tenth of a percent", and usually doesnt result in any discount at all due to rounding of 2 decimal places.
            //For 10% off, this field should be 10 or 10.0, not 0.1
        );
        insert existing;
        
        SBQQ__Quote__c quote = new SBQQ__Quote__c(
            Account_Record_Type_Txt__c='Credit',
            Rentalman_Quote_Id__c = '01-123',
            Company_Code__c = '01'
        );
        insert quote;
        
        SBR_3_0_CreateOrder.WrapOrder ordWrapper = new SBR_3_0_CreateOrder.WrapOrder();
        ordWrapper.rmAccountNumber = '1234';
        ordWrapper.branchNumber = '0720';
        ordWrapper.reservationNumber = 'res1234';
        ordWrapper.type = 'ReservationOrder';
        ordWrapper.primarySalesRep = '12340';
        ordWrapper.secondarySalesRep = '12341';
        ordWrapper.address = new SBR_3_0_WrapAddress();
        ordWrapper.orderedBy = new SBR_3_0_ContactWrap();
        ordWrapper.orderedBy.firstName = 'Test';
        ordWrapper.orderedBy.lastName = 'Contact';
        ordWrapper.orderedBy.phone= '(800)867-5309';
        ordWrapper.orderedBy.email = 'test@testContact.com';
        ordWrapper.address.city = 'test';
        ordWrapper.address.country = 'CA';
        ordWrapper.address.state = 'ON';
        ordWrapper.address.street1 = 'test';
        ordWrapper.address.zip = 'test';
        ordWrapper.address.latitude = 0;
        ordWrapper.address.longitude = 0;
        ordWrapper.data = new Order(
        	Company_Code__c = '01',
        	Deliverymethod__c = 'Delivery',
            SBQQ__Quote__c = quote.Id
        );
        
        List<OrderItem> orderItems = new List<OrderItem>();
        Integer i=0;
        for(PriceBookEntry pbe : [Select Id,Product2Id From PricebookEntry]){
        	orderItems.add(
            	new OrderItem(
                    OrderId = existing.Id,
                    PricebookEntryId = pbe.Id,
                    Line_Composite_Key__c = 'line'+i,
                	Reservation_Line_Number__c= 2,
                	Fulfillment_Service__c= 'STANDARD',
                	Delivery_Method__c= 'Delivery',
                	Date_time_out__c= datetime.now(),
           			Global_Line_Number__C= i,
                	Quantity= 1,
                	rates_overriden__c= false,
                	CommissionableYN__c= true,
                	Taxable__c= true,
                	Day_Rate_Source_Code__c= '0R',
               	 	Week_Rate_Source_Code__c= 'TR',
                	Month_Rate_source_code__c= 'TR',
              		Status_Created_Qty__c= 1,
                	miChg__c= 1,
                	Hourly_Rate__c= 1,
                	Daily_Rate__c= 1,
                	Weekly_Rate__c= 1,
                	Monthly_Rate__c= 1,
                	Selling_price__c= 1892.00,
                	Cost__c= 0,
                	Hourly_Book_Rate__c= 10,
                	Minimum_Book_Rate__c= 400,
                	Daily_Book_Rate__c= 400,
               	 	Weekly_Book_Rate__c= 1080,
                	UnitPrice= 1892.00,
                	Misc_Charges_Type__c= 'DEL',
                	Misc_Charge__c= 1892.47
                )
            );
            
            SBR_3_0_CreateOrder.WrapOrderItem lineWrapper1 = new SBR_3_0_CreateOrder.WrapOrderItem();
        	lineWrapper1.productSKU = 'SKU'+i;
        	lineWrapper1.assetNumber = 'asset0';
        	lineWrapper1.orderNumber = '123456';
	        lineWrapper1.branchNumber = '1234';
    	    lineWrapper1.data = new OrderItem(
                Line_Composite_Key__c = 'line'+i,
                Reservation_Line_Number__c= 2,
                Fulfillment_Service__c= 'STANDARD',
                Delivery_Method__c= 'Delivery',
                date_time_out__c= datetime.now(),
                Global_Line_Number__C= i,
                Quantity=5,
                CommissionableYN__c= true,
                Taxable__c= true,
                Day_Rate_Source_Code__c= '0R',
                Week_Rate_Source_Code__c= 'TR',
                Month_Rate_source_code__c= 'TR',
                Status_Created_Qty__c= 1,
                miChg__c = 0,
                Hourly_Rate__c= 2.0,
                Daily_Rate__c = 3.0,
                Weekly_Rate__c = 5.0,
                Monthly_Rate__c = 6.0,
                Suggested_Minimum_Rate__c = 3.0,
                Suggested_Daily_Rate__c = 2.0,
                Suggested_Weekly_Rate__c = 4.0,
                Suggested_Monthly_Rate__c = 6.0,
                Rates_Overriden__c = false,
                Selling_price__c = 1892.00,
                Cost__c= 1,
                Hourly_Book_Rate__c= 10,
                Minimum_Book_Rate__c= 400,
                Daily_Book_Rate__c= 400,
                Weekly_Book_Rate__c= 1080,
                UnitPrice= 100,
                Misc_Charges_Type__c= 'DEL',
                Misc_Charge__c= 1892.47,
                Specific_Pricing_Type__c = SBR_3_0_Constants.CUSTOMER_LOADED_SPECIFIC_PRICING_TYPE
            );
            
            lineWrapper1.lineItemDetails = new List<SBR_3_0_CreateOrder.LineItemDetailWrapper>();
            
            
            SBR_3_0_CreateOrder.LineItemDetailWrapper lidw = new SBR_3_0_CreateOrder.LineItemDetailWrapper();
            lidw.data = new Order_Item_Detail__c(
            	Name = 'Test',
                Pickup_Ticket__c = '123',
                OMS_Order_Id__c = '1234'
            );
            lineWrapper1.lineItemDetails.add(lidw);
            
            ordWrapper.lineData.add(lineWrapper1);
            
            i++;
        }
        ordWrapper.lineData.get(1).productSKU = 'SKU1';
        ordWrapper.lineData.get(2).productSKU = 'SKU2';
        ordWrapper.lineData.get(3).productSKU = 'SKU6';
        //ordWrapper.lineData.get(3).data.Status_Closed_Qty__c = ordWrapper.lineData.get(3).data.Quantity;
        
        
        RestRequest request = new RestRequest();
        request.requestBody = Blob.valueOf(JSON.serialize(ordWrapper) );
        RestContext.request = request;
        
        Test.setMock(
            HttpCalloutMock.class,
            new SBR_3_0_CalloutMock(
                new List<SBR_3_0_CalloutMock.MockResponse>{
                    new SBR_3_0_CalloutMock.MockResponse(200,'{"access_token":"test"}'),
                    new SBR_3_0_CalloutMock.MockResponse(200, getMockTaxUpdate())
                }
            )
        );
        
        boolean exceptionThrown = false;
        DateTime startTime = Datetime.now();
        
        Test.startTest();
        Integer queriesBefore = Limits.getQueries();
        Integer dmlBefore = Limits.getDmlStatements();
        
        try{
        	SBR_3_0_API_Web_Order.createOrder();
        }catch(Exception ex){
            exceptionThrown = true;
        }
        System.debug('Total queries used in createOrder call: ' + (Limits.getQueries() - queriesBefore)); //NOPMD
        System.debug('Total dml used in createOrder call: ' + (Limits.getDmlStatements() - dmlBefore)); //NOPMD
		
        Test.stopTest();
        System.debug('Total time ellapsed: ' + ((Datetime.now().getTime() - startTime.getTime())));
        
        List<Exception_Log__c> exceptionLogs = [Select Id,Exception_Message__c From Exception_Log__c];
        if(!exceptionLogs.isEmpty()){
           System.assertEquals(null, exceptionLogs.get(0).Exception_Message__c, 'Encountered an exception: ' + exceptionLogs.get(0).Exception_Message__c);
        }
        
        System.assert(!exceptionThrown, 'An exception was unexpectedly thrown');
        System.assert(exceptionLogs.isEmpty(), 'Found an exception log, when none were expected');

        Order result = 
            [Select 
             	Id,
                Order_Discount__c,
                SBQQ__Quote__r.SBQQ__Status__c,
                SBQQ__Quote__r.SBQQ_Status_Reason__c,
                Name,
                Account_Record_Type_Txt__c,
                Is_Specific_Pricing_Flag__c,
             	(Select 
                     Daily_Rate_Calc_AutoFill__c,
                     Extended_Weight_Autofill__c,
                     Min_Rate__c,
                     Min_Rate_Calc_Autofill__c,
                     Weekly_Rate_Calc_Autofill__c,
                     Monthly_Rate_Calc_Autofill__c,
                     Daily_Rate2__c,
                     Daily_Rate_Calc__c,
                     Quantity,
                     Status_Closed_Qty__c,
                     Suggested_Daily_Rate__c,
                     Suggested_Daily_Rate_Calc_Autofill__c,
                     Suggested_Minimum_Rate_Calc_Autofill__c,
                     Suggested_Monthly_Rate_Calc_Autofill__c,
                     Suggested_Weekly_Rate_Calc_Autofill__c,
                     Override_Discount__c,
                     Daily_Rate__c
                 From
                 	OrderItems)
             From
                 Order];
        
        System.assertEquals('Prospect',result.Account_Record_Type_Txt__c, 'Received incorrect value for Account Record Type Text');
        System.assertEquals('Won', result.SBQQ__Quote__r?.SBQQ__Status__c, 'Quote was not converted to won');
        System.assertEquals('Converted', result.SBQQ__Quote__r?.SBQQ_Status_Reason__c, 'Quote status reason not set correctly.');
        System.assertEquals(true, result.Is_Specific_Pricing_Flag__c, 'Specific pricing flag was not set on parent order.');
        
        System.assertEquals(105, result.OrderItems.size(), 'Expected 100 order items to be created');
        for(OrderItem oi : result.OrderItems){
            //if(oi.Quantity != oi.Status_Closed_Qty__c){
                System.assertEquals(3, oi.Min_Rate__c, 'Min Rate was not set to the Weekly Rate value as expected, since the Location should have a Analysis Region Key of 921.');
                System.assertEquals(1.8, oi.Daily_Rate_Calc_AutoFill__c, 'Daily Rate Calc Autofill should match the Suggested Daily Rate, sans the discount value.');
                System.assertEquals(10, oi.Extended_Weight_AutoFill__c, 'Did not receive expected extended rate autofill value.');
                System.assertEquals(2.7, oi.Min_Rate_Calc_AutoFill__c, 'Min Rate Calc Autofill should match the Suggested Min Rate, sans the discount value.');
                System.assertEquals(3.6, oi.Weekly_Rate_Calc_AutoFill__c, 'Did not receive expected weekly rate autofill value.');
                System.assertEquals(5.4, oi.Monthly_Rate_Calc_AutoFill__c, 'Did not receive expected monthly rate autofill value.');
                System.assertEquals(2 * oi.Quantity, oi.Suggested_Daily_Rate_Calc_Autofill__c, 'Did not receive expected suggested daily rate autofill value.');
                System.assertEquals(4 * oi.Quantity, oi.Suggested_Weekly_Rate_Calc_Autofill__c, 'Did not receive expected suggested weekly rate autofill value.');
                System.assertEquals(6 * oi.Quantity, oi.Suggested_Monthly_Rate_Calc_Autofill__c, 'Did not receive expected suggested monthly rate autofill value.');
            //}
        }
    }
    
    @IsTest
    static void testContractUpdate(){
        
         RestContext.Response = new RestResponse();
        
         Id contractRecordTypeId = Schema.sObjectType.Order.getRecordTypeInfosByDeveloperName().get('Reservation_Order').getRecordTypeId();
        
         Order existing = new Order(
        	Company_Code__c = '01',
        	Deliverymethod__c = 'Delivery',
            RecordTypeId = contractRecordTypeId,
            Contract_Order_Number__c = '1234',
            AccountId = [Select Id From Account]?.Id,
            Pricebook2Id = Test.getStandardPricebookId(),
            Name = 'test',
            Duration__c = 'Custom',
            Order_Discount__c = 10,
            Rentalman_Quote_Id__c = '123',
            RPP_Amount__c = 500.55,
            Start_Date__c = System.Today().addDays(2),
            EffectiveDate = System.Today().addDays(2)
            //This is a percent field.
            //Looks like there's a LOT of test data for discounts, where they are set to 0.1 for this field,
            //Which is actually "one tenth of a percent", and usually doesnt result in any discount at all due to rounding of 2 decimal places.
            //For 10% off, this field should be 10 or 10.0, not 0.1
        );
        insert existing;
        
        SBQQ__Quote__c quote = new SBQQ__Quote__c(
            Account_Record_Type_Txt__c='Credit',
            Rentalman_Quote_Id__c = '01-123',
            Company_Code__c = '01'
        );
        insert quote;
        
        SBR_3_0_CreateOrder.WrapOrder ordWrapper = new SBR_3_0_CreateOrder.WrapOrder();
        ordWrapper.rmAccountNumber = '1234';
        ordWrapper.branchNumber = '0720';
        ordWrapper.contractNumber = '1234';
        ordWrapper.type = 'ContractOrder';
        ordWrapper.primarySalesRep = '12340';
        ordWrapper.secondarySalesRep = '12341';
        ordWrapper.address = new SBR_3_0_WrapAddress();
        ordWrapper.orderedBy = new SBR_3_0_ContactWrap();
        ordWrapper.orderedBy.firstName = 'Test';
        ordWrapper.orderedBy.lastName = 'Contact';
        ordWrapper.orderedBy.phone= '(800)867-5309';
        ordWrapper.orderedBy.email = 'test@testContact.com';
        ordWrapper.address.city = 'test';
        ordWrapper.address.country = 'CA';
        ordWrapper.address.state = 'ON';
        ordWrapper.address.street1 = 'test';
        ordWrapper.address.zip = 'test';
        ordWrapper.address.latitude = 0;
        ordWrapper.address.longitude = 0;
        
        existing.SBQQ__Quote__c = quote.id;
        ordWrapper.data = existing;
        
        
        List<OrderItem> orderItems = new List<OrderItem>();
        Integer i=0;
        
        for(PriceBookEntry pbe : [Select Id,Product2Id From PricebookEntry]){
        	orderItems.add(
            	new OrderItem(
                    OrderId = existing.Id,
                    PricebookEntryId = pbe.Id,
                    Line_Composite_Key__c = '1234-123'+i,
                	Reservation_Line_Number__c= 2,
                	Fulfillment_Service__c= 'STANDARD',
                	Delivery_Method__c= 'Delivery',
                	Date_time_out__c= datetime.now(),
                    //Global Line Number is used by the CreateOrder class to (regenerate) 
                    //the line composite key via the getCompositeKey method.
                    //The Line Composite Key = contract or reservation number + '-' + global line number.
                    Global_Line_Number__c = Integer.valueOf('123' + i),
           			Quantity= 1,
                	rates_overriden__c= false,
                	CommissionableYN__c= true,
                	Taxable__c= true,
                	Day_Rate_Source_Code__c= '0R',
               	 	Week_Rate_Source_Code__c= 'TR',
                	Month_Rate_source_code__c= 'TR',
              		Status_Created_Qty__c= 1,
                	miChg__c= 1,
                	Hourly_Rate__c= 1,
                	Daily_Rate__c= 1,
                	Weekly_Rate__c= 1,
                	Monthly_Rate__c= 1,
                	Selling_price__c= 1892.00,
                	Cost__c= 0,
                	Hourly_Book_Rate__c= 10,
                	Minimum_Book_Rate__c= 400,
                	Daily_Book_Rate__c= 400,
               	 	Weekly_Book_Rate__c= 1080,
                	UnitPrice= 1892.00,
                	Misc_Charges_Type__c= 'DEL',
                	Misc_Charge__c= 1892.47
                )
            );
            
            SBR_3_0_CreateOrder.WrapOrderItem lineWrapper1 = new SBR_3_0_CreateOrder.WrapOrderItem();
        	lineWrapper1.productSKU = 'SKU'+i;
        	lineWrapper1.assetNumber = 'asset0';
        	lineWrapper1.orderNumber = '123456';
	        lineWrapper1.branchNumber = '1234';
            lineWrapper1.data = new OrderItem(
                Line_Composite_Key__c = '1234-123'+i,
                Reservation_Line_Number__c= 2,
                Fulfillment_Service__c= 'STANDARD',
                Delivery_Method__c= 'Delivery',
                date_time_out__c= datetime.now(),
                //Global Line Number is used by the CreateOrder class to (regenerate) 
                //the line composite key via the getCompositeKey method.
                //The Line Composite Key = contract or reservation number + '-' + global line number.
                Global_Line_Number__c = Integer.valueOf('123' + i),
                Quantity=5,
                CommissionableYN__c= true,
                Taxable__c= true,
                Day_Rate_Source_Code__c= '0R',
                Week_Rate_Source_Code__c= 'TR',
                Month_Rate_source_code__c= 'TR',
                Status_Created_Qty__c= 1,
                miChg__c = 0,
                Hourly_Rate__c= 2.0,
                Daily_Rate__c = 3.0,
                Weekly_Rate__c = 5.0,
                Monthly_Rate__c = 6.0,
                Suggested_Minimum_Rate__c = 3.0,
                Suggested_Daily_Rate__c = 2.0,
                Suggested_Weekly_Rate__c = 4.0,
                Suggested_Monthly_Rate__c = 6.0,
                Rates_Overriden__c = false,
                Selling_price__c = 1892.00,
                Cost__c= 1,
                Hourly_Book_Rate__c= 10,
                Minimum_Book_Rate__c= 400,
                Daily_Book_Rate__c= 400,
                Weekly_Book_Rate__c= 1080,
                UnitPrice= 100,
                Misc_Charges_Type__c= 'DEL',
                Misc_Charge__c= 1892.47,
                Specific_Pricing_Type__c = SBR_3_0_Constants.CUSTOMER_LOADED_SPECIFIC_PRICING_TYPE
            );
            
            lineWrapper1.lineItemDetails = new List<SBR_3_0_CreateOrder.LineItemDetailWrapper>();
            
            SBR_3_0_CreateOrder.LineItemDetailWrapper lidw = new SBR_3_0_CreateOrder.LineItemDetailWrapper();
            lidw.data = new Order_Item_Detail__c(
            	Name = 'Test',
                Pickup_Ticket__c = '123',
                OMS_Order_Id__c = '1234',
                Created_Qty__c = 3
            );
            lineWrapper1.lineItemDetails.add(lidw);
            
            ordWrapper.lineData.add(lineWrapper1);
            
            i++;
        }
        
        ordWrapper.lineData.get(1).productSKU = 'SKU1';
        ordWrapper.lineData.get(2).productSKU = 'SKU2';
        ordWrapper.lineData.get(3).productSKU = 'SKU6';
        
        RestRequest request = new RestRequest();
        request.requestBody = Blob.valueOf(JSON.serialize(ordWrapper) );
        RestContext.request = request;
        
        Test.setMock(
            HttpCalloutMock.class,
            new SBR_3_0_CalloutMock(
                new List<SBR_3_0_CalloutMock.MockResponse>{
                    new SBR_3_0_CalloutMock.MockResponse(200,'{"access_token":"test"}'),
                    new SBR_3_0_CalloutMock.MockResponse(200, getMockTaxUpdate())
                }
            )
        );
        
        DateTime startTime = Datetime.now();
        
        Test.startTest();
        
        Integer queriesBefore = Limits.getQueries();
        Integer dmlBefore = Limits.getDmlStatements();
        
        SBR_3_0_API_Web_Order.createOrder();
        System.debug('Total queries used in createOrder call: ' + (Limits.getQueries() - queriesBefore)); //NOPMD
        System.debug('Total dml used in createOrder call: ' + (Limits.getDmlStatements() - dmlBefore)); //NOPMD
		Test.stopTest();
        System.debug('Total time ellapsed: ' + ((Datetime.now().getTime() - startTime.getTime())));
        
        List<Exception_Log__c> exceptionLogs = [Select Id,Exception_Message__c From Exception_Log__c];
        if(!exceptionLogs.isEmpty()){
           System.assertEquals(null, exceptionLogs.get(0).Exception_Message__c, 'Encountered an exception: ' + exceptionLogs.get(0).Exception_Message__c);
        }
        System.assert(exceptionLogs.isEmpty(), 'Found an exception log, when none were expected');

        Order result = 
            [Select 
             	Id,
                Order_Discount__c,
                SBQQ__Quote__r.SBQQ__Status__c,
                SBQQ__Quote__r.SBQQ_Status_Reason__c,
                Name,
                Account_Record_Type_Txt__c,
                Is_Specific_Pricing_Flag__c,
                RPP_Amount__c,
             	Total_Misc__c,
                Total_Rental_Amount__c,
                Total_Sales_Amount__c,
                Total_Sales_Taxes__c,
                (Select 
                     Daily_Rate_Calc_AutoFill__c,
                     Extended_Weight_Autofill__c,
                     Min_Rate__c,
                     Min_Rate_Calc_Autofill__c,
                     Weekly_Rate_Calc_Autofill__c,
                     Monthly_Rate_Calc_Autofill__c,
                     Daily_Rate2__c,
                     Daily_Rate_Calc__c,
                     Quantity,
                     Status_Created_Qty__c,
                     Status_Closed_Qty__c,
                     Suggested_Daily_Rate__c,
                     Suggested_Daily_Rate_Calc_Autofill__c,
                     Suggested_Minimum_Rate_Calc_Autofill__c,
                     Suggested_Monthly_Rate_Calc_Autofill__c,
                     Suggested_Weekly_Rate_Calc_Autofill__c,
                     Override_Discount__c,
                     Daily_Rate__c,
                     Rental_Tax__c,
                     Misc_Charges_Tax__c,
                     Sales_Tax__c
                 From
                 	OrderItems)
             From
                 Order];
        
        System.assertEquals('Prospect',result.Account_Record_Type_Txt__c, 'Received incorrect value for Account Record Type Text');
        System.assertEquals('Won', result.SBQQ__Quote__r?.SBQQ__Status__c, 'Quote was not converted to won');
        System.assertEquals('Converted', result.SBQQ__Quote__r?.SBQQ_Status_Reason__c, 'Quote status reason not set correctly.');
        System.assertEquals(true, result.Is_Specific_Pricing_Flag__c, 'Specific pricing flag was not set on parent order.');
        System.assertEquals(207.5, result.Total_Misc__c, 'Total misc did not match expeccted value');
        System.assertEquals(375.55, result.Total_Rental_Amount__c, 'Total rentals did not match expected value');
        System.assertEquals(500.55, result.RPP_Amount__c, 'RPP Amount did not match expected value');
        System.assertEquals(0, result.Total_Sales_Amount__c, 'Total sales amount did not match expected value');
        System.assertEquals(100, result.Total_Sales_Taxes__c, 'Total sales taxes did not match expected value');
        
        System.assertEquals(105, result.OrderItems.size(), 'Expected 100 order items to be created');
        for(OrderItem oi : result.OrderItems){
            System.assertEquals(3, oi.Min_Rate__c, 'Min Rate was not set to the Weekly Rate value as expected, since the Location should have a Analysis Region Key of 921.');
            System.assertEquals(1.8, oi.Daily_Rate_Calc_AutoFill__c, 'Daily Rate Calc Autofill should match the Suggested Daily Rate, sans the discount value.');
            System.assertEquals(10, oi.Extended_Weight_AutoFill__c, 'Did not receive expected extended rate autofill value.');
            System.assertEquals(2.7, oi.Min_Rate_Calc_AutoFill__c, 'Min Rate Calc Autofill should match the Suggested Min Rate, sans the discount value.');
            System.assertEquals(3.6, oi.Weekly_Rate_Calc_AutoFill__c, 'Did not receive expected weekly rate autofill value.');
            System.assertEquals(5.4, oi.Monthly_Rate_Calc_AutoFill__c, 'Did not receive expected monthly rate autofill value.');
            System.assertEquals(2 * oi.Quantity, oi.Suggested_Daily_Rate_Calc_Autofill__c, 'Did not receive expected suggested daily rate autofill value.');
            System.assertEquals(4 * oi.Quantity, oi.Suggested_Weekly_Rate_Calc_Autofill__c, 'Did not receive expected suggested weekly rate autofill value.');
            System.assertEquals(6 * oi.Quantity, oi.Suggested_Monthly_Rate_Calc_Autofill__c, 'Did not receive expected suggested monthly rate autofill value.');
            System.assertEquals(1.4, oi.Rental_Tax__c, 'Did not receive expected rental tax amount from tax calc service');
            System.assertEquals(0.8, oi.Sales_Tax__c, 'Did not receive expected sales tax amount from tax calc service');
            System.assertEquals(0.8, oi.Misc_Charges_Tax__c, 'Did not receive expected rental tax amount from tax calc service');
            //System.assertEquals(3, oi.Status_Created_Qty__c, 'Did not receive exepcted status created qty');
        }
    }
    
    @IsTest
    static void testContractUpdateWithNullTotals(){
        
         RestContext.Response = new RestResponse();
        
         Id contractRecordTypeId = Schema.sObjectType.Order.getRecordTypeInfosByDeveloperName().get('Reservation_Order').getRecordTypeId();
        
         Order existing = new Order(
        	Company_Code__c = '01',
        	Deliverymethod__c = 'Delivery',
            RecordTypeId = contractRecordTypeId,
            Contract_Order_Number__c = '1234',
            AccountId = [Select Id From Account]?.Id,
            Pricebook2Id = Test.getStandardPricebookId(),
            Name = 'test',
            Duration__c = 'Custom',
            Order_Discount__c = 10,
            Rentalman_Quote_Id__c = '123',
            RPP_Amount__c = 500.55,
            Start_Date__c = System.Today().addDays(2),
            EffectiveDate = System.Today().addDays(2)
            //This is a percent field.
            //Looks like there's a LOT of test data for discounts, where they are set to 0.1 for this field,
            //Which is actually "one tenth of a percent", and usually doesnt result in any discount at all due to rounding of 2 decimal places.
            //For 10% off, this field should be 10 or 10.0, not 0.1
        );
        insert existing;
        
        SBQQ__Quote__c quote = new SBQQ__Quote__c(
            Account_Record_Type_Txt__c='Credit',
            Rentalman_Quote_Id__c = '01-123',
            Company_Code__c = '01'
        );
        insert quote;
        
        SBR_3_0_CreateOrder.WrapOrder ordWrapper = new SBR_3_0_CreateOrder.WrapOrder();
        ordWrapper.rmAccountNumber = '1234';
        ordWrapper.branchNumber = '0720';
        ordWrapper.contractNumber = '1234';
        ordWrapper.type = 'ContractOrder';
        ordWrapper.primarySalesRep = '12340';
        ordWrapper.secondarySalesRep = '12341';
        ordWrapper.address = new SBR_3_0_WrapAddress();
        ordWrapper.orderedBy = new SBR_3_0_ContactWrap();
        ordWrapper.orderedBy.firstName = 'Test';
        ordWrapper.orderedBy.lastName = 'Contact';
        ordWrapper.orderedBy.phone= '(800)867-5309';
        ordWrapper.orderedBy.email = 'test@testContact.com';
        ordWrapper.address.city = 'test';
        ordWrapper.address.country = 'CA';
        ordWrapper.address.state = 'ON';
        ordWrapper.address.street1 = 'test';
        ordWrapper.address.zip = 'test';
        ordWrapper.address.latitude = 0;
        ordWrapper.address.longitude = 0;
        
        existing.SBQQ__Quote__c = quote.id;
        ordWrapper.data = existing;
        
        
        List<OrderItem> orderItems = new List<OrderItem>();
        Integer i=0;
        
        for(PriceBookEntry pbe : [Select Id,Product2Id From PricebookEntry]){
        	orderItems.add(
            	new OrderItem(
                    OrderId = existing.Id,
                    PricebookEntryId = pbe.Id,
                    Line_Composite_Key__c = '1234-123'+i,
                	Reservation_Line_Number__c= 2,
                	Fulfillment_Service__c= 'STANDARD',
                	Delivery_Method__c= 'Delivery',
                	Date_time_out__c= datetime.now(),
                    //Global Line Number is used by the CreateOrder class to (regenerate) 
                    //the line composite key via the getCompositeKey method.
                    //The Line Composite Key = contract or reservation number + '-' + global line number.
                    Global_Line_Number__c = Integer.valueOf('123' + i),
           			Quantity= 1,
                	rates_overriden__c= false,
                	CommissionableYN__c= true,
                	Taxable__c= true,
                	Day_Rate_Source_Code__c= '0R',
               	 	Week_Rate_Source_Code__c= 'TR',
                	Month_Rate_source_code__c= 'TR',
              		Status_Created_Qty__c= 1,
                	miChg__c= 1,
                	Hourly_Rate__c= 1,
                	Daily_Rate__c= 1,
                	Weekly_Rate__c= 1,
                	Monthly_Rate__c= 1,
                	Selling_price__c= 1892.00,
                	Cost__c= 0,
                	Hourly_Book_Rate__c= 10,
                	Minimum_Book_Rate__c= 400,
                	Daily_Book_Rate__c= 400,
               	 	Weekly_Book_Rate__c= 1080,
                	UnitPrice= 1892.00,
                	Misc_Charges_Type__c= 'DEL',
                	Misc_Charge__c= 1892.47
                )
            );
            
            SBR_3_0_CreateOrder.WrapOrderItem lineWrapper1 = new SBR_3_0_CreateOrder.WrapOrderItem();
        	lineWrapper1.productSKU = 'SKU'+i;
        	lineWrapper1.assetNumber = 'asset0';
        	lineWrapper1.orderNumber = '123456';
	        lineWrapper1.branchNumber = '1234';
            lineWrapper1.data = new OrderItem(
                Line_Composite_Key__c = '1234-123'+i,
                Reservation_Line_Number__c= 2,
                Fulfillment_Service__c= 'STANDARD',
                Delivery_Method__c= 'Delivery',
                date_time_out__c= datetime.now(),
                //Global Line Number is used by the CreateOrder class to (regenerate) 
                //the line composite key via the getCompositeKey method.
                //The Line Composite Key = contract or reservation number + '-' + global line number.
                Global_Line_Number__c = Integer.valueOf('123' + i),
                Quantity=5,
                CommissionableYN__c= true,
                Taxable__c= true,
                Day_Rate_Source_Code__c= '0R',
                Week_Rate_Source_Code__c= 'TR',
                Month_Rate_source_code__c= 'TR',
                Status_Created_Qty__c= 1,
                miChg__c = 0,
                Hourly_Rate__c= 2.0,
                Daily_Rate__c = 3.0,
                Weekly_Rate__c = 5.0,
                Monthly_Rate__c = 6.0,
                Suggested_Minimum_Rate__c = 3.0,
                Suggested_Daily_Rate__c = 2.0,
                Suggested_Weekly_Rate__c = 4.0,
                Suggested_Monthly_Rate__c = 6.0,
                Rates_Overriden__c = false,
                Selling_price__c = 1892.00,
                Cost__c= 1,
                Hourly_Book_Rate__c= 10,
                Minimum_Book_Rate__c= 400,
                Daily_Book_Rate__c= 400,
                Weekly_Book_Rate__c= 1080,
                UnitPrice= 100,
                Misc_Charges_Type__c= 'DEL',
                Misc_Charge__c= 1892.47,
                Specific_Pricing_Type__c = SBR_3_0_Constants.CUSTOMER_LOADED_SPECIFIC_PRICING_TYPE
            );
            
            lineWrapper1.lineItemDetails = new List<SBR_3_0_CreateOrder.LineItemDetailWrapper>();
            
            SBR_3_0_CreateOrder.LineItemDetailWrapper lidw = new SBR_3_0_CreateOrder.LineItemDetailWrapper();
            lidw.data = new Order_Item_Detail__c(
            	Name = 'Test',
                Pickup_Ticket__c = '123',
                OMS_Order_Id__c = '1234',
                Created_Qty__c = 3
            );
            lineWrapper1.lineItemDetails.add(lidw);
            
            ordWrapper.lineData.add(lineWrapper1);
            
            i++;
        }
        
        ordWrapper.lineData.get(1).productSKU = 'SKU1';
        ordWrapper.lineData.get(2).productSKU = 'SKU2';
        ordWrapper.lineData.get(3).productSKU = 'SKU6';
        
        RestRequest request = new RestRequest();
        request.requestBody = Blob.valueOf(JSON.serialize(ordWrapper) );
        RestContext.request = request;
        
        Test.setMock(
            HttpCalloutMock.class,
            new SBR_3_0_CalloutMock(
                new List<SBR_3_0_CalloutMock.MockResponse>{
                    new SBR_3_0_CalloutMock.MockResponse(200,'{"access_token":"test"}'),
                    new SBR_3_0_CalloutMock.MockResponse(200, getMockTaxUpdateWithNullTotals())
                }
            )
        );
        
        DateTime startTime = Datetime.now();
        
        Test.startTest();
        
        Integer queriesBefore = Limits.getQueries();
        Integer dmlBefore = Limits.getDmlStatements();
        
        SBR_3_0_API_Web_Order.createOrder();
        System.debug('Total queries used in createOrder call: ' + (Limits.getQueries() - queriesBefore)); //NOPMD
        System.debug('Total dml used in createOrder call: ' + (Limits.getDmlStatements() - dmlBefore)); //NOPMD
		Test.stopTest();
        System.debug('Total time ellapsed: ' + ((Datetime.now().getTime() - startTime.getTime())));
        
        List<Exception_Log__c> exceptionLogs = [Select Id,Exception_Message__c From Exception_Log__c];
        if(!exceptionLogs.isEmpty()){
           System.assertEquals(null, exceptionLogs.get(0).Exception_Message__c, 'Encountered an exception: ' + exceptionLogs.get(0).Exception_Message__c);
        }
        System.assert(exceptionLogs.isEmpty(), 'Found an exception log, when none were expected');

        Order result = 
            [Select 
             	Id,
                Order_Discount__c,
                SBQQ__Quote__r.SBQQ__Status__c,
                SBQQ__Quote__r.SBQQ_Status_Reason__c,
                Name,
                Account_Record_Type_Txt__c,
                Is_Specific_Pricing_Flag__c,
                RPP_Amount__c,
             	Total_Misc__c,
                Total_Rental_Amount__c,
                Total_Sales_Amount__c,
                Total_Sales_Taxes__c,
                (Select 
                     Daily_Rate_Calc_AutoFill__c,
                     Extended_Weight_Autofill__c,
                     Min_Rate__c,
                     Min_Rate_Calc_Autofill__c,
                     Weekly_Rate_Calc_Autofill__c,
                     Monthly_Rate_Calc_Autofill__c,
                     Daily_Rate2__c,
                     Daily_Rate_Calc__c,
                     Quantity,
                     Status_Created_Qty__c,
                     Status_Closed_Qty__c,
                     Suggested_Daily_Rate__c,
                     Suggested_Daily_Rate_Calc_Autofill__c,
                     Suggested_Minimum_Rate_Calc_Autofill__c,
                     Suggested_Monthly_Rate_Calc_Autofill__c,
                     Suggested_Weekly_Rate_Calc_Autofill__c,
                     Override_Discount__c,
                     Daily_Rate__c,
                     Rental_Tax__c,
                     Misc_Charges_Tax__c,
                     Sales_Tax__c
                 From
                 	OrderItems)
             From
                 Order];
        
        System.assertEquals('Prospect',result.Account_Record_Type_Txt__c, 'Received incorrect value for Account Record Type Text');
        System.assertEquals('Won', result.SBQQ__Quote__r?.SBQQ__Status__c, 'Quote was not converted to won');
        System.assertEquals('Converted', result.SBQQ__Quote__r?.SBQQ_Status_Reason__c, 'Quote status reason not set correctly.');
        System.assertEquals(true, result.Is_Specific_Pricing_Flag__c, 'Specific pricing flag was not set on parent order.');
        System.assertEquals(0, result.Total_Misc__c, 'Total misc did not match expeccted value');
        System.assertEquals(0, result.Total_Rental_Amount__c, 'Total rentals did not match expected value');
        System.assertEquals(500.55, result.RPP_Amount__c, 'RPP Amount did not match expected value');
        System.assertEquals(0, result.Total_Sales_Amount__c, 'Total sales amount did not match expected value');
        System.assertEquals(0, result.Total_Sales_Taxes__c, 'Total sales taxes did not match expected value');
        
        System.assertEquals(105, result.OrderItems.size(), 'Expected 100 order items to be created');
        for(OrderItem oi : result.OrderItems){
            System.assertEquals(3, oi.Min_Rate__c, 'Min Rate was not set to the Weekly Rate value as expected, since the Location should have a Analysis Region Key of 921.');
            System.assertEquals(1.8, oi.Daily_Rate_Calc_AutoFill__c, 'Daily Rate Calc Autofill should match the Suggested Daily Rate, sans the discount value.');
            System.assertEquals(10, oi.Extended_Weight_AutoFill__c, 'Did not receive expected extended rate autofill value.');
            System.assertEquals(2.7, oi.Min_Rate_Calc_AutoFill__c, 'Min Rate Calc Autofill should match the Suggested Min Rate, sans the discount value.');
            System.assertEquals(3.6, oi.Weekly_Rate_Calc_AutoFill__c, 'Did not receive expected weekly rate autofill value.');
            System.assertEquals(5.4, oi.Monthly_Rate_Calc_AutoFill__c, 'Did not receive expected monthly rate autofill value.');
            System.assertEquals(2 * oi.Quantity, oi.Suggested_Daily_Rate_Calc_Autofill__c, 'Did not receive expected suggested daily rate autofill value.');
            System.assertEquals(4 * oi.Quantity, oi.Suggested_Weekly_Rate_Calc_Autofill__c, 'Did not receive expected suggested weekly rate autofill value.');
            System.assertEquals(6 * oi.Quantity, oi.Suggested_Monthly_Rate_Calc_Autofill__c, 'Did not receive expected suggested monthly rate autofill value.');
            System.assertEquals(1.4, oi.Rental_Tax__c, 'Did not receive expected rental tax amount from tax calc service');
            System.assertEquals(0.8, oi.Sales_Tax__c, 'Did not receive expected sales tax amount from tax calc service');
            System.assertEquals(0.8, oi.Misc_Charges_Tax__c, 'Did not receive expected rental tax amount from tax calc service');
            //System.assertEquals(3, oi.Status_Created_Qty__c, 'Did not receive exepcted status created qty');
        }
    }
    
    @IsTest
    static void testContractUpdateAndPreventTaxCalculation(){
        
         RestContext.Response = new RestResponse();
        
         Id contractRecordTypeId = Schema.sObjectType.Order.getRecordTypeInfosByDeveloperName().get('Reservation_Order').getRecordTypeId();
        
         Order existing = new Order(
        	Company_Code__c = '01',
        	Deliverymethod__c = 'Delivery',
            RecordTypeId = contractRecordTypeId,
            Contract_Order_Number__c = '1234',
            AccountId = [Select Id From Account]?.Id,
            Pricebook2Id = Test.getStandardPricebookId(),
            Name = 'test',
            Duration__c = 'Custom',
            Order_Discount__c = 10,
            Rentalman_Quote_Id__c = '123',
            RPP_Amount__c = 500.55,
            Start_Date__c = System.Today().addDays(2),
            EffectiveDate = System.Today().addDays(2)
            //This is a percent field.
            //Looks like there's a LOT of test data for discounts, where they are set to 0.1 for this field,
            //Which is actually "one tenth of a percent", and usually doesnt result in any discount at all due to rounding of 2 decimal places.
            //For 10% off, this field should be 10 or 10.0, not 0.1
        );
        insert existing;
        
        SBQQ__Quote__c quote = new SBQQ__Quote__c(
            Account_Record_Type_Txt__c='Credit',
            Rentalman_Quote_Id__c = '01-123',
            Company_Code__c = '01'
        );
        insert quote;
        
        SBR_3_0_CreateOrder.WrapOrder ordWrapper = new SBR_3_0_CreateOrder.WrapOrder();
        ordWrapper.preventTaxCalculation = 'true';
        ordWrapper.rmAccountNumber = '1234';
        ordWrapper.branchNumber = '0720';
        ordWrapper.contractNumber = '1234';
        ordWrapper.type = 'ContractOrder';
        ordWrapper.primarySalesRep = '12340';
        ordWrapper.secondarySalesRep = '12341';
        ordWrapper.address = new SBR_3_0_WrapAddress();
        ordWrapper.orderedBy = new SBR_3_0_ContactWrap();
        ordWrapper.orderedBy.firstName = 'Test';
        ordWrapper.orderedBy.lastName = 'Contact';
        ordWrapper.orderedBy.phone= '(800)867-5309';
        ordWrapper.orderedBy.email = 'NONE@';
        ordWrapper.address.city = 'test';
        ordWrapper.address.country = 'CA';
        ordWrapper.address.state = 'ON';
        ordWrapper.address.street1 = 'test';
        ordWrapper.address.zip = 'test';
        ordWrapper.address.latitude = 0;
        ordWrapper.address.longitude = 0;
        
        existing.SBQQ__Quote__c = quote.id;
        ordWrapper.data = existing;
        
        
        List<OrderItem> orderItems = new List<OrderItem>();
        Integer i=0;
        
        for(PriceBookEntry pbe : [Select Id,Product2Id From PricebookEntry]){
        	orderItems.add(
            	new OrderItem(
                    OrderId = existing.Id,
                    PricebookEntryId = pbe.Id,
                    Line_Composite_Key__c = '1234-123'+i,
                	Reservation_Line_Number__c= 2,
                	Fulfillment_Service__c= 'STANDARD',
                	Delivery_Method__c= 'Delivery',
                	Date_time_out__c= datetime.now(),
                    //Global Line Number is used by the CreateOrder class to (regenerate) 
                    //the line composite key via the getCompositeKey method.
                    //The Line Composite Key = contract or reservation number + '-' + global line number.
                    Global_Line_Number__c = Integer.valueOf('123' + i),
           			Quantity= 1,
                	rates_overriden__c= false,
                	CommissionableYN__c= true,
                	Taxable__c= true,
                	Day_Rate_Source_Code__c= '0R',
               	 	Week_Rate_Source_Code__c= 'TR',
                	Month_Rate_source_code__c= 'TR',
              		Status_Created_Qty__c= 1,
                	miChg__c= 1,
                	Hourly_Rate__c= 1,
                	Daily_Rate__c= 1,
                	Weekly_Rate__c= 1,
                	Monthly_Rate__c= 1,
                	Selling_price__c= 1892.00,
                	Cost__c= 0,
                	Hourly_Book_Rate__c= 10,
                	Minimum_Book_Rate__c= 400,
                	Daily_Book_Rate__c= 400,
               	 	Weekly_Book_Rate__c= 1080,
                	UnitPrice= 1892.00,
                	Misc_Charges_Type__c= 'DEL',
                	Misc_Charge__c= 1892.47
                )
            );
            
            SBR_3_0_CreateOrder.WrapOrderItem lineWrapper1 = new SBR_3_0_CreateOrder.WrapOrderItem();
        	lineWrapper1.productSKU = 'SKU'+i;
        	lineWrapper1.assetNumber = 'asset0';
        	lineWrapper1.orderNumber = '123456';
	        lineWrapper1.branchNumber = '1234';
            lineWrapper1.data = new OrderItem(
                Line_Composite_Key__c = '1234-123'+i,
                Reservation_Line_Number__c= 2,
                Fulfillment_Service__c= 'STANDARD',
                Delivery_Method__c= 'Delivery',
                date_time_out__c= datetime.now(),
                //Global Line Number is used by the CreateOrder class to (regenerate) 
                //the line composite key via the getCompositeKey method.
                //The Line Composite Key = contract or reservation number + '-' + global line number.
                Global_Line_Number__c = Integer.valueOf('123' + i),
                Quantity=5,
                CommissionableYN__c= true,
                Taxable__c= true,
                Day_Rate_Source_Code__c= '0R',
                Week_Rate_Source_Code__c= 'TR',
                Month_Rate_source_code__c= 'TR',
                Status_Created_Qty__c= 1,
                miChg__c = 0,
                Hourly_Rate__c= 2.0,
                Daily_Rate__c = 3.0,
                Weekly_Rate__c = 5.0,
                Monthly_Rate__c = 6.0,
                Suggested_Minimum_Rate__c = 3.0,
                Suggested_Daily_Rate__c = 2.0,
                Suggested_Weekly_Rate__c = 4.0,
                Suggested_Monthly_Rate__c = 6.0,
                Rates_Overriden__c = false,
                Selling_price__c = 1892.00,
                Cost__c= 1,
                Hourly_Book_Rate__c= 10,
                Minimum_Book_Rate__c= 400,
                Daily_Book_Rate__c= 400,
                Weekly_Book_Rate__c= 1080,
                UnitPrice= 100,
                Misc_Charges_Type__c= 'DEL',
                Misc_Charge__c= 1892.47,
                Specific_Pricing_Type__c = SBR_3_0_Constants.CUSTOMER_LOADED_SPECIFIC_PRICING_TYPE
            );
            
            lineWrapper1.lineItemDetails = new List<SBR_3_0_CreateOrder.LineItemDetailWrapper>();
            
            SBR_3_0_CreateOrder.LineItemDetailWrapper lidw = new SBR_3_0_CreateOrder.LineItemDetailWrapper();
            lidw.data = new Order_Item_Detail__c(
            	Name = 'Test',
                Pickup_Ticket__c = '123',
                OMS_Order_Id__c = '1234'
            );
            lineWrapper1.lineItemDetails.add(lidw);
            
            ordWrapper.lineData.add(lineWrapper1);
            
            i++;
        }
        
        ordWrapper.lineData.get(1).productSKU = 'SKU1';
        ordWrapper.lineData.get(2).productSKU = 'SKU2';
        ordWrapper.lineData.get(3).productSKU = 'SKU6';
        
        RestRequest request = new RestRequest();
        request.requestBody = Blob.valueOf(JSON.serialize(ordWrapper) );
        RestContext.request = request;
        
        //Dont set any mock HTTP responses, because we are expecting none to happen in this case.
        //If there were a callout, it should throw an exception and fail this test case.
        
        Test.startTest();
        SBR_3_0_API_Web_Order.createOrder();
		Test.stopTest();
        
        List<Exception_Log__c> exceptionLogs = [Select Id,Exception_Message__c From Exception_Log__c];
        if(!exceptionLogs.isEmpty()){
           System.assertEquals(null, exceptionLogs.get(0).Exception_Message__c, 'Encountered an exception: ' + exceptionLogs.get(0).Exception_Message__c);
        }
        System.assert(exceptionLogs.isEmpty(), 'Found an exception log, when none were expected');

        Order result = 
            [Select 
             	Id,
                Order_Discount__c,
                SBQQ__Quote__r.SBQQ__Status__c,
                SBQQ__Quote__r.SBQQ_Status_Reason__c,
                Name,
                Account_Record_Type_Txt__c,
                Is_Specific_Pricing_Flag__c,
                RPP_Amount__c,
             	Total_Misc__c,
                Total_Rental_Amount__c,
                Total_Sales_Amount__c,
                Total_Sales_Taxes__c,
                Email__c,
                (Select 
                     Daily_Rate_Calc_AutoFill__c,
                     Extended_Weight_Autofill__c,
                     Min_Rate__c,
                     Min_Rate_Calc_Autofill__c,
                     Weekly_Rate_Calc_Autofill__c,
                     Monthly_Rate_Calc_Autofill__c,
                     Daily_Rate2__c,
                     Daily_Rate_Calc__c,
                     Quantity,
                     Status_Closed_Qty__c,
                     Suggested_Daily_Rate__c,
                     Suggested_Daily_Rate_Calc_Autofill__c,
                     Suggested_Minimum_Rate_Calc_Autofill__c,
                     Suggested_Monthly_Rate_Calc_Autofill__c,
                     Suggested_Weekly_Rate_Calc_Autofill__c,
                     Override_Discount__c,
                     Daily_Rate__c,
                     Rental_Tax__c,
                     Misc_Charges_Tax__c,
                     Sales_Tax__c
                 From
                 	OrderItems)
             From
                 Order];
        
        System.assertEquals('Prospect',result.Account_Record_Type_Txt__c, 'Received incorrect value for Account Record Type Text');
        System.assertEquals('Won', result.SBQQ__Quote__r?.SBQQ__Status__c, 'Quote was not converted to won');
        System.assertEquals('Converted', result.SBQQ__Quote__r?.SBQQ_Status_Reason__c, 'Quote status reason not set correctly.');
        System.assertEquals(true, result.Is_Specific_Pricing_Flag__c, 'Specific pricing flag was not set on parent order.');
        System.assertNotEquals(207.5, result.Total_Misc__c, 'Total misc did not match expeccted value');
        System.assertNotEquals(375.55, result.Total_Rental_Amount__c, 'Total rentals did not match expected value');
        System.assertEquals(500.55, result.RPP_Amount__c, 'RPP Amount did not match expected value');
        System.assertEquals(105, result.OrderItems.size(), 'Expected 100 order items to be created');
        System.assert(String.isBlank(result.Email__c), 'Expected a blank order email field');
    }
    
    @IsTest
    static void testMissingRequiredCompanyCode(){
        
        RestContext.Response = new RestResponse();
        
        SBR_3_0_CreateOrder.WrapOrder ordWrapper = new SBR_3_0_CreateOrder.WrapOrder();
        ordWrapper.rmAccountNumber = '1234';
        ordWrapper.branchNumber = '0720';
        ordWrapper.reservationNumber = 'res1234';
        ordWrapper.contractNumber = 'con1234';
        ordWrapper.type = 'ContractOrder';
        ordWrapper.primarySalesRep = '12340';
        ordWrapper.secondarySalesRep = '12341';
        ordWrapper.address = new SBR_3_0_WrapAddress();
        ordWrapper.orderedBy = new SBR_3_0_ContactWrap();
        ordWrapper.orderedBy.firstName = 'Test';
        ordWrapper.orderedBy.lastName = 'Contact';
        ordWrapper.orderedBy.phone= '(800)867-5309';
        ordWrapper.orderedBy.email = 'test@testContact.com';
        ordWrapper.address.city = 'test';
        ordWrapper.address.country = 'CA';
        ordWrapper.address.state = 'ON';
        ordWrapper.address.street1 = 'test';
        ordWrapper.address.zip = 'test';
        ordWrapper.address.latitude = 0;
        ordWrapper.address.longitude = 0;
        ordWrapper.type = 'ContractOrder';
        ordWrapper.data = new Order(
        	Deliverymethod__c = 'Delivery'
        );
        
        RestRequest request = new RestRequest();
        request.requestBody = Blob.valueOf(JSON.serialize(ordWrapper) );
        RestContext.request = request;
        Test.startTest();
        SBR_3_0_API_Web_Order.createOrder();
        Test.stopTest();
        
        Exception_Log__c exceptionLog = [Select Id,Exception_Message__c From Exception_Log__c];
        System.assert(exceptionLog?.Exception_Message__c?.startsWith(Label.CompanyCodeRequired), 'Did not receive the proper exception message for an invalid company code.');
    }
    
    @IsTest
    static void testMissingRequiredOrderType(){
        
        RestContext.Response = new RestResponse();
        
        SBR_3_0_CreateOrder.WrapOrder ordWrapper = new SBR_3_0_CreateOrder.WrapOrder();
        ordWrapper.rmAccountNumber = '1234';
        ordWrapper.branchNumber = '0720';
        ordWrapper.reservationNumber = 'res1234';
        ordWrapper.contractNumber = 'con1234';
        //ordWrapper.type = 'ContractOrder';
        ordWrapper.primarySalesRep = '12340';
        ordWrapper.secondarySalesRep = '12341';
        ordWrapper.address = new SBR_3_0_WrapAddress();
        ordWrapper.orderedBy = new SBR_3_0_ContactWrap();
        ordWrapper.orderedBy.firstName = 'Test';
        ordWrapper.orderedBy.lastName = 'Contact';
        ordWrapper.orderedBy.phone= '(800)867-5309';
        ordWrapper.orderedBy.email = 'test@testContact.com';
        ordWrapper.address.city = 'test';
        ordWrapper.address.country = 'CA';
        ordWrapper.address.state = 'ON';
        ordWrapper.address.street1 = 'test';
        ordWrapper.address.zip = 'test';
        ordWrapper.address.latitude = 0;
        ordWrapper.address.longitude = 0;
        ordWrapper.data = new Order(
        	Deliverymethod__c = 'Delivery',
            Company_Code__c = '01'
        );
        
        RestRequest request = new RestRequest();
        request.requestBody = Blob.valueOf(JSON.serialize(ordWrapper) );
        RestContext.request = request;
        Test.startTest();
        SBR_3_0_API_Web_Order.createOrder();
        Test.stopTest();
        
        Exception_Log__c exceptionLog = [Select Id,Exception_Message__c From Exception_Log__c];
        System.assert(exceptionLog?.Exception_Message__c?.startsWith(Label.OrderTypeRequired), 'Did not receive the proper exception message for a missing, but required order type.');
    }
    
    @IsTest
    static void testInvalidOrderType(){
        RestContext.Response = new RestResponse();
        
        SBR_3_0_CreateOrder.WrapOrder ordWrapper = new SBR_3_0_CreateOrder.WrapOrder();
        ordWrapper.rmAccountNumber = '1234';
        ordWrapper.branchNumber = '0720';
        ordWrapper.reservationNumber = 'res1234';
        ordWrapper.contractNumber = 'con1234';
        ordWrapper.type = 'GIBBERISH';
        ordWrapper.primarySalesRep = '12340';
        ordWrapper.secondarySalesRep = '12341';
        ordWrapper.address = new SBR_3_0_WrapAddress();
        ordWrapper.orderedBy = new SBR_3_0_ContactWrap();
        ordWrapper.orderedBy.firstName = 'Test';
        ordWrapper.orderedBy.lastName = 'Contact';
        ordWrapper.orderedBy.phone= '(800)867-5309';
        ordWrapper.orderedBy.email = 'test@testContact.com';
        ordWrapper.address.city = 'test';
        ordWrapper.address.country = 'CA';
        ordWrapper.address.state = 'ON';
        ordWrapper.address.street1 = 'test';
        ordWrapper.address.zip = 'test';
        ordWrapper.address.latitude = 0;
        ordWrapper.address.longitude = 0;
        ordWrapper.data = new Order(
        	Deliverymethod__c = 'Delivery',
            Company_Code__c = '01'
        );
        
        RestRequest request = new RestRequest();
        request.requestBody = Blob.valueOf(JSON.serialize(ordWrapper) );
        RestContext.request = request;
        
        Test.startTest();
        SBR_3_0_API_Web_Order.createOrder();
        Test.stopTest();
        
        Exception_Log__c exceptionLog = [Select Id,Exception_Message__c From Exception_Log__c];
        System.assert(exceptionLog?.Exception_Message__c?.startsWith(String.format(Label.InvalidOrderType, new List<String>{ ordWrapper.type })), 'Did not receive the proper exception message for an invalid order type.');
    }
    
     @IsTest
    static void testMissingContractNumber(){
        RestContext.Response = new RestResponse();
        
        SBR_3_0_CreateOrder.WrapOrder ordWrapper = new SBR_3_0_CreateOrder.WrapOrder();
        ordWrapper.rmAccountNumber = '1234';
        ordWrapper.branchNumber = '0720';
        ordWrapper.reservationNumber = 'res1234';
        //ordWrapper.contractNumber = 'con1234';
        ordWrapper.type = 'ContractOrder';
        ordWrapper.primarySalesRep = '12340';
        ordWrapper.secondarySalesRep = '12341';
        ordWrapper.address = new SBR_3_0_WrapAddress();
        ordWrapper.orderedBy = new SBR_3_0_ContactWrap();
        ordWrapper.orderedBy.firstName = 'Test';
        ordWrapper.orderedBy.lastName = 'Contact';
        ordWrapper.orderedBy.phone= '(800)867-5309';
        ordWrapper.orderedBy.email = 'test@testContact.com';
        ordWrapper.address.city = 'test';
        ordWrapper.address.country = 'CA';
        ordWrapper.address.state = 'ON';
        ordWrapper.address.street1 = 'test';
        ordWrapper.address.zip = 'test';
        ordWrapper.address.latitude = 0;
        ordWrapper.address.longitude = 0;
        ordWrapper.data = new Order(
        	Deliverymethod__c = 'Delivery',
            Company_Code__c = '01'
        );
        
        RestRequest request = new RestRequest();
        request.requestBody = Blob.valueOf(JSON.serialize(ordWrapper) );
        RestContext.request = request;
                
        Test.startTest();
        SBR_3_0_API_Web_Order.createOrder();
        Test.stopTest();
        
        Exception_Log__c exceptionLog = [Select Id,Exception_Message__c,RequestJSON__c From Exception_Log__c];
        System.assert(exceptionLog?.Exception_Message__c?.startsWith(Label.ContractOrResNumberRequired), 'Did not receive the proper exception message for a missing contract number.');
        System.assert(!String.isBlank(exceptionLog.RequestJSON__c), 'Payload in exception log was null or empty');
    }
    
    @IsTest
    static void testRecordLockNewOrderWithCalloutException(){
        
        RestContext.Response = new RestResponse();
        
        Id reservationId = Schema.sObjectType.Order.getRecordTypeInfosByDeveloperName().get('Reservation_Order').getRecordTypeId();
        
        //Creating a reservation to test related reservation functionality.
        insert new Order(
        	Company_Code__c = '01',
        	Deliverymethod__c = 'Delivery',
            RecordTypeId = reservationId,
            Reservation_Order_Number__c = 'res1234',
            AccountId = [Select Id From Account]?.Id,
            Pricebook2Id = Test.getStandardPricebookId(),
            Name = 'test',
            Duration__c = 'Custom',
            Order_Discount__c = 10,
            Start_Date__c = System.Today().addDays(2),
            EffectiveDate = System.Today().addDays(2),
            Status = 'Draft'
            //This is a percent field.
            //Looks like there's a LOT of test data for discounts, where they are set to 0.1 for this field,
            //Which is actually "one tenth of a percent", and usually doesnt result in any discount at all due to rounding of 2 decimal places.
            //For 10% off, this field should be 10 or 10.0, not 0.1
        );
        
        Test.setMock(
            HttpCalloutMock.class,
            new SBR_3_0_CalloutMock(
                new List<SBR_3_0_CalloutMock.MockResponse>{
                    new SBR_3_0_CalloutMock.MockResponse(200,'{"access_token":"test"}'),
                    new SBR_3_0_CalloutMock.MockResponse(200,'success') // Should have the latest callout here...
                }
            )
        );
        
        RestRequest request = new RestRequest();
        
        SBR_3_0_CreateOrder.WrapOrder ordWrapper = new SBR_3_0_CreateOrder.WrapOrder();
        ordWrapper.rmAccountNumber = '1234';
        ordWrapper.branchNumber = '0720';
        //ordWrapper.jobSiteId = '12345';
        //ordWrapper.jobSiteNumber = '123456';
        ordWrapper.reservationNumber = 'res1234';
        ordWrapper.contractNumber = '1234';
        ordWrapper.type = 'ContractOrder';
        ordWrapper.primarySalesRep = '12340';
        ordWrapper.secondarySalesRep = '12341';
        ordWrapper.address = new SBR_3_0_WrapAddress();
        ordWrapper.orderedBy = new SBR_3_0_ContactWrap();
        ordWrapper.orderedBy.firstName = 'Test';
        ordWrapper.orderedBy.lastName = 'Contact';
        ordWrapper.orderedBy.phone= '(800)867-5309';
        ordWrapper.orderedBy.email = 'test@testContact.com';
        ordWrapper.address.city = 'test';
        ordWrapper.address.country = 'CA';
        ordWrapper.address.state = 'ON';
        ordWrapper.address.street1 = 'test';
        ordWrapper.address.zip = 'test';
        ordWrapper.address.latitude = 0;
        ordWrapper.address.longitude = 0;
        ordWrapper.type = 'ContractOrder';
        ordWrapper.data = new Order(
        	Company_Code__c = '01',
        	Deliverymethod__c = 'Delivery'
        );
        
        for(Integer i=0; i < 100; i++){
        	SBR_3_0_CreateOrder.WrapOrderItem lineWrapper1 = new SBR_3_0_CreateOrder.WrapOrderItem();
        	lineWrapper1.productSKU = 'SKU'+i;
        	lineWrapper1.assetNumber = 'asset0';
        	lineWrapper1.orderNumber = '123456';
	        lineWrapper1.branchNumber = '1234';
    	    lineWrapper1.data = new OrderItem(
                Line_Composite_Key__c = 'line'+i,
                Reservation_Line_Number__c= 2,
                Fulfillment_Service__c= 'STANDARD',
                Delivery_Method__c= 'Delivery',
                date_time_out__c= datetime.now(),
           
                Global_Line_Number__C= i,
                Quantity= 1,
                rates_overriden__c= false,
                CommissionableYN__c= true,
                Taxable__c= true,
                Day_Rate_Source_Code__c= '0R',
                Week_Rate_Source_Code__c= 'TR',
                Month_Rate_source_code__c= 'TR',
              
                Status_Created_Qty__c= 1,
                miChg__c= 0,
                Hourly_Rate__c= 0,
                Daily_Rate__c= 0,
                Weekly_Rate__c= 0,
                Monthly_Rate__c= 0,
                Selling_price__c= 1892.00,
                Cost__c= 0,
                Hourly_Book_Rate__c= 10,
                Minimum_Book_Rate__c= 400,
                Daily_Book_Rate__c= 400,
                Weekly_Book_Rate__c= 1080,
                UnitPrice= 1892.00,
                Misc_Charges_Type__c= 'DEL',
                Misc_Charge__c= 1892.47
            );
            
            lineWrapper1.lineItemDetails = new List<SBR_3_0_CreateOrder.LineItemDetailWrapper>();
            
            
            SBR_3_0_CreateOrder.LineItemDetailWrapper lidw = new SBR_3_0_CreateOrder.LineItemDetailWrapper();
            lidw.data = new Order_Item_Detail__c(
            	Name = 'Test',
                Pickup_Ticket__c = '123',
                OMS_Order_Id__c = '1234'
            );
            lineWrapper1.lineItemDetails.add(lidw);
            
            ordWrapper.lineData.add(lineWrapper1);
        }
        
        ordWrapper.lineData.get(0).productSKU = '0000000';
        ordWrapper.lineData.get(0).data.Misc_Charges_Type__c = 'DELIVERY';
        ordWrapper.lineData.get(1).productSKU = '0000000';
        ordWrapper.lineData.get(1).data.Misc_Charges_Type__c = 'PICKUP';
        
        request.requestBody = Blob.valueOf(JSON.serialize(ordWrapper) );
        RestContext.request = request;
        
        Test.setMock(
            HttpCalloutMock.class,
            new SBR_3_0_CalloutMock(
                new List<SBR_3_0_CalloutMock.MockResponse>{
                    new SBR_3_0_CalloutMock.MockResponse(200,'{"access_token":"test"}'),
                    new SBR_3_0_CalloutMock.MockResponse(400, '{"error":"error"}')
                }
            )
        );
        
        Test.startTest();
        SBR_3_0_API_Web_Order.createOrder();
        Test.stopTest();
        
        Exception_Log__c exLog = [Select Id,Related_To_Number__c,RequestJSON__c From Exception_Log__c Limit 1];
        System.assertNotEquals(null, exLog.Related_To_Number__c, 'Related Id was not set correctly in the exception log');
        System.assertNotEquals(null, exLog.RequestJSON__c, 'Request JSON was not set correctly in the exception log');
        
        Order result = 
            [Select 
                Id,
                Account_Record_Type_Txt__c,
                Reservation_Order__c,
                Total_Invoiced_Amount__c,
                (Select Id From OrderItems)
             From 
                Order
             Where
                RecordType.DeveloperName = 'Contract_Order'];
        
        System.assertEquals(100, result.OrderItems.size(), 'Expected 100 order items to be created');
        
    }
    
    private static String getMockTaxUpdate(){
        SBR_3_0_API_Contract_OpenOrderTaxUpdate.WrapOrderResponse mockResponse = new SBR_3_0_API_Contract_OpenOrderTaxUpdate.WrapOrderResponse();
        mockResponse.companyId = '01';
        mockResponse.contractNumber = '1234';
        mockResponse.sequenceNumber = '0';
        mockResponse.type = 'ContractOrder';
        mockResponse.channel = 'SLSFRC';
        mockResponse.contractStartDateTime = Datetime.now().format();
        mockResponse.contractReturnDateTime = Datetime.now().addDays(30).format();
        mockResponse.numberofRentalDays = '30';
        mockResponse.numberOfRentalHours = '720';
        mockResponse.isDeliveryAndPickupCharge = 'true';
        mockResponse.isRPPCharge = 'false';
        mockResponse.fulfillmentStatus = 'N';
        mockResponse.stagingStatus = 'N';
        mockResponse.customerOnSite = 'N';
        
        mockResponse.totals = new SBR_3_0_API_Contract_OpenOrderTaxUpdate.WrapTotals();
        mockResponse.totals.fuel = '2.5';
        mockResponse.totals.environmental = '3.5';
        mockResponse.totals.deliveryAndPickup = '200';
        mockResponse.totals.misc = '1.5';
        mockResponse.totals.rentals = '375.55';
        mockResponse.totals.tax = '100.00';
        
        for(Integer i=0; i < 105; i++){
            SBR_3_0_API_Contract_OpenOrderTaxUpdate.WrapOrderItem prodWrapper = new SBR_3_0_API_Contract_OpenOrderTaxUpdate.WrapOrderItem();
            prodWrapper.rentalCost = '380';
            prodWrapper.lineNumber = '123'+i;
            prodWrapper.rentalTax = '1.4';
            mockResponse.products.add(prodWrapper);
            
            SBR_3_0_API_Contract_OpenOrderTaxUpdate.WrapOrderItem salesWrapper = new SBR_3_0_API_Contract_OpenOrderTaxUpdate.WrapOrderItem();
            salesWrapper.cost = '380';
            salesWrapper.salesTax = '0.8';
            salesWrapper.lineNumber = '123'+i;
            mockResponse.salesItems.add(salesWrapper);
            
            SBR_3_0_API_Contract_OpenOrderTaxUpdate.WrapOrderItem miscWrapper = new SBR_3_0_API_Contract_OpenOrderTaxUpdate.WrapOrderItem();
            miscWrapper.cost = '380';
            miscWrapper.tax = '0.8';
            miscWrapper.lineNumber = '123'+i;
            mockResponse.miscItems.add(miscWrapper);
        }

        return JSON.serialize(mockResponse, true);
    }
    
    private static String getMockTaxUpdateWithNullTotals(){
        SBR_3_0_API_Contract_OpenOrderTaxUpdate.WrapOrderResponse mockResponse = new SBR_3_0_API_Contract_OpenOrderTaxUpdate.WrapOrderResponse();
        mockResponse.companyId = '01';
        mockResponse.contractNumber = '1234';
        mockResponse.sequenceNumber = '0';
        mockResponse.type = 'ContractOrder';
        mockResponse.channel = 'SLSFRC';
        mockResponse.contractStartDateTime = Datetime.now().format();
        mockResponse.contractReturnDateTime = Datetime.now().addDays(30).format();
        mockResponse.numberofRentalDays = '30';
        mockResponse.numberOfRentalHours = '720';
        mockResponse.isDeliveryAndPickupCharge = 'true';
        mockResponse.isRPPCharge = 'false';
        mockResponse.fulfillmentStatus = 'N';
        mockResponse.stagingStatus = 'N';
        mockResponse.customerOnSite = 'N';
        
        mockResponse.totals = null;
        
        for(Integer i=0; i < 105; i++){
            SBR_3_0_API_Contract_OpenOrderTaxUpdate.WrapOrderItem prodWrapper = new SBR_3_0_API_Contract_OpenOrderTaxUpdate.WrapOrderItem();
            prodWrapper.rentalCost = '380';
            prodWrapper.lineNumber = '123'+i;
            prodWrapper.rentalTax = '1.4';
            mockResponse.products.add(prodWrapper);
            
            SBR_3_0_API_Contract_OpenOrderTaxUpdate.WrapOrderItem salesWrapper = new SBR_3_0_API_Contract_OpenOrderTaxUpdate.WrapOrderItem();
            salesWrapper.cost = '380';
            salesWrapper.salesTax = '0.8';
            salesWrapper.lineNumber = '123'+i;
            mockResponse.salesItems.add(salesWrapper);
            
            SBR_3_0_API_Contract_OpenOrderTaxUpdate.WrapOrderItem miscWrapper = new SBR_3_0_API_Contract_OpenOrderTaxUpdate.WrapOrderItem();
            miscWrapper.cost = '380';
            miscWrapper.tax = '0.8';
            miscWrapper.lineNumber = '123'+i;
            mockResponse.miscItems.add(miscWrapper);
        }

        return JSON.serialize(mockResponse, true);
    }
    
    /**
    * @description Test for order with blank account
    * @author Shreenivas Adapur | 03-21-2024 
    **/
    @IsTest
    static void testMissingAccountNumber(){
        
        RestContext.Response = new RestResponse();
        
        SBR_3_0_CreateOrder.WrapOrder ordWrapper = new SBR_3_0_CreateOrder.WrapOrder();
        ordWrapper.rmAccountNumber = '2341';
        ordWrapper.branchNumber = '0720';
        ordWrapper.reservationNumber = 'res1234';
        ordWrapper.contractNumber = 'con1234';
        ordWrapper.type = 'ContractOrder';
        ordWrapper.primarySalesRep = '12340';
        ordWrapper.secondarySalesRep = '12341';
        ordWrapper.address = new SBR_3_0_WrapAddress();
        ordWrapper.orderedBy = new SBR_3_0_ContactWrap();
        ordWrapper.orderedBy.firstName = 'Test';
        ordWrapper.orderedBy.lastName = 'Contact';
        ordWrapper.orderedBy.phone= '(800)867-5309';
        ordWrapper.orderedBy.email = 'test@testContact.com';
        ordWrapper.address.city = 'test';
        ordWrapper.address.country = 'CA';
        ordWrapper.address.state = 'ON';
        ordWrapper.address.street1 = 'test';
        ordWrapper.address.zip = 'test';
        ordWrapper.address.latitude = 0;
        ordWrapper.address.longitude = 0;
        ordWrapper.data = new Order(
            Deliverymethod__c = 'Delivery',
            Company_Code__c = '01'
        );
        
        RestRequest request = new RestRequest();
        request.requestBody = Blob.valueOf(JSON.serialize(ordWrapper) );
        RestContext.request = request;
                
        Test.startTest();
        SBR_3_0_API_Web_Order.createOrder();
        Test.stopTest();
        
        Exception_Log__c exceptionLog = [Select Id,Exception_Message__c,RequestJSON__c From Exception_Log__c];
        Assert.isTrue(exceptionLog?.Exception_Message__c?.startsWith('Related Account not found!'), 'Did not receive the proper exception message for a missing Related Account.');
        Assert.isTrue(!String.isBlank(exceptionLog.RequestJSON__c), 'Payload in exception log was null or empty');
    }    
       
    /**
    * @description Test for order with invalid jobsite id

    * @author Shreenivas Adapur | 03-21-2024 
    **/
    @IsTest
    static void testNewContractWithInvalidJobSite(){
        
        RestContext.Response = new RestResponse();
        
        Id reservationId = Schema.sObjectType.Order.getRecordTypeInfosByDeveloperName().get('Reservation_Order').getRecordTypeId();
        
        //Creating a reservation to test related reservation functionality.
        insert new Order(
        	Company_Code__c = '01',
        	Deliverymethod__c = 'Delivery',
            RecordTypeId = reservationId,
            Reservation_Order_Number__c = 'res1234',
            AccountId = [Select Id From Account]?.Id,
            Pricebook2Id = Test.getStandardPricebookId(),
            Name = 'test',
            Duration__c = 'Custom',
            Order_Discount__c = 10,
            Start_Date__c = System.Today().addDays(2),
            EffectiveDate = System.Today().addDays(2),
            Status = 'Draft'
        );
        
       
        Test.setMock(
            HttpCalloutMock.class,
            new SBR_3_0_CalloutMock(
                new List<SBR_3_0_CalloutMock.MockResponse>{
                    new SBR_3_0_CalloutMock.MockResponse(200,'{"access_token":"test"}'),
                    new SBR_3_0_CalloutMock.MockResponse(200,'success') // Should have the latest callout here...
                }
            )
        );
        
        RestRequest request = new RestRequest();
        
        SBR_3_0_CreateOrder.WrapOrder ordWrapper = new SBR_3_0_CreateOrder.WrapOrder();
        ordWrapper.rmAccountNumber = '1234';
        ordWrapper.branchNumber = '0720';
        ordWrapper.jobSiteId = '12345';
        ordWrapper.jobNumber = '123456';
        ordWrapper.reservationNumber = 'res1234';
        ordWrapper.contractNumber = '1234';
        ordWrapper.type = 'ContractOrder';
        ordWrapper.primarySalesRep = '12340';
        ordWrapper.secondarySalesRep = '12341';
        ordWrapper.address = new SBR_3_0_WrapAddress();
        ordWrapper.orderedBy = new SBR_3_0_ContactWrap();
        ordWrapper.orderedBy.firstName = 'Test';
        ordWrapper.orderedBy.lastName = 'Contact';
        ordWrapper.orderedBy.phone= '(800)867-5309';
        ordWrapper.orderedBy.email = 'test@testContact.com';
        ordWrapper.address.city = 'test';
        ordWrapper.address.country = 'CA';
        ordWrapper.address.state = 'ON';
        ordWrapper.address.street1 = 'test';
        ordWrapper.address.zip = 'test';
        ordWrapper.address.latitude = 0;
        ordWrapper.address.longitude = 0;
        ordWrapper.type = 'ContractOrder';
        ordWrapper.data = new Order(
        	Company_Code__c = '01',
        	Deliverymethod__c = 'Delivery'
        );
        
        request.requestBody = Blob.valueOf(JSON.serialize(ordWrapper) );
        RestContext.request = request;
        
        Test.setMock(
            HttpCalloutMock.class,
            new SBR_3_0_CalloutMock(
                new List<SBR_3_0_CalloutMock.MockResponse>{
                    new SBR_3_0_CalloutMock.MockResponse(200,'{"access_token":"test"}'),
                    new SBR_3_0_CalloutMock.MockResponse(200, getMockTaxUpdate())
                }
            )
        );
        
        DateTime startTime = Datetime.now();
        boolean exceptionThrown = false;
        
        Test.startTest();
        Integer queriesBefore = Limits.getQueries();
        Integer dmlBefore = Limits.getDmlStatements();

        try{
        	SBR_3_0_API_Web_Order.createOrder();
        }catch(Exception ex){
            System.debug('Exception message: ' + ex.getMessage());
            System.debug('Exception stack trace: ' + ex.getStackTraceString());
            exceptionThrown = true;
        }
        
        System.debug('Total queries used in createOrder call: ' + (Limits.getQueries() - queriesBefore)); //NOPMD
        System.debug('Total dml used in createOrder call: ' + (Limits.getDmlStatements() - dmlBefore)); //NOPMD
		
        Test.stopTest();
        System.debug('Total time ellapsed: ' + ((Datetime.now().getTime() - startTime.getTime())));
        
        List<Exception_Log__c> exceptionLogs = [Select Id,Exception_Message__c From Exception_Log__c];
        if(!exceptionLogs.isEmpty()){
            Assert.isTrue(exceptionLogs[0]?.Exception_Message__c?.startsWith('Jobsite Id'), 'Did not receive the proper exception message for a missing JobSite.');
        }
    }
    
    //Test for order with blank branch
    
    //Test for order with order items, but without assets
    
    /**
    * @description Test for existing order with order items, with order items that should be deleted.
    * @author Shreenivas Adapur | 03-21-2024 
    **/
    @IsTest
    static void testReservationUpdateToDeleteLineItems(){
        
        RestContext.Response = new RestResponse();
        
        Id reservationId = Schema.sObjectType.Order.getRecordTypeInfosByDeveloperName().get('Reservation_Order').getRecordTypeId();
        AssociatedLocation jobSite =  [SELECT ID FROM ASSOCIATEDLOCATION];
        
         Order existing = new Order(
        	Company_Code__c = '01',
        	Deliverymethod__c = 'Delivery',
            RecordTypeId = reservationId,
            Reservation_Order_Number__c = 'res1234',
            AccountId = [Select Id From Account]?.Id,
            Pricebook2Id = Test.getStandardPricebookId(),
            Name = 'test',
            Duration__c = 'Custom',
            Order_Discount__c = 10,
            Rentalman_Quote_Id__c = '123',
            Jobsite__c = jobSite.Id,
            Start_Date__c = System.Today().addDays(2),
            EffectiveDate = System.Today().addDays(2),
            Status = 'Draft'
            //This is a percent field.
            //Looks like there's a LOT of test data for discounts, where they are set to 0.1 for this field,
            //Which is actually "one tenth of a percent", and usually doesnt result in any discount at all due to rounding of 2 decimal places.
            //For 10% off, this field should be 10 or 10.0, not 0.1
        );
        insert existing;
        
        SBQQ__Quote__c quote = new SBQQ__Quote__c(
            Account_Record_Type_Txt__c='Credit',
            Rentalman_Quote_Id__c = '01-123',
            Company_Code__c = '01'
        );
        insert quote;
        
        SBR_3_0_CreateOrder.WrapOrder ordWrapper = new SBR_3_0_CreateOrder.WrapOrder();
        ordWrapper.rmAccountNumber = '1234';
        ordWrapper.branchNumber = '0720';
        ordWrapper.reservationNumber = 'res1234';
        ordWrapper.type = 'ReservationOrder';
        ordWrapper.primarySalesRep = '12340';
        ordWrapper.secondarySalesRep = '12341';
        ordWrapper.address = new SBR_3_0_WrapAddress();
        ordWrapper.orderedBy = new SBR_3_0_ContactWrap();
        ordWrapper.orderedBy.firstName = 'Test';
        ordWrapper.orderedBy.lastName = 'Contact';
        ordWrapper.orderedBy.phone= '(800)867-5309';
        ordWrapper.orderedBy.email = 'test@testContact.com';
        ordWrapper.address.city = 'test';
        ordWrapper.address.country = 'CA';
        ordWrapper.address.state = 'ON';
        ordWrapper.address.street1 = 'test';
        ordWrapper.address.zip = 'test';
        ordWrapper.address.latitude = 0;
        ordWrapper.address.longitude = 0;
        ordWrapper.data = new Order(
        	Company_Code__c = '01',
        	Deliverymethod__c = 'Delivery',
            SBQQ__Quote__c = quote.Id
        );
        
        List<OrderItem> orderItems = new List<OrderItem>();
        Integer i=0;
        for(PriceBookEntry pbe : [Select Id,Product2Id From PricebookEntry]){
        	orderItems.add(
            	new OrderItem(
                    OrderId = existing.Id,
                    PricebookEntryId = pbe.Id,
                    Line_Composite_Key__c = 'line'+i,
                	Reservation_Line_Number__c= 2,
                	Fulfillment_Service__c= 'STANDARD',
                	Delivery_Method__c= 'Delivery',
                	Date_time_out__c= datetime.now(),
           			Global_Line_Number__C= i,
                	Quantity= 1,
                	rates_overriden__c= false,
                	CommissionableYN__c= true,
                	Taxable__c= true,
                	Day_Rate_Source_Code__c= '0R',
               	 	Week_Rate_Source_Code__c= 'TR',
                	Month_Rate_source_code__c= 'TR',
              		Status_Created_Qty__c= 1,
                	miChg__c= 1,
                	Hourly_Rate__c= 1,
                	Daily_Rate__c= 1,
                	Weekly_Rate__c= 1,
                	Monthly_Rate__c= 1,
                	Selling_price__c= 1892.00,
                	Cost__c= 0,
                	Hourly_Book_Rate__c= 10,
                	Minimum_Book_Rate__c= 400,
                	Daily_Book_Rate__c= 400,
               	 	Weekly_Book_Rate__c= 1080,
                	UnitPrice= 1892.00,
                	Misc_Charges_Type__c= 'DEL',
                	Misc_Charge__c= 1892.47
                )
            );
            
            SBR_3_0_CreateOrder.WrapOrderItem lineWrapper1 = new SBR_3_0_CreateOrder.WrapOrderItem();
        	lineWrapper1.productSKU = 'SKU'+i;
        	lineWrapper1.assetNumber = 'asset0';
        	lineWrapper1.orderNumber = '123456';
	        lineWrapper1.branchNumber = '1234';
    	    lineWrapper1.data = new OrderItem(
                Line_Composite_Key__c = 'line'+i,
                Reservation_Line_Number__c= 2,
                Fulfillment_Service__c= 'STANDARD',
                Delivery_Method__c= 'Delivery',
                date_time_out__c= datetime.now(),
                Global_Line_Number__C= i,
                Quantity=5,
                CommissionableYN__c= true,
                Taxable__c= true,
                Day_Rate_Source_Code__c= '0R',
                Week_Rate_Source_Code__c= 'TR',
                Month_Rate_source_code__c= 'TR',
                Status_Created_Qty__c= 1,
                miChg__c = 0,
                Hourly_Rate__c= 2.0,
                Daily_Rate__c = 3.0,
                Weekly_Rate__c = 5.0,
                Monthly_Rate__c = 6.0,
                Suggested_Minimum_Rate__c = 3.0,
                Suggested_Daily_Rate__c = 2.0,
                Suggested_Weekly_Rate__c = 4.0,
                Suggested_Monthly_Rate__c = 6.0,
                Rates_Overriden__c = false,
                Selling_price__c = 1892.00,
                Cost__c= 1,
                Hourly_Book_Rate__c= 10,
                Minimum_Book_Rate__c= 400,
                Daily_Book_Rate__c= 400,
                Weekly_Book_Rate__c= 1080,
                UnitPrice= 100,
                Misc_Charges_Type__c= 'DEL',
                Misc_Charge__c= 1892.47,
                Specific_Pricing_Type__c = SBR_3_0_Constants.CUSTOMER_LOADED_SPECIFIC_PRICING_TYPE,
                PricebookEntryId =  '01uxx0000004C92'
                
            );
            
            lineWrapper1.lineItemDetails = new List<SBR_3_0_CreateOrder.LineItemDetailWrapper>();
            
            
            SBR_3_0_CreateOrder.LineItemDetailWrapper lidw = new SBR_3_0_CreateOrder.LineItemDetailWrapper();
            lidw.data = new Order_Item_Detail__c(
            	Name = 'Test',
                Pickup_Ticket__c = '123',
                OMS_Order_Id__c = '1234'
            );
            lineWrapper1.lineItemDetails.add(lidw);
            
            ordWrapper.lineData.add(lineWrapper1);
            
            i++;
        }
        insert orderItems;
        ordWrapper.lineData.get(1).productSKU = 'SKU1';
        ordWrapper.lineData.get(2).productSKU = 'SKU2';
        ordWrapper.lineData.get(3).productSKU = 'SKU6';
        //ordWrapper.lineData.get(3).data.Status_Closed_Qty__c = ordWrapper.lineData.get(3).data.Quantity;
        
        
        RestRequest request = new RestRequest();
        request.requestBody = Blob.valueOf(JSON.serialize(ordWrapper) );
        RestContext.request = request;
        
        Test.setMock(
            HttpCalloutMock.class,
            new SBR_3_0_CalloutMock(
                new List<SBR_3_0_CalloutMock.MockResponse>{
                    new SBR_3_0_CalloutMock.MockResponse(200,'{"access_token":"test"}'),
                    new SBR_3_0_CalloutMock.MockResponse(200, getMockTaxUpdate())
                }
            )
        );
        
        boolean exceptionThrown = false;
        DateTime startTime = Datetime.now();
        
        Test.startTest();
        Integer queriesBefore = Limits.getQueries();
        Integer dmlBefore = Limits.getDmlStatements();
        
        try{
        	SBR_3_0_API_Web_Order.createOrder();
        }catch(Exception ex){
            exceptionThrown = true;
        }
        System.debug('Total queries used in createOrder call: ' + (Limits.getQueries() - queriesBefore)); //NOPMD
        System.debug('Total dml used in createOrder call: ' + (Limits.getDmlStatements() - dmlBefore)); //NOPMD
		
        Test.stopTest();
        System.debug('Total time ellapsed: ' + ((Datetime.now().getTime() - startTime.getTime())));
        
        List<Exception_Log__c> exceptionLogs = [Select Id,Exception_Message__c From Exception_Log__c];
        if(!exceptionLogs.isEmpty()){
           System.assertEquals(null, exceptionLogs.get(0).Exception_Message__c, 'Encountered an exception: ' + exceptionLogs.get(0).Exception_Message__c);
        }
        
        System.assert(!exceptionThrown, 'An exception was unexpectedly thrown');
        System.assert(exceptionLogs.isEmpty(), 'Found an exception log, when none were expected');

        Order result = 
            [Select 
             	Id,
                Order_Discount__c,
                SBQQ__Quote__r.SBQQ__Status__c,
                SBQQ__Quote__r.SBQQ_Status_Reason__c,
                Name,
                Account_Record_Type_Txt__c,
                Is_Specific_Pricing_Flag__c,
             	(Select 
                     Daily_Rate_Calc_AutoFill__c,
                     Extended_Weight_Autofill__c,
                     Min_Rate__c,
                     Min_Rate_Calc_Autofill__c,
                     Weekly_Rate_Calc_Autofill__c,
                     Monthly_Rate_Calc_Autofill__c,
                     Daily_Rate2__c,
                     Daily_Rate_Calc__c,
                     Quantity,
                     Status_Closed_Qty__c,
                     Suggested_Daily_Rate__c,
                     Suggested_Daily_Rate_Calc_Autofill__c,
                     Suggested_Minimum_Rate_Calc_Autofill__c,
                     Suggested_Monthly_Rate_Calc_Autofill__c,
                     Suggested_Weekly_Rate_Calc_Autofill__c,
                     Override_Discount__c,
                     Daily_Rate__c
                 From
                 	OrderItems)
             From
                 Order];
    }
    
    /**
    * @description Test for existing order with order items, with order items that should be deleted.
    * @author Shreenivas Adapur | 03-21-2024 
    **/
    @IsTest
    static void testSalesOrder(){
        
        RestContext.Response = new RestResponse();
        
        Id salesRtId = Schema.sObjectType.Order.getRecordTypeInfosByDeveloperName().get('Sales_Order').getRecordTypeId();
        AssociatedLocation jobSite =  [SELECT ID FROM ASSOCIATEDLOCATION];
        
         Order existing = new Order(
        	Company_Code__c = '01',
        	Deliverymethod__c = SBR_3_0_Constants.FULFILLMENT_TYPE_PICKUP,
            RecordTypeId = salesRtId,
            Contract_Order_Number__c = 'con1234',
            Reservation_Order_Number__c = 'res1234',
            AccountId = [Select Id From Account]?.Id,
            Pricebook2Id = Test.getStandardPricebookId(),
            Name = 'test',
            Duration__c = 'Custom',
            Order_Discount__c = 10,
            Rentalman_Quote_Id__c = '123',
            Jobsite__c = jobSite.Id,
            Start_Date__c = System.Today().addDays(2),
            EffectiveDate = System.Today().addDays(2),
            Status = 'Draft'
        );
        insert existing;
        
        SBQQ__Quote__c quote = new SBQQ__Quote__c(
            Account_Record_Type_Txt__c='Credit',
            Rentalman_Quote_Id__c = '01-123',
            Company_Code__c = '01'
        );
        insert quote;
        
        SBR_3_0_CreateOrder.WrapOrder ordWrapper = new SBR_3_0_CreateOrder.WrapOrder();
        ordWrapper.rmAccountNumber = '1234';
        ordWrapper.branchNumber = '0720';
        //ordWrapper.reservationNumber = 'res1234';
        ordWrapper.type = 'SalesOrder';
        ordWrapper.contractNumber = 'con1234';
        ordWrapper.primarySalesRep = '12340';
        ordWrapper.secondarySalesRep = '12341';
        ordWrapper.address = new SBR_3_0_WrapAddress();
        ordWrapper.orderedBy = new SBR_3_0_ContactWrap();
        ordWrapper.orderedBy.firstName = 'Test';
        ordWrapper.orderedBy.lastName = 'Contact';
        ordWrapper.orderedBy.phone= '(800)867-5309';
        ordWrapper.orderedBy.email = 'test@testContact.com';
        ordWrapper.address.city = 'test';
        ordWrapper.address.country = 'CA';
        ordWrapper.address.state = 'ON';
        ordWrapper.address.street1 = 'test';
        ordWrapper.address.zip = 'test';
        ordWrapper.address.latitude = 0;
        ordWrapper.address.longitude = 0;
        ordWrapper.data = new Order(
        	Company_Code__c = '01',
        	Deliverymethod__c = SBR_3_0_Constants.FULFILLMENT_TYPE_PICKUP,
            SBQQ__Quote__c = quote.Id,
            RecordTypeId = salesRtId
        );
        
        List<OrderItem> orderItems = new List<OrderItem>();
        Integer i=0;
        for(PriceBookEntry pbe : [Select Id,Product2Id From PricebookEntry]){
        	orderItems.add(
            	new OrderItem(
                    OrderId = existing.Id,
                    PricebookEntryId = pbe.Id,
                    Line_Composite_Key__c = 'line'+i,
                	Reservation_Line_Number__c= 2,
                	Fulfillment_Service__c= 'STANDARD',
                	Delivery_Method__c= SBR_3_0_Constants.FULFILLMENT_TYPE_PICKUP,
                	Date_time_out__c= datetime.now(),
           			Global_Line_Number__C= i,
                	Quantity= 1,
                	rates_overriden__c= false,
                	CommissionableYN__c= true,
                	Taxable__c= true,
                	Day_Rate_Source_Code__c= '0R',
               	 	Week_Rate_Source_Code__c= 'TR',
                	Month_Rate_source_code__c= 'TR',
              		Status_Created_Qty__c= 1,
                	miChg__c= 1,
                	Hourly_Rate__c= 1,
                	Daily_Rate__c= 1,
                	Weekly_Rate__c= 1,
                	Monthly_Rate__c= 1,
                	Selling_price__c= 1892.00,
                	Cost__c= 0,
                	Hourly_Book_Rate__c= 10,
                	Minimum_Book_Rate__c= 400,
                	Daily_Book_Rate__c= 400,
               	 	Weekly_Book_Rate__c= 1080,
                	UnitPrice= 1892.00,
                	Misc_Charges_Type__c= 'DEL',
                	Misc_Charge__c= 1892.47
                )
            );
            
            SBR_3_0_CreateOrder.WrapOrderItem lineWrapper1 = new SBR_3_0_CreateOrder.WrapOrderItem();
        	lineWrapper1.productSKU = 'SKU'+i;
        	lineWrapper1.assetNumber = 'asset0';
        	lineWrapper1.orderNumber = '123456';
	        lineWrapper1.branchNumber = '1234';
    	    lineWrapper1.data = new OrderItem(
                Line_Composite_Key__c = 'line'+i,
                Reservation_Line_Number__c= 2,
                Fulfillment_Service__c= 'STANDARD',
                Delivery_Method__c= 'Delivery',
                date_time_out__c= datetime.now(),
                Global_Line_Number__C= i,
                Quantity=5,
                CommissionableYN__c= true,
                Taxable__c= true,
                Day_Rate_Source_Code__c= '0R',
                Week_Rate_Source_Code__c= 'TR',
                Month_Rate_source_code__c= 'TR',
                Status_Created_Qty__c= 1,
                miChg__c = 0,
                Hourly_Rate__c= 2.0,
                Daily_Rate__c = 3.0,
                Weekly_Rate__c = 5.0,
                Monthly_Rate__c = 6.0,
                Suggested_Minimum_Rate__c = 3.0,
                Suggested_Daily_Rate__c = 2.0,
                Suggested_Weekly_Rate__c = 4.0,
                Suggested_Monthly_Rate__c = 6.0,
                Rates_Overriden__c = false,
                Selling_price__c = 1892.00,
                Cost__c= 1,
                Hourly_Book_Rate__c= 10,
                Minimum_Book_Rate__c= 400,
                Daily_Book_Rate__c= 400,
                Weekly_Book_Rate__c= 1080,
                UnitPrice= 100,
                Misc_Charges_Type__c= 'DEL',
                Misc_Charge__c= 1892.47,
                Specific_Pricing_Type__c = SBR_3_0_Constants.CUSTOMER_LOADED_SPECIFIC_PRICING_TYPE,
                PricebookEntryId =  '01uxx0000004C92'
                
            );
            
            lineWrapper1.lineItemDetails = new List<SBR_3_0_CreateOrder.LineItemDetailWrapper>();
            
            
            SBR_3_0_CreateOrder.LineItemDetailWrapper lidw = new SBR_3_0_CreateOrder.LineItemDetailWrapper();
            lidw.data = new Order_Item_Detail__c(
            	Name = 'Test',
                Pickup_Ticket__c = '123',
                OMS_Order_Id__c = '1234'
            );
            lineWrapper1.lineItemDetails.add(lidw);
            
            ordWrapper.lineData.add(lineWrapper1);
            
            i++;
        }
        insert orderItems;
        ordWrapper.lineData.get(1).productSKU = 'SKU1';
        ordWrapper.lineData.get(2).productSKU = 'SKU2';
        ordWrapper.lineData.get(3).productSKU = 'SKU6';
        //ordWrapper.lineData.get(3).data.Status_Closed_Qty__c = ordWrapper.lineData.get(3).data.Quantity;
        
        
        RestRequest request = new RestRequest();
        request.requestBody = Blob.valueOf(JSON.serialize(ordWrapper) );
        RestContext.request = request;
        
        Test.setMock(
            HttpCalloutMock.class,
            new SBR_3_0_CalloutMock(
                new List<SBR_3_0_CalloutMock.MockResponse>{
                    new SBR_3_0_CalloutMock.MockResponse(200,'{"access_token":"test"}'),
                    new SBR_3_0_CalloutMock.MockResponse(200, getMockTaxUpdate())
                }
            )
        );
        
        boolean exceptionThrown = false;
        DateTime startTime = Datetime.now();
        
        Test.startTest();
        Integer queriesBefore = Limits.getQueries();
        Integer dmlBefore = Limits.getDmlStatements();
        
        try{
        	SBR_3_0_API_Web_Order.createOrder();
        }catch(Exception ex){
            exceptionThrown = true;
        }
        System.debug('Total queries used in createOrder call: ' + (Limits.getQueries() - queriesBefore)); //NOPMD
        System.debug('Total dml used in createOrder call: ' + (Limits.getDmlStatements() - dmlBefore)); //NOPMD
		
        Test.stopTest();
        System.debug('Total time ellapsed: ' + ((Datetime.now().getTime() - startTime.getTime())));
        
        List<Exception_Log__c> exceptionLogs = [Select Id,Exception_Message__c From Exception_Log__c];
        if(!exceptionLogs.isEmpty()){
           System.assertEquals(null, exceptionLogs.get(0).Exception_Message__c, 'Encountered an exception: ' + exceptionLogs.get(0).Exception_Message__c);
        }
        
        System.assert(!exceptionThrown, 'An exception was unexpectedly thrown');
        System.assert(exceptionLogs.isEmpty(), 'Found an exception log, when none were expected');
    }
    
    @isTest
    static void testCustomException(){
        //Testing mostly for code coverage.
        SBR_3_0_CustomException ex = new SBR_3_0_CustomException('Message','123');
        System.assertEquals('123', ex.relatedId, 'Related to id not set correctly.');
    }
}