//------------------------------------------------------------------------------------------------------------------------//
// Class: TestAPI_ContractFromReservation_Test
// Purpose: Provides unit test coverage for the 'TestAPI_ContractFromReservation' class.
// Author: Publicis Sapient
// Related: TestAPI_ContractFromReservation.cls		
//------------------------------------------------------------------------------------------------------------------------//
@isTest public class TestAPI_ContractFromReservation_Test 
{
    @TestSetup static void makeData()
    {
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
        System.debug('Test Account: ' + acct);
        
        // Create Contact
        Contact contact = SBR_3_0_TestDataFactory.createContacts(1, acct.Id, true)[0];
        System.debug('Test Contact: ' + contact);
        
        // Create Analysis Region
        Analysis_Region__c region = new Analysis_Region__c();
        region.Analysis_Region_Key__c = '001';
        region.Name = 'Test Region';
        region.Company_Code__c = '01';
        insert region;
        System.debug('Test Analysis Region: ' + region);
        
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
        System.debug('Test Job Location: ' + jobLocation);
        
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
        System.debug('Test Branch: ' + branchLocation);
        
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
        System.debug('Test Job Site: ' + jobSite);
        
        // Create Price Book
        Pricebook2 priceBook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update priceBook;
        System.debug('Test Pricebook: ' + priceBook);
        
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
        System.debug('Test Order: ' + order);
        
        // Create Product
        List<Product2> products = new List<Product2>();
        for(Integer i = 0; i < 3; i++) 
        {
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
        System.debug('Test Products: ' + products);
        
        // Create Price Book Entry
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = priceBook.Id,
            Product2Id = products[0].Id,
            UnitPrice = 1020,
            IsActive = true);
        Insert pbe;
        List<PricebookEntry> listPbe = new List<PricebookEntry>();
        Map<Id, Id> mapPBE = new Map<Id, Id>();
        for(PricebookEntry pbEntry : [SELECT Id,Product2Id FROM PricebookEntry WHERE Pricebook2Id = :priceBook.Id]) 
        {
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
        for(Integer i = 0; i < 3; i++)
        {
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
            if(i == 0) 
            {
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
            } 
            else if (i == 1) 
            {
                orderItem.Quantity = 3;
                //orderItem.ListPrice = pbEntry2.ListPrice;
            } 
            else 
            {
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
        System.debug('Test Order Items: ' + orderItems);
    }
    
    @isTest static void testCloning() 
    {
        Order order = [SELECT Id FROM Order LIMIT 1];
        System.debug('Queried Test Order: ' + order);
        System.assert(order != null,'Failed to query test Order record');
        
        String reservationId = order.Id;
        Integer numberOfClones = 10;
        
        Test.startTest();
    	List<Id> newContractIds = TestAPI_ContractFromReservation.doPostCall(reservationId,numberOfClones);
        Test.stopTest();
        
        List<Order> orders = [SELECT Id FROM Order];
        System.debug('# Queried Orders: ' + orders.size());
        System.assertEquals(numberOfClones,orders.size()-1); // Subtract the original Order
        
    }

}