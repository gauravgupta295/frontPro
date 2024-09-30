trigger SBR_3_0_OrderItemTrigger on OrderItem (before insert, before update, after update, after insert, before delete,after delete) {//SF-5291,SF-5292 added after delete
    if (Trigger.isAfter && Trigger.isInsert) {
        new SBR_3_0_OrderItemTriggerHandler().run();
    }

    if (Trigger.isBefore && Trigger.isInsert) {
        new SBR_3_0_OrderItemTriggerHandler().run();
    }

    if (Trigger.isAfter && Trigger.isUpdate){
        new SBR_3_0_OrderItemTriggerHandler().run();
    }

    if (Trigger.isBefore && Trigger.isUpdate){
        new SBR_3_0_OrderItemTriggerHandler().run();
    }
    if (Trigger.isBefore && Trigger.isDelete){
        new SBR_3_0_OrderItemTriggerHandler().run();
    }
    if (Trigger.isAfter && Trigger.isDelete){ 
        new SBR_3_0_OrderItemTriggerHandler().run(); //SF-5291,SF-5292 added to handle after delete
    }
}