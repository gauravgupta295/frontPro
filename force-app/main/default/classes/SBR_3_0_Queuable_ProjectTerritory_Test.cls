@isTest
public class SBR_3_0_Queuable_ProjectTerritory_Test {
 @isTest static void testSBR_3_0_Queuable_ProjectTerritory() {
      Credential__c cred = SBR_3_0_TestDataFactory.createCredentials(1, false)[0];
        cred.Name = 'Mule_Token_Endpoint';
        cred.Key_Id__c = 'keyid';
        cred.Secret__c ='credSecret';
        insert cred;
        // Create sample records for Project__c and Territory__c
        List<Project__c> testProjects = new List<Project__c>();
        
        // Inserting a dummy Project__c record
        Project__c testProject = new Project__c();
        testProject.City__c = 'Centreville';
        testProject.Zip_Code__c = '20121';
        testProject.Country__c = 'US';
        testProject.Street__c = '6365 Multiplex Dr';
        testProject.State__c = 'VA';
        testProject.Project_Name__c = 'Test Project';
        testProjects.add(testProject);
        insert testProject;
        
        Territory__c terri = new Territory__c();
        terri.Name = 'Terri1';
        terri.Territory_Id__c = '1-170-30-1';
        //terri.Map_Analysis_Region__c = loc.Id;
        terri.OwnerId = UserInfo.getUserId();
        insert terri;
       

        Test.startTest();
       Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_FetchTerritory_MockSuccess());
   
        
        SBR_3_0_Queuable_ProjectTerritory queuableJob = new SBR_3_0_Queuable_ProjectTerritory(testProjects);
        System.enqueueJob(queuableJob);
        
        Test.stopTest();

        
        List<Project_Relationship__c> relationships = [SELECT Id, Project__c, Territory__c FROM Project_Relationship__c];
        System.assertEquals(testProjects.size(), relationships.size(), 'Expecting the number of Project Relationship records to match the number of Project records');
        
       
    }
}