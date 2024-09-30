trigger SBR_3_0_FeedItemTrigger on FeedItem (before delete) {
    new SBR_3_0_FeedItemTriggerHandler().run();
}