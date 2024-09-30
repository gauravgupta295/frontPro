/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 02-21-2024
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@isTest
public with sharing class  SBR_3_0_CrewSummaryDA_test {
    
    static final String PRODUCT_1_SKU = '123001';
    static final String PRODUCT_2_SKU = '123002';
    
    @TestSetup
    static void testSetup() {
        Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(SBR_3_0_Constants.ACCOUNT_REC_TYPE_CREDIT)?.getRecordTypeId();
        Account acct = new Account(
            RM_Account_Number__c = '12345',
            Name = SBR_3_0_API_Web_Jobsite_DA.JOBSITEACCOUNTNAME,
            BillingStreet = '123 Main Street',
            BillingCity = 'test',
            BillingPostalCode = '20173',
            BillingState = 'VA',
            BillingCountry = 'US',
            Phone = '1234567890',
            RecordTypeId = recordTypeId
        );
        insert acct;
        
        // Create Price Book
        Pricebook2 priceBook = new Pricebook2(Id = Test.getStandardPricebookId(), IsActive = true);
        update priceBook;
        system.debug('priceBook::' + priceBook);
        
        Product_Hierarchy__c prdHierachy = new Product_Hierarchy__c(
            Name = 'Test Hierarchy',
            Product_Hierarchy_Code__c = 'Test_HR_Code',
            RecordTypeId = SBR_3_0_Constants.PRODUCT_HIERARCHY_PRODUCT_SUB_CATEGORY_RT_ID
        );
        insert prdHierachy;
    
        // Create Product
        List<Product2> products = new List<Product2>();
        for (Integer i = 0; i < 3; i++) {
          Product2 product = new Product2();
          product.Name = 'Test Product ' + i;
          if (i == 0) {
            product.Product_Type__c = 'Cat-Class';
            product.Product_SKU__c = '123456';
            product.Category__c = '32134';
            product.Class__c = '2039';
            product.ToolFlex__c = 'N';
            product.isSerialized = true;
            product.Stock_class__c = '';
            product.Bulk_Item__c = false;
            product.Status__c = 'A';
          } else if (i == 1) {
            product.Product_Type__c = 'Parts';
            product.Item_Number__c = '1234GH';
            product.Stock_Class__c = 'AIMFV';
            product.isSerialized = true;
          } else {
            product.Product_Type__c = '';
            product.Item_Number__c = '1285JC';
            product.Stock_Class__c = 'UJEKL';
          }
          products.add(product);
        }
        insert products;
    
        List<PricebookEntry> pbEntries = new List<PricebookEntry>();
        for (Product2 prod : products) {
          PricebookEntry stdPbe = new PricebookEntry();
          stdPbe.Pricebook2Id = Test.getStandardPricebookId();
          stdPbe.Product2Id = prod.Id;
          stdPbe.IsActive = true;
          stdPbe.UnitPrice = 20;
          pbEntries.add(stdPbe);
        }
    
        //insert pbEntries;
        
        SBQQ__Quote__c quote = new SBQQ__Quote__c(
            SBQQ__BillingCity__c = 'Test City',
            Contingency_Plan__c = true,
            Seasonal_Quote__c = true,
            Shift_Pricing_Required__c = true,
            Standby_Pricing__c = true,
            Account_Record_Type_Txt__c = 'Credit'
        );
        insert quote;
        
        SBQQ__QuoteLine__c quoteLine = new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__Product__c = products[0].Id, Line_Composite_Key__c = 'Z23bb');
        insert quoteLine;
        
        SBQQ__QuoteLine__c quoteLine2 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__Product__c = products[1].Id);
        insert quoteLine2;
        
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
        jobLocation.Analysis_Region_Key__c = '945';
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
        branchLocation.Job_Number__c = '332112';
        branchLocation.RecordTypeId = SBR_3_0_Constants.LOCATION_BRANCH_RT_ID;
        branchLocation.Company_Code__c = 'X';
        branchLocation.Time_Zone_Name__c = 'America/Chicago';
        branchLocation.Time_Zone__c = 3;
        branchLocation.Analysis_Region_Key__c = '945';
        //insert branchLocation;
    
    }
    
    
    @isTest public static void testGetCrewSummaryByQuote(){
        Test.startTest();
        SBQQ__Quote__c tq = [SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__BillingCity__c = 'Test City'];
        Set<Id> testSets = new Set<Id>();
        testSets.add(tq.Id);
       
        System.assertEquals(SBR_3_0_CrewSummaryDA.getCrewSummaryByQuote(testSets).isEmpty(), true);
        Test.stopTest();
    }
    
    @isTest public static void testGetCrewSummaryByIds(){
        Test.startTest();
        Crew_Summary__c cs = new Crew_Summary__c();
        insert cs;
        Set<Id> testSets = new Set<Id>();
        testSets.add(cs.Id);
        
        System.assertEquals(SBR_3_0_CrewSummaryDA.getCrewSummaryByIds(testSets)[0].Id, cs.Id);
        Test.stopTest();
    }
    
    private static String TASK = 'Orientation';
    
    @isTest public static void testgetCrewSummaryAggregateList(){
        Test.startTest();
        List<SBQQ__Quote__c> quotes = SBR_3_0_TestDataFactory.createQuotes(1, true, SBR_3_0_Constants.QUOTE_REC_TYPE_RENTAL_QUOTE);
        List<Crew__c> createCrew=   SBR_3_0_TestDataFactory.createCrew(2, false, TASK, quotes[0].Id);
        //    SBR_3_0_TestDataFactory.createCrew(2, false, TASK, quotes[0].Id);
        for(Crew__c crew:createCrew)
        {
            crew.Crew__c=0;
        }
        insert createCrew;
        Set<Id> quoteIds = new Set<Id>();
        for (SBQQ__Quote__c quote : quotes) {
            quoteIds.add(quote.Id);
        }
        
        List<AggregateResult> results = SBR_3_0_CrewSummaryDA.getCrewSummaryAggregateList(quoteIds);
        Test.stopTest();

        
    }
    
    @isTest public static void testgetCrewSummaryForScaffoldingQuotes(){
        Test.startTest();
        List<SBQQ__Quote__c> quotes = SBR_3_0_TestDataFactory.createQuotes(1, true, SBR_3_0_Constants.QUOTE_REC_TYPE_RENTAL_QUOTE);
        List<Crew__c> createCrew=   SBR_3_0_TestDataFactory.createCrew(2, false, TASK, quotes[0].Id);
        //    SBR_3_0_TestDataFactory.createCrew(2, false, TASK, quotes[0].Id);
        for(Crew__c crew:createCrew)
        {
            crew.Crew__c=0;
        }
        insert createCrew;
        Set<Id> quoteIds = new Set<Id>();
        for (SBQQ__Quote__c quote : quotes) {
            quoteIds.add(quote.Id);
        }
       
        List<Crew_Summary__c> results = SBR_3_0_CrewSummaryDA.getCrewSummaryForScaffoldingQuotes(quoteIds);
        Test.stopTest();
        
    }
    
    @isTest public static void testgetCrewSummaryScaffoldingAggregateList(){
        Test.startTest();
        List<SBQQ__Quote__c> quotes = SBR_3_0_TestDataFactory.createQuotes(1, true, SBR_3_0_Constants.QUOTE_REC_TYPE_RENTAL_QUOTE);
        List<Crew__c> createCrew=   SBR_3_0_TestDataFactory.createCrew(2, false, TASK, quotes[0].Id);
        //    SBR_3_0_TestDataFactory.createCrew(2, false, TASK, quotes[0].Id);
        for(Crew__c crew:createCrew)
        {
            crew.Crew__c=0;
        }
        insert createCrew;
        Set<Id> quoteIds = new Set<Id>();
        for (SBQQ__Quote__c quote : quotes) {
            quoteIds.add(quote.Id);
        }
      
        List<AggregateResult> results = SBR_3_0_CrewSummaryDA.getCrewSummaryScaffoldingAggregateList(quoteIds);
        Test.stopTest();
        
    }
    
    @isTest public static void testgetCrewSummaryByQuoteId(){
        Test.startTest();
         List<SBQQ__Quote__c> quotes = SBR_3_0_TestDataFactory.createQuotes(1, true, SBR_3_0_Constants.QUOTE_REC_TYPE_RENTAL_QUOTE);
        List<Crew__c> createCrew=   SBR_3_0_TestDataFactory.createCrew(2, false, TASK, quotes[0].Id);
        //    SBR_3_0_TestDataFactory.createCrew(2, false, TASK, quotes[0].Id);
        for(Crew__c crew:createCrew)
        {
            crew.Crew__c=0;
        }
        insert createCrew;
        Set<Id> quoteIds = new Set<Id>();
        for (SBQQ__Quote__c quote : quotes) {
            quoteIds.add(quote.Id);
        }
       
        Crew_Summary__c result = SBR_3_0_CrewSummaryDA.getCrewSummaryByQuoteId(quotes[0].Id);
        Test.stopTest();
        
    }
    
    
    
}