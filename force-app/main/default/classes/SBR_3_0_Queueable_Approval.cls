public with sharing class SBR_3_0_Queueable_Approval implements Queueable, Database.AllowsCallouts{
    public Map<Id, sbaa__Approval__c> newTriggeredApprovalList;
    public Map<Id, sbaa__Approval__c> relatedApprovalList;

    public SBR_3_0_Queueable_Approval(Map<Id, sbaa__Approval__c> newTriggeredApprovalList, Map<Id, sbaa__Approval__c> relatedApprovalList) {
        this.newTriggeredApprovalList = newTriggeredApprovalList;
        this.relatedApprovalList = relatedApprovalList;
    }

    public void execute(QueueableContext context) {
        List<String> approvalIds = new List< String>();
        List<String> comments = new List< String>();
        //List<sbaa__Approval__c> updateNextStep = new List<sbaa__Approval__c>();
        for(Id ide : newTriggeredApprovalList.keySet()) {
            sbaa__Approval__c newApproval = newTriggeredApprovalList.get(ide);
            sbaa__Approval__c recentApproval = SBR_3_0_ApprovalDA.getRecentApproval(newApproval.Id);
            for(Id ide2 : relatedApprovalList.keySet()) {
                if(newApproval.Quote__c == relatedApprovalList.get(ide2).Quote__c) {
                    sbaa__Approval__c relatedApproval = relatedApprovalList.get(ide2);
                    if(newApproval.sbaa__ApprovalStep__c == relatedApproval.sbaa__ApprovalStep__c && newApproval.sbaa__Status__c != relatedApproval.sbaa__Status__c) {
                        if(newApproval.sbaa__Status__c == 'Approved' && relatedApproval.sbaa__ApprovedBy__c == null) {
                            if(relatedApproval.sbaa__Status__c != 'Approved' && newApproval.sbaa__ApprovedBy__c == recentApproval.sbaa__ApprovedBy__c && recentApproval.sbaa__Status__c == 'Approved') {
                                //SBR_3_0_API_Approve.Approve(String.valueOf(relatedApproval.Id), newApproval.sbaa__CommentsLong__c, UserInfo.getUserId());
                                
                                // SF-5301
                                approvalIds.add(String.valueOf(relatedApproval.Id));
                                comments.add(newApproval.sbaa__CommentsLong__c);
                            }
                        }
                    } 
                    /**else if(newApproval.sbaa__Status__c == 'Approved' && relatedApproval.sbaa__Status__c == 'Assigned' && relatedApproval.sbaa__ApprovalStep__c == newApproval.sbaa__ApprovalStep__c + 1) {
                        relatedApproval.sbaa__Status__c = 'Requested';
                        updateNextStep.add(relatedApproval);
                    }**/
                }
            }
        }
        // SF-5301
        if(!approvalIds.isEmpty())
             SBR_3_0_API_Approve.BulkApprove(approvalIds,comments);
             
        /**if(!updateNextStep.isEmpty()) {
            update updateNextStep;
        }**/
    }
}