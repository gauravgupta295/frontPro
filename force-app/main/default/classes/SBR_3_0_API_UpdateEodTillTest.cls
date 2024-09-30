/**
 * @description Test class for testing the functionality of SBR_3_0_API_UpdateEodTill class.
 * This class contains test methods for updating End_of_Day_Till__c records.
 */
@isTest
public class SBR_3_0_API_UpdateEodTillTest {
     /**
     * @description Test method to verify the updateTillSummary method of SBR_3_0_API_UpdateEodTill class.
     * Tests the successful invocation of the method using mock data and HTTP callout mock.
     */
    @isTest
    static void testUpdateTillSummary() {
        // Setup test data
        Profile p = [SELECT Id FROM Profile WHERE Name='Sales'];
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Payment_Access'];
        //create ers user clone
        String ersUserName = 'ersuser' + DateTime.now().getTime() + '@SBRtestorg.com';
        User ersu = new User(Alias = 'ers', Email='ersuser@testorg.com',
        EmailEncodingKey='UTF-8', LastName='erstest', LanguageLocaleKey='en_US',
        LocaleSidKey='en_US', ProfileId = p.Id,
        TimeZoneSidKey='America/Los_Angeles',
        UserName=ersUserName);
        ersu.RepID__c = '1028';
        ersu.IsActive =true;
        insert ersu;
        
        insert new PermissionSetAssignment(AssigneeId = ersu.Id, PermissionSetId = ps.Id);
        User user = [SELECT Id FROM User Where IsActive =true LIMIT 1];
        System.runAs(user){
        End_of_Day_Till__c eodTillRecord = createTestEodTillRecord();
        Id eodTillRecordId = eodTillRecord.Id;
        
        // Prepare reason records as JSON string
        String reasonRecords = '[{"amount": 50.00, "description": "Test Reason", "customerNumber": 12345, "note": "Test Note", "checkNumber": "CHK123", "reasonCode": "R001"}]';
        
        // Mock callout response
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        Test.startTest();
        
        // Invoke the method
        Object result = SBR_3_0_API_UpdateEodTill.updateTillSummary(eodTillRecordId, user.Id, reasonRecords);
        System.assertEquals(null, result, 'Result cant be null');
        
        Test.stopTest();
        }
    }
    
    /**
     * @description Test method to verify the constructor and initialization of SBR_3_0_API_UpdateEodTill class.
     * Tests the instantiation and non-null instance creation of the class.
     */
    @isTest
    static void testConstructorAndMethods() {
        // Setup test data
        Profile p = [SELECT Id FROM Profile WHERE Name='Sales'];
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Payment_Access'];
        //create ers user clone
        String ersUserName = 'ersuser' + DateTime.now().getTime() + '@SBRtestorg.com';
        User ersu = new User(Alias = 'ers', Email='ersuser@testorg.com',
        EmailEncodingKey='UTF-8', LastName='erstest', LanguageLocaleKey='en_US',
        LocaleSidKey='en_US', ProfileId = p.Id,
        TimeZoneSidKey='America/Los_Angeles',
        UserName=ersUserName);
        ersu.RepID__c = '1028';
        ersu.IsActive =true;
        insert ersu;
        
        insert new PermissionSetAssignment(AssigneeId = ersu.Id, PermissionSetId = ps.Id);
        User user = [SELECT Id FROM User Where IsActive =true LIMIT 1];
        System.runAs(user){
        End_of_Day_Till__c eodTillRecord = createTestEodTillRecord();
        Id eodTillRecordId = eodTillRecord.Id;
        
        // Prepare reason records as JSON string
        String reasonRecords = '[{"amount": 50.00, "description": "Test Reason", "customerNumber": 12345, "note": "Test Note", "checkNumber": "CHK123", "reasonCode": "R001"}]';
        
        // Mock callout response
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        Test.startTest();
        
        // Instantiate the class
        SBR_3_0_API_UpdateEodTill instance = new SBR_3_0_API_UpdateEodTill(user.Id, eodTillRecordId, reasonRecords);
        System.assertNotEquals(null, instance, 'Instance cant be null');
        Test.stopTest();
    }

    }
    
    /**
     * @description Helper method to create a test user for use in tests.
     * Creates and inserts a User record with test data.
     * 
     * @return User object that was created and inserted
     */
    private static User createTestUser() {
        User user = new User(
            Username = 'testuser12@example.com',
            Alias = 'testus12',
            Email = 'testuser12@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Test',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User'].Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            CompanyName = 'Test Company',
            Department = 'Test Department',
            Wynne_User_Name__c = 'TestWynneUser'
        );
        insert user;
        return user;
    }
    
    /**
     * @description Helper method to create a test End_of_Day_Till__c record for use in tests.
     * Creates and inserts an End_of_Day_Till__c record with test data.
     * 
     * @return End_of_Day_Till__c object that was created and inserted
     */
    private static End_of_Day_Till__c createTestEodTillRecord() {
        End_of_Day_Till__c eodTill = new End_of_Day_Till__c(
            CurrencyIsoCode = 'USD',
            Till_Date__c = Date.today(),
            Total_ROA_Checks__c = 100.50,
            Total_Checks__c = 200.75,
            Next_Day_Drawer__c = 300.00,
            Start_Drawer__c = 150.00,
            Submitted__c = true,
            Drawer_Bills_Hundred__c = 1000,
            Drawer_Bills_Fifty__c = 500,
            Drawer_Bills_Twenty__c = 400,
            Drawer_Bills_Ten__c = 100,
            Drawer_Bills_Five__c = 50,
            Drawer_Bills_Two__c = 10,
            Drawer_Bills_One__c = 20,
            Drawer_Coins_One__c = 5,
            Drawer_Coins_Fifty__c = 2.5,
            Drawer_Coins_Quarter__c = 10,
            Drawer_Coins_Dime__c = 5,
            Drawer_Coins_Nickel__c = 2,
            Drawer_Coins_Penny__c = 1,
            Amex__c = 100.00,
            Amex_ROA__c = 10.00,
            Discover__c = 200.00,
            Discover_ROA__c = 20.00,
            MasterCard__c = 300.00,
            MasterCard_ROA__c = 30.00,
            Visa__c = 400.00,
            Visa_ROA__c = 40.00,
            Diners_Club__c = 500.00,
            Diners_Club_ROA__c = 50.00,
            Status__c='In Balance',
            Total_Currency__c=1000.00
        );
        insert eodTill;
        return eodTill;
    }
    
    /**
     * @description MockHttpResponseGenerator class implements HttpCalloutMock to mock HTTP callout responses.
     * This mock class returns a success response for HTTP callouts made during testing.
     */
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        /**
        * @description MockHttpResponseGenerator class implements HttpCalloutMock to mock HTTP callout responses.
        * This mock class returns a success response for HTTP callouts made during testing.
        * @param req The Request body to create Payments.
        * @return The response from the API Callout.
        */
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"status": "success"}');
            res.setStatusCode(200);
            return res;
        }
    }

}