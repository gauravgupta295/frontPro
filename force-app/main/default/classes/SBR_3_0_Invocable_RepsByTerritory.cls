public without sharing class SBR_3_0_Invocable_RepsByTerritory {

    private static final String REPID = 'salesRepId';
    private static final String TERRITORY = 'territory';
    private static final String ANALYSIS_REGION = 'mapAnalysisRegion';
    private static final String MAP_SOURCE = 'mapSource';
    private static final String ERRORCODE = 'errorCode';
    private static final String API_FAILURE = 'There was an error finding Sales Reps for this location, please contact crmsupport@sunbeltrentals.com.';
    private static final String NO_REPS_FOUND = 'No Sales Reps were found. Please search for the desired Sales Rep.';
    @InvocableMethod(
      label='Get Reps by Lat/Long'
      description='Call the territory API and return list of sales reps'
    )
    public static List<RepResponse> fetchTerritoryReps(List<RepRequest> repRequests) {
        
        SBR_3_0_API_FetchTerritory territoryFetcher = new SBR_3_0_API_FetchTerritory();
        RepRequest repRequest = repRequests[0];
        List<RepResponse> repResponses = new List<RepResponse>();
        RepResponse repResponse = new RepResponse();
        List<String> repAndTerritoryMap = new List<String>();
        Set<String> repIds = new Set<String>();
        List<String> mapSources = !String.isBlank(repRequest.mapSourceString) ? repRequest.mapSourceString.split(';') : new List<String>();

        List<Object> reps = territoryFetcher.getTerritoryDetails(String.valueOf(repRequest.latitude),String.valueOf(repRequest.longitude),SBR_3_0_Constants.ACCOUNT_API_NAME);
        system.debug('Reps: ' + reps);
        if (reps != null && reps.size() > 0) {

            for (Object rep : reps) {
                if (rep != null && rep instanceof Map<String, Object>) {
                    Map<String, Object> repMap = (Map<String, Object>)rep;
                    if (repMap.containsKey(MAP_SOURCE)) {
                        if (mapSources.size() > 0) {
                            for (String mapSource : mapSources) {
                                system.debug('map source: ' + mapSource);
                                system.debug('map source from api: ' + String.valueOf(repMap.get(MAP_SOURCE)));
                                if (String.valueOf(repMap.get(MAP_SOURCE)) == mapSource) {
                                    repIds.add(String.valueOf(repMap.get(REPID)));
                                    repAndTerritoryMap.add(String.valueOf(repMap.get(REPID) + ':' + String.valueOf(repMap.get(TERRITORY))));
                                }
                            }
                        }
                    }
                    else if (repMap.containsKey(ERRORCODE)) {
                        repResponse.errorMessage = API_FAILURE;
                        system.debug('repmap contains errorcode');
                        repResponses.add(repResponse);
                        return repResponses;
                    }
                }
            }
            if (repIds.size() == 0) {
                system.debug('no reps found by map source');
                for (Object rep : reps) {
                    if (rep != null && rep instanceof Map<String, Object>) {
                        Map<String, Object> repMap = (Map<String, Object>)rep;
                        if (repMap.containsKey(ANALYSIS_REGION)) {
                            if (String.valueOf(repMap.get(ANALYSIS_REGION)) == repRequest.analysisRegion) {
                                system.debug('analysis regions: ' + repMap.get(ANALYSIS_REGION) + '/' + repRequest.analysisRegion);
                                if (repMap.containsKey(REPID) && repMap.containsKey(TERRITORY)) {
                                    repIds.add(String.valueOf(repMap.get(REPID)));
                                    repAndTerritoryMap.add(String.valueOf(repMap.get(REPID) + ':' + String.valueOf(repMap.get(TERRITORY))));
                                }
                            }
                        }
                    }
                }
            }
        }
        if (repIds.size() > 0) {
            system.debug('rep id size: ' + repIds.size());
            //Set<Id> SFRepIds = (new Map<Id, User>([SELECT Id FROM User WHERE RepId__c IN: repIds])).keySet();
            List<User_Location__c> SFReps = [SELECT Id, RepId__c, Rep_Type__c, Analysis_Region_Name__c, Sales_Rep_Name__c, User__c FROM User_Location__c WHERE RepId__c IN: repIds];
            repResponse.users = SFReps;
            repResponse.numberOfReps = SFReps.size();
            repResponse.repAndTerritoryMap = repAndTerritoryMap;
        }
        else {
            repResponse.errorMessage = NO_REPS_FOUND;
        }
        repResponses.add(repResponse);
        return repResponses;
    }

    public class RepRequest {
        @InvocableVariable(label='Latitude' required=true)
        public String latitude;
        @InvocableVariable(label='Longitude' required=true)
        public String longitude;
        @InvocableVariable(label='Analysis Region Key' required=true)
        public String analysisRegion;
        @InvocableVariable(label='Map Source String' required=false)
        public String mapSourceString;
    }

    public class RepResponse {
        @InvocableVariable(label='Error Message' required=false)
        public String errorMessage;
        @InvocableVariable(label='Reps' required=false)
        public List<User_Location__c> users;
        @InvocableVariable(label='Number of reps' required=false)
        public Integer numberOfReps;
        @InvocableVariable(label='Rep and territory map' required=false)
        public List<String> repAndTerritoryMap;
    }
}