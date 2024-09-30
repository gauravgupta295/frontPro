@isTest
public class PPA_GeneratePDFHttpCalloutMock_Test implements HttpCalloutMock {

    public HttpResponse respond(HttpRequest req) {
        HttpResponse res = new HttpResponse();

        if(req.getMethod() == 'POST') {
            res.setHeader('Content-Type', 'application/json');

            if(req.getEndpoint().contains('token')) {
                res.setBody('{ "access_token": "12345" }');
                res.setStatusCode(200);
            }
            else if(req.getEndpoint().contains('document')) {
                res.setHeader('Content-Type', 'application/json');
                res.setHeader('x-request-id', '12345');
                res.setBody('{ "status": "In Progress" }');
                res.setStatusCode(201);
            }
            else if(req.getEndpoint().contains('pdf')) {
                res.setHeader('Content-Type', 'application/pdf');
                res.setHeader('x-request-id', '12345');
                res.setStatusCode(201);                
            }
            else if(req.getEndpoint().contains('other')) {
                res.setHeader('x-request-id', '12345');
                res.setStatusCode(201);                
            }
            else {
                res.setStatusCode(400);
            }
        }
        else {
            if(req.getEndpoint().contains('document')) {
                res.setHeader('Content-Type', 'application/pdf');
            	res.setStatusCode(200);
            }
            else if(req.getEndpoint().contains('status')) {
                res.setHeader('Content-Type', 'application/json');
                res.setBody('{ "status": "In Progress" }');
            	res.setStatusCode(200);                
            }
            else if(req.getEndpoint().contains('error')) {
            	res.setStatusCode(400);                                
            }
        }

        return res;
    }
}