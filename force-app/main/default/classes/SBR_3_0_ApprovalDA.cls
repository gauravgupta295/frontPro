public with sharing class SBR_3_0_ApprovalDA implements SBR_3_0_ApprovalDAInterface{
    public static Map<Id, sbaa__Approval__c> getRelatedQuoteApprovals(Set<Id> approvalIds) {
        sbaa__Approval__c approval = [SELECT Quote__c, sbaa__ApprovalStep__c
                                            FROM sbaa__Approval__c
                                            WHERE Id =: approvalIds LIMIT 1];

        // Set<Id> quoteIds = new Set<Id>();
        // for(sbaa__Approval__c approval : approvals) {
        //     quoteIds.add(approval.Quote__c);
        // }

        return new Map<Id, sbaa__Approval__c> ([SELECT Id, sbaa__Status__c, Quote__c, sbaa__ApprovalStep__c, Name, sbaa__ApprovedBy__c
                                                    FROM sbaa__Approval__c
                                                    WHERE Quote__c =: approval.Quote__c]);
    }

    public static sbaa__Approval__c getRecentApproval(Id approvalId) {
        sbaa__Approval__c approval = [SELECT Quote__c, sbaa__ApprovalStep__c
                                            FROM sbaa__Approval__c
                                            WHERE Id =: approvalId LIMIT 1];

        return ([SELECT Id, sbaa__Status__c, Quote__c, sbaa__ApprovalStep__c, Name, sbaa__ApprovedBy__c
                                                    FROM sbaa__Approval__c
                                                    WHERE Quote__c =: approval.Quote__c AND sbaa__ApprovalStep__c =: approval.sbaa__ApprovalStep__c AND sbaa__Status__c = 'Approved'
                                                    ORDER BY LastModifiedDate LIMIT 1]);
    }

    public static sbaa__Approval__c getApprovalById(Id approvalId) {
        return [SELECT Id, sbaa__ApprovedBy__c
                        FROM sbaa__Approval__c
                        WHERE Id =: approvalId];
    }
}