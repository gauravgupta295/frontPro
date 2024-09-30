public with sharing class SBR_3_0_API_FetchTerritory extends SBR_3_0_HttpCallout{
    private static final String APINAME = 'Territory_Check';
    private static final String DATA = 'data';
    private static final String TERRITORIES = 'territories';
    private static final String ERROR = 'error';
    // public enum Types {Account, Project}
    // Types acc= Types.Account;

    public SBR_3_0_API_FetchTerritory(){
        super(APINAME);
    }

    private Object getResponseBody(){
        //system.debug('request body'+ (getRequest()));
        HttpResponse res = sendRequest();
        try{
            system.debug('Response Body: ');
            System.debug('URL'+ endpointURL);
            system.debug(JSON.serialize(res.getBody()));
            return JSON.deserializeUntyped(res.getBody());	
        } catch(Exception e){
            System.debug('Response body not in correct format for JSON.deseralizeUntyped, error message: ' + e.getMessage());
            return null;
        }
    }

    public Map<String, String> getTerritoryIdOwnerMatch(String lat, String lon, String Acc){
        Map<String, String> returnValue = new Map<String, String>();
        
        setHeader('companyId', '1');
        setHeader('Content-Type', SBR_3_0_Constants.APP_JSON);
        setQueryParam('latitude', lat);
        setQueryParam('longitude', lon);
        setQueryParam('prospectType', Acc);
        
        //setQueryParam(Types.Account);

        
        Object result = getResponseBody();
        System.debug('result-'+result);
        Id userid=UserInfo.getUserId();
        System.debug(userid);
        User repid=[Select RepID__c from user where id=: userid];
        System.debug(repid);

        if (result != null && result instanceof Map<String, Object>) {
            Map<String, Object> resultMap = (Map<String, Object>)result;
            if(resultMap.containsKey(DATA) && resultMap.get(DATA) instanceof Map<String, Object>){
                Map<String, Object> data = (Map<String, Object>)resultMap.get(DATA);
                if(data.containsKey(TERRITORIES)){
                    List<Object> territoryInfo = (List<Object>)data.get(TERRITORIES);
                    System.debug(territoryInfo);
                    for(Object obj: territoryInfo){
                        Map<String , Object> TerryMap = (Map<String, Object>) obj; 
                        if (TerryMap.containsKey('territoryId')){
                            String terriId=String.valueOf(TerryMap.get('territoryId'));
                            Territory__c terr= [Select Id,OwnerId from Territory__c where Territory_Id__c=:terriId limit 1];
                            if(terr.OwnerId==userid){
                                System.debug('Hello');
                                returnValue.put(TERRITORIES,terriId);
                            }
                        }    
                    }
                }
            }
        }

        return returnValue;
    }


    public List<Object> getTerritoryDetails(String lat, String lon, String Acc){
        Map<String, String> returnValue = new Map<String, String>();
        List<Object> territoryInfo1 = new List<Object>();
        setHeader('companyId', '1');
        setHeader('Content-Type', SBR_3_0_Constants.APP_JSON);
        setQueryParam('latitude', lat);
        setQueryParam('longitude', lon);
        setQueryParam('prospectType', Acc);
        
        //setQueryParam(Types.Account);

        
        Object result = getResponseBody();
        System.debug('result-'+result);
        // Id userid=UserInfo.getUserId();
        // User repid=[Select RepID__c from user where id=: userid];
        // System.debug(repid);

        if (result != null && result instanceof Map<String, Object>) {
            Map<String, Object> resultMap = (Map<String, Object>)result;
            if(resultMap.containsKey(DATA) && resultMap.get(DATA) instanceof Map<String, Object>){
                Map<String, Object> data = (Map<String, Object>)resultMap.get(DATA);
                if(data.containsKey(TERRITORIES)){
                    territoryInfo1 = (List<Object>)data.get(TERRITORIES);
                    System.debug(territoryInfo1);                
                }
            }
            else if (resultMap.containsKey(ERROR)) {
                system.debug('Territory API Error');
                territoryInfo1.add((Map<String, Object>)resultMap.get(ERROR));
            }
        }
        return territoryInfo1;
    }

}


// SBR_3_0_API_FetchTerritory sh = new SBR_3_0_API_FetchTerritory();
// List<Object> returnval = sh.getTerritoryDetails('37.790291','-122.3972452','Account');
// System.debug(returnval);

// // Select Name, Territory_Id__c, OwnerId, Id from Territory__c where Territory_Id__c ='32254438'

// Select Id,Name,OwnerId from Territory__c where Territory_Id__c='1-506-20-1'