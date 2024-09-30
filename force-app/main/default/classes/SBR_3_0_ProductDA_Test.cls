/*********************************************************************************************************************
* Apex Class: SBR_3_0_ProductDA_Test
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Class to test SBR_3_0_ProductDA
* - 
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
1.0         Saathvik Tulasi      2023-01-11             Initial version    
*********************************************************************************************************************/
@isTest(seeAllData=false)
public class SBR_3_0_ProductDA_Test {
  @TestSetup
  static void makeData() {
    Pricebook2 priceBook = new Pricebook2(
      Id = Test.getStandardPricebookId(),
      IsActive = true
    );
    update priceBook;
    // Create Account
    Account acct = new Account();
    acct.RM_Account_Number__c = '4';
    acct.Company_Code__c = '01';
    acct.Name = 'Test Account';
    acct.BillingStreet = '4700 REAGAN DRIVE';
    acct.BillingCity = 'CHARLOTTE ';
    acct.BillingPostalCode = '28206';
    acct.BillingState = 'NC';
    acct.BillingCountry = 'US';
    acct.Phone = '9232343434';
    insert acct;
    // Create Location
    Schema.Location jobLocation = new Schema.Location();
    jobLocation.Name = 'Test Job Location';
    jobLocation.Street_Address__c = '4700 REAGAN DRIVE';
    jobLocation.City__c = 'CHARLOTTE';
    jobLocation.Zip_Code__c = '28206';
    jobLocation.State__c = 'NC';
    jobLocation.Country__c = 'US';
    jobLocation.RecordTypeId = SBR_3_0_Constants.LOCATION_JOB_RT_ID;
    insert jobLocation;
    // Create Branch
    Schema.Location branchLocation = new Schema.Location();
    branchLocation.Branch_Location_Number__c = '720';
    branchLocation.Name = 'Test Branch Location';
    branchLocation.Street_Address__c = '4700 REAGAN DRIVE';
    branchLocation.City__c = 'CHARLOTTE';
    branchLocation.Zip_Code__c = '28206';
    branchLocation.State__c = 'NC';
    branchLocation.Country__c = 'US';
    branchLocation.Job_Number__c = '332112';
    branchLocation.RecordTypeId = SBR_3_0_Constants.LOCATION_BRANCH_RT_ID;
    branchLocation.Company_Code__c = '01';
    insert branchLocation;
    // Create Job Site
    AssociatedLocation jobSite = new AssociatedLocation(
      Name__c = 'Test Job Site',
      ParentRecordId = acct.Id,
      LocationId = jobLocation.Id,
      Branch__c = branchLocation.Id,
      Job_Number__c = '20221004A'
    );
    insert jobSite;

    /*  Product_Hierarchy__c prdHierachy = new Product_Hierarchy__c(
			Name = 'Test Hierarchy',
			Product_Hierarchy_Code__c = 'Test_HR_Code',
			RecordTypeId = SBR_3_0_Constants.PRODUCT_HIERARCHY_PRODUCT_SUB_CATEGORY_RT_ID
		);
		insert prdHierachy; */
    // Create Product
    Product2 prod = new Product2(
      Name = 'Fuel Convenience Charge',
      Product_Title_Internal__c = 'Test Product 1',
      Product_SKU__c = '1234567',
      Product_Type__c = 'Cat-Class'
    );
    Product2 prod2 = new Product2(
      Name = 'Test Product 2',
      Product_Title_Internal__c = 'Test Product 2',
      Product_SKU__c = '01-PIPSA-817633',
      Product_Type__c = 'Merchandise'
    );
    insert prod;
    insert prod2;
    // Create Quote
    SBQQ__Quote__c quote = new SBQQ__Quote__c(
      Quote_Name__c = 'Test Quote',
      SBQQ__Account__c = acct.Id,
      Jobsite__c = jobSite.Id
    );
    insert quote;
    // Create Quote Line Item

    List<SBQQ__QuoteLine__c> lineItems = new List<SBQQ__QuoteLine__c>();
    lineItems.add(
      new SBQQ__QuoteLine__c(
        SBQQ__Quote__c = quote.Id,
        SBQQ__Product__c = prod2.Id,
        Line_Item_Type__c = 'VR',
        Fuel_Plan__c = true,
        Product_SKU_Text__c = '1234567',
        Start_Date__c = Datetime.now().addDays(2),
        Line_Name__c = 'test line name 1'
      )
    );
    lineItems.add(
      new SBQQ__QuoteLine__c(
        SBQQ__Quote__c = quote.Id,
        Kit_Number_this_Item_Belongs_to__c = '1234567',
        SBQQ__Product__c = prod.Id,
        Line_Name__c = 'test line name',
        Start_Date__c = Datetime.now().addDays(2)
      )
    );

    insert lineItems;
  }
  /************************************************************* Cover getProductByExternalId Starts*************************************************************/
  public static testMethod void getProductByExternalId() {
    Profile oProfile = [
      SELECT Id
      FROM Profile
      WHERE Name = 'System Administrator'
    ];
    User oUsers = SBR_3_0_TestDataFactory.createUser(false, oProfile);
    oUsers.CompanyName = '02';
    List<Product2> lProducts = SBR_3_0_TestDataFactory.createProducts(1, false);
    Set<String> externalIds = new Set<String>();
    integer i = 0;
    for (Product2 oProduct : lProducts) {
      Integer randomNumber = Integer.valueof((Math.random() * 10000)) + i;
      oProduct.Product_SKU__c = String.valueOf(randomNumber);
      externalIds.add(String.valueOf(randomNumber));
      i++;
    }
    insert lProducts;
    Map<String, Product2> mProducts = new Map<String, Product2>();
    Product2 mproduct;
    Id productId;

    System.runAs(oUsers) {
      Test.startTest();
      mProducts = SBR_3_0_ProductDA.getProductByExternalId(externalIds);
      productId = mProducts.values()[0].Id;
      mproduct = SBR_3_0_ProductDA.getProductById(productId);
      Test.stopTest();
    }
    System.assertEquals(mProducts.size(), 1);
    System.assertEquals(mproduct.Id, productId);
  }
  /************************************************************* Cover getProductByExternalId Ends*************************************************************/
  /************************************************************* Cover getProductHierarchyByCode Starts*************************************************************/
  public static testMethod void getProductHierarchyByCode() {
    Profile oProfile = [
      SELECT Id
      FROM Profile
      WHERE Name = 'System Administrator'
    ];
    User oUsers = SBR_3_0_TestDataFactory.createUser(true, oProfile);
    Product_Hierarchy__c oPH = SBR_3_0_TestDataFactory.createProductHierarchies(
      true,
      'Test'
    );
    Set<String> externalIds = new Set<String>();
    String productHierarchyCode = '1234';
    System.runAs(oUsers) {
      Test.startTest();
      Product_Hierarchy__c oPHRes = SBR_3_0_ProductDA.getProductHierarchyByCode(
        productHierarchyCode
      );
      Test.stopTest();
      System.assertEquals(
        productHierarchyCode,
        oPHRes.Product_Hierarchy_Code__c
      );
    }
  }
  public static testMethod void getProductHierarchyByCodeNULL() {
    Profile oProfile = [
      SELECT Id
      FROM Profile
      WHERE Name = 'System Administrator'
    ];
    User oUsers = SBR_3_0_TestDataFactory.createUser(true, oProfile);
    Product_Hierarchy__c oPH = SBR_3_0_TestDataFactory.createProductHierarchies(
      true,
      'Test'
    );
    Set<String> externalIds = new Set<String>();
    String productHierarchyCode = '12345';
    System.runAs(oUsers) {
      Test.startTest();
      Product_Hierarchy__c oPHRes = new Product_Hierarchy__c();
      try {
        oPHRes = SBR_3_0_ProductDA.getProductHierarchyByCode(
          productHierarchyCode
        );
      } catch (Exception e) {
      }
      Test.stopTest();
      System.assertEquals(oPHRes, null);
    }
  }
  /************************************************************* Cover getProductHierarchyByCode Ends*************************************************************/
  /************************************************************* Cover getProductFeatures Starts*************************************************************/
  public static testMethod void getProductFeatures() {
    Profile oProfile = [
      SELECT Id
      FROM Profile
      WHERE Name = 'System Administrator'
    ];
    User oUsers = SBR_3_0_TestDataFactory.createUser(true, oProfile);
    List<Product2> lProducts = SBR_3_0_TestDataFactory.createProducts(1, true);
    SBQQ__ProductFeature__c oPF = SBR_3_0_TestDataFactory.createProductFeatures(
      true,
      lProducts[0].id
    );
    System.runAs(oUsers) {
      Test.startTest();
      Map<String, SBQQ__ProductFeature__c> mProductFeature = SBR_3_0_ProductDA.getProductFeatures(
        lProducts[0].id
      );
      Test.stopTest();
    }
  }
  /************************************************************* Cover getProductFeatures Ends*************************************************************/
  /************************************************************* Cover getMessageRecordsByExternalId Starts*************************************************************/
  public static testMethod void getMessageRecordsByExternalId() {
    Profile oProfile = [
      SELECT Id
      FROM Profile
      WHERE Name = 'System Administrator'
    ];
    User oUsers = SBR_3_0_TestDataFactory.createUser(true, oProfile);
    List<Product2> lProducts = SBR_3_0_TestDataFactory.createProducts(1, true);
    Message__c oMessage = SBR_3_0_TestDataFactory.createMessage(true, '1234');
    Set<String> externalIds = new Set<String>();
    externalIds.add('1234');
    System.runAs(oUsers) {
      Test.startTest();
      Map<String, Message__c> mMessages = SBR_3_0_ProductDA.getMessageRecordsByExternalId(
        externalIds
      );
      Test.stopTest();
    }
  }
  /************************************************************* Cover getMessageRecordsByExternalId Ends*************************************************************/
  /************************************************************* Cover getProductMessages Starts*************************************************************/
  public static testMethod void getProductMessages() {
    Profile oProfile = [
      SELECT Id
      FROM Profile
      WHERE Name = 'System Administrator'
    ];
    User oUsers = SBR_3_0_TestDataFactory.createUser(true, oProfile);
    List<Product2> lProducts = SBR_3_0_TestDataFactory.createProducts(1, true);
    Product_Message__c oPM = SBR_3_0_TestDataFactory.createProductMessage(
      true,
      lProducts[0].id
    );
    System.runAs(oUsers) {
      Test.startTest();
      Map<String, Product_Message__c> mPM = SBR_3_0_ProductDA.getProductMessages(
        lProducts[0].id
      );
      Test.stopTest();
    }
  }

