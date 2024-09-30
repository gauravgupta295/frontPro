/*********************************************************************************************************************
* Apex Trigger : SBR_3_0_ProductServiceCampaignItemTrigger
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Trigger on ProductServiceCampaignItem for before update context
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME           DATE                 DETAIL FEATURES
    1.0         Chhavi Singhal           2023-11-22           Initial version
    2.0         Evan Kuminski            2023-12-19           Now also runs before delete
*********************************************************************************************************************/

trigger SBR_3_0_ProductServiceCampaignItemTrigger on ProductServiceCampaignItem (before update, before delete, after delete) {
	new SBR_3_0_PSCItemTriggerHandler().run();
}