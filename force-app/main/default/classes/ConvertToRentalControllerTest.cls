@IsTest
public class ConvertToRentalControllerTest {
  @TestSetup
  public static void setupTestData() {
    //verify record type
    RecordType productRecordType = [
      SELECT Id
      FROM RecordType
      WHERE SObjectType = 'Product2' AND DeveloperName = 'SKU'
      LIMIT 1
    ];

    //create 2 product2 objects with related rental cat class and cat class fields
    String matchCategory = '123CatMatch';
    String matchClass = '123ClassMatch';

    List<Product2> products = new List<Product2>();
    Product2 salesProduct = new Product2(
      RecordTypeId = productRecordType.Id,
      Name = 'Sales Product',
      Category__c = '123',
      Class__c = '100',
      Rental_Category__c = matchCategory,
      Rental_Class__c = matchClass,
      Status__c = 'A',
      Company_Code__c = '01',
      Product_Type__c = 'Merchandise'
    );

    Product2 rentalProduct = new Product2(
      RecordTypeId = productRecordType.Id,
      Name = 'Rental Product',
      Category__c = matchCategory,
      Class__c = matchClass,
      Status__c = 'A',
      Company_Code__c = '01',
      Product_Type__c = 'Merchandise'
    );
    Product2 mismatchSalesProduct = new Product2(
      RecordTypeId = productRecordType.Id,
      Name = 'Mismatch Sales Product',
      Rental_Category__c = 'non-match-123',
      Rental_Class__c = 'non-match-100',
      Status__c = 'A',
      Company_Code__c = '01',
      Product_Type__c = 'Merchandise'
    );
    products.add(salesProduct);
    products.add(rentalProduct);
    products.add(mismatchSalesProduct);
    insert products;
  }

  @IsTest
  public static void testRetrieveRentalProductMatch() {
    Product2 salesProduct = [
      SELECT
        Id,
        Name,
        itemNumberUsedByReservationsRentalOut__c,
        Bulk_Item__c,
        Product_Description__c,
        Rental_Category__c,
        Rental_Class__c
      FROM Product2
      WHERE Name = 'Sales Product'
    ];
    Test.startTest();
    List<Product2> matchProducts = ConvertToRentalController.retrieveRentalProduct(
      salesProduct.Rental_Class__c,
      salesProduct.Rental_Category__c
    );
    Test.stopTest();
    System.assert(
      matchProducts.size() > 0,
      'The matchProduct list should contain 1 product'
    );
    System.assertEquals(
      matchProducts[0].Name,
      'Rental Product',
      'The matchProduct list should contain 1 Rental Product'
    );
  }

  @IsTest
  public static void testRetrieveRentalProductNoMatch() {
    Product2 salesProduct = [
      SELECT
        Id,
        Name,
        itemNumberUsedByReservationsRentalOut__c,
        Bulk_Item__c,
        Product_Description__c,
        Rental_Category__c,
        Rental_Class__c
      FROM Product2
      WHERE Name = 'Mismatch Sales Product'
    ];
    Test.startTest();
    List<Product2> mismatchProducts = ConvertToRentalController.retrieveRentalProduct(
      salesProduct.Rental_Class__c,
      salesProduct.Rental_Category__c
    );
    Test.stopTest();

    System.assertEquals(
      mismatchProducts.size(),
      0,
      'There should be no products that match this product record'
    );
  }
}