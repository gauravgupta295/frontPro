/*********************************************************************************************************************
* Apex Class: SBR_3_0_UpdateTotals_Test
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Test class for SBR_3_0_UpdateTotals
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Kunal Patel             2022-11-17          Initial version    
*********************************************************************************************************************/
@isTest
public with sharing class SBR_3_0_UpdateTotals_Test implements HttpCalloutMock{

    static string PRODUCT_1_SKU = '123001';
    static string PRODUCT_2_SKU = '123002';
    static string PRODUCT_3_SKU = '123003';
    static string PRODUCT_4_SKU = '123004';
    static string PRODUCT_5_SKU = '123005';

    @TestSetup
    static void makeData(){
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator']; 
        
        UserRole ur = [SELECT Id, Name FROM UserRole where Name = 'Sales - US'];
        
        User user = new User(Alias = 'standt', Email='standardperson@airrexusa.com', 
        EmailEncodingKey='UTF-8', LastName='Testing',UserRoleId =ur.Id, LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', ProfileId = p.Id, Analysis_Region_Key__c = '921',
        TimeZoneSidKey='America/Los_Angeles', UserName='standardperson@airrexusa.com');

        insert user;
      
        system.runAs(user){
            
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
        SBR_3_0_TriggerHandler.bypass('SBR_3_0_AccountTriggerHandler');//bypass trigger
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
        branchLocation.Time_Zone_Id__c = '1111';
        branchLocation.OMS_Sourcing_Enabled__c = true;
        branchLocation.Analysis_Region_Key__c = '921';
        branchLocation.Latitude_Longitude__Latitude__s = 47.09;
        branchLocation.Latitude_Longitude__Longitude__s = 47.09;
        insert branchLocation;

        //Create branch for analysis region key as 921
        Schema.Location branchLocation2 = new Schema.Location();
        branchLocation2.Branch_Location_Number__c = '720';
        branchLocation2.Name = 'Test Branch Location1';
        branchLocation2.Street_Address__c = '12 Main Street';
        branchLocation2.City__c = 'Toronto';
        branchLocation2.Zip_Code__c = 'M7N7B3';
        branchLocation2.State__c = 'ON';
        branchLocation2.Country__c = 'CA';
        branchLocation2.Job_Number__c='332112';
        branchLocation2.RecordTypeId = SBR_3_0_Constants.LOCATION_BRANCH_RT_ID;
        branchLocation2.Company_Code__c = 'X';
        branchLocation2.Time_Zone_Name__c = 'America/Chicago';
        branchLocation2.Time_Zone__c = 3;
        branchLocation2.Time_Zone_Id__c = '1111';
        branchLocation2.Analysis_Region_Key__c = '921';
        branchLocation2.OMS_Sourcing_Enabled__c = true;
        branchLocation2.Latitude_Longitude__Latitude__s = 47.09;
        branchLocation2.Latitude_Longitude__Longitude__s = 47.09;
        insert branchLocation2;

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
            Start_Date__c = System.today().addMonths(1),
            End_Date__c = System.today().addMonths(3),
            Delivery_Date__c = System.today().addMonths(2),
            Opt_Out_RPP__c = false,
            Ordered_by__c = contact.Id,
            Opt_Out_Fuel_Charge__c = false,
            Selling_Channel__c = 'SBRB2B',
            Account_Record_Type_Txt__c='Credit'
            //Duration__c = 'Custom'
        );
        quoteInsertList.add(quote1);
        
        SBQQ__Quote__c quote2 = new SBQQ__Quote__c(
            Quote_Name__c = 'Test Quote 2',
            SBQQ__Account__c = acct.Id,
            Branch__c = branchLocation2.Id,
            Jobsite__c = jobSite.Id,
            SBQQ__DeliveryMethod__c = 'Delivery',
            Delivery_Charge__c = 0,
            SBQQ__Status__c = 'Draft',
            SBQQ__PriceBook__c = priceBook.Id,
            Start_Date__c = System.today().addMonths(1),
            End_Date__c = System.today().addMonths(3),
            Delivery_Date__c = System.today().addMonths(2),
            Opt_Out_RPP__c = false,
            Ordered_by__c = contact.Id,
            Opt_Out_Fuel_Charge__c = false,
            //Number_of_Trucks__c = '2',
            Delivery_Charges_Override__c = false,
            Selling_Channel__c = 'SBRB2B',
            Account_Record_Type_Txt__c='Credit'
            //Duration__c = 'Custom'
        );
        quoteInsertList.add(quote2);

        SBQQ__Quote__c quote3 = new SBQQ__Quote__c(
            Quote_Name__c = 'Test Quote 3',
            SBQQ__Account__c = acct.Id,
            SBQQ__DeliveryMethod__c = '',
            Delivery_Charge__c = 0,
            SBQQ__Status__c = 'Draft',
            SBQQ__PriceBook__c = priceBook.Id,
            Start_Date__c = System.today().addMonths(1),
            End_Date__c = System.today().addMonths(10),
            Delivery_Date__c = System.today().addMonths(2),
            Account_Record_Type_Txt__c='Credit'
        );
        quoteInsertList.add(quote3);
        
        SBQQ__Quote__c quote = new SBQQ__Quote__c(
            Quote_Name__c = 'Test Quote',
            SBQQ__Account__c = acct.Id,
            Branch__c = branchLocation.Id,
            Jobsite__c = jobSite.Id,
            SBQQ__DeliveryMethod__c = 'Delivery',
            Delivery_Charge__c = 0,
            SBQQ__Status__c = 'Draft',
            SBQQ__PriceBook__c = priceBook.Id,
            Start_Date__c = System.today().addMonths(1),
            End_Date__c = System.today().addMonths(3),
            Delivery_Date__c = System.today().addMonths(2),
            Opt_Out_RPP__c = false,
            Ordered_by__c = contact.Id,
            Opt_Out_Fuel_Charge__c = false,
            //Number_of_Trucks__c = '2',
            Delivery_Charges_Override__c = false,
            Selling_Channel__c = 'SBRB2B',
            Account_Record_Type_Txt__c='Credit'
            //Duration__c = 'Custom'
        );
        quoteInsertList.add(quote);
        SBR_3_0_TriggerHandler.bypass('SBR_3_0_QuoteTriggerHandler');//bypass trigger
        insert quoteInsertList ;
        
        // Create Product
        List<Product2> products = new List<Product2>();
        for(Integer i = 0; i < 5; i++) {
            Product2 product = new Product2();
            product.Name = 'Test Product ' + i;
            if(i == 0) {
                product.Product_Type__c = 'Cat-Class';
                product.Product_SKU__c = '123456';
                product.Category__c = '32134';
                product.Class__c = '2039';
                product.ToolFlex__c = 'N';
                product.Product_SKU__c = PRODUCT_1_SKU;
            } else if (i == 1) {
                product.Product_Type__c = 'Parts';
                product.Item_Number__c = '1234GH';
                product.Stock_Class__c = 'AIMFV';
                product.Product_SKU__c = PRODUCT_2_SKU;
            } else if (i == 2) {
                product.Product_Type__c = '';
                product.Item_Number__c = '1285JC';
                product.Stock_Class__c = 'MISC';
                product.Product_SKU__c = PRODUCT_3_SKU;
            } else if (i == 3) {
                product.Product_Type__c = '';
                product.Item_Number__c = '016-0010';
                product.Stock_Class__c = 'MISC';
                product.Product_SKU__c = PRODUCT_4_SKU;
            }else{
                product.Product_Type__c = 'Cat-Class';
                product.Item_Number__c = '008-0007';
                product.Stock_Class__c = 'MISC';
                product.Product_SKU__c = PRODUCT_5_SKU;
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
        
        PricebookEntry pbe4 = new PricebookEntry(
        Pricebook2Id = priceBook.Id,
        Product2Id = products[3].Id,
        UnitPrice = 1020,
        IsActive = true);
        pbEntryListInsert.add(pbe4);
        
        PricebookEntry pbe5 = new PricebookEntry(
        Pricebook2Id = priceBook.Id,
        Product2Id = products[4].Id,
        UnitPrice = 1020,
        IsActive = true);
        pbEntryListInsert.add(pbe5);
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

        /*PricebookEntry pbEntry = [SELECT Id,CurrencyIsoCode FROM PricebookEntry WHERE Pricebook2Id = :priceBook.Id AND Product2Id = :products[0].Id LIMIT 1];
        PricebookEntry pbEntry2 = [SELECT Id FROM PricebookEntry WHERE Pricebook2Id = :priceBook.Id AND Product2Id = :products[1].Id LIMIT 1];
        PricebookEntry pbEntry3 = [SELECT Id FROM PricebookEntry WHERE Pricebook2Id = :priceBook.Id AND Product2Id = :products[2].Id LIMIT 1];
        PricebookEntry pbEntry4 = [SELECT Id FROM PricebookEntry WHERE Pricebook2Id = :priceBook.Id AND Product2Id = :products[3].Id LIMIT 1];
        PricebookEntry pbEntry5 = [SELECT Id FROM PricebookEntry WHERE Pricebook2Id = :priceBook.Id AND Product2Id = :products[4].Id LIMIT 1];*/
        
        List<PricebookEntry> pbEntry = [SELECT Id,CurrencyIsoCode FROM PricebookEntry WHERE Pricebook2Id = :priceBook.Id AND Product2Id IN:products];
        
        // Create Order item
        List<SBQQ__QuoteLine__c> quoteItems = new List<SBQQ__QuoteLine__c>();
       for(Integer i = 0; i < 5; i++){
            SBQQ__QuoteLine__c quoteItem = new SBQQ__QuoteLine__c();
            quoteItem.SBQQ__Quote__c = quote.Id;
            quoteItem.SBQQ__Product__c = products[i].Id;
            quoteItem.SBQQ__UnitCost__c = 100;
            quoteItem.RM_Quote_Line_Number__c = i;
            quoteItem.Min_Rate__c = 2;
            quoteItem.Daily_Rate__c = 2.0;
            quoteItem.Weekly_Rate__c = 2.0;
            quoteItem.Monthly_Rate__c = 2.0;
            quoteItem.SBQQ__PricebookEntryId__c = pbEntry[0].Id;
            quoteItem.Extended_Weight_Autofill__c= 20000.0;
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
            } else if (i == 2) {
                quoteItem.SBQQ__Quantity__c = 3;
                quoteItem.Misc_Charges_Type__c = 'TRANSPORTATION CHARGE';
                quoteItem.Misc_Charge__c = 20.3;
                quoteItem.Misc_Charges_Tax__c = 2.34;
                quoteItem.SBQQ__Taxable__c = false;
                quoteItem.Misc_Charges_Non_Taxable__c = false;
                quoteItem.Misc_Charges_Item_Tax_Rate__c = 2.0;
                quoteItem.is_Forced_Item__c = true;
            }  else if (i == 3) {
                quoteItem.SBQQ__Quantity__c = 3;
                quoteItem.Misc_Charges_Type__c = 'TRANSPORTATION CHARGE';
                quoteItem.Misc_Charge__c = 20.3;
                quoteItem.Misc_Charges_Tax__c = 2.34;
                quoteItem.SBQQ__Taxable__c = false;
                quoteItem.Misc_Charges_Non_Taxable__c = false;
                quoteItem.Misc_Charges_Item_Tax_Rate__c = 2.0;
                quoteItem.is_Forced_Item__c = true;
                quoteItem.Rental_Amount__c = 1.0;
                quoteItem.SBQQ__UnitCost__c = 1239.12;
                quoteItem.Rental_Tax__c = 8675.24;
                quoteItem.Rental_Tax_Rate__c = 7.0;
                quoteItem.Unit_RPP_Cost__c = 18518518.36;
                quoteItem.RPP_Tax_Rate__c = 7.0;
                quoteItem.Selling_Price__c = 1.0;
                quoteItem.Hourly_Rate__c = 2.0;
                quoteItem.Min_Rate__c = 2.0;
                quoteItem.Daily_Rate__c = 2.0;
                quoteItem.Weekly_Rate__c = 2.0;
                quoteItem.Monthly_Rate__c = 2.0;
            } else{
                quoteItem.SBQQ__Quantity__c = 3;
                quoteItem.Misc_Charges_Type__c = 'TRANSPORTATION CHARGE';
                quoteItem.Misc_Charge__c = 20.3;
                quoteItem.Misc_Charges_Tax__c = 2.34;
                quoteItem.SBQQ__Taxable__c = false;
                quoteItem.Misc_Charges_Non_Taxable__c = false;
                quoteItem.Misc_Charges_Item_Tax_Rate__c = 2.0;
                quoteItem.is_Forced_Item__c = true;
                quoteItem.Rental_Amount__c = 1.0;
                quoteItem.SBQQ__UnitCost__c = 1239.12;
                quoteItem.Rental_Tax__c = 8675.24;
                quoteItem.Rental_Tax_Rate__c = 7.0;
                quoteItem.Unit_RPP_Cost__c = 18518518.36;
                quoteItem.RPP_Tax_Rate__c = 7.0;
                quoteItem.Selling_Price__c = 1.0;
                quoteItem.Hourly_Rate__c = 2.0;
                quoteItem.Min_Rate__c = 2.0;
                quoteItem.Daily_Rate__c = 2.0;
                quoteItem.Weekly_Rate__c = 2.0;
                quoteItem.Monthly_Rate__c = 2.0;
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
            Delivery_Charge__c = 0,
            Status = 'Draft',
            Pricebook2Id = priceBook.Id,
            Start_Date__c = system.today().addMonths(1),
            EffectiveDate = system.today().addMonths(1),
            EndDate = system.today().addMonths(2),
            Return_Date__c = system.today().addMonths(3),
            Estimated_Return_Date__c = system.today().addMonths(3),
            Earliest_Delivery_Date__c = system.today().addMonths(1),
            Opt_Out_RPP__c = false,
            Order_Initiating_Channel__c = 'SLSFRC',
            Opt_Out_Fuel_Charge__c = false,
            Selling_Channel__c = 'SBRB2B',
            Duration__c = 'Custom',
            Reservation_Order_Number__c = '12342',
            Branch__c = branchLocation.Id,
            Sourcing_Branch__c = branchLocation.Id,
            
            //Number_of_Trucks__c = '2',
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
            Name ='Test Order',
            Pricebook2Id = priceBook.Id,
            Start_Date__c = system.today().addMonths(1),
            EffectiveDate = system.today().addMonths(1),
            EndDate = system.today().addMonths(3),
            Return_Date__c = system.today().addMonths(4),
            Estimated_Return_Date__c = system.today().addMonths(4),
            Earliest_Delivery_Date__c = system.today().addMonths(2),
            Reservation_Order_Number__c = '12342',
            Branch__c = branchLocation.Id,
            Sourcing_Branch__c = branchLocation.Id,
            RecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('Reservation Order').getRecordTypeId()
        );
        orderListInsert.add(order1);
       // SBR_3_0_TriggerHandler.bypass('SBR_3_0_OrderTriggerHandler');//bypass trigger
        insert orderListInsert;
        
        //Create Asset 
        Asset ast = new Asset();
        ast.Status = 'SCHEDULED FOR PICKUP';
        ast.Name = 'Test Asset';
        ast.AccountId = acct.Id;
        SBR_3_0_TriggerHandler.bypass('SBR_3_0_AssetTriggerHandler');//bypass trigger
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
                orderItem.PricebookEntryId = pbEntry[0].Id;
                orderItem.Extended_Weight_Autofill__c= 17500.0;
            } else if (i == 1) {
                orderItem.Quantity = 3;
                orderItem.PricebookEntryId = pbEntry[1].Id;
                orderItem.Extended_Weight_Autofill__c= 9000.0;
            } else {
                orderItem.Quantity = 3;
                orderItem.Misc_Charges_Type__c = 'TRANSPORTATION CHARGE';
                orderItem.Misc_Charge__c = 20.3;
                orderItem.Misc_Charges_Tax__c = 2.34;
                orderItem.Taxable__c = false;
                orderItem.Misc_Charges_Non_Taxable__c = false;
                orderItem.Misc_Charges_Item_Tax_Rate__c = 2.0;
                orderItem.PricebookEntryId = pbEntry[2].Id;
                orderItem.is_Forced_Item__c = true;
                orderItem.Extended_Weight_Autofill__c= 17500.0;
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
            res.setBody('{ "data": { "estimate": { "itemizedCharges": { "orderLines": [ { "salesItems": [ { "itemNumber": "4FPK3", "stockClass": "GRAIN", "unitPrice": 292.000, "totalPrice": 292.00, "salesTax": 20.44, "salesTaxRate": 7.0000, "quantity": 1.00 },{ "itemNumber": "1285JC", "stockClass": "MISC", "unitPrice": 292.000, "totalPrice": 292.00, "salesTax": 20.44, "salesTaxRate": 7.0000, "quantity": 3.00 } ] }, { "products": [ { "catId": "016", "classId": "0010", "rentalCost": 1289.12, "unitRentalCost": 1239.12, "quantity": 1.00, "rentalTax": 8675.24, "rentalTaxRate": 7.0000, "rppCost": 18518518.36, "unitRPPCost": 18518518.36, "rppTax": 1296296.29, "rppTaxRate": 7.0000, "isSerialized": true }, { "catId": "008", "classId": "0007", "rentalCost": 12389.12, "unitRentalCost": 1289.12, "quantity": 1.00, "rentalTax": 8675.24, "rentalTaxRate": 7.0000, "rppCost": 1818.36, "unitRPPCost": 118.36, "rppTax": 126.29, "rppTaxRate": 7.0000, "isSerialized": true } ] } ] }, "miscCharges": [ { "type": "DELIVERY", "charge": 1234.12, "tax": 7.70, "taxExempt": false, "nonTaxable": false, "itemTaxRate": 7.0000, "productSku": "' + PRODUCT_1_SKU + '"}, { "type": "FUEL CONVENIENCE CHARGE", "charge": 23.75, "tax": 1.66, "taxExempt": false, "nonTaxable": false, "itemTaxRate": 7.0000, "productSku": "' + PRODUCT_2_SKU + '" }, { "type": "PICKUP", "charge": 110.00, "tax": 7.70, "taxExempt": false, "nonTaxable": false, "itemTaxRate": 7.0000, "productSku": "' + PRODUCT_3_SKU + '" }], "taxInfo": [ { "taxRateUsed": 7.0000, "taxRateFromPC": true, "currencyCode": "USD" } ], "totals": { "rentalAmount": 2578.24, "rppCharges": 3706.72, "miscCharges": 612.53, "finalTotal": 3132.51, "salesAmount": 292.00, "salesTax": 6.02 }, "otherDetails": { "distBetweenPCandSite": 90, "unitOfDistance": "miles", "unitofCurrency": [ "USD" ] } } } }');
        }
        res.setStatusCode(200);
        return res;
    }

    private class Mock implements HttpCalloutMock {
        Boolean wasCalled = false;
        public HTTPResponse respond(HTTPRequest request) {
            wasCalled = true;
            throw new AuraHandledException('error');
        }
    }

    @isTest
    static void testUserPerms() {
        
        User adminUser = [Select Id from User Limit 1];
       
        system.runAs(adminUser){
            
        Test.startTest();
         SBQQ__Quote__c quote = [SELECT Id,Total_Rental_Amount__c,RPP_Amount__c FROM SBQQ__Quote__c Where Quote_Name__c = 'Test Quote' limit 1];
         Order order = [SELECT Id FROM Order where Quote_Name__c = 'Test Quote' limit 1];
         
            SBR_3_0_UpdateTotals.PermissionWrapper permsWrapperQuote = SBR_3_0_UpdateTotals.checkUpdateablePermission(quote.Id);
            SBR_3_0_UpdateTotals.PermissionWrapper permsWrapperOrder = SBR_3_0_UpdateTotals.checkUpdateablePermission(order.Id);
            SBR_3_0_UpdateTotals.PermissionWrapper permsWrapperNull = SBR_3_0_UpdateTotals.checkUpdateablePermission(NULL);
            //SBR_3_0_UpdateTotals.PermissionWrapper permsWrapperQuoteNegative = SBR_3_0_UpdateTotals.checkUpdateablePermission(testQuote.Id);
            //SBR_3_0_UpdateTotals.PermissionWrapper permsWrapperOrderNegative = SBR_3_0_UpdateTotals.checkUpdateablePermission(testOrder.Id);

        Test.stopTest();

        System.assertEquals(permsWrapperQuote.hasPermission, true);
        System.assertEquals(permsWrapperOrder.hasPermission, true);
        }
    }

    @isTest
    static void testUserPermsStandardUser() {
        Profile pfl = [SELECT id FROM Profile WHERE Name='Standard User'];
        
        User admin  = SBR_3_0_TestDataFactory.createUser(true, pfl);
        User standardUser = [Select Id from User where Profile.name='Standard User' Limit 1];
      
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c where Quote_Name__c = 'Test Quote' limit 1];
        
        system.runAs(standardUser){
        
        Test.startTest();
     
       
        SBR_3_0_UpdateTotals.PermissionWrapper permsWrapperQuote;
        SBR_3_0_UpdateTotals.PermissionWrapper permsWrapperOrder;
        try{
                                permsWrapperQuote = SBR_3_0_UpdateTotals.checkUpdateablePermission(quote.Id);
        }catch(Exception e){
          //  System.debug('Exception '+e);
            Assert.areEqual(e.getMessage(), 'Insufficient permissions: secure query included inaccessible field');
        }         
            
        Test.stopTest();
        
        //System.assertEquals(permsWrapperQuote.hasPermission, false);
    }
    }

    @isTest
    static void testUpdateTotalsQuotes() {
        User adminUser = [Select Id from User Limit 1];
       
        system.runAs(adminUser){

        Test.startTest();
           SBQQ__Quote__c quote = [SELECT Id, Branch__c, Branch__r.Analysis_Region_Key__c,Total_Weight__c,Delivery_Charge__c,
                                   Delivery_Charges_Override__c,Number_of_Trucks__c,SBQQ__DeliveryMethod__c,Pickup_Charges_Override__c
                                   FROM SBQQ__Quote__c 
                                   where  Quote_Name__c = 'Test Quote' 
                                   limit 1];
        
        system.debug('order Details:: '+ quote.Branch__c +' '+ quote.Branch__r.Analysis_Region_Key__c +' '+ quote.Total_Weight__c+' '+quote.Delivery_Charge__c+' '+quote.Delivery_Charges_Override__c+' '+quote.Number_of_Trucks__c); 
           Order testOrder = [SELECT Id FROM Order WHERE Quote_Name__c = 'Test Quote' LIMIT 1];
        List<Schema.Location> sourcingBranchData = [SELECT Id, Branch_Location_Number__c, Latitude_Longitude__Latitude__s, Latitude_Longitude__Longitude__s, Time_Zone_Id__c FROM Location WHERE Name = 'Test Branch Location' LIMIT 1];
            Test.setMock(HttpCalloutMock.class, new SBR_3_0_UpdateTotals_Test());
            Boolean quoteRes = SBR_3_0_UpdateTotals.updateTotals(quote.Id);
        Test.stopTest();

        System.assertEquals(quoteRes, true);
        }
    }

    @isTest
    static void testUpdateTotalsQuotesTwo() {
        User adminUser = [Select Id from User Limit 1];
        system.runAs(adminUser){
            
            Test.startTest();
                SBQQ__Quote__c quote = [SELECT Id, Branch__c, Branch__r.Analysis_Region_Key__c,Total_Weight__c,Delivery_Charge__c,
                                   Delivery_Charges_Override__c,Number_of_Trucks__c,SBQQ__DeliveryMethod__c,Pickup_Charges_Override__c
                                   FROM SBQQ__Quote__c 
                                   where  Quote_Name__c = 'Test Quote' 
                                   limit 1];
                List<Schema.Location> sourcingBranchData = [SELECT Id, Branch_Location_Number__c, Latitude_Longitude__Latitude__s, Latitude_Longitude__Longitude__s, Time_Zone_Id__c FROM Location WHERE Name = 'Test Branch Location' LIMIT 1];
                Test.setMock(HttpCalloutMock.class, new SBR_3_0_UpdateTotals_Test());
                try {
                    SBR_3_0_UpdateTotals.updateTotals(quote.Id);
                    SBR_3_0_UpdateTotals.secondEstimateAPICall(quote.Id, 334.21);
                } catch (Exception e) {
                    System.debug('Error is : ' + e.getMessage());
                }
            Test.stopTest();
        }
    }

    @isTest
    static void testUpdateTotalsQuotesThree() {
        User adminUser = [Select Id from User Limit 1];
        system.runAs(adminUser){
            
            Test.startTest();
                SBQQ__Quote__c quote = [
                    SELECT Id,Total_Weight__c,Delivery_Charge__c, Delivery_Charges_Override__c,Number_of_Trucks__c,SBQQ__DeliveryMethod__c,Pickup_Charges_Override__c
                    FROM SBQQ__Quote__c 
                    where  Quote_Name__c = 'Test Quote 3' 
                    limit 1
                ];
                List<Schema.Location> sourcingBranchData = [SELECT Id, Branch_Location_Number__c, Latitude_Longitude__Latitude__s, Latitude_Longitude__Longitude__s, Time_Zone_Id__c FROM Location WHERE Name = 'Test Branch Location' LIMIT 1];
                Test.setMock(HttpCalloutMock.class, new Mock());
                try {
                    SBR_3_0_UpdateTotals.updateTotals(quote.Id);
                } catch (AuraHandledException e) {
                    System.debug('Error is : ' + e.getMessage());
                }
            Test.stopTest();
        }
    }

    @isTest
    static void testUpdateTotalsOrder() {
        
        User adminUser = [Select Id from User Limit 1];
        system.runAs(adminUser){
        Test.startTest();
        List<OrderItem> oi = [SELECT id, Extended_Weight_Autofill__c  from OrderItem];
        for(OrderItem o : oi){
            system.debug('weight '+o.Extended_Weight_Autofill__c);
        }
        
        Order order = [SELECT Id,Branch__c, Total_Sales_Taxes__c,Branch__r.Analysis_Region_Key__c,Total_Weight__c,Delivery_Charge__c,Delivery_Charges_Override__c,Number_of_Trucks__c 
                       FROM Order 
                       Where Quote_Name__c = 'Test Quote' 
                       Limit 1];
            
        system.debug('order Details:: '+ order.Branch__c +' '+ order.Branch__r.Analysis_Region_Key__c +' '+ order.Total_Weight__c+' '+order.Delivery_Charge__c+' '+order.Delivery_Charges_Override__c+' '+order.Number_of_Trucks__c); 
        
        
            Test.setMock(HttpCalloutMock.class, new SBR_3_0_UpdateTotals_Test());
            Boolean orderRes = SBR_3_0_UpdateTotals.updateTotals(order.Id);
        Test.stopTest();
        System.assertEquals(orderRes, true);
    }
    }
    
     @isTest
    static void testUpdateTotalsSourcingBranch(){
        User adminUser = [Select Id from User Limit 1];
       
        system.runAs(adminUser){
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_UpdateTotals_Test());
        
        Test.startTest();
        List<Schema.Location> locationData = SBR_3_0_LocationDA.getLocation('720');
        Order order = [SELECT id FROM Order Where Quote_Name__c = 'Test Quote'];
        Boolean orderRes = SBR_3_0_UpdateTotals.updateTotals(order.Id,locationData[0]);
        Test.stopTest();
        System.assert(orderRes != null);
    }
    }
    
    @isTest
    static void testUpdateTotalsOrderClearTotals() {
        User adminUser = [Select Id from User Limit 1];
       
        system.runAs(adminUser){

        Test.startTest();
          Order order = [SELECT Id FROM Order where Quote_Name__c = 'Test Quote1' Limit 1];
            Test.setMock(HttpCalloutMock.class, new SBR_3_0_UpdateTotals_Test());
            Boolean orderRes = SBR_3_0_UpdateTotals.updateTotals(order.Id);
        Test.stopTest();

        System.assertEquals(orderRes, true);
    }
    }
    
    @isTest
    static void testDeliveryOptionChangeTotals() {
        User adminUser = [Select Id from User Limit 1];
        SBQQ__Quote__c quoteUpdate;
        system.runAs(adminUser){

          Test.startTest();
            SBQQ__Quote__c quote = [SELECT Id, Branch__c, Branch__r.Analysis_Region_Key__c,Total_Weight__c,Delivery_Charge__c,
                                    Delivery_Charges_Override__c,Number_of_Trucks__c,SBQQ__DeliveryMethod__c,Pickup_Charges_Override__c,IsDeliveryOptionsChanged__c
                                    FROM SBQQ__Quote__c 
                                    where  Quote_Name__c = 'Test Quote' 
                                    limit 1];
            Test.setMock(HttpCalloutMock.class, new SBR_3_0_UpdateTotals_Test());
            Boolean quoteRes = SBR_3_0_UpdateTotals.updateTotals(quote.Id);
            quoteUpdate = new SBQQ__Quote__c(Id=quote.Id,Delivery_Charges_Override__c=true,Delivery_Charges__c=20);
            update quoteUpdate;
        Test.stopTest();
        Assert.areEqual(false,quoteUpdate.IsDeliveryOptionsChanged__c,'Update Success');
            
        }
    }
}