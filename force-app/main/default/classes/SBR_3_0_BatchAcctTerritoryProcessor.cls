public with sharing class SBR_3_0_BatchAcctTerritoryProcessor implements Database.Batchable<sObject>, Database.AllowsCallouts{

    private Account[] accounts;
    private Set<Id> acctIds;
    private Set<Id> acctParentIds;
    private static final String TERRITORY = 'Territory';
    private static final Integer DEFAULT_RANK = 99999;
    private static final String PROSPECT_RT_ID = SBR_3_0_Constants.ACCOUNT_PROSPECT_RT_ID;
    private static final String OFFICE_RT_ID = SBR_3_0_Constants.ACCOUNT_OFFICE_RT_ID;
    private static final String ACCOUNT = 'Account';

    public SBR_3_0_BatchAcctTerritoryProcessor(sObject[] records) {
        accounts = (Account[])records;

    }
    public sObject[] start(Database.BatchableContext context) {
        return accounts;
    }
    public void execute(Database.BatchableContext context, sObject[] scope) {
        getTerritories();
    }
    public void finish(Database.BatchableContext context) {
    }

    private void getTerritories() {
        Map<Account,List<Territories>> responses = new Map<Account,List<Territories>>();
        SBR_3_0_API_FetchTerritory fetch = new SBR_3_0_API_FetchTerritory();
        acctIds = new Set<Id>();
        acctParentIds = new Set<Id>();
        for(Account a : accounts) {
            String lat = String.valueOf(a.Street_Address_LatLong__Latitude__s);
            String lon = String.valueOf(a.Street_Address_LatLong__Longitude__s);
            acctIds.add(a.Id);
            acctParentIds.add(a.ParentId);
            List<Object> resp = fetch.getTerritoryDetails(lat,lon, ACCOUNT);
            String respStr = (JSON.serialize(resp)).replace('\n','');
            System.debug('\n respStr = ' + respStr);
            List<Territories> wr = (List<Territories>) System.JSON.deserialize(respStr, List<Territories>.class);
            responses.put(a,wr);
        }
        updateTerritoriesInSF(responses);
    }

    private void updateTerritoriesInSF(Map<Account,List<Territories>> responses) {
        Set<String> territoryIds = new Set<String>();
        Set<String> SalesRepIds = new Set<String>();
        for(Account a : responses.keySet()) {
            for(Territories t : responses.get(a)) {
                territoryIds.add(t.territoryId);
                SalesRepIds.add(String.valueOf(t.salesRepId));
            }
        }
		Map<String,User> mUser = SBR_3_0_UserDA.getUserMapBySalesRepIds(SalesRepIds);
        Map<String,Id> territories = getTerritoriesById(territoryIds);
        Map<String,Account_Relationship__c> existingReln = getExistingRelationshipInfo(territoryIds);
        Map<Id,List<Account_Relationship__c>> allExistingReln = getAllExistngRelationships(territoryIds);
        List<Account_Relationship__c> relationshipsToAdd = new List<Account_Relationship__c>();
        List<Account_Relationship__c> relationshipsToDelete = new List<Account_Relationship__c>();
        Set<Id> acctDeleteTracker = new Set<Id>();

        for(Account a : responses.keySet()) {
            for(Territories t : responses.get(a)) {
                //only add Account relationship if the related territory exists in SF
                if(territories.containsKey(t.territoryId)) {
                    String externalId = a.Id + '' + t.territoryId;
                    Decimal rank = DEFAULT_RANK;
                    String type = TERRITORY;

                    //for Office Accounts, find rank and types
                    if(a.RecordTypeId == OFFICE_RT_ID && existingReln.containsKey(t.territoryId)) {
                        rank = existingReln.get(t.territoryId).Rank__c;
                        type = existingReln.get(t.territoryId).Type__c;
                    }
                    
					Account_Relationship__c accRln = new Account_Relationship__c(
                        Name = t.mapSource + ' - ' + t.territoryId + ' - ' + a.Id, 
                        Account_ID__c = a.Id,
                        Rank__c = rank,
                        External_ID__c = externalId,
                        Type__c = TERRITORY,
                        PC_Number__c = String.valueOf(t.pcId), 
                        Sales_Rep_ID__c = t.salesRepId,
                        Analysis_Region__c = String.valueOf(t.mapAnalysisRegion),
                        Territory__c = territories.get(t.territoryId)
                    );
                    if(mUser.containsKey(String.valueOf(t.salesRepId))){
                    	User oUser = mUser.get(String.valueOf(t.salesRepId)); 
                        accRln.User_Account__c = oUser.id;
                    }
                    relationshipsToAdd.add(accRln);
                    if(allExistingReln.containsKey(a.Id) && !acctDeleteTracker.contains(a.Id)) {
                        relationshipsToDelete.addAll(allExistingReln.get(a.Id));
                        acctDeleteTracker.add(a.Id);
                    }
                }
            }
            Integer rmAcctNum = String.isNotBlank(a.RM_Account_Number_Display__c) ? Integer.valueOf(a.RM_Account_Number_Display__c) : null;
            SBR_3_0_API_UpdateTerritoryDB.sendAccount(a.Id, rmAcctNum, a.Street_Address_LatLong__Latitude__s , a.Street_Address_LatLong__Longitude__s);
        }

        //delete existing since if address had changed, those need to be gottne rid of
        if(relationshipsToDelete.size() >0 ) {
            delete relationshipsToDelete;
        }

        if(relationshipsToAdd.size() > 0) {
            upsert relationshipsToAdd External_ID__c;
        }
    }
    
    private Map<String,Id> getTerritoriesById(Set<String> territoryIds) {
        Map<String,Id> territories = new Map<String,Id> ();
        for(Territory__c t : [SELECT Territory_Id__c, Id FROM Territory__c WHERE Territory_Id__c IN :territoryIds ]){
            territories.put(t.Territory_Id__c, t.Id);
        }
        return territories;
    }

    private Map<String,Account_Relationship__c> getExistingRelationshipInfo(Set<String> territoryIds) {
        Map<String,Account_Relationship__c> accountReln = new Map<String,Account_Relationship__c> ();
        for( Account_Relationship__c ar: [ SELECT Id, Rank__c, Type__c  FROM Account_Relationship__c 
            WHERE Account_ID__c IN :acctParentIds AND Territory_ID_hr__c IN :territoryIds AND Rank__c!=null AND Rank__c!=99999]) {
                ar.put(ar.Territory_ID_hr__c, ar);
        }
        return accountReln;
    }

    private Map<Id,List<Account_Relationship__c>> getAllExistngRelationships(Set<String> territoryIds) {
        Map<Id,List<Account_Relationship__c>> accountReln = new Map<Id,List<Account_Relationship__c>>();
        for( Account_Relationship__c ar: [ SELECT Id, Account_Id__c, Rank__c, Type__c  FROM Account_Relationship__c 
            WHERE (Account_ID__c IN :acctIds) ]) {
                if(accountReln.containsKey(ar.Account_Id__c)) {
                    List<Account_Relationship__c> ars = accountReln.get(ar.Account_Id__c);
                    ars.add(ar);
                    accountReln.put(ar.Account_Id__c,ars);
                }
                else {
                    List<Account_Relationship__c> ars = new List<Account_Relationship__c> ();
                    ars.add(ar);
                    accountReln.put(ar.Account_Id__c,ars);
                }
        }
        return accountReln;
    }



    public class Territories {
        public Integer pcId;
        public Integer territory;
        public Integer section;
        public String territoryId;
        public String mapSource;
        public Integer mapAnalysisRegion;
        public Integer salesRepId;
        public String salesRepName;
    }
}