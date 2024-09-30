trigger SBR_3_0_CartTrigger on Cart__c (after insert, after update, before update, before insert) {
    new SBR_3_0_CartTriggerHandler().run();
}