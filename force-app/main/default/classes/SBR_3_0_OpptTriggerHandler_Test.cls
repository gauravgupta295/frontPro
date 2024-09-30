@isTest
public with sharing class SBR_3_0_OpptTriggerHandler_Test {

    private static SBR_3_0_OpptTriggerHandler handler;
    private static String lastMethodCalled;

    static {
        handler = new SBR_3_0_OpptTriggerHandler();
        // override its internal trigger detection
        handler.isTriggerExecuting = true;
        handler.oldOpptMap = new Map<Id, Opportunity>();
        handler.newOpptMap = new Map<Id, Opportunity>();
    }

    @isTest
    static void testBeforeInsert() {
        handler.setTriggerContext('before insert', null);
        handler.setMaxLoopCount(5);
        handler.run();
        SBR_3_0_TriggerHandler.LoopCount loopCount = SBR_3_0_TriggerHandler.loopCountMap.get('SBR_3_0_OpptTriggerHandler');
        System.assertNotEquals(0, loopCount.getCount(), 'SBR_3_0_OpptTriggerHandler was not executed');
    }

    @isTest
    static void testAfterInsert() {
        handler.setTriggerContext('after insert', null);
        handler.setMaxLoopCount(5);
        handler.run();
        SBR_3_0_TriggerHandler.LoopCount loopCount = SBR_3_0_TriggerHandler.loopCountMap.get('SBR_3_0_OpptTriggerHandler');
        System.assertNotEquals(0, loopCount.getCount(), 'SBR_3_0_OpptTriggerHandler was not executed');
    }

    @isTest
    static void testBeforeUpdate() {
        handler.setTriggerContext('before update', null);
        handler.setMaxLoopCount(5);
        handler.run();
        SBR_3_0_TriggerHandler.LoopCount loopCount = SBR_3_0_TriggerHandler.loopCountMap.get('SBR_3_0_OpptTriggerHandler');
        System.assertNotEquals(0, loopCount.getCount(), 'SBR_3_0_OpptTriggerHandler was not executed');
    }

    @isTest
    static void testAfterUpdate() {
        handler.setTriggerContext('after update', null);
        handler.setMaxLoopCount(5);
        handler.run();
        SBR_3_0_TriggerHandler.LoopCount loopCount = SBR_3_0_TriggerHandler.loopCountMap.get('SBR_3_0_OpptTriggerHandler');
        System.assertNotEquals(0, loopCount.getCount(), 'SBR_3_0_OpptTriggerHandler was not executed');
    }
    @isTest
    static void testBeforeDelete() {
        handler.setTriggerContext('before delete', null);
        handler.setMaxLoopCount(5);
        handler.run();
        SBR_3_0_TriggerHandler.LoopCount loopCount = SBR_3_0_TriggerHandler.loopCountMap.get('SBR_3_0_OpptTriggerHandler');
        System.assertNotEquals(0, loopCount.getCount(), 'SBR_3_0_OpptTriggerHandler was not executed');
    }
}