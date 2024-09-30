public with sharing class SBR_3_0_API_FetchTimezone_MockSuccess implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest request) {
        // Create a fake response
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        if(request.getEndpoint().endsWithIgnoreCase('token')){
            response.setBody('{"access_token":"test"}');
        } else{
            response.setBody('{"data":{"geoInfo":{"streetAddress":"Hyannis Drive","city":"Avon","province":"Indiana","country":"United States","zipCode":"46123","latitude":39.7712298,"longitude":-86.3710359},"timezone":{"id":"America/Indiana/Indianapolis","name":"Eastern Daylight Time","dstOffset":3600,"rawOffset":-18000,"rmOffset":0}}}');
        }
        response.setStatusCode(200);
        return response; 
    }
}