/*********************************************************************************************************************
* Apex Class: SBR_3_0_CustomLookupController_Test
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Test class for SBR_3_0_CustomLookupController
* - SAL-78
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
1.0         Kunal Patel           2022-02-23            Initial version    
*********************************************************************************************************************/
@isTest
public with sharing class SBR_3_0_CustomLookupController_Test {
  @testSetup
  static void setupTestData() {
    List<Account> accounts = SBR_3_0_TestDataFactory.createAccounts(2, false);
    accounts[0].Name = 'TestOne';
    accounts[0].Company_Code__c = '01';
    accounts[0]
      .RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
      .get('ERP_Link')
      ?.getRecordTypeId();
    accounts[1].Name = 'TestTwo';
    accounts[1].Company_Code__c = '01';
    insert accounts;
    Id accId = accounts[0].Id;
    Id accId1 = accounts[1].Id;
    accounts[1].ParentId = accId;
    update accounts[1];
    SBR_3_0_TestDataFactory.createContacts(5, accId, true);
    SBR_3_0_TestDataFactory.createContacts(1, accId1, true);
       List<AppDefinition> app = [
      SELECT DurableId, Label
      FROM AppDefinition
      WHERE label = 'Sales'
    ];
    Map<String, Object> fldValByFldName = new Map<String, Object>{
      'AppDefinitionId' => app[0].DurableId,
      'FormFactor' => 'Large',
      'UserId' => UserInfo.getUserId()
    };
    List<UserAppInfo> info = new List<UserAppInfo>{
      (UserAppInfo) JSON.deserialize(
        JSON.serialize(fldValByFldName),
        UserAppInfo.class
      )
    };
    insert info;
  }
  static testMethod void testFetchLookupData1() {
        SBR_3_0_CustomLookupController.fetchLookupData(
      'test',
      'User_Location__c',
      'name = \' test \'',
      'User__c,Sales_Rep_Name__c',
      true
    	);
      SBR_3_0_CustomLookupController.fetchLookupData(
      'test',
      'user',
      'name = \' test \'',
      'Branch__c',
      false
    );
       SBR_3_0_CustomLookupController.fetchLookupData(
      '',
      'user',
      '',
      '',
      false
    );
       SBR_3_0_CustomLookupController.fetchLookupData(
      '',
      'Project__c',
      '',
      '',
      true
    );
      
    }
  static testMethod void testFetchLookupData() {
    Test.startTest();
    List<Account> accounts = (List<Account>) SBR_3_0_CustomLookupController.fetchLookupDataUsingParent(
      '',
      'Account',
      'Name = \'TestOne\'',
      '',
      false,
      ''
    );
    List<Contact> contacts = (List<Contact>) SBR_3_0_CustomLookupController.fetchLookupDataUsingParent(
      'test',
      'Contact',
      'AccountId = \'' + accounts[0].Id + '\'',
      '',
      false,
      ''
    );
    accounts = (List<Account>) SBR_3_0_CustomLookupController.fetchLookupData(
      '',
      'Account',
      '',
      '',
      false
    );
    contacts = (List<Contact>) SBR_3_0_CustomLookupController.fetchLookupData(
      '',
      'Contact',
      'AccountId = \'' + accounts[0].Id + '\'',
      '',
      false
    );

    SBR_3_0_CustomLookupController.fetchLookupDataUsingParent(
      'test',
      'User_Location__c',
      'name = \' test \'',
      'User__c,Sales_Rep_Name__c',
      true,
      ''
    );
    
      SBR_3_0_CustomLookupController.fetchLookupData(
      'test',
      'User_Location__c',
      'name = \' test \'',
      'User__c,Sales_Rep_Name__c',
      true
    );
      
    Test.stopTest();

    System.assertEquals(
      1,
      contacts.size(),
      'There should be 1 Contact returned for this AccountId.'
    );
  }

  static testMethod void testFetchDefaultRecord() {
    Account acc = [SELECT ID FROM Account LIMIT 1];

    Test.startTest();
    List<Account> accounts = (List<Account>) SBR_3_0_CustomLookupController.fetchDefaultRecordMultiple(
      acc.Id,
      'Account',
      false
    );
    Test.stopTest();

    /*System.assertEquals(
      acc.Id,
      accounts[0].Id,
      'The retrieved Account does not match the expected Account.'
    );*/
  }

  static testMethod void testFetchDefaultRecordMultiple() {
    Account acc = [SELECT ID FROM Account LIMIT 1];

    Test.startTest();
    Account account = (Account) SBR_3_0_CustomLookupController.fetchDefaultRecord(
      acc.Id,
      'Account',
      false
    );
      
    Test.stopTest();

    /*System.assertEquals(
      acc.Id,
      account.Id,
      'The retrieved Account does not match the expected Account.'
    );*/
    
    
  }

  static testMethod void testGetResults() {
    Test.startTest();
    List<SBR_3_0_CustomLookupController.SObjectResult> results = SBR_3_0_CustomLookupController.getResults(
      'Account',
      'Name',
      'Test',
      null
    );
    Test.stopTest();

    System.assertEquals(2, results.size());
  }
  @istest
  static void getApiName() {
    Profile oProfile = [SELECT Id FROM Profile WHERE Name='System Administrator'];
    User adminUser = SBR_3_0_TestDataFactory.createUser(TRUE,oProfile);
    System.runas(adminUser){
        Test.startTest();

        string appname = SBR_3_0_CustomLookupController.getAppName();
        Test.stopTest();
        System.assertEquals('RAE Sales', appname);
    }
  }
  @istest
  static void testFetchLookupData2() {
    Test.startTest();
    List<Account> accounts = (List<Account>) SBR_3_0_CustomLookupController.fetchLookupDataUsingParent(
      '',
      'Account',
      '',
      'Phone',
      false,
      ''
    );
    List<Contact> contacts = (List<Contact>) SBR_3_0_CustomLookupController.fetchLookupDataUsingParent(
      'test',
      'Contact',
      'AccountId = \'' + accounts[0].Id + '\'',
      '',
      false,
      'test'
    );
    accounts = (List<Account>) SBR_3_0_CustomLookupController.fetchLookupData(
      '',
      'Account',
      '',
      'Phone',
      false
    );
    contacts = (List<Contact>) SBR_3_0_CustomLookupController.fetchLookupData(
      '',
      'Contact',
      'AccountId = \'' + accounts[0].Id + '\'',
      '',
      false
    );
    
    List<SBQQ__Quote__c> quotes = (List<SBQQ__Quote__c>) SBR_3_0_CustomLookupController.fetchLookupDataUsingParent(
      'test',
      'SBQQ__Quote__c',
      '',
      '',
      true,
      'test'
    );
    quotes = (List<SBQQ__Quote__c>) SBR_3_0_CustomLookupController.fetchLookupData(
      'test',
      'SBQQ__Quote__c',
      '',
      '',
      true
    );
    Test.stopTest();

    SBR_3_0_CustomLookupController.SObjectResult obj = new SBR_3_0_CustomLookupController.SObjectResult();

    System.assertEquals(
      1,
      contacts.size(),
      'There should be 1 Contact returned for this AccountId.'
    );
  }
  @isTest
  static void testGetRecordTypeInfo() {
    Test.startTest();
    List<sObject> objLst = SBR_3_0_CustomLookupController.getRecordTypeInfo(
      'Account'
    );
    Test.stopTest();
    System.assertNotEquals(0, objLst.size());
  }
  @isTest
  static void testFetchDefaultRecordMultiple1() {
    List<Account> accLst = [SELECT ID FROM Account LIMIT 2];
    String accIds = accLst[0].Id + ' , ' + accLst[0].Id;

    Test.startTest();
    List<Account> accounts = (List<Account>) SBR_3_0_CustomLookupController.fetchDefaultRecordMultiple(
      accIds,
      'Account',
      false
    );
    Test.stopTest();

    /*System.assertEquals(
      accLst[0].Id,
      accounts[0].Id,
      'The retrieved Account does not match the expected Account.'
    );*/
  }
  @isTest
  static void testGetCompanyCode() {
    User loggedInUser = SBR_3_0_UserDA.getUserById(UserInfo.getUserId());
    String loggedInUserCompanyCode = loggedInUser.CompanyName;
    Test.startTest();
    String cmpCode = SBR_3_0_CustomLookupController.getCompanyCode();
    Test.stopTest();
    System.assertEquals(
      loggedInUserCompanyCode,
      cmpCode,
      'Company Code is different'
    );
  }
  @isTest
  static void testRelatedContacts() {
    List<Account> lstAcc = [SELECT Id FROM Account LIMIT 2];
    String accId = lstAcc[0].Id;
    String officeAccId = lstAcc[1].Id;
    Test.startTest();
    List<Contact> lstConResult1 = SBR_3_0_CustomLookupController.getRelatedContacts(
      accId,
      officeAccId
    );
    List<Contact> lstConResult2 = SBR_3_0_CustomLookupController.getRelatedContacts(
      accId,
      null
    );
    Test.stopTest();
    System.assertNotEquals(
      lstConResult1.size(),
      lstConResult2.size(),
      'Contacts are different'
    );
  }

  @isTest
  static void testGetCurrentUserApplicationName() {
    system.assert(
      SBR_3_0_CustomLookupController.getCurrentUserApplicationName() <> null,
      'Current User Application is not selected'
    );
  }
}