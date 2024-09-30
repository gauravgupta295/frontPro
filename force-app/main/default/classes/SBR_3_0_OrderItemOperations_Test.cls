/**
 * @description       : Test Class for SBR_3_0_OrderItemOperations class
 * @author            : Hashem Abdul
 * @group             : 
 * @last modified on  : 02-02-2024
 * @last modified by  : Hashem Abdul
**/
@isTest
private class SBR_3_0_OrderItemOperations_Test {
    @TestSetup
    static void makeData() {
        try{
            Profile pfl = [SELECT id FROM Profile WHERE Name='System Administrator'];
            User admin = SBR_3_0_TestDataFactory.createUser(true, pfl);
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
            acct.Phone = '1234567891';
            acct.Record_Type_Text__c = 'Credit';
            acct.E_mail_Address__c = '123@asdf.com';
            acct.BillingStreet = '123 Main Street';
            acct.BillingCity = 'Toronto';
            acct.BillingPostalCode = 'M9N7V5';
            acct.BillingState = 'ON';
            acct.BillingCountry = 'CA';
            acct.Drivers_License__c = 'AKF';
            acct.Driver_s_License_State__c = 'AL';
            insert acct;
            
            Contact contact = SBR_3_0_TestDataFactory.createContacts(1, acct.Id, true)[0];
            
            // Create Analysis Region
            Analysis_Region__c region = new Analysis_Region__c();
            region.Analysis_Region_Key__c = '933';
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
            jobLocation.Analysis_Region_Key__c = '933';
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
            branchLocation.Job_Number__c = '332112';
            branchLocation.RecordTypeId = SBR_3_0_Constants.LOCATION_BRANCH_RT_ID;
            branchLocation.Company_Code__c = 'X';
            branchLocation.Time_Zone_Name__c = 'America/Chicago';
            branchLocation.Time_Zone__c = 3;
            branchLocation.Time_Zone_Id__c = '121212';
            branchLocation.Analysis_Region_Key__c = '933';
            insert branchLocation;
            
            // Create Job Site
            AssociatedLocation jobSite = new AssociatedLocation(Name__c = 'Test Job Site', ParentRecordId = acct.Id, LocationId = jobLocation.Id, Branch__c = branchLocation.Id, Job_Number__c = '20221004A');
            insert jobSite;
            
            // Create Quote
            SBQQ__Quote__c quote = new SBQQ__Quote__c(
                Quote_Name__c = 'Test Quote',
                SBQQ__Account__c = acct.Id,
                Jobsite__c = jobSite.Id,
                SBQQ__DeliveryMethod__c = 'Delivery',
                Start_Date__c = date.valueOf('2022-10-07 12:00:00'),
                End_Date__c = date.valueOf('2022-10-07 12:00:00'),
                Delivery_Date__c  = date.valueOf('2022-10-08 12:00:00'),
                Opt_Out_RPP__c = false,
                Opt_Out_Fuel_Charge__c = false,
                Selling_Channel__c = 'SBRB2B',
                Rentalman_Quote_Id__c = 'Test QId',
                Company_Code__c = '01',
                Show_Crew_Expense_Calculator__c = true,
                Branch__c = branchLocation.Id
            );
            insert quote; 
            
            
            // Create Price Book
            Pricebook2 priceBook = new Pricebook2(Id = Test.getStandardPricebookId(), IsActive = true, CurrencyIsoCode = 'USD');
            update priceBook;
            
            // Create Order
            Order order = new Order(Quote_Name__c = 'Test Quote', Rentalman_Quote_Id__c = '111111', ORder_By__c = contact.Id, AccountId = acct.Id, Jobsite__c = jobSite.Id, branch__c = branchLocation.id, Deliverymethod__c = 'Delivery', Status = 'Draft', Pricebook2Id = priceBook.Id, Start_Date__c = date.valueOf('2022-10-07 12:00:00'), EffectiveDate = date.valueOf('2022-10-07 12:00:00'), EndDate = date.valueOf('2022-10-08 8:00:00'), Earliest_Delivery_Date__c = date.valueOf('2022-09-06 12:00:00'), Opt_Out_RPP__c = false, Opt_Out_Fuel_Charge__c = false, Selling_Channel__c = 'SBRB2B', Duration__c = 'Custom', CurrencyIsoCode = 'USD');
            insert order;
            





            // Create Product
            List<Product2> products = new List<Product2>();
            for (Integer i = 0; i < 5; i++) {
                Product2 product = new Product2();
                product.Name = 'Test Product ' + i;
                if (i == 0) {
                    product.Product_Type__c = 'Cat-Class';
                    product.Product_SKU__c = '123456';
                    product.Category__c = '32134';
                    product.Class__c = '2039';
                    product.ToolFlex__c = 'N';
                    product.isSerialized = true;
                    product.Stock_class__c = '';
                    product.Bulk_Item__c = false;
                    product.Status__c = 'A';
                } else if (i == 1) {
                    product.Product_Type__c = 'Parts';
                    product.Item_Number__c = '1234GH';
                    product.Stock_Class__c = 'AIMFV';
                    product.isSerialized = true;
                    product.Inventoried_Item__c=true;
                } else if (i == 2) {
                    product.Name = 'Not Fuel Plan';
                    product.Product_SKU__c = '234567';
                    product.Category__c = '32138';
                    product.Class__c = '2038';
                    product.Stock_class__c = '';
                    product.Bulk_Item__c = false;
                    product.Status__c = 'A';
                }else if (i == 3) {
                    product.Name='Fuel Convenience Charge';
                    product.Product_Type__c = 'Parts';
                    product.Item_Number__c = '4321GH';
                    product.Stock_Class__c = 'Fuel';
                    //product.isSerialized = true;
                }
                else {
                    product.Product_Type__c = '';
                    product.Item_Number__c = '1285JC';
                    product.Stock_Class__c = 'UJEKL';
                }
                products.add(product);
            }
            insert products;
            
            List<PricebookEntry> pbEntries = new List<PricebookEntry>();
            for (Product2 prod : products) {
                PricebookEntry stdPbe = new PricebookEntry();
                stdPbe.CurrencyIsoCode = 'USD';
                stdPbe.Pricebook2Id = Test.getStandardPricebookId();
                stdPbe.Product2Id = prod.Id;
                stdPbe.IsActive = true;
                stdPbe.UnitPrice = 20;
                pbEntries.add(stdPbe);
            }
            
            insert pbEntries;
            
           List<OrderItem> orderItems = new List<OrderItem>();
                // Create Order item
                OrderItem orderItem = new OrderItem();
                orderItem.OrderId = order.Id;
                // orderItem.groupID__c = 'Test';
                orderItem.Product2Id = products[0].Id;
                orderItem.UnitPrice = 100;
                orderItem.Item_Number__c = 0;
                orderItem.PricebookEntryId = pbEntries[0].Id;
                orderItem.Hourly_Rate__c = 2.0;
                orderItem.Min_Rate__c = 0;
                orderItem.Quantity = 5;
                orderItem.Free_Flag__c = false;
                orderItem.Suggested_Daily_Rate__c = 2.0;
                orderItem.Suggested_Weekly_Rate__c = 2.0;
                orderItem.Suggested_Monthly_Rate__c = 2.0;
                orderItem.Apply_Standby_Rates__c = true;
                orderItem.Contingency_Cost__c = 1;
                orderItem.Line_Item_Notes__c = 'Test';
                orderItem.Seasonal_Multiplier__c = 12;
                orderItem.Shift_Differential__c = 'D';
                
                orderItem.Daily_Rate__c = 2.0;
                orderItem.Weekly_Rate__c = 4.0;
                orderItem.Monthly_Rate__c = 6.0;
                orderItem.Rates_Overriden__c = false;
        

                OrderItem orderItemOne = new OrderItem();
                orderItemOne.OrderId = order.Id;
                orderItemOne.Fuel_Plan__c = true;
                orderItemOne.Product2Id = products[2].Id;
                orderItemOne.UnitPrice = 100;
                orderItemOne.Item_Number__c = 0;
                orderItemOne.PricebookEntryId = pbEntries[2].Id;
                orderItemOne.Hourly_Rate__c = 2.0;
                orderItemOne.Min_Rate__c = 0;
                orderItemOne.Quantity = 5;
                orderItemOne.Free_Flag__c = false;
                orderItemOne.Suggested_Daily_Rate__c = 2.0;
                orderItemOne.Suggested_Weekly_Rate__c = 2.0;
                orderItemOne.Suggested_Monthly_Rate__c = 2.0;
                orderItemOne.Daily_Rate__c = 2.0;
                orderItemOne.Weekly_Rate__c = 40.0;
                orderItemOne.Monthly_Rate__c = 6.0;
                orderItemOne.Rates_Overriden__c = false;
                orderItemOne.Specific_Pricing_Type__c = SBR_3_0_Constants.CUSTOMER_LOADED_SPECIFIC_PRICING_TYPE;
                
    
                OrderItem orderItemTwo = new OrderItem();
                orderItemTwo.OrderId = order.Id;
                orderItemTwo.Product2Id = products[3].Id;
                orderItemTwo.UnitPrice = 100;
                orderItemTwo.Item_Number__c = 0;
                orderItemTwo.PricebookEntryId = pbEntries[3].Id;
                orderItemTwo.Hourly_Rate__c = 2.0;
                orderItemTwo.Min_Rate__c = 0;
                orderItemTwo.Quantity = 5;
                orderItemTwo.Free_Flag__c = false;
                orderItemTwo.Suggested_Daily_Rate__c = 2.0;
                orderItemTwo.Suggested_Weekly_Rate__c = 2.0;
                orderItemTwo.Suggested_Monthly_Rate__c = 2.0;
                orderItemTwo.Daily_Rate__c = 2.0;
                orderItemTwo.Weekly_Rate__c = 40.0;
                orderItemTwo.Monthly_Rate__c = 6.0;
                orderItemTwo.Rates_Overriden__c = false;
                orderItemTwo.Kit_Number_This_Item_Belongs_To__c ='234567';
                orderItemTwo.Specific_Pricing_Type__c = SBR_3_0_Constants.CUSTOMER_LOADED_SPECIFIC_PRICING_TYPE;

                orderItems.add(orderItem);
                orderItems.add(orderItemOne);
                orderItems.add(orderItemTwo);
                insert orderItems;

        }catch(Exception ex){
            SBR_3_0_Log.logException(ex);
        }
    }
    
