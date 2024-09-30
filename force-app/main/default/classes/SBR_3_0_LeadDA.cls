/*********************************************************************************************************************
* Apex Class: SBR_3_0_LeadDA
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Concrete class for Lead Data Access
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Kunal Patel           2022-02-09            Initial version    
*********************************************************************************************************************/
public with sharing class SBR_3_0_LeadDA implements SBR_3_0_LeadDAInterface {
    public static LeadStatus getLeadStatus(String status) {
        LeadStatus result;
        if(status != null) {
            result = [SELECT Id, MasterLabel, ApiName FROM LeadStatus WHERE ApiName =: status LIMIT 1];
        }
        return result;
    }

    public static List<Lead> getLeads() {
        return [SELECT ID, Name, LeadSource, IsConverted, Status, Account__c, Contact__c,
                    City, Street, State, PostalCode, Address, Phone, Country, Company, Latitude, Longitude FROM Lead ORDER BY Name];
    }

    public static Lead getLead(Id id) {
        return [SELECT ID, Name, LeadSource, IsConverted, Status, Account__c, Contact__c, Job_Address_Street__c,Job_Address_City__c, Job_Address_State__c, Job_Address_Zip_Code__c, Job_Address_Country__c,
        				City, Street, State, PostalCode, Address, Phone, Country, Company, Latitude, Longitude FROM Lead WHERE Id =: id];
	}

    public static Map<Id, Lead> getLeadsMap(Set<Id> leadIds) {
        return new Map<Id, Lead>([SELECT ID, Name, LeadSource, IsConverted, Status, Account__c, Contact__c,
                                    City, Street, State, PostalCode, Address, Phone, Country, Company, Latitude, Longitude FROM Lead WHERE Id IN:leadIds ORDER BY Name]);
    }

    public static List<Lead> getLeadsByIds(Set<Id> leadIds){
        return [SELECT Id, FirstName, LastName, Name, LeadSource, MobilePhone, Email, OwnerId, Status, Activity_Created__c, Activity_Completed__c, 
                City, Street, State, PostalCode, Address, Phone, Country, Company, Title, Latitude, Longitude FROM Lead WHERE Id IN:leadIds ORDER BY Name];
    }

    public static List<Lead> getLeadsLatLongStatus(Set<Id> leadIds){
        return [SELECT ID, Address_LatLong_Status__c FROM Lead WHERE ID in: leadIds ORDER BY Name];
    }

    public static List<Lead> getLeadsFiltered(SBR_3_0_GoogleMapCmpController.FilterWrapper wrapper) {
        
        Set<Id> ownerIds = new Set<Id>();

        String users = wrapper.userTerritories;
        if(String.isNotBlank(users)) {
            users = users.deleteWhitespace();
            for(String s : users.split(',')) {
                ownerIds.add(s);
            }
        }

        String sQuery = 'SELECT ID, Name, LeadSource, IsConverted, Status, Account__c, Contact__c,'
                            + ' City, Street, State, PostalCode, Address, Phone, Country, Company, Latitude, Longitude,'
                            + ' Job_Address_City__c, Job_Address_Street__c, Job_Address_State__c, Job_Address_Zip_Code__c, Job_Address_Country__c FROM Lead WHERE ';
        
        //if(wrapper.openLeads == true) {
            sQuery += 'isConverted = false AND ';
        //}

        sQuery += '(';

        if(wrapper.leadShareLeads == true) {
            sQuery += 'LeadSource = \'Employee Referral\' OR ';
        }

        if(wrapper.campaignLeads == true) {
            sQuery += 'Source_Campaign__c != null';
        }

        sQuery += ') AND ';
        System.debug('pre sQuery lead -> ' + sQuery);
        sQuery = sQuery.replaceAll('\\(\\) AND ', '');
        sQuery = sQuery.replaceAll('OR \\)', ')');

        if(String.isNotBlank(wrapper.campaignType)) {
            sQuery += 'Source_Campaign__r.RecordType.Name = \'' + wrapper.campaignType + '\' AND ';
        } else {
            sQuery += 'Source_Campaign__c = null AND ';
        }
        
        sQuery += 'OwnerId IN ' + inClausify(ownerIds);
        sQuery += ' ORDER BY Name ASC';
        System.debug('sQuery -> ' + sQuery);

        List<Lead> result = Database.query(sQuery);

        return result;
    }

    public static String inClausify(Set<Id> ids) {
        String inClause = String.format( '(\'\'{0}\'\')', 
                             new List<String> { String.join( new List<Id>(ids) , '\',\'') });
        return inClause;
    }
    
}