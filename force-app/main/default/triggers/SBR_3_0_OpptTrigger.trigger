trigger SBR_3_0_OpptTrigger on Opportunity (before delete, before insert, before update, after insert, after update) {
    new SBR_3_0_OpptTriggerHandler().run();
}