    @isTest
    static void updateOrderlineWithMinRate() {
        
        try{
            Test.startTest();
            Order order = [SELECT Id, EndDate, Rentalman_Quote_Id__c FROM Order];
            order.Rentalman_Quote_Id__c = '';
            update order;
            Product2 products = [SELECT Id FROM Product2];
            PricebookEntry pbEntry = [SELECT Id, Product2Id FROM PricebookEntry WHERE Pricebook2Id = :Test.getStandardPricebookId() AND Product2Id = :products.Id LIMIT 1];
            
            // Create Order item
             List<OrderItem> orderItems  =[select id,Product2Id,Monthly_Rate__c from orderItem where  Product2Id=:products.Id];
            
            Test.stopTest();
            List<orderItem> postOrderItems = [SELECT Id, Min_Rate__c FROM OrderItem];
            System.assertEquals(orderItems[0].Monthly_Rate__c, postOrderItems[0].Min_Rate__c, 'The minimum rate did not match the monthly rate for scaffold');
        }catch(Exception ex){
            SBR_3_0_Log.logException(ex);
        }
    }
    @isTest
    static void assignPBEntriesForOrderLineItems() {
        
        try {
            Order order = [SELECT Id, EndDate FROM Order];
            List<Product2> products = [SELECT Id FROM Product2];
            PricebookEntry pbEntry = [SELECT Id, Product2Id FROM PricebookEntry WHERE Pricebook2Id = :Test.getStandardPricebookId() AND Product2Id = :products[0].Id LIMIT 1];
            
            system.debug('priceBook::' + pbEntry);
            List<OrderItem> orderItems = new List<OrderItem>();
            OrderItem orderItem = new OrderItem();
            orderItem.OrderId = order.Id;
            orderItem.groupID__c = 'Test';
            orderItem.Product2Id = products[0].Id;
            orderItem.UnitPrice = 100;
            orderItem.Item_Number__c = 0;
            orderItem.PricebookEntryId = pbEntry.Id;
            orderItem.Hourly_Rate__c = 2.0;
            orderItem.Min_Rate__c = 0;
            orderItem.Quantity = 5;
            orderItem.Free_Flag__c = false;
            orderItem.Suggested_Daily_Rate__c = 2.0;
            orderItem.Suggested_Weekly_Rate__c = 2.0;
            orderItem.Suggested_Monthly_Rate__c = 2.0;
            orderItem.Apply_Standby_Rates__c = true;
            orderItem.Contingency_Cost__c = 1;
            orderItem.Line_Item_Notes__c = 'Test';
            
            orderItem.Seasonal_Multiplier__c = 12;
            orderItem.Shift_Differential__c = 'D';
            
            orderItem.Daily_Rate__c = 2.0;
            orderItem.Weekly_Rate__c = 4.0;
            orderItem.Monthly_Rate__c = 6.0;
            orderItem.Rates_Overriden__c = false;
            orderItem.groupId__c = '12345678';
            OrderItem orderItem1 = new OrderItem();
            orderItem1.OrderId = order.Id;
            orderItem1.Product2Id = products[0].Id;
            orderItem1.UnitPrice = 100;
            orderItem1.Item_Number__c = 0;
            orderItem1.PricebookEntryId = pbEntry.Id;
            orderItem1.Hourly_Rate__c = 2.0;
            orderItem1.Min_Rate__c = 0;
            orderItem1.Quantity = 5;
            orderItem1.Free_Flag__c = false;
            orderItem1.Suggested_Daily_Rate__c = 2.0;
            orderItem1.Suggested_Weekly_Rate__c = 2.0;
            orderItem1.Suggested_Monthly_Rate__c = 2.0;
            orderItem1.Daily_Rate__c = 2.0;
            orderItem1.Weekly_Rate__c = 4.0;
            orderItem1.Monthly_Rate__c = 6.0;
            orderItem1.Rates_Overriden__c = false;
            orderItem1.groupId__c = '12345678';
            
            orderItem1.Apply_Standby_Rates__c = true;
            
            orderItem1.Contingency_Cost__c = 1;
            orderItem1.Line_Item_Notes__c = 'Test';
            
            orderItem1.Seasonal_Multiplier__c = 12;
            orderItem1.Shift_Differential__c = 'D';
            
            orderItems.add(orderItem);
            orderItems.add(orderItem1);
            
            system.debug('orderItems:' + orderItems);
            // Create Order item
            
            Map<id, orderItem> orderItemMap = new Map<id, orderItem>();
            
            Test.startTest();
            insert orderItems;
            orderItemMap.put(orderItems[0].id, orderItems[1]);
            orderItemMap.put(orderItems[1].id, orderItems[0]);
            List<orderItem> postOrderItems = [SELECT Id, Product2Id, PriceBookEntryId,Min_Rate__c FROM OrderItem];
            //SBR_3_0_OrderItemOperations.updateItemGroup(orderItemMap);
            System.AssertEquals(orderItemMap.size(), 2);
            Test.stopTest();
            
            System.assertEquals(orderItems[0].Monthly_Rate__c, postOrderItems[0].Min_Rate__c, 'The minimum rate did not match the weekly rate for shoring');
        }catch(Exception ex){
            SBR_3_0_Log.logException(ex);
        }
    }
    
