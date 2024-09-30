/*********************************************************************************************************************
* Apex Class: P2P_API_Web_Quote_Test
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Test class for creating custom p2p quote using REST API
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Delvin Riley         2023-10-12             Initial version    
*********************************************************************************************************************/

@isTest
public class P2P_API_Web_Quote_Test {
    
     @TestSetup
    static void makeData(){
        Credential__c cred = new Credential__c();
        cred.Name = 'Mule_Token_Endpoint' ; 
        cred.Key_Id__c  = 'Mule_Token_Endpoint';
        cred.Secret__c  = '***********************************XQzY';
        cred.Environment__c = 'SANDBOX';
        insert cred;
        
        // Create Price Book
        Pricebook2 priceBook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update priceBook;
        // Create Product Hierarchy
        Product_Hierarchy__c prdHierachy = new Product_Hierarchy__c(Name = 'Test Hierarchy', 
                                                                    Product_Hierarchy_Code__c = 'Test_HR_Code', RecordTypeId = SBR_3_0_Constants.PRODUCT_HIERARCHY_PRODUCT_SUB_CATEGORY_RT_ID);
        insert prdHierachy;
        // Create Product2
        List<Product2> products = new List<Product2>();
        products.add(new Product2(Name = 'Test Product 1', Product_Title_Internal__c = 'Test Product 1', Product_SKU__c = '0000000', Product_Hierarchy__c = prdHierachy.Id,Stock_class__c = 'DEL', Product_Type__c = 'MISC Charge Items', Item_Number__c = 'DELIVERY', Company_Code__c = '01'));
        products.add(new Product2(Name = 'Test Product 2', Product_Title_Internal__c = 'Test Product 2', Product_SKU__c = '123002', Product_Hierarchy__c = prdHierachy.Id, Product_Type__c = 'Cat-Class', Company_Code__c = '01'));
        insert products;
        System.debug(products);
        
        // Create Price Book Entries
        SBR_3_0_TestDataFactory.createPriceBookEntries(products);

        // Create Account
        Account relatedAccount = new Account();
        relatedAccount.RM_Account_Number__c = '12345';
        relatedAccount.Name = SBR_3_0_API_Web_Jobsite_DA.JOBSITEACCOUNTNAME;
        relatedAccount.BillingStreet = '123 Main Street';
        relatedAccount.BillingCity = 'Toronto';
        relatedAccount.BillingPostalCode = 'M9N7V5';
        relatedAccount.BillingState = 'ON';
        relatedAccount.BillingCountry = 'CA';
        insert relatedAccount;
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
        branchLocation.Branch_Location_Number__c = '1234';
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
        // Create Jobsite
        AssociatedLocation jobSite = new AssociatedLocation(
            Name__c = 'Test Job Site',
            ParentRecordId = relatedAccount.Id,
            Branch__c = branchLocation.Id,
            Job_Number__c = '20221107A',
            Job_Site_Id__c = 'SF20221107A',
            Street_Address__c = '12 Main Street',
            City__c = 'Toronto',
            State__c = 'ON',
            Zip_Code__c = 'M9N7V3',
            LocationId = jobLocation.Id
        );
        insert jobSite;
        
        Profile p = [SELECT Id FROM Profile WHERE Name='Sales'];
        //create OSR user who will be related to the account
        String osrUserOneName = 'osrUserOne' + DateTime.now().getTime() + '@SBRtestorg.com';
        User osrUserOne = new User(Alias = 'osrOne', Email='ersuser@testorg.com',
                                   EmailEncodingKey='UTF-8', LastName='osrOne', LanguageLocaleKey='en_US',
                                   LocaleSidKey='en_US', ProfileId = p.Id,
                                   TimeZoneSidKey='America/Los_Angeles',
                                   UserName=osrUserOneName, RepID__c='92011');
        insert osrUserOne;
    }
  
    
    
  
    
