@isTest
public with sharing class SBR_3_0_API_Rates_Test Implements HttpCalloutMock{

    @TestSetup
    static void makeData(){
        Credential__c cred = SBR_3_0_TestDataFactory.createCredentials(1, false)[0];
        cred.Name = 'Mule_Token_Endpoint';
        cred.Key_Id__c = 'testKey123';
        cred.Secret__c = 'secret';
        insert cred;

        // Prepare Data
        // Activate Price Book
        Pricebook2 priceBook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update priceBook;
        // Create Account
        Account acct = new Account();
        acct.RM_Account_Number__c = '4';
        acct.Company_Code__c = '01';
        acct.Name = 'Test Account';
        acct.BillingStreet = '123 Main Street';
        acct.BillingCity = 'Toronto';
        acct.BillingPostalCode = 'M9N7V5';
        acct.BillingState = 'ON';
        acct.BillingCountry = 'CA';
        acct.Phone = '9232343434';
        insert acct;
        // Create Location
        Schema.Location jobLocation = new Schema.Location();
        jobLocation.Name = 'Test Job Location';
        jobLocation.Street_Address__c = '12 Main Street';
        jobLocation.City__c = 'Toronto';
        jobLocation.Zip_Code__c = 'M7N7B3';
        jobLocation.State__c = 'ON';
        jobLocation.Country__c = 'CA';
        jobLocation.RecordTypeId = SBR_3_0_Constants.LOCATION_JOB_RT_ID;
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
        branchLocation.Company_Code__c = '01';
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
        SVMXA360__SM_TA_Template__c smTaTemplate = new SVMXA360__SM_TA_Template__c();
        smTaTemplate.Name = 'SBR 3.0 Maintenance Template';
        smTaTemplate.SVMXA360__DeveloperName__c = 'SBR_3_0_Maintenance_Template';
        insert smTaTemplate;
        
        // Create Product
        Product2 prod = new Product2(Name = 'Test Product 1', Product_Title_Internal__c = 'Test Product 1', Product_SKU__c = '1234567', Product_Type__c = 'Cat-Class');
        Product2 prod2 = new Product2(Name = 'Test Product 2', Product_Title_Internal__c = 'Test Product 2', Product_SKU__c = '01-PIPSA-817633', Product_Type__c = 'Merchandise');
        insert prod;
        insert prod2;
        
        
        
        // Create Quote
        SBQQ__Quote__c quote = new SBQQ__Quote__c(
            Quote_Name__c = 'Test Quote',
            SBQQ__Account__c = acct.Id,
            Jobsite__c = jobSite.Id
        );
        insert quote;
        // Create Quote Line Item
        List<SBQQ__QuoteLine__c> lineItems = new List<SBQQ__QuoteLine__c>();
        lineItems.add(new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = quote.Id,
            SBQQ__Product__c = prod.Id,
            Start_Date__c = Datetime.now().addDays(2)
        ));
        lineItems.add(new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = quote.Id,
            SBQQ__Product__c = prod2.Id,
            Start_Date__c = Datetime.now().addDays(2)
        ));
        
        insert lineItems;
    }

    public HTTPResponse respond(HTTPRequest req) {
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type',SBR_3_0_Constants.APP_JSON);
        if(req.getEndpoint().endsWithIgnoreCase('token')){
            // Access Token Response
            res.setBody('{"access_token":"test"}');
        }else if(req.getEndpoint().endsWithIgnoreCase('rates')){
            // Rates Response here
            res.setBody('{ "data": { "errorCode": "0000", "errorDesc": "Success", "company": "01", "customer": "4", "jobsite": "CO MEDIMMUNE BOULDER", "location": "0720", "items": [ { "catId": "123", "classId": "4567", "productId": "1234567", "rateFlag": "B", "rateFlagDescription": "Book Rates", "notToExceed": "", "notToExceedDescription": "No override needed for any change.", "rppPercentage": ".000", "needPassword": "FALSE", "showAllRates": "FALSE", "suggestMinimalHours": ".00", "isConsumerCatClass": "FALSE", "isSerialized": "FALSE", "customerDiscountPercentageDaily": ".00", "customerDiscountPercentageWeekly": ".00", "customerDiscountPercentageMonthly": ".00", "customerMonthly": null, "rates": { "suggestedRates": { "minimum": "10", "daily": "10", "weekly": "70", "monthly": "300" }, "bookRates": { "minimum": ".00", "daily": ".00", "weekly": ".00", "monthly": ".00" } } } ] } }');
        } else if(req.getEndpoint().endsWithIgnoreCase('consumables')){
            // Consumables Response here
            res.setBody('{"data":{"suggestedItems":[{"catId":"123","classId":"4567","rentables":[],"consumables":[{"inventoryClass":"206","invClassDescription":"PPE, RESPIRATORY","specGroups":[{"specNumber":"206-0002","title":"Disposable Respirator","specDescription":"Disposable Respirator","minPrice":6,"maxPrice":6,"products":[{"productNumber":"01-PIPSA-817633","stockClass":"PIPSA","oemStockNumber":"10102481","productDescription":"N95 HARMFUL DUST RESPIRATOR 2 PACK","priceSchedule":"","sequence":"10","forceItem":"N","minQuantity":0,"sellingPrice":10,"availQuantity":25,"binNumber1":"SC3","binNumber2":"","binNumber3":"","rentalCat":"0","rentalClass":"0","isSerialized":false}]}]}]}]}}');
        }
        res.setStatusCode(200);
        return res;
    }
    @isTest static void testGetRates() {
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_Rates_Test());
        Test.startTest();
        String ratesRequestJson = '{ "pc": 720, "accountNumber": 4, "jobsiteName": "CO MEDIMMUNE BOULDER", "products": [ { "productId": "1234567" } ] }';
        System.assert(String.isNotEmpty(SBR_3_0_API_Rates.getRates(ratesRequestJson, '1')), 'No Rates Data Received From Rates API');
        Test.stopTest();
    }

    @isTest static void testRefreshQuoteRates(){
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_Rates_Test());
        SBQQ__Quote__c testQuote = [SELECT ID FROM SBQQ__Quote__c WHERE Quote_Name__c = 'Test Quote' LIMIT 1];
        Test.startTest();
        SBR_3_0_API_Rates.refreshQuoteRates(testQuote.Id);
        Test.stopTest();
        List<SBQQ__QuoteLine__c> lineItemsUpdated = [SELECT ID, Min_Rate__c, SBQQ__Product__r.Name, Selling_Price__c, Suggested_Minimum_Rate__c, Daily_Rate__c, Suggested_Daily_Rate__c, 
        Weekly_Rate__c, Suggested_Weekly_Rate__c, Monthly_Rate__c, Suggested_Monthly_Rate__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c =: testQuote.Id];

        for(SBQQ__QuoteLine__c lineItemUpdated: lineItemsUpdated){
            if(lineItemUpdated.SBQQ__Product__r.Name == 'Test Product 1'){
                System.assert(lineItemUpdated.Min_Rate__c == 10.0, 'Min_Rate__c is not 10.0 but ' + lineItemUpdated.Min_Rate__c);
                System.assert(lineItemUpdated.Suggested_Minimum_Rate__c == 10.0, 'Suggested_Minimum_Rate__c is not 10.0 but ' + lineItemUpdated.Suggested_Minimum_Rate__c);
                System.assert(lineItemUpdated.Daily_Rate__c == 10.0, 'Daily_Rate__c is not 10.0 but ' + lineItemUpdated.Daily_Rate__c);
                System.assert(lineItemUpdated.Suggested_Daily_Rate__c == 10.0, 'Suggested_Daily_Rate__c is not 10.0 but ' + lineItemUpdated.Suggested_Daily_Rate__c);
                System.assert(lineItemUpdated.Weekly_Rate__c == 70.0, 'Weekly_Rate__c is not 70.0 but ' + lineItemUpdated.Weekly_Rate__c);
                System.assert(lineItemUpdated.Suggested_Weekly_Rate__c == 70.0, 'Suggested_Weekly_Rate__c is not 70.0 but ' + lineItemUpdated.Suggested_Weekly_Rate__c);
                System.assert(lineItemUpdated.Monthly_Rate__c == 300.0, 'Monthly_Rate__c is not 300.0 but ' + lineItemUpdated.Monthly_Rate__c);
                System.assert(lineItemUpdated.Suggested_Monthly_Rate__c == 300.0, 'Suggested_Monthly_Rate__c is not 300.0 but ' + lineItemUpdated.Suggested_Monthly_Rate__c);
            } 
            /**else if (lineItemUpdated.SBQQ__Product__r.Name == 'Test Product 2') {
                System.assert(lineItemUpdated.Selling_Price__c == 10.0, 'Selling_Price__c is not 10.0 but ' + lineItemUpdated.Selling_Price__c);
            }**/
        }
    }
}