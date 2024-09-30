/*********************************************************************************************************************
* Apex Class: SBR_3_0_ManageWebsiteUserControllerTest
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - This Test Calss is created for handeling Invited,Edited,Searched in SBR_3_0_ManageWebsiteUserIntegration class
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Saathvik Tulasi      2023-20-07             Initial version    
********************************************************************************************************************/
@isTest(seeAllData=false) 
public class SBR_3_0_ManageWebsiteUserControllerTest Implements HttpCalloutMock{
    public HTTPResponse respond(HTTPRequest oRequest) {
        HttpResponse oResponse = new HttpResponse();
        oResponse.setHeader('Content-Type',SBR_3_0_Constants.APP_JSON);
        if(oRequest.getEndpoint().endsWithIgnoreCase('users')){
            System.debug('Company Id : '+oRequest.getHeader('companyId'));
            if(oRequest.getHeader('companyId') == '02'){
                oResponse.setBody('{"error":{"message":"Company id is not valid. Error occurred, please refer application logs for more details","errorKey":"BAD_REQUEST","errorCode":"400-000"}}');
				oResponse.setStatusCode(201);
            }
            else{
                oResponse.setBody('{"data":{"companyCode":"01","accountNumber":"560324","users":[{"email":"uscredit4uat1@gmail.com","firstName":"Test","lastName":"Test","lastLoginDateTime":"2022-01-05T14:36:22Z"},{"email":"uscredit3.uat@sbrtbtc.com","firstName":"Ususer","lastName":"Credit","lastLoginDateTime":"2022-01-05T14:36:22Z"}]}}');
            	oResponse.setStatusCode(200);
            }
        }
        else if(oRequest.getEndpoint().endsWithIgnoreCase('invite')){
            if(oRequest.getHeader('companyId') == '02'){
                oResponse.setBody('{"data":{"message":"USER_PART_OF_ACCOUNT"}}');
                oResponse.setStatusCode(201);
            }
            else{
				oResponse.setBody('{"data":{"userType":"cash","firstName":"Cash","lastName":"User"}}');
                oResponse.setStatusCode(200);                
            }
        }
        else if(oRequest.getEndpoint().endsWithIgnoreCase('accounts')){
            if(oRequest.getHeader('email') == 'josh28704test2@yopmail.com'){
                oResponse.setBody('{"data":{"email":"josh28704test2@yopmail.com","firstName":"Josh","lastName":"Forte","address":{"line1":"4078 Booney Rd","line2":"","line3":"","city":"Rock Hill","state":"SC","postalCode":"29730-6201","phone":"8032804267"},"driverlicenseNumber":"","driverlicenseState":"","accountType":"credit","accounts":[{"accountNumber":81,"accountName":"ZACHRY INDUSTRIAL-MERSA","corpLinkNumber":186849},{"accountNumber":181,"accountName":"ORKIN PEST CONTROL","corpLinkNumber":181},{"accountNumber":11001,"accountName":"ORKIN PEST CONTROL","corpLinkNumber":181}]}}');
                oResponse.setStatusCode(200);
            }
            else if(oRequest.getHeader('email') == 'josh28704test3@yopmail.com'){
                oResponse.setBody('{"data":{"email":"josh28704test3@yopmail.com","firstName":"Josh","lastName":"Forte","address":{"line1":"4078 Booney Rd","line2":"","line3":"","city":"Rock Hill","state":"SC","postalCode":"29730-6201","phone":"8032804267"},"driverlicenseNumber":"","driverlicenseState":"","accountType":"cash","accounts":[{"accountNumber":81,"accountName":"ZACHRY INDUSTRIAL-MERSA","corpLinkNumber":186849},{"accountNumber":181,"accountName":"ORKIN PEST CONTROL","corpLinkNumber":181},{"accountNumber":11002,"accountName":"ORKIN PEST CONTROL","corpLinkNumber":181}]}}');
                oResponse.setStatusCode(200);
            }
            else if(oRequest.getHeader('email') == 'josh28704test4@yopmail.com'){
                oResponse.setBody('{"error":{"message":"Unable to process the request","errorKey":"INTERNAL_SERVER_ERROR","errorCode":"500-001"}}');
                oResponse.setStatusCode(201);
            }
            else if(oRequest.getHeader('email') == ''){
                oResponse.setBody('{"error":{"message":"Unable to process the request","errorKey":"INTERNAL_SERVER_ERROR","errorCode":"500-001"}}');
                oResponse.setStatusCode(201);
            }
        }
        else if(oRequest.getEndpoint().contains('email?search')){
            if(oRequest.getEndpoint().endsWithIgnoreCase('Test1')){
                oResponse.setBody('{"data":{"users":[{"email":"john..doe136@yopmail.com"},{"email":"john.006@yopmail.com"},{"email":"john.01@yopmail.com"},{"email":"john.1001@yopmail.com"},{"email":"john.36@yopmail.com"}]}}');
                oResponse.setStatusCode(200);
            }
            else if(oRequest.getEndpoint().endsWithIgnoreCase('Test2')){
                oResponse.setBody('{"error":{"message":"Unable to process the request","errorKey":"INTERNAL_SERVER_ERROR","errorCode":"500-001"}}');
                oResponse.setStatusCode(201);
            }
        }
        else{
            oResponse.setBody('{"token_type":"Bearer","expires_in":900,"access_token":"eyJraWQiOiI1Vk9qbHFHM2RiWktxX0RGQkJ6WEVVV0xWMU1hMGhVMEJhWWE5cm1LRzcwIiwiYWxnIjoiUlMyNTYifQ.eyJ2ZXIiOjEsImp0aSI6IkFULnR4VW1BbS1PZFhLQzNWZVJmLU03ckx0NjBHYVZjRGNSVGE5cnNETk8taTAiLCJpc3MiOiJodHRwczovL2xvZ2lucHJldmlldy5zdW5iZWx0cmVudGFscy5jb20vb2F1dGgyL2F1czFsZjMyMjZ6N1ZwekF0MWQ3IiwiYXVkIjoiaHR0cHM6Ly93d3cuc3VuYmVsdHJlbnRhbHMuY29tL29rdGEvdmVuZG9ycyIsImlhdCI6MTY5MDIwNjY2OSwiZXhwIjoxNjkwMjA3NTY5LCJjaWQiOiIwb2E0NDA0eDJxdmplWmtKcDFkNyIsInNjcCI6WyJNdWxlc29mdCJdLCJzdWIiOiIwb2E0NDA0eDJ","scope":"Mulesoft"}');
            oResponse.setStatusCode(200);
        }
        return oResponse;
    }
    /************************************************************* Cover getManageWebsiteUsersColumns Starts*************************************************************/
    public Static testMethod void getManageWebsiteUsersColumns(){
        SBR_3_0_TestDataFactory.createCredential();
        Profile oProfile = [SELECT Id FROM Profile WHERE Name='System Administrator'];
		User oRunAsUser = SBR_3_0_TestDataFactory.createUser(TRUE,oProfile);
        System.runAs(oRunAsUser){
            Test.startTest();
            Map<Integer,list<String>> mColumns = SBR_3_0_ManageWebsiteUserController.getManageWebsiteUsersColumns('AccountsResuts');
            Test.stopTest();
        }
    }
    /************************************************************* Cover getManageWebsiteUsersColumns Ends*************************************************************/
    /************************************************************* Cover getManageWebsiteUsersRecords Starts*************************************************************/
    public Static testMethod void getManageWebsiteUsersRecords(){
        SBR_3_0_TestDataFactory.createCredential();
        Profile oProfile = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        List<Account> lAccounts = SBR_3_0_TestDataFactory.createAccounts(1,FALSE,SBR_3_0_Constants.ACCOUNT_REC_TYPE_CREDIT);
        lAccounts[0].RM_Account_Number__c = '1234';
        lAccounts[0].Company_Code__c = '01';
        INSERT lAccounts;
        User oRunAsUser = SBR_3_0_TestDataFactory.createUser(TRUE,oProfile);
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_ManageWebsiteUserControllerTest());
        System.runAs(oRunAsUser){
            Test.startTest();
            SBR_3_0_ManageWebsiteUserController.AccountResults oAccountResults = SBR_3_0_ManageWebsiteUserController.getManageWebsiteUsersRecords(lAccounts[0].id,'10');
            Test.stopTest();
        }
    }
    public Static testMethod void getManageWebsiteUsersRecordsNegative(){
        SBR_3_0_TestDataFactory.createCredential();
        Profile oProfile = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        List<Account> lAccounts = SBR_3_0_TestDataFactory.createAccounts(1,FALSE,SBR_3_0_Constants.ACCOUNT_REC_TYPE_CREDIT);
        lAccounts[0].RM_Account_Number__c = '10096';
        lAccounts[0].Company_Code__c = '02';
        INSERT lAccounts;
        try{
            User oRunAsUser = SBR_3_0_TestDataFactory.createUser(TRUE,oProfile);
            Test.setMock(HttpCalloutMock.class, new SBR_3_0_ManageWebsiteUserControllerTest());
            System.runAs(oRunAsUser){
                Test.startTest();
            	SBR_3_0_ManageWebsiteUserController.AccountResults oAccountResults = SBR_3_0_ManageWebsiteUserController.getManageWebsiteUsersRecords(lAccounts[0].id,'10');
            	Test.stopTest();
                System.assertEquals(2,oAccountResults.users.size());
            }
        }
        Catch(Exception e){
                
        }
    }
    public Static testMethod void getManageWebsiteUsersRecordsNegative1(){
        SBR_3_0_TestDataFactory.createCredential();
        Profile oProfile = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        List<Account> lAccounts = SBR_3_0_TestDataFactory.createAccounts(1,FALSE,SBR_3_0_Constants.ACCOUNT_REC_TYPE_CREDIT);
        lAccounts[0].RM_Account_Number__c = '';
        lAccounts[0].Company_Code__c = '02';
        INSERT lAccounts;
        try{
            User oRunAsUser = SBR_3_0_TestDataFactory.createUser(TRUE,oProfile);
            Test.setMock(HttpCalloutMock.class, new SBR_3_0_ManageWebsiteUserControllerTest());
            System.runAs(oRunAsUser){
                Test.startTest();
            	SBR_3_0_ManageWebsiteUserController.AccountResults oAccountResults = SBR_3_0_ManageWebsiteUserController.getManageWebsiteUsersRecords(lAccounts[0].id,'10');
            	Test.stopTest();
                System.assertEquals(NULL,oAccountResults.users);
            }
        }
        Catch(Exception e){
                
        }
    }
    public Static testMethod void SBR_3_0_ManageWebsiteUserRequestWrapper(){
        SBR_3_0_TestDataFactory.createCredential();
        Profile oProfile = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        String JSON = '{"requester":{"lastName":"Tulasi","firstName":"Saathvik","employeeId":92287,"email":"saathvik.tulasi@salesforce.com"},"overideNonCredit":false,"customer":{"lastName":"Test 1","isAdmin":true,"firstName":"Test","email":"Test@test.com"},"accountNumber":1200215,"accountName":"CREDIT CCA"}';
        User oRunAsUser = SBR_3_0_TestDataFactory.createUser(TRUE,oProfile);
        System.runAs(oRunAsUser){
        	Test.startTest();
            SBR_3_0_ManageWebsiteUserRequestWrapper responseWrap = SBR_3_0_ManageWebsiteUserRequestWrapper.parse(JSON);
            Test.stopTest();
        }
    }
    /************************************************************* Cover getManageWebsiteUsersRecords Ends*************************************************************/
    /************************************************************* Cover CreateWebsiteUsersRecords Starts*************************************************************/
    public Static testMethod void CreateWebsiteUsersRecordsCredit(){
        Profile oProfile = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        SBR_3_0_TestDataFactory.createCredential();
        List<Account> lAccounts = SBR_3_0_TestDataFactory.createAccounts(1,FALSE,SBR_3_0_Constants.ACCOUNT_REC_TYPE_CREDIT);
        lAccounts[0].RM_Account_Number__c = '1234';
        lAccounts[0].Company_Code__c = '01';
        INSERT lAccounts;
        User oRunAsUser = SBR_3_0_TestDataFactory.createUser(TRUE,oProfile);
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_ManageWebsiteUserControllerTest());
        System.runAs(oRunAsUser){
            Test.startTest();
            Boolean isInserted = SBR_3_0_ManageWebsiteUserController.CreateWebsiteUsersRecords(
                																				lAccounts[0].id,
                																				'Test FirstName',
                																				'Test LastName',
                																				'Test@Test.com',
                																				lAccounts[0].RM_Account_Number__c,
                                																lAccounts[0].Company_Code__c,
                																				'credit'
                                                                                               );
            Test.stopTest();
            System.assertEquals(TRUE,isInserted);
        }
    }
    public Static testMethod void CreateWebsiteUsersRecordsCreditNegative(){
        Profile oProfile = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        SBR_3_0_TestDataFactory.createCredential();
        List<Account> lAccounts = SBR_3_0_TestDataFactory.createAccounts(1,FALSE,SBR_3_0_Constants.ACCOUNT_REC_TYPE_CREDIT);
        lAccounts[0].AccountNumber = '1234';
        lAccounts[0].Company_Code__c = '02';
        INSERT lAccounts;
        User oRunAsUser = SBR_3_0_TestDataFactory.createUser(TRUE,oProfile);
        try{
            Test.setMock(HttpCalloutMock.class, new SBR_3_0_ManageWebsiteUserControllerTest());
            System.runAs(oRunAsUser){
                Test.startTest();
                Boolean isInserted = SBR_3_0_ManageWebsiteUserController.CreateWebsiteUsersRecords(
                                                                                                    lAccounts[0].id,
                                                                                                    'Test FirstName',
                                                                                                    'Test LastName',
                                                                                                    'Test@Test.com',
                                                                                                    lAccounts[0].RM_Account_Number__c,
                                                                                                    lAccounts[0].Company_Code__c,
                                                                                                    'credit'
                                                                                                   );
                Test.stopTest();
                System.assertEquals(TRUE,isInserted);
            }
        }
        Catch(Exception e){
            
        }
    }
    /************************************************************* Cover CreateWebsiteUsersRecords Ends*************************************************************/
    /************************************************************* Cover searchWebsiteUser Starts*************************************************************/
    public Static testMethod void searchWebsiteUserCredit(){
        SBR_3_0_TestDataFactory.createCredential();
        Profile oProfile = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        List<Account> lAccounts = SBR_3_0_TestDataFactory.createAccounts(1,FALSE,SBR_3_0_Constants.ACCOUNT_REC_TYPE_CREDIT);
        lAccounts[0].RM_Account_Number__c = '11001';
        lAccounts[0].Company_Code__c = '01';
        INSERT lAccounts;
        User oRunAsUser = SBR_3_0_TestDataFactory.createUser(TRUE,oProfile);
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_ManageWebsiteUserControllerTest());
        System.runAs(oRunAsUser){
            Test.startTest();
            SBR_3_0_ManageWebsiteUserController.AccountSearchResults oAccountResults = SBR_3_0_ManageWebsiteUserController.searchWebsiteUser('josh28704test2@yopmail.com');
            Test.stopTest();
            System.assertEquals(3,oAccountResults.CreditAccountSearchResults.size());
        }
    }
    public Static testMethod void searchWebsiteUserCash(){
        SBR_3_0_TestDataFactory.createCredential();
        Profile oProfile = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        List<Account> lAccounts = SBR_3_0_TestDataFactory.createAccounts(1,FALSE,SBR_3_0_Constants.ACCOUNT_REC_TYPE_CREDIT);
        lAccounts[0].RM_Account_Number__c = '11002';
        lAccounts[0].Company_Code__c = '01';
        INSERT lAccounts;
        User oRunAsUser = SBR_3_0_TestDataFactory.createUser(TRUE,oProfile);
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_ManageWebsiteUserControllerTest());
        System.runAs(oRunAsUser){
            Test.startTest();
            SBR_3_0_ManageWebsiteUserController.AccountSearchResults oAccountResults = SBR_3_0_ManageWebsiteUserController.searchWebsiteUser('josh28704test3@yopmail.com');
            Test.stopTest();
            System.assertEquals(3,oAccountResults.CashAccountSearchResults.size());
        }
    }
    public Static testMethod void searchWebsiteUserNegative1(){
        SBR_3_0_TestDataFactory.createCredential();
        Profile oProfile = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        List<Account> lAccounts = SBR_3_0_TestDataFactory.createAccounts(1,FALSE,SBR_3_0_Constants.ACCOUNT_REC_TYPE_CREDIT);
        lAccounts[0].RM_Account_Number__c = '1234';
        lAccounts[0].Company_Code__c = '01';
        INSERT lAccounts;
        try{
            User oRunAsUser = SBR_3_0_TestDataFactory.createUser(TRUE,oProfile);
            Test.setMock(HttpCalloutMock.class, new SBR_3_0_ManageWebsiteUserControllerTest());
            System.runAs(oRunAsUser){
                Test.startTest();
                SBR_3_0_ManageWebsiteUserController.AccountSearchResults oAccountResults = SBR_3_0_ManageWebsiteUserController.searchWebsiteUser('');
                Test.stopTest();
                System.assertEquals(NULL,oAccountResults);
            }
        }
        Catch(Exception e){
            
        }
    }
    public Static testMethod void searchWebsiteUserNegative2(){
        SBR_3_0_TestDataFactory.createCredential();
        Profile oProfile = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        List<Account> lAccounts = SBR_3_0_TestDataFactory.createAccounts(1,FALSE,SBR_3_0_Constants.ACCOUNT_REC_TYPE_CREDIT);
        lAccounts[0].RM_Account_Number__c = '1234';
        lAccounts[0].Company_Code__c = '01';
        INSERT lAccounts;
        try{
            User oRunAsUser = SBR_3_0_TestDataFactory.createUser(TRUE,oProfile);
            Test.setMock(HttpCalloutMock.class, new SBR_3_0_ManageWebsiteUserControllerTest());
            System.runAs(oRunAsUser){
                Test.startTest();
                SBR_3_0_ManageWebsiteUserController.AccountSearchResults oAccountResults = SBR_3_0_ManageWebsiteUserController.searchWebsiteUser('josh28704test4@yopmail.com');
                Test.stopTest();
                System.assertEquals('INTERNAL_SERVER_ERROR',oAccountResults.accountType);
            }
        }
        Catch(Exception e){
            
        }
    }
    /************************************************************* Cover searchWebsiteUser Ends*************************************************************/
    /************************************************************* Cover searchUserEmail Starts*************************************************************/
    public Static testMethod void searchUserEmailNegative1(){
        SBR_3_0_TestDataFactory.createCredential();
        Profile oProfile = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        try{
            User oRunAsUser = SBR_3_0_TestDataFactory.createUser(TRUE,oProfile);
            Test.setMock(HttpCalloutMock.class, new SBR_3_0_ManageWebsiteUserControllerTest());
            System.runAs(oRunAsUser){
                Test.startTest();
                list<SBR_3_0_MWUAccountEmailSearchWrapper.Users> lUsers = SBR_3_0_ManageWebsiteUserController.searchUserEmail('Test2');
                Test.stopTest();
                System.assertEquals(NULL,lUsers);
            }
        }
        Catch(Exception e){
                
        }
    }
    public Static testMethod void searchUserEmailNegative2(){
        SBR_3_0_TestDataFactory.createCredential();
        Profile oProfile = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        try{
            User oRunAsUser = SBR_3_0_TestDataFactory.createUser(TRUE,oProfile);
            Test.setMock(HttpCalloutMock.class, new SBR_3_0_ManageWebsiteUserControllerTest());
            System.runAs(oRunAsUser){
                Test.startTest();
                list<SBR_3_0_MWUAccountEmailSearchWrapper.Users> lUsers = SBR_3_0_ManageWebsiteUserController.searchUserEmail('');
                Test.stopTest();
                System.assertEquals(NULL,lUsers);
            }
        }
        Catch(Exception e){
                
        }
    }
	/************************************************************* Cover searchUserEmail Ends*************************************************************/
}