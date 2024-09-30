@isTest
public with sharing class SBR_3_0_Invocable_AVS_Test {
    private static final String TOKENNAME = 'MuleJWT';
    @TestSetup
    static void makeData(){
        List<Credential__c> creds = SBR_3_0_TestDataFactory.createCredentials(1, false);
        creds[0].Name = 'Mule_Token_Endpoint';
        creds[0].Key_Id__c = 'keyid';
        creds[0].Secret__c ='credSecret';
        insert creds;
    }

    @isTest
    static void testValidateAssociatedLocation() {

        List<SBR_3_0_Invocable_AVS.AVSRequest> requests = new  List<SBR_3_0_Invocable_AVS.AVSRequest>();
        SBR_3_0_Invocable_AVS.AVSRequest request = new SBR_3_0_Invocable_AVS.AVSRequest();
        request.city = 'x';
        request.state = 'IN';
        request.streetOne = '123 Fake St.';
        request.zip = '99999';
        request.country = 'US';
        requests.add(request);

      Test.startTest();
      Test.setMock(HttpCalloutMock.class, new SBR_3_0_AVS_CalloutMock(6));
      Cache.Org.put(TOKENNAME, 'testToken', 850);
        List<SBR_3_0_Invocable_AVS.AVSResponse> responses = SBR_3_0_Invocable_AVS.validateAddress(requests);
      Test.stopTest();
      
      
      System.assertEquals(
        'Valid',
        responses[0].result,
        'Address validation field not updated'
      );
    }
    @isTest
    static void testValidateAssociatedLocationCA() {

        List<SBR_3_0_Invocable_AVS.AVSRequest> requests = new  List<SBR_3_0_Invocable_AVS.AVSRequest>();
        SBR_3_0_Invocable_AVS.AVSRequest request = new SBR_3_0_Invocable_AVS.AVSRequest();
        request.city = 'x';
        request.state = 'IN';
        request.streetOne = '123 Fake St.';
        request.zip = '99999';
        request.country = 'CA';
        requests.add(request);

      Test.startTest();
      Test.setMock(HttpCalloutMock.class, new SBR_3_0_AVS_CalloutMock(6));
      Cache.Org.put(TOKENNAME, 'testToken', 850);
        List<SBR_3_0_Invocable_AVS.AVSResponse> responses = SBR_3_0_Invocable_AVS.validateAddress(requests);
      Test.stopTest();
      
      
      System.assertEquals(
        'Valid',
        responses[0].result,
        'Address validation field not updated'
      );
    }
}