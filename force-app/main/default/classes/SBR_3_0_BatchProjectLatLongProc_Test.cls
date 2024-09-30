@isTest
public with sharing class SBR_3_0_BatchProjectLatLongProc_Test Implements HttpCalloutMock{
    static Boolean SUCCESSTEST = true;
    @TestSetup
    static void makeData(){       
        Credential__c cred = SBR_3_0_TestDataFactory.createCredentials(1, false)[0];
        cred.Name = 'Mule_Token_Endpoint';
        cred.Key_Id__c = 'testKey123';
        cred.Secret__c = 'secret';
        insert cred;
    }

    public HTTPResponse respond(HTTPRequest req) {
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type',SBR_3_0_Constants.APP_JSON);
        if(req.getEndpoint().endsWithIgnoreCase('token')){
            res.setBody('{"access_token":"test"}');
        }else if (SUCCESSTEST) {
            res.setBody('{"message": "Custom Error Message", "data": {"geoInfo": {"latitude": 38.82717,"longitude": -77.439927}}}');
            //res.setBody('{ "message": "Custom Error Message", "data": { "results": [ { "addressComponents": [ { "longName": "6365", "shortName": "6365", "types": [ "street_number" ] }, { "longName": "Multiplex Drive", "shortName": "Multiplex Dr", "types": [ "route" ] }, { "longName": "Centreville", "shortName": "Centreville", "types": [ "locality", "political" ] }, { "longName": "Fairfax County", "shortName": "Fairfax County", "types": [ "administrative_area_level_2", "political" ] }, { "longName": "Virginia", "shortName": "VA", "types": [ "administrative_area_level_1", "political" ] }, { "longName": "United States", "shortName": "US", "types": [ "country", "political" ] }, { "longName": "20121", "shortName": "20121", "types": [ "postal_code" ] } ], "formattedAddress": "6365 Multiplex Dr, Centreville, VA 20121, USA", "geometry": { "location": { "latitude": 38.82717, "longitude": -77.439927 }, "locationType": "ROOFTOP", "viewport": { "northeast": { "latitude": 38.8286634802915, "longitude": -77.43860981970849 }, "southwest": { "latitude": 38.8259655197085, "longitude": -77.44130778029151 } } }, "placeId": "ChIJC0C2DMJEtokR4Kx6xT21ctk", "types": [ "street_address" ] } ] } }');
        } else {
            res.setBody('{ "data": {} }');
        }
        res.setStatusCode(200);
        return res;
    }

    @isTest
    static void testBatchProjectLatLongProcessor_Success(){
        SUCCESSTEST = true;
        Project__c testProject = new Project__c();
        testProject.City__c = 'Centreville';
        testProject.Zip_Code__c = '20121';
        testProject.Country__c = 'US';
        testProject.Street__c = '6365 Multiplex Dr';
        testProject.State__c = 'VA';
        testProject.Project_Name__c = 'Test Project';
        insert testProject;

        List<Project__c> projects = [SELECT Id, Latitude_Longitude_Status__c
                                        FROM Project__c];

        Set<Id> projectIds = new Set<Id>();

        for (Project__c p : projects) {
            projectIds.add(p.Id);
        }

        Test.setMock(HttpCalloutMock.class, new SBR_3_0_BatchProjectLatLongProc_Test());
        Test.startTest();
        SBR_3_0_BatchProjectLatLongProcessor obj = new SBR_3_0_BatchProjectLatLongProcessor(projectIds, 100);
        Database.executeBatch(obj, 200);
        Test.stopTest();

        List<Project__c> updatedProjects = [SELECT Id, Latitude_Longitude_Status__c, Latitude_Longitude_error__c
                                                FROM Project__c];
        System.assertEquals('Success', updatedProjects[0].Latitude_Longitude_Status__c, 
                                'Status should be changed to Success');
    }

    @isTest
    static void testBatchProjectLatLongProcessor_Recursive(){
        SUCCESSTEST = true;
        Project__c testProject = new Project__c();
        testProject.City__c = 'Centreville';
        testProject.Zip_Code__c = '20121';
        testProject.Country__c = 'US';
        testProject.Street__c = '6365 Multiplex Dr';
        testProject.State__c = 'VA';
        testProject.Project_Name__c = 'Test Project';
        insert testProject;

        List<Project__c> projects = [SELECT Id, Latitude_Longitude_Status__c
                                        FROM Project__c];

        Set<Id> projectIds = new Set<Id>();

        for (Project__c p : projects) {
            projectIds.add(p.Id);
        }

        Test.setMock(HttpCalloutMock.class, new SBR_3_0_BatchProjectLatLongProc_Test());
        Test.startTest();
        SBR_3_0_BatchProjectLatLongProcessor obj = new SBR_3_0_BatchProjectLatLongProcessor(projectIds, 98);
        Database.executeBatch(obj, 200);
        Test.stopTest();

        List<Project__c> updatedProjects = [SELECT Id, Latitude_Longitude_Status__c, Latitude_Longitude_error__c
                                                FROM Project__c];
        System.assertEquals('Success', updatedProjects[0].Latitude_Longitude_Status__c, 
                                'Status should be changed to Success');
    }

    // @isTest
    // static void testBatchProjectLatLongProcessor_Fail_CustomErrorMessage(){
    //     SUCCESSTEST = true;
    //     Project__c testProject = new Project__c();
    //     testProject.Name = 'Test1';
    //     testProject.City__c = 'Centreville2';
    //     testProject.Zip_Code__c = '20121';
    //     testProject.Country__c = 'United States';
    //     testProject.Street__c = '6365 Multiplex Dr';
    //     testProject.State__c = 'VA';
    //     insert testProject;

    //     List<Project__c> projects = [SELECT Id, Latitude_Longitude_Status__c
    //                                     FROM Project__c];

    //     Set<Id> projectIds = new Set<Id>();

    //     for (Project__c p : projects) {
    //         projectIds.add(p.Id);
    //     }

    //     Test.setMock(HttpCalloutMock.class, new SBR_3_0_BatchProjectLatLongProc_Test());
    //     Test.startTest();
    //     SBR_3_0_BatchProjectLatLongProcessor obj = new SBR_3_0_BatchProjectLatLongProcessor(projectIds);
    //     Database.executeBatch(obj);
    //     Test.stopTest();

    //     List<Project__c> updatedProjects = [SELECT Id, Latitude_Longitude_Status__c, Latitude_Longitude_error__c
    //                                             FROM Project__c];
    //     System.assertEquals('Error', updatedProjects[0].Latitude_Longitude_Status__c, 
    //                             'Status should be changed to Error');
    //     System.assertEquals('Custom Error Message', updatedProjects[0].Latitude_Longitude_error__c, 
    //                             'Message should be from response body');
    // }

    @isTest
    static void testBatchProjectLatLongProcessor_Fail_DefaultErrorMessage(){
        SBR_3_0_TestDataFactory.createProjects(1, true);
        SUCCESSTEST = false;

        List<Project__c> projects = [SELECT Id, Latitude_Longitude_Status__c
                                        FROM Project__c];

        Set<Id> projectIds = new Set<Id>();

        for (Project__c p : projects) {
            projectIds.add(p.Id);
        }

        Test.setMock(HttpCalloutMock.class, new SBR_3_0_BatchProjectLatLongProc_Test());
        Test.startTest();
        SBR_3_0_BatchProjectLatLongProcessor obj = new SBR_3_0_BatchProjectLatLongProcessor(projectIds, 100);
        Database.executeBatch(obj, 200);
        Test.stopTest();

        List<Project__c> updatedProjects = [SELECT Id, Latitude_Longitude_Status__c, Latitude_Longitude_error__c
                                                FROM Project__c];
        System.assertEquals('Error', updatedProjects[0].Latitude_Longitude_Status__c, 
                                'Status should be changed to Error');
        System.assertEquals('Latitude, Longitude not captured; please contact support.', updatedProjects[0].Latitude_Longitude_error__c, 
                                'Message should be from default string');
    }
}