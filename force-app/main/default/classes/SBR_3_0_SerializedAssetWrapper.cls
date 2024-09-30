/**
 * @description Invocable Apex Defined Type / Wrapper for assisting with splitting serialized assets out.
 */
public class SBR_3_0_SerializedAssetWrapper {

    public Decimal quantity {get; private set;}
    
    //E.g. the order item where OrderItem == GroupId
    public OrderItem rootOrderItem {get; set;}
    
    public List<OrderItem> orderLineItems {get; private set;}
    
    /**
     * @description Default constructor.
     * Initializes the quantity value as well as the pseudo private order line items list.
     */
    public SBR_3_0_SerializedAssetWrapper(){
        this.quantity = 0;
        this.orderLineItems = new List<OrderItem>();
    }
    
    /**
     * @description Adds an order line item to the wrapper's list.
     * @param oi The order item to add.
     */
    public void addLineItem(OrderItem oi){
        this.orderLineItems.add(oi);
    }
    
    /**
     * @description Increments the current wrapper's quantity by the specified decimal value.
     * @param quantity - The decimal to increment the quantity by
     */
    public void addQuantity(Decimal quantity){
        this.quantity += quantity;
    }
    
    @InvocableMethod(
        label='Update Serialized Asset Quantities by Group Id'
        description='Iterate through serialized asset line items by group id, and figure out how many items need to be deleted or cloned so that order items have a singular quantity.'
    )
    public static List<Decimal> updateQuantitiesByGroupId(List<OrderItem> orderItem){
        
        Map<String,SBR_3_0_SerializedAssetWrapper> groupIdWrappers = new Map<String,SBR_3_0_SerializedAssetWrapper>();
        
        Set<Id> orderIds = new Set<Id>();
        Set<Id> orderItemIds = new Set<Id>();
        
        for(OrderItem oi : orderItem){
            String groupId = oi.groupID__C ?? oi.OrderItemNumber;
            orderIds.add(oi.OrderId);
            groupIdWrappers.put(groupId, new SBR_3_0_SerializedAssetWrapper());
        }

        if(groupIdwrappers.values().isEmpty()){
            return new List<Decimal>();
        }
        
        Set<String> groupIds = groupIdWrappers.keySet();

        for(OrderItem oi : 
            [Select 
                Id,
                OrderId,
                OrderItemNumber,
                Quantity,
                groupID__c,
                Num_Serialized_Items_To_Add__c
             From 
                 OrderItem 
             Where 
                 (groupID__c in :groupIds OR OrderItemNumber in: groupIds)
                 And OrderId in :orderIds]){
            String groupId = oi.groupID__C ?? oi.OrderItemNumber;
            
            SBR_3_0_SerializedAssetWrapper giw = groupIdWrappers.get(groupId);
                
            giw.addLineItem(oi);
            if(groupId == oi.OrderItemNumber){
                giw.rootOrderItem = oi;


            }
                 
            giw.addQuantity(oi.Num_Serialized_Items_To_Add__c ?? 0);
        }
        
        List<OrderItem> orderItemsToDelete = new List<OrderItem>();
        Map<Id,OrderItem> orderItemsToUpdate = new Map<Id,OrderItem>();
        
        for(SBR_3_0_SerializedAssetWrapper giw : groupIdWrappers.values()){
                for(OrderItem oi : giw.orderLineItems){
                    //If a child of the root has an updated qty of 0, then delete it.
                    if((oi.Quantity ?? 0) == 0 || (oi.Num_Serialized_Items_To_Add__c ?? 0) == 0){
                        orderItemsToDelete.add(oi);
                    }else if((oi.Num_Serialized_Items_To_Add__c ?? 0) > 0){
                        //Reset the num serialized items to add fiel back to zero, which tells this class and the 
                        //assocaited after insert/update flow to clone items.
                        oi.Num_Serialized_Items_To_Add__c = 0;
                        oi.groupID__C = oi.groupID__C ?? oi.OrderItemNumber;
                        orderItemsToUpdate.put(oi.Id, oi);
                    }
                }
        
             //If the main / root order item (e.g. where OrderItem is the same as groupId__c),
            //Is set to a quantity of zero, then delete all of the groupid order items.
            if (giw.rootOrderItem != null && giw.rootOrderItem.Quantity == 0){
                orderItemsToDelete.add(giw.rootOrderItem);
                orderItemsToDelete.addAll(giw.orderLineItems);
            }
        }
        
        //Updates any order items where QTY was recently added.
        update orderItemsToUpdate.values();
        
        //delete any order items where qty = 0
        delete orderItemsToDelete;
     
        //Loop through the originally passed in list, and IN ORDER, return each
        //order item's number of assets that NEED TO BE CLONED.
        //The order is important, it allows the flow to operate in bulk records.
        List<Decimal> quantitiesToReturn = new List<Decimal>();
        for(OrderItem oi : orderItem){
            String groupId = oi.groupID__c ?? oi.OrderItemNumber;
            SBR_3_0_SerializedAssetWrapper giw = groupIdWrappers.get(groupId);
            quantitiesToReturn.add(giw?.quantity);
        }
            
        return quantitiesToReturn;
    }
}