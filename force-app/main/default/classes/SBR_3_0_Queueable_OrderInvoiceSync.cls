public with sharing class SBR_3_0_Queueable_OrderInvoiceSync implements Queueable, Database.AllowsCallouts {
    
   
    public List<Invoice__c> invoices;
    public List<Order> orders;

    
    public SBR_3_0_Queueable_OrderInvoiceSync( List<Invoice__c> invoiceList) {
        this.invoices = invoiceList ;
    }

    public SBR_3_0_Queueable_OrderInvoiceSync( List<Order> orderList) {
        this.orders = orderList ;
    }

    public void execute(QueueableContext context){


        if(invoices != null){
            System.debug('invoice trigger');
            updateInvoices(invoices);
        }
        else if (orders != null){
            System.debug('order trigger');
            List<Decimal> orderContractNumbers = new List<Decimal>();
            List<Invoice__c> invoiceList = new List<Invoice__c>();

            //Build list of contract order Numbers from Order List
            for(Order orderItem : orders ){
                if(orderItem.Contract_Order_Number__c != null){
                    orderContractNumbers.add(Decimal.valueOf(orderItem.Contract_Order_Number__c));
                }
            }

            //Get Invoices by Contract number
            if(!orderContractNumbers.isEmpty()){
                invoiceList =  [SELECT Id, Contract_Number__c,Order__c FROM Invoice__c WHERE  Contract_Number__c IN :orderContractNumbers];
            }
            updateInvoices(invoiceList);
        }
    }


    private void updateInvoices (List<Invoice__c> invoicesToProcess) {
        List<String> contractNumbers = new List<String>();
        List<Order> orderList = new List<Order>();
        List<Invoice__c> invoicesToUpdate = new List<Invoice__c>();


        //Build list of contractNumbers from Invoice List
        for(Invoice__c invoiceItem : invoicesToProcess ){
            if(invoiceItem.Order__c == null){
                contractNumbers.add(String.valueOf(invoiceItem.Contract_Number__c));
            }
        }

        //Get Orders by Contract number
        if(!contractNumbers.isEmpty()){
                orderList =  [SELECT Id, Contract_Order_Number__c FROM Order WHERE  Contract_Order_Number__c IN :contractNumbers];
        }

        if(!orderList.isEmpty()){
                for(Invoice__c inv : invoicesToProcess ){
                    for(Order order : orderList){
                        if(String.valueOf(inv.Contract_Number__c) == order.Contract_Order_Number__c){
                            invoicesToUpdate.add(new Invoice__c(Id = inv.Id, Order__c = order.Id ));
                        }
                    }
                }
        }
        System.debug('invoice to update : ' + invoicesToUpdate);

        if(!invoicesToUpdate.isEmpty()){
            update invoicesToUpdate;
        }
    }
}