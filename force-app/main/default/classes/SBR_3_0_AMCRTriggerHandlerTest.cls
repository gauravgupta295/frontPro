@isTest
private class SBR_3_0_AMCRTriggerHandlerTest {

    @isTest
    static void testAfterInsert() {
        // Create test data
        List<Account_Management_Change_Request__c> testAMCRList = new List<Account_Management_Change_Request__c>();
        // Add any necessary field values to your records

        // Insert test records
        Test.startTest();
        SBR_3_0_AMCRTriggerHandler handler = new SBR_3_0_AMCRTriggerHandler();
        insert testAMCRList;
        Test.stopTest();

        // Query the records to verify the expected changes
        List<Account_Management_Change_Request__c> queriedAMCRList = [ SELECT Id FROM Account_Management_Change_Request__c WHERE Id IN :testAMCRList ];

        // Perform assertions to verify the results
        System.assertEquals(testAMCRList.size(), queriedAMCRList.size(), 'Number of records should match');
        // Add more assertions based on your specific requirements
    }
}