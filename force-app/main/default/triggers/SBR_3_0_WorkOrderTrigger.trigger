/*********************************************************************************************************************
* Apex Class: SBR_3_0_WorkOrderTrigger
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - SERV-15700
* - Trigger to check WorkOrder Before Update actions
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME                     DATE                DETAIL FEATURES
1.0         Diksha Tiwari                      2024-05-28           Initial version
*********************************************************************************************************************/
trigger SBR_3_0_WorkOrderTrigger on WorkOrder (before update) {
    
    Boolean isIntegrationUser = FeatureManagement.checkPermission('Integration_User');
    Bypass_Settings__c bps = Bypass_Settings__c.getInstance(UserInfo.getUserId());
    boolean bypass = bps.Bypass_Flow__c;
    
    
    if(Trigger.isBefore && Trigger.isUpdate && !isIntegrationUser && !bypass) {
        SBR_3_0_WorkOrderTriggerHandler.checkForWOEditbale(Trigger.old,Trigger.new);
    }  
    
}