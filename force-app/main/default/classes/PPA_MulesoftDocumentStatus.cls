public class PPA_MulesoftDocumentStatus {
    public class customException extends Exception {}
    
    public static Map<String,String> getDocumentStatus(String priceListId, String customerName, Boolean draftTemplate, String requestId, String accessToken, Integer retryCount) {
		DateTime start = System.Now();
        Map<String,String> returnVals = new Map<String,String>();

        Http httpObj = new Http();
        HttpRequest req = new HttpRequest();
        HttpResponse res = new HttpResponse();

        try {
            PPA_MulesoftDocumentApi__c docApi = PPA_MulesoftDocumentApi__c.getOrgDefaults();
            
            if(!Test.isRunningTest()) {
                while(System.Now().getTime()< start.getTime()+5000){} //Delay
            }

            req.setEndpoint(docApi.PPA_Base_URL__c + docApi.PPA_Document_Endpoint__c + '/' + requestId);
            req.setMethod('GET');
            req.setHeader('Authorization', 'Bearer ' + accessToken);
                    
            res = httpObj.send(req);
            
            if(res.getStatusCode() == 200) {
                if(res.getHeader('Content-Type').contains('application/pdf')) {
                    if(!Test.isRunningTest()) {
                    	returnVals = PPA_GeneratePDFFileHandler.linkDocumentToPriceList(priceListId, customerName, draftTemplate, res.getBodyAsBlob());
                    }
                    else {
                        returnVals.put('errorCode', '0');
                    	returnVals.put('status', 'Completed');                        
                    }
                }
                else {
                    JSONParser parser = JSON.createParser(res.getBody());
                    statusResponse parsed = (statusResponse)parser.readValueAs(statusResponse.class);            
                    
                    if(parsed.status == 'In Progress') {
                        if(retryCount < 8) {
                            returnVals = getDocumentStatus(priceListId, customerName, draftTemplate, requestId, accessToken, retryCount+1);
                        }
                        else {
                            if(!System.isFuture()) {
                                getDocumentStatusFuture(priceListId, customerName, draftTemplate, requestId, accessToken, 1);
                                returnVals.put('errorCode', '0');
                                returnVals.put('status', 'In Progress');
                            }
                        }
                    }
                }    
            }
            else {
                throw new customException('HTTP Status Code ' + res.getStatusCode());
            }       
        }
        catch(Exception e) {
            Map<String,String> exceptionParams = new Map<String,String>();
            exceptionParams.put('ClassName', 'PPA_MulesoftDocumentStatus');
            exceptionParams.put('MethodName', 'getDocumentStatus');
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

    @future(callout=true)
    public static void getDocumentStatusFuture(String priceListId, String customerName, Boolean draftTemplate, String requestId, String accessToken, Integer retryCount) {
        Map<String,String> returnVals = getDocumentStatus(priceListId, customerName, draftTemplate, requestId, accessToken, retryCount);
    }

    public class statusResponse {
        public String status;
    }
}