@isTest
private class SBR_3_0_QuoteLineOperations_Test {
    @TestSetup
    static void makeData(){
        Id RT_ID = Schema.getGlobalDescribe().get('Product2').getDescribe().getRecordTypeInfosByName().get('SKU').getRecordTypeId();
    
        List<Product2> products = SBR_3_0_TestDataFactory.createProducts(4, false);
        products[0].Product_SKU__c = 'XXXXX';
        products[0].Is_Kit__c = 'Yes';
        products[1].Product_SKU__c = '00XXXXX';
        products[1].recordtypeid = RT_ID;
        products[1].Is_Kit__c = 'Yes';
        products[2].Name = 'Not Fuel Plan';
        products[2].Product_Type__c = 'Cat-Class';
        products[2].Product_SKU__c = '234567';
        products[2].Category__c = '32134';
        products[2].Class__c = '2039';
        products[2].ToolFlex__c = 'N';
        products[2].isSerialized = true;
        products[2].Stock_class__c = '';
        products[2].Bulk_Item__c = false;
        products[2].Status__c = 'A';
        products[3].Name = 'Fuel Convenience Charge';
        products[3].Product_Type__c = 'Parts';
        products[3].Item_Number__c = '4321GH';
        products[3].Stock_Class__c = 'FVAIM';
        products[3].isSerialized = true;

        insert products;

        List<PricebookEntry> pbEntries = new List<PricebookEntry>();
        for (Product2 prod : products) {
        PricebookEntry stdPbe = new PricebookEntry();
        stdPbe.CurrencyIsoCode = 'USD';
        stdPbe.Pricebook2Id = Test.getStandardPricebookId();
        stdPbe.Product2Id = prod.Id;
        stdPbe.IsActive = true;
        stdPbe.UnitPrice = 20;
        pbEntries.add(stdPbe);
    }
        insert pbEntries;
        // Insert Product Feature
        SBQQ__ProductFeature__c featureObj = new SBQQ__ProductFeature__c(
                Name = 'Kit Component',
                Product_Feature_Load_Ext_ID__c = products[1].Product_SKU__c + '_' + 'Kit Component',
                SBQQ__ConfiguredSKU__c = products[1].Id,
                SBQQ__MinOptionCount__c = 1,
                SBQQ__Number__c = 1
        );
        insert featureObj;
        
        
        List<SBQQ__ProductOption__c> options = new List<SBQQ__ProductOption__c>();
        SBQQ__ProductOption__c option1 = new SBQQ__ProductOption__c();
        option1.SBQQ__ConfiguredSKU__c = products[0].Id;
        option1.SBQQ__OptionalSKU__c = products[1].Id;
        //option1.SBQQ__Feature__c = featureObj.Id;
        option1.SBQQ__Number__c = 1;
        option1.Company_Code__c = '01';
        option1.SBQQ__Quantity__c = 5;
        option1.SBQQ__Required__c=false;
        options.add(option1);
        
        SBQQ__ProductOption__c option2 = new SBQQ__ProductOption__c();
        option2.SBQQ__ConfiguredSKU__c = products[1].Id;
        option2.SBQQ__OptionalSKU__c = products[1].Id;
        option2.SBQQ__Feature__c = featureObj.Id;
        option2.SBQQ__Number__c = 2;
        option2.Company_Code__c = '01';
        option2.SBQQ__Quantity__c = 5;
        option2.SBQQ__Required__c=false;
        options.add(option2);
        
        insert options;
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
        

       SBQQ__Quote__c rentalQuote = new SBQQ__Quote__c(
			SBQQ__BillingCity__c = 'Test City',
			Contingency_Plan__c = true,
			Seasonal_Quote__c = true,
            Contingency_Quote__c = true,
			Shift_Pricing_Required__c = true,
			Standby_Pricing__c = true,
            Shift_Rate__c = true,
            Apply_Standby_Rates__c = true,
            SBQQ__Account__c = acct.Id,
            recordtypeId = Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosByDeveloperName().get(SBR_3_0_Constants.QUOTE_REC_TYPE_RENTAL_QUOTE).getRecordTypeId()
		);
		insert rentalQuote;
        SBQQ__Quote__c salesQuote = new SBQQ__Quote__c(
			SBQQ__BillingCity__c = 'Test City',
			Contingency_Plan__c = true,
			Seasonal_Quote__c = true,
            Contingency_Quote__c = true,
			Shift_Pricing_Required__c = true,
			Standby_Pricing__c = true,
            Shift_Rate__c = true,
            Apply_Standby_Rates__c = true,
            SBQQ__Account__c = acct.Id,
            recordtypeId = Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosByDeveloperName().get('Sales_Quote').getRecordTypeId()
		);
		insert salesQuote;

       }

