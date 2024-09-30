/*********************************************************************************************************************
* Apex Class: SBR_3_0_LeadTriggerHandler
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Class to manage trigger logic for Leads
* - SAL-326
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Kunal Patel           2022-02-02            Initial version
    2.0         Konrad Haight         2022-03-21            Added before delete
    3.0         Harry                 2022-06-21            Separated varibale declaration from 1 line to 2 lines. * Apex PMD *    
*********************************************************************************************************************/
public with sharing class SBR_3_0_LeadTriggerHandler extends SBR_3_0_TriggerHandler {

    @TestVisible
    private Map<Id, Lead> oldLeadMap;
    @TestVisible
    private Map<Id, Lead> newLeadMap;
  
    public SBR_3_0_LeadTriggerHandler() {
        this.oldLeadMap = (Map<Id, Lead>) Trigger.oldMap;
        this.newLeadMap = (Map<Id, Lead>) Trigger.newMap;
    }
    public override void beforeUpdate() {
        SBR_3_0_LeadOperations.updateLeadFields(Trigger.new,this.oldLeadMap);
        //SF-5325 Changes
        SBR_3_0_LeadOperations.updateLeadAssignmentFlag(Trigger.new,this.oldLeadMap);
    }
    
    //SF-5325 Changes
    public override void beforeInsert() {
        SBR_3_0_LeadOperations.updateLeadAssignmentFlag(Trigger.new,NULL);
    }
    
    public override void afterInsert() {
        SBR_3_0_ConvertLeads.convertQualifiedLeads(this.newLeadMap);
        if (Test.isRunningTest() == false) {
            SBR_3_0_LeadOperations.fetchAddressLatLong(NULL, this.newLeadMap);
        }
    }

    public override void afterUpdate() {
        SBR_3_0_ConvertLeads.convertQualifiedLeads(this.newLeadMap);
        if (Test.isRunningTest() == false) {
            SBR_3_0_LeadOperations.fetchAddressLatLong(this.oldLeadMap, this.newLeadMap);
        }
    }

    public override void beforeDelete() {
        SBR_3_0_LeadOperations.preventLeadDeletion(Trigger.old);
    }
  
  }