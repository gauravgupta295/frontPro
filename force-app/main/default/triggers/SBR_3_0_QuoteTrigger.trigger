trigger SBR_3_0_QuoteTrigger on SBQQ__Quote__c (after insert, after update, before insert,before update) {
    new SBR_3_0_QuotetriggerHandler().run();
}