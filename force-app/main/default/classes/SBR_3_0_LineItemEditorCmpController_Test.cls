/*********************************************************************************************************************
* Apex Class: SBR_3_0_LineItemEditorCmpController_Test
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Test class for SBR_3_0_LineItemEditorCmpController
* - SAL-6165, SAL-6859
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME                      DATE                 DETAIL FEATURES
    1.0         Kaylee Gabus                     2022-09-20              Initial version

*********************************************************************************************************************/
/**
 * @description : Test class for SBR_3_0_LineItemEditorCmpController
 */
@IsTest
public with sharing class SBR_3_0_LineItemEditorCmpController_Test {
  static final String PRODUCT_1_SKU = '123001';
  static final String PRODUCT_2_SKU = '123002';

  @TestSetup
  static void testSetup() {
    Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
      .get('Credit')
      .getRecordTypeId();
    User usr = [
      SELECT Id, Name
      FROM User
      WHERE
        Profile.name = 'System Administrator'
        AND IsActive = TRUE
        AND CompanyName = '01'
      LIMIT 1
    ];
    System.runAs(usr) {
    //mocking up data for test runs
    Account acct = new Account(
      RM_Account_Number__c = '12345',
      Name = SBR_3_0_API_Web_Jobsite_DA.JOBSITEACCOUNTNAME,
      BillingStreet = '123 Main Street',
      BillingCity = 'test',
      BillingPostalCode = '20173',
      BillingState = 'VA',
      BillingCountry = 'US',
        Phone = '4567676789',
        RecordTypeId = recordTypeId
    );
    insert acct;

    // Create Price Book
    Pricebook2 priceBook = new Pricebook2(
      Id = Test.getStandardPricebookId(),
      IsActive = true
    );
    update priceBook;

    Product_Hierarchy__c prdHierachy = new Product_Hierarchy__c(
      Name = 'Test Hierarchy',
      Product_Hierarchy_Code__c = 'Test_HR_Code',
      RecordTypeId = SBR_3_0_Constants.PRODUCT_HIERARCHY_PRODUCT_SUB_CATEGORY_RT_ID
    );
    insert prdHierachy;

      List<Product2> products = new List<Product2>();
    Product2 product = new Product2(
      Name = 'Test Product 1',
      Product_Title_Internal__c = 'Test Product 1',
      Product_SKU__c = PRODUCT_1_SKU,
      Product_Hierarchy__c = prdHierachy.Id,
      Company_Code__c = '01'
    );
      products.add(product);

    Product2 product2 = new Product2(
      Name = 'Test Product 2',
      Product_Title_Internal__c = 'Test Product 2',
      Product_SKU__c = PRODUCT_2_SKU,
      Product_Hierarchy__c = prdHierachy.Id,
      Company_Code__c = '01'
    );
      products.add(product2);
      insert products;

      SBR_3_0_TestDataFactory.createPriceBookEntries(products);
    PricebookEntry pbEntry = [
      SELECT Id
      FROM PricebookEntry
      WHERE
        Pricebook2Id = :Test.getStandardPricebookId()
        AND Product2Id = :product.Id
      LIMIT 1
    ];
    PricebookEntry pbEntry2 = [
      SELECT Id
      FROM PricebookEntry
      WHERE
        Pricebook2Id = :Test.getStandardPricebookId()
        AND Product2Id = :product2.Id
      LIMIT 1
    ];

    SBQQ__Quote__c quote = new SBQQ__Quote__c(
      SBQQ__BillingCity__c = 'Test City',
      Contingency_Plan__c = true,
      Seasonal_Quote__c = true,
      Contingency_Quote__c = true,
      Shift_Pricing_Required__c = true,
      Standby_Pricing__c = true,
      Shift_Rate__c = true,
        Apply_Standby_Rates__c = true,
        SBQQ__Account__c = acct.Id
    );
    insert quote;

      List<SBQQ__QuoteLine__c> qlines = new List<SBQQ__QuoteLine__c>();
    SBQQ__QuoteLine__c quoteLine = new SBQQ__QuoteLine__c(
      SBQQ__Quote__c = quote.Id,
      SBQQ__Product__c = product.Id
    );
      qlines.add(quoteLine);

    SBQQ__QuoteLine__c quoteLine2 = new SBQQ__QuoteLine__c(
      SBQQ__Quote__c = quote.Id,
      SBQQ__Product__c = product2.Id
    );
      qlines.add(quoteLine2);
      insert qlines;

    Order order = new Order(
        Name = 'testOrder',
      AccountId = acct.Id,
      BillingCity = 'Test City',
      Contingency_Order__c = true,
      EffectiveDate = Date.today(),
      Pricebook2Id = Test.getStandardPricebookId(),
      Status = 'Draft',
      Seasonal_Order__c = true,
      Apply_Standby_Rates__c = true,
      Shift_Order__c = true
    );
    insert order;

      List<OrderItem> ois = new List<OrderItem>();
    OrderItem orderLine = new OrderItem(
      OrderId = order.Id,
      Product2Id = product.Id,
      PricebookEntryId = pbEntry.Id,
      Quantity = 1,
      UnitPrice = 3.0
    );
      ois.add(orderLine);

    OrderItem orderLine2 = new OrderItem(
      OrderId = order.Id,
      Product2Id = product2.Id,
      PricebookEntryId = pbEntry2.Id,
      Quantity = 1,
      UnitPrice = 2.00
    );
      ois.add(orderLine2);

      insert ois;
    }
  }

  @IsTest
  static void getLineItemTypeGivenQuoteLineIdReturnsQuoteLineType() {
    SBQQ__QuoteLine__c quoteLine = [
      SELECT Id
      FROM SBQQ__QuoteLine__c
      WHERE SBQQ__Product__r.Product_SKU__c = :PRODUCT_1_SKU
      LIMIT 1
    ];

    Test.startTest();
    String objectType = SBR_3_0_LineItemEditorCmpController.getLineItemType(
      quoteLine.Id
    );
    Test.stopTest();

    System.assertEquals(
      SBR_3_0_LineItemEditorCmpController.QUOTE_LINE_TYPE,
      objectType,
      'Unable to properly identify line item type'
    );
  }

  @IsTest
  static void getLineItemTypeGivenOrderLineIdReturnsOrderLineType() {
    OrderItem orderLine = [
      SELECT Id
      FROM OrderItem
      WHERE Product2.Product_SKU__c = :PRODUCT_1_SKU
      LIMIT 1
    ];

    Test.startTest();
    String objectType = SBR_3_0_LineItemEditorCmpController.getLineItemType(
      orderLine.Id
    );
    Test.stopTest();

    System.assertEquals(
      SBR_3_0_LineItemEditorCmpController.ORDER_LINE_TYPE,
      objectType,
      'Unable to properly identify line item type'
    );
  }

  @IsTest
  static void hasSeasonalRateGivenQuoteIdReturnsBoolean() {
    SBQQ__QuoteLine__c quoteLine = [
      SELECT Id, SBQQ__Quote__c
      FROM SBQQ__QuoteLine__c
      WHERE SBQQ__Product__r.Product_SKU__c = :PRODUCT_1_SKU
      LIMIT 1
    ];

    Test.startTest();
    Boolean hasSeasonalRate = SBR_3_0_LineItemEditorCmpController.hasSeasonalRate(
      quoteLine.SBQQ__Quote__c,
      SBR_3_0_LineItemEditorCmpController.QUOTE_LINE_TYPE
    );
    Test.stopTest();

    System.assert(
      hasSeasonalRate,
      'Unable to determine if parent quote is seasonal'
    );
  }

  @IsTest
  static void hasSeasonalRateGivenOrderIdReturnsBoolean() {
    OrderItem orderLine = [
      SELECT Id, OrderId
      FROM OrderItem
      WHERE Product2.Product_SKU__c = :PRODUCT_1_SKU
      LIMIT 1
    ];

    Test.startTest();
    Boolean hasSeasonalRate = SBR_3_0_LineItemEditorCmpController.hasSeasonalRate(
      orderLine.OrderId,
      SBR_3_0_LineItemEditorCmpController.ORDER_LINE_TYPE
    );
    Test.stopTest();

    System.assert(
      hasSeasonalRate,
      'Unable to determine if parent order is seasonal'
    );
  }

  @IsTest
  static void hasShiftPricingGivenQuoteIdReturnsBoolean() {
    SBQQ__QuoteLine__c quoteLine = [
      SELECT Id, SBQQ__Quote__c
      FROM SBQQ__QuoteLine__c
      WHERE SBQQ__Product__r.Product_SKU__c = :PRODUCT_1_SKU
      LIMIT 1
    ];

    Test.startTest();
    Boolean hasShiftPricing = SBR_3_0_LineItemEditorCmpController.hasShiftPricing(
      quoteLine.SBQQ__Quote__c,
      SBR_3_0_LineItemEditorCmpController.QUOTE_LINE_TYPE
    );
    Test.stopTest();

    System.assert(
      hasShiftPricing,
      'Unable to determine if parent quote requires shift pricing'
    );
  }

  @IsTest
  static void hasShiftPricingGivenOrderIdReturnsBoolean() {
    OrderItem orderLine = [
      SELECT Id, OrderId
      FROM OrderItem
      WHERE Product2.Product_SKU__c = :PRODUCT_1_SKU
      LIMIT 1
    ];

    Test.startTest();
    Boolean hasShiftPricing = SBR_3_0_LineItemEditorCmpController.hasShiftPricing(
      orderLine.OrderId,
      SBR_3_0_LineItemEditorCmpController.ORDER_LINE_TYPE
    );
    Test.stopTest();

    System.assert(
      hasShiftPricing,
      'Unable to determine if parent order requires shift pricing'
    );
  }

  @IsTest
  static void hasStandbyPricingGivenQuoteIdReturnsBoolean() {
    SBQQ__QuoteLine__c quoteLine = [
      SELECT Id, SBQQ__Quote__c
      FROM SBQQ__QuoteLine__c
      WHERE SBQQ__Product__r.Product_SKU__c = :PRODUCT_1_SKU
      LIMIT 1
    ];

    Test.startTest();
    Boolean hasStandbyPricing = SBR_3_0_LineItemEditorCmpController.hasStandbyPricing(
      quoteLine.SBQQ__Quote__c,
      SBR_3_0_LineItemEditorCmpController.QUOTE_LINE_TYPE
    );
    Test.stopTest();

    System.assert(
      hasStandbyPricing,
      'Unable to determine if parent quote has standby pricing'
    );
  }

  @IsTest
  static void hasStandbyPricingGivenOrderIdReturnsBoolean() {
    OrderItem orderLine = [
      SELECT Id, OrderId
      FROM OrderItem
      WHERE Product2.Product_SKU__c = :PRODUCT_1_SKU
      LIMIT 1
    ];

    Test.startTest();
    Boolean hasStandbyPricing = SBR_3_0_LineItemEditorCmpController.hasStandbyPricing(
      orderLine.OrderId,
      SBR_3_0_LineItemEditorCmpController.ORDER_LINE_TYPE
    );
    Test.stopTest();

    System.assert(
      hasStandbyPricing,
      'Unable to determine if parent order has standby pricing'
    );
  }

  @IsTest
  static void hasContingencyPlanGivenQuoteIdReturnsBoolean() {
    SBQQ__QuoteLine__c quoteLine = [
      SELECT Id, SBQQ__Quote__c
      FROM SBQQ__QuoteLine__c
      WHERE SBQQ__Product__r.Product_SKU__c = :PRODUCT_1_SKU
      LIMIT 1
    ];

    Test.startTest();
    Boolean hasContingencyPlan = SBR_3_0_LineItemEditorCmpController.hasContingencyPlan(
      quoteLine.SBQQ__Quote__c,
      SBR_3_0_LineItemEditorCmpController.QUOTE_LINE_TYPE
    );
    Test.stopTest();

    System.assert(
      hasContingencyPlan,
      'Unable to determine if parent quote has contingency plan'
    );
  }

  @IsTest
  static void hasContingencyPlanGivenOrderIdReturnsBoolean() {
    OrderItem orderLine = [
      SELECT Id, OrderId
      FROM OrderItem
      WHERE Product2.Product_SKU__c = :PRODUCT_1_SKU
      LIMIT 1
    ];

    Test.startTest();
    Boolean hasContingencyPlan = SBR_3_0_LineItemEditorCmpController.hasContingencyPlan(
      orderLine.OrderId,
      SBR_3_0_LineItemEditorCmpController.ORDER_LINE_TYPE
    );
    Test.stopTest();

    System.assert(
      hasContingencyPlan,
      'Unable to determine if parent quote has contingency plan'
    );
  }

  @IsTest
  static void getLineItemGivenQuoteLineIdReturnsSObject() {
    SBQQ__QuoteLine__c quoteLine = [
      SELECT Id
      FROM SBQQ__QuoteLine__c
      WHERE SBQQ__Product__r.Product_SKU__c = :PRODUCT_1_SKU
      LIMIT 1
    ];

    Test.startTest();
    SBR_3_0_LineItemEditorCmpController.LineEditorWrapper wrapper = SBR_3_0_LineItemEditorCmpController.getLineItem(
      quoteLine.Id,
      null,
      null
    );
    Test.stopTest();

    System.assertEquals(
      SBR_3_0_LineItemEditorCmpController.QUOTE_LINE_TYPE,
      wrapper.objectType,
      'Did not return quote line item'
    );
  }

  @IsTest
  static void getLineItemGivenOrderIdAndGroupIdReturnsSObject() {
    OrderItem orderLine = [
      SELECT Id
      FROM OrderItem
      WHERE Product2.Product_SKU__c = :PRODUCT_1_SKU
      LIMIT 1
    ];
    //todo: update when group id field is determined
    Test.startTest();
    SBR_3_0_LineItemEditorCmpController.LineEditorWrapper wrapper = SBR_3_0_LineItemEditorCmpController.getLineItem(
      orderLine.Id,
      PRODUCT_1_SKU,
      null
    );
    Test.stopTest();

    System.assertEquals(
      SBR_3_0_LineItemEditorCmpController.ORDER_LINE_TYPE,
      String.valueOf(wrapper.objectType),
      'Did not return order line item'
    );
  }

  @IsTest
  static void getLineItemsGivenQuoteIdAndQuoteLineTypeReturnsListOfSObject() {
    List<SBQQ__QuoteLine__c> line = [
      SELECT Id, SBQQ__Quote__c
      FROM SBQQ__QuoteLine__c
      WHERE SBQQ__Product__r.Product_SKU__c = :PRODUCT_1_SKU
    ];

    Test.startTest();
    List<SObject> retrievedLines = SBR_3_0_LineItemEditorCmpController.getLineItems(
      line[0].SBQQ__Quote__c,
      SBR_3_0_LineItemEditorCmpController.QUOTE_LINE_TYPE
    );
    Test.stopTest();

    System.assertEquals(
      SBR_3_0_LineItemEditorCmpController.QUOTE_LINE_TYPE,
      String.valueOf(retrievedLines[0].Id.getSobjectType()),
      'Did not return quote items'
    );
    System.assertEquals(
      2,
      retrievedLines.size(),
      'Did not properly retrieve quote lines'
    );
  }

  @IsTest
  static void getLineItemsGivenOrderIdAndOrderLineTypeReturnsListOfSObject() {
    List<OrderItem> line = [
      SELECT Id, OrderId
      FROM OrderItem
      WHERE Product2.Product_SKU__c = :PRODUCT_1_SKU
    ];

    Test.startTest();
    List<SObject> retrievedLines = SBR_3_0_LineItemEditorCmpController.getLineItems(
      line[0].OrderId,
      SBR_3_0_LineItemEditorCmpController.ORDER_LINE_TYPE
    );
    Test.stopTest();

    System.assertEquals(
      SBR_3_0_LineItemEditorCmpController.ORDER_LINE_TYPE,
      String.valueOf(retrievedLines[0].Id.getSobjectType()),
      'Did not return order items'
    );
    System.assertEquals(
      2,
      retrievedLines.size(),
      'Did not properly retrieve order lines'
    );
  }

  @IsTest
  static void saveSObjectsGivenQuoteAndLinesShouldUpdateBoth() {
    List<SBQQ__QuoteLine__c> quoteLines = [
      SELECT Id, Line_Item_Notes__c, SBQQ__Quote__c
      FROM SBQQ__QuoteLine__c
      WHERE SBQQ__Product__r.Product_SKU__c = :PRODUCT_1_SKU
    ];
    List<SBQQ__Quote__c> quotes = [
      SELECT Id, SBQQ__Notes__c
      FROM SBQQ__Quote__c
      WHERE Id = :quoteLines[0].SBQQ__Quote__c
    ];
    List<SObject> updateList = new List<SObject>();
    updateList.addAll(quotes);
    updateList.addAll(quoteLines);

    quotes[0].SBQQ__Notes__c = 'updated';
    quoteLines[0].Line_Item_Notes__c = 'updated';

    Test.startTest();
    boolean result = SBR_3_0_LineItemEditorCmpController.saveSObjects(
      quoteLines,
      null,
      null
    );
    Test.stopTest();

    //quotes = [SELECT SBQQ__Notes__c FROM SBQQ__Quote__c WHERE Id = :quotes[0].Id];
    //quoteLines = [SELECT Line_Item_Notes__c FROM SBQQ__QuoteLine__c WHERE Id = :quoteLines[0].Id];
    System.assertEquals(true, result, 'Quote updated');
  }
}