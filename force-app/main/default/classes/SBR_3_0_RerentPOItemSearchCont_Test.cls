@isTest
public class SBR_3_0_RerentPOItemSearchCont_Test {
    
    
    @isTest
    public static void testCreatePOLineItem() {
        //test Data
        Purchase_Order__c testPurchaseOrder = new Purchase_Order__c(Name = 'Test PO');
        insert testPurchaseOrder;
              Product2 testProduct = new Product2(
                    Name = 'Test product',
                    CurrencyIsoCode = 'USD',
                    RecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('SKU').getRecordTypeId()
                );
                insert testProduct;
        Test.startTest();
        SBR_3_0_RerentPOItemSearchController.createPOLineItem(
            testPurchaseOrder.Id,
            testProduct.Id,
            10,
            5,
            'ULI'
        );
		Test.stopTest();

        List<PO_Line_Item__c> createdLineItems = [SELECT Id FROM PO_Line_Item__c WHERE Purchase_Order__c = :testPurchaseOrder.Id];
        System.assertEquals(1, createdLineItems.size(), 'Expected one PO Line Item to be created');
    
    }

    @isTest
    static void testCreateBulkPOLineItem() {
        //test Data
        Purchase_Order__c testPurchaseOrder = new Purchase_Order__c(Name = 'Test PO');
        insert testPurchaseOrder;
              Product2 testProduct = new Product2(
                    Name = 'Test product',
                    CurrencyIsoCode = 'USD',
                    RecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('SKU').getRecordTypeId()
                );
                insert testProduct;

        // Call the createBulkPOLineItem method
        Test.startTest();
        SBR_3_0_RerentPOItemSearchController.createBulkPOLineItem(
            testPurchaseOrder.Id,
            new List<String>{ testProduct.Id },
            new List<Double>{ 10 },
            new List<Decimal>{ 5 },
            new List<String>{ '51511515' }
        );
        Test.stopTest();

        List<PO_Line_Item__c> createdLineItems = [SELECT Id FROM PO_Line_Item__c WHERE Purchase_Order__c = :testPurchaseOrder.Id];
        System.assertEquals(1, createdLineItems.size(), 'Expected one PO Line Item to be created');
    }
    
    @isTest
    static void testGetProductCategoryOptions() {
        //test Data
        //Id recordTypeId = [SELECT id from RecordType where name = 'Product Sub-Category'];
        Product_Hierarchy__c testProdCat = new Product_Hierarchy__c(Name = 'Test PO', 
                                                                    Product_Family_Type__c = 'Cat-Class', 
                                                                    Filter_Level__c = '1',
                                                                    RecordTypeId = Schema.SObjectType.Product_Hierarchy__c.getRecordTypeInfosByDeveloperName().get('Product_Sub_Category').getRecordTypeId(),
                                                                    Product_Hierarchy_Code__c = 'test');
        insert testProdCat;
        Test.startTest();
        List<Product_Hierarchy__c> catList = SBR_3_0_RerentPOItemSearchController.getProductCategoryOptions(1,true,true);
        Test.stopTest();
        System.assertEquals(true, catList.size() > 0, 'No Category Returned');
    }
    
    

}