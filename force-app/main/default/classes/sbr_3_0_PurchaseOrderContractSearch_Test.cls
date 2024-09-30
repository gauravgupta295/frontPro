@isTest


public class sbr_3_0_PurchaseOrderContractSearch_Test {
    
    @testSetup
    static void makeData(){
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
            Name = 'Test Order',
            AccountId = acct.Id,
            Jobsite__c = jobSite.Id,
            Deliverymethod__c = 'Delivery',
            Status = 'Draft',
            Pricebook2Id = priceBook.Id,
            Start_Date__c = date.valueOf('2022-10-07 12:00:00'),
            EffectiveDate = date.valueOf('2022-10-07 12:00:00'),
            EndDate = date.valueOf('2022-10-08 8:00:00'),
            Earliest_Delivery_Date__c = date.valueOf('2022-10-07 12:00:00'),
            Opt_Out_RPP__c = false,
            Opt_Out_Fuel_Charge__c = false,
            Selling_Channel__c = 'SBRB2B',
            Duration__c = 'Custom'
        );
        insert order;

        SVMXA360__SM_TA_Template__c smTaTemplate = new SVMXA360__SM_TA_Template__c();
        smTaTemplate.Name = 'SBR 3.0 Maintenance Template';
        smTaTemplate.SVMXA360__DeveloperName__c = 'SBR_3_0_Maintenance_Template';
        insert smTaTemplate;

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

        SBR_3_0_TestDataFactory.createPriceBookEntries(products);
        // Create Price Book Entry
        List<PricebookEntry> listPbe = new List<PricebookEntry>();
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
        Product2 prod =  [SELECT Id, Product_SKU__c FROM Product2 WHERE Product_Type__c = 'Cat-Class' LIMIT 1];
        
        List<OrderItem> orderItems = new List<OrderItem>();
        
        for(Integer i = 0; i < 5; i++){
            OrderItem orderItem = new OrderItem();
            orderItem.OrderId = order.Id;
            orderItem.Product2Id = prod.Id;
            orderItem.UnitPrice = 100;
            orderItem.Item_Number__c = 0;
            orderItem.PricebookEntryId = mapPBE.get(prod.Id);        
            orderItem.Hourly_Rate__c = 2.0;
            orderItem.Min_Rate__c = 2.0;
            orderItem.Quantity = 5;
            orderItem.Cost__c = 10;
            orderItem.groupID__c = '123';
            orderItem.Free_Flag__c = false;
            orderItem.Suggested_Daily_Rate__c = 2.0;
            orderItem.Suggested_Weekly_Rate__c = 2.0;
            orderItem.Suggested_Monthly_Rate__c = 2.0;
            orderItem.Selling_Price__c = 2.0;
            orderItem.Daily_Rate__c = 2.0;
            orderItem.Weekly_Rate__c = 2.0;
            orderItem.Monthly_Rate__c = 2.0;
            orderItem.Rates_Overriden__c = false;
            orderItems.add(orderItem);
        }            
        
        insert orderItems;
    }

    @isTest
    public static void testGetContract() { 
        Account acct = [SELECT Id, Name FROM Account WHERE Name = 'Test Account'];
        Order order = new Order(
			AccountId = acct.Id,
            Name = 'Test Order',
			BillingCity = 'Test City',
			Contingency_Order__c = true,
			EffectiveDate = Date.today(),
			Pricebook2Id = Test.getStandardPricebookId(),
			Status = 'Draft',
			Seasonal_Order__c = true,
			Apply_Standby_Rates__c = true,
			Shift_Pricing_Required__c = true
		);

        Test.startTest();
        insert order;
        Test.stopTest();
        List<String> fieldList = new List<String> {'Id', 'Name', 'AccountId', 'OrderNumber', 'Account.Name', 'Status'};                               
        List<Order> contractList = sbr_3_0_PurchaseOrderContractSearch.getContract(order.Id, 'Order', fieldList);
        System.assert(true, contractList.size() > 0 ); 
    }

    @isTest
    public static void testGetSearchResults() {
        Account acct = [SELECT Id, Name FROM Account WHERE Name = 'Test Account'];
        Order order = new Order(
			AccountId = acct.Id,
            Name = 'Test Order 2',
			BillingCity = 'Test City 2',
			Contingency_Order__c = true,
			EffectiveDate = Date.today(),
			Pricebook2Id = Test.getStandardPricebookId(),
			Status = 'Draft',
			Seasonal_Order__c = true,
			Apply_Standby_Rates__c = true,
			Shift_Pricing_Required__c = true
		);

        Test.startTest();
        insert order;
        Test.stopTest();

        List<Order> contractList = sbr_3_0_PurchaseOrderContractSearch.getSearchResults(order.Id, 'Test');
        System.debug('contractList: ' + contractList);
        System.assert(true, contractList.size() > 0 );
    }

    @isTest
    public static void testGetContractForFilter() {
        Account acct = [SELECT Id, Name FROM Account WHERE Name = 'Test Account'];
        List<Order> orders = new List<Order>();
        for(Integer i = 0; i < 60; i++) {
            Order order = new Order(
                AccountId = acct.Id,
                Name = 'Test Order ' + i.toString(),
                BillingCity = 'Test City ' + i.toString(),
                Contingency_Order__c = true,
                EffectiveDate = Date.today(),
                Pricebook2Id = Test.getStandardPricebookId(),
                Status = 'Draft',
                Seasonal_Order__c = true,
                Apply_Standby_Rates__c = true,
                Shift_Pricing_Required__c = true
            );
            orders.add(order);
        }
        Order orderNew = new Order(
            AccountId = acct.Id,
            Name = 'Zest Order',
            BillingCity = 'Zest City',
            Contingency_Order__c = true,
            EffectiveDate = Date.today(),
            Pricebook2Id = Test.getStandardPricebookId(),
            Status = 'Draft',
            Seasonal_Order__c = true,
            Apply_Standby_Rates__c = true,
            Shift_Pricing_Required__c = true
        );
        Test.startTest();
        insert orders;
        insert orderNew;
        Test.stopTest();

        List<Order> contractList = sbr_3_0_PurchaseOrderContractSearch.getContractForFilter(orderNew.Id, 'Order', new List<String>{'Id', 'Name', 'AccountId','OrderNumber', 'Account.Name', 'Status', 'Start_Date__c', 'EffectiveDate', 'Account.RM_Account_Number_Display__c', 'EndDate'}, '');
        Set<Id> resultIds = (new Map<Id,SObject>(contractList)).keySet();
        System.assert(true, contractList.size() > 50 );
    }

}