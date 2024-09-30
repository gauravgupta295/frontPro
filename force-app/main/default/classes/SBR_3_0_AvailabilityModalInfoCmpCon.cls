public with sharing class SBR_3_0_AvailabilityModalInfoCmpCon {
    @AuraEnabled
    public static List<Asset> fetchAssets(String catClass, String branchNumber){
        List<Asset> Assets = SBR_3_0_AssetDA.fetchAssetsBasedOnStatus(catClass, branchNumber);
        return Assets;
    }

    @AuraEnabled
    public static List<Equipment_on_Hold__c> fetchEquipmentOnHold(String catClass, String branch){
        try {
            List<Equipment_on_Hold__c> equipment = SBR_3_0_EquipmentOnHoldDA.fetchEquipmentOnHold(catClass, branch);
            return equipment;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static SBR_3_0_AssetDA.AssetInformationWrapper fetchAssetInformation(String assetId){
        return SBR_3_0_AssetDA.fetchAssetInformation(assetId);        
    }


}