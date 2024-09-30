/*********************************************************************************************************************
* Apex Class: SBR_3_0_CrewDAInterface
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Interface class for Crew Data Access
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Kunal Patel           2022-12-19            Initial version    
*********************************************************************************************************************/
public interface SBR_3_0_CrewDAInterface {
    List<Crew__c> getQuotesCrew(Id quoteId);
    List<Crew__c> getQuotesCrewRefresh(Id quoteId);
    List<Crew__c> getCrewsForQuotes(Id quoteId, List<String> tasktypes);
    List<Crew__c> getCrews(List<Id> crewIds);
}