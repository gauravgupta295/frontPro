trigger SBR_3_0_InvoiceTrigger on Invoice__c (after insert, before insert) {
    new SBR_3_0_InvoiceTriggerHandler().run();
}