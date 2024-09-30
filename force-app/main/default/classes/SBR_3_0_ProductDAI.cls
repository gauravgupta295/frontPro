public interface SBR_3_0_ProductDAI {
    Map<String, Product2> getProductByExternalId(Set<String> externalIds);
    Product_Hierarchy__c getProductHierarchyByCode(String productHierarchyCode);
    Map<String, SBQQ__ProductFeature__c>  getProductFeatures(Id productId);
    Map<String, Message__c> getMessageRecordsByExternalId(Set<String> externalIds);
    Map<String, Product_Message__c> getProductMessages(Id productId);
    Map<String, SBQQ__ProductOption__c> getProductOptions(Id productId);
    Map<String, Product2> getProductsById(Set<String> ids);
    List<Product2> getProductsByProductSKU(Set<String> productSKUs);
}