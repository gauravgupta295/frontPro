/**
 * @description       : Order Item Data Access Class
 * @group             : 
 * @last modified on  : 02-06-2024
 * @last modified by  : Hashem Abdul
**/
public class SBR_3_0_OrderItemDA implements SBR_3_0_OrderItemDAI{

    /**
    * @description Get List of Order Items using Order Item Ids
    * @param orderItemsIds 
    * @return List<OrderItem> 
    **/
    public static List<OrderItem> getOrderItem(Set<String> orderItemsIds) {
        return [ SELECT ID,  SBQQ__Asset__c, Order_Item_Detail__c, OrderItemNumber, OrderId, PricebookEntryId, UnitPrice, Product2Id, Quantity, Order.Account.Company_Code__c,
                SBQQ__OrderedQuantity__c, groupId__c, Is_Bulk_Item__c, Order.Sourcing_Branch__c, Order.Sourcing_Branch__r.Time_Zone_Id__c, Product2.Product_SKU__c,Order.Company_Code__c,
                Order.Branch__c, Order.Branch__r.Time_Zone_Id__c, Order.Contract_Order_Number__c, Global_Line_Number__c,Product2.Bulk_Item__c,Product2.IsSerialized,Status_Pick_Created_Qty__c 
                FROM OrderItem 
                WHERE Id in: orderItemsIds ];
    }

        /**
        * @description Get List of Order Item Details using Order Item Details Ids
        * @param orderItemsDetailIds 
        * @return List<Order_Item_Detail__c> 
        **/
        public static List<Order_Item_Detail__c> getOrderItemDetails(Set<String> orderItemsDetailIds) {
        return [ SELECT ID,  Pickup_Ticket__c, Created_Qty__c, Line_Item__r.OrderItemNumber, Line_Item__r.Product2.Product_SKU__c, Order_Item_Comments__c,
                 Service_Requested_Date__c, Pickup_Requested_Date__c, Reason_Code__c, Line_Item__r.Order.Sourcing_Branch__r.Time_Zone_Id__c,Line_Item__r.Order.Branch__r.Time_Zone_Id__c,
                 Pickup_Ticket_Request_By__c,  Quantity__c, Line_Item__r.Product2.itemNumberUsedByReservationsRentalOut__c,
                 Line_Item__r.Order.Contract_Order_Number__c, Line_Item__r.Order.Account.Company_Code__c, Line_Item__r.Quantity, Asset_Number__r.Name
                FROM Order_Item_Detail__c 
                WHERE Id in: orderItemsDetailIds ];
    }

        /**
        * @description Get List of Order Items using Group Id
        * @param groupId 
        * @param orderIds 
        * @return List<OrderItem> 
        **/
        public static List<OrderItem> getOrderItemsFromGroupId(Set<String> groupId, Set<Id> orderIds) {
                if(!orderIds.isEmpty()){
                        return [SELECT Id, groupId__c,OrderId, OrderItemNumber, Apply_Standby_Rates__c, Contingency_Cost__c, Daily_Rate__c, 
                        Line_Item_Notes__c, Min_Rate__c, Monthly_Rate__c, Seasonal_Multiplier__c, Shift_Differential__c, Weekly_Rate__c, Quantity,
                        Order.Branch__r.Analysis_Region_Key__c
                        FROM OrderItem WHERE groupId__c IN :groupId and OrderId In:orderIds ];
                }
                else{
                        return [SELECT Id, groupId__c,OrderId, OrderItemNumber, Apply_Standby_Rates__c, Contingency_Cost__c, Daily_Rate__c, 
                        Line_Item_Notes__c, Min_Rate__c, Monthly_Rate__c, Seasonal_Multiplier__c, Shift_Differential__c, Weekly_Rate__c, Quantity,
                        Order.Branch__r.Analysis_Region_Key__c
                        FROM OrderItem WHERE groupId__c IN :groupId];
                }
        }

        
        /**
        * @description SAL-25119, SF-5291, SF-5292
        * @param orderId 
        * @return List<OrderItem> 
        **/
        public static List<OrderItem> getOrderItemsByOrder(Id orderId) {
                return [SELECT id, Quantity__c, Quantity, Product2Id,Kit_Number_This_Item_Belongs_to__c, Product_SKU__c, Item_Number__c, Hourly_Rate__c, Daily_Rate__c, Weekly_Rate__c, Monthly_Rate__c,is_User_Added__c,
                        Min_Rate__c, OrderItemNumber, Contract_Line_Number__c, Product2.Product_SKU__c, Product2.Category__c, Product2.Class__c, 
                        Product2.ToolFlex__c, Product2.Product_Type__c, Product2.Stock_Class__c, Product2.Item_Number__c , Product2.Name,is_Forced_Item__c
                        FROM OrderItem WHERE OrderId =: orderId];
        }

