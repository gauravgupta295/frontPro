@isTest
public class SBR_3_0_QuoteLineTriggerHandler_Test {
    @TestSetup
    static void makeData(){
        List<Product2> products = SBR_3_0_TestDataFactory.createProducts(2, false);
        products[0].Product_SKU__c = 'XXXXX';
        products[1].Product_SKU__c = '00XXXXX';
        insert products;
        
        List<SBQQ__Quote__c> quotes = SBR_3_0_TestDataFactory.createQuotes(1, true, SBR_3_0_Constants.QUOTE_REC_TYPE_RENTAL_QUOTE);
        
        List<SBQQ__Quote__c> salesQuote = SBR_3_0_TestDataFactory.createQuotes(1, true, 'Sales_Quote');   
        
    }
    
    @isTest
    static void updateQuoteLineWithProductTest () {
        List<SBQQ__Quote__c> quotes = [SELECT Id FROM SBQQ__Quote__c WHERE recordtype.developername = 'Rental_Quote'];
                
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        UserRole ur = [SELECT Id, Name FROM UserRole where Name = 'Sales - US'];
        User user = new User(Alias = 'standt', Email='standardperson@sunbeltrentals.com',
                             EmailEncodingKey='UTF-8', LastName='Testing',UserRoleId =ur.Id, LanguageLocaleKey='en_US',
                             LocaleSidKey='en_US', ProfileId = p.Id,
                             TimeZoneSidKey='America/Los_Angeles', UserName='standardperson@testorg.com');
        insert user;
        
        System.runAs(user){
            List<Product2> products = [SELECT Id FROM Product2 WHERE Product_SKU__c = '00XXXXX'];
            List<SBQQ__QuoteLine__c> beforeQuoteLines = SBR_3_0_TestDataFactory.createQuoteLines(1, false, quotes[0].Id );
            system.debug('@@beforeQuoteLines::'+beforeQuoteLines);
            beforeQuoteLines[0].Product_SKU_Text__c = 'XXXXX';
            Test.startTest();
            insert beforeQuoteLines;
            Test.stopTest();
            List<SBQQ__QuoteLine__c> postQuoteLines = [SELECT Id, SBQQ__Product__c FROM SBQQ__QuoteLine__c];
            system.debug('@@postQuoteLines::'+postQuoteLines);
            System.assertEquals(products[0].Id, postQuoteLines[0].SBQQ__Product__c, 'Product2 not updated on QuoteLine');
            
        }         
        
    }
    
    @isTest
    static void updateQuoteLineWithMinRate () {
        List<SBQQ__Quote__c> quotes = [SELECT Id FROM SBQQ__Quote__c WHERE recordtype.developername = 'Rental_Quote'];
        
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        UserRole ur = [SELECT Id, Name FROM UserRole where Name = 'Sales - US'];
        User user = new User(Alias = 'standt', Email='standardperson@sunbeltrentals.com',
                             EmailEncodingKey='UTF-8', LastName='Testing',UserRoleId =ur.Id, LanguageLocaleKey='en_US',
                             LocaleSidKey='en_US', ProfileId = p.Id,
                             TimeZoneSidKey='America/Los_Angeles', UserName='standardperson@testorg.com');
        insert user;
        
        System.runAs(user){
            List<Schema.location> location = SBR_3_0_TestDataFactory.createLocations(1,false,'Branch');
            location[0].Analysis_Region_Key__c = '921';
            insert location;
            quotes[0].Branch__c = location[0].Id;
            quotes[0].Contingency_Quote__c = true;
            update quotes;
            List<SBQQ__QuoteLine__c> beforeQuoteLines = SBR_3_0_TestDataFactory.createQuoteLines(1, false, quotes[0].Id );
            system.debug('@@beforeQuoteLines::'+beforeQuoteLines);
            beforeQuoteLines[0].Monthly_Rate__c = 105;
            beforeQuoteLines[0].Product_SKU_Text__c = 'XXXXX';
            beforeQuoteLines[0].Contingency_Cost__c = 1050;
            Test.startTest();
            insert beforeQuoteLines;
            Test.stopTest();
            List<SBQQ__QuoteLine__c> postQuoteLines = [SELECT Id, SBQQ__Product__c,Min_Rate__c FROM SBQQ__QuoteLine__c];
            System.assertEquals(beforeQuoteLines[0].Monthly_Rate__c, postQuoteLines[0].Min_Rate__c, 'The minimum rate did not match the weekly rate for shoring');
        }
    }
    
