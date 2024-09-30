/*********************************************************************************************************************
* Apex Class: SBR_3_0_JobsiteDA
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Concrete class for Jobsite Data Access
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Kunal Patel           2022-05-04            Initial version    
    1.2         Viren Patel           2022-09-06            Added getRelatedAccount, getRelatedJobLocation, getRelatedBranchLocation
    1.3         Viren Patel           2022-10-15            Update location queries to filter by record type. Also, updated the code so that if Account does not exist, the call fails 
*********************************************************************************************************************/
public with sharing class SBR_3_0_JobsiteDA implements SBR_3_0_JobsiteDAInterface {
    public static final String JOBSITEACCOUNTNAME = 'Job Site Placeholder Account';

    public static List<AssociatedLocation> getJobsitesByAccounts(Set<Id> accIds) {
        return [
            SELECT Id, JobsiteName__c, Latitude_Longitude__c, Street_Address__c, City__c, State__c, Country__c, Zip_Code__c, ParentRecordId
            FROM AssociatedLocation
            WHERE ParentRecordId IN :accIds
            ORDER BY JobsiteName__c
        ];
    }

    public static AssociatedLocation getJobSiteByJobSiteId(String jobsiteExternalId) {
        return [SELECT Id, Job_Site_Id__c, LocationId, Company_Code__c FROM AssociatedLocation WHERE Job_Site_Id__c = :jobsiteExternalId LIMIT 1];
    }

    public static List<AssociatedLocation> getJobSitesByJobSiteId(String jobsiteExternalId) {
        return [SELECT Id, Job_Site_Id__c, LocationId, Company_Code__c FROM AssociatedLocation WHERE Job_Site_Id__c = :jobsiteExternalId LIMIT 1];
    }

    public static List<AssociatedLocation> getJobsiteByName(String jobsiteName) {
        return [SELECT JobsiteName__c FROM AssociatedLocation WHERE JobsiteName__c = :jobsiteName];
    }

    public static List<AssociatedLocation> getJobsiteByJobNumber(Set<String> jobNumbers) {
        return [SELECT Job_Number__c FROM AssociatedLocation WHERE Job_Number__c IN :jobNumbers];
    }

    public static Account getRelatedAccount(String rmAccountNumber) {
        Account relAcct;
        List<Account> relAccts = [
            SELECT ID, Name, RM_Account_Number__c
            FROM Account
            WHERE RM_Account_Number__c = :rmAccountNumber
            LIMIT 1
        ];
        if (relAccts.size() > 0) {
            relAcct = relAccts[0];
        }
        return relAcct;
    }

    public static Schema.Location getRelatedJobLocation(String jobsiteExternalId) {
        //gets the locations related to the jobsite
        List<Schema.Location> locations = new List<Schema.Location>();
        locations = [
            SELECT Id, Name, Street_Address__c, Street_Address_2__c, City__c, Zip_Code__c, State__c, Country__c, Latitude_Longitude__c
            FROM Location
            WHERE Id IN (SELECT LocationId FROM AssociatedLocation WHERE Job_Site_Id__c = :jobsiteExternalId)
            LIMIT 1
        ];
        if (locations.size() > 0) {
            return locations[0];
        }
        return null;
    }

    public static Schema.Location getRelatedJobLocation(SBR_3_0_WrapAddress a) {
        List<Schema.Location> locations = new List<Schema.Location>();
        if (!String.isBlank(a.street1) && !String.isBlank(a.city) && !String.isBlank(a.state) && !String.isBlank(a.zip) && !String.isBlank(a.country)) {
            locations = [
                SELECT ID, Name, Street_Address__c, City__c, Zip_Code__c, State__c, Country__c, Latitude_Longitude__c
                FROM Location
                WHERE Recordtype.Name = :SBR_3_0_Constants.LOCATION_REC_TYPE_JOB_LOC AND Street_Address__c = :a.street1 AND City__c = :a.city AND State__c = :a.State AND Zip_Code__c = :a.zip AND Country__c = :a.country
                ORDER BY CreatedDate ASC
                LIMIT 1
            ];
        }
        if (locations.size() > 0) {
            return locations[0];
        }
        if (a.latitude != null && a.longitude != null) {
            locations = [
                SELECT ID, Name, Street_Address__c, City__c, Zip_Code__c, State__c, Country__c, Latitude_Longitude__c
                FROM Location
                WHERE Recordtype.Name = :SBR_3_0_Constants.LOCATION_REC_TYPE_JOB_LOC AND Latitude_Longitude__latitude__s = :a.latitude AND Latitude_Longitude__longitude__s = :a.longitude
                ORDER BY CreatedDate ASC
                LIMIT 1
            ];
            if (locations.size() > 0) {
                return locations[0];
            }
        }
        return null;
    }
    
	// changes for FRONT-22246, FRONT-22247
    // Added Name field in the query
	// Added AuraEnabled to be called in sbr_3_0_orderDeliveryDetailsCmp
    @AuraEnabled(cacheable=true)
    public static Schema.Location getRelatedBranchLocation(String branchNumber, String cc) {
        Schema.Location relBranch;
        List<Schema.Location> relBranches = [
            SELECT ID, Branch_Location_Number__c, Name
            FROM Location
            WHERE Recordtype.Name = :SBR_3_0_Constants.LOCATION_REC_TYPE_BRANCH AND Branch_Location_Number__c = :branchNumber AND Company_Code__c = :cc
            LIMIT 1
        ];
        if (relBranches.size() > 0) {
            relBranch = relBranches[0];
        }
        return relBranch;
    }

    public static List<AssociatedLocation> getJobSitesFiltered(SBR_3_0_GoogleMapCmpController.FilterWrapper wrapper) {
        List<AssociatedLocation> emptyAssociatedLocationLst = new List<AssociatedLocation>();
        system.debug('wrapper in getJobSitesFiltered:' + wrapper);
        Set<Id> ownerIds = new Set<Id>();
        String users = wrapper.userTerritories;
        if (String.isNotBlank(users)) {
            users = users.deleteWhitespace();
            for (String s : users.split(',')) {
                ownerIds.add(s);
            }
        }

        String query = 'SELECT Id, Order.Jobsite__c, Order.Jobsite__r.JobsiteName__c, Order.Jobsite__r.Status__c, Order.Jobsite__r.Latitude_Longitude__Longitude__s,Order.Jobsite__r.Latitude_Longitude__Latitude__s, Order.Jobsite__r.Street_Address__c,Order.Jobsite__r.City__c, Order.Jobsite__r.State__c, Order.Jobsite__r.Country__c, Order.Jobsite__r.Zip_Code__c FROM OrderItem WHERE  Order.Status = \'Open\' AND SBQQ__Asset__r.Status = \'ON RENT\' AND ';

        query += '(';

        if (wrapper.todayJobSites == true) {
            query += 'Order.Start_Date__c = TODAY OR ';
        }
        if (wrapper.yesterdayJobSites == true) {
            query += 'Order.Start_Date__c = YESTERDAY OR ';
        }
        if (wrapper.nextXDaysJobSites == true && String.isNotBlank(wrapper.nextXDaysJobSitesValue)) {
            query += 'Order.Start_Date__c = LAST_N_DAYS:' + String.escapeSingleQuotes(wrapper.nextXDaysJobSitesValue);
        }

        /*if (wrapper.activeJobSites == true) {
            query += ' Order.Jobsite__r.Status__c = \'A\' AND ';
        } else {
            query += ' Order.Jobsite__r.Status__c = \'D\' AND ';
        }*/

        query += ') AND ';
        System.debug('pre sQuery jobsite -> ' + query);
        query = query.replaceAll('\\(\\) AND ', '');
        query = query.replaceAll('OR \\)', ')');

        if (String.isNotBlank(wrapper.jobSiteSearch)) {
            query += ' Order.Jobsite__r.JobsiteName__c LIKE \'%' + String.escapeSingleQuotes(wrapper.jobSiteSearch) + '%\' AND ';
        }
        query += 'Order.Sales_Rep__c IN ' + inClausify(ownerIds);

        System.debug(query);
        List<OrderItem> orderItems = Database.query(query);
        if (!orderItems.isEmpty()) {
            System.debug(orderItems);
        }

        List<AssociatedLocation> jobSiteList = new List<AssociatedLocation>();
        Set<Id> jobSiteIds = new Set<Id>();
        for (OrderItem mOrderItem : orderItems) {
            if (mOrderItem.Order != null && mOrderItem.Order.Jobsite__c != null) {
                Id jobSiteId = mOrderItem.Order.Jobsite__c;

                // Check if the job site Id is not already in the set
                if (!jobSiteIds.contains(jobSiteId)) {
                    jobSiteIds.add(jobSiteId);
                }
            }
        }
        System.debug(jobSiteIds.size());
       
        //return jobSiteList;
        return [SELECT Id, JobsiteName__c, Latitude_Longitude__c, Latitude_Longitude__Longitude__s, Latitude_Longitude__Latitude__s, Street_Address__c, City__c, State__c, Country__c, Zip_Code__c, ParentRecordId FROM AssociatedLocation WHERE ID IN: jobSiteIds];
        
    }

    public static String inClausify(Set<Id> ids) {
        String inClause = String.format('(\'\'{0}\'\')', new List<String>{ String.join(new List<Id>(ids), '\',\'') });
        return inClause;
    }
}