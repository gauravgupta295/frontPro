public without sharing class SBR_3_0_Invocable_RepsByTerritoryNoAR {

    private static final String REPID = 'salesRepId';
    @InvocableMethod(
      label='Get Reps by Lat/Long no Analysis Region'
      description='Call the territory API and return list of sales reps'
    )
    public static List<RepResponse> fetchTerritoryReps(List<RepRequest> repRequests) {
        
        SBR_3_0_API_FetchTerritory territoryFetcher = new SBR_3_0_API_FetchTerritory();
        RepRequest repRequest = repRequests[0];
        List<RepResponse> repResponses = new List<RepResponse>();
        RepResponse repResponse = new RepResponse();
        Set<String> repIds = new Set<String>();

        List<Object> reps = territoryFetcher.getTerritoryDetails(String.valueOf(repRequest.latitude),String.valueOf(repRequest.longitude),SBR_3_0_Constants.ACCOUNT_API_NAME);
        system.debug('Reps: ' + reps);
        if (reps != null) {

            for (Object rep : reps) {  
                if (rep != null && rep instanceof Map<String, Object>) {
                    Map<String, Object> repMap = (Map<String, Object>)rep;
                            if (repMap.containsKey(REPID)) {
                                repIds.add(String.valueOf(repMap.get(REPID)));
                            }
                    }
                }
            }
        else {
            repResponse.errorMessage = 'no reps for lat long provided (or some other error)';
        }
        Set<Id> SFRepIds = (new Map<Id, User>([SELECT Id FROM User WHERE RepId__c IN: repIds])).keySet();
        List<User_Location__c> SFReps = [SELECT Id, RepId__c, Rep_Type__c, Sales_Rep_Name__c, User__c FROM User_Location__c WHERE User__c IN: SFRepIds];
        repResponse.users = SFReps;
        repResponse.numberOfReps = SFReps.size();
        repResponses.add(repResponse);
        return repResponses;


    }

    @AuraEnabled
    public static List<User_Location__c> getTerritoryRepsByCoordinates(Double latitude, Double longitude) {
        SBR_3_0_API_FetchTerritory territoryFetcher = new SBR_3_0_API_FetchTerritory();
        Set<String> repIds = new Set<String>();
        List<Object> reps = territoryFetcher.getTerritoryDetails(String.valueOf(latitude), String.valueOf(longitude), SBR_3_0_Constants.ACCOUNT_API_NAME);
		
        if (reps != null) {
            for (Object rep : reps) {
                if (rep != null && rep instanceof Map<String, Object>) {
                    Map<String, Object> repMap = (Map<String, Object>) rep;
                    if (repMap.containsKey(REPID)) {
                        repIds.add(String.valueOf(repMap.get(REPID)));
                    }
                }
            }
        } else {
            
            return null;
        }

        Set<Id> SFRepIds = (new Map<Id, User>([SELECT Id FROM User WHERE RepId__c IN :repIds])).keySet();
        List<User_Location__c> SFReps = [SELECT Id, User__c, RepId__c, Rep_Type__c, Sales_Rep_Name__c, Analysis_Region2__c, Analysis_Region2__r.Name FROM User_Location__c WHERE User__c IN :SFRepIds];
		System.debug('SFReps '+SFReps);

        return SFReps;
    }
    
    public class RepRequest {
        @InvocableVariable(label='Latitude' required=true)
        public String latitude;
        @InvocableVariable(label='Longitude' required=true)
        public String longitude;
    }

    public class RepResponse {
        @InvocableVariable(label='Error Message' required=false)
        public String errorMessage;
        @InvocableVariable(label='Reps' required=false)
        public List<User_Location__c> users;
        @InvocableVariable(label='Number of reps' required=false)
        public Integer numberOfReps;
    }
}