    /*@istest
    static void splitSerializedAssetsIntoSeparateLinestest() {
        try{
            Test.startTest();
            Order order = [SELECT Id,Rentalman_Quote_Id__c,Quote_Name__c,EndDate FROM Order where Quote_Name__c = 'Test Quote'];
            order.Rentalman_Quote_Id__c =null ;
            update order;
            List<Product2> products = [SELECT Id FROM Product2 where Product_Type__c = 'Cat-Class' limit 1];
            PricebookEntry pbEntry = [SELECT Id, Product2Id FROM PricebookEntry WHERE Pricebook2Id = :Test.getStandardPricebookId() AND Product2Id = :products[0].Id LIMIT 1];
            List<orderItem> orderItems =  [Select Id,groupId__c,OrderItemNumber,OrderId,Shift_Differential__c,Quantity,Product2Id from OrderItem where Order.Quote_Name__c = 'Test Quote' and Product2Id =:products[0].Id limit 1];
            orderItems[0].Quantity=5;
            Database.Update(orderItems);
            Map<Id,OrderItem> mapOI = new Map<Id,ORderItem>();
            mapOI.put(orderItems[0].Id,orderItems[0]);
            try {
                SBR_3_0_OrderItemOperations.splitSerializedAssets_Queueable(orderItems);  
                SBR_3_0_OrderItemOperations.executeQueueableOnInsert(mapOI);  
            } catch (Exception e) {
                SBR_3_0_Log.logException(e);
            }
            List<orderItem> orderItemRecordList = new List<orderItem>();
            orderItemRecordList = [Select Id,OrderItemNumber,groupId__c,OrderId,Order.Quote_Name__c from OrderItem where OrderId=: order.Id and Product2Id =:products[0].Id];
            Test.stopTest();
            System.assertEquals(orderItemRecordList.size(),5,'LineItem are Split');
           }catch(Exception ex){
            SBR_3_0_Log.logException(ex);
        }
    }*/
    /*@istest
    static void assignPriceBookEntriesForNewOrderItemsTest() {
        try{
            Test.startTest();
            Order order = [SELECT Id, EndDate FROM Order];
            List<Product2> products = [SELECT Id FROM Product2];
            PricebookEntry pbEntry = [SELECT Id, Product2Id FROM PricebookEntry WHERE Pricebook2Id = :Test.getStandardPricebookId() AND Product2Id = :products[0].Id LIMIT 1];
            
            system.debug('priceBook::' + pbEntry);
            List<OrderItem> orderItems = new List<OrderItem>();
            OrderItem orderItem = new OrderItem();
            orderItem.OrderId = order.Id;
            orderItem.groupID__c = 'Test';
            orderItem.Product2Id = products[0].Id;
            orderItem.UnitPrice = 100;
            orderItem.Item_Number__c = 0;
            //  orderItem.PricebookEntryId = pbEntry.Id;
            orderItem.Hourly_Rate__c = 2.0;
            orderItem.Min_Rate__c = 0;
            orderItem.Quantity = 5;
            orderItem.Free_Flag__c = false;
            orderItem.Suggested_Daily_Rate__c = 2.0;
            orderItem.Suggested_Weekly_Rate__c = 2.0;
            orderItem.Suggested_Monthly_Rate__c = 2.0;
            orderItem.Apply_Standby_Rates__c = true;
            orderItem.Contingency_Cost__c = 1;
            orderItem.Line_Item_Notes__c = 'Test';
            
            orderItem.Seasonal_Multiplier__c = 12;
            orderItem.Shift_Differential__c = 'D';
            
            orderItem.Daily_Rate__c = 2.0;
            orderItem.Weekly_Rate__c = 4.0;
            orderItem.Monthly_Rate__c = 6.0;
            orderItem.Rates_Overriden__c = false;
            orderItem.groupId__c = '12345678';
            OrderItem orderItem1 = new OrderItem();
            orderItem1.OrderId = order.Id;
            orderItem1.Product2Id = products[0].Id;
            orderItem1.UnitPrice = 100;
            orderItem1.Item_Number__c = 0;
            //orderItem1.PricebookEntryId = pbEntry.Id;
            orderItem1.Hourly_Rate__c = 2.0;
            orderItem1.Min_Rate__c = 0;
            orderItem1.Quantity = 5;
            orderItem1.Free_Flag__c = false;
            orderItem1.Suggested_Daily_Rate__c = 2.0;
            orderItem1.Suggested_Weekly_Rate__c = 2.0;
            orderItem1.Suggested_Monthly_Rate__c = 2.0;
            orderItem1.Daily_Rate__c = 2.0;
            orderItem1.Weekly_Rate__c = 4.0;
            orderItem1.Monthly_Rate__c = 6.0;
            orderItem1.Rates_Overriden__c = false;
            orderItem1.groupId__c = '12345678';
            
            orderItem1.Apply_Standby_Rates__c = true;
            
            orderItem1.Contingency_Cost__c = 1;
            orderItem1.Line_Item_Notes__c = 'Test';
            
            orderItem1.Seasonal_Multiplier__c = 12;
            orderItem1.Shift_Differential__c = 'D';
            
            orderItems.add(orderItem);
            orderItems.add(orderItem1);
            
            system.debug('orderItems:' + orderItems);
            // Create Order item
            
            Map<id, orderItem> orderItemMap = new Map<id, orderItem>();
            
            // insert orderItems;
            orderItemMap.put(orderItems[0].id, orderItems[1]);
            orderItemMap.put(orderItems[1].id, orderItems[0]);
            List<orderItem> postOrderItems = [SELECT Id, Product2Id, PriceBookEntryId FROM OrderItem];
            SBR_3_0_OrderItemOperations.assignPriceBookEntriesForNewOrderItems(orderItems);
            system.assertNotEquals(orderItems[0].PriceBookEntryId, null);
            
            Test.stopTest();
        }
        catch(Exception ex){
            SBR_3_0_Log.logException(ex);
        }
        //System.assertEquals(orderItems[0].Weekly_Rate__c, postOrderItems[0].Min_Rate__c, 'The minimum rate did not match the weekly rate for shoring');
    }*/
        
