/*********************************************************************************************************************
* Apex Class: SBR_3_0_AssetOperations
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* @description - Class to Check Asset After Update on Status and update the Status Counters on the linked Product Item Records
* - SAL- 4736
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME                      DATE                 DETAIL FEATURES
    1.0         Bill Convis , ServiceMax          2022-07-15             Initial version
    2.0         Tom Canter                        2022-09-30             SAL-6263 Added Outbox Events
    3.0         Kedar Mudhalwadkar KM             2023-06-28             SAL-25190 Outbox publishing restricted only
																		 if limited field changes detected.
	4.0         Evan Kuminski, Salesforce         2023-07-27             Condense logic that checks for field changes on Asset
																		 Remove logic for maintaining Quantity fields on Product Item
																		 Create Stocked Serial record(s) after Asset creation
    5.0         Evan Kuminski, Salesforce         2024-03-19             SERV-13968 Remove logic for tracking Asset quantities on Product Item
                                                                         Remove come unused, commented out code
                                                                         Address code scanner errors
	6.0         Chhavi Singhal, Salesforce        2024-04-15             Handled null check scenario for potentialProductItemMatches
    7.0         Shilpa Mitra                      2024-04-23             PS-5583 Added a condition, create outbox record only for 
																	     Company owned Assets with 146 catclass and Asset type code 
																	     as TRACTORTRAILOR

    8.0         Chhavi Singhal, Salesforce        2024-05-03             SERV-15313 Handled null check
	9.0         Chhavi Singhal, Salesforce        2024-05-22             Changes done as per SERV-15624
*********************************************************************************************************************/
public with sharing class SBR_3_0_AssetOperations {
    /**
     * @description Generates Stocked_Serial__c records by matching new Assets Company Code, Current Location and Cat
     * Class to an existing ProductItem
     * @param newAssetMap Stores the current Asset values as a Map
     */
    public static void generateStockedSerials(Map<Id, Schema.Asset> newAssetMap) {
        List<ProductItem> potentialProductItemMatches = new List<ProductItem>();
        Set<String> companyCodes = new Set<String>();
        Set<Id> currentLocationIds = new Set<Id>();
        Set<String> catClasses = new Set<String>();
        List<Stocked_Serial__c> stockedSerialsToInsert = new List<Stocked_Serial__c>();
        
        for (Asset newAsset : newAssetMap.values()) {
            companyCodes.add(newAsset.SM_PS_Company_Code__c);
            currentLocationIds.add(newAsset.SM_PS_Current_Location__c);
            catClasses.add(newAsset.SM_PS_Cat_Class__c);
        }

        try {
            potentialProductItemMatches = getPotentialProductItemMatches(companyCodes, currentLocationIds, catClasses);
        } catch(NoAccessException ex) {
            addErrorMessageToAllAssets(
                newAssetMap,
                'You do not have permission to access Product Item data which is necessary for creating Assets. Please contact an administrator.'
            );
        }
 
        stockedSerialsToInsert = createStockedSerialsToInsert(newAssetMap, potentialProductItemMatches);
        
        if(Stocked_Serial__c.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).isCreateable()) {
           if(!stockedSerialsToInsert.isEmpty()) {
              insert stockedSerialsToInsert;
           }
        } else {
                addErrorMessageToAllAssets(
                    newAssetMap,
                    'You do not have permission to create Stocked Serial records, which is required for creating Assets. Please contact an administrator.'
                );
        }
    }
    
    /**
     * @description Created Stocked_Serial__c records by matching new Assets Company Code, Current Location and Cat
     * Class to an existing ProductItem
     * @param newAssetMap Stores the current Asset values as a Map
     * @param potentialProductItemMatches Stores potential product items matches
     * @return List<Stocked_Serial__c> to insert
     */
    private static List<Stocked_Serial__c> createStockedSerialsToInsert(Map<Id, Schema.Asset> newAssetMap, List<ProductItem> potentialProductItemMatches) {
        List<Stocked_Serial__c> stockedSerialsToInsert = new List<Stocked_Serial__c>();
        for(Asset newAsset : newAssetMap.values()) {
            if(!potentialProductItemMatches.isEmpty()) {
                    for (ProductItem productItem : potentialProductItemMatches) {
                        if(isAssetProductItemMatch(newAsset, productItem)) {
                            stockedSerialsToInsert.add(new Stocked_Serial__c(
                                    										 SM_PS_Asset__c = newAsset.Id,
                                    										 SM_PS_Product_Item__c = productItem.Id
                            												));
                        }
                    }
            }
        }
        
        return stockedSerialsToInsert;
    }

    /**
     * @description Get potential Product Items matching new Assets Company Code, Current Location and Cat Class
     * @param companyCodes Stores the current Asset's company code
     * @param currentLocationIds Stores current location Ids
     * @param catClasses Stores the current Asset's CatClasses
     * @return potential List<ProductItem> matches
     */
    private static List<ProductItem> getPotentialProductItemMatches(Set<String> companyCodes, Set<Id> currentLocationIds, Set<String> catClasses) {
        if(
            ProductItem.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).isAccessible() &&
            ProductItem.SM_PS_Company_Code__c.getDescribe().isAccessible() &&
            ProductItem.LocationId.getDescribe().isAccessible() &&
            ProductItem.SM_PS_Cat_Class__c.getDescribe().isAccessible()
        ) {
            return [
                    SELECT
                            Id, SM_PS_Company_Code__c, LocationId, SM_PS_Cat_Class__c
                    FROM
                            ProductItem
                    WHERE
                            SM_PS_Company_Code__c IN :companyCodes AND
                            LocationId IN :currentLocationIds AND
                            SM_PS_Cat_Class__c IN :catClasses
            ];
        } else {
            throw new NoAccessException();
        }
    }

    /**
     * @description Check if Asset and ProductItem is a match
     * @param asset Stores the current Asset
     * @param productItem Stores potential Product Item
     * @return true/false 
     */
    public static Boolean isAssetProductItemMatch(Asset asset, ProductItem productItem) {
        return (
            asset.SM_PS_Company_Code__c == productItem.SM_PS_Company_Code__c &&
            asset.SM_PS_Current_Location__c == productItem.LocationId &&
            asset.SM_PS_Cat_Class__c == productItem.SM_PS_Cat_Class__c
        );
    }

    /**
     * @description Method for adding ErrorMessage To All Assets
     * @param assetMap Stores the current Asset values as a Map
     * @param errorMessage Stores Error Message
     */
    public static void addErrorMessageToAllAssets(Map<Id, Asset> assetMap, String errorMessage) {
        for (Asset asset : assetMap.values()) {
            asset.addError(errorMessage);
        }
    }

    /**
     * @description SAL-25190 new V2 of previous publishAssetType method. With additional oldAssetMap parameter
     * @param oldAssetMap stores the existing record value in the form of Map
     * @param newAssetMap stores the current record value in the form of Map
     */
    public static void publishAssetType(Map<Id, Schema.Asset> oldAssetMap, Map<Id, Schema.Asset> newAssetMap){
        Map<Id, Schema.Asset> assetsToPublish = null;
        assetsToPublish = checkAssetAdditionalFieldChanges(oldAssetMap,newAssetMap);
        if (assetsToPublish != null && assetsToPublish.size()>0){
          SBR_3_0_PublishRecordsToOutbox publishAsset = new SBR_3_0_PublishRecordsToOutbox(assetsToPublish, SBR_3_0_Constants.ASSET_API_NAME);
            publishAsset.publish();
        }
    }

    /**
     * @description Create Outbox__c records for Mulesoft to pick up if SM_PS_Updated_in_SF__c is true
     * @param newAssetMap Stores the current Asset values as a Map
     */
    public static void publishUpdatedInSfAssets(Map<Id, Schema.Asset> newAssetMap) {
        Map<Id, Asset> assetsToPublish = new Map<Id, Asset>();
        for (Asset asset : newAssetMap.values()) {
            if(asset.SM_PS_Updated_in_SF__c) {
                assetsToPublish.put(asset.Id, asset);
            }
        }
        if(!assetsToPublish.isEmpty()) {
            SBR_3_0_PublishRecordsToOutbox publishAsset = new SBR_3_0_PublishRecordsToOutbox(assetsToPublish, SBR_3_0_Constants.ASSET_API_NAME);
            publishAsset.setRecordSourceOfUpdate('SF');
            publishAsset.publish();
        }
    }

    /**KM CHANGES START- COMMENT_2**/
    /**
     * @description SAL-25190 Method to check if additional fields have changed, then only post to outbox. Otherwise skip the check.
     * @param oldAssetMap stores the existing record value in the form of Map
     * @param newAssetMap stores the current record value in the form of Map
     * @return changed asset record in the form of Map
     */
    public static Map<Id, Schema.Asset> checkAssetAdditionalFieldChanges(Map<Id, Schema.Asset> oldAssetMap, Map<Id, Schema.Asset> newAssetMap) {
        Map<Id, Schema.Asset> changedAssets = new Map<Id, Schema.Asset>();
        String companyRecordTypeId = Schema.SObjectType.Asset.getRecordTypeInfosByName().get('Company-Owned Asset').getRecordTypeId();
        String customerRecordTypeId = Schema.SObjectType.Asset.getRecordTypeInfosByName().get('Customer-Owned Asset').getRecordTypeId();
        String rentalRecordTypeId = Schema.SObjectType.Asset.getRecordTypeInfosByName().get('Rental Asset').getRecordTypeId();
        //System.debug('****** SAL-25190 Calling from SBR_3_0_AssetOperations.checkAssetAdditionalFieldChanges | newAssetMap Size=' + newAssetMap.size());  
        for (Id assetId : newAssetMap.keySet()) {
            Schema.Asset oldAsset = oldAssetMap.get(assetId);
            Schema.Asset newAsset = newAssetMap.get(assetId);
            if(newAsset.SM_PS_Updated_in_SF__c) {
                continue;
            }
        
            //Added condition as part of PS-5583
            Boolean checkAssetCondition = (newAsset.RecordTypeId == customerRecordTypeId || newAsset.RecordTypeId == rentalRecordTypeId || (newAsset.RecordTypeId == companyRecordTypeId && newAsset.SM_PS_Category__c=='146' && newAsset.SM_PS_Asset_Type_Code__c=='TRACTORTRAILER'));
            if (checkAssetCondition && oldAsset != null && isAssetFieldsChanged(oldAsset, newAsset)) {
                //System.debug('****** SAL-25190 Inside 001');        
                changedAssets.put(assetId,newAsset);
            }
        }
        return changedAssets;
    }

    /**
     * @description SAL-25190 Check all fields for which change has to be detected.
     * @return Return true/false based on condition
     * @param oldAsset stores current Asset record old value
     * @param newAsset stores current Asset record value
     */
    public static Boolean isAssetFieldsChanged(Schema.Asset oldAsset, Schema.Asset newAsset) {
        List<SObjectField> fieldsToCheckAsStrings = new List<SObjectField>{
                Asset.SM_PS_Asset_Id__c, Asset.SM_PS_Asset_Record_Type_Text__c, Asset.SM_PS_Asset_Type_Code__c,
                Asset.SM_PS_Assigned_Branch_Location_Number__c, Asset.SM_PS_Assigned_Location__c,
                Asset.SM_PS_Cat_Class__c, Asset.SM_PS_Class__c, Asset.SM_PS_Company_Code__c,
                Asset.SM_PS_Currency_Code__c, Asset.SM_PS_Current_Branch_Location_Number__c,
                Asset.SM_PS_Current_Location__c, Asset.SM_PS_Equipment_Number__c, Asset.SM_PS_Equipment_Type_Code__c,
                Asset.SM_PS_License_Number__c, Asset.SM_PS_Miscellaneous_Options__c, Asset.Status
        };
        List<SObjectField> fieldsToCheckAsNonStrings = new List<SObjectField>{
                Asset.SM_PS_Container_Orientation_HLW__c, Asset.SM_PS_Container_Orientation_HWL__c,
                Asset.SM_PS_Container_Orientation_LHW__c, Asset.SM_PS_Container_Orientation_LWH__c,
                Asset.SM_PS_Container_Orientation_WHL__c, Asset.SM_PS_Container_Orientation_WLH__c,
                Asset.SM_PS_Machine_Height__c, Asset.SM_PS_Machine_Length__c, Asset.SM_PS_Machine_Weight__c,
                Asset.SM_PS_Machine_Width__c, Asset.SM_PS_Sell_Price__c
        };

        for (SObjectField fieldToCheck : fieldsToCheckAsStrings) {
            // Using == or Object.equals() on Strings ignores capitalization. Using String.equals() does not.
            // ((String) oldAsset.get(fieldToCheck))?.equals(newAsset.get(fieldToCheck)) will evaluate to null if the
            // checked field on oldAsset is null. This is why we check if the expression equals false instead of just
            // adding a not to the front of it.
            if ((oldAsset.get(fieldToCheck) != null || newAsset.get(fieldToCheck) != null) && ((String) oldAsset.get(fieldToCheck))?.equals(newAsset.get(fieldToCheck)) == false) {
                return true;
            }
        }
        for (SObjectField fieldToCheck : fieldsToCheckAsNonStrings) {
            if(oldAsset.get(fieldToCheck) != newAsset.get(fieldToCheck)) {
                return true;
            }
        }
        return false;
    }
}