public with sharing class SBR_3_0_GenericRESTMockClass implements HttpCalloutMock{
    protected Integer code;
    protected String status;
    protected String body;
    protected Map<string , String> responseHeaders;

    public SBR_3_0_GenericRESTMockClass(Integer code, String status, String body, Map<String,String> responseHeaders) {
        this.code = code;
        this.status = status;
        this.body = body;
        this.responseHeaders = responseHeaders;
    }

    public HTTPResponse respond(HTTPRequest req) {
        //create fake response
        HttpResponse res = new HttpResponse();
        for (String key : this.responseHeaders.keySet()) {
            res.setHeader(key, this.responseHeaders.get(key));
        }
        res.setBody(this.body);
        res.setStatusCode(this.code);
        res.setStatus(this.status);
        return res;
    }
}