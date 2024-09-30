trigger SBR_3_0_EventTrigger on Event (after insert, after update) {
    new SBR_3_0_EventTriggerHandler().run();
}