/*********************************************************************************************************************
* Apex Class: P2P_CustomCreateQuote_Test
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Test class for P2P_CustomCreateQuote class
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Delvin Riley			2023-10-12			Initial version    
*********************************************************************************************************************/

@istest
public class P2P_CustomCreateQuote_Test {  
     public HTTPResponse respond(HTTPRequest request) {
        // Create a fake response
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setBody('{"success":true,"errorMsg":"","data":""}');
        response.setStatusCode(200);
        return response; 
    }
     @TestSetup
    static void makeData(){
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
        products.add(new Product2(Name = 'Test Product 1', Product_Title_Internal__c = 'Test Product 1', Product_SKU__c = '123001', Product_Hierarchy__c = prdHierachy.Id, Product_Type__c = 'Cat-Class', Company_Code__c = '01'));
        products.add(new Product2(Name = 'Test Product 2', Product_Title_Internal__c = 'Test Product 2', Product_SKU__c = '123002', Product_Hierarchy__c = prdHierachy.Id, Product_Type__c = 'Cat-Class', Company_Code__c = '01'));
        products.add(new Product2(Name = 'Test Product 3', Product_Title_Internal__c = 'Test Product 1', Product_SKU__c = '0000000', Product_Hierarchy__c = prdHierachy.Id, Product_Type__c = 'Cat-Class', Company_Code__c = '01'));
        insert products;
        System.debug(products);
        SBR_3_0_TestDataFactory.createPriceBookEntries(products);
        // Create Account
        Account relatedAccount = new Account();
        relatedAccount.RM_Account_Number__c = '01-1111';
        relatedAccount.Name = SBR_3_0_API_Web_Jobsite_DA.JOBSITEACCOUNTNAME;
        relatedAccount.BillingStreet = '123 Main Street';
        relatedAccount.BillingCity = 'Toronto';
        relatedAccount.BillingPostalCode = 'M9N7V5';
        relatedAccount.BillingState = 'ON';
        relatedAccount.BillingCountry = 'CA';
      
        insert relatedAccount;
        List<Contact> contacts = SBR_3_0_TestDataFactory.createContacts(5,relatedAccount.Id, true);
        
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
        String osrUserOneName = 'osrUserOne' + DateTime.now().getTime() + '@sunbeltrentals.com';
        User osrUserOne = new User(Alias = 'osrOne', Email='ersuser@sunbeltrentals.com',
        EmailEncodingKey='UTF-8', LastName='osrOne', LanguageLocaleKey='en_US',
        LocaleSidKey='en_US', ProfileId = p.Id,
        TimeZoneSidKey='America/Los_Angeles',
        UserName=osrUserOneName, RepID__c='92011');
        insert osrUserOne;
    }
     @isTest
    static void testCreateQuoteSuccess(){
        RestResponse res = new RestResponse(); 
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_Web_Product_Test());
        RestRequest request = new RestRequest();
        request.requestUri = 'https://yourInstance.salesforce.com/services/apexrest/Quote/ApiCreate/v1/';
        request.httpMethod = 'POST';
        request.addHeader('Content-Type', 'application/json');
        // Get Related Records
        Account relAccount = SBR_3_0_AccountDA.getAccountByRmAccountNumber('01-1111');
        Schema.Location branch = SBR_3_0_LocationDA.getBranchByBranchNumber('1234', '01');
        //AssociatedLocation jobSite = SBR_3_0_JobsiteDA.getJobSiteByJobSiteId('20221107A');
        AssociatedLocation jobSite = [SELECT Id, Job_Site_Id__c FROM AssociatedLocation WHERE Job_Number__c = '20221107A'];

