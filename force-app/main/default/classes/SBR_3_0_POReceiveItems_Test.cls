@isTest
public with sharing class SBR_3_0_POReceiveItems_Test {

    @testSetup static void createTestData() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];

        String uName = 'admin' + DateTime.now().getTime() + '@SBRPOTest.com';
        User admin = new User(
          Alias = 'admin',
          Email = 'adminuser1@testorg.com',
          RepId__c = '1092345',
          EmailEncodingKey = 'UTF-8',
          LastName = 'Admin1',
          LanguageLocaleKey = 'en_US',
          LocaleSidKey = 'en_US',
          ProfileId = p.Id,
          TimeZoneSidKey = 'America/Los_Angeles',
          UserName = uName
        );
        insert admin;
        
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Purchase_Order_Integration'];
		List <PermissionSetAssignment> permSetCheck = [SELECT Id from PermissionSetAssignment WHERE PermissionSetId = : ps.Id
                                                    AND AssigneeId = : admin.Id];
        
        if (permSetCheck.size()==0){
        	insert new PermissionSetAssignment(AssigneeId = admin.Id, PermissionSetId = ps.Id);
        }
    }

    @isTest
    public static void getUserProductItemsByProductIdsTest(){
        User admin = [SELECT Id from User WHERE Email='adminuser1@testorg.com' AND LastName='Admin1' LIMIT 1];
        System.runAs(admin) {
            DescribeSObjectResult dsr = Account.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED);
            Id recordTypeId = SBR_3_0_TestDataFactory.getAvailableRecordTypeId(dsr, 'Vendor');
            String rm_acc = '1234567';
            Account acct = SBR_3_0_TestDataFactory.createSingleAccount(true, recordTypeId, 'acc090', rm_acc, '01');
            List<Purchase_Order__c> pos = SBR_3_0_POTestDataFactory.createPurchaseOrders(1, acct, true);  
            
            List<PO_Line_Item__c> poLineItems = SBR_3_0_POTestDataFactory.createPurchaseOrderLineItems(2, pos[0].Id, true);
            system.debug('Value of poLineItems---> ' +poLineItems);
    
            List<Product2> lstProds = SBR_3_0_TestDataFactory.createProducts(1, true);
            List<Schema.Location> locs = SBR_3_0_TestDataFactory.createInventoryLocations(1, true, 'Branch');
            List<User_Location__c> userLocs = SBR_3_0_POTestDataFactory.createUserLocation(locs[0].id);
            List<ProductItem> productItems = SBR_3_0_TestDataFactory.createProductItems(1, true, lstProds[0].id, userLocs[0].ProfileBranche__c);
            productItems[0].SM_PS_Branch_Location_Number__c = productItems[0].LocationId;
            update productItems;
            system.debug('Value of productItems---> ' +productItems);
            Product2 prd = [Select Id from Product2 LIMIT 1];
            List<Id> prodIds = new List<Id>{prd.Id};
            Test.startTest();
            List<ProductItem> prodItems = SBR_3_0_POReceiveItems.getUserProductItemsByProductIds(prodIds);
            system.debug('Value of prodItems---> ' +prodItems);
            Test.stopTest();
            System.assertEquals(productItems[0].Id, prodItems[0].Id);
        }
    }
    
    @isTest
    public static void receiveMiscItemsTest(){
        User admin = [SELECT Id from User WHERE Email='adminuser1@testorg.com' AND LastName='Admin1' LIMIT 1];
        System.runAs(admin) {
            DescribeSObjectResult dsr = Account.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED);
            Id recordTypeId = SBR_3_0_TestDataFactory.getAvailableRecordTypeId(dsr, 'Vendor');
            String rm_acc = '1234567';
            Account acct = SBR_3_0_TestDataFactory.createSingleAccount(true, recordTypeId, 'acc090', rm_acc, '01');
            List<Purchase_Order__c> pos = SBR_3_0_POTestDataFactory.createPurchaseOrders(1, acct, true);  
            
            List<PO_Line_Item__c> poLineItems = SBR_3_0_POTestDataFactory.createPurchaseOrderLineItems(2, pos[0].Id, true);
            system.debug('Value of poLineItems---> ' +poLineItems);
    
            List<Product2> lstProds = SBR_3_0_TestDataFactory.createProducts(1, true);
            List<Schema.Location> locs = SBR_3_0_TestDataFactory.createInventoryLocations(1, true, 'Branch');
            List<User_Location__c> userLocs = SBR_3_0_POTestDataFactory.createUserLocation(locs[0].id);
            List<ProductItem> productItems = SBR_3_0_TestDataFactory.createProductItems(1, true, lstProds[0].id, userLocs[0].ProfileBranche__c);
            
            Purchase_Order__c purchaseOrder = [SELECT Id FROM Purchase_Order__c LIMIT 1];
            PO_Line_Item__c poLineItem;
        	system.debug('Value of poLineItems---> ' +poLineItems);
            poLineItem = [SELECT Id, Name, Purchase_Order__c, Item_Type__c, Quantity__c, Quantity_Rcvd__c FROM PO_Line_Item__c WHERE Purchase_Order__c =:purchaseOrder.Id LIMIT 1];
            List<PO_Receipt__c> receiveItemList = new List<PO_Receipt__c>();
            PO_Receipt__c receiveItem = new PO_Receipt__c();
            receiveItem.Purchase_Order__c = poLineItem.Purchase_Order__c;
            receiveItem.PO_Line_Item__c = poLineItem.Id;
            system.debug('Accessible Item_Type__c---> '+Schema.SObjectType.PO_Line_Item__c.fields.Item_Type__c.isAccessible());
            system.debug('Accessible Quantity__c---> '+Schema.SObjectType.PO_Line_Item__c.fields.Quantity__c.isAccessible());
            system.debug('Value of poLineItem---> ' +poLineItem);
            system.debug('Value of Item_Type__c---> ' +poLineItem.Item_Type__c);
            system.debug('Value of Quantity__c---> ' +poLineItem.Quantity__c);
            receiveItem.Item_Type__c = poLineItem.Item_Type__c;
            receiveItem.Quantity_Received__c = poLineItem.Quantity__c - 1;
            receiveItemList.add(receiveItem);
            string inputParam = JSON.serialize(receiveItemList);
            Test.startTest();
            string output = SBR_3_0_POReceiveItems.receiveMiscItems(purchaseOrder.Id, inputParam, '');
            system.debug('Value of output---> ' +output);
            PO_Receipt__c poReceipt = [SELECT Id, Name, PO_Line_Item__c from PO_Receipt__c LIMIT 1];
            Test.stopTest();
            System.assertEquals(poLineItem.Id, poReceipt.PO_Line_Item__c);
        }
    }
    
    @isTest
    public static void receiveMiscItemsTestNegative(){
        User admin = [SELECT Id from User WHERE Email='adminuser1@testorg.com' AND LastName='Admin1' LIMIT 1];
        System.runAs(admin) {
            DescribeSObjectResult dsr = Account.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED);
            Id recordTypeId = SBR_3_0_TestDataFactory.getAvailableRecordTypeId(dsr, 'Vendor');
            String rm_acc = '1234567';
            Account acct = SBR_3_0_TestDataFactory.createSingleAccount(true, recordTypeId, 'acc090', rm_acc, '01');
            List<Purchase_Order__c> pos = SBR_3_0_POTestDataFactory.createPurchaseOrders(1, acct, true);  
            
            List<PO_Line_Item__c> poLineItems = SBR_3_0_POTestDataFactory.createPurchaseOrderLineItems(2, pos[0].Id, true);
            system.debug('Value of poLineItems---> ' +poLineItems);
    
            List<Product2> lstProds = SBR_3_0_TestDataFactory.createProducts(1, true);
            List<Schema.Location> locs = SBR_3_0_TestDataFactory.createInventoryLocations(1, true, 'Branch');
            List<User_Location__c> userLocs = SBR_3_0_POTestDataFactory.createUserLocation(locs[0].id);
            List<ProductItem> productItems = SBR_3_0_TestDataFactory.createProductItems(1, true, lstProds[0].id, userLocs[0].ProfileBranche__c);
            
            Purchase_Order__c purchaseOrder = [SELECT Id FROM Purchase_Order__c LIMIT 1];
            PO_Line_Item__c poLineItem;
        	system.debug('Value of poLineItems---> ' +poLineItems);
            poLineItem = [SELECT Id, Name, Purchase_Order__c, Item_Type__c, Quantity__c, Quantity_Rcvd__c FROM PO_Line_Item__c WHERE Purchase_Order__c =:purchaseOrder.Id LIMIT 1];
            List<PO_Receipt__c> receiveItemList = new List<PO_Receipt__c>();
            PO_Receipt__c receiveItem = new PO_Receipt__c();
            receiveItem.Purchase_Order__c = poLineItem.Purchase_Order__c;
            receiveItem.PO_Line_Item__c = poLineItem.Id;
            system.debug('Accessible Item_Type__c---> '+Schema.SObjectType.PO_Line_Item__c.fields.Item_Type__c.isAccessible());
            system.debug('Accessible Quantity__c---> '+Schema.SObjectType.PO_Line_Item__c.fields.Quantity__c.isAccessible());
            system.debug('Value of poLineItem---> ' +poLineItem);
            system.debug('Value of Item_Type__c---> ' +poLineItem.Item_Type__c);
            system.debug('Value of Quantity__c---> ' +poLineItem.Quantity__c);
            receiveItem.Item_Type__c = poLineItem.Item_Type__c;
            receiveItem.Quantity_Received__c = poLineItem.Quantity__c - 1;
            receiveItem.Bin_1__c = '12345679012';
            receiveItemList.add(receiveItem);
            string inputParam = JSON.serialize(receiveItemList);
            Test.startTest();
            string output = SBR_3_0_POReceiveItems.receiveMiscItems(purchaseOrder.Id, inputParam, '');
            system.debug('Value of output---> ' +output);
            integer recCount = [SELECT Id, Name, PO_Line_Item__c from PO_Receipt__c LIMIT 1].size();            
            Test.stopTest();
            System.assertEquals(0, recCount);
        }
    }

}