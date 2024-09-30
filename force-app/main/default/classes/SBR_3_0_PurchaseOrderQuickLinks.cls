public with sharing class SBR_3_0_PurchaseOrderQuickLinks {
    @AuraEnabled(cacheable=true)
    public static List<SBR_3_0_PurchaseOrderQuickLinks__mdt> getQuickLinks() {
        return [SELECT DeveloperName, MasterLabel, URL__c
                  FROM SBR_3_0_PurchaseOrderQuickLinks__mdt
                 ORDER BY Display_Sequence__c];
    }
}