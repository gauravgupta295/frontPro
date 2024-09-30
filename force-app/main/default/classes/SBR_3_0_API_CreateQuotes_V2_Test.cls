@isTest(seeAllData=false)
public with sharing class SBR_3_0_API_CreateQuotes_V2_Test implements HttpCalloutMock {
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
    branchLocation.Latitude_Longitude__Longitude__s = -80.80209;
    branchLocation.Latitude_Longitude__Latitude__s = 35.275662;
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
      Rentalman_Quote_Id__c = '000086613723',
      Company_Code__c = '01',
      Show_Crew_Expense_Calculator__c = true,
      Branch__c = branchLocation.Id,
      Sourcing_Branch__c = branchLocation.Id,
      SBQQ__Primary__c = true,
      P_O_Num__c = '100',
      Ordered_by__c = contact.Id,
      Market_Segment__c = '01',
      SBQQ__SalesRep__c = testAdminUser.Id,
      Cash_Customer_Payment_Method__c = 'P'
    );
    insert quote;

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
        product.Product_Type__c = 'MISC Charge Items';
        product.Item_Number__c = '1285JC';
        product.Stock_Class__c = 'UJEKL';
      }
      products.add(product);
    }
    insert products;
    Test.startTest();
    SBQQ__QuoteLine__c quoteLine = new SBQQ__QuoteLine__c(
      SBQQ__Quote__c = quote.Id,
      SBQQ__Product__c = products[0].Id,
      Line_Composite_Key__c = 'Z23bb'
    );
    insert quoteLine;
    quoteLine.Daily_Rate__c = 9;
    quoteLine.Hourly_Rate__c = 9;
    quoteLine.Weekly_Rate__c = 9;
    quoteLine.Monthly_Rate__c = 9;
    quoteLine.Min_Rate__c = 9;
    quoteLine.SBQQ__Quantity__c = 9;
    update quoteLine;
    Test.stopTest();
  }

  public HTTPResponse respond(HTTPRequest req) {
    // Create a fake response
    HttpResponse res = new HttpResponse();
    res.setHeader('Content-Type', SBR_3_0_Constants.APP_JSON);
    if (req.getEndpoint().endsWithIgnoreCase('token')) {
      res.setBody('{"access_token":"test"}');
      res.setStatusCode(200);
    } else if (SUCCESSTEST) {
      SBQQ__QuoteLine__c quoteLine = [
        SELECT Id, SF_Line_Number__c
        FROM SBQQ__QuoteLine__c
        LIMIT 1
      ];
      res.setBody(
        '{"data":{"rmQuoteId":"000086613723","sfQuoteId":"109876","lines":[{"lineNumber":1900540,"rmLineNumber":1,"sfLineNumber":"' +
          quoteLine.SF_Line_Number__c +
          '","rmLineType":"VR","rmItemNumber":"1468000","rmStockClass":"","rmProductSku":""},{"lineNumber":1900541,"rmLineNumber":1,"sfLineNumber":"79462","rmLineType":"VS","rmItemNumber":"DIESEL","rmStockClass":"FUEL","rmProductSku":"10037527"},{"lineNumber":1900542,"rmLineNumber":2,"sfLineNumber":"0000079465","rmLineType":"YD","rmItemNumber":"DELIVERY","rmStockClass":"DEL","rmProductSku":"10036685"},{"lineNumber":1900543,"rmLineNumber":3,"sfLineNumber":"0000079466","rmLineType":"YD","rmItemNumber":"PICKUP","rmStockClass":"DEL","rmProductSku":"10106520"}]}}'
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
    Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_CreateQuotes_V2_Test());
    SBQQ__Quote__c order = [SELECT Id FROM SBQQ__Quote__c];
    Test.startTest();
    SBR_3_0_API_CreateQuotesV2.submitQuote(order.Id);
    Test.stopTest();

    SBQQ__Quote__c newOrder = [
      SELECT Id, Rentalman_Quote_Id__c
      FROM SBQQ__Quote__c
    ];
    System.assertEquals('000086613723', newOrder.Rentalman_Quote_Id__c);
  }

  @isTest
  static void testCreateQuotesFail() {
    SUCCESSTEST = false;
    Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_CreateQuotes_V2_Test());
    SBQQ__Quote__c order = [SELECT Id FROM SBQQ__Quote__c];

    Test.startTest();
    try {
      SBR_3_0_API_CreateQuotesV2.submitQuote(order.Id);
    } catch (Exception e) {
      System.assertNotEquals(null, e, 'Exception should be thrown');
    }
    Test.stopTest();
  }

  @isTest
  static void testCreateQuotesAccountTypeCreditError() {
    Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_CreateQuotes_V2_Test());
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
    SBQQ__Quote__c order = [SELECT Id FROM SBQQ__Quote__c];
    Test.startTest();
    try {
      SBR_3_0_API_CreateQuotesV2.submitQuote(order.Id);
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
      SBR_3_0_API_CreateQuotesV2.submitQuote(order.Id);
    } catch (Exception e) {
    }
    Test.stopTest();
  }

  @isTest
  static void testQuoteException() {
    Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_CreateQuotes_V2_Test());
    SBQQ__Quote__c quote = [
      SELECT Id, P_O_Num__c, Market_Segment__c
      FROM SBQQ__Quote__c
    ];
    Test.startTest();
    try {
      quote.P_O_Num__c = '100';
      quote.Market_Segment__c = '01';
      quote.End_Date__c = null;
      update quote;
      SBR_3_0_API_CreateQuotesV2.submitQuote(quote.Id);
    } catch (Exception e) {
      System.assertEquals(
        'Return date is required.',
        e.getMessage(),
        'Exception should be thrown'
      );
    }
    Test.stopTest();
  }
  @isTest
  static void testContactException() {
    Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_CreateQuotes_V2_Test());
    SBQQ__Quote__c quote = [
      SELECT Id, P_O_Num__c, Market_Segment__c
      FROM SBQQ__Quote__c
    ];
    Contact con = [SELECT Id FROM contact];
    Test.startTest();
    try {
      con.Email = null;
      update con;
      SBR_3_0_API_CreateQuotesV2.submitQuote(quote.Id);
    } catch (Exception e) {
      System.assertEquals(
        'Email of ordered by is required.',
        e.getMessage(),
        'Exception should be thrown'
      );
    }
    try {
      con.Email = 'test@test.com';
      con.Phone = '';
      update con;
      SBR_3_0_API_CreateQuotesV2.submitQuote(quote.Id);
    } catch (Exception e) {
      System.assertEquals(
        'Phone of ordered by is required.',
        e.getMessage(),
        'Exception should be thrown'
      );
    }
    Exception expx = null;
    try {
      con.Email = 'test@test.com';
      con.Phone = '1234';
      update con;
      SBR_3_0_API_CreateQuotesV2.submitQuote(quote.Id);
    } catch (Exception e) {
      expx = e;
    }
    System.assert(expx != null, 'Exception');
    try {
      con.Email = 'test@test.com';
      con.Phone = '1234567890';
      update con;
      quote.Jobsite__c = null;
      update quote;
      SBR_3_0_API_CreateQuotesV2.submitQuote(quote.Id);
    } catch (Exception e) {
      System.assertEquals(
        'Jobsite is required',
        e.getMessage(),
        'Exception should be thrown'
      );
    }
    Test.stopTest();
  }
  @isTest
  static void testAccountException() {
    Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_CreateQuotes_V2_Test());
    SBQQ__Quote__c quote = [
      SELECT Id, P_O_Num__c, Market_Segment__c
      FROM SBQQ__Quote__c
    ];
    Account acc = [SELECT Id FROM Account];
    SBQQ__QuoteLine__c qli = [SELECT Id FROM SBQQ__QuoteLine__c];
    Test.startTest();
    try {
      acc.Phone = null;
      update acc;
      SBR_3_0_API_CreateQuotesV2.submitQuote(quote.Id);
    } catch (Exception e) {
      System.assertEquals(
        'Phone of account is required.',
        e.getMessage(),
        'Exception should be thrown'
      );
    }
    Test.stopTest();
  }
  @isTest
  static void testQLIException() {
    Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_CreateQuotes_V2_Test());
    SBQQ__Quote__c quote = [
      SELECT Id, P_O_Num__c, Market_Segment__c
      FROM SBQQ__Quote__c
    ];
    SBQQ__QuoteLine__c qli = [SELECT Id FROM SBQQ__QuoteLine__c];
    Test.startTest();
    try {
      qli.Daily_Rate__c = null;
      update qli;
      SBR_3_0_API_CreateQuotesV2.submitQuote(quote.Id);
    } catch (Exception e) {
      System.assertEquals(
        'Daily rate is required for product.',
        e.getMessage(),
        'Exception should be thrown'
      );
    }
    try {
      qli.Daily_Rate__c = 9;
      qli.Hourly_Rate__c = 9;
      qli.Weekly_Rate__c = null;
      update qli;
      SBR_3_0_API_CreateQuotesV2.submitQuote(quote.Id);
    } catch (Exception e) {
      System.assertEquals(
        'Weekly Rate is required for Product',
        e.getMessage(),
        'Exception should be thrown'
      );
    }

    Test.stopTest();
  }
  @isTest
  static void testQLIRateException() {
    Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_CreateQuotes_V2_Test());
    SBQQ__Quote__c quote = [
      SELECT Id, P_O_Num__c, Market_Segment__c
      FROM SBQQ__Quote__c
    ];
    SBQQ__QuoteLine__c qli = [SELECT Id FROM SBQQ__QuoteLine__c];
    Test.startTest();
    try {
      qli.Monthly_Rate__c = null;
      update qli;
      SBR_3_0_API_CreateQuotesV2.submitQuote(quote.Id);
    } catch (Exception e) {
      System.assertEquals(
        'Montly Rate is required for Product',
        e.getMessage(),
        'Exception should be thrown'
      );
    }

    try {
      qli.Monthly_Rate__c = 9;
      qli.Min_Rate__c = null;
      update qli;
      SBR_3_0_API_CreateQuotesV2.submitQuote(quote.Id);
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
  static void testNCACcount() {
    Account acc = [SELECT Id FROM Account];
    acc.Record_Type_Text__c = 'Non-Credit';
    update acc;
    SBQQ__Quote__c quote = [
      SELECT Id, P_O_Num__c, Market_Segment__c
      FROM SBQQ__Quote__c
    ];
    Test.startTest();
    Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_CreateQuotes_V2_Test());
    SBR_3_0_API_CreateQuotesV2.submitQuote(quote.Id);
    Test.stopTest();
  }
  @isTest
  static void testCreateAPI() {
    SBQQ__Quote__c quote = [
      SELECT Id, P_O_Num__c, Market_Segment__c
      FROM SBQQ__Quote__c
    ];
    quote.Rentalman_Quote_Id__c = null;
    update quote;
    Test.startTest();
    Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_CreateQuotes_V2_Test());
    SBR_3_0_API_CreateQuotesV2.submitQuote(quote.Id);
    Test.stopTest();

    SBQQ__Quote__c newQuote = [
      SELECT Id, Rentalman_Quote_Id__c
      FROM SBQQ__Quote__c
    ];
    System.assertEquals('000086613723', newQuote.Rentalman_Quote_Id__c);
  }
  @isTest
  static void testNullBranch() {
    SBQQ__Quote__c quote = [
      SELECT Id, P_O_Num__c, Market_Segment__c
      FROM SBQQ__Quote__c
    ];
    quote.Sourcing_Branch__c = null;
    update quote;
    Test.startTest();
    Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_CreateQuotes_V2_Test());
    SBR_3_0_API_CreateQuotesV2.submitQuote(quote.Id);
    Test.stopTest();

    SBQQ__Quote__c newQuote = [
      SELECT Id, Rentalman_Quote_Id__c
      FROM SBQQ__Quote__c
    ];
    System.assertEquals('000086613723', newQuote.Rentalman_Quote_Id__c);
  }
  @isTest
  static void testSalesQLIException() {
    Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_CreateQuotes_V2_Test());
    SBQQ__Quote__c quote = [
      SELECT Id, P_O_Num__c, Market_Segment__c
      FROM SBQQ__Quote__c
    ];
    Product2 product = [
      SELECT Id
      FROM Product2
      WHERE Product_Type__c = 'MISC Charge Items'
    ];
    SBQQ__QuoteLine__c quoteLine = new SBQQ__QuoteLine__c(
      SBQQ__Quote__c = quote.Id,
      SBQQ__Product__c = product.Id,
      Line_Composite_Key__c = 'Z23ab',
      SBQQ__Quantity__c = 9,
      is_User_Added__c = true,
      Selling_Price__c = 10
    );
    insert quoteLine;
    Test.startTest();
    SBR_3_0_API_CreateQuotesV2.submitQuote(quote.Id);
    try {
      quoteLine.Selling_Price__c = null;
      update quoteLine;
      SBR_3_0_API_CreateQuotesV2.submitQuote(quote.Id);
    } catch (Exception e) {
      System.assertEquals(
        'Selling Price is required for SaleItem',
        e.getMessage(),
        'Exception should be thrown'
      );
    }
    Test.stopTest();
  }
}