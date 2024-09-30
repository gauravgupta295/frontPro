/*********************************************************************************************************************
* Apex Class: SBR_3_0_API_Web_Return_Test
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Send Order to Rentalman (via Mulesoft) when it is created in Salesforce test class
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Aditee Churiwala        2022-15-08             Initial version    
*********************************************************************************************************************/
@isTest(seeAllData=false)
private with sharing class SBR_3_0_API_Web_Return_Test  { // implements HttpCalloutMock
    // Class set to private - Added by Nitin - PS-3930
	static Boolean SUCCESSTEST = true;
    @TestSetup
    static void makeData() {

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

        Credential__c cred = SBR_3_0_TestDataFactory.createCredentials(1, false)[0];
        cred.Name = 'Mule_Token_Endpoint';
        cred.Key_Id__c = 'testKey123';
        cred.Secret__c = 'secret';
        insert cred;
               
        // Create Account
        Account acct = new Account();
        acct.RM_Account_Number__c = '12345';
        acct.Company_Code__c = '01';
        acct.Name = 'Test Account';
        acct.Record_Type_Text__c = 'Credit';
        acct.E_mail_Address__c = '123@asdf.com';
        acct.Phone = '1234567899';
        acct.BillingStreet = '123 Main Street';
        acct.BillingCity = 'Toronto';
        acct.BillingPostalCode = 'M9N7V5';
        acct.BillingState = 'ON';
        acct.BillingCountry = 'CA';
        acct.Drivers_License__c = 'AKF';
        acct.Driver_s_License_State__c = 'AL';
        insert acct;
       // Account acct = SBR_3_0_TestDataFactory.createAccounts(1, true, null)[0];
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
        branchLocation.Branch_Location_Number__c = '1234';
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
        insert branchLocation;
        // Create Job Site
        AssociatedLocation jobSite = new AssociatedLocation(
            Name__c = 'Test Job Site',
            ParentRecordId = acct.Id,
            LocationId = jobLocation.Id,
            Branch__c = branchLocation.Id,
            Job_Number__c = '20221004A',
            Job_Site_Id__c='12345'
        );
        insert jobSite;
                // Create Price Book
        Pricebook2 priceBook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update priceBook;
        // Create Order
       /* Order order = new Order(
            Quote_Name__c = 'Test Quote',
            AccountId = acct.Id,
            Jobsite__c = jobSite.Id,
            Deliverymethod__c = 'Delivery',
            Delivery_Charge__c = 10,
           // Status = 'Draft',
            Pricebook2Id = priceBook.Id,
            Start_Date__c = date.valueOf('2022-12-12 12:00:00'),
            EffectiveDate = date.valueOf('2022-12-12 12:00:00'),
            EndDate = date.valueOf('2023-10-09 8:00:00'),
            Return_Date__c = date.valueOf('2023-10-09 8:00:00'),
            Earliest_Delivery_Date__c = date.valueOf('2022-10-08 12:00:00'),
            Opt_Out_RPP__c = false,
            Order_Initiating_Channel__c = 'SLSFRC',
            Opt_Out_Fuel_Charge__c = false,
            Selling_Channel__c = 'SBRB2B',
            Duration__c = 'Custom',
            Company_Code__c='01',
            Reservation_Order_Number__c='123456'
        );
        insert order;*/

         
        // Create Product
        List<Product2> products = new List<Product2>();
        for(Integer i = 0; i < 3; i++) {
            Product2 product = new Product2();
            product.Name = 'Test Product ' + i;
            if(i == 0) {
                product.Product_Type__c = 'Cat-Class';
                product.Product_SKU__c = '123001';
                product.Category__c = '32134';
                product.Class__c = '2039';
                product.ToolFlex__c = 'N';
                product.Company_Code__c = '01';
            } else if (i == 1) {
                product.Product_Type__c = 'Parts';
                product.Item_Number__c = '1234GH';
                product.Stock_Class__c = 'AIMFV';
                product.Company_Code__c = '01';
            } else {
                product.Product_Type__c = '';
                product.Item_Number__c = '1285JC';
                product.Stock_Class__c = 'UJEKL';
                product.Item_Number__c = 'ITEMNOTFOUND';
                product.Company_Code__c = '01';
            }
            products.add(product);
        }
        insert products;
        // Create Price Book Entry
        List<PricebookEntry> listPbe = new List<PricebookEntry>();
        SBR_3_0_TestDataFactory.createPriceBookEntries(products);

        Map<Id, Id> mapPBE = new Map<Id, Id>();
        for(PricebookEntry pbEntry : [SELECT Id,Product2Id FROM PricebookEntry WHERE Pricebook2Id = :Test.getStandardPricebookId()]) {
            if(pbEntry.Product2Id == products[0].Id){
                mapPBE.put(pbEntry.Product2Id, pbEntry.Id);
            }
            else if(pbEntry.Product2Id == products[1].Id){
                mapPBE.put(pbEntry.Product2Id, pbEntry.Id);
            }
            else if(pbEntry.Product2Id == products[2].Id){
                mapPBE.put(pbEntry.Product2Id, pbEntry.Id);
            }
        }


        Order ord = new Order(
            Name = 'Test Order',
            RecordTypeId = SBR_3_0_Constants.ORDER_REC_TYPE_CONTRACT_ORDER_ID,
            Contract_Order_Number__c = '1234',
            AccountId = acct.Id,
            Sourcing_Branch__c = branchLocation.Id,
            Status = 'Open',
            Reservation_Order_Number__c='123456',
            EffectiveDate = Date.today(),
            Company_Code__c = 'X'
        );
        insert ord;

        PricebookEntry pbEntry = [SELECT Id FROM PricebookEntry WHERE Product2Id =: products[0].Id];

        OrderItem ordItem = new OrderItem(
            OrderId = ord.Id,
            Product2Id = products[0].Id,
            UnitPrice = 100,
            Quantity = 5,
            Line_Composite_Key__c = '1234-1328090',
            PricebookEntryId = pbEntry.Id
        );
        insert ordItem;
         

        Order_Item_Detail__c ordItemDtl = new Order_Item_Detail__c(
            Line_Item__c = ordItem.Id,
            Pickup_Ticket__c = '353535',
            Service_Requested_Date__c = Datetime.now(),
            Pickup_Ticket_Requested_By__c = ersu.Id,
            Pickup_Ticket_Line_Number__c = '1328090',
            OMS_Order_ID__c = '119206777-353535',
            Order_Item_Comments__c = 'Test Comment',
            Global_Line_Number__c = 1328090,
            Reason_Code__c = 'TR',
            Quantity__c = 1
        );
        insert ordItemDtl;
        
          Asset assetinsert = new Asset(
            Name = '987654321',
            SBQQ__Number__c = 16.2,
            AccountId = acct.Id
           );
        insert assetinsert;
    }
    @isTest 
    static void testCreateOrderSuccess() {
        // Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_Web_Return_Test());
        // Added by Nitin Gottiparthi - PS-3930
        Test.setMock(HttpCalloutMock.class,new SBR_3_0_CalloutMock(new List<SBR_3_0_CalloutMock.MockResponse>{new SBR_3_0_CalloutMock.MockResponse(200,'Success')}));
         //PS-3930--End
        RestRequest request = new RestRequest();
        request.requestUri = 'https://yourInstance.salesforce.com/services/Order/ApiReturn/v1/';
        request.httpMethod = 'POST';
        SBR_3_0_CreateReturn.WrapReturn retWrapper = new SBR_3_0_CreateReturn.WrapReturn();
        retWrapper.contractNumber = '1234';
        retWrapper.type = 'ReturnOrder';
        retWrapper.companyCode = 'X';
       
        Order_Item_Detail__c ordItemDtl= [SELECT Id, Name, Order_Item_Comments__c, Global_Line_Number__c, OMS_Order_ID__c FROM Order_Item_Detail__c WHERE Reason_Code__c = 'TR'];
        retWrapper.data = ordItemDtl;
         request.addHeader('Content-Type', 'application/json');
         request.requestBody = Blob.valueOf(JSON.serialize(retWrapper));
         RestContext.request = request;
         system.debug('test request' + request);
        try {
            Test.startTest();
            SBR_3_0_API_Web_Return.createReturn();
            Test.stopTest();
             
           }
        catch (Exception e) {
            system.assertEquals('Related Account not found!', e.getMessage(), 'Order API did not return Success!');
        }
    }
    
    @isTest 
    static void testCreateOrderFailure() {
        // Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_Web_Return_Test());
        // PS-3930 - Added by Nitin gottiparthi
        Test.setMock(HttpCalloutMock.class,new SBR_3_0_CalloutMock(new List<SBR_3_0_CalloutMock.MockResponse>{new SBR_3_0_CalloutMock.MockResponse(200,'Success')}));
        //PS-3930 - End
        RestRequest request = new RestRequest();
        request.requestUri = 'https://yourInstance.salesforce.com/services/Order/ApiReturn/v1/';
        request.httpMethod = 'POST';
        SBR_3_0_CreateReturn.WrapReturn retWrapper = new SBR_3_0_CreateReturn.WrapReturn();
        retWrapper.contractNumber = '1234';
        retWrapper.type = 'ReturnOrder';
        retWrapper.companyCode = '01';
       
        Order_Item_Detail__c ordItemDtl= [SELECT Id, Name, Order_Item_Comments__c, Global_Line_Number__c, OMS_Order_ID__c FROM Order_Item_Detail__c WHERE Reason_Code__c = 'TR'];
        retWrapper.data = ordItemDtl;     
         request.addHeader('Content-Type', 'application/json');
         request.requestBody = Blob.valueOf(JSON.serialize(retWrapper));
         RestContext.request = request;
         system.debug('test request' + request);
        try {
            Test.startTest();
            SBR_3_0_API_Web_Return.createReturn();
            Test.stopTest();
           }
        catch (Exception e) {
            system.assertEquals('Unable to find related Line Item to Return or Exchange!', e.getMessage(), 'Order API did not return Success!');
        }
    }

}