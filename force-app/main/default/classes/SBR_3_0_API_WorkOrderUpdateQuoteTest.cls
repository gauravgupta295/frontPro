@isTest
public with sharing class SBR_3_0_API_WorkOrderUpdateQuoteTest Implements HttpCalloutMock {
	 static Boolean SUCCESS = true;

    static HttpResponse res;


    public HTTPResponse respond(HTTPRequest req) {
        // Create a fake response
        res = new HttpResponse();
        res.setHeader('Content-Type',SBR_3_0_Constants.APP_JSON);
        res.setBody('{ "error": { "message": "Invalid input parameters, parameters might contain special characters, SQL statements or script statements. Please check application logs for more information.", "errorKey": "BAD_REQUEST", "errorCode": "400-000" } }');
        res.setStatusCode(400);
        return res;
    }
	
	

}