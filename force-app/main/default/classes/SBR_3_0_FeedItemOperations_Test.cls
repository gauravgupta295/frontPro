/*********************************************************************************************************************
* Apex Class: SBR_3_0_FeedItemOperations_Test
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Class to test SBR_3_0_FeedItemOperations
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Konrad Haight           2022-05-02          Initial version    
*********************************************************************************************************************/
@isTest public with sharing class SBR_3_0_FeedItemOperations_Test {
    @TestSetup
    static void createTestUsers(){

        List<User> userList = new List<User>();

        Profile p = [SELECT Id FROM Profile WHERE Name='Sales'];
        //create ers user clone
        String ersUserName = 'ersuser' + DateTime.now().getTime() + '@SBRtestorg.com';
        User ersu = new User(Alias = 'ers', Email='ersuser@testorg.com',
        EmailEncodingKey='UTF-8', LastName='erstest', LanguageLocaleKey='en_US',
        LocaleSidKey='en_US', ProfileId = p.Id,
        TimeZoneSidKey='America/Los_Angeles',
        UserName=ersUserName);
        userList.add(ersu);

        //create pcm user clone
        String pcmUserName = 'pcmuser' + DateTime.now().getTime() + '@SBRtestorg.com';
        User pcmu = new User(Alias = 'pcm', Email='pcmuser@testorg.com',
        EmailEncodingKey='UTF-8', LastName='pcmtest', LanguageLocaleKey='en_US',
        LocaleSidKey='en_US', ProfileId = p.Id,
        TimeZoneSidKey='America/Los_Angeles',
        UserName=pcmUserName);

        userList.add(pcmu);

        Profile p2 = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        String adminUserName = 'systemadmin' + DateTime.now().getTime() + '@SBRtestorg.com';
        User adminUser = new User(Alias = 'standt', Email='systemadmin@testorg.com',
        EmailEncodingKey='UTF-8', LastName='adminTest', LanguageLocaleKey='en_US',
        LocaleSidKey='en_US', ProfileId = p2.Id,
        TimeZoneSidKey='America/Los_Angeles',
        UserName=adminUserName);

        userList.add(adminUser);

        insert userList;
    }

    @isTest static void testERSDeletePostOnNotOwnedLead(){
        PermissionSet ers = [SELECT Id FROM PermissionSet WHERE Name = 'ERS_Equip_Rental_Specialist'];
        PermissionSet pcm = [SELECT Id FROM PermissionSet WHERE Name = 'Branch_Manager1'];
        PermissionSetLicense psl = [SELECT Id FROM PermissionSetLicense WHERE DeveloperName = 'SalesforceCPQ_CPQStandardPerm'];
        User pcmu = [SELECT Id FROM User WHERE LastName = 'pcmtest'];
        User ersu = [SELECT Id FROM User WHERE LastName = 'erstest'];
        List<Lead> pcmLeads;
        FeedItem post;
        List<PermissionSetAssignment> psaList = new List<PermissionSetAssignment>();


        insert new PermissionSetLicenseAssign(
            AssigneeId = pcmu.Id,
            PermissionSetLicenseId = psl.Id);
        insert new PermissionSetLicenseAssign(
            AssigneeId = ersu.Id,
            PermissionSetLicenseId = psl.Id);
            
        PermissionSetAssignment erspsa = new PermissionSetAssignment(
           PermissionSetId = ers.Id,
           AssigneeId = ersu.Id);
        psaList.add(erspsa);
        PermissionSetAssignment pcmpsa = new PermissionSetAssignment(
           PermissionSetId = pcm.Id,
           AssigneeId = pcmu.Id);
        psaList.add(pcmpsa);

        insert psaList;


        System.runAs(pcmu){
            pcmLeads = SBR_3_0_TestDataFactory.createLeads(1, true);
            post = new FeedItem();
            post.ParentId = pcmLeads[0].Id;
            post.Body = 'PCM owned Lead Post';
            insert post;
        }
        
        System.runAs(ersu){
            try{
                Database.DeleteResult dr = Database.delete(post);
                //Force the test to fail if deletion is successful
                System.assert(!dr.isSuccess());
            } catch(DmlException e){
                system.assert(e.getMessage().contains('Item cannot be deleted'), 'Item cannot be deleted');
            }

        }

    }
    
    @isTest static void testAdminDeletePostOnNotOwnedLead(){
        PermissionSet pcm = [SELECT Id FROM PermissionSet WHERE Name = 'Branch_Manager1'];
        PermissionSetLicense psl = [SELECT Id FROM PermissionSetLicense WHERE DeveloperName = 'SalesforceCPQ_CPQStandardPerm'];
        User pcmu = [SELECT Id FROM User WHERE LastName = 'pcmtest'];
        User admin = [SELECT Id FROM User WHERE LastName = 'adminTest'];
        List<Lead> pcmLeads;
        FeedItem post;
        List<PermissionSetAssignment> psaList = new List<PermissionSetAssignment>();

        insert new PermissionSetLicenseAssign(
            AssigneeId = pcmu.Id,
            PermissionSetLicenseId = psl.Id);

        PermissionSetAssignment pcmpsa = new PermissionSetAssignment(
           PermissionSetId = pcm.Id,
           AssigneeId = pcmu.Id);
        insert pcmpsa;


        System.runAs(pcmu){
            pcmLeads = SBR_3_0_TestDataFactory.createLeads(1, true);
            post = new FeedItem();
            post.ParentId = pcmLeads[0].Id;
            post.Body = 'PCM owned Lead Post';
            insert post;
        }
        
        System.runAs(admin){
            try{
                Database.DeleteResult dr = Database.delete(post);
                System.assert(dr.isSuccess());
            } catch(DmlException e){
                //Force the test to fail if deletion is not successful
                system.assert(!e.getMessage().contains('Item cannot be deleted'), 'Item cannot be deleted');
            }

        }

    }
    
}