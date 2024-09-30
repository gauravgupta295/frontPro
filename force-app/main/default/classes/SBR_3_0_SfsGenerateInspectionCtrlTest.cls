/*********************************************************************************************************************
* Apex Class: SBR_3_0_SfsGenerateInspectionCtrlTest
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Test class for SBR_3_0_SfsGenerateInspectionController
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION       DATE               DETAIL FEATURES
    1.0          2023-02-23          Vikas Kumar-Initial version 
    2.0          2023-10-17          Vikas Kumar- Added pricebook
**********************************************************************************************************************************************/
@isTest
public class SBR_3_0_SfsGenerateInspectionCtrlTest {
    
     @isTest 
    static void getOpenWOToAssetTest(){
         workOrder wo = SBR_3_0_ServiceTestDataFactory.createWorkOrder(false);
         Asset ass =  SBR_3_0_ServiceTestDataFactory.createAsset(true);
         wo.AssetId=ass.Id;
         List<WorkOrder> openWo=SBR_3_0_SfsGenerateInspectionController.getOpenWOToAsset(ass.Id);
         Assert.areEqual(openWo.size(),0);
    }
    
    
     @isTest 
    static void getStdPriceBookTest(){
          // pricebook
          Id pricebookId = Test.getStandardPricebookId();
          Pricebook2 standardPricebook = new Pricebook2(Id = pricebookId,IsActive = true);
          update standardPricebook;
          Pricebook2 stdPriceBook =SBR_3_0_SfsGenerateInspectionController.getStdPriceBook();
          System.debug(stdPriceBook);
          Assert.areEqual(stdPriceBook.Id,pricebookId);
        
    }
    
    @isTest 
    static void getAssetByIdTest(){
         Asset ass =  SBR_3_0_ServiceTestDataFactory.createAsset(true);
         Asset asset =  SBR_3_0_SfsGenerateInspectionController.getAssetById(ass.Id);
         Assert.areEqual(ass.Id,asset.Id);
      
    }

}