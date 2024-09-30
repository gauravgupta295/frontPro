/*********************************************************************************************************************
* Apex Class: SBR_3_0_LeadTriggerHandler
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Class to test SBR_3_0_LeadTriggerHandler
* - SAL-326
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Kunal Patel           2022-02-02            Initial version    
*********************************************************************************************************************/
@isTest
public with sharing class SBR_3_0_LeadTriggerHandler_Test {

    private static SBR_3_0_LeadTriggerHandler handler;
    private static String lastMethodCalled;

    static {
        handler = new SBR_3_0_LeadTriggerHandler();
        // override its internal trigger detection
        handler.isTriggerExecuting = true;
        handler.oldLeadMap = new Map<Id, Lead>();
        handler.newLeadMap = new Map<Id, Lead>();
    }

    @isTest
    static void testAfterInsert() {
        handler.setTriggerContext('after insert', null);
        handler.setMaxLoopCount(5);
        handler.run();
        SBR_3_0_TriggerHandler.LoopCount loopCount = SBR_3_0_TriggerHandler.loopCountMap.get('SBR_3_0_LeadTriggerHandler');
        System.assertNotEquals(0, loopCount.getCount(), 'SBR_3_0_LeadTriggerHandler was not executed');
    }

    @isTest
    static void testAfterUpdate() {
        handler.setTriggerContext('after update', null);
        handler.setMaxLoopCount(5);
        handler.run();
        SBR_3_0_TriggerHandler.LoopCount loopCount = SBR_3_0_TriggerHandler.loopCountMap.get('SBR_3_0_LeadTriggerHandler');
        System.assertNotEquals(0, loopCount.getCount(), 'SBR_3_0_LeadTriggerHandler was not executed');
    }
    @isTest
   static void testBeforeUpdate() {
        List<Lead> testLeads = SBR_3_0_TestDataFactory.createLeads(2, false);
        Lead testLeadOne = testLeads[0];
        insert testLeadOne;
        Test.startTest();
        List<Lead> leadsToUpdate = [SELECT Id, OwnerId, Status FROM Lead where id=:testLeadOne.id LIMIT 1];  
        update leadsToUpdate;
        Test.stopTest();
    }
     static testMethod void testBeforeDelete() {
         List<Lead> testLeads = SBR_3_0_TestDataFactory.createLeads(2, false);
        Lead testLeadOne = testLeads[1];
        insert testLeadOne;
        Test.startTest();
        List<Lead> leadsToDelete = [SELECT Id, OwnerId, Status FROM Lead where id=:testLeadOne.id LIMIT 1]; 
        delete leadsToDelete;
        Test.stopTest();
      }
}