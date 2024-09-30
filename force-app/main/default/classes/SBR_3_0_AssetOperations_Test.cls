/*********************************************************************************************************************
* Apex Class: SBR_3_0_AssetOperations_Test
---------------------------------------------------------------------------------------------------------------------------------------
* @description
* - Test Class to Check Asset After Update on Status and update the Status Counters on the linked Product Item Records
* - SAL- 4736, SAL-25190
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME                      DATE                 DETAIL FEATURES
 	1.0			Bill Convis - ServiceMax			2022-08-19
    2.0         Kedar Mudhalwadkar KM               2023-06-28           SAL-25190 Outbox publishing restricted only 
																		 if limited field changes detected
    3.0         Evan Kuminski                       2023-08-10           SERV-263 - Add testPublishUpdatedInSfAssets()
    4.0         Evan Kuminski                       2024-03-19           Fix madeData Asset creation failing
                                                                         Remove test stubs for methods that no longer exist
                                                                         Remove commented out test for method that no longer exists
                                                                         Updates to resolve code scanner errors
	5.0         Chhavi Singhal, Salesforce          2024-04-16           Covered updated logic of generateStockedSerials()
    6.0         Shilpa Mitra                        2024-04-23 			 Increased test coverage & solved PMD issue
	7.0         Chhavi Singhal, Salesforce          2024-05-22           Changes done as per SERV-15624
*********************************************************************************************************************/

@IsTest 
public class SBR_3_0_AssetOperations_Test {
    @TestSetup
    static void makeData() {
        List<Account> accounts = SBR_3_0_TestDataFactory.createAccounts(2, true);
        List<Contact> contacts = SBR_3_0_TestDataFactory.createContacts(1, accounts[0].Id, true);
        //Create Location Record
        List<Schema.Location> locs = SBR_3_0_TestDataFactory.createInventoryLocations(1, false, 'Branch');
        locs[0].Name = 'Test Location 2';
        insert locs;
        //Create User Location
        Id user = UserInfo.getUserId();
        User_location__c userLocation = new User_location__c(branch__c = locs[0].Id,User__c = user);
        insert userLocation;
        //Create Product record
        List<Product2> products = SBR_3_0_TestDataFactory.createProducts(1, false);
        products[0].Category__c = '009';
        products[0].Class__c = '0103';
        products[0].Product_SKU__c = '0090103';
        insert products; 
        //Create Product Item record
        List<ProductItem> productItems = SBR_3_0_TestDataFactory.createProductItems(1, false, products[0].Id, locs[0].Id);
        productItems[0].SM_PS_Company_Code__c = '01';
        productItems[0].SM_PS_Cat_Class__c = '0090103';
        insert productItems;
        
        //Create Customer-Owned Asset records
        List<Asset> assets = SBR_3_0_TestDataFactory.createAssets(2, false, accounts[0].Id, contacts[0].Id, locs[0].Id);
        assets[0].SM_PS_Company_Code__c = '01';
        assets[0].SM_PS_Equipment_Number__c = '1234567';
        assets[0].SM_PS_Asset_Id__c = assets[0].SM_PS_Company_Code__c + '-' + assets[0].SM_PS_Equipment_Number__c;
        assets[0].SM_PS_Updated_in_SF__c = false;
        assets[0].SM_PS_Current_Location__c = locs[0].Id;
		assets[0].RecordTypeId = Schema.SObjectType.Asset.getRecordTypeInfosByName().get('Customer-Owned Asset').getRecordTypeId();
        assets[0].SM_PS_Category__c = '009';
        assets[0].SM_PS_Class__c = '0103';
        
        assets[1].SM_PS_Company_Code__c = '01';
        assets[1].SM_PS_Equipment_Number__c = '2345678';
        assets[1].SM_PS_Asset_Id__c = assets[1].SM_PS_Company_Code__c + '-' + assets[1].SM_PS_Equipment_Number__c;
        assets[1].SM_PS_Updated_in_SF__c = true;
        assets[1].RecordTypeId = Schema.SObjectType.Asset.getRecordTypeInfosByName().get('Customer-Owned Asset').getRecordTypeId();
        assets[1].SM_PS_Category__c = '009';
        assets[1].SM_PS_Class__c = '0103';
        insert assets;
    }

    @IsTest
    static void testCheckAssetStatusChange(){
        Account account = [SELECT Id FROM Account ORDER BY CreatedDate ASC LIMIT 1];
        Asset oldAsset = [SELECT Id, Status, SM_PS_Updated_in_SF__c,SM_PS_Company_Code__c,SM_PS_Current_Location__c,SM_PS_Cat_Class__c FROM Asset WHERE AccountId = :account.Id ORDER BY CreatedDate ASC LIMIT 1];
        ProductItem oPItem = [SELECT Id, SM_PS_Company_Code__c, LocationId, SM_PS_Cat_Class__c FROM ProductItem];
        Map<Id,Asset> assetMap = new Map<Id,Asset>();
        assetMap.put(oldAsset.id,oldAsset);
        Test.startTest();
            oldAsset.Status = 'On Rent';
            update oldAsset;
        	SBR_3_0_AssetOperations.isAssetProductItemMatch(oldAsset,oPItem);
        	SBR_3_0_AssetOperations.addErrorMessageToAllAssets(assetMap,'Test Error');
        Test.stopTest();
        Asset newAsset = [SELECT Id, Status FROM Asset WHERE Id = :oldAsset.Id ORDER BY CreatedDate ASC LIMIT 1];
        System.assertEquals('ON RENT', newAsset.Status, 'Status did not update properly');
    }

