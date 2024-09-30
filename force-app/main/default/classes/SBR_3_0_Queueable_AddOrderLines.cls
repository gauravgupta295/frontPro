/*********************************************************************************************************************
* Apex Class: SBR_3_0_Queueable_AddOrderLines
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Add extra lines if a lineitem being added to the Order is serialized asset and has qunatity greater than 1
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME                        DATE                DETAIL FEATURES
    1.0         Viren Patel                         2022-11-16              Initial version   
	2.0			Aditee Churiwala                    2022-11-18				Moving SOQL
*********************************************************************************************************************/
public with sharing class SBR_3_0_Queueable_AddOrderLines implements Queueable {
    
    public List<OrderItem> orderItems;

    public SBR_3_0_Queueable_AddOrderLines(Set<String> orderItemsIds) {


        this.orderItems = new List<OrderItem>();
        this.orderItems = SBR_3_0_OrderItemDA.getOrderItem(orderItemsIds);
    }

    public void execute(QueueableContext context) {
        splitSerializedAssetsIntoSeparateLines();




    }

    private void splitSerializedAssetsIntoSeparateLines() {
        //when a serialized asset has a quantity greater than 1, split them into individual lines
        Set<String> serializedProducts = getSerializedInfo(orderItems);
        List<OrderItem> lineItemsToUpsert = new List<OrderItem>();
        SBR_3_0_OrderItemTriggerHandler.beforeUpdateRecursiveCheck = true;
        SBR_3_0_OrderItemTriggerHandler.afterUpdateRecursiveCheck = true;


        for(OrderItem oi : orderItems) {
            if(
                oi.Quantity != null 
                && oi.Quantity > 1 
                && serializedProducts.contains(oi.Product2Id)
                //&& String.IsBlank(oi.groupId__c)
            )
            {
                System.debug('\n conditions true');
                // if quantity is greather > 1 for a serialized Product,
                // 1. Update the main line item's quantity to 1 
                // 2. Insert (quantity - 1) line items records
                // 3. The groupId__c of all these records is the SF Line# to identify that they belong this group
				
                Integer i = Integer.valueOf(oi.Quantity);
                oi.groupId__c = oi.OrderItemNumber;
                oi.SBQQ__OrderedQuantity__c =  oi.Quantity;
                oi.Quantity = 1;
                lineItemsToUpsert.add(oi);
                
                List<String> fieldNotToQuery = new List<String>{'OwnerId'};
                OrderItem cloned = new OrderItem();
                Schema.SObjectType objectTypeOrderItem = OrderItem.sObjectType;                

                for(integer qty = 0; qty < i - 1 ; qty ++) {
					List<sObject> cloneOrderItemList = SBR_3_0_CloneUtility.cloneObjects(new List<Sobject>{oi}, objectTypeOrderItem, 'Id', fieldNotToQuery, false);
                    for(sObject cloneOi : cloneOrderItemList) {
                            cloned = (OrderItem)cloneOi;
                            //Id quoteCloneId = (Id)cloned.Id;
                            cloned.groupID__c = oi.OrderItemNumber;
                            cloned.Quantity = 1;
                            cloned.Id = null;
                            lineItemsToUpsert.add(cloned);
                    }    
                   /* OrderItem oiClone  = oi.clone(false, true, false, false);
                    oiClone.Quantity = 1;
                    oiClone.groupID__c = oi.OrderItemNumber;*/
                    
                }
            }
        }


        if(lineItemsToUpsert.size()>0) {
            upsert lineItemsToUpsert;
        }

        List<OrderItem> oItems = [SELECT Id, Product2.name FROM OrderItem WHERE OrderId = :orderItems[0].OrderId];
    }

    private Set<String> getSerializedInfo(List<OrderItem> orderItems) {
        //returns Set of ids which has isSerialized=true from Product2
        Set<String> serializedProducts = new Set<String> ();

        //get Ids
        Set<String> productIds = new Set<String>();
        for(OrderItem oi: orderItems) {
            productIds.add(oi.Product2Id);
        }

        //get Serialized info for Product Ids
        Map<String, Product2> productsMap = SBR_3_0_ProductDA.getProductsById(productIds);
        if(productsMap != null) {
            for(Product2 p : productsMap.values()) {
                if(String.IsBlank(p.Stock_class__c) && !p.Bulk_Item__c && p.Status__c == 'A') {
                    serializedProducts.add(p.Id);
                }
            }
        }

        return serializedProducts;
    }
}