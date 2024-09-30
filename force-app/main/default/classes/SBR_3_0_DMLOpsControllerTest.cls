@isTest
private class SBR_3_0_DMLOpsControllerTest {
    public static final String RESERVTION_RECORD_TYPE = 'Reservation Order';
    @TestSetup
    static void makeData(){
        
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_OrderPdfController_Test());
        Credential__c cred = SBR_3_0_TestDataFactory.createCredentials(1, false)[0];
        cred.Name = 'Mule_Token_Endpoint';
        cred.Key_Id__c = 'testKey123';
        cred.Secret__c = 'secret';
        insert cred;
               
        // Create Account
        Account acct = new Account();
        acct.RM_Account_Number__c = '4';
        acct.Company_Code__c = '01';
        acct.Name = 'Test Account123';
        acct.Record_Type_Text__c = 'Credit';
        acct.E_mail_Address__c = '123@asdf123.com';
        acct.Phone = '9123456789';
        acct.BillingStreet = '123 Main Street123';
        acct.BillingCity = 'Toronto';
        acct.BillingPostalCode = 'M9N7V6';
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
        Order reservationOrder = new Order(
            Quote_Name__c = 'Test Reservation Quote',
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
            Reservation_Order_Number__c = '1234' ,
            RecordTypeId = Schema.getGlobalDescribe().get('Order').getDescribe().getRecordTypeInfosByName().get(RESERVTION_RECORD_TYPE).getRecordTypeId()
        );
        insert reservationOrder;
    }
    
    @isTest
    static void testCreateSObject() {
        // Create a test record
        RecordType ncRec = [SELECT Id, DeveloperName, IsActive, Name, SobjectType FROM RecordType Where DeveloperName = 'Non_Credit'];
        List<Account> testAccount = new List<Account>();
        for(integer i=0;i<2;i++){
         Account a = new Account();
            a.Name = 'Test';
            a.Company_Name__c = 'Test';
            a.Status__c = SBR_3_0_Constants.ACCOUNT_STATUS_ACTIVE;
            a.RecordTypeId = ncRec.Id;
            a.Phone = '9199892214';         
            a.BillingStreet = 'Test';
            a.BillingCity = 'CS';
            a.BillingStateCode = 'IN';
            a.BillingPostalCode = '20111';
            a.BillingCountryCode = 'US';
            a.ShippingStreet = 'Test';
            a.ShippingCity = 'San Francisco';
            a.ShippingState = 'IN';
            a.ShippingPostalCode = '94103';
            a.ShippingCountry = 'US';
            a.E_mail_Address__c='test@test.com';
            testAccount.add(a);
        }
        insert testAccount[0];
        
        // Call the createSObject method
        Test.startTest();
        SBR_3_0_DMLOpsController.createSObject(testAccount[1],false);
        Test.stopTest();      
    }
    
    @isTest
    static void testUpdateSObject() {
        // Create a test record
       RecordType ncRec = [SELECT Id, DeveloperName, IsActive, Name, SobjectType FROM RecordType Where DeveloperName = 'Non_Credit'];
        List<Account> testAccount = new List<Account>();
        for(integer i=0;i<2;i++){
         Account a = new Account();
            a.Name = 'Test';
            a.Company_Name__c = 'Test';
            a.Status__c = SBR_3_0_Constants.ACCOUNT_STATUS_ACTIVE;
            a.RecordTypeId = ncRec.Id;
            a.Phone = '9199892214';         
            a.BillingStreet = 'Test';
            a.BillingCity = 'CS';
            a.BillingStateCode = 'IN';
            a.BillingPostalCode = '20111';
            a.BillingCountryCode = 'US';
            a.ShippingStreet = 'Test';
            a.ShippingCity = 'San Francisco';
            a.ShippingState = 'IN';
            a.ShippingPostalCode = '94103';
            a.ShippingCountry = 'US';
            testAccount.add(a);
        }
        insert testAccount[0];
        // Call the updateSObject method      
        Test.startTest();
        try{
        SBR_3_0_DMLOpsController.updateSObject(testAccount[1], false);
        }
        catch(exception e){}
        Test.stopTest();

    }
    @isTest
    public static void deleteOrderTest(){
        Order ord=[Select Id from Order LIMIT 1];
        Test.startTest();
        SBR_3_0_DMLOpsController.deleteOrder(ord.Id);
        Test.stopTest();
    }
    
}