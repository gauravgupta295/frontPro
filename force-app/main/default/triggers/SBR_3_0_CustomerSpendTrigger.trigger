trigger SBR_3_0_CustomerSpendTrigger on Customer_spend__c (after update, after insert, after delete) {
    new SBR_3_0_CustomerSpendTriggerHandler().run();
}