    @isTest
    static void updateQuoteLineWithProductTest () {
        Test.startTest();
        List<SBQQ__Quote__c> quotes = [SELECT Id FROM SBQQ__Quote__c WHERE recordtype.developername = 'Rental_Quote'];
        List<SBQQ__QuoteLine__c> beforeQuoteLines = SBR_3_0_TestDataFactory.createQuoteLines(1, false, quotes[0].Id );
        beforeQuoteLines[0].Product_SKU_Text__c = 'XXXXX';
        beforeQuoteLines[0].Shift_Differential__c = 'S';
        List<Product2> products = [SELECT Id FROM Product2 WHERE Product_SKU__c = '00XXXXX'];
        insert beforeQuoteLines;
        Test.stopTest();
        List<SBQQ__QuoteLine__c> postQuoteLines = [SELECT Id, SBQQ__Product__c FROM SBQQ__QuoteLine__c];
        System.assertEquals(products[0].Id, postQuoteLines[0].SBQQ__Product__c, 'Product2 not updated on QuoteLine');

    }

    @isTest
    static void updateQuoteLineWithMinRate () {
        Test.startTest();
        List<SBQQ__Quote__c> quotes = [SELECT Id, Contingency_Quote__c,SBQQ__Account__r.Company_Code__c FROM SBQQ__Quote__c WHERE recordtype.developername = 'Rental_Quote'];
         List<Schema.location> location = SBR_3_0_TestDataFactory.createLocations(1,false,'Branch');
        location[0].Analysis_Region_Key__c = '921';
        insert location;
         quotes[0].Branch__c = location[0].Id;
        update quotes;
           List<SBQQ__QuoteLine__c> beforeQuoteLines = SBR_3_0_TestDataFactory.createQuoteLines(1, false, quotes[0].Id );
            beforeQuoteLines[0].Monthly_Rate__c = 105;
            beforeQuoteLines[0].Product_SKU_Text__c = 'XXXXX';
            insert beforeQuoteLines;
            
        Test.stopTest();
         
         List<SBQQ__QuoteLine__c> postQuoteLines = [SELECT Id, SBQQ__Product__c, Min_Rate__c FROM SBQQ__QuoteLine__c];
        System.assertEquals(beforeQuoteLines[0].Monthly_Rate__c, postQuoteLines[0].Min_Rate__c, 'The minimum rate did not match the monthly rate for scaffold');
    }


    @isTest
    static void updateKitrate () {
        Test.startTest();
        List<Account> acc=[Select id from Account];
        List<SBQQ__Quote__c> quotes = [SELECT Id, Contingency_Quote__c,SBQQ__Account__r.Company_Code__c FROM SBQQ__Quote__c WHERE recordtype.developername = 'Rental_Quote'];
        quotes[0].Company_Code__c ='01';
        quotes[0].SBQQ__Account__c = acc[0].id;
        update quotes;
        List<SBQQ__ProductOption__c> options =[Select Id,SBQQ__Quantity__c,SBQQ__OptionalSKU__c,SBQQ__OptionalSKU__r.RecordType.Name,Company_Code__c,
            SBQQ__Required__c from SBQQ__ProductOption__c];
        
        List<SBQQ__ProductFeature__c> features = [Select id,name,SBQQ__ConfiguredSKU__c,SBQQ__ConfiguredSKU__r.Product_SKU__c from SBQQ__ProductFeature__c];
         List<SBQQ__QuoteLine__c> beforeQuoteLines = SBR_3_0_TestDataFactory.createQuoteLines(1, false, quotes[0].Id );
            beforeQuoteLines[0].Product_SKU_Text__c = 'XXXXX';
            beforeQuoteLines[0].SBQQ__Quantity__c = 2;
            insert beforeQuoteLines;
            
        Test.stopTest();
        
        SBR_3_0_QuoteLineOperations.quoteLineToInsert(options,beforeQuoteLines[0]);
        
    }

