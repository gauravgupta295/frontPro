@isTest
public class SBR_3_0_API_SyncAccountTest Implements HttpCalloutMock{
    static HttpResponse res;
    static Boolean SUCCESS = true;
    
   @TestSetup
    static void makeData()
    {
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        
        String uName = 'admin' + DateTime.now().getTime() + '@SBRtestorg.com';
        User admin = new User(Alias = 'admin', Email='adminuser1@testorg.com',RepId__c='1092345',
        EmailEncodingKey='UTF-8', LastName='Admin1', LanguageLocaleKey='en_US',
        LocaleSidKey='en_US', ProfileId = p.Id,
        TimeZoneSidKey='America/Los_Angeles',
        UserName=uName, CompanyName='01');
        insert admin;

        Schema.Location loc = new Schema.Location();
        loc.recordTypeId = SBR_3_0_Constants.LOCATION_BRANCH_RT_ID;
        loc.Name = '1799 Innovation Point';
        loc.Street_Address__c = '1799 Innovation Point';
        loc.State__c = 'SC';
        loc.Zip_Code__c = '29715';
        loc.Branch_Location_Number__c = '0411';
        loc.Company_Code__c = '01';
        insert loc;

        User_Location__c ul = new User_Location__c(User__c = admin.Id, Branch__c = loc.Id);
        insert ul;

        Credential__c cred = SBR_3_0_TestDataFactory.createCredentials(1, false)[0];
        cred.Name = 'Mule_Token_Endpoint';
        cred.Key_Id__c = 'testKey123';
        cred.Secret__c = 'secret';
        insert cred;
    }
    public HTTPResponse respond(HTTPRequest req) {
        // Create a fake response
        res = new HttpResponse();
        res.setHeader('Content-Type',SBR_3_0_Constants.APP_JSON);
        if(req.getEndpoint().endsWithIgnoreCase('token')){
            res.setBody('{"access_token":"test"}');
            res.setStatusCode(200);
        }else if(SUCCESS) {
            res.setBody('{"data": {"crossReferenceNumber": "00000000000000000277","rentalmanCashCustomerNumber": "246"}}');
            res.setStatusCode(200);
        }
        return res;
    }
    @isTest 
    static void testCreateAccountSuccess() {
        User admin = [SELECT Id from User WHERE Email='adminuser1@testorg.com' AND LastName='Admin1' LIMIT 1];
        System.runAs(admin)
        {
            //Create Account 
            List<Account> accLst =  SBR_3_0_TestDataFactory.createAccounts(1, false, 'Non_Credit');
            Account testAcc = accLst[0];
            testAcc.Email__c = 'test@test.com';
            testAcc.Driver_s_License_State__c = 'CA';
            testAcc.Drivers_License__c = '123AD';
            testAcc.Company_Code__c = '01';
            testAcc.Date_of_Birth__c = System.today() -1;
            testAcc.BirthDate__c = System.today() -1;
            testAcc.Billing_Street1__c = 'TestStreet';
            testAcc.BillingPostalCode = '20100';
            insert testAcc;
            system.debug('account in Test Calss is --' + testAcc );
            
            Map<Id,Account> newAccMap = new Map<Id, Account>();
            newAccMap.put(testAcc.id, testAcc);
            
            Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_SyncAccountTest());
            Test.startTest();
            //SBR_3_0_API_CreateWorkOrder.CreateWorkOrderRMCallout(input);
            //SBR_3_0_AccountOperationsFrontLine.checkAccount(List<Account> accLst, Map<Id,Account> newAccMap, Map<Id,Account> oldAccMap, 'POST');
            SBR_3_0_AccountOperationsFrontLine.checkAccount(accLst, newAccMap, null, 'POST');
            Test.stopTest();
            
            Account acc = [SELECT id, Non_Credit_Integration_Status__c FROM Account WHERE id=:testAcc.id];
            System.assertNotEquals(acc.Non_Credit_Integration_Status__c, null);
        }
    }
}