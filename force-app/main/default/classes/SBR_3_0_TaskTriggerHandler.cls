public with sharing class SBR_3_0_TaskTriggerHandler extends SBR_3_0_TriggerHandler { 
    public SBR_3_0_TaskTriggerHandler() {

    }

    public override void afterInsert() {
        // SAL-25594
        SBR_3_0_TaskOperations.updateRelatedLead((List<Task>) Trigger.New);
    }

    public override void afterUpdate() {
        // SAL-25594
        SBR_3_0_TaskOperations.updateRelatedLead((List<Task>) Trigger.New);
    }
}