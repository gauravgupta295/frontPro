/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 12-27-2023
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@isTest
public with sharing class SBR_3_0_QuoteOperations_Test {
    @TestSetup
    static void makeData() {
        Account acct = new Account(
            RM_Account_Number__c = '12345',
            Name = SBR_3_0_API_Web_Jobsite_DA.JOBSITEACCOUNTNAME,
            BillingStreet = '123 Main Street',
            BillingCity = 'test',
            BillingPostalCode = '20173',
            BillingState = 'VA',
            BillingCountry = 'US',
            Company_Code__c = '01',
            phone='3445354635'
        );
        insert acct;
        
        List<Product2> products = SBR_3_0_TestDataFactory.createProducts(1, false);
        products[0].Product_SKU__c = System.Label.E_Labor_Product_SKU;
        insert products;

        List<SBQQ__Quote__c> quotes = SBR_3_0_TestDataFactory.createQuotes(3, false, SBR_3_0_Constants.QUOTE_REC_TYPE_RENTAL_QUOTE);
        
        Schema.Location jobLocation = new Schema.Location();
        jobLocation.Name = 'Test Job Location';
        jobLocation.Street_Address__c = '12 Main Street';
        jobLocation.City__c = 'Toronto';
        jobLocation.Zip_Code__c = 'M7N7B3';
        jobLocation.State__c = 'ON';
        jobLocation.Country__c = 'CA';
        jobLocation.RecordTypeId = SBR_3_0_Constants.LOCATION_BRANCH_RT_ID;
        jobLocation.OMS_Sourcing_Enabled__c = true;
        jobLocation.Distance_Multiplier__c = 50;
        jobLocation.Analysis_Region_Key__c = '921';
        jobLocation.Company_Code__c = '01';
        insert jobLocation;
        
        quotes[2].Branch__c = jobLocation.Id;
        quotes[2].SBQQ__Account__c = acct.Id;
        quotes[2].Quote_Name__c = 'Test Quote 3';
        insert quotes;
        quotes[0].Quote_Name__c = 'Test Quote Line Operation';
        quotes[0].Branch__c = jobLocation.Id; 
        quotes[0].SBQQ__Account__c = acct.Id;
        quotes[1].Branch__c = jobLocation.Id;
        quotes[1].Erection_Allocation__c = 12;
        quotes[1].SBQQ__Account__c = acct.Id;
        update quotes;
        
        List<Analysis_Region__c> regions = [Select Id from Analysis_Region__c where Unique_Name__c = '01-921'];
        Analysis_Region__c region = new Analysis_Region__c();
        if(!regions.isEmpty())
            region = regions[0];
        else {
            region.Analysis_Region_Key__c = '921';
            region.Name = 'Scaffold Region Test';
            region.Company_Code__c = '01';
            region.Unique_Name__c = '01-921';
            insert region;
        }
        
        String EXP_RT_ID = Schema.getGlobalDescribe().get('Expense_Crew_Mapping__c').getDescribe().getRecordTypeInfosByName().get('Expense Mapping').getRecordTypeId();
        
        List<Expense_Crew_Mapping__c> listExpenseMapping = new List<Expense_Crew_Mapping__c>();
        Expense_Crew_Mapping__c mapping1 = new Expense_Crew_Mapping__c();
        mapping1.RecordTypeId=EXP_RT_ID;
        mapping1.Company_Code__c='01';
        mapping1.Expense_Crew_Type__c='Delivery Freight';
        mapping1.SF_Product_SKU__c=products[0].Id;
        mapping1.Analysis_Region__c=region.Id;
        listExpenseMapping.add(mapping1);
        
        Expense_Crew_Mapping__c mapping2 = new Expense_Crew_Mapping__c();
        mapping2.RecordTypeId=EXP_RT_ID;
        mapping2.Company_Code__c='01';
        mapping2.Expense_Crew_Type__c='Misc.';
        mapping2.SF_Product_SKU__c=products[0].Id;
        mapping2.Analysis_Region__c=region.Id;
        listExpenseMapping.add(mapping2);
        
        Expense_Crew_Mapping__c mapping3 = new Expense_Crew_Mapping__c();
        mapping3.RecordTypeId=EXP_RT_ID;
        mapping3.Company_Code__c='01';
        mapping3.Expense_Crew_Type__c='Per Diem';
        mapping3.SF_Product_SKU__c=products[0].Id;
        mapping3.Analysis_Region__c=region.Id;
        listExpenseMapping.add(mapping3);
        insert listExpenseMapping;
        
        List<SBR_Expense__c> expenses = new List<SBR_Expense__c>();
        SBR_Expense__c expense1 = new SBR_Expense__c();
        expense1.Quote_Expenses__c = quotes[0].Id;
        expense1.Quantity__c = 5;
        expense1.Price__c = 5;
        expense1.Analysis_Region_Key__c = '921';
        expense1.ExpenseType__c = 'Delivery Freight';
        expenses.add(expense1);
        
        SBR_Expense__c expense11 = new SBR_Expense__c();
        expense11.Quote_Expenses__c = quotes[0].Id;
        expense11.Quantity__c = 3;
        expense11.Price__c = 3;
        expense11.Analysis_Region_Key__c = '921';
        expense11.ExpenseType__c = 'Delivery Freight';
        expenses.add(expense11);

        SBR_Expense__c expense2 = new SBR_Expense__c();
        expense2.Quote_Expenses__c = quotes[0].Id;
        expense2.Quantity__c = 5;
        expense2.Price__c = 5;
        expense2.Analysis_Region_Key__c = '921';
        expense2.ExpenseType__c = 'Misc.';
        expenses.add(expense2);
        
        SBR_Expense__c expense22 = new SBR_Expense__c();
        expense22.Quote_Expenses__c = quotes[0].Id;
        expense22.Quantity__c = 3;
        expense22.Price__c = 3;
        expense22.Analysis_Region_Key__c = '921';
        expense22.ExpenseType__c = 'Misc.';
        expenses.add(expense22);
        
        SBR_Expense__c expense33 = new SBR_Expense__c();
        expense33.Quote_Expenses__c = quotes[0].Id;
        expense33.Quantity__c = 3;
        expense33.Price__c = 3;
        expense33.Analysis_Region_Key__c = '921';
        expense33.ExpenseType__c = 'Per Diem';
        expenses.add(expense33);
        
        SBR_Expense__c expense44 = new SBR_Expense__c();
        expense44.Quote_Expenses__c = quotes[0].Id;
        expense44.Quantity__c = 3;
        expense44.Price__c = 3;
        expense44.Analysis_Region_Key__c = '921';
        expense44.ExpenseType__c = 'Per Diem';
        expenses.add(expense44);

        insert expenses;
        

    }
    
    @isTest
    static void manageELaborQuoteLinesTest(){
        
         List<SBQQ__Quote__c> quotes = [SELECT Id,Branch__c,Analysis_Region_Key__c,Erection_Allocation__c,Show_Crew_Expense_Calculator__c,Dismantle_Allocation__c FROM SBQQ__Quote__c WHERE Quote_Name__c = 'Test Quote Line Operation'];
         Schema.Location joblocation = [Select Id,Analysis_Region_Key__c from Location WHERE Name='Test Job Location' LIMIT 1];
                   
         quotes[0].Branch__c = joblocation.Id;
         quotes[0].Erection_Allocation__c = 1;
         quotes[0].Show_Crew_Expense_Calculator__c = true;
         quotes[0].Total_Est_Duration_weeks__c = 11;
        
        // quotes[1].Branch__c = joblocation.Id;
       //  quotes[1].Erection_Allocation__c = 15;
       //  quotes[1].Show_Crew_Expense_Calculator__c = true;
       //  quotes[1].Total_Est_Duration_weeks__c = 11;
         Test.startTest();
         update quotes;
         Test.stopTest();
          List<SBQQ__QuoteLine__c> quoteLineList = [
            SELECT Id,Line_Name__c,Misc_Charges_Type__c
            FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c = :quotes[0].Id AND Misc_Charges_Type__c='Delivery Freight'
        ];
        System.assertEquals(quoteLineList.size(), 2, 'Assert Success');
    }
    
    @isTest
    static void updateNameTest(){
        
         List<SBQQ__Quote__c> quotes = [SELECT Id,Branch__c,Analysis_Region_Key__c,Erection_Allocation__c,Show_Crew_Expense_Calculator__c,Dismantle_Allocation__c FROM SBQQ__Quote__c];
         Schema.Location joblocation = [Select Id,Analysis_Region_Key__c from Location WHERE Name='Test Job Location' LIMIT 1];
         
         quotes[0].Branch__c = joblocation.Id;
         quotes[0].Erection_Allocation__c = 1;
         quotes[0].Show_Crew_Expense_Calculator__c = true;
         quotes[0].Total_Est_Duration_weeks__c = 11;
         quotes[0].Rentalman_Quote_Id__c = 'TestRMName';
         quotes[0].Quote_Name__c = null;
        Integer queriesBefore = Limits.getQueries();
        Integer dmlBefore = Limits.getDmlStatements();
         Test.startTest();
         update quotes;
         Test.stopTest();
          List<SBQQ__QuoteLine__c> quoteLineList = [
            SELECT Id
            FROM SBQQ__QuoteLine__c
            WHERE SBQQ__Quote__c = :quotes[0].Id
        ];
        SBQQ__Quote__c updatedQuote = [Select Id,Start_Date__c,End_Date__c,Quote_Name__c ,Job_Name__c from SBQQ__Quote__c where Id=:quotes[0].Id];

        System.assertEquals(updatedQuote.Quote_Name__c,updatedQuote.Job_Name__c, 'Assert Success');
    }
    
    @isTest
    static void deleteELaborQuoteLinesTest() {
        List<SBQQ__Quote__c> quotes = [SELECT Id FROM SBQQ__Quote__c];
        Test.startTest();
        quotes[0].Erection_Allocation__c = 0;
        update quotes[0];
        Test.stopTest();
        List<SBQQ__QuoteLine__c> quoteLineList = [
            SELECT Id
            FROM SBQQ__QuoteLine__c
            WHERE SBQQ__Quote__c = :quotes[0].Id AND Misc_Charges_Type__c = 'Erect'
        ];
        System.assertEquals(quoteLineList.size(), 0, 'Assert Success');
    }
    
    @isTest
    static void updateEndDateForDayTest(){
        
         List<SBQQ__Quote__c> quotes = [SELECT Id,Branch__c,Analysis_Region_Key__c,Erection_Allocation__c,Show_Crew_Expense_Calculator__c,Dismantle_Allocation__c FROM SBQQ__Quote__c];
                   
         quotes[0].Start_Date__c = System.now();
         quotes[0].SBQQ__Status__c = 'Draft';
         quotes[0].Submitted_to_Wynne__c =false;
         quotes[0].Duration__c = 'Day';
         quotes[0].Total_Est_Duration_weeks__c = 1.00;
        
         Test.startTest();
         update quotes;
         Test.stopTest();
        SBQQ__Quote__c updatedQuote = [Select Id,Start_Date__c,End_Date__c from SBQQ__Quote__c where Id=:quotes[0].Id];
        Date startDate =  Date.ValueOf(updatedQuote.Start_Date__c);
        Date endDate =  Date.ValueOf(updatedQuote.End_Date__c);
        System.assertEquals(startDate.daysBetween(endDate), 1, 'Assert Success');
    }
    
    @isTest
    static void updateEndDateForWeekTest(){
        
         List<SBQQ__Quote__c> quotes = [SELECT Id,Branch__c,Analysis_Region_Key__c,Erection_Allocation__c,Show_Crew_Expense_Calculator__c,Dismantle_Allocation__c FROM SBQQ__Quote__c];
                   
         quotes[0].Start_Date__c = System.now();
         quotes[0].SBQQ__Status__c = 'Draft';
         quotes[0].Submitted_to_Wynne__c =false;
         quotes[0].Duration__c = 'Week';
         quotes[0].Total_Est_Duration_weeks__c = 1.00;
        
         Test.startTest();
         update quotes;
         Test.stopTest();
         SBQQ__Quote__c updatedQuote = [Select Id,Start_Date__c,End_Date__c from SBQQ__Quote__c where Id=:quotes[0].Id];
         List<SBQQ__QuoteLine__c> quoteLineList = [
            SELECT Id
            FROM SBQQ__QuoteLine__c
            WHERE SBQQ__Quote__c = :quotes[0].Id
        ];
        Date startDate =  Date.ValueOf(updatedQuote.Start_Date__c);
        Date endDate =  Date.ValueOf(updatedQuote.End_Date__c);
        System.assertEquals(startDate.daysBetween(endDate), 7, 'Assert Success');
    }
    
    @isTest
    static void updateEndDateFor4WeekTest(){
        
         List<SBQQ__Quote__c> quotes = [SELECT Id,Branch__c,Analysis_Region_Key__c,Erection_Allocation__c,Show_Crew_Expense_Calculator__c,Dismantle_Allocation__c FROM SBQQ__Quote__c];
                   
         quotes[0].Start_Date__c = System.now();
         quotes[0].SBQQ__Status__c = 'Draft';
         quotes[0].Submitted_to_Wynne__c =false;
         quotes[0].Duration__c = '4 Week';
         quotes[0].Total_Est_Duration_weeks__c = 1.00;
        
         Test.startTest();
         update quotes;
         Test.stopTest();
          List<SBQQ__QuoteLine__c> quoteLineList = [
            SELECT Id
            FROM SBQQ__QuoteLine__c
            WHERE SBQQ__Quote__c = :quotes[0].Id
         ];
         SBQQ__Quote__c updatedQuote = [Select Id,Start_Date__c,End_Date__c from SBQQ__Quote__c where Id=:quotes[0].Id];
        Date startDate =  Date.ValueOf(updatedQuote.Start_Date__c);
        Date endDate =  Date.ValueOf(updatedQuote.End_Date__c);
         System.assertEquals(startDate.daysBetween(endDate), 28, 'Assert Success');
    }
    
    @isTest
    static void updateEndDateForCustomTest(){
        
         List<SBQQ__Quote__c> quotes = [SELECT Id,Branch__c,Analysis_Region_Key__c,Erection_Allocation__c,Show_Crew_Expense_Calculator__c,Dismantle_Allocation__c FROM SBQQ__Quote__c];
         DateTime dateNow = System.now();            
         quotes[0].Start_Date__c = System.now();
         quotes[0].SBQQ__Status__c = 'Draft';
         quotes[0].Submitted_to_Wynne__c =false;
         quotes[0].Duration__c = 'Custom';
         quotes[0].End_Date__c = dateNow.addDays(5);
         quotes[0].Total_Est_Duration_weeks__c = 1.00;
        
         Test.startTest();
         update quotes;
         Test.stopTest();
         List<SBQQ__QuoteLine__c> quoteLineList = [
            SELECT Id
            FROM SBQQ__QuoteLine__c
            WHERE SBQQ__Quote__c = :quotes[0].Id
        ];
        SBQQ__Quote__c updatedQuote = [Select Id,Start_Date__c,End_Date__c from SBQQ__Quote__c where Id=:quotes[0].Id];
        Date startDate =  Date.ValueOf(updatedQuote.Start_Date__c);
        Date endDate =  Date.ValueOf(updatedQuote.End_Date__c);
        System.assertEquals(startDate.daysBetween(endDate), 5, 'Assert Success');
    }
    
    @isTest
    static void updateQuoteLinesTest() {
        List<SBQQ__Quote__c> quotes = [
            SELECT Id, Analysis_Region_Key__c, Include_Advanced_Scope__c, Show_Crew_Expense_Calculator__c, SBQQ__Account__c,
            SBQQ__Account__r.RecordTypeId, SBQQ__Account__r.RPP__c, RPP__c
            FROM SBQQ__Quote__c
            WHERE Analysis_Region_Key__c = '921' AND  Quote_Name__c = 'Test Quote Line Operation'
        ];
        List<SBQQ__QuoteLine__c> quoteLines = [
            SELECT Id
            FROM SBQQ__QuoteLine__c
            WHERE SBQQ__Quote__c = :quotes[0].Id
        ];
        Test.startTest();
        if (!quotes.isEmpty()) {
            quotes[0].Erection_Allocation__c = 60;
            quotes[0].Show_Crew_Expense_Calculator__c = true;
            update quotes[0];
    } 
        //quoteLines[0].Weekly_Rate__c = 105;
        //quoteLines[0].Product_SKU_Text__c = 'XXXXX';
        //quoteLines[0].Line_Name__c = 'ELABOR';
        //quoteLines[0].Misc_Charges_Type__c = 'Dismantle';
        //update quoteLines;
       
        SBR_3_0_QuoteOperations.updateQuoteLines(new Set<Id>{ quotes[0].Id });
        SBR_3_0_QuoteOperations.setRPPFieldToTrue(quotes);
        SBR_3_0_QuoteOperations.enableScaffoldQuotesOptions(quotes);
        Test.stopTest();

        List<SBQQ__QuoteLine__c> quoteLineList = [
            SELECT Id
            FROM SBQQ__QuoteLine__c
            WHERE SBQQ__Quote__c = :quotes[0].Id
        ];
        System.assertEquals(quoteLineList.size(), 6, 'Assert Success');
    }
    @isTest 
    static void enableScaffoldQuotesOptionsTest () {
        SBQQ__Quote__c testQuote = [SELECT Id, Include_Advanced_Scope__c From SBQQ__Quote__c WHERE Quote_Name__c = 'Test Quote 3'];
        test.startTest();
        system.assertEquals(true, testQuote.Include_Advanced_Scope__c, 'Failure, Options not set by trigger');
        test.stopTest();
    }
    
    @isTest 
    static void handleDeliveryOptionChangeTest () {
        SBQQ__Quote__c testQuote = [SELECT Id, Include_Advanced_Scope__c,Delivery_Charges_Override__c,IsDeliveryOptionsChanged__c From SBQQ__Quote__c WHERE Quote_Name__c = 'Test Quote 3'];
        test.startTest();
        testQuote.Delivery_Charges_Override__c = true;
        update testQuote;
        SBQQ__Quote__c updatedQuote = [SELECT Id, Include_Advanced_Scope__c,Delivery_Charges_Override__c,IsDeliveryOptionsChanged__c From SBQQ__Quote__c WHERE Quote_Name__c = 'Test Quote 3'];
        Assert.areEqual(true,updatedQuote.IsDeliveryOptionsChanged__c,'Update Success');
        test.stopTest();
    }
}