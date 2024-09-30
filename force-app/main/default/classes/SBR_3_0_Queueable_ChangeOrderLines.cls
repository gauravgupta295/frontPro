/**
 * @description This class was moved into the SBR 3 0 OrderItem After Insert Flow
 */
public with sharing class SBR_3_0_Queueable_ChangeOrderLines implements Queueable {
    
    /*private Set<String>  toDeleteIds;
    private Map<Id,OrderItem> orderItems;
    private Boolean isDelete = false;
    private Id updatedOId;
    private Integer toAdd =0;
    private String groupId;
    private OrderItem o;
    private Boolean hasSpecialARKey = false;
    //SAL-27478
    private Boolean arIs939 = false;
    List<OrderItem> orderItems_updateOrder;// SF-6897
    Set<String> orderIds_staleTotals;// SF-6897*/

    /**
     * @description This method was moved into the SBR 3 0 Order Item After Insert Flow
     * @param toDeleteIds - ids of records to delete
     * @param o - the originating order item
     * @param isDelete - boolean to tell if this is for deletion
     * @param oiIds_updateOrder
     * @param orderIds_staleTotals
     */
    public SBR_3_0_Queueable_ChangeOrderLines(Set<String> toDeleteIds, String groupId, OrderItem o, Boolean isDelete, Set<String> oiIds_updateOrder, Set<String> orderIds_staleTotals) {

        /*this.toDeleteIds = new Set<String>();
        this.toDeleteIds.addAll(toDeleteIds);
        this.orderItems = new Map<Id,OrderItem>(SBR_3_0_OrderItemDA.getOrderItemsFromGroupId(new Set<String> {groupId}, new Set<Id>()));
        this.updatedOId = updatedOId;
        this.isDelete = isDelete;
        this.o = new OrderItem();
        this.o = o;

        // SF-6897
        this.orderIds_staleTotals = orderIds_staleTotals;
        this.orderItems_updateOrder = SBR_3_0_OrderItemDA.getOrderItem(oiIds_updateOrder);*/
    }

    /**
     * @description This method was moved into the SBR 3 0 Order Item After Insert Flow
     * @param toAdd - True if order items should be created
     * @param groupId - Id of the group
     * @param orderIds set of order ids
     * @param oiIds_updateOrder - order items to update
     * @param orderIds_staleTotals - Ids of stale orders
     */
    public SBR_3_0_Queueable_ChangeOrderLines(Integer toAdd, String groupId, OrderItem o, Set<Id> orderIds, Set<String> oiIds_updateOrder, Set<String> orderIds_staleTotals) {

        /*this.orderItems = new Map<Id,OrderItem>(SBR_3_0_OrderItemDA.getOrderItemsFromGroupId(new Set<String> {groupId}, orderIds));
        this.updatedOId = updatedOId;
        this.isDelete = false;
        this.toAdd = toAdd;
        this.groupId = groupId;
        this.o = new OrderItem();
        this.o = o;

        // SF-6897
        this.orderIds_staleTotals = orderIds_staleTotals;
        this.orderItems_updateOrder = SBR_3_0_OrderItemDA.getOrderItem(oiIds_updateOrder);*/
    }

    /**
     * @description queueable execute method (moved to SBR 3 0 Order Item After Insert Flow)
     * @param context - The context of the queueable run.
     */
    public void execute(QueueableContext context) {
        /*SBR_3_0_OrderItemTriggerHandler.beforeUpdateRecursiveCheck = true;
        SBR_3_0_OrderItemTriggerHandler.afterUpdateRecursiveCheck = true;
        if(isDelete) {
            deleteItems();
        }
        else {
            addItems();
        }

        // Updates Order fields Specific_Pricing_Flag__c & LastOrderItemUpdated__c
        if(!this.orderItems_updateOrder.isEmpty()) {
            SBR_3_0_OrderItemOperations.updateOrderFields_Queueable(this.orderItems_updateOrder,this.orderIds_staleTotals);
        }*/
    }

    /*private void deleteItems() {
        List<OrderItem> todelete = new List<OrderItem>();
        List<OrderItem> toUpdate = new List<OrderItem>();

        hasSpecialARKey = SBR_3_0_OrderItemOperations.hasSpecialAnalysisRegionKeys(orderItems.values()[0].Order.Branch__r.Analysis_Region_Key__c);
        for(OrderItem oi : orderItems.values()) {
            if( toDeleteIds.contains(oi.Id)) {
                toDelete.add(oi);
            }
            else {
                oi = setOrderItemValues(oi);
                toUpdate.add(oi);
            }
        }

        if(toDelete.size()>0) {
            delete toDelete;
        }
        if(toUpdate.size()>0) {
            update toUpdate;
        }
        
    }

    private void addItems() {
        List<OrderItem> insertOrderItems = new List<OrderItem>();

        hasSpecialARKey = SBR_3_0_OrderItemOperations.hasSpecialAnalysisRegionKeys(orderItems.values()[0].Order.Branch__r.Analysis_Region_Key__c);
        //SAL-27478
        arIs939 = SBR_3_0_OrderItemOperations.analysisRegionIs939(orderItems.values()[0].Order.Branch__r.Analysis_Region_Key__c);
        
        Schema.SObjectType objectTypeOrderItem = OrderItem.sObjectType;
        List<String> fieldNotToQuery = new List<String>{'OwnerId', 'Line_Composite_Key__c'};
        for(Integer i = 0; i < toAdd; i++) {
            List<sObject> cloneOrderItemList = 
                SBR_3_0_CloneUtility.cloneObjects(new List<Sobject>{o}, objectTypeOrderItem, 'Id', fieldNotToQuery, false);
            for(sObject clonedOi : cloneOrderItemList) {
                OrderItem cloned = (OrderItem)clonedOi;
                cloned.groupId__c = groupId;
                cloned.Quantity = 1;
                cloned.Id = null;
                insertOrderItems.add(cloned);
            }
        }

        for(OrderItem oi : orderItems.values()) {
            oi = setOrderItemValues(oi);
        }

        if(insertOrderItems.size() > 0) {
            insert insertOrderItems;
        }
        update orderItems.values();
    }

    private OrderItem setOrderItemValues(OrderItem oi) {
        oi.Apply_Standby_Rates__c = o.Apply_Standby_Rates__c;
        oi.Contingency_Cost__c = o.Contingency_Cost__c;
        oi.Daily_Rate__c = o.Daily_Rate__c;
        oi.Line_Item_Notes__c = o.Line_Item_Notes__c;
        String appName=SBR_3_0_CustomLookupController.getAppName(); //FRONT-20866 Bug Code Addition
        if(appName != 'RAE Frontline'){
            //SAL-27478
            if(hasSpecialARKey){
                oi.Min_Rate__c = o.Monthly_Rate__c;
            } else if (arIs939){
                oi.Min_Rate__c = o.Weekly_Rate__c;
            } else {
                oi.Min_Rate__c = o.Daily_Rate__c;
            }
        }
        else{ 
            oi.Min_Rate__c = o.Min_Rate__c; // FRONT-20866 Bug Code Addition
        }
        oi.Monthly_Rate__c = o.Monthly_Rate__c;
        oi.Seasonal_Multiplier__c = o.Seasonal_Multiplier__c;
        oi.Shift_Differential__c = o.Shift_Differential__c;
        oi.Weekly_Rate__c = o.Weekly_Rate__c;
        oi.Quantity = o.Quantity;
        // SAL-19006
        oi.Rates_Overriden__c = o.Rates_Overriden__c;
        return oi;
    }*/
}