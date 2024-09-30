trigger SBR_3_0_CommentTrigger on Comment__c (before insert, after insert, after update) {
    //SF-5848
    new SBR_3_0_CommentTriggerHandler().run();
}