/*********************************************************************************************************************
* Apex Class: SBR_3_0_OpptOperations
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Class to manage any updates that needs to be done on Opportunities as part of trigger
* - SAL-1397
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Konrad Haight             2022-03-11          Initial version
    2.0         Harry Rokad               2022-08-18          Fetch LatLong logic
*********************************************************************************************************************/
public with sharing class SBR_3_0_OpptOperations {
    public static void preventOpptDeletion(List<Opportunity> opptList){
        Id profileId = userinfo.getProfileId();
        String profileName;
        Profile p = [SELECT Id, Name from Profile WHERE Id = :profileId LIMIT 1];

        if(p != null){
            profileName = p.Name;
        }
        for(Opportunity oppt:opptList){
            if(profileName != SBR_3_0_Constants.PROFILE_NAME_ADMIN){
                oppt.adderror('Opportunity cannot be deleted');
            }
        }
    }
    public static void checkProjectField(List<Opportunity> Opp){
        for(Opportunity opt: Opp){
            // if(oldOpptMap == NULL || oldOpptMap.isEmpty()){
                if (opt.Project__c <> NULL){
                    Id ide = opt.Project__c;
                    Project__c proj = SBR_3_0_ProjectDA.getProject(ide);
                    opt.City__c =  proj.City__c;
                    opt.State__c = proj.State__c;
                    opt.ZIP_Code__c =  proj.ZIP_Code__c;
                    opt.Country__c = proj.Country__c;
                    opt.Latitude_Longitude__Latitude__s = proj.Latitude_Longitude__Latitude__s;
                    opt.Latitude_Longitude__Longitude__s =  proj.Latitude_Longitude__Longitude__s;

                }
            // }
        }
    }

    public static void fetchAddressLatLong(Map<Id, Opportunity> oldOpptMap, Map<Id, Opportunity> newOpptMap){
        Set<Id> changedStreetAddress = new Set<Id>();

        for(Opportunity opt: newOpptMap.values()){
            if(oldOpptMap == NULL || oldOpptMap.isEmpty()){
                // Insert Operation
                // Street Address Populated
                if( opt.Street__c <> NULL || opt.City__c <> NULL || opt.State__c <> NULL || opt.ZIP_Code__c <> NULL || opt.Country__c <> NULL && opt.Project__c==NULL && (opt.Latitude_Longitude__Latitude__s == NULL || opt.Latitude_Longitude__Latitude__s == 0 || opt.Latitude_Longitude__Longitude__s == NULL || opt.Latitude_Longitude__Longitude__s == 0)){
                    if(!changedStreetAddress.contains(opt.Id)){
                        changedStreetAddress.add(opt.Id);
                    }
                }

            } else {
                // Update Operation
                Opportunity oldopt = oldOpptMap.get(opt.Id);
                // Changed Street Address
                if(opt.Street__c <> oldopt.Street__c || opt.City__c <> oldopt.City__c || opt.State__c <> oldopt.State__c || opt.ZIP_Code__c <> oldopt.ZIP_Code__c || opt.Country__c <> oldopt.Country__c && opt.Project__c==NULL){
                    if(!changedStreetAddress.contains(opt.Id)){
                        changedStreetAddress.add(opt.Id);
                    }
                }

            }
        }

        if(!changedStreetAddress.isEmpty()){
            // Call SBR_3_0_BatchOpptLatLongProcessor Batch Class
            SBR_3_0_BatchOpptLatLongProcessor latLongBtch = new SBR_3_0_BatchOpptLatLongProcessor(changedStreetAddress);
            if(Test.isRunningTest() == false) {
                Database.executeBatch(latLongBtch, 1);
            }
            List<Opportunity> changedAddrPcts =  SBR_3_0_OpportunityDA.getOpportunitiesList(changedStreetAddress);
            for(Opportunity opt: changedAddrPcts){
                if(changedStreetAddress.contains(opt.Id)){
                    opt.Latitude_Longitude_Status__c = 'Fetching';
                    opt.Latitude_Longitude_error__c = '';
                    // opt.Street_Address_LatLong__Latitude__s = null;
                    // opt.Street_Address_LatLong__Longitude__s = null;
                }
            }
            update changedAddrPcts;
        }
    }
}