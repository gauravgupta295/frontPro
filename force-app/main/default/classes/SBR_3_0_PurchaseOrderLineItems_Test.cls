@isTest
private class SBR_3_0_PurchaseOrderLineItems_Test {
    @isTest
   public static void testGetPOLineItems() {
        Purchase_Order__c testPurchaseOrder = new Purchase_Order__c(Name = 'Test PO');
        insert testPurchaseOrder;
 
        List<PO_Line_Item__c> lineItems = new List<PO_Line_Item__c>();
        for(Integer i = 0; i < 5; i++) {
            lineItems.add(new PO_Line_Item__c(
                Purchase_Order__c = testPurchaseOrder.Id,
                Item_Type__c = 'M', 
                Quantity__c = 10        
            ));
        }
        insert lineItems;
       Test.startTest();
        List<PO_Line_Item__c> result = SBR_3_0_PurchaseOrderLineItems.getPOLineItems(testPurchaseOrder.Id);
       Test.stopTest();
        System.assertEquals(lineItems.size(), result.size());
}

// test method for Create PO Line Item method
 
    @isTest
    public static void testCreatePOLineItem() {
         Purchase_Order__c testPurchaseOrder = new Purchase_Order__c(Name = 'Test PO');
        insert testPurchaseOrder;
              Product2 testProduct = new Product2(
                    Name = 'Test product',
                    CurrencyIsoCode = 'USD',
                    RecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('SKU').getRecordTypeId()
                );
                insert testProduct;
            SBR_3_0_PurchaseOrderLineItems.createPOLineItem(
                testPurchaseOrder.Id,
                false,
                testProduct.Id,
                10,
                100.00
            );
            List<PO_Line_Item__c> createdLineItems = [SELECT Id FROM PO_Line_Item__c WHERE Purchase_Order__c = :testPurchaseOrder.Id];
            System.assertEquals(1, createdLineItems.size());
 
    }
// test method for Search PO Line Item method
    @isTest
    public static void testSearchProductMiscSalesItems() {
        Test.startTest();
        List<Product2> result = SBR_3_0_PurchaseOrderLineItems.searchProductMiscSalesItems('TestCode', 'TestSearch');
        Test.stopTest();
    }

//	Sachin Khambe
//	Test method for SBR_3_0_PurchaseOrderLineItems.deletePOLineItems
   @isTest
    public static void testDeletePOLineItems() {
        // test data
        Purchase_Order__c testPurchaseOrder = new Purchase_Order__c(Name = 'Test PO');
        insert testPurchaseOrder;
 
        List<PO_Line_Item__c> lineItems = new List<PO_Line_Item__c>();
        for(Integer i = 0; i < 5; i++) {
            lineItems.add(new PO_Line_Item__c(
                Purchase_Order__c = testPurchaseOrder.Id,
                Item_Type__c = 'M', 
                Quantity__c = 10        
            ));
        }
        insert lineItems;
 
        List<Id> selectedRowIDs = new List<Id>();
        for(PO_Line_Item__c item : lineItems) {
            selectedRowIDs.add(item.Id);
        }
        Test.startTest();
        Boolean result = SBR_3_0_PurchaseOrderLineItems.deletePOLineItems(selectedRowIDs);
        Test.stopTest();
 
        System.assertEquals(true, result);
 
        List<PO_Line_Item__c> deletedItems = [SELECT Id FROM PO_Line_Item__c WHERE Id IN :selectedRowIDs];
        System.assertEquals(0, deletedItems.size());        
    }
    
    //	Abhishek Hiremath
//	Test method for SBR_3_0_PurchaseOrderLineItems.cancelPOLineItems
   @isTest
    public static void testCancelPOLineItems() {
        // test data
        Purchase_Order__c testPurchaseOrder = new Purchase_Order__c(Name = 'Test PO');
        insert testPurchaseOrder;
 
        List<PO_Line_Item__c> lineItems = new List<PO_Line_Item__c>();
        for(Integer i = 0; i < 5; i++) {
            lineItems.add(new PO_Line_Item__c(
                Purchase_Order__c = testPurchaseOrder.Id        
            ));
        }
        insert lineItems;
 
        List<Id> selectedRowIDs = new List<Id>();
        for(PO_Line_Item__c item : lineItems) {
            selectedRowIDs.add(item.Id);
        }
        Test.startTest();
        Boolean result = SBR_3_0_PurchaseOrderLineItems.cancelPOLineItems(testPurchaseOrder.Id,selectedRowIDs);
        Test.stopTest();
 
        System.assertEquals(true, result);
 
        List<PO_Line_Item__c> cancelledItems = [SELECT Id FROM PO_Line_Item__c where Purchase_Order__c=:testPurchaseOrder.Id];
        System.assertEquals(5, cancelledItems.size());        
    }
    
