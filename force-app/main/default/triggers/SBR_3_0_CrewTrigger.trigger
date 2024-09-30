trigger SBR_3_0_CrewTrigger on Crew__c (before insert, after insert, after delete) {

    new SBR_3_0_CrewTriggerHandler().run();
}