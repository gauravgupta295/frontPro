/*********************************************************************************************************************
* Apex Class: SBR_3_0_FeedCommentOperations
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Class to manage any business logic that needs to be performed on FeedComments as a result of a trigger
* - Use in conjunction with Block_User_from_Deleting_Chatter_Post_And_Comment_On_Leads custom permission to prevent users from deleting other users' chatter posts on records they do not own.
* - SAL-2727
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Konrad Haight           2022-05-03          Initial version    
*********************************************************************************************************************/
public without sharing class SBR_3_0_FeedCommentOperations {

    private static final String PERMISSION = 'Block_User_from_Deleting_Chatter_Post_And_Comment_On_Leads';
   
    public static void preventFeedCommentDeletion(List<FeedComment> feedList){
            
            
        Boolean userCannotDelete = FeatureManagement.checkPermission(PERMISSION);
            
        if(userCannotDelete){

            Set<Id> leadIds  = new Set<Id>();
                
            for(FeedComment comment:feedList){
                leadIds.add(comment.ParentId);
            }
            
            Map<Id,Lead> parentLeadsMap = new Map<Id,Lead>(SBR_3_0_LeadDA.GetLeadsByIds(leadIds));
                
            if(parentLeadsMap.size() > 0){
                    
                Id userId = UserInfo.getUserId();
                
                for(FeedComment comment:feedList){
                    String ownerId = parentLeadsMap.get(comment.ParentId).OwnerId;
                    if(userId != ownerId && userId != comment.InsertedById){
                        comment.adderror('Comment cannot be deleted');
                    }
                }
            }
        }
    }
}