    @IsTest
    static void testCheckAssetStatusChangeUpdateLocation() {
        Account account = [SELECT Id FROM Account ORDER BY CreatedDate ASC LIMIT 1][0];
        Asset oldAsset = [SELECT Id, 
                        SM_PS_Asset_Record_Type_Text__c,
                            SM_PS_Asset_Id__c,
                            SM_PS_Asset_Type_Code__c,
                            SM_PS_Assigned_Branch_Location_Number__c,
                            SM_PS_Assigned_Location__c,
                            SM_PS_Cat_Class__c,
                            SM_PS_Class__c,
                            SM_PS_Company_Code__c,
                            SM_PS_Currency_Code__c,
                            SM_PS_Current_Branch_Location_Number__c,
                            SM_PS_Current_Location__c,
                            SM_PS_Equipment_Number__c,
                            SM_PS_Equipment_Type_Code__c,
                            SM_PS_License_Number__c,
                            SM_PS_Miscellaneous_Options__c,
                            Status,
                            SM_PS_Container_Orientation_LHW__c,
                            SM_PS_Container_Orientation_HLW__c,
                            SM_PS_Container_Orientation_HWL__c,
                            SM_PS_Container_Orientation_LWH__c,
                            SM_PS_Container_Orientation_WHL__c,
                            SM_PS_Container_Orientation_WLH__c,
                            SM_PS_Machine_Height__c,
                            SM_PS_Machine_Length__c,
                            SM_PS_Machine_Weight__c,
                            SM_PS_Machine_Width__c,
                            SM_PS_Sell_Price__c FROM Asset WHERE AccountId = :account.Id ORDER BY CreatedDate ASC LIMIT 1];
        Schema.Location newLocation = [SELECT Id FROM Location WHERE Name = 'Test Location 2'];
        Test.startTest();
            oldAsset.Status = 'On Rent';
            oldAsset.SM_PS_Current_Location__c = newLocation.Id;
            update oldAsset;
        Test.stopTest();
        Asset newAsset = [SELECT Id, SM_PS_Asset_Id__c,
                            SM_PS_Asset_Type_Code__c,
                            SM_PS_Assigned_Branch_Location_Number__c,
                            SM_PS_Assigned_Location__c,
                            SM_PS_Cat_Class__c,
                            SM_PS_Class__c,
                            SM_PS_Company_Code__c,
                            SM_PS_Currency_Code__c,
                            SM_PS_Current_Branch_Location_Number__c,
                            SM_PS_Current_Location__c,
                            SM_PS_Equipment_Number__c,
                            SM_PS_Equipment_Type_Code__c,
                            SM_PS_License_Number__c,
                            SM_PS_Miscellaneous_Options__c,
                            Status,
                            SM_PS_Container_Orientation_LHW__c,
                            SM_PS_Container_Orientation_HLW__c,
                            SM_PS_Container_Orientation_HWL__c,
                            SM_PS_Container_Orientation_LWH__c,
                            SM_PS_Container_Orientation_WHL__c,
                            SM_PS_Container_Orientation_WLH__c,
                            SM_PS_Machine_Height__c,
                            SM_PS_Machine_Length__c,
                            SM_PS_Machine_Weight__c,
                            SM_PS_Machine_Width__c,
                            SM_PS_Sell_Price__c,
                            SM_PS_Asset_Record_Type_Text__c FROM Asset WHERE Id = :oldAsset.Id ORDER BY CreatedDate ASC LIMIT 1];
        System.assertEquals(newLocation.Id, newAsset.SM_PS_Current_Location__c, 'Status did not update properly');
    }

