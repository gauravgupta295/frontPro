@isTest
private class SBR_3_0_BatchAddPriceBookEntries_Test {
    @isTest
    static void testBatchAddPriceBookEntries() {
        List<Product2> products = new List<Product2>();
        for (Integer i = 0; i < 5; i++) {
            Product2 p = new Product2(
                Name = 'Test Product ' + i,
                Company_Code__c = '01;02'
            );
            products.add(p);
        }
        insert products;
        
        // Create/Update Price Book
        Pricebook2 priceBook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update priceBook;

        Test.startTest();
        SBR_3_0_BatchAddPriceBookEntries batch = new SBR_3_0_BatchAddPriceBookEntries();

        ID batchprocessid = Database.executeBatch(batch, 20);
        ID batchprocessid2 = Database.executeBatch(batch, 20);

        Test.stopTest();

        List<Pricebookentry> pricebookEntries = [SELECT Id, Product2Id, CurrencyIsoCode FROM Pricebookentry];
        System.assertEquals(10, pricebookEntries.size());
    }
    
    @isTest
    static void testNegativeEntries() {
        List<Product2> products = new List<Product2>();
        for (Integer i = 0; i < 5; i++) {
            Product2 p = new Product2(
                Name = 'Test Product ' + i,
                Company_Code__c = '01;02'
            );
            products.add(p);
        }
        insert products;
        for (Integer i = 0; i < products.size(); i++) {
            products[i].Company_Code__c = '01;';
        }
        update products;
        
        // Create/Update Price Book
        Pricebook2 priceBook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update priceBook;

        Test.startTest();
        SBR_3_0_BatchAddPriceBookEntries batch = new SBR_3_0_BatchAddPriceBookEntries();

        ID batchprocessid = Database.executeBatch(batch, 20);
        ID batchprocessid2 = Database.executeBatch(batch, 20);

        Test.stopTest();

        List<Pricebookentry> pricebookEntries = [SELECT Id, Product2Id, CurrencyIsoCode FROM Pricebookentry];
        System.assertEquals(5, pricebookEntries.size());
    }
}