/*********************************************************************************************************************
* Apex Class: SBR_3_0_ContactOperations_Test
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Verifies proper execution of Contact Operations utility methods
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE            DETAIL FEATURES
    1.0         Philippe Bilodeau       2022-10-17      Initial version
*********************************************************************************************************************/
@isTest
public class SBR_3_0_ContactOperations_Test {
    @testSetup
    public static void createTestData(){
        List<Account> parentAccounts = SBR_3_0_TestDataFactory.createAccounts(1, true, 'Credit');
        List<Account> childAccounts = SBR_3_0_TestDataFactory.createAccounts(1, true, 'Office');
        
        Account pAcc = parentAccounts[0];
        
        Account cAcc = childAccounts[0];
        cAcc.ParentId = pAcc.Id;
        update cAcc;
    }
    public static testmethod void validateContactParentAccountOnInsert(){
        Account cAcc = [select Id, ParentId from Account where RecordType.Name = 'Office' order by CreatedDate desc limit 1];
		
        test.startTest();        
        List<Contact> contactList = SBR_3_0_TestDataFactory.createContacts(1, cAcc.Id, true);
        test.stopTest();
        
        Contact con = [select Id, AccountParent__c from Contact order by CreatedDate desc limit 1];
        system.AssertEquals(con.AccountParent__c, cAcc.ParentId);
    }
    
    public static testmethod void validateContactParentAccountOnUpdate(){
        Account cAcc = [select Id, ParentId from Account where RecordType.Name = 'Office' order by CreatedDate desc limit 1];

		test.startTest();        
        List<Contact> contactList = SBR_3_0_TestDataFactory.createContacts(1, cAcc.Id, true);
        Contact c = contactList[0];
        c.AccountParent__c = null;
        update c;
        test.stopTest();
        
        Contact con = [select Id, AccountParent__c from Contact order by LastModifiedDate desc limit 1];
        system.AssertEquals(con.AccountParent__c, cAcc.ParentId);
    }
}