    /*@istest
    static void checkQuantityChangeTest2() {
        try{
            Test.startTest();
            Order order = [SELECT Id, EndDate FROM Order];
            List<Product2> products = [SELECT Id FROM Product2];
            PricebookEntry pbEntry = [SELECT Id, Product2Id FROM PricebookEntry WHERE Pricebook2Id = :Test.getStandardPricebookId() AND Product2Id = :products[0].Id LIMIT 1];
            
            system.debug('priceBook::' + pbEntry);
            List<OrderItem> orderItems = new List<OrderItem>();
            OrderItem orderItem = new OrderItem();
            orderItem.OrderId = order.Id;
            orderItem.groupID__c = 'Test';
            orderItem.Product2Id = products[0].Id;
            orderItem.UnitPrice = 100;
            orderItem.Item_Number__c = 0;
            orderItem.PricebookEntryId = pbEntry.Id;
            orderItem.Hourly_Rate__c = 2.0;
            orderItem.Min_Rate__c = 0;
            orderItem.Quantity = 1;
            orderItem.Free_Flag__c = false;
            orderItem.Suggested_Daily_Rate__c = 2.0;
            orderItem.Suggested_Weekly_Rate__c = 2.0;
            orderItem.Suggested_Monthly_Rate__c = 2.0;
            orderItem.Apply_Standby_Rates__c = true;
            orderItem.Contingency_Cost__c = 1;
            orderItem.Line_Item_Notes__c = 'Test';
            
            orderItem.Seasonal_Multiplier__c = 12;
            orderItem.Shift_Differential__c = 'D';
            
            orderItem.Daily_Rate__c = 2.0;
            orderItem.Weekly_Rate__c = 4.0;
            orderItem.Monthly_Rate__c = 6.0;
            orderItem.Rates_Overriden__c = false;
            orderItem.groupId__c = '12345678';
            OrderItem orderItem1 = new OrderItem();
            orderItem1.OrderId = order.Id;
            orderItem1.Product2Id = products[0].Id;
            orderItem1.UnitPrice = 100;
            orderItem1.Item_Number__c = 0;
            orderItem1.PricebookEntryId = pbEntry.Id;
            orderItem1.Hourly_Rate__c = 2.0;
            orderItem1.Min_Rate__c = 0;
            orderItem1.Quantity = 1;
            orderItem1.Free_Flag__c = false;
            orderItem1.Suggested_Daily_Rate__c = 2.0;
            orderItem1.Suggested_Weekly_Rate__c = 2.0;
            orderItem1.Suggested_Monthly_Rate__c = 2.0;
            orderItem1.Daily_Rate__c = 2.0;
            orderItem1.Weekly_Rate__c = 4.0;
            orderItem1.Monthly_Rate__c = 6.0;
            orderItem1.Rates_Overriden__c = false;
            orderItem1.groupId__c = '12345678';
            
            orderItem1.Apply_Standby_Rates__c = true;
            
            orderItem1.Contingency_Cost__c = 1;
            orderItem1.Line_Item_Notes__c = 'Test';
            
            orderItem1.Seasonal_Multiplier__c = 12;
            orderItem1.Shift_Differential__c = 'D';
            
            orderItems.add(orderItem);
            orderItems.add(orderItem1);
            
            system.debug('orderItems:' + orderItems);
            // Create Order item
            
            Map<id, orderItem> orderItemMap = new Map<id, orderItem>();
            insert orderItems;
            orderItemMap.put(orderItems[0].id, orderItems[0]);
            orderItemMap.put(orderItems[1].id, orderItems[1]);
            List<orderItem> postOrderItems = [SELECT Id, Product2Id, PriceBookEntryId FROM OrderItem];
            SBR_3_0_OrderItemOperations.executeQueueableOnUpdate(orderItemMap, orderItemMap);
            List<OrderItem> oli = [SELECT id FROM orderItem LIMIT 1];
            System.assertEquals(oli.size(), 1);
            Test.stopTest();
        }
        catch(Exception ex){
            SBR_3_0_Log.logException(ex);
        }
        //    stOrderItems[0].Min_Rate__c, 'The minimum rate did not match the weekly rate for shoring');
    }*/
    
