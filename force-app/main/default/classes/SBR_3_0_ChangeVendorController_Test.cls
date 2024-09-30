@isTest
public class SBR_3_0_ChangeVendorController_Test {

    @isTest
    public static void testGetVendorName() {
        List<Account> accts = new List<Account>();
        for(Integer i = 0; i < 60; i++) {
            accts.add(new Account(
                Name='Test Vendor' + i.toString(),
                Account_Type__c = 'Non Credit',
                BillingCity = 'NY',
                BillingCountry = 'US',
                BillingCountryCode = 'US',
                BillingPostalCode = '43215',
                BillingState = 'OH',
                CurrencyIsoCode = 'USD',
                Phone = '9999991919',
                ShippingStreet = '123 Main St',
                Vendor_Status__c = 'A',
                Vendor_Number__c= '7676' + + i.toString(),
                RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Vendor').getRecordTypeId()
            ));
        }
        insert accts;
        //test data
        Account testVendor = new Account(
            Name='Z Test Vendor',
            Account_Type__c = 'Non Credit',
            BillingCity = 'NY',
            BillingCountry = 'US',
            BillingCountryCode = 'US',
            BillingPostalCode = '43215',
            BillingState = 'OH',
            CurrencyIsoCode = 'USD',
            Phone = '9999991919',
            ShippingStreet = '123 Main St',
            Vendor_Status__c = 'A',
            Vendor_Number__c= '7676',
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Vendor').getRecordTypeId()
        );
        insert testVendor;

        List<Account> result = SBR_3_0_ChangeVendorController.getVendorName(testVendor.id, 'Account', new List<String>{'Id', 'Name'}, 'Vendor_Status__c=\'A\'');
        Set<Id> resultIds = (new Map<Id,SObject>(result)).keySet();
        System.assertEquals(51, result.size());
        System.assertEquals(true, resultIds.contains(testVendor.id));
    }
    
    
    
@isTest
    public static void testGetSearchResults() {
        Purchase_Order__c testPurchaseOrder = new Purchase_Order__c(Name = 'Test PO');
        insert testPurchaseOrder;
        //id recId = [select id from Purchase_Order__c].id;
        List<Account> accList = SBR_3_0_ChangeVendorController.getSearchResults(testPurchaseOrder.Id,'test');
        System.assert(true, accList.size() > 0 );    
    }

@isTest
    public static void testUpdateVendor() {
        //test data
        Purchase_Order__c testPurchaseOrder = new Purchase_Order__c(Name = 'Test PO');
        insert testPurchaseOrder;

        Account testVendor = new Account(
            Name='Test Vendor',
            Account_Type__c = 'Non Credit',
            BillingCity = 'NY',
            BillingCountry = 'US',
            BillingCountryCode = 'US',
            BillingPostalCode = '43215',
            BillingState = 'OH',
            CurrencyIsoCode = 'USD',
            Phone = '9999991919',
            ShippingStreet = '123 Main St',
            Vendor_Status__c = 'A',
            Vendor_Number__c= '7676',
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Vendor').getRecordTypeId()
        );
        insert testVendor;

        Test.startTest();
        SBR_3_0_ChangeVendorController.updateVendor(testPurchaseOrder.Id, testVendor.Id);
        Test.stopTest();
        Purchase_Order__c updatedPurchaseOrder = [SELECT Id, Vendor__c FROM Purchase_Order__c WHERE Id = :testPurchaseOrder.Id];
        System.assertEquals(testVendor.Id, updatedPurchaseOrder.Vendor__c);
    }
}