    //	Test method for SBR_3_0_PurchaseOrderLineItems.cancelPOLineItem
   
    @isTest
    public static void testCancelPOLineItem() {
         Purchase_Order__c testPurchaseOrder = new Purchase_Order__c(Name = 'Test PO');
        insert testPurchaseOrder;
              Product2 testProduct = new Product2(
                    Name = 'Test product'
                );
                insert testProduct;
        system.debug('testPurchaseOrder>> '+testPurchaseOrder );
        system.debug('testProduct>> '+testProduct  );
        
            SBR_3_0_PurchaseOrderLineItems.cancelPOLineItem(
                testPurchaseOrder.Id,
                null
                
            );
            List<PO_Line_Item__c> cancelLineItem = [SELECT Id FROM PO_Line_Item__c WHERE Purchase_Order__c = :testPurchaseOrder.Id];
            System.assertEquals(0, cancelLineItem.size());
 
    } 
    /** @Author: Nikhil Shende
     *  @Description: This is a unit test method for removeBackOrderQtyStatus
     *  @Ticket no: FRONT-11934
	**/
    @isTest
    public static void testremoveBackOrderQtyStatus() {
        Purchase_Order__c testPurchaseOrder = new Purchase_Order__c(Name = 'Test PO');
		insert testPurchaseOrder;
        
        PO_Line_Item__c poLI = new PO_Line_Item__c(
            Purchase_Order__c = testPurchaseOrder.Id,
            Item_Type__c = 'M', 
            Quantity__c = 10,
            Open_Order_Qty__c = 1        
      	);
        insert poLI;
        
        Test.startTest();
        	SBR_3_0_PurchaseOrderLineItems.removeBackOrderQtyStatus(testPurchaseOrder.Id, poLI.Id);
        Test.stopTest();
        
        List<PO_Line_Item__c> result = [SELECT Open_Order_Qty__c FROM PO_Line_Item__c WHERE ID=:poLI.ID];
        System.assertEquals(0, result[0].Open_Order_Qty__c);
    }
    
    /** @Author: Nikhil Shende
     *  @Description: This is a unit test method for updatePOStatusToReceived
     *  @Ticket no: FRONT-11934
	**/
    @isTest
    public static void testupdatePOStatusToReceived() {
        List<Purchase_Order__c> poList = new List<Purchase_Order__c>();
        poList.add(new Purchase_Order__c(Name = 'Test PO'));
        poList.add(new Purchase_Order__c(Name = 'Test PO New'));
		insert poList;
        
        List<PO_Line_Item__c> poLIList = new List<PO_Line_Item__c>();
        poLIList.add(new PO_Line_Item__c(Purchase_Order__c = poList[0].Id, Status__c = 'Received' ));
        poLIList.add(new PO_Line_Item__c(Purchase_Order__c = poList[1].Id, Status__c = 'Back Order' ));
        insert poLIList;
        
        Id poId = poList[0].Id;
        Id poIdNew = poList[1].Id;
        
        Test.startTest();
        	SBR_3_0_PurchaseOrderLineItems.updatePOStatusToReceived(poId);
        	SBR_3_0_PurchaseOrderLineItems.updatePOStatusToReceived(poIdNew);
        Test.stopTest();
        
        List<Purchase_Order__c> result = [SELECT Status__c FROM Purchase_Order__c WHERE ID=:poId];
        System.assertEquals('Received', result[0].Status__c);
    }
    
