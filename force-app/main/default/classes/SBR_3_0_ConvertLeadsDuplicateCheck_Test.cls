/*********************************************************************************************************************
* Apex Class: SBR_3_0_ConvertLeadsDuplicateCheck_Test
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Class to test SBR_3_0_ConvertLeadDuplicateCheck
* - SAL-3038
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Konrad Haight           2022-05-13          Initial version    
*********************************************************************************************************************/
@isTest
public with sharing class SBR_3_0_ConvertLeadsDuplicateCheck_Test {
  @TestSetup
  static void makeData() {
    //create account and contact
    List<Account> testAccounts = SBR_3_0_TestDataFactory.createAccounts(
      1,
      false,
      SBR_3_0_Constants.ACCOUNT_REC_TYPE_PROSPECT
    );
    testAccounts[0].Name = 'Test Company Zero';
    insert testAccounts;

    List<Contact> testContacts = SBR_3_0_TestDataFactory.createContacts(
      2,
      testAccounts[0].Id,
      false
    );
    testContacts[0].FirstName = 'TestFirstZero';
    testContacts[0].LastName = 'TestLastZero';
    testContacts[0].Phone = testAccounts[0].Phone;
    testContacts[0].MobilePhone = 'TestMobilePhone';
    testContacts[0].Email = 'testemail@email.com';
    testContacts[1].FirstName = 'TestFirstOne';
    testContacts[1].LastName = 'TestLastOne';
    testContacts[1].Phone = testAccounts[0].Phone;
    testContacts[1].MobilePhone = 'TestMobilePhone';
    testContacts[1].Email = 'testemail@email.com';
    Database.DMLOptions dml = new Database.DMLOptions();
    dml.DuplicateRuleHeader.AllowSave = true;
    Database.insert(testContacts, dml);

    List<Lead> testLeads = SBR_3_0_TestDataFactory.createLeads(3, false);
    testLeads[0].Company = testAccounts[0].Name;
    testLeads[0].FirstName = testContacts[0].FirstName;
    testLeads[0].LastName = testContacts[0].LastName;
    testLeads[0].Email = testContacts[0].Email;
    testLeads[0].Phone = testAccounts[0].Phone;
    testLeads[0].MobilePhone = testContacts[0].MobilePhone;
    testLeads[0].Street = testAccounts[0].BillingStreet;
    testLeads[0].City = testAccounts[0].BillingCity;
    testLeads[0].State = testAccounts[0].BillingState;
    testLeads[0].Country = testAccounts[0].BillingCountry;
    testLeads[0].PostalCode = testAccounts[0].BillingPostalCode;
	testLeads[0].Company = 'Test Company Zero';
    testLeads[1].Company = 'Test Company One';
    testLeads[2].Company = 'Test Company Two';
    testLeads[2].FirstName = testLeads[0].FirstName;
    testLeads[2].LastName = testLeads[0].LastName;
    testLeads[2].Email = testLeads[0].Email;

    Database.insert(testLeads, dml);
  }

  @IsTest
  static void testConvertLeadCheckWhenObjectsExist() {
    Lead testLead = [
      SELECT Id
      FROM Lead
      WHERE Company = 'Test Company Zero'
      LIMIT 1
    ];
    Account testAccount = [
      SELECT Id
      FROM Account
      WHERE Name = 'Test Company Zero'
      LIMIT 1
    ];
    Contact testContact = [
      SELECT Id
      FROM Contact
      WHERE LastName = 'TestLastZero'
      LIMIT 1
    ];

    List<SBR_3_0_ConvertLeadsDuplicateCheck.LeadConversionCheckWrapper> wrappers = new List<SBR_3_0_ConvertLeadsDuplicateCheck.LeadConversionCheckWrapper>();

    SBR_3_0_ConvertLeadsDuplicateCheck.LeadConversionCheckWrapper w = new SBR_3_0_ConvertLeadsDuplicateCheck.LeadConversionCheckWrapper();

    w.leadId = testLead.Id;

    wrappers.add(w);

    //create inner class instance with leadId set to new lead.Id
    Test.startTest();
    List<SBR_3_0_ConvertLeadsDuplicateCheck.LeadConversionCheckWrapper> result = SBR_3_0_ConvertLeadsDuplicateCheck.convertLeadCheck(
      wrappers
    );
    Test.stopTest();

    SBR_3_0_ConvertLeadsDuplicateCheck.LeadConversionCheckWrapper wrap = result[0];

    System.debug('TestAccountID'+testAccount.Id);
    System.debug('WrapAccountID'+wrap.accountId);
    //System.assertEquals(
    //  testAccount.Id,
    //  wrap.accountId,
    //  'No account duplicates were found'
    //);
   // System.assertEquals(
    //  wrap.contactId,
    //  testContact.Id,
    //  'Converted Contact Id should match Contact Id'
  //  );
    /*System.debug('Test Lead ID'+testLead.Id);
    System.debug('Wrap Lead Id'+wrap.leadId);
    System.assertEquals(
      wrap.leadId,
      testLead.Id,
      'Converted Contact Id should match Contact Id'
    );*/
  }
  @IsTest
  static void testConvertLeadCheckForLeadDuplicate() {
    Lead testLeadOne = [
      SELECT Id
      FROM Lead
      WHERE Company = 'Test Company One'
      LIMIT 1
    ];
    Lead testLeadTwo = [
      SELECT Id
      FROM Lead
      WHERE Company = 'Test Company Two'
      LIMIT 1
    ];
    

    List<SBR_3_0_ConvertLeadsDuplicateCheck.LeadConversionCheckWrapper> wrappers = new List<SBR_3_0_ConvertLeadsDuplicateCheck.LeadConversionCheckWrapper>();

    SBR_3_0_ConvertLeadsDuplicateCheck.LeadConversionCheckWrapper w = new SBR_3_0_ConvertLeadsDuplicateCheck.LeadConversionCheckWrapper();

    w.leadId = testLeadOne.Id;

    wrappers.add(w);

    //create inner class instance with leadId set to new lead.Id
    Test.startTest();
    List<SBR_3_0_ConvertLeadsDuplicateCheck.LeadConversionCheckWrapper> result = SBR_3_0_ConvertLeadsDuplicateCheck.convertLeadCheck(
      wrappers
    );
    Test.stopTest();

    SBR_3_0_ConvertLeadsDuplicateCheck.LeadConversionCheckWrapper wrap = result[0];
    System.debug('Ids: ');
    System.debug('Wrap Id : ' + wrap.leadId);
    //System.debug('Test Lead Id : ' + testLeadTwo.Id);
    System.assertEquals(
      wrap.leadId,
      '',
      'No lead duplicates should be found'
    );
  }
}