@isTest
public with sharing class SBR_3_0_TaskOperations_Test {
    @isTest
    static void testUpdateRelatedLead(){
        List<Lead> ldList =SBR_3_0_TestDataFactory.createLeads(1, true);
        User u = (SBR_3_0_TestDataFactory.createUsers(1,true))[0];
        List<Task> tasks = SBR_3_0_TestDataFactory.createTasks(1,null, ldList[0].Id, u.Id,false);
        tasks[0].Status = 'Completed';
        insert tasks;
        Lead updateLead = [SELECT ID, Activity_Created__c, Activity_Completed__c FROM Lead WHERE ID =: ldList[0].Id];
        system.assertEquals(true, updateLead.Activity_Created__c, 'Lead.Activity_Created__c is not updated');
        system.assertEquals(true, updateLead.Activity_Completed__c, 'Lead.Activity_Completed__c is not updated');
    }
}