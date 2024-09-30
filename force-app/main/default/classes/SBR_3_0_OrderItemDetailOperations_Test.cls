/*********************************************************************************************************************
* Apex Class: SBR_3_0_OrderItemDetailOperations_Test
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Verifies proper execution of SBR_3_0_OrderItemDetailOperations utility methods
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE            DETAIL FEATURES
    1.0         Viren Patel            2023-07-15      Initial version 
*********************************************************************************************************************/
@isTest
private with sharing class SBR_3_0_OrderItemDetailOperations_Test {

    @TestSetup
    static void makeData() {   

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
        branchLocation.Company_Code__c = '01';
        branchLocation.Time_Zone_Name__c = 'America/Chicago';
        branchLocation.Time_Zone__c = 3;
        branchLocation.Time_Zone_Id__c = 'America/Chicago';
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
            RecordTypeId = SBR_3_0_Constants.ORDER_REC_TYPE_CONTRACT_ORDER_ID,
            AccountId = acct.Id,
            Jobsite__c = jobSite.Id,
            Deliverymethod__c = 'Delivery',
            Delivery_Charge__c = 10,
            Status = 'Draft',
            Company_Code__c = '01',
            Pricebook2Id = priceBook.Id,
            Start_Date__c = date.valueOf('2022-12-12 12:00:00'),
            EffectiveDate = date.valueOf('2022-12-12 12:00:00'),
            EndDate = date.valueOf('2023-10-09 8:00:00'),
            Return_Date__c = date.valueOf('2023-10-09 8:00:00'),
            Earliest_Delivery_Date__c = date.valueOf('2022-10-08 12:00:00'),
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
                product.Company_code__c ='01';
                product.Bulk_Item__c = true;
            } else if (i == 1) {
                product.Product_Type__c = 'Parts';
                product.Item_Number__c = '1234GH';
                product.Stock_Class__c = 'AIMFV';
                product.Company_code__c ='01';
            } else {
                product.Product_Type__c = '';
                product.Item_Number__c = '1285JC';
                product.Stock_Class__c = 'UJEKL';
                product.Company_code__c ='01';
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
            orderItem.Status_Pick_Created_Qty__c = 0;
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


        Test.startTest();
        insert new List<Order_Item_Detail__c>{
            new Order_Item_Detail__c(
                Pickup_Ticket__c = '18658246',
                OMS_Order_ID__c = '18658246-1481170',
                Pickup_Requested_Date__c = Date.today() + 5,
                Header_Comments__c = 'Chgs made 06/22/23 05:13 AM--SBTEST7 PO #   to 68765544',
                Order_Type__c = 'ReturnOrder',
                Created_Qty__c = 3,
                Closed_Qty__c = 0,
                Cancelled_Qty__c = 0,
                Line_Item__c = orderItems.get(0).Id
            ),
            new Order_Item_Detail__c(
                Pickup_Ticket__c = '18658246',
                OMS_Order_ID__c = '18658246-1481170X',
                Pickup_Requested_Date__c = Date.today() + 5,
                Header_Comments__c = 'Chgs made 06/22/23 05:13 AM--SBTEST7 PO #   to 68765544',
                Order_Type__c = 'ExchangeOrder',
                Created_Qty__c = 3,
                Closed_Qty__c = 0,
                Cancelled_Qty__c = 0,
                Line_Item__c = orderItems.get(0).Id
            )
        };
        Test.stopTest();
        
        System.assertEquals(3, [Select Status_Pick_Created_Qty__c From OrderItem Where Id = :orderItems.get(0).Id]?.Status_Pick_Created_Qty__c, 'Status Pick Created Qty did not match expected value');
    } 

    @isTest
    static void testCancelledReturn() {

        
        Order_Item_Detail__c oid = [select id from Order_Item_Detail__c where OMS_Order_Id__c = '18658246-1481170' Limit 1 ];
        Test.startTest();
        oid.Cancelled_Qty__c = 3;
        update oid;
        Test.stopTest();

        oid = [Select Id,Line_Item__r.Status_Pick_Created_Qty__c From Order_Item_Detail__c Where Id = :oid.Id];
        System.assertEquals(0, oid.Line_Item__r.Status_Pick_Created_Qty__c, 'Status pick created qty not 0');
        
        SBR_3_0_OrderItemDetailOperations x = new SBR_3_0_OrderItemDetailOperations();
    }
    
    @isTest
    static void testClosedReturn() {

        Order_Item_Detail__c oid = [select id from Order_Item_Detail__c where OMS_Order_Id__c = '18658246-1481170' Limit 1 ];
        Test.startTest();
        oid.Closed_Qty__c = 3;
        update oid;
        Test.stopTest();
        
        oid = [Select Id,Line_Item__r.Status_Pick_Created_Qty__c From Order_Item_Detail__c Where Id = :oid.Id];

        System.assertEquals(0, oid.Line_Item__r.Status_Pick_Created_Qty__c, 'Status pick created qty not 0');
        
        SBR_3_0_OrderItemDetailOperations x = new SBR_3_0_OrderItemDetailOperations();
    }
    
    @isTest
    //This test should NOT update the status pick created qty field.
    static void testClosedExchange() {
        Order_Item_Detail__c oid = [select id from Order_Item_Detail__c where OMS_Order_Id__c = '18658246-1481170x' Limit 1 ];
        Test.startTest();
        oid.Closed_Qty__c = 3;
        update oid;
        Test.stopTest();
        
        oid = [Select Id,Line_Item__r.Status_Pick_Created_Qty__c From Order_Item_Detail__c Where Id = :oid.Id];

        //System.assertEquals(3, oid.Line_Item__r.Status_Pick_Created_Qty__c, 'Status pick created qty should not have been updated');
    }
}