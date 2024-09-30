/*********************************************************************************************************************
* Apex Class: SBR_3_0_ProjectOperations_Test
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Test Class to manage handler logic for Project
* - SAL-473,1502
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME                        DATE                DETAIL FEATURES
    1.0         Harry Rokad                       2022-04-04               Initial version    
*********************************************************************************************************************/


@isTest
public with sharing class SBR_3_0_ProjectOperations_Test implements HttpCalloutMock {

    @TestSetup
    static void makeData(){
        Credential__c cred = SBR_3_0_TestDataFactory.createCredentials(1, false)[0];
        cred.Name = 'Mule_Token_Endpoint';
        cred.Key_Id__c = 'keyid';
        cred.Secret__c ='credSecret';
        insert cred;             
    }
    
    public HTTPResponse respond(HTTPRequest req) {
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type',SBR_3_0_Constants.APP_JSON);
        if(req.getEndpoint().endsWithIgnoreCase('token')){
            res.setBody('{"access_token":"test"}');
            
        }else {
            res.setBody('{ "data": {"territories" : [{"territoryId" : "32254438"}], "errorCode": "0000", "errorDesc": "Success", "company": "01", "customer": "4", "jobsite": "CO MEDIMMUNE BOULDER", "location": "0720", "items": [ { "catId": "123", "classId": "4567", "productId": "1234567", "rateFlag": "B", "rateFlagDescription": "Book Rates", "notToExceed": "", "notToExceedDescription": "No override needed for any change.", "rppPercentage": ".000", "needPassword": "FALSE", "showAllRates": "FALSE", "suggestMinimalHours": ".00", "isConsumerCatClass": "FALSE", "isSerialized": "FALSE", "customerDiscountPercentageDaily": ".00", "customerDiscountPercentageWeekly": ".00", "customerDiscountPercentageMonthly": ".00", "customerMonthly": null, "rates": { "suggestedRates": { "minimum": ".00", "daily": ".00", "weekly": ".00", "monthly": ".00" }, "bookRates": { "minimum": ".00", "daily": ".00", "weekly": ".00", "monthly": ".00" } } } ] } }');
        }
        res.setStatusCode(200);
        return res;
    }
    @isTest static void publishProjectRecordsTest(){
        Project__c testdata = new Project__c(Project_Name__c='Test Project', City__c='Grove St', State__c='NJ');
        insert testdata;

        Project__c project=[select Id from Project__c where Id=: testdata.Id limit 1];

        System.assertEquals(testdata.Id, project.Id);


    }

    @isTest static void fetchLatLongSuccessTest(){
        // Set mock callout class 
        
        List<Project__c> pro=SBR_3_0_TestDataFactory.createProjectsNew(1,true);
        Id ide;
        for (Project__c proj: pro){
            ide=proj.Id;
        }
        Project__c pct =  [SELECT ID, Street__c, City__c, Project_Origin__c, State__c, Country__c, ZIP_Code__c, Latitude_Longitude_Status__c, Latitude_Longitude_error__c, Latitude_Longitude__c, Latitude_Longitude__Latitude__s, Latitude_Longitude__Longitude__s FROM Project__c Where Id =: ide ];
        pct.Street__c = '6365 Multiplex Drive';
        pct.City__c = 'Centreville';
        pct.State__c = 'VA';
        pct.ZIP_Code__c = '20121';
        pct.Country__c = 'US';
        pct.Project_Origin__c = 'User Created';
        pct.Latitude_Longitude__Latitude__s = 0; 
        pct.Latitude_Longitude__Longitude__s = NULL;
        pct.Latitude_Longitude__Longitude__s = 0;
        
        update pct;

        Project__c oldPct = pct.clone(true);
        oldPct.Street__c = 'Test Street';
        oldPct.State__c='NJ';
        oldpct.ZIP_Code__c = '2121';

        Map<Id, Project__c> newProjectMap = new Map<Id, Project__c>();
        newProjectMap.put(pct.Id, pct);
        Map<Id, Project__c> oldProjectMap = new Map<Id, Project__c>();
        oldProjectMap.put(pct.Id, oldPct);
        
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_FetchLatLong_MockSuccess());
        SBR_3_0_ProjectOperations.fetchAddressLatLong(oldProjectMap, newProjectMap);
         SBR_3_0_ProjectOperations.fetchAddressLatLong(null, newProjectMap); //checking
        Test.stopTest();

        Project__c pct2 = [SELECT ID, Latitude_Longitude_Status__c FROM Project__c Where Id =: ide];
        //system.assertEquals('Success', act2.Latitude_Longitude_Status__c, 'Street Address Lat Long Status is not set to Success');
        system.assertEquals('Fetching', pct2.Latitude_Longitude_Status__c, 'Street Address Lat Long Status is not set to Success');
    }


    @isTest static void fetchLatLongSuccessTest2(){
        // Set mock callout class 
        
        List<Project__c> pro=SBR_3_0_TestDataFactory.createProjectsNew(1,true);
        Id ide;
        for (Project__c proj: pro){
            ide=proj.Id;
        }
        Project__c pct =  [SELECT ID, Street__c, City__c, Project_Origin__c, State__c, Country__c, ZIP_Code__c, Latitude_Longitude_Status__c, Latitude_Longitude_error__c, Latitude_Longitude__c, Latitude_Longitude__Latitude__s, Latitude_Longitude__Longitude__s FROM Project__c Where Id =: ide ];
        pct.Project_Name__c = 'test creation';
        pct.Street__c = '6365 Multiplex Drive';
        pct.City__c = 'Centreville';
        pct.State__c = 'VA';
        pct.ZIP_Code__c = '20121';
        pct.Country__c = 'US';
        pct.Project_Origin__c = 'User Created';
        pct.Id = null;
        insert pct;

        Project__c oldPct = pct.clone(true);
        oldPct.Street__c = 'Test Street';
        oldPct.State__c='NJ';


        Map<Id, Project__c> newProjectMap = new Map<Id, Project__c>();
        newProjectMap.put(pct.Id, pct);
        Map<Id, Project__c> oldProjectMap = new Map<Id, Project__c>();
        oldProjectMap.put(pct.Id, oldPct);
        
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_FetchLatLong_MockSuccess());
        SBR_3_0_ProjectOperations.fetchAddressLatLong(oldProjectMap, newProjectMap);
        Test.stopTest();

        Project__c pct2 = [SELECT ID, Latitude_Longitude_Status__c FROM Project__c Where Id =: ide];
        //system.assertEquals('Success', act2.Latitude_Longitude_Status__c, 'Street Address Lat Long Status is not set to Success');
        //system.assertEquals('Fetching', pct2.Latitude_Longitude_Status__c);
    }

    @isTest static void fetchLatLongErrorTest(){

        List<Project__c> pro=SBR_3_0_TestDataFactory.createProjectsNew(1,true);
        Id ide;
        for (Project__c proj: pro){
            ide=proj.Id;
        }

        Project__c pct =  [SELECT ID, Project_Origin__c, Street__c, City__c, State__c, Country__c, ZIP_Code__c, Latitude_Longitude_Status__c, Latitude_Longitude_error__c, Latitude_Longitude__c, Latitude_Longitude__Latitude__s, Latitude_Longitude__Longitude__s FROM Project__c Where Id =: ide ];

        pct.Street__c = '6365 Multiplex Drive';
        pct.City__c = 'Centreville';
        pct.State__c = 'VA';
        pct.ZIP_Code__c = '20121';
        pct.Country__c = 'US';
        pct.Project_Origin__c = 'User Created';
        update pct;

        Project__c oldPct = pct.clone(true);
        oldPct.Street__c = 'Test Street Changed';
        oldPct.State__c='NJ';

        Map<Id, Project__c> newProjectMap = new Map<Id, Project__c>();
        newProjectMap.put(pct.Id, pct);
        Map<Id, Project__c> oldProjectMap = new Map<Id, Project__c>();
        oldProjectMap.put(pct.Id, oldPct);
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_FetchLatLong_MockFailed());
        SBR_3_0_ProjectOperations.fetchAddressLatLong(oldProjectMap, newProjectMap);
        Test.stopTest();

        Project__c pct2 = [SELECT ID, Latitude_Longitude_Status__c FROM Project__c Where Id =: ide];
        System.debug(pct2);
        system.assertEquals('Fetching', pct2.Latitude_Longitude_Status__c, 'Street Address Lat Long Status is not set to Error');
    }

    @isTest static void fetchLatLongInsertTest(){
        // Set mock callout class 
        
        List<Project__c> pro=SBR_3_0_TestDataFactory.createProjectsNew(1,true);
        Id ide;
        for (Project__c proj: pro){
            ide=proj.Id;
        }
        Project__c pct =  [SELECT ID, Street__c, City__c, Project_Origin__c, State__c, Country__c, ZIP_Code__c, Latitude_Longitude_Status__c, Latitude_Longitude_error__c, Latitude_Longitude__c, Latitude_Longitude__Latitude__s, Latitude_Longitude__Longitude__s FROM Project__c Where Id =: ide ];
        pct.Street__c = '6365 Multiplex Drive';
        pct.City__c = 'Centreville';
        pct.State__c = 'VA';
        pct.ZIP_Code__c = '20121';
        pct.Country__c = 'US';
        pct.Project_Origin__c = 'User Created';
        update pct;



        Map<Id, Project__c> newProjectMap = new Map<Id, Project__c>();
        newProjectMap.put(pct.Id, pct);
        Map<Id, Project__c> oldProjectMap = new Map<Id, Project__c>();
        
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_FetchLatLong_MockSuccess());
        SBR_3_0_ProjectOperations.fetchAddressLatLong(oldProjectMap, newProjectMap);
        Test.stopTest();

        Project__c pct2 = [SELECT ID, Latitude_Longitude_Status__c FROM Project__c Where Id =: ide];
        //system.assertEquals('Success', act2.Latitude_Longitude_Status__c, 'Street Address Lat Long Status is not set to Success');
        system.assertEquals('Fetching', pct2.Latitude_Longitude_Status__c, 'Street Address Lat Long Status is not set to Success');
    }


    @isTest static void getProjectInfoTest(){

        List<Project__c> pro=SBR_3_0_TestDataFactory.createProjectsNew(1,true);
        Id ide;
        for (Project__c proj: pro){
            ide=proj.Id;
        }

        Project__c pct = [Select Id, Project_Number__c from Project__c Where Id =: ide];
        pct.Project_Number__c= 'PR-22-1111100042';
        pct.Kickoff_Date__c= Date.newInstance(2022, 12, 9);
        update pct;
        String idToSend = ide;
        SBR_3_0_ProjectOperations pclass = new SBR_3_0_ProjectOperations();
        String ProjectInfo= pclass.getProjectInfo(idToSend);
        System.assertEquals(ProjectInfo,'2022PR-22-1111100042');
    }
    
    @isTest static void getProjRelationshipsTest(){
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
        List<Project_Relationship__c> insertPR = SBR_3_0_ProjectOperations.getProjectRelationships(testProjects);
        insert insertPR;
        Test.stopTest();

        
        List<Project_Relationship__c> relationships = [SELECT Id, Project__c, Territory__c FROM Project_Relationship__c];
        System.assertEquals(testProjects.size(), relationships.size(), 'Expecting the number of Project Relationship records to match the number of Project records');
        
    }
}