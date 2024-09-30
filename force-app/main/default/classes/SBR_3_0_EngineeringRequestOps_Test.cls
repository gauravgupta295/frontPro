@isTest
public with sharing class SBR_3_0_EngineeringRequestOps_Test {
    @TestSetup
    static void makeData(){
        SBR_3_0_TestDataFactory.createEngineeringRequest(2, true);
        SBR_3_0_TestDataFactory.createEngineeringRequest(1, true);
    }

    @isTest
    static void testPopulateJobNumber() {
        List<Engineering_Request__c> ers = [SELECT Id, Name, Eng_Job_Number__c FROM Engineering_Request__c WHERE Eng_Job_Number__c = 030001];
        system.assertEquals(1, ers.size());
        List<Engineering_Request__c> ers2 = [SELECT Id, Name, Eng_Job_Number__c FROM Engineering_Request__c WHERE Eng_Job_Number__c = 030002];
        system.assertEquals(1, ers2.size());
        List<Engineering_Request__c> ers3 = [SELECT Id, Name, Eng_Job_Number__c FROM Engineering_Request__c WHERE Eng_Job_Number__c = 030003];
        system.assertEquals(1, ers3.size());
    }
}