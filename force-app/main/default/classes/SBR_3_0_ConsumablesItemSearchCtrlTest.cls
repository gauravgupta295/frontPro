/*********************************************************************************************************************
* Apex Class: SBR_3_0_ConsumablesItemSearchCtrlTest
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Test class for SBR_3_0_ConsumablesItemSearchCtrl
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Soomjeet Sahoo			2023-12-20          Initial version    
    2.0         Nilesh Jaiswal		    2023-12-28			Added Product_Type while creating products 
**********************************************************************************************************************************************/
@isTest(seeAllData=false)
public class SBR_3_0_ConsumablesItemSearchCtrlTest {
    private static List<Product2> lstProds;
    private static List<Schema.ProductItem> productItems;
    private static List<Schema.ProductItem> productItems2;
    private static List<Schema.Asset> assets;
    private static List<Schema.Location> locs;

    private static void makePIData() {
        lstProds = SBR_3_0_TestDataFactory.createProducts(1, false);
        lstProds[0].Product_Type__c = 'Parts';
        insert lstProds;
        
        // Create a Location
        locs = SBR_3_0_TestDataFactory.createInventoryLocations(1, false, 'Branch');
        Schema.Location loc = locs[0];
        loc.Name = 'Ohio PC1107';
        loc.District__c = 'BALTIMORE DELAWARE DISTRICT';
        loc.Region__c = 'REGION 02';
        loc.Territory__c = 'EAST TERRITORY';
        loc.Company__c = 'SUNBELT RENTALS';
        insert locs;
        
        // Create a Product Item
        productItems = SBR_3_0_TestDataFactory.createProductItems(
            1,
            false,
            lstProds[0].Id,
            locs[0].Id
        );
        Schema.ProductItem pi = productItems[0];
        pi.SM_PS_Cat_Class__c = '0090030';
        pi.SM_PS_Quantity_Available__c = 20;
        pi.SM_PS_Quantity_Reserved__c = 5;
        pi.SM_PS_Quantity_on_Scheduled_Pick_Up__c = 5;
        pi.SM_PS_Quantity_on_Rent__c = 30;
        pi.SM_PS_Number_of_Rental_Units__c = 60;
        pi.SM_PS_Quantity_Returned__c = 5;
        pi.RecordTypeId = Schema.SObjectType.ProductItem.getRecordTypeInfosByDeveloperName()
            .get(
                SBR_3_0_PartsAndMerchAvailCmpController.PARTS_AND_MERCH_RECORDTYPE_DEVELOPERNAME
            )
            .getRecordTypeId();
        insert productItems;
    }
    
    @IsTest
    private static void testGetAllProductItemsForSales() {
        List<SBR_3_0_ConsumablesItemSearchCtrl.ProductionItemWrapper> piData = new List<SBR_3_0_ConsumablesItemSearchCtrl.ProductionItemWrapper>();
        Profile oProfile = [
            SELECT Id
            FROM Profile
            WHERE Name = :SBR_3_0_Constants.PROFILE_NAME_ADMIN
        ];
        User oUsers = SBR_3_0_TestDataFactory.createUser(true, oProfile);
        System.Test.startTest();
        System.runAs(oUsers) {
            makePIData();
            System.debug(
                'PI >> ' + [SELECT Id, LocationId FROM ProductItem LIMIT 10]
            );
            piData = SBR_3_0_ConsumablesItemSearchCtrl.getAllProductItemsForSales(
                0,
                1,
                'LocationId = \'' + locs[0].id + '\'',
				'SALES'
            );
        }
        System.Test.stopTest();
        Assert.areEqual(true, piData.size() > 0, 'Consumables returned.');
    }
    
        @IsTest
    private static void testGetAllProductItemsForMISC() {
        List<SBR_3_0_ConsumablesItemSearchCtrl.ProductionItemWrapper> piData = new List<SBR_3_0_ConsumablesItemSearchCtrl.ProductionItemWrapper>();
        Profile oProfile = [
            SELECT Id
            FROM Profile
            WHERE Name = :SBR_3_0_Constants.PROFILE_NAME_ADMIN
        ];
        User oUsers = SBR_3_0_TestDataFactory.createUser(true, oProfile);
        System.Test.startTest();
        System.runAs(oUsers) {
            makePIData();
            System.debug(
                'PI >> ' + [SELECT Id, LocationId FROM ProductItem LIMIT 10]
            );
            piData = SBR_3_0_ConsumablesItemSearchCtrl.getAllProductItemsForSales(
                0,
                1,
                'LocationId = \'' + locs[0].id + '\'',
				'MISC'
            );
        }
        System.Test.stopTest();
        Assert.areEqual(false, piData.size() > 0, 'Consumables returned.');
    }
}