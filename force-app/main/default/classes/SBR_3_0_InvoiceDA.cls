public with sharing class SBR_3_0_InvoiceDA implements SBR_3_0_InvoiceDAI {
    public SBR_3_0_InvoiceDA() {

    }

    @AuraEnabled(Cacheable = true)
    public static List<Invoice__c> getInvoices(String accountId){
      
        List<Invoice__c> invoices = [SELECT Id, Name, Contract_Number__c, Invoice_number__c,Invoice_Sequence_Number__c, Invoice_Date__c, Total_invoice_Amount__c,
        toLabel(Order_Status__c),Order__c,Order__r.Sourcing_Branch__c,Order__r.Sourcing_Branch__r.Name, Job_Site__c, Account__c FROM Invoice__c WHERE Account__c =: accountId];
        if(invoices.size()<0){
            
        }
        return invoices;
    }
    
    @AuraEnabled(Cacheable = true)
    public static List<String> getInvoiceOrderStatusOptions() {
        List<String> activeOptions = new List<String>();
        List<PicklistEntry> picklistOptions = Invoice__c.Order_Status__c.getDescribe().getPicklistValues();
        
        for (PicklistEntry option : picklistOptions) {
            if (option.isActive()) {
                
                activeOptions.add(option.getValue());
            }
        }
        
        return activeOptions;
    }

    @AuraEnabled(Cacheable = true)
    public static List<Invoice__c> getInvoicesForOrder(String orderId){
        
        List<Invoice__c> invoices;
        Order invoiceOrder = SBR_3_0_OrderDA.getOrder(orderId);
        if(invoiceOrder!=null && String.isNotBlank(invoiceOrder.Contract_Order_Number__c) )
        {	
       	   Integer contractNumber = Integer.valueOf(invoiceOrder.Contract_Order_Number__c);
           invoices = [SELECT Id, Name, Contract_Number__c, Invoice_Sequence_Number__c, Invoice_Date__c, Total_invoice_Amount__c,
           toLabel(Order_Status__c), Job_Site__c, Account__c FROM Invoice__c WHERE Contract_Number__c =:contractNumber ];

		}
        else{
            	invoices = [SELECT Id, Name, Contract_Number__c, Invoice_Sequence_Number__c, Invoice_Date__c, Total_invoice_Amount__c,
        					toLabel(Order_Status__c), Job_Site__c, Account__c FROM Invoice__c WHERE Order__c =: orderId];
        }

        if(invoices.size()<0){
            
        }
        return invoices;
    }


}