public with sharing class SBR_3_0_CrewTriggerHandler extends SBR_3_0_TriggerHandler {

    public static Boolean afterDeleteRecursiveCheck = false;

    public override void beforeInsert() {
        SBR_3_0_CrewOperations.createOrUpdateCrewSummary(Trigger.new);
    }

    public override void afterDelete() {
        if(!SBR_3_0_CrewTriggerHandler.afterDeleteRecursiveCheck) {  
            SBR_3_0_CrewOperations.deleteCrewSummary(Trigger.old);
            SBR_3_0_CrewTriggerHandler.afterDeleteRecursiveCheck = true;
        }
    }
}