/*********************************************************************************************************************
* Apex Class: SBR_3_0_GoogleMapCmpController_Test
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - @description Test Class for SBR_3_0_GoogleMapCmpController
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Kunal Patel           2022-03-15            Initial version  
    2.0         Konrad Haight         2022-08-17            Added Tests  
*********************************************************************************************************************/
@isTest
public with sharing class SBR_3_0_GoogleMapCmpController_Test {
    @TestSetup
    static void makeData() {

        SBR_3_0_TriggerHandler.bypass('SBR_3_0_LocationTriggerHandler');
        SBR_3_0_TriggerHandler.bypass('SBR_3_0_AccountTriggerHandler');
        SBR_3_0_TriggerHandler.bypass('SBR_3_0_AssociatedLocationTriggerHandler');
        SBR_3_0_TriggerHandler.bypass('SBR_3_0_ProjectTriggerHandler');

        User systemUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        Profile standardUserProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User'];
        User standardUser = new User(Alias = 'standt', Email = 'standarduserTest@sunbeltrentals.com', EmailEncodingKey = 'UTF-8', LastName = 'Testing', LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', ProfileId = standardUserProfile.Id, TimeZoneSidKey = 'America/Los_Angeles', UserName = 'standarduserTestMap@sunbeltrentals.com', Analysis_Region_Key__c = '945', Rep_Type__c = 'All');
        insert standardUser;

        System.runAs(systemUser) {
            PermissionSetLicense license = [SELECT ID, Developername FROM PermissionSetLicense WHERE DeveloperName = 'SalesforceCPQ_CPQStandardPerm'];
            PermissionSetLicenseAssign psl = new PermissionSetLicenseAssign(AssigneeId = standardUser.Id, PermissionSetLicenseId = license.Id);
            insert psl;

            PermissionSet branchManagerPS = [
                SELECT Id
                FROM PermissionSet
                WHERE Name = 'Branch_Manager1'
            ];
            insert new PermissionSetAssignment(AssigneeId = standardUser.Id, PermissionSetId = branchManagerPS.Id);
        }

        Credential__c cred = SBR_3_0_TestDataFactory.createCredentials(1, false)[0];
        cred.Name = 'Mule_Token_Endpoint';
        cred.Key_Id__c = 'keyid';
        cred.Secret__c = 'credSecret';
        insert cred;

        List<Account> accounts = new List<Account>();
        Id userId = UserInfo.getUserId();

        update new User(Id = userId, Analysis_Region_Key__c = '922', Rep_Type__c = ''); // DodgePhases = Start, DodgeType = Sanitary Sewer

        SBR_3_0_TestDataFactory.createProjects(1, true);
        List<Account> creditAccounts = SBR_3_0_TestDataFactory.createAccounts(1, false, SBR_3_0_Constants.ACCOUNT_REC_TYPE_CREDIT);
        creditAccounts[0].Sales_Activity_Status__c = 'Dormant';
        creditAccounts[0].Sales_Rep_Commission__c = true;
        creditAccounts[0].Managed_w_OSR_Fingerprint__c = true;
        accounts.add(creditAccounts[0]);
        List<Account> erpAccounts = SBR_3_0_TestDataFactory.createAccounts(1, false, SBR_3_0_Constants.ACCOUNT_REC_TYPE_NAME_ERP);
        erpAccounts[0].Sales_Activity_Status__c = 'Watchlist';
        erpAccounts[0].BillingState = 'NY';
        erpAccounts[0].BillingPostalCode = '10002';
        accounts.add(erpAccounts[0]);
        List<Account> globalAccounts = SBR_3_0_TestDataFactory.createAccounts(1, false, SBR_3_0_Constants.ACCOUNT_REC_TYPE_GLOBAL);
        globalAccounts[0].Sales_Activity_Status__c = 'Watchlist';
        accounts.add(globalAccounts[0]);
        List<Account> officeAccounts = SBR_3_0_TestDataFactory.createAccounts(1, false, SBR_3_0_Constants.ACCOUNT_REC_TYPE_OFFICE);
        officeAccounts[0].Sales_Activity_Status__c = 'Watchlist';
        accounts.add(officeAccounts[0]);
        List<Account> prospectAccounts = SBR_3_0_TestDataFactory.createAccounts(1, false, SBR_3_0_Constants.ACCOUNT_REC_TYPE_PROSPECT);
        prospectAccounts[0].Sales_Activity_Status__c = 'Watchlist';
        accounts.add(prospectAccounts[0]);
        List<Account> vendorAccounts = SBR_3_0_TestDataFactory.createAccounts(1, false, SBR_3_0_Constants.ACCOUNT_REC_TYPE_VENDOR);
        vendorAccounts[0].Sales_Activity_Status__c = 'Watchlist';
        accounts.add(vendorAccounts[0]);
        accounts[0].BillingLatitude = 0;
        accounts[0].BillingLongitude = 0;
        accounts[0].BillingState = 'ID';
        accounts[0].BillingCountry = 'US';
        accounts[0].ShippingState = 'ID';
        accounts[0].ShippingCountry = 'US';
        insert accounts;

        Analysis_Region__c oAR = SBR_3_0_TestDataFactory.createAnalysisRegion(true, '922', accounts[0].id);
        oAR.Name = 'GENERAL TOOL';
        update oAR;

        Territory__c terri = new Territory__c();
        terri.Name = 'Terri1';
        terri.Territory_Id__c = '123';
        terri.OwnerId = UserInfo.getUserId();
        insert terri;

        Account_Relationship__c ar = new Account_Relationship__c();
        ar.Account_ID__c = accounts[0].Id;
        ar.Name = 'Test AR';
        ar.User_Account__c = userId;
        ar.Rank__c = 1;
        ar.Territory__c = terri.Id;
        insert ar;

        Account_Relationship__c ar2 = new Account_Relationship__c();
        ar2.Account_ID__c = accounts[1].Id;
        ar2.Name = 'Test AR';
        ar2.User_Account__c = userId;
        ar2.Rank__c = 30;
        ar.Territory__c = terri.Id;
        insert ar2;

        List<Contact> contacts = SBR_3_0_TestDataFactory.createContacts(1, accounts[0].Id, true);

        List<Schema.Location> jobLocations = SBR_3_0_TestDataFactory.createLocations(1, true, SBR_3_0_Constants.LOCATION_REC_TYPE_JOB_LOC);
        List<Schema.Location> branches = SBR_3_0_TestDataFactory.createLocations(1, true, SBR_3_0_Constants.LOCATION_REC_TYPE_BRANCH);

        List<AssociatedLocation> jobSites = SBR_3_0_TestDataFactory.createAssociatedLocations(1, accounts[0].Id, branches[0].Id, jobLocations[0].Id, false);
        insert jobSites;
        List<Contract> contracts = SBR_3_0_TestDataFactory.createContracts(1, accounts[0].Id, 12, 'Draft', true);

        contracts[0].Status = 'Activated';
        update contracts;

        List<Project__c> projects = SBR_3_0_TestDataFactory.createProjects(1, true);
        for (Project__c p : projects) {
            p.Bid_Date__c = Date.today().addDays(5);
            p.Kickoff_Date__c = Date.today().addDays(5);
            p.Dodge_Phase__c = 'Negotiating';
            p.Primary_Project_Type__c = 'Storm Sewer';
            p.Valuation__c = 1000000;
            p.Display_on_Map__c = '945';
        }
        update projects;

        // Create Analysis Region
        List<Analysis_Region__c> regions = new List<Analysis_Region__c>();
        Analysis_Region__c region = new Analysis_Region__c();
        region.Name = 'GENERAL TOOL';
        region.Analysis_Region_Key__c = '922';
        region.Company_Code__c = '01';
        regions.add(region);
        Analysis_Region__c region2 = new Analysis_Region__c();
        region2.Analysis_Region_Key__c = '945';
        region2.Name = 'GENERAL TOOL';
        region2.Company_Code__c = '01';
        regions.add(region2);
        insert regions;

        // Create Territory
        List<Territory__c> territories = new List<Territory__c>();
        Territory__c terr = new Territory__c();
        terr.Analysis_Region__c = regions[0].Id;
        terr.Territory_ID__c = '123123123';
        territories.add(terr);
        Territory__c terr2 = new Territory__c();
        terr2.Analysis_Region__c = regions[1].Id;
        terr2.Territory_ID__c = '432432432';
        territories.add(terr2);
        System.runAs(standardUser) {
            insert territories;
        }

        Schema.Location branch = SBR_3_0_TestDataFactory.createLocations(1, false, SBR_3_0_Constants.LOCATION_REC_TYPE_BRANCH)[0];
        branch.Name = 'Branch';
        branch.Company_Code__c = '01';
        branch.Analysis_Region_Key__c = '922';
        branch.Operational_Status__c = 'A';
        insert branch;

        // List<Schema.Location> locations = new List<Schema.Location>();
        // locations.add(branch);
        // locations.add(branch2);
        // insert locations;

        List<User_Location__c> userLocations = new List<User_Location__c>();
        User_Location__c ul = new User_Location__c();
        ul.Analysis_Region__c = regions[0].Id;
        ul.User__c = userId;
        ul.Branch__c = branch.Id;
        userLocations.add(ul);

        // Create Project Relationship
        List<Project_Relationship__c> projRelationships = new List<Project_Relationship__c>();
        for (Project__c p : projects) {
            Project_Relationship__c pr = new Project_Relationship__c();
            pr.Project__c = p.Id;
            pr.Territory__c = territories[1].Id;
            pr.Territory_ID__c = territories[1].Territory_ID__c;
            projRelationships.add(pr);
        }
        insert projRelationships;

        List<Opportunity> oppties = SBR_3_0_TestDataFactory.createOppts(1, accounts[0].Id, true);
        for (Opportunity o : oppties) {
            o.CloseDate = Date.today().addDays(5);
            o.Est_Start_Date__c = Date.today().addDays(5);
        }
        update oppties;

        List<Campaign> campaigns = SBR_3_0_TestDataFactory.createCampaigns(1, true, 'Marketing');
        List<Lead> leads = SBR_3_0_TestDataFactory.createLeads(1, true);
        for(Lead l : leads) {
            l.Source_Campaign__c = campaigns[0].Id;
            l.LeadSource = 'Employee Referral';
        }
        update leads;

        List<Task> tasks = new List<Task>();
        tasks.addAll(SBR_3_0_TestDataFactory.createTasks(1, accounts[0].Id, contacts[0].Id, userId, true));
        tasks.addAll(SBR_3_0_TestDataFactory.createTasks(1, projects[0].Id, null, userId, true));
        tasks.addAll(SBR_3_0_TestDataFactory.createTasks(1, accounts[0].Id, contacts[0].Id, userId, true));
        tasks.addAll(SBR_3_0_TestDataFactory.createTasks(1, null, Leads[0].Id, userId, true));
        tasks.addAll(SBR_3_0_TestDataFactory.createTasks(1, oppties[0].Id, null, userId, true));

        for (Task t : tasks) {
            t.ActivityDate = Date.today();
        }
        update tasks;

        SBR_3_0_TestDataFactory.createAppointments(3, accounts[0].Id, contacts[0].Id, true);
        SBR_3_0_TestDataFactory.createAppointments(2, null, Leads[0].Id, true);
        SBR_3_0_TestDataFactory.createAppointments(2, oppties[0].Id, null, true);
    }

    @isTest
    static void testAllRecords() {
        Test.startTest();
        List<SBR_3_0_GoogleMapCmpController.MarkerWrapper> allList = SBR_3_0_GoogleMapCmpController.getAllRecords();
        SBR_3_0_GoogleMapCmpController.getJobSites(null);
        Test.stopTest();
        System.assertNotEquals(0, allList.size(), 'Assert Success');
    }

    @isTest
    static void testAccounts() {
        Test.startTest();
        List<SBR_3_0_GoogleMapCmpController.MarkerWrapper> accountsList = SBR_3_0_GoogleMapCmpController.getAccounts(null);
        SBR_3_0_GoogleMapCmpController.MarkerWrapper accWrapper = SBR_3_0_GoogleMapCmpController.getAccount(accountsList[0].account.Id);
        Test.stopTest();

        System.assertEquals(1, accountsList.size(), 'Assert Success');
        System.assertEquals(accountsList[0].account.Id, accWrapper.account.Id, 'Assert Success');

        System.assertEquals(1, accountsList[0].compareTo(accWrapper), 'Assert Success');
        System.assertEquals(0, accWrapper.compareTo(accWrapper), 'Assert Success');
    }

    @isTest
    static void testAccountsTop50() {
        SBR_3_0_GoogleMapCmpController.FilterWrapper fw = new SBR_3_0_GoogleMapCmpController.FilterWrapper();
        fw.top50Accounts = true;
        fw.top25Accounts = false;
        fw.watchlistAccounts = true;
        fw.dormantAccounts = false;
        fw.rankRangeAccounts = true;
        fw.rankRangeAccountsStart = '26';
        fw.rankRangeAccountsEnd = '45';
        Test.startTest();
        List<SBR_3_0_GoogleMapCmpController.MarkerWrapper> accountsList = SBR_3_0_GoogleMapCmpController.getAccounts(fw);
        SBR_3_0_GoogleMapCmpController.MarkerWrapper accWrapper = SBR_3_0_GoogleMapCmpController.getAccount(accountsList[0].account.Id);
        Test.stopTest();

        System.assertEquals(1, accountsList.size(), 'Assert Success');
        System.assertEquals(accountsList[0].account.Id, accWrapper.account.Id, 'Assert Success');

        System.assertEquals(1, accountsList[0].compareTo(accWrapper), 'Assert Success');
        System.assertEquals(0, accWrapper.compareTo(accWrapper), 'Assert Success');
    }

    /*
    @isTest
    static void testAccountsThree() {
        SBR_3_0_GoogleMapCmpController.FilterWrapper fw = new SBR_3_0_GoogleMapCmpController.FilterWrapper();
        fw.watchlistAccounts = false;
        fw.dormantAccounts = true;
        fw.accountRecordType = 'Prospect ';
        Test.startTest();
        List<SBR_3_0_GoogleMapCmpController.MarkerWrapper> accountsList = SBR_3_0_GoogleMapCmpController.getAccounts(fw);
        //SBR_3_0_GoogleMapCmpController.MarkerWrapper accWrapper = SBR_3_0_GoogleMapCmpController.getAccount(accountsList[0].account.Id);
        Test.stopTest();

        
        System.assertEquals(1, accountsList.size());
        System.assertEquals(accountsList[0].account.Id, accWrapper.account.Id);

        System.assertEquals(1, accountsList[0].compareTo(accWrapper));
        System.assertEquals(0, accWrapper.compareTo(accWrapper)); 
    }*/

    @isTest
    static void testOpportunities() {
        Test.startTest();
        List<SBR_3_0_GoogleMapCmpController.MarkerWrapper> oppList = SBR_3_0_GoogleMapCmpController.getOpportunities(null);
        SBR_3_0_GoogleMapCmpController.MarkerWrapper oppWrapper = SBR_3_0_GoogleMapCmpController.getOpportunity(oppList[0].opportunity.Id);
        Test.stopTest();

        System.assertEquals(1, oppList.size(), 'Assert Success');
        System.assertEquals(oppList[0].opportunity.Id, oppWrapper.opportunity.Id, 'Assert Success');
    }

    @isTest
    static void testLeads() {
        Test.startTest();
        List<SBR_3_0_GoogleMapCmpController.MarkerWrapper> leadsList = SBR_3_0_GoogleMapCmpController.getLeads(null);
        SBR_3_0_GoogleMapCmpController.MarkerWrapper leadWrapper = SBR_3_0_GoogleMapCmpController.getLead(leadsList[0].lead.Id);
        Test.stopTest();
        System.assertEquals(1, leadsList.size(), 'Assert Success');
        System.assertEquals(leadsList[0].lead.Id, leadWrapper.lead.Id, 'Assert Success');
    }

    @isTest
    static void testProjects() {
        User testUser = [SELECT Id FROM User WHERE UserName = 'standarduserTestMap@sunbeltrentals.com'];
        List<SBR_3_0_GoogleMapCmpController.MarkerWrapper> projectsList = new List<SBR_3_0_GoogleMapCmpController.MarkerWrapper>();
        SBR_3_0_GoogleMapCmpController.MarkerWrapper projWrapper;
        System.runAs(testUser) {
            Test.startTest();
            List<Analysis_Region__c> regions = [SELECT Id FROM Analysis_Region__c WHERE Analysis_Region_Key__c = '945'];
            Schema.Location branch = SBR_3_0_TestDataFactory.createLocations(1, false, SBR_3_0_Constants.LOCATION_REC_TYPE_BRANCH)[0];
            branch.Name = 'Branch2';
            branch.Company_Code__c = '01';
            branch.Analysis_Region_Key__c = '945';
            branch.Operational_Status__c = 'A';
            insert branch;

            User_Location__c ul2 = new User_Location__c();
            ul2.Analysis_Region__c = regions[0].Id;
            ul2.User__c = testUser.Id;
            ul2.Branch__c = branch.Id;
            insert ul2;

            SBR_3_0_GoogleMapCmpController.FilterWrapper wrapper = (SBR_3_0_GoogleMapCmpController.FilterWrapper) System.JSON.deserialize('{"userTerritories":"' + testUser.Id + '","cityProject":false,"plantIdProject":false,"plantNameProject":false,"valuationProject":false,"valuationRangeProjects":false,"squareFootageRangeProjects":false,"projectStatus":"","projectPrimaryType":"Default","projectStage":"","projectOrigin":"","projectActivity":"","projectTiming":"","projectDodgePhase":"Default"}', SBR_3_0_GoogleMapCmpController.FilterWrapper.class);
            wrapper.cityProjectValue = '';
            wrapper.plantIdProject = false;
            wrapper.plantIdProjectValue = '';
            wrapper.plantNameProject = false;
            wrapper.plantNameProjectValue = '';
            wrapper.valuationProject = false;
            wrapper.valuationProjectValue = '';
            wrapper.next30DaysCompletionDateProject = false;
            wrapper.lastXDaysCompletionDateProject = false;
            wrapper.nextXDaysCompletionDateProject = false;
            wrapper.dateRangeCompletionDateProjects = false;
            wrapper.lastXDaysKickoffDateProject = false;
            wrapper.lastXDaysKickoffDateProjectValue = '';
            wrapper.nextXDaysKickoffDateProject = false;
            wrapper.nextXDaysKickoffDateProjectValue = '';
            wrapper.dateRangeKickoffDateProjects = false;
            wrapper.next30DaysAFEDateProject = false;
            wrapper.lastXDaysAFEDateProject = false;
            wrapper.lastXDaysAFEDateProjectValue = '';
            wrapper.nextXDaysAFEDateProject = false;
            wrapper.nextXDaysAFEDateProjectValue = '';
            wrapper.dateRangeAFEDateProjects = false;
            wrapper.next30DaysRQFDateProject = false;
            wrapper.lastXDaysRQFDateProject = false;
            wrapper.lastXDaysRQFDateProjectValue = '';
            wrapper.nextXDaysRQFDateProject = false;
            wrapper.nextXDaysRQFDateProjectValue = '';
            wrapper.dateRangeRQFDateProjects = false;

            projectsList = SBR_3_0_GoogleMapCmpController.getProjects(wrapper);
            projWrapper = SBR_3_0_GoogleMapCmpController.getProject(projectsList[0].project.Id);
            Test.stopTest();
        }

        System.assertEquals(1, projectsList.size(), 'Assert Success');
        System.assertEquals(projectsList[0].project.Id, projWrapper.project.Id, 'Assert Success');
    }
    @isTest
    static void testGetJobsites() {
        Test.startTest();
        List<SBR_3_0_GoogleMapCmpController.MarkerWrapper> jobSitesLst = SBR_3_0_GoogleMapCmpController.getJobsites(null);
        Test.stopTest();

        System.assertEquals(0, jobSitesLst.size(), 'No related Order'); // no related order
    }

    @isTest
    static void testTasks() {
        Test.startTest();
        List<SBR_3_0_GoogleMapCmpController.MarkerWrapper> tasksList = SBR_3_0_GoogleMapCmpController.getTasks(null);
        Test.stopTest();
        System.assertEquals(5, tasksList.size(), 'Assert Success');
    }

    @isTest
    static void testBranches() {
        SBR_3_0_GoogleMapCmpController.FilterWrapper fw = new SBR_3_0_GoogleMapCmpController.FilterWrapper();
        fw.loadBranchData = true;
        Test.startTest();
        List<SBR_3_0_GoogleMapCmpController.MarkerWrapper> branchesList = SBR_3_0_GoogleMapCmpController.getBranches(fw);
        Test.stopTest();
        System.assertEquals(1, branchesList.size(), 'Assert Success');
    }

    @isTest
    static void testAppointments() {
        Test.startTest();
        List<SBR_3_0_GoogleMapCmpController.MarkerWrapper> apptsList = SBR_3_0_GoogleMapCmpController.getAppointments(null);
        Test.stopTest();
        System.assertEquals(7, apptsList.size(), 'Assert Success'); //checking
    }

    @isTest
    static void testGetTasksAndAppointmentsById() {
        Test.startTest();
        List<Event> testAppts = [SELECT Id, WhoId FROM Event];
        List<SBR_3_0_GoogleMapCmpController.MarkerWrapper> resultAppts = new List<SBR_3_0_GoogleMapCmpController.MarkerWrapper>();
        List<Task> testTasks = [SELECT Id FROM Task];
        List<SBR_3_0_GoogleMapCmpController.MarkerWrapper> resultTasks = new List<SBR_3_0_GoogleMapCmpController.MarkerWrapper>();
        for (Event appt : testAppts) {
            resultAppts.add(SBR_3_0_GoogleMapCmpController.getAppointment(appt.Id));
        }
        for (Task task : testTasks) {
            resultTasks.add(SBR_3_0_GoogleMapCmpController.getTask(task.Id));
        }
        Test.stopTest();

        System.assertEquals(7, resultAppts.size(), 'Assert Success');
        System.assertEquals(5, resultTasks.size(), 'Assert Success');
    }

    @isTest
    static void testDomains() {
        Test.startTest();
        // Chrome test
        String vfDomainChrome = SBR_3_0_GoogleMapCmpController.getVisualforceDomain('Large', 'Chrome');
        //String vfDomainMobile = SBR_3_0_GoogleMapCmpController.getVisualforceDomain('Small', 'Safari');
        String ltngDomain = SBR_3_0_GoogleMapCmpController.getLightningDomain();
        Test.stopTest();

        System.assertNotEquals(ltngDomain, vfDomainChrome, 'Assert Success');
    }

    @isTest
    static void testUpdateEventTask() {
        String apptString = 'Appointment Test Outcome';
        String taskString = 'Task Test Description';

        Test.startTest();
        List<SBR_3_0_GoogleMapCmpController.MarkerWrapper> apptsList = SBR_3_0_GoogleMapCmpController.getAppointments(null);
        List<SBR_3_0_GoogleMapCmpController.MarkerWrapper> tasksList = SBR_3_0_GoogleMapCmpController.getTasks(null);

        Id apptId = apptsList.get(0).event.Id;
        Id taskId = tasksList.get(0).task.Id;

        SBR_3_0_GoogleMapCmpController.updateTaskEvent(apptId, apptString);
        SBR_3_0_GoogleMapCmpController.updateTaskEvent(taskId, taskString);

        Test.stopTest();

        Event appt = [SELECT ID, Outcome__c FROM Event WHERE ID = :apptId];
        Task t = [SELECT ID, Description FROM Task WHERE ID = :taskId];

        System.assertEquals(apptString, appt.Outcome__c, 'Assert Success');
        System.assertEquals(taskString, t.Description, 'Assert Success');
    }

    @isTest
    static void testSetGoogleAPIKey() {
        Test.startTest();
        SBR_3_0_GoogleMapCmpController.setGoogleMapAPIKey();
        Test.stopTest();

        System.assertNotEquals(SBR_3_0_GoogleMapCmpController.apiKey, '', 'API key not null');
    }

    @isTest
    static void testWiredTerritories() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_FetchGeoJson_Test());
        List<SBR_3_0_GoogleMapCmpController.TerritoryWrapper> territoryList = SBR_3_0_GoogleMapCmpController.getWiredTerritories();
        Test.stopTest();

        System.assertNotEquals(0, territoryList.size(), 'Assert Success');
    }
}