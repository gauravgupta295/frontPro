@isTest
private class SBR_3_0_UserSessionDetailsTest {

    @isTest
    static void testFetchUserSessionId() {
        // Call the method under test
        String sessionId = SBR_3_0_UserSessionDetails.fetchUserSessionId();
        
        // Assert that session id is not null or empty
        System.assertNotEquals(null, sessionId);
        System.assertNotEquals('', sessionId);
    }

    @isTest
    static void testFetchUserEmailAddress() {
        // Call the method under test
        String userEmail = SBR_3_0_UserSessionDetails.fetchUserEmailAddress();
        
        // Assert that user email address is not null or empty
        System.assertNotEquals(null, userEmail);
        System.assertNotEquals('', userEmail);
    }

    @isTest
    static void testOktaPasswordVerification() {
        // Mocking variables
        String pswddata = 'dummyPassword';
        String responseBody = 'Dummy response from Okta';
        
        // Mocking the callout
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody));
        
        // Call the method under test
        String response = SBR_3_0_UserSessionDetails.oktaPasswordVerification(pswddata);
        
        // Assert that response is not null or empty
        System.assertNotEquals(null, response);
        // Additional assertions can be added based on the expected behavior of the method
    }
    
    // Inner class to mock HTTP callout response
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        private String responseBody;

        MockHttpResponseGenerator(String responseBody) {
            this.responseBody = responseBody;
        }

        public HTTPResponse respond(HTTPRequest req) {
            // Create a fake response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody(responseBody);
            res.setStatusCode(200);
            return res;
        }
    }
}