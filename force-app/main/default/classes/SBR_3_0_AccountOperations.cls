/*********************************************************************************************************************
* Apex Class: SBR_3_0_AccountOperations
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Class to manage handler logic for Accounts
* - SAL-473,1502
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME                        DATE                DETAIL FEATURES
    1.0         Harry Patel,Viren Patel           2022-03-15               Initial version
    1.1         Nate Kanyok                       2022-08-17               Comment out  populateSFAccountNumber    
    1.2         Lakshya Khandelwal                2023-06-27               FRONT-3524 : Added validateRMCashState and edited updateDriverslicense methods
*********************************************************************************************************************/



public with sharing class SBR_3_0_AccountOperations {

    public static Set<String> validRecTypes;
    private static final String PERMISSION = 'Block_User_from_Updating_Readiness_Fields_On_Account';
    private static final String JOB_SITE_FIELDS_ERROR = 'User is not permitted to update Job Site Requirements Fields on this Account';
    
    public static void publishProspectAccount(Map<Id, Account> oldAccountMap, Map<Id, Account> newAccountMap){
        Map<Id, Account> accToPublish = new Map<Id, Account>();
        validRecTypes = new Set<String>{SBR_3_0_Constants.ACCOUNT_REC_TYPE_PROSPECT};

        for (Id ide : newAccountMap.keySet()){    
            //if Acct RT is Prospect and Sales Activity Status changes to Pending Non-Credit Conversion, then publish to outbox
            if (
                newAccountMap.get(ide).RecordTypeId==SBR_3_0_Constants.ACCOUNT_PROSPECT_RT_ID
                &&
                oldAccountMap.get(ide).Sales_Activity_Status__c != SBR_3_0_Constants.ACCOUNT_SALES_ACTIVITY_STATUS_PENDING_NON_CREDIT
                && 
                newAccountMap.get(ide).Sales_Activity_Status__c == SBR_3_0_Constants.ACCOUNT_SALES_ACTIVITY_STATUS_PENDING_NON_CREDIT  
            ){
                accToPublish.put(ide, newAccountMap.get(ide));
            }
        }
        if (accToPublish.size()>0){
            SBR_3_0_PublishRecordsToOutbox publishAccounts= new SBR_3_0_PublishRecordsToOutbox(accToPublish, SBR_3_0_Constants.ACCOUNT_API_NAME, validRecTypes);
            publishAccounts.publish();
        }
    }
     
        //publishCreditorCorpLinkedAccounts SAL-26003
      public static void publishCreditOrCorp(Map<Id, Account> oldAccountMap, Map<Id, Account> newAccountMap){
        Map<Id, Account> accToPublish = new Map<Id, Account>();
        Map<Id,AssociatedLocation> jobSiteToPublish=new Map<Id,AssociatedLocation>();
        
        for (Id ide : newAccountMap.keySet()){    
            if ((newAccountMap.get(ide).RecordTypeId==SBR_3_0_Constants.ACCOUNT_CORP_LINK_RT_ID ||  newAccountMap.get(ide).RecordTypeId==SBR_3_0_Constants.ACCOUNT_CREDIT_RT_ID)
                &&
                (oldAccountMap.get(ide).RecordTypeId != SBR_3_0_Constants.ACCOUNT_CORP_LINK_RT_ID && oldAccountMap.get(ide).RecordTypeId != SBR_3_0_Constants.ACCOUNT_CREDIT_RT_ID)  
            ){
                accToPublish.put(ide, newAccountMap.get(ide));
            }
        }
        System.debug('\n accToPublish size =  ' + accToPublish.size());
        if(!accToPublish.isEmpty()) {
            for(AssociatedLocation asl:[Select id from AssociatedLocation where ParentRecordId IN :accToPublish.KeySet()]) {
                jobSiteToPublish.put(asl.id,asl);
            }

            if (jobSiteToPublish.size()>0){
            SBR_3_0_PublishRecordsToOutbox publishJobSites= new SBR_3_0_PublishRecordsToOutbox(jobSiteToPublish, SBR_3_0_Constants.ASSOCIATED_LOCATION_API_NAME);
                publishJobSites.publish();
            }
        }
    }

    public static void updateAccToNonCredit(Map<Id, Account> oldAccountMap,Map<Id, Account> newAccountMap){
        for (Id ide : newAccountMap.keySet()){
            if ( 
                isCreditApplicationApproved(oldAccountMap.get(ide), newAccountMap.get(ide)) == false 
                && 
                isRMAccountCreated(oldAccountMap.get(ide), newAccountMap.get(ide)) == true
            ) {
                newAccountMap.get(ide).recordtypeid = SBR_3_0_Constants.ACCOUNT_NON_CREDIT_RT_ID;
                newAccountMap.get(ide).Sales_Activity_Status__c= 'None';
            }
        }
    }

    private static Boolean isCreditApplicationApproved(Account oldRecord, Account newRecord){
        // Integration call sends below 2 updates (not necessarily in that order) after a Credit Application is approved in RM
        // 1 - Update credit application status to 'Non Ordering Acct.' (i.e. Sales_Activity_Status)
        // 2 - Upsert based on SF Acct# with new RM Account# and Recordtype = Credit
        if (
            oldRecord.RecordTypeId == SBR_3_0_Constants.ACCOUNT_PROSPECT_RT_ID
            && newRecord.RecordTypeId == SBR_3_0_Constants.ACCOUNT_CREDIT_RT_ID
            && String.isBlank(oldRecord.RM_Account_Number__c)
            && !(String.isBlank(newRecord.RM_Account_Number__c)) 
        ) {
                return true;
        }
        return false;
    }

    private static Boolean isRMAccountCreated(Account oldRecord, Account newRecord) {
        //this applies to Cash (Non-Credit customer) when a Prospect in SF becomes a Cash Customer in RM and a RM# is generated
        //when RM Account Number is added, update Sales Activity Status and change record type to Non-Credit
        //After update trigger will publish this record
        if (
            String.isBlank(oldRecord.RM_Account_Number__c)
            && !(String.isBlank(newRecord.RM_Account_Number__c)) 
        ) {
            return true;
        }
        return false;
    }

    public static void publishCreditAndNonCreditAccounts(Map<Id, Account> newAccountMap) {
        //publish for any change for Credit and Non-Credit RTs
        validRecTypes = new Set<String>{SBR_3_0_Constants.ACCOUNT_REC_TYPE_CREDIT, SBR_3_0_Constants.ACCOUNT_REC_TYPE_NON_CREDIT};
        SBR_3_0_PublishRecordsToOutbox publishAccounts= new SBR_3_0_PublishRecordsToOutbox(newAccountMap, SBR_3_0_Constants.ACCOUNT_API_NAME , validRecTypes);
        publishAccounts.publish();
    }

    public static void updateSourceOfUpdate(List<Account> accountList){
        //If External user permission is NOT assigned then write source of update to SF
        Boolean hasPermission = FeatureManagement.checkPermission(SBR_3_0_Constants.ACCOUNT_EXTERNAL_USER);
        if (accountList!=null){
            for (Account acc : accountList){
                System.debug(acc);
                if (hasPermission==False){
                    acc.Source_Of_Update__c = SBR_3_0_Constants.INTERNAL_SBR_USER;
                }
            }
        }
    }

    public static List<Account> fetchterriFuture(List<Account> oldAccountList, List<Account> newAccountList){
        List<Account> finalList = new List<Account>();
        if(oldAccountList!=null && newAccountList!=null){
            for(Integer i=0; i<oldAccountList.size();i++){
                System.debug('hi2');
                if (oldAccountList[i].RecordTypeId==SBR_3_0_Constants.ACCOUNT_PROSPECT_RT_ID){
                    System.debug('hi3');
                    if (oldAccountList[i].Street_Address_LatLong__Latitude__s == null && newAccountList[i].Street_Address_LatLong__Latitude__s != null &&
                        oldAccountList[i].Street_Address_LatLong__Longitude__s == null && newAccountList[i].Street_Address_LatLong__Longitude__s !=null){
                            finalList.add(newAccountList[i]);
                    }
                }
                if (oldAccountList[i].RecordTypeId==SBR_3_0_Constants.ACCOUNT_OFFICE_RT_ID){
                    if (oldAccountList[i].Street_Address_LatLong__Latitude__s == null && newAccountList[i].Street_Address_LatLong__Latitude__s != null &&
                        oldAccountList[i].Street_Address_LatLong__Longitude__s == null && newAccountList[i].Street_Address_LatLong__Longitude__s !=null){
                            finalList.add(newAccountList[i]);
                    }
                }
            }
            // do not increase this size to more than 10, since there are external API calls being fired from this batch
            //Database.executeBatch(new SBR_3_0_BatchAcctTerritoryProcessor(finalList), 10); 
        }
        return finalList; 
    }
                       

    public static void fetchAddressLatLong(Map<Id, Account> oldAccountMap, Map<Id, Account> newAccountMap){
        Set<Id> changedStreetAddress = new Set<Id>();
        Set<Id> changedBillingAddress = new Set<Id>();
        Set<Id> changedOverrideAddress = new Set<Id>();
		/* List<Account> lAccounts = fetchterriFuture(oldAccountMap.values(),newAccountMap.values());
        system.debug('lAccounts'+lAccounts); */
        for(Account act: newAccountMap.values()){
            if(oldAccountMap == NULL || oldAccountMap.isEmpty()){
                // Insert Operation
                // Street Address Populated
                if((act.ShippingStreet <> NULL || 
                act.Shipping_Street2__c <> NULL ||
                act.ShippingCity <> NULL ||
                act.ShippingState <> NULL ||
                act.ShippingPostalCode <> NULL ||
                act.ShippingCountry <> NULL) && 
                (act.Street_Address_LatLong__Latitude__s == NULL || 
                act.Street_Address_LatLong__Latitude__s == 0 ||
                act.Street_Address_LatLong__Longitude__s == NULL || 
                act.Street_Address_LatLong__Longitude__s == 0)
                ){
                    if(!changedStreetAddress.contains(act.Id)){
                        changedStreetAddress.add(act.Id);
                    }
                }

                // Override Address Populated
                if((act.Override_Address__Street__s <> NULL || 
                act.Override_Address__City__s <> NULL ||
                act.Override_Address__StateCode__s <> NULL ||
                act.Override_Address__PostalCode__s <> NULL ||
                act.Override_Address__CountryCode__s <> NULL) && 
                (act.Override_Address__Latitude__s == NULL || 
                act.Override_Address__Latitude__s == 0 ||
                act.Override_Address__Longitude__s == NULL || 
                act.Override_Address__Longitude__s == 0)
                ){
                    if(!changedOverrideAddress.contains(act.Id)){
                        changedOverrideAddress.add(act.Id);
                    }
                }

                if((act.BillingStreet <> NULL || 
                act.Billing_Street2__c <> NULL ||
                act.BillingCity <> NULL ||
                act.BillingState <> NULL ||
                act.BillingPostalCode <> NULL ||
                act.BillingCountry <> NULL) && 
                (act.BillingLatitude == NULL || 
                act.BillingLatitude == 0 ||
                act.BillingLongitude == NULL || 
                act.BillingLongitude == 0)
                ){
                    if(!changedBillingAddress.contains(act.Id)){
                        changedBillingAddress.add(act.Id);
                    }
                }

            } else {
                // Update Operation
                Account oldAct = oldAccountMap.get(act.Id);
                // Changed Street Address
                if(act.ShippingStreet <> oldAct.ShippingStreet || 
                act.Shipping_Street2__c <> oldAct.Shipping_Street2__c ||
                act.ShippingCity <> oldAct.ShippingCity ||
                act.ShippingState <> oldAct.ShippingState ||
                act.ShippingPostalCode <> oldAct.ShippingPostalCode ||
                act.ShippingCountry <> oldAct.ShippingCountry){
                    if(!changedStreetAddress.contains(act.Id)){
                        changedStreetAddress.add(act.Id);
                    }
                }

                // Changed Override Address
                if(act.Override_Address__Street__s <> oldAct.Override_Address__Street__s || 
                act.Override_Address__City__s <> oldAct.Override_Address__City__s ||
                act.Override_Address__StateCode__s <> oldAct.Override_Address__StateCode__s ||
                act.Override_Address__PostalCode__s <> oldAct.Override_Address__PostalCode__s ||
                act.Override_Address__CountryCode__s <> oldAct.Override_Address__CountryCode__s){
                    if(!changedOverrideAddress.contains(act.Id)){
                        changedOverrideAddress.add(act.Id);
                    }
                }

                // Changed Billing Address   // SAL-26502
                if(act.BillingStreet <> oldAct.BillingStreet || 
                act.Billing_Street2__c <> oldAct.Billing_Street2__c ||
                act.BillingCity <> oldAct.BillingCity ||
                act.BillingState <> oldAct.BillingState ||
                act.BillingState <> oldAct.BillingState ||
                act.BillingPostalCode <> oldAct.BillingPostalCode ||
                act.BillingCountry <> oldAct.BillingCountry){
                    if(!changedBillingAddress.contains(act.Id)){
                        changedBillingAddress.add(act.Id);
                    }
                }

            }
        }
        if(!Test.isRunningTest() && (!changedOverrideAddress.isEmpty() || !changedStreetAddress.isEmpty() || !changedBillingAddress.isEmpty())){
            // Call SBR_3_0_BatchAccountLatLongProcessor Batch Class
            SBR_3_0_BatchAccountLatLongProcessor latLongBtch = new SBR_3_0_BatchAccountLatLongProcessor(changedStreetAddress, changedOverrideAddress, changedBillingAddress, newAccountMap.values());
            Database.executeBatch(latLongBtch, 1);
        }
    }

    public static void preventOSRUpdateOfReadinessFields(Map<Id, Account> oldAccountMap, Map<Id, Account> newAccountMap) {
        
        Boolean userCannotUpdate = FeatureManagement.checkPermission(PERMISSION);
        Boolean userIsRelated = false;
        Set<Id> accountIds = new Set<Id>();
        List<Account_Relationship__c> userAccountRels;
        Account newAccount;
        Account oldAccount;
        
        
        if(userCannotUpdate){
            System.debug('User Cannot Update Account');
            //Get the account relationships connected to the current user and create a set of the Account Ids
            Id userId = UserInfo.getUserId();
            userAccountRels = SBR_3_0_AccountRelationshipDA.getAccountRelsByUserId(userId);
            if (userAccountRels != null) {
                for ( Account_Relationship__c ar: userAccountRels) {
                    accountIds.add(ar.Account_ID__c);
                }
            }
            for (Id ide : newAccountMap.keySet()){
                newAccount = newAccountMap.get(ide);
                oldAccount = oldAccountMap.get(ide);
                //If the Set of Ids is empty the user is not related to any Accounts and therefore not authorized to update this account OR
                //If the Set is not empty, but the current Account Id is not in the set the user is not related to the account and therefore not allowed to update it
                if (!accountIds.contains(ide) || accountIds.isEmpty()) {
                    System.debug('User Is Not Related to Account');
                    //Finally, check if the user was attempting to update any of the fields that are being targeted to prevent updates by the user
                    if (checkForReadinessFieldChange(oldAccount, newAccount)) {
                        newAccount.addError(JOB_SITE_FIELDS_ERROR);
                    }
                }
            }
        }
    }

    
    
    private static Boolean checkForReadinessFieldChange(Account oldAccount, Account newAccount) { //TO DO - add the other fields we're checking for
        if (oldAccount.Plant_Ready_Required__c != newAccount.Plant_Ready_Required__c) { return true; }
        else if (oldAccount.Event_Ready_Required__c != newAccount.Event_Ready_Required__c) { return true; }
        else if (oldAccount.Airport_Personnel_Badge_Required__c != newAccount.Airport_Personnel_Badge_Required__c) { return true; }
        else if (oldAccount.Airport_Vehicle_Badge_Required__c != newAccount.Airport_Vehicle_Badge_Required__c) { return true; }
        else if (oldAccount.All_gauges_and_controls_must_work_proper__c != newAccount.All_gauges_and_controls_must_work_proper__c) { return true; }
        else if (oldAccount.All_lights_and_alarms_must_work_properly__c != newAccount.All_lights_and_alarms_must_work_properly__c) { return true; }
        else if (oldAccount.Annual_Inspection_must_be_up_to_date__c != newAccount.Annual_Inspection_must_be_up_to_date__c) { return true; }
        else if (oldAccount.Anti_Entrapment__c != newAccount.Anti_Entrapment__c) { return true; }
        else if (oldAccount.Beacon_Light_Required__c != newAccount.Beacon_Light_Required__c) { return true; }
        else if (oldAccount.Carb_Registration_Required__c != newAccount.Carb_Registration_Required__c) { return true; }
        else if (oldAccount.Containment_Berms__c != newAccount.Containment_Berms__c) { return true; }
        else if (oldAccount.Copy_of_Owner_Manual_and_AEM_Required__c != newAccount.Copy_of_Owner_Manual_and_AEM_Required__c) { return true; }
        else if (oldAccount.COVID_Negative_Result_Required__c != newAccount.COVID_Negative_Result_Required__c) { return true; }
        else if (oldAccount.COVID_Vaccination_Required__c != newAccount.COVID_Vaccination_Required__c) { return true; }
        else if (oldAccount.Dashboards_must_be_wiped_clean__c != newAccount.Dashboards_must_be_wiped_clean__c) { return true; }
        else if (oldAccount.Decals_Stencils_Must_Be_Legible__c != newAccount.Decals_Stencils_Must_Be_Legible__c) { return true; }
        else if (oldAccount.Equipment_must_be_extremely_clean__c != newAccount.Equipment_must_be_extremely_clean__c) { return true; }
        else if (oldAccount.Facial_Hair_Restrictions__c != newAccount.Facial_Hair_Restrictions__c) { return true; }
        else if (oldAccount.Fire_Extinguisher_Required__c != newAccount.Fire_Extinguisher_Required__c) { return true; }
        else if (oldAccount.Generators_must_be_hand_wiped__c != newAccount.Generators_must_be_hand_wiped__c) { return true; }
        else if (oldAccount.Glass_must_be_intact_and_wiped_clean__c != newAccount.Glass_must_be_intact_and_wiped_clean__c) { return true; }
        else if (oldAccount.Hard_Hats_Required__c != newAccount.Hard_Hats_Required__c) { return true; }
        else if (oldAccount.Headlights_Required__c != newAccount.Headlights_Required__c) { return true; }
        else if (oldAccount.Motion_Beacons__c != newAccount.Motion_Beacons__c) { return true; }
        else if (oldAccount.No_Photography__c != newAccount.No_Photography__c) { return true; }
        else if (oldAccount.No_visible_damage_to_the_machine__c != newAccount.No_visible_damage_to_the_machine__c) { return true; }
        else if (oldAccount.No_visible_signs_of_leaks__c != newAccount.No_visible_signs_of_leaks__c) { return true; }
        else if (oldAccount.Non_Marking_Tires__c != newAccount.Non_Marking_Tires__c) { return true; }
        else if (oldAccount.OSHA_10_Required__c != newAccount.OSHA_10_Required__c) { return true; }
        else if (oldAccount.OSHA_30_Required__c != newAccount.OSHA_30_Required__c) { return true; }
        else if (oldAccount.Paint_must_be_close_to_perfect__c != newAccount.Paint_must_be_close_to_perfect__c) { return true; }
        else if (oldAccount.Prevailing_Wage__c != newAccount.Prevailing_Wage__c) { return true; }
        else if (oldAccount.Proximity_Alarms__c != newAccount.Proximity_Alarms__c) { return true; }
        else if (oldAccount.Safety_Cones__c != newAccount.Safety_Cones__c) { return true; }
        else if (oldAccount.Safety_Flags__c != newAccount.Safety_Flags__c) { return true; }
        else if (oldAccount.Safety_Glasses_Required__c != newAccount.Safety_Glasses_Required__c) { return true; }
        else if (oldAccount.Site_Specific_Crane_Inspection_Required__c != newAccount.Site_Specific_Crane_Inspection_Required__c) { return true; }
        else if (oldAccount.Site_Specific_Training_Required__c != newAccount.Site_Specific_Training_Required__c) { return true; }
        else if (oldAccount.Special_Back_up_Alarm_Required__c != newAccount.Special_Back_up_Alarm_Required__c) { return true; }
        else if (oldAccount.Special_Decals_Required__c != newAccount.Special_Decals_Required__c) { return true; }
        else if (oldAccount.Special_Tire_Tread_Requirements__c != newAccount.Special_Tire_Tread_Requirements__c) { return true; }
        else if (oldAccount.Spill_Kits__c != newAccount.Spill_Kits__c) { return true; }
        else if (oldAccount.State_of_MA_Code_Compliance_for_Heaters__c != newAccount.State_of_MA_Code_Compliance_for_Heaters__c) { return true; }
        else if (oldAccount.Tier_4_Engine_Required__c != newAccount.Tier_4_Engine_Required__c) { return true; }
        else if (oldAccount.Tire_Covers__c != newAccount.Tire_Covers__c) { return true; }
        else if (oldAccount.Tire_Shine_Required__c != newAccount.Tire_Shine_Required__c) { return true; }
        else if (oldAccount.Tires_must_be_in_good_condition__c != newAccount.Tires_must_be_in_good_condition__c) { return true; }
        else if (oldAccount.TWIC_Card_Required__c != newAccount.TWIC_Card_Required__c) { return true; }
        else if (oldAccount.Union_Personnel_Required__c != newAccount.Union_Personnel_Required__c) { return true; }
        else if (oldAccount.Water_Barriers_Required__c != newAccount.Water_Barriers_Required__c) { return true; }
        else if (oldAccount.Wheel_Chalks__c != newAccount.Wheel_Chalks__c) { return true; }
        else if (oldAccount.Personnel_Must_Be_US_Citizen__c != newAccount.Personnel_Must_Be_US_Citizen__c) { return true; }
        else if (oldAccount.Drip_Diapers__c != newAccount.Drip_Diapers__c) { return true; }
        else { return false; }
    }

    public static void preventUpdateOfAccFields(Map<Id, Account> oldAccountMap, Map<Id, Account> newAccountMap) {
        
        Boolean isOSR = FeatureManagement.checkPermission('OSR_Outside_Sales_Rep');
        Boolean isSCR = FeatureManagement.checkPermission('SCR_Strategic_Customer_Rep');
        Boolean isBM = FeatureManagement.checkPermission('Branch_Manager');
        Boolean isERS = FeatureManagement.checkPermission('ERS_Equip_Rental_Specialist');
        Boolean isSM = FeatureManagement.checkPermission('Sales_Management');
        Account newAccount;
        Account oldAccount;
        
        if(isOSR || isSCR || isBM || isERS || isSM){  
            for (Id ide : newAccountMap.keySet()){
                if (
                    (newAccountMap.get(ide).RecordTypeId==SBR_3_0_Constants.ACCOUNT_CORP_LINK_RT_ID 
                    ||  newAccountMap.get(ide).RecordTypeId==SBR_3_0_Constants.ACCOUNT_CREDIT_RT_ID)
                ) {
                newAccount = newAccountMap.get(ide);
                oldAccount = oldAccountMap.get(ide);
                //Finally, check if the user was attempting to update any of the fields that are being targeted to prevent updates by the user
                if (checkForAccFieldChange(oldAccount, newAccount)) {
                    newAccount.addError('Only Job Site Requirements can be updated.');
                }
            }
        }
    }
    }
    

    private static Boolean checkForAccFieldChange(Account oldAccount, Account newAccount) {
        if (oldAccount.ParentId != newAccount.ParentId) { return true; }
        else if (oldAccount.Name != newAccount.Name) { return true; }
        else if (oldAccount.Phone != newAccount.Phone) { return true; }
        else if (oldAccount.E_mail_Address__c != newAccount.E_mail_Address__c) { return true; }
        else if (oldAccount.Description_Comment_2__c != newAccount.Description_Comment_2__c) { return true; }
        else if (oldAccount.Credit_Code_Description__c != newAccount.Credit_Code_Description__c) { return true; }
        else if (oldAccount.PersonOtherPhone__c != newAccount.PersonOtherPhone__c) { return true; }
        else if (oldAccount.Fax != newAccount.Fax) { return true; }
        else if (oldAccount.Other_Opportunity__c != newAccount.Other_Opportunity__c) { return true; }
        else if (oldAccount.Strategy_Last_Updated__c != newAccount.Strategy_Last_Updated__c) { return true; }
        else { return false; }
    }
    

    public static void prefixAccountNumberWithCompanyCode(List<Account> accounts) {
        if(accounts != null && !accounts.isEmpty() ){
            for(Account a : accounts) {
                if(!String.isBlank(a.RM_Account_Number__c) && a.RM_Account_Number__c.contains('-') == false && !String.isBlank(a.Company_Code__c)) {
                    a.RM_Account_Number__c = a.Company_Code__c + '-' + a.RM_Account_Number__c;
                }
            }
        }
    }

    public static void preventAccountNumberUpdate(Map<Id, Account> oldAccountMap, Map<Id, Account> newAccountMap) {

        for(Account a : newAccountMap.values()) {
            String newVal = a.RM_Account_Number__c;
            String oldVal = oldAccountMap.get(a.Id).RM_Account_Number__c;
            if(
                !String.isBlank(newVal) && newVal.contains('-') == false
                && !String.isBlank(oldVal) && oldVal.contains('-') == true 
            ) {
                //if the new value of RM_Account_Number is NOT prefixed with company code and hyphen 
                //and old value is correctly prefixed, then copy the value from old 
                a.RM_Account_Number__c = oldVal;
            }
            else if(
                !String.isBlank(newVal) && newVal.contains('-') == false
                && !String.isBlank(oldVal) && oldVal.contains('-') == false 
                && !String.isBlank(a.Company_Code__c)
            ) {
                //if the new value of RM_Account_Number is NOT prefixed with company code and hyphen 
                //and old value is also not prefixed, then update it to the right number 
                a.RM_Account_Number__c = a.Company_Code__c + '-' + a.RM_Account_Number__c;
            }
        }
    }

    public static void linkSalesRepIds(List<Account> accts) {
        Map<String,String> acctNumToSalesRepId = new Map<String,String>();
        Map<String,String> acctNumToRMName = new Map<String,String>();

        if(accts != null && !accts.isEmpty()) {
            for(Account a : accts) {
                if(String.IsNotBlank(a.Sales_Rep_Id__c)) {
                    acctNumToSalesRepId.put(a.RM_Account_Number__c, a.Sales_Rep_Id__c);
                }
                if(String.IsNotBlank(a.Last_Contact_By__c)) {
                    acctNumToRMName.put(a.RM_Account_Number__c, a.Last_Contact_By__c);
                }
            }

            Map<String, String>  userMap = new Map<String, String> ();
            if(acctNumToSalesRepId.size() > 0) {
                for(User u : SBR_3_0_UserDA.getUsersBySalesRepIds(new Set<String>(acctNumToSalesRepId.values()))) {
                    userMap.put(u.RepId__c, u.Id);
                }
            }

            Map<String, User> rmUserMap = SBR_3_0_UserDA.getUsersByRMUserName(new Set<String>( acctNumToRMName.values() ));
            for(Account a : accts) {
                //System.debug('\n @@acct rep = ' + a.Sales_Rep_Id__c);
                //Sales Rep Id update
                if(userMap.containsKey(a.Sales_Rep_Id__c)) {
                    a.RepID__c = userMap.get(a.Sales_Rep_Id__c);
                }
                else {
                    a.RepID__c = null;
                }
                
                // Last contact User lookup by update
                if(rmUserMap.containsKey(a.Last_Contact_By__c)) {
                    a.Last_Contact_By_User__c = rmUserMap.get(a.Last_Contact_By__c).Id;
                }
                else {
                    a.Last_Contact_By_User__c = null;
                }
            }
        }
    }

    public static void linkSalesRepIds(Map<Id, Account> oldMap, Map<Id, Account> newMap) {
        List<Account> toUpdate = new List<Account>();
        if(oldMap != null) {
            for(Account a : newMap.values()) {
                if(a.Sales_Rep_Id__c != oldMap.get(a.Id).Sales_Rep_Id__c || a.RepId__c == null) {
                    toUpdate.add(a);
                }
                if(a.Last_Contact_By__c != oldMap.get(a.Id).Last_Contact_By__c) {
                    toUpdate.add(a);
                }
            }
        }
        System.debug('\n @@ toupdate = ' + toUpdate);
        if(toUpdate.size() > 0) {
            linkSalesRepIds(toUpdate);
        }
    }

    public static void validateInboundAccount(List<Account> accts) {
        if(accts != null && !accts.isEmpty()) {
            for(Account a : accts) {
                if(String.isBlank(a.Billing_Street1__c)) {
                    //if billing street 1 is emtpy, copy billing street 2 to billingstreet
                    a.BillingStreet = a.Billing_Street2__c;
                }
            }
        }
    }

    public static void validateInboundAccount(Map<Id, Account> oldMap, Map<Id, Account> newMap) {
        List<Account> toUpdate = new List<Account>();
        if(oldMap != null) {
            for(Account a : newMap.values()) {
                if(a.Billing_Street1__c != oldMap.get(a.Id).Billing_Street1__c) {
                    toUpdate.add(a);
                }
            }
        }
        if(toUpdate.size() > 0) {
            validateInboundAccount(toUpdate);
        }
    }

    //SAL-23454 - Hashem A - Check if Country coming from RM is correct
    public static void validateStateCountry(Map<Id, Account> oldMap, List<Account> newAccts){
        Schema.DescribeFieldResult countryResult = User.Countrycode.getDescribe();
        List<Schema.PicklistEntry> countryEntries = countryResult.getPicklistValues();
        Schema.DescribeFieldResult stateResult = User.statecode.getDescribe();
        List<Schema.PicklistEntry> stateEntries = stateResult.getPicklistValues();

        Map<String, Set<String>> countryStatePicklist = SBR_3_0_GetDependentPicklistHelper.getDependentOptions(stateEntries, countryEntries);

        if(oldMap != null){
            for(Account acct: newAccts){
                Account oldAcct = oldMap.get(acct.Id);
                if(acct.RM_Country__c <> oldAcct.RM_Country__c || acct.RM_State__c <> oldAcct.RM_State__c){
                    if(acct.RM_Country__c <> NULL){
                        if(countryStatePicklist.containsKey(acct.RM_Country__c)){
                            acct.BillingCountry = acct.RM_Country__c;
                            if(acct.RM_State__c <> NULL && countryStatePicklist.get(acct.RM_Country__c).contains(acct.RM_State__c)){
                                acct.BillingState = acct.RM_State__c;
                            } else {
                                acct.BillingState = '';
                                acct.BillingCountry = '';
                            }
                        } else {
                            acct.BillingCountry = '';
                        }
                    } else {
                        acct.BillingCountry = '';
                        acct.BillingState = '';
                    }
                }
                
            }
        } else {
            // Insert
            for(Account acct: newAccts){
                if(acct.RM_Country__c <> NULL){
                    if(countryStatePicklist.containsKey(acct.RM_Country__c)){
                        acct.BillingCountry = acct.RM_Country__c;
                        acct.ShippingCountry = acct.RM_Country__c;
                        if(acct.RM_State__c <> NULL && countryStatePicklist.get(acct.RM_Country__c).contains(acct.RM_State__c)){
                            acct.BillingState = acct.RM_State__c;
                            acct.ShippingState = acct.RM_State__c;
                        } else {
                            acct.BillingCountry = '';
                            acct.ShippingCountry = '';
                            acct.BillingState = '';
                            acct.ShippingState = '';
                        }
                    } else {
                        acct.BillingCountry = '';
                        acct.ShippingCountry = '';
                    }
                } else {
                    acct.ShippingCountry = '';
                    acct.ShippingState = '';
                    acct.BillingCountry = '';
                    acct.BillingState = '';
                }
            }
        }
    }
    // Added for SAL-22623
    public static void updateDriverslicense(Map<Id, Account> oldMap,Map<Id, Account> newMap)
    {
        if(oldMap != null && newMap != null)
        {
            // for(Account currentAccount:  newMap.values()){
            //     if(
            //         currentAccount.RM_Cash_Number__c!=null 
            //         && currentAccount.RM_Cash_State__c!=null 
            //         && (
            //             oldMap.get(currentAccount.Id).RM_Cash_Number__c != currentAccount.RM_Cash_Number__c 
            //             || oldMap.get(currentAccount.Id).RM_Cash_State__c != currentAccount.RM_Cash_State__c
            //         )
            //     )
            //     {
            //         currentAccount.Drivers_License__c = currentAccount.RM_Cash_Number__c;
            //         currentAccount.Driver_s_License_State__c  = currentAccount.RM_Cash_State__c;
            //     }
            // }

            /* FRONT-3524 : Removed the loop on Accounts from this method and directly called validateRMCashState method 
             * so that method is only called once and not for every account record in loop
            */
            validateRMCashState(newMap.values(), oldMap);
        }
    }

    public static void updateDriverslicense(List<Account> newAccts)
    {
        // for(Account currentAccount: newAccts){
        //     if(currentAccount.RM_Cash_Number__c!=null && currentAccount.RM_Cash_State__c!=null)
        //     {
        //         currentAccount.Drivers_License__c = currentAccount.RM_Cash_Number__c;
        //         currentAccount.Driver_s_License_State__c  = currentAccount.RM_Cash_State__c;
        //     }
        // }

        /* FRONT-3524 : Removed the loop on Account records from this method and directly called validateRMCashState method 
         * so that method is only called once and not for every account record in loop
        */
        validateRMCashState(newAccts, null);
    }

    //FRONT-3524 : Added this method to validate the RM_Cash_State__c and RM_Cash_Number__c fields
    private static void validateRMCashState(List<Account> newAccts, Map<Id, Account> oldMap)
    {
        //List of string for Driver_s_License_State__c picklist values
        List<String> dlStatePickListValues = new List<String>();

        //Retrieve Driver_s_License_State__c picklist values
        Schema.DescribeFieldResult objFieldDescribe = Account.Driver_s_License_State__c.getDescribe();
        List<Schema.PicklistEntry> lstPickListValues = objFieldDescribe.getPickListValues();

        //Convert Schema.PicklistEntry to String list
        for(Schema.PicklistEntry picklistEntry : lstPickListValues){
            dlStatePickListValues.add(picklistEntry.getValue());
        }

        //If method called from insert trigger
        if(Trigger.isExecuting && Trigger.isInsert){
            //Added the loops on Account records here instead in updateDriverslicense methods 
            //so that validateRMCashState method is only called once and not for every account record in loop
            for(Account currentAccount : newAccts){
                if(currentAccount.RM_Cash_Number__c!=null && currentAccount.RM_Cash_State__c!=null){
                    //If RM_Cash_State__c is valid, then update the Drivers_License__c and Driver_s_License_State__c fields
                    if (dlStatePickListValues.contains(currentAccount.RM_Cash_State__c)){
                        currentAccount.Drivers_License__c = currentAccount.RM_Cash_Number__c;
                        currentAccount.Driver_s_License_State__c  = currentAccount.RM_Cash_State__c;
        
                        //IF DL is Valid, THEN Account Record Type = Non-Credit
                        currentAccount.RecordTypeId = SBR_3_0_Constants.ACCOUNT_NON_CREDIT_RT_ID;
                    }
                    else{
                        //If RM_Cash_State__c is not valid then DL State and DL Number is Null
                        currentAccount.Drivers_License__c = null;
                        currentAccount.Driver_s_License_State__c  = null;
        
                        //IF DL is Invalid, THEN Account Record Type = Guest
                        currentAccount.RecordTypeId = SBR_3_0_Constants.ACCOUNT_GUEST_RT_ID;
                    }
                }
            }
        }

        //If method called from update trigger
        if(Trigger.isExecuting && Trigger.isUpdate){
            //Added the loops on Account records here instead in updateDriverslicense methods 
            //so that validateRMCashState method is only called once and not for every account record in loop
            for(Account currentAccount : newAccts){
                if(
                    currentAccount.RM_Cash_Number__c!=null 
                    && currentAccount.RM_Cash_State__c!=null 
                    && (
                        oldMap.get(currentAccount.Id).RM_Cash_Number__c != currentAccount.RM_Cash_Number__c 
                        || oldMap.get(currentAccount.Id).RM_Cash_State__c != currentAccount.RM_Cash_State__c
                    )
                ){
                    //If RM_Cash_State__c is valid, then update the Drivers_License__c and Driver_s_License_State__c fields
                    if(dlStatePickListValues.contains(currentAccount.RM_Cash_State__c)){
                        currentAccount.Drivers_License__c = currentAccount.RM_Cash_Number__c;
                        currentAccount.Driver_s_License_State__c  = currentAccount.RM_Cash_State__c;
                    }
                    //If RM_Cash_State__c is invalid and record type is Non-Credit, then keep the RM values as it is and don't update the record type also
                    else if(!dlStatePickListValues.contains(currentAccount.RM_Cash_State__c)
                    && oldMap.get(currentAccount.Id).RecordTypeId == SBR_3_0_Constants.ACCOUNT_NON_CREDIT_RT_ID){
                        currentAccount.RM_Cash_Number__c = oldMap.get(currentAccount.Id).RM_Cash_Number__c;
                        currentAccount.RM_Cash_State__c   = oldMap.get(currentAccount.Id).RM_Cash_State__c;
                    }
                }
            }
        }
    }
    public static void setSanitisedDLNumber(List<Account> newAccounts) {
        for (Account newAccount : newAccounts) {
          if (String.isNotBlank(newAccount.Drivers_License__c)) {
            newAccount.Sanitised_DL_Number__c = sanitiseDLNumber(
              newAccount.Drivers_License__c
            );
          }
        }
      }
    
    private static String sanitiseDLNumber(String dLNumber) {
        return (String.isNotBlank(dLNumber))
          ? dLNumber.replaceAll('[^a-zA-Z0-9+]', '')
          : dLNumber;
    }

     public static void updateLobOnChildRecords(List<Account> newList, Map<Id, Account> oldMap){
      set<Id> creditIdSet = new Set<ID>();
      List<Account> updateAccList = new List<Account>();
      Set<Id> creditOrCorpIdSet = new Set<ID>();
      creditOrCorpIdSet.add(Schema.SObjectType.Account.getRecordTypeInfosByName().get('Credit').getRecordTypeId());
      creditOrCorpIdSet.add(SBR_3_0_Constants.ACCOUNT_CORP_LINK_RT_ID);
      Id officeRecordId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Office').getRecordTypeId();
      for(Account each:newList){
        if( ( oldMap ==null || each.Lines_of_Business__c != oldMap.get(each.id).Lines_of_Business__c || 
            each.No_of_Lines_of_Business__c != oldMap.get(each.id).No_of_Lines_of_Business__c)){
              if(creditOrCorpIdSet.contains(each.recordtypeid) ){
                creditIdSet.add(each.id);
              }
              if(officeRecordId == each.recordtypeid && each.parentId != null){
                creditIdSet.add(each.parentid);
              }
            
          }
      }
      if(!creditIdSet.isEmpty()){
          for(Account each: [Select id,parent.Lines_of_Business__c,parent.No_of_Lines_of_Business__c,
                                    Lines_of_Business__c, No_of_Lines_of_Business__c
                                    from Account where parentid in:creditIdSet AND 
                                    recordtype.name =: SBR_3_0_Constants.ACCOUNT_REC_TYPE_OFFICE]){
            each.No_of_Lines_of_Business__c = each.parent.No_of_Lines_of_Business__c;
            each.Lines_of_Business__c = each.parent.Lines_of_Business__c;
            system.debug('each.No_of_Lines_of_Business__c@ '+ each.No_of_Lines_of_Business__c);
            system.debug('each.Lines_of_Business__c@ '+ each.Lines_of_Business__c);
            updateAccList.add(each);
          }
      }
      if(!updateAccList.isEmpty()){
          UPDATE updateAccList;
      }
    }

    // SF-5397: On change of Account record type, updating Account_Record_Type_Txt__c field on Contact, Order and Quote. This field is used in sharing rules.
    public static void updateAccountRecordTypeOnChild(Map<Id,Account> oldAccMap, Map<Id,Account> newAccMap) {
        Set<Id> accIdsRecTypeChange = new Set<Id>();
        // check if Account record type is modified
        for(Account acc : newAccMap.values()) {
            if(acc.RecordTypeId != oldAccMap.get(acc.Id).RecordTypeId)
                accIdsRecTypeChange.add(acc.Id);
        }

        // if Account Record Type is changed, update the new rec type on child objects
        if(!accIdsRecTypeChange.isEmpty()) {
            List<Contact> listContactsToUpdate = new List<Contact>();
            List<Order> listOrdersToUpdate = new List<Order>();
            List<SBQQ__Quote__c> listQuotesToUpdate = new List<SBQQ__Quote__c>();

            List<Account> listAccountRecTypeChange = [Select RecordType.Name, (Select Id, Account_Record_Type_Txt__c from Contacts),
                (Select Id, Account_Record_Type_Txt__c from Orders), (Select Id, Account_Record_Type_Txt__c from SBQQ__Quotes__r) 
                from Account Where Id in: accIdsRecTypeChange];
            
            for(Account acc : listAccountRecTypeChange) {
                for(Contact c : acc.Contacts) {
                    c.Account_Record_Type_Txt__c = acc.RecordType.Name;
                    listContactsToUpdate.add(c);


                }
                for(Order o : acc.Orders) {
                    o.Account_Record_Type_Txt__c = acc.RecordType.Name;
                    listOrdersToUpdate.add(o);
                }
                for(SBQQ__Quote__c q : acc.SBQQ__Quotes__r) {
                    q.Account_Record_Type_Txt__c = acc.RecordType.Name;
                    listQuotesToUpdate.add(q);
                }
            }
            if(!listContactsToUpdate.isEmpty())
                update listContactsToUpdate;
            if(!listOrdersToUpdate.isEmpty())
                update listOrdersToUpdate;
            if(!listQuotesToUpdate.isEmpty())
                update listQuotesToUpdate;
        }

    }
        public static void setRPPFieldToTrue(List<Account> newList){
        try{

            List<Account> accountsToUpdate = new List<Account>();
            Id prospectRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect').getRecordTypeId();
            
            if(prospectRecordTypeId != null){
                for(Account account : newList){
                    if(account.RecordTypeId == prospectRecordTypeId && account.RPP__c != 'Y'){    //SF-7224
                        Account updatedAccount = new Account(Id = account.Id , RPP__c = 'Y');
                        accountsToUpdate.add(updatedAccount);
                    }
                }
                if(!accountsToUpdate.isEmpty()){
                    update accountsToUpdate;
                }
            }

        }catch(Exception e){
            throw e;
        }
       
    }
    
    // FRONT-11427 - keep the converted guest account record type to Non-Credit
  public static void setRecordTypeForConvertedWG(
    Map<Id, Account> oldAccountMap,
    Map<Id, Account> newAccountMap
  ) {
    for (Id accountId : newAccountMap.keySet()) {
      Account newAccount = newAccountMap.get(accountId);
      Account oldAccount = oldAccountMap.get(accountId);







      if (
        newAccount.RecordTypeId != oldAccount.RecordTypeId &&
        newAccount.RecordTypeId == SBR_3_0_Constants.ACCOUNT_GUEST_RT_ID &&
        oldAccount.RecordTypeId == SBR_3_0_Constants.ACCOUNT_NON_CREDIT_RT_ID
      ) {
        newAccount.RecordTypeId = SBR_3_0_Constants.ACCOUNT_NON_CREDIT_RT_ID;
      }
    }
  }

}