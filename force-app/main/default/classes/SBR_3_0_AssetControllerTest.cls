@isTest(SeeAllData=false)
private class SBR_3_0_AssetControllerTest {
  @isTest
  private static void testAssetParamsForSerialTabAndSearchKeyNull() {
    //Asset Data
    List<Asset> dummyAssetListToBeInserted = SBR_3_0_TestDataFactory.createAssets(
      1,
      false
    );
    SBR_3_0_TriggerHandler.bypass('SBR_3_0_AssetTriggerHandler');
    Database.insert(dummyAssetListToBeInserted);

    SBR_3_0_AssetController.AssetListParams dummyAssetParamList = new SBR_3_0_AssetController.AssetListParams();
    dummyAssetParamList.searchKey = '';
    dummyAssetParamList.actvTab = 'Serial';
    dummyAssetParamList.year = '';
    dummyAssetParamList.loc = '';
    dummyAssetParamList.statusList = null;
    dummyAssetParamList.selectedLocation = null;
    dummyAssetParamList.contractId = '';

    System.test.startTest();
    List<Asset> assetList = SBR_3_0_AssetController.getAssetList(
      dummyAssetParamList
    );
    System.test.stopTest();

    Assert.areEqual(assetList.isEmpty(), true, 'No assets queried.');
  }

  @isTest
  private static void testAssetParamsForNonSerialTabAndSearchKeyNull() {
    //Asset Data
    List<Asset> dummyAssetListToBeInserted = SBR_3_0_TestDataFactory.createAssets(
      1,
      false
    );
    SBR_3_0_TriggerHandler.bypass('SBR_3_0_AssetTriggerHandler');
    Database.insert(dummyAssetListToBeInserted);

    SBR_3_0_AssetController.AssetListParams dummyAssetParamList = new SBR_3_0_AssetController.AssetListParams();
    dummyAssetParamList.searchKey = '';
    dummyAssetParamList.actvTab = 'Asset';
    dummyAssetParamList.year = '';
    dummyAssetParamList.loc = '';
    dummyAssetParamList.statusList = null;
    dummyAssetParamList.selectedLocation = null;
    dummyAssetParamList.contractId = '';

    System.test.startTest();
    List<Asset> assetList = SBR_3_0_AssetController.getAssetList(
      dummyAssetParamList
    );
    System.test.stopTest();
    System.debug('assetList >> ' + assetList);

    
  }

  @isTest
  private static void testAssetParamsForSerialTabAndSearchKeyNotNull() {
    //Asset Data
    List<Asset> dummyAssetListToBeInserted = SBR_3_0_TestDataFactory.createAssets(
      1,
      false
    );
    dummyAssetListToBeInserted[0].SM_PS_Serial_Number__c = 'Test';
    SBR_3_0_TriggerHandler.bypass('SBR_3_0_AssetTriggerHandler');
    Database.insert(dummyAssetListToBeInserted);

    SBR_3_0_AssetController.AssetListParams dummyAssetParamList = new SBR_3_0_AssetController.AssetListParams();
    dummyAssetParamList.searchKey = 'Test';
    dummyAssetParamList.actvTab = 'Serial';
    dummyAssetParamList.year = '';
    dummyAssetParamList.loc = '';
    dummyAssetParamList.statusList = null;
    dummyAssetParamList.selectedLocation = null;
    dummyAssetParamList.contractId = '';

    System.test.startTest();
    List<Asset> assetList = SBR_3_0_AssetController.getAssetList(
      dummyAssetParamList
    );
    System.test.stopTest();
    System.debug('assetList >> ' + assetList);

    Assert.areEqual(assetList.isEmpty(), false, 'Queried Assets Successfully');
  }

