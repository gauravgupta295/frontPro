/*********************************************************************************************************************
* Apex Class: SBR_3_0_UpdateProjectRelBatch_Test
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Class to test SBR_3_0_UpdateProjectRelationshipBatch
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Salesforce              2024-05-16           Initial version    
*********************************************************************************************************************/
@isTest(seeAllData=false) 
public class SBR_3_0_UpdateProjectRelBatch_Test {
    @isTest static void testUpdateProjectRelBatch() {
        Credential__c cred = SBR_3_0_TestDataFactory.createCredentials(1, false)[0];
        cred.Name = 'Mule_Token_Endpoint';
        cred.Key_Id__c = 'keyid';
        cred.Secret__c ='credSecret';
        insert cred;
        
        // Inserting a dummy Project__c record
        Project__c testProject = new Project__c();
        testProject.City__c = 'Centreville';
        testProject.Zip_Code__c = '20121';
        testProject.Country__c = 'US';
        testProject.Street__c = '6365 Multiplex Dr';
        testProject.State__c = 'VA';
        testProject.Project_Name__c = 'Test Project';
        testProject.Project_Relationship_Update_Flag__c = true;
        insert testProject;
        
        Territory__c terri = new Territory__c();
        terri.Name = 'Terri1';
        terri.Territory_Id__c = '1-170-30-1';
        terri.OwnerId = UserInfo.getUserId();
        insert terri;
       

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_FetchTerritory_MockSuccess());
        
        SBR_3_0_UpdateProjectRelationshipBatch updatePRBatch = new SBR_3_0_UpdateProjectRelationshipBatch();
        Database.executeBatch(updatePRBatch);
        
        Test.stopTest();
        
        List<Project_Relationship__c> relationships = [SELECT Id, Project__c, Territory__c FROM Project_Relationship__c];
        System.assertEquals(1, relationships.size(), 'Expecting 1 Project Relationship records');
        
       
    }

}