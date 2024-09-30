/*********************************************************************************************************************
* Apex Class: SBR_3_0_API_FetchLatLong
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - This class is to be used for retrieving Latitude and Longitude for a given address
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME                        DATE                DETAIL FEATURES
    1.0         Hashem Abdul                        2022-08-18            Initial version    
*********************************************************************************************************************/


public without sharing class SBR_3_0_API_FetchLatLong extends SBR_3_0_HttpCallout{
    private static final String APINAME = 'Address_Geocode';
    private static final String DATA = 'data';
    private static final String RESULTS = 'results';
    private static final String GEOMETRY = 'geometry';
    private static final String GEOMETRYLOCATION = 'location';
    private static final String ADDRESSCOMPONENTS = 'addressComponents';
    private static final String ADDRESSTYPES = 'types';
    private static final String LATITUDE = 'latitude';
    private static final String LONGITUDE = 'longitude';
    private static final String CITY_ADDR = 'city';
    private static final String STATE_ADDR = 'state';
    private static final String PROVINCE = 'province';
    private static final String STATENODE = 'administrative_area_level_1';
    private static final String CITYNODE = 'locality';
    private static final String SHORTNAMEPROPERTY = 'shortName';
    private static final String LONGNAMEPROPERTY = 'longName';

    // SAL-24521
    private static final String GEOINFO = 'geoInfo';
    private static final String TIMEZONE = 'timezone';
    private static final String TIMEZONE_ID = 'id';
    private static final String TIMEZONE_NAME = 'name';
    private static final String TIMEZONE_OFFSET = 'rmOffset';

    public SBR_3_0_API_FetchLatLong() {
        super(APINAME);
    }

    private Object getResponseBody(String fullAddress, String country){
        if(!apiMap.get(APINAME).Is_JWT_Enabled__c){
            Credential__c creds = credsMap.get(apiMap.get(APINAME).Credential_Name__c);
            setHeader('client_secret', creds.Secret__c);
            setHeader('client_id', creds.Key_Id__c);
            system.debug('Applying Credential__c: ');
            System.debug(creds);
        }
        setHeader('x-correlation-Id', SBR_3_0_Generic.generateRandomString(10));
        setQueryParam('address', fullAddress);
        // SAL-24521
        setQueryParam('timestamp', SBR_3_0_API_FetchLatLong.getGenerateTimeStamp());
        setQueryParam('includeRMOffset', 'true');
        setQueryParam('location', '');
        HttpRequest req = getRequest();

        system.debug(req.getEndpoint());
        HttpResponse res = new Http().send(req);
        try{
            system.debug('Response Body: ');
            system.debug(JSON.serialize(res.getBody()));
            return JSON.deserializeUntyped(res.getBody());	
        } catch(Exception e){
            System.debug('Response body not in correct format for JSON.deseralizeUntyped, error message: ' + e.getMessage());
            return null;
        }
    }

    // Updated as per SF - 6121 to include city, state as well 
    public Map<String, String> getAddressLatLong(String line1, String line2, String city, String state, String zip, String country){
        Map<String, String> returnValue = new Map<String, String>();
        String fullAddress = (String.isEmpty(line1) ? '' : line1) + (String.isEmpty(line2) ? '' : ', ' + line2) + (String.isEmpty(city) ? '' : ', ' + city);
        fullAddress += (String.isEmpty(state) ? '' : ', ' + state) + (String.isEmpty(zip) ? '' : ', ' + zip);
        Object result = getResponseBody(fullAddress, country);

        if (result != null && result instanceof Map<String, Object>) {
            Map<String, Object> resultMap = (Map<String, Object>)result;
            if(resultMap.containsKey(DATA) && resultMap.get(DATA) instanceof Map<String, Object>){
                Map<String, Object> data = (Map<String, Object>)resultMap.get(DATA);
                if(data.containsKey(GEOINFO)){
                    Map<String, Object> geoinfos = (Map<String, Object>)data.get(GEOINFO);
                        if(geoinfos.containsKey(LATITUDE)){
                            returnValue.put(LATITUDE, String.valueOf(geoinfos.get(LATITUDE)));
                        }
                        if(geoinfos.containsKey(LONGITUDE)){
                            returnValue.put(LONGITUDE, String.valueOf(geoinfos.get(LONGITUDE)));
                        }
                        // Added to parse city, state (province)   - SF-6121
                        /* sample json response we get  {"data":{"geoInfo":{"city":"Washington","province":"District of Columbia",
                        "country":"United States","zipCode":"20001","latitude":38.912068,"longitude":-77.0190228},
                        "timezone":{"id":"America/New_York","name":"Eastern Standard Time","dstOffset":0,"rawOffset":-18000,
                        "rmOffsetForStandardTime":0,"rmOffsetForDaylightSavingTime":10}}}
                        */
                        if(geoinfos.containsKey(CITY_ADDR)){
                            returnValue.put(CITY_ADDR, String.valueOf(geoinfos.get(CITY_ADDR)));
                        }
                        if(geoinfos.containsKey(PROVINCE)){  // response has it named as province but we need to save as state for use in other places
                            returnValue.put(STATE_ADDR, String.valueOf(geoinfos.get(PROVINCE)));
                        }
                }
            }
        }
        return returnValue;
    }

    // SAL-24521
    // add getTimezoneFields func with params : address line 1, line 2 .. + lat/long
    public Map<String, String> getTimezoneFields(String line1, String line2, String city, String state, String zip, String country, String lat, String longt, Boolean offsetFlag){
        Map<String, String> returnValue = new Map<String, String>();
        String fullAddress = (String.isEmpty(line1) ? '' : line1) + (String.isEmpty(line2) ? '' : ', ' + line2) + (String.isEmpty(city) ? '' : ', ' + city);
        fullAddress += (String.isEmpty(state) ? '' : ', ' + state) + (String.isEmpty(zip) ? '' : ', ' + zip);
        Object result = getGeoTimeResponseBody(fullAddress, country, offsetFlag, lat, longt);

        if (result != null && result instanceof Map<String, Object>) {

            Map<String, Object> resultMap = (Map<String, Object>)result;
            if(resultMap.containsKey(DATA) && resultMap.get(DATA) instanceof Map<String, Object>){
                Map<String, Object> data = (Map<String, Object>)resultMap.get(DATA);
                if(data.containsKey(TIMEZONE)){
                    Map<String, Object> timezoneNode = (Map<String, Object>)data.get(TIMEZONE);
                    if(timezoneNode.containsKey(TIMEZONE_ID)){
                        returnValue.put(TIMEZONE_ID, String.valueOf(timezoneNode.get(TIMEZONE_ID)));
                    }
                    if(timezoneNode.containsKey(TIMEZONE_NAME)){
                        returnValue.put(TIMEZONE_NAME, String.valueOf(timezoneNode.get(TIMEZONE_NAME)));
                    }
                    if(timezoneNode.containsKey(TIMEZONE_OFFSET)){
                        returnValue.put(TIMEZONE_OFFSET, String.valueOf(timezoneNode.get(TIMEZONE_OFFSET)));
                    }
                }
            }
        }

        return returnValue;
    }

    // SAL-24521
    private Object getGeoTimeResponseBody(String fullAddress, String country, Boolean flag, String lat, String longt){
        if(!apiMap.get(APINAME).Is_JWT_Enabled__c){
            Credential__c creds = credsMap.get(apiMap.get(APINAME).Credential_Name__c);
            setHeader('client_secret', creds.Secret__c);
            setHeader('client_id', creds.Key_Id__c);
            system.debug('Applying Credential__c: ');
            System.debug(creds);
        }
        setHeader('x-correlation-Id', SBR_3_0_Generic.generateRandomString(10));
        setQueryParam('address', fullAddress);
        setQueryParam('timestamp', SBR_3_0_API_FetchLatLong.getGenerateTimeStamp());
        setQueryParam('includeRMOffset', String.valueOf(flag));
        if(!String.isBlank(lat) && !String.isBlank(longt)){
            setQueryParam('location', lat+','+longt);
        }
        
        HttpRequest req = getRequest();

        system.debug(req.getEndpoint());
        HttpResponse res = new Http().send(req);
        try{
            system.debug('Response Body: ');
            system.debug(JSON.serialize(res.getBody()));
            return JSON.deserializeUntyped(res.getBody());	
        } catch(Exception e){
            System.debug('Response body not in correct format for JSON.deseralizeUntyped, error message: ' + e.getMessage());
            return null;
        }
    }

    // SAL-24521
    public static String getGenerateTimeStamp() {
        return String.valueof(DateTime.now().getTime()/1000);
    }
}