  @isTest
  private static void testAssetParamsForNonSerialTabAndSearchKeyNotNull() {
    //Asset Data
    List<Asset> dummyAssetListToBeInserted = SBR_3_0_TestDataFactory.createAssets(
      1,
      false
    );
    dummyAssetListToBeInserted[0].Name = 'Test';
    SBR_3_0_TriggerHandler.bypass('SBR_3_0_AssetTriggerHandler');
    Database.insert(dummyAssetListToBeInserted);

    SBR_3_0_AssetController.AssetListParams dummyAssetParamList = new SBR_3_0_AssetController.AssetListParams();
    dummyAssetParamList.searchKey = 'Test';
    dummyAssetParamList.actvTab = 'Asset';
    dummyAssetParamList.year = '';
    dummyAssetParamList.loc = '';
    dummyAssetParamList.statusList = null;
    dummyAssetParamList.selectedLocation = null;
    dummyAssetParamList.contractId = '';

    System.test.startTest();
    List<Asset> assetList = SBR_3_0_AssetController.getAssetList(
      dummyAssetParamList
    );
    System.test.stopTest();
    System.debug('assetList >> ' + assetList);

    Assert.areEqual(assetList.isEmpty(), false, 'Queried Assets Successfully');
  }

  @isTest
  private static void testAssetParamsForCatClassTab() {
    Id createContractRecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName()
      .get('Create_Contract')
      ?.getRecordTypeId();

    Order ord = SBR_3_0_TestDataFactory.createOrder(
      false,
      'test',
      createContractRecordTypeId
    );
    ord.Name = 'TEST ORDER';

    SBR_3_0_TriggerHandler.bypass('SBR_3_0_OrderTriggerHandler');
    Database.insert(new List<sObject>{ ord });

    SBR_3_0_AssetController.AssetListParams dummyAssetParamList = new SBR_3_0_AssetController.AssetListParams();
    dummyAssetParamList.searchKey = 'TestDescription';
    dummyAssetParamList.actvTab = 'CatClass';
    dummyAssetParamList.year = '2001';
    dummyAssetParamList.loc = '01';
    dummyAssetParamList.statusList = new List<String>{ 'Available' };
    dummyAssetParamList.selectedLocation = 'All Branches';
    dummyAssetParamList.contractId = ord.Id;
    dummyAssetParamList.catClass = '0001';

    SBR_3_0_AssetController.AssetListParams dummyAssetParamList2 = new SBR_3_0_AssetController.AssetListParams();
    dummyAssetParamList2.searchKey = 'TestDescription';
    dummyAssetParamList2.actvTab = 'CatClass';
    dummyAssetParamList2.year = '';
    dummyAssetParamList2.loc = '01';
    dummyAssetParamList2.statusList = new List<String>{ 'Available' };
    dummyAssetParamList2.selectedLocation = null;
    dummyAssetParamList2.contractId = ord.Id;
    dummyAssetParamList2.catClass = '0001';

    SBR_3_0_AssetController.AssetListParams dummyAssetParamList3 = new SBR_3_0_AssetController.AssetListParams();
    dummyAssetParamList3.searchKey = '';
    dummyAssetParamList3.actvTab = 'CatClass';
    dummyAssetParamList3.year = '2000';
    dummyAssetParamList3.loc = '01';
    dummyAssetParamList3.statusList = new List<String>{ 'Available' };
    dummyAssetParamList3.selectedLocation = null;
    dummyAssetParamList3.contractId = ord.Id;
    dummyAssetParamList3.catClass = '';

    SBR_3_0_AssetController.AssetListParams dummyAssetParamList4 = new SBR_3_0_AssetController.AssetListParams();
    dummyAssetParamList4.searchKey = 'Test';
    dummyAssetParamList4.actvTab = 'CatClass';
    dummyAssetParamList4.year = '2000';
    dummyAssetParamList4.loc = '01';
    dummyAssetParamList4.statusList = null;
    dummyAssetParamList4.selectedLocation = null;
    dummyAssetParamList4.contractId = ord.Id;
    dummyAssetParamList4.catClass = '';

    SBR_3_0_AssetController.AssetListParams dummyAssetParamList5 = new SBR_3_0_AssetController.AssetListParams();
    dummyAssetParamList5.searchKey = 'Test';
    dummyAssetParamList5.actvTab = 'CatClass';
    dummyAssetParamList5.year = '2000';
    dummyAssetParamList5.loc = '';
    dummyAssetParamList5.statusList = new List<String>{ 'Available' };
    dummyAssetParamList5.selectedLocation = null;
    dummyAssetParamList5.contractId = ord.Id;
    dummyAssetParamList5.catClass = '';

    SBR_3_0_AssetController.AssetListParams dummyAssetParamList6 = new SBR_3_0_AssetController.AssetListParams();
    dummyAssetParamList6.searchKey = 'Test';
    dummyAssetParamList6.actvTab = 'CatClass';
    dummyAssetParamList6.year = '2000';
    dummyAssetParamList6.loc = '';
    dummyAssetParamList6.statusList = null;
    dummyAssetParamList6.selectedLocation = null;
    dummyAssetParamList6.contractId = ord.Id;
    dummyAssetParamList6.catClass = '';

    SBR_3_0_AssetController.AssetListParams dummyAssetParamList7 = new SBR_3_0_AssetController.AssetListParams();
    dummyAssetParamList7.searchKey = '';
    dummyAssetParamList7.actvTab = 'CatClass';
    dummyAssetParamList7.year = '2000';
    dummyAssetParamList7.loc = '';
    dummyAssetParamList7.statusList = new List<String>{ 'Available' };
    dummyAssetParamList7.selectedLocation = null;
    dummyAssetParamList7.contractId = ord.Id;
    dummyAssetParamList7.catClass = '';

    SBR_3_0_AssetController.AssetListParams dummyAssetParamList8 = new SBR_3_0_AssetController.AssetListParams();
    dummyAssetParamList8.searchKey = 'Test';
    dummyAssetParamList8.actvTab = 'CatClass';
    dummyAssetParamList8.year = '';
    dummyAssetParamList8.loc = '';
    dummyAssetParamList8.statusList = new List<String>{ 'Available' };
    dummyAssetParamList8.selectedLocation = null;
    dummyAssetParamList8.contractId = ord.Id;
    dummyAssetParamList8.catClass = '';

    SBR_3_0_AssetController.AssetListParams dummyAssetParamList9 = new SBR_3_0_AssetController.AssetListParams();
    dummyAssetParamList9.searchKey = 'Test';
    dummyAssetParamList9.actvTab = 'CatClass';
    dummyAssetParamList9.year = '';
    dummyAssetParamList9.loc = '01';
    dummyAssetParamList9.statusList = null;
    dummyAssetParamList9.selectedLocation = null;
    dummyAssetParamList9.contractId = ord.Id;
    dummyAssetParamList9.catClass = '';

    SBR_3_0_AssetController.AssetListParams dummyAssetParamList10 = new SBR_3_0_AssetController.AssetListParams();
    dummyAssetParamList10.searchKey = '';
    dummyAssetParamList10.actvTab = 'CatClass';
    dummyAssetParamList10.year = '2001';
    dummyAssetParamList10.loc = '01';
    dummyAssetParamList10.statusList = null;
    dummyAssetParamList10.selectedLocation = null;
    dummyAssetParamList10.contractId = ord.Id;
    dummyAssetParamList10.catClass = '';

    SBR_3_0_AssetController.AssetListParams dummyAssetParamList11 = new SBR_3_0_AssetController.AssetListParams();
    dummyAssetParamList11.searchKey = '';
    dummyAssetParamList11.actvTab = 'CatClass';
    dummyAssetParamList11.year = '';
    dummyAssetParamList11.loc = '01';
    dummyAssetParamList11.statusList = new List<String>{ 'Available' };
    dummyAssetParamList11.selectedLocation = null;
    dummyAssetParamList11.contractId = ord.Id;
    dummyAssetParamList11.catClass = '';

    SBR_3_0_AssetController.AssetListParams dummyAssetParamList12 = new SBR_3_0_AssetController.AssetListParams();
    dummyAssetParamList12.searchKey = '';
    dummyAssetParamList12.actvTab = 'CatClass';
    dummyAssetParamList12.year = '2000';
    dummyAssetParamList12.loc = '';
    dummyAssetParamList12.statusList = null;
    dummyAssetParamList12.selectedLocation = null;
    dummyAssetParamList12.contractId = ord.Id;
    dummyAssetParamList12.catClass = '001';
    dummyAssetParamList12.offset = 1;

    SBR_3_0_AssetController.AssetListParams dummyAssetParamList13 = new SBR_3_0_AssetController.AssetListParams();
    dummyAssetParamList13.searchKey = '';
    dummyAssetParamList13.actvTab = 'CatClass';
    dummyAssetParamList13.year = '';
    dummyAssetParamList13.loc = '';
    dummyAssetParamList13.statusList = new List<String>{ 'Available' };
    dummyAssetParamList13.selectedLocation = null;
    dummyAssetParamList13.contractId = ord.Id;
    dummyAssetParamList13.catClass = '001';

    SBR_3_0_AssetController.AssetListParams dummyAssetParamList14 = new SBR_3_0_AssetController.AssetListParams();
    dummyAssetParamList14.searchKey = '';
    dummyAssetParamList14.actvTab = 'CatClass';
    dummyAssetParamList14.year = '';
    dummyAssetParamList14.loc = '01';
    dummyAssetParamList14.statusList = null;
    dummyAssetParamList14.selectedLocation = null;
    dummyAssetParamList14.contractId = ord.Id;
    dummyAssetParamList14.catClass = '001';
      
    Schema.Location loc = new Schema.Location();
    loc.recordTypeId = SBR_3_0_Constants.LOCATION_BRANCH_RT_ID;
    loc.Name = '1799 Innovation Point';
    loc.Street_Address__c = '1799 Innovation Point';
    loc.State__c = 'SC';
    loc.Zip_Code__c = '29715';
    loc.Branch_Location_Number__c = '0411';
    loc.Market_Name__c = '0411';
    insert loc;

    User_Location__c ul = new User_Location__c(
      User__c = UserInfo.getUserId(),
      Branch__c = loc.Id,
      ProfileBranche__c  = loc.Id
    );
    insert ul;

    System.test.startTest();
    system.debug('dummyAssetParamList==='+dummyAssetParamList);
    List<Asset> assetList = SBR_3_0_AssetController.getAssetList(
      dummyAssetParamList
    );

    List<Asset> assetList2 = SBR_3_0_AssetController.getAssetList(
      dummyAssetParamList2
    );

    List<Asset> assetList3 = SBR_3_0_AssetController.getAssetList(
      dummyAssetParamList3
    );

    List<Asset> assetList4 = SBR_3_0_AssetController.getAssetList(
      dummyAssetParamList4
    );

    List<Asset> assetList5 = SBR_3_0_AssetController.getAssetList(
      dummyAssetParamList5
    );

    List<Asset> assetList6 = SBR_3_0_AssetController.getAssetList(
      dummyAssetParamList6
    );

    List<Asset> assetList7 = SBR_3_0_AssetController.getAssetList(
      dummyAssetParamList7
    );

    List<Asset> assetList8 = SBR_3_0_AssetController.getAssetList(
      dummyAssetParamList8
    );

    List<Asset> assetList9 = SBR_3_0_AssetController.getAssetList(
      dummyAssetParamList9
    );

    List<Asset> assetList10 = SBR_3_0_AssetController.getAssetList(
      dummyAssetParamList10
    );

    List<Asset> assetList11 = SBR_3_0_AssetController.getAssetList(
      dummyAssetParamList11
    );

    List<Asset> assetList12 = SBR_3_0_AssetController.getAssetList(
      dummyAssetParamList12
    );

    List<Asset> assetList13 = SBR_3_0_AssetController.getAssetList(
      dummyAssetParamList13
    );

    List<Asset> assetList14 = SBR_3_0_AssetController.getAssetList(
      dummyAssetParamList14
    );
    System.test.stopTest();
    System.debug('assetList >> ' + assetList);

    Assert.areEqual(assetList.isEmpty(), true, 'No Records found.');
    Assert.areEqual(assetList2.isEmpty(), true, 'No Records found.');
  }

