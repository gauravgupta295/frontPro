public with sharing class SBR_3_0_ApprovalTriggerHandler extends SBR_3_0_TriggerHandler{
    @TestVisible
    private Map<Id, sbaa__Approval__c> oldApprovalMap;
    @TestVisible
    private Map<Id, sbaa__Approval__c> newApprovalMap;

    public static Boolean afterUpdateRecursiveCheck = false;
    public static Boolean beforeUpdateRecursiveCheck = false;

    public SBR_3_0_ApprovalTriggerHandler() {
        this.oldApprovalMap = (Map<Id, sbaa__Approval__c>) Trigger.oldMap;
        this.newApprovalMap = (Map<Id, sbaa__Approval__c>) Trigger.newMap;
    }

    public override void afterUpdate() {
        if(!afterUpdateRecursiveCheck) {
            SBR_3_0_ApprovalOperations.checkApprovalStatusChange(this.oldApprovalMap , this.newApprovalMap);
        }
    }
}