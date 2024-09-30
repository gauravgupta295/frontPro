/*********************************************************************************************************************
* Apex Trigger: SBR_3_0_ProductItemEventTrigger
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Trigger to check ProductItem Platform Event After Insert actions
* - PS-4644 - Created part of duplicate issue
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME                      DATE                 DETAIL FEATURES
    1.0         Shilpa Mitra                      2024-02-22             Initial version
*********************************************************************************************************************/
trigger SBR_3_0_ProductItemEventTrigger on SBR_3_0_Product_Item__e (after insert) {
    new SBR_3_0_ProductItemEventTriggerHandler().run();
}