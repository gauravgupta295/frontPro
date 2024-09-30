trigger SBR_3_0_AccountTrigger on Account (after insert, after update, before update, before insert) {
    
    new SBR_3_0_AccountTriggerHandler().run();
}