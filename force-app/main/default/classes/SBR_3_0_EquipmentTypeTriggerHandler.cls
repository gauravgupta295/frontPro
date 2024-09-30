/*********************************************************************************************************************
* Apex Class: SBR_3_0_EquipmentTypeTriggerHandler
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Class to publish EquipmentType records to Outbox object
* - SAL-1424
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME                      DATE                 DETAIL FEATURES
    1.0         Harry Rokad, Viren Patel           2022-03-30            Initial version    
*********************************************************************************************************************/



public with sharing class SBR_3_0_EquipmentTypeTriggerHandler extends SBR_3_0_TriggerHandler {
    @TestVisible
    private Map<Id, Equipment_Type__c> newEquipmentTypeMap;

    public SBR_3_0_EquipmentTypeTriggerHandler() {
        this.newEquipmentTypeMap = (Map<Id, Equipment_Type__c>) Trigger.newMap;
    }
    public override void afterInsert() { 
        SBR_3_0_EquipmentTypeOperations.publishEquipmentType(this.newEquipmentTypeMap);
    }

    public override void afterUpdate() {
        SBR_3_0_EquipmentTypeOperations.publishEquipmentType(this.newEquipmentTypeMap);
    }

}