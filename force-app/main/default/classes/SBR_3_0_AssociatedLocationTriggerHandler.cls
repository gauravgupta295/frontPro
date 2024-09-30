/*********************************************************************************************************************
* Apex Class: SBR_3_0_AssociatedLocationTriggerHandler
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - SAL-1503
* - Add Source Of Update field on Associated Location and populate it to track which system updated it
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME                      DATE                 DETAIL FEATURES
    1.0         Harry Rokad, Viren Patel           2022-03-30            Initial version 
    2.0         Konrad Haight                      2022-05-25            Added updateAddress        
    2.0         Viren Patel                        2022-10-15            Updated publishing jobsite to only publish if it has a lat/long (SAL-8663)
    2.0         Konrad Haight                      2022-10-18            Added System.enqueueJob(new SBR_3_0_Queueable_VerifyJobSiteAddress(Trigger.new)) to before Insert and Update
*********************************************************************************************************************/

public with sharing class SBR_3_0_AssociatedLocationTriggerHandler extends SBR_3_0_TriggerHandler {
    @TestVisible
    private Map<Id, AssociatedLocation> oldLocationMap;
    @TestVisible
    private Map<Id, AssociatedLocation> newLocationMap;
    
    public SBR_3_0_AssociatedLocationTriggerHandler() {
        this.oldLocationMap = (Map<Id, AssociatedLocation>) Trigger.oldMap;
        this.newLocationMap = (Map<Id, AssociatedLocation>) Trigger.newMap;
    }

    public override void beforeInsert() {
        system.debug('Job Site Before Insert Trigger');
        SBR_3_0_AssociatedLocationOperations.updateSourceOfUpdate(Trigger.new);
        //SBR_3_0_AssociatedLocationOperations.updateAddress(Trigger.new);
        SBR_3_0_AssociatedLocationOperations.mapReadinessFields(Trigger.new);
        SBR_3_0_AssociatedLocationOperations.setRecordCurrency(Trigger.new);
        Boolean isExternalUser = FeatureManagement.checkPermission(SBR_3_0_Constants.ACCOUNT_EXTERNAL_USER);
        if (!isExternalUser){
            SBR_3_0_JobSiteDuplicateCheckError.JobSiteDuplicateCheck(Trigger.new, false);
        }
        SBR_3_0_AssociatedLocationOperations.truncateLatLong(Trigger.new,  null);
        SBR_3_0_AssociatedLocationOperations.populateJobSiteId(Trigger.new);
        SBR_3_0_AssociatedLocationOperations.updateCompanyCode(Trigger.new);
        SBR_3_0_AssociatedLocationOperations.generateJobName(Trigger.new); 
        SBR_3_0_AssociatedLocationOperations.linkSalesRepIds(Trigger.new);
    }

    public override void beforeUpdate(){
        system.debug('Job Site Before Update Trigger');
        SBR_3_0_AssociatedLocationOperations.updateSourceOfUpdate(this.newLocationMap.values());
        //SBR_3_0_AssociatedLocationOperations.checkJobNumber(this.oldLocationMap, this.newLocationMap);
        SBR_3_0_AssociatedLocationOperations.setRecordCurrency(this.newLocationMap.values());
        //coming in future story: remove this update address from the before update
        //SBR_3_0_AssociatedLocationOperations.updateAddress(Trigger.new); //removed on purpose
        SBR_3_0_AssociatedLocationOperations.linkSalesRepIds(this.oldLocationMap, this.newLocationMap);
        SBR_3_0_AssociatedLocationOperations.truncateLatLong(Trigger.new, this.oldLocationMap);
    }
    
    public override void afterInsert() { 
        Map<Id, AssociatedLocation> recordsWithLatLong = getRecordsWithLatLongandCredit();
        if(recordsWithLatLong.size() > 0 && Test.isRunningTest() == false) {
            SBR_3_0_AssociatedLocationOperations.publishAssociatedLocations(recordsWithLatLong);
        }
        if (Test.isRunningTest() == false){
            SBR_3_0_AssociatedLocationOperations.validateNewJobSiteAddress(this.newLocationMap);
        }
    }

    public override void afterUpdate() {
        Map<Id, AssociatedLocation> recordsWithLatLong = getRecordsWithLatLongandCredit();
        if(recordsWithLatLong.size() > 0) {
            SBR_3_0_AssociatedLocationOperations.publishAssociatedLocations(recordsWithLatLong);
        }
        //SBR_3_0_AssociatedLocationOperations.getTerritory(Trigger.old, Trigger.new); //removed on purpose
        if (Test.isRunningTest() == false){
            //SBR_3_0_JobSiteDuplicateCheckError.JobSiteDuplicateCheckforUpdate(Trigger.newMap, Trigger.oldMap, Trigger.new);
            SBR_3_0_AssociatedLocationOperations.validateUpdateJobSiteAddress(this.newLocationMap , this.oldLocationMap);
        }
    }

    private Map<Id, AssociatedLocation> getRecordsWithLatLongandCredit() {
        Map<Id, AssociatedLocation> recordsWithLatLong = new Map<Id, AssociatedLocation>();
        
        Set<Id> parentaccountIds = new Set<Id>();
        for (AssociatedLocation asl : newLocationMap.values()) {
            if (asl.ParentRecordId != null) {
                parentaccountIds.add(asl.ParentRecordId);
            }
        }
        
        Map<Id, Account> accountMap = new Map<Id, Account>([SELECT Id, RecordTypeId FROM Account 
            WHERE Id IN :parentaccountIds 
            AND (RecordTypeId = :SBR_3_0_Constants.ACCOUNT_CREDIT_RT_ID OR
                 RecordTypeId = :SBR_3_0_Constants.ACCOUNT_CORP_LINK_RT_ID) ]);
        
        for (AssociatedLocation asl : newLocationMap.values()) {
            if (asl.Latitude_Longitude__latitude__s != null && asl.Latitude_Longitude__longitude__s != null &&
            accountMap.containsKey(asl.ParentRecordId)) {
                recordsWithLatLong.put(asl.Id, asl);
            }
        }
        
        System.debug('\n recordsWithLatLong = ' + recordsWithLatLong);
        return recordsWithLatLong;
    }
    
}