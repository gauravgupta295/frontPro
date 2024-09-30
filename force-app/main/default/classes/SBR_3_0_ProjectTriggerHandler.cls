/*********************************************************************************************************************
* Apex Class: SBR_3_0_ProjectTriggerHandler
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Hadnler class for Project trigger SBR_3_0_ProjectTriggerHandler
* - SAL-2911
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Harry Rokad           2022-05-17            Initial version    
*********************************************************************************************************************/


public with sharing class SBR_3_0_ProjectTriggerHandler extends SBR_3_0_TriggerHandler {

    @TestVisible
    private Map<Id, Project__c> oldProjectMap;
    @TestVisible
    private Map<Id, Project__c> newProjectMap;

    Boolean isIntegrationUser = FeatureManagement.checkPermission(SBR_3_0_Constants.ACCOUNT_EXTERNAL_USER);
    Boolean isDataMigrationUser = FeatureManagement.checkPermission(SBR_3_0_Constants.DATA_MIGRATION_USER);
    public SBR_3_0_ProjectTriggerHandler() {
        this.oldProjectMap = (Map<Id, Project__c>) Trigger.oldMap;
        this.newProjectMap = (Map<Id, Project__c>) Trigger.newMap;
    }

    public override void afterInsert() { 
        SBR_3_0_ProjectOperations.publishProjectsToOutbox(this.newProjectMap);
        if (isDataMigrationUser == false && Test.isRunningTest() == false) {
            SBR_3_0_ProjectOperations.fetchAddressLatLong(NULL, this.newProjectMap);
            //SBR_3_0_ProjectOperations.getProjectTerritory(NULL, this.newProjectMap); // SF-8059: Commented as this has been moved to SBR_3_0_BatchProjectLatLongProcessor
        }
    }

    public override void afterUpdate() {
        // System.debug('In handler class');
        SBR_3_0_ProjectOperations.publishSfUserUpdates(this.newProjectMap);
        if (isDataMigrationUser == false && Test.isRunningTest() == false){
            SBR_3_0_ProjectOperations.fetchAddressLatLong(this.oldProjectMap,this.newProjectMap);
            //SBR_3_0_ProjectOperations.getProjectTerritory(this.oldProjectMap,this.newProjectMap); // SF-8059: Commented as this has been moved to SBR_3_0_BatchProjectLatLongProcessor
        }
    }
    
    //SF-8129 & SF-8059
    public override void beforeInsert() {
        if (isDataMigrationUser == true){
            SBR_3_0_ProjectOperations.updateProjRelField(null,Trigger.new);
        }        
    }
    
    //SF-8129 & SF-8059
    public override void beforeUpdate() {
        if (isDataMigrationUser == true){
            SBR_3_0_ProjectOperations.updateProjRelField(this.oldProjectMap,Trigger.new);
        }                
    }


}