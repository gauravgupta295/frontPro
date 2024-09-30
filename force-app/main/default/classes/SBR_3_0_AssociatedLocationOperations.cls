/*********************************************************************************************************************
* Apex Class: SBR_3_0_AssociatedLocationOperations
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - SAL-1503
* - Add Source Of Update field on Associated Location and populate if to SF if a non integration user updates it.
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME                      DATE                 DETAIL FEATURES
    1.0         Harry Rokad                        2022-04-11            Initial version
    2.0         Konrad Haight                      2022-05-25            Added updateAddress
    3.0         Konrad Haight                      2022-08-10            Added mapReadinessFields, verifyNewJobSiteAddress
*********************************************************************************************************************/

public with sharing class SBR_3_0_AssociatedLocationOperations {
    public static void publishAssociatedLocations(Map<Id, AssociatedLocation> associatedLocationMap) {
        Set<Id> locationIds = new Set<Id>();
        Set<Id> accountIds = new Set<Id>();
        Map<Id, Schema.Location> locationMap = new  Map<Id, Schema.Location>();
        Map<Id, Account> accountMap = new Map<Id, Account>();

        for (AssociatedLocation al : associatedLocationMap.values()) {
            locationIds.add(al.Branch__c);
            locationIds.add(al.LocationId);
            accountIds.add(al.ParentRecordId);
        }
        locationMap = SBR_3_0_LocationDA.getLocations(locationIds);
        accountMap = SBR_3_0_AccountDA.getAccounts(accountIds);

        //publishRelatedLocations(locationMap);
        //publishRelatedAccounts(accountMap);
        publishMainLocations(associatedLocationMap);
    }

    public static void publishRelatedLocations(Map<Id, Schema.Location> locationMap) {
        Set<String> validRecTypes = new Set<String>{SBR_3_0_Constants.LOCATION_REC_TYPE_BRANCH};
        SBR_3_0_PublishRecordsToOutbox publishLocations = new SBR_3_0_PublishRecordsToOutbox(locationMap, SBR_3_0_Constants.LOCATION_API_NAME , validRecTypes);
        publishLocations.publish();
    }

    public static void publishRelatedAccounts(Map<Id, Account> accountMap) {
        Set<String> validRecTypes = new Set<String>{SBR_3_0_Constants.ACCOUNT_REC_TYPE_PROSPECT, SBR_3_0_Constants.ACCOUNT_REC_TYPE_CREDIT, SBR_3_0_Constants.ACCOUNT_REC_TYPE_NON_CREDIT};
        SBR_3_0_PublishRecordsToOutbox publishAccounts = new SBR_3_0_PublishRecordsToOutbox(accountMap, SBR_3_0_Constants.ACCOUNT_API_NAME , validRecTypes);
        publishAccounts.publish();
    }

    public static void publishMainLocations(Map<Id, AssociatedLocation> associatedLocationMap) {
        Set<String> validRecTypes = new Set<String>();
        SBR_3_0_PublishRecordsToOutbox publishLocations = new SBR_3_0_PublishRecordsToOutbox(associatedLocationMap, SBR_3_0_Constants.ASSOCIATED_LOCATION_API_NAME , validRecTypes);
        publishLocations.publish();
    }

    public static void updateSourceOfUpdate(List<AssociatedLocation> assocLocList){
        //If External user permission is NOT assigned then write source of update to SF
        Boolean hasPermission = FeatureManagement.checkPermission(SBR_3_0_Constants.ACCOUNT_EXTERNAL_USER);
        if (assocLocList!=null){
            for (AssociatedLocation asl : assocLocList){
                System.debug(asl);
                if (hasPermission==False){
                    asl.Source_Of_Update__c = SBR_3_0_Constants.INTERNAL_SBR_USER;
                }
            }
        }
    }
   

     public static void generateJobName(List<AssociatedLocation> associatedLocations) {
        if(associatedLocations != null && !associatedLocations.isEmpty()) {
            for(AssociatedLocation associatedLocation : associatedLocations) {

                if(String.IsBlank(associatedLocation.Name__c)){
                    String jobName  = associatedLocation.Parent_Account_Name__c;
                    if(jobName.length() > 30){
                        jobName = jobName.substring(0, 30);
                    }
                    associatedLocation.Name__c = jobName;
                }
            }
        }
    }
    public static void setRecordCurrency(List<AssociatedLocation> associatedLocations) {
        if(associatedLocations != null && !associatedLocations.isEmpty()) {
            for(AssociatedLocation associatedLocation : associatedLocations) {
                if(String.IsNotBlank(associatedLocation.Company_Code__c))
                {
                    if((associatedLocation.Company_Code__c=='01' && associatedLocation.CurrencyIsoCode!='USD') || (associatedLocation.Company_Code__c=='02' && associatedLocation.CurrencyIsoCode!='CAD'))
                    {
                        associatedLocation.CurrencyIsoCode =associatedLocation.Company_Code__c=='01'?'USD':'CAD' ;
                    }
                }
            }
            }
         }
         
    // public static void checkJobNumber(Map<Id, AssociatedLocation> associatedLocationOldMap, Map<Id, AssociatedLocation> associatedLocationNewMap) {
    //     Map<Id, AssociatedLocation> updateAssociatedLocations = new Map<Id, AssociatedLocation>();
    //     for(Id id : associatedLocationNewMap.keySet()){   
    //         if (associatedLocationNewMap.get(id).Job_Number__c != associatedLocationOldMap.get(id).Job_Number__c) {
    //             associatedLocationNewMap.get(id).Name__c = associatedLocationNewMap.get(id).Parent_Account_Name__c + '-' + associatedLocationNewMap.get(id).Job_Number__c;
    //         }
    //     }
    // }

    /*public static void updateAddress(List<AssociatedLocation> assocLocList){
        List<AssociatedLocation> listToUpdate = new List<AssociatedLocation>();
        Set<Id> locationIds = new Set<Id>();
        Map<Id,Schema.Location> locationMap;
        if (assocLocList!=null){
            for (AssociatedLocation asl : assocLocList){
                if (asl.Override_System_Address_Updates__c == false) {
                    listToUpdate.add(asl);
                    locationIds.add(asl.LocationId);
                }
            }
        }

        locationMap = SBR_3_0_BranchDA.getLocationsByIds(locationIds);

        for (AssociatedLocation asl : listToUpdate) {
            Schema.Location jobLocation = locationMap.get(asl.LocationId);
            if (String.isNotBlank(jobLocation.Street_Address__c) && String.isNotBlank(jobLocation.City__c) && String.isNotBlank(jobLocation.State__c) && String.isNotBlank(jobLocation.Zip_Code__c)) {
            //coming in future story - add check here if job site already has an address, which indicates user added one on creation and it doesn't need the job location address 
                asl.Street_Address__c = jobLocation.Street_Address__c;
                asl.City__c = jobLocation.City__c;
                asl.State__c = jobLocation.State__c;
                asl.Zip_Code__c = jobLocation.Zip_Code__c;
                asl.Country__c = jobLocation.Country__c;
                if (jobLocation.Latitude_Longitude__Latitude__s != null && jobLocation.Latitude_Longitude__Longitude__s != null) {
                    asl.Latitude_Longitude__Latitude__s = jobLocation.Latitude_Longitude__Latitude__s;
                    asl.Latitude_Longitude__Longitude__s = jobLocation.Latitude_Longitude__Longitude__s;
                } 
            }
        }
    }*/
    public static void populateJobSiteId(List<AssociatedLocation> jobSites) {
        if (jobSites!= null && !jobSites.isEmpty()) {
            for (AssociatedLocation a : jobSites) {
                if(String.isBlank(a.job_site_id__c)) {
                    String result = '';
                    String n = String.valueof(Math.abs(Crypto.getRandomInteger()));
                    Integer i = n.length();
                    system.debug('n: ' + n);
                    if (i > 9) {
                        result = n.right(9);
                        system.debug('n more than 9: ' + result);
                    }
                    else if (i < 9) {
                        result = n;
                        for (Integer l = 0; l < (9-i); l++) {
                            result = '0' + result;
                        }
                        system.debug('n less than 9: ' + result);
                    }
                    else {
                        result = n;
                        system.debug('n is 9: ' + result);
                    }
                    a.Job_Site_Id__c = 'SF-' + result;
                }
            }
        }
    }

    public static void mapReadinessFields(List<AssociatedLocation> assocLocList) {
        if (assocLocList != null && !assocLocList.isEmpty()) {
            Set<Id> locationIds = new Set<Id>();
            Set<Id> accountIds = new Set<Id>();
            Map<Id,Schema.Location> locationMap;
            Map<Id,Account> accountMap;
            if (assocLocList!=null){
                for (AssociatedLocation asl : assocLocList){
                    accountIds.add(asl.ParentRecordId);
                    locationIds.add(asl.LocationId);
                }
            }

            locationMap = SBR_3_0_BranchDA.getLocationReadinessFields(locationIds);
            accountMap = SBR_3_0_AccountDA.getAccountReadinessFields(accountIds);

            if (assocLocList!=null){
                for (AssociatedLocation asl : assocLocList){
                    Schema.Location sharedLocation = locationMap.get(asl.LocationId);
                    Account parentAccount = accountMap.get(asl.ParentRecordId);
                    if (parentAccount != null && sharedLocation != null){
                        asl.Event_Ready_Required__c = (parentAccount.Event_Ready_Required__c || sharedLocation.Event_Ready_Required__c) ? true : false;
                        asl.Plant_Ready_Required__c = (parentAccount.Plant_Ready_Required__c || sharedLocation.Plant_Ready_Required__c) ? true : false;
                        asl.Airport_Personnel_Badge_Required__c = (parentAccount.Airport_Personnel_Badge_Required__c || sharedLocation.Airport_Personnel_Badge_Required__c) ? true : false;
                        asl.Airport_Vehicle_Badge_Required__c = (parentAccount.Airport_Vehicle_Badge_Required__c || sharedLocation.Airport_Vehicle_Badge_Required__c) ? true : false;
                        asl.All_gauges_and_controls_must_work_proper__c = (parentAccount.All_gauges_and_controls_must_work_proper__c || sharedLocation.All_gauges_and_controls_must_work_proper__c) ? true : false;
                        asl.All_lights_and_alarms_must_work_properly__c = (parentAccount.All_lights_and_alarms_must_work_properly__c || sharedLocation.All_lights_and_alarms_must_work_properly__c) ? true : false;
                        asl.Annual_Inspection_must_be_up_to_date__c = (parentAccount.Annual_Inspection_must_be_up_to_date__c || sharedLocation.Annual_Inspection_must_be_up_to_date__c) ? true : false;
                        asl.Anti_Entrapment__c = (parentAccount.Anti_Entrapment__c || sharedLocation.Anti_Entrapment__c) ? true : false;
                        asl.Beacon_Light_Required__c = (parentAccount.Beacon_Light_Required__c || sharedLocation.Beacon_Light_Required__c) ? true : false;
                        asl.Carb_Registration_Required__c = (parentAccount.Carb_Registration_Required__c || sharedLocation.Carb_Registration_Required__c) ? true : false;
                        asl.Containment_Berms__c = (parentAccount.Containment_Berms__c || sharedLocation.Containment_Berms__c) ? true : false;
                        asl.Copy_of_Owner_Manual_and_AEM_Required__c = (parentAccount.Copy_of_Owner_Manual_and_AEM_Required__c || sharedLocation.Copy_of_Owner_Manual_and_AEM_Required__c) ? true : false;
                        asl.COVID_Negative_Result_Required__c = (parentAccount.COVID_Negative_Result_Required__c || sharedLocation.COVID_Negative_Result_Required__c) ? true : false;
                        asl.COVID_Vaccination_Required__c = (parentAccount.COVID_Vaccination_Required__c || sharedLocation.COVID_Vaccination_Required__c) ? true : false;
                        asl.Dashboards_must_be_wiped_clean__c = (parentAccount.Dashboards_must_be_wiped_clean__c || sharedLocation.Dashboards_must_be_wiped_clean__c) ? true : false;
                        asl.Decals_Stencils_Must_Be_Legible__c = (parentAccount.Decals_Stencils_Must_Be_Legible__c || sharedLocation.Decals_Stencils_Must_Be_Legible__c) ? true : false;
                        asl.Equipment_must_be_extremely_clean__c = (parentAccount.Equipment_must_be_extremely_clean__c || sharedLocation.Equipment_must_be_extremely_clean__c) ? true : false;
                        asl.Facial_Hair_Restrictions__c = (parentAccount.Facial_Hair_Restrictions__c || sharedLocation.Facial_Hair_Restrictions__c) ? true : false;
                        asl.Fire_Extinguisher_Required__c = (parentAccount.Fire_Extinguisher_Required__c || sharedLocation.Fire_Extinguisher_Required__c) ? true : false;
                        asl.Generators_must_be_hand_wiped__c = (parentAccount.Generators_must_be_hand_wiped__c || sharedLocation.Generators_must_be_hand_wiped__c) ? true : false;
                        asl.Glass_must_be_intact_and_wiped_clean__c = (parentAccount.Glass_must_be_intact_and_wiped_clean__c || sharedLocation.Glass_must_be_intact_and_wiped_clean__c) ? true : false;
                        asl.Hard_Hats_Required__c = (parentAccount.Hard_Hats_Required__c || sharedLocation.Hard_Hats_Required__c) ? true : false;
                        asl.Headlights_Required__c = (parentAccount.Headlights_Required__c || sharedLocation.Headlights_Required__c) ? true : false;
                        asl.Motion_Beacons__c = (parentAccount.Motion_Beacons__c || sharedLocation.Motion_Beacons__c) ? true : false;
                        asl.No_Photography__c = (parentAccount.No_Photography__c || sharedLocation.No_Photography__c) ? true : false;
                        asl.No_visible_damage_to_the_machine__c = (parentAccount.No_visible_damage_to_the_machine__c || sharedLocation.No_visible_damage_to_the_machine__c) ? true : false;
                        asl.No_visible_signs_of_leaks__c = (parentAccount.No_visible_signs_of_leaks__c || sharedLocation.No_visible_signs_of_leaks__c) ? true : false;
                        asl.Non_Marking_Tires__c = (parentAccount.Non_Marking_Tires__c || sharedLocation.Non_Marking_Tires__c) ? true : false;
                        asl.OSHA_10_Required__c = (parentAccount.OSHA_10_Required__c || sharedLocation.OSHA_10_Required__c) ? true : false;
                        asl.OSHA_30_Required__c = (parentAccount.OSHA_30_Required__c || sharedLocation.OSHA_30_Required__c) ? true : false;
                        asl.Paint_must_be_close_to_perfect__c = (parentAccount.Paint_must_be_close_to_perfect__c || sharedLocation.Paint_must_be_close_to_perfect__c) ? true : false;
                        asl.Prevailing_Wage__c = (parentAccount.Prevailing_Wage__c || sharedLocation.Prevailing_Wage__c) ? true : false;
                        asl.Proximity_Alarms__c = (parentAccount.Proximity_Alarms__c || sharedLocation.Proximity_Alarms__c) ? true : false;
                        asl.Safety_Cones__c = (parentAccount.Safety_Cones__c || sharedLocation.Safety_Cones__c) ? true : false;
                        asl.Safety_Flags__c = (parentAccount.Safety_Flags__c || sharedLocation.Safety_Flags__c) ? true : false;
                        asl.Safety_Glasses_Required__c = (parentAccount.Safety_Glasses_Required__c || sharedLocation.Safety_Glasses_Required__c) ? true : false;
                        asl.Site_Specific_Crane_Inspection_Required__c = (parentAccount.Site_Specific_Crane_Inspection_Required__c || sharedLocation.Site_Specific_Crane_Inspection_Required__c) ? true : false;
                        asl.Site_Specific_Training_Required__c = (parentAccount.Site_Specific_Training_Required__c || sharedLocation.Site_Specific_Training_Required__c) ? true : false;
                        asl.Special_Back_up_Alarm_Required__c = (parentAccount.Special_Back_up_Alarm_Required__c || sharedLocation.Special_Back_up_Alarm_Required__c) ? true : false;
                        asl.Special_Decals_Required__c = (parentAccount.Special_Decals_Required__c || sharedLocation.Special_Decals_Required__c) ? true : false;
                        asl.Special_Tire_Tread_Requirements__c = (parentAccount.Special_Tire_Tread_Requirements__c || sharedLocation.Special_Tire_Tread_Requirements__c) ? true : false;
                        asl.Spill_Kits__c = (parentAccount.Spill_Kits__c || sharedLocation.Spill_Kits__c) ? true : false;
                        asl.State_of_MA_Code_Compliance_for_Heaters__c = (parentAccount.State_of_MA_Code_Compliance_for_Heaters__c || sharedLocation.State_of_MA_Code_Compliance_for_Heaters__c) ? true : false;
                        asl.Tier_4_Engine_Required__c = (parentAccount.Tier_4_Engine_Required__c || sharedLocation.Tier_4_Engine_Required__c) ? true : false;
                        asl.Tire_Covers__c = (parentAccount.Tire_Covers__c || sharedLocation.Tire_Covers__c) ? true : false;
                        asl.Tire_Shine_Required__c = (parentAccount.Tire_Shine_Required__c || sharedLocation.Tire_Shine_Required__c) ? true : false;
                        asl.Tires_must_be_in_good_condition__c = (parentAccount.Tires_must_be_in_good_condition__c || sharedLocation.Tires_must_be_in_good_condition__c) ? true : false;
                        asl.TWIC_Card_Required__c = (parentAccount.TWIC_Card_Required__c || sharedLocation.TWIC_Card_Required__c) ? true : false;
                        asl.Union_Personnel_Required__c = (parentAccount.Union_Personnel_Required__c || sharedLocation.Union_Personnel_Required__c) ? true : false;
                        asl.Water_Barriers_Required__c = (parentAccount.Water_Barriers_Required__c || sharedLocation.Water_Barriers_Required__c) ? true : false;
                        asl.Wheel_Chalks__c = (parentAccount.Wheel_Chalks__c || sharedLocation.Wheel_Chalks__c) ? true : false;
                        asl.Drip_Diapers__c = (parentAccount.Drip_Diapers__c || sharedLocation.Drip_Diapers__c) ? true : false;
                        asl.Personnel_Must_Be_US_Citizen__c = (parentAccount.Personnel_Must_Be_US_Citizen__c || sharedLocation.Personnel_Must_Be_US_Citizen__c) ? true : false;
                        asl.Ground_Delivery__c = sharedLocation.Ground_Delivery__c;
                        asl.Drive_in_Ramp_Available__c = sharedLocation.Drive_in_Ramp_Available__c;
                        asl.Are_there_designated_routes_to_location__c = sharedLocation.Are_there_designated_routes_to_location__c;
                        asl.Escort_Required__c = sharedLocation.Escort_Required__c;
                        asl.Loading_Dock__c = sharedLocation.Loading_Dock__c;
                        asl.Personnel_Ramp_Available__c = sharedLocation.Personnel_Ramp_Available__c;
                        asl.Delivery_timeslot_reservation_required__c = sharedLocation.Delivery_timeslot_reservation_required__c;
                    }
                }
            }
        }
    }

    public static void validateNewJobSiteAddress(Map<Id, AssociatedLocation> newJobSites) {
        List<AssociatedLocation> jobSitesToVerify = new List<AssociatedLocation>();
        for (Id ide : newJobSites.keySet()) {
            AssociatedLocation newJobSite = newJobSites.get(ide);
            if (newJobSite.City__c != null || newJobSite.State__c != null || newJobSite.Country__c != null || newJobSite.Street_Address__c != null || newJobSite.Zip_Code__c != null) {
                jobSitesToVerify.add(newJobSite);
            }
        }
        Boolean isInsert = true;
        if (jobSitesToVerify.size() > 0) {
            System.enqueueJob(new SBR_3_0_Queueable_VerifyJobSiteAddress(jobSitesToVerify, isInsert));
        }
    }

    public static void validateUpdateJobSiteAddress(Map<Id, AssociatedLocation> newJobSites, Map<Id, AssociatedLocation> oldJobSites) {
        List<AssociatedLocation> jobSitesToVerify = new List<AssociatedLocation>();
            for (Id ide : newJobSites.keySet()) {
                AssociatedLocation newJobSite = newJobSites.get(ide);
                AssociatedLocation oldJobSite = oldJobSites.get(ide);
                if (newJobSite.City__c != oldJobSite.City__c || newJobSite.State__c != oldJobSite.State__c || newJobSite.Country__c != oldJobSite.Country__c || newJobSite.Street_Address__c != oldJobSite.Street_Address__c || newJobSite.Zip_Code__c != oldJobSite.Zip_Code__c) {
                    jobSitesToVerify.add(newJobSite);
                }     
            }
        Boolean isInsert = false;
        if (jobSitesToVerify.size() > 0) {
            System.enqueueJob(new SBR_3_0_Queueable_VerifyJobSiteAddress(jobSitesToVerify, isInsert));
        }
    }
    
    public static void updateCompanyCode (List<AssociatedLocation> newJobSites) {
        if(newJobSites != null && !newJobSites.isEmpty()) {
            Set<Id> accountIds = new Set<Id>();
            for (AssociatedLocation al : newJobSites) {
                if (al.Company_Code__c == null) {
                    accountIds.add(al.ParentRecordId);
                }
            }
            
            Map<Id, Account> accountMap = SBR_3_0_AccountDA.getAccounts(accountIds);

            for (AssociatedLocation al : newJobSites) {
                if(accountMap.containsKey(al.ParentRecordId)) {
                    al.Company_Code__c = accountMap.get(al.ParentRecordId).Company_Code__c;
                }
            }
        }
    }
    public static void truncateJobNumber (AssociatedLocation al) {
        System.debug('\n @@ associatedLocation.Job_Number__c ' + associatedLocation.Job_Number__c );
        if(!String.IsBlank(al.Job_Number__c)){
            String jobNum  =  al.Job_Number__c;
            if(jobNum.length() > 20){
                al.Job_Number__c = jobNum.substring(0, 20);
            }
        }
    }
    
    // Method to associate Sales Rep Name(SalesRepUserId__c) from Sales Rep Id(Sales_Rep_Id__c) for Integration user
    public static void linkSalesRepIds(Map<Id, AssociatedLocation> oldMap, Map<Id, AssociatedLocation> newMap) {
        List<AssociatedLocation> toUpdate = new List<AssociatedLocation>();
        Boolean hasPermission = FeatureManagement.checkPermission(SBR_3_0_Constants.ACCOUNT_EXTERNAL_USER);
        if(oldMap != null && hasPermission) {
            for(AssociatedLocation a : newMap.values()) {
                if(a.Sales_Rep_Id__c != oldMap.get(a.Id).Sales_Rep_Id__c) {
                    toUpdate.add(a);
                }
            }
            System.debug('\n @@ toupdate = ' + toUpdate);
            if(toUpdate.size() > 0) {
                linkSalesRepIds(toUpdate);
            }
        } else{
            //23563
            Set<String> userIds = new Set<String>();    
            for(AssociatedLocation a : newMap.values()) {
                if(a.SalesRepUserId__c != null) {
                    userIds.add(a.SalesRepUserId__c);
                }
            }
            Map<String, String> usersRepIdMap = SBR_3_0_UserDA.getUserRepIdMapByIds(userIds);
            
            for(AssociatedLocation a : newMap.values()) {
                if(usersRepIdMap.containsKey(a.SalesRepUserId__c)) {
                    a.Sales_Rep_Id__c = usersRepIdMap.get(a.SalesRepUserId__c);
                }
                else {
                    a.Sales_Rep_Id__c = null;
                }
            }
        }
    }
    public static void linkSalesRepIds(List<AssociatedLocation> associatedLocations) {
        Set<String> SalesRepIdSet = new Set<String>();   
        Boolean hasPermission = FeatureManagement.checkPermission(SBR_3_0_Constants.ACCOUNT_EXTERNAL_USER);     
        if(associatedLocations != null && !associatedLocations.isEmpty() && hasPermission) {
            for(AssociatedLocation a : associatedLocations) {
                if(String.IsNotBlank(a.Sales_Rep_Id__c)) {
                    SalesRepIdSet.add(a.Sales_Rep_Id__c);
                }
            }            
            Map<String,String> userMap = new Map<String,Id> ();
            if(!SalesRepIdSet.isEmpty()) {
                for(User u : SBR_3_0_UserDA.getUsersBySalesRepIds(SalesRepIdSet)) {
                    userMap.put(u.RepId__c, u.Id);
                }
            }
            //System.debug('\n @@ userMap = '+ userMap); 
            for(AssociatedLocation a : associatedLocations) {
                //System.debug('\n @@AssociatedLocation rep = ' + a.Sales_Rep_Id__c);
                if(userMap.containsKey(a.Sales_Rep_Id__c)) {
                    a.SalesRepUserId__c = userMap.get(a.Sales_Rep_Id__c);
                }
                else {
                    a.SalesRepUserId__c = null;
                }
            }
        }
    }
    
    /**
    * @description  :  To truncate lat long values to 10 digits
    * @author Venkata
    * @param List<AssociatedLocation>
    * @param Map<Id, AssociatedLocation>
    **/
    public static void truncateLatLong (List<AssociatedLocation> newJobSites, Map<Id, AssociatedLocation> oldMap) {//SF-7831
        if(newJobSites != null && !newJobSites.isEmpty()){
            for(AssociatedLocation asl : newJobSites){
                if(oldMap == null || (oldMap !=null && (asl.Latitude_Longitude__Latitude__s != oldMap.get(asl.Id).Latitude_Longitude__Latitude__s || asl.Latitude_Longitude__Longitude__s != oldMap.get(asl.Id).Latitude_Longitude__Longitude__s))){
                    String latStr = asl.Latitude_Longitude__Latitude__s != null ? string.valueOf(asl.Latitude_Longitude__Latitude__s) : null;
                    String longStr = asl.Latitude_Longitude__Longitude__s != null ? string.valueOf(asl.Latitude_Longitude__Longitude__s) : null;
                    if(latStr != null && latStr.length() > 10){
                        asl.Latitude_Longitude__Latitude__s   = Double.valueOf(latStr.substring(0, 10));
                    }
                    if(longStr != null && longStr.length() > 10){
                        asl.Latitude_Longitude__Longitude__s   = Double.valueOf(longStr.substring(0, 10));
                    }
                }
            }
        }
    }
}