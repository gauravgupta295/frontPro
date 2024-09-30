/*********************************************************************************************************************
* Apex Class: SBR_3_0_API_Create_ConversionLog_Test
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Test class for the following classes: SBR_3_0_API_Create_ConversionLog, SBR_3_0_ItemProductUpdateHelper, 
SBR_3_0_BatchSObjectCloneAndDelete, SBR_3_0_BatchSObjectUpdate, and SBR_3_0_AccountConversionMergeHelper
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME                        DATE                DETAIL FEATURES
    1.0         Hashem Abdul                        2023-04-10           Initial version    
*********************************************************************************************************************/

@IsTest
public class SBR_3_0_API_Create_ConversionLog_Test implements HttpCalloutMock{
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
        Credential__c cred = SBR_3_0_TestDataFactory.createCredentials(1, false)[0];
        cred.Name = 'Mule_Token_Endpoint';
        cred.Key_Id__c = 'testKey123'; 
        cred.Secret__c = 'secret';
        insert cred;
    }
    
    @IsTest
    public static void testAccountMerge(){
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_Create_ConversionLog_Test());
        // Create Account
        Account mergeAcct = new Account();
        mergeAcct.RM_Account_Number__c = '4';
        mergeAcct.Company_Code__c = '01';
        mergeAcct.Name = 'Test Account';
        mergeAcct.Record_Type_Text__c = 'Credit';
        mergeAcct.E_mail_Address__c = '123@asdf.com';
        mergeAcct.Phone = '1234567890';
        mergeAcct.BillingStreet = '123 Main Street';
        mergeAcct.BillingCity = 'Toronto';
        mergeAcct.BillingPostalCode = 'M9N7V5';
        mergeAcct.BillingState = 'ON';
        mergeAcct.BillingCountry = 'CA';
        mergeAcct.Drivers_License__c = 'AKF';
        mergeAcct.Driver_s_License_State__c = 'AL';
        insert mergeAcct;

        SBR_3_0_TestDataFactory.createAccountRelationships(5, mergeAcct.Id, true);

        // Create Contact
        Contact cont = new Contact();
        cont.FirstName = 'Test';
        cont.LastName = 'TEST';
        cont.AccountId = mergeAcct.Id;
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
            ParentRecordId = mergeAcct.Id,
            LocationId = jobLocation.Id,
            Branch__c = branchLocation.Id,
            Job_Number__c = '20221004A'
        );
        insert jobSite;
        List<Contact> contacts = SBR_3_0_TestDataFactory.createContacts(1, mergeAcct.Id, true);
        List<Schema.Location> locs = SBR_3_0_TestDataFactory.createInventoryLocations(1, false, 'Branch');
        locs[0].Name = 'Test Location 1';
        insert locs;
        List<Asset> assets = SBR_3_0_TestDataFactory.createAssets(1, true, mergeAcct.Id, contacts[0].Id, locs[0].Id);

        Account masterAcct = new Account();
        masterAcct.RM_Account_Number__c = '5';
        masterAcct.Company_Code__c = '01';
        masterAcct.Name = 'Test Account - Master';
        masterAcct.Record_Type_Text__c = 'Credit';
        masterAcct.E_mail_Address__c = '123@aasdfsdf.com';
        masterAcct.Phone = '1234567891';
        masterAcct.BillingStreet = '432 Main Street';
        masterAcct.BillingCity = 'Toronto';
        masterAcct.BillingPostalCode = 'M9N7V5';
        masterAcct.BillingState = 'ON';
        masterAcct.BillingCountry = 'CA';
        masterAcct.Drivers_License__c = 'AKF';
        masterAcct.Driver_s_License_State__c = 'AL';
        insert masterAcct;

        Test.startTest();
        RestRequest request = new RestRequest();
        request.requestUri = 'https://yourInstance.salesforce.com/services/apexrest/Conversion/ApiCreate/v1/';
        request.httpMethod = 'POST';
        SBR_3_0_API_Create_ConversionLog.RequestBody rqBody = new SBR_3_0_API_Create_ConversionLog.RequestBody();
        rqBody.conversionType = 'Account';
        rqBody.oldValue = new SBR_3_0_API_Create_ConversionLog.values();
        rqBody.oldValue.itemNumber = '';
        rqBody.oldValue.stockClass = '';
        rqBody.oldValue.companyCode = '';
        rqBody.oldValue.accountNumber = '01-4';
        rqBody.oldValue.catclass = '';
        rqBody.newValue = new SBR_3_0_API_Create_ConversionLog.values();
        rqBody.newValue.itemNumber = '';
        rqBody.newValue.stockClass = '';
        rqBody.newValue.companyCode = '';
        rqBody.newValue.accountNumber = '01-5';
        rqBody.newValue.catclass = '';
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf(JSON.serialize(rqBody));
        RestContext.request = request;
        SBR_3_0_API_Create_ConversionLog.create();
        Test.stopTest();
        List<AssociatedLocation> masterAcctJbSite = [SELECT ID FROM AssociatedLocation WHERE ParentRecordId =: masterAcct.Id];
        System.assert(masterAcctJbSite.size() > 0);
        Map<Id, Schema.Asset> mergeAcctAssets = new Map<Id, Schema.Asset>([SELECT ID FROM Asset WHERE AccountId =: masterAcct.Id]);
        System.assert(mergeAcctAssets.size() > 0);
    }

    @isTest
    public static void testProductUpdate(){
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_Create_ConversionLog_Test());
        Test.startTest();
        // Create Price Book
        Pricebook2 priceBook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update priceBook;

        Profile p = [SELECT Id FROM Profile WHERE Name='Sales'];

        //create ers user clone
        String ersUserName = 'ersuser' + DateTime.now().getTime() + '@SBRtestorg.com';
        User ersu = new User(Alias = 'ers', Email='ersuser@testorg.com',
        EmailEncodingKey='UTF-8', LastName='erstest', LanguageLocaleKey='en_US',
        LocaleSidKey='en_US', ProfileId = p.Id,
        TimeZoneSidKey='America/Los_Angeles',
        UserName=ersUserName);
        ersu.RepID__c = '1234';
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

        Product2 product1 = new Product2();
        product1.Name = 'Test Product 1';
        product1.Product_Type__c = 'Cat-Class';
        product1.Product_SKU__c = '123456';
        product1.Category__c = '32134';
        product1.Class__c = '2039';
        product1.ToolFlex__c = 'N';
        insert product1;

        Product2 product2 = new Product2();
        product2.Name = 'Test Product 2';
        product2.Product_Type__c = 'Cat-Class';
        product2.Product_SKU__c = '1234567';
        product2.Category__c = '32134';
        product2.Class__c = '2039';
        product2.ToolFlex__c = 'N';
        insert product2;

        PricebookEntry stdPbe = new PricebookEntry();
        stdPbe.Pricebook2Id = Test.getStandardPricebookId();
        stdPbe.Product2Id = product1.Id;
        stdPbe.IsActive = true;
        stdPbe.UnitPrice = 20;
        insert stdPbe;
        
        PricebookEntry stdPbe2 = new PricebookEntry();
        stdPbe2.Pricebook2Id = Test.getStandardPricebookId();
        stdPbe2.Product2Id = product2.Id;
        stdPbe2.IsActive = true;
        stdPbe2.UnitPrice = 20;
        insert stdPbe2;

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
            Duration__c = 'Custom',
            SBQQ__SalesRep__c = ersu.Id
        );
        insert quote;

        SBQQ__QuoteLine__c quoteLine = new SBQQ__QuoteLine__c();
        quoteLine.SBQQ__Quote__c = quote.Id;
        quoteLine.SBQQ__Product__c = product1.Id;
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
        insert quoteLine;

        Order order = new Order(
            Quote_Name__c = 'Test Quote',
            AccountId = acct.Id,
            Jobsite__c = jobSite.Id,
            branch__c = branchLocation.id,
            RecordTypeId = SBR_3_0_Constants.ORDER_REC_TYPE_CONTRACT_ORDER_ID,
            status = 'Cancelled',
            Deliverymethod__c = 'Delivery',
            Pricebook2Id = priceBook.Id,
            Start_Date__c = date.valueOf('2022-10-07 12:00:00'),
            EffectiveDate = date.valueOf('2022-10-07 12:00:00'),
            EndDate = date.valueOf('2022-10-08 8:00:00'),
            Earliest_Delivery_Date__c = date.valueOf('2022-10-07 12:00:00'),
            Opt_Out_RPP__c = false,
            Opt_Out_Fuel_Charge__c = false,
            Selling_Channel__c = 'SBRB2B',
            Duration__c = 'Custom'
        );
        insert order;

        PricebookEntry pbEntry = [SELECT Id,UnitPrice,Product2Id FROM PricebookEntry WHERE Pricebook2Id = :Test.getStandardPricebookId() AND Product2Id = :product1.Id LIMIT 1];
		PricebookEntry pbEntry2 = [SELECT Id,UnitPrice,Product2Id FROM PricebookEntry WHERE Pricebook2Id = :Test.getStandardPricebookId() AND Product2Id = :product2.Id LIMIT 1];

        OrderItem orderItem = new OrderItem();
        orderItem.OrderId = order.Id;
        orderItem.Product2Id = product1.Id;
        orderItem.UnitPrice = 100;
        orderItem.Item_Number__c = 0;
        orderItem.PricebookEntryId = pbEntry.Id;        
        orderItem.Hourly_Rate__c = 2.0;
        orderItem.Min_Rate__c = 0;
        orderItem.Quantity = 5;
        orderItem.Free_Flag__c = false;
        orderItem.Suggested_Daily_Rate__c = 2.0;
        orderItem.Suggested_Weekly_Rate__c = 2.0;
        orderItem.Suggested_Monthly_Rate__c = 2.0;
        orderItem.Daily_Rate__c = 2.0;
        orderItem.Weekly_Rate__c = 4.0;
        orderItem.Monthly_Rate__c = 6.0;
        orderItem.Rates_Overriden__c = false;
        insert orderItem;

        Cart__c cart = new Cart__c(
            Account__c = acct.Id, 
            Branch__c = branchLocation.Id, 
            Rental_Start_Date__c = System.now().addDays(1),
            Rental_End_Date__c = System.now().addDays(2),
            Job_Site__c = jobSite.Id,
            Rental_Period__c= '1 Day' );
        insert cart;

        Cart_Items__c cartItem = new Cart_Items__c(
            Cart__c = cart.Id,
            Product__c = product1.Id
        );
        insert cartItem;

        Equipment_Type__c et = new Equipment_Type__c();
        et.Name = 'Test Equipment Type 1';
        et.SM_PS_Product__c = product1.Id;
        insert et;

        /*ServiceTerritory  testST = SBR_3_0_ServiceTestDataFactory.createServiceTerritory(true);

        Workorder wo = new Workorder(
                            SF_PS_Claim_Type__c='N',
                            SF_PS_Expense_To_Loc__c='1211',
                            SF_PS_LaborCode__c='9600',
                            SF_PS_ExpenseCode__c='BSE',
                            Pricebook2Id = Test.getStandardPricebookId(),
                            SF_PS_Expense_To_Location__c = testST.Id);
        insert wo;
         
        WorkOrderLineItem woli = new WorkOrderLineItem(WorkOrderId=wo.Id, PricebookEntryId = pbEntry.Id);
        insert woli;
        */
        
        RestRequest request = new RestRequest();
        request.requestUri = 'https://yourInstance.salesforce.com/services/apexrest/Conversion/ApiCreate/v1/';
        request.httpMethod = 'POST';
        SBR_3_0_API_Create_ConversionLog.RequestBody rqBody = new SBR_3_0_API_Create_ConversionLog.RequestBody();
        rqBody.conversionType = 'CatClass';
        rqBody.oldValue = new SBR_3_0_API_Create_ConversionLog.values();
        rqBody.oldValue.itemNumber = '';
        rqBody.oldValue.stockClass = '';
        rqBody.oldValue.companyCode = '01';
        rqBody.oldValue.accountNumber = '';
        rqBody.oldValue.catclass = '123456';
        rqBody.newValue = new SBR_3_0_API_Create_ConversionLog.values();
        rqBody.newValue.itemNumber = '';
        rqBody.newValue.stockClass = '';
        rqBody.newValue.companyCode = '01';
        rqBody.newValue.accountNumber = '';
        rqBody.newValue.catclass = '1234567';
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf(JSON.serialize(rqBody));
        RestContext.request = request;
        SBR_3_0_API_Create_ConversionLog.create();
        Test.stopTest();

        // Check if product on Quote Line is updated
        SBQQ__QuoteLine__c updatedQuoteLine = [SELECT ID, SBQQ__Product__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Product__c =: Product2.Id];
        system.assertEquals(product2.Id, updatedQuoteLine.SBQQ__Product__c);
        // Check if product on Order Line Item is updated
        //orderItem updateOrderItem = [SELECT ID, Product2Id FROM OrderItem WHERE Product2Id =: Product2.Id];
        //system.assertEquals(product2.Id, updateOrderItem.Product2Id);
        // Check if product on Cart Item is updated
        Cart_Items__c updatedCartItem = [SELECT ID, Product__c FROM Cart_Items__c WHERE Product__c =: Product2.Id];
        system.assertEquals(product2.Id, updatedCartItem.Product__c);
        // Check if equipment type is updated
        Equipment_Type__c updatedEqpTypes= [SELECT ID, SM_PS_Product__c FROM Equipment_Type__c WHERE SM_PS_Product__c =: Product2.Id];
        system.assertEquals(product2.Id, updatedEqpTypes.SM_PS_Product__c);
        // Check if Work Order Line Item is updated  WorkOrderLineItem
        //WorkOrderLineItem updatedWOLineItm= [SELECT ID, Product2Id FROM WorkOrderLineItem WHERE Product2Id =: Product2.Id];
        //system.assertEquals(product2.Id, updatedWOLineItm.Product2Id);


    }
}