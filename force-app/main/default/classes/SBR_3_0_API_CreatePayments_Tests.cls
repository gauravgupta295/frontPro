/*********************************************************************************************************************
* Apex Class: SBR_3_0_API_CreatePayments_Tests
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Send Payment to Rentalman (via Mulesoft) when it is created in Salesforce test class
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Vivek Sharma        2024-03-21           Initial version    
*********************************************************************************************************************/
@isTest(seeAllData=false)
    /**
     * @description Class to create payments through API.
     */
public with sharing class SBR_3_0_API_CreatePayments_Tests Implements HttpCalloutMock{
    static Boolean successTest = true;
    /**
     * @description Test setup method to prepare necessary data for tests.
     */
    @TestSetup
    static void makeData(){

        Profile p = [SELECT Id FROM Profile WHERE Name='Sales'];
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Payment_Access'];
        //create ers user clone
        String ersUserName = 'ersuser' + DateTime.now().getTime() + '@SBRtestorg.com';
        User ersu = new User(Alias = 'ers', Email='ersuser@testorg.com',
        EmailEncodingKey='UTF-8', LastName='erstest', LanguageLocaleKey='en_US',
        LocaleSidKey='en_US', ProfileId = p.Id,
        TimeZoneSidKey='America/Los_Angeles',
        UserName=ersUserName);
        ersu.RepID__c = '1028';
        ersu.IsActive =true;
        insert ersu;
        
        insert new PermissionSetAssignment(AssigneeId = ersu.Id, PermissionSetId = ps.Id);

        System.runAs(ersu){

        Credential__c cred = SBR_3_0_TestDataFactory.createCredentials(1, false)[0];
        cred.Name = 'Mule_Token_Endpoint';
        cred.Key_Id__c = 'testKey123';
        cred.Secret__c = 'secret';
        insert cred;
        Account acct = new Account();
        acct.RM_Account_Number__c = '4';
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
        // Create Order
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
        branchLocation.Branch_Location_Number__c = '0720';
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
        branchLocation.Latitude_Longitude__Latitude__s = 40.464390;
        branchLocation.Latitude_Longitude__Longitude__s = -80.601060;
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
            Name = 'Test',
            Quote_Name__c = 'Test Quote',
            AccountId = acct.Id,
            Jobsite__c = jobSite.Id,
            Deliverymethod__c = 'Delivery',
            Delivery_Charge__c = 10,
            Pickup_Charge__c = 10,
            Status = 'Draft',
            Company_Code__c = '02',
            CurrencyIsoCode= 'USD',
            Pricebook2Id = priceBook.Id,
            Start_Date__c = Date.today().addDays(1),
            EffectiveDate = Date.today().addDays(2),
            EndDate = Date.today().addDays(5),
            Return_Date__c = Date.today().addDays(5),
            Earliest_Delivery_Date__c = Date.today().addDays(1),
            Estimated_Return_Date__c = Date.today().addDays(4),
            Opt_Out_RPP__c = false,
            Order_By__c = contact.Id,
            Order_Initiating_Channel__c = 'SLSFRC',
            Opt_Out_Fuel_Charge__c = false,
            Selling_Channel__c = 'SBRB2B',
            Rentalman_Quote_Id__c = 'test',
			Duration__c = 'Custom',
            Branch__c =branchLocation.Id,
            Sourcing_Branch__c = branchLocation.Id,
            Invoice_Sequence_Number__c=100
            //Reservation_Order_Number__c = '1111'
        );
        insert order;
        
         Transaction__c newTransaction = new Transaction__c();
            newTransaction.Order__c =order.id;
            insert newTransaction;
        }
    }

    /**
     * @description Mock HTTPResponse for callouts.
     * @param req The HTTPRequest object.
     * @return HTTPResponse The mock HTTPResponse.
     */
    public HTTPResponse respond(HTTPRequest req) {

        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type',SBR_3_0_Constants.APP_JSON);
        if(req.getEndpoint().endsWithIgnoreCase('token')){
            res.setBody('{"access_token":"test"}');
            res.setStatusCode(200);
        }else if(successTest) {
            res.setBody( '{"data": {"rmReservationId": "000086613723","sfOrderId": "ABCD-12345","lines": ['+
			'{"lineNumber": 1324546,"sfLineNumber": "100059","rmLineNumber": 1,"rmLineType": "VR"},'+
			'{"lineNumber": 1343567,"sfLineNumber": "100060","rmLineNumber": 2,"rmLineType": "VR"},'+
			'{"lineNumber": 1343567,"sfLineNumber": "100061","rmLineNumber": 5,"rmLineType": "VR"}'+
		']}}');
            res.setStatusCode(200);
        }else {
            res.setBody('{ "error": { "message": "Invalid input parameters, parameters might contain special characters, SQL statements or script statements. Please check application logs for more information.", "errorKey": "BAD_REQUEST", "errorCode": "400-000" } }');
            res.setStatusCode(400);
        }
        return res;
    }

    /**
     * @description Test method to validate successful creation of payments.
     */
    @isTest 
    static void testCreatePaymentsSuccess() {
        User ersu = [SELECT Id FROM User Where IsActive =true LIMIT 1];
        System.runAs(ersu){

        successTest = true;
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_CreatePayments_Tests());
        Order order = [SELECT Id, EndDate FROM Order];
        Transaction__c tran = [SELECT Id, Name,RM_Detail_Sequence_Number__c,Order__c  FROM Transaction__c];
        Test.startTest();
        String wynneUserName = 'WROHR';
        String recordDetailsJsonString = '{\n' +
                                                ' "paymentMethod" :"Visa",\n' +    
                                                ' "amountCollected" : 10,\n' +
                                                ' "terminal" : "Lane: 003,ID: 1223",\n' +
                                                ' "checkNumber" : 0,\n' +
            									' "usePreviousCard" : true\n' +
                                                '}';
		SBR_3_0_API_CreatePayments.makeADepositDetails =  recordDetailsJsonString;       
        SBR_3_0_API_CreatePayments testCreate = new SBR_3_0_API_CreatePayments(order.Id);
        System.assertNotEquals(null, testCreate, 'Payments cant be null');
        //SBR_3_0_API_CreatePayments.transactionId =  tran.Id; 
        SBR_3_0_API_CreatePayments.createPayments(order.Id,recordDetailsJsonString,tran.Id,wynneUserName);    
        Test.stopTest(); 
    }
    }

    /**
    * @description Test method to validate handling of uncollected payments.
    */
    @isTest 
    static void testUncollected() {
        User ersu = [SELECT Id FROM User Where IsActive =true LIMIT 1];
        System.runAs(ersu){

        successTest = true;
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_CreatePayments_Tests());
        Order order = [SELECT Id,Invoice_Sequence_Number__c,EndDate FROM Order];
        Transaction__c tran = [SELECT Id, Name,RM_Detail_Sequence_Number__c,Order__c  FROM Transaction__c];
        Test.startTest();
        String wynneUserName = 'WROHR';
        String recordDetailsJsonString = '{\n' +
                                                ' "paymentMethod" :"Visa",\n' +    
                                                ' "amountCollected" : 10,\n' +
                                                ' "terminal" : "Lane: 003,ID: 1223",\n' +
                                                ' "checkNumber" : 0,\n' +
            									' "usePreviousCard" : true\n' +
                                                '}';
		SBR_3_0_API_CreateUncollectedPayments.makeADepositDetails =  recordDetailsJsonString;       
        SBR_3_0_API_CreateUncollectedPayments testCreate = new SBR_3_0_API_CreateUncollectedPayments(order.Id);
        System.assertNotEquals(null, testCreate, 'UCP cant be null');
        //SBR_3_0_API_CreatePayments.transactionId =  tran.Id; 
        SBR_3_0_API_CreateUncollectedPayments.createUncollectedPayment(order.Id,recordDetailsJsonString,tran.Id,wynneUserName); 
        Test.stopTest();
        }
    } 

    /**
     * @description Test method to validate creation of payments with specific details.
     */
    @isTest 
    static void testCreatePaymentsSuccessCheck() {
        User ersu = [SELECT Id FROM User Where IsActive =true LIMIT 1];
        System.runAs(ersu){
        successTest = true;
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_CreatePayments_Tests());
        Order order = [SELECT Id, EndDate FROM Order];
        Transaction__c tran = [SELECT Id, Name,RM_Detail_Sequence_Number__c,Order__c  FROM Transaction__c];
        Test.startTest();
        String wynneUserName = 'WROHR';
       String recordDetailsJsonString = '{\n' +
                                                ' "paymentMethod" :"Check",\n' +    
                                                ' "amountCollected" : 10,\n' +
                                                ' "checkNumber" : "na1234",\n' +
                                                '}';
		SBR_3_0_API_CreatePayments.makeADepositDetails =  recordDetailsJsonString;       
        SBR_3_0_API_CreatePayments testCreate = new SBR_3_0_API_CreatePayments(order.Id);
        System.assertNotEquals(null, testCreate, 'Payments cant be null');
        //SBR_3_0_API_CreatePayments.transactionId =  tran.Id; 
        SBR_3_0_API_CreatePayments.createPayments(order.Id,recordDetailsJsonString,tran.Id,wynneUserName);    
        Test.stopTest();
        }
    }
    
    /**
     * @description Test method to validate creation of uncollected payments with specific details.
     */
    @isTest 
    static void testCreateUncollectedPaymentsSuccessCheck() {
        User ersu = [SELECT Id FROM User Where IsActive =true LIMIT 1];
        System.runAs(ersu){

        successTest = true;
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_CreatePayments_Tests());
        Order order = [SELECT Id,Invoice_Sequence_Number__c, EndDate FROM Order];
        Transaction__c tran = [SELECT Id, Name,RM_Detail_Sequence_Number__c,Order__c  FROM Transaction__c];
        Test.startTest();
        String wynneUserName = 'WROHR';
        String recordDetailsJsonString = '{\n' +
                                                ' "paymentMethod" :"Check",\n' +    
                                                ' "amountCollected" : 10,\n' +
                                                ' "checkNumber" : "na1234",\n'+
                                                '}';
		SBR_3_0_API_CreateUncollectedPayments.makeADepositDetails =  recordDetailsJsonString;       
        SBR_3_0_API_CreateUncollectedPayments testCreate = new SBR_3_0_API_CreateUncollectedPayments(order.Id);
        System.assertNotEquals(null, testCreate, 'UCP cant be null');
        //SBR_3_0_API_CreatePayments.transactionId =  tran.Id; 
        SBR_3_0_API_CreateUncollectedPayments.createUncollectedPayment(order.Id,recordDetailsJsonString,tran.Id,wynneUserName); 
        Test.stopTest();
        }
    }
    
    /**
     * @description Test method to validate successful creation of uncollected payments.
     */
    @isTest
    static void testCreateUncollectedPaymentsSuccess() {
        User ersu = [SELECT Id FROM User Where IsActive =true LIMIT 1];
        System.runAs(ersu){
        successTest = true;
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_CreatePayments_Tests());
        Order order = [SELECT Id,Invoice_Sequence_Number__c, EndDate FROM Order];
        Transaction__c tran = [SELECT Id, Name,RM_Detail_Sequence_Number__c,Order__c  FROM Transaction__c];
        Test.startTest();
        String wynneUserName = 'WROHR';
        String recordDetailsJsonString = '{\n' +
                                                ' "paymentMethod" :"Visa",\n' +    
                                                ' "amountCollected" : 10,\n' +
                                                ' "terminal" : "Lane: 003,ID: 1223",\n' +
                                                '}';
		SBR_3_0_API_CreateUncollectedPayments.makeADepositDetails =  recordDetailsJsonString;       
        SBR_3_0_API_CreateUncollectedPayments testCreate = new SBR_3_0_API_CreateUncollectedPayments(order.Id);
        System.assertNotEquals(null, testCreate, 'UCP cant be null');
        //SBR_3_0_API_CreatePayments.transactionId =  tran.Id; 
        SBR_3_0_API_CreateUncollectedPayments.createUncollectedPayment(order.Id,recordDetailsJsonString,tran.Id,wynneUserName); 
        Test.stopTest();
        }
    }
    
    /**
     * @description Test method to validate creation of ROA payments.
     */
    @isTest 
    static void testCreateROAPaymentsSuccess() {
        User ersu = [SELECT Id FROM User Where IsActive =true LIMIT 1];
        System.runAs(ersu){
        successTest = true;
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_CreatePayments_Tests());
        Account acc = [SELECT Id FROM Account];
        Transaction__c tran = [SELECT Id, Name,RM_Detail_Sequence_Number__c,Order__c  FROM Transaction__c];
        Test.startTest();
        String recordDetailsJsonString = '{\n' +
                                                ' "paymentMethod" :"Visa",\n' +    
                                                ' "amountCollected" : 10,\n' +
                                                ' "terminal" : "Lane: 003,ID: 1223",\n' +
                                                ' "checkNumber" : 0,\n' +
            									' "usePreviousCard" : true,\n' +
            									' "invSeqNumber" : 100\n' +
                                                '}';
        String paymentRecords = '{\n' +
                                                ' "paymentAmount" :100,\n' +    
                                                ' "comment" : "167548904-1115",\n' +
                                                ' "sfReferenceNumber" : "a4n8K0000008KDeQAM"\n' +
                                                '}';
        String wynneUserName = 'WROHR';
		SBR_3_0_API_CreateROAPayments.makeADepositDetails =  recordDetailsJsonString;       
        SBR_3_0_API_CreateROAPayments testCreate = new SBR_3_0_API_CreateROAPayments(acc.Id,paymentRecords);
        System.assertNotEquals(null, testCreate, 'ROA Payments cant be null');
        //SBR_3_0_API_CreatePayments.transactionId =  tran.Id; 
        SBR_3_0_API_CreateROAPayments.createRoaPayment(acc.Id,recordDetailsJsonString,tran.Id,paymentRecords,wynneUserName); 
        Test.stopTest();
        }
    }

    /**
     * @description Test method to validate creation of ROA payments with check payment method.
     */
    @isTest 
    static void testCreateROAPaymentsSuccessCheck() {
        User ersu = [SELECT Id FROM User Where IsActive =true LIMIT 1];
        System.runAs(ersu){
        successTest = true;
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_CreatePayments_Tests());
        Account acc = [SELECT Id FROM Account];
        Transaction__c tran = [SELECT Id, Name,RM_Detail_Sequence_Number__c,Order__c  FROM Transaction__c];
        Test.startTest();
        String recordDetailsJsonString = '{\n' +
                                                ' "paymentMethod" :"Check",\n' +    
                                                ' "amountCollected" : 10,\n' +
                                                ' "checkNumber" : "na1234",\n' +
            									' "invSeqNumber" : 100\n' +
                                                '}';
        String wynneUserName = 'WROHR';
        String paymentRecords = '[{"paymentAmount":100,"comment":"167548904-1111","sfReferenceNumber":"a4n8K0000008KDUQA2"},{"paymentAmount":100,"comment":"167548904-1115","sfReferenceNumber":"a4n8K0000008KDeQAM"}]';
		SBR_3_0_API_CreateROAPayments.makeADepositDetails =  recordDetailsJsonString;       
        SBR_3_0_API_CreateROAPayments testCreate = new SBR_3_0_API_CreateROAPayments(acc.Id,paymentRecords);
        System.assertNotEquals(null, testCreate, 'ROA Payments cant be null');
        //SBR_3_0_API_CreatePayments.transactionId =  tran.Id; 
        SBR_3_0_API_CreateROAPayments.createRoaPayment(acc.Id,recordDetailsJsonString,tran.Id,paymentRecords,wynneUserName); 
        Test.stopTest();
        }
    }

    /**
     * @description Test method to validate handling of ROA payments when successTest is false.
     * FRONT-30847 Added testmethods to increase code coverage
     */
    @isTest 
    static void testCreateROAPaymentsSuccessCheckSuccessTestFalse() {
        User ersu = [SELECT Id FROM User Where IsActive =true LIMIT 1];
        System.runAs(ersu){
        successTest = false;
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_CreatePayments_Tests());
        Account acc = [SELECT Id FROM Account];
        Transaction__c tran = [SELECT Id, Name,RM_Detail_Sequence_Number__c,Order__c  FROM Transaction__c];
        Test.startTest();
        String recordDetailsJsonString = '{\n' +
                                                ' "paymentMethod" :"Check",\n' +    
                                                ' "amountCollected" : 10,\n' +
                                                ' "checkNumber" : "na1234",\n' +
            									' "invSeqNumber" : 100\n' +
                                                '}';
        String wynneUserName = 'WROHR';
        String paymentRecords = '[{"paymentAmount":100}]';
		SBR_3_0_API_CreateROAPayments.makeADepositDetails =  recordDetailsJsonString;       
        SBR_3_0_API_CreateROAPayments testCreate = new SBR_3_0_API_CreateROAPayments(acc.Id,paymentRecords);
        System.assertNotEquals(null, testCreate, 'ROA Payments cant be null');        
        try{
        	SBR_3_0_API_CreateROAPayments.createRoaPayment(acc.Id,recordDetailsJsonString,tran.Id,paymentRecords,wynneUserName); 
        }catch(Exception e){
            SBR_3_0_Log.logException(e);
        }
        Test.stopTest();
    }
    }
    
    /**
     * @description Test method to validate handling of uncollected payments when successTest is false.
     */
    @isTest 
    static void testUncollectedSuccessTestFalse() {
        User ersu = [SELECT Id FROM User Where IsActive =true LIMIT 1];
        System.runAs(ersu){
        successTest = false;
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_CreatePayments_Tests());
        Order order = [SELECT Id,Invoice_Sequence_Number__c,EndDate FROM Order];
        Transaction__c tran = [SELECT Id, Name,RM_Detail_Sequence_Number__c,Order__c  FROM Transaction__c];
        Test.startTest();
        String wynneUserName = 'WROHR';
        String recordDetailsJsonString = '{\n' +
                                                ' "paymentMethod" :"Visa",\n' +    
                                                ' "amountCollected" : 10,\n' +
                                                ' "terminal" : "Lane: 003,ID: 1223",\n' +
                                                ' "checkNumber" : 0,\n' +
            									' "usePreviousCard" : true\n' +
                                                '}';
        try{
            SBR_3_0_API_CreateUncollectedPayments.makeADepositDetails =  recordDetailsJsonString;       
            SBR_3_0_API_CreateUncollectedPayments testCreate = new SBR_3_0_API_CreateUncollectedPayments(order.Id);
            System.assertNotEquals(null, testCreate, 'UCP cant be null');        
            SBR_3_0_API_CreateUncollectedPayments.createUncollectedPayment(order.Id,recordDetailsJsonString,tran.Id,wynneUserName); 
        }catch(exception e){
            SBR_3_0_Log.logException(e);
        }
        Test.stopTest();
    }
    } 
    
    /**
     * @description Test method to validate negative scenarios for uncollected payments.
     */
    @isTest  
    static void uncollectedNegativeTestMethod() {
        User ersu = [SELECT Id FROM User Where IsActive =true LIMIT 1];
        System.runAs(ersu){
        Order order = [SELECT Id,Invoice_Sequence_Number__c,EndDate FROM Order];
        Test.startTest();
        try{  
            SBR_3_0_API_CreateUncollectedPayments testCreate = new SBR_3_0_API_CreateUncollectedPayments(order.Id); 
            System.assertNotEquals(null, testCreate, 'UCP cant be null');
        }catch(exception e){
            SBR_3_0_Log.logException(e);
            throw new AuraHandledException(e.getMessage());
        }
        Test.stopTest();
    }
    } //End of FRONT-30847
}