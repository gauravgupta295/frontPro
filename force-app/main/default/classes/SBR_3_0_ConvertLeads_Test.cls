/*********************************************************************************************************************
* Apex Class: SBR_3_0_ConvertLeads_Test
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Class to test SBR_3_0_ConvertLeads
* - SAL-326
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Kunal Patel           2022-02-02            Initial version    
*********************************************************************************************************************/
@isTest
public with sharing class SBR_3_0_ConvertLeads_Test {
    
    @testSetup static void setupTestData() {
        // creating leads for test manipulation

        List<User> userList = new List<User>();

        Profile p2 = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        String adminUserName = 'systemadmin' + DateTime.now().getTime() + '@SBRtestorg.com';
        User adminUser = new User(Alias = 'standt', Email='systemadmin@testorg.com',
        EmailEncodingKey='UTF-8', LastName='adminTest', LanguageLocaleKey='en_US',
        LocaleSidKey='en_US', ProfileId = p2.Id,
        TimeZoneSidKey='America/Los_Angeles',
        UserName=adminUserName);
        userList.add(adminUser);
        insert userList;

        
        System.runAs(adminUser){
            Integer count = 1;
            List<Account> accounts = SBR_3_0_TestDataFactory.createAccounts(1, true, 'Prospect');
            Id accId = accounts[0].Id;
            List<Contact> contacts = SBR_3_0_TestDataFactory.createContacts(1, accId, true);
            List<Lead> leads = SBR_3_0_TestDataFactory.createLeads(count, true);

        }


    }

    @isTest
    static  void testConvertLead_NoOpportunity() {
        Lead l = SBR_3_0_LeadDA.getLeads()[0];
        Account acc = [SELECT ID FROM Account LIMIT 1];
        Contact cont = [SELECT ID FROM Contact LIMIT 1];
        User admin = [SELECT Id FROM User WHERE LastName = 'adminTest'];

        System.runAs(admin){
            l.Account__c = acc.Id;
            l.Contact__c = cont.Id;
            l.Allow_Lead_Conversion__c = true;
            update l;

            List<SBR_3_0_ConvertLeads.LeadConversionWrapper> wrappers = new List<SBR_3_0_ConvertLeads.LeadConversionWrapper>();
            SBR_3_0_ConvertLeads.LeadConversionWrapper w = new SBR_3_0_ConvertLeads.LeadConversionWrapper();

            w.leadId = l.Id;
            w.accountId = acc.Id;
            w.contactId = cont.Id;
            w.opportunityId = null;
            w.opportunityName = null;
            w.createNewOpportunity = false;
            wrappers.add(w);
        
            Test.startTest();
            List<SBR_3_0_ConvertLeads.LeadConversionWrapper> result = SBR_3_0_ConvertLeads.convertLead(wrappers);
            Test.stopTest();

            for(SBR_3_0_ConvertLeads.LeadConversionWrapper wrap : result) {
            
                System.assertEquals(wrap.leadId, l.Id, 'Converted Lead Id should match Lead Id');
                System.assertEquals(wrap.accountId, acc.Id, 'Converted Account Id should match Account Id');
                System.assertEquals(wrap.contactId, cont.Id, 'Converted Contact Id should match Contact Id');
                System.assertEquals(wrap.opportunityId, null, 'Converted Opportunity Id should not exist');
            }
        }
        
        
    }
    @isTest
    static  void testConvertLead_CreateNewOpportunity() {
        Lead l = SBR_3_0_LeadDA.getLeads()[0];
        Account acc = [SELECT ID FROM Account LIMIT 1];
        User admin = [SELECT Id FROM User WHERE LastName = 'adminTest'];
        Contact cont = [SELECT ID FROM Contact LIMIT 1];

        System.runAs(admin){
            l.Account__c = acc.Id;
            l.Contact__c = cont.Id;
            l.Allow_Lead_Conversion__c = true;
            update l;

            List<SBR_3_0_ConvertLeads.LeadConversionWrapper> wrappers = new List<SBR_3_0_ConvertLeads.LeadConversionWrapper>();
            SBR_3_0_ConvertLeads.LeadConversionWrapper w = new SBR_3_0_ConvertLeads.LeadConversionWrapper();

            w.leadId = l.Id;
            w.accountId = acc.Id;
            w.contactId = cont.Id;
            w.opportunityId = null;
            w.opportunityName = 'New Opportunity';
            w.createNewOpportunity = true;
            wrappers.add(w);

        
            Test.startTest();
                List<SBR_3_0_ConvertLeads.LeadConversionWrapper> result = SBR_3_0_ConvertLeads.convertLead(wrappers);
            Test.stopTest();

            for(SBR_3_0_ConvertLeads.LeadConversionWrapper wrap : result) {
            
                System.assertEquals(wrap.leadId, l.Id, 'Converted Lead Id should match Lead Id');
                System.assertEquals(wrap.accountId, acc.Id, 'Converted Account Id should match Account Id');
                System.assertEquals(wrap.contactId, cont.Id, 'Converted Contact Id should match Contact Id');
                System.assertNotEquals(wrap.opportunityId, null, 'Converted Opportunity Id should exist');
            }
        }
        
       
    }

	@isTest
    static  void testConvertLead_CreateDuplicateOpportunity() {
        Lead l = SBR_3_0_LeadDA.getLeads()[0];
        Account acc = [SELECT ID FROM Account LIMIT 1];
        Contact cont = [SELECT ID FROM Contact LIMIT 1];

        l.Account__c = acc.Id;
        l.Contact__c = cont.Id;
        l.Allow_Lead_Conversion__c = true;
        update l;

        List<SBR_3_0_ConvertLeads.LeadConversionWrapper> wrappers = new List<SBR_3_0_ConvertLeads.LeadConversionWrapper>();
        SBR_3_0_ConvertLeads.LeadConversionWrapper w = new SBR_3_0_ConvertLeads.LeadConversionWrapper();

        w.leadId = l.Id;
        w.accountId = acc.Id;
        w.contactId = cont.Id;
        w.opportunityId = null;
        w.opportunityName = 'New Opportunity';
        w.createNewOpportunity = true;
        wrappers.add(w);
        
        Boolean wasExceptionThrow = false;
        try {
            Test.startTest();
                List<SBR_3_0_ConvertLeads.LeadConversionWrapper> result = SBR_3_0_ConvertLeads.convertLead(wrappers);
                List<SBR_3_0_ConvertLeads.LeadConversionWrapper> resultDupe = SBR_3_0_ConvertLeads.convertLead(wrappers);
            Test.stopTest();
        } 
        catch (SBR_3_0_ConvertLeads.LeadConversionException ex)
        {
            wasExceptionThrow = true;
        }

        System.assertEquals(true, wasExceptionThrow, 'The expected LeadConversionException was not thrown');
        
    }

    @isTest
    static  void testQualifyLeads() {
        List<Lead> leads = SBR_3_0_LeadDA.getLeads();
        Account acc = [SELECT ID FROM Account LIMIT 1];
        Contact cont = [SELECT ID FROM Contact LIMIT 1];

        Map<Id, Lead> leadMap = new Map<Id, Lead>();

        for(Lead l : leads) {
            l.Allow_Lead_Conversion__c = true;
        }
        update leads;

        for(Lead l : leads) {
            l.Account__c = acc.Id;
            l.Contact__c = cont.Id;
            LeadStatus qualifiedStatus = SBR_3_0_LeadDA.getLeadStatus(SBR_3_0_Constants.LEAD_STATUS_QUALIFIED);
            l.Status = qualifiedStatus.ApiName;
            leadMap.put(l.Id, l);
        }


        Test.startTest();
            List<Database.LeadConvertResult> results = SBR_3_0_ConvertLeads.convertQualifiedLeads(leadMap);
        Test.stopTest();
        
        for(Database.LeadConvertResult lcr : results) {
            Id leadId = lcr.getLeadId();
            Id accId = lcr.getAccountId();
            Id contId = lcr.getContactId();
            Lead l = leadMap.get(leadId);
            
            System.assertEquals(acc.Id, accId, 'Converted Lead Account should match Leads Parent Account');
            System.assertEquals(cont.Id, contId, 'Converted Lead Contact should match Leads Parent Contact');
        }
    }
}