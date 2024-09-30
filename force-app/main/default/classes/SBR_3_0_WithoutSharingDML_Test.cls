@isTest
public without sharing class SBR_3_0_WithoutSharingDML_Test {
    @TestSetup
    static void makeData(){
        Account acc = SBR_3_0_TestDataFactory.createAccounts(1, true)[0];
        User u = SBR_3_0_TestDataFactory.createUsers(1, false)[0];
        u.FirstName = 'AccountRelationshipDA';
        u.LastName = 'Test';
        insert u;
        //System.debug(u.Id);
        Account_Relationship__c accRel = SBR_3_0_TestDataFactory.createAccountRelationships(1, acc.Id, false)[0];
        accRel.User_Account__c = u.Id;
        insert accRel;
    }
    
    @isTest
    static void createTrackingAccount() {
        Test.startTest();
            Account acc = [SELECT Id FROM Account LIMIT 1];
            Account_Relationship__c trackingAccount = SBR_3_0_AccountRelationshipDA.createAccountRelationship(acc.Id, UserInfo.getUserId());
        Test.stopTest();
        System.assertNotEquals(null, trackingAccount.Id, 'No relationship created');
    }
}