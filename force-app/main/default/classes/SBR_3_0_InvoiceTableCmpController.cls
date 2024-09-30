public with sharing class SBR_3_0_InvoiceTableCmpController {
    public SBR_3_0_InvoiceTableCmpController() {

    }

    @AuraEnabled(cacheable = true)
    public static List<Invoice__c> getInvoiceList(String accountId){
        System.debug('Get Invoices for: ' + accountId);
        List<Invoice__c> invoices = SBR_3_0_InvoiceDA.getInvoices(accountId);
        if(invoices.size() < 0){
            System.debug('Empty Invoice List');
        }
        return invoices;
    }

    @AuraEnabled(cacheable = true)
    public static List<Invoice__c> getInvoiceListForOrder(String orderId){
        System.debug('Get Invoices for: ' + orderId);
        List<Invoice__c> invoices = SBR_3_0_InvoiceDA.getInvoicesForOrder(orderId);
        if(invoices.size() < 0){
            System.debug('Empty Invoice List');
        }
        return invoices;
    }

}