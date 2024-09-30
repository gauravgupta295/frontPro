/*********************************************************************************************************************
* Apex Class: SBR_3_0_AssociatedLocationTrigger_Test
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - SAL-1503
* - Test class for AssociatedLocationTrigger class.
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME                      DATE                 DETAIL FEATURES
    1.0         Harry Rokad                        2022-04-11            Initial version    
*********************************************************************************************************************/

@isTest 
public with sharing class SBR_3_0_AssociatedLocationTrigger_Test {
    private static SBR_3_0_AssociatedLocationTriggerHandler handler;
    private static String lastMethodCalled;

    static {
        handler = new SBR_3_0_AssociatedLocationTriggerHandler();
        // override its internal trigger detection
        handler.isTriggerExecuting = true;
        handler.oldLocationMap = new Map<Id, AssociatedLocation>();
        handler.newLocationMap = new Map<Id, AssociatedLocation>();
    }

    @isTest
    static void testAfterInsert() {
        handler.setTriggerContext('after insert', null);
        handler.setMaxLoopCount(5);
        handler.run();
        SBR_3_0_TriggerHandler.LoopCount loopCount = SBR_3_0_TriggerHandler.loopCountMap.get('SBR_3_0_AssociatedLocationTriggerHandler');
        System.assertNotEquals(0, loopCount.getCount(), 'SBR_3_0_AssociatedLocationTriggerHandler was not executed');
    }

    @isTest
    static void testAfterUpdate() {
        handler.setTriggerContext('after update', null);
        handler.setMaxLoopCount(5);
        handler.run();
        SBR_3_0_TriggerHandler.LoopCount loopCount = SBR_3_0_TriggerHandler.loopCountMap.get('SBR_3_0_AssociatedLocationTriggerHandler');
        System.assertNotEquals(0, loopCount.getCount(), 'SBR_3_0_AssociatedLocationTriggerHandler was not executed');
    }

    @isTest
    static void testBeforeUpdate() {
        handler.setTriggerContext('before update', null);
        handler.setMaxLoopCount(5);
        handler.run();
        SBR_3_0_TriggerHandler.LoopCount loopCount = SBR_3_0_TriggerHandler.loopCountMap.get('SBR_3_0_AssociatedLocationTriggerHandler');
        System.assertNotEquals(0, loopCount.getCount(), 'SBR_3_0_AssociatedLocationTriggerHandler was not executed');
    }

    @isTest
    static void testBeforeInsert() {
        handler.setTriggerContext('before insert', null);
        handler.setMaxLoopCount(5);
        handler.run();
        SBR_3_0_TriggerHandler.LoopCount loopCount = SBR_3_0_TriggerHandler.loopCountMap.get('SBR_3_0_AssociatedLocationTriggerHandler');
        System.assertNotEquals(0, loopCount.getCount(), 'SBR_3_0_AssociatedLocationTriggerHandler was not executed');
    }
}