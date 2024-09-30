public with sharing class PPA_PendingApprovalsLWCController {
    @AuraEnabled(cacheable=true)
    public static List<PPA_Price_List__c> getPendingApproval(){
        return [SELECT Id, Name, PPA_Customer_No__c, PPA_Customer_Name__c, PPA_Record_Type_Name__c, PPA_Start_Date__c, PPA_End_Date__c,
                       PPA_Customer_TTM__c, PPA_At_Market_Display__c, PPA_Current_TTM_RA_Display__c, PPA_RA_Improvement_Display__c, PPA_Rate_Type__c 
                  FROM PPA_Price_List__c
                 WHERE RecordType.DeveloperName IN ('PPA_Renewal','PPA_Extension')
                   AND PPA_Visible__c = true
                   AND PPA_Status__c = 'Pending Approval'
                   AND PPA_Next_Approver__c = :UserInfo.getUserId()];
    }
}