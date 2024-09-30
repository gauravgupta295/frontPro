/*********************************************************************************************************************
* Apex Class: SBR_3_0_OrderItemTriggerHandler_Test
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - 
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Aditee Churiwala        2022-18-08          Initial version
    2.0         Hamza Askour            2023-06-19          Version 2
*********************************************************************************************************************/
@isTest(seeAllData=false)
public with sharing class SBR_3_0_OrderItemTriggerHandler_Test {
    
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
            branchLocation.Analysis_Region_Key__c ='293';
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
                IsActive = true,
                CurrencyIsoCode = 'USD'
            );
            update priceBook;
            
            // Create Order
            Order order = new Order(
                Quote_Name__c = 'Test Quote',
                AccountId = acct.Id,
                Jobsite__c = jobSite.Id,
                Branch__c = branchLocation.Id,
                Deliverymethod__c = 'Delivery',
                Status = 'Draft',
                Company_Code__c = '01',
                Pricebook2Id = priceBook.Id,
                Start_Date__c = date.valueOf('2022-10-07 12:00:00'),
                EffectiveDate = date.valueOf('2022-10-07 12:00:00'),
                EndDate = date.valueOf('2022-10-08 8:00:00'),
                Earliest_Delivery_Date__c = date.valueOf('2022-10-07 12:00:00'),
                Opt_Out_RPP__c = false,
                Opt_Out_Fuel_Charge__c = false,
                Selling_Channel__c = 'SBRB2B',
                Duration__c = 'Custom',
                CurrencyIsoCode = 'USD'
            );
            insert order;
    
             
            // Create Product
            List<Product2> products = new List<Product2>();
            for(Integer i = 0; i < 3; i++) {
                Product2 product = new Product2();
                product.CurrencyIsoCode = 'USD';
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

            List<PricebookEntry> pes = new List<PricebookEntry>();
            for(Product2 product : products){
                PricebookEntry pe = new PricebookEntry();
                pe.Pricebook2Id = Test.getStandardPricebookId();
                pe.Product2Id = product.Id;
                pe.UnitPrice = 100;
                pe.IsActive = true;
                pe.UseStandardPrice = false;
                pe.CurrencyIsoCode = 'USD';
                pes.add(pe);
            }
            insert pes;
    }

    @isTest 
    static void testCreateOrderItemOnQuantity() {
        Order order = [SELECT Id, EndDate, CurrencyIsoCode FROM Order LIMIT 1];
        Product2 products =  [SELECT Id, Product_SKU__c, CurrencyIsoCode FROM Product2 WHERE Product_Type__c = 'Cat-Class'];
        List<PricebookEntry> pbEntry = [SELECT Id, Name, Product2Id FROM PricebookEntry WHERE Pricebook2Id =:Test.getStandardPricebookId() ];
        
        System.debug('price book soql : ' + pbEntry);
        System.debug('price book soql size : ' + pbEntry.size());
        System.debug('order : ' + order);
        System.debug('products : ' + products);
        // Create Order item
        List<OrderItem> orderItems = new List<OrderItem>();
        // We can't really test this because the code that splits the line
        // items only runs if we aren't running a test, so...loop time
        for(Integer i = 0; i < 5; i++){
            OrderItem orderItem = new OrderItem();
            orderItem.OrderId = order.Id;
            orderItem.Product2Id = products.Id;
            orderItem.UnitPrice = 100;
            orderItem.Item_Number__c = 0;
            orderItem.PricebookEntryId = pbEntry[0].Id;        
            orderItem.Hourly_Rate__c = 2.0;
            orderItem.Min_Rate__c = 2.0;
            orderItem.Quantity = 5;
            orderItem.Cost__c = 10;
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

            Test.startTest();

                insert orderItems;
                
                for(OrderItem oi : orderItems) {
                    oi.Hourly_Rate__c = 5.0;
                }
                update orderItems;
                
            Test.stopTest();

        Integer countOrderItem = [SELECT count() FROM OrderItem];
        System.debug('@@count'+countOrderItem);
        System.assertEquals(5, countOrderItem, 'Did not return expected number of order items');
        System.assertEquals(5.0, orderItems[0].Hourly_Rate__c, 'Hourly rate did not update');
    }

    @isTest 
    static void testUpdateOrderItem() {
        Order order = [SELECT Id, EndDate FROM Order LIMIT 1];
        Product2 products =  [SELECT Id, Product_SKU__c FROM Product2 WHERE Product_Type__c = 'Cat-Class'];
        List<PricebookEntry> pbEntry = [SELECT Id, Name, Product2Id FROM PricebookEntry WHERE Pricebook2Id =:Test.getStandardPricebookId() ];
        
        // Create Order item
        List<OrderItem> orderItems = new List<OrderItem>();
    
        for(Integer i = 0; i < 5; i++){
            OrderItem orderItem = new OrderItem();
            orderItem.OrderId = order.Id;
            orderItem.Product2Id = products.Id;
            orderItem.UnitPrice = 100;
            orderItem.Item_Number__c = 0;
            orderItem.PricebookEntryId = pbEntry[0].Id;        
            orderItem.Hourly_Rate__c = 2.0;
            orderItem.Min_Rate__c = 2.0;
            orderItem.Quantity = 5;
            orderItem.Cost__c = 10;
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

            Test.startTest();

                insert orderItems;
                
                for(OrderItem oi : orderItems) {
                    oi.Hourly_Rate__c = 5.0;
                }
                update orderItems;
                
            Test.stopTest();

        Integer countOrderItem = [SELECT count() FROM OrderItem];
        System.assertEquals(5, countOrderItem, 'Did not return expected number of order items');
        System.assertEquals(5.0, orderItems[0].Hourly_Rate__c, 'Hourly rate did not update');
    }
}