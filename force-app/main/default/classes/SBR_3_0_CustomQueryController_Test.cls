@isTest
public class SBR_3_0_CustomQueryController_Test {
    
    @TestSetup
    static void makeData(){
        Credential__c cred = SBR_3_0_TestDataFactory.createCredentials(1, false)[0];
        cred.Name      = 'Mule_Token_Endpoint';
        cred.Key_Id__c = 'testKey123';
        cred.Secret__c = 'secret';
        insert cred;

        // Create Account
        Account acct1 =  SBR_3_0_ServiceTestDataFactory.createAccount(false,'33333');
        acct1.E_mail_Address__c = '123@asdf.com';
        acct1.Company_Code__c   = '01';
        insert acct1;
    }

    @isTest
    public static void executeQueryTest(){
        Test.startTest();
            List<SObject> data = SBR_3_0_CustomQueryController.executeQuery('Name, E_mail_Address__c', 'Account', '');
            Assert.isTrue(!data.isEmpty(), 'Account record found');

            data = SBR_3_0_CustomQueryController.executeQuery('Name', 'Contact', '');
            Assert.isTrue(data.isEmpty(), 'No Contact record found');
        Test.stopTest();
    }
}