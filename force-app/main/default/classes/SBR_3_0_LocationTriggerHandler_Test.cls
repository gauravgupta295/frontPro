@isTest
public with sharing class SBR_3_0_LocationTriggerHandler_Test {
 
    private static SBR_3_0_LocationTriggerHandler handler;
    private static String lastMethodCalled;

    static {
        handler = new SBR_3_0_LocationTriggerHandler();
        // override its internal trigger detection
        handler.isTriggerExecuting = true;
        handler.oldLocationMap = new Map<Id, Schema.Location>();
        handler.newLocationMap = new Map<Id, Schema.Location>();
        handler.newLocationList = new List<Schema.Location>();
    }

    @isTest
    static void testAfterInsert() {
        handler.setTriggerContext('after insert', null);
        handler.setMaxLoopCount(5);
        handler.run();
        SBR_3_0_TriggerHandler.LoopCount loopCount = SBR_3_0_TriggerHandler.loopCountMap.get('SBR_3_0_LocationTriggerHandler');
        System.assertNotEquals(0, loopCount.getCount(), 'SBR_3_0_LocationTriggerHandler was not executed');
    }

    @isTest
    static void testAfterUpdate() {
        handler.setTriggerContext('after update', null);
        handler.setMaxLoopCount(5);
        handler.run();
        SBR_3_0_TriggerHandler.LoopCount loopCount = SBR_3_0_TriggerHandler.loopCountMap.get('SBR_3_0_LocationTriggerHandler');
        System.assertNotEquals(0, loopCount.getCount(), 'SBR_3_0_LocationTriggerHandler was not executed');
    }

}