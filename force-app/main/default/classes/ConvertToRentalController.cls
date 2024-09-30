public with sharing class ConvertToRentalController {
  @AuraEnabled(cacheable=true)
  public static List<sObject> retrieveRentalProduct(
    String rentalClass,
    String rentalCategory
  ) {
    List<Product2> productList = [
      SELECT
        itemNumberUsedByReservationsRentalOut__c,
        Bulk_Item__c,
        Product_Description__c,
        Name
      FROM Product2
      WHERE Class__c = :rentalClass AND Category__c = :rentalCategory
      WITH SECURITY_ENFORCED
    ];
    return productList;
  }
}