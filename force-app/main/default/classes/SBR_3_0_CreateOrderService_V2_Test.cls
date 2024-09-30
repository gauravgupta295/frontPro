@isTest(seeAllData=false)
public with sharing class SBR_3_0_CreateOrderService_V2_Test implements HttpCalloutMock {
  static Boolean SUCCESSTEST = true;
  static account getNonCreditAccount() {
    Account acct = new Account();
    acct.RM_Account_Number__c = '42';
    acct.Company_Code__c = '01';
    acct.Name = 'Test Account test';
    acct.Record_Type_Text__c = 'Non-Credit';
    acct.E_mail_Address__c = '123@asdf.com';
    acct.Phone = '1234567895';
    acct.BillingStreet = '123 Main Street';
    acct.BillingCity = 'Toronto';
    acct.BillingPostalCode = 'M9N7V5';
    acct.BillingState = 'ON';
    acct.BillingCountry = 'CA';
    acct.Drivers_License__c = 'AKF';
    acct.Driver_s_License_State__c = 'AL';
    insert acct;
    return acct;
  }
  @TestSetup
  static void makeData() {
    Credential__c cred = SBR_3_0_TestDataFactory.createCredentials(1, false)[0];
    cred.Name = 'Mule_Token_Endpoint';
    cred.Key_Id__c = 'testKey123';
    cred.Secret__c = 'secret';
    insert cred;
    User testAdminUser = SBR_3_0_ServiceTestDataFactory.createSystemAdminUser(
      true,
      '8898',
      '987644'
    );
    testAdminUser.RepID__c = '2F00577000000ax1QAAQ';
    testAdminUser.Wynne_User_Name__c = 'CSR';
    update testAdminUser;
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
    // Create Contact
    Contact contact = SBR_3_0_TestDataFactory.createContacts(
      1,
      acct.Id,
      true
    )[0];
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
    branchLocation.Time_Zone_Id__c = '8';
    branchLocation.Latitude_Longitude__Longitude__s = -74.0073;
    branchLocation.Latitude_Longitude__Latitude__s = 40.70948;
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
    //Create Quote
    SBQQ__Quote__c quote = new SBQQ__Quote__c(
      Quote_Name__c = 'Test Quote',
      SBQQ__Account__c = acct.Id,
      Jobsite__c = jobSite.Id,
      SBQQ__DeliveryMethod__c = 'Delivery',
      Start_Date__c = date.valueOf('2022-10-07 12:00:00'),
      End_Date__c = date.valueOf('2022-10-07 12:00:00'),
      Delivery_Date__c = date.valueOf('2022-10-08 12:00:00'),
      Opt_Out_RPP__c = false,
      Opt_Out_Fuel_Charge__c = false,
      Selling_Channel__c = 'SBRB2B',
      Rentalman_Quote_Id__c = 'Test QId',
      Company_Code__c = '01',
      Show_Crew_Expense_Calculator__c = true,
      Branch__c = branchLocation.Id,
      Sourcing_Branch__c = branchLocation.Id,
      SBQQ__Primary__c = true
    );
    insert quote;
    // Create Order
    Order order = new Order(
      Quote_Name__c = 'Test Quote',
      AccountId = acct.Id,
      Jobsite__c = jobSite.Id,
      PoNumber = 'GHTY6789',
      Leave_Facility_Date__c = System.today(),
      Install_Start_Date__c = System.today(),
      Dismantle_Start_Date__c = System.today(),
      Territory_Number__c = 30,
      Market_Segment__c = '01',
      Sales_Rep__c = testAdminUser.Id,
      Pickup_Charge__c = 2,
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
      Reservation_Order_Number__c = null,
      SBQQ__Quote__c = null,
      Branch__c = branchLocation.Id,
      Sourcing_Branch__c = branchLocation.Id
    );
    insert order;

    //Create template
    SVMXA360__SM_TA_Template__c smTaTemplate = new SVMXA360__SM_TA_Template__c();
    smTaTemplate.Name = 'SBR 3.0 Maintenance Template';
    smTaTemplate.SVMXA360__DeveloperName__c = 'SBR_3_0_Maintenance_Template';
    insert smTaTemplate;

    // Create Product
    List<Product2> products = new List<Product2>();
    for (Integer i = 0; i < 3; i++) {
      Product2 product = new Product2();
      product.Name = 'Test Product ' + i;
      product.QuantityUnitOfMeasure = 'A';
      if (i == 0) {
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

    // Create Price Book Entry
    List<PricebookEntry> pbEntries = new List<PricebookEntry>();
    for (Product2 prod : products) {
      PricebookEntry stdPbe = new PricebookEntry();
      stdPbe.Pricebook2Id = Test.getStandardPricebookId();
      stdPbe.Product2Id = prod.Id;
      stdPbe.IsActive = true;
      stdPbe.UnitPrice = 20;
      pbEntries.add(stdPbe);
    }

    insert pbEntries;

    Map<Id, Id> mapPBE = new Map<Id, Id>();
    for (PricebookEntry pbEntry : [
      SELECT Id, Product2Id
      FROM PricebookEntry
      WHERE Pricebook2Id = :Test.getStandardPricebookId()
    ]) {
      //mapPBE.put(products[0].Id,pbEntry.Id);
      if (pbEntry.Product2Id == products[0].Id) {
        mapPBE.put(pbEntry.Product2Id, pbEntry.Id);
      } else if (pbEntry.Product2Id == products[1].Id) {
        mapPBE.put(pbEntry.Product2Id, pbEntry.Id);
      } else if (pbEntry.Product2Id == products[2].Id) {
        mapPBE.put(pbEntry.Product2Id, pbEntry.Id);
      }
    }
    System.debug('mapPBE:- ' + mapPBE);

    /*Asset ast = new Asset();
        ast.Status = 'SCHEDULED FOR PICKUP';
        ast.Name = 'Test Asset';
        ast.AccountId = acct.Id;
        ast.SM_PS_Equipment_Number__c='45';
        insert ast;*/

    // Create Order item
    List<OrderItem> orderItems = new List<OrderItem>();
    for (Integer i = 0; i < 3; i++) {
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
      orderItem.Order_Item_Unit_Of_Measure__c = 'A';
      orderItem.PricebookEntryId = mapPBE.get(products[i].Id);
      if (i == 0) {
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
        //orderItem.SBQQ__Asset__c=ast.id;
      } else if (i == 1) {
        orderItem.Quantity = 3;
        //orderItem.SBQQ__Asset__c=ast.id;
      } else {
        orderItem.Quantity = 3;
        orderItem.Misc_Charges_Type__c = 'TRANSPORTATION CHARGE';
        orderItem.Misc_Charge__c = 20.3;
        orderItem.Misc_Charges_Tax__c = 2.34;
        orderItem.Taxable__c = false;
        orderItem.Misc_Charges_Non_Taxable__c = false;
        orderItem.Misc_Charges_Item_Tax_Rate__c = 2.0;
        //orderItem.SBQQ__Asset__c=ast.id;
      }
      orderItems.add(orderItem);
    }
    insert orderItems;
  }

  public HTTPResponse respond(HTTPRequest req) {
    // Create a fake response
    HttpResponse res = new HttpResponse();
    res.setHeader('Content-Type', SBR_3_0_Constants.APP_JSON);
    if (req.getEndpoint().endsWithIgnoreCase('token')) {
      res.setBody('{"access_token":"test"}');
      res.setStatusCode(200);
    } else if (SUCCESSTEST) {
      List<OrderItem> orderItems = [SELECT Id, OrderItemNumber FROM OrderItem];
      res.setBody(
        '{"data": {"rmReservationId": "000086613723","sfOrderId": "ABCD-12345","lines": [' +
          '{"lineNumber": 1324546,"sfLineNumber": "' +
          orderItems.get(0).OrderItemNumber +
          '","rmLineNumber": 1,"rmLineType": "VR"},' +
          '{"lineNumber": 1343547,"sfLineNumber": "' +
          orderItems.get(1).OrderItemNumber +
          '","rmLineNumber": 2,"rmLineType": "VR"},' +
          '{"lineNumber": 1343567,"sfLineNumber": "' +
          orderItems.get(2).OrderItemNumber +
          '","rmLineNumber": 5,"rmLineType": "VR"}' +
          ']}}'
      );
      res.setStatusCode(200);
    } else {
      res.setBody(
        '{ "error": { "message": "Invalid input parameters, parameters might contain special characters, SQL statements or script statements. Please check application logs for more information.", "errorKey": "BAD_REQUEST", "errorCode": "400-000" } }'
      );
      res.setStatusCode(400);
    }
    return res;
  }

  @isTest
  static void testCreateOrderSuccess() {
    Test.setMock(
      HttpCalloutMock.class,
      new SBR_3_0_CreateOrderService_V2_Test()
    );
    Order order = [SELECT Id, EndDate FROM Order];
    Test.startTest();
    SBR_3_0_CreateOrderService_V2.submitOrder(order.Id);
    Test.stopTest();
    Order newOrder = [SELECT Id, Reservation_Order_Number__c FROM Order];
    System.assertEquals('000086613723', newOrder.Reservation_Order_Number__c);
  }

  @isTest
  static void testCreateQuotesFail() {
    SUCCESSTEST = false;
    Test.setMock(
      HttpCalloutMock.class,
      new SBR_3_0_CreateOrderService_V2_Test()
    );
    Order order = [SELECT Id FROM Order];

    Test.startTest();
    try {
      SBR_3_0_CreateOrderService_V2.submitOrder(order.Id);
    } catch (Exception e) {
      System.assertNotEquals(null, e, 'Exception should be thrown');
    }
    Test.stopTest();
  }

  @isTest
  static void testCreateQuotesAccountTypeCreditError() {
    Test.setMock(
      HttpCalloutMock.class,
      new SBR_3_0_CreateOrderService_V2_Test()
    );
    Account account = [
      SELECT
        Id,
        Record_Type_Text__c,
        RM_Account_Number__c,
        SF_Account_Number__c,
        Drivers_License__c,
        Driver_s_License_State__c
      FROM Account
      LIMIT 1
    ];
    account.Record_Type_Text__c = null;
    update account;
    Order order = [
      SELECT
        Id,
        Account.RM_Account_Number__c,
        RM_Account_Number__c,
        Rentalman_Quote_Id__c,
        SBQQ__Quote__c
      FROM Order
    ];
    update order;
    Test.startTest();
    try {
      SBR_3_0_CreateOrderService_V2.submitOrder(order.Id);
    } catch (Exception e) {
      System.assertEquals(
        'order.Account.Record_Type_Text__c is required',
        e.getMessage(),
        'Exception should be thrown'
      );
    }
    try {
      account.RM_Account_Number__c = '4';
      account.Record_Type_Text__c = 'Credit';
      update account;
      SBR_3_0_CreateOrderService_V2.submitOrder(order.Id);
    } catch (Exception e) {
    }
    Test.stopTest();
  }

  @isTest
  static void testCreateOrdersAccountDetailError() {
    String err = '';
    Test.setMock(
      HttpCalloutMock.class,
      new SBR_3_0_CreateOrderService_V2_Test()
    );
    Order order = [SELECT Id FROM Order];
    Account account = [
      SELECT
        Id,
        Record_Type_Text__c,
        RM_Account_Number__c,
        SF_Account_Number__c,
        Drivers_License__c,
        Driver_s_License_State__c
      FROM Account
    ];
    Test.startTest();
    try {
      account.Phone = null;
      update account;
      SBR_3_0_CreateOrderService_V2.submitOrder(order.Id);
    } catch (Exception e) {
      err = e.getMessage();
    }
    try {
      account.E_mail_Address__c = null;
      update account;
      SBR_3_0_CreateOrderService_V2.submitOrder(order.Id);
    } catch (Exception e) {
    }
    Test.stopTest();
  }

  @isTest
  static void testCreateOrderBranchError() {
    Test.setMock(
      HttpCalloutMock.class,
      new SBR_3_0_CreateOrderService_V2_Test()
    );
    Order order = [SELECT Id FROM Order];
    Schema.Location location = [
      SELECT Branch_Location_Number__c, Time_Zone_Name__c, Time_Zone__c
      FROM Location
      WHERE Name = :'Test Branch Location'
    ];
    Test.startTest();
    try {
      location.Time_Zone__c = null;
      location.Time_Zone_Id__c = null;
      update location;
      SBR_3_0_CreateOrderService_V2.submitOrder(order.Id);
    } catch (Exception e) {
      System.assertEquals(
        'Location Time Zone Id is required',
        e.getMessage(),
        'Exception should be thrown'
      );
    }
    try {
      location.Time_Zone_Name__c = null;
      update location;
      SBR_3_0_CreateOrderService_V2.submitOrder(order.Id);
    } catch (Exception e) {
      System.assertEquals(
        'Location Time Zone Id is required',
        e.getMessage(),
        'Exception should be thrown'
      );
    }
    try {
      location.Branch_Location_Number__c = null;
      update location;
      SBR_3_0_CreateOrderService_V2.submitOrder(order.Id);
    } catch (Exception e) {
      System.assertEquals(
        'Branch Location Number is required',
        e.getMessage(),
        'Exception should be thrown'
      );
    }
    Test.stopTest();
  }

  @isTest
  static void testCreateOrdersProductRatesError() {
    Test.setMock(
      HttpCalloutMock.class,
      new SBR_3_0_CreateOrderService_V2_Test()
    );
    Order order = [SELECT Id FROM Order];
    OrderItem ProductItemLine = [
      SELECT Id, Misc_Charges_Type__c, Misc_Charge__c
      FROM OrderItem
      WHERE
        Product2.Product_Type__c = :'Cat-Class'
        AND Product2.Name = 'Test Product 0'
    ];
    Product2 ProductItemProd = [
      SELECT Id, Category__c, Class__c, ToolFlex__c, Product_SKU__c
      FROM Product2
      WHERE Product_Type__c = :'Cat-Class' AND Product2.Name = 'Test Product 0'
    ];
    Exception unexpectedException;
    Test.startTest();
    try {
      ProductItemLine.Item_Number__c = null;
      update ProductItemLine;
      SBR_3_0_CreateOrderService_V2.submitOrder(order.Id);
    } catch (Exception e) {
      System.assertEquals(
        'You have uncommitted work pending. Please commit or rollback before calling out',
        e.getMessage(),
        'Exception should be thrown'
      );
    }
    try {
      ProductItemLine.Monthly_Rate__c = null;
      update ProductItemLine;
      SBR_3_0_CreateOrderService_V2.submitOrder(order.Id);
    } catch (Exception e) {
      System.assertEquals(
        'Montly Rate is required for Product',
        e.getMessage(),
        'Exception should be thrown'
      );
    }
    try {
      ProductItemLine.Weekly_Rate__c = null;
      update ProductItemLine;
      SBR_3_0_CreateOrderService_V2.submitOrder(order.Id);
    } catch (Exception e) {
      System.assertEquals(
        'Weekly Rate is required for Product',
        e.getMessage(),
        'Exception should be thrown'
      );
    }
    try {
      ProductItemLine.Daily_Rate__c = null;
      update ProductItemLine;
      SBR_3_0_CreateOrderService_V2.submitOrder(order.Id);
    } catch (Exception e) {
      System.assertEquals(
        'Daily rate is required for product.',
        e.getMessage(),
        'Exception should be thrown'
      );
    }
    Test.stopTest();
  }

  @isTest
  static void testCreateOrderProductSuggestedRatesError() {
    Test.setMock(
      HttpCalloutMock.class,
      new SBR_3_0_CreateOrderService_V2_Test()
    );
    Order order = [SELECT Id FROM Order];
    OrderItem ProductItemLine = [
      SELECT
        Id,
        Hourly_Rate__c,
        Suggested_Monthly_Rate__c,
        Suggested_Weekly_Rate__c,
        Suggested_Daily_Rate__c,
        Min_Rate__c
      FROM OrderItem
      WHERE Product2.Product_Type__c = :'Cat-Class'
    ];
    Product2 ProductItemProd = [
      SELECT Id, Category__c, Class__c, ToolFlex__c, Product_SKU__c
      FROM Product2
      WHERE Product_Type__c = :'Cat-Class'
    ];
    Exception unexpectedException;
    Test.startTest();
    try {
      ProductItemLine.Item_Number__c = null;
      update ProductItemLine;
      SBR_3_0_CreateOrderService_V2.submitOrder(order.Id);
    } catch (Exception e) {
      System.assertEquals(
        'You have uncommitted work pending. Please commit or rollback before calling out',
        e.getMessage(),
        'Exception should be thrown'
      );
    }
    try {
      ProductItemLine.Min_Rate__c = null;
      update ProductItemLine;
      SBR_3_0_CreateOrderService_V2.submitOrder(order.Id);
    } catch (Exception e) {
      System.assertEquals(
        'Min rate is required for product.',
        e.getMessage(),
        'Exception should be thrown'
      );
    }
    Test.stopTest();
  }
  @isTest
  static void testCreateOrderProductError() {
    Test.setMock(
      HttpCalloutMock.class,
      new SBR_3_0_CreateOrderService_V2_Test()
    );
    Order order = [SELECT Id FROM Order];
    OrderItem ProductItemLine = [
      SELECT
        Id,
        Suggested_Monthly_Rate__c,
        Suggested_Weekly_Rate__c,
        Suggested_Daily_Rate__c,
        Min_Rate__c
      FROM OrderItem
      WHERE Product2.Product_Type__c = :'Cat-Class'
    ];
    Product2 ProductItemProd = [
      SELECT Id, Category__c, Class__c, ToolFlex__c, Product_SKU__c
      FROM Product2
      WHERE Product_Type__c = :'Cat-Class'
    ];
    Exception unexpectedException;
    Test.startTest();
    try {
      ProductItemProd.Class__c = null;
      update ProductItemProd;
      SBR_3_0_CreateOrderService_V2.submitOrder(order.Id);
    } catch (Exception e) {
      System.assertEquals(
        'Class is required for product.',
        e.getMessage(),
        'Exception should be thrown'
      );
    }
    try {
      ProductItemProd.Category__c = null;
      update ProductItemProd;
      SBR_3_0_CreateOrderService_V2.submitOrder(order.Id);
    } catch (Exception e) {
      System.assertEquals(
        'Category is required for product.',
        e.getMessage(),
        'Exception should be thrown'
      );
    }
    try {
      SBR_3_0_CreateOrderService_V2.submitOrder(order.id);
    } catch (Exception e) {
      System.debug('Exception' + e);
    }
    Test.stopTest();
  }

  @isTest
  static void testNonCreateOrders() {
    String err = '';
    Test.setMock(
      HttpCalloutMock.class,
      new SBR_3_0_CreateOrderService_V2_Test()
    );
    String recordDetailsJsonString =
      '{\n' +
      ' "paymentMethod" :"Visa",\n' +
      ' "amountCollected" : 10,\n' +
      ' "terminal" : "Lane: 003,ID: 1223",\n' +
      ' "checkNumber" : 0,\n' +
      ' "usePreviousCard" : true\n' +
      '}';
    SBR_3_0_OrderServicePayloadGenerator.makeADepositDetails = recordDetailsJsonString;
    Order order = [SELECT Id, Cash_Customer_Payment_Method__c FROM Order];
    Account account = [
      SELECT
        Id,
        Record_Type_Text__c,
        RM_Account_Number__c,
        SF_Account_Number__c,
        Drivers_License__c,
        Driver_s_License_State__c
      FROM Account
    ];
    try {
      account.Record_Type_Text__c = 'Non-Credit';
      order.Cash_Customer_Payment_Amount__c = 100;
      order.Cash_Customer_Payment_Method__c = 'A';
      update order;
      update account;
      Test.startTest();
      SBR_3_0_CreateOrderService_V2.submitOrder(order.Id);
      Test.stopTest();
    } catch (Exception e) {
      err = e.getMessage();
      system.debug('error' + err);
    }
  }
  @isTest
  static void testNonCreateOrdersCheck() {
    String err = '';
    Test.setMock(
      HttpCalloutMock.class,
      new SBR_3_0_CreateOrderService_V2_Test()
    );
    String recordDetailsJsonString =
      '{\n' +
      ' "paymentMethod" :"Check",\n' +
      ' "amountCollected" : 100,\n' +
      ' "checkNumber" : 0,\n' +
      ' "usePreviousCard" : true\n' +
      '}';
    SBR_3_0_OrderServicePayloadGenerator.makeADepositDetails = recordDetailsJsonString;
    Order order = [SELECT Id, Cash_Customer_Payment_Method__c FROM Order];
    Account account = [
      SELECT
        Id,
        Record_Type_Text__c,
        RM_Account_Number__c,
        SF_Account_Number__c,
        Drivers_License__c,
        Driver_s_License_State__c
      FROM Account
    ];
    try {
      account.Record_Type_Text__c = 'Non-Credit';
      order.Cash_Customer_Payment_Amount__c = 100;
      order.Cash_Customer_Payment_Method__c = 'A';
      update order;
      update account;
      Test.startTest();
      SBR_3_0_CreateOrderService_V2.submitOrder(order.Id);
      Test.stopTest();
    } catch (Exception e) {
      err = e.getMessage();
      system.debug('error' + err);
    }
  }
}