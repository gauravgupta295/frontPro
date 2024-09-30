/*********************************************************************************************************************
* Apex Class: SBR_3_0_CrewSummaryDAInterface
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Interface class for Crew Summary Data access
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Konrad Haight           2022-12-16            Initial version    
*********************************************************************************************************************/

public interface SBR_3_0_CrewSummaryDAInterface {
    List<Crew_Summary__c> getCrewSummaryByQuote(Set<Id> quoteIds);
    List<Crew_Summary__c> getCrewSummaryByIds(Set<Id> ides);
    List<Crew_Summary__c> getCrewSummaryForScaffoldingQuotes(Set<Id> quoteIds);
    List<AggregateResult> getCrewSummaryScaffoldingAggregateList(Set<Id> quoteIds);
    List<AggregateResult> getCrewSummaryAggregateList(Set<Id> quoteIds);
    Crew_Summary__c getCrewSummaryByQuoteId(String quoteId);
}