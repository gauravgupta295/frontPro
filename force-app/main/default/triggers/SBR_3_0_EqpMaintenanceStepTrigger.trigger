/*********************************************************************************************************************
* Apex Class: SBR_3_0_EqpMaintenanceStepTrigger
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Trigger for Eqp Maintenance Trigger
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME                      DATE                 DETAIL FEATURES
    1.0         Evan Kuminski, Salesforce           2023-10-19           Initial version
*********************************************************************************************************************/

trigger SBR_3_0_EqpMaintenanceStepTrigger on SM_PS_Eqp_Maintenance_Step__c (before update) {
    new SBR_3_0_EqpMaintenanceStepTriggerHandler().run();
}