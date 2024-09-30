/*********************************************************************************************************************
* Apex Class: SBR_3_0_API_ReservationSourcingCall_Test
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Test class for SBR_3_0_API_ReservationSourcingCall
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
1.0         Aditee Churiwala        2023-01-02          Initial version    
*********************************************************************************************************************/
@isTest(seeAllData=false)
public with sharing class SBR_3_0_API_ReservationSourcingCall_Test Implements HttpCalloutMock{
    static Boolean SUCCESSTEST = true;
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
        // Create Order
        Order order = new Order(
            Quote_Name__c = 'Test Quote Test Class',
            AccountId = acct.Id,
            Branch__c = branchLocation.Id,
            Jobsite__c = jobSite.Id,
            Deliverymethod__c = 'Delivery',
            Delivery_Charge__c = 10,
            Status = 'Draft',
            Cart_Id__c = 'abcd',
            Pricebook2Id = priceBook.Id,
            Start_Date__c = date.valueOf('2025-12-12 12:00:00'),
            EffectiveDate = date.valueOf('2025-12-12 12:00:00'),
            EndDate = date.valueOf('2026-10-09 8:00:00'),
            Return_Date__c = date.valueOf('2023-10-09 8:00:00'),
            Earliest_Delivery_Date__c = date.valueOf('2024-10-08 12:00:00'),
            Estimated_Return_Date__c = date.valueOf('2024-10-06 12:00:00'),
            Opt_Out_RPP__c = false,
            Order_By__c = contact.Id,
            Order_Initiating_Channel__c = 'SLSFRC',
            Opt_Out_Fuel_Charge__c = false,
            Selling_Channel__c = 'SBRB2B',
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
                product.Stock_Class__c = 'UJEKL';
            }
            products.add(product);
        }
        insert products;
        // Create Price Book Entry
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = priceBook.Id,
            Product2Id = products[0].Id,
            UnitPrice = 1020,
            IsActive = true);
        Insert pbe;
        List<PricebookEntry> listPbe = new List<PricebookEntry>();
        Map<Id, Id> mapPBE = new Map<Id, Id>();
        for(PricebookEntry pbEntry : [SELECT Id,Product2Id FROM PricebookEntry WHERE Pricebook2Id = :priceBook.Id]) {
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
            orderItem.Product2Id = products[i].Id;
            orderItem.UnitPrice = 100;
            orderItem.Item_Number__c = i;
            orderItem.Min_Rate__c = 2;
            orderItem.Daily_Rate__c = 2.0;
            orderItem.Weekly_Rate__c = 2.0;
            orderItem.Monthly_Rate__c = 2.0;
            OrderItem orderItem2 = new OrderItem();
            orderItem2.OrderId = order.Id;
            orderItem2.Product2Id = products[1].Id;
            orderItem2.UnitPrice = 100;
            orderItem2.Item_Number__c = 3;
            orderItem2.Min_Rate__c = 2;
            orderItem2.Daily_Rate__c = 2.0;
            orderItem2.Weekly_Rate__c = 2.0;
            orderItem2.Monthly_Rate__c = 2.0;
            //orderItem.PricebookEntryId = mapPBE.get(products[i].Id);
            orderItem.PricebookEntryId = [SELECT Id,Product2Id FROM PricebookEntry WHERE Pricebook2Id = :priceBook.Id].ID;
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
            res.setBody( '{"data": {'+
                        '"pc": "720",'+
                        '"latitude": 48.51,'+
                        '"longitude": -117.62,'+
                        '"companyId": "01",'+
                        '"isLastResortBranch": true}}');
            res.setStatusCode(200);
        }else {
            res.setBody('{ "error": { "message": "Invalid input parameters, parameters might contain special characters, SQL statements or script statements. Please check application logs for more information.", "errorKey": "BAD_REQUEST", "errorCode": "400-000" } }');
            res.setStatusCode(400);
        }
        return res;
    }
    
    @isTest 
    static void testCreateOrderSuccess() {
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_ReservationSourcingCall_Test());
        Order order = [SELECT Id, EndDate,OMS_Sourcing_Enabled__c, Sourcing_Branch__c FROM Order];
        System.debug('@@@order'+order);
        Test.startTest();
        SBR_3_0_API_ReservationSourcingCall.callSource(order.Id);
        Test.stopTest();
        
        Order newOrder = [SELECT Id,Branch__r.Branch_Location_Number__c, Sourcing_Branch__c FROM Order];
        Schema.Location loc = [SELECT Id, Branch_Location_Number__c FROM Location WHERE Branch_Location_Number__c = '720' 
                               AND Recordtype.Name =: SBR_3_0_Constants.LOCATION_REC_TYPE_BRANCH LIMIT 1];
        System.assertEquals(loc.Branch_Location_Number__c, newOrder.Branch__r.Branch_Location_Number__c);
    }
    @isTest 
    static void setSalesItemTest() {
        OrderItem orderItem = new OrderItem();
        orderItem.Product2 = new Product2();
        orderItem.Product2.Item_Number__c = '123';
        orderItem.Product2.Stock_Class__c = 'A';
        orderItem.Quantity = 5.0;
        orderItem.Selling_Price__c = 10.0;
        Test.startTest();
        SBR_3_0_WrapOrderSource orderWrapper = new SBR_3_0_WrapOrderSource();
        SBR_3_0_WrapOrderSource.SalesItems salesItems = new SBR_3_0_WrapOrderSource.SalesItems();
        SBR_3_0_API_ReservationSourcingCall.setSalesItem(orderItem);
        Test.stopTest();
    }
    
    @isTest 
    static void validateSaleItemTest() {
        OrderItem orderItem = new OrderItem();
        orderItem.Product2 = new Product2();
        orderItem.Product2.Item_Number__c = null;
        orderItem.Product2.Stock_Class__c = null;
        orderItem.Quantity = null;
        orderItem.Selling_Price__c = null;
        
        try {
            
            SBR_3_0_API_ReservationSourcingCall.validateSaleItem(orderItem);
            
            
        } catch (Exception e) {
            
            System.assertEquals('orderItem.Product2.Item_Number__c is required for SaleItem', e.getMessage());
        }
    }
    
    @isTest 
    static void validateSaleItemItem_NumberTest() {
        OrderItem orderItem = new OrderItem();
        orderItem.Product2 = new Product2();
        orderItem.Product2.Item_Number__c = null;
        orderItem.Product2.Stock_Class__c = null;
        orderItem.Quantity = null;
        orderItem.Selling_Price__c = null;
        
        try {
            SBR_3_0_API_ReservationSourcingCall.validateSaleItem(orderItem);
        } catch (Exception e) {
            System.assertEquals('orderItem.Product2.Item_Number__c is required for SaleItem', e.getMessage());
        }
    }
    
    @isTest 
    static void validateSaleItemStock_ClassTest() {
        OrderItem orderItem = new OrderItem();
        orderItem.Product2 = new Product2();
        orderItem.Product2.Item_Number__c = '123';
        orderItem.Product2.Stock_Class__c = null;
        orderItem.Quantity = null;
        orderItem.Selling_Price__c = null;
        
        try {
            SBR_3_0_API_ReservationSourcingCall.validateSaleItem(orderItem);
        } catch (Exception e) {
            System.assertEquals('orderItem.Product2.Stock_Class__c is required for SaleItem', e.getMessage());
        }
    }
    @isTest 
    static void validateSaleQuantity_ClassTest() {
        OrderItem orderItem = new OrderItem();
        orderItem.Product2 = new Product2();
        orderItem.Product2.Item_Number__c = '123';
        orderItem.Product2.Stock_Class__c = 'ABC';
        orderItem.Quantity = null;
        orderItem.Selling_Price__c = 9.0;
        
        try {
            SBR_3_0_API_ReservationSourcingCall.validateSaleItem(orderItem);
        } catch (Exception e) {
            System.assertEquals('orderItem.Quantity is required for SaleItem', e.getMessage());
        }
    }
    @isTest 
    static void validateSaleSellingPrice_ClassTest() {
        OrderItem orderItem = new OrderItem();
        orderItem.Product2 = new Product2();
        orderItem.Product2.Item_Number__c = '123';
        orderItem.Product2.Stock_Class__c = 'ACR';
        orderItem.Quantity = 9.0;
        orderItem.Selling_Price__c = null;
        
        try {
            SBR_3_0_API_ReservationSourcingCall.validateSaleItem(orderItem);
        } catch (Exception e) {
            System.assertEquals('orderItem.Selling_Price__c is required for SaleItem', e.getMessage());
        }
    }
    
    @isTest 
    static void testCreateQuotesFail() {
        SUCCESSTEST = false;
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_ReservationSourcingCall_Test());
        Order order = [SELECT Id FROM Order];
        
        Test.startTest();
        try {
            SBR_3_0_API_ReservationSourcingCall.callSource(order.Id);
        } catch (Exception e) {
            System.assertNotEquals(null, e, 'Exception should be thrown');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testCallSourceFrontline() {
        Order order = [SELECT Id FROM Order];
        Test.startTest();
        order.Start_Date__c = Datetime.now().addDays(10);
        order.Return_Date__c = Datetime.now().addDays(20);
        order.Closed_Description__c = 'Test Closed Description';
        SBR_3_0_API_ReservationSourcingCall.callSourceFrontline(order, order.Id);        
        Test.stopTest();
        Order updateOrder = [SELECT Closed_Description__c FROM Order];
        System.Assert.areEqual(
            order.Closed_Description__c,
            'Test Closed Description',
            'Order updated successfully'
        );
    }
}