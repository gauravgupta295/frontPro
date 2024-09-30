/*********************************************************************************************************************
* Apex Class: SBR_3_0_AssetInquiryController_Test
---------------------------------------------------------------------------------------------------------------------
* @description
* - Test class for SBR_3_0_AssetInquiryController
---------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
*   1.0         Ritesh Mohapatra        2023-05-15          Initial version
*   1.0         Chhavi Singhal          2024-03-14          Updated testAssetInquiryController() method 
*********************************************************************************************************************/
@isTest
public class SBR_3_0_AssetInquiryController_Test {
  @TestSetup
  static void makeData() {
    //Create User Location
    Id user = UserInfo.getUserId();
    List<Schema.Location> branch = SBR_3_0_TestDataFactory.createInventoryLocations(1, true, 'Branch');
    branch[0].Branch_Location_Number__c = '657';
    update branch[0];

    User_location__c userLocation = new User_location__c(branch__c = branch[0].Id,
                                 User__c = user);
    insert userLocation;

    RecordType rt = [SELECT Id, DeveloperName, IsActive, Name, SobjectType
               FROM RecordType
             WHERE IsActive = TRUE AND SobjectType = 'Asset' AND Name = 'Rental Asset'];

    //Create Asset
    Asset newAsset = new Asset();
    newAsset.RecordTypeId = rt.Id;
    newAsset.SM_PS_Current_Location__c = branch[0].id;
    newAsset.SM_PS_Assigned_Location__c = branch[0].id;
    newAsset.Status = 'Available';
    newAsset.Name = '112233';
    newAsset.SM_PS_Category__c = '657';
    newAsset.SM_PS_Class__c = '657';
    newAsset.Status = 'Available';
    newAsset.SM_PS_Company_Code__c = '01';
    newAsset.SM_PS_Cat_Class__c = 'TESTCATCLASS';
    newAsset.SM_PS_Last_Transaction_Date__c = Date.today();
    insert newAsset;

    List<Product2> lstProds = SBR_3_0_TestDataFactory.createProducts(1, true);
    lstProds[0].Name = 'Test Product 11';
    update lstProds[0];
      
  }

  @isTest
  public static void testAssetInquiryController() {
    Id supCatRecordTypeId = Schema.SObjectType.Product_Hierarchy__c.getRecordTypeInfosByName().get('Super Category').getRecordTypeId();
    Id catRecordTypeId = Schema.SObjectType.Product_Hierarchy__c.getRecordTypeInfosByName().get('Product Category').getRecordTypeId();
    Id subCatRecordTypeId = Schema.SObjectType.Product_Hierarchy__c.getRecordTypeInfosByName().get('Product Sub-Category').getRecordTypeId();
    
    Product_Hierarchy__c testParentCode = new Product_Hierarchy__c(Name = 'Test Parent Code',
                                                                   Product_Hierarchy_Code__c = '1234',
                                                                   RecordTypeId = supCatRecordTypeId);
    insert testParentCode;
      
    Product_Hierarchy__c testParentCode2 = new Product_Hierarchy__c(Name = 'Test Parent Code 2',
                                                                    Product_Hierarchy_Code__c = '1111',
                                                                    RecordTypeId = supCatRecordTypeId);
    insert testParentCode2;

    Product_Hierarchy__c testProductCategory = new Product_Hierarchy__c(Name = 'Test Product Category',
                                                                        Parent_Code__c = testParentCode.Id,
                                                                        Product_Hierarchy_Code__c = '4562',
                                                                        RecordTypeId = catRecordTypeId); 
    testProductCategory.Filter_Level__c = '2';
    testProductCategory.Product_Family_Type__c = 'Cat-Class';
    insert testProductCategory;
      
    Product_Hierarchy__c testProductCategory2 = new Product_Hierarchy__c(Name = 'Test Product Category',
                                                                         Parent_Code__c = testParentCode2.Id,
                                                                         Product_Hierarchy_Code__c = '7894',
                                                                         RecordTypeId = CatRecordTypeId); 
    testProductCategory2.Filter_Level__c = '2';
    testProductCategory2.Product_Family_Type__c = 'Cat-Class';
    insert testProductCategory2;

    Product_Hierarchy__c testProdSubCategory = new Product_Hierarchy__c(Name = 'Test Product Sub-Category',
                                                                        Parent_Code__c = testProductCategory.Id,
                                                                        Product_Hierarchy_Code__c = '3685',
                                                                        Product_Family_Type__c = 'Cat-Class',
                                                                        RecordTypeID = subCatRecordTypeId, 
                                                                        Filter_Level__c = '3');
    insert testProdSubCategory;
      
    Product_Hierarchy__c testProductClass = new Product_Hierarchy__c(Name = 'Test Product Class',
                                                                     Parent_Code__c = testProductCategory2.Id,
                                                                     Product_Hierarchy_Code__c = '2233',
                                                                     Filter_Level__c = '2',
                                                                     RecordTypeId = CatRecordTypeId);
    insert testProductClass;
      
    List<Product_Hierarchy__c> categoryOptions = new List<Product_Hierarchy__c>();
    categoryOptions.add(testProductCategory);
    categoryOptions.add(testProdSubCategory);

    Schema.Location branch = [SELECT Id, Name, Branch_Location_Name__c, Branch_Location_Number__c, City__c, State__c,
                                     Zip_Code__c, District__c, Region__c, Territory__c,Company__c
                    FROM Location
                    LIMIT 1];

    Test.startTest();
        SBR_3_0_AssetInquiryController.getPicklistMetadata('Level');

        SBR_3_0_AssetInquiryController.getCurrentUserLocation();
        SBR_3_0_AssetInquiryController.getBranchLocation('657');
        SBR_3_0_AssetInquiryController.getBranchDetails(string.valueOf(branch.id));
        
          SBR_3_0_AssetInquiryController.getFilteredAssetsCount('SELECT Count() FROM Asset');
          SBR_3_0_AssetInquiryController.getFilteredAssets('SELECT Id FROM Asset');
          
          SBR_3_0_AssetInquiryController.getProductsForSelection('SELECT Id FROM Product2');
          SBR_3_0_AssetInquiryController.getPickListValuesFromFields('Asset','Status');
          
          SBR_3_0_AssetInquiryController.getProductSuperCategories();
          SBR_3_0_AssetInquiryController.removeDuplicateCategories(categoryOptions);
          
          SBR_3_0_AssetInquiryController.SBR_3_0_CategoryDetails catDetailsList = new SBR_3_0_AssetInquiryController.SBR_3_0_CategoryDetails(testProductClass);
          List<SBR_3_0_AssetInquiryController.SBR_3_0_CategoryDetails> wrapperList = SBR_3_0_AssetInquiryController.getProductCategories('All Items');
          List<SBR_3_0_AssetInquiryController.SBR_3_0_CategoryDetails> wrapperList2 = SBR_3_0_AssetInquiryController.getProductCategories('Test Parent Code');
          
          System.assertEquals(catDetailsList.Name,'Test Product Class','');
          System.assertEquals(wrapperList.size(), 1, '');
          System.assertEquals(wrapperList2.size(), 1, '');
      Test.stopTest();
  }
}