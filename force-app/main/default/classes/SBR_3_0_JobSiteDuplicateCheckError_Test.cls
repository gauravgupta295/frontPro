@isTest
public with sharing class SBR_3_0_JobSiteDuplicateCheckError_Test {
    
    
    @isTest public static void JobSiteDuplicateCheckTest() {
        List<Account> acc =SBR_3_0_TestDataFactory.createAccounts(1, True, SBR_3_0_Constants.ACCOUNT_REC_TYPE_PROSPECT);
        Id accId;
        for (Account sob:acc){
            accId=sob.Id;
        }
        
        List<Schema.Location> loc = SBR_3_0_TestDataFactory.createLocations(1, True, SBR_3_0_Constants.LOCATION_REC_TYPE_JOB_LOC);
        Id locId;
        for (Schema.Location sob:loc){
            locId=sob.Id;
        }
        List<Schema.Location> branch = SBR_3_0_TestDataFactory.createLocations(1, True, SBR_3_0_Constants.LOCATION_REC_TYPE_BRANCH);
        Id branchId;
        for (Schema.Location sob:branch){
            branchId=sob.Id;
        }
        
        List<AssociatedLocation> assocLoc =SBR_3_0_TestDataFactory.createAssociatedLocations(1,accId, branchId, locId, True);
        Id assoLocId;
        for (AssociatedLocation sob:assocLoc){
            assoLocId=sob.Id;
        }
        
        Boolean exceptionOccured = false;
        Test.startTest();
        // SBR_3_0_JobSiteDuplicateCheckError.JobSiteDuplicateCheck(passList,true);
        
        
        try {
            List<AssociatedLocation> assocLocDuplicate =SBR_3_0_TestDataFactory.createAssociatedLocations(1,accId, branchId, locId, True);
        } catch (Exception e) {
            exceptionOccured = true;
            Boolean expectedExceptionThrown =  (e.getMessage().contains('There is already a Job Site that matches this Account, Company Code, and Job Site')) ? true : false; 
            System.AssertEquals(true, expectedExceptionThrown, e.getMessage()); 
        }
        
        System.assertEquals(false, exceptionOccured, 'No exception was thrown');
        Test.stopTest();
        
    }
    
    @isTest public static void JobSiteDuplicateCheckforUpdateTest() {
        List<Account> acc =SBR_3_0_TestDataFactory.createAccounts(1, True, SBR_3_0_Constants.ACCOUNT_REC_TYPE_PROSPECT);
        Id accId;
        for (Account sob:acc){
            accId=sob.Id;
        }
        
        List<Schema.Location> loc = SBR_3_0_TestDataFactory.createLocations(1, True, SBR_3_0_Constants.LOCATION_REC_TYPE_JOB_LOC);
        Id locId;
        for (Schema.Location sob:loc){
            locId=sob.Id;
        }
        List<Schema.Location> branch = SBR_3_0_TestDataFactory.createLocations(1, True, SBR_3_0_Constants.LOCATION_REC_TYPE_BRANCH);
        Id branchId;
        for (Schema.Location sob:branch){
            branchId=sob.Id;
        }
        
        List<AssociatedLocation> assocLoc =SBR_3_0_TestDataFactory.createAssociatedLocations(2,accId, branchId, locId, True);
        Id assoLocId;
        for (AssociatedLocation sob:assocLoc){
            assoLocId=sob.Id;
        }
        
        Boolean exceptionThrown = false;
        Test.startTest();
        List<Account> accounts = SBR_3_0_TestDataFactory.createAccounts(2, true, SBR_3_0_Constants.ACCOUNT_REC_TYPE_PROSPECT);
        List<Schema.Location> locations = SBR_3_0_TestDataFactory.createLocations(1,true, SBR_3_0_Constants.LOCATION_REC_TYPE_JOB_LOC);
        List<Schema.Location> branches = SBR_3_0_TestDataFactory.createLocations(1,true, SBR_3_0_Constants.LOCATION_REC_TYPE_BRANCH);
        // insert locations;
        // insert branches;
        List<AssociatedLocation> passList = new List<AssociatedLocation>();
        passList.add(new AssociatedLocation(
            // Account__c = accounts[0].Id,
            Company_Code__c = 'TestCode1',
            Job_Number__c = 'TestJob1',
            // Location__c = locations[0].Id,
            Branch__c = branches[0].Id
        ));
        // passList.add(new AssociatedLocation(
        //  Account__c = accounts[1].Id,
        //  Company_Code__c = 'TestCode2',
        //  Job_Number__c = 'TestJob2',
        // Location__c = locations[1].Id,
        //  Branch__c = branches[1].Id
        //  ));
        
        Map<Id, sObject> oldJobSites = new Map<Id, sObject>();
        oldJobSites.put(passList[0].Id, passList[0]);
        // oldJobSites.put(passList[1].Id, passList[1]);
        
        Map<Id, sObject> newJobSites = new Map<Id, sObject>();
        passList[0].Job_Number__c = 'TestJob2';
        newJobSites.put(passList[0].Id, passList[0]);
        // newJobSites.put(passList[1].Id, passList[1]);
        
        // Call the method
        SBR_3_0_JobSiteDuplicateCheckError.JobSiteDuplicateCheckforUpdate(newJobSites, oldJobSites, passList);
        
        try {
            
            assocLoc[0].Job_Number__c = assocLoc[1].Job_Number__c;
            update assocLoc[0];
        } catch (Exception e) {
            exceptionThrown = true;
            Boolean expectedExceptionThrown =  (e.getMessage().contains('There is already a Job Site that matches this Account, Company Code, and Job Site')) ? true : false; 
            System.AssertEquals(true, expectedExceptionThrown, e.getMessage()); 
        }
        
        SBR_3_0_JobSiteDuplicateCheckError.JobSiteDuplicateCheck(passList,true);
        
        Test.stopTest();
        
    }
    
    
    @isTest public static void test(){
        // create test AssociatedLocation record

        
        
        
    }
    
    
    
}