public class SBR_3_0_EngineeringRequestDA implements SBR_3_0_EngineeringRequestDAI {
    public static List<Engineering_Request__c> getEngineeringRequestDetails(Id engRequestId) {
        return [SELECT Id, Name, Eng_Job_Number__c, Revision_Number__c, Source_Engineering_Request__c 
                FROM Engineering_Request__c WHERE ID = :engRequestId];
    }
    public static List<Engineering_Request__c> getSourceEngineeringRequest(Id sourceEngRequestId) {
        return [SELECT Name, Eng_Job_Number__c, Revision_Number__c, Source_Engineering_Request__c 
                FROM Engineering_Request__c
                WHERE Source_Engineering_Request__c = :sourceEngRequestId
                AND Status__c IN ('Cancelled', 'Completed') ORDER BY Revision_Number__c DESC];
    }
    public static Engineering_Request__c getMostRecentRequest() {
        List<Engineering_Request__c> ers = [SELECT Id, Eng_Job_Number__c FROM Engineering_Request__c ORDER BY Eng_Job_Number__c DESC LIMIT 1];
        return ers.size() > 0 ? ers[0] : null;
    }
}