  @isTest
  private static void testGetProductItemList() {
    Id createContractRecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName()
      .get('Create_Contract')
      ?.getRecordTypeId();

    Order ord = SBR_3_0_TestDataFactory.createOrder(
      false,
      'test',
      createContractRecordTypeId
    );

    Id testBranchLocation = [
      SELECT Id
      FROM Location
      WHERE RecordTypeId = :SBR_3_0_Constants.LOCATION_BRANCH_RT_ID
      LIMIT 1
    ]
    .Id;

    ord.Sourcing_Branch__c = testBranchLocation;
    ord.Name = 'TEST ORDER';

    Product2 testProd = SBR_3_0_TestDataFactory.createProducts(1, false)[0];
    testProd.Name = 'testProd';
    testProd.Bulk_Item__c = true;

    Schema.Location updLocation = new Schema.Location(
      Id = testBranchLocation,
      IsInventoryLocation = true
    );

    SBR_3_0_TriggerHandler.bypass('SBR_3_0_OrderTriggerHandler');
    SBR_3_0_TriggerHandler.bypass('SBR_3_0_ProductTriggerHandler');
    SBR_3_0_TriggerHandler.bypass('SBR_3_0_LocationTriggerHandler');

    Database.upsert(new List<sObject>{ ord, testProd, updLocation });

    Pricebookentry pbe = new Pricebookentry(
      Pricebook2Id = Test.getStandardPricebookId(),
      IsActive = true,
      UnitPrice = 0,
      Product2Id = testProd.Id
    );

    Database.insert(pbe);

    ProductItem testProductItem = SBR_3_0_TestDataFactory.createProductItems(
      1,
      false,
      testProd.Id,
      testBranchLocation
    )[0];

    OrderItem oiRecord = new OrderItem(
      Product2Id = testProd.Id,
      OrderId = ord.Id,
      Quantity = 1,
      UnitPrice = 10,
      PricebookEntryId = pbe.Id
    );

    SBR_3_0_TriggerHandler.bypass('SBR_3_0_ProductItemTriggerHandler');
    SBR_3_0_TriggerHandler.bypass('SBR_3_0_OrderItemTriggerHandler');
    Database.insert(new List<sObject>{ testProductItem, oiRecord });

    System.test.startTest();
    SBR_3_0_AssetController.ProductItemListParams dummyResultProduct = new SBR_3_0_AssetController.ProductItemListParams();
    dummyResultProduct.actvTab = 'Cat Class Description';
    dummyResultProduct.searchKey = 'testProd';
    dummyResultProduct.contractId = ord.Id;
    dummyResultProduct.selectedLocationFilter = 'Current Branch';
    dummyResultProduct.limitSize = 100;
    dummyResultProduct.offset = 0;
    dummyResultProduct.itemListSearchKey = 'testProd';

    SBR_3_0_AssetController.ProductItemListParams dummyResultProduct1 = new SBR_3_0_AssetController.ProductItemListParams();
    dummyResultProduct.actvTab = 'Cat Class Description';
    dummyResultProduct.searchKey = 'test';

    List<SBR_3_0_AssetController.ProductItemWrapper> resultProduct = SBR_3_0_AssetController.getProductItemList(
      dummyResultProduct
    );
    List<SBR_3_0_AssetController.ProductItemWrapper> resultProduct1 = SBR_3_0_AssetController.getProductItemList(
      dummyResultProduct1
    );
    System.Test.stopTest();
    Assert.areEqual(!resultProduct.isEmpty(), true, 'Records found.');
  }
  @isTest
  static void testGetFilteredAssetsCatClassRegion() {
    Id createContractRecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName()
      .get('Create_Contract')
      ?.getRecordTypeId();

    Order ord = SBR_3_0_TestDataFactory.createOrder(
      false,
      'test',
      createContractRecordTypeId
    );

    Id testBranchLocation = [
      SELECT Id
      FROM Location
      WHERE RecordTypeId = :SBR_3_0_Constants.LOCATION_BRANCH_RT_ID
      LIMIT 1
    ]
    .Id;

    ord.Sourcing_Branch__c = testBranchLocation;
    ord.Name = 'TEST ORDER';

    Product2 testProd = SBR_3_0_TestDataFactory.createProducts(1, false)[0];
    testProd.Name = 'testProd';
    testProd.Bulk_Item__c = true;

    Schema.Location updLocation = new Schema.Location(
      Id = testBranchLocation,
      IsInventoryLocation = true
    );

    SBR_3_0_TriggerHandler.bypass('SBR_3_0_OrderTriggerHandler');
    SBR_3_0_TriggerHandler.bypass('SBR_3_0_ProductTriggerHandler');
    SBR_3_0_TriggerHandler.bypass('SBR_3_0_LocationTriggerHandler');

    Database.upsert(new List<sObject>{ ord, testProd, updLocation });

    Pricebookentry pbe = new Pricebookentry(
      Pricebook2Id = Test.getStandardPricebookId(),
      IsActive = true,
      UnitPrice = 0,
      Product2Id = testProd.Id
    );

    Database.insert(pbe);

    ProductItem testProductItem = SBR_3_0_TestDataFactory.createProductItems(
      1,
      false,
      testProd.Id,
      testBranchLocation
    )[0];

    OrderItem oiRecord = new OrderItem(
      Product2Id = testProd.Id,
      OrderId = ord.Id,
      Quantity = 1,
      UnitPrice = 10,
      PricebookEntryId = pbe.Id
    );

    SBR_3_0_TriggerHandler.bypass('SBR_3_0_ProductItemTriggerHandler');
    SBR_3_0_TriggerHandler.bypass('SBR_3_0_OrderItemTriggerHandler');
    Database.insert(new List<sObject>{ testProductItem, oiRecord });

    Schema.Location loc = new Schema.Location();
    loc.recordTypeId = SBR_3_0_Constants.LOCATION_BRANCH_RT_ID;
    loc.Name = '1799 Innovation Point';
    loc.Street_Address__c = '1799 Innovation Point';
    loc.State__c = 'SC';
    loc.Zip_Code__c = '29715';
    loc.Branch_Location_Number__c = '0411';
    loc.Market_Name__c = '0411';
    insert loc;

    User_Location__c ul = new User_Location__c(
      User__c = UserInfo.getUserId(),
      Branch__c = loc.Id,
      ProfileBranche__c  = loc.Id
    );
    insert ul;

    String searchKey = '3';
    String year = '2024';
    String locs = '23';
    integer offset = 4;
    String actvTab = 'CatClass';
    String catClass = '23';
    string contractId = [SELECT id FROM order LIMIT 1].id;
    String selectedLocation = 'All Region Branches';
    List<String> statusList = new List<String>{ 'available', 'In Transit' };

    SBR_3_0_AssetController.AssetListParams params = new SBR_3_0_AssetController.AssetListParams();
    params.searchKey = searchKey;
    params.year = year;
    params.loc = locs;
    params.statusList = statusList;
    params.contractId = contractId;
    params.actvTab = actvTab;
    params.catClass = catClass;
    params.selectedLocation = selectedLocation;
    params.offset = offset;
    Test.startTest();
    List<Asset> result = SBR_3_0_AssetController.getFilteredAssetsCatClass(
      params
    );
    Test.stopTest();
  }
}