public with sharing class SBR_3_0_CrewSummaryTriggerHandler extends SBR_3_0_TriggerHandler {

    public static Boolean afterInsertRecursiveCheck = false;
    public static Boolean afterUpdateRecursiveCheck = false;
    public static Boolean afterDeleteRecursiveCheck = false;

    public override void afterInsert() {
        if(!SBR_3_0_CrewSummaryTriggerHandler.afterInsertRecursiveCheck) {  
            SBR_3_0_CrewSummaryOperations.updateQuoteLineForScaffolding(Trigger.new);
            SBR_3_0_CrewSummaryTriggerHandler.afterInsertRecursiveCheck = true;
        }
    }

    public override void afterUpdate() {
        if(!SBR_3_0_CrewSummaryTriggerHandler.afterUpdateRecursiveCheck) { 
            SBR_3_0_CrewSummaryOperations.updateQuoteDetails(Trigger.new);
            SBR_3_0_CrewSummaryOperations.updateQuoteLineForScaffolding(Trigger.new);
            SBR_3_0_CrewSummaryTriggerHandler.afterUpdateRecursiveCheck = true;
        }
    }

    public override void afterDelete() {
        if(!SBR_3_0_CrewSummaryTriggerHandler.afterDeleteRecursiveCheck) { 
            SBR_3_0_CrewSummaryOperations.updateQuoteLineForScaffolding(Trigger.old);
            SBR_3_0_CrewSummaryTriggerHandler.afterDeleteRecursiveCheck = true;
        }
    }

 
}