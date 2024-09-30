/*********************************************************************************************************************
* Apex Class: SBR_3_0_ProjectDA_Test
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Class to test SBR_3_0_ProjectDA
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Nate Kanyok             2022-08-17         Initial version    
*********************************************************************************************************************/
@isTest
public without sharing class SBR_3_0_ProjectDA_Test {
       
    @TestSetup
    static void makeData(){

        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
        User user = new User(Alias = 'standt', Email='standardperson@airrexusa.com', 
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', ProfileId = p.Id, 
        TimeZoneSidKey='America/Los_Angeles', UserName='standardperson@airrexusa.com',
        Analysis_Region_Key__c = '941', Rep_Type__c='Industrial');

        insert user;


        Project__c testProject = new Project__c(
            Project_Name__c = 'testProject',
            City__c = 'TestTown',
            State__c = 'TX',
            Display_on_Map__c = '920'
        );
        insert testProject;

        // Create Analysis Region
        Analysis_Region__c ar = new Analysis_Region__c();
        ar.Analysis_Region_Key__c = '941';
        ar.Company_Code__c  = '01';
        ar.Name = '920';
        insert ar;

        // Create Territory
        Territory__c terr = new Territory__c();
        terr.Analysis_Region__c = ar.Id;
        insert terr;

        // Create Project Relationship
        Project_Relationship__c pr = new Project_Relationship__c();
        pr.Project__c = testProject.Id;
        pr.Territory__c = terr.Id;
        insert pr;

        Schema.Location branch = SBR_3_0_TestDataFactory.createLocations(1, false, SBR_3_0_Constants.LOCATION_REC_TYPE_BRANCH)[0];
        branch.Name = 'Branch';
        branch.Company_Code__c = '01';
        branch.Analysis_Region_Key__c = '941';
        insert branch;

        User_Location__c ul = new User_Location__c();
        ul.Analysis_Region__c = ar.Id;
        ul.User__c = user.Id;
        ul.Branch__c = branch.Id;
        insert ul;
    }

    @isTest
    static void testGetProjects() {
        List<Project__c> projectList = new List<Project__c>();

        Test.startTest();
            projectList = SBR_3_0_ProjectDA.getProjects();
        Test.stopTest();

        System.assertEquals(1, projectList.size());
    }

    @isTest
    static void testGetProject_givenSet() {
        List<Project__c> projectQuery = [
            SELECT
                Id
            FROM
                Project__c
        ];
        Set<Id> projectIdSet = new Set<Id>();
        
        for (Project__c project : projectQuery) {
            projectIdSet.add(project.Id);
        }

        Map<Id,Project__c> projectMap = new Map<Id,Project__c>();

        Test.startTest();
            projectMap = SBR_3_0_ProjectDA.getProjects(projectIdSet);
        Test.stopTest();

        System.assertEquals(1, projectMap.size());
    }
    
    @isTest
    static void testGetProject_givenID() {
        Project__c projectQuery = [
            SELECT
                Id
            FROM
                Project__c
            LIMIT 1
        ];
        
        Test.startTest();
        	Project__c testProject = SBR_3_0_ProjectDA.getProject(projectQuery.Id);
        Test.stopTest();
    }

    @isTest
    static void testGetFilteredProjects() {
        Project__c projectQuery = [
            SELECT
                Id
            FROM
                Project__c
            LIMIT 1
        ];

        projectQuery.Project_Name__c = 'TestP1';
        projectQuery.City__c = 'Austin';
        projectQuery.Plant_ID__c = '123';
        projectQuery.Plant_Name__c = 'PName';
        projectQuery.Valuation__c = 500;
        projectQuery.Square_Footage__c = 500;
        projectQuery.Project_Status__c = 'Pending';
        projectQuery.Project_Origin__c = 'Dodge';
        projectQuery.Bid_Date__c = Date.today().addDays(10);
        projectQuery.Completion_Date__c = Date.today().addDays(10);
        projectQuery.Kickoff_Date__c = Date.today().addDays(10);
        projectQuery.AFE_Date__c = Date.today().addDays(10);
        projectQuery.RQF_Date__c = Date.today().addDays(10);
        projectQuery.Primary_Project_Type__c = 'Bank';
        projectQuery.Dodge_Phase__c = 'Start';
        update projectQuery;

        User u = [SELECT ID FROM User WHERE Analysis_Region_Key__c = '941' AND Rep_Type__c = 'Industrial' LIMIT 1];

        SBR_3_0_GoogleMapCmpController.FilterWrapper wrapper = new SBR_3_0_GoogleMapCmpController.FilterWrapper();
        wrapper.userTerritories = u.Id;
        wrapper.projectSearch = 'Test';
        wrapper.cityProject = true;
        wrapper.cityProjectValue = 'Austin';
        wrapper.plantIdProject = true;
        wrapper.plantIdProjectValue = '123';
        wrapper.plantNameProject = true;
        wrapper.plantNameProjectValue = 'PName';
        wrapper.valuationRangeProjects = true;
        wrapper.valuationRangeProjectsStart = '1';
        wrapper.valuationRangeProjectsEnd = '1000';
        wrapper.squareFootageRangeProjects = true;
        wrapper.squareFootageRangeProjectsStart = '1';
        wrapper.squareFootageRangeProjectsEnd = '1000';
        wrapper.projectStatus = 'Pending';
        wrapper.projectOrigin = JSON.serialize(new List<String>{'Dodge'});
        wrapper.projectPrimaryType = JSON.serialize(new List<String>{'Bank'});
        wrapper.projectDodgePhase = JSON.serialize(new List<String>{'Start'});

        wrapper.next30DaysBidDateProject = true;
        wrapper.nextXDaysBidDateProject = true;
        wrapper.nextXDaysBidDateProjectValue = '30';
        wrapper.dateRangeBidDateProjects = true;
        wrapper.dateRangeBidDateProjectsStart = String.valueOf(Date.today().addDays(-5));
        wrapper.dateRangeBidDateProjectsEnd = String.valueOf(Date.today().addDays(20));

        wrapper.next30DaysCompletionDateProject = true;
        wrapper.nextXDaysCompletionDateProject = true;
        wrapper.nextXDaysCompletionDateProjectValue = '30';
        wrapper.dateRangeCompletionDateProjects = true;
        wrapper.dateRangeCompletionDateProjectsStart = String.valueOf(Date.today().addDays(-5));
        wrapper.dateRangeCompletionDateProjectsEnd = String.valueOf(Date.today().addDays(20));

        wrapper.next30DaysKickoffDateProject = true;
        wrapper.nextXDaysKickoffDateProject = true;
        wrapper.nextXDaysKickoffDateProjectValue = '30';
        wrapper.dateRangeKickoffDateProjects = true;
        wrapper.dateRangeKickoffDateProjectsStart = String.valueOf(Date.today().addDays(-5));
        wrapper.dateRangeKickoffDateProjectsEnd = String.valueOf(Date.today().addDays(20));

        wrapper.next30DaysAFEDateProject = true;
        wrapper.nextXDaysAFEDateProject = true;
        wrapper.nextXDaysAFEDateProjectValue = '30';
        wrapper.dateRangeAFEDateProjects = true;
        wrapper.dateRangeAFEDateProjectsStart = String.valueOf(Date.today().addDays(-5));
        wrapper.dateRangeAFEDateProjectsEnd = String.valueOf(Date.today().addDays(20));

        wrapper.next30DaysRQFDateProject = true;
        wrapper.nextXDaysRQFDateProject = true;
        wrapper.nextXDaysRQFDateProjectValue = '30';
        wrapper.dateRangeRQFDateProjects = true;
        wrapper.dateRangeRQFDateProjectsStart = String.valueOf(Date.today().addDays(-5));
        wrapper.dateRangeRQFDateProjectsEnd = String.valueOf(Date.today().addDays(20));

        Test.startTest();
            List<Project__c> testProjects = new List<Project__c>();
            System.runAs(u) {
                testProjects = SBR_3_0_ProjectDA.getProjectsFiltered(wrapper);
                List<String> dodgeTypes = SBR_3_0_ProjectDA.getUsersProjectDodgeTypes(u.Id);
                List<String> dodgePhases = SBR_3_0_ProjectDA.getUsersProjectDodgePhases(u.Id);
            }
        Test.stopTest();

        System.assertEquals(testProjects.size(), 1); // todo increase result
    }
}