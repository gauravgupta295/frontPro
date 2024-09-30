trigger SBR_3_0_OrderItemDetailTrigger on Order_Item_Detail__c (before insert, before update, after update, after insert, before delete) {
    if (Trigger.isAfter && Trigger.isInsert || Trigger.isAfter && Trigger.isUpdate) {
        new SBR_3_0_OrderItemDetailTriggerHandler().run();
    }
    

}