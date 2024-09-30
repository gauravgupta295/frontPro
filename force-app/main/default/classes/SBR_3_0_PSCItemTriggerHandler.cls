/*********************************************************************************************************************
* Apex Class : SBR_3_0_PSCItemTriggerHandler
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Class to handle ProductServiceCampaignItem Before Update context
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME           DATE                 DETAIL FEATURES
    1.0         Chhavi Singhal           2023-11-22           Initial version
    2.0         Evan Kuminski            2023-12-19           Added beforeDelete()
*********************************************************************************************************************/

public with sharing class SBR_3_0_PSCItemTriggerHandler extends SBR_3_0_TriggerHandler {
    @TestVisible
    private Map<Id, Schema.ProductServiceCampaignItem> oldPSCItemMap;
    @TestVisible
    private Map<Id, Schema.ProductServiceCampaignItem> newPSCItemMap;

    public SBR_3_0_PSCItemTriggerHandler() {
        this.oldPSCItemMap = (Map<Id, ProductServiceCampaignItem>) Trigger.oldMap;
        this.newPSCItemMap = (Map<Id, ProductServiceCampaignItem>) Trigger.newMap;
    }

    public override void beforeUpdate() {
       SBR_3_0_PSCItem_Operations.publishActiveRecords(newPSCItemMap.values(), oldPSCItemMap);
    }

    public override void beforeDelete() {
        SBR_3_0_PSCItem_Operations.validateStatusBeforeDelete(oldPSCItemMap.values());
    }
    
    public override void afterDelete(){
        SBR_3_0_PSCItem_Operations.publishDeactivatedRecords(oldPSCItemMap.values());
    }
}