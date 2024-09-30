@isTest
public with sharing class SBR_3_0_API_FetchLatLongTest {
@TestSetup
    static void makeData(){
        Credential__c cred = SBR_3_0_TestDataFactory.createCredentials(1, false)[0];
        cred.Name = 'Mule_Token_Endpoint';
        cred.Key_Id__c = 'testKey123';
        cred.Secret__c = 'secret';
        insert cred;
    }
    @isTest
    static void testGetAddressLatLong() {       
        Test.startTest();
            Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_FetchTimezone_MockSuccess());
        	SBR_3_0_API_FetchLatLong fetchTerritory = new SBR_3_0_API_FetchLatLong();
            Map<String,String> mapStr = fetchTerritory.getAddressLatLong('line1', 'line2', 'city', 'state','1000','country');
        Test.stopTest();
        system.assert(!mapStr.isEmpty());
    }

    @isTest
    static void testGetAddressTimeZone() {    
        Test.startTest();
            Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_FetchTimezone_MockSuccess());
        	SBR_3_0_API_FetchLatLong fetchTerritory = new SBR_3_0_API_FetchLatLong();
            Map<String,String> mapStr = fetchTerritory.getTimezoneFields('line1', 'line2', 'city', 'state','1000','country', '', '', true);
        Test.stopTest();
        system.assert(!mapStr.isEmpty());
    }

    @isTest 
    static void testGetAddressLatLongError(){
        Test.startTest();
            Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_FetchTimezone_MockFailed());
            try{
                SBR_3_0_API_FetchLatLong fetchTerritory = new SBR_3_0_API_FetchLatLong();
                Map<String,String> mapStr = fetchTerritory.getAddressLatLong('123', 'line2', 'city', 'state','1000','country');
            }catch(Exception e){
                System.assertEquals('testGetAddressLatLongError', e.getMessage(), 'Response body not in correct format for JSON.deseralizeUntyped, error message: ');
            }
        Test.stopTest();
    }

    @isTest 
    static void testGetAddressTimeZoneError(){
        Test.startTest();
            Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_FetchTimezone_MockFailed());
            try{
                SBR_3_0_API_FetchLatLong fetchTerritory = new SBR_3_0_API_FetchLatLong();
                Map<String,String> mapStr = fetchTerritory.getTimezoneFields('123', 'line2', 'city', 'state','1000','country', '', '', true);
            }catch(Exception e){
                System.assertEquals('testGetAddressTimeZoneError', e.getMessage(), 'Response body not in correct format for JSON.deseralizeUntyped, error message: ');
            }
        Test.stopTest();
    }
}