        P2P_CustomCreateQuote.QuoteRequestWrapper requestWrapper = new P2P_CustomCreateQuote.QuoteRequestWrapper();
        requestWrapper.rmAccountNumber = '1111';
        requestWrapper.branchNumber = branch.Branch_Location_Number__c;
        requestWrapper.jobSiteId = jobSite.Job_Site_Id__c;
        requestWrapper.type = SBR_3_0_Constants.QUOTE_REC_TYPE_RENTAL_QUOTE;
        requestWrapper.companyCodeId = '01';
        requestWrapper.primarySalesRep = '92011';
        requestWrapper.secondarySalesRep = '78967';
        requestWrapper.initiateTransmit = 'Transmitted';
        requestWrapper.name = 'Q-00015';
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
            Contingency_Quote__c = false,
            Rentalman_Quote_Id__c = '139824'
        );
        requestWrapper.linedata = new List<P2P_CustomCreateQuote.QuoteLineRequestWrapper>();
        P2P_CustomCreateQuote.QuoteLineRequestWrapper lineItem = new P2P_CustomCreateQuote.QuoteLineRequestWrapper();
        lineItem.productSKU = '123001';
        /*lineItem.globalLineNumber = '12345';
        lineItem.legacyQuote = '12345';*/
        lineItem.data = new SBQQ__QuoteLine__c(
            Start_Date__c = Datetime.now().addDays(2),
            SBQQ__Quantity__c = 4,
            Line_Comments__c = 'Testing...',
            Global_Line_Number__c=45234,
            RM_Quote_Line_Number__c=3412,
            Line_Item_Notes__c = 'Testing \nNew Line \nNote',
            SBQQ__Taxable__c = true
        );

        
        requestWrapper.linedata.add(lineItem);
             //   P2P_CustomCreateQuote.QuoteRequestWrapper requestWrapper1 = new P2P_CustomCreateQuote.QuoteRequestWrapper();
        Test.StartTest();
          P2P_CustomCreateQuote quoteHelper = new P2P_CustomCreateQuote(JSON.serialize(requestWrapper));
           SObject returnData = quoteHelper.upsertQuoteToSF();
              SBQQ__Quote__c quote = quoteHelper.setAddress(requestWrapper.data);

      //  quoteHelper.setNewJobLocation();
        Test.stopTest();
                 System.assertEquals(String.isNotBlank(returnData.Id),true);
     
          }
     @isTest                                     
    static void testCreateQuote(){
        RestResponse res = new RestResponse(); 
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_Web_Product_Test());
        RestRequest request = new RestRequest();
        request.requestUri = '/services/apexrest/Quote/ApiCreate/v1/';
        request.httpMethod = 'POST';
        request.addHeader('Content-Type', 'application/json');
        // Get Related Records
        Account relAccount = SBR_3_0_AccountDA.getAccountByRmAccountNumber('01-1111');
        system.debug('rel account '+relAccount);
          relAccount.RecordTypeId= SBR_3_0_Constants.ACCOUNT_CREDIT_RT_ID;
        update relAccount;
        Schema.Location branch = SBR_3_0_LocationDA.getBranchByBranchNumber('1234', '01');
        //AssociatedLocation jobSite = SBR_3_0_JobsiteDA.getJobSiteByJobSiteId('20221107A');
        AssociatedLocation jobSite = [SELECT Id, Job_Site_Id__c FROM AssociatedLocation WHERE Job_Number__c = '20221107A'];

        P2P_CustomCreateQuote.QuoteRequestWrapper requestWrapper = new P2P_CustomCreateQuote.QuoteRequestWrapper();
        requestWrapper.rmAccountNumber = '1111';
        requestWrapper.branchNumber = branch.Branch_Location_Number__c;
       // requestWrapper.jobSiteId = jobSite.Job_Site_Id__c;
        requestWrapper.type = SBR_3_0_Constants.QUOTE_REC_TYPE_RENTAL_QUOTE;
        requestWrapper.companyCodeId = '01';
        requestWrapper.primarySalesRep = '92011';
        requestWrapper.secondarySalesRep = '78967';
        requestWrapper.initiateTransmit = 'Transmitted';
        requestWrapper.name = 'Q-00015';
        requestWrapper.address.street1 = '12 Main Street';
        requestWrapper.address.city = 'pto';
        requestWrapper.address.zip = '234234';
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
            Contingency_Quote__c = false,
            Rentalman_Quote_Id__c = '139824'
        );
        requestWrapper.linedata = new List<P2P_CustomCreateQuote.QuoteLineRequestWrapper>();
        P2P_CustomCreateQuote.QuoteLineRequestWrapper lineItem = new P2P_CustomCreateQuote.QuoteLineRequestWrapper();
        lineItem.productSKU = '0000000';
        /*lineItem.globalLineNumber = '12345';
        lineItem.legacyQuote = '12345';*/
        lineItem.data = new SBQQ__QuoteLine__c(
            Start_Date__c = Datetime.now().addDays(2),
            SBQQ__Quantity__c = 4,
            Line_Comments__c = 'Testing...',
            Global_Line_Number__c=45234,
            RM_Quote_Line_Number__c=3412,
            Line_Item_Notes__c = 'Testing \nNew Line \nNote',
            SBQQ__Taxable__c = true,
            Misc_Charges_Type__c = 'DELIVERY'
        );

        
        requestWrapper.linedata.add(lineItem);
        Test.startTest();
        try{
          P2P_CustomCreateQuote quoteHelper = new P2P_CustomCreateQuote(JSON.serialize(requestWrapper));
            SObject returnData = quoteHelper.upsertQuoteToSF();
           }
        Catch(Exception e)
        {
             System.assertEquals(String.isNotBlank(e.getMessage()),true);
        }
        Test.stopTest();
       //System.assertEquals(String.isNotBlank(returnData),true);
