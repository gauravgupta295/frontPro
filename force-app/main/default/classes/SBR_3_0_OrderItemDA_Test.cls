/**
 * @description       : 
 * @author            : Hashem Abdul
 * @group             : 
 * @last modified on  : 01-29-2024
 * @last modified by  : Hashem Abdul
**/
@isTest public with sharing class SBR_3_0_OrderItemDA_Test {
    @TestSetup
    static void makeData(){

        // Create price book
        Pricebook2 stdpriceBook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update stdpriceBook;

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
        // List<Pricebook2> priceBookLst = [SELECT Id, IsActive FROM Pricebook2 Where Id =: Test.getStandardPricebookId() AND IsActive = false FOR Update];
        
        // Pricebook2 priceBook;
        // if(priceBookLst.isEmpty()){
        //     priceBook = new Pricebook2(
        //         Id = Test.getStandardPricebookId(),
        //         IsActive = true
        //     );
        //     update priceBook;
        // } else {
        //     priceBook = 
        // }
        // Pricebook2 priceBook = new Pricebook2(
        //     Id = Test.getStandardPricebookId(),
        //     IsActive = true
        // );
        // update priceBook;
        // Create Order
        Order order = new Order(
            Quote_Name__c = 'Test Quote',
            AccountId = acct.Id,
            Jobsite__c = jobSite.Id,
            Deliverymethod__c = 'Delivery',
            Delivery_Charge__c = 10,
            Status = 'Draft',
            Pricebook2Id = Test.getStandardPricebookId(),
            Start_Date__c = date.valueOf('2022-12-12 12:00:00'),
            EffectiveDate = date.valueOf('2022-12-12 12:00:00'),
            EndDate = date.valueOf('2023-10-09 8:00:00'),
            Return_Date__c = date.valueOf('2023-10-09 8:00:00'),
            Earliest_Delivery_Date__c = date.valueOf('2022-10-08 12:00:00'),
            Opt_Out_RPP__c = false,
            Order_Initiating_Channel__c = 'SLSFRC',
            Opt_Out_Fuel_Charge__c = false,
            Selling_Channel__c = 'SBRB2B',
            Duration__c = 'Custom',
            Reservation_Order_Number__c = '12345',
            Contract_Order_Number__c = '12345',
            Company_Code__c = '01'
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

        List<PricebookEntry> pbEntries = new List<PricebookEntry>();
        for(Product2 p : products) {
            PricebookEntry pbe = new PricebookEntry(Product2Id = p.Id, Pricebook2Id = Test.getStandardPricebookId(), UnitPrice = 100);
            pbEntries.add(pbe);
        }
        insert pbEntries;

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
            orderItem.PricebookEntryId = mapPBE.get(products[i].Id);
            orderItem.groupId__c = '12345';
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

        //Create Order item details using list
        //SAL-22424, SADAPUR
        List<Order_Item_Detail__c> orderItemsDtlsList = new List<Order_Item_Detail__c>();
        Order_Item_Detail__c orderItemDetail1 = new Order_Item_Detail__c();
        orderItemDetail1.Pickup_Ticket__c = 'Test ticket';
        orderItemDetail1.Line_Item__c = orderItems[0].Id;
        orderItemsDtlsList.add(orderItemDetail1) ;

        Order_Item_Detail__c orderItemDetail2 = new Order_Item_Detail__c();
        orderItemDetail2.Pickup_Ticket__c = 'Test ticket 2';
        orderItemDetail1.Line_Item__c = orderItems[1].Id;
        orderItemsDtlsList.add(orderItemDetail2) ;
        insert orderItemsDtlsList; 
    }

    @isTest
    public static void getOrderItemTest(){
        OrderItem test = [SELECT Id, UnitPrice, Min_Rate__c FROM OrderItem WHERE Min_Rate__c = 2.0 LIMIT 1];
        Set<String> searchingSet = new Set<String>();
        searchingSet.add(test.Id);
        List<OrderItem> searching = SBR_3_0_OrderItemDA.getOrderItem(searchingSet);
        System.AssertEquals(test.Id, searching[0].Id);
    }

    @isTest
    public static void getOrderItemDetails(){
        List<Order_Item_Detail__c> orderItemDetails = [SELECT Id FROM Order_Item_Detail__c LIMIT 2];
        Set<String> itemDetailsSet = new Set<String>();
        for(Order_Item_Detail__c oid : orderItemDetails) {
            itemDetailsSet.add(oid.Id);
        }
        List<Order_Item_Detail__c> itemDetails = SBR_3_0_OrderItemDA.getOrderItemDetails(itemDetailsSet);

        System.AssertEquals(orderItemDetails.size(), itemDetails.size());
    }

    @isTest
    public static void getOrderItemsFromGroupId(){
        List<OrderItem> orderItems = SBR_3_0_OrderItemDA.getOrderItemsFromGroupId(new Set<String>{'12345'},new Set<Id>());
        System.AssertNotEquals(orderItems.size(), 0);
    }

    @isTest
    public static void getOrderItemByOrder(){
        Order testOrder = [SELECT Id FROM Order WHERE Quote_Name__c = 'Test Quote' LIMIT 1];
        List<OrderItem> orderItems = SBR_3_0_OrderItemDA.getOrderItemsByOrder(testOrder.Id);
        System.AssertNotEquals(orderItems.size(), 0);
    }

    @isTest
    public static void getOrderItemByReservationNumberTest(){
        Map<String, OrderItem> orderItemMap = SBR_3_0_OrderItemDA.getOrderItemByReservationNumber('12345', '01');
        System.AssertNotEquals(orderItemMap.size(), 0);
    }

    @isTest
    public static void getOrderItemByContractNumberTest(){
        Map<String, OrderItem> orderItemMap = SBR_3_0_OrderItemDA.getOrderItemByContractNumber('12345', '01');
        System.AssertNotEquals(orderItemMap.size(), 0);
    }
    /**
    * @description Test by checking if SBR_3_0_OrderItemDA.getOrderItemsMapForUpdate return records
    * @author Hashem Abdul | 01-29-2024 
    **/
    @isTest
    public static void getOrderItemsMapForUpdateTest(){
        Map<Id, OrderItem> ordItemsMap = new Map<Id, OrderItem>([SELECT ID FROM OrderItem]);
        Map<Id, OrderItem> orderItemsMap = SBR_3_0_OrderItemDA.getOrderItemsMapForUpdate(ordItemsMap.keySet());
        System.AssertNotEquals(orderItemsMap.size(), 0);
    }
}