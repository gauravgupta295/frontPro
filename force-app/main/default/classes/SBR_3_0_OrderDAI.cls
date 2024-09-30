public interface SBR_3_0_OrderDAI {
	Order getOrder(String orderId);
	Schema.Location getRelatedBranchLocation(String branchNumber, String cc);
	List<Account> getRelatedAccount(String relatedAccountNumber);
    Map<Id, Order> getOrders(Set<Id> ids);  
}