@isTest
public with sharing class SBR_3_0_ROAPaymentControllerTest {
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
        ersu.IsActive =true;
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


        Payments__c testPayment = new Payments__c();
            testPayment.Order__c= orderRecordsList[0].Id;
            testPayment.Payment_Method__c = 'C';
            testPayment.Deposit_Amount__c = 50.00;
            testPayment.Tran_Type__c = 'Charged';
            testPayment.Invoice_or_Comment__c = '198768545-9875';
            testPayment.Account__c=acct.Id;
            insert testPayment;
        
        Payments__c testPaymentZero = new Payments__c();
            testPaymentZero.Order__c= orderRecordsList[0].Id;
            testPaymentZero.Payment_Method__c = 'C';
            testPaymentZero.Deposit_Amount__c = 0.00;
            testPaymentZero.Tran_Type__c = 'Charged';
            testPayment.Invoice_or_Comment__c = '198768545-9876';
            testPayment.Account__c=acct.Id;
            insert testPaymentZero;
        }
    }

    @isTest
static void testGetPayments() {

    User ersu = [SELECT Id FROM User Where IsActive =true LIMIT 1];
    System.runAs(ersu){
    // Retrieve an Order with its associated Account
    List<Order> orders = [SELECT Id, AccountId FROM Order LIMIT 1];
    System.assertNotEquals(0, orders.size(), 'No orders found');

    // Select one order from the list
    Order testOrder = orders[0];

    Test.startTest();
    // Pass the Account Id associated with the Order
    List<Payments__c> paymentData = SBR_3_0_ROAPaymentController.getPayments(testOrder.AccountId); 
    Test.stopTest(); 

    // Assert that the returned list is not null
    System.assertNotEquals(null, paymentData, 'List of payments should not be null');

    // Assert that the returned list contains the expected number of Payments records
    System.assertEquals(1, paymentData.size(), 'Number of payments returned');
    }

    // Additional assertions can be added here to verify the correctness of the returned data
}
}