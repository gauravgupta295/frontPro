/*********************************************************************************************************************
* Apex Class: SBR_3_0_AssetTriggerHandler
---------------------------------------------------------------------------------------------------------------------------------------
* @description
* - Class to check Asset After Update actions
* - SAL- 4736 - Check Status update and set the Counters on the Product Item record
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME                     DATE                DETAIL FEATURES
    1.0         Bill Convis ServiceMax             2022-07-15           Initial version
    2.0         Tom Canter                         2022-09-30           SAL-6263 Added Outbox Events
    3.0         Evan Kuminski, Salesforce          2023-07-27           Remove logic for maintaining Quantity fields on Product Item
                                                                        Create Stocked Serial record(s) after Asset creation
    4.0         Evan Kuminski, Salesforce          2024-03-19           Remove call to SBR_3_0_AssetOperations.checkAssetStatusChange()
                                                                        Fix some minor code scanner errors
*********************************************************************************************************************/
public with sharing class SBR_3_0_AssetTriggerHandler extends SBR_3_0_TriggerHandler {
    @TestVisible
    private Map<Id, Schema.Asset> oldAssetMap;
    @TestVisible
    private Map<Id, Schema.Asset> newAssetMap;

    /**
     * @description Default constructor that copies Trigger.oldMap and Trigger.newMap into class variables
     */
    public SBR_3_0_AssetTriggerHandler() {
        this.oldAssetMap = (Map<Id, Schema.Asset>) Trigger.oldMap;
        this.newAssetMap = (Map<Id, Schema.Asset>) Trigger.newMap;
    }

    public override void afterInsert() {
        SBR_3_0_AssetOperations.generateStockedSerials(this.newAssetMap);
        SBR_3_0_AssetOperations.publishUpdatedInSfAssets(this.newAssetMap);
    }

    public override void afterUpdate() {
        /**KM Commented for SAL-25190***/
        //SBR_3_0_AssetOperations.publishAssetType(this.newAssetMap);
        SBR_3_0_AssetOperations.publishAssetType(this.oldAssetMap , this.newAssetMap);
        SBR_3_0_AssetOperations.publishUpdatedInSfAssets(this.newAssetMap);
    }

}