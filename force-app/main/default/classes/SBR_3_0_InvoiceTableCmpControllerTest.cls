@isTest
public with sharing class SBR_3_0_InvoiceTableCmpControllerTest {
    @TestSetup
    static void makeData(){
        // Create Price Book
        Pricebook2 priceBook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update priceBook;
        
        RecordType rt = [SELECT Id, DeveloperName, IsActive, Name, SobjectType FROM RecordType
                    WHERE IsActive = true AND SobjectType =: SBR_3_0_Constants.ORDER_API_NAME AND DeveloperName = 'Contract_Order'];
        Order testOrder = SBR_3_0_TestDataFactory.createOrder(false, 'Test', rt.Id);
        testOrder.Name = 'Test Invoice Table Order';
        insert testOrder;
        Account testAccount = SBR_3_0_TestDataFactory.createAccounts(1, false)[0];
        testAccount.Name = 'Test Invoice Table Account';
        insert testAccount;
        Invoice__c testInvoice = new Invoice__c(
            Account__c = testAccount.Id,
            Order__c = testOrder.Id,
            Contract_Number__c = 234
        );
        insert testInvoice;
    }
    
    @isTest
    static void constructorTest() {
        Test.startTest();
            SBR_3_0_InvoiceTableCmpController result = new SBR_3_0_InvoiceTableCmpController();
        Test.stopTest();
        System.assert(result != null, 'Did not correctly create controller');
    }
    
    @isTest
    static void getInvoiceListTest() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Invoice Table Account' LIMIT 1];
        Test.startTest();
            List<Invoice__c> results = SBR_3_0_InvoiceTableCmpController.getInvoiceList(acc.Id);
        Test.stopTest();
        System.assertEquals(1, results.size(), 'Returned wrong number of invoices');
    }
    
    @isTest
    static void getInvoiceListForOrderTest() {
        Order o = [SELECT Id FROM Order WHERE Name = 'Test Invoice Table Order'];
        Test.startTest();
            List<Invoice__c> results = SBR_3_0_InvoiceTableCmpController.getInvoiceListForOrder(o.Id);
        Test.stopTest();
        System.assertEquals(1, results.size(), 'Returned wrong number of invoices');
    }
}