@isTest
private class SBR_3_0_CrewTriggerHandler_Test {
    
    @TestSetup
    static void makeData(){

        List<Product2> products = SBR_3_0_TestDataFactory.createProducts(1, false);
        products[0].Product_SKU__c = 'XXXXX';
        insert products;

        Analysis_Region__c region = new Analysis_Region__c();
        region.Analysis_Region_Key__c = '921';
        region.Name = 'Test Region';
        region.Company_Code__c = '01';
        insert region;

        String EXP_RT_ID = Schema.getGlobalDescribe().get('Expense_Crew_Mapping__c').getDescribe().getRecordTypeInfosByName().get('Expense Mapping').getRecordTypeId();
        String CREWSUM_RT_ID = Schema.getGlobalDescribe().get('Expense_Crew_Mapping__c').getDescribe().getRecordTypeInfosByName().get('Crew Mapping').getRecordTypeId();
    
        Expense_Crew_Mapping__c mapping = new Expense_Crew_Mapping__c();
        mapping.RecordTypeId=EXP_RT_ID;
        mapping.Company_Code__c='01';
        mapping.Expense_Crew_Type__c='Safety/Consumables';
        mapping.SF_Product_SKU__c=products[0].Id;
        mapping.Analysis_Region__c=region.Id;

        insert mapping;

        Expense_Crew_Mapping__c mapping2 = new Expense_Crew_Mapping__c();
        mapping2.RecordTypeId=CREWSUM_RT_ID;
        mapping2.Company_Code__c='01';
        mapping2.Expense_Crew_Type__c='Set Up';
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
            ShippingStreet = '123 Main Street',
            ShippingCity = 'test',
            ShippingPostalCode = '20173',
            ShippingState = 'VA',
            ShippingCountry = 'US',
            Company_Code__c = '1'
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
            Branch__c = branchLocation.Id
        );
        insert quote;
        
        Crew_Summary__c cs = new Crew_Summary__c();
        cs.Quote__c=quote.id;
        cs.Task_Type__c='Travel In';
        //cs.Product_SKU__c='123005';
        insert cs;

        Crew__c cTest = new Crew__c();
        cTest.Quote__c = quote.Id;
        cTest.Crew__c = 0;
        cTest.Shift__c = 5;
        cTest.Standard_Hours__c = 5;
        cTest.Rate_Standard__c = 5;
        cTest.Overtime_Hours__c = 5;
        cTest.Rate_Overtime__c = 5;
        cTest.Analysis_Region_Key__c = '921';
        cTest.Task__c = 'Misc';
        cTest.Crew_Summary__c = cs.Id;
        insert cTest;
    }

    @isTest
    static void testBeforeInsert() {
        SBQQ__Quote__c quote1 = [SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__BillingCity__c = 'Test City' LIMIT 1];
        Crew_Summary__c cs1 = [SELECT Id FROM Crew_Summary__c WHERE Task_Type__c = 'Travel In' LIMIT 1];
        System.Test.startTest();
        Crew__c c = new Crew__c();
        c.Quote__c = quote1.Id;
        c.Crew__c = 0;
        c.Shift__c = 5;
        c.Standard_Hours__c = 5;
        c.Rate_Standard__c = 5;
        c.Overtime_Hours__c = 5;
        c.Rate_Overtime__c = 5;
        c.Analysis_Region_Key__c = '921';
        c.Task__c = 'Misc';
        c.Crew_Summary__c = cs1.Id;
        insert c;
        System.Test.stopTest();
        List<Crew__c> allCrews = [SELECT Id FROM Crew__c WHERE Analysis_Region_Key__c = '921'];
        System.assertNotEquals(1, allCrews.size());
    }
    
    @isTest
    static void testAfterDelete() {
        SBQQ__Quote__c quote1 = [SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__BillingCity__c = 'Test City' LIMIT 1];
        Crew_Summary__c cs1 = [SELECT Id FROM Crew_Summary__c WHERE Task_Type__c = 'Travel In' LIMIT 1];
        Crew__c c1 = [SELECT Id FROM Crew__c WHERE Analysis_Region_Key__c = '921' LIMIT 1];

        System.Test.startTest();
        delete c1;
        System.Test.stopTest();
        List<Crew__c> allCrews = [SELECT Id FROM Crew__c WHERE Analysis_Region_Key__c = '921'];
        System.assertEquals(0, allCrews.size());
    }
}