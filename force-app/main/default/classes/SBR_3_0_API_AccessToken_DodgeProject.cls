public without sharing class SBR_3_0_API_AccessToken_DodgeProject extends SBR_3_0_HttpCallout {
    private static final String APINAME = 'Dodge_Token_Endpoint';
    private static final String TOKENNAME = 'DodgeToken';
    private static final String SOAPAction = 'http://constructionpoints.com/2011/07/token/ISecureToken/GetToken';

    public SBR_3_0_API_AccessToken_DodgeProject() {
        super(APINAME);
    }

    public Object getNewToken() {
        setHeader('Content-Type',SBR_3_0_Constants.TEXT_XML);
        setHeader('SOAPAction',SOAPAction);
        setRequestBody(getRequestBody());
        HttpResponse res = sendRequest();
        if (res == null){
            TokenException tExcept = new TokenException();
            SBR_3_0_LogException.LogIt(tExcept);
            throw tExcept;
        }
        String xmlTagName ='token';
        Object token = SBR_3_0_HttpResponse.getValueFromXMLTags(res,xmlTagName);
        if (token == null) {
            TokenException tExcept = new TokenException();
            SBR_3_0_LogException.LogIt(tExcept);
            throw tExcept;
        }
        return token;
    }

    public Object getAccessToken() {
        // Check for cached token 
        Object token = getTokenFromCache(TOKENNAME);

        // Check if token exists. If the token is invalid or expired, get a new one
        if (token == null) {
            // Cache miss 
            token = getNewToken();
            Integer ttl = getTokenLifetime();
            putTokenIntoCache(token, ttl);
        }
        return token;
    }

    public Object getTokenFromCache(String tokenName) {
        if (Cache.org.contains(tokenName)) {
            return Cache.Org.get(tokenName);
        } else {
            return null;
        }
    }

    public void putTokenIntoCache(Object token, Integer ttl) {
        Cache.org.put(TOKENNAME, token, ttl);
    }

    public Integer getTokenLifetime() {
        Token_Lifetime__c tokenSettings = Token_Lifetime__c.getOrgDefaults();
        return (Integer)tokenSettings.Dodge_Token__c;
    }

    public String getRequestBody() {
        Credential__c creds = credsMap.get(apiMap.get(APINAME).Credential_Name__c);

        String body ='<?xml version="1.0" encoding="utf-8"?>'
            + '<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">'
            + '<soap:Body>'
            + '<GetToken xmlns="http://constructionpoints.com/2011/07/token">'
            + '<username>'
            + creds.Key_Id__c 
            +'</username>'
            +'<password>'
            + creds.Secret__c
            + '</password>'
            + '</GetToken>'
            + '</soap:Body>'
            + '</soap:Envelope>';
        return body;
    }

    

    private class TokenException extends Exception {}
}