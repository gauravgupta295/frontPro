/**
 * @description       : Test class for SBR_3_0_PartsAndMerchAvailCmpController
 * @author            : soomjeet.sahoo
 * @group             : salesforce
 * @changes : soomjeet.sahoo   12-14-2023
 * @changes : Lakshya Khandelwal  22-Apr-2024   Added method testFetchEquipmentOnHold
 **/
@isTest(seeAllData=false)
public with sharing class SBR_3_0_PartsAndMerchAvailCmpCntrl_Test {
  private static List<Product2> lstProds;
  private static List<Schema.ProductItem> productItems;
  private static List<Schema.ProductItem> productItems2;
  private static List<Schema.Asset> assets;
  private static List<Schema.Location> locs;

  private static void makeTestDataForAvailability() {
    lstProds = SBR_3_0_TestDataFactory.createProducts(1, true);

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
    pi.RecordTypeId = Schema.SObjectType.ProductItem.getRecordTypeInfosByDeveloperName()
      .get(
        SBR_3_0_PartsAndMerchAvailCmpController.PARTS_AND_MERCH_RECORDTYPE_DEVELOPERNAME
      )
      .getRecordTypeId();
    insert productItems;
  }

  private static void makeTestDataForReserved() {
    // makeTestDataForAvailability();

    locs = SBR_3_0_TestDataFactory.createInventoryLocations(1, false, 'Branch');
    Schema.Location loc = locs[0];
    loc.Name = 'Ohio PC107';
    loc.District__c = 'BALTIMORE DELAWARE DISTRICT';
    loc.Region__c = 'REGION 02';
    loc.Territory__c = 'EAST TERRITORY';
    loc.Company__c = 'SUNBELT RENTALS';
    insert locs;

    lstProds = SBR_3_0_TestDataFactory.createProducts(1, false);
    lstProds[0].Company_Code__c = '01';
    insert lstProds;
    Pricebook2 priceBook = new Pricebook2(
      Id = Test.getStandardPricebookId(),
      IsActive = true,
      Name = 'Standard Price Book'
    );
    update priceBook;
    List<PricebookEntry> proceBookEntry = SBR_3_0_TestDataFactory.createPriceBookEntries(
      lstProds
    );

    Id orderRecType = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName()
      .get('Order')
      .getRecordTypeId();
    Order order = SBR_3_0_TestDataFactory.createOrder(
      false,
      'Test Order',
      orderRecType
    );
    order.Reservation_Order_Number__c = '1234567890';
    order.Estimated_Return_Date__c = date.valueOf('2024-12-12 12:00:00');
    order.Sourcing_Branch__c = locs[0].Id;
    insert order;

    OrderItem orderItem = new OrderItem();
    orderItem.OrderId = order.Id;
    orderItem.Product2Id = lstProds[0].Id;
    orderItem.UnitPrice = 100;
    orderItem.Item_Number__c = 0;
    orderItem.Hourly_Rate__c = 2.0;
    orderItem.Min_Rate__c = 2.0;
    orderItem.Quantity = 5;
    orderItem.Cost__c = 10;
    orderItem.groupID__c = '123';
    orderItem.Free_Flag__c = false;
    orderItem.PricebookEntryId = proceBookEntry[0].Id;
    orderItem.Suggested_Daily_Rate__c = 2.0;
    orderItem.Suggested_Weekly_Rate__c = 2.0;
    orderItem.Suggested_Monthly_Rate__c = 2.0;
    orderItem.Selling_Price__c = 2.0;
    orderItem.Daily_Rate__c = 2.0;
    orderItem.Weekly_Rate__c = 2.0;
    orderItem.Monthly_Rate__c = 2.0;
    orderItem.Rates_Overriden__c = false;
    orderItem.Status_Filled_Qty__c = 0;
    orderItem.Status_Created_Qty__c = 1;
    insert orderItem;
  }

  @IsTest
  private static void testGetAllAvailabilityDetailsAggregated() {
    List<AggregateResult> branchAggregatedResults = new List<AggregateResult>();
    List<AggregateResult> districtAggregatedResults = new List<AggregateResult>();
    List<AggregateResult> regionAggregatedResults = new List<AggregateResult>();
    List<AggregateResult> companyAggregatedResults = new List<AggregateResult>();
    Profile oProfile = [
      SELECT Id
      FROM Profile
      WHERE Name = :SBR_3_0_Constants.PROFILE_NAME_ADMIN
    ];
    User oUsers = SBR_3_0_TestDataFactory.createUser(true, oProfile);
    System.Test.startTest();
    System.runAs(oUsers) {
      makeTestDataForAvailability();
      String testProdId = [SELECT Id FROM Product2 LIMIT 1].Id;
      branchAggregatedResults = SBR_3_0_PartsAndMerchAvailCmpController.getAllAvailabilityDetailsAggregated(
        JSON.serialize(locs[0]),
        'BRANCH',
        new List<String>{ testProdId },
        false
      );

      districtAggregatedResults = SBR_3_0_PartsAndMerchAvailCmpController.getAllAvailabilityDetailsAggregated(
        JSON.serialize(locs[0]),
        'DISTRICT',
        new List<String>{ testProdId },
        false
      );

      regionAggregatedResults = SBR_3_0_PartsAndMerchAvailCmpController.getAllAvailabilityDetailsAggregated(
        JSON.serialize(locs[0]),
        'REGION',
        new List<String>{ testProdId },
        false
      );

      companyAggregatedResults = SBR_3_0_PartsAndMerchAvailCmpController.getAllAvailabilityDetailsAggregated(
        JSON.serialize(locs[0]),
        'COMPANY',
        new List<String>{ testProdId },
        false
      );
    }

    System.Test.stopTest();
    Assert.areEqual(
      true,
      branchAggregatedResults.size() > 0,
      'rows retrieved for branch availability'
    );
    Assert.areEqual(
      true,
      districtAggregatedResults.size() > 0,
      'rows retrieved for district availability'
    );
    Assert.areEqual(
      true,
      regionAggregatedResults.size() > 0,
      'rows retrieved for region availability'
    );
    Assert.areEqual(
      true,
      companyAggregatedResults.size() > 0,
      'rows retrieved for company availability'
    );
  }

  @IsTest
  private static void testGetConsumableSpotlightAvailabilityValues() {
    List<SBR_3_0_AvailabilityCmpController.AvailabilityWrapper> spotlightAvailabilityList = new List<SBR_3_0_AvailabilityCmpController.AvailabilityWrapper>();

    Profile oProfile = [
      SELECT Id
      FROM Profile
      WHERE Name = :SBR_3_0_Constants.PROFILE_NAME_ADMIN
    ];
    User oUsers = SBR_3_0_TestDataFactory.createUser(true, oProfile);
    System.Test.startTest();
    System.runAs(oUsers) {
      makeTestDataForAvailability();
      String testProdId = [SELECT Id FROM Product2 LIMIT 1].Id;
      spotlightAvailabilityList = SBR_3_0_PartsAndMerchAvailCmpController.getConsumableSpotlightAvailabilityValues(
        JSON.serialize(locs[0]),
        new List<String>{ testProdId }
      );
    }
    System.Test.stopTest();
    Assert.areEqual(
      true,
      spotlightAvailabilityList.size() == 4,
      'all 4 spotlight rows retrieved'
    );
  }

  @IsTest
  private static void testFetchOrderItems() {
    List<OrderItem> orderItemList = new List<OrderItem>();
    Profile oProfile = [
      SELECT Id
      FROM Profile
      WHERE Name = :SBR_3_0_Constants.PROFILE_NAME_ADMIN
    ];
    User oUsers = SBR_3_0_TestDataFactory.createUser(true, oProfile);
    System.Test.startTest();
    System.runAs(oUsers) {
      makeTestDataForReserved();
      String testProdId = [SELECT Id FROM Product2 LIMIT 1].Id;
      String testLocId = [SELECT Id FROM Location LIMIT 1].Id;
      orderItemList = SBR_3_0_PartsAndMerchAvailCmpController.fetchReservedOrderItems(
        testLocId,
        new List<String>{ testProdId }
      );
    }
    System.Test.stopTest();
    System.assertEquals(
      true,
      orderItemList[0].Reserved_Item__c,
      'This is not a Reserved Item'
    );
  }
}