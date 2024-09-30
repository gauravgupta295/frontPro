/*********************************************************************************************************************
* Apex Class: SBR_3_0_FilterAssetInvocable_Test
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* @description- Test class for SBR_3_0_FilterAssetInvocable
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME                      DATE                 DETAIL FEATURES
    1.0         Shilpa Mitra                        2024-06-10           Initial Version
    2.0         Shilpa Mitra                        2024-06-17           Increased Code Coverage
*********************************************************************************************************************/
/**@description 
 * Test case for SBR_3_0_FilterAssetInvocable
*/
@IsTest
private class SBR_3_0_FilterAssetInvocable_Test {
    @IsTest
    static void allowedValuesStringSubClassTest() {
        //Asset Creation
        List<Asset> assetList = new List<Asset>();
        assetList = SBR_3_0_TestDataFactory.createAssets(1, FALSE); 
        assetList[0].SM_PS_Sub_Class__c = 075;
        assetList[0].SM_PS_Company_Code__c = '01';
        assetList[0].SM_PS_Category__c = '143';
        assetList[0].SM_PS_Cat_Class__c = '0090100';
        assetList[0].Status ='Available';
        insert assetList;
        
        SBR_3_0_FilterAssetInvocable.SBR_3_0_FilterInfo filterInfo = new SBR_3_0_FilterAssetInvocable.SBR_3_0_FilterInfo();
        filterInfo.fieldValueSubClass = 075;
        filterInfo.allowedValuesString = '01;02;03';

        List<SBR_3_0_FilterAssetInvocable.SBR_3_0_OutputVariables> results;
        
        Test.startTest();
        {
            results = SBR_3_0_FilterAssetInvocable.filterAsset(new List<SBR_3_0_FilterAssetInvocable.SBR_3_0_FilterInfo>{filterInfo});
        }
       
        Test.stopTest(); 
        
		Assert.areEqual(1, results.size(),'Wrapper Data is not as expected');
        Assert.areEqual(1, results[0].outputAssetList.size(),'No Asset found matching SubClass');
    }
}