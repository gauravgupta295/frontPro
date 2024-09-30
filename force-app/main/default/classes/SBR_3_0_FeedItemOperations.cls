/*********************************************************************************************************************
* Apex Class: SBR_3_0_FeedItemOperations
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Class to manage any business logic that needs to be performed on FeedItems as a result of a trigger
* - Use in conjunction with Block_User_from_Deleting_Chatter_Post custom permission to prevent users from deleting other users' chatter posts on records they do not own.
* - SAL-2727
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Konrad Haight           2022-04-29          Initial version    
*********************************************************************************************************************/
public without sharing class SBR_3_0_FeedItemOperations {

    private static final String PERMISSION = 'Block_User_from_Deleting_Chatter_Post_And_Comment_On_Leads';
   
    public static void preventFeedItemDeletion(List<FeedItem> feedList){
            
            
        Boolean userCannotDelete = FeatureManagement.checkPermission(PERMISSION);
            
        if(userCannotDelete){

            Set<Id> leadIds  = new Set<Id>();
                
            for(FeedItem item:feedList){
                leadIds.add(item.ParentId);
            }
            
            Map<Id,Lead> parentLeadsMap = new Map<Id,Lead>(SBR_3_0_LeadDA.GetLeadsByIds(leadIds));
                
            if(parentLeadsMap.size() > 0){
                    
                Id userId = UserInfo.getUserId();
                
                for(FeedItem item:feedList){
                    String ownerId = parentLeadsMap.get(item.ParentId).OwnerId;
                    if(userId != ownerId && userId != item.InsertedById){
                        item.adderror('Item cannot be deleted');
                    }
                }
            }
        }
    }
}