    @isTest
    static void checkForStaleTotalsOnQuote() {
        List<SBQQ__Quote__c> quotes = [SELECT Id FROM SBQQ__Quote__c WHERE recordtype.developername = 'Rental_Quote'];
        
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        UserRole ur = [SELECT Id, Name FROM UserRole where Name = 'Sales - US'];
        User user = new User(Alias = 'standt', Email='standardperson@sunbeltrentals.com',
                             EmailEncodingKey='UTF-8', LastName='Testing',UserRoleId =ur.Id, LanguageLocaleKey='en_US',
                             LocaleSidKey='en_US', ProfileId = p.Id,
                             TimeZoneSidKey='America/Los_Angeles', UserName='standardperson@testorg.com');
        insert user;
        
        System.runAs(user){
            List<Schema.location> location = SBR_3_0_TestDataFactory.createLocations(1,false,'Branch');
            
            location[0].Analysis_Region_Key__c = '945';
            
            insert location;
            quotes[0].Branch__c = location[0].Id;
            quotes[0].Contingency_Quote__c = true;
            quotes[0].SBQQ__LastCalculatedOn__c = System.now().addDays(-1);
            update quotes;
            List<SBQQ__QuoteLine__c> beforeQuoteLines = SBR_3_0_TestDataFactory.createQuoteLines(1, false, quotes[0].Id );
            beforeQuoteLines[0].Product_SKU_Text__c = 'XXXXX';
            beforeQuoteLines[0].Contingency_Cost__c = 1050;
            insert beforeQuoteLines;
            Test.startTest();
            beforeQuoteLines[0].min_rate__c = 105;
            beforeQuoteLines[0].Contingency_Cost__c = 1050;
            update beforeQuoteLines;
            Test.stopTest();
            List<SBQQ__Quote__c> postQuote = [SELECT Id, stale_totals__c FROM SBQQ__Quote__c];
            System.assertEquals(false,postQuote[0].stale_totals__c, 'The totals were not stale');
        }
    }
    @isTest
    static void testUpdateTotalQuoteId () {
        List<SBQQ__Quote__c> quotes = [SELECT Id,Total_Quoted_Amount__c FROM SBQQ__Quote__c WHERE recordtype.developername = 'Sales_Quote'];
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        UserRole ur = [SELECT Id, Name FROM UserRole where Name = 'Sales - US'];
        User user = new User(Alias = 'standt', Email='standardperson@sunbeltrentals.com',
                             EmailEncodingKey='UTF-8', LastName='Testing',UserRoleId =ur.Id, LanguageLocaleKey='en_US',
                             LocaleSidKey='en_US', ProfileId = p.Id,
                             TimeZoneSidKey='America/Los_Angeles', UserName='standardperson@testorg.com');
        insert user;
        System.runAs(user){
            List<Schema.location> location = SBR_3_0_TestDataFactory.createLocations(1,false,'Branch');
            location[0].Analysis_Region_Key__c = '945';

            insert location;
            quotes[0].Branch__c = location[0].Id;
            quotes[0].Total_Quoted_Amount__c = 0;
            quotes[0].Contingency_Quote__c = true;
            update quotes;
            List<SBQQ__QuoteLine__c> beforeQuoteLines = SBR_3_0_TestDataFactory.createQuoteLines(1, false, quotes[0].Id );
            system.debug(beforeQuoteLines);
            beforeQuoteLines[0].Daily_Rate__c = 105;
            beforeQuoteLines[0].Product_SKU_Text__c = 'XXXXX';
            beforeQuoteLines[0].Total_Price__c = 1000;
            beforeQuoteLines[0].Contingency_Cost__c = 1050;
            insert beforeQuoteLines;
            Test.startTest();
            SBR_3_0_QuoteLineOperations.updateTotalQuoteId(beforeQuoteLines);
            Test.stopTest();
            List<SBQQ__QuoteLine__c> postQuoteLines = [SELECT Id, SBQQ__Product__c,Total_Price__c FROM SBQQ__QuoteLine__c];
            System.assert(quotes[0].Total_Quoted_Amount__c != null);     
        }
    }
    