    @isTest
    static void checkForStaleTotalsOnQuote() {
        Test.startTest();
        List<SBQQ__Quote__c> quotes = [SELECT Id FROM SBQQ__Quote__c WHERE recordtype.developername = 'Rental_Quote'];
        quotes[0].Contingency_Quote__c = true;
        update quotes;
        List<Schema.location> location = SBR_3_0_TestDataFactory.createLocations(1,false,'Branch');
        location[0].Analysis_Region_Key__c = '945';
        insert location;
        quotes[0].Branch__c = location[0].Id;
        quotes[0].SBQQ__LastCalculatedOn__c = System.now().addDays(-1);
        update quotes;
        List<SBQQ__QuoteLine__c> beforeQuoteLines = SBR_3_0_TestDataFactory.createQuoteLines(1, false, quotes[0].Id );
        beforeQuoteLines[0].Product_SKU_Text__c = 'XXXXX';
        beforeQuoteLines[0].Contingency_Cost__c =2000;
        insert beforeQuoteLines;

        beforeQuoteLines[0].min_rate__c = 105;
        beforeQuoteLines[0].Shift_Differential__c = 'S';
        beforeQuoteLines[0].Contingency_Cost__c =1000;
        update beforeQuoteLines;
        Test.stopTest();
        List<SBQQ__Quote__c> postQuote = [SELECT Id, stale_totals__c FROM SBQQ__Quote__c];
        System.assertEquals(false ,postQuote[0].stale_totals__c, 'The totals were stale');
    }
        @isTest
    static void testUpdateTotalQuoteId () {
        Test.startTest();
        List<SBQQ__Quote__c> quotes = [SELECT Id,Total_Quoted_Amount__c FROM SBQQ__Quote__c WHERE recordtype.developername = 'Sales_Quote'];
        List<Schema.location> location = SBR_3_0_TestDataFactory.createLocations(1,false,'Branch');
        location[0].Analysis_Region_Key__c = '945';
        insert location;
        quotes[0].Branch__c = location[0].Id;
        quotes[0].Total_Quoted_Amount__c = 0;
        update quotes;
        List<SBQQ__QuoteLine__c> beforeQuoteLines = SBR_3_0_TestDataFactory.createQuoteLines(1, false, quotes[0].Id );
       
        beforeQuoteLines[0].Daily_Rate__c = 105;
        beforeQuoteLines[0].Product_SKU_Text__c = 'XXXXX';
        beforeQuoteLines[0].Total_Price__c = 1000;
        insert beforeQuoteLines;
            SBR_3_0_QuoteLineOperations.updateTotalQuoteId(beforeQuoteLines);
        Test.stopTest();
        List<SBQQ__QuoteLine__c> postQuoteLines = [SELECT Id, SBQQ__Product__c,Total_Price__c FROM SBQQ__QuoteLine__c];
        System.assert(quotes[0].Total_Quoted_Amount__c != null);       
    }
    
    @isTest
    static void testUpdateQuoteLinesWithMinValues () {
        Test.startTest();
        List<SBQQ__Quote__c> quotes = [SELECT Id FROM SBQQ__Quote__c WHERE recordtype.developername = 'Rental_Quote'];
        List<Schema.location> location = SBR_3_0_TestDataFactory.createLocations(1,false,'Branch');
        location[0].Analysis_Region_Key__c = '945';
        insert location;
        quotes[0].Branch__c = location[0].Id;
        update quotes;
        List<SBQQ__QuoteLine__c> beforeQuoteLines = SBR_3_0_TestDataFactory.createQuoteLines(1, false, quotes[0].Id );
        
        beforeQuoteLines[0].Daily_Rate__c = 105;
        beforeQuoteLines[0].Product_SKU_Text__c = 'XXXXX';
        insert beforeQuoteLines;
        Test.stopTest();
        List<SBQQ__QuoteLine__c> postQuoteLines = [SELECT Id, SBQQ__Product__c,Min_Rate__c FROM SBQQ__QuoteLine__c];
        System.assertEquals(beforeQuoteLines[0].Daily_Rate__c, postQuoteLines[0].Min_Rate__c, 'The minimum rate did not match the daily rate for shoring');
    }
    @isTest
    static void testUpdateQuoteHeaderSpecificPricingFlag() {
        Test.startTest();
        List<SBQQ__Quote__c> testQuotes = [SELECT Id FROM SBQQ__Quote__c WHERE recordtype.developername = 'Rental_Quote'];
        List<Schema.location> location = SBR_3_0_TestDataFactory.createLocations(1,false,'Branch');
        location[0].Analysis_Region_Key__c = '921';
        insert location;
        testQuotes[0].Branch__c = location[0].Id;
        update testQuotes;
        List<SBQQ__QuoteLine__c> testLines = SBR_3_0_TestDataFactory.createQuoteLines(1, false, testQuotes[0].Id);
        testLines[0].Specific_Pricing_Type__c = 'Set Rates';
        testLines[0].Product_SKU_Text__c = 'XXXXX';
        insert testLines;
        Test.stopTest();
        
        List<SBQQ__Quote__c> testQuoteResults = [SELECT Id, Specific_Pricing_Flag__c FROM SBQQ__Quote__c WHERE Id=: testQuotes[0].Id];
        System.assertEquals(testQuoteResults[0].Specific_Pricing_Flag__c, true, 'Quote specific pricing flag not updated.');

    }

