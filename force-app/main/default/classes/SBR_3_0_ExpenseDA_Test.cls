/*********************************************************************************************************************
* Apex Class: SBR_3_0_ExpenseDA_Test
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Class to test SBR_3_0_ExpenseDA_Test
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Kunal Patel             2022-12-19          Initial version    
*********************************************************************************************************************/
@isTest
public with sharing class SBR_3_0_ExpenseDA_Test {
    
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
            Phone = '1234567890'
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
            Branch__c = branchLocation.Id
        );
        insert quote;
		List<Product2> lProducts = SBR_3_0_TestDataFactory.createProducts(1,TRUE);
        SBR_Expense__c ex = new SBR_Expense__c();
        ex.Quote_Expenses__c = quote.Id;
        ex.Quantity__c = 5;
        ex.Price__c = 5;
        ex.Analysis_Region_Key__c = '921';
        ex.ExpenseType__c = 'Safety/Consumables';
        ex.Product_Lookup__c  = lProducts[0]?.id;
        insert ex;

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
        mapping.SF_Product_SKU__c=lProducts[0].Id;
        mapping.Analysis_Region__c=region.Id;

        insert mapping;

        Expense_Crew_Mapping__c mapping2 = new Expense_Crew_Mapping__c();
        mapping2.RecordTypeId=CREWSUM_RT_ID;
        mapping2.Company_Code__c='01';
        mapping2.Expense_Crew_Type__c='Set Up';
        mapping2.SF_Product_SKU__c=lProducts[0].Id;
        mapping2.Analysis_Region__c=region.Id;

        insert mapping2;
    }

    static testMethod void testGetQuotesExpense() {
        
        Test.startTest();
            SBQQ__Quote__c quote = [SELECT ID FROM SBQQ__Quote__c LIMIT 1];
            List<SBR_Expense__c> expense = SBR_3_0_ExpenseDA.getQuotesExpense(quote.Id);
            List<SBR_Expense__c> expenseRefresh = SBR_3_0_ExpenseDA.getQuotesExpenseRefresh(quote.Id);
        Test.stopTest();

        System.assertEquals(1, expense.size());
        System.assertEquals(1, expenseRefresh.size());
    }

    static testMethod void testGetScaffoldingQuotesExpense() {
        Product2 product = [SELECT ID FROM Product2 LIMIT 1];
        SBQQ__Quote__c quote = [SELECT ID FROM SBQQ__Quote__c LIMIT 1];
        SBR_Expense__c ex1 = new SBR_Expense__c();
        ex1.Quote_Expenses__c = quote.Id;
        ex1.Quantity__c = 1;
        ex1.Price__c = 100;
        ex1.Analysis_Region_Key__c = '921';
        ex1.ExpenseType__c = 'Safety/Consumables';
        insert ex1;

        ex1.Product_Lookup__c  = product?.id;
        update ex1;

        Test.startTest();
            
            Set<Id> quotes = new Set<Id>();
            quotes.add(quote.Id);
            List<SBR_Expense__c> expense = SBR_3_0_ExpenseDA.getQuotesExpensesForScaffoldingQuotes(quotes);
            List<AggregateResult> aggResult = SBR_3_0_ExpenseDA.getExpenseAggregateList(quotes);
        Test.stopTest();

        System.assertNotEquals(1, expense.size());
        Decimal cost=0;        
        if(aggResult != null && aggResult.size() > 0){ 
            for(AggregateResult aggrExp : aggResult){   
                cost = (Decimal)aggrExp.get('total'); 
            }
        }
        System.assertEquals(125, cost);
    }
}