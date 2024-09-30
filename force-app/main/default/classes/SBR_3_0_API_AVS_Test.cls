/*********************************************************************************************************************
* Apex Class: SBR_3_0_API_AVS_Test
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Class to test SBR_3_0_API_AVS
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Konrad Haight           2022-03-15            Initial version    
*********************************************************************************************************************/
@isTest public class SBR_3_0_API_AVS_Test {
    private static final String TOKENNAME = 'MuleJWT';
    private static final String ADDRRESULT = 'result';
    private static final String ADDMESSAGE = 'message';
    @TestSetup
    static void makeData(){
       List<Credential__c> creds = SBR_3_0_TestDataFactory.createCredentials(1, false);
        creds[0].Name = 'Mule_Token_Endpoint';
        creds[0].Key_Id__c = 'keyid';
        creds[0].Secret__c ='credSecret';
        insert creds;
    }
    @isTest static void testValidAddress(){
        Test.startTest();
        //adding the token to the cache for the test to circumvent the callout from HTTPCallout class init() function
        Cache.Org.put(TOKENNAME, 'testToken', 850);
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_AVS_CalloutMock(6));
        SBR_3_0_AVSHelper avh = new SBR_3_0_AVSHelper();
        avh.address.line1 = 'address1';
        avh.address.line2 = '';
        avh.address.city = 'City';
        avh.address.state = 'IN';
        avh.address.zip = '99999';
        avh.address.type = 'physical';
        SBR_3_0_API_AVS avs = new SBR_3_0_API_AVS();
        system.debug('AVS:' + avs);
        Map<String, String> resultMap = avs.validateAddress(avh);
        system.debug('Result map: ' + resultMap);
        String result = resultMap.get(ADDRRESULT);
        Test.stopTest();
        System.assertEquals('Valid', result, 'Not returning valid for addrResult == 0');
    }
    @isTest static void testInvalidAddress(){
        Test.startTest();
        //adding the token to the cache for the test to circumvent the callout from HTTPCallout class init() function
        Cache.Org.put(TOKENNAME, 'testToken', 850);
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_AVS_CalloutMock(1));
        SBR_3_0_AVSHelper avh = new SBR_3_0_AVSHelper();
        avh.address.line1 = 'address1';
        avh.address.line2 = '';
        avh.address.city = 'City';
        avh.address.state = 'IN';
        avh.address.zip = '99999';
        avh.address.type = 'physical';
        SBR_3_0_API_AVS avs = new SBR_3_0_API_AVS();
        Map<String, String> resultMap = avs.validateAddress(avh);
        String result = resultMap.get(ADDRRESULT);
        Test.stopTest();
        System.assertEquals('Invalid', result, 'Not returning invalid for addrResult != 0');
    }
    @isTest static void testImproperResponseFormat(){
        Test.startTest();
        //adding the token to the cache for the test to circumvent the callout from HTTPCallout class init() function
        Cache.Org.put(TOKENNAME, 'testToken', 850);
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_AVS_CalloutMock(2));
        SBR_3_0_AVSHelper avh = new SBR_3_0_AVSHelper();
        avh.address.line1 = 'address1';
        avh.address.line2 = '';
        avh.address.city = 'City';
        avh.address.state = 'IN';
        avh.address.zip = '99999';
        avh.address.type = 'physical';
        SBR_3_0_API_AVS avs = new SBR_3_0_API_AVS();
        Map<String, String> resultMap = avs.validateAddress(avh);
        Test.stopTest();
        System.assertEquals(true, resultMap.containsKey(ADDMESSAGE), 'Not returning null for invalid response format');
    }
    @isTest static void testResponseMissingDataKey(){
        Test.startTest();
        //adding the token to the cache for the test to circumvent the callout from HTTPCallout class init() function
        Cache.Org.put(TOKENNAME, 'testToken', 850);
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_AVS_CalloutMock(3));
        SBR_3_0_AVSHelper avh = new SBR_3_0_AVSHelper();
        avh.address.line1 = 'address1';
        avh.address.line2 = '';
        avh.address.city = 'City';
        avh.address.state = 'IN';
        avh.address.zip = '99999';
        avh.address.type = 'physical';
        SBR_3_0_API_AVS avs = new SBR_3_0_API_AVS();
        Map<String, String> resultMap = avs.validateAddress(avh);
        String result = resultMap.get(ADDRRESULT);
        Test.stopTest();
        System.assertEquals('Invalid', result, 'Not returning null for missing data Key');
    }
        @isTest static void testResponseMissingAddressInfoKey(){
        Test.startTest();
        //adding the token to the cache for the test to circumvent the callout from HTTPCallout class init() function
        Cache.Org.put(TOKENNAME, 'testToken', 850);
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_AVS_CalloutMock(4));
        SBR_3_0_AVSHelper avh = new SBR_3_0_AVSHelper();
        avh.address.line1 = 'address1';
        avh.address.line2 = '';
        avh.address.city = 'City';
        avh.address.state = 'IN';
        avh.address.zip = '99999';
        avh.address.type = 'physical';
        SBR_3_0_API_AVS avs = new SBR_3_0_API_AVS();
        Map<String, String> resultMap = avs.validateAddress(avh);
        Test.stopTest();
        System.assertEquals(null, resultMap, 'Not returning null for missing addressInfo Key');
    }
        @isTest static void testResponseMissingAddrResultKey(){
        Test.startTest();
        //adding the token to the cache for the test to circumvent the callout from HTTPCallout class init() function
        Cache.Org.put(TOKENNAME, 'testToken', 850);
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_AVS_CalloutMock(5));
        SBR_3_0_AVSHelper avh = new SBR_3_0_AVSHelper();
        avh.address.line1 = 'address1';
        avh.address.line2 = '';
        avh.address.city = 'City';
        avh.address.state = 'IN';
        avh.address.zip = '99999';
        avh.address.type = 'physical';
        SBR_3_0_API_AVS avs = new SBR_3_0_API_AVS();
        Map<String, String> resultMap = avs.validateAddress(avh);
        Test.stopTest();
        System.assertEquals(null, resultMap, 'Not returning null for missing addrResult Key');
    }
}