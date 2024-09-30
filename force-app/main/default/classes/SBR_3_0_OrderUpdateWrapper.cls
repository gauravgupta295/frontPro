/**
 * @description Class for the order update invocable method,
 * that is called via the after insert/update and delete flows on OrderItem.
 * if the order is "stale" the staleOrder attribute will be true.
 * Also contains the id of the order record, which will be queried using FOR UPDATe
 * to determine if the order's specific pricing flag(s) need to be updated.
 */
public class SBR_3_0_OrderUpdateWrapper{
    @AuraEnabled @InvocableVariable(label='Order Id' description='Id of the order record to update' required=true) public Id orderId;
    @AuraEnabled @InvocableVariable(label='Stale Order' description='If true, the order is considered stale.' required=false) public boolean staleOrder;
}