/*********************************************************************************************************************
* Apex Class: SBR_3_0_CustomDataTableCmpController_Test
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Class to test SBR_3_0_CustomDataTableCmpController
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME                  DATE                    DETAIL FEATURES
    1.0         Joelle Ramiandrisoa           2022-08-17                Initial version    
*********************************************************************************************************************/
@isTest
public class SBR_3_0_CustomDataTableCmpCtrl_Test {
  static testMethod void testGetItemSearchColumns() {
    List<CustomDataTableCmpColumn__mdt> result = new List<CustomDataTableCmpColumn__mdt>();
    Test.startTest();
    result = SBR_3_0_CustomDataTableCmpController.getItemSearchColumns();
    Test.stopTest();
    System.assert(result.size() > 0);
  }

  static testMethod void testGetFilteredProducts() {
    List<Product2> prods = SBR_3_0_TestDataFactory.createProducts(1, true);
    prods[0].Status__c = 'A';
    update prods[0];
    List<Product2> result = new List<Product2>();

    Test.startTest();
    result = SBR_3_0_CustomDataTableCmpController.getFilteredProducts(
      0,
      '',
      50,
      '',
      ''
    );
    Test.stopTest();

    //System.assertEquals(1, result.size());
  }

  static testMethod void testgetOrderItemStatusOptions() {
    List<String> resultString = new List<String>();
    Test.startTest();
    resultString = SBR_3_0_CustomDataTableCmpController.getOrderItemStatusOptions();
    Test.stopTest();
  }

  
  static testMethod void getFilteredOrderItemstest() {
    // Create Price Book
    Pricebook2 priceBook = new Pricebook2(
      Id = Test.getStandardPricebookId(),
      IsActive = true
    );
    update priceBook;

    Id orderRecType = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName()
      .get('Order')
      .getRecordTypeId();
    Order o = SBR_3_0_TestDataFactory.createOrder(
      true,
      'Test Order',
      orderRecType
    );

    Test.startTest();
    List<OrderItem> oIList = SBR_3_0_CustomDataTableCmpController.getFilteredOrderItems(
      o.Id,
      1,
      1,
      '',
      ''
    );
    Test.StopTest();
    System.assertNotEquals(null, oIList);
  }

  static testMethod void testGetFilteredProductsForAssetInquiry() {
    List<Product2> prods = SBR_3_0_TestDataFactory.createProducts(1, true);
    prods[0].Status__c = 'A';
    update prods[0];
    List<Product2> result = new List<Product2>();

    Test.startTest();
    result = SBR_3_0_CustomDataTableCmpController.getFilteredProductsForAssetInquiry(
      0,
      '',
      50,
      '',
      ''
    );
    Test.stopTest();

    System.assertEquals(1, result.size());
  }

  static testMethod void testGetProductSuperCategories() {
    Id recordTypeId = Schema.SObjectType.Product_Hierarchy__c.getRecordTypeInfosByName()
      .get('Super Category')
      .getRecordTypeId();
    Id prodrecordTypeId = Schema.SObjectType.Product_Hierarchy__c.getRecordTypeInfosByName()
      .get('Product Category')
      .getRecordTypeId();
    Product_Hierarchy__c ph = new Product_Hierarchy__c(
      Name = 'Forklifts',
      RecordTypeId = recordTypeId,
      Product_Family_Type__c = 'Cat-Class',
      Product_Hierarchy_Code__c = '0303030'
    );
    insert ph;

    Product_Hierarchy__c ph1 = new Product_Hierarchy__c(
      Name = 'Test PH1',
      RecordTypeId = prodrecordTypeId,
      Product_Family_Type__c = 'Cat-Class',
      Product_Hierarchy_Code__c = '0303031',
      Parent_Code__c = ph.id
    );
    insert ph1;

    List<Product_Hierarchy__c> result = new List<Product_Hierarchy__c>();

    Test.startTest();
    result = SBR_3_0_CustomDataTableCmpController.getProductSuperCategories();
    Test.stopTest();
  }

