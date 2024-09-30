public interface SBR_3_0_QuoteDAI {
    SBQQ__Quote__c getQuote(String quoteId);
    Map<Id, SBQQ__Quote__c> getQuotes(Set<Id> ids);
    Id getRecordTypeId(String recordTypeDevName);
    List<SBQQ__Quote__c> getScaffoldingQuotes(Set<Id> quoteIds);
}