  /************************************************************* Cover getProductMessages Ends*************************************************************/
  /************************************************************* Cover getProductOptions Starts*************************************************************/

  public static testMethod void getProductOptions() {
    Profile oProfile = [
      SELECT Id
      FROM Profile
      WHERE Name = 'System Administrator'
    ];
    User oUsers = SBR_3_0_TestDataFactory.createUser(true, oProfile);
    List<Product2> lProducts = SBR_3_0_TestDataFactory.createProducts(1, true);
    SBQQ__ProductOption__c oPO = SBR_3_0_TestDataFactory.createMessage(
      true,
      lProducts[0].id
    );
    System.runAs(oUsers) {
      Test.startTest();
      Map<String, SBQQ__ProductOption__c> mPO = SBR_3_0_ProductDA.getProductOptions(
        lProducts[0].id
      );
      Test.stopTest();
    }
  }
  /************************************************************* Cover getProductOptions Ends*************************************************************/
  /************************************************************* Cover getProductsById Starts*************************************************************/
  public static testMethod void getProductsById() {
    Profile oProfile = [
      SELECT Id
      FROM Profile
      WHERE Name = 'System Administrator'
    ];
    User oUsers = SBR_3_0_TestDataFactory.createUser(true, oProfile);
    List<Product2> lProducts = SBR_3_0_TestDataFactory.createProducts(3, true);
    Set<String> sProductIds = new Set<String>();
    for (Product2 oProduct : lProducts) {
      sProductIds.add(oProduct.id);
    }
    System.runAs(oUsers) {
      Test.startTest();
      Map<String, Product2> mapProducts = SBR_3_0_ProductDA.getProductsById(
        sProductIds
      );
      Map<String, Product2> mapDeliveryProducts = SBR_3_0_ProductDA.getDeliveryPickupProds();
      List<Product2> productList = SBR_3_0_ProductDA.getdlvrGenericProducts();
      Test.stopTest();
    }
  }
  public static testMethod void getGenericProductForEachCompanyCodes() {
    Test.startTest();
    Map<String, Product2> result = SBR_3_0_ProductDA.getGenericProductForEachCompanyCodes();

    Test.stopTest();
  }

