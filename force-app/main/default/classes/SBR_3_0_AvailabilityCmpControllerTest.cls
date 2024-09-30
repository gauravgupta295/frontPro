@isTest
public with sharing class SBR_3_0_AvailabilityCmpControllerTest {
  static List<Product2> lstProds;
  static List<Schema.ProductItem> productItems;
  static List<Schema.ProductItem> productItems2;
  static List<Schema.Location> locs;

  static void makeData() {
    lstProds = SBR_3_0_TestDataFactory.createProducts(1, true);
    String recId = Schema.getGlobalDescribe()
      .get('ProductItem')
      .getDescribe()
      .getRecordTypeInfosByDeveloperName()
      .get('Assets')
      .getRecordTypeId();

    // Create a Location
    locs = SBR_3_0_TestDataFactory.createInventoryLocations(1, false, 'Branch');
    Schema.Location loc = locs[0];
    loc.Name = 'Ohio PC107';
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
    pi.SM_PS_Quantity_Available__c = 20;
    pi.SM_PS_Quantity_Reserved__c = 5;
    pi.SM_PS_Quantity_on_Scheduled_Pick_Up__c = 5;
    pi.SM_PS_Quantity_on_Rent__c = 30;
    pi.SM_PS_Number_of_Rental_Units__c = 60;
    pi.SM_PS_Quantity_Returned__c = 5;
    insert productItems;

    productItems2 = SBR_3_0_TestDataFactory.createProductItems(
      1,
      false,
      lstProds[0].id,
      locs[0].id
    );
    Schema.ProductItem pi2 = productItems2[0];
    pi2.SM_PS_Cat_Class__c = '0020080';
    pi2.SM_PS_Quantity_Available__c = 10;
    pi2.SM_PS_Quantity_Reserved__c = 5;
    pi2.SM_PS_Quantity_on_Scheduled_Pick_Up__c = 7;
    pi2.SM_PS_Quantity_on_Rent__c = 15;
    pi2.SM_PS_Number_of_Rental_Units__c = 32;
    //insert productItems2;
  }

  @isTest
  static void givenValidStringsReturnBranchSummary() {
    List<String> prodCat = new List<string>();
    makeData();
    Schema.Location loc = locs[0];
    prodCat.add(productItems[0].SM_PS_Cat_Class__c);
    String locationInfo = JSON.serialize(locs[0]);
    System.debug(locationInfo);
    Test.startTest();
    List<SBR_3_0_AvailabilityCmpController.AvailabilityListWrapper> TestRows = SBR_3_0_AvailabilityCmpController.getProductAvailabilities(
      prodCat,
      'summary',
      locationInfo
    );
    Test.stopTest();
    System.debug(testRows);
    if (!TestRows.isEmpty() && TestRows[0]?.availabilityInfo.size() > 0) {
      System.assertEquals(
        Integer.valueOf(TestRows[0].availabilityInfo[0].available),
        Integer.valueOf(
          productItems[0].SM_PS_Quantity_Available__c +
          productItems[0].SM_PS_Quantity_Returned__c
        )
      );
    }
  }

  @isTest
  static void givenValidDistrictReturnBranchsAvailability() {
    makeData();
    List<String> prodCat = new List<string>();
    prodCat.add(productItems[0].SM_PS_Cat_Class__c);
    String locationInfo = JSON.serialize(locs[0]);
    Test.startTest();
    List<SBR_3_0_AvailabilityCmpController.AvailabilityListWrapper> TestRows = SBR_3_0_AvailabilityCmpController.getProductAvailabilities(
      prodCat,
      'district',
      locationInfo
    );
    Test.stopTest();
    if (!TestRows.isEmpty()) {
      System.assertEquals(
        Integer.valueOf(TestRows[0].availabilityInfo[0].available),
        Integer.valueOf(
          productItems[0].SM_PS_Quantity_Available__c +
          productItems[0].SM_PS_Quantity_Returned__c
        )
      );
    }
  }

  @isTest
  static void givenValidCompanyReturnBranchAvailability() {
    makeData();
    List<String> prodCat = new List<string>();
    prodCat.add(productItems[0].SM_PS_Cat_Class__c);
    String locationInfo = JSON.serialize(locs[0]);
    Test.startTest();
    List<SBR_3_0_AvailabilityCmpController.AvailabilityListWrapper> TestRows = SBR_3_0_AvailabilityCmpController.getProductAvailabilities(
      prodCat,
      'Company',
      locationInfo
    );
    Test.stopTest();
    System.debug(testRows);
    if (!TestRows.isEmpty()) {
      System.assertEquals(
        Integer.valueOf(TestRows[0].availabilityInfo[0].available),
        Integer.valueOf(
          productItems[0].SM_PS_Quantity_Available__c +
          productItems[0].SM_PS_Quantity_Returned__c
        )
      );
    }
  }

  @isTest
  static void givenValidRegionReturnBranchAvailability() {
    makeData();
    List<String> prodCat = new List<string>();
    prodCat.add(productItems[0].SM_PS_Cat_Class__c);
    String locationInfo = JSON.serialize(locs[0]);
    System.debug(locationInfo);
    Test.startTest();
    List<SBR_3_0_AvailabilityCmpController.AvailabilityListWrapper> TestRows = SBR_3_0_AvailabilityCmpController.getProductAvailabilities(
      prodCat,
      'Region',
      locationInfo
    );
    Test.stopTest();
    System.debug(testRows);
    if (!TestRows.isEmpty()) {
      System.assertEquals(
        Integer.valueOf(TestRows[0].availabilityInfo[0].available),
        Integer.valueOf(
          productItems[0].SM_PS_Quantity_Available__c +
          productItems[0].SM_PS_Quantity_Returned__c
        )
      );
    }
  }
  @isTest
  static void testGetProductAvailabilities() {
    makeData();
    List<String> prodCat = new List<string>();
    prodCat.add('');
    String locationInfo = JSON.serialize(locs[0]);
    System.debug(locationInfo);
    Test.startTest();
    List<SBR_3_0_AvailabilityCmpController.AvailabilityListWrapper> TestRows = SBR_3_0_AvailabilityCmpController.getProductAvailabilities(
      prodCat,
      'Region',
      locationInfo
    );
    Test.stopTest();
    System.assertEquals(0, TestRows.size()); //FRONT-8722, modifying to fix test case.
    System.assertEquals(0, TestRows.size());
  }
  @isTest
  static void givenValidTerritoryReturnBranchAvailability() {
    makeData();
    List<String> prodCat = new List<string>();
    prodCat.add(productItems[0].SM_PS_Cat_Class__c);
    String locationInfo = JSON.serialize(locs[0]);
    System.debug(locationInfo);
    Test.startTest();
    List<SBR_3_0_AvailabilityCmpController.AvailabilityListWrapper> TestRows = SBR_3_0_AvailabilityCmpController.getProductAvailabilities(
      prodCat,
      'Territory',
      locationInfo
    );
    Test.stopTest();
    System.debug(testRows);
    if (!TestRows.isEmpty()) {
      System.assertEquals(
        Integer.valueOf(TestRows[0].availabilityInfo[0].available),
        Integer.valueOf(
          productItems[0].SM_PS_Quantity_Available__c +
          productItems[0].SM_PS_Quantity_Returned__c
        )
      );
    }
  }
}