    /*@istest
    static void checkQuantityChangeTest3() {
        try{
            Test.startTest();
            Order order = [SELECT Id, EndDate FROM Order];
            List<Product2> products = [SELECT Id FROM Product2];
            PricebookEntry pbEntry = [SELECT Id, Product2Id FROM PricebookEntry WHERE Pricebook2Id = :Test.getStandardPricebookId() AND Product2Id = :products[0].Id LIMIT 1];
            
            system.debug('priceBook::' + pbEntry);
            List<OrderItem> orderItems = new List<OrderItem>();
            OrderItem orderItem = new OrderItem();
            orderItem.OrderId = order.Id;
            orderItem.groupID__c = 'Test';
            orderItem.Product2Id = products[0].Id;
            orderItem.UnitPrice = 100;
            orderItem.Item_Number__c = 0;
            orderItem.PricebookEntryId = pbEntry.Id;
            orderItem.Hourly_Rate__c = 2.0;
            orderItem.Min_Rate__c = 0;
            orderItem.Quantity = 1;
            orderItem.Free_Flag__c = false;
            orderItem.Suggested_Daily_Rate__c = 2.0;
            orderItem.Suggested_Weekly_Rate__c = 2.0;
            orderItem.Suggested_Monthly_Rate__c = 2.0;
            orderItem.Apply_Standby_Rates__c = true;
            orderItem.Contingency_Cost__c = 1;
            orderItem.Line_Item_Notes__c = 'Test';
            
            orderItem.Seasonal_Multiplier__c = 12;
            orderItem.Shift_Differential__c = 'D';
            
            orderItem.Daily_Rate__c = 2.0;
            orderItem.Weekly_Rate__c = 4.0;
            orderItem.Monthly_Rate__c = 6.0;
            orderItem.Rates_Overriden__c = false;
            orderItem.groupId__c = '12345678';
            OrderItem orderItem1 = new OrderItem();
            orderItem1.OrderId = order.Id;
            orderItem1.Product2Id = products[0].Id;
            orderItem1.UnitPrice = 100;
            orderItem1.Item_Number__c = 0;
            orderItem1.PricebookEntryId = pbEntry.Id;
            orderItem1.Hourly_Rate__c = 2.0;
            orderItem1.Min_Rate__c = 0;
            orderItem1.Quantity = 1;
            orderItem1.Free_Flag__c = false;
            orderItem1.Suggested_Daily_Rate__c = 2.0;
            orderItem1.Suggested_Weekly_Rate__c = 2.0;
            orderItem1.Suggested_Monthly_Rate__c = 2.0;
            orderItem1.Daily_Rate__c = 2.0;
            orderItem1.Weekly_Rate__c = 4.0;
            orderItem1.Monthly_Rate__c = 6.0;
            orderItem1.Rates_Overriden__c = false;
            orderItem1.groupId__c = '12345678';
            
            orderItem1.Apply_Standby_Rates__c = true;
            
            orderItem1.Contingency_Cost__c = 1;
            orderItem1.Line_Item_Notes__c = 'Test';
            
            orderItem1.Seasonal_Multiplier__c = 12;
            orderItem1.Shift_Differential__c = 'D';
            
            orderItems.add(orderItem);
            //orderItems.add(orderItem1);
            
            system.debug('orderItems:' + orderItems);
            // Create Order item
            
            Map<id, orderItem> orderItemMap = new Map<id, orderItem>();
            insert orderItems;
            orderItemMap.put(orderItems[0].id, orderItems[0]);
            //orderItemMap.put(orderItems[1].id,orderItems[1]);
            List<orderItem> postOrderItems = [SELECT Id, Product2Id, PriceBookEntryId FROM OrderItem];
            SBR_3_0_OrderItemOperations.executeQueueableOnUpdate(orderItemMap, orderItemMap);
            List<OrderItem> oli = [SELECT id FROM orderItem LIMIT 1];
            System.assertEquals(oli.size(), 1);
            Test.stopTest();
        }
        catch(Exception ex){
            SBR_3_0_Log.logException(ex);
        }
        //    stOrderItems[0].Min_Rate__c, 'The minimum rate did not match the weekly rate for shoring');
    }*/
    
    /*
    @isTest
    static void checkForStaleTotals() {
            Order order = [SELECT Id, EndDate, IsDeliveryOptionsChanged__c, Deliverymethod__c, Delivery_Charges_Override__c, Rentalman_Quote_Id__c FROM Order LIMIT 1];
            order.IsDeliveryOptionsChanged__c = true;
            order.Deliverymethod__c = 'Delivery';
            order.Delivery_Charges_Override__c = true;
            order.Delivery_Charges__c = 0;
            order.Rentalman_Quote_Id__c = '';
            update order;
            Product2 products = [SELECT Id FROM Product2 WHERE Product_Type__c = 'Cat-Class'];
            PricebookEntry pbEntry = [SELECT Id, Product2Id FROM PricebookEntry WHERE Pricebook2Id = :Test.getStandardPricebookId() AND Product2Id = :products.Id LIMIT 1];
            order.Last_Calculated_On__c = System.now().addDays(-1);
            update order;
            
            // Create Order item
            OrderItem orderItem = new OrderItem();
            orderItem.OrderId = order.Id;
            orderItem.Product2Id = products.Id;
            orderItem.UnitPrice = 100;
            orderItem.Item_Number__c = 0;
            orderItem.PricebookEntryId = pbEntry.Id;
            orderItem.Hourly_Rate__c = 2.0;
            orderItem.Min_Rate__c = 0;
            orderItem.Quantity = 5;
            orderItem.Free_Flag__c = false;
            orderItem.Suggested_Daily_Rate__c = 2.0;
            orderItem.Suggested_Weekly_Rate__c = 2.0;
            orderItem.Suggested_Monthly_Rate__c = 2.0;
            orderItem.Daily_Rate__c = 2.0;
            orderItem.Weekly_Rate__c = 40.0;
            orderItem.Monthly_Rate__c = 6.0;
            orderItem.Rates_Overriden__c = false;
            
            insert orderItem;
            
            Test.startTest();
            orderItem.Min_Rate__c = 10;
            System.debug('this is the daily rate before entering the trigger' + orderItem.Min_Rate__c);
            SBR_3_0_OrderItemTriggerHandler.beforeUpdateRecursiveCheck = false;
            SBR_3_0_OrderItemTriggerHandler.afterUpdateRecursiveCheck = false;
            
            Test.stopTest();
            update orderItem;
            List<order> postOrder = [SELECT Id, stale_totals__c, Last_Calculated_On__c, lastOrderItemUpdated__c FROM order WHERE Id = :orderItem.OrderId];
            System.assertEquals(true, postOrder[0].stale_totals__c, 'The totals were not stale last calculated on: ' + postOrder[0].Last_Calculated_On__c + ' last order item update : ' + postOrder[0].LastOrderItemUpdated__c);
    }*/
    
