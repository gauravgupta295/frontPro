@isTest
public with sharing class SBR_3_0_ApprovalTriggerHandler_Test {
    private static SBR_3_0_ApprovalTriggerHandler handler;
    private static String lastMethodCalled;

    static {
        handler = new SBR_3_0_ApprovalTriggerHandler();
        // override its internal trigger detection
        handler.isTriggerExecuting = true;
        handler.oldApprovalMap = new Map<Id, sbaa__Approval__c>();
        handler.newApprovalMap = new Map<Id, sbaa__Approval__c>();
    }

    @isTest
    static void testAfterUpdate() {
        handler.setTriggerContext('after update', null);
        handler.setMaxLoopCount(5);
        handler.run();
        SBR_3_0_TriggerHandler.LoopCount loopCount = SBR_3_0_TriggerHandler.loopCountMap.get('SBR_3_0_ApprovalTriggerHandler');
        System.assertNotEquals(0, loopCount.getCount(), 'SBR_3_0_ApprovalTriggerHandler was not executed');
    }
}