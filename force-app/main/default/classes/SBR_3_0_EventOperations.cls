/*********************************************************************************************************************
* Apex Class: SBR_3_0_EventOperations
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Class to manage handler logic for Evetns
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Hashem Abdul         2023-07-11            Initial version    
*********************************************************************************************************************/
public without sharing class SBR_3_0_EventOperations {
    //SAL-25594
    public static void updateRelatedLead(List<Event> events){
        Schema.SObjectType leadObject = Schema.Lead.getSObjectType();
        Map<Id, Event> leadEventMap = new Map<Id, Event>();
        Map<Id, Id> eventLeadsMap = new Map<Id, Id>();

        for(Event evt: events){
            if(evt.whoId <> NULL && evt.whoId.getsobjecttype() == leadObject){
                eventLeadsMap.put(evt.Id, evt.whoId);
                leadEventMap.put(evt.whoId, evt);
            }
        }

        if(!eventLeadsMap.isEmpty()){
            List<Lead> leads = SBR_3_0_LeadDA.getLeadsByIds(new Set<Id>(eventLeadsMap.values()));
            //[SELECT ID, Activity_Created__c, Activity_Completed__c FROM Lead WHERE Id in: eventLeadsMap.values()];
            if(!leads.isEmpty()){
                for(Lead ld: leads){
                    Event evt = leadEventMap.get(ld.Id);
                    system.debug('Event Status: ' + evt.State__c);
                    ld.Activity_Created__c = true;
                    if(evt.Status__c <> NULL && evt.Status__c == 'Completed'){
                        ld.Activity_Completed__c = true;
                    }
                }
                update leads;
            }
        }
    }
}