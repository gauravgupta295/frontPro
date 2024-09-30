/**
 * @description Test class for SBR_3_0_OrderOperations
 */
@isTest
private class SBR_3_0_OrderOperations_Test {

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
        region.Analysis_Region_Key__c = '921';
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
        jobLocation.Analysis_Region_Key__c = '921';
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
        branchLocation.Analysis_Region_Key__c = '921';
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
            Status = 'Draft',
            Pricebook2Id = priceBook.Id,
            Start_Date__c = date.valueOf('2022-10-07 12:00:00'),
            EffectiveDate = date.valueOf('2022-10-07 12:00:00'),
            EndDate = date.valueOf('2022-10-08 8:00:00'),
            Earliest_Delivery_Date__c = date.valueOf('2022-09-06 12:00:00'),
            Opt_Out_RPP__c = false,
            Opt_Out_Fuel_Charge__c = false,
            Selling_Channel__c = 'SBRB2B',
            Using_3rd_Party__c = false,
            Order_Initiating_Channel__c = 'SF',
            Delivery_Charges_Override__c = false,
            Pickup_Charges_Override__c = false,
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
    static void testUpdateEndDate(){
        Account acct = [SELECT Id, Name FROM Account WHERE Name = 'Test Account'];
        Id recordType = [SELECT Id FROM RecordType WHERE DeveloperName = 'Reservation_Order' LIMIT 1].Id;

        List<Order> testOrders = new List<Order>();
        Order orderOne = new Order(
            AccountId = acct.Id,
            Contingency_Order__c = true,
            EffectiveDate = Date.today(),
            Pricebook2Id = Test.getStandardPricebookId(),
            Status = 'Draft',
            Start_Date__c = Datetime.now(),
            Duration__c = 'Custom',
            RecordTypeId = recordType,
            Submitted_to_Wynne__c = true,
            Total_Est_Duration_weeks__c = 1,
            Deliverymethod__c = 'Delivery',
            //Estimated_Return_Date__c = Datetime.now().addDays(14),
            Name = 'test'
        );

        Order orderTwo = new Order(
            AccountId = acct.Id,
            Contingency_Order__c = true,
            EffectiveDate = Date.today(),
            Pricebook2Id = Test.getStandardPricebookId(),
            Status = 'Draft',
            Start_Date__c = Datetime.now(),
            Duration__c = 'Day',
            RecordTypeId = recordType,
            Submitted_to_Wynne__c = true,
            Total_Est_Duration_weeks__c = 1,
            Deliverymethod__c = 'Delivery',
            //Estimated_Return_Date__c = Datetime.now().addDays(14),
            Name = 'testTwo'
        );

        Order orderThree = new Order(
            AccountId = acct.Id,
            Contingency_Order__c = true,
            EffectiveDate = Date.today(),
            Pricebook2Id = Test.getStandardPricebookId(),
            Status = 'Draft',
            Start_Date__c = Datetime.now(),
            Duration__c = 'Week',
            RecordTypeId = recordType,
            Submitted_to_Wynne__c = true,
            Total_Est_Duration_weeks__c = 1,
            Deliverymethod__c = 'Delivery',
            //Estimated_Return_Date__c = Datetime.now().addDays(14),
            Name = 'testThree'
        );

        Order orderFour = new Order(
            AccountId = acct.Id,
            Contingency_Order__c = true,
            EffectiveDate = Date.today(),
            Pricebook2Id = Test.getStandardPricebookId(),
            Status = 'Draft',
            Start_Date__c = Datetime.now(),
            Duration__c = '4 Week',
            RecordTypeId = recordType,
            Submitted_to_Wynne__c = true,
            Total_Est_Duration_weeks__c = 1,
            Deliverymethod__c = 'Delivery',
            //Estimated_Return_Date__c = Datetime.now().addDays(14),
            Name = 'testFour'
        );
        testOrders.add(orderOne);
        testOrders.add(orderTwo);
        testOrders.add(orderThree);
        testOrders.add(orderFour);
        insert testOrders;
        //SBR_3_0_OrderOperations.updateEndDate(testOrders);

        orderOne = [SELECT Start_Date__c, Estimated_Return_Date__c FROM Order WHERE Name = 'test'];
        Assert.areNotEqual(null, order.Estimated_Return_Date__c, 'Estimated Return Date updated for order with Custom Duration');

        SBR_3_0_OrderOperations.updatePickUpOverride(testOrders);
        orderOne = [SELECT Pickup_Charges_Override__c,Delivery_Charges_Override__c FROM Order WHERE Name = 'test'];
        Assert.areEqual(orderOne.Pickup_Charges_Override__c,orderOne.Delivery_Charges_Override__c, 'Pickup and Delivery Override are Equal');
        orderOne.Status='Open';
        update orderOne;
   }

