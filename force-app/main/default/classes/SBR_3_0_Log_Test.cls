@isTest
public class SBR_3_0_Log_Test {
	
    @TestSetup
    static void makeData(){
        Profile p = [SELECT Id FROM Profile WHERE Name='Sales'];
        //create OSR user who will be related to the account
        String osrUserOneName = 'osrUserOne' + DateTime.now().getTime() + '@sunbeltrentals.com';
        User osrUserOne = new User(Alias = 'osrOne', Email='ersuser@sunbeltrentals.com',RepId__c='1092345',
        EmailEncodingKey='UTF-8', LastName='osrOne', LanguageLocaleKey='en_US',
        LocaleSidKey='en_US', ProfileId = p.Id,
        TimeZoneSidKey='America/Los_Angeles',
        UserName=osrUserOneName);
        insert osrUserOne;
        String osrUserTwoName = 'osrUserTwo' + DateTime.now().getTime() + '@sunbeltrentals.com';
        User osrUserTwo = new User(Alias = 'osrTwo', Email='ersusertwo@sunbeltrentals.com',RepId__c='109234522',
        EmailEncodingKey='UTF-8', LastName='osrTwo', LanguageLocaleKey='en_US',
        LocaleSidKey='en_US', ProfileId = p.Id,
        TimeZoneSidKey='America/Los_Angeles',
        UserName=osrUserTwoName);
        insert osrUserTwo;
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Logger'];
		insert new PermissionSetAssignment(AssigneeId = osrUserOne.id, PermissionSetId = ps.Id);
        
    }
    
    @isTest
    static void it_should_logInfo() {
        
        User osrUserOne = [SELECT id from User where email = 'ersuser@sunbeltrentals.com'];
        insert LoggerSettings__c.getOrgDefaults();
        LoggerSettings__c userSettings = LoggerSettings__c.getOrgDefaults();
        userSettings.Id = null;
        userSettings.isEnabled__c =true;
        userSettings.SetupOwnerId = osrUserOne.Id;
        insert userSettings;
        System.runAs(osrUserOne){
            
            Test.startTest();
            SBR_3_0_TestDataFactory.createAccounts(1, true);
            List<Account> lstAccount = [SELECT Id from Account];
            SBR_3_0_Log.setRelatedRecordId(lstAccount[0].Id);
            SBR_3_0_Log.logInfo('Test1');
            SBR_3_0_Log.saveLog();
            Test.stopTest();
            Exception_Log__c log = [SELECT id, Type__c from Exception_Log__c LIMIT 1];
            System.assertEquals('DEBUG', log.Type__c);
        }
    }
    
    @isTest
    static void it_should_logInfoException() {
        User osrUserOne = [SELECT id from User where email = 'ersusertwo@sunbeltrentals.com'];
        insert LoggerSettings__c.getOrgDefaults();
        LoggerSettings__c userSettings = LoggerSettings__c.getOrgDefaults();
        userSettings.Id = null;
        userSettings.isEnabled__c =true;
        userSettings.SetupOwnerId = UserInfo.getProfileId();
        insert userSettings;
        System.runAs(osrUserOne){
            Test.startTest();
            //List<Account> lstAccount = [SELECT Id from Account];
            SBR_3_0_Log.setRelatedRecordId(UserInfo.getUserId());
            SBR_3_0_Log.logInfo('Test1');
            SBR_3_0_Log.saveLog();
            Test.stopTest();
            List<Exception_Log__c> logs = [SELECT id, Type__c from Exception_Log__c];
            System.assertEquals(0, logs.size());
        }
    }
    
