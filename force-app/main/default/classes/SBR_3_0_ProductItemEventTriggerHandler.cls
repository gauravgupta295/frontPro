/**************************************************************************
* Apex Class: SBR_3_0_ProductItemEventTriggerHandler
---------------------------------------------------------------------------
* Purpose/Methods:
* @description Class created to check the after insert actions for product 
               items platform event.
---------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME      DATE        DETAIL FEATURES
    1.0         Shilpa Mitra        2024-02-22  Initial version(PS-4644)
***************************************************************************/
public with sharing class SBR_3_0_ProductItemEventTriggerHandler extends SBR_3_0_TriggerHandler {
    @TestVisible
    private Map<Id, SBR_3_0_Product_Item__e> newProductItemEventMap;
    
    /**
     * @description constructor used to initialize the context variable
     */
    public SBR_3_0_ProductItemEventTriggerHandler() {
        this.newProductItemEventMap = (Map<Id, SBR_3_0_Product_Item__e>) Trigger.newMap;
    }

    public override void afterInsert() {
        SBR_3_0_ProductItemEventOperations.updateProductItems(this.newProductItemEventMap);
    }
}