        /**
        * @description Get Order Items by Reservation Number and Company Code
        * @param reservationNumber 
        * @param companyCode 
        * @return Map<String, OrderItem> 
        **/
        public static Map<String, OrderItem> getOrderItemByReservationNumber(String reservationNumber, String companyCode){
                Map<String, OrderItem> OrderItemMap = new Map<String, OrderItem>();
                List<OrderItem> OrderItemsList = [Select Id ,Line_Composite_Key__c, Product2Id, PricebookEntryId, 
                        Product2.Product_SKU__c, Selling_Price__c, Global_Line_Number__c, Line_Item_Type__c,Total_Price__c
                        FROM OrderItem 
                        WHERE Order.Reservation_Order_Number__c =: reservationNumber
                        AND Order.Company_Code__c = :companyCode];
                for (OrderItem oi: OrderItemsList){
                        if(oi.Line_Composite_Key__c !=null ){
                                OrderItemMap.put(oi.Line_Composite_Key__c, oi);
                        }else{
                                OrderItemMap.put(oi.Id, oi); //23832
                        }
                }
                return OrderItemMap;
        }

        /**
        * @description Get Order Items by using Contract Number and Company Code
        * @param contractNumber 
        * @param companyCode 
        * @return Map<String, OrderItem> 
        **/
        public static Map<String, OrderItem> getOrderItemByContractNumber(String contractNumber, String companyCode){
                Map<String, OrderItem> OrderItemMap = new Map<String, OrderItem>();
                List<OrderItem> OrderItemsList = [Select Id ,Line_Composite_Key__c, Product2Id, 
                        PricebookEntryId, Product2.Product_SKU__c, OrderId, Selling_Price__c, Product2.Bulk_Item__c, 
                        Global_Line_Number__c, Total_Price__c, Line_Item_Type__c
                        FROM OrderItem 
                        WHERE Order.Contract_Order_Number__c =: contractNumber 
                        AND Order.Company_Code__c = :companyCode];
                for (OrderItem oi: OrderItemsList){
                       if(oi.Line_Composite_Key__c !=null ){
                                OrderItemMap.put(oi.Line_Composite_Key__c, oi);
                        }else{
                                OrderItemMap.put(oi.Id, oi); //23832
                        }
                }
                return OrderItemMap;
        }

        
        /**
        * @description SF-5865
        * @author Hashem Abdul | 01-29-2024 
        * @param assetIds 
        * @return List<OrderItem> 
        **/
        public static List<OrderItem> getOrderItemsByAssetIds(Set<Id> assetIds){
                return [SELECT Id, groupId__c, OrderItemNumber, SBQQ__Asset__c
                        FROM OrderItem WHERE SBQQ__Asset__c IN :assetIds];
        }

        
        /**
        * @description Get Map of Order Items by passing Ids of Order Item
        * @author Hashem Abdul | 01-29-2024 
        * @param orderItemIds 
        * @return Map<Id, OrderItem> 
        **/
        public static Map<Id, OrderItem> getOrderItemsMapForUpdate(Set<Id> orderItemIds){
                Map<Id, OrderItem> orderItemsForUpdate = new Map<Id, OrderItem>(
                [SELECT ID, Status_Pick_Created_Qty__c FROM OrderItem WHERE Id in: orderItemIds FOR UPDATE]);

                return orderItemsForUpdate;
        }
}