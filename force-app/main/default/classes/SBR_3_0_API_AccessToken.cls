/*********************************************************************************************************************
* Apex Class: SBR_3_0_API_AccessToken_Test
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Provides methods to obtain, store, and retrieve the JSON Web Token (JWT) for authentication to Mulesoft APIs
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Tyler Niggel            2022-03-11          Initial version    
*********************************************************************************************************************/
public without sharing class SBR_3_0_API_AccessToken extends SBR_3_0_HttpCallout {
    private static final String APINAME = 'Mule_Token_Endpoint';
    private static final String TOKENNAME = 'MuleJWT';

    public SBR_3_0_API_AccessToken() {
        super(APINAME);
    }

    public Object getNewJWT() {
        setHeader('Content-Type',SBR_3_0_Constants.APP_ENCODED);
        setRequestBody(getRequestBody());
        HttpResponse res = sendRequest();

        if (checkNullResponse(res)) { // if token request fails once, retry
            res = sendRequest();
            if (checkNullResponse(res)) { // if token request fails again, throw exception
                TokenException tExcept = new TokenException();
                SBR_3_0_LogException.LogIt(tExcept);
                throw tExcept;
            }
        } 
        Object token = SBR_3_0_HttpResponse.getValueForKey(res,SBR_3_0_Constants.TOKEN_KEY);
        return token;
    }

    public Boolean checkNullResponse(HttpResponse res) {
        try {
            Map<String, Object> resMap = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
            if (resMap.get(SBR_3_0_Constants.TOKEN_KEY) == null || resMap == null) {
                return true;
            }
            else {
                return false;
            }
        } catch(Exception e) {
            return true;
        }
    }

    public String getRequestBody() {
        Credential__c creds = credsMap.get(apiMap.get(APINAME).Credential_Name__c);
        String body = 
            'grant_type=client_credentials&client_id='
            + creds.Key_Id__c
            + '&client_secret='
            + creds.Secret__c
            + '&scope=Mulesoft';
        return body;
    }

    public Object getTokenFromCache(String tokenName) {
      
        if (Cache.org.contains(tokenName)) {
            System.debug('Getting Token From Cache->');
            return Cache.Org.get(tokenName);
        } else {
            System.debug('No Tokens in Cache->');
            return null;
        }
    }

    public void putTokenIntoCache(Object token, Integer ttl) {
        Cache.org.put(TOKENNAME, token, ttl);
    }

    public Integer getTokenLifetime() {
        Mulesoft_jwt__c tokenSettings = Mulesoft_jwt__c.getOrgDefaults();
        return (Integer)tokenSettings.Token_Lifetime__c;
    }

    public Object getAccessToken() {
        // Check for cached token 
        Object jwt = getTokenFromCache(TOKENNAME);
       
        // Check if token exists. If the token is invalid or expired, get a new one
        if (jwt == null) {
            // Cache miss 
            jwt = getNewJWT();
            Integer ttl = getTokenLifetime();
            putTokenIntoCache(jwt, ttl);
        }
        return jwt;
    }
    private class TokenException extends Exception {}
}