    static testMethod void testGetFilteredAssets()
    {
        
    Integer offset = 0;
    Integer batchSize = 50;
    String searchKey = 'Test';

    List<Schema.Location> locs = new List<Schema.Location>();
    locs = SBR_3_0_TestDataFactory.createInventoryLocations(1, false, 'Branch');
    Schema.Location loc = locs[0];
    loc.District__c = 'BALTIMORE DELAWARE DISTRICT';
    loc.Region__c = 'REGION 02';
    loc.Territory__c = 'EAST TERRITORY';
    loc.Company__c = 'SUNBELT RENTALS';
    insert locs;

    List<Product2> products = SBR_3_0_TestDataFactory.createProducts(1, false);
    products[0].Name = 'Test Optional SKU';
    products[0].Sell_Price__c = 10;
    products[0].Product_SKU__c = '657657';
    products[0].Status__c = 'A';
    insert products;

    string whereClause =
      'Product2.Product_SKU__c IN (\'' +
      products[0].Product_SKU__c +
      '\') AND SM_PS_Current_Location__c = \'' +
      locs[0].id +
      '\'';

    System.debug('TEST whereClause :' + whereClause);
    System.debug('TEST searchKey :' + searchKey);

    List<Account> newAccList = SBR_3_0_TestDataFactory.createAccounts(1, false);
    insert newAccList;

    List<Asset> lstAssets = SBR_3_0_TestDataFactory.createAssets(1, false);
    lstAssets[0].SM_PS_Current_Location__c = locs[0].id;
    lstAssets[0].Product2Id = products[0].id;
    lstAssets[0].AccountId = newAccList[0].Id;
    insert lstAssets;
    List<Asset> results = new List<Asset>();

    List<SBR_3_0_CustomDataTableCmpController.Category_Details> prodCategories = new List<SBR_3_0_CustomDataTableCmpController.Category_Details>();

    Id recordTypeId = Schema.SObjectType.Product_Hierarchy__c.getRecordTypeInfosByName()
      .get('Super Category')
      .getRecordTypeId();
    Id prodrecordTypeId = Schema.SObjectType.Product_Hierarchy__c.getRecordTypeInfosByName()
      .get('Product Category')
      .getRecordTypeId();
    Id prodSubrecordTypeId = Schema.SObjectType.Product_Hierarchy__c.getRecordTypeInfosByName()
      .get('Product Sub-Category')
      .getRecordTypeId();

    Product_Hierarchy__c ph = new Product_Hierarchy__c(
      Name = 'Forklifts',
      RecordTypeId = recordTypeId,
      Product_Family_Type__c = 'Cat-Class',
      Product_Hierarchy_Code__c = '0303030'
    );
    insert ph;

    Product_Hierarchy__c ph1 = new Product_Hierarchy__c(
      Name = 'Test PH1',
      RecordTypeId = prodrecordTypeId,
      Product_Family_Type__c = 'Cat-Class',
      Product_Hierarchy_Code__c = '0303031',
      Parent_Code__c = ph.id
    );
    insert ph1;

    Product_Hierarchy__c ph2 = new Product_Hierarchy__c(
      Name = 'Test PH2',
      RecordTypeId = prodSubrecordTypeId,
      Product_Family_Type__c = 'Cat-Class',
      Product_Hierarchy_Code__c = '0303032',
      Parent_Code__c = ph1.id
    );
    insert ph2;

    Test.startTest();
    SBR_3_0_CustomDataTableCmpController.getFilteredAssetsOtherLocations(
      offset,
      offset,
      batchSize,
      searchKey,
      whereClause,
      true,
      JSON.serialize(locs[0])
    );
    results = SBR_3_0_CustomDataTableCmpController.getFilteredAssets(
      offset,
      batchSize,
      searchKey,
      whereClause
    );
    searchKey = '';
    results = SBR_3_0_CustomDataTableCmpController.getFilteredAssets(
      offset,
      batchSize,
      searchKey,
      whereClause
    );
    whereClause = '';
    results = SBR_3_0_CustomDataTableCmpController.getFilteredAssets(
      0,
      50,
      'test',
      ''
    );
    prodCategories = SBR_3_0_CustomDataTableCmpController.getProductCategories(
      'All Items'
    );
    prodCategories = SBR_3_0_CustomDataTableCmpController.getProductCategories(
      'Forklifts'
    );
    SBR_3_0_CustomDataTableCmpController.Asset_Details assetDetailsResult = SBR_3_0_CustomDataTableCmpController.getAssetDetails(
      lstAssets[0].Id
    );
    System.assertEquals(true, prodCategories.size() > 0);

    Test.stopTest();
  }

  /*FRONT - 10481 : Test method added for getAllProductItemsForSalesProductInquiry */

  @isTest
  private static void testGetAllProductItemsForSalesProductInquiry() {
    List<Schema.Location> locs = new List<Schema.Location>();
    locs = SBR_3_0_TestDataFactory.createInventoryLocations(1, false, 'Branch');
    Schema.Location loc = locs[0];
    loc.District__c = 'BALTIMORE DELAWARE DISTRICT';
    loc.Region__c = 'REGION 02';
    loc.Territory__c = 'EAST TERRITORY';
    loc.Company__c = 'SUNBELT RENTALS';
    // insert locs;

    List<Product2> products = SBR_3_0_TestDataFactory.createProducts(1, false);
    products[0].Name = 'Test Optional SKU';
    products[0].Sell_Price__c = 10;
    products[0].Product_SKU__c = '657657';
    // insert products;

    Database.insert(new List<sObject>{ loc, products[0] });

    List<ProductItem> prodItms = SBR_3_0_TestDataFactory.createProductItems(
      1,
      false,
      products[0].Id,
      loc.Id
    );
    prodItms[0]
      .RecordTypeId = Schema.SObjectType.ProductItem.getRecordTypeInfosByDeveloperName()
      .get(
        SBR_3_0_Constants.PRODUCTITEM_PARTS_AND_MERCH_RECORDTYPE_DEVELOPERNAME
      )
      .getRecordTypeId();
    Database.insert(prodItms[0]);

    Test.startTest();
    List<ProductItem> pItemsFetched = SBR_3_0_CustomDataTableCmpController.getAllProductItemsForSalesProductInquiry();
    // System.debug('pItemsFetched >> '+pItemsFetched);
    System.assertEquals(true, pItemsFetched.size() > 0);
    Test.stopTest();
  }

  static testMethod void testGetFilteredProductsFL() {
    List<Product2> prods = SBR_3_0_TestDataFactory.createProducts(1, true);
    List<Product2> result = new List<Product2>();

    Test.startTest();
    result = SBR_3_0_CustomDataTableCmpController.getFilteredProductsFL(
      0,
      '',
      50,
      '',
      '',
      true
    );
    Test.stopTest();

    //System.assertEquals(1, result.size());
  }

  /* END : FRONT - 10481 */

}