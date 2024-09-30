/**************************************************************************
* Apex Trigger: SBR_3_0_ProductItemTrigger
---------------------------------------------------------------------------
* Purpose/Methods:
* @description Trigger used to check insert & update actions
---------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME      DATE        DETAIL FEATURES
    1.0         								Initial version
    2.0         Shilpa Mitra        2024-02-27  Added before event as part 
												of PS-4644
***************************************************************************/
trigger SBR_3_0_ProductItemTrigger on ProductItem (after insert, after update,before insert) {
    new SBR_3_0_ProductItemTriggerHandler().run();
}