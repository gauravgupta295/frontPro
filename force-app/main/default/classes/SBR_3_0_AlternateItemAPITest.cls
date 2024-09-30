@isTest
public with sharing class SBR_3_0_AlternateItemAPITest implements HttpCalloutMock{
    @TestSetup
    static void makeData()
    {       
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
        branchLocation.OMS_Sourcing_Enabled__c = true;
        branchLocation.Time_Zone__c = 3;
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
                // Create Price Book
        Pricebook2 priceBook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update priceBook;
        // Create Order
        Order order = new Order(
            Quote_Name__c = 'Test Quote',
            AccountId = acct.Id,
            Jobsite__c = jobSite.Id,
            Deliverymethod__c = 'Delivery',
            Delivery_Charge__c = 10,
            Status = 'Draft',
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
            Reservation_Order_Number__c = '12342',
             Branch__c = branchLocation.Id,
            RecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('Reservation Order').getRecordTypeId()
        );
        insert order;

        // Create Quote
        SBQQ__Quote__c quote = new SBQQ__Quote__c(
            Quote_Name__c = 'Test Quote',
            SBQQ__Account__c = acct.Id,
            Jobsite__c = jobSite.Id,
            SBQQ__DeliveryMethod__c = 'Delivery',
            Start_Date__c = date.valueOf('2022-10-07 12:00:00'),
            End_Date__c = date.valueOf('2022-10-07 12:00:00'),
            Delivery_Date__c  = date.valueOf('2022-10-08 12:00:00'),
            Opt_Out_RPP__c = false,
            Opt_Out_Fuel_Charge__c = false,
            Selling_Channel__c = 'SBRB2B',
            Rentalman_Quote_Id__c = 'Test QId',
            Company_Code__c = '01',
            Show_Crew_Expense_Calculator__c = true,
            Branch__c = branchLocation.Id
        );
        insert quote; 

        User_Location__c ul = new User_Location__c();
        ul.Analysis_Region__c = region.Id;
        ul.User__c = UserInfo.getUserId();
        ul.Branch__c = branchLocation.Id;
        insert ul;
    }

    public HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type',SBR_3_0_Constants.APP_JSON);
        if(req.getEndpoint().endsWithIgnoreCase('token')){
            res.setBody('{"access_token":"test"}');
        }
        else if(req.getEndpoint().endsWithIgnoreCase('alternate'))
        {
            res.setBody('{ "data": { "companyId": "01", "sellingChannel": "SBRB2B", "cartId": "5242f682-13de-4b77-a654-612a62ab782e", "availabilityByTransactionType": [ { "transactionType": "SBR", "availabilityByProducts": [ { "productId": "1088773", "uom": "EA", "availabilityByFulfillmentTypes": [ { "fulfillmentType": "DEL", "availabilityDetails": [ { "availabilityByLocations": [ { "locationType": "PC", "locationId": "01-0001", "atp": 0, "geoDistanceFromJobSite": 569.837 } ] } ] } ] }, { "productId": "1428123", "uom": "EA", "availabilityByFulfillmentTypes": [ { "fulfillmentType": "DEL", "availabilityDetails": [ { "availabilityByLocations": [ { "locationType": "PC", "locationId": "01-0001", "atp": 0, "geoDistanceFromJobSite": 569.837 } ] } ] } ] } ] } ] } }');
        }
        res.setStatusCode(200);
        return res;
    }

    @isTest
    static void testExecuteSuccess()
    {
        String catClass = '1088773';
        List<String> catClasses = new List<String>();
        catClasses.add('1088773');
        String companyCode = '01';
        Test.startTest();
            Test.setMock(HttpCalloutMock.class, new SBR_3_0_AlternateItemAPITest());
            SBR_3_0_WrapAlternateItems.ATIResponse response = (SBR_3_0_WrapAlternateItems.ATIResponse)System.JSON.deserialize(SBR_3_0_AvailabilityBadgeCmpController.getATI(null, JSON.serialize(catClasses)), SBR_3_0_WrapAlternateItems.ATIResponse.class);
        Test.stopTest();
        System.assertEquals(catClass, response.data.availabilityByTransactionType[0].availabilityByProducts[0].productId, 'Returned incorrect catClass');
    }

    @isTest
    static void testExecuteOrderSuccess()
    {
        String catClass = '1088773';
        List<String> catClasses = new List<String>();
        catClasses.add('1088773');
        Order ord = [SELECT ID FROM Order WHERE Quote_Name__c = 'Test Quote' LIMIT 1];
        Test.startTest();
            Test.setMock(HttpCalloutMock.class, new SBR_3_0_AlternateItemAPITest());
            SBR_3_0_WrapAlternateItems.ATIResponse response = (SBR_3_0_WrapAlternateItems.ATIResponse)System.JSON.deserialize(SBR_3_0_AvailabilityBadgeCmpController.getATI(ord.Id, JSON.serialize(catClasses)), SBR_3_0_WrapAlternateItems.ATIResponse.class);
        Test.stopTest();
        System.assertEquals(catClass, response.data.availabilityByTransactionType[0].availabilityByProducts[0].productId, 'Returned incorrect catClass');
    }

    @isTest
    static void testExecuteQuoteSuccess()
    {
        String catClass = '1088773';
        List<String> catClasses = new List<String>();
        catClasses.add('1088773');
        SBQQ__Quote__c quote = [SELECT ID FROM SBQQ__Quote__c WHERE Quote_Name__c = 'Test Quote' LIMIT 1];
        Test.startTest();
            Test.setMock(HttpCalloutMock.class, new SBR_3_0_AlternateItemAPITest());
            SBR_3_0_WrapAlternateItems.ATIResponse response = (SBR_3_0_WrapAlternateItems.ATIResponse)System.JSON.deserialize(SBR_3_0_AvailabilityBadgeCmpController.getATI(quote.Id, JSON.serialize(catClasses)), SBR_3_0_WrapAlternateItems.ATIResponse.class);
        Test.stopTest();
        System.assertEquals(catClass, response.data.availabilityByTransactionType[0].availabilityByProducts[0].productId, 'Returned incorrect catClass');
    }
}