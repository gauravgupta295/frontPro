@isTest
public class sbr_3_0_PurchaseOrderTransferSearch_Test {
	
    static Schema.Location loc;
    static Schema.User_Location__c ul;
    
    @testSetup
    static void makeData() {
    Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];

    String uName = 'admin' + DateTime.now().getTime() + '@SBRtestorg.com';
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
	
    loc = new Schema.Location(); // Assign loc here
    // Schema.Location loc = new Schema.Location();
    loc.recordTypeId = SBR_3_0_Constants.LOCATION_BRANCH_RT_ID;
    loc.Name = '1799 Innovation Point';
    loc.Street_Address__c = '1799 Innovation Point';
    loc.State__c = 'SC';
    loc.Zip_Code__c = '29715';
    loc.Branch_Location_Number__c = '0411';
    insert loc;
        system.debug('loc >> ' +loc);
	/*
    User_Location__c ul = new User_Location__c(
      User__c = admin.Id,
      Branch__c = loc.Id
    );
    insert ul;
*/
    ul = new User_Location__c(); // Assign to class-level static variable
    ul.User__c = admin.Id;
    ul.Branch__c = loc.Id;
    insert ul;
        system.debug('ul >> ' +ul);
  }
    
        @isTest
    public static void testGetTransfer() { 
        
        user userObj  = [SELECT Id from user where  Alias = 'admin' limit 1];
        User_Location__c userLocationObj = [SELECT Id,user__c,branch__c FROM User_Location__c limit 1];
        
        Schema.Location objLoc = new Schema.Location();
        objLoc.recordTypeId = SBR_3_0_Constants.LOCATION_BRANCH_RT_ID;
        objLoc.Name = '1799 Innovation Point';
        objLoc.Street_Address__c = '1799 Innovation Point';
        objLoc.State__c = 'SC';
        objLoc.Zip_Code__c = '29715';
        objLoc.Branch_Location_Number__c = '0411';
        insert objLoc;
        
        system.debug('userLocationObj'+userLocationObj);
        system.debug('userObj'+userObj);
        
        List<Internal_Order__c> orders = new List<Internal_Order__c>();

            Internal_Order__c order = new Internal_Order__c(
                // Name = '10' + i,
                Permanent_Transfer__c = 'Permanent' ,
                Receiving_Branch__c = objLoc.Id, 
                Receiving_Rep_User_Location__c = userLocationObj.Id, 
                Requested_By_User_Location__c = userLocationObj.Id, 
                Sending_Branch__c = objLoc.Id, 
                Sending_Rep_User_Location__c = userLocationObj.Id,
                RM_Transfer_Number__c = '12345',
                Status__c = 'Pending',
                Transfer_Date__c = Date.today()
                // Ordered_by__c = 'Test user'
            );
            orders.add(order);
        	insert orders;

        Test.startTest();
        List<String> fields = new List<String>{'Name', 'RM_Transfer_Number__c', 'Status__c', 'Transfer_Date__c'};
        List<Internal_Order__c> result = sbr_3_0_PurchaseOrderTransferSearch.getTransfer(orders[0].Id, 'Internal_Order__c', fields);
        Test.stopTest();

        System.assertEquals(1, result.size());
        // System.assertEquals('TestOrder', result[0].Name); // Updated assertion
        // System.assertEquals(orders[0].Name, result[0].Name);
        System.assertEquals(order.RM_Transfer_Number__c, result[0].RM_Transfer_Number__c);
        System.assertEquals(order.Status__c, result[0].Status__c);
        System.assertEquals(order.Transfer_Date__c, result[0].Transfer_Date__c);
    }
    
    @isTest
    public static void testGetSearchResults() {
        User_Location__c userLocationObj = [SELECT Id,user__c,branch__c FROM User_Location__c limit 1];
        
        Schema.Location objLoc = new Schema.Location();
        objLoc.recordTypeId = SBR_3_0_Constants.LOCATION_BRANCH_RT_ID;
        objLoc.Name = '1799 Innovation Point';
        objLoc.Street_Address__c = '1799 Innovation Point';
        objLoc.State__c = 'SC';
        objLoc.Zip_Code__c = '29715';
        objLoc.Branch_Location_Number__c = '0411';
        insert objLoc;
        
        system.debug('userLocationObj'+userLocationObj);
        
        List<Internal_Order__c> orders = new List<Internal_Order__c>();

            Internal_Order__c order = new Internal_Order__c(
                // Name = '10' + i,
                Permanent_Transfer__c = 'Permanent' ,
                Receiving_Branch__c = objLoc.Id, 
                Receiving_Rep_User_Location__c = userLocationObj.Id, 
                Requested_By_User_Location__c = userLocationObj.Id, 
                Sending_Branch__c = objLoc.Id, 
                Sending_Rep_User_Location__c = userLocationObj.Id,
                RM_Transfer_Number__c = '12345',
                Status__c = 'Pending',
                Transfer_Date__c = Date.today()
                // Ordered_by__c = 'Test user'
            );
            Test.startTest();
        	insert order;
			Test.stopTest();
        
        List<Internal_Order__c> result = sbr_3_0_PurchaseOrderTransferSearch.getSearchResults(order.Id, 'Test');
       	System.assert(true, result.size() > 0 );
    }
    
    
    @isTest
    public static void testGetTransferForFilter() {
        User_Location__c userLocationObj = [SELECT Id,user__c,branch__c FROM User_Location__c limit 1];
        
        Schema.Location objLoc = new Schema.Location();
        objLoc.recordTypeId = SBR_3_0_Constants.LOCATION_BRANCH_RT_ID;
        objLoc.Name = '1799 Innovation Point';
        objLoc.Street_Address__c = '1799 Innovation Point';
        objLoc.State__c = 'SC';
        objLoc.Zip_Code__c = '29715';
        objLoc.Branch_Location_Number__c = '0411';
        insert objLoc;
        
        system.debug('userLocationObj'+userLocationObj);
        
        List<Internal_Order__c> orders = new List<Internal_Order__c>();
        for(Integer i = 0; i < 60; i++) {
        Internal_Order__c order = new Internal_Order__c(
                // Name = '10' + i,
                Permanent_Transfer__c = 'Permanent' ,
                Receiving_Branch__c = objLoc.Id, 
                Receiving_Rep_User_Location__c = userLocationObj.Id, 
                Requested_By_User_Location__c = userLocationObj.Id, 
                Sending_Branch__c = objLoc.Id, 
                Sending_Rep_User_Location__c = userLocationObj.Id,
                RM_Transfer_Number__c = '12345',
                Status__c = 'Pending',
                Transfer_Date__c = Date.today()
                // Ordered_by__c = 'Test user'
            );
        		orders.add(order);
    }

            Internal_Order__c orderNew = new Internal_Order__c(
                // Name = '10' + i,
                Permanent_Transfer__c = 'Permanent' ,
                Receiving_Branch__c = objLoc.Id, 
                Receiving_Rep_User_Location__c = userLocationObj.Id, 
                Requested_By_User_Location__c = userLocationObj.Id, 
                Sending_Branch__c = objLoc.Id, 
                Sending_Rep_User_Location__c = userLocationObj.Id,
                RM_Transfer_Number__c = '12345',
                Status__c = 'Pending',
                Transfer_Date__c = Date.today()
                // Ordered_by__c = 'Test user'
            );
            
        	insert orders;
        	insert orderNew;
			
		Test.startTest();
        List<String> fields = new List<String>{'Name', 'RM_Transfer_Number__c', 'Status__c', 'Transfer_Date__c'};
        List<Internal_Order__c> result = sbr_3_0_PurchaseOrderTransferSearch.getTransferForFilter(orderNew.Id, 'Internal_Order__c', fields, '');
		Test.stopTest();
        System.assertNotEquals(null, result);
    }

    
    @isTest
    public static void testGetTransfersForFilter() {
        
        // Create Product
        List<Product2> products = new List<Product2>();
        for(Integer i = 0; i < 3; i++) {
            Product2 product = new Product2();
            product.Name = 'Test Product ' + i;
            if(i == 0) {
                product.Product_Type__c = 'Cat-Class';
                product.Product_SKU__c = '123456';
                product.Category__c = '32134';
                product.Class__c = '2039';
                product.ToolFlex__c = 'N';
                product.Company_code__c ='01;02';
            } else if (i == 1) {
                product.Product_Type__c = 'Parts';
                product.Item_Number__c = '1234GH';
                product.Stock_Class__c = 'AIMFV';
                product.Company_code__c ='01;02';
            } else {
                product.Product_Type__c = '';
                product.Item_Number__c = '1285JC';
                product.Stock_Class__c = 'UJEKL';
                product.Company_code__c ='01;02';
            }
                products.add(product);
                }
            insert products;
        
       User_Location__c userLocationObj = [SELECT Id,user__c,branch__c FROM User_Location__c limit 1];
        
        Schema.Location objLoc = new Schema.Location();
        objLoc.recordTypeId = SBR_3_0_Constants.LOCATION_BRANCH_RT_ID;
        objLoc.Name = '1799 Innovation Point';
        objLoc.Street_Address__c = '1799 Innovation Point';
        objLoc.State__c = 'SC';
        objLoc.Zip_Code__c = '29715';
        objLoc.Branch_Location_Number__c = '0411';
        objLoc.IsInventoryLocation = true;
        insert objLoc;
        
        system.debug('objLoc >>'+objLoc);
        system.debug('userLocationObj'+userLocationObj);
        List<Internal_Order__c> orders = new List<Internal_Order__c>();

            Internal_Order__c order = new Internal_Order__c(
                // Name = '10' + i,
                Permanent_Transfer__c = 'Permanent' ,
                Receiving_Branch__c = objLoc.Id, 
                Receiving_Rep_User_Location__c = userLocationObj.Id, 
                Requested_By_User_Location__c = userLocationObj.Id, 
                Sending_Branch__c = objLoc.Id, 
                Sending_Rep_User_Location__c = userLocationObj.Id,
                RM_Transfer_Number__c = '12345',
                Status__c = 'Pending',
                Transfer_Date__c = Date.today()
                // Ordered_by__c = 'Test user'
            );
        	insert order;

            Asset objAsset = new Asset(
                Name = '243535',
                SM_PS_Equipment_Number__c = '25252522'
            );
            insert objAsset;
        	
        system.debug('objLoc.Id >>'+objLoc.Id);
        	ProductItem objProductItem = new ProductItem(
                SM_PS_Branch_Location_Number__c = objLoc.Id,
                LocationId = objLoc.Id,
                Product2Id = products[0].Id,
                QuantityOnHand = 122344
                
            );
        	insert objProductItem;
        system.debug('objProductItem >>'+objProductItem);

        List<Internal_Order_Line_Item__c> ordersLI = new List<Internal_Order_Line_Item__c>();
        for(Integer i = 0; i < 60; i++) {
            Internal_Order_Line_Item__c orderLI = new Internal_Order_Line_Item__c(
                //Assigned_Location__c = objLoc.Id,
                //Current_Location__c = objLoc.Id,
                Transfer_Number__c = order.Id,
                //Asset_Number__c = '1234', 
                Asset_Number__c = objAsset.Id,
                Cat_Class__c = objProductItem.Id 
                //Status__c = 'Available'
            );
            ordersLI.add(orderLI);
        	//insert orderLI;
        }
        Internal_Order_Line_Item__c newOrderLI = new Internal_Order_Line_Item__c(
                //Assigned_Location__c = objLoc.Id,
                //Current_Location__c = objLoc.Id,
                Transfer_Number__c = order.Id,
                //Asset_Number__c = '1234',
                Asset_Number__c = objAsset.Id, 
                Cat_Class__c = objProductItem.Id
                //Status__c = 'Available'
            );
        
        insert ordersLI;
        insert newOrderLI;

        // List<String> fields = new List<String>{'Name', 'Status__c', 'Transfer_Date__c', 'Ordered_by__c'};
        Test.startTest();
        List<Internal_Order_Line_Item__c> result = sbr_3_0_PurchaseOrderTransferSearch.getTransfersForFilter(newOrderLI.Id, 'Internal_Order_Line_Item__c',  new List<String>{'Id', 'Transfer_Number__r.RM_Transfer_Number__c', 'Transfer_Number__r.Receiving_Branch_Name__c', 'Transfer_Number__r.Sending_Branch_Name__c', 'Transfer_Number__r.Status__c', 'Transfer_Number__r.Transfer_Date__c'}, '');
        Set<Id> resultIds = (new Map<Id,SObject>(result)).keySet();
        
		System.assertNotEquals(null, result);
        System.assert(true, result.size() > 50 );
        Test.stopTest();
    }
    
    
    
    
}