  public static testMethod void getProductCategoryOptions() {
    // Create test data

    Product_Hierarchy__c testParentCode = new Product_Hierarchy__c(
      Name = 'Test Parent Code',
      Product_Hierarchy_Code__c = '1234'
    );
    insert testParentCode;
    Product_Hierarchy__c testProductCategory = new Product_Hierarchy__c(
      Name = 'Test Product Category',
      Parent_Code__c = testParentCode.Id,
      Product_Hierarchy_Code__c = '1243'
    ); // Replace with Product Sub-Category record type Id
    insert testProductCategory;
    Product_Hierarchy__c testProductClass = new Product_Hierarchy__c(
      Name = 'Test Product Class',
      Parent_Code__c = testParentCode.Id,
      Product_Hierarchy_Code__c = '1244'
    ); // Replace with Product Class record type Id
    insert testProductClass;

    // Test without filters
    List<Product_Hierarchy__c> allProducts = SBR_3_0_ProductDA.getProductCategoryOptions(
      null,
      null,
      null,
      false,
      false
    );
    //System.assertEquals(2, allProducts.size());

    // Test with filterLevel
    List<Product_Hierarchy__c> filteredProducts = SBR_3_0_ProductDA.getProductCategoryOptions(
      1,
      null,
      null,
      false,
      false
    );
    //System.assertEquals(2, filteredProducts.size());

    // Test with parentCodeName
    List<Product_Hierarchy__c> filteredProductsByName = SBR_3_0_ProductDA.getProductCategoryOptions(
      null,
      'Test Parent Code',
      null,
      false,
      false
    );
    //System.assertEquals(2, filteredProductsByName.size());

    // Test with parentCodeIds
    Set<Id> parentCodeIds = new Set<Id>{ testParentCode.Id };
    List<Product_Hierarchy__c> filteredProductsByIds = SBR_3_0_ProductDA.getProductCategoryOptions(
      null,
      null,
      parentCodeIds,
      false,
      false
    );
    //System.assertEquals(2, filteredProductsByIds.size());

    // Test with isSubCategory
    List<Product_Hierarchy__c> subCategories = SBR_3_0_ProductDA.getProductCategoryOptions(
      null,
      null,
      null,
      true,
      false
    );
    // System.assertEquals(1, subCategories.size());
    //System.assertEquals('Test Product Category', subCategories[0].Name);

    // Test with orderByName
    List<Product_Hierarchy__c> orderedProducts = SBR_3_0_ProductDA.getProductCategoryOptions(
      null,
      null,
      null,
      false,
      true
    );
    //System.assertEquals('Test Product Category', orderedProducts[0].Name);
    // System.assertEquals('Test Product Class', orderedProducts[1].Name);
  }

  public static testMethod void getEdLabourproductTest() {
    Pricebook2 stdpriceBook = new Pricebook2(
      Id = Test.getStandardPricebookId(),
      IsActive = true
    );
    update stdpriceBook;

    //Create Products
    List<Product2> products = new List<Product2>();
    for (Integer i = 0; i < 3; i++) {
      Product2 product = new Product2();
      product.Name = 'Test Product ' + i;
      if (i == 0) {
        product.Product_Type__c = 'Cat-Class';
        product.Product_SKU__c = '123456';
        product.Category__c = '32134';
        product.Class__c = '2039';
        product.ToolFlex__c = 'N';
      } else if (i == 1) {
        product.Product_Type__c = 'Parts';
        product.Item_Number__c = '1234GH';
        product.Stock_Class__c = 'AIMFV';
      } else {
        product.Product_Type__c = '';
        product.Item_Number__c = '1285JC';
        product.Stock_Class__c = 'UJEKL';
      }
      products.add(product);
    }
    insert products;
    Test.startTest();
    // Call the method being tested
    List<Product2> results = SBR_3_0_ProductDA.getEDLaborProduct();
    Test.stopTest();
  }

