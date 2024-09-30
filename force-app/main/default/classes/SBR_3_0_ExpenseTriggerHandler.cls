public with sharing class SBR_3_0_ExpenseTriggerHandler extends SBR_3_0_TriggerHandler {

    public override void afterInsert() {
        SBR_3_0_ExpenseOperations.updateQuoteLineForScaffolding(Trigger.new);
    }
    public override void afterUpdate() {
        SBR_3_0_ExpenseOperations.updateQuoteLineForScaffolding(Trigger.new);
    } 
    public override void afterDelete() {
      SBR_3_0_ExpenseOperations.updateQuoteLineForScaffolding(Trigger.old);
  }
}