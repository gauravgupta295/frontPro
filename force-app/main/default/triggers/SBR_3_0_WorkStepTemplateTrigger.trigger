/*********************************************************************************************************************
* Apex Class: SBR_3_0_WorkStepTemplateTrigger
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Class to check WorkStepTemplate Before Update actions
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME                      DATE                 DETAIL FEATURES
    1.0         Evan Kuminski, Salesforce           2023-08-18           Initial version
*********************************************************************************************************************/
trigger SBR_3_0_WorkStepTemplateTrigger on WorkStepTemplate (before update) {
    new SBR_3_0_WorkStepTemplateTriggerHandler().run();
}