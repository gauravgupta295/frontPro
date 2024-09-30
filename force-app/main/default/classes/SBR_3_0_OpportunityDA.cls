/*********************************************************************************************************************
* Apex Class: SBR_3_0_OpportunityDA
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Concrete class for Opportunity Data Access
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
1.0         Kunal Patel             2022-07-19          Initial version    
*********************************************************************************************************************/

public with sharing class SBR_3_0_OpportunityDA implements SBR_3_0_OpportunityDAInterface{
    public static List<Opportunity> getOpportunities(){
        return [SELECT ID, Name, Latitude_Longitude__c, StageName, Est_Start_Date__c,
                Street__c, City__c, State__c, Zip_Code__c, Country__c FROM Opportunity ORDER BY Name ASC];
    }
    
    public static Map<Id, Opportunity> getOpportunities(Set<Id> ids) {
        return new Map<Id, Opportunity>([SELECT ID, Name, Latitude_Longitude__c, StageName, Est_Start_Date__c,
                                         Street__c, City__c, State__c, Zip_Code__c, Country__c FROM Opportunity WHERE ID IN: ids ORDER BY Name ASC]);
    }
    
    public static Opportunity getOpportunity(Id id) {
        return [SELECT ID, Name, Latitude_Longitude__c, StageName, Est_Start_Date__c,
                Street__c, City__c, State__c, Zip_Code__c, Country__c FROM Opportunity WHERE ID =: id];
    }
    
    public static List<Opportunity> getOpportunitiesList(Set<Id> ids){
        return [SELECT ID, Latitude_Longitude__Latitude__s, Latitude_Longitude__Longitude__s, Latitude_Longitude_Status__c, 
                Latitude_Longitude_error__c FROM Opportunity WHERE ID IN: ids];
    }
    
    public static List<Opportunity> getOpportunityFiltered(SBR_3_0_GoogleMapCmpController.FilterWrapper wrapper) {
        
        Set<Id> ownerIds = new Set<Id>();
        
        String users = wrapper.userTerritories;
        if(String.isNotBlank(users)) {
            users = users.deleteWhitespace();
            for(String s : users.split(',')) {
                ownerIds.add(s);
            }
        }
        
        List<String> formattedOwnerIds = new List<String>();
        for (Id ownerId : ownerIds) {
            formattedOwnerIds.add('\'' + ownerId + '\'');
        }
        
        String sQuery = 'SELECT ID, Name, Latitude_Longitude__c, StageName, Est_Start_Date__c,'
            + ' Street__c, City__c, State__c, Zip_Code__c, Country__c FROM Opportunity WHERE OwnerId IN '+formattedOwnerIds+' AND ';
        
        if(String.isNotBlank(wrapper.opportunitySearch)) {
            sQuery += '(Name LIKE \'%' + String.escapeSingleQuotes(wrapper.opportunitySearch) + '%\'' 
                + ' OR Account.Name LIKE \'%' + String.escapeSingleQuotes(wrapper.opportunitySearch) + '%\''
                + ' OR Office_Account__r.Name LIKE \'%' + String.escapeSingleQuotes(wrapper.opportunitySearch) + '%\''
                + ' OR Parent_Account__r.Name LIKE \'%' + String.escapeSingleQuotes(wrapper.opportunitySearch) + '%\') AND ';
        }
        
        if(String.isNotBlank(wrapper.opportunityStage)) {
            List<String> oppStageList = (List<String>) JSON.deserialize(wrapper.opportunityStage, List<String>.class);
            Set<String> oppStageSet = new Set<String>(oppStageList);
            if(!oppStageSet.isEmpty() && !oppStageSet.contains('All')) {
                sQuery += 'StageName IN ' + inClausify(oppStageSet) + ' AND ';
            }
        }

        //if(wrapper.openOpportunity == true) {
            sQuery += 'isClosed = false AND ';
        //}
        
        sQuery += '(';

        if(wrapper.closeDateNext30DaysOpportunity == true) {
            sQuery += 'CloseDate = NEXT_N_DAYS:30 OR ';
        }
        
        if(wrapper.closeDateLastXDaysOpportunity == true && String.isNotBlank(wrapper.closeDateLastXDaysOpportunityValue)) {
            sQuery += 'CloseDate = LAST_N_DAYS:' + String.escapeSingleQuotes(wrapper.closeDateLastXDaysOpportunityValue) + ' OR ';
        }
        
        if(wrapper.closeDateNextXDaysOpportunity == true && String.isNotBlank(wrapper.closeDateNextXDaysOpportunityValue)) {
            sQuery += 'CloseDate = NEXT_N_DAYS:' + String.escapeSingleQuotes(wrapper.closeDateNextXDaysOpportunityValue) + ' OR ';
        }
        
        if(wrapper.estDateNext30DaysOpportunity == true) {
            sQuery += 'Est_Start_Date__c = NEXT_N_DAYS:30 OR ';
        }
        
        if(wrapper.estDateLastXDaysOpportunity == true && String.isNotBlank(wrapper.estDateLastXDaysOpportunityValue)) {
            sQuery += 'Est_Start_Date__c = LAST_N_DAYS:' + String.escapeSingleQuotes(wrapper.estDateLastXDaysOpportunityValue) + ' OR ';
        }
        
        if(wrapper.estDateNextXDaysOpportunity == true && String.isNotBlank(wrapper.estDateNextXDaysOpportunityValue)) {
            sQuery += 'Est_Start_Date__c = NEXT_N_DAYS:' + String.escapeSingleQuotes(wrapper.estDateNextXDaysOpportunityValue) + ' OR ';
        }
        
        sQuery += ') AND ';
        System.debug('pre sQuery lead -> ' + sQuery);
        sQuery = sQuery.replaceAll('\\(\\) AND ', '');
        sQuery = sQuery.replaceAll('OR \\)', ')');

        sQuery = sQuery.removeEnd(' WHERE ');
        sQuery = sQuery.removeEnd(' AND ');
        
        sQuery += ' ORDER BY Name ASC';
        System.debug('sQuery -> ' + sQuery);
        
        List<Opportunity> result = Database.query(sQuery);
        
        return result;
    }

    public static String inClausify(Set<String> stringSet) {
        String inClause = String.format( '(\'\'{0}\'\')', 
                             new List<String> { String.join( new List<String>(stringSet) , '\',\'') });
        return inClause;
    }
}