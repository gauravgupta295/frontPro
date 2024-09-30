/**
 * @description       : Test Class for all Data Store specific logics covering SBR_3_0_DataStoreUtility,SBR_3_0_DataStoreOperations
 * @author            : soomjeet.sahoo
 * @group             : salesforce.com
 * @last modified on  : 05-14-2024
 * @last modified by  : soomjeet.sahoo
 **/
@isTest(SeeAllData=false)
public with sharing class SBR_3_0_DataStoreOperationsTest {
  @TestSetup
  private static void makeData() {
    SBR_3_0_TestDataFactory.createUsersWithPermissions(
      1,
      true,
      'System Administrator',
      new Set<String>(),
      new Set<String>{ 'SBR_3_0_DataStoreAccess', 'Frontline_User' }
    );
  }

  /**
   * @description : testmethod to test initiateDataStoreEntries method
   * @author soomjeet.sahoo | 05-09-2024
   **/
  @IsTest
  private static void initiateDataStoreEntriesTest() {
    User contextuser = [
      SELECT Id
      FROM USER
      WHERE UserName LIKE '%.unittest'
      LIMIT 1
    ];

    System.Test.startTest();
    System.runAs(contextuser) {
      Order orderRec = SBR_3_0_TestDataFactory.createOrder(
        false,
        'testOrder',
        SBR_3_0_Constants.ORDER_REC_TYPE_CONTRACT_ORDER_ID
      );
      orderRec.Name = 'testOrder1';
      // orderRec.Reservation_Order_Number__c = '119272447';
      SBR_3_0_DataStoreOperations.setByPassTriggerHandlers();
      Database.insert(orderRec);
      // SBR_3_0_DataStoreController.fireDataStoreEvent('Order', orderRec.Id);
      SBR_3_0_DataStoreOperations.initiateDataStoreEntries(
        new List<SBR_3_0_Data_Store_Staging_Event__e>{
          new SBR_3_0_Data_Store_Staging_Event__e(
            Staging_Record_Id__c = orderRec.Id,
            Object_API_Name__c = 'Order'
          )
        }
      );
    }
    Test.stopTest();
    Data_Store__c dataStoreEntry = [SELECT Id FROM Data_Store__c LIMIT 1];
    Assert.areEqual(dataStoreEntry != null, true, 'DataStore Record Created');
  }

  /**
   * @description testmethod to test initiateDataStoreEntries method with multiple entities
   * @author soomjeet.sahoo | 05-09-2024
   **/
  @IsTest
  private static void initiateDataStoreEntriesMultipleEntriesTest() {
    User contextuser = [
      SELECT Id
      FROM USER
      WHERE UserName LIKE '%.unittest'
      LIMIT 1
    ];

    Order orderRec = SBR_3_0_TestDataFactory.createOrder(
      false,
      'testOrder',
      SBR_3_0_Constants.ORDER_REC_TYPE_CONTRACT_ORDER_ID
    );
    orderRec.Name = 'testOrder1';
    SBR_3_0_DataStoreOperations.setByPassTriggerHandlers();
    Database.insert(orderRec);

    Test.startTest();
    System.runAs(contextuser) {
      SBR_3_0_DataStoreOperations.initiateDataStoreEntries(
        new List<SBR_3_0_Data_Store_Staging_Event__e>{
          new SBR_3_0_Data_Store_Staging_Event__e(
            Staging_Record_Id__c = orderRec.Id,
            Object_API_Name__c = 'Order'
          ),
          new SBR_3_0_Data_Store_Staging_Event__e(
            Staging_Record_Id__c = orderRec.AccountId
          )
        }
      );
    }
    Test.stopTest();

    List<Data_Store__c> dataStoreEntryList = [SELECT Id FROM Data_Store__c];
    Assert.areEqual(
      !dataStoreEntryList.isEmpty(),
      true,
      'DataStore Records Created'
    );
  }

  /**
   * @description : testmethod to test updateEntityFromDataStore method
   * @author soomjeet.sahoo | 05-09-2024
   **/
  @IsTest
  static void updateEntityFromDataStoreTest() {
    User contextuser = [
      SELECT Id
      FROM USER
      WHERE UserName LIKE '%.unittest'
      LIMIT 1
    ];

    Order orderRec = SBR_3_0_TestDataFactory.createOrder(
      false,
      'testOrder',
      SBR_3_0_Constants.ORDER_REC_TYPE_CONTRACT_ORDER_ID
    );
    orderRec.Name = 'testOrder1';

    List<Product2> testProds = SBR_3_0_TestDataFactory.createProducts(1, false);
    SBR_3_0_DataStoreOperations.setByPassTriggerHandlers();
    Database.insert(new List<sObject>{ orderRec, testProds[0] });

    PricebookEntry pbEntry = new PricebookEntry();
    pbEntry.Pricebook2Id = Test.getStandardPricebookId();
    pbEntry.IsActive = true;
    pbEntry.UnitPrice = 0;
    pbEntry.Product2Id = testProds[0].Id;
    Database.insert(pbEntry);
    System.debug('pbEntry >> ' + pbEntry);

    // List<PricebookEntry> pbEntries = SBR_3_0_TestDataFactory.createPriceBookEntries(testProds);

    OrderItem orderItem = new OrderItem();
    orderItem.OrderId = orderRec.Id;
    orderItem.UnitPrice = 100;
    orderItem.Item_Number__c = 0;
    orderItem.Quantity = 1;
    orderItem.PricebookEntryId = pbEntry.Id;
    Database.insert(orderItem);

    SBR_3_0_DataStoreOperations.initiateDataStoreEntries(
      new List<SBR_3_0_Data_Store_Staging_Event__e>{
        new SBR_3_0_Data_Store_Staging_Event__e(
          Staging_Record_Id__c = orderRec.Id,
          Object_API_Name__c = 'Order'
        )
      }
    );

    Test.startTest();
    System.runAs(contextuser) {
      // SBR_3_0_DataStoreController.restoreRecordFromDataStore(orderRec.Id);
      SBR_3_0_DataStoreOperations.updateEntityFromDataStore(
        new List<String>{ orderRec.Id }
      );
    }
    Test.stopTest();

    Order orderRecAfterModified = [
      SELECT ID, LastModifiedById
      FROM Order
      WHERE Id = :orderRec.Id
    ];
    Assert.areEqual(
      orderRecAfterModified.LastModifiedById == contextuser.Id,
      true,
      'Record updated from DataStore'
    );
  }

  /**
   * @description : fireDataStoreEvent method test
   * @author soomjeet.sahoo | 05-09-2024
   **/
  @IsTest
  private static void fireDataStoreEventOnOrderTest() {
    User contextuser = [
      SELECT Id
      FROM USER
      WHERE UserName LIKE '%.unittest'
      LIMIT 1
    ];
    Order orderRec = SBR_3_0_TestDataFactory.createOrder(
      false,
      'testOrder',
      SBR_3_0_Constants.ORDER_REC_TYPE_CONTRACT_ORDER_ID
    );
    orderRec.Name = 'testOrder1';
    orderRec.Status = 'Created';
    orderRec.Reservation_Order_Number__c = '119272447';
    SBR_3_0_DataStoreOperations.setByPassTriggerHandlers();
    Database.insert(orderRec);
    System.debug('>> orderRec : ' + orderRec);
    Test.startTest();
    System.runAs(contextuser) {
      SBR_3_0_DataStoreController.fireDataStoreEvent('Order', orderRec.Id);
      Test.getEventBus().deliver();
    }
    Test.stopTest();
    Data_Store__c dataStoreEntry = [SELECT Id FROM Data_Store__c LIMIT 1];
    Assert.areEqual(dataStoreEntry != null, true, 'DataStore Record Created');
  }

  /**
   * @description : fireDataStoreEvent method test
   * @author soomjeet.sahoo | 05-09-2024
   **/
  @IsTest
  private static void fireDataStoreEventTest() {
    User contextuser = [
      SELECT Id
      FROM USER
      WHERE UserName LIKE '%.unittest'
      LIMIT 1
    ];

    Test.startTest();
    System.runAs(contextuser) {
      SBR_3_0_DataStoreController.fireDataStoreEvent('User', contextuser.Id);
      Test.getEventBus().deliver();
    }
    Test.stopTest();
    Data_Store__c dataStoreEntry = [SELECT Id FROM Data_Store__c LIMIT 1];
    Assert.areEqual(dataStoreEntry != null, true, 'DataStore Record Created');
  }

  /**
   * @description
   * @author soomjeet.sahoo | 05-09-2024
   **/
  @IsTest
  private static void restoreRecordFromDataStoreTest() {
    User contextuser = [
      SELECT Id
      FROM USER
      WHERE UserName LIKE '%.unittest'
      LIMIT 1
    ];
    Order orderRec = SBR_3_0_TestDataFactory.createOrder(
      false,
      'testOrder',
      SBR_3_0_Constants.ORDER_REC_TYPE_CONTRACT_ORDER_ID
    );
    orderRec.Name = 'testOrder1';
    SBR_3_0_DataStoreOperations.setByPassTriggerHandlers();
    Database.insert(orderRec);

    SBR_3_0_DataStoreOperations.initiateDataStoreEntries(
      new List<SBR_3_0_Data_Store_Staging_Event__e>{
        new SBR_3_0_Data_Store_Staging_Event__e(
          Staging_Record_Id__c = orderRec.Id,
          Object_API_Name__c = 'Order'
        )
      }
    );

    Test.startTest();
    System.runAs(contextuser) {
      try {
        SBR_3_0_DataStoreController.restoreRecordFromDataStore(orderRec.Id);
      } catch (Exception exp) {
        System.debug(exp);
      }
    }
    Test.stopTest();

    Order orderRecAfterModified = [
      SELECT ID, LastModifiedById
      FROM Order
      WHERE Id = :orderRec.Id
    ];
    Assert.areEqual(
      orderRecAfterModified.LastModifiedById == contextuser.Id,
      true,
      'Record updated from DataStore'
    );
  }

  /**
   * @description : testmethod to test restoreOrderOnCancelActionType method
   * @author soomjeet.sahoo | 05-09-2024
   **/
  @IsTest
  private static void restoreOrderOnCancelActionTypeTest() {
    User contextuser = [
      SELECT Id
      FROM USER
      WHERE UserName LIKE '%.unittest'
      LIMIT 1
    ];

    Order orderRec = SBR_3_0_TestDataFactory.createOrder(
      false,
      'testOrder',
      SBR_3_0_Constants.ORDER_REC_TYPE_CONTRACT_ORDER_ID
    );
    orderRec.Name = 'testOrder1';

    List<Product2> testProds = SBR_3_0_TestDataFactory.createProducts(1, false);
    SBR_3_0_DataStoreOperations.setByPassTriggerHandlers();
    Database.insert(new List<sObject>{ orderRec, testProds[0] });

    PricebookEntry pbEntry = new PricebookEntry();
    pbEntry.Pricebook2Id = Test.getStandardPricebookId();
    pbEntry.IsActive = true;
    pbEntry.UnitPrice = 0;
    pbEntry.Product2Id = testProds[0].Id;
    Database.insert(pbEntry);
    System.debug('pbEntry >> ' + pbEntry);

    // List<PricebookEntry> pbEntries = SBR_3_0_TestDataFactory.createPriceBookEntries(testProds);

    OrderItem orderItem = new OrderItem();
    orderItem.OrderId = orderRec.Id;
    orderItem.UnitPrice = 100;
    orderItem.Item_Number__c = 0;
    orderItem.Quantity = 1;
    orderItem.PricebookEntryId = pbEntry.Id;
    Database.insert(orderItem);

    SBR_3_0_DataStoreOperations.initiateDataStoreEntries(
      new List<SBR_3_0_Data_Store_Staging_Event__e>{
        new SBR_3_0_Data_Store_Staging_Event__e(
          Staging_Record_Id__c = orderRec.Id,
          Object_API_Name__c = 'Order'
        )
      }
    );

    Test.startTest();
    System.runAs(contextuser) {
      SBR_3_0_DataStoreController.restoreOrderOnCancelActionType(
        String.valueOf(orderRec.Id)
      );
    }
    Test.stopTest();

    Order orderRecAfterModified = [
      SELECT ID, LastModifiedById
      FROM Order
      WHERE Id = :orderRec.Id
    ];
    Assert.areEqual(
      orderRecAfterModified.LastModifiedById == contextuser.Id,
      true,
      'Record updated from DataStore'
    );
  }

  /**
   * @description : testmethod to test restoreQuoteOnCancelActionType method
   * @author soomjeet.sahoo | 05-09-2024
   **/
  @IsTest
  private static void restoreQuoteOnCancelActionTypeTest() {
    User contextuser = [
      SELECT Id
      FROM USER
      WHERE UserName LIKE '%.unittest'
      LIMIT 1
    ];

    SBQQ__Quote__c quoteRecord = SBR_3_0_TestDataFactory.createQuotes(
      1,
      false,
      SBR_3_0_Constants.QUOTE_REC_TYPE_RENTAL_QUOTE
    )[0];
    quoteRecord.Account_Record_Type_Txt__c = SBR_3_0_Constants.QUOTE_REC_TYPE_RENTAL_QUOTE;

    // List<Product2> testProds = SBR_3_0_TestDataFactory.createProducts(1, false);
    SBR_3_0_DataStoreOperations.setByPassTriggerHandlers();
    Database.insert(new List<sObject>{ quoteRecord });

    // PricebookEntry pbEntry = new PricebookEntry();
    // pbEntry.Pricebook2Id = Test.getStandardPricebookId();
    // pbEntry.IsActive = true;
    // pbEntry.UnitPrice = 0;
    // pbEntry.Product2Id = testProds[0].Id;
    // Database.insert(pbEntry);
    // System.debug('pbEntry >> ' + pbEntry);

    // List<PricebookEntry> pbEntries = SBR_3_0_TestDataFactory.createPriceBookEntries(testProds);

    // OrderItem orderItem = new OrderItem();
    // orderItem.OrderId = orderRec.Id;
    // orderItem.UnitPrice = 100;
    // orderItem.Item_Number__c = 0;
    // orderItem.Quantity = 1;
    // orderItem.PricebookEntryId = pbEntry.Id;
    // Database.insert(orderItem);

    SBQQ__QuoteLine__c quoteLineRecord = SBR_3_0_TestDataFactory.createQuoteLines(
      1,
      false,
      quoteRecord.Id
    )[0];
    SBR_3_0_TriggerHandler.bypass('SBR_3_0_QuoteLineTriggerHandler');
    Database.insert(quoteLineRecord, false, System.AccessLevel.SYSTEM_MODE);
    // SBR_3_0_DataStoreOperations.initiateDataStoreEntries(
    //   new List<SBR_3_0_Data_Store_Staging_Event__e>{
    //     new SBR_3_0_Data_Store_Staging_Event__e(
    //       Staging_Record_Id__c = quoteRecord.Id,
    //       Object_API_Name__c = 'SBQQ__Quote__c'
    //     )
    //   }
    // );

    SBR_3_0_DataStoreController.fireDataStoreEventForQuoteFlowAction(
      new List<Id>{ quoteRecord.Id }
    );
    Test.getEventBus().deliver();
    Test.startTest();
    System.runAs(contextuser) {
      SBR_3_0_DataStoreController.restoreQuoteOnCancelActionType(
        String.valueOf(quoteRecord.Id)
      );
    }
    Test.stopTest();

    SBQQ__Quote__c quoteRecAfterModified = [
      SELECT ID, LastModifiedById
      FROM SBQQ__Quote__c
      WHERE Id = :quoteRecord.Id
    ];
    Assert.areEqual(
      quoteRecAfterModified.LastModifiedById == contextuser.Id,
      true,
      'Record updated from DataStore'
    );
  }
}