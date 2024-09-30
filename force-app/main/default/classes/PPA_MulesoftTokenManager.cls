public class PPA_MulesoftTokenManager {
    public class customException extends Exception {}

    public static Map<String,String> getAccessToken() {
        Map<String,String> returnVals = new Map<String,String>();
        String reqBody;
        Http httpObj = new Http();
        HttpRequest req = new HttpRequest();
        HttpResponse res = new HttpResponse();

        try {
            PPA_MulesoftDocumentApi__c docApi = PPA_MulesoftDocumentApi__c.getOrgDefaults();
    
            req.setEndpoint(docApi.PPA_Base_URL__c + docApi.PPA_Token_Endpoint__c);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
            
            reqBody = 'grant_type=client_credentials&scope=Mulesoft&client_id=';
            reqBody = reqBody + EncodingUtil.urlEncode(docApi.PPA_Client_Id__c,'UTF-8') + '&client_secret=';
            reqBody = reqBody + EncodingUtil.urlEncode(docApi.PPA_Client_Secret__c,'UTF-8');
            req.setBody(reqBody);
    
            res = httpObj.send(req);
    
            if(res.getStatusCode() == 200) {
                JSONParser parser = JSON.createParser(res.getBody());
                tokenResponse parsed = (tokenResponse)parser.readValueAs(tokenResponse.class);
                returnVals.put('errorCode', '0');
                returnVals.put('accessToken', parsed.access_token);
            }
            else {
				throw new customException('HTTP Status Code ' + res.getStatusCode());
            }    
        }
        catch(Exception e) {
            Map<String,String> exceptionParams = new Map<String,String>();
            exceptionParams.put('ClassName', 'PPA_MulesoftTokenManager');
            exceptionParams.put('MethodName', 'getAccessToken');
            exceptionParams.put('Type', e.getTypeName());
            exceptionParams.put('LineNumber', String.valueOf(e.getLineNumber()));
            exceptionParams.put('StackTrace', e.getStackTraceString());
            exceptionParams.put('Message', e.getMessage());
            PPA_ExceptionLogHandler.createExceptionLog(exceptionParams);

            returnVals.put('errorCode', '-1');
            returnVals.put('errorMsg', e.getMessage());
        }

        return returnVals;
    }

    public class tokenResponse {
        public String token_type;
        public String expires_in;
        public String access_token;
        public String scope;
    }
}