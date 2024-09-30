public with sharing class SBR_3_0_EngineeringRequest_DA implements SBR_3_0_EngineeringRequest_DAInterface {
    public static Engineering_Request__c getMostRecentRequest() {
        // List<Engineering_Request__c> ers = [SELECT Id, Eng_Job_Number__c FROM Engineering_Request__c ORDER BY Eng_Job_Number__c DESC LIMIT 1];
        // system.debug('new er query query');
        // return ers.size() > 0 ? ers[0] : null;
        return new Engineering_Request__c();
    }
}