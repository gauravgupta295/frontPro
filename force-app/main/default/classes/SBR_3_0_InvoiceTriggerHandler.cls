public with sharing class SBR_3_0_InvoiceTriggerHandler extends SBR_3_0_TriggerHandler {


    public override void afterInsert() {
        List<Invoice__c> newInvoices = (List<Invoice__c>) Trigger.new;
        System.debug('new invoices : ' + newInvoices);
        System.enqueueJob(new SBR_3_0_Queueable_OrderInvoiceSync(newInvoices));
    }
    
}