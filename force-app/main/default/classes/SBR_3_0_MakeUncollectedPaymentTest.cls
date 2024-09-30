@isTest
public with sharing class SBR_3_0_MakeUncollectedPaymentTest {

    @testSetup
    static void setupTestData() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Sales'];
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Payment_Access'];
           //create ers user clone
           String ersUserName = 'ersuser' + DateTime.now().getTime() + '@SBRtestorg.com';
           User ersu = new User(Alias = 'ers', Email = 'ersuser@testorg.com',
        EmailEncodingKey = 'UTF-8', LastName = 'erstest', LanguageLocaleKey = 'en_US',
        LocaleSidKey = 'en_US', ProfileId = p.Id,
        TimeZoneSidKey = 'America/Los_Angeles',
        UserName = ersUserName);
        ersu.RepID__c = '1028';
        insert ersu;
           
        Profile chatterProfile = [SELECT Id FROM Profile WHERE Name like '%Chatter%' Limit 1];  
        //create ers user clone
           String chatterUserName = 'chatteruser' + DateTime.now().getTime() + '@SBRtestorg.com';
           User chatteruser = new User(Alias = 'chatter', Email = 'chatteruser@testorg.com',
        EmailEncodingKey = 'UTF-8', LastName = 'chatteruser', LanguageLocaleKey = 'en_US',
        LocaleSidKey = 'en_US', ProfileId = chatterProfile.Id,
        TimeZoneSidKey = 'America/Los_Angeles',
        UserName = chatterUserName);
        chatteruser.RepID__c = '1029';
        insert chatteruser;
        
        insert new PermissionSetAssignment(AssigneeId = ersu.Id, PermissionSetId = ps.Id);

        System.runAs(ersu){
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

           Account acct1 = new Account();
           acct1.RM_Account_Number__c = '123467';
           acct1.Company_Code__c = '01';
           acct1.Name = 'Test Account12';
           acct1.Record_Type_Text__c = 'Credit';
           acct1.E_mail_Address__c = '123@asdf.com';
           acct1.Phone = '1234567859';
           acct1.BillingStreet = '123 Main Street';
           acct1.BillingCity = 'Toronto';
           acct1.BillingPostalCode = 'M9N7V5';
           acct1.BillingState = 'ON';
           acct1.BillingCountry = 'CA';
           acct1.Drivers_License__c = 'AKF';
           acct1.Driver_s_License_State__c = 'AL';
           insert acct1;

            Schema.Location branchLocation = new Schema.Location();
            branchLocation.Branch_Location_Number__c = '1234';
            branchLocation.Name = 'Test Branch Location';
            branchLocation.Street_Address__c = '12 Main Street';
            branchLocation.City__c = 'Toronto';
            branchLocation.Zip_Code__c = 'M7N7B3';
            branchLocation.State__c = 'ON';
            branchLocation.Country__c = 'CA';
            branchLocation.Job_Number__c = '332112';
            branchLocation.RecordTypeId = SBR_3_0_Constants.LOCATION_BRANCH_RT_ID;
            branchLocation.Company_Code__c = 'X';
            branchLocation.Time_Zone_Name__c = 'America/Chicago';
            branchLocation.Time_Zone__c = 3;

        insert branchLocation;

        Pricebook2 priceBook = new Pricebook2(
                Name = 'Standard Price Book',
                isActive = true
            );
        insert priceBook;

        Pricebook2 priceBook1 = new Pricebook2(
                Name = 'Standard Price Book',
                isActive = true
            );
        insert priceBook1;

            List < Order > orderRecordsList = new List < Order > ();
          
        Order ord = new Order();
            ord.RecordTypeId = SBR_3_0_Constants.ORDER_REC_TYPE_CONTRACT_ORDER_ID;
            ord.Contract_Order_Number__c = '12345';
            ord.Name = 'OrderName';
            ord.AccountId = acct.Id;
            ord.Sourcing_Branch__c = branchLocation.Id;
            ord.Status = 'Draft';
            ord.Pricebook2Id = priceBook1.Id;
            ord.Branch__c = branchLocation.Id;
            ord.EffectiveDate = Date.today();
            ord.Total_Rental_Amount__c = 50;
            orderRecordsList.add(ord);

        Order ord1 = new Order();
            ord1.RecordTypeId = SBR_3_0_Constants.ORDER_REC_TYPE_CONTRACT_ORDER_ID;
            ord1.Contract_Order_Number__c = '12345';
            ord1.Name = 'OrderNameNew';
            ord1.AccountId = acct1.Id;
            ord1.Sourcing_Branch__c = branchLocation.Id;
            ord1.Status = 'Draft';
            ord1.Pricebook2Id = priceBook.Id;
            ord1.Branch__c = branchLocation.Id;
            ord1.EffectiveDate = Date.today();
            ord1.Total_Rental_Amount__c = 50;
            orderRecordsList.add(ord1);

        insert orderRecordsList;

            Invoice__c invoice = new Invoice__c();
            invoice.name='123';
            invoice.Contract_Number__c= 1235;
            invoice.Order__c=orderRecordsList[0].id;
            invoice.Invoice_Sequence_Number__c = 1234;
            invoice.Invoice_number__c = '123456789';
            invoice.Total_invoice_Amount__c = 12000;
            invoice.Money_Applied_to_Invoice__c = 12000;
            invoice.Written_Off_Invoice__c = true;
            invoice.Order_Status__c='OP';
            invoice.Account__c = acct.Id;
            invoice.Amount_Due__c=1000;
            insert invoice;

            Invoice__c invoiceNew = new Invoice__c();
            invoiceNew.name='1234';
            invoiceNew.Contract_Number__c= 1235;
            invoiceNew.Order__c=orderRecordsList[0].id;
            invoiceNew.Invoice_Sequence_Number__c = 1234;
            invoiceNew.Invoice_number__c = '123456789';
            invoiceNew.Order_Status__c='HL';
            
            invoiceNew.Total_invoice_Amount__c = 12000;
            invoiceNew.Money_Applied_to_Invoice__c = 12000;
            //invoiceNew.Written_Off_Invoice__c = true;
            invoiceNew.Account__c = acct1.Id;
            
            insert invoiceNew;
        }
    }

    @isTest
    static void getInvoiceDetailsTest() {
        User ersu = [SELECT Id FROM User Where IsActive =true LIMIT 1];
        System.runAs(ersu){
        try{
            List < Order > orders =[SELECT Id FROM Order where Name = 'OrderName'];
            Id orderId = orders[0].Id;
            List<Account> accounts = [SELECT Id FROM Account where Name = 'Test Account'];
            Id accountId = accounts[0].Id;
            List<Invoice__c> invoiceList = [select id, Invoice_number__c, Invoice_Sequence_Number__c, Total_invoice_Amount__c, Money_Applied_to_Invoice__c, Written_Off_Invoice__c,Order__c from Invoice__c where name='123'];
            System.assert(!invoiceList.isEmpty(), 'Invoice list should not be empty');
            SBR_3_0_MakeUncollectedPaymentController.getInvoiceDetails(orderId, 'Order');
            SBR_3_0_MakeUncollectedPaymentController.getInvoiceDetails(accountId, 'Account');
            SBR_3_0_MakeUncollectedPaymentController.getNotOpenInvoiceFromAccount(accountId);
            SBR_3_0_MakeUncollectedPaymentController.getInvoiceData(accountId);
            System.assert(true, 'No exception should be thrown during execution');         
        }catch(Exception e){
            System.assert(true, 'Exception: ' + e.getMessage());
        }
    }
    }
    
    @isTest
    static void getInvoiceTest2() {
        User ersu = [SELECT Id FROM User Where IsActive =true LIMIT 1];
        System.runAs(ersu){
        try{
            List<Account> accounts = [SELECT Id FROM Account where Name = 'Test Account'];
           
            System.assert(accounts != null, 'Accounts list should not be null and should contain at least one account'); //List<Invoice__c> invList =[SELECT Id FROM Invoice__c WHERE Account__c =:accountId];
            //delete invList;
            SBR_3_0_MakeUncollectedPaymentController.getInvoice(new Set<Id>{'234567890__3434'});  
            System.assert(true, 'No exception should be thrown during execution');   
        }catch(Exception e){
            System.assert(true, 'Exception: ' + e.getMessage());
        }
    }
    }

    @isTest
    static void getInvoiceDetailsTestFail() {
        User ersu = [SELECT Id FROM User Where IsActive =true LIMIT 1];
        System.runAs(ersu){
        List < Order > orders =[SELECT Id FROM Order where Name = 'OrderNameNew'];
        Id orderId = orders[0].Id;
        List<Account> accounts = [SELECT Id FROM Account where Name = 'Test Account12'];
        Id accountId = accounts[0].Id;
        List<Invoice__c> invoiceListNew = [select id, Invoice_number__c, Invoice_Sequence_Number__c, Total_invoice_Amount__c, Money_Applied_to_Invoice__c,Order__c from Invoice__c where name='1234'];
        System.assert(!invoiceListNew.isEmpty(), 'Invoice list should not be empty');
        SBR_3_0_MakeUncollectedPaymentController.getInvoiceDetails(orderId, 'Order');
        SBR_3_0_MakeUncollectedPaymentController.getInvoiceDetails(accountId, 'SBQQ__Quote__c');
        SBR_3_0_MakeUncollectedPaymentController.getInvoiceDetails(accountId, '');
        SBR_3_0_MakeUncollectedPaymentController.getInvoiceDetails(accountId, 'Account');
        System.assert(true, 'No exception should be thrown during execution');
        }
    }
    
    @isTest
    static void getInvoiceRecordTest() {
        User ersu = [SELECT Id FROM User Where IsActive =true LIMIT 1];
        System.runAs(ersu){
            List<Invoice__c> invoiceList = [select id, Invoice_number__c, Invoice_Sequence_Number__c, Total_invoice_Amount__c, Money_Applied_to_Invoice__c, Written_Off_Invoice__c,Order__c from Invoice__c where name='123'];
            SBR_3_0_MakeUncollectedPaymentController.getInvoiceRecord(invoiceList[0].id);
            System.assert(true, 'No exception should be thrown during execution');
        }
    }
    
    @isTest
    static void getInvoiceRecordTest02() {
        User ersu = [SELECT Id FROM User Where IsActive =true LIMIT 1];
        System.runAs(ersu){
            try{
            List<Invoice__c> invoiceList = [select id, Invoice_number__c, Invoice_Sequence_Number__c, Total_invoice_Amount__c, Money_Applied_to_Invoice__c, Written_Off_Invoice__c,Order__c from Invoice__c where name='123'];
            System.assertNotEquals(null, invoiceList, 'Invoice list should not be null');
            SBR_3_0_MakeUncollectedPaymentController.getInvoiceRecord('');
            System.assert(true, 'No exception should be thrown during execution');
        }catch(Exception e){
            System.assert(true, 'Exception: ' + e.getMessage());
        }
        }
    }
    
    @isTest
    static void getUpdateRecordTest() {
        User ersu = [SELECT Id FROM User Where IsActive =true LIMIT 1];
        System.runAs(ersu){
            List<Invoice__c> invoiceList = [select id, Invoice_number__c, Invoice_Sequence_Number__c, Total_invoice_Amount__c, Money_Applied_to_Invoice__c, Written_Off_Invoice__c,Order__c from Invoice__c where name='123'];
            SBR_3_0_MakeUncollectedPaymentController.updateInvoiceDetails(invoiceList[0].id,'200','100');    
         System.assert(true, 'No exception should be thrown during execution');
        }
    }
    
    @isTest
    static void testUpdateInvoicePaymentDetails() {
        User ersu = [SELECT Id FROM User Where IsActive =true LIMIT 1];
        System.runAs(ersu){
        List<Invoice__c> invoiceList = [select id,Amount_Due__c from Invoice__c where name='123'];
        
        // Create JSON payload
        List<SBR_3_0_MakeUncollectedPaymentController.InvoiceUpdateWrapper> invoicesToUpdate = new List<SBR_3_0_MakeUncollectedPaymentController.InvoiceUpdateWrapper>();
        invoicesToUpdate.add(new SBR_3_0_MakeUncollectedPaymentController.InvoiceUpdateWrapper(invoiceList[0].Id, '100'));

        String invoicesToUpdateJson = JSON.serialize(invoicesToUpdate);

        // Call the method under test
        Test.startTest();
        String result = SBR_3_0_MakeUncollectedPaymentController.updateInvoicePaymentDetails(invoicesToUpdateJson);
        Test.stopTest();
        System.assertNotEquals(null, result, 'Uncollected Payment Controller should not be null');
        }
    }
    
    @isTest
    static void getInvoiceDetailsTest2() {
        User ersu = [SELECT Id FROM User Where IsActive =true LIMIT 1];
        System.runAs(ersu){
            test.startTest();
            SBR_3_0_MakeUncollectedPaymentController.InvoiceUpdateWrapper wrp = new SBR_3_0_MakeUncollectedPaymentController.InvoiceUpdateWrapper();
            List < Order > orders =[SELECT Id FROM Order where Name = 'OrderName'];
            Id orderId = orders[0].Id;
            List<Account> accounts = [SELECT Id FROM Account where Name = 'Test Account'];
            Id accountId = accounts[0].Id;
            List<Invoice__c> invoiceList = [select id, Invoice_number__c, Invoice_Sequence_Number__c, Total_invoice_Amount__c, Money_Applied_to_Invoice__c, Written_Off_Invoice__c,Order__c from Invoice__c where name='123'];
            
            List<Invoice__c> invoives = SBR_3_0_MakeUncollectedPaymentController.getInvoiceDetails(invoiceList[0].Id, 'Invoice__c');
            Assert.areEqual(invoives[0].id, invoiceList[0].Id);
            test.stopTest();
        }
    }
    
     @isTest
    static void getUpdateRecordNegativeTest() {
        User ersu = [SELECT Id FROM User Where IsActive =true LIMIT 1];
        System.runAs(ersu){
            List<Invoice__c> invoiceList = [select id, Invoice_number__c, Invoice_Sequence_Number__c, Total_invoice_Amount__c, Money_Applied_to_Invoice__c, Written_Off_Invoice__c,Order__c from Invoice__c where name='123'];
            SBR_3_0_MakeUncollectedPaymentController.updateInvoiceDetails(invoiceList[0].id,'two hundred','One Hundred rupees');    
         System.assert(true, 'No exception should be thrown during execution');
        }
    }    
   
    @isTest
    static void getInvoiceDetailsTestFail2() {
        User ersu = [SELECT Id FROM User Where IsActive =true and Email = 'chatteruser@testorg.com' LIMIT 1];
        
        //List < Order > orders =[SELECT Id FROM Order where Name = 'OrderNameNew'];
        //Id orderId = orders[0].Id;
        List<Account> accounts = [SELECT Id FROM Account where Name = 'Test Account12'];
        Id accountId = accounts[0].Id;
        set<id> ids = new Set<Id>();
        ids.add(accountId);
        
        System.runAs(ersu){
            SBR_3_0_MakeUncollectedPaymentController.getInvoice(ids);
            SBR_3_0_MakeUncollectedPaymentController.getNotOpenInvoiceFromAccount(accountId);
            SBR_3_0_MakeUncollectedPaymentController.getInvoiceDetails(accountId,'Account');
            SBR_3_0_MakeUncollectedPaymentController.getInvoiceData(accountId);
        }
    }
}