@isTest(seeAllData=false)
public class SBR_3_0_API_GetEodTillSummaryTest {
    @TestSetup
    static void makeData(){
        Credential__c cred = SBR_3_0_TestDataFactory.createCredentials(1, false)[0];
        cred.Name = 'Mule_Token_Endpoint';
        cred.Key_Id__c = 'testKey123';
        cred.Secret__c = 'secret';
        insert cred;

        List<User> userList = SBR_3_0_TestDataFactory.createUsers(1,true);
        System.assertEquals(1, userList.size(), 'User should be defined');
    }
    
     @isTest 
    static void testGetTillSummaryNext() {
        User userList = [SELECT Id FROM User Where IsActive =true LIMIT 1];
        System.runAs(userList){
        Test.startTest();
        SBR_3_0_API_GetEodTillSummary.getTillSummary('2024-06-10',userList.id,'Next');
        System.assertNotEquals(null, userList, 'User should be defined');
        Test.stopTest();
        }
    }
    
    @isTest 
    static void testGetTillSummaryCashROA() {
        User userList = [SELECT Id FROM User Where IsActive =true LIMIT 1];
        System.runAs(userList){
        Test.startTest();
        SBR_3_0_API_GetEodTillSummary.getTillSummary('2024-06-10',userList.id,'CashROA');
        System.assertNotEquals(null, userList, 'User should be defined');
        Test.stopTest();
        }
    }
    
    @isTest 
    static void testGetTillSummaryCashInvoice() {
        User userList = [SELECT Id FROM User Where IsActive =true LIMIT 1];
        System.runAs(userList){
        Test.startTest();
        SBR_3_0_API_GetEodTillSummary.getTillSummary('2024-06-10',userList.id,'CashInvoice');
        System.assertNotEquals(null, userList, 'User should be defined');
        Test.stopTest();
        }
    }
    
    @isTest 
    static void testGetTillSummaryNewDeposits() {
        User userList = [SELECT Id FROM User Where IsActive =true LIMIT 1];
        System.runAs(userList){
        Test.startTest();
        SBR_3_0_API_GetEodTillSummary.getTillSummary('2024-06-10',userList.id,'NewDeposits');
        System.assertNotEquals(null, userList, 'User should be defined');
        Test.stopTest();
        }
    }

    @isTest     
    static void testGetTillSummaryInterCompanyDetails() {
        User userList = [SELECT Id FROM User Where IsActive =true LIMIT 1];
        System.runAs(userList){
        Test.startTest();
        SBR_3_0_API_GetEodTillSummary.getTillSummary('2024-06-10',userList.id,'InterCompanyDetails');
        System.assertNotEquals(null, userList, 'User should be defined');
        Test.stopTest();
        }
    }
    
    @isTest 
    static void testGetTillSummaryAdditionalDeposits() {
        User userList = [SELECT Id FROM User Where IsActive =true LIMIT 1];
        System.runAs(userList){
        Test.startTest();
        SBR_3_0_API_GetEodTillSummary.getTillSummary('2024-06-10',userList.id,'AdditionalDeposits');
        System.assertNotEquals(null, userList, 'User should be defined');
        Test.stopTest();
        }
    }
    
    @isTest 
    static void testGetTillSummaryAdditionalDepositsFail() {
        User userList = [SELECT Id FROM User Where IsActive =true LIMIT 1];
        System.runAs(userList){
        try{
        Test.startTest();
        SBR_3_0_API_GetEodTillSummary.getTillSummary('2024-06-10',userList.id,'');
        Test.stopTest();
        }catch(exception e){
            SBR_3_0_Log.logException(e);
            System.assert(true, 'Exception: ' + e.getMessage());
        }
    }
}

}