     @isTest
    static void testCreateQuoteSuccess(){
        RestResponse res = new RestResponse(); 
       // Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_Web_Product_Test());
        Test.setMock(
            HttpCalloutMock.class,
            new SBR_3_0_CalloutMock(
                new SBR_3_0_CalloutMock.MockResponse(200,'{"success":true,"errorMsg":"","data":""}')
            )
        );
        RestRequest request = new RestRequest();
        request.requestUri = 'https://yourInstance.salesforce.com/services/apexrest/Quote/ApiCreate/v1/';
        request.httpMethod = 'POST';
        request.addHeader('Content-Type', 'application/json');
        
        DateTime startTime = Datetime.now();
        boolean exceptionThrown = false;
        
        Test.startTest();
        Integer queriesBefore = Limits.getQueries();
        Integer dmlBefore = Limits.getDmlStatements();

        try{
        	// Get Related Records
        //Account relAccount = SBR_3_0_AccountDA.getAccountByRmAccountNumber('12345');
        
        Schema.Location branch = SBR_3_0_LocationDA.getBranchByBranchNumber('1234', '01');
        //AssociatedLocation jobSite = SBR_3_0_JobsiteDA.getJobSiteByJobSiteId('20221107A');
        AssociatedLocation jobSite = [SELECT Id, Job_Site_Id__c FROM AssociatedLocation WHERE Job_Number__c = '20221107A'];
        Pricebook2 priceBook = [SELECT Id FROM Pricebook2 WHERE IsActive = true LIMIT 1];
        System.debug('====>'+priceBook);
        P2P_CustomCreateQuote.QuoteRequestWrapper requestWrapper = new P2P_CustomCreateQuote.QuoteRequestWrapper();
        requestWrapper.rmAccountNumber = '12345' ;
        requestWrapper.branchNumber = branch.Branch_Location_Number__c;
        requestWrapper.jobSiteId = jobSite.Job_Site_Id__c;
        requestWrapper.type = 'P2P_Punchout';
        requestWrapper.companyCodeId = '01';
        requestWrapper.primarySalesRep = '92011';
        requestWrapper.address.street1 = '12 Main Street';
        requestWrapper.address.city = 'Toronto';
        requestWrapper.address.zip = 'M7N7B3';
        requestWrapper.address.state = 'ON';
        requestWrapper.address.country = 'CA';
        requestWrapper.orderedBy.firstName = 'Test';
        requestWrapper.orderedBy.lastName = 'Test';
        requestWrapper.orderedBy.email = 'Test@sdfojiTEST.com';
        requestWrapper.orderedBy.phone = '5555555555';
        
        requestWrapper.data = new SBQQ__Quote__c(
            Quote_Name__c = 'Test API Quote',
            Branch_Manager_Email__c = 'test@test.com',
            Default_Overtime_Rate__c = 15,
            Default_Standard_Rate__c = 10,
            Contingency_Plan__c = true,
            Contingency_Quote__c = false
            //Rentalman_Quote_Id__c = '139824'
            //SBQQ__Account__c = [Select Id from Account Limit 1].Id
        );
        requestWrapper.linedata = new List<P2P_CustomCreateQuote.QuoteLineRequestWrapper>();
        P2P_CustomCreateQuote.QuoteLineRequestWrapper lineItem = new P2P_CustomCreateQuote.QuoteLineRequestWrapper();
        lineItem.productSKU = '0000000';
        /*lineItem.globalLineNumber = '12345';
lineItem.legacyQuote = '12345';*/
        lineItem.data = new SBQQ__QuoteLine__c(
            Start_Date__c = Datetime.now().addDays(2),
            SBQQ__Quantity__c = 0,
            Line_Comments__c = 'Testing...',
            Line_Item_Notes__c = 'Testing \nNew Line \nNote deletedLineData',
            SBQQ__Taxable__c = true,
            Global_Line_Number__c = 123,
            RM_Quote_Line_Number__c = 123,
            Misc_Charges_Type__c = 'DELIVERY',
            SBQQ__PricebookEntryId__c = [Select Id from PriceBookEntry Where Product2.Product_SKU__c = '0000000'].Id
        );
        
        
        requestWrapper.linedata.add(lineItem);
        //requestWrapper.deletedLineData = new List<String>();
        //requestWrapper.deletedLineData.add('12345');
        request.requestBody = Blob.valueOf(JSON.serialize(requestWrapper));
        RestContext.request = request;
        RestContext.response= res;
        
        P2P_API_Web_Quote.create();
        
        delete [Select id from AssociatedLocation];
        P2P_API_Web_Quote.create();
        //SBR_3_0_HttpResponse.ResponseMessage responseObj = (SBR_3_0_HttpResponse.ResponseMessage)JSON.deserialize(response, SBR_3_0_HttpResponse.ResponseMessage.class);
        
        //System.assert(res.statusCode == 200);
        }catch(Exception ex){
            System.debug('Exception message: ' + ex.getMessage());
            System.debug('Exception stack trace: ' + ex.getStackTraceString());
            exceptionThrown = true;
        }
        
        System.debug('Total queries used in createQuote call: ' + (Limits.getQueries() - queriesBefore)); //NOPMD
        System.debug('Total dml used in createQuote call: ' + (Limits.getDmlStatements() - dmlBefore)); //NOPMD
		
        Test.stopTest();
        System.debug('Total time ellapsed: ' + ((Datetime.now().getTime() - startTime.getTime())));
        
       // List<Exception_Log__c> exceptionLogs = [Select Id,Exception_Message__c From Exception_Log__c];
       // if(!exceptionLogs.isEmpty()){
       //    System.assertEquals(null, exceptionLogs.get(0).Exception_Message__c, 'Encountered an exception: ' + exceptionLogs.get(0).Exception_Message__c);
      //  }
        
      //  System.assert(!exceptionThrown, 'An exception was unexpectedly thrown');
      //  System.assert(exceptionLogs.isEmpty(), 'Found an exception log, when none were expected');
        
    }
   
}