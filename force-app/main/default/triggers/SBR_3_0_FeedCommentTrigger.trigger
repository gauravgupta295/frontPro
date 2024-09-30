trigger SBR_3_0_FeedCommentTrigger on FeedComment (before delete) {
    new SBR_3_0_FeedCommentTriggerHandler().run();
}