/*********************************************************************************************************************
* Apex Class: SBR_3_0_GoogleMapCmpController
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Controller for Google Maps component
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Kunal Patel           2022-03-15            Initial version  
*********************************************************************************************************************/

public with sharing class SBR_3_0_GoogleMapCmpController {
    
    public static String apiKey { get; set; }

    @AuraEnabled(cacheable = true)
    public static List<MarkerWrapper> getAllRecords() {
        try {
            return filterRecords(null);
        } catch (Exception e) {
            throw new CustomException(e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable = false)
    public static List<MarkerWrapper> getAccounts(FilterWrapper filter) {

        if(filter == null) {
            filter = new FilterWrapper();
        }

        Map<Id, MarkerWrapper> resultMap = new Map<Id, MarkerWrapper>();

        List<SBR_3_0_AccountDA.AccountWrapper> topAccounts = SBR_3_0_AccountDA.getAccountsFiltered(filter);

        for(SBR_3_0_AccountDA.AccountWrapper wrap : topAccounts) {

            MarkerWrapper aw;
            Set<String> cats = new Set<String>();
            if(resultMap.containsKey(wrap.account.Id)) {
                aw = resultMap.get(wrap.account.Id);
                cats = aw.categories;
            }
            
            String cat = '';
            if(wrap.account_relationship.Rank__c > 0 && wrap.account_relationship.Rank__c <= 25) {
                cats.add('top25');
                cat = 'top25';
            } else if(wrap.account_relationship.Rank__c > 25 && wrap.account_relationship.Rank__c <= 50) {
                cats.add('top50');
                cat = 'top50';
            }

            cats.add(wrap.account.RecordType.Name);
            if(wrap.account.Managed_w_OSR_Fingerprint__c == true) {
                cats.add('fingerprint');
            }

            if(wrap.account.Sales_Rep_commission__c == true) {
                cats.add('commissionable');
            }

            if(wrap.account.Sales_Activity_Status__c == 'Watchlist') {
                cats.add('watchlist');
                cat = 'watchlist';
            }

            if(wrap.account.Sales_Activity_Status__c == 'Dormant') {
                cats.add('dormant');
                cat = 'dormant';

            }

            if(wrap.account.RecordTypeId == SBR_3_0_Constants.ACCOUNT_OFFICE_RT_ID) {
                cats.add('office');
            }
            if(wrap.account.RecordTypeId == SBR_3_0_Constants.ACCOUNT_PROSPECT_RT_ID) {
                cats.add('prospect');
                cat = 'prospect';
            }

            aw = new MarkerWrapper(null, wrap.account, null, null, null, null, null, null, cat, cats, wrap.account_relationship.Rank__c);
            resultMap.put(wrap.account.Id, aw);
        }

        // Sort Accounts by Name, Rank ASC
        List<MarkerWrapper> sortedResults = resultMap.values();
        sortedResults.sort();

        System.debug('sortedResults size -> ' + sortedResults.size());
        return sortedResults; 
    }

    @AuraEnabled(cacheable = false)
    public static MarkerWrapper getAccount(Id id) {
        
        Account acc = SBR_3_0_AccountDA.getAccount(id);
        MarkerWrapper result = new MarkerWrapper(null, acc, null, null, null, null, null, null, 'account', null, null);
        
        return result;
    }

    @AuraEnabled(cacheable = false)
    public static List<MarkerWrapper> getProjects(FilterWrapper filter) {

        if(filter == null) {
            filter = new FilterWrapper();
        }

        List<MarkerWrapper> results = new List<MarkerWrapper>();
        
        for(Project__c p : SBR_3_0_ProjectDA.getProjectsFiltered(filter)) {
            MarkerWrapper aw = new MarkerWrapper(null, null, p, null, null, null, null, null, 'project', null, null);
            results.add(aw);
        }

        return results;
    }

    @AuraEnabled(cacheable = false)
    public static MarkerWrapper getProject(Id id) {
        
        Project__c p = SBR_3_0_ProjectDA.getProject(id);
        MarkerWrapper result = new MarkerWrapper(null, null, p, null, null, null, null, null, 'project', null, null);
        
        return result;
    }

    @AuraEnabled(cacheable = false)
    public static List<MarkerWrapper> getBranches(FilterWrapper filter) {

        if(filter == null) {
            filter = new FilterWrapper();
        }
        List<MarkerWrapper> results = new List<MarkerWrapper>();
        
        for(Schema.Location l : SBR_3_0_BranchDA.getBranchesFiltered(filter)) {
            MarkerWrapper aw = new MarkerWrapper(null, null, null, l, null, null, null, null, 'branch', null, null);
            results.add(aw);
        }
        return results;
    }

    @AuraEnabled(cacheable = false)
    public static List<MarkerWrapper> getJobsites(FilterWrapper filter) {

        if(filter == null) {
            filter = new FilterWrapper();
        }

        List<MarkerWrapper> results = new List<MarkerWrapper>();

        List<AssociatedLocation> jobsites = SBR_3_0_JobsiteDA.getJobSitesFiltered(filter);

        for(AssociatedLocation js : jobsites) {
            MarkerWrapper aw = new MarkerWrapper(null, null, null, null, js, null, null, null, 'jobsite', null, null);
            results.add(aw);
        }
                
        return results;
    }

    @AuraEnabled(cacheable = false)
    public static List<MarkerWrapper> getOpportunities(FilterWrapper filter) {

        if(filter == null) {
            filter = new FilterWrapper();
        }

        List<MarkerWrapper> results = new List<MarkerWrapper>();
        
        List<Opportunity> opps = SBR_3_0_OpportunityDA.getOpportunityFiltered(filter);

        for(Opportunity o : opps) {
            MarkerWrapper aw = new MarkerWrapper(null, null, null, null, null, o, null, null, 'opportunity', null, null);
            results.add(aw);
        }
        
        return results;
    }

    @AuraEnabled(cacheable = false)
    public static MarkerWrapper getOpportunity(Id id) {
        
        Opportunity opp = SBR_3_0_OpportunityDA.getOpportunity(id);
        MarkerWrapper result = new MarkerWrapper(null, null, null, null, null, opp, null, null, 'opportunity', null, null);
        
        return result;
    }

    @AuraEnabled(cacheable = false)
    public static List<MarkerWrapper> getLeads(FilterWrapper filter) {
        
        if(filter == null) {
            filter = new FilterWrapper();
        }

        List<MarkerWrapper> results = new List<MarkerWrapper>();
        List<Lead> leads = SBR_3_0_LeadDA.getLeadsFiltered(filter);

        for(Lead l : leads) {
            MarkerWrapper aw = new MarkerWrapper(null, null, null, null, null, null, l, null, 'lead', null, null);
            results.add(aw);
        }
        return results;
    }

    @AuraEnabled(cacheable = false)
    public static MarkerWrapper getLead(Id id) {
        
        Lead l = SBR_3_0_LeadDA.getLead(id);
        MarkerWrapper result = new MarkerWrapper(null, null, null, null, null, null, l, null, 'lead', null, null);
        
        return result;
    }

    @AuraEnabled(cacheable = false)
    public static List<MarkerWrapper> getTasks(FilterWrapper filter) {
 
        if(filter == null) {
            filter = new FilterWrapper();
        }
        List<Task> tasks = SBR_3_0_TaskDA.getTasksFiltered(filter);

        List<MarkerWrapper> results = new List<MarkerWrapper>();

        Set<Id> accIds = new Set<Id>();
        Set<Id> projIds = new Set<Id>();
        Set<Id> oppIds = new Set<Id>();
        Set<Id> ownerIds = new Set<Id>();
        
        for(Task t : tasks) {
            String parentApiName = '';
            ownerIds.add(t.OwnerId);

            if(t.WhatId != null) {
                parentApiName = t.WhatId.getSObjectType().getDescribe().getName();
                if(parentApiName == 'Account') {
                    accIds.add(t.WhatId);
                } else if(parentApiName == 'Project__c') {
                    projIds.add(t.WhatId);
                } else if(parentApiName == 'Opportunity') {
                    oppIds.add(t.WhatId);
                }
            }
        }

        Map<Id, Account> accountMap = SBR_3_0_AccountDA.getAccounts(accIds);
        Map<Id, Project__c> projectMap = SBR_3_0_ProjectDA.getProjects(projIds);
        Map<Id, Opportunity> opportunityMap = SBR_3_0_OpportunityDA.getOpportunities(oppIds);

        Map<Id, User> userMap = SBR_3_0_UserDA.getUsers(ownerIds);
        Map<Id, Account_Relationship__c> accountRelationshipsByAccountId = SBR_3_0_AccountDA.getAccountRelationShipAccountId(accountMap.keySet(), ownerIds);
        Map<Id, Set<String>> categoriesByAccountId = getAccountBadges(accountMap, accountRelationshipsByAccountId);

        for (Task t : tasks) {
            Set<String> categories = new Set<String>();
            if (accountMap.get(t.WhatId) != null) {
                categories = categoriesByAccountId.get(accountMap.get(t.WhatId).Id);
            }

            MarkerWrapper aw = new MarkerWrapper(null, accountMap.get(t.WhatId), projectMap.get(t.WhatId), null, null, opportunityMap.get(t.WhatId), null, t, 'task', categories, null);
            String whoName = '';
            String whoType = '';
            if(t.WhoId != null) {
                whoName = t.who.Name;
                whoType = t.WhoId.getSObjectType().getDescribe().getName();
            }
            aw.whoName = whoName;
            aw.whoType = whoType;
            
            User owner = userMap.get(t.OwnerId);
            aw.assignedToName = owner.Name;

            results.add(aw);
        }

        return results;
    }

    @TestVisible
    private static Map<Id, Set<String>> getAccountBadges(Map<Id, Account> accounts, Map<Id, Account_Relationship__c> accountRelationshipsByAccountId) {
        Map<Id, Set<String>> categoriesByAccountId = new Map<Id, Set<String>>();
        for (Id accountId : accounts.keySet()) {
            Set<String> categories = new Set<String>();
            Account_Relationship__c accountRelationships = accountRelationshipsByAccountId.get(accountId);
            if (accountRelationships != null) {
                if (accountRelationships != null && accountRelationships.Rank__c > 0 && accountRelationships.Rank__c <= 25) {
                    categories.add('top25');
                } else if (accountRelationships != null && accountRelationships.Rank__c > 25 && accountRelationships.Rank__c <= 50) {
                    categories.add('top50');
                }
                if (accounts.get(accountId).Managed_w_OSR_Fingerprint__c == true) {
                    categories.add('fingerprint');
                }
    
                if (accounts.get(accountId).Sales_Rep_commission__c == true) {
                    categories.add('commissionable');
                }
    
                if (accounts.get(accountId).Sales_Activity_Status__c == 'Watchlist') {
                    categories.add('watchlist');
                }
    
                if (accounts.get(accountId).Sales_Activity_Status__c == 'Dormant') {
                    categories.add('dormant');
                }
    
                if (accounts.get(accountId).RecordTypeId == SBR_3_0_Constants.ACCOUNT_OFFICE_RT_ID) {
                    categories.add('office');
                }
                if (accounts.get(accountId).RecordTypeId == SBR_3_0_Constants.ACCOUNT_PROSPECT_RT_ID) {
                    categories.add('prospect');
                }
                categoriesByAccountId.put(accountId, categories);
            }

            
        }
        return categoriesByAccountId;
    }

    @AuraEnabled(cacheable=false)
    public static List<MarkerWrapper> getAppointments(FilterWrapper filter) {
        if (filter == null) {
            filter = new FilterWrapper();
        }

        List<MarkerWrapper> result = new List<MarkerWrapper>();

        List<Event> events = SBR_3_0_AppointmentDA.getAppointmentsFiltered(filter);
        Set<Id> accIds = new Set<Id>();
        Set<Id> projIds = new Set<Id>();
        Set<Id> oppIds = new Set<Id>();
        Set<Id> ownerIds = new Set<Id>();

        for(Event e : events) {
            String parentApiName = '';
            ownerIds.add(e.OwnerId);

            if(e.WhatId != null) {
                parentApiName = e.WhatId.getSObjectType().getDescribe().getName();
                if(parentApiName == 'Account') {
                    accIds.add(e.WhatId);
                } else if(parentApiName == 'Project__c') {
                    projIds.add(e.WhatId);
                } else if(parentApiName == 'Opportunity') {
                    oppIds.add(e.WhatId);
                }
            }
        }

        Map<Id, Account> accountMap = SBR_3_0_AccountDA.getAccounts(accIds);
        Map<Id, Project__c> projectMap = SBR_3_0_ProjectDA.getProjects(projIds);
        Map<Id, Opportunity> opportunityMap = SBR_3_0_OpportunityDA.getOpportunities(oppIds);
        Map<Id, User> userMap = SBR_3_0_UserDA.getUsers(ownerIds);
        Map<Id, Account_Relationship__c> accountRelationshipsByAccountId = SBR_3_0_AccountDA.getAccountRelationShipAccountId(accountMap.keySet(), ownerIds);
        Map<Id, Set<String>> categoriesByAccountId = getAccountBadges(accountMap, accountRelationshipsByAccountId);

        for (Event e : events) {
            Set<String> categories = new Set<String>();
            if (accountMap.get(e.WhatId) != null) {
                categories = categoriesByAccountId.get(accountMap.get(e.WhatId).Id);
            }
            MarkerWrapper aw = new MarkerWrapper(e, accountMap.get(e.WhatId), projectMap.get(e.WhatId), null, null, opportunityMap.get(e.WhatId), null, null, 'appointment', categories, null);
            String whoName = '';
            String whoType = '';
            if(e.WhoId != null) {
                whoName = e.who.Name;
                whoType = e.WhoId.getSObjectType().getDescribe().getName();
            }
            aw.whoName = whoName;
            aw.whoType = whoType;

            User owner = userMap.get(e.OwnerId);
            aw.assignedToName = owner.Name;

            result.add(aw);

        }
        return result;
    }

    @AuraEnabled(cacheable = false)
    public static MarkerWrapper getAppointment(Id id) {
        Event e = SBR_3_0_AppointmentDA.getAppointment(id);
        MarkerWrapper mw = new MarkerWrapper(e, null, null, null, null, null, null, null, null, null, null);
         

        User owner = SBR_3_0_UserDA.getUserById(e.OwnerId);
        mw.assignedToName = owner.Name;


        if(e.WhoId != null) {
            Set<Id> ids = new Set<Id>();
            if('Lead' == e.WhoId.getSObjectType().getDescribe().getName()) {
                ids.add(e.WhoId);
                Map<Id, Lead> leads = SBR_3_0_LeadDA.getLeadsMap(ids);
                mw.whoName = leads.values().get(0).Name;
                mw.whoType = 'Lead';
            }
            else if('Contact' == e.WhoId.getSObjectType().getDescribe().getName()) {
                ids.add(e.WhoId);
                Map<Id, Contact> conts = SBR_3_0_ContactDA.getContacts(ids);
                mw.whoName = conts.values().get(0).Name;
                mw.whoType = 'Contact';
            }
        }
        
        return mw;
    }

    @AuraEnabled(cacheable = false)
    public static MarkerWrapper getTask(Id id) {
        Task t = SBR_3_0_TaskDA.getTask(id);
        MarkerWrapper mw = new MarkerWrapper(null, null, null, null, null, null, null, t, null, null, null);
           
        User owner = SBR_3_0_UserDA.getUserById(t.OwnerId);
        mw.assignedToName = owner.Name;

        if(t.WhoId != null) {
            Set<Id> ids = new Set<Id>();
            if('Lead' == t.WhoId.getSObjectType().getDescribe().getName()) {
                ids.add(t.WhoId);
                Map<Id, Lead> leads = SBR_3_0_LeadDA.getLeadsMap(ids);
                mw.whoName = leads.values().get(0).Name;
                mw.whoType = 'Lead';
            }
            else if('Contact' == t.WhoId.getSObjectType().getDescribe().getName()) {
                ids.add(t.WhoId);
                Map<Id, Contact> conts = SBR_3_0_ContactDA.getContacts(ids);
                mw.whoName = conts.values().get(0).Name;
                mw.whoType = 'Contact';
            }
        }
        
        return mw;
    }

    @AuraEnabled(cacheable = false)
    public static void updateTaskEvent(Id id, String outcome) {
        try {
            if(String.isNotBlank(id)) {
                String objType = id.getSObjectType().getDescribe().getName();
                if(objType == 'Task') {
                    Task t = new Task(Id = id, Description = outcome, Status = 'Completed');
                    update t;
                }

                if(objType == 'Event') {
                    Event e = new Event(Id = id, Outcome__c = outcome, Status__c = 'Completed');
                    update e;
                }
            }
        } catch (Exception e) {
            throw new CustomException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable = true)
    public static List<TerritoryWrapper> getWiredTerritories() {
        try {
            return getTerritories(null);
        } catch (Exception e) {
            throw new CustomException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable = false)
    public static List<TerritoryWrapper> getTerritories(FilterWrapper filterWrapper) {

        try {
            System.debug('wrapper: ' + filterWrapper);
            List<TerritoryWrapper> result = new List<TerritoryWrapper>();

            String userIds;
            if(filterWrapper != null) {
                userIds = filterWrapper.userTerritories;
            }

            if(String.isBlank(userIds)) {
                userIds = UserInfo.getUserId();
            }

            System.debug('userIds -> ' + userIds);

            userIds = userIds.deleteWhitespace();
            List<String> userIdList = userIds.split(',');

            Map<String, List<String>> userToTerIdMap = getUserToTerritoryIDs(userIdList);

            Set<String> processedTerrIds = new Set<String>();
            for(String userId : userIdList) {
                List<String> terIds = userToTerIdMap.get(userId);
                if(terIds != null) {
                    for(String tid : terIds) {
                        if(!processedTerrIds.contains(tid)) {
                            SBR_3_0_API_FetchGeoJson sbrGeoJsonApi = new SBR_3_0_API_FetchGeoJson();
                            String geoResult = sbrGeoJsonApi.getTerritoryGeoJson(tid);
                            result.add(new TerritoryWrapper(userId, tid, geoResult));
                            processedTerrIds.add(tid);
                        }
                    }
                }
            }
            System.debug('getTerritories result -> ' + result);
            return result;

        } catch (Exception e) {
            throw new CustomException(e.getMessage());
        }
    }

    public static void setGoogleMapAPIKey() {

        Credential__c gm = SBR_3_0_APISettings.getCredentials('Google_Map');
        
        if(gm != null) {
            apiKey = gm.Secret__c;
        }
    }

    public static Map<String, List<String>> getUserToTerritoryIDs(List<String> userIds) {
        Map<String, List<String>> result = new Map<String, List<String>>();
        Set<Id> userSet = new Set<Id>();
        for(String s : userIds) {
            userSet.add(s);
        }
        List<Territory__c> territories = SBR_3_0_TerritoryDA.getTerritories(userSet);

        for(Territory__c t : territories) {
            String userId = t.OwnerId;
            String tid = t.Territory_ID__c;
            if(result.get(userId) == null) {
                result.put(userId, new List<String>()); 
            }
            List<String> terrIds = result.get(userId);
            if(String.isNotBlank(tid)) {
                terrIds.add(tid);
            }
            result.put(userId, terrIds); 
        }

        return result;
    }

    /******* Method to dynamically obtain VF origin for the iframe VF page in LWC  *******/
    @AuraEnabled(cacheable = true)
    public static String getVisualforceDomain(String formFactor, String userAgent) {
        String result = getMyDomain() + '--c';
        if(isSandbox()) {
            result += '.sandbox';
        }
        result += '.vf.force.com';
        
        System.debug('VF Domain -> ' + result);
        System.debug('formFactor -> ' + formFactor);
        System.debug('userAgent -> ' + userAgent);
        return result;
    }

    @AuraEnabled(cacheable = true)
    public static String getLightningDomain() {
        String result = getMyDomain();
        if(isSandbox()) {
            result += '.sandbox';
        }
        result += '.lightning.force.com';
        System.debug('Lightning Domain -> ' + result);
        return result;
    }

    public static String getMyDomain() {
        return URL.getOrgDomainUrl().getHost().split('\\.')[0].toLowerCase();
    }

    public static Boolean isSandbox() {
        return [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
    }

    @AuraEnabled
    public static List<MarkerWrapper> filterRecords(FilterWrapper wrapper) {
        try {
            System.debug('wrapper:' + wrapper);
            if(wrapper == null) {
                wrapper = new FilterWrapper();
            }

            List<MarkerWrapper> result = new List<MarkerWrapper>();

            result.addAll(getAppointments(wrapper));
            result.addAll(getTasks(wrapper));
            result.addAll(getAccounts(wrapper));
            result.addAll(getProjects(wrapper));
            result.addAll(getJobsites(wrapper));
            result.addAll(getOpportunities(wrapper));
            result.addAll(getBranches(wrapper));
            result.addAll(getLeads(wrapper));

            return result;
        } catch (Exception e) {
            throw new CustomException(e.getMessage());
        }
    }

    public class MarkerWrapper implements Comparable {
        @AuraEnabled
        public Event event {get; set;}
        @AuraEnabled
        public String summary {get; set;}
        @AuraEnabled
        public String iconName {get; set;}
        @AuraEnabled
        public Boolean isEvent {get; set;}
        @AuraEnabled
        public Boolean isAccount {get; set;}
        @AuraEnabled
        public Boolean isProject {get; set;}
        @AuraEnabled
        public Boolean isJobsite {get; set;}
        @AuraEnabled
        public Boolean isOpportunity {get; set;}
        @AuraEnabled
        public Boolean isBranch {get; set;}
        @AuraEnabled
        public Boolean isLead {get; set;}
        @AuraEnabled
        public Boolean isTask {get; set;}
        @AuraEnabled
        public Account account {get; set;}
        @AuraEnabled
        public Decimal rank {get; set;}
        @AuraEnabled
        public Project__c project {get; set;}
        @AuraEnabled
        public AssociatedLocation jobsite {get; set;}
        @AuraEnabled
        public Opportunity opportunity {get; set;}
        @AuraEnabled
        public Schema.Location branch {get; set;}
        @AuraEnabled
        public Lead lead {get; set;}
        @AuraEnabled
        public Task task {get; set;}
        @AuraEnabled
        public String recId {get; set;}
        @AuraEnabled
        public String assignedToName {get; set;}
        @AuraEnabled
        public String objectType {get; set;}
        @AuraEnabled
        public String markerType {get; set;}
        @AuraEnabled
        public Set<String> categories {get; set;}
        @AuraEnabled
        public String parentType {get; set;}
        @AuraEnabled
        public String parentTypeLabel {get; set;}
        @AuraEnabled
        public String parentName {get; set;}
        @AuraEnabled
        public Boolean isToday {get; set;}
        @AuraEnabled
        public String whoName {get; set;}
        @AuraEnabled
        public String whoType {get; set;}
        @AuraEnabled
        public String lat {get; set;}
        @AuraEnabled
        public String lng {get; set;}
        @AuraEnabled
        public String street {get; set;}
        @AuraEnabled
        public String city {get; set;}
        @AuraEnabled
        public String state {get; set;}
        @AuraEnabled
        public String postal {get; set;}
        @AuraEnabled
        public String country {get; set;}
        @AuraEnabled
        public String recordType {get; set;}

        MarkerWrapper(Event e, Account acc, Project__c p, Schema.Location b, AssociatedLocation j, Opportunity opp, Lead l, Task t, String markerType, Set<String> categories, Decimal rank) {
            this.isToday = false; // set to false, true for test
            this.event = e;
            this.account = acc;
            this.project = p;
            this.branch = b;
            this.jobsite = j;
            this.opportunity = opp;
            this.lead = l;
            this.task = t;
            this.markerType = markerType;
            this.categories = categories;
            this.rank = rank;
            this.recordType = '';
            
            if(e != null) {
                if(e.WhatId != null) {
                    this.parentName = e.What.Name;
                    this.parentType = e.WhatId.getSObjectType().getDescribe().getName();
                    this.parentTypeLabel = e.WhatId.getSObjectType().getDescribe().getLabel();
                }
                if(e.StartDateTime != null && e.StartDateTime.date() == System.now().date()) {
                    this.isToday = true;
                }
                
                if(e.Latitude_Longitude__latitude__s != null && e.Latitude_Longitude__longitude__s != null) {
                    this.lat = String.valueOf(e.Latitude_Longitude__latitude__s);
                    this.lng = String.valueOf(e.Latitude_Longitude__longitude__s);
                } 
                else if(acc != null) {
                    this.lat = (acc.Override_Address__Latitude__s != null) ? String.valueOf(acc.Override_Address__Latitude__s) : String.valueOf(acc.Street_Address_LatLong__latitude__s);
                    this.lng = (acc.Override_Address__Longitude__s != null) ? String.valueOf(acc.Override_Address__Longitude__s) : String.valueOf(acc.Street_Address_LatLong__longitude__s);

                    if(this.lat == null && this.lng == null) {
                        this.lat = String.valueOf(acc.BillingLatitude);
                        this.lng = String.valueOf(acc.BillingLongitude);
                    }
                }
                this.street = e.Street__c;
                this.city = e.City__c;
                this.state = e.State__c;
                this.postal = e.Zip_Code__c;
                this.country = e.Country__c;
            }

            if(t != null) {
                if(t.WhatId != null) {
                    this.parentName = t.What.Name;
                    this.parentType = t.WhatId.getSObjectType().getDescribe().getName();
                    this.parentTypeLabel = t.WhatId.getSObjectType().getDescribe().getLabel();
                }
                if(t.WhoId != null) {
                    this.whoName = t.Who.Name;
                    this.whoType = t.WhoId.getSObjectType().getDescribe().getLabel();
                }
            }

            if(e == null && acc != null) {
                this.parentName = acc.Name;

                this.street = (acc.Override_Address__Street__s != null) ? acc.Override_Address__Street__s : acc.ShippingStreet;
                this.city = (acc.Override_Address__City__s != null) ? acc.Override_Address__City__s : acc.ShippingCity;
                this.state = (acc.Override_Address__StateCode__s != null) ? acc.Override_Address__StateCode__s : acc.ShippingState;
                this.postal = (acc.Override_Address__PostalCode__s != null) ? acc.Override_Address__PostalCode__s : acc.ShippingPostalCode;
                this.country = (acc.Override_Address__CountryCode__s != null) ? acc.Override_Address__CountryCode__s : acc.ShippingCountry;
                this.lat = (acc.Override_Address__Latitude__s != null) ? String.valueOf(acc.Override_Address__Latitude__s) : String.valueOf(acc.Street_Address_LatLong__latitude__s);
                this.lng = (acc.Override_Address__Longitude__s != null) ? String.valueOf(acc.Override_Address__Longitude__s) : String.valueOf(acc.Street_Address_LatLong__longitude__s);
                


                // if all values for override and street address were blank, use billing. We check for all null as we don't want to mix addresses
                if(this.street == null && this.city == null && this.state == null && this.postal == null && this.country == null && this.lat == null && this.lng == null) {
                    this.street = String.valueOf(acc.BillingStreet);
                    this.city = String.valueOf(acc.BillingCity);
                    this.state = String.valueOf(acc.BillingState);
                    this.postal = String.valueOf(acc.BillingPostalCode);
                    this.country = String.valueOf(acc.BillingCountry);
                    this.lat = String.valueOf(acc.BillingLatitude);
                    this.lng = String.valueOf(acc.BillingLongitude);
                }
            
            }
            
            if(p != null) {
                Location loc = p.Latitude_Longitude__c;
                if(loc != null) {
                    this.lat = String.valueOf(loc.latitude);
                    this.lng = String.valueOf(loc.longitude);
                }
                this.parentName = p.Project_Name__c;
                this.street = p.Street__c;
                this.city = p.City__c;
                this.state = p.State__c;
                this.postal = p.Zip_Code__c;
                this.country = p.Country__c;
            }

            if(j != null) {
                //Location loc = j.Latitude_Longitude__c;
                if(j.Latitude_Longitude__Latitude__s != null && j.Latitude_Longitude__Longitude__s != null) {
                    this.lat = String.valueOf(j.Latitude_Longitude__Latitude__s);
                    this.lng = String.valueOf(j.Latitude_Longitude__Longitude__s);
                }
                this.parentName = j.JobsiteName__c;
                this.street = j.Street_Address__c;
                this.city = j.City__c;
                this.state = j.State__c;
                this.postal = j.Zip_Code__c;
                this.country = j.Country__c;
            }

            if(opp != null) {
                Location loc = opp.Latitude_Longitude__c;
                if(loc != null) {
                    this.lat = String.valueOf(loc.latitude);
                    this.lng = String.valueOf(loc.longitude);
                }
                this.parentName = opp.Name;
                this.street = opp.Street__c;
                this.city = opp.City__c;
                this.state = opp.State__c;
                this.postal = opp.Zip_Code__c;
                this.country = opp.Country__c;
            }
            
            if(b != null) {
                Location loc = b.Latitude_Longitude__c;
                if(loc != null) {
                    this.lat = String.valueOf(loc.latitude);
                    this.lng = String.valueOf(loc.longitude);
                }
                this.parentName = b.Name;
                this.street = b.Street_Address__c;
                this.city = b.City__c;
                this.state = b.State__c;
                this.postal = b.Zip_Code__c;
                this.country = b.Country__c;
            }

            if(l != null) {
                this.lat = String.valueOf(l.Latitude);
                this.lng = String.valueOf(l.Longitude);
                this.parentName = l.Name;
                if (String.isNotBlank(l.Job_Address_Street__c)) {
                  this.street = l.Job_Address_Street__c;
                  this.city = l.Job_Address_City__c;
                  this.state = l.Job_Address_State__c;
                  this.postal = l.Job_Address_Zip_Code__c;
                  this.country = l.Job_Address_Country__c;
                } else {
                  // SF-7084: Use Customer Address when Job Address is not present
                  this.street = l.Street;
                  this.city = l.City;
                  this.state = l.State;
                  this.postal = l.PostalCode;
                  this.country = l.Country;
                }
            }

            if(this.event != null) { this.isEvent = true; this.objectType = 'Event'; this.recId = e.Id; this.summary = this.event.Subject;}
            if(this.task != null) { this.isTask = true; this.objectType = 'Task'; this.recId = this.task.Id; this.summary = this.task.Subject;}


            if(this.event == null && this.task == null) {
                if(this.account != null) { this.isAccount = true; this.objectType = 'Account'; this.recId = this.account.Id; this.summary = this.account.Name;}
                if(this.project != null) { this.isProject = true; this.objectType = 'Project__c'; this.recId = this.project.Id; this.summary = this.project.Project_Name__c;}
                if(this.jobsite != null) { this.isJobsite = true; this.objectType = 'AssociatedLocation'; this.recId = this.jobsite.Id; this.summary = this.jobsite.JobsiteName__c;}
                if(this.opportunity != null) { this.isOpportunity = true; this.objectType = 'Opportunity'; this.recId = this.opportunity.Id; this.summary = this.opportunity.Name;}
                if(this.branch != null) { this.isBranch = true; this.objectType = 'Location'; this.recId = this.branch.Id; this.summary = this.branch.Name;}
                if(this.lead != null) { this.isLead = true; this.objectType = 'Lead'; this.recId = this.lead.Id; this.summary = this.lead.Name;}
            }

            if(this.objectType == 'Account') { this.iconName = 'standard:account';}
            if(this.objectType == 'Project__c') { this.iconName = 'custom:custom57';}
            if(this.objectType == 'AssociatedLocation') { this.iconName = 'standard:location';}
            if(this.objectType == 'Opportunity') { this.iconName = 'standard:opportunity';}
            if(this.objectType == 'Location') { this.iconName = 'standard:location';}
            if(this.objectType == 'Lead') { this.iconName = 'standard:lead';}
            if(this.objectType == 'Task') { this.iconName = 'standard:task';}
            if(this.objectType == 'Event') { this.iconName = 'standard:event';}

            if(this.objectType == 'Account') { this.recordType = this.account.RecordType.Name; }
            if(this.objectType == 'Location') { this.recordType = this.branch.RecordType.Name; }
            
        }

        public Integer compareTo(Object compareTo) {

            MarkerWrapper compareToWrapper = (MarkerWrapper) compareTo;
            
            // The return value of 0 indicates that both elements are equal.
            // sort by rank
            Integer returnValue = 0;
            if (this.rank > compareToWrapper.rank) {
                returnValue = 1;
            } else if (this.rank < compareToWrapper.rank) {
                returnValue = -1;
            } else if ((this.rank == null) && (compareToWrapper.rank != null)) {
                returnValue = -1;
            } else if ((this.rank != null) && (compareToWrapper.rank == null)) {
                returnValue = 1;
            }
            
            // secondary sort if rank's are equal
            if(returnValue == 0 && this.isAccount) {
                if (this.summary > compareToWrapper.summary) {
                    returnValue = 1;
                } else if (this.summary < compareToWrapper.summary) {
                    returnValue = -1;
                } else if ((this.summary == null) && (compareToWrapper.summary != null)) {
                    returnValue = 1;
                } else if ((this.summary != null) && (compareToWrapper.summary == null)) {
                    returnValue = -1;
                }
            }
            return returnValue;       
        }
    }

    public class FilterWrapper {

        @AuraEnabled
        public String userTerritories {get; set;}

        @AuraEnabled
        public String globalSearch {get; set;}

        @AuraEnabled
        public Boolean isPEC {get; set;}

        // Appointment Filters
        @AuraEnabled
        public String appointmentSearch {get; set;}
        @AuraEnabled
        public String apptParentType {get; set;}
        @AuraEnabled
        public Boolean openAppointments {get; set;}
        @AuraEnabled
        public Boolean todaysAppointments {get; set;}
        @AuraEnabled
        public Boolean next7DaysAppointments {get; set;}
        @AuraEnabled
        public Boolean thisWeekAppointments {get; set;}
        @AuraEnabled
        public Boolean nextWeekAppointments {get; set;}
        @AuraEnabled
        public Boolean nextXDaysAppointments {get; set;}
        @AuraEnabled
        public String nextXDaysAppointmentsValue {get; set;}
        @AuraEnabled
        public Boolean dateRangeAppointments {get; set;}
        @AuraEnabled
        public String dateRangeAppointmentsStart {get; set;}
        @AuraEnabled
        public String dateRangeAppointmentsEnd {get; set;}

        // Task Filters
        @AuraEnabled
        public String taskSearch {get; set;}
        @AuraEnabled
        public String taskParentType {get; set;}
        @AuraEnabled
        public Boolean openTasks {get; set;}
        @AuraEnabled
        public Boolean todaysTasks {get; set;}
        @AuraEnabled
        public Boolean next7DaysTasks {get; set;}
        @AuraEnabled
        public Boolean thisWeekTasks {get; set;}
        @AuraEnabled
        public Boolean nextWeekTasks {get; set;}
        @AuraEnabled
        public Boolean nextXDaysTasks {get; set;}
        @AuraEnabled
        public String nextXDaysTasksValue {get; set;}
        @AuraEnabled
        public Boolean dateRangeTasks {get; set;}
        @AuraEnabled
        public String dateRangeTasksStart {get; set;}
        @AuraEnabled
        public String dateRangeTasksEnd {get; set;}

        // Account Filters
        @AuraEnabled
        public Boolean searchAccounts {get; set;}
        @AuraEnabled
        public String accountSearch {get; set;}
        @AuraEnabled
        public Boolean top25Accounts {get; set;}
        @AuraEnabled
        public Boolean top50Accounts {get; set;}
        @AuraEnabled
        public Boolean topXAccounts {get; set;}
        @AuraEnabled
        public String topXAccountsValue {get; set;}
        @AuraEnabled
        public Boolean watchlistAccounts {get; set;}
        @AuraEnabled
        public Boolean dormantAccounts {get; set;}
        @AuraEnabled
        public Boolean rankRangeAccounts {get; set;}
        @AuraEnabled
        public String rankRangeAccountsStart {get; set;}
        @AuraEnabled
        public String rankRangeAccountsEnd {get; set;}
        @AuraEnabled
        public String accountRecordType {get; set;}
        @AuraEnabled
        public Boolean showOffices {get; set;}
        @AuraEnabled
        public Boolean assignedAccountsOnly {get;set;}
        @AuraEnabled
        public Boolean includeTracked {get;set;}

        // Lead Filters
        @AuraEnabled
        public Boolean openLeads {get; set;}
        @AuraEnabled
        public Boolean leadShareLeads {get; set;}
        @AuraEnabled
        public Boolean campaignLeads {get; set;}
        @AuraEnabled
        public String campaignType {get; set;}

        // Job Site Filters
        @AuraEnabled
        public String jobSiteSearch {get; set;}
        @AuraEnabled
        public Boolean activeJobSites {get; set;}
        @AuraEnabled
        public Boolean todayJobSites {get; set;}
        @AuraEnabled
        public Boolean yesterdayJobSites {get; set;}
        @AuraEnabled
        public Boolean nextXDaysJobSites {get; set;}
        @AuraEnabled
        public String nextXDaysJobSitesValue {get; set;}

        // Project Filters
        @AuraEnabled
        public String projectSearch {get; set;}
        @AuraEnabled
        public Boolean cityProject {get; set;}
        @AuraEnabled
        public String cityProjectValue {get; set;}
        @AuraEnabled
        public Boolean plantIdProject {get; set;}
        @AuraEnabled
        public String plantIdProjectValue {get; set;}
        @AuraEnabled
        public Boolean plantNameProject {get; set;}
        @AuraEnabled
        public String plantNameProjectValue {get; set;}
        @AuraEnabled
        public Boolean valuationProject {get; set;}
        @AuraEnabled
        public String valuationProjectValue {get; set;}
        @AuraEnabled
        public Boolean valuationRangeProjects {get; set;}
        @AuraEnabled
        public String valuationRangeProjectsStart {get; set;}
        @AuraEnabled
        public String valuationRangeProjectsEnd {get; set;}
        @AuraEnabled
        public Boolean squareFootageRangeProjects {get; set;}
        @AuraEnabled
        public String squareFootageRangeProjectsStart {get; set;}
        @AuraEnabled
        public String squareFootageRangeProjectsEnd {get; set;}
        @AuraEnabled
        public String projectStatus {get; set;}
        @AuraEnabled
        public String projectPrimaryType {get; set;}
        @AuraEnabled
        public String projectStage {get; set;}
        @AuraEnabled
        public String projectOrigin {get; set;}
        @AuraEnabled
        public String projectActivity {get; set;}
        @AuraEnabled
        public String projectTiming {get; set;}
        @AuraEnabled
        public String projectDodgePhase {get; set;}
        @AuraEnabled
        public String projectCreatedDate {get; set;}
        @AuraEnabled
        public String dateRangeCreatedDateProjectsStart {get; set;}
        @AuraEnabled
        public String dateRangeCreatedDateProjectsEnd {get; set;}
        
        // Project Bid Date Filters
        @AuraEnabled
        public Boolean next30DaysBidDateProject {get; set;}
        @AuraEnabled
        public Boolean lastXDaysBidDateProject {get; set;}
        @AuraEnabled
        public String lastXDaysBidDateProjectValue {get; set;}
        @AuraEnabled
        public Boolean nextXDaysBidDateProject {get; set;}
        @AuraEnabled
        public String nextXDaysBidDateProjectValue {get; set;}
        @AuraEnabled
        public Boolean dateRangeBidDateProjects {get; set;}
        @AuraEnabled
        public String dateRangeBidDateProjectsStart {get; set;}
        @AuraEnabled
        public String dateRangeBidDateProjectsEnd {get; set;}
        // Project Completion Date Filters
        @AuraEnabled
        public Boolean next30DaysCompletionDateProject {get; set;}
        @AuraEnabled
        public Boolean lastXDaysCompletionDateProject {get; set;}
        @AuraEnabled
        public String lastXDaysCompletionDateProjectValue {get; set;}
        @AuraEnabled
        public Boolean nextXDaysCompletionDateProject {get; set;}
        @AuraEnabled
        public String nextXDaysCompletionDateProjectValue {get; set;}
        @AuraEnabled
        public Boolean dateRangeCompletionDateProjects {get; set;}
        @AuraEnabled
        public String dateRangeCompletionDateProjectsStart {get; set;}
        @AuraEnabled
        public String dateRangeCompletionDateProjectsEnd {get; set;}
        // Project Kickoff Date Filters
        @AuraEnabled
        public Boolean next30DaysKickoffDateProject {get; set;}
        @AuraEnabled
        public Boolean lastXDaysKickoffDateProject {get; set;}
        @AuraEnabled
        public String lastXDaysKickoffDateProjectValue {get; set;}
        @AuraEnabled
        public Boolean nextXDaysKickoffDateProject {get; set;}
        @AuraEnabled
        public String nextXDaysKickoffDateProjectValue {get; set;}
        @AuraEnabled
        public Boolean dateRangeKickoffDateProjects {get; set;}
        @AuraEnabled
        public String dateRangeKickoffDateProjectsStart {get; set;}
        @AuraEnabled
        public String dateRangeKickoffDateProjectsEnd {get; set;}
        // Project AFE Date Filters
        @AuraEnabled
        public Boolean next30DaysAFEDateProject {get; set;}
        @AuraEnabled
        public Boolean lastXDaysAFEDateProject {get; set;}
        @AuraEnabled
        public String lastXDaysAFEDateProjectValue {get; set;}
        @AuraEnabled
        public Boolean nextXDaysAFEDateProject {get; set;}
        @AuraEnabled
        public String nextXDaysAFEDateProjectValue {get; set;}
        @AuraEnabled
        public Boolean dateRangeAFEDateProjects {get; set;}
        @AuraEnabled
        public String dateRangeAFEDateProjectsStart {get; set;}
        @AuraEnabled
        public String dateRangeAFEDateProjectsEnd {get; set;}
        // Project RQF Date Filters
        @AuraEnabled
        public Boolean next30DaysRQFDateProject {get; set;}
        @AuraEnabled
        public Boolean lastXDaysRQFDateProject {get; set;}
        @AuraEnabled
        public String lastXDaysRQFDateProjectValue {get; set;}
        @AuraEnabled
        public Boolean nextXDaysRQFDateProject {get; set;}
        @AuraEnabled
        public String nextXDaysRQFDateProjectValue {get; set;}
        @AuraEnabled
        public Boolean dateRangeRQFDateProjects {get; set;}
        @AuraEnabled
        public String dateRangeRQFDateProjectsStart {get; set;}
        @AuraEnabled
        public String dateRangeRQFDateProjectsEnd {get; set;}

        // Opportunity Filters
        @AuraEnabled
        public String opportunitySearch {get; set;}
        @AuraEnabled
        public String opportunityStage {get; set;}
        @AuraEnabled
        public Boolean openOpportunity {get; set;}
        @AuraEnabled
        public Boolean closeDateNext30DaysOpportunity {get; set;}
        @AuraEnabled
        public Boolean closeDateLastXDaysOpportunity {get; set;}
        @AuraEnabled
        public String closeDateLastXDaysOpportunityValue {get; set;}
        @AuraEnabled
        public Boolean closeDateNextXDaysOpportunity {get; set;}
        @AuraEnabled
        public String closeDateNextXDaysOpportunityValue {get; set;}
        @AuraEnabled
        public Boolean estDateNext30DaysOpportunity {get; set;}
        @AuraEnabled
        public Boolean estDateLastXDaysOpportunity {get; set;}
        @AuraEnabled
        public String estDateLastXDaysOpportunityValue {get; set;}
        @AuraEnabled
        public Boolean estDateNextXDaysOpportunity {get; set;}
        @AuraEnabled
        public String estDateNextXDaysOpportunityValue {get; set;}

        // Branch Filters
        @AuraEnabled
        public String branchSearch {get; set;}
        @AuraEnabled
        public String country {get; set;}
        @AuraEnabled
        public String lineOfBusiness {get; set;}
        @AuraEnabled
        public Boolean loadBranchData {get; set;}
        @AuraEnabled
        public Boolean allBranches {get; set;}

        // Set Defaults
        public FilterWrapper() {

            // Users
            this.userTerritories = UserInfo.getUserId();

            // Appointments
            this.todaysAppointments = true;
            this.openAppointments = true;

            // Tasks
            this.todaysTasks = true;
            this.openTasks = true;

            // Accounts
            this.top25Accounts = true;
            this.rankRangeAccountsStart = '1';
            this.rankRangeAccountsEnd = '10';
            this.showOffices = false;
            this.assignedAccountsOnly = false;
            this.includeTracked = false;
            this.searchAccounts = false;

            // Leads
            this.openLeads = true;

            // Projects
            this.next30DaysBidDateProject = true;
            this.next30DaysKickoffDateProject = true;
            this.projectPrimaryType = 'Default';
            this.projectDodgePhase = 'Default';
            this.projectOrigin = '["All"]';
            this.projectCreatedDate = 'All Time';
            this.valuationRangeProjects = true;

            // JobSites
            this.activeJobSites = true;

            // Opportunities
            this.estDateNext30DaysOpportunity = true;
            this.closeDateNext30DaysOpportunity = true;

            // Branches
            this.allBranches = false;
        }
    }

    public class TerritoryWrapper {

        @AuraEnabled
        public String userId {get; set;}

        @AuraEnabled
        public String territoryId {get; set;}

        @AuraEnabled
        public String coordinates {get; set;} 

        public TerritoryWrapper(String userId, String territoryId, String coordinates) {
            this.userId = userId;
            this.territoryId = territoryId;
            this.coordinates = coordinates;
        }
    }

    public class CustomException extends Exception {}
}