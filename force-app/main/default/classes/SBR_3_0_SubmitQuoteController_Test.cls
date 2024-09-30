/*********************************************************************************************************************
* Apex Class: SBR_3_0_SubmitQuoteController_Test
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Test class for SBR_3_0_SubmitQuoteController
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Davinder Singh         2022-12-05          Initial version    
*********************************************************************************************************************/
@isTest
public with sharing class SBR_3_0_SubmitQuoteController_Test implements HttpCalloutMock {
  static Boolean SUCCESSTEST = true;
  @TestSetup
  static void makeData() {
    Credential__c cred = SBR_3_0_TestDataFactory.createCredentials(1, false)[0];
    cred.Name = 'Mule_Token_Endpoint';
    cred.Key_Id__c = 'testKey123';
    cred.Secret__c = 'secret';
    insert cred;

    Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User'];
    User user = new User(
      Alias = 'standt',
      Email = 'standardperson@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = p.Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'standardperson@testorg.com'
    );

    insert user;

    List<Account> accounts = new List<Account>();
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
    accounts.add(acct);

    Account prospectAccount = new Account();
    prospectAccount.RM_Account_Number__c = '3';
    prospectAccount.Company_Code__c = '01';
    prospectAccount.Name = 'Test Prospect Account';
    prospectAccount.Record_Type_Text__c = 'Prospect';
    prospectAccount.E_mail_Address__c = '1234@asdf.com';
    prospectAccount.Phone = '22113344';
    prospectAccount.BillingStreet = '23 Cornelia Street';
    prospectAccount.BillingCity = 'New York';
    prospectAccount.BillingPostalCode = '101014';
    prospectAccount.BillingState = 'NY';
    prospectAccount.BillingCountry = 'US';
    prospectAccount.Drivers_License__c = 'AKF';
    prospectAccount.Driver_s_License_State__c = 'AL';
    accounts.add(prospectAccount);

    insert accounts;
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
    insert branchLocation;
    // Create Job Site
    List<AssociatedLocation> jobSites = new List<AssociatedLocation>();
    AssociatedLocation jobSite = new AssociatedLocation(
      Name__c = 'Test Job Site',
      ParentRecordId = acct.Id,
      LocationId = jobLocation.Id,
      Branch__c = branchLocation.Id,
      Job_Number__c = '20221004A'
    );
    jobSites.add(jobSite);
    AssociatedLocation jobSite2 = new AssociatedLocation(
      Name__c = 'Test Job Site2',
      ParentRecordId = prospectAccount.Id,
      LocationId = jobLocation.Id,
      Branch__c = branchLocation.Id,
      Job_Number__c = '20221004A'
    );
    jobSites.add(jobSite2);
    insert jobSites;

    // Create Quote
    List<SBQQ__Quote__c> quotes = new List<SBQQ__Quote__c>();
    SBQQ__Quote__c quote1 = new SBQQ__Quote__c(
      Quote_Name__c = 'Test Quote1',
      SBQQ__Account__c = acct.Id,
      Jobsite__c = jobSite.Id,
      SBQQ__DeliveryMethod__c = 'Delivery',
      Start_Date__c = date.valueOf('2022-10-07 12:00:00'),
      End_Date__c = date.valueOf('2022-10-08 8:00:00'),
      Delivery_Date__c = date.valueOf('2022-10-07 12:00:00'),
      Opt_Out_RPP__c = false,
      Opt_Out_Fuel_Charge__c = false,
      Selling_Channel__c = 'SBRB2B'
    );
    quotes.add(quote1);

    DateTime currentDateTime = DateTime.now();
    SBQQ__Quote__c quote2 = new SBQQ__Quote__c(
      Quote_Name__c = 'Test Quote2',
      SBQQ__Account__c = prospectAccount.Id,
      Jobsite__c = jobSite2.Id,
      SBQQ__DeliveryMethod__c = 'Delivery',
      Start_Date__c = currentDateTime.addDays(1),
      End_Date__c = currentDateTime.addDays(2),
      Delivery_Date__c = date.valueOf('2022-10-07 12:00:00'),
      Opt_Out_RPP__c = false,
      Opt_Out_Fuel_Charge__c = false,
      Selling_Channel__c = 'SBRB2B'
    );
    quotes.add(quote2);

    SBQQ__Quote__c quote3 = new SBQQ__Quote__c(
      Quote_Name__c = 'Test Quote3',
      SBQQ__Account__c = prospectAccount.Id,
      Jobsite__c = jobSite2.Id,
      SBQQ__DeliveryMethod__c = 'Delivery',
      Start_Date__c = currentDateTime.addDays(1),
      End_Date__c = currentDateTime.addDays(2),
      Delivery_Date__c = currentDateTime.addDays(2),
      Opt_Out_RPP__c = false,
      Opt_Out_Fuel_Charge__c = false,
      Selling_Channel__c = 'SBRB2B'
    );
    quotes.add(quote3);

    insert quotes;
    // Create Price Book
    Pricebook2 priceBook = new Pricebook2(
      Id = Test.getStandardPricebookId(),
      IsActive = true
    );
    update priceBook;
    SVMXA360__SM_TA_Template__c smTaTemplate = new SVMXA360__SM_TA_Template__c();
    smTaTemplate.Name = 'SBR 3.0 Maintenance Template';
    smTaTemplate.SVMXA360__DeveloperName__c = 'SBR_3_0_Maintenance_Template';
    insert smTaTemplate;
    // Create Product
    List<Product2> products = new List<Product2>();
    for (Integer i = 0; i < 3; i++) {
      Product2 product = new Product2();
      product.Name = 'Test Product ' + i;
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
    // Create Quote Line
    List<SBQQ__QuoteLine__c> quoteLines = new List<SBQQ__QuoteLine__c>();
    for (Integer i = 0; i < 3; i++) {
      SBQQ__QuoteLine__c quoteLine = new SBQQ__QuoteLine__c();
      quoteLine.SBQQ__Quote__c = quote1.Id;
      quoteLine.SBQQ__Product__c = products[i].Id;
      if (i == 0) {
        quoteLine.Hourly_Rate__c = 2.0;
        quoteLine.Min_Rate__c = 2.0;
        quoteLine.SBQQ__Quantity__c = 5;
        quoteLine.Free_Flag__c = false;
        quoteLine.Suggested_Daily_Rate__c = 2.0;
        quoteLine.Suggested_Weekly_Rate__c = 2.0;
        quoteLine.Suggested_Monthly_Rate__c = 2.0;
        quoteLine.Daily_Rate__c = 2.0;
        quoteLine.Weekly_Rate__c = 2.0;
        quoteLine.Monthly_Rate__c = 2.0;
        quoteLine.Rates_Overriden__c = false;
        quoteLine.Line_Comments__c = 'Comments';
        quoteLine.SBQQ__Number__c = 5;
      } else if (i == 1) {
        quoteLine.SBQQ__Quantity__c = 3;
        quoteLine.SBQQ__ListPrice__c = 20.0;
      } else {
        quoteLine.Misc_Charges_Type__c = 'TRANSPORTATION CHARGE';
        quoteLine.Misc_Charge__c = 20.3;
        quoteLine.Misc_Charges_Tax__c = 2.34;
        quoteLine.SBQQ__Taxable__c = false;
        quoteLine.Misc_Charges_Non_Taxable__c = false;
        quoteLine.Misc_Charges_Item_Tax_Rate__c = 2.0;
      }
      quoteLines.add(quoteLine);
    }
    insert quoteLines;
  }

  public HTTPResponse respond(HTTPRequest req) {
    // Create a fake response
    HttpResponse res = new HttpResponse();
    res.setHeader('Content-Type', SBR_3_0_Constants.APP_JSON);
    if (req.getEndpoint().endsWithIgnoreCase('token')) {
      res.setBody('{"access_token":"test"}');
      res.setStatusCode(200);
    } else if (SUCCESSTEST) {
      res.setBody('{ "data": { "rmQuoteId": "000086613723" } }');
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
  static void testUserPerms() {
    SBQQ__Quote__c quote = [
      SELECT Id
      FROM SBQQ__Quote__c
      WHERE Quote_Name__c = 'Test Quote1'
    ];

    Test.startTest();
    SBR_3_0_SubmitQuoteController.PermissionWrapper permsWrapperQuote = SBR_3_0_SubmitQuoteController.checkUpdateablePermission(
      quote.Id
    );
    Test.stopTest();

    System.assertEquals(permsWrapperQuote.hasPermission, true);
  }

  @isTest
  static void testUserPermsStandardUser() {
    User u = [
      SELECT ID
      FROM User
      WHERE Email = 'standardperson@testorg.com'
      LIMIT 1
    ];

    SBQQ__Quote__c quote = [
      SELECT Id
      FROM SBQQ__Quote__c
      WHERE Quote_Name__c = 'Test Quote1'
    ];
    SBR_3_0_SubmitQuoteController.PermissionWrapper permsWrapperQuote;

    Test.startTest();
    System.runAs(u) {
      permsWrapperQuote = SBR_3_0_SubmitQuoteController.checkUpdateablePermission(
        quote.Id
      );
    }
    Test.stopTest();

    System.assertEquals(permsWrapperQuote.hasPermission, false);
  }

  @isTest
  static void testSubmitQuote() {
    SBQQ__Quote__c quote = [
      SELECT Id
      FROM SBQQ__Quote__c
      WHERE Quote_Name__c = 'Test Quote1'
    ];
    try {
      Test.startTest();
      Test.setMock(HttpCalloutMock.class, new SBR_3_0_UpdateTotals_Test());
      Boolean quoteRes = SBR_3_0_SubmitQuoteController.submitQuote(quote.Id);
      Test.stopTest();
    } catch (Exception e) {
      System.assertEquals(
        'Script-thrown exception',
        e.getMessage(),
        'Exception should be thrown'
      );
    }
  }

  @isTest
  static void testSubmitQuoteFail() {
    SBQQ__Quote__c quote = [
      SELECT Id
      FROM SBQQ__Quote__c
      WHERE Quote_Name__c = 'Test Quote2'
    ];
    try {
      Test.startTest();
      Test.setMock(HttpCalloutMock.class, new SBR_3_0_UpdateTotals_Test());
      Boolean quoteRes = SBR_3_0_SubmitQuoteController.submitQuote(quote.Id);
      Test.stopTest();
    } catch (Exception e) {
      System.assertEquals(
        'Script-thrown exception',
        e.getMessage(),
        'Exception should be thrown'
      );
    }
  }

  @isTest
  static void testSubmitQuoteFailStartDate() {
    SBQQ__Quote__c quote = [
      SELECT Id
      FROM SBQQ__Quote__c
      WHERE Quote_Name__c = 'Test Quote1'
    ];
    String message = SBR_3_0_SubmitQuoteController.checkRequiredData(quote.Id);
    System.assertEquals(
      message,
      'Start Date must be greater than or equal than the current day/time. Please update and try again',
      'Error message should be related to startDate'
    );
  }

  @isTest
  static void testSubmitQuoteFailDeliveryDate() {
    SBQQ__Quote__c quote = [
      SELECT Id
      FROM SBQQ__Quote__c
      WHERE Quote_Name__c = 'Test Quote2'
    ];
    String message = SBR_3_0_SubmitQuoteController.checkRequiredData(quote.Id);
    System.assertEquals(
      message,
      'Earliest Delivery Date must be greater than or equal than the current day/time. Please update and try again',
      'Error message should be related to Earliest Delivery Date'
    );
  }

  @isTest
  static void testSubmitQuoteFailDeliveryDateTwo() {
    SBQQ__Quote__c quote = [
      SELECT Id
      FROM SBQQ__Quote__c
      WHERE Quote_Name__c = 'Test Quote3'
    ];
    String message = SBR_3_0_SubmitQuoteController.checkRequiredData(quote.Id);
    System.assertEquals(
      message,
      'Earliest Delivery Date must be before or on the Start Date/Time. Please update and try again',
      'Error message should be related to Earliest Delivery Date'
    );
  }
}