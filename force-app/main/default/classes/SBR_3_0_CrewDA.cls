/*********************************************************************************************************************
* Apex Class: SBR_3_0_CrewDA
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Data Access class for Crew records
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Kunal Patel          2022-12-7              Initial version    
*********************************************************************************************************************/

public with sharing class SBR_3_0_CrewDA implements SBR_3_0_CrewDAInterface {

    @AuraEnabled(cacheable=true)
    public static List<Crew__c> getQuotesCrew(Id quoteId) {
        return [SELECT Id, Name, Task__c, Crew__c, Shift__c, Standard_Hours__c,
            Rate_Standard__c, Overtime_Hours__c, Rate_Overtime__c,Total_Hours__c FROM Crew__c WHERE Quote__c =: quoteId]; 
    }

    @AuraEnabled(cacheable=false)
    public static List<Crew__c> getQuotesCrewRefresh(Id quoteId) {
        return [SELECT Id, Name, Task__c, Crew__c, Shift__c, Standard_Hours__c,
            Rate_Standard__c, Overtime_Hours__c, Rate_Overtime__c,Total_Hours__c FROM Crew__c WHERE Quote__c =: quoteId]; 
    }

    public static List<Crew__c> getCrewsForQuotes(Id quoteId, List<String> tasktypes ) {
        return [SELECT Id, Name, Task__c, Crew__c, Shift__c, Standard_Hours__c,Standard_Cost__c,Overtime_Cost__c,
            Rate_Standard__c, Overtime_Hours__c, Rate_Overtime__c FROM Crew__c WHERE Quote__c =: quoteId AND Task__c IN: tasktypes ] ; 
    }

    public static List<Crew__c> getCrews(List<Id> crewIds) {
        return [SELECT Id, Name, Task__c, Crew__c, Shift__c, Standard_Hours__c,Standard_Cost__c, Overtime_Cost__c,
            Rate_Standard__c, Overtime_Hours__c, Rate_Overtime__c FROM Crew__c WHERE Id IN: crewIds]; 
    }

    
    @AuraEnabled(cacheable=false)
    public static void updateCrewRecord(List<Sobject> records) {
        SBR_3_0_Log.setRelatedRecordId(records[0].Id);
        try{
            update records;
        }
        catch(Exception ex){
            System.debug(ex.getMessage());
            SBR_3_0_Log.logException(ex);
            throw new AuraHandledException(ex.getMessage());
        }
    }

}