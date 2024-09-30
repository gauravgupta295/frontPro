@isTest
public with sharing class SBR_3_0_AccountRelationshipDA_Test {
    @TestSetup
    static void makeData(){
        Account acc = SBR_3_0_TestDataFactory.createAccounts(1, true)[0];
        User u = SBR_3_0_TestDataFactory.createUsers(1, false)[0];
        u.FirstName = 'AccountRelationshipDA';
        u.LastName = 'Test';
        u.Rep_Type__c = 'Strategic Customer Manager';
        insert u;
        //System.debug(u.Id);
        Account_Relationship__c accRel = SBR_3_0_TestDataFactory.createAccountRelationships(1, acc.Id, false)[0];
        accRel.User_Account__c = u.Id;
        accRel.Type__c = 'Territory';
        insert accRel;
    }
    
    @isTest
    static void getAccountRelsByUserIdTest() {
        Test.startTest();
            List<User> users = [SELECT Id FROM User WHERE Name = 'AccountRelationshipDA Test'];
            Id userId = users[0].Id;
            List<Account_Relationship__c> relationship = SBR_3_0_AccountRelationshipDA.getAccountRelsByUserId(userId);
        Test.stopTest();
        System.assertEquals(1, relationship.size(), 'No relationship found');
    }

    @isTest
    static void getAccountRelsByUserIdsTest() {
        Test.startTest();
            List<User> users = [SELECT Id FROM User WHERE Name = 'AccountRelationshipDA Test'];
            Id userId = users[0].Id;
            List<Id> userIds = new List<Id>{userId};
            List<Account_Relationship__c> relationship = SBR_3_0_AccountRelationshipDA.getAccountRelsByUserIds(userIds);
        Test.stopTest();
        System.assertEquals(1, relationship.size(), 'No relationship found');
    }

    @isTest
    static void getAccountRelsByAccountIdTest() {
        Test.startTest();
            Account acc = [SELECT Id FROM Account LIMIT 1];
            List<Account_Relationship__c> relationship = SBR_3_0_AccountRelationshipDA.getAccountRelsByAccountId(acc.Id);
        Test.stopTest();
        System.assertEquals(1, relationship.size(), 'No relationship found');
    }

    @isTest
    static void createTrackingAccount() {
        Test.startTest();
            Account acc = [SELECT Id FROM Account LIMIT 1];
            Account_Relationship__c trackingAccount = SBR_3_0_AccountRelationshipDA.createAccountRelationship(acc.Id, UserInfo.getUserId());
        Test.stopTest();
        System.assertNotEquals(null, trackingAccount.Id, 'No relationship created');
    }

    @isTest
    static void deleteTrackingAccount() {
        Test.startTest();
            Account acc = [SELECT Id FROM Account LIMIT 1];
            SBR_3_0_AccountRelationshipDA.createAccountRelationship(acc.Id, UserInfo.getUserId());
            SBR_3_0_AccountRelationshipDA.deleteTrackedAccountRelationships(acc.Id, UserInfo.getUserId());
        Test.stopTest();
        
        List<Account_Relationship__c> arList = SBR_3_0_AccountRelationshipDA.getTrackedAccountRelationships(acc.Id, UserInfo.getUserId());
        System.assertEquals(0, arList.size(), 'Relationship were not deleted.');
    }

}