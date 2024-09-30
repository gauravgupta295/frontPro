trigger SBR_3_0_QuoteLineTrigger on SBQQ__QuoteLine__c (before insert,before update, after update, after insert, before delete,after delete) {
    new SBR_3_0_QuoteLineTriggerHandler().run();
}