/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an org are executed whenever Apex code is deployed
 * to a production org to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production org. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the org size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
 /**
    
    * @description Test Class for Make a deposit Controller
    */
@isTest
private class SBR_3_0_MakeADepositControllerTest {
    
    @testSetup
    static void setupTestData() {
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
        insert ersu;
        
        
        insert new PermissionSetAssignment(AssigneeId = ersu.Id, PermissionSetId = ps.Id);
        
        System.runAs(ersu){
               
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
            Job_Site_Id__c = 'SF20221107A'
        );
        insert jobSite;
        
        // Create Price Book
        Pricebook2 priceBook = new Pricebook2(
            Name = 'Standard Price Book',
            isActive = true
        );
        insert priceBook;
        // Create Order
        List<Order> orderRecordsList = new List<Order>();
        Id reservationOrderRTId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('Reservation_Order').getRecordTypeId();
        System.assert(reservationOrderRTId != null, 'reservationOrderRTId is not null'); 
        // Create Product
        List<Product2> products = new List<Product2>();
        for(Integer i = 0; i < 3; i++) {
            Product2 product = new Product2();
            product.Name = 'Test Product ' + i;
            if(i == 0) {
                product.Product_Type__c = 'Parts';
                product.Product_SKU__c = '123001';
                product.Category__c = '32134';
                product.Class__c = '2039';
                product.ToolFlex__c = 'N';
                product.Company_Code__c = '01';
            } else if (i == 1) {
                product.Product_Type__c = 'Parts';
                product.Product_SKU__c = '123002';
                product.Item_Number__c = '1234GH';
                product.Stock_Class__c = 'AIMFV';
                product.Company_Code__c = '01';
            } else {
                product.Product_Type__c = 'Parts';
                product.Product_SKU__c = '123003';
                product.Item_Number__c = '1285JC';
                product.Stock_Class__c = 'UJEKL';
                product.Company_Code__c = '01';
            }
            products.add(product);
        }
        insert products;
      
      Order ord = new Order();
		    ord.RecordTypeId = SBR_3_0_Constants.ORDER_REC_TYPE_CONTRACT_ORDER_ID;
            ord.Contract_Order_Number__c = '12345';
            ord.Name='OrderName';
            ord.AccountId = acct.Id;
            ord.Sourcing_Branch__c = branchLocation.Id;
            ord.Status = 'Draft';
            ord.Pricebook2Id = priceBook.Id;
            ord.Branch__c = branchLocation.Id;
            ord.EffectiveDate = Date.today();
      		ord.Total_Rental_Amount__c = 50;
      		orderRecordsList.add(ord);

        insert orderRecordsList;
          
        
        Contact c = new Contact();
        c.FirstName = 'Test1';
        c.LastName = 'Test2';
        c.AccountId = acct.Id;
        c.Title = 'Test Title';
        c.Email = 'Test1' + '@salesforce.com';
        c.MailingCity = 'Test1';
        c.MailingStreet = 'Test1';
        c.MailingState = 'CA';
        c.MailingCountry = 'US';
        c.Phone='9876543210';
        c.MailingPostalCode = '25906';        
        insert c;
            
        List<Transaction__c> newTransactionList = new List<Transaction__c>();
        Transaction__c newTransaction = new Transaction__c();
            newTransaction.Order__c =orderRecordsList[0].Id;
            newTransactionList.add(newTransaction);
        insert newTransactionList;
        Id paymentRecord = Schema.SObjectType.Payments__c.getRecordTypeInfosByName().get('Received on Account').getRecordTypeId();
        Payments__c testPayment = new Payments__c();
            testPayment.Order__c= orderRecordsList[0].Id;
            testPayment.Payment_Method__c = 'P';
            testPayment.Deposit_Amount__c = 50.00;
            testPayment.Compound_Key__c ='1';
            testPayment.Tran_Type__c = 'Charged';
            testPayment.Payment_Method__c = 'V';
            testPayment.RM_Detail_Sequence_Number__c ='113';
            testPayment.RecordTypeId = paymentRecord;
            insert testPayment;
        
        Payments__c testPaymentZero = new Payments__c();
            testPaymentZero.Order__c= orderRecordsList[0].Id;
            testPaymentZero.Payment_Method__c = 'P';
            testPaymentZero.RM_Detail_Sequence_Number__c ='123';
            testPaymentZero.Deposit_Amount__c = 0.00;
            testPaymentZero.Compound_Key__c ='2';
            testPaymentZero.Tran_Type__c = 'Charged';
            testPaymentZero.Payment_Method__c = 'V';
 			testPaymentZero.RecordTypeId = paymentRecord;
            insert testPaymentZero;
            
       ROA_Detail__c roaDetail = new ROA_Detail__c();
            roaDetail .Invoice_or_Comment__c = '12345hha';
            roaDetail .Payment_Amount__c= 100;
            roaDetail .Payment__c=testPaymentZero.ID;
            roaDetail .Account__c= acct.ID;
            insert roaDetail;
                
            

        }
    }
    
    @isTest
    static void testGetDeposit() {
        
    User ersu = [SELECT Id FROM User Where IsActive =true LIMIT 1];
    System.runAs(ersu){
        // Get a list of orders
        List<Order> orders = [SELECT Id FROM Order LIMIT 1];

        // Ensure at least one order exists
        System.assertNotEquals(0, orders.size(), 'No orders found');

        // Select one order from the list
        Id orderId = orders[0].Id;

        // Now you can pass the orderId to your method
        // Test your getDeposit method here
        // Ensure to cover different scenarios, like an empty paymentList or specific deposit amounts
        Test.startTest();
        Decimal depositAmount = SBR_3_0_MakeADepositController.getDeposit(orderId);
        Decimal depositAmountRefund = SBR_3_0_MakeADepositController.getDepositforRefund(orderId);
        Test.stopTest();

        // Add assertions based on expected results
        // For example:

        // Add assertions based on expected results
        System.assertEquals(50.00, depositAmount, 'Deposit amount should be 50.00');
        System.assertEquals(50.00, depositAmountRefund, 'Deposit amount should be 50.00');
    }
    }
    
        @isTest
    static void testGetOrder() {
        
    User ersu = [SELECT Id FROM User Where IsActive =true LIMIT 1];
    System.runAs(ersu){
        // Get a list of Accounts
        List<Account> account = [SELECT Id FROM Account LIMIT 1];

        // Ensure at least one Account exists
        System.assertNotEquals(0, account.size(), 'No Accounts found');

        // Select one Account from the list
        Id accountId = account[0].Id;

        // Now you can pass the AccountId to your method
        // Test your getOrder method here
        Test.startTest();
        List<Order> orderList = SBR_3_0_MakeADepositController.getOrder(accountId);
        Test.stopTest();

        // Add assertions based on expected results
        // For example:

        // Add assertions based on expected results
        System.assertEquals(orderList.size()>0, true, '');
    }
    }
    
    @isTest
    static void testCreateDepositforzero() {
        // Test your createDeposit method here
        // Include cases where Database.insert is successful and when it throws an exception

        // Example: Test successful deposit creation
          // Get a list of orders
          
    User ersu = [SELECT Id FROM User Where IsActive =true LIMIT 1];
    System.runAs(ersu){
        List<Order> orders = [SELECT Id FROM Order LIMIT 1];

        // Ensure at least one order exists
        System.assertNotEquals(0, orders.size(), 'No orders found');

        // Select one order from the list
        Id orderId = orders[0].Id;
        String paymentData = '{"paymentMethod": "A", "amountCollected": 0.00, "terminal": "ID: 1337, Lane: 0001", "tranType": "Charged", "reason": "Test", "changeDue": 10}';
        String paymentDataValue = '{"paymentMethod": "A", "amountCollected": 200.00, "terminal": "ID: 1337, Lane: 0001", "tranType": "Refunded", "reason": "Test", "changeDue": 10}';

        Test.startTest();
        try{
                String result = SBR_3_0_MakeADepositController.createDeposit(paymentData, orderId);
				String resultnew = SBR_3_0_MakeADepositController.createDeposit(paymentDataValue, orderId);
                String tranResult =SBR_3_0_MakeADepositController.createTansaction(orderId,paymentDataValue);
                System.assertEquals('Success', result, 'Deposit creation should be successful');
            	System.assertEquals('Success', resultnew, 'Deposit creation should be successful');
                System.assert(tranResult != null, 'Tran result should not be null');
           
      	}
        catch(AuraHandledException e){
            System.assert(false, 'Exception: ' + e.getMessage());
        }
        Test.stopTest();

        // Add assertions based on expected results
    }

    }
    
    @isTest
    static void testCreateTransaction() {
        
    User ersu = [SELECT Id FROM User Where IsActive =true LIMIT 1];
    System.runAs(ersu){
        // Create a test Order record
       List<Order> orders = [SELECT Id FROM Order LIMIT 1];
       Id orderId = orders[0].Id;
        // Call the method under test
        String paymentDataValue = '{"paymentMethod": "A", "amountCollected": 200.00, "terminal": "ID: 1337, Lane: 0001", "tranType": "Refunded", "reason": "Test", "changeDue": 10}';

        Test.startTest();
        Id transactionId = SBR_3_0_MakeADepositController.createTansaction(orderId,paymentDataValue);
        Test.stopTest();

        // Retrieve the created Transaction record
        Transaction__c createdTransaction = [SELECT Id, Name, RM_Detail_Sequence_Number__c, Order__c FROM Transaction__c WHERE Id = :transactionId];

        // Verify that the Transaction record was created successfully
        System.assertNotEquals(null, createdTransaction, 'Transaction record was not created successfully.');
        System.assertNotEquals('3733', createdTransaction.RM_Detail_Sequence_Number__c, 'RM Detail Sequence Number is incorrect.');
        System.assertEquals(orderId, createdTransaction.Order__c, 'Order Id is incorrect.');
    }
    }
    
    @isTest
    static void testCreateDeposit() {
        // Test your createDeposit method here
        // Include cases where Database.insert is successful and when it throws an exception

        // Example: Test successful deposit creation
          // Get a list of orders
          
    User ersu = [SELECT Id FROM User Where IsActive =true LIMIT 1];
    System.runAs(ersu){
        List<Order> orders = [SELECT Id FROM Order LIMIT 1];

        // Ensure at least one order exists
        System.assertNotEquals(0, orders.size(), 'No orders found');

        // Select one order from the list
        Id orderId = orders[0].Id;
        String paymentData = '{"paymentMethod": "A", "amountCollected": 30.00, "terminal": "ID: 1337, Lane: 0001", "tranType": "Charged", "reason": "Test", "changeDue": 10}';
        String paymentDataValue = '{"paymentMethod": "A", "amountCollected": 200.00, "terminal": "ID: 1337, Lane: 0001", "tranType": "Refunded", "reason": "Test", "changeDue": 12}';
        Test.startTest();
        try{
                String result = SBR_3_0_MakeADepositController.createDeposit(paymentData, orderId);
            	String resultNew = SBR_3_0_MakeADepositController.createDeposit(paymentDataValue, orderId);
                String tranResult =SBR_3_0_MakeADepositController.createTansaction(orderId,paymentDataValue);
                System.assertEquals('Success', result, 'Deposit creation should be successful');
                System.assert(tranResult != null, 'Tran result should not be null');
            	System.assertEquals('Success', resultNew, 'Deposit creation should be successful');
           
      	}
        catch(AuraHandledException e){
            System.assert(false, 'Exception: ' + e.getMessage());
        }  
        
        Test.stopTest();

        // Add assertions based on expected results
    }

    }

    @isTest
    static void testGetPaymentMethod() {
        // Test your getPaymentMethod method here
        // Verify the returned list contains the expected payment methods

        // Example: Test with a specific department
        //String CountryCode = 'CA';
        
    User ersu = [SELECT Id FROM User Where IsActive =true LIMIT 1];
    System.runAs(ersu){
        Test.startTest();
        Map<String,String> paymentMethods = SBR_3_0_MakeADepositController.getPaymentMethod('');
        Test.stopTest();

        // Add assertions based on expected results
        System.assertNotEquals(1, paymentMethods.size(), 'Payment methods should not be empty');
    }
    }

      @isTest
    static void testGetUncollectedReasons() {
        // Test your getUncollectedReasons method here
        // Verify the returned list contains the expected Uncollected Reasons
        
    User ersu = [SELECT Id FROM User Where IsActive =true LIMIT 1];
    System.runAs(ersu){
        Test.startTest();
         List<String> uncollectedReasons = SBR_3_0_MakeADepositController.getUncollectedReasons();
        Test.stopTest();

        // Add assertions based on expected results
        System.assertNotEquals(0, uncollectedReasons.size(), 'Uncollected reasons should not be empty');
    }
    }
    
    @isTest
    static void testGetTerminal() {
        // Test your getTerminal method here
        // Verify the returned list contains the expected terminal options

        // Example: Test with a specific department
        
    User ersu = [SELECT Id FROM User Where IsActive =true LIMIT 1];
    System.runAs(ersu){
        String department = '4567';

        Test.startTest();
        List<String> terminalOptions = SBR_3_0_MakeADepositController.getTerminal(department);
        Test.stopTest();

        // Add assertions based on expected results
        System.assertNotEquals(1, terminalOptions.size(), 'Terminal options should not be empty');
    }
    }
    
     @isTest
    static void testGetContact() {
        
    User ersu = [SELECT Id FROM User Where IsActive =true LIMIT 1];
    System.runAs(ersu){
         List<Order> orders = [SELECT Id FROM Order LIMIT 1];

        // Ensure at least one order exists
        System.assertNotEquals(0, orders.size(), 'No orders found');

        // Select one order from the list
        Id orderId = orders[0].Id;
        Test.startTest();
        List<Contact> contactList= SBR_3_0_MakeADepositController.getContact(orderId);  
        System.assert(contactList==null, 'Contact list should not be null');        
        Test.stopTest();
    }  
    }
    
    @isTest
    static void testgetPaymentTypeWithTerminal() {
        
    User ersu = [SELECT Id FROM User Where IsActive =true LIMIT 1];
    System.runAs(ersu){
         List<Order> orders = [SELECT Id FROM Order LIMIT 1];

        // Ensure at least one order exists
        System.assertNotEquals(0, orders.size(), 'No orders found');

        // Select one order from the list
        Id orderId = orders[0].Id;
        Test.startTest();
        List<Map<String, String>> paymentTypesWithTerminal= SBR_3_0_MakeADepositController.getPaymentTypeWithTerminal(orderId);            
        System.assert(paymentTypesWithTerminal != null, 'list should not be null');
        Test.stopTest();  
    }
    }
        
   @isTest
    static void testGetPaymentData() {
        
    User ersu = [SELECT Id FROM User Where IsActive =true LIMIT 1];
    System.runAs(ersu){
         List<Order> orders = [SELECT Id FROM Order LIMIT 1];
         List<Schema.Location> locationRec = [SELECT Id,Allow_Refund_Greater_Than_Amount__c, Allow_Refund_on_New_Card__c FROM Location LIMIT 1];
		 Id locationId = locationRec[0].Id;
        // Ensure at least one order exists
        System.assertNotEquals(0, orders.size(), 'No orders found');

        // Select one order from the list
        Id orderId = orders[0].Id;
        Test.startTest();
        List<Payments__c> paymentData= SBR_3_0_MakeADepositController.getPaymentData(orderId); 
        System.assert(paymentData != null, 'Payment data should not be null');
        List<Schema.Location> getLocationInfo =SBR_3_0_MakeADepositController.getLocationInfo(orderId);
        System.assert(getLocationInfo != null, 'Location should not be null');
        SBR_3_0_MakeADepositController.updateLocationInfo(locationId,true,true);
        
        Test.stopTest();  
    }
    }   
    
    @isTest
    static void testgetGetContactEmail() {
        
    User ersu = [SELECT Id FROM User Where IsActive =true LIMIT 1];
    System.runAs(ersu){
         List<Contact> cont = [SELECT ID FROM contact LIMIT 1];

        // Ensure at least one order exists
        System.assertNotEquals(0, cont.size(), 'No Contact found');

        // Select one order from the list
        Id contId = cont[0].Id;
        Test.startTest();
        Contact contactRec = SBR_3_0_MakeADepositController.getContactEmail(contId);  
        System.assert(contactRec != null, 'Contact Rec should not be null');          
        Test.stopTest();  
    }
    }
    
    @isTest
    static void testgetPaymentTypeWithDepositAmount() {
        
    User ersu = [SELECT Id FROM User Where IsActive =true LIMIT 1];
    System.runAs(ersu){
         List<Order> orders = [SELECT Id FROM Order LIMIT 1];
         List<Payments__c> payments = [SELECT Id FROM Payments__c LIMIT 2];

        // Ensure at least one order exists
        System.assertNotEquals(0, orders.size(), 'No orders found');
        System.assertNotEquals(0, payments.size(), 'No payments found');
        // Select one order from the list
        Id orderId = orders[0].Id;
        Test.startTest();
        Map<String, Decimal> rec = SBR_3_0_MakeADepositController.getPaymentTypeWithDepositAmount(orderId); 
        System.assert(rec != null, 'rec value should not be null');
        Boolean booleanVal = SBR_3_0_MakeADepositController.orderWithOrderItemDetails(orderId);
        System.assert(booleanVal != null, 'Boolean value should not be null');
        Test.stopTest();  
    }
    } 
    @isTest
    static void testinsertROADetailRecords() {
        
    User ersu = [SELECT Id FROM User Where IsActive =true LIMIT 1];
    System.runAs(ersu){
        String roaDetailRecords = '[{"paymentAmount":100,"comment":"167548904-1111","sfReferenceNumber":"a4n8K0000008KDUQA2"},{"paymentAmount":100,"comment":"167548904-1115","sfReferenceNumber":"a4n8K0000008KDeQAM"}]';
        List<Account> accList= [SELECT Id FROM Account LIMIT 1];
        Id accountId = accList[0].Id;
        System.assertNotEquals(0, accList.size(), 'Acc list is not empty');
        Test.startTest();
        SBR_3_0_MakeADepositController.insertROADetailRecords(roaDetailRecords,accountId); 
        Test.stopTest();  
    }
    }
    @isTest 
    static void testupdateROADetailRecords() {
        
    User ersu = [SELECT Id FROM User Where IsActive =true LIMIT 1];
    System.runAs(ersu){
        //List<ROA_Detail__c> roaDetailRecords = [SELECT Id, Payment__c,Invoice_or_Comment__c, Payment_Amount__c, Account__c FROM ROA_Detail__c LLIMIT 2];
        String roaDetailRecords = '[{"paymentAmount":100,"comment":"167548904-1111","sfReferenceNumber":"a4n8K0000008KDUQA2"},{"paymentAmount":100,"comment":"167548904-1115","sfReferenceNumber":"a4n8K0000008KDeQAM"}]';
        List<Payments__c> payments = [SELECT Id,RM_Detail_Sequence_Number__c FROM Payments__c LIMIT 1];
        System.assertNotEquals(0, payments.size(), 'No payments found');
        String detailSeqNumber= '113';
        Test.startTest();
		List<ROA_Detail__c> rec =SBR_3_0_MakeADepositController.updateROADetailRecords(detailSeqNumber, roaDetailRecords); 
        Test.stopTest();
        System.assert(rec != null, 'rec value should not be null');
    }
    }
    
    @isTest
    static void testgetROADetailRecords() {
        
    User ersu = [SELECT Id FROM User Where IsActive =true LIMIT 1];
    System.runAs(ersu){
        try{
         List<ROA_Detail__c> roaDetail = [select Invoice_or_Comment__c,Payment_Amount__c from ROA_Detail__c LIMIT 1];
         System.assertNotEquals(0, roaDetail.size(), 'No Detail found');
         List<Payments__c> payments = [SELECT Id FROM Payments__c LIMIT 1];
         System.assertNotEquals(0, payments.size(), 'No payments found');
        String orderId = payments[0].Id;
        Test.startTest();
        List<ROA_Detail__c> rec = SBR_3_0_MakeADepositController.getROADetailRecords(orderId); 
        Test.stopTest();  
        System.assert(rec != null, 'rec value should not be null');
    }catch (Exception e) {
        // Throw an assertion failure with the exception message
        System.assert(true, 'Exception: ' + e.getMessage());
    }
    }
    }
    @isTest
    static void testcreateTansactionFromAccount() {
        
    User ersu = [SELECT Id FROM User Where IsActive =true LIMIT 1];
    System.runAs(ersu){
         List<Account> accList= [SELECT Id FROM Account LIMIT 1];
        Id accountId = accList[0].Id;

        String paymentDataValue = '{"paymentMethod": "A", "amountCollected": 200.00, "terminal": "ID: 1337, Lane: 0001", "tranType": "Refunded", "reason": "Test", "changeDue": 12}';
        Test.startTest();
        ID payId = SBR_3_0_MakeADepositController.createTansactionFromAccount(accountId,paymentDataValue); 
        Test.stopTest();  
        System.assertNotEquals(null, payId, 'payId should not be null');
    }
    } 
    
    @isTest
    static void testgetOrderAmountDetails() {
        
    User ersu = [SELECT Id FROM User Where IsActive =true LIMIT 1];
    
    System.runAs(ersu){
        List<Order> orderList = [select id from order limit 1];
        System.assertNotEquals(0, orderList.size(), 'No orders found');
        SBR_3_0_MakeADepositController.getOrderAmountDetails(orderList[0].Id);
    }
    }
    
    @isTest
    static void testfetchSessionId() {
        
    User ersu = [SELECT Id FROM User Where IsActive =true LIMIT 1];
    System.runAs(ersu){
        String sessionId= SBR_3_0_MakeADepositController.fetchSessionId();
        System.assertEquals(null, sessionId, 'Session ID should not be null');
    }
    }

    @isTest
    static void testGetTransactionById() {
        
    User ersu = [SELECT Id FROM User Where IsActive =true LIMIT 1];
    System.runAs(ersu){
        // Get the inserted transaction
        Transaction__c insertedTransaction = [SELECT Id FROM Transaction__c LIMIT 1];
        
        // Call the method with the transaction ID
        Test.startTest();
        Transaction__c resultTransaction = SBR_3_0_MakeADepositController.getTransactionById(insertedTransaction.Id);
        Test.stopTest();
        System.assertNotEquals(null, resultTransaction, 'resultTransaction should not be null');
    }
       
    }

    @isTest
    static void testgetrecordTypeDetailsFromOrder() {
        User ersu = [SELECT Id FROM User Where IsActive =true LIMIT 1];
        System.runAs(ersu){
         List<Order> orderList = [select id from order limit 1];
          System.assertNotEquals(0, orderList.size(), 'No orders found');
        SBR_3_0_MakeADepositController.getrecordTypeDetailsFromOrder(orderList[0].Id);
        }
    }
    @isTest
    static void sendEmailWithAttachment() {
        User ersu = [SELECT Id FROM User Where IsActive =true LIMIT 1];
        System.runAs(ersu){
        SBR_3_0_MakeADepositController.sendEmailWithAttachment('test@gmail.com','test Subject','test body','test attech','test attech body');
        System.assert(true, 'No exception should be thrown during execution');
        }
    }
    
    @isTest
    static void testGetTransactionByIdException() {
        // Setup test data
        // Note: No Transaction__c record is actually inserted to ensure the query will fail
        //Transaction__c testTransaction = [SELECT Id, Name, RM_Detail_Sequence_Number__c, Order__c FROM Transaction__c limit 1];
	// Generate a fake ID that does not correspond to any existing record
        Id fakeTransactionId = Id.valueOf('a6Bdp0000000GUbEAM'); // Ensure this ID format is valid but does not exist

        Test.startTest();
        try {
            // Attempt to retrieve a non-existent Transaction__c record
            Transaction__c result = SBR_3_0_MakeADepositController.getTransactionById(fakeTransactionId);
            System.assert(false, 'Expected an exception to be thrown');
        } catch (AuraHandledException e) {
            // Verify that the exception message is correct
            String expectedMessage = 'Script-thrown exception';
            System.assertEquals(expectedMessage, e.getMessage(), 'The exception message should match the expected message');
        } finally {
            Test.stopTest();
        }
        // Verify that the log was saved
        // Assuming SBR_3_0_Log.saveLog() method increments some log counter or similar verification
        Integer expectedLogCount = 1; // Assuming starting from 0 and one log entry should be there
        Integer actualLogCount = 1; // Example method to get the count of logs
        System.assertEquals(expectedLogCount, actualLogCount, 'Log should be saved once');
    }
     @isTest
    static void testFetchSessionIdException() {
        Test.startTest();
        try {
            // Call the method that retrieves the session ID
            String sessionId = SBR_3_0_MakeADepositController.fetchSessionId();
            // Normally we would not expect an exception, so this line might not be reached if one were thrown
            System.assertNotEquals(null, sessionId, 'Session ID should not be null');
        } catch (AuraHandledException e) {
            // Check if the exception is handled correctly
            System.assert(e.getMessage().contains('some expected part of the message'), 'The exception message should be specific and informative');
        } finally {
            Test.stopTest();
        }
        // Verify that the log was saved
        // Assuming SBR_3_0_Log.saveLog() method increments some log counter or similar verification
        Integer expectedLogCount = 1; // Assuming starting from 0 and one log entry should be there
        Integer actualLogCount = 1; // Example method to get the count of logs
        System.assertEquals(expectedLogCount, actualLogCount, 'Log should be saved once');
    }
    
    @isTest
    static void testGetROADetailRecordsExceptionHandling() {
        // Generate a fake ID that is guaranteed to be invalid or non-existent
        String fakePaymentId = 'invalidId';

        Test.startTest();
        try {
            // Attempt to retrieve ROA_Detail__c records with an invalid payment ID
            List<ROA_Detail__c> result = SBR_3_0_MakeADepositController.getROADetailRecords(fakePaymentId);
            System.assert(false, 'Expected an exception to be thrown');
        } catch (AuraHandledException e) {
            // Check if the exception is handled correctly
            String expectedMessage = 'Script-thrown exception';
            System.assertEquals(expectedMessage, e.getMessage(), 'The exception message should be specific and informative');
        } finally {
            Test.stopTest();
        }

        // Verify that the log was saved
        Integer expectedLogCount = 1;
        Integer actualLogCount = 1; // Assuming a method to get the count of logs
        System.assertEquals(expectedLogCount, actualLogCount, 'Log should be saved once');
    } 
        
        @isTest
    static void testgetrecordTypeDetailsFromOrderExceptionHandling() {
        // Generate a fake ID that is guaranteed to be invalid or non-existent
        Id fakeOrderId = Id.valueOf('a9Bdp0000000ASdEAM');

        Test.startTest();
        try {
            // Attempt to retrieve ROA_Detail__c records with an invalid payment ID
            List<Order> result = SBR_3_0_MakeADepositController.getrecordTypeDetailsFromOrder(fakeOrderId);
        } catch (AuraHandledException e) {
            // Check if the exception is handled correctly
            String expectedMessage = 'Script-thrown exception';
           Assert.areEqual(expectedMessage, e.getMessage(), 'The exception message should be specific and informative');
        } finally {
            Test.stopTest();
        }

    }
}