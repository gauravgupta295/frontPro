/*********************************************************************************************************************
* Apex Class: SBR_3_0_MakeUncollectedPaymentController
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:@description This code defines a Salesforce Apex controller class named SBR_3_0_MakeUncollectedPaymentController. It contains 
methods for retrieving deposit amount, contact information, payment methods, terminals, payment data, card details, and more. 
These methods are annotated with @AuraEnabled to make them accessible from Lightning components.
The code ensures security enforcement by utilizing WITH SECURITY_ENFORCED in SOQL queries and handles exceptions 
appropriately.
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
     1          Vivek Kumar Sharma     20-01-2024           
     2          Manu                   24-01-2024
     3          Prakash                29-01-2024
     4          Vatshal                10-02-2024
     5          Chethan                11-02-2024
     6          Kavita                 11-03-2024
     7          Vikas                  11-05-2024
*********************************************************************************************************************/
public with sharing class SBR_3_0_MakeUncollectedPaymentController {

     /**
    * Author: Manu
    * Method Name : getInvoice
    * @description Fetches the invoices for a given account ID.
    * @param accountIds The ID of the account for which to calculate the deposit.
    * @return List of Invoice.
    */

    public static List<Invoice__c> getInvoice(set<Id> accountIds) {
        if(accountIds.isEmpty()){
            return new List<Invoice__c>();
        }
        try{
            return [select id, Invoice_number__c, Invoice_Sequence_Number__c, Total_invoice_Amount__c, 
            Money_Applied_to_Invoice__c, Written_Off_Invoice__c,Order__c from Invoice__c where Account__c =: accountIds WITH SECURITY_ENFORCED];
        }catch(Exception e){
            SBR_3_0_Log.logException(e);
            return null ;
        } 
    }

     /**
    * Author: Manu
    * Method Name : getInvoiceFromOrder
    * @description Fetches the invoices for a given Order ID.
    * @param orderId The ID of the order for which to calculate the deposit.
    * @return List of Invoice.
    */
        
    @AuraEnabled(cacheable=false)
    public static List<Invoice__c> getInvoiceFromOrder(Id orderId) {
        List<Order> orderList = [select AccountId from Order where id =: orderId WITH SECURITY_ENFORCED];
        Set<Id> accountIds = new Set<Id>();
        for(Order order : orderList){
            accountIds.add(order.AccountId);
        }
        return getInvoice(accountIds);
    }

     /**
    * Author: Manu
    * Method Name : getInvoiceFromQuote
    * @description Fetches the invoices for a given Order ID.
    * @param quoteId The ID of the Quote for which to calculate the deposit.
    * @return List of Invoice.
    */
    @AuraEnabled(cacheable=false)
    public static List<Invoice__c> getInvoiceFromQuote(Id quoteId) {
        List<SBQQ__Quote__c> quoteList = [select SBQQ__Account__c from SBQQ__Quote__c where id =: quoteId WITH SECURITY_ENFORCED];
        Set<Id> accountIds = new Set<Id>();
        for(SBQQ__Quote__c quote : quoteList){
            accountIds.add(quote.SBQQ__Account__c);
        }
        return getInvoice(accountIds);   
    }

    /**
    * Author: Manu
    * Method Name : getInvoiceFromAccount
    * @description Fetches the invoices for a given Order ID.
    * @param accountId The ID of the Account for which to calculate the deposit.
    * @return List of Invoice.
    */

    @AuraEnabled(cacheable=false)
    public static List<Invoice__c> getInvoiceFromAccount(Id accountId) {
        return [select id, Invoice_number__c, Invoice_Sequence_Number__c, Total_invoice_Amount__c, Money_Applied_to_Invoice__c, Written_Off_Invoice__c,Order__c from Invoice__c where Account__c =: accountId WITH SECURITY_ENFORCED];       
    }

     /**
    * Author: Manu
    * Method Name : getNotOpenInvoiceFromAccount
    * @description Fetches the invoices for a given Order ID.
    * @param accountId The ID of the Account for which to calculate the deposit.
    * @return List of Invoice.
    */
    @AuraEnabled(cacheable=false)
    public static List<Invoice__c> getNotOpenInvoiceFromAccount(Id accountId) {
        try{
            SBR_3_0_Log.setRelatedRecordId(accountId);
            return [select id from Invoice__c where Account__c =: accountId and Order_Status__c = 'OP' WITH SECURITY_ENFORCED];
        } catch(Exception e){
            SBR_3_0_Log.logException(e);
            return null ;
        } finally {
            SBR_3_0_Log.saveLog();
        } 
    }

    /**
    * Author: Manu
    * Method Name : getInvoiceRecord
    * @description Fetches the invoices for a given Order ID.
    * @param invoiceId The ID of the Account for which to calculate the deposit.
    * @return List of Invoice.
    */

    @AuraEnabled(cacheable=false)
    public static List<Invoice__c> getInvoiceRecord(Id invoiceId) {
        return [select id, Invoice_number__c, Invoice_Sequence_Number__c, Total_invoice_Amount__c, 
                Money_Applied_to_Invoice__c, Written_Off_Invoice__c,Order__c from Invoice__c where id =: invoiceId WITH SECURITY_ENFORCED];
    }

    /**
    * Author: Kavita
    * Method Name : getInvoiceDetails
    * @description Fetches the invoices for a given Order ID.
     * @param recordId The ID of the Account for which to calculate the deposit.
    * @param sObjectName The ID of the Account for which to calculate the deposit.
    * @return List of Invoice.
    */
    @AuraEnabled(cacheable=false)
    public static List<Invoice__c> getInvoiceDetails(Id recordId, String sObjectName){
        try{
            SBR_3_0_Log.setRelatedRecordId(recordId);
            SBR_3_0_Log.logInfo('Test Log from AnonymousBlock');
            if(sObjectName == 'Order'){
                return getInvoiceFromOrder(recordId);
            }else if(sObjectName == 'Account'){
                return getInvoiceFromAccount(recordId);
            }else if(sObjectName == 'SBQQ__Quote__c'){
                return getInvoiceFromQuote(recordId);
            }else if(sObjectName == 'Invoice__c'){
                return getInvoiceRecord(recordId);
            }
            return new List<Invoice__c>();
        } catch(Exception e){
            SBR_3_0_Log.logException(e);
            return null ;
        } finally {
            SBR_3_0_Log.saveLog();
        }
    }

   /**
    * Author: Manu
    * Method Name : updateInvoiceDetails
    * @description Fetches the invoices for a given Order ID.
    * @param invoiceRecordId The ID of the Account for which to calculate the deposit.
    * @param moneyAppliedAmount The ID of the Account for which to calculate the deposit.
    * @param invoiceAmountEntered The ID of the Account for which to calculate the deposit.
    * @return List of Invoice.
    */
    @AuraEnabled(cacheable=false)
    public static String updateInvoiceDetails(Id invoiceRecordId, String moneyAppliedAmount, String invoiceAmountEntered){
        try {
            SBR_3_0_Log.setRelatedRecordId(invoiceRecordId);
            List<Invoice__c> invoiceDataToInsert = new List<Invoice__c>();
            Invoice__c invoiceRecord = new Invoice__c();
            invoiceRecord.Id = invoiceRecordId;
            invoiceRecord.Money_Applied_to_Invoice__c = Decimal.valueOf(moneyAppliedAmount) + Decimal.valueOf(invoiceAmountEntered);
            invoiceDataToInsert.add(invoiceRecord);
            if(!invoiceDataToInsert.isEmpty()){
                if (Schema.sObjectType.Invoice__c.isUpdateable()) {
                Database.update(invoiceDataToInsert);
                }
            }
            return 'success';
        } catch(Exception e){
            SBR_3_0_Log.logException(e);
            return null ;
        } finally {
            SBR_3_0_Log.saveLog();
        } 
    }

    /**
    * Author: Manu
    * Method Name : getInvoiceData
    * @description Fetches the invoices for a given Order ID.
    * @param accountId The ID of the Account for which to calculate the deposit.
    * @return List of Invoice.
    */
    @AuraEnabled(cacheable=false)
    public static List<Invoice__c> getInvoiceData(Id accountId) {
        try {
        // Calculate the date 120 days ago
        SBR_3_0_Log.setRelatedRecordId(accountId);
            Date startDate = Date.today().addDays(-120);
            // Query open invoices for the specified account within the last 120 days
            List<Invoice__c> invoiceData = [
                SELECT Id,Job_Site_Location__c, Name,Invoice_number__c,Invoice_Sequence_Number__c, Job_Site__c, Total_invoice_Amount__c, Invoice_Date__c ,Profit_Center__c,Due_Date__c,Amount_Due__c
                FROM Invoice__c 
                WHERE Account__c = :accountId 
                AND Due_Date__c >= :startDate 
                AND Order_Status__c = 'OP' 
                WITH SECURITY_ENFORCED
                ORDER BY Due_Date__c ASC
            ];
            return invoiceData;
        } catch(Exception e){
            SBR_3_0_Log.logException(e);
            return null ;
        } finally {
            SBR_3_0_Log.saveLog();
        } 
    }  
    
     /**
    * Author: Manu
    * Method Name : updateInvoicePaymentDetails
    * @description Fetches the invoices for a given Order ID.
    * @param invoicesToUpdateJson The ID of the Account for which to calculate the deposit.
    * @return List of Invoice.
    */
    @AuraEnabled(cacheable=false)
    public static String updateInvoicePaymentDetails(String invoicesToUpdateJson) {
    List<InvoiceUpdateWrapper> invoicesToUpdate = (List<InvoiceUpdateWrapper>) JSON.deserialize(invoicesToUpdateJson, List<InvoiceUpdateWrapper>.class);
    List<Id> invoiceIds = new List<Id>();
    Map<Id, Decimal> invoiceAmountMap = new Map<Id, Decimal>();

    // Gather Invoice Ids and corresponding amounts from the input wrappers
    for (InvoiceUpdateWrapper wrapper : invoicesToUpdate) {
        invoiceIds.add(wrapper.invoiceRecordId);
        invoiceAmountMap.put(wrapper.invoiceRecordId, Decimal.valueOf(wrapper.invoiceAmount));
    }

    // Fetch Invoice records using a single query
    List<Invoice__c> invoicesToUpdateList = [SELECT Id, Amount_Due__c FROM Invoice__c WHERE Id IN :invoiceIds WITH SECURITY_ENFORCED];

    // Update Amount Due for each Invoice record
    List<Invoice__c> invoicesToUpdateRecords = new List<Invoice__c>();
    for (Invoice__c invoiceRecord : invoicesToUpdateList) {
        Decimal newAmountDue = invoiceRecord.Amount_Due__c - invoiceAmountMap.get(invoiceRecord.Id);
        invoiceRecord.Amount_Due__c = newAmountDue;
        invoicesToUpdateRecords.add(invoiceRecord);
    }

    try {
        // Update all Invoice records in a single DML operation
        if (!invoicesToUpdateRecords.isEmpty()) {
            Database.update(invoicesToUpdateRecords);
            return 'success';
        } else {
            return 'error: No records to update';
        }
    } catch (Exception e) {
        SBR_3_0_Log.logException(e);
        return 'error: ' + e.getMessage();
    } finally {
        SBR_3_0_Log.saveLog();
    } 
}

    /**
    * Author: Manu
    * Method Name : InvoiceUpdateWrapper
    * @description Fetches the invoices for a given Order ID.
    */
    public class InvoiceUpdateWrapper {
        @AuraEnabled
        public Id invoiceRecordId;
        @AuraEnabled
        public String invoiceAmount;
        
        /**
    * Author: Manu
    * Method Name : InvoiceUpdateWrapper
    * @description Fetches the invoices for a given Order ID.
    */
        // No-argument constructor
        public InvoiceUpdateWrapper() {
            // No initialization needed, but required for serialization
            SBR_3_0_Log.saveLog();
        }
        
         /**
    * Author: Manu
    * Method Name : InvoiceUpdateWrapper
    * @description Fetches the invoices for a given Order ID.
    * @param invoiceRecordId The ID of the Account for which to calculate the deposit.
    * @param invoiceAmount The ID of the Account for which to calculate the deposit.
    */
        public InvoiceUpdateWrapper(Id invoiceRecordId, String invoiceAmount) {
            this.invoiceRecordId = invoiceRecordId;
            this.invoiceAmount = invoiceAmount;
        }
    }
}