@isTest
public with sharing class SBR_3_0_EventOperations_Test {
    @isTest
    static void testUpdateRelatedLead(){
        List<Lead> ldList =SBR_3_0_TestDataFactory.createLeads(1, true);
        User u = (SBR_3_0_TestDataFactory.createUsers(1,true))[0];
        List<Event> appts = SBR_3_0_TestDataFactory.createAppointments(1, null, ldList[0].Id, true);
        Lead updateLead = [SELECT ID, Activity_Created__c, Activity_Completed__c FROM Lead WHERE ID =: ldList[0].Id];
        system.assertEquals(true, updateLead.Activity_Created__c, 'Lead.Activity_Created__c is not updated');
    }
}