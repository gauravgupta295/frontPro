/*********************************************************************************************************************
* Apex Class: SBR_3_0_LeadOperations
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Class to manage any updates that needs to be done on Leads as part of trigger
* - SAL-756
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Avinash Rao             2022-03-11          Initial version    
*********************************************************************************************************************/
public with sharing class SBR_3_0_LeadOperations {

    private static final Boolean isIntegrationUser = FeatureManagement.checkPermission(SBR_3_0_Constants.ACCOUNT_EXTERNAL_USER);
    private static final Boolean isDataMigrationUser = FeatureManagement.checkPermission(SBR_3_0_Constants.DATA_MIGRATION_USER);

    public static void updateLeadFields(List<Lead> leadList,Map<Id, Lead> oldLeadMap){
        Map<Id, Contact> contMap = new Map<Id, Contact>();
        Map<Id, Account> acctMap = new Map<Id, Account>();
        for(Lead l : leadList) {
            if(l.Contact__c != null) {
                contMap.put(l.Contact__c, null);
            }
            if(l.Account__c != null) {
                acctMap.put(l.Account__c, null);
            }
        }
        contMap = SBR_3_0_ContactDA.getContactsName(contMap.keySet());
        acctMap = SBR_3_0_AccountDA.getAccountsName(acctMap.keySet());

        for(Lead l : leadList){
            //SF-5912 Skip Lead source update for Marketo Leads
            if (l.Marketo_Lead__c == false && oldLeadMap.containsKey(l.Id) && oldLeadMap.get(l.Id).OwnerId != l.OwnerId) {
                l.LeadSource = 'Employee Referral';
            }
            l.Company = acctMap.get(l.Account__c)!=null?acctMap.get(l.Account__c).Name:l.Company;
            l.Salutation = contMap.get(l.Contact__c)!=null?contMap.get(l.Contact__c).Salutation:l.Salutation;
            l.FirstName = contMap.get(l.Contact__c)!=null?contMap.get(l.Contact__c).FirstName:l.FirstName;
            l.MiddleName = contMap.get(l.Contact__c)!=null?contMap.get(l.Contact__c).MiddleName:l.MiddleName;
            l.LastName = contMap.get(l.Contact__c)!=null?contMap.get(l.Contact__c).LastName:l.LastName;
            l.Suffix = contMap.get(l.Contact__c)!=null?contMap.get(l.Contact__c).Suffix:l.Suffix;
        }
    }

    public static void preventLeadDeletion(List<Lead> leadList){
        Id profileId = userinfo.getProfileId();
        String profileName;
        Profile p = [SELECT Id, Name from Profile WHERE Id = :profileId LIMIT 1];

        if(p != null){
            profileName = p.Name;
        }
        for(Lead lead:leadList){
            if(profileName != SBR_3_0_Constants.PROFILE_NAME_ADMIN){
                lead.adderror('Lead cannot be deleted');
            }
        }
    }

    public static void fetchAddressLatLong(Map<Id, Lead> oldLeadMap, Map<Id, Lead> newLeadMap){
        Set<Id> changedAddress = new Set<Id>();

        for(Lead ld: newLeadMap.values()){
            if(oldLeadMap == NULL || oldLeadMap.isEmpty()){
                // Insert Operation
                if(ld.Job_Address_Street__c <> NULL || 
                ld.Job_Address_City__c <> NULL ||
                ld.Job_Address_State__c <> NULL ||
                ld.Job_Address_Zip_Code__c <> NULL ||
                ld.Job_Address_Country__c <> NULL || 
                ld.Street <> NULL || 
                ld.City <> NULL ||
                ld.State <> NULL ||
                ld.PostalCode <> NULL ||
                ld.Country <> NULL){
                    if(!changedAddress.contains(ld.Id)){
                        changedAddress.add(ld.Id);
                    }
                }

            } else {
                // Update Operation
                Lead oldLd = oldLeadMap.get(ld.Id);
                if(ld.Job_Address_Street__c <> oldLd.Job_Address_Street__c || 
                ld.Job_Address_City__c <> oldLd.Job_Address_City__c ||
                ld.Job_Address_State__c <> oldLd.Job_Address_State__c ||
                ld.Job_Address_Zip_Code__c <> oldld.Job_Address_Zip_Code__c ||
                ld.Job_Address_Country__c <> oldLd.Job_Address_Country__c || 
                ld.Street <> oldLd.Street || 
                ld.City <> oldLd.City ||
                ld.State <> oldLd.State ||
                ld.PostalCode <> oldld.PostalCode ||
                ld.Country <> oldLd.Country){
                    if(!changedAddress.contains(ld.Id)){
                        changedAddress.add(ld.Id);
                    }
                }
            }
        }

        if(!changedAddress.isEmpty()){
            // Call SBR_3_0_BatchLeadtLatLongProcessor Batch Class
            SBR_3_0_BatchLeadtLatLongProcessor latLongBtch = new SBR_3_0_BatchLeadtLatLongProcessor(changedAddress);
            if(isIntegrationUser == false && isDataMigrationUser == false && Test.isRunningTest() == false) {
                Database.executeBatch(latLongBtch, 1);
            }
            List<Lead> changedAddrLeads = SBR_3_0_LeadDA.getLeadsLatLongStatus(changedAddress);
            for(Lead ld: changedAddrLeads){
                if(changedAddress.contains(ld.Id)){
                    ld.Address_LatLong_Status__c = 'Fetching';
                }
            }
            update changedAddrLeads;
        }
    }
    
    //SF-5325 changes
    public static void updateLeadAssignmentFlag(List<Lead> leadList,Map<Id, Lead> oldLeadMap){
        for(Lead l : leadList){
            if (l.Marketo_Lead__c == true){
                if(oldLeadMap == NULL || oldLeadMap.isEmpty()){
                    l.Route_Marketo_Lead__c = true;
                }
                else if(l.Analysis_Region_Key__c != oldLeadMap.get(l.Id).Analysis_Region_Key__c){
                    l.Route_Marketo_Lead__c = true;
                }
            }
            
        }
    }
}