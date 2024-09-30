public with sharing class SBR_3_0_POJobCostingController {
    @AuraEnabled
    public static List<AssociatedLocation> getJobsitesByAccounts(List<Id> accIds) {
        return [
            SELECT Id, JobsiteName__c, Latitude_Longitude__c, Street_Address__c, City__c, State__c, Country__c, Zip_Code__c, ParentRecordId
            FROM AssociatedLocation
            WHERE ParentRecordId IN :accIds
            ORDER BY JobsiteName__c
        ];
    }
}