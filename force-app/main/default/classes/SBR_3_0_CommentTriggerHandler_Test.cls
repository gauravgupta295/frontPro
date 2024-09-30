@isTest
public with sharing class SBR_3_0_CommentTriggerHandler_Test {

    private static SBR_3_0_CommentTriggerHandler handler;
    private static String lastMethodCalled;

    static {
        handler = new SBR_3_0_CommentTriggerHandler();
        // override its internal trigger detection
        handler.isTriggerExecuting = true;
        handler.oldCommentMap = new Map<Id, Comment__c>();
        handler.newCommentMap = new Map<Id, Comment__c>();
    }

    @isTest
    static void testAfterInsert() {
        handler.setTriggerContext('after insert', null);
        handler.setMaxLoopCount(5);
        handler.run();
        SBR_3_0_TriggerHandler.LoopCount loopCount = SBR_3_0_TriggerHandler.loopCountMap.get('SBR_3_0_CommentTriggerHandler');
        Assert.areNotEqual(0, loopCount.getCount(), 'SBR_3_0_CommentTriggerHandler was not executed');
    }

    @isTest
    static void testAfterUpdate() {
        handler.setTriggerContext('after update', null);
        handler.setMaxLoopCount(5);
        handler.run();
        SBR_3_0_TriggerHandler.LoopCount loopCount = SBR_3_0_TriggerHandler.loopCountMap.get('SBR_3_0_CommentTriggerHandler');
        Assert.areNotEqual(0, loopCount.getCount(), 'SBR_3_0_CommentTriggerHandler was not executed');
    }
}