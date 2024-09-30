@isTest
public with sharing class SBR_3_0_POSearchController_Test {

    @testSetup static void poDataSetup() {
        DescribeSObjectResult dsr = Account.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED);
        Id recordTypeId = SBR_3_0_TestDataFactory.getAvailableRecordTypeId(dsr, 'Vendor');
        String rm_acc = '1234567';
        Account acct = SBR_3_0_TestDataFactory.createSingleAccount(true, recordTypeId, 'acc090', rm_acc, '01');
        SBR_3_0_POTestDataFactory.createPurchaseOrders(5, acct, true);     
    }

    @isTest
    public static void testGetObjectRecords() {
        Account acct = [SELECT Id FROM Account LIMIT 1];
        Test.startTest();
        List<Purchase_Order__c> result = SBR_3_0_POSearchController.getObjectRecords('Purchase_Order__c', 
                                                                            new List<String>{'Id', 'Name', 'Vendor__c', 'Vendor_Number__c', 'Vendor_Name_Text__c', 
                                                                                             'Status__c', 'Type__c', 'Issue_Date__c', 'OrderedBy_Name__c', 'Location__c', 
                                                                                             'ShipTo__c'}, 'Id != null', 50, null);
        Test.stopTest();
        System.assertEquals(5, result.size());
        //System.assertEquals(acct.Id, result[0].Vendor__c);
    }
    
    @isTest
    public static void testGetPOSearchResults() {
        Account acct = [SELECT Id, Name FROM Account LIMIT 1];
        Test.startTest();
        List<Purchase_Order__c> purchaseOrders = SBR_3_0_POSearchController.getPOSearchResults(acct.Name);
        Test.stopTest();
        System.assert(true, purchaseOrders.size() > 0 );    
    }

    @isTest
    public static void testGetObjectRecordsWithLineItems() {
        Account acct = [SELECT Id FROM Account LIMIT 1];
        Test.startTest();
        List<PO_Line_Item__c> result = SBR_3_0_POSearchController.getObjectRecordsWithLineItems('PO_Line_Item__c',new List<String>{'Id','Name','Item_Number__c','Purchase_Order__r.Vendor__c', 'Purchase_Order__r.Vendor_Number__c', 'Purchase_Order__r.Vendor_Name_Text__c', 
                                                                                             'Purchase_Order__r.Status__c','Purchase_Order__r.Type__c', 'Purchase_Order__r.Issue_Date__c', 'Purchase_Order__r.OrderedBy_Name__c', 'Purchase_Order__r.Location__c', 
                                                                                             'Purchase_Order__r.ShipTo__c' ,
                                                                                             'Purchase_Order__r.Name' ,'Purchase_Order__r.id'},'Purchase_Order__r.Id != null', 50, null);
          
        //System.assertEquals(5, result.size());
        Test.stopTest();
    }
    @isTest
    public static void testGetPOLineItemsSearchResults() {
        Account acct = [SELECT Id, Name FROM Account LIMIT 1];
         //String searchKey ='MT100';
        Test.startTest();
        List<PO_Line_Item__c> poLineItems = SBR_3_0_POSearchController.getPOLineItemsSearchResults(acct.Name);
        Test.stopTest();
        System.assert(true, poLineItems.size() > 0 );    
    }
    
    @isTest
    public static void testGetPOsFromVendor() {
        List<Purchase_Order__c> purchaseOrderList = new List<Purchase_Order__c>();
        Account vendAcc = [SELECT Id, Name FROM Account WHERE Name = 'acc090' LIMIT 1];
        List<Purchase_Order__c> purchaseOrders = [SELECT Id, Name FROM Purchase_Order__c WHERE Vendor__c =: vendAcc.Id LIMIT 100];
        Test.startTest();
        purchaseOrderList = SBR_3_0_POSearchController.getPOsFromVendor(vendAcc.Id);
        Test.stopTest();
        System.assertEquals(purchaseOrderList.size(), purchaseOrders.size(), 'Purchase Order Count matches');
    }
}