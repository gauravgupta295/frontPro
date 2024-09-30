/*********************************************************************************************************************
* Apex Class: SBR_3_0_QuoteLineDA_Test
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Test Class for SBR_3_0_QuoteLineDA
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Delvin Riley			2023-10-12			Initial version  
*********************************************************************************************************************/

@isTest
public with sharing class SBR_3_0_QuoteLineDA_Test {
  static final String PRODUCT_1_SKU = '123001';
  static final String PRODUCT_2_SKU = '123002';

  @TestSetup
  static void testSetup() {
    /*
		Account acct = new Account(
			RM_Account_Number__c = '12345',
			Name = SBR_3_0_API_Web_Jobsite_DA.JOBSITEACCOUNTNAME,
			BillingStreet = '123 Main Street',
			BillingCity = 'test',
			BillingPostalCode = '20173',
			BillingState = 'VA',
			BillingCountry = 'US',
            Phone = '1234567890'
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
			Product_Hierarchy__c = prdHierachy.Id
		);
		products.add(product);

		Product2 product2 = new Product2(
			Name = 'Test Product 2',
			Product_Title_Internal__c = 'Test Product 2',
			Product_SKU__c = PRODUCT_2_SKU,
			Product_Hierarchy__c = prdHierachy.Id
		);
		products.add(product2);

		insert products;

		List<PricebookEntry> pes = new List<PricebookEntry>();
            for(Product2 prd : products){
                PricebookEntry pe = new PricebookEntry();
                pe.Pricebook2Id = Test.getStandardPricebookId();
                pe.Product2Id = prd.Id;
                pe.UnitPrice = 100;
                pe.IsActive = true;
                pe.UseStandardPrice = false;
                pes.add(pe);
            }
        insert pes;
		
		
		PricebookEntry pbEntry = [SELECT Id FROM PricebookEntry WHERE Pricebook2Id = :Test.getStandardPricebookId() AND Product2Id = :product.Id LIMIT 1];
		PricebookEntry pbEntry2 = [SELECT Id FROM PricebookEntry WHERE Pricebook2Id = :Test.getStandardPricebookId() AND Product2Id = :product2.Id LIMIT 1];
			
				
		SBQQ__Quote__c quote = new SBQQ__Quote__c(
			SBQQ__BillingCity__c = 'Test City',
			Contingency_Plan__c = true,
			Seasonal_Quote__c = true,
			Shift_Pricing_Required__c = true,
			Standby_Pricing__c = true
		);
		insert quote;

		SBQQ__QuoteLine__c quoteLine = new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__Product__c = product.Id, Line_Composite_Key__c = 'Z23bb');
		insert quoteLine;

		SBQQ__QuoteLine__c quoteLine2 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__Product__c = product2.Id, Misc_Charges_Type__c = 'Erect', Line_Name__c = 'ELABOR');
		insert quoteLine2;

		Order order = new Order(
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

		OrderItem orderLine = new OrderItem(OrderId = order.Id, Product2Id = products[0].Id, PricebookEntryId = pes[0].Id, Quantity = 1, UnitPrice = 3.0);
		insert orderLine;

		OrderItem orderLine2 = new OrderItem(OrderId = order.Id, Product2Id = products[1].Id, PricebookEntryId = pes[0].Id, Quantity = 1, UnitPrice = 2.00);
		insert orderLine2;*/

    // Create Account
    Account acct = new Account();
    acct.RM_Account_Number__c = '4';
    acct.Company_Code__c = '01';
    acct.Name = 'Test Account';
    acct.Record_Type_Text__c = 'Credit';
    acct.E_mail_Address__c = '123@asdf.com';
    acct.Phone = '1234567890';
    acct.BillingStreet = '123 Main Street';
    acct.BillingCity = 'Toronto';
    acct.BillingPostalCode = 'M9N7V5';
    acct.BillingState = 'ON';
    acct.BillingCountry = 'CA';
    acct.Drivers_License__c = 'AKF';
    acct.Driver_s_License_State__c = 'AL';
    insert acct;

    // Create Analysis Region
    Analysis_Region__c region = new Analysis_Region__c();
    region.Analysis_Region_Key__c = '001';
    region.Name = 'Test Region';
    region.Company_Code__c = '01';
    insert region;

    // Create Location
    Schema.Location jobLocation = new Schema.Location();
    jobLocation.Name = 'Test Job Location';
    jobLocation.Street_Address__c = '12 Main Street';
    jobLocation.City__c = 'Toronto';
    jobLocation.Zip_Code__c = 'M7N7B3';
    jobLocation.State__c = 'ON';
    jobLocation.Country__c = 'CA';
    jobLocation.RecordTypeId = SBR_3_0_Constants.LOCATION_JOB_RT_ID;
    jobLocation.OMS_Sourcing_Enabled__c = true;
    jobLocation.Distance_Multiplier__c = 50;
    jobLocation.Analysis_Region_Key__c = '001';
    jobLocation.Company_Code__c = '01';
    insert jobLocation;

    // Create Branch
    Schema.Location branchLocation = new Schema.Location();
    branchLocation.Branch_Location_Number__c = '720';
    branchLocation.Name = 'Test Branch Location';
    branchLocation.Street_Address__c = '12 Main Street';
    branchLocation.City__c = 'Toronto';
    branchLocation.Zip_Code__c = 'M7N7B3';
    branchLocation.State__c = 'ON';
    branchLocation.Country__c = 'CA';
    branchLocation.Job_Number__c = '332112';
    branchLocation.RecordTypeId = SBR_3_0_Constants.LOCATION_BRANCH_RT_ID;
    branchLocation.Company_Code__c = 'X';
    branchLocation.Time_Zone_Name__c = 'America/Chicago';
    branchLocation.Time_Zone__c = 3;
    branchLocation.Analysis_Region_Key__c = '293';
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

    // Create Price Book
    Pricebook2 priceBook = new Pricebook2(
      Id = Test.getStandardPricebookId(),
      IsActive = true
    );
    update priceBook;

    // Create Order
    Order order = new Order(
      Quote_Name__c = 'Test Quote',
      AccountId = acct.Id,
      Jobsite__c = jobSite.Id,
      Branch__c = branchLocation.Id,
      Deliverymethod__c = 'Delivery',
      Status = 'Draft',
      Company_Code__c = '01',
      Pricebook2Id = priceBook.Id,
      Start_Date__c = date.valueOf('2022-10-07 12:00:00'),
      EffectiveDate = date.valueOf('2022-10-07 12:00:00'),
      EndDate = date.valueOf('2022-10-08 8:00:00'),
      Earliest_Delivery_Date__c = date.valueOf('2022-10-07 12:00:00'),
      Opt_Out_RPP__c = false,
      Opt_Out_Fuel_Charge__c = false,
      Selling_Channel__c = 'SBRB2B',
      Duration__c = 'Custom'
    );
    insert order;

    SVMXA360__SM_TA_Template__c smTaTemplate = new SVMXA360__SM_TA_Template__c();
    smTaTemplate.Name = 'SBR 3.0 Maintenance Template';
    smTaTemplate.SVMXA360__DeveloperName__c = 'SBR_3_0_Maintenance_Template';
    insert smTaTemplate;

    // Create Product
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
        product.isSerialized = true;
      } else if (i == 1) {
        product.Product_Type__c = 'Parts';
        product.Item_Number__c = '1234GH';
        product.Stock_Class__c = 'AIMFV';
        product.isSerialized = true;
      } else {
        product.Product_Type__c = '';
        product.Item_Number__c = '1285JC';
        product.Stock_Class__c = 'UJEKL';
      }
      products.add(product);
    }
    insert products;

    List<PricebookEntry> pes = new List<PricebookEntry>();
    for (Product2 product : products) {
      PricebookEntry pe = new PricebookEntry();
      pe.Pricebook2Id = Test.getStandardPricebookId();
      pe.Product2Id = product.Id;
      pe.UnitPrice = 100;
      pe.IsActive = true;
      pe.UseStandardPrice = false;
      pes.add(pe);
    }
    insert pes;
    Product2 prod = [
      SELECT Id, Product_SKU__c
      FROM Product2
      WHERE Product_Type__c = 'Cat-Class'
    ];

    System.assert(prod.Product_SKU__c == '123456', 'Assert Success');
    SBQQ__Quote__c quote = new SBQQ__Quote__c(
      SBQQ__BillingCity__c = 'Test City',
      Contingency_Plan__c = true,
      Seasonal_Quote__c = true,
      Shift_Pricing_Required__c = true,
      Standby_Pricing__c = true,
      Account_Record_Type_Txt__c = 'Credit'
    );
    insert quote;

    SBQQ__QuoteLine__c quoteLine = new SBQQ__QuoteLine__c(
      SBQQ__Quote__c = quote.Id,
      SBQQ__Product__c = products[0].Id,
      Line_Composite_Key__c = 'Z23bb',
      Kit_Number_this_Item_Belongs_to__c = '1234'
    );

    insert quoteLine;
    /*
		SBQQ__QuoteLine__c quoteLine2 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__Product__c = products[0].Id, Misc_Charges_Type__c = 'Erect', Line_Name__c = 'ELABOR');
		insert quoteLine2;

		List<OrderItem> orderItems = new List<OrderItem>();
	
		for(Integer i = 0; i < 5; i++){
			OrderItem orderItem = new OrderItem();
			orderItem.OrderId = order.Id;
			orderItem.Product2Id = prod.Id;
			orderItem.UnitPrice = 100;
			orderItem.Item_Number__c = 0;
			orderItem.PricebookEntryId = pes[0].Id;        
			orderItem.Hourly_Rate__c = 2.0;
			orderItem.Min_Rate__c = 2.0;
			orderItem.Quantity = 5;
			orderItem.Cost__c = 10;
			orderItem.groupID__c = '123';
			orderItem.Free_Flag__c = false;
			orderItem.Suggested_Daily_Rate__c = 2.0;
			orderItem.Suggested_Weekly_Rate__c = 2.0;
			orderItem.Suggested_Monthly_Rate__c = 2.0;
			orderItem.Selling_Price__c = 2.0;
			orderItem.Daily_Rate__c = 2.0;
			orderItem.Weekly_Rate__c = 2.0;
			orderItem.Monthly_Rate__c = 2.0;
			orderItem.Rates_Overriden__c = false;
			orderItems.add(orderItem);
		}            
		insert orderItems;*/
  }

  @isTest
  public static void testgetQuoteLine() {
    SBQQ__Quote__c tq = [
      SELECT Id
      FROM SBQQ__Quote__c
      WHERE SBQQ__BillingCity__c = 'Test City'
    ];
    SBQQ__QuoteLine__c testquote = [
      SELECT Id
      FROM SBQQ__QuoteLine__c
      WHERE SBQQ__Quote__c = :tq.Id
      LIMIT 1
    ];

    Test.startTest();
    System.AssertEquals(
      SBR_3_0_QuoteLineDA.getQuoteLine(testquote.Id).Id,
      testquote.Id,
      'Quote Line Not found'
    );

    Test.stopTest();
  }

  @isTest
  public static void testgetQuoteLines() {
    Test.startTest();
    SBQQ__Quote__c tq = [
      SELECT Id
      FROM SBQQ__Quote__c
      WHERE SBQQ__BillingCity__c = 'Test City'
    ];
    System.AssertEquals(
      !SBR_3_0_QuoteLineDA.getQuoteLines(tq.Id).isEmpty(),
      true,
      'No quote lines found'
    );

    Test.stopTest();
  }

  @isTest
  public static void testgetQuotLine() {
    Test.startTest();
    SBQQ__Quote__c tq = [
      SELECT Id
      FROM SBQQ__Quote__c
      WHERE SBQQ__BillingCity__c = 'Test City'
    ];
    System.AssertEquals(
      !SBR_3_0_QuoteLineDA.getQuoteLines(new Set<Id>{ tq.Id }).isEmpty(),
      true,
      'No quote lines found'
    );

    Test.stopTest();
  }

  @isTest
  public static void testgetLine() {
    Test.startTest();
    SBQQ__Quote__c tq = [
      SELECT Id
      FROM SBQQ__Quote__c
      WHERE SBQQ__BillingCity__c = 'Test City'
    ];
    System.AssertEquals(
      !SBR_3_0_QuoteLineDA.getQuoteLines(new Set<Id>{ tq.Id }).isEmpty(),
      true,
      'No quote lines found'
    );

    Test.stopTest();
  }

  @isTest
  public static void testCompKey() {
    List<String> keys = new List<String>();
    keys.add('Z23bb');
    Test.startTest();
    System.AssertEquals(
      !SBR_3_0_QuoteLineDA.getQuoteLineByLineCompositeKey(keys).isEmpty(),
      true,
      'No quote lines found'
    );

    Test.stopTest();
  }

  @isTest
  static void testGetQuoteLinesMap() {
    SBQQ__Quote__c quote = [SELECT id FROM SBQQ__Quote__c];
    Test.startTest();
    Map<String, SBQQ__QuoteLine__c> retrievedQuoteLines = SBR_3_0_QuoteLineDA.getQuoteLinesMap(
      quote.Id
    );

    Test.stopTest();

    System.assert(!retrievedQuoteLines.isEmpty(), 'No quote lines found');
  }

  @isTest
  static void testGetQuoteLinesForEDScaffoldingLaborQuotes() {
    SBQQ__Quote__c quote = [SELECT id FROM SBQQ__Quote__c];
    Set<Id> quoteIds = new Set<Id>();
    quoteIds.add(quote.Id);

    Test.startTest();
    List<SBQQ__QuoteLine__c> retrievedQuoteLines = SBR_3_0_QuoteLineDA.getQuoteLinesForEDScaffoldingLaborQuotes(
      quoteIds
    );

    Test.stopTest();

    System.assert(retrievedQuoteLines.size() == 0, 'No quote lines found');
  }

  @isTest
  static void testGetQuoteLinesForEDLaborQuotes() {
    SBQQ__Quote__c quote = [SELECT id FROM SBQQ__Quote__c];
    Set<Id> quoteIds = new Set<Id>();
    quoteIds.add(quote.Id);

    Test.startTest();
    List<SBQQ__QuoteLine__c> retrievedQuoteLines = SBR_3_0_QuoteLineDA.getQuoteLinesForEDLaborQuotes(
      quoteIds,
      'Erect'
    );

    Test.stopTest();

    System.assert(retrievedQuoteLines.size() == 0, 'No quote lines found');
  }

  @isTest
  static void testGetQuoteLinesForScaffoldingQuotes() {
    SBQQ__Quote__c quote = [SELECT id FROM SBQQ__Quote__c];
    Set<Id> quoteIds = new Set<Id>();
    quoteIds.add(quote.Id);

    Test.startTest();
    List<SBQQ__QuoteLine__c> retrievedQuoteLines = SBR_3_0_QuoteLineDA.getQuoteLinesForScaffoldingQuotes(
      quoteIds
    );

    Test.stopTest();

    System.assert(retrievedQuoteLines.size() == 0, 'No quote lines found');
  }

  @isTest
  static void testPunchoutGetQuoteLinesMap() {
    SBQQ__Quote__c quote = [SELECT id FROM SBQQ__Quote__c];
    Test.startTest();
    Map<String, SBQQ__QuoteLine__c> retrievedQuoteLines = SBR_3_0_QuoteLineDA.punchoutGetQuoteLinesMap(
      quote.Id
    );
    Test.stopTest();

    System.assert(!retrievedQuoteLines.isEmpty());
  }

  @isTest
  public static void testgetQuoteLineItems() {
    SBQQ__Quote__c tq = [
      SELECT Id
      FROM SBQQ__Quote__c
      WHERE SBQQ__BillingCity__c = 'Test City'
    ];
    SBQQ__QuoteLine__c testquoteLine = [
      SELECT Id
      FROM SBQQ__QuoteLine__c
      WHERE SBQQ__Quote__c = :tq.Id
      LIMIT 1
    ];
    Test.startTest();
    System.AssertNotEquals(
      SBR_3_0_QuoteLineDA.getQuoteLines(new Set<String>{ testquoteLine.Id })
        .size(),
      0
    );
    Test.stopTest();
  }

  @isTest
  static void testGetQuoteLinesStringIds() {
    SBQQ__Quote__c tq = [
      SELECT Id
      FROM SBQQ__Quote__c
      WHERE SBQQ__BillingCity__c = 'Test City'
    ];
    SBQQ__QuoteLine__c testquote = [
      SELECT Id
      FROM SBQQ__QuoteLine__c
      WHERE SBQQ__Quote__c = :tq.Id
      LIMIT 1
    ];

    Test.startTest();
    Set<Id> ids = new Set<Id>{ testquote.Id };
    Set<String> idStrs = (Set<String>) JSON.deserialize(
      JSON.serialize(ids),
      Set<String>.class
    );
    List<SBQQ__QuoteLine__c> quoteLines = SBR_3_0_QuoteLineDA.getQuoteLines(
      idStrs
    );

    Test.stopTest();

    System.assert(!quoteLines.isEmpty(), 'No quote lines found');
  }

  @isTest
  static void testGetQuoteLinesRelatedToKit() {
    SBQQ__Quote__c tq = [
      SELECT Id
      FROM SBQQ__Quote__c
      WHERE SBQQ__BillingCity__c = 'Test City'
    ];
    SBQQ__QuoteLine__c testquote = [
      SELECT Id
      FROM SBQQ__QuoteLine__c
      WHERE SBQQ__Quote__c = :tq.Id
      LIMIT 1
    ];

    Test.startTest();
    List<String> kitIds = new List<String>();
    kitIds.add('1234');
    List<SBQQ__QuoteLine__c> quoteLines = SBR_3_0_QuoteLineDA.getQuoteLinesRelatedToKit(
      kitIds
    );

    Test.stopTest();

    System.assert(!quoteLines.isEmpty(), 'No quote lines found');
  }
}