/*********************************************************************************************************************
* Apex Class: SBR_3_0_FeedCommentTriggerHandler
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Class to manage trigger logic for FeedComments (chatter)
* - SAL-2727
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Konrad Haight           2022-05-03          Initial version    
*********************************************************************************************************************/
public without sharing class SBR_3_0_FeedCommentTriggerHandler extends SBR_3_0_TriggerHandler  {
    public override void beforeDelete() {
        SBR_3_0_FeedCommentOperations.preventFeedCommentDeletion(Trigger.old);
    }
}