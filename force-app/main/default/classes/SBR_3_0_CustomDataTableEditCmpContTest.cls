/*********************************************************************************************************************
* Apex Class: SBR_3_0_CustomDataTableEditCmpContTest
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Class to test SBR_3_0_CustomDataTableEditCmpController
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME                  DATE                    DETAIL FEATURES
    1.0         Kunal Patel                     2023-07-04              Initial version    
*********************************************************************************************************************/
@isTest public class SBR_3_0_CustomDataTableEditCmpContTest {

    
	static final String PRODUCT_1_SKU = '123001';
	static final String PRODUCT_2_SKU = '123002';

	@TestSetup
	static void testSetup() {
		//mocking up data for test runs
		Account acct = new Account(
			RM_Account_Number__c = '12345',
			Name = SBR_3_0_API_Web_Jobsite_DA.JOBSITEACCOUNTNAME,
			BillingStreet = '123 Main Street',
			BillingCity = 'test',
			BillingPostalCode = '20173',
			BillingState = 'VA',
			BillingCountry = 'US',
            Phone = '4567676789'
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
		Product2 product = new Product2(
			Name = 'Test Product 1',
			Product_Title_Internal__c = 'Test Product 1',
			Product_SKU__c = PRODUCT_1_SKU,
			Product_Hierarchy__c = prdHierachy.Id,
            Company_Code__c = '01'
		);
		insert product;

		Product2 product2 = new Product2(
			Name = 'Test Product 2',
			Product_Title_Internal__c = 'Test Product 2',
			Product_SKU__c = PRODUCT_2_SKU,
			Product_Hierarchy__c = prdHierachy.Id,
            Company_Code__c = '01'
		);
		insert product2;
        
         SBQQ__ProductFeature__c featureObj = new SBQQ__ProductFeature__c(
                Name = 'Rental Addons',
                Product_Feature_Load_Ext_ID__c = product.Product_SKU__c + '_' + 'Rental Addons',
                SBQQ__ConfiguredSKU__c = product.Id,
                SBQQ__MinOptionCount__c = 1,
                SBQQ__Number__c = 1
        );
		insert featureObj;
        
       

        List<PricebookEntry> pbEntryListInsert =  new  List<PricebookEntry>();

        PricebookEntry pbe1 = new PricebookEntry(
        Pricebook2Id = priceBook.Id,
        Product2Id = product.Id,
        UnitPrice = 1020,
        IsActive = true);
        pbEntryListInsert.add(pbe1);
        
        PricebookEntry pbe2 = new PricebookEntry(
        Pricebook2Id = priceBook.Id,
        Product2Id = product2.Id,
        UnitPrice = 1020,
        IsActive = true);
        pbEntryListInsert.add(pbe2);
        
        insert pbEntryListInsert;

		PricebookEntry pbEntry = [SELECT Id FROM PricebookEntry WHERE Pricebook2Id = :Test.getStandardPricebookId() AND Product2Id = :product.Id LIMIT 1];
		PricebookEntry pbEntry2 = [SELECT Id FROM PricebookEntry WHERE Pricebook2Id = :Test.getStandardPricebookId() AND Product2Id = :product2.Id LIMIT 1];
		
         SBQQ__ProductOption__c prodOption = new SBQQ__ProductOption__c(
            SBQQ__ConfiguredSKU__c = product.Id,
            SBQQ__OptionalSKU__c = product2.Id,
            SBQQ__Number__c = 1,
            SBQQ__Feature__c = featureObj.Id,
            SBQQ__Required__c = true,
            Company_Code__c='01' ,
            SBQQ__Quantity__c = 1 
        );
        insert prodOption;
        
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

        List<SBQQ__QuoteLine__c> quoteLines = new List<SBQQ__QuoteLine__c>();
		SBQQ__QuoteLine__c quoteLine = new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__Product__c = product.Id, SBQQ__Quantity__c=14);
		SBQQ__QuoteLine__c quoteLine2 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__Product__c = product2.Id, SBQQ__Quantity__c=10,is_Forced_Item__c=true,Kit_Number_This_Item_Belongs_to__c=PRODUCT_1_SKU);
        quoteLines.add(quoteLine);
        quoteLines.add(quoteLine2);
		insert quoteLines;

		Order order = new Order(
			AccountId = acct.Id,
			BillingCity = 'Test City',
			Contingency_Order__c = true,
			EffectiveDate = Date.today(),
			Pricebook2Id = Test.getStandardPricebookId(),
			Status = 'Draft',
			Seasonal_Order__c = true,
			Apply_Standby_Rates__c = true,
			Shift_Order__c = true,
            Name = 'Test Order'
		);
		insert order;

		OrderItem orderLine = new OrderItem(OrderId = order.Id, Product2Id = product.Id, PricebookEntryId = pbEntry.Id, Quantity = 1, UnitPrice = 3.0);
		insert orderLine;

		OrderItem orderLine2 = new OrderItem(OrderId = order.Id, Product2Id = product2.Id, PricebookEntryId = pbEntry2.Id, Quantity = 1, UnitPrice = 2.00,is_Forced_Item__c=true,Kit_Number_This_Item_Belongs_to__c=PRODUCT_1_SKU);
		insert orderLine2;
	}

    static testMethod void testQuoteLineUpdates() {
        SBQQ__Quote__c quote = [SELECT ID FROM SBQQ__Quote__c LIMIT 1];
        List<SBQQ__QuoteLine__c> quoteLines = SBR_3_0_QuoteLineDA.getQuoteLines(quote.Id);
        for(SBQQ__QuoteLine__c ql : quoteLines) {
            ql.SBQQ__Quantity__c = 1;
        }
        quoteLines[0].SBQQ__Quantity__c = 0;
        Test.startTest();
        Boolean success = SBR_3_0_CustomDataTableEditCmpController.saveSObjects(quoteLines, null, 'SBQQ__QuoteLine__c');
        System.assertEquals(success, true);
        Test.stopTest();
    }

    static testMethod void testOrderItemUpdates() {
        Order order = [SELECT ID FROM Order LIMIT 1];
        List<OrderItem> orderItems = SBR_3_0_OrderItemDA.getOrderItemsByOrder(order.Id);
        for(OrderItem oi : orderItems) {
            if(!oi.is_Forced_Item__c){
                oi.Quantity = 2;
            }            
        }
        Test.startTest();
        Boolean success = SBR_3_0_CustomDataTableEditCmpController.saveSObjects(null, orderItems, 'OrderItem');
        System.assertEquals(success, true);
        Test.stopTest();
    }
    
    static testMethod void testOrderItemEditorUpdates() {
        Order order = [SELECT ID FROM Order LIMIT 1];
        List<OrderItem> orderItems = SBR_3_0_OrderItemDA.getOrderItemsByOrder(order.Id);
        for(OrderItem oi : orderItems) {
            if(!oi.is_Forced_Item__c){
                oi.Quantity = 2;
            }            
        }
        Test.startTest();
        Boolean success = SBR_3_0_LineItemEditorCmpController.saveSObjects(null, orderItems, 'OrderItem');
        System.assertEquals(success, true);
        Test.stopTest();
    }
}