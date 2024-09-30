/**
 * @name     SBR_3_0_CalloutMock
 * @author   Salesforce Team at SBR
 * @description Used for unit tests, this class is used for returning mock HTTP Callout responses.
 * @history
 * Ver   Date               Author                   Modification
 * 1.0   Aug 13, 2023       james.loghry@sunbeltrentals.com   Initial Version
 * 2.0   April 17, 2024     evan.kuminski1@sunbeltrentals.com Log received requests to a List for reference in unit tests
 */
@IsTest
@SuppressWarnings('PMD.AvoidDebugStatements, PMD.ClassNamingConventions')
public inherited sharing class SBR_3_0_CalloutMock implements HttpCalloutMock{

    /**
     * @description Contains all HttpRequests sent to the respond() method in the order they were received.
     */
    public List<HttpRequest> requests {get; set;}
    private List<MockResponse> responses {get; set;}

    /**
     * @description Constructs the CalloutMock instance, which is used by the
     * Test.setMock calls in unit tests, for testing callouts.
     * If multiple MockResponse instances are passed in, then they are returned in sequential order.
     * This is useful, for instance, if you're making an authentication call followed immediately by a call to a different service.
     * @param responses - An ordered list of mock responses to return when callouts occur.
     */
    public SBR_3_0_CalloutMock(List<MockResponse> responses){
        this.requests = new List<HttpRequest>();
        this.responses = responses;
    }
    
    /**
     * @description Constructs the CalloutMock instance, which is used by the
     * Test.setMock calls in unit tests, for testing callouts.
     * @param response - A mock response to return when callouts occur.
     */
    public SBR_3_0_CalloutMock(MockResponse response){
        this.requests = new List<HttpRequest>();
        this.responses = new List<MockResponse>{ response };
    }

    /**
     * @description This call is invoked whenever a callout occcurs within a unit test that uses this Mock callout code.
     * @param req - an HttpRequest that is automatically created and passed in by the unit test / callout logic.
     * @return HttpResponse - The HttpResponse that is returned when the current callout is executed.
     */
    public HttpResponse respond(HttpRequest req){
        this.requests.add(req);
        System.debug(LoggingLevel.DEBUG, 'endpoint: ' + req.getEndpoint());
        MockResponse resp = this.responses.get(0);
        
        System.debug(LoggingLevel.DEBUG, 'Callout statuscode: '+ resp.statusCode);
        System.debug(LoggingLevel.DEBUG, 'Callout response: '+ resp.response);
        
        this.responses.remove(0);
        
        //Throws an exception if error is specified.
        if(resp.error != null){
            System.debug(LoggingLevel.DEBUG, 'Callout throwing an exception');
            throw resp.error;
        }
        
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type','application/json');
        res.setBody(resp.response);
        res.setStatusCode(resp.statusCode);
        return res; 
    }

    /**
     * @description When instanciating the Callout Mock in your unit test,
     * first, construct this MockResponse class with the proper response and status code, passing it into
     * the constructor of CalloutMock.
     * If multiple MockResponses are present, they are returned in sequential order. 
     */
    public class MockResponse{
        /**
         * @description The status code the mock response returns (200 = success, 400 = failure / error)
         */
        public Integer statusCode {get; set;}

        /**
         * @description The serialized response string.  Construct a callout class, and then use JSON.serialize, when setting this value.
         */
        public String response {get; set;}
        
        /**
         * @description If not null, this exception is thrown in the respond method.
         */
        public Exception error {get; set;}

        /**
         * @description Construct a MockResponse object
         * @param statusCode The HTTP status code returned when this Mockresponse is returned.
         * 400 (error) typically results in an exception being thrown,  or 200 to indiciate a success.  
         * @param response A string containing a (typically JSON) response, when the callout occurs. 
         */
        public MockResponse(Integer statusCode, String response){
            this(statusCode, response, null);
        }
        
        /**
         * @description Construct a MockResponse object with an exception
         * @param statusCode The HTTP status code returned when this Mockresponse is returned.
         * 400 (error) typically results in an exception being thrown,  or 200 to indiciate a success.
         * @param response A string containing a (typically JSON) response, when the callout occurs.
         * @param ex If specified, this exception is thrown in the respond method.
         */
        public MockResponse(Integer statusCode, String response, Exception ex){
            this.statusCode = statusCode;
            this.response = response;
            this.error = ex;
        }
    }
    
    /**
     * @description Creates an instance of SBR_3_0_CalloutMock to mock callouts which will respond with the JSON
     * representation of responseClass and a response code of 200.
     * @param responseClass Object to use to generate the mock response body
     */
     public static void setMockCallout(Object responseClass) {
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_CalloutMock(new List<MockResponse>{ new MockResponse(200, JSON.serialize(responseClass)) }));
    }
}