    @isTest
    static void testRemoveQuoteHeaderSpecificPricingFlag() {
        Test.startTest();
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
        delete testLines[0];
        List<SBQQ__Quote__c> testQuoteResults = [SELECT Id, Specific_Pricing_Flag__c FROM SBQQ__Quote__c WHERE Id=: testQuotes[0].Id];
        System.assertEquals(testQuoteResults[0].Specific_Pricing_Flag__c, true, 'Quote specific pricing flag updated to false, should have stayed true.');
        delete testLines[1];
        List<SBQQ__Quote__c> testQuoteResultsTwo = [SELECT Id, Specific_Pricing_Flag__c FROM SBQQ__Quote__c WHERE Id=: testQuotes[0].Id];
        System.assertNotEquals(testQuoteResultsTwo[0].Specific_Pricing_Flag__c, false, 'Quote specific pricing flag not updated to false');
        Test.stopTest();
        

    }
    
        @isTest
       static void testuncheckFuelPlanCheckBox() {
        Test.startTest();
        List<SBQQ__Quote__c> testQuotes = [SELECT Id FROM SBQQ__Quote__c WHERE recordtype.developername = 'Rental_Quote'];
        List<SBQQ__QuoteLine__c> testLines = SBR_3_0_TestDataFactory.createQuoteLines(2, false, testQuotes[0].Id);
        List<Product2> queriedProducts = [SELECT Id, Name, Product_Type__c, Product_SKU__c, Category__c, Class__c, ToolFlex__c, isSerialized,  Bulk_Item__c, Status__c, Item_Number__c, Stock_Class__c
        FROM Product2
        WHERE Name IN ('Fuel Convenience Charge', 'Not Fuel Plan')];
        testLines[0].Fuel_Plan__c = true;
        testLines[0].SBQQ__Product__c = queriedProducts[0].Id;
        testLines[1].SBQQ__Product__c = queriedProducts[1].Id;
        testLines[1].Kit_Number_this_Item_Belongs_to__c = '234567';
        insert testLines;
        delete testLines[1];
             List<SBQQ__QuoteLine__c> testQuoteResultsTwoFP = [SELECT Id,Fuel_Plan__c,SBQQ__Quote__c FROM SBQQ__QuoteLine__c];
             System.assertEquals(false, testQuoteResultsTwoFP[0].Fuel_Plan__c);
           Test.stopTest();
     
    }
    
    @isTest
    static void testUpdateUserAddedField() {
        Test.startTest();
        List<SBQQ__Quote__c> testQuotes = [SELECT Id FROM SBQQ__Quote__c WHERE recordtype.developername = 'Rental_Quote'];
        List<Schema.location> location = SBR_3_0_TestDataFactory.createLocations(1,false,'Branch');
        location[0].Analysis_Region_Key__c = '921';
        insert location;
        testQuotes[0].Branch__c = location[0].Id;
        update testQuotes;
        List<SBQQ__QuoteLine__c> testLines = SBR_3_0_TestDataFactory.createQuoteLines(1, false, testQuotes[0].Id);
        testLines[0].is_User_Added__c = false;
        testLines[0].Line_Item_Type__c = 'VR';
        testLines[0].Specific_Pricing_Type__c = 'Set Rates';
        testLines[0].Product_SKU_Text__c = 'XXXXX';
        insert testLines;
        List<SBQQ__QuoteLine__c> testQuoteLineResults = [SELECT Id, is_User_Added__c,Line_Item_Type__c FROM SBQQ__QuoteLine__c WHERE Id=: testLines[0].Id];
        System.assertEquals(testQuoteLineResults[0].is_User_Added__c, true, 'User Added is Set to True');
        
        Test.stopTest();
        

    }
}