    //Harshal Magar
//	Test method for SBR_3_0_PurchaseOrderLineItems.SearchProductsToAddLineItem
    @isTest
       public static void testSearchProductsToAddLineItem() {
        String companyCode = 'TestCompanyCode';
        String itemNumber = 'TestItemNumber';
 
        List<Product2> testProducts = new List<Product2>();
        for(Integer i = 0; i < 5; i++) {
             Product2 prod = new Product2(
             Name = 'Test Product ' + i,
             Item_Number__c = 'TestItem' + i,
             Company_Code__c = companyCode,
             Status__c = 'A',
             Product_Type__c = 'MISC Charge Items'
            );
 
            testProducts.add(prod);
       }
        insert testProducts;
        Test.startTest();       
 
        List<Product2> result = SBR_3_0_PurchaseOrderLineItems.searchProductsToAddLineItem(companyCode, itemNumber);
        Test.stopTest();
 
        System.assertnotEquals(5, result.size(), 'Incorrect number of products returned');
 
  }
      @isTest static void testAddPOLineItem_Success() {
        Purchase_Order__c testPurchaseOrder = new Purchase_Order__c(Name = 'Test PO');
        insert testPurchaseOrder;
        Id recordId = testPurchaseOrder.Id;
 
          Product2 testProduct = new Product2(
              Name = 'Test product',
              CurrencyIsoCode = 'USD',
              RecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('SKU').getRecordTypeId()
          );
          insert testProduct;
 
        Boolean newItem = false;
        String productId = testProduct.Id;
        Integer quantity = 10;
        Integer cost = 100;
        String itemNumber = 'hjfus';
        String companyCode = '01';
 
        // Call the method
 
        Test.startTest();
          
        String result = SBR_3_0_PurchaseOrderLineItems.addPOLineItem(recordId, newItem, productId, quantity, cost, itemNumber, companyCode);
          
        String result2 = SBR_3_0_PurchaseOrderLineItems.addPOLineItem2(recordId, newItem, productId, quantity, cost, itemNumber, companyCode);
        Test.stopTest();
 
        // Verify the result
 
        System.assertEquals('Success', result);
        List<PO_Line_Item__c> poLineItems = [SELECT Id FROM PO_Line_Item__c WHERE Purchase_Order__c = :recordId];
        System.assertEquals(2, poLineItems.size());
          
        System.assertEquals('Success', result2);
 
    }
 
    @isTest static void testAddPOLineItem_Error() {
 
        // Create test data
 
        Account acc = new Account(Name = 'Test Account');
        insert acc;
 
        // Define input parameters
 
        Id recordId = acc.Id;
        Boolean newItem = false; // Set newItem to false to simulate an error scenario
        String productId = 'Test Product';
        Integer quantity = 10;
        Integer cost = 100;
        String itemNumber = '12345';
        String companyCode = 'ABC';
        String poRecordType = 'Standard Purchase Order';
 
        // Call the method
 
        Test.startTest();
        String result = SBR_3_0_PurchaseOrderLineItems.addPOLineItem(recordId, newItem, productId, quantity, cost, itemNumber, companyCode);
        Test.stopTest();
 
        // Verify the result
 
        System.assertEquals('Error', result);
 
        // Verify that no PO_Line_Item__c record is created
 
        List<PO_Line_Item__c> poLineItems = [SELECT Id FROM PO_Line_Item__c WHERE Purchase_Order__c = :recordId];
 
        System.assertEquals(0, poLineItems.size());
 
    }
    @isTest
    public static void testGetPOLineItembyId() {
        DescribeSObjectResult dsr = Account.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED);
        Id recordTypeId = SBR_3_0_TestDataFactory.getAvailableRecordTypeId(dsr, 'Vendor');
        String rm_acc = '1234567';
        Account acct = SBR_3_0_TestDataFactory.createSingleAccount(true, recordTypeId, 'acc090', rm_acc, '01');
        Purchase_Order__c testPurchaseOrder = SBR_3_0_POTestDataFactory.createPurchaseOrders(1, acct, true)[0];
        List<PO_Line_Item__c> lineItems = SBR_3_0_POTestDataFactory.createPurchaseOrderLineItems(2, testPurchaseOrder.Id, true);
 
