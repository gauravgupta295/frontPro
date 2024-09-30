public with sharing class SBR_3_0_API_Web_Jobsite_DA implements SBR_3_0_API_Web_Jobsite_DAI {
    public static final String JOBSITEACCOUNTNAME = 'Job Site Placeholder Account';

    public static Account getRelatedAccount(String rmAccountNumber){
        Account relAcct;
        List<Account> relAccts = [SELECT ID, Name, RM_Account_Number__c FROM Account WHERE RM_Account_Number__c =: rmAccountNumber LIMIT 1];
        if(relAccts.size() > 0){
            relAcct = relAccts[0];
        } else {
            relAccts = [SELECT ID, Name, RM_Account_Number__c FROM Account WHERE NAME =: JOBSITEACCOUNTNAME LIMIT 1];
            if(relAccts.size() > 0){
                relAcct = relAccts[0];
            }
        }
        return relAcct;
    }

    public static Schema.Location getRelatedBranchLocation(String branchNumber){
        Schema.Location relBranch;
        List<Schema.Location> relBranches = [SELECT ID, Branch_Location_Number__c FROM Location WHERE Branch_Location_Number__c =: branchNumber LIMIT 1];
        if(relBranches.size() > 0){
            relBranch = relBranches[0];
        }
        return relBranch;
    }

    public static Schema.Location getRelatedJobLocation(String street1, String city, String state, String zip, String country, Decimal latitude, Decimal longitude){
        Schema.Location jobLocation;

        List<Schema.Location> locations = [SELECT ID, Name, Street_Address__c, City__c, Zip_Code__c, State__c, Country__c, Latitude_Longitude__c FROM Location 
                WHERE Street_Address__c =: street1 AND 
                City__c =: city AND 
                State__c =: state AND 
                Zip_Code__c =: zip AND 
                Country__c =: country];

        if(locations.size() > 0){
            jobLocation = locations[0];
        } else {
            if(latitude <> NULL && longitude <> NULL){
                locations = [SELECT ID, Name, Street_Address__c, City__c, Zip_Code__c, State__c, Country__c, Latitude_Longitude__c FROM Location 
                    WHERE Latitude_Longitude__latitude__s=: latitude AND
                    Latitude_Longitude__longitude__s=: longitude LIMIT 1];
                if(locations.size() > 0) {
                    jobLocation = locations[0];
                }
            }
        }

        return jobLocation;
    }
}