  public static testMethod void testgetGenericProductForEachCompanyCodes() {
    Pricebook2 stdpriceBook = new Pricebook2(
      Id = Test.getStandardPricebookId(),
      IsActive = true
    );
    update stdpriceBook;

    List<Product2> products = new List<Product2>();
    for (Integer i = 0; i < 3; i++) {
      Product2 product = new Product2();
      product.Name = 'Test Product ' + i;
      if (i == 0) {
        product.Product_Type__c = 'Cat-Class';
        product.Product_SKU__c = '123456';
        product.Category__c = '32134';
        product.Class__c = '2039';
        product.ToolFlex__c = 'N';
      } else if (i == 1) {
        product.Product_Type__c = 'Parts';
        product.Item_Number__c = '1234GH';
        product.Stock_Class__c = 'AIMFV';
      } else {
        product.Product_Type__c = '';
        product.Item_Number__c = '1285JC';
        product.Stock_Class__c = 'UJEKL';
      }
      products.add(product);
    }
    insert products;

    Map<String, Product2> results = SBR_3_0_ProductDA.getGenericProductForEachCompanyCodes();
  }
  public static testMethod void testGetProductsByProductSKU() {
    // Step 1: Create a set of product SKUs to test with
    Set<String> testSKUs = new Set<String>{ 'SKU1', 'SKU2', 'SKU3' };

    // Step 2: Insert some Product2 records with matching SKUs
    Pricebook2 stdpriceBook = new Pricebook2(
      Id = Test.getStandardPricebookId(),
      IsActive = true
    );
    update stdpriceBook;

    List<Product2> products = new List<Product2>();
    for (Integer i = 0; i < 3; i++) {
      Product2 product = new Product2();
      product.Name = 'Test Product ' + i;
      if (i == 0) {
        product.Product_Type__c = 'Cat-Class';
        product.Product_SKU__c = 'SKU1';
        product.Category__c = '32134';
        product.Class__c = '2039';
        product.ToolFlex__c = 'N';
      } else if (i == 1) {
        product.Product_Type__c = 'Parts';
        product.Item_Number__c = '1234GH';
        product.Stock_Class__c = 'AIMFV';
      } else {
        product.Product_Type__c = '';
        product.Item_Number__c = '1285JC';
        product.Stock_Class__c = 'UJEKL';
      }
      products.add(product);
    }
    insert products;
    Test.startTest();
    // Step 3: Call the method with the test SKUs
    List<Product2> matchingProducts = SBR_3_0_ProductDA.getProductsByProductSKU(
      testSKUs
    );
    Test.stopTest();
    // Step 4: Verify the results
    // System.assertEquals(3, matchingProducts.size(), 'Unexpected number of matching products');
  }

  static List<Product2> lstProds;
  static List<Schema.ProductItem> productItems;
  static List<Schema.Location> locs;

  public static testMethod void testfetchProductItemById() {
    lstProds = SBR_3_0_TestDataFactory.createProducts(1, true);
    // Create a Location
    locs = SBR_3_0_TestDataFactory.createInventoryLocations(1, false, 'Branch');
    Schema.Location loc = locs[0];
    loc.District__c = 'BALTIMORE DELAWARE DISTRICT';
    loc.Region__c = 'REGION 02';
    loc.Territory__c = 'EAST TERRITORY';
    loc.Company__c = 'SUNBELT RENTALS';
    insert locs;

    // Create a Product Item
    productItems = SBR_3_0_TestDataFactory.createProductItems(
      1,
      false,
      lstProds[0].id,
      locs[0].id
    );
    Schema.ProductItem pi = productItems[0];
    pi.SM_PS_Cat_Class__c = '0090030';
    pi.SM_PS_Quantity_Available__c = 10;
    pi.SM_PS_Quantity_Reserved__c = 5;
    pi.SM_PS_Quantity_on_Scheduled_Pick_Up__c = 7;
    pi.SM_PS_Quantity_on_Rent__c = 15;
    pi.SM_PS_Number_of_Rental_Units__c = 32;
    insert productItems;

    Set<Id> testIds = new Set<Id>();
    for (ProductItem item : productItems) {
      testIds.add(item.Id);
    }
    List<ProductItem> resultItems1;
    List<ProductItem> resultItems2;
    Test.startTest();
    resultItems1 = SBR_3_0_ProductDA.fetchProductItemById(testIds);
    resultItems2 = SBR_3_0_ProductDA.fetchProductItemByIdandLocationId(
      new Set<Id>{ lstProds[0].id },
      new Set<Id>{ locs[0].id }
    );
    Test.stopTest();
  }

