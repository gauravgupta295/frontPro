@isTest
public with sharing class SBR_3_0_OrderDA_Test {
  @TestSetup
  static void makeData() {
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
    branchLocation.Job_Number__c = '332112';
    branchLocation.RecordTypeId = SBR_3_0_Constants.LOCATION_BRANCH_RT_ID;
    branchLocation.Company_Code__c = 'X';
    branchLocation.Time_Zone_Name__c = 'America/Chicago';
    branchLocation.Time_Zone__c = 3;
    branchLocation.Analysis_Region_Key__c = '293';
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
      CurrencyIsoCode = 'USD',
      Return_Date__c = System.today().addMonths(2),
      Branch__c = branchLocation.Id,
      Deliverymethod__c = 'Delivery',
      Status = 'Draft',
      Company_Code__c = '01',
      Pricebook2Id = priceBook.Id,
      Start_Date__c = System.today().addMonths(1),
      EffectiveDate = System.today().addMonths(2),
      EndDate = System.today().addMonths(4),
      Earliest_Delivery_Date__c = System.today().addMonths(3),
      Opt_Out_RPP__c = false,
      Opt_Out_Fuel_Charge__c = false,
      Selling_Channel__c = 'SBRB2B',
      Duration__c = 'Custom',
      Invoice_Sequence_Number__c = 100
    );
    insert order;

    SVMXA360__SM_TA_Template__c smTaTemplate = new SVMXA360__SM_TA_Template__c();
    smTaTemplate.Name = 'SBR 3.0 Maintenance Template';
    smTaTemplate.SVMXA360__DeveloperName__c = 'SBR_3_0_Maintenance_Template';
    insert smTaTemplate;
    // Create Product
    List<Product2> products = new List<Product2>();
    for (Integer i = 0; i < 3; i++) {
      Product2 product = new Product2();
      product.Name = 'Test Product ' + i;
      product.Company_Code__c = '01';
      if (i == 0) {
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

    SBR_3_0_TestDataFactory.createPriceBookEntries(products);
    // Create Price Book Entry
    List<PricebookEntry> listPbe = new List<PricebookEntry>();
    Map<Id, Id> mapPBE = new Map<Id, Id>();
    for (PricebookEntry pbEntry : [
      SELECT Id, Product2Id
      FROM PricebookEntry
      WHERE Pricebook2Id = :Test.getStandardPricebookId()
    ]) {
      if (pbEntry.Product2Id == products[0].Id) {
        mapPBE.put(pbEntry.Product2Id, pbEntry.Id);
      } else if (pbEntry.Product2Id == products[1].Id) {
        mapPBE.put(pbEntry.Product2Id, pbEntry.Id);
      } else if (pbEntry.Product2Id == products[2].Id) {
        mapPBE.put(pbEntry.Product2Id, pbEntry.Id);
      }
    }
    Product2 prod = [
      SELECT Id, Product_SKU__c
      FROM Product2
      WHERE Product_Type__c = 'Cat-Class'
      LIMIT 1
    ];

    List<OrderItem> orderItems = new List<OrderItem>();

    for (Integer i = 0; i < 5; i++) {
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
  static void getPaymentTest() {
    String testQuote = 'Test Quote';
    Order testOrder = [
      SELECT
        Id,
        Quote_Name__c,
        Contract_Order_Number__c,
        Reservation_Order_Number__c,
        RecordTypeId
      FROM Order
      WHERE Quote_Name__c = :testQuote
    ];

    String countryCode = '01';
    List<Order> orderResult = SBR_3_0_OrderDA.getContractOrderByContractNum(
      testOrder.Contract_Order_Number__c,
      countryCode
    );
    List<Order> orderSearched = SBR_3_0_OrderDA.getReservationOrderByResNum(
      testOrder.Reservation_Order_Number__c,
      countryCode
    );
    System.assertEquals(
      orderSearched[0].Reservation_Order_Number__c,
      testOrder.Reservation_Order_Number__c
    );

    List<Order> results = SBR_3_0_OrderDA.getPaymentOrder(
      testOrder.Id
    );

    System.assertNotEquals(null, results.size());
  }
     @isTest
  static void getUserTest() {
    User testUser = [Select CompanyName,Department,Wynne_User_Name__c,CurrencyIsoCode from User Limit 1 ];

   List<User> users = SBR_3_0_OrderDA.getUsers(testUser.Id);

        // Assert that the returned list is not empty
        System.assertNotEquals(0, users.size());

        // Assert that the returned user matches the expected values
        User returnedUser = users[0];
        System.assertEquals(testUser.CompanyName, returnedUser.CompanyName);
        System.assertEquals(testUser.Department, returnedUser.Department);
        System.assertEquals(testUser.Wynne_User_Name__c, returnedUser.Wynne_User_Name__c);
        System.assertEquals(testUser.CurrencyIsoCode, returnedUser.CurrencyIsoCode);  
  }

  @isTest
  static void getOrderTest() {
    String testQuote = 'Test Quote';
    Order testOrder = [
      SELECT
        Id,
        Quote_Name__c,
        Contract_Order_Number__c,
        Reservation_Order_Number__c,
        RecordTypeId
      FROM Order
      WHERE Quote_Name__c = :testQuote
    ];

    Order searched = new Order();
    searched = SBR_3_0_OrderDA.getOrder(testOrder.Id);

    System.assertEquals(searched.Id, testOrder.Id);
    String countryCode = '01';
    List<Order> orderResult = SBR_3_0_OrderDA.getContractOrderByContractNum(
      testOrder.Contract_Order_Number__c,
      countryCode
    );
    List<Order> orderSearched = SBR_3_0_OrderDA.getReservationOrderByResNum(
      testOrder.Reservation_Order_Number__c,
      countryCode
    );
    System.assertEquals(
      orderSearched[0].Reservation_Order_Number__c,
      testOrder.Reservation_Order_Number__c
    );

    List<Order> results = SBR_3_0_OrderDA.getOrderDtlsForTotalTaxUpdate(
      testOrder.Id
    );

    System.assertNotEquals(null, results.size());
  }

  @isTest
  static void getRelatedAccountTest() {
    SBR_3_0_TriggerHandler.bypass('SBR_3_0_AssociatedLocationTriggerHandler');
    //List<Account> accList = SBR_3_0_TestDataFactory.createAccounts(1, true);
    List<Account> accList = [
      SELECT Id, RM_Account_Number__c
      FROM Account
      WHERE Name = 'Test Account'
    ];

    for (Account acc : accList) {
      acc.RM_Account_Number__c = '3210';
      update acc;
    }
    Test.startTest();
    List<Account> result = SBR_3_0_OrderDA.getRelatedAccount('3210');
    Test.stopTest();
    System.assertEquals(accList.size(), 1);
    System.assertEquals(result.size(), 0);
  }

  @isTest
  static void getRelatedBranchLocationTest() {
    SBR_3_0_TriggerHandler.bypass('SBR_3_0_AssociatedLocationTriggerHandler');
    List<Schema.Location> branchList = SBR_3_0_TestDataFactory.createLocations(
      1,
      true,
      'Branch'
    );

    for (Schema.Location loc : branchList) {
      loc.Branch_Location_Number__c = '1234';
      loc.Company_Code__c = '111';
      update loc;
    }
    Test.startTest();
    Schema.Location result = SBR_3_0_OrderDA.getRelatedBranchLocation(
      '1234',
      '111'
    );

    Test.stopTest();

    System.assertEquals(branchList[0].Id, result.Id);
  }

  /**
      @isTest public static void testgetQuotLine(){
      Test.startTest();
          SBQQ__Quote__c tq = [SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__BillingCity__c = 'Test City'];
          System.AssertEquals(!SBR_3_0_QuoteLineDA.getQuoteLines(new Set<Id>{tq.Id}).isEmpty(), true);
      Test.stopTest();
      }**/

  @isTest
  static void getOrderItemDetailsTest() {
    OrderItem test = [
      SELECT
        Id,
        UnitPrice,
        Min_Rate__c,
        Order_Item_Detail__r.Pickup_Ticket__c,
        groupId__c,
        OrderId,
        Order.Reservation_Order_Number__c,
        Order.Contract_Order_Number__c
      FROM OrderItem
      WHERE Min_Rate__c = 2.0
      LIMIT 1
    ];

    List<OrderItem> orderItems = SBR_3_0_OrderDA.getOrderItems(
      new Set<Id>{ test.Id }
    );
    List<String> pickUpTicketNumbers = new List<String>();
    pickUpTicketNumbers.add(test.Order_Item_Detail__r.Pickup_Ticket__c);
    String pickUpTicketNumber = test.Order_Item_Detail__r.Pickup_Ticket__c;
    List<Order_Item_Detail__c> orderItemDetailsList = SBR_3_0_OrderDA.getOrdItmDtlsByPickupTicketNumbers(
      pickUpTicketNumbers
    );

    System.assertEquals(pickUpTicketNumber, null);
    List<Order_Item_Detail__c> itemsDetailsList = SBR_3_0_OrderDA.getScheduledPickUpTktDtlsByOrderLineItemId(
      test.Id
    );

    System.debug('Data::::' + itemsDetailsList);
    List<String> optionsList = SBR_3_0_OrderDA.getOrderSubTypeOptions();
    System.assertNotEquals(null, optionsList.size());
  }
  /*START: FRONT-7422,7423*/
  @isTest
  static void getOrderItemForAvailability() {
    Order testOrder = [
      SELECT
        Id,
        Quote_Name__c,
        Contract_Order_Number__c,
        Reservation_Order_Number__c,
        RecordTypeId
      FROM Order
      WHERE Quote_Name__c = 'Test Quote'
    ];
    Test.StartTest();
    Map<Id, Order> resMap = SBR_3_0_OrderDA.getOrdersWithItems(
      new Set<Id>{ testOrder.Id }
    );
    Test.StopTest();
    System.assertNotEquals(resMap.size(), 0);
  }
  /*END: FRONT-7422,7423*/
    

    // Method to create test data
    private static End_of_Day_Till__c createTestEndOfDayTillRecord() {
        End_of_Day_Till__c testRecord = new End_of_Day_Till__c(
            CurrencyIsoCode = 'USD',
            Till_Date__c = Date.today(),
            Next_Day_Drawer__c = 1000,
            Start_Drawer__c = 500,
            Submitted_Date__c = Date.today(),
            Submitted__c = true,
            Cash_Sales__c = 1500,
            Deposits_Taken__c = 200,
            Inter_Location_Cash__c = 300,
            Total_Credit_Cards__c = 400,
            Total_Drawer__c = 2500,
            Total_ROA_Checks__c = 100,
            Total_Transaction__c = 2000,
            Uncollected__c = 100,
            Wire_Transfer__c = 50,
            Last_Edited_By_RM_User__c = 'Test User',
            Refunds_Not_Given__c = 50,
            Total_Checks__c = 200,
            Total_Currency__c = 10000,
            Total_Deposit__c = 300,
            Total_Deposit_in_Bank__c = 400,
            Net_Cash_From_Invoice__c = 100,
            Total_Cash__c = 5000,
            Drawer_Bills_Hundred__c = 10,
            Drawer_Bills_Fifty__c = 20,
            Drawer_Bills_Twenty__c = 30,
            Drawer_Bills_Ten__c = 40,
            Drawer_Bills_Five__c = 50,
            Drawer_Bills_Two__c = 60,
            Drawer_Bills_One__c = 70,
            Drawer_Coins_One__c = 80,
            Drawer_Coins_Fifty__c = 90,
            Drawer_Coins_Quarter__c = 100,
            Drawer_Coins_Dime__c = 110,
            Drawer_Coins_Nickel__c = 120,
            Drawer_Coins_Penny__c = 130,
            Amex__c = 140,
            Amex_ROA__c = 150,
            Discover__c = 160,
            Discover_ROA__c = 170,
            MasterCard__c = 180,
            MasterCard_ROA__c = 190,
            Visa__c = 200,
            Visa_ROA__c = 210,
            Diners_Club__c = 220,
            Diners_Club_ROA__c = 230,
            Status__c='In Balance',
            CreatedDate = Datetime.now() // Assuming this field is not required
        );
        insert testRecord;
        return testRecord;
    }

    @isTest
    static void testGetEodTill() {
        // Create test data
        End_of_Day_Till__c testRecord = createTestEndOfDayTillRecord();

        // Call the method and get the result
        List<End_of_Day_Till__c> result = SBR_3_0_OrderDA.getEodTill(testRecord.Id);

        // Verify the results
        System.assertEquals(1, result.size());
        End_of_Day_Till__c retrievedRecord = result[0];
        System.assertEquals(testRecord.Id, retrievedRecord.Id);
        System.assertEquals('USD', retrievedRecord.CurrencyIsoCode);
        System.assertEquals(Date.today(), retrievedRecord.Till_Date__c);
        System.assertEquals(1000, retrievedRecord.Next_Day_Drawer__c);
        System.assertEquals(500, retrievedRecord.Start_Drawer__c);
        System.assertEquals(Date.today(), retrievedRecord.Submitted_Date__c);
        System.assertEquals(true, retrievedRecord.Submitted__c);
        System.assertEquals(1500, retrievedRecord.Cash_Sales__c);
        System.assertEquals(200, retrievedRecord.Deposits_Taken__c);
        System.assertEquals(300, retrievedRecord.Inter_Location_Cash__c);
        System.assertEquals(400, retrievedRecord.Total_Credit_Cards__c);
        System.assertEquals(2500, retrievedRecord.Total_Drawer__c);
        System.assertEquals(100, retrievedRecord.Total_ROA_Checks__c);
        System.assertEquals(2000, retrievedRecord.Total_Transaction__c);
        System.assertEquals(100, retrievedRecord.Uncollected__c);
        System.assertEquals(50, retrievedRecord.Wire_Transfer__c);
        System.assertEquals('Test User', retrievedRecord.Last_Edited_By_RM_User__c);
        System.assertEquals(50, retrievedRecord.Refunds_Not_Given__c);
        System.assertEquals(200, retrievedRecord.Total_Checks__c);
        System.assertEquals(10000, retrievedRecord.Total_Currency__c);
        System.assertEquals(300, retrievedRecord.Total_Deposit__c);
        System.assertEquals(400, retrievedRecord.Total_Deposit_in_Bank__c);
        System.assertEquals(100, retrievedRecord.Net_Cash_From_Invoice__c);
        System.assertEquals(5000, retrievedRecord.Total_Cash__c);
        System.assertEquals(10, retrievedRecord.Drawer_Bills_Hundred__c);
        System.assertEquals(20, retrievedRecord.Drawer_Bills_Fifty__c);
        System.assertEquals(30, retrievedRecord.Drawer_Bills_Twenty__c);
        System.assertEquals(40, retrievedRecord.Drawer_Bills_Ten__c);
        System.assertEquals(50, retrievedRecord.Drawer_Bills_Five__c);
        System.assertEquals(60, retrievedRecord.Drawer_Bills_Two__c);
        System.assertEquals(70, retrievedRecord.Drawer_Bills_One__c);
        System.assertEquals(80, retrievedRecord.Drawer_Coins_One__c);
        System.assertEquals(90, retrievedRecord.Drawer_Coins_Fifty__c);
        System.assertEquals(100, retrievedRecord.Drawer_Coins_Quarter__c);
        System.assertEquals(110, retrievedRecord.Drawer_Coins_Dime__c);
        System.assertEquals(120, retrievedRecord.Drawer_Coins_Nickel__c);
        System.assertEquals(130, retrievedRecord.Drawer_Coins_Penny__c);
        System.assertEquals(140, retrievedRecord.Amex__c);
        System.assertEquals(150, retrievedRecord.Amex_ROA__c);
        System.assertEquals(160, retrievedRecord.Discover__c);
        System.assertEquals(170, retrievedRecord.Discover_ROA__c);
        System.assertEquals(180, retrievedRecord.MasterCard__c);
        System.assertEquals(190, retrievedRecord.MasterCard_ROA__c);
        System.assertEquals(200, retrievedRecord.Visa__c);
        System.assertEquals(210, retrievedRecord.Visa_ROA__c);
        System.assertEquals(220, retrievedRecord.Diners_Club__c);
        System.assertEquals(230, retrievedRecord.Diners_Club_ROA__c);
    }


}