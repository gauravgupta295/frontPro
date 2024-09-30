public with sharing class SBR_3_0_CustomerSpendTriggerHandler extends SBR_3_0_TriggerHandler{
    
    private List<Customer_Spend__c> newList = new List<Customer_Spend__c>();
    private Map<id,Customer_Spend__c> oldMap = new Map<id,Customer_Spend__c>();
    private Map<id,Customer_Spend__c> newMap = new Map<id,Customer_Spend__c>();

    public SBR_3_0_CustomerSpendTriggerHandler(){
        this.newList = (List<Customer_Spend__c>)Trigger.new;
        this.oldMap = (Map<id,Customer_Spend__c>)Trigger.oldMap;
        this.newMap = (Map<id,Customer_Spend__c>)Trigger.newMap;
    }

    public override void afterUpdate(){
        SBR_3_0_CustomerSpendOperations.updateSyncSortingOrder(this.newList,this.oldMap);
        SBR_3_0_CustomerSpendOperations.updateLOBOnAccount(this.newList,this.oldmap);
    }

    public override void afterInsert(){
        //SBR_3_0_CustomerSpendOperations.updateSyncSortingOrder(this.newList,NULL);
        SBR_3_0_CustomerSpendOperations.updateLOBOnAccount(this.newList,null);
    }
}