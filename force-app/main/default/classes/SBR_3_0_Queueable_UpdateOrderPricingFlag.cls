/*********************************************************************************************************************
* Apex Class: SBR_3_0_Queueable_UpdateOrderPricingFlag
----------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - To update the pricing flags on Order record 
----------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME						DATE					DETAIL FEATURES
    1.0         Nilesh Jaiswal						2024-03-01				Initial version   
*********************************************************************************************************************/
public without sharing class SBR_3_0_Queueable_UpdateOrderPricingFlag implements Queueable, Finalizer {
	/*public List<OrderItem> orderItems;
    Set<Id> orderItemsIds;
    */
    public SBR_3_0_Queueable_UpdateOrderPricingFlag(Set<Id> orderItemsIds) {
        /*orderItems = new List<OrderItem>();
        this.orderItemsIds = orderItemsIds;
        this.orderItems = SBR_3_0_OrderDA.getOrderItems(orderItemsIds);*/
    }
    
    public void execute(QueueableContext context) {
       /* String jobId = '' + context.getJobId();
        Finalizer finalizer = new SBR_3_0_Queueable_UpdateOrderPricingFlag(this.orderItemsIds);
        System.attachFinalizer(finalizer);
        SBR_3_0_OrderItemOperations.updateOrderHeaderSpecificPricingFlag(orderItems);*/
    }

    public void execute(FinalizerContext ctx) {
       /* String parentJobId = '' + ctx.getAsyncApexJobId();
        if (ctx.getResult() == ParentJobResult.SUCCESS) {
            System.debug('Parent queueable job [' + parentJobId + '] completed successfully.');
        } else {
            String newJobId = '' + System.enqueueJob(new SBR_3_0_Queueable_UpdateOrderPricingFlag(this.orderItemsIds)); // This call fails after 5 times when it hits the chaining limit
        }*/
      }
      
}