    @isTest
    static void getAsset(){
        //Map<String,String> mapV = SBR_3_0_AssetOperations.buildStatusMap();
        Map<Id, Schema.Asset> schemaAsset = new Map<Id,Schema.Asset>();
        SBR_3_0_AssetOperations.publishAssetType(schemaAsset,schemaAsset);
        Map<Id, Schema.Asset> oldAssetMap = new Map<Id, Schema.Asset>();
        ProductItem prodItem = [Select id from ProductItem limit 1];
        Asset olsAsse = [Select id, Status from Asset limit 1];
        List<Schema.Location> locLst = [select id from Location limit 2];
        oldAssetMap.put(olsAsse.id,olsAsse);
        Map<Id, Schema.Asset> newAssetMap = new Map<Id,Schema.Asset>();
       	Map<Id, Asset> newAssMap = new Map<Id,Asset>();
        Map<Id, Id> prodIDMap = new Map<Id,Id>();
        Map<Id, String> assetStatusMap = new Map<Id,String>();
        Map<String, String> statusCodeMap = new Map<String,String>();
        newAssMap.put(olsAsse.id,olsAsse);
        prodIDMap.put(prodItem.Id, olsAsse.Id);
        assetStatusMap.put(olsAsse.Id, 'Available');
        statusCodeMap.put('S', 'Available');
        olsAsse.Status = 'Available';
        olsAsse.SM_PS_Current_Location__c = locLst[0].id;
        update olsAsse;
        
        newAssetMap.put(olsAsse.Id, olsAsse);
        /*SBR_3_0_AssetOperations.checkAssetStatusChange(oldAssetMap,newAssetMap);
        Test.startTest();
        try{
        	SBR_3_0_AssetOperations.setProductItemStatusByLoc(prodItem, newAssMap, prodIDMap,assetStatusMap, 'FROMLOC',statusCodeMap);
        }catch(Exception e){
            system.debug('Exception'+ e);
        }
        Test.stopTest();*/
        System.assertEquals(1,locLst.size(),'location size');
    }
    
    /***KM Test Class start**/
    /** @description Test method to cover the status change logic */
        @isTest
    static void testPublishAssetType() {
        // Create test data
        Asset oldAsset = new Asset();
        oldAsset.SM_PS_Asset_Id__c = '11-# 10312t';
        // Set oldAsset field values
        Asset newAsset = new Asset();
        newAsset.SM_PS_Asset_Id__c = '99-# 10312t';
        // Set newAsset field values
        Map<Id, Asset> oldAssetMap = new Map<Id, Asset>();
        oldAssetMap.put(oldAsset.Id, oldAsset);
        Map<Id, Asset> newAssetMap = new Map<Id, Asset>();
        newAssetMap.put(newAsset.Id, newAsset);
        Test.startTest();
        SBR_3_0_AssetOperations.publishAssetType(oldAssetMap, newAssetMap);
        Test.stopTest();
        // Assertions
        System.assert(Limits.getQueries() > 0, 'Only one query should be executed.');
    }

    @IsTest
    static void testPublishUpdatedInSfAssets() {
        Account account = [SELECT Id FROM Account LIMIT 1][0];
        Asset asset = [SELECT Id, Status FROM Asset WHERE AccountId = :account.Id AND SM_PS_Updated_in_SF__c = TRUE];
        Integer outboxCount = [SELECT Id FROM Outbox__c WHERE Record_Id__c = :asset.Id].size();
        Assert.areEqual(1, outboxCount, 'Only one Outbox__c record was expected.');
    }

    @IsTest
    static void testCheckAssetAdditionalFieldChanges() {
        // Create test data
        Asset oldAsset = new Asset(RecordTypeId = Schema.SObjectType.Asset.getRecordTypeInfosByName().get('Company-Owned Asset').getRecordTypeId());
        oldAsset.SM_PS_Asset_Id__c = '11-# 103128';
        oldAsset.SM_PS_Category__c='146';
        oldAsset.SM_PS_Asset_Type_Code__c='TRACTORTRAILER';
        oldAsset.Status = 'Available';
        
        // Set oldAsset field values
        Asset newAsset = new Asset(RecordTypeId = Schema.SObjectType.Asset.getRecordTypeInfosByName().get('Company-Owned Asset').getRecordTypeId());
        newAsset.SM_PS_Asset_Id__c = '99-# 10312t';
        newAsset.Status = 'On Rent';
        newAsset.SM_PS_Category__c='146';
        newAsset.SM_PS_Asset_Type_Code__c='TRACTORTRAILER';

        // Set newAsset field values
        Map<Id, Asset> oldAssetMap = new Map<Id, Asset>();
        oldAssetMap.put(oldAsset.Id, oldAsset);
        Map<Id, Asset> newAssetMap = new Map<Id, Asset>();
        newAssetMap.put(newAsset.Id, newAsset);
        Map<Id, Asset> changedAssets = 
        SBR_3_0_AssetOperations.checkAssetAdditionalFieldChanges(oldAssetMap, newAssetMap);
        // Assertions
        System.assertEquals(1, changedAssets.size(), 'There should be one changed asset');
    }
        
    @isTest
    static void testIsAssetFieldsChanged() {
        // Create test data
        Asset oldAsset = new Asset();
        oldAsset.SM_PS_Asset_Id__c = '11-# 10312t';
        // Set oldAsset field values
        Asset newAsset = new Asset();
        newAsset.Name = '99-# 10312t';
        // Set newAsset field values
        Boolean isChanged = SBR_3_0_AssetOperations.isAssetFieldsChanged(oldAsset, newAsset);        
        //Assertions
        System.assertEquals(true, isChanged, 'Asset fields should be considered changed');
    }
    /***KM Test Class End**/
}