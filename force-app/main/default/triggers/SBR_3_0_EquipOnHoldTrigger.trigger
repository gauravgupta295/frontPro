/*********************************************************************************************************************
* Apex Class: SBR_3_0_EquipOnHoldTrigger
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - SAL - 9546 - Update Contract Order Applied field on Equipment on Hold Record
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME                      DATE                 DETAIL FEATURES
    1.0         Ritesh Mohapatra                   2022-11-17           Initial version    
*********************************************************************************************************************/
trigger SBR_3_0_EquipOnHoldTrigger on Equipment_on_Hold__c (before update) {
    new SBR_3_0_EquipOnHoldTriggerHandler().run();
}