public with sharing class SBR_3_0_QueueableUpdateOrderTotals implements Queueable, Database.AllowsCallouts {
    private String orderRecdId;

    public SBR_3_0_QueueableUpdateOrderTotals(String orderRecdId) {
        this.orderRecdId = orderRecdId;
    }

    public void execute(QueueableContext context) {
        if(orderRecdId != null){
           SBR_3_0_API_Contract_OpenOrderTaxUpdate.OrderWrapper resp =  SBR_3_0_API_Contract_OpenOrderTaxUpdate.updateOrderItemTaxes(orderRecdId);
           System.debug('Resp from API in SBR_3_0_QueueableUpdateOrderTotals ->'+resp);
        }
    }
}