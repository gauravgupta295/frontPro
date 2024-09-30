@isTest
private class SBR_3_0_AccessController_Test {
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
        insert orderItems;
      }
    } 

    @isTest
    static void hasEditAccessTest() {

        Test.startTest();
        List<Order> orderList = [Select Id from Order Limit 1];
        Boolean hasAccess = SBR_3_0_AccessController.hasEditAccess(orderList[0].Id);
        System.assertEquals(true, hasAccess , 'Record is Not accessible ');

        Test.stopTest();
    }
}