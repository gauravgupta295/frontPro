public with sharing class SBR_3_0_API_FetchTimezone_MockFailed implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest request) {
        // Create a fake response
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        if(request.getEndpoint().endsWithIgnoreCase('token')){
            response.setBody('{"access_token":"test"}');
        } else{
            response.setBody('[]');
        }
        response.setStatusCode(200);
        return response; 
    }
}