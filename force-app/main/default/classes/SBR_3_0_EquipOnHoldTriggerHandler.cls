/*********************************************************************************************************************
* Apex Class: SBR_3_0_EquipOnHoldTriggerHandler
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Class to manage trigger logic for Equipment On Hold 
* - SAL-9546
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME                        DATE                DETAIL FEATURES
    1.0         Ritesh Mohapatra                  2022-11-17              Initial version 
*********************************************************************************************************************/

public class SBR_3_0_EquipOnHoldTriggerHandler extends SBR_3_0_TriggerHandler
{
	@TestVisible
    private Map<Id, Equipment_on_Hold__c > oldEquipOnHoldMap;
    @TestVisible
    private Map<Id, Equipment_on_Hold__c > newEquipOnHoldMap;
    @TestVisible
    private List<Equipment_on_Hold__c > newEquipOnHoldList;
    @TestVisible
    private Boolean isUpdateValue;
    
    public SBR_3_0_EquipOnHoldTriggerHandler() {
        this.oldEquipOnHoldMap = (Map<Id, Equipment_on_Hold__c >) Trigger.oldMap;
        this.newEquipOnHoldMap = (Map<Id, Equipment_on_Hold__c >) Trigger.newMap;
        this.newEquipOnHoldList = (List<Equipment_on_Hold__c >) Trigger.new;
        this.isUpdateValue = Trigger.isUpdate;
    }
    
    public override void beforeUpdate() 
    {    
        SBR_3_0_EquipOnHoldTriggerOperations.updateContractOrderApplied(oldEquipOnHoldMap,newEquipOnHoldMap,newEquipOnHoldList,isUpdateValue);

    }
}