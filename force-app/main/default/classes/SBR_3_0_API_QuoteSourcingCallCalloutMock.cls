@isTest
global with sharing class SBR_3_0_API_QuoteSourcingCallCalloutMock implements HttpCalloutMock {
  static Boolean SUCCESSTEST = true;

  global HTTPResponse respond(HTTPRequest request) {
    // Create a fake response
    HttpResponse response = new HttpResponse();
    response.setHeader('Content-Type', SBR_3_0_Constants.APP_JSON);
    if (request.getEndpoint().endsWithIgnoreCase('token')) {
      response.setBody('{"access_token":"test"}');
      response.setStatusCode(200);
    } else if (SUCCESSTEST) {
      response.setBody('{"data": {' + '"pc": "720",' + '"latitude": 48.51,' + '"longitude": -117.62,' + '"companyId": "01",' + '"timezoneId": "America/New_York",' + '"isLastResortBranch": true}}');
      response.setStatusCode(200);
    } else {
      response.setBody('{ "error": { "message": "Invalid input parameters, parameters might contain special characters, SQL statements or script statements. Please check application logs for more information.", "errorKey": "BAD_REQUEST", "errorCode": "400-000" } }');
      response.setStatusCode(400);
    }
    return response;
  }
}