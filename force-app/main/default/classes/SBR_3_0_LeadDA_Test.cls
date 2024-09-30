/*********************************************************************************************************************
* Apex Class: SBR_3_0_LeadDA
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Concrete class for Lead Data Access
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Kunal Patel           2022-02-09            Initial version    
*********************************************************************************************************************/
@isTest
public with sharing class SBR_3_0_LeadDA_Test {
    static testMethod void testGetLeadStatus() {
        List<LeadStatus> leadStatusList = [SELECT Id, MasterLabel, ApiName FROM LeadStatus LIMIT 3];

        Test.startTest();
            for(LeadStatus ls : leadStatusList) {
                LeadStatus status = SBR_3_0_LeadDA.getLeadStatus(ls.ApiName);
                System.assertEquals(ls.MasterLabel, status.MasterLabel, 'LeadStatus MasterLabel mismatch');
            }
        Test.stopTest();
    }
    
    static testMethod void testGetLeads() {
        Integer count = 100;
        List<Lead> leads = SBR_3_0_TestDataFactory.createLeads(count, false);

        Test.startTest();
            List<Lead> result = SBR_3_0_LeadDA.getLeads();
            System.assertEquals(0, result.size(), 'No Leads should be returned');
            insert leads;

            result = SBR_3_0_LeadDA.getLeads();
            System.assertEquals(count, result.size(), 'Lead count does not match');
        Test.stopTest();
    }

    @isTest
    static void testGetLeadsMap() {
        List<Lead> leads = SBR_3_0_TestDataFactory.createLeads(2, true);

        Set<Id> leadsIdSet = new Set<Id>();
        for ( Lead lead : leads) {
            leadsIdSet.add(lead.Id);
        }

        Test.startTest();
            Map<Id,Lead> leadMap = SBR_3_0_LeadDA.getLeadsMap(leadsIdSet);
            System.assertEquals(2, leadMap.size());
        Test.stopTest();
    }

    @isTest
    static void testGetLeadsByIds() {
        List<Lead> leads = SBR_3_0_TestDataFactory.createLeads(2, true);

        Set<Id> leadsIdSet = new Set<Id>();
        for ( Lead lead : leads) {
            leadsIdSet.add(lead.Id);
        }

        Test.startTest();
            List<Lead> leadList = SBR_3_0_LeadDA.getLeadsByIds(leadsIdSet);
            System.assertEquals(2, leadList.size());
        Test.stopTest();
    }

    @isTest
    static void testGetLeadsFiltered() {
        List<Lead> leads = SBR_3_0_TestDataFactory.createLeads(2, true);

        for(Lead l : leads) {
            l.LeadSource = 'Employee Referral';
        }
        update leads;

        SBR_3_0_GoogleMapCmpController.FilterWrapper wrapper = new SBR_3_0_GoogleMapCmpController.FilterWrapper();

        wrapper.openLeads = true;
        wrapper.leadShareLeads = true;

        Test.startTest();
            List<Lead> leadList = SBR_3_0_LeadDA.getLeadsFiltered(wrapper);
            System.assertEquals(2, leadList.size());
        Test.stopTest();
    }

}