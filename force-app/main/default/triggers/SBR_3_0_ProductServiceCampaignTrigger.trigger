/*********************************************************************************************************************
* Apex Trigger : SBR_3_0_ProductServiceCampaignTrigger
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Trigger on ProductServiceCampaign for before update context
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME           DATE                 DETAIL FEATURES
    1.0         Chhavi Singhal           2023-11-10           Initial version
	2.0         Chhavi Singhal           2024-06-10           Added before delete context
*********************************************************************************************************************/

trigger SBR_3_0_ProductServiceCampaignTrigger on ProductServiceCampaign (before update, after update, before delete) {
    new SBR_3_0_PSCTriggerHandler().run();
}