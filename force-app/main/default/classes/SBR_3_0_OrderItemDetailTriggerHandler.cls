/**
 * @description       : Trigger Handler for Order Item Detail Object
 * @author            : Hashem Abdul
 * @group             : 
 * @last modified on  : 02-06-2024
 * @last modified by  : Hashem Abdul
**/
public class SBR_3_0_OrderItemDetailTriggerHandler extends SBR_3_0_TriggerHandler {
    @TestVisible
    private Map<Id, Order_Item_Detail__c> oldMap;
    @TestVisible
    private Map<Id, Order_Item_Detail__c> newMap;

    public static Boolean beforeUpdateRecursiveCheck = false;
    public static Boolean afterUpdateRecursiveCheck = false;
    public static Boolean recursiveCheck = false;
   // public Boolean isExternalUser = FeatureManagement.checkPermission(SBR_3_0_Constants.ACCOUNT_EXTERNAL_USER);

    public SBR_3_0_OrderItemDetailTriggerHandler() {
        this.oldMap = (Map<Id, Order_Item_Detail__c>) Trigger.oldMap;
        this.newMap = (Map<Id, Order_Item_Detail__c>) Trigger.newMap;
    }
    
	public override void afterUpdate() {
		SBR_3_0_OrderItemDetailOperations.updateBulkStatus(this.newMap,this.oldMap);

    }
    public override void afterInsert(){
        SBR_3_0_OrderItemDetailOperations.updateBulkStatusOnInsert(this.newMap);
    }
}