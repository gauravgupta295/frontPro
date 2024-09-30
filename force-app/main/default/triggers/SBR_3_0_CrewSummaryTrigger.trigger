trigger SBR_3_0_CrewSummaryTrigger on Crew_Summary__c (after insert, after update, after delete) {
    new SBR_3_0_CrewSummaryTriggerHandler().run();
}