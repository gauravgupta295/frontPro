/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 12-15-2023
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@isTest
private class SBR_3_0_API_UpdateTerritoryDB_Test implements HttpCalloutMock {
    @TestSetup
    static void setup() { 
        String uniqueUserName = 'testAdminUser' + DateTime.now().getTime() + '@SBRtestorg.com';
        // This code runs as the system user
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User testUser = new User(Alias = 'standt', Email = 'standarduser@testorg.com', EmailEncodingKey = 'UTF-8', LastName = 'Testing', LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', ProfileId = p.Id, TimeZoneSidKey = 'America/Los_Angeles', UserName = uniqueUserName);
        insert testUser;

        Credential__c credential = new Credential__c();
        credential.Name = 'Mule_Token_Endpoint';
        credential.Environment__c = SBR_3_0_Constants.SANDBOX;
        credential.Key_Id__c = 'Mule_Token_Endpoint';
        insert credential;

        Account testAccount = new Account();
        testAccount.RM_Account_Number__c = '12345';
        testAccount.Name = 'Test Account';
        testAccount.BillingStreet = '123 Main Street';
        testAccount.BillingCity = 'Toronto';
        testAccount.BillingPostalCode = 'M9N7V5';
        testAccount.BillingState = 'ON';
        testAccount.BillingCountry = 'CA';
        testAccount.Phone = '9123456781';
        insert testAccount;

        Project__c testProject = new Project__c(Project_Name__c = 'Test Project', City__c = 'Test City', State__c = 'IN');
        insert testProject;

    }

    public HTTPResponse respond(HTTPRequest request) {
        // Create a fake response
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setBody('{"success":true,"errorMsg":"","data":""}');
        response.setStatusCode(200);
        return response;
    }

    private static final String APINAME = 'Territory_Account_Update';
    private static final String ACCOUNT = 'Account';
    private static final String PROJECT = 'Project';

    @isTest
    static void testSendAccount() {

        
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_UpdateTerritoryDB_Test());
        User testUser = [SELECT Id FROM User WHERE UserName LIKE 'testAdminUser%'];
        List<Account> accounts = [SELECT Id FROM Account WHERE Name = 'Test Account'];
        System.runAs(testUser) {
            Test.startTest();

            Test.setMock(HttpCalloutMock.class, new SBR_3_0_Generic_Callout_Test());
           // Test.setMock(HttpCalloutMock.class, new SBR_3_0_HttpCallout());
            
            SBR_3_0_API_UpdateTerritoryDB.sendAccount(accounts[0].Id, 12345, 37.12345, -122.54321);

            Test.stopTest();
        }

    }

    @isTest
    static void testSendProject() {
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_UpdateTerritoryDB_Test());
        User testUser = [SELECT Id FROM User WHERE UserName LIKE 'testAdminUser%'];
        List<Project__c> projects = [SELECT Id FROM Project__c WHERE Project_Name__c = 'Test Project'];
        String recordId = String.valueOf(projects[0].Id);

        System.runAs(testUser) {
            Test.startTest();

            Test.setMock(HttpCalloutMock.class, new SBR_3_0_Generic_Callout_Test());
           // Test.setMock(HttpCalloutMock.class, new SBR_3_0_HttpCallout());
            
            SBR_3_0_API_UpdateTerritoryDB.sendProject(recordId, 'ABC123', 37.7749, -122.4194);

            Test.stopTest();
        }
        
    }
}