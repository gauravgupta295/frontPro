/*********************************************************************************************************************
* Apex Class: SBR_3_0_Queueable_OrderLines
------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - SF-6897: Combined the async logic (future+queueable) associated with the Order Items trigger 
* - to avoid locking errors between queueable class and future method.
------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME                        DATE                DETAIL FEATURES
    1.0         Shruti Gujarathi                      2024-02-16          Initial version   
*********************************************************************************************************************/
public class SBR_3_0_Queueable_OrderLines implements Queueable {
    List<OrderItem> orderItems_splitLines;
    List<OrderItem> orderItems_updateOrder;
    Set<String> orderIds_staleTotals;
    
    public SBR_3_0_Queueable_OrderLines(Set<String> oiIds_splitLines, Set<String> oiIds_updateOrder,Set<String> orderIds_staleTotals) {
        this.orderItems_splitLines = new List<OrderItem>();
        this.orderItems_updateOrder = new List<OrderItem>();
        this.orderIds_staleTotals = orderIds_staleTotals;
        
        if(!oiIds_splitLines.isEmpty()) {  
            this.orderItems_splitLines = SBR_3_0_OrderItemDA.getOrderItem(oiIds_splitLines);
        }
        if(!oiIds_updateOrder.isEmpty()) {   
            this.orderItems_updateOrder = SBR_3_0_OrderItemDA.getOrderItem(oiIds_updateOrder);
        }
    }

    public void execute(QueueableContext context) {        
        // Splits serialized order lines
        if(!this.orderItems_splitLines.isEmpty()) {
            SBR_3_0_OrderItemOperations.splitSerializedAssets_Queueable(this.orderItems_splitLines);
            
        }
        
        // Updates Order fields Specific_Pricing_Flag__c & LastOrderItemUpdated__c
        if(!this.orderItems_updateOrder.isEmpty()) {
            SBR_3_0_OrderItemOperations.updateOrderFields_Queueable(this.orderItems_updateOrder,this.orderIds_staleTotals);
        }
        
    }
    
}