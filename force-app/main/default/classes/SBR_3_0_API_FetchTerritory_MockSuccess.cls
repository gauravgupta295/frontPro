public with sharing class SBR_3_0_API_FetchTerritory_MockSuccess implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest request) {
        // Create a fake response
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        if(request.getEndpoint().endsWithIgnoreCase('token')){
            response.setBody('{"access_token":"test"}');
        } else{
            //response.setBody('{ "data": { "territories": [ { "pcId": 577, "territory": 21, "section": 1, "territoryId": 1-577-21-1, "mapSource": "PowerCom", "mapAnalysisRegion": 922, "salesRepId": 57713, "salesRepName": "CASLER, JACOB (577) " } ], "prospectType": "Project" } }');
           response.setBody('{ "data": { "territories": [ {     "pcId": 170,"territory": 30,"section": 1,"territoryId": "1-170-30-1","mapSource": "GT","mapAnalysisRegion": 920,"salesRepId": 17005,"salesRepName": "TARDINO, ANTHONY (170)" } ], "prospectType": "Project" } }');
        }
        response.setStatusCode(200);
        return response; 
    }
}