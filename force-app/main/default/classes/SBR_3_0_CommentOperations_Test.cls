@isTest
public with sharing class SBR_3_0_CommentOperations_Test {
    @TestSetup
    static void makeData(){
        
        Credential__c cred = SBR_3_0_TestDataFactory.createCredentials(1, false)[0];
        cred.Name = 'Mule_Token_Endpoint';
        cred.Key_Id__c = 'keyid';
        cred.Secret__c ='credSecret';
        insert cred;           
    }

    @isTest static void publishCommentsTest(){
        Id ide;
        
        List<Account> acc =SBR_3_0_TestDataFactory.createAccounts(1, True, 'Prospect');
        List<Comment__c> comments = SBR_3_0_TestDataFactory.createComments(1,true,acc[0].Id);

        for (Comment__c comment : comments){
            comment.Comment__c = 'Comment Apex Test';
            ide=comment.Id;
        }
        Update comments;

        //createOutBox(ide, SBR_3_0_Constants.COLLECTION_COMMENT_REC_TYPE);

        List<Outbox__c> out =  [Select Record_Id__c, Record_Type_Name__c from Outbox__c where Record_Id__c=:ide];
        String ric = out[0].Record_Id__c;

        Assert.areEqual(ide,ric);
    }

    static void createOutBox(Id recordId, String recordTypeName){
        Outbox__c newOutbox = new Outbox__c(Record_Id__c        = recordId,
                                            Record_Type_Name__c = recordTypeName
                                           );
        insert newOutbox;
    }
    
    @isTest static void setCommentFieldsInternalUserTest () {
        List<Account> acc =SBR_3_0_TestDataFactory.createAccounts(1, True, 'Prospect');
        List<Comment__c> comments = SBR_3_0_TestDataFactory.createComments(1,true,acc[0].Id);
        
        Comment__c comment = [SELECT Id, Type_Of_Contact__c FROM Comment__c];
        Test.startTest();
        System.assertEquals('SF', comment.Type_of_Contact__c, 'type of contact not set in trigger');
        Test.stopTest();
    }
    
    @isTest static void setCommentFieldsExternalUserTest () {
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        String intUserName = 'IntegrationUser' + DateTime.now().getTime() + '@airrexusa.com';
        User intUser = new User(Alias = 'IntUser', Email='ersuser1@airrexusa.com',
        EmailEncodingKey='UTF-8', LastName='Integration', LanguageLocaleKey='en_US',
        LocaleSidKey='en_US', ProfileId = p.Id,
        TimeZoneSidKey='America/Los_Angeles',
        UserName=intUserName);
        intUser.Wynne_User_Name__c = '0000000001';
        insert intUser;

        PermissionSet intPerm = [SELECT Id FROM PermissionSet WHERE Name = 'Integration_API_Access'];
        PermissionSetLicense psl = [SELECT Id FROM PermissionSetLicense WHERE DeveloperName = 'SalesforceCPQ_CPQStandardPerm'];
        insert new PermissionSetLicenseAssign(
            AssigneeId = intUser.Id,
            PermissionSetLicenseId = psl.Id);
        PermissionSetAssignment intUserPSA = new PermissionSetAssignment(
        PermissionSetId = intPerm.Id,
        AssigneeId = intUser.Id);
        insert intUserPSA;
        
        System.runAs(intUser) {
            List<Account> acc =SBR_3_0_TestDataFactory.createAccounts(1, True, 'Prospect');
            List<Comment__c> comments = SBR_3_0_TestDataFactory.createComments(1,false,acc[0].Id);
            comments[0].User__c = '0000000001';
            insert comments;
            
            
            User u = [SELECT Id, Name FROM User WHERE Wynne_User_Name__c = '0000000001'];
            Comment__c comment = [SELECT Id, Created_By__c, User__c FROM Comment__c];
            Test.startTest();
            System.assertEquals(u.Name, comment.Created_By__c, 'Created by and user name do not match.');
            Test.stopTest();
        }
    }
}