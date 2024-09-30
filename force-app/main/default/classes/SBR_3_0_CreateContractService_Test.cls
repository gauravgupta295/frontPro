/*********************************************************************************************************************
* Apex Class: SBR_3_0_CreateContractService_Test
----------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Test class for SBR_3_0_CreateContractService, SBR_3_0_ContractServicePayloadGenerator, 
    SBR_3_0_WrapContract and SBR_3_0_API_ContractResponse
----------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
1.0             Nilesh Jaiswal          2024-05-27          Initial version   
*********************************************************************************************************************/
@isTest
private class SBR_3_0_CreateContractService_Test implements HttpCalloutMock {
  static Boolean successTest = true;

  @TestSetup
  static void makeData() {
    Credential__c cred = SBR_3_0_TestDataFactory.createCredentials(1, false)[0];
    cred.Name = 'Mule_Token_Endpoint';
    cred.Key_Id__c = 'testKey123';
    cred.Secret__c = 'secret';
    insert cred;

    User adminUser = SBR_3_0_ServiceTestDataFactory.createSystemAdminUser(
      true,
      '8898',
      '987644'
    );
    adminUser.RepID__c = '2F00577000000ax1QSEW';
    adminUser.Wynne_User_Name__c = 'CSR';
    update adminUser;

    List<Account> accountList = new List<Account>();
    Account acct = SBR_3_0_TestDataFactory.createAccounts(1, false)[0];
    acct.RM_Account_Number__c = '1816090';
    acct.Company_Code__c = '01';
    acct.Name = 'Test Account';
    acct.Record_Type_Text__c = 'Non-Credit';
    acct.E_mail_Address__c = '123@asdf.com';
    acct.Phone = '1234567899';
    acct.BillingStreet = '123 Main Street';
    acct.BillingCity = 'Toronto';
    acct.BillingPostalCode = 'M9N7V5';
    acct.BillingState = 'ON';
    acct.BillingCountry = 'CA';
    acct.Drivers_License__c = 'AKF';
    acct.Driver_s_License_State__c = 'AL';
    acct.Date_of_Birth__c = Date.today().addYears(-30);
    acct.Social_Security_Number__c = 68699;
    accountList.add(acct);
    acct = SBR_3_0_TestDataFactory.createAccounts(1, false)[0];
    acct.RM_Account_Number__c = '1826090';
    acct.Company_Code__c = '01';
    acct.Name = 'Guest Account';
    acct.Record_Type_Text__c = 'Guest';
    acct.E_mail_Address__c = '123@sunbelt.com';
    acct.Phone = '7788339911';
    acct.BillingStreet = '123 William Street';
    acct.BillingCity = 'Toronto';
    acct.BillingPostalCode = 'M9N8V5';
    acct.BillingState = 'ON';
    acct.BillingCountry = 'CA';
    acct.Drivers_License__c = 'AKF1';
    acct.Driver_s_License_State__c = 'AK';
    acct.Date_of_Birth__c = Date.today().addYears(-30);
    acct.BirthDate__c = Date.today().addYears(-30);
    acct.DL_Expiration_Date__c = Date.today().addYears(10);
    acct.Social_Security_Number__c = 68999;
    accountList.add(acct);
    acct = SBR_3_0_TestDataFactory.createAccounts(1, false)[0];
    acct.RM_Account_Number__c = '1836090';
    acct.Company_Code__c = '01';
    acct.Name = 'Credit Account';
    acct.Record_Type_Text__c = 'Credit';
    acct.E_mail_Address__c = '125@sunb.com';
    acct.Phone = '7788669911';
    acct.BillingStreet = '125 William Street';
    acct.BillingCity = 'Toronto';
    acct.BillingPostalCode = 'M5N8V5';
    acct.BillingState = 'ON';
    acct.BillingCountry = 'CA';
    acct.Drivers_License__c = 'AKF1';
    acct.Driver_s_License_State__c = 'AL';
    acct.Date_of_Birth__c = Date.today().addYears(-35);
    acct.BirthDate__c = Date.today().addYears(-35);
    acct.DL_Expiration_Date__c = Date.today().addYears(11);
    acct.Social_Security_Number__c = 68591;
    accountList.add(acct);
    insert accountList;

    // Create Contact
    List<Contact> contactList = new List<Contact>();
    Contact contact = SBR_3_0_TestDataFactory.createContacts(
      1,
      accountList[0].Id,
      false
    )[0];
    contactList.add(contact);
    contact = SBR_3_0_TestDataFactory.createContacts(
      1,
      accountList[1].Id,
      false
    )[0];
    contactList.add(contact);
    contact = SBR_3_0_TestDataFactory.createContacts(
      1,
      accountList[2].Id,
      false
    )[0];
    contactList.add(contact);
    insert contactList;

    // Create Location
    List<Schema.Location> locationList = new List<Schema.Location>();
    Schema.Location jobLocation = SBR_3_0_TestDataFactory.createLocations(
      1,
      false,
      'Shared Job Location'
    )[0];
    jobLocation.Name = 'Test Job Location';
    jobLocation.Street_Address__c = '12 Main Street';
    jobLocation.City__c = 'Toronto';
    jobLocation.Zip_Code__c = 'M7N7B3';
    jobLocation.State__c = 'ON';
    jobLocation.Country__c = 'CA';
    jobLocation.OMS_Sourcing_Enabled__c = true;
    jobLocation.Distance_Multiplier__c = 50;
    jobLocation.Analysis_Region_Key__c = '001';
    jobLocation.Company_Code__c = '01';
    locationList.add(jobLocation);

    // Create Branch
    Schema.Location branchLocation = SBR_3_0_TestDataFactory.createLocations(
      1,
      false,
      'Branch'
    )[0];
    branchLocation.Branch_Location_Number__c = '720';
    branchLocation.Name = 'Test Branch Location';
    branchLocation.Street_Address__c = '12 Main Street';
    branchLocation.City__c = 'Toronto';
    branchLocation.Zip_Code__c = 'M7N7B3';
    branchLocation.State__c = 'ON';
    branchLocation.Country__c = 'CA';
    branchLocation.Job_Number__c = '332112';
    branchLocation.Company_Code__c = 'X';
    branchLocation.Time_Zone_Name__c = 'America/Chicago';
    branchLocation.Time_Zone__c = 3;
    branchLocation.Time_Zone_Id__c = '8';
    branchLocation.Latitude_Longitude__Longitude__s = -74.0073;
    branchLocation.Latitude_Longitude__Latitude__s = 40.70948;
    locationList.add(branchLocation);
    insert locationList;

    // Create Job Site
    List<AssociatedLocation> jobSiteList = new List<AssociatedLocation>();
    AssociatedLocation jobSite = new AssociatedLocation(
      Name__c = 'Test Job Site',
      ParentRecordId = accountList[0].Id,
      LocationId = locationList[0].Id,
      Branch__c = locationList[1].Id,
      Job_Number__c = '20221004A',
      Territory_Number__c = '126426'
    );
    jobSiteList.add(jobSite);
    jobSite = new AssociatedLocation(
      Name__c = 'Test Job Site 2',
      ParentRecordId = accountList[1].Id,
      LocationId = locationList[0].Id,
      Branch__c = locationList[1].Id,
      Job_Number__c = '20221005A',
      Territory_Number__c = '127426'
    );
    jobSiteList.add(jobSite);
    jobSite = new AssociatedLocation(
      Name__c = 'Test Job Site 2',
      ParentRecordId = accountList[2].Id,
      LocationId = locationList[0].Id,
      Branch__c = locationList[1].Id,
      Job_Number__c = '20221005A',
      Territory_Number__c = '127426'
    );
    jobSiteList.add(jobSite);
    insert jobSiteList;

    // Create Price Book
    Pricebook2 priceBook = new Pricebook2(
      Id = Test.getStandardPricebookId(),
      IsActive = true
    );
    update priceBook;

    // Create Order
    List<Order> orderList = new List<Order>();
    Order order = new Order(
      Name = 'Test Order-01',
      Quote_Name__c = 'Test Quote',
      AccountId = accountList[0].Id,
      Jobsite__c = jobSiteList[0].Id,
      PoNumber = 'GHTY6789',
      Territory_Number__c = 30,
      Market_Segment__c = '01',
      Sales_Rep__c = adminUser.Id,
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
      Order_By__c = contactList[0].Id,
      Selling_Channel__c = 'SBRB2B',
      Rentalman_Quote_Id__c = 'test',
      Duration__c = 'Custom',
      SBQQ__Quote__c = null,
      Branch__c = locationList[1].Id,
      Sourcing_Branch__c = locationList[1].Id,
      RecordTypeId = SBR_3_0_Constants.ORDER_REC_TYPE_CONTRACT_ORDER_ID
    );
    orderList.add(order);
    order = new Order(
      Name = 'Test Order-02',
      Quote_Name__c = 'Test Quote',
      AccountId = accountList[1].Id,
      Jobsite__c = jobSiteList[1].Id,
      PoNumber = 'GHTY6789',
      Territory_Number__c = 30,
      Market_Segment__c = '01',
      Sales_Rep__c = adminUser.Id,
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
      Order_By__c = contactList[1].Id,
      Order_Initiating_Channel__c = 'SLSFRC',
      Selling_Channel__c = 'SBRB2B',
      Rentalman_Quote_Id__c = 'test',
      Duration__c = 'Custom',
      SBQQ__Quote__c = null,
      Branch__c = locationList[1].Id,
      Sourcing_Branch__c = locationList[1].Id,
      RecordTypeId = SBR_3_0_Constants.ORDER_REC_TYPE_CONTRACT_ORDER_ID
    );
    orderList.add(order);
    order = new Order(
      Name = 'Test Order-03',
      Quote_Name__c = 'Test Quote',
      AccountId = accountList[2].Id,
      Jobsite__c = jobSiteList[2].Id,
      PoNumber = 'GHTY6789',
      Territory_Number__c = 30,
      Market_Segment__c = '01',
      Sales_Rep__c = adminUser.Id,
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
      Order_By__c = contactList[2].Id,
      Order_Initiating_Channel__c = 'SLSFRC',
      Selling_Channel__c = 'SBRB2B',
      Rentalman_Quote_Id__c = 'test',
      Duration__c = 'Custom',
      SBQQ__Quote__c = null,
      Branch__c = locationList[1].Id,
      Sourcing_Branch__c = locationList[1].Id,
      RecordTypeId = SBR_3_0_Constants.ORDER_REC_TYPE_CONTRACT_ORDER_ID
    );
    orderList.add(order);
    insert orderList;

    Payments__c payment = new Payments__c();
    payment.Order__c = orderList[0].Id;
    payment.Check_Number__c = '12345';
    payment.Terminal__c = 'Lane: 003, ID: 1462';
    insert payment;

    //Create template
    SVMXA360__SM_TA_Template__c smTaTemplate = new SVMXA360__SM_TA_Template__c();
    smTaTemplate.Name = 'SBR 3.0 Maintenance Template';
    smTaTemplate.SVMXA360__DeveloperName__c = 'SBR_3_0_Maintenance_Template';
    insert smTaTemplate;

    // Create Product
    List<Product2> products = new List<Product2>();
    for (Integer i = 0; i < 4; i++) {
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
      } else if (i == 2) {
        product.Product_Type__c = 'MISC Charge Items';
        product.Item_Number__c = '1285JC';
        product.Stock_Class__c = 'UJEKL';
      } else {
        product.Product_Type__c = 'MISC Charge Items';
        product.Item_Number__c = 'ENVIRONMENTAL';
        product.Stock_Class__c = 'MISC';
        product.Product_SKU__c = '10198311';
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
      if (pbEntry.Product2Id == products[0].Id) {
        mapPBE.put(pbEntry.Product2Id, pbEntry.Id);
      } else if (pbEntry.Product2Id == products[1].Id) {
        mapPBE.put(pbEntry.Product2Id, pbEntry.Id);
      } else if (pbEntry.Product2Id == products[2].Id) {
        mapPBE.put(pbEntry.Product2Id, pbEntry.Id);
      }
    }

    // Create Order item
    List<OrderItem> orderItems = new List<OrderItem>();
    Integer j = 0;
    for (Integer i = 0; i < 9; i++) {
      OrderItem orderItem = new OrderItem();
      orderItem.OrderId = i < 3
        ? orderList[0].Id
        : (i > 2 && i < 6) ? orderList[1].Id : orderList[2].Id;
      orderItem.Selling_Price__c = 15;
      orderItem.Product2Id = products[j].Id;
      orderItem.UnitPrice = 100;
      orderItem.Item_Number__c = i;
      orderItem.Min_Rate__c = 2;
      orderItem.Daily_Rate__c = 2.0;
      orderItem.Weekly_Rate__c = 2.0;
      orderItem.Monthly_Rate__c = 2.0;
      orderItem.Order_Item_Unit_Of_Measure__c = 'A';
      orderItem.PricebookEntryId = mapPBE.get(products[j].Id);
      if (i == 0 || i == 3 || i == 6) {
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
      } else if (i == 1 || i == 4 || i == 7) {
        orderItem.Quantity = 3;
      } else if (i == 2 || i == 5 || i == 8) {
        orderItem.Quantity = 3;
        orderItem.Misc_Charges_Type__c = 'TRANSPORTATION CHARGE';
        orderItem.Misc_Charge__c = 20.3;
        orderItem.Misc_Charges_Tax__c = 2.34;
        orderItem.Taxable__c = false;
        orderItem.Misc_Charges_Non_Taxable__c = false;
        orderItem.Misc_Charges_Item_Tax_Rate__c = 2.0;
      }
      j++;
      if (i == 3 || i == 6) {
        j = 0;
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
    } else if (successTest) {
      List<OrderItem> orderItems = [SELECT Id, OrderItemNumber FROM OrderItem];
      res.setBody(
        '{"data":{"rmContractId":"119277476","sfOrderId":"00339042","detailSeqNumber":"188","lines":[' +
          '{"lineNumber":1491900,"rmLineNumber":1,"rmLineType":"RI","rmItemNumber":"10564489","sfLineNumber":"' +
          orderItems.get(0).OrderItemNumber +
          '","rmStockClass":"ABC","rmProductSku":124567},' +
          '{"lineNumber":1491902,"rmLineNumber":1,"rmLineType":"SI","rmItemNumber":"ALRC TEST M","sfLineNumber":"' +
          orderItems.get(1).OrderItemNumber +
          '","rmStockClass":"MISC","rmProductSku":11965680},' +
          '{"lineNumber":1491903,"rmLineNumber":2,"rmLineType":"XC","rmItemNumber":"NCHERS001","sfLineNumber":"' +
          orderItems.get(2).OrderItemNumber +
          '","rmStockClass":"MISC","rmProductSku":10098310},' +
          '{"lineNumber":1492903,"rmLineNumber":2,"rmLineType":"XC","rmItemNumber":"ENVIRONMENTAL","sfLineNumber":"",' +
          '"rmStockClass":"MISC","rmProductSku":10198311}' +
          ']}}'
      );
      res.setStatusCode(200);
    } else {
      res.setBody(
        '{ "error": { "message": "Invalid input parameters, parameters might contain special characters,' +
          ' SQL statements or script statements. Please check application logs for more information.", ' +
          '"errorKey": "BAD_REQUEST", "errorCode": "400-000" } }'
      );
      res.setStatusCode(400);
    }
    return res;
  }

  @isTest
  static void testCreateContract() {
    Order order = [SELECT Id, EndDate FROM Order WHERE Name = 'Test Order-01'];
    List<OrderItem> orderItemList = [
      SELECT Id
      FROM OrderItem
      WHERE Global_Line_Number__c = NULL AND OrderId = :order.Id
    ];
    System.assertEquals(
      3,
      orderItemList.size(),
      'Global_Line_Number__c field should be null on existing Order Items'
    );
    Test.startTest();
    Test.setMock(
      HttpCalloutMock.class,
      new SBR_3_0_CreateContractService_Test()
    );
    SBR_3_0_CreateContractService.submitContract(order.Id);
    Test.stopTest();
    orderItemList = [
      SELECT Global_Line_Number__c
      FROM OrderItem
      WHERE OrderId = :order.Id
    ];
    System.assertEquals(
      3,
      orderItemList.size(),
      'Global_Line_Number__c field should be updated on existing Order Items'
    );
  }

  @isTest
  static void testCreateContractWithGuestAccount() {
    Order order = [SELECT Id, EndDate FROM Order WHERE Name = 'Test Order-02'];
    List<OrderItem> orderItemList = [
      SELECT Id
      FROM OrderItem
      WHERE Global_Line_Number__c = NULL AND OrderId = :order.Id
    ];
    System.assertEquals(
      3,
      orderItemList.size(),
      'Global_Line_Number__c field should be null on existing Order Items'
    );
    Test.startTest();
    Test.setMock(
      HttpCalloutMock.class,
      new SBR_3_0_CreateContractService_Test()
    );
    SBR_3_0_CreateContractService.submitContract(order.Id);
    Test.stopTest();
    orderItemList = [
      SELECT Global_Line_Number__c
      FROM OrderItem
      WHERE OrderId = :order.Id
    ];
    System.assertEquals(
      3,
      orderItemList.size(),
      'Global_Line_Number__c field should be updated on existing Order Items'
    );
  }

  @isTest
  static void testCreateContractWithCreditAccount() {
    Order order = [SELECT Id, EndDate FROM Order WHERE Name = 'Test Order-03'];
    List<OrderItem> orderItemList = [
      SELECT Id
      FROM OrderItem
      WHERE Global_Line_Number__c = NULL AND OrderId = :order.Id
    ];
    System.assertEquals(
      3,
      orderItemList.size(),
      'Global_Line_Number__c field should be null on existing Order Items'
    );
    Test.startTest();
    Test.setMock(
      HttpCalloutMock.class,
      new SBR_3_0_CreateContractService_Test()
    );
    SBR_3_0_CreateContractService.submitContract(order.Id);
    Test.stopTest();
    orderItemList = [
      SELECT Global_Line_Number__c
      FROM OrderItem
      WHERE OrderId = :order.Id
    ];
    System.assertEquals(
      3,
      orderItemList.size(),
      'Global_Line_Number__c field should be updated on existing Order Items'
    );
  }

  @isTest
  static void testValidateData() {
    Test.startTest();
    SBR_3_0_CreateContractService contractInstance = new SBR_3_0_CreateContractService();
    Account account = new Account();
    Contact contact = new Contact();
    Order order = new Order();
    try {
      contact = new Contact();
      contact.LastName = 'Test';
      order = new Order();
      order.Order_By__r = contact;
      contractInstance.order = order;
      contractInstance.validateData();
    } catch (Exception e) {
      System.assertEquals(
        Label.SBR_3_0_OrderAPI_OrdrByFrstName_ErrMsg,
        e.getMessage(),
        'Exception should be thrown'
      );
    }

    try {
      contact = new Contact();
      contact.FirstName = 'Test';
      contact.LastName = 'Contact';
      order = new Order();
      order.Order_By__r = contact;
      contractInstance.order = order;
      contractInstance.validateData();
    } catch (Exception e) {
      System.assertEquals(
        Label.SBR_3_0_OrderAPI_OrderByEmail_ErrMsg,
        e.getMessage(),
        'Exception should be thrown'
      );
    }

    try {
      contact = new Contact();
      contact.FirstName = 'Test';
      contact.LastName = 'Contact';
      contact.Email = 'test@sunbeltrentals.com';
      order = new Order();
      order.Order_By__r = contact;
      contractInstance.order = order;
      contractInstance.validateData();
    } catch (Exception e) {
      System.assertEquals(
        Label.SBR_3_0_OrderAPI_OrderByPhone_ErrMsg,
        e.getMessage(),
        'Exception should be thrown'
      );
    }

    try {
      contact = new Contact();
      contact.FirstName = 'Test';
      contact.LastName = 'Contact';
      contact.Email = 'test@sunbeltrentals.com';
      contact.Phone = '99887766';
      order = new Order();
      order.Order_By__r = contact;
      contractInstance.order = order;
      contractInstance.validateData();
    } catch (Exception e) {
      System.assertEquals(
        Label.SBR_3_0_OrderAPI_OrderByPhoneNotValid_ErrMsg,
        e.getMessage(),
        'Exception should be thrown'
      );
    }

    try {
      contact = new Contact();
      contact.FirstName = 'Test';
      contact.LastName = 'Contact';
      contact.Email = 'test@sunbeltrentals.com';
      contact.Phone = '9988776600';
      User user = new User();
      order = new Order();
      order.Order_By__r = contact;
      order.Sales_Rep__r = user;
      contractInstance.order = order;
      contractInstance.validateData();
    } catch (Exception e) {
      System.assertEquals(
        Label.SBR_3_0_OrderAPI_SalesRepId_ErrMsg,
        e.getMessage(),
        'Exception should be thrown'
      );
    }

    try {
      contact = new Contact();
      contact.FirstName = 'Test';
      contact.LastName = 'Contact';
      contact.Email = 'test@sunbeltrentals.com';
      contact.Phone = '9988776600';
      User user = new User();
      user.RepID__c = '18240';
      order = new Order();
      order.Order_By__r = contact;
      order.Sales_Rep__r = user;
      contractInstance.order = order;
      contractInstance.validateData();
    } catch (Exception e) {
      System.assertEquals(
        Label.SBR_3_0_OrderAPI_ReturnDate_ErrMsg,
        e.getMessage(),
        'Order Return Date is null exception should be thrown'
      );
    }

    try {
      account = new Account();
      account.Record_Type_Text__c = 'Credit';
      contact = new Contact();
      contact.FirstName = 'Test';
      contact.LastName = 'Contact';
      contact.Email = 'test@sunbeltrentals.com';
      contact.Phone = '9988776600';
      User user = new User();
      user.RepID__c = '18240';
      order = new Order();
      order.Return_Date__c = Date.today().addDays(15);
      order.Order_By__r = contact;
      order.Sales_Rep__r = user;
      order.Account = account;
      contractInstance.order = order;
      contractInstance.validateData();
    } catch (Exception e) {
      System.assertEquals(
        Label.SBR_3_0_OrderAPI_RMAccNumber_ErrMsg,
        e.getMessage(),
        'Order RM Account Number is null exception should be thrown'
      );
    }

    try {
      String accountStr = '{"attributes":{"type":"Account"},"Record_Type_Text__c": "Credit"}';
      String contactStr = '{"attributes":{"type":"Contact"},"FirstName": "Test","LastName": "Con","Email": "test@sunbeltrentals.com","Phone": "9988776600"}';
      String userStr = '{"attributes":{"type":"User"},"RepID__c": "18240"}';
      String orderStr =
        '{"attributes":{"type":"Order"},"RM_Account_Number__c":"19340158","Return_Date__c": "2024-05-05","Order_By__r":' +
        contactStr +
        ',"Sales_Rep__r":' +
        userStr +
        ',"Account":' +
        accountStr +
        '}';
      contractInstance.order = (Order) JSON.deserialize(orderStr, Order.class);
      contractInstance.validateData();
    } catch (Exception e) {
      System.assertEquals(
        Label.SBR_3_0_OrderAPI_AccPhone_ErrMsg,
        e.getMessage(),
        'Account Phone is null exception should be thrown'
      );
    }

    try {
      String accountStr = '{"attributes":{"type":"Account"},"Record_Type_Text__c": "Credit","Phone":"8899776655"}';
      String contactStr = '{"attributes":{"type":"Contact"},"FirstName": "Test","LastName": "Con","Email": "test@sunbeltrentals.com","Phone": "9988776600"}';
      String userStr = '{"attributes":{"type":"User"},"RepID__c": "18240"}';
      String orderStr =
        '{"attributes":{"type":"Order"},"RM_Account_Number__c":"19340158","Return_Date__c": "2024-05-05","Order_By__r":' +
        contactStr +
        ',"Sales_Rep__r":' +
        userStr +
        ',"Account":' +
        accountStr +
        '}';
      contractInstance.order = (Order) JSON.deserialize(orderStr, Order.class);
      contractInstance.validateData();
    } catch (Exception e) {
      System.assertEquals(
        Label.SBR_3_0_OrderAPI_Jobsite_ErrMsg,
        e.getMessage(),
        'Jobsite is null xception should be thrown'
      );
    }

    try {
      String locationStr = '{"attributes":{"type":"AssociatedLocation"},"Name__c": "Test Location"}';
      String accountStr = '{"attributes":{"type":"Account"},"Record_Type_Text__c": "Credit","Phone":"8899776655"}';
      String contactStr = '{"attributes":{"type":"Contact"},"FirstName": "Test","LastName": "Con","Email": "test@sunbeltrentals.com","Phone": "9988776600"}';
      String userStr = '{"attributes":{"type":"User"},"RepID__c": "18240"}';
      String orderStr =
        '{"attributes":{"type":"Order"},"RM_Account_Number__c":"19340158","Return_Date__c": "2024-05-05","Order_By__r":' +
        contactStr +
        ',"Sales_Rep__r":' +
        userStr +
        ',"Account":' +
        accountStr +
        ',"Jobsite__r":' +
        locationStr +
        '}';
      contractInstance.order = (Order) JSON.deserialize(orderStr, Order.class);
      contractInstance.validateData();
    } catch (Exception e) {
      System.assertEquals(
        Label.SBR_3_0_OrderAPI_Branch_ErrMsg,
        e.getMessage(),
        'Jobsite Branch is null xception should be thrown'
      );
    }
    Test.stopTest();
  }

  @isTest
  static void testValidateProducts() {
    Test.startTest();
    Product2 product = new Product2();
    OrderItem orderItem = new OrderItem();
    try {
      SBR_3_0_CreateContractService contractInstance = new SBR_3_0_CreateContractService();
      contractInstance.validateProduct(orderItem);
    } catch (Exception e) {
      System.assertEquals(
        Label.SBR_3_0_OrderAPI_MinRate_ErrMsg,
        e.getMessage(),
        'Exception should be thrown'
      );
    }

    try {
      orderItem = new OrderItem();
      orderItem.Min_Rate__c = 123;
      SBR_3_0_CreateContractService contractInstance = new SBR_3_0_CreateContractService();
      contractInstance.validateProduct(orderItem);
    } catch (Exception e) {
      System.assertEquals(
        Label.SBR_3_0_OrderAPI_DailyRate_ErrMsg,
        e.getMessage(),
        'Exception should be thrown'
      );
    }

    try {
      orderItem = new OrderItem();
      orderItem.Min_Rate__c = 123;
      orderItem.Daily_Rate__c = 123;
      SBR_3_0_CreateContractService contractInstance = new SBR_3_0_CreateContractService();
      contractInstance.validateProduct(orderItem);
    } catch (Exception e) {
      System.assertEquals(
        Label.SBR_3_0_OrderAPI_WeeklyRate_ErrMsg,
        e.getMessage(),
        'Exception should be thrown'
      );
    }

    try {
      orderItem = new OrderItem();
      orderItem.Min_Rate__c = 123;
      orderItem.Daily_Rate__c = 123;
      orderItem.Weekly_Rate__c = 323;
      SBR_3_0_CreateContractService contractInstance = new SBR_3_0_CreateContractService();
      contractInstance.validateProduct(orderItem);
    } catch (Exception e) {
      System.assertEquals(
        Label.SBR_3_0_OrderAPI_MonthlyRate_ErrMsg,
        e.getMessage(),
        'Exception should be thrown'
      );
    }

    try {
      orderItem = new OrderItem();
      orderItem.Min_Rate__c = 123;
      orderItem.Daily_Rate__c = 123;
      orderItem.Weekly_Rate__c = 323;
      orderItem.Monthly_Rate__c = 823;
      SBR_3_0_CreateContractService contractInstance = new SBR_3_0_CreateContractService();
      contractInstance.validateProduct(orderItem);
    } catch (Exception e) {
      System.assertEquals(
        Label.SBR_3_0_OrderAPI_Quantity_ErrMsg,
        e.getMessage(),
        'Exception should be thrown'
      );
    }

    try {
      product = new Product2();
      orderItem = new OrderItem();
      orderItem.Min_Rate__c = 123;
      orderItem.Daily_Rate__c = 123;
      orderItem.Weekly_Rate__c = 323;
      orderItem.Monthly_Rate__c = 823;
      orderItem.Quantity = 1;
      orderItem.Product2 = product;
      SBR_3_0_CreateContractService contractInstance = new SBR_3_0_CreateContractService();
      contractInstance.validateProduct(orderItem);
    } catch (Exception e) {
      System.assertEquals(
        Label.SBR_3_0_OrderAPI_ProductCategory_ErrMsg,
        e.getMessage(),
        'Exception should be thrown'
      );
    }

    try {
      product = new Product2();
      product.Category__c = '007';
      orderItem = new OrderItem();
      orderItem.Min_Rate__c = 123;
      orderItem.Daily_Rate__c = 123;
      orderItem.Weekly_Rate__c = 323;
      orderItem.Monthly_Rate__c = 823;
      orderItem.Quantity = 1;
      orderItem.Product2 = product;
      SBR_3_0_CreateContractService contractInstance = new SBR_3_0_CreateContractService();
      contractInstance.validateProduct(orderItem);
    } catch (Exception e) {
      System.assertEquals(
        Label.SBR_3_0_OrderAPI_ProductClass_ErrMsg,
        e.getMessage(),
        'Exception should be thrown'
      );
    }

    Test.stopTest();
  }

  @isTest
  static void testValidateSalesItems() {
    Test.startTest();
    Product2 product = new Product2();
    OrderItem orderItem = new OrderItem();
    try {
      orderItem = new OrderItem();
      SBR_3_0_CreateContractService contractInstance = new SBR_3_0_CreateContractService();
      contractInstance.validateSaleItem(orderItem);
    } catch (Exception e) {
      System.assertEquals(
        Label.SBR_3_0_OrderAPI_QuantitySalesItem_ErrMsg,
        e.getMessage(),
        'Exception should be thrown'
      );
    }

    try {
      orderItem = new OrderItem();
      orderItem.Quantity = 1;
      SBR_3_0_CreateContractService contractInstance = new SBR_3_0_CreateContractService();
      contractInstance.validateSaleItem(orderItem);
    } catch (Exception e) {
      System.assertEquals(
        Label.SBR_3_0_OrderAPI_SellingPriceSalesItem_ErrMsg,
        e.getMessage(),
        'Exception should be thrown'
      );
    }

    try {
      orderItem = new OrderItem();
      orderItem.Quantity = 1;
      orderItem.Selling_Price__c = 123;
      SBR_3_0_CreateContractService contractInstance = new SBR_3_0_CreateContractService();
      contractInstance.validateSaleItem(orderItem);
    } catch (Exception e) {
      System.assertEquals(
        Label.SBR_3_0_OrderAPI_OrderItemUntOfMsr_ErrMsg,
        e.getMessage(),
        'Exception should be thrown'
      );
    }

    try {
      orderItem = new OrderItem();
      orderItem.Quantity = 1;
      orderItem.Selling_Price__c = 123;
      orderItem.Order_Item_Unit_Of_Measure__c = 'EA';
      SBR_3_0_CreateContractService contractInstance = new SBR_3_0_CreateContractService();
      contractInstance.validateSaleItem(orderItem);
    } catch (Exception e) {
      System.assertEquals(
        Label.SBR_3_0_OrderAPI_ProductOrderItemNumber_ErrMsg,
        e.getMessage(),
        'Exception should be thrown'
      );
    }

    try {
      product = new Product2();
      orderItem = new OrderItem();
      orderItem.Quantity = 1;
      orderItem.Selling_Price__c = 123;
      orderItem.Order_Item_Unit_Of_Measure__c = 'EA';
      orderItem.Product2 = product;
      SBR_3_0_CreateContractService contractInstance = new SBR_3_0_CreateContractService();
      contractInstance.validateSaleItem(orderItem);
    } catch (Exception e) {
      System.assertEquals(
        Label.SBR_3_0_OrderAPI_ProductOrderItemNumber_ErrMsg,
        e.getMessage(),
        'Exception should be thrown'
      );
    }

    try {
      product = new Product2();
      product.Item_Number__c = 'ENVIRONMENTAL';
      orderItem = new OrderItem();
      orderItem.Quantity = 1;
      orderItem.Selling_Price__c = 123;
      orderItem.Order_Item_Unit_Of_Measure__c = 'EA';
      orderItem.Product2 = product;
      SBR_3_0_CreateContractService contractInstance = new SBR_3_0_CreateContractService();
      contractInstance.validateSaleItem(orderItem);
    } catch (Exception e) {
      System.assertEquals(
        Label.SBR_3_0_OrderAPI_ProductStockClass_ErrMsg,
        e.getMessage(),
        'Exception should be thrown'
      );
    }

    try {
      product = new Product2();
      product.Item_Number__c = 'ENVIRONMENTAL';
      product.Stock_Class__c = 'MISC';
      orderItem = new OrderItem();
      orderItem.Quantity = 1;
      orderItem.Selling_Price__c = 123;
      orderItem.Order_Item_Unit_Of_Measure__c = 'EA';
      orderItem.Product2 = product;
      SBR_3_0_CreateContractService contractInstance = new SBR_3_0_CreateContractService();
      contractInstance.validateSaleItem(orderItem);
    } catch (Exception e) {
      System.assertEquals(
        Label.SBR_3_0_OrderAPI_ProductOrderItemNumber_ErrMsg,
        e.getMessage(),
        'Exception should be thrown'
      );
    }
    Test.stopTest();
  }
}