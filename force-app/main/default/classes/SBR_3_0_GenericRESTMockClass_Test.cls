@isTest
Private class SBR_3_0_GenericRESTMockClass_Test {

    @isTest
    static void ResponseTest()
    {
        Map<string,string> headers = new Map<string,string>();
        headers.put('accept', 'application/json');
        SBR_3_0_GenericRESTMockClass mock = new SBR_3_0_GenericRESTMockClass(200,'Success', 'testBody',headers );
        HTTPResponse response = mock.respond(new HTTPRequest());
        system.Assert(response.getStatus() == 'Success');
    }
}