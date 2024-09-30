public with sharing class SBR_3_0_ApprovalOperations{
    public static void checkApprovalStatusChange(Map<Id, sbaa__Approval__c> oldApprovalMap, Map<Id, sbaa__Approval__c> newApprovalMap) {
        SBR_3_0_ApprovalTriggerHandler.afterUpdateRecursiveCheck = true;

        Set<Id> setNewApprovalIds = new Set<Id>();
        map<Id, sbaa__Approval__c> mapApprovalIdApproval = new map<Id, sbaa__Approval__c>();
        for(Id ide : newApprovalMap.keySet()){   
            if (oldApprovalMap != null && oldApprovalMap.get(ide).sbaa__Status__c != newApprovalMap.get(ide).sbaa__Status__c && newApprovalMap.get(ide).sbaa__Status__c == 'Approved' && newApprovalMap.get(ide).Quote__c != null) {
                mapApprovalIdApproval.put(ide, newApprovalMap.get(ide));
                setNewApprovalIds.add(ide);
            }
        }

        if(!setNewApprovalIds.isEmpty()) {
            Map<Id, sbaa__Approval__c> relatedApprovals = SBR_3_0_ApprovalDA.getRelatedQuoteApprovals(setNewApprovalIds);
            System.enqueueJob(new SBR_3_0_Queueable_Approval(newApprovalMap, relatedApprovals));
        }
    }
}