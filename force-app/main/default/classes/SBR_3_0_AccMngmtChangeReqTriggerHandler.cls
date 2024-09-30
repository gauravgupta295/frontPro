public with sharing class SBR_3_0_AccMngmtChangeReqTriggerHandler extends SBR_3_0_TriggerHandler{
    @TestVisible
    private Map<Id, Account_Management_Change_Request__c> oldUserMap;
    @TestVisible
    private Map<Id, Account_Management_Change_Request__c> newUserMap;
    
    public SBR_3_0_AccMngmtChangeReqTriggerHandler() {
        this.oldUserMap = (Map<Id, Account_Management_Change_Request__c>) Trigger.oldMap;
        this.newUserMap = (Map<Id, Account_Management_Change_Request__c>) Trigger.newMap;
    }
    
    public override void beforeInsert() {
    }

    public override void afterInsert() { 
        SBR_3_0_AccChangeMngmtReqOperations.updateWyneeRepDetails(Trigger.new);
    }

    public override void afterUpdate() {
    }
        

    public override void beforeUpdate() { 
    }
    
}