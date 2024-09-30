/*********************************************************************************************************************
* Apex Class: SBR_3_0_HttpCallout
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Class with generic Http callout base methods. Most methods can be overridden
* - SAL
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Viren Patel           2022-02-07           Initial version    
*********************************************************************************************************************/
public with sharing virtual class SBR_3_0_HttpCallout {

    protected Global_API_Settings__mdt conn;
    protected HttpRequest request;
    public String endpointURL {get; protected set;}//PS-4171/SD/01/04/24;
    protected String requestBody;
    protected Blob requestBodyAsBlob;
    protected Map<String, String> queryParamsMap;
    protected Map<String, String> headersMap;
    protected Integer requestTimeout;
    protected List<Object> pathParams;

    public Map<String, Global_API_Settings__mdt> apiMap;
    public Map<String, Credential__c> credsMap;
    public static String contractId = '';
    public static String dateSelected = '';

    public Boolean isSuccessful {
        public get {return isSuccessful;}
        private set;
    }

    public SBR_3_0_HttpCallout() {
        initialize();
    }

    public SBR_3_0_HttpCallout(String apiName) {
        initialize();
        setConnection(apiName);
    }

    public HTTPRequest getRequest() {
        try{
            createHttpRequest();   
        }catch(Exception e){
            SBR_3_0_LogException.LogIt(e);
        }

        /*system.debug('\n endpoint = ' + endpointURL);
        system.debug('\n Resource = ' + conn.Resource__c);
        system.debug('\n Path = ' + conn.Path_Params__c);
        system.debug('\n method = ' + conn.Method__c);
        system.debug('\n headers = ' + headersMap);
        system.debug('\n params = ' + queryParamsMap);
        system.debug('\n string body = ' + requestBody);*/
        return request;
    }

    public virtual HttpRequest createHttpRequest() {
        request = new HTTPRequest();
        appendQueryParams();
        request.setEndpoint(getEndpoint());
        request.setMethod(conn.Method__c);
        request.setTimeout(requestTimeout);
        addHeaders();
        setBody();
        return request;
    }

    public HttpResponse sendRequest() {
        return sendRequest(new Set<Integer> { 200 });
    }

    public HttpResponse sendRequest(Set<Integer> validCodes) {
        // System.debug('createHTTPRequest -> ' + createHTTPRequest());
        HttpResponse response = new Http().send(createHTTPRequest());
        // System.debug('\n Response = \n' + response.getBody());

        if(!validCodes.contains(response.getStatusCode())) {
            isSuccessful = false;
        }
        else {
            isSuccessful = true;
        }
        return response;
    }

    public virtual void setConnection(String settingAPIName) {
        System.debug('\n vp = apiName setConn =' + settingAPIName);
        if(apiMap.containsKey(settingAPIName)) {
            conn = apiMap.get(settingAPIName);
            if(conn!=null) {
                endpointURL = conn.Protocol__c + '://' + conn.Host__c + conn.Resource__c;
                if(conn.Path_Params__c == '/') {
                endpointURL += conn.Path_Params__c;
                }
				system.debug('endpointURL in setconnection'+endpointURL);
                if(settingAPIName == 'Create_Payments_API' || settingAPIName == 'Create_UCP_API' || settingAPIName == 'Create_ROA_API'){
                    List<Object> parameters = new List<Object> { contractId };
                    String formatted = String.format(endpointURL, parameters); 
                    endpointURL = formatted;
                }else if(settingAPIName == 'GET_TILL_SUMMARY' || settingAPIName == 'GET_NEW_DEPOSITS'  || settingAPIName == 'GET_ADDITIONAL_DEPOSITS' || settingAPIName == 'GET_ROA_CASH_CONTROL' || settingAPIName == 'GET_INTERCOMPANY_DETAILS' || settingAPIName == 'GET_CASH_INVOICE'){
                    List<Object> parameters = new List<Object> { dateSelected };
                    String formatted = String.format(endpointURL, parameters); 
                    endpointURL = formatted;
                }
                system.debug('endpointURL in setconnection --- >'+endpointURL);
                requestTimeout = (conn.Timeout__c!=null) ? Integer.valueOf(conn.Timeout__c)*1000 : 10000;
                
                // Use JWT
                if(conn.Is_JWT_Enabled__c){
                    SBR_3_0_API_AccessToken acToken = new SBR_3_0_API_AccessToken();
                    Object act = acToken.getAccessToken();//acToken.getNewJWT();
                    setHeader('Authorization', 'Bearer ' + String.valueOf(act));
                    system.debug('Access Token: ' + String.valueOf(act));
                }
            }
        }
    }

    public virtual void setHeader(String key, String value) {
        if(String.isNotEmpty(key) && String.isNotEmpty(value)) {
            headersMap.put(key, value);
        }
    }

    public void setHeadersMap(Map<String, String> headers) {
        headersMap.putAll(headers);
    }

    public virtual void setQueryParam(String key, String value) {
        if(String.isNotEmpty(key) && String.isNotEmpty(value)) {
            queryParamsMap.put(key, value);
        }
    }

    public void setQueryParamsMap(Map<String, String> queryParams) {
        queryParamsMap.putAll(queryParams);
    }

    public virtual void setRequestBody(String requestBody) {
		if(!String.isBlank(requestBody)) {
            this.requestBody = requestBody;
        }
    }
    
    public virtual void setRequestBody(Blob requestBody) {
		if(requestBody != Blob.valueOf('')) {
            this.requestBodyAsBlob = requestBody;
        }
	}

    public virtual void setPathParams(List<String> pathParamsx) {
        pathParams = pathParamsx;
        String template = conn.Path_Params__c;     //eg - /{0}
        if(template!=null){
            conn.Path_Params__c = String.format(template, pathParams);
            endpointURL += conn.Path_Params__c;   
        }
    }

    public virtual String getPathParams(Global_API_Settings__mdt c, List<String> prms) {
        String template = c.Path_Params__c;     //eg - /{0}
        return String.format(template, prms);
    }

    public virtual String getCredName() {
        return (conn!=null) ? conn.Credential_Name__c : null;
    }

    private virtual String getEndpoint() {
        if(conn!= null && !String.isBlank(conn.Named_Credential_API_Name__c)) {
            return 'callout:' + conn.Named_Credential_API_Name__c;
        }
        else {
            return endpointURL;
        }
    }

    private virtual void addHeaders() {
        for(String key : headersMap.keySet()) {
            request.setHeader(key, headersMap.get(key));
        }
    }

    private virtual void appendQueryParams() {
        Set<String> keys = queryParamsMap.keySet();
        if(!keys.isEmpty()) {
            endpointURL += '?';
            for(String key : keys) {
                endpointURL += key + '=' + EncodingUtil.urlEncode(queryParamsMap.get(key), 'UTF-8') + '&';
            }
            endpointURL = endpointURL.substringBeforeLast('&');
        }
    }

    private virtual void setBody() {
        if(!String.isBlank(requestBody)) {
            request.setBody(requestBody);
        } else if(requestBodyAsBlob != Blob.valueOf('')) {
            request.setBodyAsBlob(requestBodyAsBlob);
        }
    }

    private virtual void initialize() {
        system.debug('\n init');
        apiMap = SBR_3_0_APISettings.getAPIMap();
        credsMap = SBR_3_0_APISettings.getCredsMap();
        queryParamsMap = new Map<String, String>();
        pathParams = new List<Object>();
        headersMap = new Map<String, String>();
        requestTimeout = 10;
        requestBodyAsBlob = Blob.valueOf('');

        System.debug('\n callout apimap = ' + apiMap);
    }

    public class ServiceException extends Exception {}    
}