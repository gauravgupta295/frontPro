@isTest
private class SBR_3_0_PurchaseOrderQuickLinks_Test {    
    @isTest
    public static void getQuickLinksTest() {
        Test.startTest();
        List<SBR_3_0_PurchaseOrderQuickLinks__mdt> quickLinks = SBR_3_0_PurchaseOrderQuickLinks.getQuickLinks();
    	Test.stopTest();
        
        System.assertEquals(3, quickLinks.size());
    }
}