    @isTest
    static void testupdateShiftDurationNotes() {
         try{
            Test.startTest();
            Order order = [SELECT Id, Rentalman_Quote_Id__c, EndDate, SBQQ__Quote__c, Delivery_Charge__c, Return_Date__c, Pickup_Charge__c FROM Order];
            order.Rentalman_Quote_Id__c = '111111';
            //order.SBQQ__Quote__c = [Select Id from SBQQ__Quote__c limit 1].Id;
            order.Delivery_Charge__c = 1234;
            order.Pickup_Charge__c = 1234;
            order.Return_Date__c = system.today().addMonths(2);
            update order;
            
            List<Product2> products = [SELECT Id FROM Product2];
            PricebookEntry pbEntry = [SELECT Id, Product2Id FROM PricebookEntry WHERE Pricebook2Id = :Test.getStandardPricebookId() AND Product2Id = :products[0].Id LIMIT 1];
            List<OrderItem> orderItems = new List<OrderItem>();
            OrderItem orderItem = new OrderItem();
            orderItem.OrderId = order.Id;
            orderItem.groupID__c = 'Test';
            orderItem.Product2Id = products[0].Id;
            orderItem.UnitPrice = 100;
            orderItem.Item_Number__c = 0;
            orderItem.PricebookEntryId = pbEntry.Id;
            orderItem.Hourly_Rate__c = 2.0;
            orderItem.Min_Rate__c = 0;
            orderItem.Quantity = 1;
            orderItem.Free_Flag__c = false;
            orderItem.Suggested_Daily_Rate__c = 2.0;
            orderItem.Suggested_Weekly_Rate__c = 2.0;
            orderItem.Suggested_Monthly_Rate__c = 2.0;
            orderItem.Apply_Standby_Rates__c = true;
            orderItem.Contingency_Cost__c = 1;
            // orderItem.Line_Item_Notes__c = 'Test';
            orderItem.Seasonal_Multiplier__c = 12;
            orderItem.Shift_Differential__c = 'S';
            orderItem.Daily_Rate__c = 2.0;
            orderItem.Weekly_Rate__c = 4.0;
            orderItem.Monthly_Rate__c = 6.0;
            orderItem.Rates_Overriden__c = false;
            orderItem.groupId__c = '12345678';
            orderItems.add(orderItem);
            
            OrderItem orderItem1 = new OrderItem();
            orderItem1.OrderId = order.Id;
            orderItem1.Product2Id = products[0].Id;
            orderItem1.UnitPrice = 100;
            orderItem1.Item_Number__c = 0;
            orderItem1.PricebookEntryId = pbEntry.Id;
            orderItem1.Hourly_Rate__c = 2.0;
            orderItem1.Min_Rate__c = 0;
            orderItem1.Quantity = 1;
            orderItem1.Free_Flag__c = false;
            orderItem1.Suggested_Daily_Rate__c = 2.0;
            orderItem1.Suggested_Weekly_Rate__c = 2.0;
            orderItem1.Suggested_Monthly_Rate__c = 2.0;
            orderItem1.Daily_Rate__c = 2.0;
            orderItem1.Weekly_Rate__c = 4.0;
            orderItem1.Monthly_Rate__c = 6.0;
            orderItem1.Rates_Overriden__c = false;
            orderItem1.groupId__c = '12345678';
            orderItem1.Apply_Standby_Rates__c = true;
            orderItem1.Contingency_Cost__c = 1;
            //orderItem1.Line_Item_Notes__c = 'Test';
            orderItem1.Seasonal_Multiplier__c = 12;
            orderItem1.Shift_Differential__c = 'S';
            orderItems.add(orderItem1);
            
            OrderItem orderItem2 = new OrderItem();
            orderItem2.OrderId = order.Id;
            orderItem2.Product2Id = products[0].Id;
            orderItem2.UnitPrice = 100;
            orderItem2.Item_Number__c = 0;
            orderItem2.PricebookEntryId = pbEntry.Id;
            orderItem2.Hourly_Rate__c = 2.0;
            orderItem2.Min_Rate__c = 0;
            orderItem2.Quantity = 1;
            orderItem2.Free_Flag__c = false;
            orderItem2.Suggested_Daily_Rate__c = 2.0;
            orderItem2.Suggested_Weekly_Rate__c = 2.0;
            orderItem2.Suggested_Monthly_Rate__c = 2.0;
            orderItem2.Daily_Rate__c = 2.0;
            orderItem2.Weekly_Rate__c = 4.0;
            orderItem2.Monthly_Rate__c = 6.0;
            orderItem2.Rates_Overriden__c = false;
            orderItem2.groupId__c = '12345678';
            orderItem2.Apply_Standby_Rates__c = true;
            orderItem2.Contingency_Cost__c = 1;
            // orderItem2.Line_Item_Notes__c = 'Test';
            orderItem2.Seasonal_Multiplier__c = 12;
            orderItem2.Shift_Differential__c = 'S';
            orderItems.add(orderItem2);
            insert orderItems;
            Map<Id, ORderItem> map1 = new Map<Id, OrderItem>();
            Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_CreateOrders_Test());
            map1.put(orderItem.Id,orderItem);
            SBR_3_0_OrderItemTriggerHandler.beforeUpdateRecursiveCheck = false;
            SBR_3_0_OrderItemTriggerHandler.afterUpdateRecursiveCheck = false;
            update orderItems;
            SBR_3_0_OrderItemOperations.callUpdateTotalsForLockedReservation(map1,map1);
            //SBR_3_0_OrderItemOperations.updateShiftDurationNotes(orderItems);
            //SBR_3_0_OrderItemOperations.submitReservation(orderItems);
            
            
            List<OrderItem> updatedOrderItemList = [Select Id,Shift_Differential__c,Line_Item_Notes__c from OrderItem  where Id in : orderItems];
            Test.stopTest();
            System.assertEquals('Single Shift Rate applied. Please see Shift Rate Details section for additional details', updatedOrderItemList[0].Line_Item_Notes__c,'Not failed');
        }
        catch(Exception ex){
            SBR_3_0_Log.logException(ex);
        }
        
