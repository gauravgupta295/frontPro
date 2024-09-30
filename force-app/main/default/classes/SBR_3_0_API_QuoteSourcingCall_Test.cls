/*********************************************************************************************************************
* Apex Class: SBR_3_0_API_QuoteSourcingCall_Test
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Test class for SBR_3_0_API_QuoteSourcingCall
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
1.0         Victor Mitra         2023-01-02             Initial version    
*********************************************************************************************************************/
@isTest(seeAllData=false)
public class SBR_3_0_API_QuoteSourcingCall_Test {
    static Boolean SUCCESSTEST = true;
    @TestSetup
    static void makeData() {
        Credential__c cred = SBR_3_0_TestDataFactory.createCredentials(1, false)[0];
        cred.Name = 'Mule_Token_Endpoint';
        cred.Key_Id__c = 'testKey123';
        cred.Secret__c = 'secret';
        insert cred;
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
        // Account acct = SBR_3_0_TestDataFactory.createAccounts(1, true, null)[0];
        // Create Contact
        Contact contact = SBR_3_0_TestDataFactory.createContacts(1, acct.Id, true)[0];
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
        branchLocation.Job_Number__c = '332112';
        branchLocation.RecordTypeId = SBR_3_0_Constants.LOCATION_BRANCH_RT_ID;
        branchLocation.Company_Code__c = 'X';
        branchLocation.Time_Zone_Name__c = 'America/Chicago';
        branchLocation.Time_Zone__c = 3;
        branchLocation.OMS_Sourcing_Enabled__c = true;
        
        insert branchLocation;
        // Create Job Site
        AssociatedLocation jobSite = new AssociatedLocation(Name__c = 'Test Job Site', Latitude_Longitude__Latitude__s = 48.51, Latitude_Longitude__Longitude__s = -117.62, ParentRecordId = acct.Id, LocationId = jobLocation.Id, Branch__c = branchLocation.Id, Job_Number__c = '20221004A', Time_Zone_Id__c = 'America/New_York');
        insert jobSite;
        // Create Price Book
        Pricebook2 priceBook = new Pricebook2(Id = Test.getStandardPricebookId(), IsActive = true);
        update priceBook;
        // Create quote
        SBQQ__Quote__c quote = new SBQQ__Quote__c(
            Quote_Name__c = 'Test Quote',
            SBQQ__Account__c = acct.Id,
            Branch__c = branchLocation.Id,
            Jobsite__c = jobSite.Id,
            SBQQ__DeliveryMethod__c = 'Delivery',
            Delivery_Charge__c = 10,
            SBQQ__Status__c = 'Draft',
            SBQQ__PriceBook__c = priceBook.Id,
            Start_Date__c = date.valueOf('2022-12-12 12:00:00'),
            End_Date__c = date.valueOf('2023-10-09 8:00:00'),
            Delivery_Date__c = date.valueOf('2022-10-08 12:00:00'),
            Opt_Out_RPP__c = false,
            Ordered_by__c = contact.Id,
            // Order_Initiating_Channel__c = 'SLSFRC',
            Opt_Out_Fuel_Charge__c = false,
            Selling_Channel__c = 'SBRB2B'            
        );
        insert quote;
        
        SBQQ__Quote__c quote2 = new SBQQ__Quote__c(
            Quote_Name__c = 'Test Quote2',
            SBQQ__Account__c = acct.Id,
            Branch__c = branchLocation.Id,
            Jobsite__c = jobSite.Id,
            SBQQ__DeliveryMethod__c = '',
            Delivery_Charge__c = 10,
            SBQQ__Status__c = 'Draft',
            SBQQ__PriceBook__c = priceBook.Id,
            Start_Date__c = date.valueOf('2022-12-12 12:00:00'),
            End_Date__c = date.valueOf('2023-10-09 8:00:00'),
            Delivery_Date__c = date.valueOf('2022-10-08 12:00:00'),
            Opt_Out_RPP__c = false,
            Ordered_by__c = contact.Id,
            // Order_Initiating_Channel__c = 'SLSFRC',
            Opt_Out_Fuel_Charge__c = false,
            Selling_Channel__c = 'SBRB2B'            
        );
        insert quote2;
        
        SBQQ__Quote__c quote3 = new SBQQ__Quote__c(
            Quote_Name__c = 'Test Quote3',
            SBQQ__Account__c = acct.Id,
            Branch__c = branchLocation.Id,
            Jobsite__c = jobSite.Id,
            SBQQ__DeliveryMethod__c = '',
            Delivery_Charge__c = 10,
            SBQQ__Status__c = 'Draft',
            SBQQ__PriceBook__c = priceBook.Id,
            Start_Date__c = date.valueOf('2022-12-12 12:00:00'),
            End_Date__c = date.valueOf('2023-10-09 8:00:00'),
            Delivery_Date__c = date.valueOf('2022-10-08 12:00:00'),
            Opt_Out_RPP__c = false,
            Ordered_by__c = contact.Id,
            // Order_Initiating_Channel__c = 'SLSFRC',
            Opt_Out_Fuel_Charge__c = false,
            Selling_Channel__c = ''            
        );
        insert quote3;
        
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
            } else if (i == 1) {
                product.Product_Type__c = 'Parts';
                product.Item_Number__c = '1234GH';
                product.Stock_Class__c = 'AIMFV';
            } else {
                product.Product_Type__c = '';
                product.Item_Number__c = '1285JC';
                product.Stock_Class__c = 'UJEKL';
            }
            products.add(product);
        }
        insert products;
        // Create Price Book Entry
        List<PricebookEntry> listPbe = new List<PricebookEntry>();
        Map<Id, Id> mapPBE = new Map<Id, Id>();
        for (PricebookEntry pbEntry : [SELECT Id, Product2Id FROM PricebookEntry WHERE Pricebook2Id = :Test.getStandardPricebookId()]) {
            if (pbEntry.Product2Id == products[0].Id) {
                mapPBE.put(pbEntry.Product2Id, pbEntry.Id);
            } else if (pbEntry.Product2Id == products[1].Id) {
                mapPBE.put(pbEntry.Product2Id, pbEntry.Id);
            } else if (pbEntry.Product2Id == products[2].Id) {
                mapPBE.put(pbEntry.Product2Id, pbEntry.Id);
            }
        }
        // Create Order item
        List<SBQQ__QuoteLine__c> quoteItems = new List<SBQQ__QuoteLine__c>();
        for (Integer i = 0; i < 3; i++) {
            SBQQ__QuoteLine__c quoteItem = new SBQQ__QuoteLine__c();
            quoteItem.SBQQ__Quote__c = quote.Id;
            quoteItem.SBQQ__Product__c = products[i].Id;
            quoteItem.SBQQ__UnitCost__c = 100;
            quoteItem.RM_Quote_Line_Number__c = i;
            quoteItem.Min_Rate__c = 2;
            quoteItem.Daily_Rate__c = 2.0;
            quoteItem.Weekly_Rate__c = 2.0;
            quoteItem.Monthly_Rate__c = 2.0;
            quoteItem.Selling_Price__c = 2.0;
            
            quoteItem.SBQQ__PricebookEntryId__c = mapPBE.get(products[i].Id);
            if (i == 0) {
                quoteItem.Hourly_Rate__c = 2.0;
                quoteItem.Min_Rate__c = 2.0;
                quoteItem.SBQQ__Quantity__c = 5;
                quoteItem.Free_Flag__c = false;
                quoteItem.Suggested_Daily_Rate__c = 2.0;
                quoteItem.Suggested_Weekly_Rate__c = 2.0;
                quoteItem.Suggested_Monthly_Rate__c = 2.0;
                quoteItem.Daily_Rate__c = 2.0;
                quoteItem.Weekly_Rate__c = 2.0;
                quoteItem.Monthly_Rate__c = 2.0;
                quoteItem.Rates_Overriden__c = false;
                //  orderItem.Line_Comments__c = 'Comments';
                // orderItem.SBQQ__Number__c = 5;
            } else if (i == 1) {
                quoteItem.SBQQ__Quantity__c = 3;
                //orderItem.ListPrice = pbEntry2.ListPrice;
            } else {
                quoteItem.SBQQ__Quantity__c = 3;
                quoteItem.Misc_Charges_Type__c = 'TRANSPORTATION CHARGE';
                quoteItem.Misc_Charge__c = 20.3;
                quoteItem.Misc_Charges_Tax__c = 2.34;
                quoteItem.SBQQ__Taxable__c = false;
                quoteItem.Misc_Charges_Non_Taxable__c = false;
                quoteItem.Misc_Charges_Item_Tax_Rate__c = 2.0;
            }
            quoteItems.add(quoteItem);
        }
        insert quoteItems;
    }
    @isTest
    static void testCreateQuoteNoLineItemMethod() {
        try {
            SBQQ__Quote__c quote = [SELECT Id, End_Date__c, OMS_Sourcing_Enabled__c,Quote_Name__c,SBQQ__DeliveryMethod__c,Sourcing_Branch__c FROM SBQQ__Quote__c where  Quote_Name__c = 'Test Quote2' ];
            System.debug('@@@quote 224 test class' + quote);
            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_QuoteSourcingCallCalloutMock());
            SBR_3_0_API_QuoteSourcingCall.callSource(quote.Id);
            Test.stopTest();
        }
        catch (Exception e) {
            System.assertEquals('You must have at least one Line Item added on the record to retrieve Totals.', e.getMessage());
        }        
    }
    
    @isTest
    static void testCreateQuoteDeliveryMethodNull() {
        try {
            SBQQ__Quote__c quote = [SELECT Id, End_Date__c, SBQQ__DeliveryMethod__c,OMS_Sourcing_Enabled__c, Quote_Name__c, Sourcing_Branch__c FROM SBQQ__Quote__c where  Quote_Name__c = 'Test Quote'];
            quote.SBQQ__DeliveryMethod__c='';
            update quote;
            System.debug('@@@quote 224 test class' + quote);
            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_QuoteSourcingCallCalloutMock());
            SBR_3_0_API_QuoteSourcingCall.callSource(quote.Id);
            Test.stopTest();
        }
        catch (Exception e) {
            System.assertEquals('Delivery Method is required', e.getMessage());
        }
    }
    
    @isTest
    static void testSellingChannelMethodNull() {
        try {
            SBQQ__Quote__c quote = [SELECT Id, End_Date__c,Selling_Channel__c, SBQQ__DeliveryMethod__c,OMS_Sourcing_Enabled__c, Quote_Name__c, Sourcing_Branch__c FROM SBQQ__Quote__c where  Quote_Name__c = 'Test Quote'];
            quote.Selling_Channel__c='';
            update quote;
            System.debug('@@@quote 224 test class' + quote);
            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_QuoteSourcingCallCalloutMock());
            SBR_3_0_API_QuoteSourcingCall.callSource(quote.Id);
            Test.stopTest();
        }
        catch (Exception e) {
            System.assertEquals('quote.Selling_Channel__c is required', e.getMessage());
        }
    }
    
    @isTest
    static void testJobSiteMethodNull() {
        try {
            SBQQ__Quote__c quote = [SELECT Id, Jobsite__c,End_Date__c,Selling_Channel__c, SBQQ__DeliveryMethod__c,OMS_Sourcing_Enabled__c, Quote_Name__c, Sourcing_Branch__c FROM SBQQ__Quote__c where  Quote_Name__c = 'Test Quote'];
            Set<Id> jobsiteIds = new Set<Id>();
            List<AssociatedLocation> jobsitesToDelete = [SELECT Id FROM 	AssociatedLocation WHERE Id=:quote.Jobsite__c];
            delete jobsitesToDelete;
            
            System.debug('@@@quote 224 test class' + quote);
            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_QuoteSourcingCallCalloutMock());
            SBR_3_0_API_QuoteSourcingCall.callSource(quote.Id);
            Test.stopTest();
        }
        catch (Exception e) {
            System.assertEquals('Jobsite is required', e.getMessage());
        }
    }    
    
    @isTest
    static void testCreateQuoteSuccess() {
        SBQQ__Quote__c quote = [SELECT Id, End_Date__c, OMS_Sourcing_Enabled__c, Quote_Name__c, Sourcing_Branch__c FROM SBQQ__Quote__c where  Quote_Name__c = 'Test Quote'];
        System.debug('@@@quote 224 test class' + quote);
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_QuoteSourcingCallCalloutMock());
        SBR_3_0_API_QuoteSourcingCall.callSource(quote.Id);
        Test.stopTest();
        
        SBQQ__Quote__c newQuote = [SELECT Id, Sourcing_Branch__c FROM SBQQ__Quote__c where  Quote_Name__c = 'Test Quote'];
        System.debug('newQuote 196'+newQuote);
        Schema.Location loc = [
            SELECT Id, Branch_Location_Number__c
            FROM Location
            WHERE Branch_Location_Number__c = '720' AND Recordtype.Name = :SBR_3_0_Constants.LOCATION_REC_TYPE_BRANCH
            LIMIT 1
        ];
        System.assertEquals(loc.Branch_Location_Number__c, '720');
    }
    
    @isTest
    static void testCreateQuotesFail() {
        SUCCESSTEST = false;
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_QuoteSourcingCallCalloutMock());
        SBQQ__Quote__c quote = [SELECT Id,Quote_Name__c FROM SBQQ__Quote__c where  Quote_Name__c = 'Test Quote'];
        Test.startTest();
        try {
            SBR_3_0_API_QuoteSourcingCall.callSource(quote.Id);
        } catch (Exception e) {
            System.assertNotEquals(null, e, 'Exception should be thrown');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testCallSourceFrontline() {
        SBQQ__Quote__c quote = [SELECT Quote_Name__c FROM SBQQ__Quote__c WHERE Quote_Name__c = 'Test Quote'];
        Test.startTest();
        quote.Start_Date__c = Datetime.now().addDays(10);
        quote.End_Date__c = Datetime.now().addDays(20);
        quote.Closed_Description__c = 'Test Closed Description';
        SBR_3_0_API_QuoteSourcingCall.callSourceFrontline(quote, quote.Id);
        Test.stopTest();
        SBQQ__Quote__c updatedQuote = [SELECT Closed_Description__c FROM SBQQ__Quote__c WHERE Quote_Name__c = 'Test Quote'];
        System.Assert.areEqual(
      		updatedQuote.Closed_Description__c,
      		'Test Closed Description',
      		'Quote updated successfully'
    	);
    }
}