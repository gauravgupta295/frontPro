/*********************************************************************************************************************
* Apex Class: SBR_3_0_AccountRelationshipTH
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Class to manage trigger logic for Account Relationships
* - SF-165
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME                        DATE                DETAIL FEATURES
    1.0         Saathvik Tulasi                   2023-04-17               Initial version 
*********************************************************************************************************************/
public  with sharing  class SBR_3_0_AccountRelationshipTH extends SBR_3_0_TriggerHandler{
	@TestVisible
    private Map<Id, Account_Relationship__c> mAccountRelationshipOld;
    @TestVisible
    private Map<Id, Account_Relationship__c> mAccountRelationshipNew;
    @TestVisible
    private list<Account_Relationship__c> lAccountRelationshipNew;
    
    public SBR_3_0_AccountRelationshipTH() {
        this.mAccountRelationshipOld = (Map<Id, Account_Relationship__c>) Trigger.oldMap;
        this.mAccountRelationshipNew = (Map<Id, Account_Relationship__c>) Trigger.newMap;
        this.lAccountRelationshipNew = (list<Account_Relationship__c>) Trigger.new;
    }
    
    public override void beforeInsert() {
        SBR_3_0_AccountRelationshipOperations.updateNewAssignment(this.lAccountRelationshipNew,NULL);
    }
    public override void beforeUpdate() {
        SBR_3_0_AccountRelationshipOperations.updateSyncSortingOrder(this.lAccountRelationshipNew,this.mAccountRelationshipOld);
        SBR_3_0_AccountRelationshipOperations.updateNewAssignment(this.lAccountRelationshipNew,this.mAccountRelationshipOld);
    }
    public override void afterInsert(){
        // Account_Relationship__c.SBR_3_0_Sync_Sorting_Order__c set to False by default
        //SBR_3_0_AccountRelationshipOperations.updateSyncSortingOrder(this.lAccountRelationshipNew,NULL);
        SBR_3_0_AccountRelationshipOperations.updateStrategicType(this.lAccountRelationshipNew,null);
        SBR_3_0_AccountRelationshipOperations.populateStrategicRepField(this.lAccountRelationshipNew);
    }
    public override void afterUpdate(){
        //Move below code to Before update 
        //SBR_3_0_AccountRelationshipOperations.updateSyncSortingOrder(this.lAccountRelationshipNew,this.mAccountRelationshipOld);
        SBR_3_0_AccountRelationshipOperations.updateStrategicType(this.lAccountRelationshipNew,this.mAccountRelationshipOld);
    }
}