    @isTest
    static void testUpdateQuoteLinesWithMinValues () {
        List<SBQQ__Quote__c> quotes = [SELECT Id FROM SBQQ__Quote__c WHERE recordtype.developername = 'Rental_Quote'];
        List<Schema.location> location = SBR_3_0_TestDataFactory.createLocations(1,false,'Branch');
        location[0].Analysis_Region_Key__c = '945';
        insert location;
        quotes[0].Branch__c = location[0].Id;
        quotes[0].Contingency_Quote__c = true;
        update quotes;
        List<SBQQ__QuoteLine__c> beforeQuoteLines = SBR_3_0_TestDataFactory.createQuoteLines(1, false, quotes[0].Id );
        system.debug(beforeQuoteLines);
        beforeQuoteLines[0].Daily_Rate__c = 105;
        beforeQuoteLines[0].Product_SKU_Text__c = 'XXXXX';
        Test.startTest();
        insert beforeQuoteLines;
        Test.stopTest();
        List<SBQQ__QuoteLine__c> postQuoteLines = [SELECT Id, SBQQ__Product__c,Min_Rate__c FROM SBQQ__QuoteLine__c];
        System.assertEquals(beforeQuoteLines[0].Daily_Rate__c, postQuoteLines[0].Min_Rate__c, 'The minimum rate did not match the daily rate for shoring');
    }
    @isTest
    static void testUpdateQuoteHeaderSpecificPricingFlag() {
        List<SBQQ__Quote__c> testQuotes = [SELECT Id FROM SBQQ__Quote__c WHERE recordtype.developername = 'Rental_Quote'];
        List<Schema.location> location = SBR_3_0_TestDataFactory.createLocations(1,false,'Branch');
        location[0].Analysis_Region_Key__c = '921';
        insert location;
        testQuotes[0].Branch__c = location[0].Id;
        testQuotes[0].Contingency_Quote__c = true;
        update testQuotes;
        List<SBQQ__QuoteLine__c> testLines = SBR_3_0_TestDataFactory.createQuoteLines(1, false, testQuotes[0].Id);
        testLines[0].Specific_Pricing_Type__c = 'Set Rates';
        testLines[0].Product_SKU_Text__c = 'XXXXX';
        
        Test.startTest();
        insert testLines;
        Test.stopTest();
        
        List<SBQQ__Quote__c> testQuoteResults = [SELECT Id, Specific_Pricing_Flag__c FROM SBQQ__Quote__c WHERE Id=: testQuotes[0].Id];
        System.assertEquals(testQuoteResults[0].Specific_Pricing_Flag__c, true, 'Quote specific pricing flag not updated.');
        
    }
    
    @isTest
    static void testRemoveQuoteHeaderSpecificPricingFlag() {
        List<SBQQ__Quote__c> testQuotes = [SELECT Id FROM SBQQ__Quote__c WHERE recordtype.developername = 'Rental_Quote'];
        List<Schema.location> location = SBR_3_0_TestDataFactory.createLocations(1,false,'Branch');
        location[0].Analysis_Region_Key__c = '921';
        insert location;
        testQuotes[0].Branch__c = location[0].Id;
        update testQuotes;
        List<SBQQ__QuoteLine__c> testLines = SBR_3_0_TestDataFactory.createQuoteLines(2, false, testQuotes[0].Id);
        testLines[0].Specific_Pricing_Type__c = 'Set Rates';
        testLines[0].Product_SKU_Text__c = 'XXXXX';
        testLines[1].Specific_Pricing_Type__c = 'Set Rates';
        testLines[1].Product_SKU_Text__c = 'XXXXX';
        insert testLines;
        
        Test.startTest();
        delete testLines[0];
        List<SBQQ__Quote__c> testQuoteResults = [SELECT Id, Specific_Pricing_Flag__c FROM SBQQ__Quote__c WHERE Id=: testQuotes[0].Id];
        System.assertEquals(testQuoteResults[0].Specific_Pricing_Flag__c, true, 'Quote specific pricing flag updated to false, should have stayed true.');
        delete testLines[1];
        List<SBQQ__Quote__c> testQuoteResultsTwo = [SELECT Id, Specific_Pricing_Flag__c FROM SBQQ__Quote__c WHERE Id=: testQuotes[0].Id];
        System.assertEquals(testQuoteResultsTwo[0].Specific_Pricing_Flag__c,true,'Quote specific pricing flag not updated');
        Test.stopTest();
        
        
    }
}