trigger SBR_3_0_UserTrigger on User (after insert, after update, before update, before insert) {
    
    new SBR_3_0_UserTriggerHandler().run();
}