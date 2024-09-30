/*********************************************************************************************************************
* Apex Class: SBR_3_0_SendEmailCmpController_Mock
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Mock class for Apex Class SBR_3_0_SendEmailCmpController_Test
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
	1.0         Piyush Jindal           2023-11-28          Initial version
---------------------------------------------------------------------------------------------------------------------------------------
Note:-
* 
*********************************************************************************************************************/
@isTest
global class SBR_3_0_SendEmailCmpController_Mock implements HttpCalloutMock{
    
    global HttpResponse respond(HTTPRequest req) {
        
        // Create a fake response
        HttpResponse res = new HttpResponse();

        res.setHeader('companyId', '1');
        res.setHeader('Content-Type',SBR_3_0_Constants.APP_JSON);
        
        if(req.getEndpoint().endsWithIgnoreCase('token')){
            res.setBody('{"access_token":"test"}');
        } else if (req.getBody().containsIgnoreCase('activitytype') && !req.getBody().containsIgnoreCase('error')) {
            system.debug('else if req.getBody() : '+req.getBody());
			res.setBody('{"data":{"message":"Email triggered successfully","status":"Success"}}');
        } else {
            system.debug('else req.getBody() : '+req.getBody());            
			res.setBody('error');
        }
        
        res.setStatusCode(200);
        
        return res;
    }
}