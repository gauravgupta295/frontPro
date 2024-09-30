trigger SBR_3_0_OrderTrigger on Order (before insert, before update, after update) {
    new SBR_3_0_OrderTriggerHandler().run();
}