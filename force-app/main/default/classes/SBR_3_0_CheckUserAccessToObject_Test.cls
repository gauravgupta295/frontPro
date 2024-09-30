/*********************************************************************************************************************
* Apex Class: SBR_3_0_CheckUserAccessToObject_Test
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Test methods for SBR_3_0_CheckUserAccessToObject
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Konrad Haight           2022-09-13          Initial version    
*********************************************************************************************************************/
@isTest public with sharing class SBR_3_0_CheckUserAccessToObject_Test {
    @TestSetup
    static void makeData(){
        createUsers();
        List<Campaign> campaigns = SBR_3_0_TestDataFactory.createCampaigns(1, false, SBR_3_0_Constants.CAMPAIGN_REC_TYPE_SALES);
        campaigns[0].Name = 'Test Campaign';
        insert campaigns;
    }

    @isTest static void testCheckAccess() {
        User u = [SELECT Id FROM User WHERE LastName = 'AccessTest'];
        Campaign c = [SELECT Id FROM Campaign WHERE Name = 'Test Campaign'];
        List<SBR_3_0_CheckUserAccessToObject.CheckUserAccessRequest> requests = new List<SBR_3_0_CheckUserAccessToObject.CheckUserAccessRequest>();
        SBR_3_0_CheckUserAccessToObject.CheckUserAccessRequest request = new SBR_3_0_CheckUserAccessToObject.CheckUserAccessRequest();
        List<SBR_3_0_CheckUserAccessToObject.CheckUserAccessResponse> responses;
        request.userId = u.Id;
        request.recordId = c.Id;
        requests.add(request);
        Test.startTest();
        System.runAs(u){
           responses = SBR_3_0_CheckUserAccessToObject.checkAccess(requests);
        }
        Test.stopTest();

        System.assertEquals(false, responses[0].result);

        
    }
    @future static void createUsers(){
        Profile p = [SELECT Id FROM Profile WHERE Name='Sales'];
        //create ers user clone
        String testUserName = 'testUserName' + DateTime.now().getTime() + '@SBRtestorg.com';
        User testUser = new User(Alias = 'ers', Email='ersuser@testorg.com',
        EmailEncodingKey='UTF-8', LastName='AccessTest', LanguageLocaleKey='en_US',
        LocaleSidKey='en_US', ProfileId = p.Id,
        TimeZoneSidKey='America/Los_Angeles',
        UserName=testUserName);

        insert testUser;


    }
}