    @isTest
    static void it_should_logException() {
        User osrUserOne = [SELECT id from User where email = 'ersuser@sunbeltrentals.com'];
        insert LoggerSettings__c.getOrgDefaults();
        LoggerSettings__c userSettings = LoggerSettings__c.getOrgDefaults();
        userSettings.Id = null;
        userSettings.isEnabled__c =true;
        userSettings.SetupOwnerId = osrUserOne.Id;
        insert userSettings;
        System.runAs(osrUserOne){
            Test.startTest();
            SBR_3_0_TestDataFactory.createAccounts(1, true);
            List<Account> lstAccount = [SELECT Id from Account];
            SBR_3_0_Log.setRelatedRecordId(lstAccount[0].Id);
            SBR_3_0_Log.logException( new DmlException());
            SBR_3_0_Log.saveLog();
            Test.stopTest();
            Exception_Log__c log = [SELECT id, Type__c from Exception_Log__c LIMIT 1];
            System.assertEquals('ERROR', log.Type__c);
        }
    }
    
    @isTest
    static void it_should_logAPIDetails() {
        User osrUserOne = [SELECT id from User where email = 'ersuser@sunbeltrentals.com'];
        insert LoggerSettings__c.getOrgDefaults();
        LoggerSettings__c userSettings = LoggerSettings__c.getOrgDefaults();
        userSettings.Id = null;
        userSettings.isEnabled__c =true;
        userSettings.SetupOwnerId = osrUserOne.Id;
        insert userSettings;
        System.runAs(osrUserOne){
        Test.startTest();
            SBR_3_0_TestDataFactory.createAccounts(1, true);
            List<Account> lstAccount = [SELECT Id from Account];
            SBR_3_0_Log.setRelatedRecordId(lstAccount[0].Id);
            String requestBody = '{ "pc": 720, "accountNumber": 4, "jobsiteName": "CO MEDIMMUNE BOULDER", "products": [ { "productId": "1234567" } ] }{ "pc": 720, "accountNumber": 4, "jobsiteName": "CO MEDIMMUNE BOULDER", "products": [ { "productId": "1234567" } ] }{ "pc": 720, "accountNumber": 4, "jobsiteName": "CO MEDIMMUNE BOULDER", "products": [ { "productId": "1234567" } ] }{ "pc": 720, "accountNumber": 4, "jobsiteName": "CO MEDIMMUNE BOULDER", "products": [ { "productId": "1234567" } ] }{ "pc": 720, "accountNumber": 4, "jobsiteName": "CO MEDIMMUNE BOULDER", "products": [ { "productId": "1234567" } ] }{ "pc": 720, "accountNumber": 4, "jobsiteName": "CO MEDIMMUNE BOULDER", "products": [ { "productId": "1234567" } ] }{ "pc": 720, "accountNumber": 4, "jobsiteName": "CO MEDIMMUNE BOULDER", "products": [ { "productId": "1234567" } ] }{ "pc": 720, "accountNumber": 4, "jobsiteName": "CO MEDIMMUNE BOULDER", "products": [ { "productId": "1234567" } ] }{ "pc": 720, "accountNumber": 4, "jobsiteName": "CO MEDIMMUNE BOULDER", "products": [ { "productId": "1234567" } ] }{ "pc": 720, "accountNumber": 4, "jobsiteName": "CO MEDIMMUNE BOULDER", "products": [ { "productId": "1234567" } ] }{ "pc": 720, "accountNumber": 4, "jobsiteName": "CO MEDIMMUNE BOULDER", "products": [ { "productId": "1234567" } ] }{ "pc": 720, "accountNumber": 4, "jobsiteName": "CO MEDIMMUNE BOULDER", "products": [ { "productId": "1234567" } ] }{ "pc": 720, "accountNumber": 4, "jobsiteName": "CO MEDIMMUNE BOULDER", "products": [ { "productId": "1234567" } ] }{ "pc": 720, "accountNumber": 4, "jobsiteName": "CO MEDIMMUNE BOULDER", "products": [ { "productId": "1234567" } ] }{ "pc": 720, "accountNumber": 4, "jobsiteName": "CO MEDIMMUNE BOULDER", "products": [ { "productId": "1234567" } ] }{ "pc": 720, "accountNumber": 4, "jobsiteName": "CO MEDIMMUNE BOULDER", "products": [ { "productId": "1234567" } ] { "pc": 720, "accountNumber": 4, "jobsiteName": "CO MEDIMMUNE BOULDER", "products": [ { "productId": "1234567" } ] }{ "pc": 720, "accountNumber": 4, "jobsiteName": "CO MEDIMMUNE BOULDER", "products": [ { "productId": "1234567" } ] }{ "pc": 720, "accountNumber": 4, "jobsiteName": "CO MEDIMMUNE BOULDER", "products": [ { "productId": "1234567" } ] }{ "pc": 720, "accountNumber": 4, "jobsiteName": "CO MEDIMMUNE BOULDER", "products": [ { "productId": "1234567" } ] }{ "pc": 720, "accountNumber": 4, "jobsiteName": "CO MEDIMMUNE BOULDER", "products": [ { "productId": "1234567" } ] }{ "pc": 720, "accountNumber": 4, "jobsiteName": "CO MEDIMMUNE BOULDER", "products": [ { "productId": "1234567" } ] }{ "pc": 720, "accountNumber": 4, "jobsiteName": "CO MEDIMMUNE BOULDER", "products": [ { "productId": "1234567" } ] }{ "pc": 720, "accountNumber": 4, "jobsiteName": "CO MEDIMMUNE BOULDER", "products": [ { "productId": "1234567" } ] }{ "pc": 720, "accountNumber": 4, "jobsiteName": "CO MEDIMMUNE BOULDER", "products": [ { "productId": "1234567" } ] }{ "pc": 720, "accountNumber": 4, "jobsiteName": "CO MEDIMMUNE BOULDER", "products": [ { "productId": "1234567" } ] }{ "pc": 720, "accountNumber": 4, "jobsiteName": "CO MEDIMMUNE BOULDER", "products": [ { "productId": "1234567" } ] }{ "pc": 720, "accountNumber": 4, "jobsiteName": "CO MEDIMMUNE BOULDER", "products": [ { "productId": "1234567" } ] }{ "pc": 720, "accountNumber": 4, "jobsiteName": "CO MEDIMMUNE BOULDER", "products": [ { "productId": "1234567" } ] }{ "pc": 720, "accountNumber": 4, "jobsiteName": "CO MEDIMMUNE BOULDER", "products": [ { "productId": "1234567" } ] }{ "pc": 720, "accountNumber": 4, "jobsiteName": "CO MEDIMMUNE BOULDER", "products": [ { "productId": "1234567" } ] }{ "pc": 720, "accountNumber": 4, "jobsiteName": "CO MEDIMMUNE BOULDER", "products": [ { "productId": "1234567" } ] }';
            String responseBody = '{ "pc": 720, "accountNumber": 4, "jobsiteName": "CO MEDIMMUNE BOULDER", "products": [ { "productId": "1234567" } ] }{ "pc": 720, "accountNumber": 4, "jobsiteName": "CO MEDIMMUNE BOULDER", "products": [ { "productId": "1234567" } ] }{ "pc": 720, "accountNumber": 4, "jobsiteName": "CO MEDIMMUNE BOULDER", "products": [ { "productId": "1234567" } ] }{ "pc": 720, "accountNumber": 4, "jobsiteName": "CO MEDIMMUNE BOULDER", "products": [ { "productId": "1234567" } ] }{ "pc": 720, "accountNumber": 4, "jobsiteName": "CO MEDIMMUNE BOULDER", "products": [ { "productId": "1234567" } ] }{ "pc": 720, "accountNumber": 4, "jobsiteName": "CO MEDIMMUNE BOULDER", "products": [ { "productId": "1234567" } ] }{ "pc": 720, "accountNumber": 4, "jobsiteName": "CO MEDIMMUNE BOULDER", "products": [ { "productId": "1234567" } ] }{ "pc": 720, "accountNumber": 4, "jobsiteName": "CO MEDIMMUNE BOULDER", "products": [ { "productId": "1234567" } ] }{ "pc": 720, "accountNumber": 4, "jobsiteName": "CO MEDIMMUNE BOULDER", "products": [ { "productId": "1234567" } ] }{ "pc": 720, "accountNumber": 4, "jobsiteName": "CO MEDIMMUNE BOULDER", "products": [ { "productId": "1234567" } ] }{ "pc": 720, "accountNumber": 4, "jobsiteName": "CO MEDIMMUNE BOULDER", "products": [ { "productId": "1234567" } ] }{ "pc": 720, "accountNumber": 4, "jobsiteName": "CO MEDIMMUNE BOULDER", "products": [ { "productId": "1234567" } ] }{ "pc": 720, "accountNumber": 4, "jobsiteName": "CO MEDIMMUNE BOULDER", "products": [ { "productId": "1234567" } ] }{ "pc": 720, "accountNumber": 4, "jobsiteName": "CO MEDIMMUNE BOULDER", "products": [ { "productId": "1234567" } ] }{ "pc": 720, "accountNumber": 4, "jobsiteName": "CO MEDIMMUNE BOULDER", "products": [ { "productId": "1234567" } ] }{ "pc": 720, "accountNumber": 4, "jobsiteName": "CO MEDIMMUNE BOULDER", "products": [ { "productId": "1234567" } ] { "pc": 720, "accountNumber": 4, "jobsiteName": "CO MEDIMMUNE BOULDER", "products": [ { "productId": "1234567" } ] }{ "pc": 720, "accountNumber": 4, "jobsiteName": "CO MEDIMMUNE BOULDER", "products": [ { "productId": "1234567" } ] }{ "pc": 720, "accountNumber": 4, "jobsiteName": "CO MEDIMMUNE BOULDER", "products": [ { "productId": "1234567" } ] }{ "pc": 720, "accountNumber": 4, "jobsiteName": "CO MEDIMMUNE BOULDER", "products": [ { "productId": "1234567" } ] }{ "pc": 720, "accountNumber": 4, "jobsiteName": "CO MEDIMMUNE BOULDER", "products": [ { "productId": "1234567" } ] }{ "pc": 720, "accountNumber": 4, "jobsiteName": "CO MEDIMMUNE BOULDER", "products": [ { "productId": "1234567" } ] }{ "pc": 720, "accountNumber": 4, "jobsiteName": "CO MEDIMMUNE BOULDER", "products": [ { "productId": "1234567" } ] }{ "pc": 720, "accountNumber": 4, "jobsiteName": "CO MEDIMMUNE BOULDER", "products": [ { "productId": "1234567" } ] }{ "pc": 720, "accountNumber": 4, "jobsiteName": "CO MEDIMMUNE BOULDER", "products": [ { "productId": "1234567" } ] }{ "pc": 720, "accountNumber": 4, "jobsiteName": "CO MEDIMMUNE BOULDER", "products": [ { "productId": "1234567" } ] }{ "pc": 720, "accountNumber": 4, "jobsiteName": "CO MEDIMMUNE BOULDER", "products": [ { "productId": "1234567" } ] }{ "pc": 720, "accountNumber": 4, "jobsiteName": "CO MEDIMMUNE BOULDER", "products": [ { "productId": "1234567" } ] }{ "pc": 720, "accountNumber": 4, "jobsiteName": "CO MEDIMMUNE BOULDER", "products": [ { "productId": "1234567" } ] }{ "pc": 720, "accountNumber": 4, "jobsiteName": "CO MEDIMMUNE BOULDER", "products": [ { "productId": "1234567" } ] }{ "pc": 720, "accountNumber": 4, "jobsiteName": "CO MEDIMMUNE BOULDER", "products": [ { "productId": "1234567" } ] }{ "pc": 720, "accountNumber": 4, "jobsiteName": "CO MEDIMMUNE BOULDER", "products": [ { "productId": "1234567" } ] }}';
            SBR_3_0_Log.logAPIDetails(requestBody,responseBody,'APINAME');
            SBR_3_0_Log.logAPIDetails(requestBody,'Response Body');
            SBR_3_0_Log.saveLog();
            Test.stopTest();
            Exception_Log__c log = [SELECT id, Type__c from Exception_Log__c LIMIT 1];
            System.assertEquals('API_LOG', log.Type__c);
        }
    }
}