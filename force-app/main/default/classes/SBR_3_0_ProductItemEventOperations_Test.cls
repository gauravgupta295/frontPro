/*********************************************************************************************************************
* Apex Class: SBR_3_0_ProductItemEventOperations_Test
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* @description Test class for SBR_3_0_ProductItemOperations.
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME                      DATE                 DETAIL FEATURES
    1.0         Shilpa Mitra                        2024-02-27           Initial version    
*********************************************************************************************************************/
@isTest
public with sharing class SBR_3_0_ProductItemEventOperations_Test {
    @testSetup static void setupTestData() {
        //Create Products
        List<Product2> lstProds = SBR_3_0_TestDataFactory.createProducts(1, true);
        //Create Locations
        List<Schema.Location> locs = SBR_3_0_TestDataFactory.createInventoryLocations(1, true, 'Branch');
        //Create ProductItems
        SBR_3_0_TestDataFactory.createProductItems(1, true, lstProds[0].Id, locs[0].Id);
    }
     @isTest
    public static void testUpdateProductItems() {
        
        List<SBR_3_0_Product_Item__e> prodItemPlatformEventList = new List<SBR_3_0_Product_Item__e>();
        String uniqueUserName = 'standarduser' + DateTime.now().getTime() + '@SBRtestorg.com';
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com',
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
        LocaleSidKey='en_US', ProfileId = p.Id,
        TimeZoneSidKey='America/Los_Angeles',
        UserName=uniqueUserName);
        insert u;
        PermissionSet ps = [SELECT Id 
                    FROM PermissionSet 
                    WHERE Name = 'Inventory_Full_Access'];
		insert new PermissionSetAssignment(AssigneeId = u.Id, PermissionSetId = ps.Id);
         
        System.runAs(u){
            ProductItem productItems = [select id,SM_PS_Last_Message_DateTime_Stamp__c,SM_PS_ProductItem_Id__c,QuantityOnHand from ProductItem];
            productItems.SM_PS_Last_Message_DateTime_Stamp__c='2024-02-27T13:11:05.029218Z';
            String productItemsId = productItems.SM_PS_ProductItem_Id__c;
            update productItems;
            
            prodItemPlatformEventList.add(new SBR_3_0_Product_Item__e(SM_PS_Last_Message_DateTime_Stamp__c= '2024-02-28T13:11:51.029218Z',QuantityOnHand__c=23.0,SM_PS_ProductItem_Id__c=productItemsId));
            prodItemPlatformEventList.add(new SBR_3_0_Product_Item__e(SM_PS_Last_Message_DateTime_Stamp__c= '2024-02-28T13:11:51.029218Z',QuantityOnHand__c=23.0,SM_PS_ProductItem_Id__c='01-01-0240213'));
            
            Test.startTest();
            EventBus.publish(prodItemPlatformEventList); 
            Test.stopTest();
            
            ProductItem productItemsUpdated = [select id,SM_PS_Last_Message_DateTime_Stamp__c,SM_PS_ProductItem_Id__c,QuantityOnHand from ProductItem where SM_PS_ProductItem_Id__c=:productItemsId];
            system.assertEquals(productItemsUpdated.QuantityOnHand,23.0,'Quantity was not updated');
        }
    }
}