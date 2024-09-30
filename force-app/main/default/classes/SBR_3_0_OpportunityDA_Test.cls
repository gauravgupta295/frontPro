/*********************************************************************************************************************
* Apex Class: SBR_3_0_OpportunityDA_Test
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Class to test SBR_3_0_OpportunityDA_Test
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME                  DATE                    DETAIL FEATURES
    1.0         Joelle Ramiandrisoa           2022-08-17                Initial version    
*********************************************************************************************************************/
@isTest public class SBR_3_0_OpportunityDA_Test {
    static testMethod void testGetOpportunities() {
        List<Account> acc = SBR_3_0_TestDataFactory.createAccounts(1, true, 'Prospect');
        List<Opportunity> opp = SBR_3_0_TestDataFactory.createOppts(1, acc[0].Id, true);

        List<Opportunity> result = new List<Opportunity>();
        List<Opportunity> result2 = new List<Opportunity>();

        Test.startTest();
            result = SBR_3_0_OpportunityDA.getOpportunities();
        Test.stopTest();

        System.assertEquals(1, result.size());
    }

    static testMethod void testGetOpportunitiesWithIds() {
        List<Account> acc = SBR_3_0_TestDataFactory.createAccounts(1, true,'Prospect');
        List<Opportunity> opp = SBR_3_0_TestDataFactory.createOppts(1, acc[0].Id, true);

        Set<Id> oppIds = new Set<Id>();
        oppIds.add(opp[0].Id);

        Map<Id, Opportunity> result = new Map<Id, Opportunity>();

        Test.startTest();
            result = SBR_3_0_OpportunityDA.getOpportunities(oppIds);
        Test.stopTest();

        System.assertEquals(1, result.size());
    }

    static testMethod void testGetOpportunityById() {
        List<Account> acc = SBR_3_0_TestDataFactory.createAccounts(1, true, 'Prospect');
        List<Opportunity> opp = SBR_3_0_TestDataFactory.createOppts(1, acc[0].Id, true);

        Test.startTest();
            Opportunity result = SBR_3_0_OpportunityDA.getOpportunity(opp[0].Id);
        Test.stopTest();
    }

    static testMethod void testGetOpportunitiesListWithIds() {
        List<Account> acc = SBR_3_0_TestDataFactory.createAccounts(1, true,'Prospect');
        List<Opportunity> opp = SBR_3_0_TestDataFactory.createOppts(1, acc[0].Id, true);

        Set<Id> oppIds = new Set<Id>();
        oppIds.add(opp[0].Id);

        List<Opportunity> result = new List<Opportunity>();

        Test.startTest();
            result = SBR_3_0_OpportunityDA.getOpportunitiesList(oppIds);
        Test.stopTest();

        System.assertEquals(1, result.size());
    }

    static testMethod void testFilteredOpportunity() {
        List<Account> acc = SBR_3_0_TestDataFactory.createAccounts(1, true, 'Prospect');
        List<Opportunity> opps = SBR_3_0_TestDataFactory.createOppts(1, acc[0].Id, true);

        Opportunity opp = opps[0];
        opp.Name = 'OppTest';
        opp.StageName = 'Qualification';
        opp.CloseDate = Date.today().addDays(15);
        opp.Est_Start_Date__c = Date.today().addDays(15);
        update opp;

        SBR_3_0_GoogleMapCmpController.FilterWrapper wrapper = new SBR_3_0_GoogleMapCmpController.FilterWrapper();
        wrapper.opportunitySearch = 'OppTest';
        wrapper.opportunityStage = JSON.serialize(new List<String>{'Qualification'});
        wrapper.openOpportunity = true;
        wrapper.closeDateNext30DaysOpportunity = true;
        wrapper.closeDateNextXDaysOpportunity = true;
        wrapper.closeDateNextXDaysOpportunityValue = '50';
        wrapper.estDateNext30DaysOpportunity = true;
        wrapper.estDateNextXDaysOpportunity = true;
        wrapper.estDateNextXDaysOpportunityValue = '50';

        Test.startTest();
            List<Opportunity> results = SBR_3_0_OpportunityDA.getOpportunityFiltered(wrapper);
        Test.stopTest();

        System.assertEquals(results.size(), 1);
    }

}