public interface SBR_3_0_ApprovalDAInterface {
    Map<Id, sbaa__Approval__c> getRelatedQuoteApprovals(Set<Id> ids);
    sbaa__Approval__c getRecentApproval(Id id);
    sbaa__Approval__c getApprovalById(Id id);
}