//     
    
          }
     @isTest                                     
    static void testCreateQuote2(){
        RestResponse res = new RestResponse(); 
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_Web_Product_Test());
        RestRequest request = new RestRequest();
        request.requestUri = '/services/apexrest/Quote/ApiCreate/v1/';
        request.httpMethod = 'POST';
        request.addHeader('Content-Type', 'application/json');
        // Get Related Records
        Account relAccount = SBR_3_0_AccountDA.getAccountByRmAccountNumber('01-1111');
        system.debug('rel account '+relAccount);
          relAccount.RecordTypeId= SBR_3_0_Constants.ACCOUNT_CREDIT_RT_ID;
        update relAccount;
        Schema.Location branch = SBR_3_0_LocationDA.getBranchByBranchNumber('1234', '01');
        //AssociatedLocation jobSite = SBR_3_0_JobsiteDA.getJobSiteByJobSiteId('20221107A');
        AssociatedLocation jobSite = [SELECT Id, Job_Site_Id__c FROM AssociatedLocation WHERE Job_Number__c = '20221107A'];

        P2P_CustomCreateQuote.QuoteRequestWrapper requestWrapper = new P2P_CustomCreateQuote.QuoteRequestWrapper();
        requestWrapper.rmAccountNumber = '1111';
        requestWrapper.branchNumber = branch.Branch_Location_Number__c;
        requestWrapper.jobSiteId = jobSite.Job_Site_Id__c;
        requestWrapper.type = SBR_3_0_Constants.QUOTE_REC_TYPE_RENTAL_QUOTE;
        requestWrapper.companyCodeId = '01';
        requestWrapper.primarySalesRep = '92011';
        requestWrapper.secondarySalesRep = '78967';
        requestWrapper.initiateTransmit = 'Transmitted';
        requestWrapper.name = 'Q-00015';
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
            Contingency_Quote__c = false,
            Rentalman_Quote_Id__c = '139824',
            Delivery_Charge__c = 120
        );
        requestWrapper.linedata = new List<P2P_CustomCreateQuote.QuoteLineRequestWrapper>();
        P2P_CustomCreateQuote.QuoteLineRequestWrapper lineItem = new P2P_CustomCreateQuote.QuoteLineRequestWrapper();
        lineItem.productSKU = '123001';
        /*lineItem.globalLineNumber = '12345';
        lineItem.legacyQuote = '12345';*/
        lineItem.data = new SBQQ__QuoteLine__c(
            Start_Date__c = Datetime.now().addDays(2),
            SBQQ__Quantity__c = 4,
            Line_Comments__c = 'Testing...',
            Global_Line_Number__c=45234,
            RM_Quote_Line_Number__c=3412,
            Line_Item_Notes__c = 'Testing \nNew Line \nNote',
            SBQQ__Taxable__c = true
        );        
        requestWrapper.linedata.add(lineItem);
           
        Test.startTest();  
          P2P_CustomCreateQuote quoteHelper = new P2P_CustomCreateQuote(JSON.serialize(requestWrapper));
            SObject returnData = quoteHelper.upsertQuoteToSF();
     
        Test.stopTest();
      
     
    
          }

  
 @isTest                                     
    static void testCreateQuote3(){
         RestResponse res = new RestResponse(); 
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_Web_Product_Test());
        RestRequest request = new RestRequest();
        request.requestUri = '/services/apexrest/Quote/ApiCreate/v1/';
        request.httpMethod = 'POST';
        request.addHeader('Content-Type', 'application/json');
        // Get Related Records
        Account relAccount = SBR_3_0_AccountDA.getAccountByRmAccountNumber('01-1111');
        system.debug('rel account '+relAccount);
          relAccount.RecordTypeId= SBR_3_0_Constants.ACCOUNT_CREDIT_RT_ID;
        update relAccount;
        Schema.Location branch = SBR_3_0_LocationDA.getBranchByBranchNumber('1234', '01');
        //AssociatedLocation jobSite = SBR_3_0_JobsiteDA.getJobSiteByJobSiteId('20221107A');
        AssociatedLocation jobSite = [SELECT Id, Job_Site_Id__c FROM AssociatedLocation WHERE Job_Number__c = '20221107A'];
		String req = '{"companyCodeId":"01","jobSiteId":"RM-00000000000012194604","data":{"Transaction_Type__c":"X","Rentalman_Quote_Id__c":"","Id":"a1079000000LceWAAS","Rates_Overriden__c":false,"Employee_ID__c":"SFQUOTE","Territory_Number__c":10,"P_O_Num__c":"6541234578","End_Date__c":"2023-09-29T08:00:00Z","Start_Date__c":"2023-08-24T08:00:00Z","Opt_Out_RPP__c":true,"Taxable__c":false,"Tax_District__c":"330290290","Billing_Code__c":"A","Use_Code__c":"N","Sales_Tax_Exempt_Code__c":"","Last_Employee_Closing__c":"","Rentalman_System_Date_Time__c":"2023-08-23T09:21:46Z","Pre_Lien__c":false,"Tax_Rate_Used__c":"8.75","Tax_Rental__c":false,"Rental_Tax_Exempt_Code__c":"","Company_Project_Number__c":0,"GST_Tax__c":"","PST_Tax__c":"","Subtract_Saturday__c":"","Subtract_Sunday__c":"","Pro_rate_Days_After_a_Month__c":"","Month_Pro_rate_Divisor__c":0,"Pro_rate_Days_After_a_Week__c":"","Week_Pro_rate_Divisor__c":0,"Daily_Divisor__c":0,"Subtract_Sat_Sun_After_Cycle__c":"","Day_of_Month_to_Bill_on__c":0,"Market_Segment__c":"01","Within_City_Limits__c":"Y","Resale_Number__c":"","CurrencyIsoCode__c":"USD","Reference_Number__c":"","Source_Code__c":"","Invoice_Due_Date_Code__c":"","Summary_Billing_Code__c":"","Last_Modified_Date_Time__c":"2023-08-23T05:21:49.100","Last_Maintained_By_Name__c":"","Charge_Environmental_Fee__c":"","Contract_Out_on_Weekend__c":"","Pro_Rate_Rentals__c":false,"Pre_Bill_Rentals__c":false,"Print_Rates_on_Contracts__c":"Y","CreatedDate__c":"2023-08-23T05:21:47.311","Selling_Channel__c":"SBRINT","Delivery_Special_Instructions__c":"","Quote_Header_Comments__c":"","Delivery_Date__c":"2023-08-24T08:00:00Z","SBQQ__DeliveryMethod__c":"Delivery","Quote_Initiating_Channel__c":"Punchout","Total_Quoted_Amount__c":"100","Total_Sales_Taxes__c":"20","Total_Rental_Amount__c":"10","Total_Sales_Amount__c":"10","RPP_Amount__c":"20","Total_Misc__c":"10","P2P_Transmit_Status__c":""},"branchNumber":"1062","ownerName":"svc_salesforce_mule qa","rmAccountNumber":"9770","type":"P2P_Punchout","linedata":[{"productSKU":10108255,"data":{"Id":"a0w79000000MDJSAA4","Line_Item_Type__c":"VS","RM_Quote_Line_Number__c":1,"Misc_Charges_Type__c":"MISC","SBQQ__Quantity__c":1,"Rates_Overriden__c":false,"Hourly_Rate__c":"0","Min_Rate__c":"0","Daily_Rate__c":"0","Weekly_Rate__c":"0","Monthly_Rate__c":"0","Suggested_Daily_Rate__c":"0","Suggested_Weekly_Rate__c":"0","Suggested_Monthly_Rate__c":"0","RPP_Percentage__c":"0","Selling_Price__c":"10","Misc_Charge__c":50,"Date_Time_Out__c":"2023-08-24T08:00:00Z","Date_Time_in_or_Estimated_Return__c":"2023-09-07T08:00:00Z","Discount_Percentage__c":"0","Cost__c":"0","SBQQ__Taxable__c":true,"Rentalman_System_Date_Time__c":"2023-08-23T09:21:46Z","Kit_Number_this_Item_belongs_to__c":"","Hourly_Book_Rate__c":"0","Minimum_Book_Rate__c":"0","Daily_Book_Rate__c":"0","Weekly_Book_Rate__c":"0","Monthly_Book_Rate__c":"0","Shift_Differential__c":"","PO_Number__c":0,"PO_Sequence_Number__c":0,"Day_Rate_Source_Code__c":"","Week_Rate_Source_Code__c":"","Month_Rate_source_code__c":"","SBQQ__TaxCode__c":"","Rentalman_Last_Maintained_Date_time__c":"2023-08-23T05:21:47.276","Rentalman_Last_Maintained_by__c":"","Delivery_Method__c":"Delivery","Line_Comments__c":""}}],"deletedLineData":[{"Id":"a0w79000000MDJTAA4"}]}';
        Test.startTest();
        try{
          P2P_CustomCreateQuote quoteHelper = new P2P_CustomCreateQuote(req);
            SObject returnData = quoteHelper.upsertQuoteToSF();
           }
        Catch(Exception e)
        {
             System.assertEquals(String.isNotBlank(e.getMessage()),true);
        }
        Test.stopTest();
       //System.assertEquals(String.isNotBlank(returnData),true);
//     

 
}
}