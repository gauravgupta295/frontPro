trigger SBR_3_0_AccountMngmtChangeReqTrigger on Account_Management_Change_Request__c (after insert, after update, before update, before insert) {
    
    new SBR_3_0_AccMngmtChangeReqTriggerHandler().run();
}