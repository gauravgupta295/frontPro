public with sharing class SBR_3_0_EngineeringRequestTriggerHandler extends SBR_3_0_TriggerHandler {
    public override void beforeInsert() {
        SBR_3_0_EngineeringRequestOperations.populateJobNumber(Trigger.new);
    }
}