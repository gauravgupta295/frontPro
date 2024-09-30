trigger SBR_3_0_ApprovalTrigger on sbaa__Approval__c (after update) {

    // if (Trigger.isBefore && Trigger.isUpdate){
    //     new SBR_3_0_ApprovalTriggerHandler().run();
    // }

    if (Trigger.isAfter && Trigger.isUpdate){
        new SBR_3_0_ApprovalTriggerHandler().run();
    }
}