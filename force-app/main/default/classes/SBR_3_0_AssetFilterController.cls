/*********************************************************************************************************************
* Apex Class: SBR_3_0_AssetFilterController
----------------------------------------------------------------------------------------------------------------------
* @description
* - Controller class for loading data for Asset Filter LWC Components called from Flow
----------------------------------------------------------------------------------------------------------------------
* History:
* VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
*	1.		  Shilpa Mitra			  07/02/2024		  Initial Version
**********************************************************************************************************************/

public without sharing class SBR_3_0_AssetFilterController {
/**
* @description Get Filtered Asset Records Count
* @param sCountQuery SOQL COUNT() query to run
* @param companyCode Commpany Code of WPT
* @return Number of values returned by a COUNT() query
*/
    @AuraEnabled(cacheable=true)
    public static Integer getFilteredAssetsCount(String sCountQuery, String companyCode) {
        try {
            List<String> companyCodeWPTList = new List<String>();
            companyCodeWPTList =(companyCode.replaceAll('[\\[\\]\"]','')).split(';');
            sCountQuery =sCountQuery.replace('WHERE','WHERE SM_PS_Company_Code__c IN: companyCodeWPTList AND ');
            Integer recordCount = Database.countQuery(sCountQuery);
            return recordCount;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
* @description Get Filtered Asset Records
* @param sQuery Asset SOQL query to run
* @param companyCode Commpany Code of WPT
* @return List of Asset returned by specified query
*/
    @AuraEnabled(cacheable=true)
    public static List<Asset> getFilteredAssets(String sQuery,String companyCode) {
        try {   
            List<String> companyCodeWPTList = new List<String>();
            companyCodeWPTList =(companyCode.replaceAll('[\\[\\]\"]','')).split(';');
            List<Asset> filteredAssetsList = new List<Asset>();
            sQuery =sQuery.replace('WHERE','WHERE SM_PS_Company_Code__c IN: companyCodeWPTList AND ');
            filteredAssetsList = Database.query(sQuery);
            return filteredAssetsList;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
       }
    }
}