        // Order currentOrder = [Select Id,Reservation_Order_Number__c from Order where Id=: order.Id];
        // System.debug('###get reservation'+currentOrder.Reservation_Order_Number__c);
        //System.assertEquals(true,String.isNotBlank(currentOrder.Reservation_Order_Number__c),'Reservation Not Submitted');
    }
    
    @isTest
    static void testUpdateOrderHeaderSpecificPricingFlag() {
        
        try{
            Test.startTest();
            Profile oProfile = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        	User oUsers = SBR_3_0_TestDataFactory.createUser(TRUE,oProfile);
            System.runAs(oUsers){
                
                Order order = [SELECT Id, EndDate FROM Order LIMIT 1];
                Product2 products = [SELECT Id FROM Product2 WHERE Product_Type__c = 'Cat-Class'];
                PricebookEntry pbEntry = [SELECT Id, Product2Id FROM PricebookEntry WHERE Pricebook2Id = :Test.getStandardPricebookId() AND Product2Id = :products.Id LIMIT 1];
                
                // Create Order item
                OrderItem orderItem = new OrderItem();
                orderItem.OrderId = order.Id;
                orderItem.Product2Id = products.Id;
                orderItem.UnitPrice = 100;
                orderItem.Item_Number__c = 0;
                orderItem.PricebookEntryId = pbEntry.Id;
                orderItem.Hourly_Rate__c = 2.0;
                orderItem.Min_Rate__c = 0;
                orderItem.Quantity = 5;
                orderItem.Free_Flag__c = false;
                orderItem.Suggested_Daily_Rate__c = 2.0;
                orderItem.Suggested_Weekly_Rate__c = 2.0;
                orderItem.Suggested_Monthly_Rate__c = 2.0;
                orderItem.Daily_Rate__c = 2.0;
                orderItem.Weekly_Rate__c = 40.0;
                orderItem.Monthly_Rate__c = 6.0;
                orderItem.Rates_Overriden__c = false;
                //orderItem.Specific_Pricing_Type__c = 'Set Rates';
                orderItem.Specific_Pricing_Type__c = SBR_3_0_Constants.CUSTOMER_LOADED_SPECIFIC_PRICING_TYPE;
                insert orderItem;
                update orderItem;
                Test.stopTest();
                List<Order> testOrderResults = [SELECT Id, Specific_Pricing_Flag__c FROM Order WHERE Id = :order.Id];
                System.assertEquals(true,testOrderResults[0].Specific_Pricing_Flag__c, 'Quote specific pricing flag not updated.');      
        }
        }
        catch(Exception ex){
            SBR_3_0_Log.logException(ex);
        }
    }
    
    @isTest
    static void testRemoveQuoteHeaderSpecificPricingFlag() {
        try{
            Test.startTest();
           	Profile oProfile = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        	User oUsers = SBR_3_0_TestDataFactory.createUser(TRUE,oProfile);
            System.runAs(oUsers){
                Order order = [SELECT Id, EndDate FROM Order LIMIT 1];
                Product2 products = [SELECT Id FROM Product2 WHERE Product_Type__c = 'Cat-Class'];
                PricebookEntry pbEntry = [SELECT Id, Product2Id FROM PricebookEntry WHERE Pricebook2Id = :Test.getStandardPricebookId() AND Product2Id = :products.Id LIMIT 1];
                List<OrderItem> orderItems =[select id,Specific_Pricing_Flag__c from OrderItem where OrderId=:order.Id];
                 delete orderItems[0];
                List<Order> testOrderResultsOne = [SELECT Id, Specific_Pricing_Flag__c FROM Order WHERE Id = :order.Id];
                // System.assertEquals(false, testOrderResultsOne[0].Specific_Pricing_Flag__c, 'Quote specific pricing flag not updated.');
                delete orderItems[1];
                List<Order> testOrderResultsTwo = [SELECT Id, Specific_Pricing_Flag__c FROM Order WHERE Id = :order.Id];
                //  System.assertEquals(false, testOrderResultsTwo[0].Specific_Pricing_Flag__c, 'Quote specific pricing flag not updated.');
                System.assertEquals(true, testOrderResultsTwo[0].Specific_Pricing_Flag__c, 'Quote specific pricing flag not updated.');
                Test.stopTest();
           }
        }
        catch(Exception ex){
            SBR_3_0_Log.logException(ex);
        }
    }
    
    /*@isTest
    private static void hasNotSpecialAnalysisRegionKeysTest() {
        try{
            Boolean hasSpecialAnalysisRegionKeys;
            Test.startTest();
            hasSpecialAnalysisRegionKeys = SBR_3_0_OrderItemOperations.hasSpecialAnalysisRegionKeys('');
            Test.stopTest();
            System.assertEquals(false, hasSpecialAnalysisRegionKeys, '');
        }
        catch(Exception ex){
            SBR_3_0_Log.logException(ex);
        }
    }*/

    @isTest
    static void testUncheckFuelPlanCheckBox() {
        Test.startTest();
        Profile oProfile = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User oUsers = SBR_3_0_TestDataFactory.createUser(TRUE,oProfile);
        System.runAs(oUsers){
            Order order = [SELECT Id, EndDate FROM Order LIMIT 1];
            List<OrderItem> queryFuelPlanOLI=[select id,Product2.Name from OrderItem where Product2.Name='Fuel Convenience Charge'];
            delete queryFuelPlanOLI;
            List<OrderItem> queryNonFuelOLI= [SELECT Id,Fuel_Plan__c FROM OrderItem WHERE Product2.Name='Not Fuel Plan'];
            Test.stopTest();
            Assert.areEqual(false, queryNonFuelOLI[0].Fuel_Plan__c);
        }
    }
    
    @isTest
    static void testSpecificPricingAndFuelItem(){
        Id reservationId = Schema.sObjectType.Order.getRecordTypeInfosByDeveloperName().get('Reservation_Order').getRecordTypeId();
        AssociatedLocation jobSite =  [SELECT ID FROM ASSOCIATEDLOCATION];
        
        Order o = new Order(
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
            Is_Specific_Pricing_Flag__c = false,
            Specific_Pricing_Flag__c = false

        );
        insert o;
        
        List<Product2> products = new List<Product2>{
            new Product2(
                Name='Fuel Convenience Charge',
                Product_Title_Internal__c = '2114xxx000',
                Product_Type__c = 'MISC Charge Items',
                Product_SKU__c = 'SKU101',
                Category__c = '32134',
                ToolFlex__c = 'N',
                Company_Code__c ='01',
                Type_of_Misc_Charge_Item__c = 'MS',
                Stock_Class__c = 'FUEL',
                Item_Number__c = 'DELIVERY',
                Unit_Weight_in_Pounds__c = 10
            ),
            new Product2(
                Name='2114xxx102',
                Product_Title_Internal__c = '2114xxx102',
                Product_Type__c = 'MISC Charge Items',
                Product_SKU__c = 'SKU102',
                Category__c = '32134',
                ToolFlex__c = 'N',
                Company_Code__c ='01',
                Type_of_Misc_Charge_Item__c = 'MS',
                Bulk_Item__c = false,
                Stock_Class__c = null,
                Item_Number__c = 'DELIVERY',
                Unit_Weight_in_Pounds__c = 10,
                Status__c = 'A'
            ),
            new Product2(
                Name='FUEL123',
                Product_Title_Internal__c = '2114xxx000',
                Product_Type__c = 'MISC Charge Items',
                Product_SKU__c = 'FUEL123',
                Category__c = '32134',
                ToolFlex__c = 'N',
                Company_Code__c ='01',
                Type_of_Misc_Charge_Item__c = 'MS',
                Stock_Class__c = 'DEL',
                Item_Number__c = 'DELIVERY',
                Unit_Weight_in_Pounds__c = 10
            )
        };
        insert products;
            
        List<PricebookEntry> pricebookEntries = SBR_3_0_TestDataFactory.createPriceBookEntries(products);
        
        List<OrderItem> orderItems = new List<OrderItem>{
            
            //This should have a fuel plan item...
            new OrderItem(
                OrderId = o.Id,
                Kit_Number_This_Item_Belongs_To__c = 'FUEL123',
                PricebookEntryId = pricebookEntries.get(0).Id,
                Line_Composite_Key__c = 'line0',
                Reservation_Line_Number__c= 2,
                Fulfillment_Service__c= 'STANDARD',
                Delivery_Method__c= 'Delivery',
                Date_time_out__c= datetime.now(),
                Global_Line_Number__C= 1,
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
                Misc_Charge__c= 1892.47,
                Fuel_Plan__c = true
            ),
            new OrderItem(
                OrderId = o.Id,
                PricebookEntryId = pricebookEntries.get(1).Id,
                Line_Composite_Key__c = 'line1',
                Reservation_Line_Number__c= 2,
                Fulfillment_Service__c= 'STANDARD',
                Delivery_Method__c= 'Delivery',
                Date_time_out__c= datetime.now(),
                Global_Line_Number__C= 2,
                Quantity= 10,
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
                Misc_Charge__c= 1892.47,
                Specific_Pricing_Type__c = SBR_3_0_Constants.CUSTOMER_LOADED_SPECIFIC_PRICING_TYPE,
                //OrderItemNumber = '123',
                GroupId__c = '123'
            ),
            //Testing existing fuel flag
            new OrderItem(
                OrderId = o.Id,
                Fuel_Plan__c = true,
                Kit_Number_This_Item_Belongs_To__c = 'FUEL123',
                PricebookEntryId = pricebookEntries.get(2).Id,
                Line_Composite_Key__c = 'line2',
                Reservation_Line_Number__c= 3,
                Fulfillment_Service__c= 'STANDARD',
                Delivery_Method__c= 'Delivery',
                Date_time_out__c= datetime.now(),
                Global_Line_Number__C= 3,
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
        };
            
        Test.startTest();
        insert orderItems;
            
        
        o = [Select Id,(Select Id,groupID__c,Quantity From OrderItems Order By OrderItemNumber Asc) From Order Where Id = :o.Id];
        System.assertEquals(12, o.OrderItems.size(), 'Expected 12 order items');
        
        system.debug('order item size:: '+o.OrderItems.size());
        
        for(OrderItem oi : o.OrderItems){
            System.assertEquals(1, oi.Quantity, 'Expected a quantity of 1');
        }
        
        o.OrderItems.get(5).Quantity = 0;
        system.debug('quantity:: '+o.OrderItems.get(5).Quantity);
        
        update o.OrderItems.get(5);
         system.debug('order item size:: '+o.OrderItems.size());
        
        o = [Select Id,(Select Id,groupID__c,Quantity From OrderItems Order By OrderItemNumber Asc) From Order Where Id = :o.Id];
       	system.debug('order item size:: '+o.OrderItems.size());
        
        System.assertEquals(2, o.OrderItems.size(), 'Expected 1 order item to be deleted.');
        
        
        
        OrderItem orderItemToUpdate = orderItems.get(2);
        //delete orderItems.get(1);
        
        orderItemToUpdate.Specific_Pricing_Type__c = SBR_3_0_Constants.CUSTOMER_LOADED_SPECIFIC_PRICING_TYPE;
        update orderItemToUpdate;
        
        o = [Select Id,Specific_Pricing_Flag__c,Is_Specific_Pricing_Flag__c From Order Where Id = :o.Id];
        System.assertEquals(true, o.Specific_Pricing_Flag__c, 'Specific pricing flag not set to true as expected');
        System.assertEquals(true, o.Is_Specific_Pricing_Flag__c, 'Is Specific pricing flag not set to true as expected');
        
        orderItems.get(0).Fuel_Plan__c = false;
        update orderItems.get(0);
        
        Test.stopTest();
    }
 }