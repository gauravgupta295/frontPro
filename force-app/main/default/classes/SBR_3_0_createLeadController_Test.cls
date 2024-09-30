/**
 * Apex Class: SBR_3_0_createLeadController_Test
---------------------------------------------------------------------------------------------------------------------------------------
 * @description       : Test class for SBR_3_0_createLeadController 
 * @author            : Aishwarya Bansal
 * @last modified on  : 03-04-2024
 * @last modified by  : Aishwarya Bansal
**/
@isTest
public class SBR_3_0_createLeadController_Test {
    @TestSetup
    static void makeData(){
        Credential__c cred = SBR_3_0_TestDataFactory.createCredentials(1, false)[0];
        cred.Name = 'Mule_Token_Endpoint';
        cred.Key_Id__c = 'testKey123';
        cred.Secret__c = 'secret';
        insert cred;
    }

    /**
    * @description : Test method for fetching address latitude and longitude based on provided address.
    **/
    @isTest
    static void testGetAddressLatLong() {       
        Test.startTest();
            Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_FetchTimezone_MockSuccess());
            Map<String,String> mapStr = SBR_3_0_createLeadController.getAddressLatLong('line1', 'line2', 'city', 'state','1000','country');
        Test.stopTest();
        Assert.areEqual(mapStr.size()>0, !mapStr.isEmpty());
    }
}