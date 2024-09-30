/*********************************************************************************************************************
* Apex Class: SBR_3_0_WorkStepTemplateTriggerHandler
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Class to check WorkStepTemplate Before Update actions
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME                      DATE                 DETAIL FEATURES
    1.0         Evan Kuminski, Salesforce           2023-08-18           Initial version
*********************************************************************************************************************/

public with sharing class SBR_3_0_WorkStepTemplateTriggerHandler extends SBR_3_0_TriggerHandler {
    @TestVisible
    private Map<Id, Schema.WorkStepTemplate> oldWorkStepTemplateMap;
    @TestVisible
    private Map<Id, Schema.WorkStepTemplate> newWorkStepTemplateMap;

    public SBR_3_0_WorkStepTemplateTriggerHandler() {
        this.oldWorkStepTemplateMap = (Map<Id, WorkStepTemplate>) Trigger.oldMap;
        this.newWorkStepTemplateMap = (Map<Id, WorkStepTemplate>) Trigger.newMap;
    }

    public override void beforeUpdate() {
        SBR_3_0_WorkStepTemplateOperations.publishSendToRentalManRecords(newWorkStepTemplateMap.values(), oldWorkStepTemplateMap);
        SBR_3_0_WorkStepTemplateOperations.publishDeactivatedSendToRentalManRecords(newWorkStepTemplateMap.values(), oldWorkStepTemplateMap);
    }
}