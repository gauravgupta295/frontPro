/*********************************************************************************************************************
* Apex Class: SBR_3_0_API_SendgridService_Test
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Test class for SBR_3_0_API_SendgridService
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Davinder Singh         2022-12-11          Initial version    
*********************************************************************************************************************/
@isTest
public with sharing class SBR_3_0_API_SendgridService_Test implements HttpCalloutMock{
    
    @TestSetup
    static void makeData(){

        Credential__c cred = SBR_3_0_TestDataFactory.createCredentials(1, false)[0];
        cred.Name = 'Mule_Token_Endpoint';
        cred.Key_Id__c = 'testKey123';
        cred.Secret__c = 'secret';
        insert cred;
      
        Account acct = new Account(
            RM_Account_Number__c = '12345',
            Name = SBR_3_0_API_Web_Jobsite_DA.JOBSITEACCOUNTNAME,
            BillingStreet = '123 Main Street',
            BillingCity = 'test',
            BillingPostalCode = '20173',
            BillingState = 'VA',
            BillingCountry = 'US',
            Company_Code__c = '1',
            Phone='3322114455'
        );
        insert acct;
        
        EmailMessage emMessage = new EmailMessage(
            Subject ='Test Subject',
            HtmlBody = 'Test Body',
            FromAddress= 'QAnoreply@service.sunbeltrentals.com',
            FromName='No Reply - SunnBelt Rentals',
            ToAddress='test@test.com',
            BccAddress='test2@test.com',
            Status = '3',
            RelatedToId = acct.Id );
      //  insert emMessage;
      
        List<AppDefinition> app=[SELECT DurableId, Label FROM AppDefinition where label='RAE Frontline'];
        Map<String,Object> fldValByFldName = new Map<String,Object> {
            'AppDefinitionId' =>app[0].DurableId ,
            'FormFactor' => 'Large',
            'UserId' => UserInfo.getUserId()
        };
        List<UserAppInfo> info=new List<UserAppInfo>{(UserAppInfo)JSON.deserialize(JSON.serialize(fldValByFldName),UserAppInfo.class)};
        insert info;           

    }

    public HTTPResponse respond(HTTPRequest req) {
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type',SBR_3_0_Constants.APP_JSON);
        if(req.getEndpoint().endsWithIgnoreCase('token')){
            res.setBody('{"access_token":"test"}');
        }else {
            res.setBody('{"data":{"message":"Email triggered successfully","status":"Success"}}');
        }
        res.setStatusCode(200);
        return res;
    }


    @isTest
    static void testSendEmail() {

       try{
            Account acc = [SELECT Id,Name FROM Account Limit 1];
            SBR_3_0_SendgridWrapper.EmailWrapper emailDetails = new SBR_3_0_SendgridWrapper.EmailWrapper();
            emailDetails.subject='Test Subject';
            emailDetails.body='Test Body';
            emailDetails.frm='test@test.com';
            emailDetails.frmName='Test Name';
            emailDetails.toAddress=new List<String> {'test@test.com'};
            emailDetails.recId=acc.Id;
            String emailStr = JSON.serialize(emailDetails);

            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_SendgridService_Test());
            SBR_3_0_API_SendgridService.invokeSendgridAPI(emailStr);
            Test.stopTest();
        } catch (Exception e) {
            System.assertEquals('Email could not be sent, please try later', e.getMessage(), 'Exception should be thrown');
        }
    }

}