        Test.startTest();
        PO_Line_Item__c result = SBR_3_0_PurchaseOrderLineItems.getPOLineItembyId(lineItems[0].Id);
        PO_Line_Item__c result1 = SBR_3_0_PurchaseOrderLineItems.getFreightDetailsById(lineItems[0].Id);
        Test.stopTest();
        System.assertEquals(lineItems[0].Id, result.Id);
  }
    @isTest
    public static void testGetProductItemByProductAndLocation() {        
        Product2 testProduct = SBR_3_0_TestDataFactory.createProducts(1, true)[0];        
        Schema.Location loc = SBR_3_0_TestDataFactory.createInventoryLocations(1, true, SBR_3_0_Constants.LOCATION_REC_TYPE_BRANCH)[0];        
        ProductItem prodItem = SBR_3_0_TestDataFactory.createProductItems(1, true, testProduct.Id, loc.Id)[0];
 
        Test.startTest();
        ProductItem productItem = SBR_3_0_PurchaseOrderLineItems.getProductItemByProductAndLocation(testProduct.Id, loc.Id);
        Test.stopTest();
        System.assertEquals(productItem.Id, prodItem.Id);
  }
    @isTest
    public static void testAddFreightLineItem() {
         Purchase_Order__c testPurchaseOrder = new Purchase_Order__c(Name = 'Test PO');
        insert testPurchaseOrder;
            SBR_3_0_PurchaseOrderLineItems.addFreightLineItem(
                testPurchaseOrder.Id,
                '01',
                'Delivery',
                null,
                null,
                'FRT LONG HAUL',
                10,
                null,
                'test',
                'test',
                'test',
                false
            );
            List<PO_Line_Item__c> createdFreight = [SELECT Id FROM PO_Line_Item__c WHERE Purchase_Order__c = :testPurchaseOrder.Id];
            System.assertEquals(1, createdFreight.size());
 
    }
 
    
    @isTest
    public static void testGetEventOption() {
        // Create test records
        List<PO_Event__c> testEvents = new List<PO_Event__c>();
        for(Integer i = 0; i < 5; i++) {
            testEvents.add(new PO_Event__c(
                Name = 'Event ' + i,
                Event_Number__c =  + i,
                ExternalId__c = 'Event1' +i
            ));
        }
        insert testEvents;

        // Call the method to be tested
        Test.startTest();
        List<PO_Event__c> resultEvents = SBR_3_0_PurchaseOrderLineItems.getEventOption();
        Test.stopTest();

        // Assert the results
        System.assertEquals(5, resultEvents.size(), 'The number of events returned should be 5');

    }
    
    @isTest
    public static void testUpdatePOStatus() {
         Purchase_Order__c testPurchaseOrder = new Purchase_Order__c(Name = 'Test PO');
        insert testPurchaseOrder;
        
            SBR_3_0_PurchaseOrderLineItems.updatePOStatus(
                testPurchaseOrder.Id
            );
            List<Purchase_Order__c> updatePO = [SELECT Id FROM Purchase_Order__c WHERE Id = :testPurchaseOrder.Id];
            System.assertEquals(1, updatePO.size());
    }
    @isTest
    public static void testGetUserLocation() {
        Schema.Location location = new Schema.Location();
        location.Branch_Location_Number__c = '1234';
        location.Name = 'Test Branch Location';
        location.Street_Address__c = '12 Main Street';
        location.City__c = 'Toronto';
        location.Zip_Code__c = 'M7N7B3';
        location.State__c = 'ON';
        location.Country__c = 'CA';
        location.Job_Number__c = '332112';
        location.RecordTypeId = SBR_3_0_Constants.LOCATION_BRANCH_RT_ID;
        location.Company_Code__c = 'X';
        location.Time_Zone_Name__c = 'America/Chicago';
        location.Time_Zone__c = 3;
        insert location;

        User_Location__c userLoc = new User_Location__c();
        userLoc.User__c = UserInfo.getUserId();
        userLoc.Branch__c = location.Id;
        userLoc.ProfileBranche__c = location.Id;

        List<User_Location__c> orgUsrList = [SELECT Id, ProfileBranche__c, ProfileBranche__r.name,User__c FROM User_Location__c LIMIT 100];
        List<User_Location__c> finalUsrList = new List<User_Location__c>();
        Test.startTest();
        finalUsrList = SBR_3_0_PurchaseOrderLineItems.getUserLocation(UserInfo.getUserId());
        Test.stopTest();
        System.assertEquals(orgUsrList.size(), finalUsrList.size(), 'Count matches for user location');
    }
}