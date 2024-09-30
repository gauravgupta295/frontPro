trigger SBR_3_0_AssociatedLocationTrigger on AssociatedLocation (after insert, after update, before insert, before update) {
    new SBR_3_0_AssociatedLocationTriggerHandler().run();
}