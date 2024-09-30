/*********************************************************************************************************************
* Apex Class: SBR_3_0_UserTriggerHandler
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Class to manage trigger logic for User

---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME                        DATE                DETAIL FEATURES
    1.0         Vikram Kayathi                      2023-03-22             Initial version 
*********************************************************************************************************************/

public with sharing class SBR_3_0_UserTriggerHandler extends SBR_3_0_TriggerHandler{

    @TestVisible
    private Map<Id, User> oldUserMap;
    @TestVisible
    private Map<Id, User> newUserMap;
    
    public SBR_3_0_UserTriggerHandler() {
        this.oldUserMap = (Map<Id, User>) Trigger.oldMap;
        this.newUserMap = (Map<Id, User>) Trigger.newMap;
    }
    
    public override void beforeInsert() {
        SBR_3_0_UserOperations.updateBranchLocation(Trigger.new);
        
    }

    public override void afterInsert() { 
        List<Id> userIdList= new List<Id>();

        for(User u: newUserMap.values()) {
            if(u.Department != null) {
                userIdList.add(u.Id);
            }
        }
        if(!userIdList.isEmpty()){
            SBR_3_0_UserOperations.upsertUserLocationObject(userIdList);
        }
       
    }

    public override void afterUpdate() {
        List<Id> userIdList= new List<Id>();
        List<Id> deactivatedRepList = new List<Id>();
        
        for(User u: newUserMap.values()) {
            User oldUser = oldUserMap.get(u.Id);
            if(u.Department != null && u.Department != oldUser.Department) {
                userIdList.add(u.Id);
            }
            if (u.RepID__c != null && u.isActive == false && oldUser.isActive == true)
            {
                deactivatedRepList.add(u.Id);
            }
        }
        if(!userIdList.isEmpty()){
            SBR_3_0_UserOperations.upsertUserLocationObject(userIdList);
        }
        if(!deactivatedRepList.isEmpty()){
            SBR_3_0_UserOperations.deactivateOrRevertAccountRelationships(deactivatedRepList);
        }
    }
        

    public override void beforeUpdate() {
        SBR_3_0_UserOperations.updateBranchLocation(Trigger.new);
        
    }
    
    
}