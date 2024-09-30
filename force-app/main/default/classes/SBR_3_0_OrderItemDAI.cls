/**
 * @description       : 
 * @author            : Hashem Abdul
 * @group             : 
 * @last modified on  : 01-29-2024
 * @last modified by  : Hashem Abdul
**/
public interface SBR_3_0_OrderItemDAI {
	List<OrderItem> getOrderItem(Set<String> orderItemsIds);
    List<Order_Item_Detail__c> getOrderItemDetails(Set<String> orderItemsDetailIds);
    List<OrderItem> getOrderItemsFromGroupId(Set<String> groupId,Set<Id> orderIds);
    List<OrderItem> getOrderItemsByOrder(Id orderId);
    Map<String, OrderItem> getOrderItemByReservationNumber(String reservationNumber, String companyCode);
    Map<String, OrderItem> getOrderItemByContractNumber(String contractNumber, String companyCode);
    /**
    * @description Get Map of Order Items by passing Ids of Order Item
    * @author Hashem Abdul | 01-29-2024 
    * @param orderItemIds 
    * @return Map<Id, OrderItem> 
    **/
    Map<Id, OrderItem> getOrderItemsMapForUpdate(Set<Id> orderItemIds);
}