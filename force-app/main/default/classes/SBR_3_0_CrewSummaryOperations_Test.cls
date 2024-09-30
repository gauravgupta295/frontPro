@isTest
public with sharing class SBR_3_0_CrewSummaryOperations_Test {
    private static String TASK = 'Orientation';
 
    @TestSetup
    static void makeData(){

        List<Product2> products = SBR_3_0_TestDataFactory.createProducts(1, false);
        products[0].Product_SKU__c = System.Label.E_Labor_Product_SKU;
        insert products;

        Analysis_Region__c region = new Analysis_Region__c();
        region.Analysis_Region_Key__c = '921';
        region.Name = 'Test Region';
        region.Company_Code__c = '01';
        insert region;

        String EXP_RT_ID = Schema.getGlobalDescribe().get('Expense_Crew_Mapping__c').getDescribe().getRecordTypeInfosByName().get('Expense Mapping').getRecordTypeId();
        String CREWSUM_RT_ID = Schema.getGlobalDescribe().get('Expense_Crew_Mapping__c').getDescribe().getRecordTypeInfosByName().get('Crew Mapping').getRecordTypeId();
    
        Expense_Crew_Mapping__c mapping = new Expense_Crew_Mapping__c();
        mapping.RecordTypeId=CREWSUM_RT_ID;
        mapping.Company_Code__c='01';
        mapping.Expense_Crew_Type__c='Erect';
        mapping.SF_Product_SKU__c=products[0].Id;
        mapping.Analysis_Region__c=region.Id;

        insert mapping;

        Expense_Crew_Mapping__c mapping2 = new Expense_Crew_Mapping__c();
        mapping2.RecordTypeId=CREWSUM_RT_ID;
        mapping2.Company_Code__c='01';
        mapping2.Expense_Crew_Type__c='Move';
        mapping2.SF_Product_SKU__c=products[0].Id;
        mapping2.Analysis_Region__c=region.Id;

        insert mapping2;
        
        Account acct = new Account(
            RM_Account_Number__c = '12345',
            Name = SBR_3_0_API_Web_Jobsite_DA.JOBSITEACCOUNTNAME,
            BillingStreet = '123 Main Street',
            BillingCity = 'test',
            BillingPostalCode = '20173',
            BillingState = 'VA',
            BillingCountry = 'US',
            Company_Code__c = '01'
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
        branchLocation.Analysis_Region_Key__c = '921';
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
            Rates_To_Be_Used__c = 'Suggested',
            Erection_Allocation__c=70,
            Show_Crew_Expense_Calculator__c=true,
            Branch__c = branchLocation.Id,
            Submitted_to_Wynne__c=true
        );
        insert quote;
        
        Crew_Summary__c cs = new Crew_Summary__c();
        cs.Quote__c=quote.id;
        cs.Task_Type__c='Erect';
        cs.Product_SKU__c=products[0].Id;
        insert cs;
    
        //SBR_3_0_TestDataFactory.createCrew(2, true, TASK, quote.Id);
        
        Crew__c c = new Crew__c();
        c.Quote__c = quote.Id;
        c.Crew__c = 0;
        c.Shift__c = 5;
        c.Standard_Hours__c = 5;
        c.Rate_Standard__c = 5;
        c.Overtime_Hours__c = 5;
        c.Rate_Overtime__c = 5;
        c.Analysis_Region_Key__c = '921';
        c.Task__c = 'Move';
        c.Crew_Summary__c = cs.Id;
        insert c;

    }

    @isTest
    static void testUpdateQuotes() {
        
        List<SBQQ__Quote__c> crews = [SELECT Id, ST_Average__c,OT_Average__c FROM SBQQ__Quote__c Limit 1];

        System.assertEquals(null, crews[0].ST_Average__c);
        System.assertEquals(null, crews[0].OT_Average__c);
        
    }

    @isTest
    static void testupdateQuoteLineForScaffolding() {
        SBQQ__Quote__c quote = [Select Id, Submitted_to_Wynne__c from SBQQ__Quote__c Limit 1];
        quote.Submitted_to_Wynne__c=false;
        SBR_3_0_TriggerHandler.bypass('SBR_3_0_QuoteTriggerHandler');
        update quote;
        
        Test.startTest();
        List<Crew__c> crews = [Select Id,Name,Crew__c,Standard_Hours__c, Quote__c FROM Crew__c];
        for(Crew__c crew : crews){
            crew.Crew__c=40;
            crew.Standard_Hours__c=10;
        }
        update crews;
        test.stopTest();
    }
    
    @isTest
    static void testdeleteQuote() {
        
        Test.startTest();
        SBQQ__Quote__c quote = [SELECT id from SBQQ__Quote__c LIMIT 1];
        List<Crew__c> crews = [Select Id,Name,Crew__c,Standard_Hours__c, Quote__c FROM Crew__c where Quote__c =:quote.Id];
        
        delete crews;
        List<Crew__c> finalCrews = [Select Id,Name,Crew__c,Standard_Hours__c, Quote__c FROM Crew__c where Quote__c =:quote.Id];
        System.assertEquals(finalCrews.size(),0);
        test.stopTest();

        
    }
}