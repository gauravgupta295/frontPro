public with sharing class SBR_3_0_API_FetchGeoJson extends SBR_3_0_HttpCallout {
    private static final String APINAME = 'Territory_GeoJson';
    private static final String DATA = 'data';
    private static final String COORDINATES = 'coordinates';

    public SBR_3_0_API_FetchGeoJson() {
        super(APINAME);
    }

    private String getResponseBody() {

        //HttpResponse res = sendRequest();
        try {
            //System.debug('Response Body: ');
            System.debug('URL -> '+ endpointURL);
            //System.debug(res.getBody());
            //System.debug(JSON.serialize(res.getBody()));
            System.debug('Apex Limit before untyping... ' + Limits.getHeapSize());
            return sendRequest().getBody();
        } catch(Exception e) {
            System.debug('Response body not in correct format for JSON.deseralizeUntyped, error message: ' + e.getMessage());
            return null;
        }
    }

    public String getTerritoryGeoJson(String territoryId) {
        Map<String, String> returnValue = new Map<String, String>();
        List<Object> coordinateData = new List<Object>();
        setHeader('companyID', '1');
        setHeader('Content-Type', SBR_3_0_Constants.APP_JSON);
        setQueryParam('territoryId', territoryId);
        
        String result = getResponseBody();
        //System.debug('Apex Limit after untyping... ' + Limits.getHeapSize());
        System.debug('result -> ' + result);
        
        return result;
        /*
        if (result != null && result instanceof Map<String, Object>) {
            Map<String, Object> resultMap = (Map<String, Object>) result;
            if(resultMap.containsKey(DATA) && resultMap.get(DATA) instanceof Map<String, Object>) {
                Map<String, Object> data = (Map<String, Object>)resultMap.get(DATA);
                if(data.containsKey(COORDINATES)) {
                    coordinateData = (List<Object>)data.get(COORDINATES);
                    System.debug('coordinateData -> ' + coordinateData);
                }
            }
        }
        */
        //return coordinateData;
    }
}