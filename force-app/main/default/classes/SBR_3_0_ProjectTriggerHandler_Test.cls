/*********************************************************************************************************************
* Apex Class: SBR_3_0_ProjectTriggerHandler_Test
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Class to test SBR_3_0_ProjectTriggerHandler_Test
* - SAL-2911
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
1.0         Harry Rokad           2022-05-17            Initial version    
*********************************************************************************************************************/


@isTest
public with sharing class SBR_3_0_ProjectTriggerHandler_Test {
    private static SBR_3_0_ProjectTriggerHandler handler;
    private static String lastMethodCalled;
    
    static {
        handler = new SBR_3_0_ProjectTriggerHandler();
        // override its internal trigger detection
        handler.isTriggerExecuting = true;
        handler.oldProjectMap = new Map<Id, Project__c>();
        handler.newProjectMap = new Map<Id, Project__c>();
    }
    
    @isTest
    static void testAfterInsert() {
        handler.setTriggerContext('after insert', null);
        handler.setMaxLoopCount(5);
        handler.run();
        SBR_3_0_TriggerHandler.LoopCount loopCount = SBR_3_0_TriggerHandler.loopCountMap.get('SBR_3_0_ProjectTriggerHandler');
       
        System.assertNotEquals(0, loopCount.getCount(), 'SBR_3_0_ProjectTriggerHandler was not executed');
    }
    
    @isTest
    static void testAfterUpdate() {
        handler.setTriggerContext('after update', null);
        handler.setMaxLoopCount(5);
        handler.run();
      
      
        
        SBR_3_0_TriggerHandler.LoopCount loopCount = SBR_3_0_TriggerHandler.loopCountMap.get('SBR_3_0_ProjectTriggerHandler');
        System.assertNotEquals(0, loopCount.getCount(), 'SBR_3_0_ProjectTriggerHandler was not executed');
    }
    
}