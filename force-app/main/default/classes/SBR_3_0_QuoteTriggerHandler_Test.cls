@isTest
public with sharing class SBR_3_0_QuoteTriggerHandler_Test {
    private static SBR_3_0_QuoteTriggerHandler handler;
    private static String lastMethodCalled;
    
    static {
        handler = new SBR_3_0_QuoteTriggerHandler();
        // override its internal trigger detection
        handler.isTriggerExecuting = true;
        handler.oldQuoteMap = new Map<Id, SBQQ__Quote__c>();
        handler.newQuoteMap = new Map<Id, SBQQ__Quote__c>();
    }
    
    @TestSetup
    static void makeData() {
        SBR_3_0_TestDataFactory.createQuotes(2, true, SBR_3_0_Constants.QUOTE_REC_TYPE_RENTAL_QUOTE);
    }
    
    @isTest
    static void testAfterInsert() {
        
        handler.setTriggerContext('after insert', null);
        handler.setMaxLoopCount(5);
        //handler.run();
        SBR_3_0_TriggerHandler.LoopCount loopCount = SBR_3_0_TriggerHandler.loopCountMap.get('SBR_3_0_QuoteTriggerHandler');
        System.assertEquals(0, loopCount.getCount(), 'SBR_3_0_QuoteTriggerHandler was not executed');
    }
    
    @isTest
    static void testAfterUpdate() {
        List<SBQQ__Quote__c> quotes = [SELECT  Id FROM SBQQ__Quote__c];
        SBQQ__Quote__c newQuote = new  SBQQ__Quote__c(Id= quotes[0].Id, SBQQ__Status__c = 'Won');
		SBR_3_0_QuoteTriggerHandler.beforeUpdateRecursiveCheck = false ;
		update newQuote ;
         handler.setTriggerContext('after update', null);
         handler.setMaxLoopCount(5);
         //handler.run();
        SBR_3_0_TriggerHandler.LoopCount loopCount = SBR_3_0_TriggerHandler.loopCountMap.get('SBR_3_0_QuoteTriggerHandler');
        System.assertEquals(0, loopCount.getCount(), 'SBR_3_0_QuoteTriggerHandler was not executed');
    }

	@isTest
    static void testBeforeUpdate() {
        List<SBQQ__Quote__c> quotes = [SELECT  Id FROM SBQQ__Quote__c];
        SBQQ__Quote__c newQuote = new  SBQQ__Quote__c(Id= quotes[0].Id, SBQQ__Status__c = 'Won');
		SBR_3_0_QuoteTriggerHandler.beforeUpdateRecursiveCheck = false ;
		update newQuote ;
         handler.setTriggerContext('before update', null);
         handler.setMaxLoopCount(5);
         //handler.run();
        SBR_3_0_TriggerHandler.LoopCount loopCount = SBR_3_0_TriggerHandler.loopCountMap.get('SBR_3_0_QuoteTriggerHandler');
        System.assertEquals(0, loopCount.getCount(), 'SBR_3_0_QuoteTriggerHandler was not executed');
    }

    @isTest
    static void testBeforeInsert() {
         handler.setTriggerContext('before insert', null);
         handler.setMaxLoopCount(5);
         //handler.run();
        SBR_3_0_TriggerHandler.LoopCount loopCount = SBR_3_0_TriggerHandler.loopCountMap.get('SBR_3_0_QuoteTriggerHandler');
        System.assertEquals(0, loopCount.getCount(), 'SBR_3_0_QuoteTriggerHandler was not executed');
    }
}