trigger SBR_3_0_AccountRelationshipTrigger on Account_Relationship__c (after insert, after update, before update, before insert) {
    new SBR_3_0_AccountRelationshipTH().run();
}