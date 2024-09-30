/**
 * @description       : 
 * @author            : Shreenivas Adapur
 * @group             : 
 * @last modified on  : 02-09-2024
 * @last modified by  : Shreenivas Adapur
**/
@isTest
public with sharing class SBR_3_0_API_CreateQuotes_Test Implements HttpCalloutMock{
    static Boolean SUCCESSTEST = true;
    @TestSetup
    static void makeData(){
        Credential__c cred = SBR_3_0_TestDataFactory.createCredentials(1, false)[0];
        cred.Name = 'Mule_Token_Endpoint';
        cred.Key_Id__c = 'testKey123';
        cred.Secret__c = 'secret';
        insert cred;

        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        //create ers user clone
        String ersUserName = 'ersuser' + DateTime.now().getTime() + '@SBRtestorg.com';
        User ersu = new User(Alias = 'ers', Email='ersuser@testorg.com',
        EmailEncodingKey='UTF-8', LastName='erstest', LanguageLocaleKey='en_US',
        LocaleSidKey='en_US', ProfileId = p.Id,
        TimeZoneSidKey='America/Los_Angeles',
        UserName=ersUserName);
        ersu.RepID__c = '123444';
        insert ersu;
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
        // Create Prospect Account
        Account acct1 = new Account();
        acct1.RM_Account_Number__c = '5';
        acct1.Company_Code__c = '01';
        acct1.Name = 'Test Account Prospect';
        acct1.Record_Type_Text__c = 'Prospect';
        acct1.E_mail_Address__c = '123@asdf.com';
        acct1.Phone = '1234567890';
        acct1.BillingStreet = '123 Main Street';
        acct1.BillingCity = 'Toronto';
        acct1.BillingPostalCode = 'M9N7V5';
        acct1.BillingState = 'ON';
        acct1.BillingCountry = 'CA';
        acct1.Drivers_License__c = 'AKF';
        acct1.Driver_s_License_State__c = 'AL';
        insert acct1;
        // Create Contact
        Contact cont = new Contact();
        cont.FirstName = 'Test';
        cont.LastName = 'TEST';
        cont.AccountId = acct.Id;
        cont.MobilePhone = '5555555555';
        cont.Phone = '5555555555';
        cont.Email = 'SDFIONMW@TESTEMAILSALESFORCE.com';
        cont.MailingStreet = '12 Main Street';
        cont.MailingCity = 'Toronto';
        cont.MailingPostalCode = 'M7N7B3';
        cont.MailingState = 'ON';
        cont.MailingCountry = 'CA';
        insert cont;
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
        branchLocation.Time_Zone_Id__c = 'America/Chicago';
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
            Ordered_By__c = cont.Id,
            Jobsite__c = jobSite.Id,
            SBQQ__DeliveryMethod__c = 'Delivery',
            Start_Date__c = date.valueOf('2022-10-07 12:00:00'),
            End_Date__c = date.valueOf('2022-10-08 8:00:00'),
            Delivery_Date__c = date.valueOf('2022-10-07 12:00:00'),
            Opt_Out_RPP__c = false,
            Opt_Out_Fuel_Charge__c = false,
            Selling_Channel__c = 'SBRB2B',
            Pickup_Charge__c = 10,
            SBQQ__SalesRep__c = ersu.Id,
            Branch__c = branchLocation.Id,
            SBQQ__Status__c = 'Draft',
            OwnerId = ersu.Id
        );
        insert quote;
        // Create Price Book
        Pricebook2 priceBook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update priceBook;
        // Create Product
        List<Product2> products = new List<Product2>();
        for(Integer i = 0; i < 3; i++) {
            Product2 product = new Product2();
            product.Name = 'Test Product ' + i;
            if(i == 0) {
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
        // Create Quote Line
        List<SBQQ__QuoteLine__c> quoteLines = new List<SBQQ__QuoteLine__c>();
        for(Integer i = 0; i < 3; i++){
            SBQQ__QuoteLine__c quoteLine = new SBQQ__QuoteLine__c();
            quoteLine.SBQQ__Quote__c = quote.Id;
            quoteLine.SBQQ__Product__c = products[i].Id;
            quoteLine.Selling_Price__c = 1000;
            if(i == 0) {
                quoteLine.Hourly_Rate__c = 2.0;
                quoteLine.Min_Rate__c = 2.0;
                quoteLine.SBQQ__Quantity__c = 5;
                quoteLine.Free_Flag__c = false;
                quoteLine.Suggested_Daily_Rate__c = 2.0;
                quoteLine.Suggested_Weekly_Rate__c = 2.0;
                quoteLine.Suggested_Monthly_Rate__c = 2.0;
                quoteLine.Daily_Rate__c = 2.0;
                quoteLine.Weekly_Rate__c = 2.0;
                quoteLine.Monthly_Rate__c = 2.0;
                quoteLine.Rates_Overriden__c = false;
                quoteLine.Line_Comments__c = 'Comments';
                quoteLine.SBQQ__Number__c = 5;
            } else if (i == 1) {
                quoteLine.SBQQ__Quantity__c = 3;
                quoteLine.SBQQ__ListPrice__c = 20.0;
            } else {
                quoteLine.Misc_Charges_Type__c = 'TRANSPORTATION CHARGE';
                quoteLine.Misc_Charge__c = 20.3;
                quoteLine.Misc_Charges_Tax__c = 2.34;
                quoteLine.SBQQ__Taxable__c = false;
                quoteLine.Misc_Charges_Non_Taxable__c = false;
                quoteLine.Misc_Charges_Item_Tax_Rate__c = 2.0;
                quoteLine.SBQQ__Quantity__c = 5;
            }
            quoteLines.add(quoteLine);
        }
        insert quoteLines;
    }

    public HTTPResponse respond(HTTPRequest req) {
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type',SBR_3_0_Constants.APP_JSON);
        if(req.getEndpoint().endsWithIgnoreCase('token')){
            res.setBody('{"access_token":"test"}');
            res.setStatusCode(200);
        }else if(SUCCESSTEST) {
            res.setBody('{ "data": { "rmQuoteId": "000086613723","lines":[{"sfLineNumber":"1234","rmLineNumber":"1234","rmLineType":"Rental"}] } }');
            res.setStatusCode(200);
        }else {
            res.setBody('{ "error": { "message": "Invalid input parameters, parameters might contain special characters, SQL statements or script statements. Please check application logs for more information.", "errorKey": "BAD_REQUEST", "errorCode": "400-000" } }');
            res.setStatusCode(400);
        }
        return res;
    }

    @isTest 
    static void testCreateQuotesSuccess() {
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_CreateQuotes_Test());
        User testUser = [SELECT Id,RepID__c FROM User WHERE LastName = 'erstest'];
        System.runAs(testUser) {
            SBQQ__Quote__c quote = [SELECT Id, End_Date__c,Sales_Rep_ID__c FROM SBQQ__Quote__c];
            Test.startTest();
            SBR_3_0_API_CreateQuotes testCreate = new SBR_3_0_API_CreateQuotes(quote.Id, '01');
            Test.stopTest();
        }
        
        SBQQ__Quote__c newQuote = [SELECT Rentalman_Quote_Id__c FROM SBQQ__Quote__c];
        System.assertEquals('01-000086613723', newQuote.Rentalman_Quote_Id__c);
    }

    @isTest 
    static void testCreateQuotesFail() {
        SUCCESSTEST = false;
        User testUser = [SELECT Id,RepID__c FROM User WHERE LastName = 'erstest'];
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_CreateQuotes_Test());
        System.runAs(testUser) {
            SBQQ__Quote__c quote = [SELECT Id,SBQQ__Account__c,Start_Date__c,End_Date__c,Delivery_Date__c,
                Ordered_by__r.Phone,Ordered_by__r.MobilePhone,Ordered_by__r.Email,Opt_Out_Fuel_Charge__c,Jobsite__c,
                Jobsite__r.Branch__c, Jobsite__r.Branch__r.Time_Zone_Id__c,Jobsite__r.LocationId,
                Jobsite__r.Location.OMS_Sourcing_Enabled__c, Jobsite__r.Job_Number__c FROM SBQQ__Quote__c];
            AssociatedLocation jobSite = [Select Id, Branch__c, LocationId, Job_Number__c from AssociatedLocation Limit 1];
            Schema.Location branchLocation = [Select Id,Branch_Location_Number__c,Time_Zone_Id__c,OMS_Sourcing_Enabled__c 
                from Location Where Id =: jobSite.LocationId];
            
            Test.startTest();
            try {
                SBR_3_0_API_CreateQuotes testCreate = new SBR_3_0_API_CreateQuotes(quote.Id, '01');
            } catch (Exception e) {
                System.assertNotEquals(null, e.getMessage(), 'Exception should be thrown');
            }
            try {
                quote.SBQQ__Account__c = [Select id from account where name='Test Account Prospect'].Id;
                update quote;
                SBR_3_0_API_CreateQuotes testCreate = new SBR_3_0_API_CreateQuotes(quote.Id, '01');
            } catch (Exception e) {
                System.assertNotEquals(null, e.getMessage(), 'Exception should be thrown');
            }
            try {
                quote.SBQQ__Account__c = [Select id from account where name='Test Account'].Id;
                quote.Start_Date__c = null;
                update quote;
                SBR_3_0_API_CreateQuotes testCreate = new SBR_3_0_API_CreateQuotes(quote.Id, '01');
            } catch (Exception e) {
                System.assertNotEquals(null, e.getMessage(), 'Exception should be thrown');
            }
            try {
                quote.Start_Date__c = system.today().adddays(2);
                quote.End_Date__c = null;
                update quote;
                SBR_3_0_API_CreateQuotes testCreate = new SBR_3_0_API_CreateQuotes(quote.Id, '01');
            } catch (Exception e) {
                System.assertNotEquals(null, e.getMessage(), 'Exception should be thrown');
            }
            try {
                quote.End_Date__c = system.today().adddays(4);
                quote.Delivery_Date__c = null;
                update quote;
                SBR_3_0_API_CreateQuotes testCreate = new SBR_3_0_API_CreateQuotes(quote.Id, '01');
            } catch (Exception e) {
                System.assertNotEquals(null, e.getMessage(), 'Exception should be thrown');
            }
            try {
                Contact c = [Select id,email from contact limit 1];
                c.Email = null;
                update c;
                quote.Delivery_Date__c = system.today().adddays(3);
                update quote;
                
                SBR_3_0_API_CreateQuotes testCreate = new SBR_3_0_API_CreateQuotes(quote.Id, '01');
            } catch (Exception e) {
                System.assertNotEquals(null, e.getMessage(), 'Exception should be thrown');
            }
            try {
                Contact c = [Select id,email,phone,mobilephone from contact limit 1];
                c.Email = 'test1234@salesforce.com';
                c.Phone = null;
                c.MobilePhone = null;
                update c;
                quote.Delivery_Date__c = system.today().adddays(3);
                update quote;
                
                SBR_3_0_API_CreateQuotes testCreate = new SBR_3_0_API_CreateQuotes(quote.Id, '01');
            } catch (Exception e) {
                System.assertNotEquals(null, e.getMessage(), 'Exception should be thrown');
            }
            try {
                Contact c = [Select id,email,phone,mobilephone from contact limit 1];
                c.Email = 'test1234@salesforce.com';
                c.Phone = '3127778888';
                c.MobilePhone = '3127778888';
                update c;
                
                quote.Opt_Out_Fuel_Charge__c = null;
                update quote;
                
                SBR_3_0_API_CreateQuotes testCreate = new SBR_3_0_API_CreateQuotes(quote.Id, '01');
            } catch (Exception e) {
                System.assertNotEquals(null, e.getMessage(), 'Exception should be thrown');
            }
            try {
                quote.Opt_Out_Fuel_Charge__c = false;
                quote.JobSite__r = null;
                update quote;
                
                SBR_3_0_API_CreateQuotes testCreate = new SBR_3_0_API_CreateQuotes(quote.Id, '01');
            } catch (Exception e) {
                System.assertNotEquals(null, e.getMessage(), 'Exception should be thrown');
            }
            try {
                //jobSite.Branch__c = null;
                //update jobSite;
                quote.JobSite__c = jobSite.Id;
                update quote;
                
                SBR_3_0_API_CreateQuotes testCreate = new SBR_3_0_API_CreateQuotes(quote.Id, '01');
            } catch (Exception e) {
                System.assertNotEquals(null, e.getMessage(), 'Exception should be thrown');
            }
            try {
                branchLocation.Branch_Location_Number__c = null;
                update branchLocation;
                
                jobSite.Branch__c = branchLocation.Id;
                update jobSite;
                
                quote.JobSite__c = jobSite.Id;
                update quote;
                
                SBR_3_0_API_CreateQuotes testCreate = new SBR_3_0_API_CreateQuotes(quote.Id, '01');
            } catch (Exception e) {
                System.assertNotEquals(null, e.getMessage(), 'Exception should be thrown');
            }
            try {
                branchLocation.Branch_Location_Number__c = '720';
                branchLocation.Time_Zone_Id__c = null;
                update branchLocation;
                
                SBR_3_0_API_CreateQuotes testCreate = new SBR_3_0_API_CreateQuotes(quote.Id, '01');
            } catch (Exception e) {
                System.assertNotEquals(null, e.getMessage(), 'Exception should be thrown');
            }
            try {
                branchLocation.Time_Zone_Id__c = 'America/Chicago';
                update branchLocation;
                
                SBR_3_0_API_CreateQuotes testCreate = new SBR_3_0_API_CreateQuotes(quote.Id, '01');
            } catch (Exception e) {
                System.assertNotEquals(null, e.getMessage(), 'Exception should be thrown');
            }
            try {
                jobSite.LocationId = null;
                update jobSite;
                
                SBR_3_0_API_CreateQuotes testCreate = new SBR_3_0_API_CreateQuotes(quote.Id, '01');
            } catch (Exception e) {
                System.assertNotEquals(null, e.getMessage(), 'Exception should be thrown');
            }
            try {
                jobSite.LocationId = branchLocation.Id;
                jobSite.Job_Number__C = null;
                update jobSite;
                
                SBR_3_0_API_CreateQuotes testCreate = new SBR_3_0_API_CreateQuotes(quote.Id, '01');
            } catch (Exception e) {
                System.assertNotEquals(null, e.getMessage(), 'Exception should be thrown');
            }
            try {
                jobSite.Job_Number__C = '20221004A';
                update jobSite;
                
                SBR_3_0_API_CreateQuotes testCreate = new SBR_3_0_API_CreateQuotes(quote.Id, '01');
            } catch (Exception e) {
                System.assertNotEquals(null, e.getMessage(), 'Exception should be thrown');
            }
            Test.stopTest();
        }
        
    }

    @isTest 
    static void testCreateQuotesAccountTypeCreditError() {
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_CreateQuotes_Test());
        Account account = [SELECT Id, Record_Type_Text__c, RM_Account_Number__c, SF_Account_Number__c, Drivers_License__c, Driver_s_License_State__c FROM Account 
            Where Record_Type_Text__c = 'Credit'];
        // account.Record_Type_Text__c = 'No;
        update account;
        SBQQ__Quote__c quote = [SELECT id, Selling_Channel__c FROM SBQQ__Quote__c];
        Test.startTest();
        try {
            quote.Selling_Channel__c = null;
            update quote;
            SBR_3_0_API_CreateQuotes testCreate = new SBR_3_0_API_CreateQuotes(quote.Id, '01');
        } catch (Exception e) {
            System.assertEquals('Quote Selling Channel is required', e.getMessage(), 'Exception should be thrown');
        }
        /*try {
            account.RM_Account_Number__c = null;
            update account;
            quote.Selling_Channel__c = '12';
            update quote;
            SBR_3_0_API_CreateQuotes testCreate = new SBR_3_0_API_CreateQuotes(quote.Id, '01');
        } catch (Exception e) {
            System.assertEquals('quote.SBQQ__Account__r.RM_Account_Number__c is required', e.getMessage(), 'Exception should be thrown');
        }*/
        Test.stopTest();
    }

    @isTest 
    static void testCreateQuotesBranchError() {
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_CreateQuotes_Test());
        SBQQ__Quote__c quote = [SELECT id FROM SBQQ__Quote__c];
        Schema.Location location = [SELECT Branch_Location_Number__c FROM Location WHERE Name =: 'Test Branch Location'];
        Test.startTest();
        try { 
            location.Branch_Location_Number__c = null;
            update location;
            SBR_3_0_API_CreateQuotes testCreate = new SBR_3_0_API_CreateQuotes(quote.Id, '01');
        } catch (Exception e) {
            System.assertEquals('Quote Jobsite Branch is missing Branch Location Number. Please update Branch and Resubmit.', e.getMessage(), 'Exception should be thrown');
        }
        Test.stopTest();
    }

    @isTest
    static void testCreateQuotesMiscItemError() {
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_CreateQuotes_Test());
        SBQQ__Quote__c quote = [SELECT Id, SBQQ__Account__c, Jobsite__c, SBQQ__DeliveryMethod__c, Start_Date__c, End_Date__c, Opt_Out_RPP__c, Opt_Out_Fuel_Charge__c, Selling_Channel__c FROM SBQQ__Quote__c];
        SBQQ__QuoteLine__c miscItemLine = [SELECT Id, Misc_Charges_Type__c, Misc_Charge__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Product__r.Product_Type__c =: ''];
        Product2 miscItemProd = [SELECT Id, Item_Number__c, Stock_Class__c FROM Product2 WHERE Product_Type__c =: ''];
        Exception unexpectedException;
        Test.startTest();
        try {
            miscItemProd.Stock_Class__c = null;
            update miscItemProd;
            SBR_3_0_API_CreateQuotes testCreate = new SBR_3_0_API_CreateQuotes(quote.Id, '01');
        } catch (Exception e) {
            System.assertEquals('Quote Line product is missing Stock Class. Please update product and Resubmit.', e.getMessage(), 'Exception should be thrown');
        }
        try {
            miscItemProd.Item_Number__c = null;
            update miscItemProd;
            SBR_3_0_API_CreateQuotes testCreate = new SBR_3_0_API_CreateQuotes(quote.Id, '01');
        } catch (Exception e) {
            System.assertEquals('Quote Line product is missing Item Number. Please update product and Resubmit.', e.getMessage(), 'Exception should be thrown');
        }
        /*try {
            miscItemProd.Item_Number__c = '100';
            miscItemProd.Stock_Class__c = '100';
            update miscItemProd;
            miscItemLine.Misc_Charge__c = null;
            update miscItemLine;
            SBR_3_0_API_CreateQuotes testCreate = new SBR_3_0_API_CreateQuotes(quote.Id, '01');
        } catch (Exception e) {
            System.assertEquals('quoteLine.Misc_Charge__c is required for MiscItem', e.getMessage(), 'Exception should be thrown');
        }*/
        try {
            miscItemLine.Misc_Charges_Type__c = null;
            update miscItemLine;
            SBR_3_0_API_CreateQuotes testCreate = new SBR_3_0_API_CreateQuotes(quote.Id, '01');
        } catch (Exception e) {
            System.assertEquals('Quote Line is missing Misc Charges Type. Please update Quote Line and Resubmit.', e.getMessage(), 'Exception should be thrown');
        }
        Test.stopTest();
    }

    @isTest
    static void testCreateQuotesSaleItemError() {
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_CreateQuotes_Test());
        SBQQ__Quote__c quote = [SELECT Id, SBQQ__Account__c, Jobsite__c, SBQQ__DeliveryMethod__c, Start_Date__c, End_Date__c, Opt_Out_RPP__c, Opt_Out_Fuel_Charge__c, Selling_Channel__c FROM SBQQ__Quote__c];
        SBQQ__QuoteLine__c saleItemLine = [SELECT Id, SBQQ__Quantity__c, SBQQ__ListPrice__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Product__r.Product_Type__c =: 'Parts'];
        Product2 saleItemProd = [SELECT Id, Item_Number__c, Stock_Class__c FROM Product2 WHERE Product_Type__c =: 'Parts'];
        Exception unexpectedException;
        Test.startTest();
        try {
            saleItemProd.Stock_Class__c = null;
            update saleItemProd;
            SBR_3_0_API_CreateQuotes testCreate = new SBR_3_0_API_CreateQuotes(quote.Id, '01');
        } catch (Exception e) {
            System.assertEquals('Quote Line product is missing Stock Class. Please update product and Resubmit.', e.getMessage(), 'Exception should be thrown');
        }
        try {
            saleItemProd.Item_Number__c = null;
            update saleItemProd;
            SBR_3_0_API_CreateQuotes testCreate = new SBR_3_0_API_CreateQuotes(quote.Id, '01');
        } catch (Exception e) {
            System.assertEquals('Quote Line product is missing Item Number. Please update product and Resubmit.', e.getMessage(), 'Exception should be thrown');
        }
        Test.stopTest();
    }
    @isTest
    static void testCreateQuotesProductRatesError() {
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_CreateQuotes_Test());
        SBQQ__Quote__c quote = [SELECT Id, SBQQ__Account__c, Jobsite__c, SBQQ__DeliveryMethod__c, Start_Date__c, End_Date__c, Opt_Out_RPP__c, Opt_Out_Fuel_Charge__c, Selling_Channel__c FROM SBQQ__Quote__c];
        SBQQ__QuoteLine__c ProductItemLine = [SELECT Id, SBQQ__Number__c, Rates_Overriden__c, Monthly_Rate__c, Weekly_Rate__c, Daily_Rate__c, Suggested_Monthly_Rate__c, Suggested_Weekly_Rate__c, Suggested_Daily_Rate__c, Min_rate__c, Hourly_Rate__c, Free_Flag__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Product__r.Product_Type__c =: 'Cat-Class'];
        Product2 ProductItemProd = [SELECT Id, Category__c, Class__c, ToolFlex__c, Product_SKU__c FROM Product2 WHERE Product_Type__c =: 'Cat-Class'];
        Exception unexpectedException;
        Test.startTest();
        try {
            ProductItemLine.Monthly_Rate__c = null;
            update ProductItemLine;
            SBR_3_0_API_CreateQuotes testCreate = new SBR_3_0_API_CreateQuotes(quote.Id, '01');
        } catch (Exception e) {
            System.assertEquals('Quote Line is missing Monthly Rate. Please update Quote Line and Resubmit.', e.getMessage(), 'Exception should be thrown');
        }        
        Test.stopTest();
    }


    @isTest
    static void testCreateQuotesProductRatesErrorPt2(){
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_CreateQuotes_Test());
        SBQQ__Quote__c quote = [SELECT Id, SBQQ__Account__c, Jobsite__c, SBQQ__DeliveryMethod__c, Start_Date__c, End_Date__c, Opt_Out_RPP__c, Opt_Out_Fuel_Charge__c, Selling_Channel__c FROM SBQQ__Quote__c];
        SBQQ__QuoteLine__c ProductItemLine = [SELECT Id, SBQQ__Number__c, Rates_Overriden__c, Monthly_Rate__c, Weekly_Rate__c, Daily_Rate__c, Suggested_Monthly_Rate__c, Suggested_Weekly_Rate__c, Suggested_Daily_Rate__c, Min_rate__c, Hourly_Rate__c, Free_Flag__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Product__r.Product_Type__c =: 'Cat-Class'];
        Product2 ProductItemProd = [SELECT Id, Category__c, Class__c, ToolFlex__c, Product_SKU__c FROM Product2 WHERE Product_Type__c =: 'Cat-Class'];
        Exception unexpectedException;
        Test.startTest();
        try {
            ProductItemLine.Weekly_Rate__c = null;
            update ProductItemLine;
            SBR_3_0_API_CreateQuotes testCreate = new SBR_3_0_API_CreateQuotes(quote.Id, '01');
        } catch (Exception e) {
            System.assertEquals('Quote Line is missing Weekly Rate. Please update Quote Line and Resubmit.', e.getMessage(), 'Exception should be thrown');
        }
        Test.stopTest();
    }
    @isTest
    static void testCreateQuotesProductRatesErrorPt3(){
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_CreateQuotes_Test());
        SBQQ__Quote__c quote = [SELECT Id, SBQQ__Account__c, Jobsite__c, SBQQ__DeliveryMethod__c, Start_Date__c, End_Date__c, Opt_Out_RPP__c, Opt_Out_Fuel_Charge__c, Selling_Channel__c FROM SBQQ__Quote__c];
        SBQQ__QuoteLine__c ProductItemLine = [SELECT Id, SBQQ__Number__c, Rates_Overriden__c, Monthly_Rate__c, Weekly_Rate__c, Daily_Rate__c, Suggested_Monthly_Rate__c, Suggested_Weekly_Rate__c, Suggested_Daily_Rate__c, Min_rate__c, Hourly_Rate__c, Free_Flag__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Product__r.Product_Type__c =: 'Cat-Class'];
        Product2 ProductItemProd = [SELECT Id, Category__c, Class__c, ToolFlex__c, Product_SKU__c FROM Product2 WHERE Product_Type__c =: 'Cat-Class'];
        Exception unexpectedException;
        Test.startTest();
        try {
            ProductItemLine.Daily_Rate__c = null;
            update ProductItemLine;
            SBR_3_0_API_CreateQuotes testCreate = new SBR_3_0_API_CreateQuotes(quote.Id, '01');
        } catch (Exception e) {
            System.assertEquals('Quote Line is missing Daily Rate. Please update Quote Line and Resubmit.', e.getMessage(), 'Exception should be thrown');
        }
        Test.stopTest();
    }

    @isTest
    static void testCreateQuotesProductSuggestedRatesError() {
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_CreateQuotes_Test());
        SBQQ__Quote__c quote = [SELECT Id, SBQQ__Account__c, Jobsite__c, SBQQ__DeliveryMethod__c, Start_Date__c, End_Date__c, Opt_Out_RPP__c, Opt_Out_Fuel_Charge__c, Selling_Channel__c FROM SBQQ__Quote__c];
        SBQQ__QuoteLine__c ProductItemLine = [SELECT Id, SBQQ__Number__c, Rates_Overriden__c, Monthly_Rate__c, Weekly_Rate__c, Daily_Rate__c, Suggested_Monthly_Rate__c, Suggested_Weekly_Rate__c, Suggested_Daily_Rate__c, Min_rate__c, Hourly_Rate__c, Free_Flag__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Product__r.Product_Type__c =: 'Cat-Class'];
        //Product2 ProductItemProd = [SELECT Id, Category__c, Class__c, ToolFlex__c, Product_SKU__c FROM Product2 WHERE Product_Type__c =: 'Cat-Class'];
        Exception unexpectedException;
        Test.startTest();
        Product2 ProductItemProd = [SELECT Id, Category__c, Class__c, ToolFlex__c, Product_SKU__c FROM Product2 WHERE Product_Type__c =: 'Cat-Class'];
        try {
            ProductItemLine.Suggested_Monthly_Rate__c = null;
            update ProductItemLine;
            SBR_3_0_API_CreateQuotes testCreate = new SBR_3_0_API_CreateQuotes(quote.Id, '01');
        } catch (Exception e) {
            System.assertEquals('Quote Line is missing Suggested Monthly Rate. Please update Quote Line and Resubmit.', e.getMessage(), 'Exception should be thrown');
        }
        try {
            ProductItemLine.Suggested_Weekly_Rate__c = null;
            update ProductItemLine;
            SBR_3_0_API_CreateQuotes testCreate = new SBR_3_0_API_CreateQuotes(quote.Id, '01');
        } catch (Exception e) {
            System.assertEquals('Quote Line is missing Suggested Weekly Rate. Please update Quote Line and Resubmit.', e.getMessage(), 'Exception should be thrown');
        }
        // try {
        //     ProductItemLine.Suggested_Daily_Rate__c = null;
        //     update ProductItemLine;
        //     SBR_3_0_API_CreateQuotes testCreate = new SBR_3_0_API_CreateQuotes(quote.Id, '01');
        // } catch (Exception e) {
        //     System.assertEquals('quoteLine.Suggested_Daily_Rate__c is required for Product', e.getMessage(), 'Exception should be thrown');
        // }
        /*try {
            ProductItemLine.Min_Rate__c = null;
            update ProductItemLine;
            SBR_3_0_API_CreateQuotes testCreate = new SBR_3_0_API_CreateQuotes(quote.Id, '01');
        } catch (Exception e) {
            System.assertEquals('quoteLine.Min_Rate__c is required for Product', e.getMessage(), 'Exception should be thrown');
        }*/
        Test.stopTest();
    }
    @isTest
    static void testCreateQuotesProductError() {
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_CreateQuotes_Test());
        SBQQ__Quote__c quote = [SELECT Id, SBQQ__Account__c, Jobsite__c, SBQQ__DeliveryMethod__c, Start_Date__c, End_Date__c, 
            Opt_Out_RPP__c, Opt_Out_Fuel_Charge__c, Selling_Channel__c FROM SBQQ__Quote__c];
        SBQQ__QuoteLine__c ProductItemLine = [SELECT Id, SBQQ__Number__c, Rates_Overriden__c, Monthly_Rate__c, Weekly_Rate__c, 
            Daily_Rate__c, Suggested_Monthly_Rate__c, Suggested_Weekly_Rate__c, Suggested_Daily_Rate__c, Min_rate__c, Hourly_Rate__c, 
            Free_Flag__c,SBQQ__Quantity__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Product__r.Product_Type__c =: 'Cat-Class'];
        Product2 ProductItemProd = [SELECT Id, Category__c, Class__c, ToolFlex__c, Product_SKU__c FROM Product2 
            WHERE Product_Type__c =: 'Cat-Class'];
        Exception unexpectedException;
        Test.startTest();
        try {
            ProductItemProd.ToolFlex__c = null;
            update ProductItemProd;
            SBR_3_0_API_CreateQuotes testCreate = new SBR_3_0_API_CreateQuotes(quote.Id, '01');
        } catch (Exception e) {
            System.assertEquals('Quote Line product is missing ToolFlex. Please update product and Resubmit.', e.getMessage(), 'Exception should be thrown');
        }
        try {
            ProductItemProd.Class__c = null;
            update ProductItemProd;
            SBR_3_0_API_CreateQuotes testCreate = new SBR_3_0_API_CreateQuotes(quote.Id, '01');
        } catch (Exception e) {
            System.assertEquals('Quote Line product is missing Class. Please update product and Resubmit.', e.getMessage(), 'Exception should be thrown');
        }
        try {
            ProductItemProd.Category__c = null;
            update ProductItemProd;
            SBR_3_0_API_CreateQuotes testCreate = new SBR_3_0_API_CreateQuotes(quote.Id, '01');
        } catch (Exception e) {
            System.assertEquals('Quote Line product is missing Category .  Please update product and Resubmit.', e.getMessage(), 'Exception should be thrown');
        }
        try {
            ProductItemProd.Product_SKU__c = null;
            update ProductItemProd;
            SBR_3_0_API_CreateQuotes testCreate = new SBR_3_0_API_CreateQuotes(quote.Id, '01');
        } catch (Exception e) {
            System.assertEquals('Quote Line product is missing Product SKU.  Please update product and Resubmit.', e.getMessage(), 'Exception should be thrown');
        }
        Test.stopTest();
    }
}