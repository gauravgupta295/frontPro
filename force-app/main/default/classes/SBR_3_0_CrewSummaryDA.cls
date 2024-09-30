public with sharing class SBR_3_0_CrewSummaryDA implements SBR_3_0_CrewSummaryDAInterface {

    public static List<Crew_Summary__c> getCrewSummaryByQuote(Set<Id> quoteIds) {
        return [SELECT Id,Total__c, Quote__c, Task_Type__c, Product_SKU__c, CS_OT_Total__c, CS_ST_Total__c FROM Crew_Summary__c WHERE Quote__c IN: quoteIds];
    }
    public static List<Crew_Summary__c> getCrewSummaryByIds(Set<Id> ides) {
        return [SELECT Id, Record_Count__c FROM Crew_Summary__c WHERE Id IN: ides];
    }

    public static List<Crew_Summary__c> getCrewSummaryForScaffoldingQuotes(Set<Id> quoteIds) {
        return [SELECT Id, Name, Quote__c, Task_Type__c, Quote__r.Analysis_Region_Key__c, Quote__r.Company_Code__c 
            FROM Crew_Summary__c WHERE Quote__c in:quoteIds ];
    }

    public static List<AggregateResult> getCrewSummaryScaffoldingAggregateList(Set<Id> quoteIds) {
        return [SELECT Quote__c,Sum(Total__c) total , Count(Record_Count__c) quantity FROM Crew_Summary__c WHERE Quote__c in: quoteIds GROUP BY Quote__c];
    }
    // SF-8216
    public static List<AggregateResult> getCSTotalsSumMoveAggrList(Set<Id> quoteIds) {
        return [SELECT Quote__c,Sum(Total__c) total , Count(Record_Count__c) quantity FROM Crew_Summary__c WHERE Quote__c in: quoteIds AND Task_Type__c = 'Move' GROUP BY Quote__c];
    }

    public static List<AggregateResult> getCSTotalsSumExceptMoveAggrList(Set<Id> quoteIds) {
        return [SELECT Quote__c,Sum(Total__c) total , Count(Record_Count__c) quantity FROM Crew_Summary__c WHERE Quote__c in: quoteIds AND Task_Type__c <> 'Move' GROUP BY Quote__c];
    }

    public static List<AggregateResult> getCrewSummaryAggregateList(Set<Id> quoteIds) {
        return [SELECT Quote__c,Sum(Total_OT_Cost__c) otCostSum , Sum(Total_ST_Cost__c) stCostSum, Count(Crew_Count_OT__c) otCrewCount, 
            Count(Crew_Count_ST__c) stCrewCount, sum(CS_OT_Total__c) csOtTotalSum, sum(CS_ST_Total__c) csStTotalSum,
            Sum(CS_ST_Average__c) csStAvgSum, Sum(CS_OT_Average__c) csOtAvgSum FROM Crew_Summary__c WHERE Quote__c in: quoteIds GROUP BY Quote__c];
    }
    @AuraEnabled(cacheable=false)
    public static Crew_Summary__c getCrewSummaryByQuoteId(String quoteId) {
        return [SELECT Id,Total__c, Quote__c, Task_Type__c FROM Crew_Summary__c WHERE Quote__c =:quoteId];
    }

    public static List<AggregateResult> getOTCountFromCrewSummaryByQuoteIds(Set<Id> quoteIds) {
        return [SELECT Quote__c Id, Count (OT_Hrs__c) otCountFromCs
                FROM Crew_Summary__c 
                WHERE Quote__c in: quoteIds
                AND OT_Hrs__c > 0
                GROUP BY Quote__c];
    }

    public static List<AggregateResult> getSTCountFromCrewSummaryByQuoteIds(Set<Id> quoteIds) {
        return [SELECT Quote__c Id, Count (ST_Hrs__c) stCountFromCs
                FROM Crew_Summary__c 
                WHERE Quote__c in: quoteIds
                AND ST_Hrs__c > 0
                GROUP BY Quote__c];
    }
}