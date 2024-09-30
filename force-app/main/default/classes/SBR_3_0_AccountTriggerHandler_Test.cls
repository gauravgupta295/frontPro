/*********************************************************************************************************************
* Apex Class: SBR_3_0_AccountTriggerHandler_Test
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Class to test SBR_3_0_AccountTriggerHandler
* - SAL-1105
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Harry Rokad           2022-03-22            Initial version
	2.0  		Konrad Haight		  2023-12-06			Rework to increase coverage and remove test.isrunningtest bypasses
*********************************************************************************************************************/

@isTest
public with sharing class SBR_3_0_AccountTriggerHandler_Test {
  private static Integer recordsToCreate = 2;

  @TestSetup
  static void makeData() {
    createTestuser();
    User u = [
      SELECT Id
      FROM User
      WHERE FirstName = 'Bruce' AND LastName = 'Wayne'
    ];
    System.runAs(u) {
      List<Account> accounts = SBR_3_0_TestDataFactory.createAccounts(
        recordsToCreate,
        true
      );
    }
  }

  @isTest
  static void testAfterInsert() {
    User u = [
      SELECT Id
      FROM User
      WHERE FirstName = 'Bruce' AND LastName = 'Wayne'
    ];
    System.runAs(u) {
      Integer c = [SELECT COUNT() FROM Account];
      System.assertEquals(recordsToCreate, c);
    }
  }

  @isTest
  static void testAfterUpdate() {
    User u = [
      SELECT Id
      FROM User
      WHERE FirstName = 'Bruce' AND LastName = 'Wayne'
    ];
    System.runAs(u) {
      List<Account> accounts = [SELECT Id, Name FROM Account];
      accounts[0].Name = 'Updated Name';
      update accounts;
      Integer c = [SELECT COUNT() FROM Account WHERE Name = 'Updated Name'];
      System.assertEquals(1, c);
    }
  }

  @isTest
  static void testBeforeUpdate() {
    User u = [
      SELECT Id
      FROM User
      WHERE FirstName = 'Bruce' AND LastName = 'Wayne'
    ];
    System.runAs(u) {
      List<Account> accounts = [SELECT Id, Name FROM Account];
      accounts[0].Name = 'Updated Name';
      update accounts;
      Integer c = [SELECT COUNT() FROM Account WHERE Name = 'Updated Name'];
      System.assertEquals(1, c);
    }
  }

  @isTest
  static void testBeforeInsert() {
    User u = [
      SELECT Id
      FROM User
      WHERE FirstName = 'Bruce' AND LastName = 'Wayne'
    ];
    System.runAs(u) {
      Integer c = [SELECT COUNT() FROM Account];
      System.assertEquals(recordsToCreate, c);
    }
  }

  public static void createTestuser() {
    Set<String> permSetNames = new Set<String>();
    permSetNames.add('Integration_API_Access');
    Set<String> permSetLicenseNames = new Set<String>();
    permSetLicenseNames.add('SalesforceCPQ_CPQStandardPerm');

    List<User> users = createUsersWithPermissions(
      1,
      true,
      'System Administrator',
      permSetLicenseNames,
      permSetNames
    );
  }

  public static List<User> createUsersWithPermissions(
    Integer count,
    Boolean insertRecords,
    String profile,
    Set<String> permissionSetLicenseNames,
    Set<String> permissionSetNames
  ) {
    List<User> userList = new List<User>();

    Profile p = [SELECT Id FROM Profile WHERE Name = :profile WITH USER_MODE];

    String email =
      profile.replace(' ', '') +
      '_' +
      generateRandomString(15) +
      '@sunbeltrentals.com';

    for (Integer i = 0; i < count; i++) {
      User u = createUser(false, p);
      u.Username = email + '.unittest';
      u.Email = email;
      u.RepId__c = '1234' + i;
      u.SF_PS_Mechanic_Id__c = '8888' + i;
      userList.add(u);
    }

    userList = (List<User>) insertRecords(userList, insertRecords);

    if (permissionSetLicenseNames != null) {
      List<PermissionSetLicense> licenses = [
        SELECT Id, MasterLabel, DeveloperName
        FROM PermissionSetLicense
        WHERE DeveloperName = :permissionSetLicenseNames
        WITH USER_MODE
      ];
      List<PermissionSetLicenseAssign> licenseAssignments = new List<PermissionSetLicenseAssign>();
      for (PermissionSetLicense psl : licenses) {
        for (User u : userList) {
          licenseAssignments.add(
            new PermissionSetLicenseAssign(
              AssigneeId = u.Id,
              PermissionSetLicenseId = psl.Id
            )
          );
        }
      }
      insertRecords(licenseAssignments, true);
    }

    if (permissionSetNames != null) {
      List<PermissionSetAssignment> permissionSetAssignments = new List<PermissionSetAssignment>();
      for (PermissionSet ps : [
        SELECT Id
        FROM PermissionSet
        WHERE Name IN :permissionSetNames
        WITH USER_MODE
      ]) {
        for (User u : userList) {
          permissionSetAssignments.add(
            new PermissionSetAssignment(
              AssigneeId = u.Id,
              PermissionSetId = ps.Id
            )
          );
        }
      }
      insertRecords(permissionSetAssignments, true);
    }

    return userList;
  }

  public static User createUser(Boolean insertRecord, Profile oProfile) {
    User oUser = new User(
      Alias = 'batman',
      Email = 'bruce.wayne@sunbeltrentals.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Wayne',
      FirstName = 'Bruce',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = oProfile.Id,
      TimeZoneSidKey = 'America/Chicago',
      Username = generateRandomString(5) +
        DateTime.now().getTime() +
        '@SBRtestorg.com',
      IsActive = true,
      City = '',
      Country = 'CA',
      CountryCode = 'CA',
      PostalCode = 'V9B 3Y8',
      State = 'BC',
      StateCode = 'BC',
      Street = '2994 Jacklin Rd',
      UserPermissionsMarketingUser = false
    );

    insertRecords(oUser, insertRecord);

    return oUser;
  }
  private static List<sObject> insertRecords(
    List<sObject> records,
    boolean insertRecords
  ) {
    if (insertRecords) {
      String objApiName;
      if (records.size() > 0) {
        objApiName = String.valueOf(records[0].getSObjectType());
      }
      if (objApiName != 'Campaign') {
        SObjectAccessDecision decision = Security.stripInaccessible(
          AccessType.CREATABLE,
          records
        );
        List<sObject> tempRecords = decision.getRecords();
        System.debug('tempRecords = ' + tempRecords);
        insert tempRecords; //NOPMD
        for (Integer i = 0; i < tempRecords.size(); i++) {
          records.get(i).Id = tempRecords.get(i).Id;
        }
      } else {
        insert records;
      }
    }
    return records;
  }

  private static void insertRecords(sObject record, boolean insertRecords) {
    insertRecords(new List<sObject>{ record }, insertRecords);
  }
  public static String generateRandomString(Integer len) {
    final String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz';
    String randStr = '';
    while (randStr.length() < len) {
      Integer idx = Math.mod(
        Math.abs(Crypto.getRandomInteger()),
        chars.length()
      );
      randStr += chars.substring(idx, idx + 1);
    }
    return randStr;
  }
}