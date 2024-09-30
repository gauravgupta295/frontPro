/*********************************************************************************************************************
* Apex Class: SBR_3_0_AssetFilterContr_Test
----------------------------------------------------------------------------------------------------------------------
* @description
* - Test Class for SBR_3_0_AssetFilterController
----------------------------------------------------------------------------------------------------------------------
* History:
* VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
*	1.		  Shilpa Mitra			  07/02/2024		  Initial Version
**********************************************************************************************************************/
@isTest
public class SBR_3_0_AssetFilterContr_Test {
    @isTest
    public static void testAssetFilter() {
        //Asset Creation
        List<Asset> assetList = new List<Asset>();
        assetList = SBR_3_0_TestDataFactory.createAssets(1, FALSE); 
        assetList[0].SM_PS_Sub_Class__c = 075;
        assetList[0].SM_PS_Company_Code__c = '01';
        assetList[0].SM_PS_Category__c = '009';
        assetList[0].SM_PS_Class__c = '0100';
        assetList[0].SM_PS_Cat_Class__c = '0090100';
        assetList[0].Status ='Available';
        insert assetList;
        
        List<Asset> assetListWithFilter = new List<Asset>();
        Integer assetCount ;
        List<Asset> assetListWithFilter1 = new List<Asset>();
        Integer assetCount1 ;
        
        
        assetCount = SBR_3_0_AssetFilterController.getFilteredAssetsCount('SELECT count() FROM Asset WHERE SM_PS_Cat_Class__c =\'0090100\'','01');
        assetListWithFilter = SBR_3_0_AssetFilterController.getFilteredAssets('SELECT Id FROM Asset WHERE SM_PS_Cat_Class__c =\'0090100\'','01');
         
        System.assertEquals(assetCount,assetList.size(),'Asset Count Query is failing');
        System.assertEquals(assetListWithFilter.size(),assetList.size(),'Asset Query is failing');
        
        //Exception Block
        try{
        	assetCount1 = SBR_3_0_AssetFilterController.getFilteredAssetsCount('SELECT count() FROM Asset WHERE SM_PS_Cat_Class__c =:\'0090100\'','01');
        }catch(Exception e){
             System.assert(e!=null,'Exception Occured');
        }
        try{
        	assetListWithFilter1 = SBR_3_0_AssetFilterController.getFilteredAssets('SELECT Id FROM Asset WHERE SM_PS_Cat_Class__c =:\'0090100\'','01');
        }catch(Exception e){
             System.assert(e!=null,'Exception Occured');
        }
        
    }
}