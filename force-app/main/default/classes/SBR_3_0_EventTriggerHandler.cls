public with sharing class SBR_3_0_EventTriggerHandler extends SBR_3_0_TriggerHandler { 
    public SBR_3_0_EventTriggerHandler() {

    }

    public override void afterInsert() {
        // SAL-25594
        SBR_3_0_EventOperations.updateRelatedLead((List<Event>) Trigger.New);
    }

    public override void afterUpdate() {
        // SAL-25594
        SBR_3_0_EventOperations.updateRelatedLead((List<Event>) Trigger.New);
    }
}