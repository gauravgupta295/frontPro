/*********************************************************************************************************************
* Apex Class : SBR_3_0_PSCTriggerHandler
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* @description - Class to handle ProductServiceCampaign Before Update context
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME           DATE                 DETAIL FEATURES
    1.0         Chhavi Singhal           2023-11-10           Initial version
    2.0         Chhavi Singhal           2024-06-10           Added beforeDelete() method
*********************************************************************************************************************/

public with sharing class SBR_3_0_PSCTriggerHandler extends SBR_3_0_TriggerHandler {
    @TestVisible
    private Map<Id, Schema.ProductServiceCampaign> oldPSCMap;
    @TestVisible
    private Map<Id, Schema.ProductServiceCampaign> newPSCMap;

    /**
     * @description Constructor of SBR_3_0_PSCTriggerHandler class
    */
    public SBR_3_0_PSCTriggerHandler() {
        this.oldPSCMap = (Map<Id, ProductServiceCampaign>) Trigger.oldMap;
        this.newPSCMap = (Map<Id, ProductServiceCampaign>) Trigger.newMap;
    }

    public override void beforeUpdate() {
       SBR_3_0_PSC_Operations.publishActiveSendToRMRecords(newPSCMap.values(), oldPSCMap);
       SBR_3_0_PSC_Operations.publishDeactivatedSendToRMRecords(newPSCMap.values(), oldPSCMap);
       SBR_3_0_PSC_Operations.publishUpdatedPSCItemRecords(newPSCMap.values(), oldPSCMap);
    }
    
    public override void afterUpdate() {
       SBR_3_0_PSC_Operations.publishUpdatedPSCItemRecords(newPSCMap.values(), oldPSCMap);
    }
    
    public override void beforeDelete() {
        SBR_3_0_PSC_Operations.publishDeletedSendToRMRecords(oldPSCMap.values());
    }
}