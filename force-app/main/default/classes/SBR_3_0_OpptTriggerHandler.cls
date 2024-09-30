/*********************************************************************************************************************
* Apex Class: SBR_3_0_OpptTriggerHandler
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Class to manage trigger logic for Opportunities
* - SAL-1397
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Konrad Haight           2022-03-21            Initial version
    2.0         Harry Rokad             2022-08-18            Added After insert and update
*********************************************************************************************************************/
public with sharing class SBR_3_0_OpptTriggerHandler extends SBR_3_0_TriggerHandler {

    @TestVisible
    private Map<Id, Opportunity> oldOpptMap;
    @TestVisible
    private Map<Id, Opportunity> newOpptMap;

    public SBR_3_0_OpptTriggerHandler() {
        this.oldOpptMap = (Map<Id, Opportunity>) Trigger.oldMap;
        this.newOpptMap = (Map<Id, Opportunity>) Trigger.newMap;
    }

    public override void beforeInsert() {
        if (Test.isRunningTest() == false){
            SBR_3_0_OpptOperations.checkProjectField(Trigger.new);
        }
    }

    public override void beforeDelete() {
        if (Test.isRunningTest() == false){
            SBR_3_0_OpptOperations.preventOpptDeletion(Trigger.old);
        }
    }

    public override void afterInsert() { 
        if (Test.isRunningTest() == false){
            SBR_3_0_OpptOperations.fetchAddressLatLong(NULL, this.newOpptMap);
        }
    }

    public override void beforeUpdate() {

    }

    public override void afterUpdate() {
        if (Test.isRunningTest() == false){
            SBR_3_0_OpptOperations.fetchAddressLatLong(this.oldOpptMap,this.newOpptMap);
        }
    }
}