/*********************************************************************************************************************
    * Apex Class: SBR_3_0_(OrderItemOperations)
    ---------------------------------------------------------------------------------------------------------------------------------------
    * Purpose/Methods:
    * @description - Class to manage any insert/updates that needs to be done on Order Line Items as part of trigger
    --------------------------------------------------------------------------------------------------------------------------------------
    * History:
    * - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Viren Patel             2022-11-16          Initial version
    1.1         Bhavesh Dhamecha		2023-12-24			Updated class from with sharing to without sharing for SAL-19645
    1.2         Venkat Mothukuri		2023-09-23			Updated class to Assign values for Suggested Min/Daily/Weekly/Monthly Rates
    1.3         Bhavesh Dhamecha        2023-09-29          Added submitReservation Method and submitReservationToRM Method to Submit Order to RM (Also fixed Indentation) SAL-26768
    1.4         Shruti Gujarathi        2024-02-18          SF-6897: Changes in the Queueable logic which run on insert and update to resolve the Record_Lock errors
    2.0.        James and Amanjot       2024-03-24          Order Item Optimization Changes
    *********************************************************************************************************************/
public without sharing class SBR_3_0_OrderItemOperations {
    /**
     * @description method to call update totals for locked reservations
     * @param oldSObjectMap oldSObjectMap
     * @param newSObjectMap newSObjectMap
     */
    public static void callUpdateTotalsForLockedReservation(Map<Id, SObject> oldSObjectMap,Map<Id,SObject> newSObjectMap){
        Set<Id> orderIdSet = new Set<Id>();
        Set<Id> orderIdSetEstimate = new Set<Id>();
        Map<Id, OrderItem> oldMap = (Map<Id, OrderItem>)oldSObjectMap;
        Map<Id,OrderItem> newMap = (Map<Id, OrderItem>) newSObjectMap;

        for(OrderItem orderLine : newMap.values()){
            orderIdSet.add(orderLine.OrderId);
        }
        Map<Id, Order> allOrders = SBR_3_0_OrderDA.getOrders(orderIdSet);

        //Map<Id,String> recordTypeIdsToName = SBR_3_0_RecordTypesForObject.getRecordTypeIdsToName('Order');
        Id lockedReservationRecordTypeId = Schema.sObjectType.Order.getRecordTypeInfosByName().get('Canceled_Reservation_Order').getRecordTypeId();

        for(Order currentOrder : allOrders.values()){
            if(lockedReservationRecordTypeId == currentOrder.RecordTypeId){
                orderIdSetEstimate.add(currentOrder.Id);
            }
        }

        if(orderIdSetEstimate!=null && orderIdSetEstimate.size()>0){
            System.enqueueJob(new SBR_3_0_QueueableUpdateTotalOrder(orderIdSetEstimate));
        }
    }
    
	public static void updateFuelPlanLineItemsFromRentalMan(List<OrderItem> orderLines) {
        try {
			 SBR_3_0_LineItemCartCmpController.updateFuelPlanItems(orderLines, 'OrderId', 'Product2Id', 'Product_SKU__c', 'Order','Reservation_Order_Number__c');

        } catch (Exception ex) {
            SBR_3_0_Log.logException(ex);
        } finally {
            SBR_3_0_Log.saveLog();
        }
    }
    /**
     * @description remove child Cat-Class Fuel Plan lineitems
     * if parent fuel plan field is unchecked in after trigger context
     * SF-5291,SF-5292
     * @param newLines Trigger.new
     * @param oldLines Trigger.oldMap
     */
    public static void removeChildFuelPlanIfParentUnchecked(List < OrderItem > newLines, Map < Id, sObject > oldLines) {
        try {
            Set<String> productIds = new Set<String>();
            Set<Id> orderIds = new Set <Id>();
            Map<String,OrderItem > orderLineMain = new Map<String,OrderItem>();
            List<OrderItem> getFuelPlanLineItems = new List<OrderItem>();
            for (OrderItem orderLine: newLines) {
                productIds.add(orderLine.Product2.Id);
                OrderItem oldLine = (OrderItem) oldLines.get(orderLine.Id);
                if (oldLine.Fuel_Plan__c && !orderLine.Fuel_Plan__c){
                    orderIds.add(orderLine.OrderId);
                    orderLineMain.put(orderLine.Product_SKU__c, orderLine);
                }
            }

            if (!orderLineMain.isEmpty()) {
                getFuelPlanLineItems = [select id, Kit_Number_This_Item_Belongs_To__c, Product2.Name, Quantity from OrderItem where Kit_Number_This_Item_Belongs_To__c in: orderLineMain.keyset() and(Product2.Name Like '%Fuel Convenience Charge%') and OrderId in: orderIds WITH SECURITY_ENFORCED ];//SF-5879
                if (getFuelPlanLineItems.size() > 0) {
                    Database.delete(getFuelPlanLineItems, true);
                 }
            }
        } catch (Exception ex) {
            SBR_3_0_Log.logException(ex);
        } finally {
            SBR_3_0_Log.saveLog();
        }
    }

    /**
     * @description uncheck child Cat-Class Fuel Plan lineitems
     * if child fuel plan is removed
     * in after delete trigger context
     * SF-5291,SF-5292
     * @param oldLines Trigger.oldMap
     */
    public static void uncheckFuelPlanCheckBox(List < OrderItem > oldLines) {
        try {
            Boolean hasExistingFlag = false;
            Set<String> kitNumbers = new Set<String>();
            Set<String> orderIds = new Set<String>();
            List<OrderItem > oliToUpdate = new List < OrderItem > ();
            Map<Id, Product2 > productMap = getProductMap(oldLines);
            for (OrderItem orderLine: oldLines) {
                String productName = productMap.get(orderLine.Product2Id).Name;
                if (isFuelPlanItem(productName, orderLine.Kit_Number_This_Item_Belongs_To__c)) {
                    kitNumbers.add(orderLine.Kit_Number_This_Item_Belongs_To__c);
                    orderIds.add(orderLine.OrderId);
                }
            }
			//SF-5879
            List < OrderItem > getParentLineItem = getFuelPlanItems(kitNumbers, orderIds);
            // PS-5288:SG: Added a Null check on getParentLineItem, as this list vairable is being used in the below SOQL.
            if(!getParentLineItem.isEmpty()){
                List<OrderItem> getExistingOli = [SELECT Id,Kit_Number_This_Item_Belongs_To__c, Line_Comments__c,Product2.Id, Fuel_Plan__c, Selling_Price__c,Line_Item_Type__c, Product2.Name FROM OrderItem WHERE 	Kit_Number_This_Item_Belongs_To__c =:getParentLineItem[0].Product_SKU__c AND OrderId IN:orderIds AND (Product2.Name = 'Fuel Convenience Charge') AND Product2.Stock_class__c='FUEL' WITH SECURITY_ENFORCED];
                hasExistingFlag = !getExistingOli.isEmpty();
                if(!hasExistingFlag){
                for (OrderItem oli: getParentLineItem) {
                    if (oli.Fuel_Plan__c) {
                        oli.Fuel_Plan__c = false;
                        oliToUpdate.add(oli);
                    }
                }
            }
        } 

            if (!oliToUpdate.isEmpty()) {
                SBR_3_0_OrderItemTriggerHandler.beforeUpdateRecursiveCheck = true;
                SBR_3_0_OrderItemTriggerHandler.afterUpdateRecursiveCheck = true;
                SObjectAccessDecision securityDecision = Security.stripInaccessible(AccessType.UPDATABLE, oliToUpdate);
                update securityDecision.getRecords();
            }
        } catch (Exception ex) {
            SBR_3_0_Log.logException(ex);
        } finally {
            SBR_3_0_Log.saveLog();
        }
    }

    /**
     * @description handling complexity in separate method
     * @param orderItems
     * @return map of product from the order line item
     */
    private static Map < Id, Product2 > getProductMap(List < OrderItem > orderItems) {
        Set < Id > productIds = new Set < Id > ();
        for (OrderItem orderLine: orderItems) {
            productIds.add(orderLine.Product2Id);
        }
        return new Map < Id, Product2 > ([SELECT Id, Name FROM Product2 WHERE Id IN: productIds]);
    }

    /**
     * @description handling complexity in separate method
     * @param productName
     * @param kitNumber
     * @return true if product is fuel order line item
     */
    private static boolean isFuelPlanItem(String productName, String kitNumber) {
        return (productName == 'Fuel Convenience Charge') && kitNumber != ''; //SF-5879
    }

    /**
     * @description handling complexity in separate method
     * @param kitNumbers
     * @param orderIds
     * @return order line item of parent line item
     */
    private static List < OrderItem > getFuelPlanItems(Set < String > kitNumbers, Set < String > orderIds) {
        return
            [SELECT
                Id,
                Product_SKU__c,
                Fuel_Plan__c,
                OrderId
             FROM
                OrderItem
             WHERE
                Product_SKU__c IN: kitNumbers
                AND OrderId IN: orderIds
             WITH SECURITY_ENFORCED];
    }

    /**
     * @description Invocable method, called via the order items after insert and order item delete flows, that
     * loops through any orders suspected of needing specific pricing or last order item update -updates.
     */
    @InvocableMethod(label='Update Specific Pricing' description='Update related orders as necessary')
    public static void updateRelatedOrders(List<SBR_3_0_OrderUpdateWrapper> orderUpdateWrappers){
        Map<Id,SBR_3_0_OrderUpdateWrapper> orderUpdateWrapperMap = new Map<Id,SBR_3_0_OrderUpdateWrapper>();

        for(SBR_3_0_OrderUpdateWrapper ouw : orderUpdateWrappers){
            orderUpdateWrapperMap.put(ouw.orderId, ouw);
        }

        Datetime lastOrderItemUpdated = Datetime.now().addHours(2);

        List<Order> ordersToUpdate = new List<Order>();
            
        if(orderUpdateWrapperMap.values().isEmpty()){
            return; 
        }
        
        Set<Id> orderIds = orderUpdateWrapperMap.keySet();
        for(Order orderForUpdate :
            [Select
                 Id,
                 Specific_Pricing_Flag__c,
                 Is_Specific_Pricing_Flag__c,
                 (Select
                      Specific_Pricing_Type__c,
                      Specific_Pricing_Flag__c
                  From
                      OrderItems)
             From
                 Order
             Where
                 Id in :orderIds
             FOR UPDATE]){
                 
             SBR_3_0_OrderUpdateWrapper ouw = orderUpdateWrapperMap.get(orderForUpdate.Id);
                 
             //We may or may not need to update the parent order record if nothing changed.
             //This boolean will tell us whether or the order is required to be updated.
             //It's defaulted to stale order, because if stale order = true, the order should be updated.
             //Later on, we also will OR the boolean with specific pricing criteria to see if the order needs to be updated.
             boolean updateOrderRecord = ouw.staleOrder ?? false;
                 
             if(updateOrderRecord){
                 orderForUpdate.LastOrderItemUpdated__c = lastOrderItemUpdated;
             }
                 
             boolean specificPricingFlag = false;
             boolean isSpecificPricingFlag = false;
             for(OrderItem oi : orderForUpdate.OrderItems){
                 specificPricingFlag |= oi.Specific_Pricing_Flag__c;
                 isSpecificPricingFlag |= (SBR_3_0_Constants.CUSTOMER_LOADED_SPECIFIC_PRICING_TYPE == oi.Specific_Pricing_Type__c);
             }
                 
             //If this order item is "stale", or if the specific pricing flag or is specific pricing flags were "toggled" from false->true or true->false,
             //then we need to update the parent order record.
             updateOrderRecord |=
                 specificPricingFlag != orderForUpdate.Specific_Pricing_Flag__c ||
                 isSpecificPricingFlag != orderForUpdate.Is_Specific_Pricing_Flag__c;
                 
             orderForUpdate.Specific_Pricing_Flag__c = specificPricingFlag;
             orderForUpdate.Is_Specific_Pricing_Flag__c = isSpecificPricingFlag;
                 
             if(updateOrderRecord){
                 ordersToUpdate.add(orderForUpdate);
             }
         }

        if(Schema.sObjectType.Order.isUpdateable()){
            update ordersToUpdate;
        }
    }
}