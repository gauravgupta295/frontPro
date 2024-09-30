@isTest
public with sharing class SBR_3_0_API_CreateWorkOrdTest Implements HttpCalloutMock  {
	      public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse resp = new HTTPResponse();
            resp.setStatusCode(200);
            resp.setHeader('Content-Type',SBR_3_0_Constants.APP_JSON);
            resp.setBody('{"workOrderNumber": "123456", "rmClaimId": "RM123456"}');
            return resp;
        }

    }