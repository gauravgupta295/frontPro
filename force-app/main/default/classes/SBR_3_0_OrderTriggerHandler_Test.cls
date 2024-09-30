/*********************************************************************************************************************
* Apex Class: SBR_3_0_OrderTriggerHandler_Test
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - 
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Joelle Ramiandrisoa    2022-18-08             Initial version
    2.0         Kaylee Gabus           2022-12-05             Added UpdateEndDate Tests
*********************************************************************************************************************/
@isTest(seeAllData=false)
public with sharing class SBR_3_0_OrderTriggerHandler_Test {

    static Boolean SUCCESSTEST = true;
    @TestSetup
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
                product.isSerialized = true;
            } else if (i == 1) {
                product.Product_Type__c = 'Parts';
                product.Item_Number__c = '1234GH';
                product.Stock_Class__c = 'AIMFV';
                product.isSerialized = true;
            } else {
                product.Product_Type__c = '';
                product.Item_Number__c = '1285JC';
                product.Stock_Class__c = 'UJEKL';
            }
            products.add(product);
        }

        insert products;
    }

    @isTest 
    static void testPopulatePricebook() {
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

        Order o = [SELECT Id, Pricebook2Id, BillingCity FROM Order WHERE BillingCity = 'Test City'];
        Assert.areEqual('01s5e0000096ktSAAQ', o.Pricebook2Id);
    }

    @IsTest
    static void testUpdateEndDate() {
        Account acct = [SELECT Id, Name FROM Account WHERE Name = 'Test Account'];
        Id recordType = [SELECT Id FROM RecordType WHERE DeveloperName = 'Reservation_Order' LIMIT 1].Id;

        Order order = new Order(
            AccountId = acct.Id,
            Name = 'Test Order',
            Contingency_Order__c = true,
            EffectiveDate = Date.today(),
            Pricebook2Id = Test.getStandardPricebookId(),
            Status = 'Draft',
            Start_Date__c = Datetime.now(),
            Duration__c = 'Day',
            RecordTypeId = recordType,
            Total_Est_Duration_weeks__c = 2,
            Estimated_Return_Date__c = Datetime.now().addDays(14)
        );

        Test.startTest();
            insert order;
        Test.stopTest();

        order = [SELECT Start_Date__c, Return_Date__c FROM Order WHERE Id = :order.Id];
        Assert.areEqual(order.Start_Date__c.addDays(1), order.Return_Date__c, 'Estimated Return Date not updated properly');
    }

    @IsTest
    static void testIsDeliveryOptionsChanged() {
        Account acct = [SELECT Id, Name FROM Account WHERE Name = 'Test Account'];
        Id recordType = [SELECT Id FROM RecordType WHERE DeveloperName = 'Reservation_Order' LIMIT 1].Id;

        Order order = new Order(
            AccountId = acct.Id,
            Name = 'Test Order',
            Contingency_Order__c = true,
            EffectiveDate = Date.today(),
            Pricebook2Id = Test.getStandardPricebookId(),
            Status = 'Draft',
            Start_Date__c = Datetime.now(),
            Duration__c = 'Custom',
            RecordTypeId = recordType,
            Submitted_to_Wynne__c = true, 
            Estimated_Return_Date__c = Datetime.now().addDays(14)
        );
        insert order;

        Test.startTest();
            order.Deliverymethod__c = 'Delivery';
            order.Pickup_Charges__c = 50;
            order.Delivery_Charges__c = 50;
            order.Delivery_Charges_Override__c = true;
            update order;
        Test.stopTest();

        order = [SELECT IsDeliveryOptionsChanged__c FROM Order WHERE Id = :order.Id];
        Assert.areEqual(true, order.IsDeliveryOptionsChanged__c, 'Delivery Option is not changed');
    }

    @IsTest
    static void testUpdateEndDate_CustomDuration() {
        Account acct = [SELECT Id, Name FROM Account WHERE Name = 'Test Account'];
        Id recordType = [SELECT Id FROM RecordType WHERE DeveloperName = 'Reservation_Order' LIMIT 1].Id;

        Order order = new Order(
            AccountId = acct.Id,
            Name = 'Test Order',
            Contingency_Order__c = true,
            EffectiveDate = Date.today(),
            Pricebook2Id = Test.getStandardPricebookId(),
            Status = 'Draft',
            Start_Date__c = Datetime.now(),
            Duration__c = 'Custom',
            RecordTypeId = recordType,
            Submitted_to_Wynne__c = true, 
            Estimated_Return_Date__c = Datetime.now().addDays(14)
        );
        insert order;

        Test.startTest();
            update order;
        Test.stopTest();

        order = [SELECT Start_Date__c, Estimated_Return_Date__c FROM Order WHERE Id = :order.Id];
        Assert.areEqual(order.Start_Date__c.addDays(14), order.Estimated_Return_Date__c, 'Estimated Return Date updated for order with Custom Duration');
    }
}