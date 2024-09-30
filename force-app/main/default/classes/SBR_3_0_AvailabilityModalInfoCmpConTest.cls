/*********************************************************************************************************************
* Apex Class: SBR_3_0_AvailabilityModalInfoCmpCon
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Test class for SBR_3_0_AvailabilityModalInfoCmpCon
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    2.0         Soni Pinjala         	2023-08-29          Created proper test data for Equipment_on_Hold__c   
*********************************************************************************************************************/
@isTest
public with sharing class SBR_3_0_AvailabilityModalInfoCmpConTest {

    @TestSetup
    static void createData(){
        List<Account> testAccount = SBR_3_0_TestDataFactory.createAccounts(1, true);
        System.debug('TEST' + testAccount+ ' TETS COCO '+ testAccount[0].Company_Code__c);
        List<Contact> testContact = SBR_3_0_TestDataFactory.createContacts(1, testAccount[0].Id, true);
        List<Schema.Location> branch = SBR_3_0_TestDataFactory.createInventoryLocations(1,true,'Branch');
        branch[0].Branch_Location_Number__c = '0101';
        update branch;
        List<Asset> testAsset = SBR_3_0_TestDataFactory.createAssets(1,true,testAccount[0].Id,testContact[0].Id,branch[0].Id);
        testAsset[0].SM_PS_Cat_Class__c = '0020080';
        testAsset[0].recordtypeId = Schema.SObjectType.Asset.getRecordTypeInfosByName().get('Rental Asset').getRecordTypeId();
        update testAsset;
    }


    @isTest
    public static void fetchAssetsGivenValidCatClassAndStatus(){
        test.startTest();            
            List<Asset> testAsset = [SELECT Id,SM_PS_Cat_Class__c FROM Asset Limit 1];
            List<Schema.Location> branch = [SELECT Id,Branch_Location_Number__c FROM Location Limit 1];
            List<Asset> Assets = SBR_3_0_availabilityModalInfoCmpCon.fetchAssets(testAsset[0].SM_PS_Cat_Class__c,branch[0].Branch_Location_Number__c);
            System.assertEquals(testAsset[0].Id, Assets[0].Id);
        test.StopTest();
    }

    @isTest
    public static void fetchAssetInformationTest(){

        test.startTest();
            List<Asset> testAsset = [SELECT Id,SM_PS_Asset_Id__c FROM Asset Limit 1];
            SBR_3_0_AssetDA.AssetInformationWrapper assetDetails = SBR_3_0_availabilityModalInfoCmpCon.fetchAssetInformation(testAsset[0].SM_PS_Asset_Id__c);
            System.assertEquals(assetDetails.asset.SM_PS_Asset_Id__c, testAsset[0].SM_PS_Asset_Id__c);
            System.assertEquals(assetDetails.order, null);
        test.StopTest();
    }

    @isTest
    public static void fetchEquipmentOnHoldTest(){

        
            List<Asset> testAsset = [SELECT Id,SM_PS_Asset_Id__c,SM_PS_Cat_Class__c FROM Asset Limit 1];
            List<Schema.Location> branch = [SELECT Id,Branch_Location_Number__c FROM Location Limit 1];
            
        List<Equipment_on_Hold__c> lstEqHolds = new List<Equipment_on_Hold__c>();
        Equipment_on_Hold__c equipOnHold = new Equipment_on_Hold__c(SM_PS_Company_Code__c = '01',                                  
                                                                    SM_PS_Hold_Request_From_Date__c = Date.parse('11/11/2022'),  
                                                                    SM_PS_Contract_Applied__c = '102939',
                                                              		SM_PS_Asset_Id__c = testAsset[0].Id,                                   
                                                                    SM_PS_Status__c = 'Active');
        lstEqHolds.add(equipOnHold);
        insert lstEqHolds;
        
            test.startTest();
                List<Equipment_on_Hold__c> equipmentList = SBR_3_0_availabilityModalInfoCmpCon.fetchEquipmentOnHold(testAsset[0].SM_PS_Cat_Class__c,branch[0].Branch_Location_Number__c);
                System.assertNotEquals(equipmentList, null );
            test.StopTest();
    }
    
     @isTest
    public static void fetchEquipmentOnHoldTestError(){

        
            List<Asset> testAsset = [SELECT Id,SM_PS_Asset_Id__c,SM_PS_Cat_Class__c FROM Asset Limit 1];
        	
            List<Schema.Location> branch = [SELECT Id,Branch_Location_Number__c FROM Location Limit 1];
           
        List<Equipment_on_Hold__c> lstEqHolds = new List<Equipment_on_Hold__c>();
        Equipment_on_Hold__c equipOnHold = new Equipment_on_Hold__c(SM_PS_Company_Code__c = '01',                                  
                                                                    SM_PS_Hold_Request_From_Date__c = Date.parse('11/11/2022'),  
                                                                    SM_PS_Contract_Applied__c = '102939',
                                                              		SM_PS_Asset_Id__c = testAsset[0].Id,                                   
                                                                    SM_PS_Status__c = 'Active');
        lstEqHolds.add(equipOnHold);
        insert lstEqHolds;
        
        test.startTest();
        
        try{
             List<Equipment_on_Hold__c> equipmentList = SBR_3_0_availabilityModalInfoCmpCon.fetchEquipmentOnHold(null,null);
        } catch (DmlException ex) {
            System.assertEquals('expected text', ex.getMessage());
        } 
              /*  List<Equipment_on_Hold__c> equipmentList = SBR_3_0_availabilityModalInfoCmpCon.fetchEquipmentOnHold('','');
                System.assertEquals(equipmentList.IsEmpty(),true );*/
            test.StopTest();
    }
    
    @isTest
    public static void fetchEquipmentforAssetsTest(){

        	set<id> assetIds=new set<id>();
            List<Asset> testAsset = [SELECT Id,SM_PS_Asset_Id__c,SM_PS_Cat_Class__c FROM Asset ];
        	for(Asset assetrec:testAsset){
                    assetIds.add(assetrec.id);
            }            
            test.startTest();
                List<Equipment_on_Hold__c> equipmentList = SBR_3_0_EquipmentOnHoldDA.fetchEquipmentFromAssets(assetIds);
                System.assertNotEquals(equipmentList, null );
            test.StopTest();
    }
}