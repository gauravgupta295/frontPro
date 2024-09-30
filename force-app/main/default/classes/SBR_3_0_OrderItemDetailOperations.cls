/**
 * @description       : Operations class for handling Order Item Details updates
 * @author            : Hashem Abdul
 * @group             : 
 * @last modified on  : 02-06-2024
 * @last modified by  : Hashem Abdul
**/

public without sharing class SBR_3_0_OrderItemDetailOperations {

    /**
    * @description Modify Order Items Status that is related to Order Item Details upon Update
    * @author Hashem Abdul | 01-29-2024 
    * @param orderItemDetailsMap 
    * @param oldorderItemDetailsMap 
    **/
    public static void updateBulkStatus(Map<Id,Order_Item_Detail__c> orderItemDetailsMap ,Map<Id,Order_Item_Detail__c> oldorderItemDetailsMap )
    {
        // Map<Id,List<Order_Item_Detail__c>> orderItem_DetailsMap = new Map<Id,List<Order_Item_Detail__c>>();
        List<Order_Item_Detail__c> orderItemDetailsList;
        Set<Id> lineItemIds = new Set<Id>();
        List<OrderItem> orderItemUpdateList = new List<OrderItem>();
        Order_Item_Detail__c currentOrderItemDetailsRecord ;
        OrderItem orderItemRecord = new OrderItem();
        
        for(Order_Item_Detail__c currentOrderItemDetail : orderItemDetailsMap.values()){
           if(currentOrderItemDetail.Order_Type__c == 'ReturnOrder' && 
              (
                  (currentOrderItemDetail.Closed_Qty__c != oldorderItemDetailsMap.get(currentOrderItemDetail.Id).Closed_Qty__c && currentOrderItemDetail.Created_Qty__c == currentOrderItemDetail.Closed_Qty__c) ||
                  (currentOrderItemDetail.Cancelled_Qty__c != oldorderItemDetailsMap.get(currentOrderItemDetail.Id).Cancelled_Qty__c && currentOrderItemDetail.Created_Qty__c == currentOrderItemDetail.Cancelled_Qty__c)
              )){
                  lineItemIds.add(currentOrderItemDetail.Line_Item__c);       
           }
        }
        
        //List<OrderItem> orderItemList = SBR_3_0_OrderItemDA.getOrderItem(lineItemIds);
        List<OrderItem> orderItemRecordList = [SELECT Id FROM OrderItem WHERE Id in :lineItemIds And Status_Pick_Created_Qty__c != 0];
        for(OrderItem oi : orderItemRecordList){
            oi.Status_Pick_Created_Qty__c = 0;
        }
        
        //Moving the update. of cancelled / closed RETURN / PICKUP tickets to a queuable / async contents, since we are encountering
        //Row Locks when a RM exchange results in 3 API calls (2 for create return, 1 for create order) into Salesforce.
        //Punting the order items to a queueable class (2 minutes into the future), to help resolve.
        //We also A) adjusted the if statement above to handle only return orders (exchange orders were also locking rows),
        //and B) adjusted the SOQL query to only return line items that needed to be updated to 0 for the status pick up quantity.
        if(!orderItemRecordList.isEmpty()){
            System.enqueueJob(new SBR_3_0_Queueable_CUD_SObject(orderItemRecordList, 'Update'), 2);
        }
    }

    /**
    * @description Modify Order Items Status that is related to Order Item Details upon Insert
    * @author Hashem Abdul | 01-29-2024 
    * @param orderItemDetailsMap 
    **/
    public static void updateBulkStatusOnInsert(Map<Id,Order_Item_Detail__c> orderItemDetailsMap )
    {
         Map<Id, OrderItem> orderItemUpdateMap = new Map<Id, OrderItem>();
            
         for(Order_Item_Detail__c currentOrderItemDetail : orderItemDetailsMap.values()){
            if(currentOrderItemDetail.Line_Item__c!=null)
            {
                OrderItem orderItemRecord = new OrderItem();
                orderItemRecord.Id = currentOrderItemDetail.Line_Item__c;
                orderItemRecord.Status_Pick_Created_Qty__c = currentOrderItemDetail.Created_Qty__c;
                orderItemUpdateMap.put(orderItemRecord.Id, orderItemRecord);
            }
         }
        
         if(orderItemUpdateMap!=null && orderItemUpdateMap.size()>0)
         {
            // SF-6500 - Hashem A - Fix issue with racing condition 
            Map<Id, OrderItem> orderItemsForUpdate = SBR_3_0_OrderItemDA.getOrderItemsMapForUpdate(orderItemUpdateMap.keySet());
            for(Id key: orderItemUpdateMap.keySet()){
                orderItemsForUpdate.get(key).Status_Pick_Created_Qty__c = orderItemUpdateMap.get(key).Status_Pick_Created_Qty__c;
            }
            // System.debug('###updateList'+orderItemUpdateMap);
            System.enqueueJob(new SBR_3_0_Queueable_CUD_SObject(orderItemsForUpdate.values(), 'Update')); // SF-6748 - Moving to Queueable due to racing updating issue
         }
    }
}