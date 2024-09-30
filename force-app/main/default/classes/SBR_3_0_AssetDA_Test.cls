@isTest
public with sharing class SBR_3_0_AssetDA_Test {
  @TestSetup
  static void createData() {
    List<Account> testAccount = SBR_3_0_TestDataFactory.createAccounts(1, true);
    List<Contact> testContact = SBR_3_0_TestDataFactory.createContacts(
      1,
      testAccount[0].Id,
      true
    );
    List<Schema.Location> branch = SBR_3_0_TestDataFactory.createInventoryLocations(
      1,
      true,
      'Branch'
    );
    Id rentalAssetRecordTypeID = Schema.SObjectType.Asset.getRecordTypeInfosByName()
      .get('Rental Asset')
      .getRecordTypeId();

    branch[0].Branch_Location_Number__c = '0101';
    update branch;
    List<Asset> testAsset = SBR_3_0_TestDataFactory.createAssets(
      1,
      false,
      testAccount[0].Id,
      testContact[0].Id,
      branch[0].Id
    );
    SBR_3_0_TriggerHandler.bypass('SBR_3_0_AssetTriggerHandler');
    Database.insert(testAsset);
    testAsset[0].SM_PS_Cat_Class__c = '0020080';
    testAsset[0].RecordtypeId = rentalAssetRecordTypeID;
    update testAsset;
  }

  @isTest
  public static void givenValidCatClassAndLocIdReturnValidAsset() {
    test.startTest();
    List<Asset> testAsset = [SELECT Id, SM_PS_Cat_Class__c FROM Asset LIMIT 1];
    List<Schema.Location> branch = [
      SELECT Id, Branch_Location_Number__c
      FROM Location
      LIMIT 1
    ];
    List<Asset> Assets = SBR_3_0_AssetDA.fetchAssetsBasedOnStatus(
      testAsset[0].SM_PS_Cat_Class__c,
      branch[0].Branch_Location_Number__c
    );
    System.assertEquals(testAsset[0].Id, Assets[0].Id);
    test.StopTest();
  }

  @isTest
  public static void fetchAssetInformationTest() {
    test.startTest();
    List<Asset> testAsset = [SELECT Id, SM_PS_Asset_Id__c FROM Asset LIMIT 1];
    SBR_3_0_AssetDA.AssetInformationWrapper assetDetails = SBR_3_0_AssetDA.fetchAssetInformation(
      testAsset[0].SM_PS_Asset_Id__c
    );
    System.assertEquals(
      assetDetails.asset.SM_PS_Asset_Id__c,
      testAsset[0].SM_PS_Asset_Id__c
    );
    System.assertEquals(assetDetails.order, null);
    test.StopTest();
  }
  @isTest
  public static void testAssetreturnMethods() {
    test.startTest();
    List<Asset> resultAssets = SBR_3_0_AssetDA.getAssetsByProduct('');
    Map<String, Asset> resultAssets1 = SBR_3_0_AssetDA.getAssetssById(null);
    List<Asset> resultAssets2 = SBR_3_0_AssetDA.getAssetsByYearLoc(
      '2011',
      'Test',
      '002008'
    );
    List<Asset> resultAssets3 = SBR_3_0_AssetDA.getAssetsByStatusList(
      new List<String>{ 'Available' },
      '002008'
    );
    List<Asset> resultAssets4 = SBR_3_0_AssetDA.getAssetsByYearStatusList(
      new List<String>{ 'Available' },
      '2011',
      '002008'
    );
    List<Asset> resultAssets5 = SBR_3_0_AssetDA.getAssetsByYearStatusListLoc(
      new List<String>{ 'Available' },
      '2011',
      'Test',
      '002008'
    );
    List<Asset> resultAssets6 = SBR_3_0_AssetDA.getAssetsBySearchKeyStatusListLocYear(
      new List<String>{ 'Available' },
      'Test',
      'Test',
      '2011',
      '0070025'
    );
    List<Asset> resultAssets7 = SBR_3_0_AssetDA.getAssetsByYearStatusListSearchKey(
      new List<String>{ 'Available' },
      '2011',
      'Test',
      '0070025'
    );
    List<Asset> resultAssets8 = SBR_3_0_AssetDA.getAssetsByStatusLoc(
      new List<String>{ 'Available' },
      '2011',
      '0070025'
    );
    List<Asset> resultAssets9 = SBR_3_0_AssetDA.getAssetsBySearchKeyStatusListLoc(
      new List<String>{ 'Available' },
      '2011',
      '0070025',
      '0070025'
    );
    List<Asset> resultAssets10 = SBR_3_0_AssetDA.getAssetsByCatClass(
      '0070025',
      0
    );
    List<Asset> resultAssets11 = SBR_3_0_AssetDA.getAssetsByYearSearchKey(
      '0070025',
      '2011',
      '0070025'
    );
    List<Asset> resultAssets12 = SBR_3_0_AssetDA.getAssetsByLocSearchKeyYear(
      '0070025',
      '2011',
      '0070025',
      'abc'
    );

    test.stopTest();
    // Verify the result
    System.assertEquals(1, resultAssets.size());
    System.assertEquals(0, resultAssets1.size());
    System.assertEquals(0, resultAssets2.size());
    System.assertEquals(0, resultAssets3.size());
    System.assertEquals(0, resultAssets4.size());
    System.assertEquals(0, resultAssets5.size());
    System.assertEquals(0, resultAssets6.size());
    System.assertEquals(0, resultAssets7.size());
    System.assertEquals(0, resultAssets8.size());
    System.assertEquals(0, resultAssets9.size());
    System.assertEquals(0, resultAssets10.size());
    System.assertEquals(0, resultAssets11.size());
    System.assertEquals(0, resultAssets12.size());
  }
  @isTest
  public static void getAsset() {
    Test.startTest();
    Set<String> assetSet = new Set<String>();
    assetSet.add('Test');
    SBR_3_0_AssetDA.getAssetsByNumbers(assetSet);
    List<Asset> assetList = [
      SELECT
        id,
        SM_PS_Company_Code__c,
        SM_PS_Cat_Class__c,
        SM_PS_Current_Location__r.Branch_Location_Number__c
      FROM Asset
    ];
    String orgId = assetList[0].SM_PS_Company_Code__c;
    List<Asset> fetchAssetBlueYonder = SBR_3_0_AssetDA.fetchAssetsBlueYonder(
      orgId,
      new Set<String>{ assetList[0].SM_PS_Cat_Class__c },
      new Set<String>{
        assetList[0].SM_PS_Current_Location__r.Branch_Location_Number__c
      }
    );
    Test.stopTest();
    System.assertEquals(1, assetList.size(), 'size of list');
  }

  @IsTest
  public static void getAssetFilteredRecordstest() {
    Test.startTest();
    string locationNumber = '0854';
    list<string> catClassList = new List<string>();
    catClassList.add('0070008');
    catClassList.add('0070010');
    list<asset> assetList = SBR_3_0_AssetDA.getAssetFilteredRecords(
      locationNumber,
      catClassList
    );
    System.assert(assetList.size() == 0);
    Test.stopTest();
  }

  @IsTest
  public static void getAssettest() {
    Profile p = [SELECT Id FROM Profile WHERE Name = 'Frontline'];
    String intUserName =
      'IntegrationUser' +
      DateTime.now().getTime() +
      '@airrexusa.com';
    User intUser = new User(
      Alias = 'IntUser',
      Email = 'ersuser1@airrexusa.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'User',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = p.Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = intUserName
    );
    insert intUser;

    System.runAs(intUser) {
      Test.startTest();
      string locationNumber = '0854';
      list<string> catClassList = new List<string>();
      catClassList.add('0070008');
      catClassList.add('0070010');
      list<asset> assetList = SBR_3_0_AssetDA.getAssetFilteredRecords(
        locationNumber,
        catClassList
      );
      System.assert(assetList.size() == 0);
      Test.stopTest();
    }

  }
  @isTest
  private static void testNewAssetReturnMethods() {
    System.test.startTest();
    List<Asset> searchKeyAssets = SBR_3_0_AssetDA.getAssetsBySearchKey(
      '',
      '0020080'
    );
    List<Asset> catClassBasedAssets = SBR_3_0_AssetDA.getAssetsByCatClassWithRelatedOrderItems(
      '',
      '0020080',
      1
    );
    System.test.stopTest();
    Assert.areEqual(searchKeyAssets.isEmpty(), true, 'No Assets Received');
  }
}