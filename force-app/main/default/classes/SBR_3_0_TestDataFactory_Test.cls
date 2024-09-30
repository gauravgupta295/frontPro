/*********************************************************************************************************************
* Apex Class: SBR_3_0_TestDataFactory_Test
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* @description Class to test SBR_3_0_TestDataFactory
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Kunal Patel           2022-02-02            Initial version
	2.0			Sai Krishna Kotagiri  2022-05-03			Addedd validateCases() test method
    3.0         Viren Patel           2022-09-15            Increased coverage
    4.0         Tom Canter            2022-09-28            Equipment Type tests
    5.0			Bhavesh Dhamecha 	  2023-01-23			Updated for Bug SAL-8356
*********************************************************************************************************************/
@isTest
private with sharing class SBR_3_0_TestDataFactory_Test {
  @TestSetup
  static void makeData() {
    User admin = SBR_3_0_TestDataFactory.createUsersWithPermissions(
      1,
      true,
      'System Administrator',
      new Set<String>{
        'SalesUserPsl',
        'Integration API Access',
        'SalesforceCPQ_CPQStandardPerm'
      },
      new Set<String>{ 'Sales_User ', 'Branch_Manager1' }
    )[0];

    System.runAs(admin) {
      update new Pricebook2(
        Id = Test.getStandardPricebookId(),
        IsActive = true
      );
    }
  }

  @IsTest
  static void validateAccounts() {
    System.runAs([
        SELECT Id
        FROM User
        WHERE Username LIKE '%@sunbeltrentals.com.unittest'
        LIMIT 1
      ]
      .get(0)) {
      DescribeSObjectResult dsr = Account.SObjectType.getDescribe(
        SObjectDescribeOptions.DEFERRED
      );
      Id recordTypeId = SBR_3_0_TestDataFactory.getAvailableRecordTypeId(
        dsr,
        null
      );
      System.assertNotEquals(
        null,
        recordTypeId,
        'Expected non null record type Id.'
      );
      String recordTypeDeveloperName = [
        SELECT DeveloperName
        FROM RecordType
        WHERE Id = :recordTypeId
      ]
      ?.DeveloperName;

      // DO NOT INSERT RECORDS - FALSE
      SBR_3_0_TestDataFactory.createAccounts(15, false);
      SBR_3_0_TestDataFactory.createAccounts(
        15,
        false,
        recordTypeDeveloperName
      );
      SBR_3_0_TestDataFactory.createAccounts(15, true);
      SBR_3_0_TestDataFactory.createAccounts(15, true, recordTypeDeveloperName);
    }

    // INSERT RECORDS - TRUE
    List<Account> accounts = [SELECT Id, RecordTypeId FROM Account];
    System.assertEquals(30, accounts.size(), 'Accounts Size mismatch');
  }

  @IsTest
  static void validateContacts() {
    Integer count = 15;
    System.runAs([
        SELECT Id
        FROM User
        WHERE Username LIKE '%@sunbeltrentals.com.unittest'
        LIMIT 1
      ]
      .get(0)) {
      List<Account> accounts = SBR_3_0_TestDataFactory.createAccounts(1, true);
      SBR_3_0_TestDataFactory.createContacts(count, accounts[0].Id, true);
    }
    System.assertEquals(
      count,
      [SELECT Id FROM Contact]?.size(),
      'Contacts Size mismatch'
    );
  }

  @IsTest
  static void validateLeads() {
    System.runAs([
        SELECT Id
        FROM User
        WHERE Username LIKE '%@sunbeltrentals.com.unittest'
        LIMIT 1
      ]
      .get(0)) {
      Integer count = 15;

      List<Lead> leads = SBR_3_0_TestDataFactory.createLeads(count, false);
      leads = [SELECT ID FROM Lead];
      System.assertEquals(0, leads.size(), 'Leads Size mismatch');

      leads = SBR_3_0_TestDataFactory.createLeads(count, true);
      leads = [SELECT ID FROM Lead];
      System.assertEquals(count, leads.size(), 'Leads Size mismatch');
    }
  }

  @IsTest
  static void validateRandomizer() {
    Integer count = 30;

    Set<String> strings = new Set<String>();
    for (Integer i = 0; i < count; i++) {
      String s = SBR_3_0_TestDataFactory.generateRandomString(count);
      strings.add(s);
    }

    System.assertEquals(
      count,
      strings.size(),
      'Randomizer generated duplicate strings'
    );
  }

  @IsTest
  static void validateCases() {
    System.runAs([
        SELECT Id
        FROM User
        WHERE Username LIKE '%@sunbeltrentals.com.unittest'
        LIMIT 1
      ]
      .get(0)) {
      Integer count = 1;

      List<Account> accounts = SBR_3_0_TestDataFactory.createAccounts(1, true);
      Id accId = accounts[0].Id;
      List<Case> cases = SBR_3_0_TestDataFactory.createCaseForAnAccount(
        count,
        accId,
        true,
        'Email',
        '4 - Low'
      );

      cases = [SELECT ID FROM Case WHERE AccountId = :accId];
      System.assertEquals(count, cases.size(), 'Cases Size mismatch ');
    }
  }

  @IsTest
  static void validateProducts() {
    System.runAs([
        SELECT Id
        FROM User
        WHERE Username LIKE '%@sunbeltrentals.com.unittest'
        LIMIT 1
      ]
      .get(0)) {
      Integer count = 15;

      Test.startTest();
      List<Product2> pds = SBR_3_0_TestDataFactory.createProducts(count, false);
      pds = [SELECT ID FROM Product2];
      System.assertEquals(0, pds.size(), 'Products Size mismatch');

      pds = SBR_3_0_TestDataFactory.createProducts(count, true);
      pds = [SELECT ID FROM Product2];
      System.assertEquals(count, pds.size(), 'Leads Size match');
      SBQQ__ProductFeature__c oPF = SBR_3_0_TestDataFactory.createProductFeatures(
        true,
        pds[0].id
      );
      System.assertNotEquals(null, oPF, 'oPF was unexpectedly null');
      Test.stopTest();
    }
  }

  @IsTest
  static void validateStockedSerials() {
    System.runAs([
        SELECT Id
        FROM User
        WHERE Username LIKE '%@sunbeltrentals.com.unittest'
        LIMIT 1
      ]
      .get(0)) {
      Integer count = 15;

      List<Account> lstAccounts = SBR_3_0_TestDataFactory.createAccounts(
        count,
        true
      );
      //Create Contacts
      List<Contact> lstContacts = SBR_3_0_TestDataFactory.createContacts(
        count,
        lstAccounts[0].id,
        true
      );
      //Create Products
      List<Product2> lstProds = SBR_3_0_TestDataFactory.createProducts(1, true);
      //Create Locations
      List<Schema.Location> locs = SBR_3_0_TestDataFactory.createInventoryLocations(
        1,
        true,
        'Branch'
      );
      //Create Stocked Serials
      //Create ProductItems
      List<ProductItem> productItems = SBR_3_0_TestDataFactory.createProductItems(
        1,
        true,
        lstProds[0].id,
        locs[0].id
      );
      //Create the Assets
      List<Asset> lstAsssets = SBR_3_0_TestDataFactory.createAssets(
        1,
        true,
        lstAccounts[0].id,
        lstContacts[0].id,
        locs[0].id
      );

      List<Stocked_Serial__c> lstss = SBR_3_0_TestDataFactory.createStockedSerials(
        0,
        true,
        lstAsssets[0].id,
        lstProds[0].id,
        productItems[0].id
      );

      System.assertEquals(0, lstss.size(), 'Stocked Serials Size mismatch');

      lstss = SBR_3_0_TestDataFactory.createStockedSerials(
        count,
        true,
        lstAsssets[0].id,
        lstProds[0].id,
        productItems[0].id
      );
      System.assertEquals(count, lstss.size(), 'Stocked Serials Size match');
    }
  }

  @IsTest
  static void validateProductItems() {
    System.runAs([
        SELECT Id
        FROM User
        WHERE Username LIKE '%@sunbeltrentals.com.unittest'
        LIMIT 1
      ]
      .get(0)) {
      Integer count = 1;

      List<Product2> lstProds = SBR_3_0_TestDataFactory.createProducts(1, true);
      List<Schema.Location> locs = SBR_3_0_TestDataFactory.createInventoryLocations(
        1,
        true,
        'Branch'
      );

      List<ProductItem> lstProductItems = SBR_3_0_TestDataFactory.createProductItems(
        0,
        false,
        lstProds[0].id,
        locs[0].id
      );
      lstProductItems = [SELECT ID FROM ProductItem];
      System.assertEquals(
        0,
        lstProductItems.size(),
        'Product Items Size mismatch'
      );

      lstProductItems = SBR_3_0_TestDataFactory.createProductItems(
        count,
        true,
        lstProds[0].id,
        locs[0].id
      );
      lstProductItems = [SELECT ID FROM ProductItem];
      System.assertEquals(
        count,
        lstProductItems.size(),
        'Product Item Size match'
      );
    }
  }

  @IsTest
  static void validateLocations() {
    System.runAs([
        SELECT Id
        FROM User
        WHERE Username LIKE '%@sunbeltrentals.com.unittest'
        LIMIT 1
      ]
      .get(0)) {
      Integer count = 15;

      List<Schema.Location> locs = SBR_3_0_TestDataFactory.createLocations(
        count,
        false,
        'Branch'
      );
      locs = [SELECT ID FROM Location];
      System.assertEquals(0, locs.size(), 'Locations Size mismatch');
      count = 2;
      locs = SBR_3_0_TestDataFactory.createLocations(1, true, 'Branch');
      locs = [SELECT ID FROM Location];
      System.assertEquals(1, locs.size(), 'Locations Size match');
    }
  }

  @IsTest
  static void validateOpportunities() {
    System.runAs([
        SELECT Id
        FROM User
        WHERE Username LIKE '%@sunbeltrentals.com.unittest'
        LIMIT 1
      ]
      .get(0)) {
      Integer count = 1;
      List<Account> lstAccounts = SBR_3_0_TestDataFactory.createAccounts(
        count,
        true,
        'Prospect'
      ); // Updated for Bug SAL-8356

      List<Opportunity> opps = SBR_3_0_TestDataFactory.createOppts(
        count,
        lstAccounts[0].id,
        false
      );
      opps = [SELECT ID FROM Opportunity];
      System.assertEquals(0, opps.size(), 'Opportunity Size mismatch');

      opps = SBR_3_0_TestDataFactory.createOppts(
        count,
        lstAccounts[0].id,
        true
      );
      opps = [SELECT ID FROM Opportunity];
      System.assertEquals(count, opps.size(), 'Opportunity Size mismatch');
    }
  }

  @IsTest
  static void validateInventoryLocations() {
    System.runAs([
        SELECT Id
        FROM User
        WHERE Username LIKE '%@sunbeltrentals.com.unittest'
        LIMIT 1
      ]
      .get(0)) {
      Integer count = 15;

      List<Schema.Location> locs = SBR_3_0_TestDataFactory.createLocations(
        count,
        false,
        'Branch'
      );
      locs = [SELECT ID FROM Location];
      System.assertEquals(0, locs.size(), 'Locations Size mismatch');

      locs = SBR_3_0_TestDataFactory.createLocations(1, true, 'Branch');
      locs = [SELECT ID FROM Location];
      System.assertEquals(1, locs.size(), 'Locations Size match');
    }
  }

  @IsTest
  static void validateAssets() {
    System.runAs([
        SELECT Id
        FROM User
        WHERE Username LIKE '%@sunbeltrentals.com.unittest'
        LIMIT 1
      ]
      .get(0)) {
      Integer count = 1;
      Test.StartTest();
      List<Account> lstAccounts = SBR_3_0_TestDataFactory.createAccounts(
        count,
        true
      );
      List<Contact> lstContacts = SBR_3_0_TestDataFactory.createContacts(
        count,
        lstAccounts[0].id,
        true
      );
      List<Schema.Location> locs = SBR_3_0_TestDataFactory.createInventoryLocations(
        1,
        true,
        'Branch'
      );
      List<Asset> lstAssets = SBR_3_0_TestDataFactory.createAssets(
        1,
        false,
        lstAccounts[0].id,
        lstContacts[0].id,
        locs[0].id
      );
      lstAssets = [SELECT ID FROM Asset];
      System.assertEquals(0, lstAssets.size(), 'Assets Size mismatch');

      lstAssets = SBR_3_0_TestDataFactory.createAssets(
        1,
        true,
        lstAccounts[0].id,
        lstContacts[0].id,
        locs[0].id
      );
      lstAssets = [SELECT ID FROM Asset];
      System.assertEquals(count, lstAssets.size(), 'Asset Size match');

      List<Asset> lstAssets1 = SBR_3_0_TestDataFactory.createAssets(1, false);
      System.assertNotEquals(
        null,
        lstAssets1,
        'lstAssets1 was unexpectedly null.'
      );
      Test.StopTest();
    }
  }

  @IsTest
  static void validateUsers() {
    Integer count = 1;

    Test.StartTest();
    List<User> users = SBR_3_0_TestDataFactory.createUsers(count, true);
    System.assertEquals(
      count,
      users.size(),
      'Users list did not match expected size.'
    );
    Test.stopTest();
  }

  @IsTest
  static void validateAppointments() {
    System.runAs([
        SELECT Id
        FROM User
        WHERE Username LIKE '%@sunbeltrentals.com.unittest'
        LIMIT 1
      ]
      .get(0)) {
      Integer count = 1;

      Test.StartTest();
      List<Event> appt = SBR_3_0_TestDataFactory.createAppointments(
        count,
        null,
        null,
        true
      );
      System.assertEquals(
        count,
        appt.size(),
        'Appt list did not match expected size.'
      );
      Test.stopTest();
    }
  }

  @IsTest
  static void validateProjects() {
    System.runAs([
        SELECT Id
        FROM User
        WHERE Username LIKE '%@sunbeltrentals.com.unittest'
        LIMIT 1
      ]
      .get(0)) {
      Integer count = 1;

      Test.StartTest();
      List<Project__c> proj = SBR_3_0_TestDataFactory.createProjects(
        count,
        true
      );
      System.assertEquals(
        count,
        proj.size(),
        'Project did not match expected size.'
      );
      Test.stopTest();
    }
  }

  @IsTest
  static void validateProjectsNew() {
    System.runAs([
        SELECT Id
        FROM User
        WHERE Username LIKE '%@sunbeltrentals.com.unittest'
        LIMIT 1
      ]
      .get(0)) {
      Integer count = 1;

      Test.StartTest();
      List<Project__c> proj = SBR_3_0_TestDataFactory.createProjectsNew(
        count,
        true
      );
      System.assertEquals(
        count,
        proj.size(),
        'Project did not match expected size.'
      );
      Test.stopTest();
    }
  }

  @IsTest
  static void validateCampaigns() {
    System.runAs([
        SELECT Id
        FROM User
        WHERE Username LIKE '%@sunbeltrentals.com.unittest'
        LIMIT 1
      ]
      .get(0)) {
      Integer count = 1;

      Test.StartTest();
      List<Campaign> campaigns = SBR_3_0_TestDataFactory.createCampaigns(
        count,
        true,
        'Marketing'
      );
      System.assertEquals(
        count,
        campaigns.size(),
        'Campaigns did not match expected size.'
      );
      Test.stopTest();
    }
  }

  @IsTest
  static void validateContracts() {
    System.runAs([
        SELECT Id
        FROM User
        WHERE Username LIKE '%@sunbeltrentals.com.unittest'
        LIMIT 1
      ]
      .get(0)) {
      Test.StartTest();
      Account a = (SBR_3_0_TestDataFactory.createAccounts(1, true))[0];
      List<Contract> contracts = SBR_3_0_TestDataFactory.createContracts(
        1,
        a.Id,
        2,
        'Draft',
        true
      );
      System.assertEquals(
        1,
        contracts.size(),
        'Contracts list did not match expected size.'
      );
      Test.stopTest();
    }
  }

  @IsTest
  static void validateTasks() {
    Test.StartTest();
    List<Task> tasks;
    System.runAs([
        SELECT Id
        FROM User
        WHERE Username LIKE '%@sunbeltrentals.com.unittest'
        LIMIT 1
      ]
      .get(0)) {
      Account a = (SBR_3_0_TestDataFactory.createAccounts(1, true))[0];
      tasks = SBR_3_0_TestDataFactory.createTasks(
        1,
        a.Id,
        null,
        UserInfo.getUserId(),
        true
      );
    }
    Test.stopTest();

    System.assertEquals(1, tasks.size(), 'Tasks did not match expected size.');
  }

  @IsTest
  static void validateCreds() {
    Integer count = 1;

    Test.StartTest();
    List<Credential__c> credentials = SBR_3_0_TestDataFactory.createCredentials(
      count,
      true
    );
    System.assertEquals(
      count,
      credentials.size(),
      'Credentials did not match expected size.'
    );
    Test.stopTest();
  }

  @IsTest
  static void validateCases2() {
    System.runAs([
        SELECT Id
        FROM User
        WHERE Username LIKE '%@sunbeltrentals.com.unittest'
        LIMIT 1
      ]
      .get(0)) {
      Integer count = 1;

      Test.StartTest();
      List<Case> cases = SBR_3_0_TestDataFactory.createCases(count, true);
      System.assertEquals(
        count,
        cases.size(),
        'Cases did not match expected size.'
      );
      Test.stopTest();
    }
  }

  @IsTest
  static void validateEquipmentOnHold() {
    System.runAs([
        SELECT Id
        FROM User
        WHERE Username LIKE '%@sunbeltrentals.com.unittest'
        LIMIT 1
      ]
      .get(0)) {
      Integer count = 1;

      Test.StartTest();
      List<Account> lstAccounts = SBR_3_0_TestDataFactory.createAccounts(
        count,
        true
      );
      List<Contact> lstContacts = SBR_3_0_TestDataFactory.createContacts(
        count,
        lstAccounts[0].id,
        true
      );
      List<Schema.Location> locs = SBR_3_0_TestDataFactory.createInventoryLocations(
        1,
        true,
        'Branch'
      );
      List<Asset> lstAssets = SBR_3_0_TestDataFactory.createAssets(
        1,
        false,
        lstAccounts[0].id,
        lstContacts[0].id,
        locs[0].id
      );
      List<Equipment_on_Hold__c> eh = SBR_3_0_TestDataFactory.createEquipmentOnHold(
        count,
        true,
        lstAssets[0].Id,
        'strassetId'
      );
      System.assertEquals(
        count,
        eh.size(),
        'Equipment on hold did not match expected size.'
      );
      Test.stopTest();
    }
  }

  @IsTest
  static void validateAcctRelationship() {
    System.runAs([
        SELECT Id
        FROM User
        WHERE Username LIKE '%@sunbeltrentals.com.unittest'
        LIMIT 1
      ]
      .get(0)) {
      Integer count = 1;

      Test.StartTest();
      Account a = (SBR_3_0_TestDataFactory.createAccounts(1, true))[0];
      List<Account_Relationship__c> ars = SBR_3_0_TestDataFactory.createAccountRelationships(
        count,
        a.Id,
        true
      );
      System.assertEquals(
        count,
        ars.size(),
        'Number of account relationships did not match expected size'
      );
      Test.stopTest();
    }
  }

  @IsTest
  static void validateEquipmentTypes() {
    System.runAs([
        SELECT Id
        FROM User
        WHERE Username LIKE '%@sunbeltrentals.com.unittest'
        LIMIT 1
      ]
      .get(0)) {
      Integer count = 1;
      Test.startTest();
      List<Equipment_Type__c> equipmentType = SBR_3_0_TestDataFactory.createEquipmentTypes(
        count,
        true
      );
      equipmentType = [SELECT ID FROM Equipment_Type__c];
      System.assertEquals(
        1,
        equipmentType.size(),
        'Equipment_Type__c Size mismatch'
      );
      Test.stopTest();
    }
  }

  @IsTest
  static void testCreateOrder() {
    System.runAs([
        SELECT Id
        FROM User
        WHERE Username LIKE '%@sunbeltrentals.com.unittest'
        LIMIT 1
      ]
      .get(0)) {
      Test.StartTest();
      Id contractOrderRecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName()
        .get('Contract_Order')
        .getRecordTypeId();
      Order order = SBR_3_0_TestDataFactory.createOrder(
        true,
        'Test Order',
        contractOrderRecordTypeId
      );
      System.assertNotEquals(null, order, 'Order was unexpectedly null');
      Test.stopTest();
    }
  }

  @IsTest
  static void testCreateEngineeringRequest() {
    System.runAs([
        SELECT Id
        FROM User
        WHERE Username LIKE '%@sunbeltrentals.com.unittest'
        LIMIT 1
      ]
      .get(0)) {
      Test.StartTest();
      List<Engineering_Request__c> lER = SBR_3_0_TestDataFactory.createEngineeringRequest(
        2,
        true
      );
      System.assertNotEquals(null, lER, 'lER was unexpectedly null');
      Test.stopTest();
    }
  }

  @IsTest
  static void testCreateQuoteCrew() {
    System.runAs([
        SELECT Id
        FROM User
        WHERE Username LIKE '%@sunbeltrentals.com.unittest'
        LIMIT 1
      ]
      .get(0)) {
      String task = 'Orientation';
      Test.startTest();
      List<SBQQ__Quote__c> quotes = SBR_3_0_TestDataFactory.createQuotes(
        1,
        true,
        SBR_3_0_Constants.QUOTE_REC_TYPE_RENTAL_QUOTE
      );
      System.assertNotEquals(null, quotes, 'Quotes was unexpectedly null');

      List<Crew__c> createCrew = SBR_3_0_TestDataFactory.createCrew(
        2,
        false,
        TASK,
        quotes[0].Id
      );
      System.assertNotEquals(
        null,
        createCrew,
        'CreateCrew was unexpectedly null.'
      );

      List<SBQQ__QuoteLine__c> quoteLines = SBR_3_0_TestDataFactory.createQuoteLines(
        1,
        false,
        quotes[0].Id
      );
      System.assertNotEquals(
        null,
        quoteLines,
        'Quote lines was unexpectedly null'
      );
      Test.stopTest();
    }
  }

  @isTest
  static void validateCommentsTest() {
    Test.StartTest();
    List<Account> acc = SBR_3_0_TestDataFactory.createAccounts(
      1,
      true,
      'Prospect'
    );

    List<Comment__c> comments = SBR_3_0_TestDataFactory.createComments(
      1,
      true,
      acc[0].Id
    );
    Assert.isNotNull(comments);
    Test.stopTest();
  }

  @isTest
  static void createCredentialTest() {
    Test.StartTest();
    Credential__c credentail = SBR_3_0_TestDataFactory.createCredential();
    Assert.isNotNull(credentail);
    Test.stopTest();
  }

  @isTest
  static void createSalesUserTest() {
    Test.StartTest();
    User salesUser = SBR_3_0_TestDataFactory.createSalesUser();
    Assert.isNotNull(salesUser);
    Test.stopTest();
  }

  @isTest
  static void createServiceUserTest() {
    Test.StartTest();
    User serviceUser = SBR_3_0_TestDataFactory.createServiceUser();
    Assert.isNotNull(serviceUser);
    Test.stopTest();
  }

  @isTest
  static void createAdminUserTest() {
    Test.StartTest();
    User adminUser = SBR_3_0_TestDataFactory.createAdminUser();
    Assert.isNotNull(adminUser);
    Test.stopTest();
  }

  @isTest
  static void createProductHierarchiesTest() {
    Test.StartTest();
    Product_Hierarchy__c ph = SBR_3_0_TestDataFactory.createProductHierarchies(
      false,
      'proudctHierarchier090'
    );
    Assert.isNotNull(ph);
    Test.stopTest();
  }

  @isTest
  static void createSingleAccountTest() {
    System.runAs([
        SELECT Id
        FROM User
        WHERE Username LIKE '%@sunbeltrentals.com.unittest'
        LIMIT 1
      ]
      .get(0)) {
      DescribeSObjectResult dsr = Account.SObjectType.getDescribe(
        SObjectDescribeOptions.DEFERRED
      );
      Id recordTypeId = SBR_3_0_TestDataFactory.getAvailableRecordTypeId(
        dsr,
        null
      );
      String rm_acc = '1234567';
      Account acc = SBR_3_0_TestDataFactory.createSingleAccount(
        true,
        recordTypeId,
        'acc090',
        rm_acc,
        '01'
      );
      Assert.isNotNull(acc);
    }
  }

  @isTest
  static void createQuoteWithSourcingBranchTest() {
    System.runAs([
        SELECT Id
        FROM User
        WHERE Username LIKE '%@sunbeltrentals.com.unittest'
        LIMIT 1
      ]
      .get(0)) {
      Id quoteRecordType = Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosByDeveloperName()
        .get('Sales_Quote')
        .getRecordTypeId();
      SBQQ__Quote__c quote = SBR_3_0_TestDataFactory.createQuoteWithSourcingBranch(
        false,
        'salesQuote090',
        quoteRecordType
      );
      Assert.isNotNull(quote);
    }
  }
}