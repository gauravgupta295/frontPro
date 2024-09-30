/*********************************************************************************************************************
* Apex Class: SBR_3_0_CrewDA_Test
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Class to test SBR_3_0_CrewDA_Test
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Kunal Patel             2022-12-19          Initial version    
*********************************************************************************************************************/
@isTest
public with sharing class SBR_3_0_CrewDA_Test {
    
    @TestSetup 
    static void setupTestData() {

        Account acct = new Account(
            RM_Account_Number__c = '12345',
            Name = SBR_3_0_API_Web_Jobsite_DA.JOBSITEACCOUNTNAME,
            BillingStreet = '123 Main Street',
            BillingCity = 'test',
            BillingPostalCode = '20173',
            BillingState = 'VA',
            BillingCountry = 'US',
            Company_Code__c = '1',
            phone = '3434343434'
        );
        insert acct;
		
        // Create Branch
        Schema.Location branchLocation = new Schema.Location();
        branchLocation.Branch_Location_Number__c = '720';
        branchLocation.Name = 'Test Branch Location';
        branchLocation.Street_Address__c = '12 Main Street';
        branchLocation.City__c = 'Toronto';
        branchLocation.Zip_Code__c = 'M7N7B3';
        branchLocation.State__c = 'ON';
        branchLocation.Country__c = 'CA';
        branchLocation.Latitude_Longitude__Latitude__s = 56.77395;
        branchLocation.Latitude_Longitude__Longitude__s = -111.42814;
        branchLocation.Job_Number__c='332112';
        branchLocation.RecordTypeId = SBR_3_0_Constants.LOCATION_BRANCH_RT_ID;
        branchLocation.Company_Code__c = 'X';
        branchLocation.Time_Zone_Name__c = 'America/Chicago';
        branchLocation.Time_Zone__c = 3;
        insert branchLocation;
		
        
        SBQQ__Quote__c quote = new SBQQ__Quote__c(
            SBQQ__BillingCity__c = 'Test City',
            Contingency_Plan__c = true,
            Seasonal_Quote__c = true,
            Shift_Pricing_Required__c = true,
            Standby_Pricing__c = true,
            Company_Code__c = '1',
            SBQQ__Account__c = acct.Id,
            SBQQ__DeliveryMethod__c = 'Delivery',
            Start_Date__c = System.now().addMonths(2),
            End_Date__c = System.now().addMonths(3),
            Duration__c = 'Custom',
            Distance_to_Job_Site__c = 90,
            ST_Overhead__c =10,
            ST_Burden__c =10,
            ST_Profit__c =10,
            OT_Burden__c =10,
            OT_Profit__c =10,
            OT_Overhead__c =10,
            Rates_To_Be_Used__c = 'Suggested',
            Branch__c = branchLocation.Id
        );
        insert quote;

        Crew_Summary__c cs = new Crew_Summary__c();
        cs.Quote__c=quote.id;
        cs.Task_Type__c='Travel In';
        cs.Product_SKU__c=null;
        insert cs;
        
        Crew__c c = new Crew__c();
        c.Quote__c = quote.Id;
        c.Crew__c = 0;
        c.Shift__c = 5;
        c.Standard_Hours__c = 5;
        c.Rate_Standard__c = 5;
        c.Overtime_Hours__c = 5;
        c.Rate_Overtime__c = 5;
        c.Analysis_Region_Key__c = '922';
        c.Task__c = 'Misc';
        c.Crew_Summary__c = cs.Id;
        insert c;
        
    }

    static testMethod void testGetQuotesCrew() {
        
        Test.startTest();
            SBQQ__Quote__c quote = [SELECT ID FROM SBQQ__Quote__c LIMIT 1];
            List<Crew__c> crew = SBR_3_0_CrewDA.getQuotesCrew(quote.Id);
        	SBR_3_0_CrewDA.updateCrewRecord(crew);
        	List<Crew__c> crewRefresh = SBR_3_0_CrewDA.getQuotesCrewRefresh(quote.Id);
        	List<Crew__c> crewRefreshWithTask = SBR_3_0_CrewDA.getCrewsForQuotes(quote.Id,new List<string>{'Misc'});
        	List<Crew__c> getCrews = SBR_3_0_CrewDA.getCrews(new List<Id>{quote.Id});
        Test.stopTest();

        System.assertEquals(1, crew.size());
        System.assertEquals(1, crewRefresh.size());
    }
}