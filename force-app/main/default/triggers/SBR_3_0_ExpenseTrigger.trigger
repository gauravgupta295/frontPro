trigger SBR_3_0_ExpenseTrigger  on SBR_Expense__c (after insert, after update, after delete) {
    new SBR_3_0_ExpenseTriggerHandler().run();
}