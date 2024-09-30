/*********************************************************************************************************************
* Apex Class: SBR_3_0_EqpMaintenanceStepTriggerHandler
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Methods used in Eqp Maintenance Step trigger
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME                      DATE                 DETAIL FEATURES
    1.0         Evan Kuminski, Salesforce           2023-10-19           Initial version
*********************************************************************************************************************/

public with sharing class SBR_3_0_EqpMaintenanceStepTriggerHandler extends SBR_3_0_TriggerHandler {
    @TestVisible
    private Map<Id, SM_PS_Eqp_Maintenance_Step__c> oldEqpMaintenanceStepMap;
    @TestVisible
    private Map<Id, SM_PS_Eqp_Maintenance_Step__c> newEqpMaintenanceStepMap;

    public SBR_3_0_EqpMaintenanceStepTriggerHandler() {
        this.oldEqpMaintenanceStepMap = (Map<Id, SM_PS_Eqp_Maintenance_Step__c>) Trigger.oldMap;
        this.newEqpMaintenanceStepMap = (Map<Id, SM_PS_Eqp_Maintenance_Step__c>) Trigger.newMap;
    }

    public override void beforeUpdate() {
        SBR_3_0_EqpMaintenanceStepOperations.publishUpdatesToOutbox(newEqpMaintenanceStepMap.values(), oldEqpMaintenanceStepMap);
    }
}