/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 11-01-2023
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@isTest
public class SBR_3_0_CheckDuplicateRecords_Test {

    @TestSetup
    static void makeData(){
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
    }
    
    @isTest
    static void checkDuplicateContactRecords() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account'][0];
        List<Contact> contactList = new List<Contact>();
        List<Contact> result = new List<Contact>();
        Contact contact1 = new Contact();
        contact1.FirstName = 'Hamza';
        contact1.LastName = 'Demo';
        contact1.Email = 'ba@test.com';
        contact1.AccountId = acc.Id;
        contact1.MailingStreet = '2065 Oakdale Avenue';
        contact1.MailingCity = 'San Francisco';
        contact1.MailingState = 'CA';
        contact1.MailingPostalCode = '94124';
        contact1.MailingCountry = 'US';
        contact1.Phone = '09786654';
        contact1.MobilePhone = '06564534';
        contact1.Fax  = '8776544';
        
        //contactList.add(contact1);

        Test.startTest();
        insert contact1;
        Test.stopTest();
       
        Contact contact2 = new Contact();
        contact2.FirstName = 'Hamza';
        contact2.LastName = 'Demo';
        contact2.Email = 'ba@test.com';
        contact2.AccountId = acc.Id;
        contact2.MailingStreet = '2065 Oakdale Avenue';
        contact2.MailingCity = 'San Francisco';
        contact2.MailingState = 'CA';
        contact2.MailingPostalCode = '94124';
        contact2.MailingCountry = 'US';
        contact2.Phone = '09786654';
        contact2.MobilePhone = '06564534';
        contact2.Fax  = '8776544';

        result = SBR_3_0_CheckDuplicateRecords.duplicateList(contact2);
        Assert.isTrue(result.size() > 0);
    }

    @isTest
    static void checkDuplicateContactFields() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account'][0];
        List<Contact> contactList = new List<Contact>();
        List<String> result = new List<String>();
        Contact contact1 = new Contact();
        contact1.FirstName = 'Hamza';
        contact1.LastName = 'Demo';
        contact1.Email = 'ba@test.com';
        contact1.AccountId = acc.Id;
        contact1.MailingStreet = '2065 Oakdale Avenue';
        contact1.MailingCity = 'San Francisco';
        contact1.MailingState = 'CA';
        contact1.MailingPostalCode = '94124';
        contact1.MailingCountry = 'US';
        contact1.Phone = '09786654';
        contact1.MobilePhone = '06564534';
        contact1.Fax  = '8776544';
        
        //contactList.add(contact1);

        Test.startTest();
        insert contact1;
        Test.stopTest();
       
        Contact contact2 = new Contact();
        contact2.FirstName = 'Hamza';
        contact2.LastName = 'Demo';
        contact2.Email = 'ba@test.com';
        contact2.AccountId = acc.Id;
        contact2.MailingStreet = '2065 Oakdale Avenue';
        contact2.MailingCity = 'San Francisco';
        contact2.MailingState = 'CA';
        contact2.MailingPostalCode = '94124';
        contact2.MailingCountry = 'US';
        contact2.Phone = '09786654';
        contact2.MobilePhone = '06564534';
        contact2.Fax  = '8776544';

        result = SBR_3_0_CheckDuplicateRecords.findDuplicateFields(contact2);
        Assert.isTrue(result.size() > 0);
    }
}