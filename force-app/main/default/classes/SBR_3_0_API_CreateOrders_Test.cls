/*********************************************************************************************************************
* Apex Class: SBR_3_0_API_CreateOrders_Test
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Send Order to Rentalman (via Mulesoft) when it is created in Salesforce test class
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Aditee Churiwala        2022-15-08             Initial version    
*********************************************************************************************************************/
@isTest(seeAllData=false)
public with sharing class SBR_3_0_API_CreateOrders_Test Implements HttpCalloutMock{
    static Boolean SUCCESSTEST = true;
    @TestSetup
    static void makeData(){
        Credential__c cred = SBR_3_0_TestDataFactory.createCredentials(1, false)[0];
        cred.Name = 'Mule_Token_Endpoint';
        cred.Key_Id__c = 'testKey123';
        cred.Secret__c = 'secret';
        insert cred;
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
        branchLocation.Job_Number__c='332112';
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
                // Create Price Book
        Pricebook2 priceBook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update priceBook;
        // Create Order
        Order order = new Order(
            Quote_Name__c = 'Test Quote',
            AccountId = acct.Id,
            Jobsite__c = jobSite.Id,
            Deliverymethod__c = 'Delivery',
            Delivery_Charge__c = 10,
            Pickup_Charge__c = 10,
            Status = 'Draft',
            Company_Code__c = '02',
            Pricebook2Id = priceBook.Id,
            Start_Date__c = Date.today().addDays(1),
            EffectiveDate = Date.today().addDays(2),
            EndDate = Date.today().addDays(5),
            Return_Date__c = Date.today().addDays(5),
            Earliest_Delivery_Date__c = Date.today().addDays(1),
            Estimated_Return_Date__c = Date.today().addDays(4),
            Opt_Out_RPP__c = false,
            Order_By__c = contact.Id,
            Order_Initiating_Channel__c = 'SLSFRC',
            Opt_Out_Fuel_Charge__c = false,
            Selling_Channel__c = 'SBRB2B',
            Rentalman_Quote_Id__c = 'test',
			Duration__c = 'Custom',
            Branch__c =branchLocation.Id
        );
        insert order; 
        
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
                product.Company_code__c ='01;02';
            } else if (i == 1) {
                product.Product_Type__c = 'Parts';
                product.Item_Number__c = '1234GH';
                product.Stock_Class__c = 'AIMFV';
                product.Company_code__c ='01;02';
            } else {
                product.Product_Type__c = '';
                product.Item_Number__c = '1285JC';
                product.Stock_Class__c = 'UJEKL';
                product.Company_code__c ='01;02';
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
            orderItem.Selling_Price__c = 15;
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
            } else if (i == 1) {
                orderItem.Quantity = 3;
                //orderItem.ListPrice = pbEntry2.ListPrice;
            } else {
                orderItem.Quantity = 3;
                orderItem.Misc_Charges_Type__c = 'TRANSPORTATION CHARGE';
                orderItem.Misc_Charge__c = 20.3;
                orderItem.Misc_Charges_Tax__c = 2.34;
                orderItem.Taxable__c = false;
                orderItem.Misc_Charges_Non_Taxable__c = false;
                orderItem.Misc_Charges_Item_Tax_Rate__c = 2.0;
            }
            orderItems.add(orderItem);
        }
        insert orderItems;
    }

    public HTTPResponse respond(HTTPRequest req) {
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type',SBR_3_0_Constants.APP_JSON);
        if(req.getEndpoint().endsWithIgnoreCase('token')){
            res.setBody('{"access_token":"test"}');
            res.setStatusCode(200);
        }else if(SUCCESSTEST) {
            res.setBody( '{"data": {"rmReservationId": "000086613723","sfOrderId": "ABCD-12345","lines": ['+
			'{"lineNumber": 1324546,"sfLineNumber": "100059","rmLineNumber": 1,"rmLineType": "VR"},'+
			'{"lineNumber": 1343567,"sfLineNumber": "100060","rmLineNumber": 2,"rmLineType": "VR"},'+
			'{"lineNumber": 1343567,"sfLineNumber": "100061","rmLineNumber": 5,"rmLineType": "VR"}'+
		']}}');
            res.setStatusCode(200);
        }else {
            res.setBody('{ "error": { "message": "Invalid input parameters, parameters might contain special characters, SQL statements or script statements. Please check application logs for more information.", "errorKey": "BAD_REQUEST", "errorCode": "400-000" } }');
            res.setStatusCode(400);
        }
        return res;
    }

    @isTest 
    static void testCreateOrderSuccess() {
        SUCCESSTEST = true;
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_CreateOrders_Test());
        Order order = [SELECT Id, EndDate FROM Order];
        Test.startTest();
        String recordDetailsJsonString = '{\n' +
                                                ' "paymentMethod" :"Visa",\n' +    
                                                ' "amountCollected" : 10,\n' +
                                                ' "terminal" : "Lane: 003,ID: 1223",\n' +
                                                ' "tranType" : "Charged",\n' +
                                                ' "cashReceived" : 0,\n' +
                                                ' "checkNumber" : 0,\n' +
                                                ' "changeDue" : 0\n' +
                                                '}';
		SBR_3_0_API_CreateOrders.makeADepositDetails =  recordDetailsJsonString;       
        SBR_3_0_API_CreateOrders testCreate = new SBR_3_0_API_CreateOrders(order.Id);
        Test.stopTest();

        // Order newOrder = [SELECT Id, Reservation_Order_Number__c FROM Order];
        // System.assertEquals('000086613723', newOrder.Reservation_Order_Number__c);
    }
    @isTest 
    static void testCreateHandleOrderResponse() {
        SUCCESSTEST = true;
        String response = '{"data": {"rmReservationId": "000086613723","sfOrderId": "ABCD-12345","lines": ['+
        '{"lineNumber": 1324546,"sfLineNumber": "100059","rmLineNumber": 1,"rmLineType": "VR"},'+
        '{"lineNumber": 1343567,"sfLineNumber": "100060","rmLineNumber": 2,"rmLineType": "VR"},'+
        '{"lineNumber": 1343567,"sfLineNumber": "100061","rmLineNumber": 5,"rmLineType": "VR"}'+
    ']}}';
        Object result = JSON.deserializeUntyped(response);

        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_Estimates_Test());
        Order order = [SELECT Id, EndDate FROM Order];
        Test.startTest();
        String recordDetailsJsonString = '{\n' +
                                                ' "paymentMethod" :"Visa",\n' +    
                                                ' "amountCollected" : 10,\n' +
                                                ' "terminal" : "Lane: 003,ID: 1223",\n' +
                                                ' "tranType" : "Charged",\n' +
                                                ' "cashReceived" : 0,\n' +
                                                ' "checkNumber" : 0,\n' +
                                                ' "changeDue" : 0\n' +
                                                '}';
		SBR_3_0_API_CreateOrders.makeADepositDetails =  recordDetailsJsonString;
        SBR_3_0_API_CreateOrders testCreate = new SBR_3_0_API_CreateOrders(order.Id);
        testCreate.response = result;
        testCreate.handleOrderResponse();
        Test.stopTest();

    }

    @isTest 
    static void testCreateQuotesFail() {
        SUCCESSTEST = false;
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_CreateOrders_Test());
        Order order = [SELECT Id FROM Order];
		String recordDetailsJsonString = '{\n' +
                                                ' "paymentMethod" :"Visa",\n' +    
                                                ' "amountCollected" : 10,\n' +
                                                ' "terminal" : "Lane: 003,ID: 1223",\n' +
                                                ' "tranType" : "Charged",\n' +
                                                ' "cashReceived" : 0,\n' +
                                                ' "checkNumber" : 0,\n' +
                                                ' "changeDue" : 0\n' +
                                                '}';
		SBR_3_0_API_CreateOrders.makeADepositDetails =  recordDetailsJsonString;
        Test.startTest();
        try {
            SBR_3_0_API_CreateOrders testCreate = new SBR_3_0_API_CreateOrders(order.Id);
        } catch (Exception e) {
            System.assertNotEquals(null, e, 'Exception should be thrown');
        }
        Test.stopTest();
    }

    @isTest 
    static void testCreateQuotesAccountTypeCreditError() {
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_CreateOrders_Test());
        Account account = [SELECT Id, Record_Type_Text__c, RM_Account_Number__c, SF_Account_Number__c, Drivers_License__c, Driver_s_License_State__c FROM Account LIMIT 1];
         account.Record_Type_Text__c = null;
        //try{
        account.RM_Account_Number__c = null;
        update account;
        //}catch(Exception ex){
        //    system.debug('Exception-'+ ex);
        //}
        Order order = [SELECT Id,Account.RM_Account_Number__c,Rentalman_Quote_Id__c,SBQQ__Quote__c FROM Order];
        String recordDetailsJsonString = '{\n' +
                                                ' "paymentMethod" :"Visa",\n' +    
                                                ' "amountCollected" : 10,\n' +
                                                ' "terminal" : "Lane: 003,ID: 1223",\n' +
                                                ' "tranType" : "Charged",\n' +
                                                ' "cashReceived" : 0,\n' +
                                                ' "checkNumber" : 0,\n' +
                                                ' "changeDue" : 0\n' +
                                                '}';
		SBR_3_0_API_CreateOrders.makeADepositDetails =  recordDetailsJsonString;
        Test.startTest();
        try {
          SBR_3_0_API_CreateOrders testCreate1 = new SBR_3_0_API_CreateOrders(order.Id);
        } catch (Exception e) {
            System.assertEquals('Order related Account is missing RM Account Number. Please update Account and Resubmit', e.getMessage(), 'Exception should be thrown');
        }
        try {
            account.RM_Account_Number__c = null;
            account.Record_Type_Text__c = 'Credit';
            update account;
            SBR_3_0_API_CreateOrders testCreate = new SBR_3_0_API_CreateOrders(order.Id);
        } catch (Exception e) {
            System.assertEquals('Order related Account is missing RM Account Number. Please update Account and Resubmit', e.getMessage(), 'Exception should be thrown');
        }
        Test.stopTest();
       
    }

    @isTest 
    static void testCreateOrdersAccountDetailError() {
        String err = '';
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_CreateOrders_Test());
       Order order = [SELECT Id FROM Order];
        Account account = [SELECT Id, Record_Type_Text__c, RM_Account_Number__c, SF_Account_Number__c, Drivers_License__c, Driver_s_License_State__c FROM Account];
        String recordDetailsJsonString = '{\n' +
                                                ' "paymentMethod" :"Visa",\n' +    
                                                ' "amountCollected" : 10,\n' +
                                                ' "terminal" : "Lane: 003,ID: 1223",\n' +
                                                ' "tranType" : "Charged",\n' +
                                                ' "cashReceived" : 0,\n' +
                                                ' "checkNumber" : 0,\n' +
                                                ' "changeDue" : 0\n' +
                                                '}';
		SBR_3_0_API_CreateOrders.makeADepositDetails =  recordDetailsJsonString;
        Test.startTest();
        try {
            account.Phone = null;
            update account;
            SBR_3_0_API_CreateOrders testCreate = new SBR_3_0_API_CreateOrders(order.Id);
        } catch (Exception e) {
            err = e.getMessage();
           // System.assert(err.contains(e), 'g');
            //System.assertEquals('Please enter a 10 Digit phone number.: [Phone]', e.getMessage(), 'Exception should be thrown');
        }
        try {
            account.E_mail_Address__c = null;
            update account;
            SBR_3_0_API_CreateOrders testCreate = new SBR_3_0_API_CreateOrders(order.Id);
        } catch (Exception e) {
           // System.assertEquals('order.Account.E_mail_Address__c is required', e.getMessage(), 'Exception should be thrown');
        }
        Test.stopTest();
    }

    @isTest 
    static void testCreateOrderBranchError() {
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_CreateOrders_Test());
        Order order = [SELECT Id FROM Order];
        Schema.Location location = [SELECT Branch_Location_Number__c, Time_Zone_Name__c, Time_Zone__c FROM Location WHERE Name =: 'Test Branch Location'];
        String recordDetailsJsonString = '{\n' +
                                                ' "paymentMethod" :"Visa",\n' +    
                                                ' "amountCollected" : 10,\n' +
                                                ' "terminal" : "Lane: 003,ID: 1223",\n' +
                                                ' "tranType" : "Charged",\n' +
                                                ' "cashReceived" : 0,\n' +
                                                ' "checkNumber" : 0,\n' +
                                                ' "changeDue" : 0\n' +
                                                '}';
		SBR_3_0_API_CreateOrders.makeADepositDetails =  recordDetailsJsonString;
        Test.startTest();
        try {
            location.Time_Zone__c = null;
            location.Time_Zone_Id__c = null;
            update location;
            SBR_3_0_API_CreateOrders testCreate = new SBR_3_0_API_CreateOrders(order.Id);
        } catch (Exception e) {
            System.assertEquals('Location Time Zone Id is required', e.getMessage(), 'Exception should be thrown');
        }
        try {
            location.Time_Zone_Name__c = null;
            update location;
            SBR_3_0_API_CreateOrders testCreate = new SBR_3_0_API_CreateOrders(order.Id);
        } catch (Exception e) {
            System.assertEquals('Location Time Zone Id is required', e.getMessage(), 'Exception should be thrown');
        }
        try {
            location.Branch_Location_Number__c = null;
            update location;
            SBR_3_0_API_CreateOrders testCreate = new SBR_3_0_API_CreateOrders(order.Id);
        } catch (Exception e) {
            System.assertEquals('Branch Location Number is required', e.getMessage(), 'Exception should be thrown');
        }
        Test.stopTest();
    }

    @isTest
    static void testCreateOrderMiscItemError() {
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_CreateOrders_Test());
        Order order = [SELECT Id FROM Order];
        OrderItem miscItemLine = [SELECT Id, Misc_Charges_Type__c, Misc_Charge__c FROM OrderItem WHERE Product2.Product_Type__c =: ''];
        Product2 miscItemProd = [SELECT Id, Item_Number__c, Stock_Class__c FROM Product2 WHERE Product_Type__c =: ''];
        Exception unexpectedException;
        String recordDetailsJsonString = '{\n' +
                                                ' "paymentMethod" :"Visa",\n' +    
                                                ' "amountCollected" : 10,\n' +
                                                ' "terminal" : "Lane: 003,ID: 1223",\n' +
                                                ' "tranType" : "Charged",\n' +
                                                ' "cashReceived" : 0,\n' +
                                                ' "checkNumber" : 0,\n' +
                                                ' "changeDue" : 0\n' +
                                                '}';
		SBR_3_0_API_CreateOrders.makeADepositDetails =  recordDetailsJsonString;
        Test.startTest();
        try {
            miscItemProd.Stock_Class__c = null;
            update miscItemProd;
            SBR_3_0_API_CreateOrders testCreate = new SBR_3_0_API_CreateOrders(order.Id);
        } catch (Exception e) {
            System.assertEquals('Order Item Product is missing Stock Class. Please update Product and Resubmit.', e.getMessage(), 'Exception should be thrown');
        }
        try {
            miscItemProd.Item_Number__c = null;
            update miscItemProd;
            SBR_3_0_API_CreateOrders testCreate = new SBR_3_0_API_CreateOrders(order.Id);
        } catch (Exception e) {
            System.assertEquals('Order Item Product is missing Item Number. Please update Product and Resubmit.', e.getMessage(), 'Exception should be thrown');
        }
        try {
            miscItemLine.Misc_Charge__c = null;
            update miscItemLine;
            SBR_3_0_API_CreateOrders testCreate = new SBR_3_0_API_CreateOrders(order.Id);
        } catch (Exception e) {
            System.assertEquals('Order Item Product is missing Item Number. Please update Product and Resubmit.', e.getMessage(), 'Exception should be thrown');
        }
        try {
            miscItemLine.Misc_Charges_Type__c = null;
            update miscItemLine;
            SBR_3_0_API_CreateOrders testCreate = new SBR_3_0_API_CreateOrders(order.Id);
        } catch (Exception e) {
            System.assertEquals('Order Item is missing Misc Charges Type. Please update Order Item and Resubmit.', e.getMessage(), 'Exception should be thrown');
        }
        Test.stopTest();
    }

    @isTest
    static void testCreateOrdersSaleItemError() {
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_CreateOrders_Test());
        Order order = [SELECT Id FROM Order];
        OrderItem miscItemLine = [SELECT Id, Misc_Charges_Type__c, Misc_Charge__c FROM OrderItem WHERE Product2.Product_Type__c =: 'Parts'];
        Product2 saleItemProd = [SELECT Id, Item_Number__c, Stock_Class__c FROM Product2 WHERE Product_Type__c =: 'Parts'];
        Exception unexpectedException;
        String recordDetailsJsonString = '{\n' +
                                                ' "paymentMethod" :"Visa",\n' +    
                                                ' "amountCollected" : 10,\n' +
                                                ' "terminal" : "Lane: 003,ID: 1223",\n' +
                                                ' "tranType" : "Charged",\n' +
                                                ' "cashReceived" : 0,\n' +
                                                ' "checkNumber" : 0,\n' +
                                                ' "changeDue" : 0\n' +
                                                '}';
		SBR_3_0_API_CreateOrders.makeADepositDetails =  recordDetailsJsonString;
        Test.startTest();
        try {
            saleItemProd.Stock_Class__c = null;
            update saleItemProd;
            SBR_3_0_API_CreateOrders testCreate = new SBR_3_0_API_CreateOrders(order.Id);
        } catch (Exception e) {
            System.assertEquals('Order Item product is missing Stock Class. Please update product and Resubmit.', e.getMessage(), 'Exception should be thrown');
        }
        try {
            saleItemProd.Item_Number__c = null;
            update saleItemProd;
            SBR_3_0_API_CreateOrders testCreate = new SBR_3_0_API_CreateOrders(order.Id);
        } catch (Exception e) {
            System.assertEquals('Order Item product is missing Item Number. Please update product and Resubmit.', e.getMessage(), 'Exception should be thrown');
        }
        Test.stopTest();
    }
 
    @isTest
    static void testCreateOrdersProductRatesError() {
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_CreateOrders_Test());
        Order order = [SELECT Id FROM Order];
        OrderItem ProductItemLine = [SELECT Id, Misc_Charges_Type__c, Misc_Charge__c FROM OrderItem WHERE Product2.Product_Type__c =: 'Cat-Class' AND Product2.Name = 'Test Product 0'];
        Product2 ProductItemProd = [SELECT Id, Category__c, Class__c, ToolFlex__c, Product_SKU__c FROM Product2 WHERE Product_Type__c =: 'Cat-Class' AND Product2.Name = 'Test Product 0'];
        Exception unexpectedException;
        String recordDetailsJsonString = '{\n' +
                                                ' "paymentMethod" :"Visa",\n' +    
                                                ' "amountCollected" : 10,\n' +
                                                ' "terminal" : "Lane: 003,ID: 1223",\n' +
                                                ' "tranType" : "Charged",\n' +
                                                ' "cashReceived" : 0,\n' +
                                                ' "checkNumber" : 0,\n' +
                                                ' "changeDue" : 0\n' +
                                                '}';
		SBR_3_0_API_CreateOrders.makeADepositDetails =  recordDetailsJsonString;
        Test.startTest();
        try {
          
            ProductItemLine.Item_Number__c = null;
            update ProductItemLine;
            SBR_3_0_API_CreateOrders testCreate = new SBR_3_0_API_CreateOrders(Order.Id);
        } catch (Exception e) {
            System.assertEquals('You have uncommitted work pending. Please commit or rollback before calling out', 
                                e.getMessage(), 'Exception should be thrown');
        }
        try {
            ProductItemLine.Monthly_Rate__c = null;
            update ProductItemLine;
            SBR_3_0_API_CreateOrders testCreate = new SBR_3_0_API_CreateOrders(Order.Id);
        } catch (Exception e) {
            System.assertEquals('Order item is missing Montly Rate .  Please update Order Item and Resubmit.', e.getMessage(), 'Exception should be thrown');
        }
        try {
            ProductItemLine.Weekly_Rate__c = null;
            update ProductItemLine;
            SBR_3_0_API_CreateOrders testCreate = new SBR_3_0_API_CreateOrders(Order.Id);
        } catch (Exception e) {
            System.assertEquals('Order item is missing Weekly Rate .  Please update Order Item and Resubmit.', e.getMessage(), 'Exception should be thrown');
        }
        try {
            ProductItemLine.Daily_Rate__c = null;
            update ProductItemLine;
            SBR_3_0_API_CreateOrders testCreate = new SBR_3_0_API_CreateOrders(Order.Id);
        } catch (Exception e) {
            System.assertEquals('Order item is missing Daily Rate .  Please update Order Item and Resubmit.', e.getMessage(), 'Exception should be thrown');
        }
        Test.stopTest();
    }

    @isTest
    static void testCreateOrderProductSuggestedRatesError() {
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_CreateOrders_Test());
        Order order = [SELECT Id FROM Order];
        OrderItem ProductItemLine = [SELECT Id, Hourly_Rate__c, Suggested_Monthly_Rate__c, Suggested_Weekly_Rate__c, Suggested_Daily_Rate__c, Min_Rate__c FROM OrderItem WHERE Product2.Product_Type__c =: 'Cat-Class'];
        Product2 ProductItemProd = [SELECT Id, Category__c, Class__c, ToolFlex__c, Product_SKU__c FROM Product2 WHERE Product_Type__c =: 'Cat-Class'];
        Exception unexpectedException;
        String recordDetailsJsonString = '{\n' +
                                                ' "paymentMethod" :"Visa",\n' +    
                                                ' "amountCollected" : 10,\n' +
                                                ' "terminal" : "Lane: 003,ID: 1223",\n' +
                                                ' "tranType" : "Charged",\n' +
                                                ' "cashReceived" : 0,\n' +
                                                ' "checkNumber" : 0,\n' +
                                                ' "changeDue" : 0\n' +
                                                '}';
		SBR_3_0_API_CreateOrders.makeADepositDetails =  recordDetailsJsonString;
        Test.startTest();
        try {
            ProductItemLine.Suggested_Monthly_Rate__c = null;
            update ProductItemLine;
            SBR_3_0_API_CreateOrders testCreate = new SBR_3_0_API_CreateOrders(order.Id);
        } catch (Exception e) {
            System.assertEquals('Order item is missing Suggested Monthly Rate .  Please update Order Item and Resubmit.', e.getMessage(), 'Exception should be thrown');
        }
        try {
            ProductItemLine.Suggested_Weekly_Rate__c = null;
            update ProductItemLine;
            SBR_3_0_API_CreateOrders testCreate = new SBR_3_0_API_CreateOrders(order.Id);
        } catch (Exception e) {
            System.assertEquals('Order item is missing Suggested Weekly Rate .  Please update Order Item and Resubmit.', e.getMessage(), 'Exception should be thrown');
        }
        try {
            ProductItemLine.Suggested_Daily_Rate__c = null;
            update ProductItemLine;
            SBR_3_0_API_CreateOrders testCreate = new SBR_3_0_API_CreateOrders(order.Id);
        } catch (Exception e) {
            System.assertEquals('Order item is missing Suggested Daily Rate .  Please update Order Item and Resubmit.', e.getMessage(), 'Exception should be thrown');
        }
        try {
            ProductItemLine.Min_Rate__c = null;
            update ProductItemLine;
            SBR_3_0_API_CreateOrders testCreate = new SBR_3_0_API_CreateOrders(order.Id);
        } catch (Exception e) {
            System.assertEquals('Order item is missing Min Rate .  Please update Order Item and Resubmit.', e.getMessage(), 'Exception should be thrown');
        }
        try {
            ProductItemLine.Hourly_Rate__c = null;
            update ProductItemLine;
            SBR_3_0_API_CreateOrders testCreate = new SBR_3_0_API_CreateOrders(order.Id);
        } catch (Exception e) {
            System.assertEquals('Order item is  missing Hourly Rate .  Please update Order Item and Resubmit.', e.getMessage(), 'Exception should be thrown');
        }
        Test.stopTest();
    }
}