/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 03-06-2024
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@isTest
public with sharing class SBR_3_0_QuoteDA_Test {
    @TestSetup
    static void makeData(){
        // Create Account
        Account acct = new Account();
        acct.RM_Account_Number__c = '4';
        acct.Company_Code__c = '01';
        acct.Name = 'Test Account';
        acct.Record_Type_Text__c = 'Credit';
        acct.E_mail_Address__c = '123@asdf.com';
        acct.Phone = '1234567890';
        acct.BillingStreet = '123 Main Street';
        acct.BillingCity = 'Toronto';
        acct.BillingPostalCode = 'M9N7V5';
        acct.BillingState = 'ON';
        acct.BillingCountry = 'CA';
        acct.Drivers_License__c = 'AKF';
        acct.Driver_s_License_State__c = 'AL';
        insert acct;
        
        // Create Analysis Region
        Analysis_Region__c region = new Analysis_Region__c();
        region.Analysis_Region_Key__c = '001';
        region.Name = 'Test Region';
        region.Company_Code__c = '01';
        insert region;
        
        // Create Location
        Schema.Location jobLocation = new Schema.Location();
        jobLocation.Name = 'Test Job Location';
        jobLocation.Street_Address__c = '12 Main Street';
        jobLocation.City__c = 'Toronto';
        jobLocation.Zip_Code__c = 'M7N7B3';
        jobLocation.State__c = 'ON';
        jobLocation.Country__c = 'CA';
        jobLocation.RecordTypeId = SBR_3_0_Constants.LOCATION_JOB_RT_ID;
        jobLocation.OMS_Sourcing_Enabled__c = true;
        jobLocation.Distance_Multiplier__c = 50;
        jobLocation.Analysis_Region_Key__c = '001';
        jobLocation.Company_Code__c = '01';
        insert jobLocation;
        
        // Create Branch
        Schema.Location branchLocation = new Schema.Location();
        branchLocation.Branch_Location_Number__c = '720';
        branchLocation.Name = 'Test Branch Location';
        branchLocation.Street_Address__c = '12 Main Street';
        branchLocation.City__c = 'Toronto';
        branchLocation.Zip_Code__c = 'M7N7B3';
        branchLocation.State__c = 'ON';
        branchLocation.Country__c = 'CA';
        branchLocation.Job_Number__c='332112';
        branchLocation.RecordTypeId = SBR_3_0_Constants.LOCATION_BRANCH_RT_ID;
        branchLocation.Company_Code__c = 'X';
        branchLocation.Time_Zone_Name__c = 'America/Chicago';
        branchLocation.Time_Zone__c = 3;
        branchLocation.Analysis_Region_Key__c = '921';
        insert branchLocation;
        
        // Create Job Site
        AssociatedLocation jobSite = new AssociatedLocation(
            Name__c = 'Test Job Site',
            ParentRecordId = acct.Id,
            LocationId = jobLocation.Id,
            Branch__c = branchLocation.Id,
            Job_Number__c = '20221004A'
        );
        insert jobSite;
        
        // Create Quote
        SBQQ__Quote__c quote = new SBQQ__Quote__c(
            Quote_Name__c = 'Test Quote',
            SBQQ__Account__c = acct.Id,
            Jobsite__c = jobSite.Id,
            SBQQ__DeliveryMethod__c = 'Delivery',
            Start_Date__c = date.valueOf('2022-10-07 12:00:00'),
            End_Date__c = date.valueOf('2022-10-07 12:00:00'),
            Opt_Out_RPP__c = false,
            Opt_Out_Fuel_Charge__c = false,
            Selling_Channel__c = 'SBRB2B',
            Rentalman_Quote_Id__c = 'Test QId',
            Company_Code__c = '01',
            Show_Crew_Expense_Calculator__c = true,
            Branch__c = branchLocation.Id
        );
        insert quote; 
    }

    @isTest
    static void testGetQuote(){
        SBQQ__Quote__c quote = [SELECT id FROM SBQQ__Quote__c];
        Test.startTest();
        SBQQ__Quote__c retrievedQuote = SBR_3_0_QuoteDA.getQuote(quote.Id);
        Test.stopTest();

        Assert.areEqual(quote.Id, retrievedQuote.Id, 'A quote should be retrieved');
    }

    @isTest
    static void testGetQuotes(){
        SBQQ__Quote__c quote = [SELECT id FROM SBQQ__Quote__c];
        Set<Id> quoteIds = new Set<Id>();
        quoteIds.add(quote.Id);
        Test.startTest();
        Map<Id, SBQQ__Quote__c> retrievedQuotes = SBR_3_0_QuoteDA.getQuotes(quoteIds);
        Test.stopTest();
        SBQQ__Quote__c retrievedQuote = new SBQQ__Quote__c();
        for (Id key: retrievedQuotes.keySet()) {
            retrievedQuote = retrievedQuotes.get(key);
        }
        Assert.areEqual(quote.Id, retrievedQuote.Id, 'A quote should be retrieved');
    }

    @isTest
    static void testGetRecordTypeId() {
        Test.startTest();
        Id retrievedId = SBR_3_0_QuoteDA.getRecordTypeId(SBR_3_0_Constants.QUOTE_REC_TYPE_RENTAL_QUOTE);
        Test.stopTest();
        Assert.areEqual(SBR_3_0_Constants.QUOTE_REC_TYPE_RENTAL_QUOTE_ID, retrievedId,'Quote Record Type Id should match');
    }
    
    @isTest
    static void testGetScaffoldingQuotes(){
        SBQQ__Quote__c quote = [SELECT id FROM SBQQ__Quote__c];
        Set<Id> quoteIds = new Set<Id>();
        quoteIds.add(quote.Id);
        Test.startTest();
        List<SBQQ__Quote__c> retrievedQuotes = SBR_3_0_QuoteDA.getScaffoldingQuotes(quoteIds);
        Test.stopTest();
        Assert.isTrue(retrievedQuotes.size()>0, 'Retrieved Quotes should not be empty');      
    }
        
    @isTest
    static void testGetQuoteByRentalmanQuoteId(){
        SBQQ__Quote__c quote = [SELECT id FROM SBQQ__Quote__c];
        Test.startTest();
        SBQQ__Quote__c retrievedQuote = SBR_3_0_QuoteDA.getQuoteByRentalmanQuoteId('Test QId','01');
        Test.stopTest();       
        Assert.areEqual(quote.Id, retrievedQuote.Id, 'A quote should be retrieved');
    }
    
    @isTest
    static void testGetQuoteByRentalmanQuoteId1(){
        Test.startTest();
        List<SBQQ__Quote__c> retrievedQuotes = SBR_3_0_QuoteDA.getQuoteByRentalmanQuoteId('Test QId');
        Test.stopTest();
        Assert.isTrue(retrievedQuotes.size()>0, 'Retrieved Quotes should not be empty');        
    }
    
    @isTest
    static void testGetRelatedAccount(){
        Test.startTest();
        List<Account> retrievedAccounts = SBR_3_0_QuoteDA.getRelatedAccount('01-4');
        Test.stopTest();
        Assert.isTrue(retrievedAccounts.size()>0,  'Retrieved Account should not be empty');
    }
    
    @isTest
    static void getRelatedAccountId(){
        Account acc = [SELECT id FROM Account];
        Test.startTest();
        List<Account> retrievedAccounts = SBR_3_0_QuoteDA.getRelatedAccountId(acc.Id);
        Test.stopTest();
        Assert.isTrue(retrievedAccounts.size()>0, 'Retrieved Account should not be empty');
    }
    
    @isTest
    static void testPunchoutGetquote(){
         SBQQ__Quote__c quote = [SELECT id FROM SBQQ__Quote__c];
        Test.startTest();
        SBQQ__Quote__c retrievedQuote = SBR_3_0_QuoteDA.punchoutGetQuote(quote.Id);
        Test.stopTest();

        Assert.areEqual(quote.Id, retrievedQuote.Id, 'A quote should be retrieved');
    }
    
    @isTest
    static void testPunchoutGetQuoteResponse(){
         SBQQ__Quote__c quote = [SELECT id FROM SBQQ__Quote__c];
        Test.startTest();
        SBQQ__Quote__c retrievedQuote = SBR_3_0_QuoteDA.punchoutGetQuoteResponse(quote.Id);
        Test.stopTest();

        Assert.areEqual(quote.Id, retrievedQuote.Id, 'A quote should be retrieved');
    }

}