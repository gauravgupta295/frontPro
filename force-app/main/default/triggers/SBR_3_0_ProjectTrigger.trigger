trigger SBR_3_0_ProjectTrigger on Project__c (before insert, before update, after insert, after update) {
    
    new SBR_3_0_ProjectTriggerHandler().run();
}