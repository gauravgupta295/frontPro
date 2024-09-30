/*********************************************************************************************************************
* Apex Class: SBR_3_0_TaskOperations
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Class to manage handler logic for Tasks
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Hashem Abdul         2023-07-11            Initial version    
*********************************************************************************************************************/
public without sharing class SBR_3_0_TaskOperations {
    // SAL-25594
    public static void updateRelatedLead(List<Task> tasks){
        Schema.SObjectType leadObject = Schema.Lead.getSObjectType();
        Map<Id, Task> leadTaskMap = new Map<Id, Task>();
        Map<Id, Id> taskLeadsMap = new Map<Id, Id>();

        for(Task tsk: tasks){
            if(tsk.whoId <> NULL && tsk.whoId.getsobjecttype() == leadObject){
                taskLeadsMap.put(tsk.Id, tsk.whoId);
                leadTaskMap.put(tsk.whoId, tsk);
            }
        }

        if(!taskLeadsMap.isEmpty()){
            List<Lead> leads = SBR_3_0_LeadDA.getLeadsByIds(new Set<Id>(taskLeadsMap.values()));
            if(!leads.isEmpty()){
                for(Lead ld: leads){
                    Task tsk = leadTaskMap.get(ld.Id);
                    ld.Activity_Created__c = true;
                    if(tsk.CompletedDateTime <> NULL){
                        ld.Activity_Completed__c = true;
                    }
                }
                update leads;
            }
        }
    }
}