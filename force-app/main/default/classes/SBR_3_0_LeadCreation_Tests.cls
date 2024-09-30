@isTest
public with sharing class SBR_3_0_LeadCreation_Tests {
    @isTest
    static void testCreateLeads() {
        Profile oProfile = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User oUsers1 = SBR_3_0_TestDataFactory.createUser(TRUE,oProfile);
        System.runAs(oUsers1){
        List<Campaign> campaigns = SBR_3_0_TestDataFactory.createCampaigns(1, true, SBR_3_0_Constants.CAMPAIGN_REC_TYPE_SALES);
        List<Lead> leads = SBR_3_0_TestDataFactory.createLeads(3, false);
        List<Account> accts = SBR_3_0_TestDataFactory.createAccounts(2, false, SBR_3_0_Constants.ACCOUNT_REC_TYPE_PROSPECT);
        accts[0].Name = 'ABC';
        accts[1].Name = '123';
        insert accts;
        List<Contact> contacts = SBR_3_0_TestDataFactory.createContacts(1, accts[0].Id, true);
        leads[0].FirstName = '';
        leads[0].LastName = '';
        leads[0].Company = 'Leadzero';
        leads[1].LastName = 'Leadone';
        leads[1].Account__c = accts[0].Id;
        leads[2].Account__c = accts[1].Id;
        leads[2].LastName = '';
        leads[2].FirstName = '';
        leads[2].Company = 'ABC123';
        SBR_3_0_LeadCreation.LeadCreationRequest request = new SBR_3_0_LeadCreation.LeadCreationRequest();
        request.campaignId = campaigns[0].Id;
        request.leads = leads;
        String resultContactFirstName;

        List<SBR_3_0_LeadCreation.LeadCreationRequest> requests = new List<SBR_3_0_LeadCreation.LeadCreationRequest>();
        requests.add(request);

        Test.startTest();
        List<SBR_3_0_LeadCreation.LeadCreationResponse> responses = SBR_3_0_LeadCreation.createLeads(requests);
        Test.stopTest();

        Lead leadZero = [SELECT Id, FirstName, Company FROM Lead WHERE Company = 'Leadzero'];
        Lead leadOne = [SELECT Id, FirstName, LastName, Account__c FROM Lead WHERE LastName = 'Leadone'];
        List<Contact> resultContacts = [SELECT Id, FirstName FROM Contact];
        Integer i = 0;
        for (Contact contact : resultContacts) {
            system.debug(contact.FirstName);
            if (contact.FirstName == '123') {
                resultContactFirstName = contact.FirstName;
            }
        }

        System.assertEquals('Campaign Contact', responses[0].Leads[0].LastName, 'Campaign Contact not assigned to lead Last Name');
        System.assertEquals(leadZero.FirstName, leadZero.Company, 'Lead Company Name not assigned to Lead First Name');
        System.assertEquals('Leadone', leadOne.LastName, 'Last Name given with insert is not the last name');
        System.assertEquals(2, resultContacts.size());
        System.assertEquals('123', resultContactFirstName, 'No Campaign Contact created or Campaign contact first name is not company name');
        
        }
    }
}