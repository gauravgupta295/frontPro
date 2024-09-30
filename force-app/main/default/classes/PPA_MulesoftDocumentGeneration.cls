public class PPA_MulesoftDocumentGeneration {    
    public class customException extends Exception {}

    public static Map<String,String> submitRequest(String priceListId, String customerName, Boolean onlyRatesLoaded, Boolean draftTemplate) {
        Map<String,String> returnVals = new Map<String,String>();
        String accessToken;
        String reqBody;
        String requestId;
        Map<String,Object> reqBodyMap = new Map<String,Object>();

        Http httpObj = new Http();
        HttpRequest req = new HttpRequest();
        HttpResponse res = new HttpResponse();

        try {
            PPA_MulesoftDocumentApi__c docApi = PPA_MulesoftDocumentApi__c.getOrgDefaults();

            if(!Test.isRunningTest()) {
            	returnVals = PPA_MulesoftTokenManager.getAccessToken();
            }
            else {
                returnVals.put('errorCode', '0');
                returnVals.put('accessToken', '12345');
            }

            if(returnVals.get('errorCode') == '0') {
                accessToken = returnVals.get('accessToken');
                
                if(!String.isEmpty(accessToken)) {   
                    req.setEndpoint(docApi.PPA_Base_URL__c + docApi.PPA_Document_Endpoint__c);
                    req.setMethod('POST');
                    req.setHeader('Content-Type', 'application/json');
                    req.setHeader('source', 'SF');
                    req.setHeader('x-correlation-id', priceListId);
                    req.setHeader('Authorization', 'Bearer ' + accessToken);

                    reqBodyMap.put('templateId', docApi.PPA_Template_Id__c);

                    if(!Test.isRunningTest()) {
                    	reqBodyMap.put('inputPayload', PPA_DocumentPayloadGenerator.generatePayload(priceListId, onlyRatesLoaded, draftTemplate));
                    }
                    else {
                        reqBodyMap.put('inputPayload', '{}');                        
                    }
                    
                    reqBody = JSON.serialize(reqBodyMap);
                    system.debug(reqBody);
                    req.setBody(reqBody);
            
                    res = httpObj.send(req);
            
                    if(res.getStatusCode() == 201) {
                        if(res.getHeader('Content-Type').contains('application/json')) {
                            requestId = res.getHeader('x-request-id');

                            JSONParser parser = JSON.createParser(res.getBody());
                            documentResponse parsed = (documentResponse)parser.readValueAs(documentResponse.class);

                            if(parsed.status == 'In Progress' && !String.isEmpty(requestId)) {
                                if(!Test.isRunningTest()) {
                                    PPA_MulesoftDocumentStatus.getDocumentStatusFuture(priceListId, customerName, draftTemplate, requestId, accessToken, 1);                                    
                                }
                                
								returnVals.put('status', 'In Progress');
                            }
                        }
                        else if(res.getHeader('Content-Type').contains('application/pdf')) {
                            if(!Test.isRunningTest()) {
                            	returnVals = PPA_GeneratePDFFileHandler.linkDocumentToPriceList(priceListId, customerName, draftTemplate, res.getBodyAsBlob());
                            }
                            else {
                                returnVals.put('errorCode', '0');
                                returnVals.put('status', 'Completed');
                            }
                        }
                        else {
                        	throw new customException('Invalid Content-type returned');
                        }
                    }
                    else {
                        throw new customException('HTTP Status Code ' + res.getStatusCode());
                    }       
                }
                else {
                    throw new customException('Access token was not valid');
                }
            }
        }
        catch(Exception e) {
            Map<String,String> exceptionParams = new Map<String,String>();
            exceptionParams.put('ClassName', 'PPA_MulesoftDocumentGeneration');
            exceptionParams.put('MethodName', 'submitRequest');
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

    public class documentResponse {
        public String status;
    }
}