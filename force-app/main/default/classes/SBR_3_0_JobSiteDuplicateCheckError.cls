public with sharing class SBR_3_0_JobSiteDuplicateCheckError {

    public SBR_3_0_JobSiteDuplicateCheckError() {}

    public static void JobSiteDuplicateCheck(List<AssociatedLocation> newJobSites, Boolean fromUpdate) {
        // if(newJobSites!=null) {
        //     Set<String> jobSiteNumbers = new Set<String>();
        //     Set<Id> jobSiteIds = new Set<Id>();
        //     List<Integer> indexes = new List<Integer>();
        //     for (AssociatedLocation al : newJobSites) {
        //         jobSiteNumbers.add((String)al.get('Job_Number__c'));
        //         jobSiteIds.add((String)al.get('Id'));
        //     }
        //     //when called from JobSiteDuplicateCheckforUpdate this is finding the job site by it's new Job_Number__c and erroneously indicating that the job site already exists
        //     List<AssociatedLocation> checkJobSites = [SELECT Job_Number__c FROM AssociatedLocation WHERE Job_Number__c IN :jobSiteNumbers];
        //     if (checkJobSites.size() > 0) {
        //         if(fromUpdate) {
        //             for (AssociatedLocation al : checkJobSites) {
        //                 if(jobSiteIds.contains(al.Id)) {
        //                     indexes.add(checkjobSites.indexof(al));
        //                 }
        //             }
        //             for (Integer i : indexes) {
        //                 checkJobSites.remove(i);
        //             }
        //             if(checkJobSites.size() > 0) {
        //                 newJobSites[0].addError('There is already a Job Site that matches this Account, Company Code, and Job Number. Please review your current field entries or the existing records. If you are creating multiple records, please remove all duplicates and try again.');
        //             }
        //         }
        //         if(!fromUpdate) {
        //             newJobSites[0].addError('There is already a Job Site that matches this Account, Company Code, and Job Number. Please review your current field entries or the existing records. If you are creating multiple records, please remove all duplicates and try again.');
        //         }
        //     }
        // }
    }

    public static void JobSiteDuplicateCheckforUpdate(Map<Id, sObject> newJobSites, Map<Id, sObject> oldJobSites, List<AssociatedLocation> passList) {
        if(newJobSites!=null) {
            for(Id newJobSiteId : newJobSites.keySet()) {
                if(newJobSites!=null && oldJobSites!=null && newJobSites.containsKey(newJobSiteId) && oldJobSites.containsKey(newJobSiteId) ) {
                    if(newJobSites.get(newJobSiteId).get('Job_Number__c') != oldJobSites.get(newJobSiteId).get('Job_Number__c')) {
                        JobSiteDuplicateCheck(passList, true);
                    }
                }
            }
        }
    }
}