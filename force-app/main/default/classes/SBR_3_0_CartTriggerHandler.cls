/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 12-29-2023
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class SBR_3_0_CartTriggerHandler extends SBR_3_0_TriggerHandler {

    @TestVisible
    private Map<Id, Cart__c> oldCartMap;
    @TestVisible
    private Map<Id, Cart__c> newCartMap;

    public SBR_3_0_CartTriggerHandler() {
        this.oldCartMap = (Map<Id, Cart__c>) Trigger.oldMap;
        this.newCartMap = (Map<Id, Cart__c>) Trigger.newMap;
    }

    public override void beforeInsert() {
        try{
            SBR_3_0_CartOperations.setCartStatusToNull(Trigger.new);
            SBR_3_0_CartOperations.populateStartTime(Trigger.new);
            SBR_3_0_CartOperations.setDateInUserTimeZone(Trigger.new);
            SBR_3_0_CartOperations.populateUTCstartTime(Trigger.new,null);
        }catch (Exception e){
            SBR_3_0_Log.logException(e);
        }finally{
            SBR_3_0_Log.saveLog();
        }
    }
    /*public override void afterInsert(){
        SBR_3_0_CartOperations.setStartAndReturnTime(Trigger.new);
    }*/
    public override void beforeUpdate() {
        try{
            SBR_3_0_CartOperations.setDateInUserTimeZone(Trigger.new);
            //SAL-26857
            SBR_3_0_CartOperations.SetRentalEndDateForOG(Trigger.new);
            SBR_3_0_CartOperations.populateUTCstartTime(Trigger.new,this.oldCartMap);
        }catch (Exception e){
            SBR_3_0_Log.logException(e);
        }finally{
            SBR_3_0_Log.saveLog();
        }

    }
}