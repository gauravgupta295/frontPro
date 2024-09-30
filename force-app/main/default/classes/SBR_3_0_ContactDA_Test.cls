/*********************************************************************************************************************
* Apex Class: SBR_3_0_ContactDA
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Concrete class for Contact Data Access
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Kunal Patel           2022-02-16            Initial version 
    2.0         Hrishikesh Kanabar    2022-07-19            Added method testgetContactsWithAccId
*********************************************************************************************************************/
@isTest
public with sharing class SBR_3_0_ContactDA_Test {
    
    static testMethod void testGetContacts() {
        Integer count = 100;
        List<Account> accounts = SBR_3_0_TestDataFactory.createAccounts(1, true);
        List<Contact> contacts = SBR_3_0_TestDataFactory.createContacts(count, accounts[0].Id, false);

        Test.startTest();
            List<Contact> result = SBR_3_0_ContactDA.getContacts();
            System.assertEquals(0, result.size(), 'No Contacts should be returned');
            insert contacts;

            result = SBR_3_0_ContactDA.getContacts();
            System.assertEquals(count, result.size(), 'Contact count does not match');
        Test.stopTest();
    }

    static testMethod void testGetContactsMap() {
        Integer count = 100;
        List<Account> accounts = SBR_3_0_TestDataFactory.createAccounts(1, true);
        List<Contact> contacts = SBR_3_0_TestDataFactory.createContacts(count, accounts[0].Id, true);
        Set<Id> contIds = new Set<Id>();
        for(Contact c : contacts) {
            contIds.add(c.Id);
        }

        Test.startTest();
            Map<Id, Contact> result = SBR_3_0_ContactDA.getContacts(contIds);
            System.assertEquals(count, result.size(), 'Contact count does not match');
            for(Id cid : result.keySet()) {
                System.assertEquals(true, contIds.contains(cid), 'An expected Contact was not retrieved');
            }
        Test.stopTest();
    }
    
    static testMethod void testGetContactsWithAccId(){
        Integer count = 100;
        List<Account> accounts = SBR_3_0_TestDataFactory.createAccounts(1, true);
        List<Contact> contacts = SBR_3_0_TestDataFactory.createContacts(count, accounts[0].Id, true);
        Set<Id> contIds = new Set<Id>();
        for(Contact c : contacts) {
            contIds.add(c.Id);
        }
        
        Test.startTest();
        List<Contact> result = SBR_3_0_ContactDA.getContactsWithAccId(accounts[0].id);
        System.assertEquals(count, result.size(), 'Contact count does not match');
        for(Contact cons : result) {
                System.assertEquals(true, contIds.contains(cons.id), 'An expected Contact was not retrieved');
        }
        Test.stopTest();
        
    }

    static testMethod void testGetContactsName(){
        Integer count = 100;
        List<Account> accounts = SBR_3_0_TestDataFactory.createAccounts(1, true);
        List<Contact> contacts = SBR_3_0_TestDataFactory.createContacts(count, accounts[0].Id, true);
        Set<Id> contIds = new Set<Id>();
        for(Contact c : contacts) {
            contIds.add(c.Id);
        }

        Test.startTest();
            Map<Id, Contact> result = SBR_3_0_ContactDA.getContactsName(contIds);
            System.assertEquals(count, result.size(), 'Contact count does not match');
            for(Id cid : result.keySet()) {
                System.assertEquals(true, contIds.contains(cid), 'An expected Contact was not retrieved');
            }
        Test.stopTest();
    }

    static testMethod void testGtContactsByAccIdLastName(){
        Integer count = 100;
        List<Account> accounts = SBR_3_0_TestDataFactory.createAccounts(1, true);
        List<Contact> contacts = SBR_3_0_TestDataFactory.createContacts(count, accounts[0].Id, true);
        Set<Id> accIds = new Set<Id>();
        Set<Id> contIds = new Set<Id>();
        for(Contact c : contacts) {
            contIds.add(c.Id);
        }
        for(Account a : accounts) {
            accIds.add(a.Id);
        }
        
        Test.startTest();
        List<Contact> result = SBR_3_0_ContactDA.getContactsByAccIdLastName(accIds, contacts[0].LastName);
        for(Contact cons : result) {
                System.assertEquals(true, contIds.contains(cons.id), 'An expected Contact was not retrieved');
        }
        Test.stopTest();
        
    }

    static testMethod void testGetContactWrap(){
        List<Account> accounts = SBR_3_0_TestDataFactory.createAccounts(1, true);
        List<Contact> contacts = SBR_3_0_TestDataFactory.createContacts(1, accounts[0].Id, true);
        Set<Id> contIds = new Set<Id>();
        for(Contact c : contacts) {
            contIds.add(c.Id);
        }
        SBR_3_0_ContactWrap contactWrap = new SBR_3_0_ContactWrap();
        contactWrap.firstName = contacts[0].FirstName;
        contactWrap.lastName = contacts[0].LastName;
        contactWrap.email = contacts[0].Email;
        contactWrap.phone = contacts[0].Phone;
        
        Test.startTest();
        List<Contact> result = SBR_3_0_ContactDA.getContact(contactWrap);
        for(Contact cons : result) {
                System.assertEquals(true, contIds.contains(cons.id), 'An expected Contact was not retrieved');
        }
        Test.stopTest();
        
    }
    
    static testMethod void testGetContactWrapwithAccId(){
        List<Account> accounts = SBR_3_0_TestDataFactory.createAccounts(1, true);
        List<Contact> contacts = SBR_3_0_TestDataFactory.createContacts(1, accounts[0].Id, true);
        Set<Id> contIds = new Set<Id>();
        for(Contact c : contacts) {
            contIds.add(c.Id);
        }
        SBR_3_0_ContactWrap contactWrap = new SBR_3_0_ContactWrap();
        contactWrap.firstName = contacts[0].FirstName;
        contactWrap.lastName = contacts[0].LastName;
        contactWrap.email = contacts[0].Email;
        contactWrap.phone = contacts[0].Phone;        
        Test.startTest();
        List<Contact> result = SBR_3_0_ContactDA.getContact(contactWrap,accounts[0]);
       // System.assertEquals(count, result.size(), 'Contact count does not match');
        for(Contact cons : result) {
                System.assertEquals(true, contIds.contains(cons.id), 'An expected Contact was not retrieved');
        }
        Test.stopTest();
        
    }
        static testMethod void testGetContactWrapWithAccIdNullFirstname(){
        List<Account> accounts = SBR_3_0_TestDataFactory.createAccounts(1, true);
        List<Contact> contacts = SBR_3_0_TestDataFactory.createContacts(1, accounts[0].Id, true);
        Set<Id> contIds = new Set<Id>();
        for(Contact c : contacts) {
            contIds.add(c.Id);
        }
        SBR_3_0_ContactWrap contactWrap = new SBR_3_0_ContactWrap();
        contactWrap.firstName = null;
        contactWrap.lastName = contacts[0].LastName;
        contactWrap.email = contacts[0].Email;
        contactWrap.phone = contacts[0].Phone;        
        Test.startTest();
        List<Contact> result = SBR_3_0_ContactDA.getContact(contactWrap,accounts[0]);
        for(Contact cons : result) {
            Assert.areEqual(true, contIds.contains(cons.id), 'An expected Contact was not retrieved');
        }
        Test.stopTest();
        
    }

}