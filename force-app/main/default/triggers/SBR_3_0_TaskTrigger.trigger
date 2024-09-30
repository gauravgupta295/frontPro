trigger SBR_3_0_TaskTrigger on Task(after insert, after update) {
    new SBR_3_0_TaskTriggerHandler().run();
}