  public static testMethod void testgetProductOptionsWithCompanyCode() {
    String testCompanyCode = 'ABC';

    Pricebook2 stdpriceBook = new Pricebook2(
      Id = Test.getStandardPricebookId(),
      IsActive = true
    );
    update stdpriceBook;

    List<Product2> products = new List<Product2>();
    for (Integer i = 0; i < 3; i++) {
      Product2 product = new Product2();
      product.Name = 'Test Product ' + i;
      if (i == 0) {
        product.Product_Type__c = 'Cat-Class';
        product.Product_SKU__c = 'SKU1';
        product.Category__c = '32134';
        product.Class__c = '2039';
        product.ToolFlex__c = 'N';
        product.Company_Code__c = '01';
      } else if (i == 1) {
        product.Product_Type__c = 'Parts';
        product.Item_Number__c = '1234GH';
        product.Stock_Class__c = 'AIMFV';
      } else {
        product.Product_Type__c = '';
        product.Item_Number__c = '1285JC';
        product.Stock_Class__c = 'UJEKL';
        product.Company_Code__c = '01';
      }
      products.add(product);
    }
    //creating products
    insert products;
    Product_Hierarchy__c prdHierachy = new Product_Hierarchy__c(
      Name = 'Test Hierarchy',
      Product_Hierarchy_Code__c = 'Test_HR_Code',
      RecordTypeId = SBR_3_0_Constants.PRODUCT_HIERARCHY_PRODUCT_SUB_CATEGORY_RT_ID
    );
    insert prdHierachy;
    //creating product hierarchy
    Product2 prod = new Product2(
      Name = 'Test Product 1',
      Product_Title_Internal__c = 'Test Product 1',
      Product_SKU__c = '123001',
      Product_Hierarchy__c = prdHierachy.Id,
      Product_Type__c = 'Cat-Class'
    );
    insert prod;
    //creating prod

    //creating product hierarchy
    SBQQ__ProductFeature__c featureObj = new SBQQ__ProductFeature__c(
      Name = 'Sales Addons',
      Product_Feature_Load_Ext_ID__c = prod.Product_SKU__c +
        '_' +
        'Sales Addons',
      SBQQ__ConfiguredSKU__c = prod.Id,
      SBQQ__MinOptionCount__c = 1,
      SBQQ__Number__c = 1
    );
    insert featureObj;
    //Creating Product Message
    Product2 prod2 = new Product2(
      Name = 'Test Product 3',
      Product_Title_Internal__c = 'Test Product 3',
      Product_SKU__c = '123003',
      Product_Hierarchy__c = prdHierachy.Id,
      Product_Type__c = 'Cat-Class'
    );
    insert prod2;
    SBQQ__ProductOption__c prodOption = new SBQQ__ProductOption__c(
      Product_Optional_SKU__c = '123001-123003',
      SBQQ__ConfiguredSKU__c = prod.Id,
      SBQQ__OptionalSKU__c = prod2.Id,
      SBQQ__Number__c = 1,
      SBQQ__Feature__c = featureObj.Id
    );
    insert prodOption;
    //creating product options

    Test.startTest();
    List<SBQQ__ProductOption__c> result = SBR_3_0_ProductDA.getProductOptionsWithCompanyCode(
      prod.ID,
      testCompanyCode,
      'Sales Addons'
    );
    Map<String, Product2> mapProducts = SBR_3_0_ProductDA.getItemClassProduct(
      '1285JC',
      'UJEKL',
      '01'
    );
    List<SBQQ__ProductOption__c> productOptions = SBR_3_0_ProductDA.getProductOptionsForProducts(
      new List<String>{ 'SKU1' },
      '01',
      'Sales Addons'
    );
    String productOptionForLineItems = SBR_3_0_ProductDA.getProductOptionForLineItems(
      new List<String>{ 'SKU1' },
      new List<String>{ '234567' }
    );
    System.AssertNotEquals(String.isBlank(productOptionForLineItems), true);
    Test.stopTest();
  }

  public static testMethod void testgetAlternateProducts() {
    Pricebook2 stdpriceBook = new Pricebook2(
      Id = Test.getStandardPricebookId(),
      IsActive = true
    );
    update stdpriceBook;

    Product_Hierarchy__c prdHierachy = new Product_Hierarchy__c(
      Name = 'Test Hierarchy',
      Product_Hierarchy_Code__c = 'Test_HR_Code',
      RecordTypeId = SBR_3_0_Constants.PRODUCT_HIERARCHY_PRODUCT_SUB_CATEGORY_RT_ID
    );
    insert prdHierachy;
    // Create test products with matching and non-matching criteria
    Product2 matchingProduct = new Product2(
      Name = 'Matching Product',
      Product_SKU__c = 'SKU-001',
      Sell_Price__c = 100,
      // Product_Category__c = 'Category A',
      // Product_Sub_Category__c = 'Subcategory A',
      RecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName()
        .get('SKU')
        .getRecordTypeId(),
      Company_Code__c = 'Code A',
      Product_Type__c = 'Cat-Class',
      Product_Hierarchy__c = prdHierachy.Id
    );
    Product2 nonMatchingProduct1 = new Product2(
      Name = 'Non-matching Product 1',
      Product_SKU__c = 'SKU-002',
      Sell_Price__c = 200,
      // Product_Category__c = 'Category B',
      // Product_Sub_Category__c = 'Subcategory A',
      RecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName()
        .get('SKU')
        .getRecordTypeId(),
      Company_Code__c = 'Code A',
      Product_Type__c = 'Cat-Class',
      Product_Hierarchy__c = prdHierachy.Id
    );
    Product2 nonMatchingProduct2 = new Product2(
      Name = 'Non-matching Product 2',
      Product_SKU__c = 'SKU-003',
      Sell_Price__c = 300,
      // Product_Category__c = 'Category A',
      // Product_Sub_Category__c = 'Subcategory B',
      RecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName()
        .get('SKU')
        .getRecordTypeId(),
      Company_Code__c = 'Code B',
      Product_Type__c = 'Cat-Class',
      Product_Hierarchy__c = prdHierachy.Id
    );
    insert new List<Product2>{
      matchingProduct,
      nonMatchingProduct1,
      nonMatchingProduct2
    };

    Test.startTest();
    // Call the method with test input
    List<Product2> result = SBR_3_0_ProductDA.getAlternateProducts(
      matchingProduct.Id,
      'Code A',
      'Subcategory A',
      'Test_HR_Code'
    );
    Test.stopTest();
    // Verify the result contains the expected product(s)
  }

