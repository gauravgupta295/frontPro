@isTest
public with sharing class SBR_3_0_OrderPdfController_Test Implements HttpCalloutMock {
    static Boolean isSuccessTest = true;
    private static final String RESERVTION_RECORD_TYPE = 'Reservation Order';
    private static final String CONTRACT_RECORD_TYPE ='Contract Order';

    public static final String RESERVATION_RT_ID = Schema.getGlobalDescribe().get('Order').getDescribe().getRecordTypeInfosByName().get(RESERVTION_RECORD_TYPE).getRecordTypeId();
    public static final String CONTRACT_RT_ID = Schema.getGlobalDescribe().get('Order').getDescribe().getRecordTypeInfosByName().get(CONTRACT_RECORD_TYPE).getRecordTypeId();

    public HttpResponse respond(HTTPRequest req) {
        // Create a fake response
        SBR_3_0_ResContrctOrderPdfController.WrappedResponse wrapperResp = new SBR_3_0_ResContrctOrderPdfController.WrappedResponse();
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type','application/octet-stream');
        res.setHeader('companyId', '1');
        
        if(req.getEndpoint().endsWithIgnoreCase('token')){
            res.setBody('{"access_token":"test"}');
        }else {
            res.setBody('{"example":"test"}');
        }
        if(isSuccessTest) {
            res.setStatusCode(200);
        }
        else {
            res.setStatusCode(400);
        }
        return res;
    }
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
        List<Order> orders =  new List<Order>();
        Order contractOrder = new Order(
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
            Contract_Order_Number__c = '1234',
            Reservation_Order_Number__c = '1234' ,
            Rentalman_Quote_Id__c = '13232',
            RecordTypeId = CONTRACT_RT_ID
        );
        orders.add(contractOrder);
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
            RecordTypeId = RESERVATION_RT_ID
        );
        orders.add(reservationOrder);
        // Create Quote
        SBQQ__Quote__c ordQuote = new SBQQ__Quote__c(
            Quote_Name__c = 'Test Quote',
            SBQQ__Account__c = acct.Id,
            Jobsite__c = jobSite.Id,
            SBQQ__DeliveryMethod__c = 'Delivery',
            Start_Date__c = date.valueOf('2022-10-07 12:00:00'),
            End_Date__c = date.valueOf('2022-10-07 12:00:00'),
            Opt_Out_RPP__c = false,
            Opt_Out_Fuel_Charge__c = false,
            Selling_Channel__c = 'SBRB2B',
            Rentalman_Quote_Id__c = '1323',
            Company_Code__c = '01',
            Show_Crew_Expense_Calculator__c = true,
            Branch__c = branchLocation.Id
        );
        insert ordQuote; 
        Order quoteOrder = new Order(
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
            Rentalman_Quote_Id__c = '1323'
        );
        orders.add(quoteOrder);
        insert orders;
        // Create Approval Rule
        sbaa__ApprovalRule__c approvalRule = new sbaa__ApprovalRule__c();
        approvalRule.Name = 'Test Level 1';
        approvalRule.sbaa__TargetObject__c = 'SBQQ__Quote__c';
        approvalRule.sbaa__ApprovalStep__c = 1;
        insert approvalRule;
        // Create Approval User
        Profile oProfile = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User apprUser = SBR_3_0_TestDataFactory.createUser(TRUE,oProfile);
        // Create Approval
        List<sbaa__Approval__c> approvals = new List<sbaa__Approval__c>();
        for (Integer i = 1; i < 3; i++) {
            sbaa__Approval__c approval = new sbaa__Approval__c();
            approval.sbaa__Status__c = 'Requested';
            approval.sbaa__AssignedTo__c = apprUser.Id;
            approval.sbaa__ApprovalStep__c = 1;
            approval.sbaa__RecordField__c = 'Quote__c';
            approval.sbaa__Rule__c = approvalRule.Id;
            approval.Quote__c  = ordQuote.Id;
            approval.sbaa__CommentsLong__c = 'TEST';
            approvals.add(approval);
        }
        insert approvals;
    }

    @isTest static void loadOrderFieldsTest(){
        
        Order contractOrder = [SELECT Id, Reservation_Order_Number__c,RecordTypeId,Contract_Order_Number__c, OrderNumber,RM_Account_Number__c,Company_Code__c,Rentalman_Quote_Id__c  from Order WHERE RecordTypeId=:CONTRACT_RT_ID LIMIT 1];
        Order reservationOrder = [SELECT Id, Reservation_Order_Number__c,RecordTypeId,Contract_Order_Number__c, OrderNumber,RM_Account_Number__c,Company_Code__c,Rentalman_Quote_Id__c  from Order WHERE RecordTypeId=:RESERVATION_RT_ID LIMIT 1];
        Order quoteOrder = [SELECT Id, Reservation_Order_Number__c,RecordTypeId,Contract_Order_Number__c, OrderNumber,RM_Account_Number__c,Company_Code__c,Rentalman_Quote_Id__c  from Order WHERE Rentalman_Quote_Id__c = '1323' LIMIT 1];
        System.debug('quoteOrder->'+quoteOrder);
        Exception e = null;
        SBR_3_0_ResContrctOrderPdfController.OrderWrapper contractOrderWrap;
        SBR_3_0_ResContrctOrderPdfController.OrderWrapper reservationOrderWrap;
        SBR_3_0_ResContrctOrderPdfController.OrderWrapper quoteOrderWrap;

        Assert.isNotNull(contractOrder);
        Assert.isNotNull(reservationOrder);
        Assert.isNotNull(quoteOrder);

        Test.startTest();
            try{
                contractOrderWrap = SBR_3_0_ResContrctOrderPdfController.loadOrderFields(contractOrder.Id);
                reservationOrderWrap = SBR_3_0_ResContrctOrderPdfController.loadOrderFields(reservationOrder.Id);
                quoteOrderWrap = SBR_3_0_ResContrctOrderPdfController.loadOrderFields(quoteOrder.Id);
                System.debug('quoteOrderWrap->'+quoteOrderWrap);
            }
            catch(Exception ex) {
                e = ex;
            }
        Test.stopTest(); 

        Assert.isNotNull(contractOrderWrap);
        Assert.areEqual(contractOrder.OrderNumber, contractOrderWrap.OrderNumber);

        Assert.isNotNull(reservationOrderWrap);
        Assert.areEqual(reservationOrder.OrderNumber, reservationOrderWrap.OrderNumber);

        Assert.isNotNull(quoteOrderWrap);
        Assert.areEqual(quoteOrder.OrderNumber, quoteOrderWrap.OrderNumber); 

    }

    @isTest static void loadOrderFieldsNullTest(){
        
        Exception e = null;
        SBR_3_0_ResContrctOrderPdfController.OrderWrapper OrderWrap;
       
        Test.startTest();
            try{
                OrderWrap = SBR_3_0_ResContrctOrderPdfController.loadOrderFields('12341234');
                System.debug('OrderWrap->'+OrderWrap);
            }
            catch(Exception ex) {
                e = ex;
            }
        Test.stopTest(); 
        Assert.isNull(OrderWrap);
    }

    @isTest static void buildRequestTest(){
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_OrderPdfController_Test());

        SBR_3_0_ResContrctOrderPdfController.WrappedResponse res = new SBR_3_0_ResContrctOrderPdfController.WrappedResponse();
        
        String rmId = '65287816';
      
        Test.startTest();
            res = SBR_3_0_ResContrctOrderPdfController.buildRequest(rmId,'','1');
        Test.stopTest();
        Assert.isNotNull(res);
        Assert.isNotNull(res.status);
    }
    
    
}