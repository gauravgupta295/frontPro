/*********************************************************************************************************************
* Apex Class: SBR_3_0_LocationOperations
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Class to publish Location records of Branch record type to Outbox object
* - SAL-1424
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME                      DATE                 DETAIL FEATURES
    1.0         Harry Rokad, Viren Patel           2022-03-30            Initial version    
*********************************************************************************************************************/

public with sharing class SBR_3_0_LocationOperations {

    public static Set<String> validRecTypes;
    public static final String LOCATION_BRANCH_RT_ID = SBR_3_0_Constants.LOCATION_BRANCH_RT_ID;
    public static void publishBranchLocations(Map<Id, Schema.Location> oldLocationMap, Map<Id, Schema.Location> newLocationMap){
        Map<Id, Schema.Location> locToPublish = new Map<Id, Schema.Location>();
        validRecTypes = new Set<String>{SBR_3_0_Constants.LOCATION_REC_TYPE_BRANCH};

        for (Id ide : newLocationMap.keySet()){    
            //if Location RT is Branch, then publish to Outbox.
            if (newLocationMap.get(ide).RecordTypeId==LOCATION_BRANCH_RT_ID){
                locToPublish.put(ide, newLocationMap.get(ide));
            }
        }
        if (locToPublish.size()>0){
            SBR_3_0_PublishRecordsToOutbox publishLocations= new SBR_3_0_PublishRecordsToOutbox(locToPublish, SBR_3_0_Constants.LOCATION_API_NAME, validRecTypes);
            publishLocations.publish();
        }
    }

    public static void updateSourceOfUpdate(List<Schema.Location> locations) {
        //If External user permission is NOT assigned then write source of update to SF
        Boolean hasPermission = FeatureManagement.checkPermission(SBR_3_0_Constants.EXTERNAL_USER_PERMISSION_NAME);
        if (locations!=null){
            for (Schema.Location loc : locations){
                if (hasPermission == False){
                   loc.Source_Of_Update__c = SBR_3_0_Constants.INTERNAL_SBR_USER;
                }
            }
        }
    }

    public static void proccessDeliveryFieldsUpdate(Map<Id, Schema.Location> oldLocations, Map<Id, Schema.Location> newLocations, Boolean isInsert){
        Boolean hasExtPermission = FeatureManagement.checkPermission(SBR_3_0_Constants.EXTERNAL_USER_PERMISSION_NAME);
        List<String> fieldsToExclude = new List<String>();
        fieldsToExclude.add('Delivery_Monday_Open_Time__c');
        fieldsToExclude.add('Delivery_Tuesday_Open_Time__c');
        fieldsToExclude.add('Delivery_Wednesday_Open_Time__c');
        fieldsToExclude.add('Delivery_Thursday_Open_Time__c');
        fieldsToExclude.add('Delivery_Friday_Open_Time__c');
        fieldsToExclude.add('Delivery_Saturday_Open_Time__c');
        fieldsToExclude.add('Delivery_Sunday_Open_Time__c');
        fieldsToExclude.add('Delivery_Monday_Close_Time__c');
        fieldsToExclude.add('Delivery_Tuesday_Close_Time__c');
        fieldsToExclude.add('Delivery_Wednesday_Close_Time__c');
        fieldsToExclude.add('Delivery_Thursday_Close_Time__c');
        fieldsToExclude.add('Delivery_Friday_Close_Time__c');
        fieldsToExclude.add('Delivery_Saturday_Close_Time__c');
        fieldsToExclude.add('Delivery_Sunday_Close_Time__c');
        // Process Updates
        if(!isInsert){
            for(Schema.Location newLoct: newLocations.values()){
                for(String field: fieldsToExclude){
                    if(oldLocations.get(newLoct.Id).get(field) <> newLoct.get(field)){
                        // Ignore delivery field update
                        if(newLoct.Delivery_Times_Updated_by_SF__c && hasExtPermission){
                            newLoct.put(field, oldLocations.get(newLoct.Id).get(field));
                        } else if(!hasExtPermission){
                            newLoct.Delivery_Times_Updated_by_SF__c = true;
                            break;
                        }
                    }
                }
            }
        }
    }

    public static void fetchAddressLatLong(Map<Id, Schema.Location> oldLocationMap, Map<Id, Schema.Location> newLocationMap) {

        Set<Id> changedStreetAddress = new Set<Id>();
        Id jobLocationRT = SBR_3_0_Constants.LOCATION_JOB_RT_ID;

        for(Schema.Location loc: newLocationMap.values()){
            if(loc.RecordTypeId == jobLocationRT) {
                if(oldLocationMap == NULL || oldLocationMap.isEmpty()){
                    // Insert Operation
                    // Street Address Populated
                    if((loc.Street_Address__c <> NULL || 
                    loc.City__c <> NULL ||
                    loc.State__c <> NULL ||
                    loc.Zip_Code__c <> NULL ||
                    loc.Country__c <> NULL) && 
                    (loc.Latitude_Longitude__Latitude__s == NULL || 
                    loc.Latitude_Longitude__Latitude__s == 0 ||
                    loc.Latitude_Longitude__Longitude__s == NULL || 
                    loc.Latitude_Longitude__Longitude__s == 0)
                    ){
                        if(!changedStreetAddress.contains(loc.Id)){
                            changedStreetAddress.add(loc.Id);
                        }
                    }

                } else {
                    // Update Operation
                    Schema.Location oldLoc = oldLocationMap.get(loc.Id);
                    // Changed Street Address
                    if(loc.Street_Address__c <> oldLoc.Street_Address__c || 
                    loc.City__c <> oldLoc.City__c ||
                    loc.State__c <> oldLoc.State__c ||
                    loc.Zip_Code__c <> oldLoc.Zip_Code__c ||
                    loc.Country__c <> oldLoc.Country__c){
                        if(!changedStreetAddress.contains(loc.Id)){
                            changedStreetAddress.add(loc.Id);
                        }
                    }
                }
            }
        }

        if(!changedStreetAddress.isEmpty()){
            // Call SBR_3_0_BatchLocationLatLongProcessor Batch Class
            SBR_3_0_BatchLocationLatLongProcessor latLongBtch = new SBR_3_0_BatchLocationLatLongProcessor(changedStreetAddress, Trigger.new);
            Database.executeBatch(latLongBtch, 1);
        }
    }
    public static void setCompanyCodeOnJobLocation(List<Schema.Location> newLocations) {
        Id userId = UserInfo.getUserId();
        User u = SBR_3_0_UserDA.getUserById(userId);
        Id jobLocationRT = SBR_3_0_Constants.LOCATION_JOB_RT_ID;
        for (Schema.Location location : newLocations) {
            if (String.isBlank(location.Company_Code__c) && location.RecordTypeId == jobLocationRT) {
               location.Company_Code__c = u.CompanyName;
            }
        }
    }
}