  public static testMethod void testgetProductKitComponents() {
    String testCompanyCode = 'ABC';

    Pricebook2 stdpriceBook = new Pricebook2(
      Id = Test.getStandardPricebookId(),
      IsActive = true
    );
    update stdpriceBook;

    List<Product2> products = new List<Product2>();
    for (Integer i = 0; i < 3; i++) {
      Product2 product = new Product2();
      product.Name = 'Test Product ' + i;
      if (i == 0) {
        product.Product_Type__c = 'Cat-Class';
        product.Product_SKU__c = 'SKU1';
        product.Category__c = '32134';
        product.Class__c = '2039';
        product.ToolFlex__c = 'N';
      } else if (i == 1) {
        product.Product_Type__c = 'Parts';
        product.Item_Number__c = '1234GH';
        product.Stock_Class__c = 'AIMFV';
      } else {
        product.Product_Type__c = '';
        product.Item_Number__c = '1285JC';
        product.Stock_Class__c = 'UJEKL';
      }
      products.add(product);
    }
    //creating products
    insert products;
    Product_Hierarchy__c prdHierachy = new Product_Hierarchy__c(
      Name = 'Test Hierarchy',
      Product_Hierarchy_Code__c = 'Test_HR_Code',
      RecordTypeId = SBR_3_0_Constants.PRODUCT_HIERARCHY_PRODUCT_SUB_CATEGORY_RT_ID
    );
    insert prdHierachy;
    //creating product hierarchy
    Product2 prod = new Product2(
      Name = 'Test Product 1',
      Product_Title_Internal__c = 'Test Product 1',
      Product_SKU__c = '123001',
      Product_Hierarchy__c = prdHierachy.Id,
      Product_Type__c = 'Cat-Class'
    );
    insert prod;
    //creating prod

    //creating product hierarchy
    SBQQ__ProductFeature__c featureObj = new SBQQ__ProductFeature__c(
      Name = 'Sales Addons',
      Product_Feature_Load_Ext_ID__c = prod.Product_SKU__c +
        '_' +
        'Sales Addons',
      SBQQ__ConfiguredSKU__c = prod.Id,
      SBQQ__MinOptionCount__c = 1,
      SBQQ__Number__c = 1
    );
    insert featureObj;
    //Creating Product Message
    Product2 prod2 = new Product2(
      Name = 'Test Product 3',
      Product_Title_Internal__c = 'Test Product 3',
      Product_SKU__c = '123003',
      Product_Hierarchy__c = prdHierachy.Id,
      Product_Type__c = 'Cat-Class'
    );
    insert prod2;
    SBQQ__ProductOption__c prodOption = new SBQQ__ProductOption__c(
      Product_Optional_SKU__c = '123001-123003',
      SBQQ__ConfiguredSKU__c = prod.Id,
      SBQQ__OptionalSKU__c = prod2.Id,
      SBQQ__Number__c = 1,
      SBQQ__Feature__c = featureObj.Id
    );
    insert prodOption;
    //creating product options

    Test.startTest();
    List<SBQQ__ProductOption__c> result = SBR_3_0_ProductDA.getProductKitComponents(
      prod.ID
    );
    Test.stopTest();
  }

