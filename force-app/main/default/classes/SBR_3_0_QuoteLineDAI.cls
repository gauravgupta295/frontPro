public interface SBR_3_0_QuoteLineDAI {
	SBQQ__QuoteLine__c getQuoteLine(String lineId);
	List<SBQQ__QuoteLine__c> getQuoteLines(String quoteId);
	List<SBQQ__QuoteLine__c> getQuoteLineByLineCompositeKey(List<String> lineCompositeKeys);
	List<SBQQ__QuoteLine__c> getQuoteLinesForScaffoldingQuotes(Set<Id> scaffoldingQuotes);
	List<SBQQ__QuoteLine__c> getQuoteLinesForEDLaborQuotes(Set<Id> quoteIds, String chargeType);
}