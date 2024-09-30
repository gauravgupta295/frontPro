trigger SBR_3_0_LeadTrigger on Lead (before insert,before update, after insert, after update, before delete) {
    new SBR_3_0_LeadTriggerHandler().run();
}