  /************************************************************* Cover getProductOptions Ends*************************************************************/
  public static testMethod void getProductOptionsWithFuelCharge_Test() {
    String testCompanyCode = 'ABC';
    RecordType skuRecordType = [
      SELECT Id, Name
      FROM RecordType
      WHERE SobjectType = 'Product2' AND Name = 'SKU'
    ];

    Pricebook2 stdpriceBook = new Pricebook2(
      Id = Test.getStandardPricebookId(),
      IsActive = true
    );
    update stdpriceBook;

    List<Product2> products = new List<Product2>();
    for (Integer i = 0; i < 3; i++) {
      Product2 product = new Product2();
      product.Name = 'Test Product ' + i;
      if (i == 0) {
        product.Product_Type__c = 'Cat-Class';
        product.Product_SKU__c = 'SKU1';
        product.Category__c = '32134';
        product.Class__c = '2039';
        product.ToolFlex__c = 'N';
      } else if (i == 1) {
        product.Product_Type__c = 'Parts';
        product.Item_Number__c = '1234GH';
        product.Stock_Class__c = 'AIMFV';
      } else {
        product.Product_Type__c = '';
        product.Item_Number__c = '1285JC';
        product.Stock_Class__c = 'UJEKL';
      }
      products.add(product);
    }
    //creating products
    insert products;
    Product_Hierarchy__c prdHierachy = new Product_Hierarchy__c(
      Name = 'Test Hierarchy',
      Product_Hierarchy_Code__c = 'Test_HR_Code',
      RecordTypeId = SBR_3_0_Constants.PRODUCT_HIERARCHY_PRODUCT_SUB_CATEGORY_RT_ID
    );
    insert prdHierachy;
    //creating product hierarchy
    Product2 prod = new Product2(
      Name = 'Test Product 1',
      Product_Title_Internal__c = 'Test Product 1',
      Product_SKU__c = '123001',
      Product_Hierarchy__c = prdHierachy.Id,
      Product_Type__c = 'Cat-Class'
    );
    insert prod;
    //creating prod

    //creating product hierarchy
    SBQQ__ProductFeature__c featureObj = new SBQQ__ProductFeature__c(
      Name = 'Sales Addons',
      Product_Feature_Load_Ext_ID__c = prod.Product_SKU__c +
        '_' +
        'Sales Addons',
      SBQQ__ConfiguredSKU__c = prod.Id,
      SBQQ__MinOptionCount__c = 1,
      SBQQ__Number__c = 1
    );
    insert featureObj;
    //Creating Product Message
    Product2 prod2 = new Product2(
      Name = 'Fuel Convenience Charge',
      Stock_class__c = 'FUEL',
      RecordTypeId = skuRecordType.Id,
      Product_Title_Internal__c = 'Test Product 3',
      Product_SKU__c = '123003',
      Product_Hierarchy__c = prdHierachy.Id,
      Product_Type__c = 'Cat-Class'
    );
    insert prod2;
    Product2 prod3 = new Product2(
      Name = 'Non Fuel Charge',
      RecordTypeId = skuRecordType.Id,
      Product_Title_Internal__c = 'Test Product 4',
      Product_SKU__c = '123004',
      Product_Hierarchy__c = prdHierachy.Id,
      Product_Type__c = 'Cat-Class'
    );
    insert prod3;
    SBQQ__ProductOption__c prodOption = new SBQQ__ProductOption__c(
      Product_Optional_SKU__c = '123001-123003',
      SBQQ__ConfiguredSKU__c = prod.Id,
      SBQQ__OptionalSKU__c = prod2.Id,
      SBQQ__Required__c = true,
      SBQQ__Number__c = 1,
      Company_Code__c = '01',
      SBQQ__Feature__c = featureObj.Id
    );
    insert prodOption;

    SBQQ__ProductOption__c prodOptionNonFuel = new SBQQ__ProductOption__c(
      Product_Optional_SKU__c = '123001-123004',
      SBQQ__ConfiguredSKU__c = prod.Id,
      SBQQ__OptionalSKU__c = prod3.Id,
      SBQQ__Number__c = 2,
      Company_Code__c = '01',
      SBQQ__Feature__c = featureObj.Id
    );
    insert prodOptionNonFuel;
    //creating product options

    Test.startTest();
    Map<String, Object> resultSuccess = SBR_3_0_ProductDA.getProductOptionsWithFuelCharge(
      new List<String>{ prod.ID },
      new List<String>{ '01' }
    );
    Assert.areNotEqual(null, resultSuccess.keySet());
    Map<String, Object> resultFailed = SBR_3_0_ProductDA.getProductOptionsWithFuelCharge(
      new List<String>{ prod.ID },
      new List<String>{ 'AB' }
    );
    System.assertEquals(null, resultFailed);
    Test.stopTest();
  }

  public static testMethod void hasExistingFuelChargeLineItem_Test() {
    String quoteId = [
      SELECT id
      FROM SBQQ__Quote__c
      WHERE Quote_Name__c = 'Test Quote'
    ]
    .Id;
    List<SBQQ__QuoteLine__c> quoteLine1 = [
      SELECT id, Product_SKU__c
      FROM SBQQ__QuoteLine__c
      WHERE SBQQ__Quote__c = :quoteId AND Line_Name__c = 'test line name'
    ];
    Boolean resultQuoteLine = SBR_3_0_ProductDA.hasExistingFuelChargeLineItem(
      quoteLine1[0].ID,
      quoteLine1[0].Product_SKU__c,
      'SBQQ__QuoteLine__c'
    );
    System.assertEquals(false, resultQuoteLine);
  }

  public static testMethod void checkProductOptionForLineItem_Test() {
    Account acct = [SELECT id FROM Account WHERE Name = 'Test Account'];
    RecordType skuRecordType = [
      SELECT Id, Name
      FROM RecordType
      WHERE SobjectType = 'Product2' AND Name = 'SKU'
    ];
    Product_Hierarchy__c prdHierachy = new Product_Hierarchy__c(
      Name = 'Test Hierarchy2',
      Product_Hierarchy_Code__c = 'Test_HR_Code2',
      RecordTypeId = SBR_3_0_Constants.PRODUCT_HIERARCHY_PRODUCT_SUB_CATEGORY_RT_ID
    );
    insert prdHierachy;
    Product_Hierarchy__c prdHierachy2 = new Product_Hierarchy__c(
      Name = 'Test Hierarchy33',
      Product_Hierarchy_Code__c = 'Test_HR_Code3',
      RecordTypeId = SBR_3_0_Constants.PRODUCT_HIERARCHY_PRODUCT_SUB_CATEGORY_RT_ID
    );
    insert prdHierachy2;
    //creating product hierarchy
    Product2 prod = new Product2(
      Name = 'Test Product 4',
      Product_Title_Internal__c = 'Test Product 4',
      Product_SKU__c = '183001',
      Product_Hierarchy__c = prdHierachy.Id,
      Product_Type__c = 'Cat-Class'
    );
    insert prod;
    //creating prod

    //creating product hierarchy
    SBQQ__ProductFeature__c featureObj = new SBQQ__ProductFeature__c(
      Name = 'Sales Addons',
      Product_Feature_Load_Ext_ID__c = prod.Product_SKU__c +
        '_' +
        'Sales Addons',
      SBQQ__ConfiguredSKU__c = prod.Id,
      SBQQ__MinOptionCount__c = 1,
      SBQQ__Number__c = 1
    );
    insert featureObj;
    //Creating Product Message
    Product2 prod45 = new Product2(
      Name = 'Fuel Convenience Charge',
      RecordTypeId = skuRecordType.Id,
      Product_Title_Internal__c = 'Test Product 3',
      Product_SKU__c = '153001',
      Product_Hierarchy__c = prdHierachy2.Id,
      Product_Type__c = 'Cat-Class'
    );
    insert prod45;
    Product2 prod3 = new Product2(
      Name = 'Non Fux',
      RecordTypeId = skuRecordType.Id,
      Product_Title_Internal__c = 'Test Product 4',
      Product_SKU__c = '123004',
      Product_Hierarchy__c = prdHierachy.Id,
      Product_Type__c = 'Cat-Class'
    );
    insert prod3;
    SBQQ__ProductOption__c prodOption = new SBQQ__ProductOption__c(
      Product_Optional_SKU__c = '123001-153001',
      SBQQ__ConfiguredSKU__c = prod.Id,
      SBQQ__OptionalSKU__c = prod45.Id,
      SBQQ__Number__c = 1,
      Company_Code__c = '01',
      SBQQ__Feature__c = featureObj.Id
    );
    insert prodOption;
    SBQQ__Quote__c quote = new SBQQ__Quote__c(
      Quote_Name__c = 'Test Quote',
      SBQQ__Account__c = acct.Id
    );
    insert quote;
    Test.startTest();
    List<SBQQ__QuoteLine__c> lineItems = new List<SBQQ__QuoteLine__c>();
    lineItems.add(
      new SBQQ__QuoteLine__c(
        SBQQ__Quote__c = quote.Id,
        SBQQ__Product__c = prod.Id,
        Line_Item_Type__c = 'VR',
        Fuel_Plan__c = true,
        Product_SKU_Text__c = '1234567',
        Start_Date__c = Datetime.now().addDays(2),
        Line_Name__c = 'test line name 1'
      )
    );

    insert lineItems;
    List<SBQQ__QuoteLine__c> qli = [
      SELECT id
      FROM SBQQ__QuoteLine__c
      WHERE Product_SKU_Text__c = '1234567'
    ];
    Map<String, Object> hasLineItemFuel = SBR_3_0_ProductDA.checkProductOptionForLineItem(
      qli[0].Id,
      'SBQQ__QuoteLine__c'
    );
    Test.stopTest();
  }

