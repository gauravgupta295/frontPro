/*********************************************************************************************************************
* Apex Class: SBR_3_0_AssetTriggerHandler_Test
---------------------------------------------------------------------------------------------------------------------------------------
* @description
* - SAL-1503
* - Test class for Asset Trigger Handler class.
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME                      DATE                 DETAIL FEATURES
    1.0         Bill Convis                        2022-08-10            Initial version
    2.0         Evan Kuminski                      2023-03-19            Minor updates to fix code scanner errors, minor code cleanup
    3.0         Shilpa Mitra                       2024-04-23 			 Increased test coverage & solved PMD issue
	4.0         Chhavi Singhal, Salesforce         2024-05-22            Changes done as per SERV-15624
*********************************************************************************************************************/
@IsTest
public with sharing class SBR_3_0_AssetTriggerHandler_Test {
    
    private static SBR_3_0_AssetTriggerHandler handler;
    private static String lastMethodCalled;

    static {
        handler = new SBR_3_0_AssetTriggerHandler();
        // override its internal trigger detection
        handler.isTriggerExecuting = true;
        handler.oldAssetMap = new Map<Id, Asset>();
        handler.newAssetMap = new Map<Id, Asset>();
    }

    @TestSetup static void setupTestData() {
        Integer count = 15;
        //Create Accounts
        List<Account> lstAccounts = SBR_3_0_TestDataFactory.createAccounts(count, true);
        //Create Contacts 
        List<Contact> lstContacts = SBR_3_0_TestDataFactory.createContacts(count, lstAccounts[0].Id, true);
        //Create Products
        List<Product2> lstProds = SBR_3_0_TestDataFactory.createProducts(1, true);
        //Create Locations
        List<Schema.Location> locs = SBR_3_0_TestDataFactory.createInventoryLocations(1, true, 'Branch');
        //Create Stocked Serials
        //Create ProductItems
        List<ProductItem> productItems = SBR_3_0_TestDataFactory.createProductItems(1, true, lstProds[0].Id, locs[0].Id);
        //Create the Assets
        List<Asset> lstAssets = SBR_3_0_TestDataFactory.createAssets(1,true,lstAccounts[0].Id,lstContacts[0].Id, locs[0].Id);
        //Create Stocked Serials
        SBR_3_0_TestDataFactory.createStockedSerials(1, true, lstAssets[0].Id, lstProds[0].Id , productItems[0].Id);


    }

    @IsTest
    static void testAfterUpdate() {
        
        String uniqueUserName = 'standarduser' + Datetime.now().getTime() + '@SBRtestorg.com';
        // This code runs as the system user
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com',
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
        LocaleSidKey='en_US', ProfileId = p.Id,
        TimeZoneSidKey='America/Los_Angeles',
        UserName=uniqueUserName);
        insert u;
        PermissionSet ps = [SELECT Id 
                    FROM PermissionSet 
                    WHERE Name = 'Assets_Full_Access'];
		insert new PermissionSetAssignment(AssigneeId = u.Id, PermissionSetId = ps.Id);
        System.runAs(u){
            List<Asset> lstAssets = [SELECT Id, Status FROM Asset];
            List<Schema.Location> locs = SBR_3_0_TestDataFactory.createInventoryLocations(1, true, 'Branch');
            Asset ast = lstAssets[0];
            Schema.Location loc = locs[0];
            
            try{
                ast.Status = 'ON RENT';
                update ast;
                ast.Status = 'AVAILABLE';
                ast.SM_PS_Current_Location__c = loc.Id;
                update ast;
            } catch(DmlException e){
                System.assert(e.getMessage().contains('Asset cannot be Updated'), 'Asset cannot be Updated');
            }
        }

    }

}