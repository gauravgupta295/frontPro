/*********************************************************************************************************************
* Apex Class: SBR_3_0_GeneratePOPDFController_Test
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Mock class for Apex Class SBR_3_0_GeneratePOPDFController, SBR_3_0_GeneratePOPDF, SBR_3_0_RetrievePOPDF
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         
---------------------------------------------------------------------------------------------------------------------------------------
Note:-
* 
*********************************************************************************************************************/
@isTest
global class SBR_3_0_GeneratePOPDFController_Mock implements HttpCalloutMock{
    
    global HttpResponse respond(HTTPRequest req) {
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('companyId', '1');
        
        String body = req.getBody();
        if(req.getEndpoint().endsWithIgnoreCase('token')){
            res.setHeader('Content-Type','application/octet-stream');
            res.setBody('{"access_token":"test"}');
            res.setStatusCode(200);
        } else if(req.getEndpoint().containsIgnoreCase('communication')){
            res.setHeader('Content-Type','application/json');
            if(body.containsIgnoreCase('activitytype') && !body.containsIgnoreCase('error')){
                res.setBody('{"data":{"message":"Email triggered successfully","status":"Success"}}');
                res.setStatusCode(200);
            } else {
                res.setBody('error');
            }
        } else {
            res.setStatusCode(200);
            if((String.isNotBlank(body) && (body.contains('887796990')||body.contains('887796993')))||req.getEndpoint() == 'endpoint/123456'){
                res.setHeader('Content-Type','application/octet-stream');
                res.setBody('%PDF starts form here');
            } else if((String.isNotBlank(body) && body.contains('887796991')) || req.getEndpoint() == 'endpoint/123457'){
                res.setBody('{"status": "In Progress"}');
                res.setHeader('x-request-id', '123456');
            } else if((String.isNotBlank(body) && body.contains('887796992')) || req.getEndpoint() == 'endpoint/123458'){
                res.setHeader('Content-Type','application/json');
                res.setBody('{"error": {"message": "Required key [templateId] is invalid", "errorKey": "BAD_REQUEST", "errorCode": "400-000"}}');
            }
        }
        return res;
    }
}