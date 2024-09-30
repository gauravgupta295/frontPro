public interface SBR_3_0_UtilityDAInterface {
    Map<String, PricebookEntry> getPriceBookEntriesByProductSKUs(Set<String> skus);
    Pricebook2 getStandardPriceBookRec();
    String getCurrentUserApplicationName();
}