public with sharing class SBR_3_0_QueueableUpdateQuoteTotals implements Queueable, Database.AllowsCallouts {
    private String quoteRecdId;

    public SBR_3_0_QueueableUpdateQuoteTotals(String quoteRecdId) {
        this.quoteRecdId = quoteRecdId;
    }

    public void execute(QueueableContext context) {
        if(quoteRecdId != null){
            SBR_3_0_API_Contract_OpenQuoteTaxUpdate.QuoteWrapper resp =  SBR_3_0_API_Contract_OpenQuoteTaxUpdate.updateQuoteTaxes(quoteRecdId);
           System.debug('Resp from API in SBR_3_0_API_Contract_OpenQuoteTaxUpdate ->'+resp);
        }
    }
}