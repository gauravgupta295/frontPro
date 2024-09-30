/*********************************************************************************************************************
* Apex Class:   
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* @description Class to intercept OrderItem Creation 
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME                      DATE                 DETAIL FEATURES
1.0         Viren Patel                      2022-11-16            Initial version - Split serialized items into multiple if qty > 1 
*********************************************************************************************************************/
public with sharing class SBR_3_0_OrderItemTriggerHandler extends SBR_3_0_TriggerHandler {

    public static Boolean beforeUpdateRecursiveCheck = false;
    public static Boolean afterUpdateRecursiveCheck = false;
    //public Boolean isExternalUser = FeatureManagement.checkPermission(SBR_3_0_Constants.ACCOUNT_EXTERNAL_USER);

    public SBR_3_0_OrderItemTriggerHandler(){}

    public override void beforeInsert() {
    SBR_3_0_OrderItemOperations.updateFuelPlanLineItemsFromRentalMan(Trigger.New);
    }
    public override void beforeUpdate() {
        if(!SBR_3_0_OrderItemTriggerHandler.beforeUpdateRecursiveCheck) {
            //This is still used by the order item operations class...
            SBR_3_0_OrderItemOperations.updateFuelPlanLineItemsFromRentalMan(Trigger.New);
            SBR_3_0_OrderItemTriggerHandler.beforeUpdateRecursiveCheck = true;
            
        }
    }

    /**
     * @description order item after update logic.  Most of this has been moved to the order item after insert flow.
     */
    public override void afterUpdate() {
        // SAL-12631 - Hashem Abdul - 01-24-2023
        if(!SBR_3_0_OrderItemTriggerHandler.afterUpdateRecursiveCheck){
            //SF-5291,SF-5292
            SBR_3_0_OrderItemOperations.removeChildFuelPlanIfParentUnchecked(Trigger.New, Trigger.oldMap);
            SBR_3_0_OrderItemTriggerHandler.afterUpdateRecursiveCheck = true;
        }        
    }
    
    /**
     * @description handles after deletion logic for order items (logic that isnt already in the order item delete flow)
     * SF-5291,SF-5292
     */
    public override void afterDelete() {
       SBR_3_0_OrderItemOperations.uncheckFuelPlanCheckBox((List<OrderItem>)Trigger.old);
    }
}