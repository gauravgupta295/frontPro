public with sharing class SBR_3_0_EngineeringRequestOperations {
    private static final String ONE_ZERO = '0';

    public static void populateJobNumber(List<Engineering_Request__c> requestList) {
        Set<Id> branchIds = new Set<Id>();
        List<Engineering_Request__c> requestsToUpdate = new List<Engineering_Request__c>();
        Integer startNumber;
        Integer increment = 1;
        for (Engineering_Request__c request : requestList) {
            if(request.Original_Request__c == null) {
                requestsToUpdate.add(request);
                branchIds.add(request.Branch__c);
            }
        }
        if(requestsToUpdate.size() > 0) {
            Map<Id, Schema.Location> branches = SBR_3_0_BranchDA.getLocationsByIds(branchIds);
            Engineering_Request__c lastER = SBR_3_0_EngineeringRequestDA.getMostRecentRequest();
            if (lastER != null && lastER.Eng_Job_Number__c != null) {
                system.debug('last eng job number: ' + lastER.Eng_Job_Number__c);
                startNumber = Integer.valueOf(lastER.Eng_Job_Number__c);
            }
            else {
                startNumber = 30000;
            }
            for (Engineering_Request__c er : requestsToUpdate) {
                Integer jobNumber = startNumber + increment;
                increment++;
                er.Eng_Job_Number__c = jobNumber;
                String jobNumberText = String.valueOf(jobNumber);
                switch on jobNumberText.length() {
                    when 5 {
                        jobNumberText = ONE_ZERO + jobNumberText;
                    }
                    when 6 {
                    }
                    when else {
                        system.debug('Engineering Request Limit Exceeded');
                    }
                }
                if (branches.containsKey(er.Branch__c)) {
                    er.Name = branches.get(er.Branch__c).Branch_Location_Number__c + '-' + jobNumberText;
                }
                else {
                    er.Name = jobNumberText;
                }
            }
        }
    }
}