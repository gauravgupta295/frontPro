public with sharing class SBR_3_0_CommentTriggerHandler extends SBR_3_0_TriggerHandler {

    @TestVisible
    private Map<Id, Comment__c> oldCommentMap;
    @TestVisible
    private Map<Id, Comment__c> newCommentMap;
    
    Boolean isIntegrationUser = FeatureManagement.checkPermission(SBR_3_0_Constants.ACCOUNT_EXTERNAL_USER);
    Boolean isDataMigrationUser = FeatureManagement.checkPermission(SBR_3_0_Constants.DATA_MIGRATION_USER);

    public SBR_3_0_CommentTriggerHandler() {
        this.oldCommentMap = (Map<Id, Comment__c>) Trigger.oldMap;
        this.newCommentMap = (Map<Id, Comment__c>) Trigger.newMap;
    }
    
    public override void beforeInsert() {
        SBR_3_0_CommentOperations.setCommentFields(trigger.new, (isIntegrationUser || isDataMigrationUser));
    }
    
    public override void afterInsert() { 
        //SF-5848
        SBR_3_0_CommentOperations.publishComment(this.newCommentMap);
    }

    public override void afterUpdate() {
        //SF-5848
        SBR_3_0_CommentOperations.publishComment(this.newCommentMap);
    }
}