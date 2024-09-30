/*********************************************************************************************************************
* Apex Class: SBR_3_0_FeedItemTriggerHandler
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Class to manage trigger logic for FeedItems (chatter)
* - SAL-2727
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Konrad Haight           2022-04-29          Initial version    
*********************************************************************************************************************/
public without sharing class SBR_3_0_FeedItemTriggerHandler extends SBR_3_0_TriggerHandler  {
    public override void beforeDelete() {
        SBR_3_0_FeedItemOperations.preventFeedItemDeletion(Trigger.old);
    }
}