    @isTest
    static void updateOrderStartDateTest() {
        Order preTestOrder = [SELECT Id, Start_Date__c FROM Order Limit 1];
        preTestOrder.Start_Date__c = preTestOrder.Start_Date__c.addDays(1);
        Test.startTest();
        update preTestOrder;
        Order postTestOrder = [SELECT Id, Start_Date__c, EffectiveDate FROM Order WHERE Id =: preTestOrder.Id];
        Test.stopTest();
        Assert.areEqual(postTestOrder.Start_Date__c.date(), postTestOrder.EffectiveDate, 'Start Date and Effective Date Matches ');
    }
    
    @isTest
    static void testDeliveryCharges(){
        Account acct = [Select Id From Account];
        
        Id recordType = [SELECT Id FROM RecordType WHERE DeveloperName = 'Reservation_Order' LIMIT 1].Id;
        
        Id branchId = [Select Id From Location Where Name = 'Test Branch Location' LIMIT 1].Id;
        
        Order o = new Order(
            AccountId = acct.Id,
            Contingency_Order__c = true,
            EffectiveDate = Date.today(),
            Pricebook2Id = Test.getStandardPricebookId(),
            Status = 'Draft',
            Start_Date__c = Datetime.now(),
            Duration__c = 'Week',
            RecordTypeId = recordType,
            Submitted_to_Wynne__c = false,
            Total_Est_Duration_weeks__c = 1,
            Deliverymethod__c = 'Delivery',
            Using_3rd_Party__c = false,
            Delivery_Charges_Override__c = false,
            Pickup_Charges_Override__c = false,
            Order_Initiating_Channel__c = 'SF', 
            Name = 'testThree',
            Branch__c = branchId
        );
        
        insert o;
        
        Test.startTest();
        o.Delivery_Charges_Override__c = true;
        update o;
        Test.stopTest();
        
        o = [Select Pickup_Charges_Override__c From Order Where Id = :o.Id];
        System.assertEquals(true, o.Pickup_Charges_Override__c, 'Pickup charges override did not match excepted value');
    }
    
    @isTest
    static void testFulfillmentCharges(){
        Account acct = [Select Id From Account];
        
        Id recordType = [SELECT Id FROM RecordType WHERE DeveloperName = 'Reservation_Order' LIMIT 1].Id;
        
        Schema.Location branch = [Select Id,Analysis_Region_Key__c From Location Where Name = 'Test Branch Location' LIMIT 1];
        branch.Analysis_Region_Key__c = '101';
        update branch;
        
        Order o = new Order(
            AccountId = acct.Id,
            Contingency_Order__c = true,
            EffectiveDate = Date.today(),
            Pricebook2Id = Test.getStandardPricebookId(),
            Status = 'Draft',
            Start_Date__c = Datetime.now(),
            Duration__c = 'Week',
            RecordTypeId = recordType,
            Submitted_to_Wynne__c = false,
            Total_Est_Duration_weeks__c = 1,
            Deliverymethod__c = SBR_3_0_Constants.FULFILLMENT_TYPE_DELIVERY,
            Using_3rd_Party__c = false,
            Delivery_Charges_Override__c = false,
            Pickup_Charges_Override__c = false,
            Order_Initiating_Channel__c = 'SF', 
            Name = 'testThree',
            Branch__c = branch.Id,
            Delivery_Charges__c = 4,
            Pickup_Charges__c = 4,
            Delivery_Charge__c = 1,
            Pickup_Charge__c = 1
        );
        
        insert o;
        
        Test.startTest();
        o.Delivery_Charges_Override__c = true;
        o.Pickup_Charges_Override__c = true;
        o.Delivery_Charges__c = 5;
        o.Pickup_Charges__c = 5;
        o.Using_3rd_Party__c = true;
        update o;
        Test.stopTest();
        
        o = [Select Delivery_Charge__c, Pickup_Charge__c From Order Where Id = :o.Id];
        System.assertEquals(5, o.Delivery_Charge__c, 'Delivery charge did not match excepted value');
        System.assertEquals(5, o.Pickup_Charge__c, 'Pickup charge did not match excepted value');
    }
}