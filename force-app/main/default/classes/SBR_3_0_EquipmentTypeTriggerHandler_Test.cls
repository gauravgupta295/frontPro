@isTest
public with sharing class SBR_3_0_EquipmentTypeTriggerHandler_Test {

    private static SBR_3_0_EquipmentTypeTriggerHandler handler;
    private static String lastMethodCalled;

    static {
        handler = new SBR_3_0_EquipmentTypeTriggerHandler();
        // override its internal trigger detection
        handler.isTriggerExecuting = true;
        handler.newEquipmentTypeMap = new Map<Id, Equipment_Type__c>();
    }

    @isTest
    static void testAfterInsert() {
        handler.setTriggerContext('after insert', null);
        handler.setMaxLoopCount(5);
        handler.run();
        SBR_3_0_TriggerHandler.LoopCount loopCount = SBR_3_0_TriggerHandler.loopCountMap.get('SBR_3_0_EquipmentTypeTriggerHandler');
        System.assertNotEquals(0, loopCount.getCount(), 'SBR_3_0_EquipmentTypeTriggerHandler was not executed');
    }

    @isTest
    static void testAfterUpdate() {
        handler.setTriggerContext('after update', null);
        handler.setMaxLoopCount(5);
        handler.run();
        SBR_3_0_TriggerHandler.LoopCount loopCount = SBR_3_0_TriggerHandler.loopCountMap.get('SBR_3_0_EquipmentTypeTriggerHandler');
        System.assertNotEquals(0, loopCount.getCount(), 'SBR_3_0_EquipmentTypeTriggerHandler was not executed');
    }


}