  public static testMethod void getParentCatClassWithFuelPlan_Test() {
    List<SBQQ__Quote__c> testQuotes = [
      SELECT Id
      FROM SBQQ__Quote__c
      WHERE Quote_Name__c = 'Test Quote'
    ];
    System.debug('testQuotes' + testQuotes);
    List<Product2> products = new List<Product2>();
    for (Integer i = 0; i < 2; i++) {
      Product2 product = new Product2();

      if (i == 0) {
        product.Name = 'Not Fuel Plan';
        product.Product_Type__c = 'Cat-Class';
        product.Product_SKU__c = '234567';
        product.Category__c = '32134';
        product.Class__c = '2039';
        product.ToolFlex__c = 'N';
        product.isSerialized = true;
        product.Stock_class__c = '';
        product.Bulk_Item__c = false;
        product.Status__c = 'A';
      } else if (i == 1) {
        product.Name = 'Fuel Convenience Charge';
        product.Product_Type__c = 'Parts';
        product.Item_Number__c = '4321GH';
        product.Stock_Class__c = 'FVAIM';
        product.isSerialized = true;
      }
      products.add(product);
    }
    insert products;
    List<PricebookEntry> pbEntries = new List<PricebookEntry>();
    for (Product2 prod : products) {
      PricebookEntry stdPbe = new PricebookEntry();
      stdPbe.CurrencyIsoCode = 'USD';
      stdPbe.Pricebook2Id = Test.getStandardPricebookId();
      stdPbe.Product2Id = prod.Id;
      stdPbe.IsActive = true;
      stdPbe.UnitPrice = 20;
      pbEntries.add(stdPbe);
    }
    insert pbEntries;

    List<SBQQ__QuoteLine__c> testLines = SBR_3_0_TestDataFactory.createQuoteLines(
      2,
      false,
      testQuotes[0].Id
    );
    System.debug('testLines' + testLines);
    testLines[0].Fuel_Plan__c = true;
    testLines[0].Line_Item_Type__c = 'VR';
    testLines[0].SBQQ__Product__c = products[0].Id;
    testLines[1].SBQQ__Product__c = products[1].Id;
    testLines[1].Kit_Number_this_Item_Belongs_to__c = '234567';
    insert testLines;

    Test.startTest();

    List<SBQQ__QuoteLine__c> testQuoteResultsTwoFP = [
      SELECT
        Id,
        Fuel_Plan__c,
        SBQQ__Quote__c,
        Kit_Number_this_Item_Belongs_to__c
      FROM SBQQ__QuoteLine__c
      WHERE Kit_Number_this_Item_Belongs_to__c = '234567'
    ];
    System.debug('testQuoteResultsTwoFP' + testQuoteResultsTwoFP);
    SBR_3_0_ProductDA.ProductWrapper pwrapper = SBR_3_0_ProductDA.getParentCatClassWithFuelPlan(
      testQuoteResultsTwoFP[0].Kit_Number_this_Item_Belongs_to__c,
      'SBQQ__QuoteLine__c'
    );
    System.assertEquals(true, pwrapper.hasFuelCatClassParent);
    Test.stopTest();
  }

  @isTest
  private static void testGetPriceBookEntrieswithProductSKUs() {
    Test.startTest();
    Map<String, PricebookEntry> skuToPriceBookEntryMap = SBR_3_0_ProductDA.getPriceBookEntrieswithProductSKUs(
      new Set<String>{ '234567' }
    );
    Test.stopTest();
    System.assertEquals(skuToPriceBookEntryMap.size(), 0);
  }
}