/*********************************************************************************************************************
* Apex Class: SBR_3_0_API_Inspection_Appointments_Test
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose:
* - This is the Test Calss for the SBR_3_0_API_Inspection_Appointments Class
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
1.0         Mayank Jain 			2023-05-19			Initial version
*********************************************************************************************************************/
@isTest
public with sharing class SBR_3_0_API_Inspection_Appointments_Test Implements HttpCalloutMock  {


    public HTTPResponse respond(HTTPRequest request) {
        //Create a fake response
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setBody('Success');
        response.setStatusCode(200);
        return response;
    }

    @TestSetup
    static void makeData(){

        //Create Test User
        User testUser = SBR_3_0_ServiceTestDataFactory.createServiceResourceEmpNoUser(true,'1234','98765');
        User testAdminUser = SBR_3_0_ServiceTestDataFactory.createSystemAdminUser(true,'8898','987644');

        // Query for the PermissionSetId of the 'Integration_API_Access' permission set
        PermissionSet integrationPermissionSet = [SELECT Id FROM PermissionSet WHERE Name = 'Integration_API_Access'];
        PermissionSetLicense psl = [SELECT Id FROM PermissionSetLicense WHERE DeveloperName = 'SalesforceCPQ_CPQStandardPerm'];
        // Check if the user already has the 'Integration_API_Access' permission set assigned
        List<PermissionSetAssignment> permSetCheck = [SELECT Id FROM PermissionSetAssignment WHERE PermissionSetId = :integrationPermissionSet.Id AND AssigneeId = :testAdminUser.Id];

        // If the permission set is not assigned, assign it
        if (permSetCheck.isEmpty()) {
            insert new PermissionSetLicenseAssign ( AssigneeId = testAdminUser.Id, PermissionSetLicenseId = psl.Id);
            insert new PermissionSetAssignment(AssigneeId = testAdminUser.Id, PermissionSetId = integrationPermissionSet.Id);
        }
    }
    //Success Test for the Updation Of the Service Resource from Payload Json
    @isTest

    static void testSBR_3_0_CustomUpdateWorkOrder(){
        insert new Bypass_Settings__c(SetupOwnerId=UserInfo.getUserId(), Bypass_Flow__c=true);

        Credential__c cred = SBR_3_0_TestDataFactory.createCredentials(1, false)[0];
        cred.Name = 'Mule_Token_Endpoint';
        cred.Key_Id__c = 'testKey123';
        cred.Secret__c = 'secret';
        insert cred;
        //Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_Web_Order_Test());
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_CreateWorkOrderTest());
        //Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_Inspection_Appointments_Test());

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/WorkOder/ApiUpdateApointment/v1';
        req.httpMethod = 'POST';
        //String jsonString = '{ "EventType": "1","SF_PS_Company_Code__c": "01","Name": "Test Resouce","SF_PS_Hourly_Billing_Rate__c": 15.0,"SF_PS_Hourly_Internal_Rate__c": 15.0,"SF_PS_Overtime_Billing_Rate__c": 15.0,"SF_PS_Overtime_Internal_Rate__c": 15.0,"SF_PS_Labor_Type__c": "I","SF_PS_Type__c": "D","IsActive": true,"SF_PS_Branch_Loc_Num__c": "6666","SF_PS_Start_Date__c": "2023-02-22","SF_PS_RM_Created_DateTime__c": "2023-02-22T09:45:00Z","SF_PS_RM_Created_By__c": "Test User","SF_PS_RM_Update_DateTime__c": "2023-02-22T09:45:00Z","SF_PS_RM_Updated_By_User__c": "Test User","SF_PS_Mechanic_Id__c": "9999","SF_PS_Comments__c": "Yes api" }';
        String jsonString  =  '{ "EventType": "1", "Status": "Dispatched", "SF_PS_VDOS_OrderLine_External_Id__c": "vdostestclass1", "SF_PS_VDOS_Dispatch_Type__c": "AU", "SF_PS_RM_WO_Number__c": "1122900",  "SF_PS_Service_Resource__c": "98765", "SF_PS_VDOS_Stop_Id__c": "909090", "SF_PS_Company_Code__c" : "01", "SF_PS_Status_Reasons__c": "" }';
        req.requestBody = Blob.valueOf(jsonString);

        RestContext.request = req;
        RestContext.response= res;
        User testAdminUser = [Select Id,Name from User where UserName LIKE 'testAdminUser%' ];


        System.runAs(testAdminUser) {
                    insert new Bypass_Settings__c(SetupOwnerId=testAdminUser.Id, Bypass_Flow__c=true);

            Test.startTest();
            FSL.GlobalAPIS.addStatusTransition('Open', 'Scheduled');
            FSL.GlobalAPIS.addStatusTransition('Scheduled', 'Dispatched');
            //create Asset
            Asset testAsrt =  SBR_3_0_ServiceTestDataFactory.createAsset(true);

            //Create Exponce to Location
            ServiceTerritory  testE2Loc = SBR_3_0_ServiceTestDataFactory.createServiceTerritory(true);

            //Create Service Territory
            ServiceTerritory  testST = SBR_3_0_ServiceTestDataFactory.createServiceTerritory(true);



            //create work order
            workorder wo = SBR_3_0_ServiceTestDataFactory.createWorkOrder(false);
            wo.SF_PS_RM_WO_Number__c = '01-1122900';
            wo.SF_PS_Expense_To_Location__c = testE2Loc.id;
            wo.AssetId = testAsrt.id;
            wo.ServiceTerritoryId  = testST.id;
            insert wo;



            ServiceAppointment sa = SBR_3_0_ServiceTestDataFactory.createServiceAppointment(true,wo.id);

            //create service terroteritory

            //create service resource

            ServiceResource testFactorySR = SBR_3_0_ServiceTestDataFactory.create_Service_Resource(False);
            User testUser = [Select Id,Name from User where UserName LIKE 'SRTestUser%' ];
            testFactorySR.RelatedRecordId = testUser.Id;
            testFactorySR.ResourceType = 'T';
            insert testFactorySR;

            //ceate Service Territory member
            ServiceTerritoryMember testSTM =SBR_3_0_ServiceTestDataFactory.createServiceTerritoryMember(true,testFactorySR.id,testST.id);

            try {
                SBR_3_0_API_Inspection_Appointments.create();
                system.debug('test res 2nd' + res);
            }Catch (Exception e) {
                System.debug('An Error Occur | ' + e);
            }
            Test.stopTest();
        }
    }

    @isTest
    static void testSBR_3_0_CustomUpdateWorkOrdertoInRoute(){
                insert new Bypass_Settings__c(SetupOwnerId=UserInfo.getUserId(), Bypass_Flow__c=true);

        Credential__c cred = SBR_3_0_TestDataFactory.createCredentials(1, false)[0];
        cred.Name = 'Mule_Token_Endpoint';
        cred.Key_Id__c = 'testKey123';
        cred.Secret__c = 'secret';
        insert cred;
        //Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_Web_Order_Test());
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_CreateWorkOrderTest());
        //Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_Inspection_Appointments_Test());

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/WorkOder/ApiUpdateApointment/v1';
        req.httpMethod = 'POST';
        //String jsonString = '{ "EventType": "1","SF_PS_Company_Code__c": "01","Name": "Test Resouce","SF_PS_Hourly_Billing_Rate__c": 15.0,"SF_PS_Hourly_Internal_Rate__c": 15.0,"SF_PS_Overtime_Billing_Rate__c": 15.0,"SF_PS_Overtime_Internal_Rate__c": 15.0,"SF_PS_Labor_Type__c": "I","SF_PS_Type__c": "D","IsActive": true,"SF_PS_Branch_Loc_Num__c": "6666","SF_PS_Start_Date__c": "2023-02-22","SF_PS_RM_Created_DateTime__c": "2023-02-22T09:45:00Z","SF_PS_RM_Created_By__c": "Test User","SF_PS_RM_Update_DateTime__c": "2023-02-22T09:45:00Z","SF_PS_RM_Updated_By_User__c": "Test User","SF_PS_Mechanic_Id__c": "9999","SF_PS_Comments__c": "Yes api" }';
        String jsonString  =  '{ "EventType": "1", "Status": "In Route", "SF_PS_VDOS_OrderLine_External_Id__c": "vdostestclass1", "SF_PS_VDOS_Dispatch_Type__c": "AU", "SF_PS_RM_WO_Number__c": "1122900",  "SF_PS_Service_Resource__c": "98765", "SF_PS_VDOS_Stop_Id__c": "909090", "SF_PS_Company_Code__c" : "01", "SF_PS_Status_Reasons__c": "" }';
        req.requestBody = Blob.valueOf(jsonString);

        RestContext.request = req;
        RestContext.response= res;
        User testAdminUser = [Select Id,Name from User where UserName LIKE 'testAdminUser%' ];


        System.runAs(testAdminUser) {
                    insert new Bypass_Settings__c(SetupOwnerId=testAdminUser.Id, Bypass_Flow__c=true);

            Test.startTest();
            FSL.GlobalAPIS.addStatusTransition('Open', 'Scheduled');
            FSL.GlobalAPIS.addStatusTransition('Scheduled', 'Dispatched');
            FSL.GlobalAPIS.addStatusTransition('Dispatched', 'In Route');
            //create Asset
            Asset testAsrt =  SBR_3_0_ServiceTestDataFactory.createAsset(true);

            //Create Exponce to Location
            ServiceTerritory  testE2Loc = SBR_3_0_ServiceTestDataFactory.createServiceTerritory(true);

            //Create Service Territory
            ServiceTerritory  testST = SBR_3_0_ServiceTestDataFactory.createServiceTerritory(true);



            //create work order
            workorder wo = SBR_3_0_ServiceTestDataFactory.createWorkOrder(false);
            wo.SF_PS_RM_WO_Number__c = '01-1122900';
            wo.SF_PS_Expense_To_Location__c = testE2Loc.id;
            wo.AssetId = testAsrt.id;
            wo.ServiceTerritoryId  = testST.id;
            wo.status ='O';
            insert wo;



            ServiceAppointment sa = SBR_3_0_ServiceTestDataFactory.createServiceAppointment(False,wo.id);
            sa.State = 'Open';
            sa.State= '';
            insert sa;
            sa.status = 'Scheduled';
            update sa;
            sa.status = 'Dispatched';
            Update sa;
            //create service terroteritory

            //create service resource

            ServiceResource testFactorySR = SBR_3_0_ServiceTestDataFactory.create_Service_Resource(False);
            User testUser = [Select Id,Name from User where UserName LIKE 'SRTestUser%' ];
            testFactorySR.RelatedRecordId = testUser.Id;
            testFactorySR.ResourceType = 'T';
            insert testFactorySR;

            //ceate Service Territory member
            ServiceTerritoryMember testSTM =SBR_3_0_ServiceTestDataFactory.createServiceTerritoryMember(true,testFactorySR.id,testST.id);

            try {
                SBR_3_0_API_Inspection_Appointments.create();
                system.debug('test res of inroute' + res);
            }Catch (Exception e) {
                System.debug('An Error Occur in Route| ' + e);
            }
            Test.stopTest();
        }
    }

    @isTest
    static void testSBR_3_0_CustomUpdateWorkOrdertoInCompletedwithExceptions(){
                insert new Bypass_Settings__c(SetupOwnerId=UserInfo.getUserId(), Bypass_Flow__c=true);

        Credential__c cred = SBR_3_0_TestDataFactory.createCredentials(1, false)[0];
        cred.Name = 'Mule_Token_Endpoint';
        cred.Key_Id__c = 'testKey123';
        cred.Secret__c = 'secret';
        insert cred;
        //Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_Web_Order_Test());
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_CreateWorkOrderTest());
        //Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_Inspection_Appointments_Test());

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/WorkOder/ApiUpdateApointment/v1';
        req.httpMethod = 'POST';
        //String jsonString = '{ "EventType": "1","SF_PS_Company_Code__c": "01","Name": "Test Resouce","SF_PS_Hourly_Billing_Rate__c": 15.0,"SF_PS_Hourly_Internal_Rate__c": 15.0,"SF_PS_Overtime_Billing_Rate__c": 15.0,"SF_PS_Overtime_Internal_Rate__c": 15.0,"SF_PS_Labor_Type__c": "I","SF_PS_Type__c": "D","IsActive": true,"SF_PS_Branch_Loc_Num__c": "6666","SF_PS_Start_Date__c": "2023-02-22","SF_PS_RM_Created_DateTime__c": "2023-02-22T09:45:00Z","SF_PS_RM_Created_By__c": "Test User","SF_PS_RM_Update_DateTime__c": "2023-02-22T09:45:00Z","SF_PS_RM_Updated_By_User__c": "Test User","SF_PS_Mechanic_Id__c": "9999","SF_PS_Comments__c": "Yes api" }';
        String jsonString  =  '{ "EventType": "1", "Status": "Completed with Exceptions", "SF_PS_VDOS_OrderLine_External_Id__c": "vdostestclass1", "SF_PS_VDOS_Dispatch_Type__c": "AU", "SF_PS_RM_WO_Number__c": "1122900",  "SF_PS_Service_Resource__c": "98765", "SF_PS_VDOS_Stop_Id__c": "909090", "SF_PS_Company_Code__c" : "01", "SF_PS_Status_Reasons__c": "Equipment running but is damaged" }';
        req.requestBody = Blob.valueOf(jsonString);

        RestContext.request = req;
        RestContext.response= res;
        User testAdminUser = [Select Id,Name from User where UserName LIKE 'testAdminUser%' ];


        System.runAs(testAdminUser) {
                    insert new Bypass_Settings__c(SetupOwnerId=testAdminUser.Id, Bypass_Flow__c=true);

            Test.startTest();
            FSL.GlobalAPIS.addStatusTransition('Open', 'Scheduled');
            FSL.GlobalAPIS.addStatusTransition('Scheduled', 'Dispatched');
            FSL.GlobalAPIS.addStatusTransition('Dispatched', 'In Route');
            //create Asset
            Asset testAsrt =  SBR_3_0_ServiceTestDataFactory.createAsset(true);

            //Create Exponce to Location
            ServiceTerritory  testE2Loc = SBR_3_0_ServiceTestDataFactory.createServiceTerritory(true);

            //Create Service Territory
            ServiceTerritory  testST = SBR_3_0_ServiceTestDataFactory.createServiceTerritory(true);



            //create work order
            workorder wo = SBR_3_0_ServiceTestDataFactory.createWorkOrder(false);
            wo.SF_PS_RM_WO_Number__c = '01-1122900';
            wo.SF_PS_Expense_To_Location__c = testE2Loc.id;
            wo.AssetId = testAsrt.id;
            wo.ServiceTerritoryId  = testST.id;
            wo.status ='O';
            insert wo;



            ServiceAppointment sa = SBR_3_0_ServiceTestDataFactory.createServiceAppointment(False,wo.id);
            sa.State = 'Open';
            sa.State= '';
            insert sa;
            sa.status = 'Scheduled';
            update sa;
            sa.status = 'Dispatched';
            Update sa;
            //create service terroteritory

            //create service resource

            ServiceResource testFactorySR = SBR_3_0_ServiceTestDataFactory.create_Service_Resource(False);
            User testUser = [Select Id,Name from User where UserName LIKE 'SRTestUser%' ];
            testFactorySR.RelatedRecordId = testUser.Id;
            testFactorySR.ResourceType = 'T';
            insert testFactorySR;

            //ceate Service Territory member
            ServiceTerritoryMember testSTM =SBR_3_0_ServiceTestDataFactory.createServiceTerritoryMember(true,testFactorySR.id,testST.id);

            try {
                SBR_3_0_API_Inspection_Appointments.create();
                system.debug('test res of inroute' + res);
            }Catch (Exception e) {
                System.debug('An Error Occur in Route| ' + e);
            }
            Test.stopTest();
        }
    }


    @isTest
    static void testSBR_3_0_CustomUpdateWorkOrderNoWo(){
                insert new Bypass_Settings__c(SetupOwnerId=UserInfo.getUserId(), Bypass_Flow__c=true);

        Credential__c cred = SBR_3_0_TestDataFactory.createCredentials(1, false)[0];
        cred.Name = 'Mule_Token_Endpoint';
        cred.Key_Id__c = 'testKey123';
        cred.Secret__c = 'secret';
        insert cred;
        //Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_Web_Order_Test());
        //Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_CreateWorkOrderTest());
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_CreateWorkOrderTest());


        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/WorkOder/ApiUpdateApointment/v1';
        req.httpMethod = 'POST';
        //String jsonString = '{ "EventType": "1","SF_PS_Company_Code__c": "01","Name": "Test Resouce","SF_PS_Hourly_Billing_Rate__c": 15.0,"SF_PS_Hourly_Internal_Rate__c": 15.0,"SF_PS_Overtime_Billing_Rate__c": 15.0,"SF_PS_Overtime_Internal_Rate__c": 15.0,"SF_PS_Labor_Type__c": "I","SF_PS_Type__c": "D","IsActive": true,"SF_PS_Branch_Loc_Num__c": "6666","SF_PS_Start_Date__c": "2023-02-22","SF_PS_RM_Created_DateTime__c": "2023-02-22T09:45:00Z","SF_PS_RM_Created_By__c": "Test User","SF_PS_RM_Update_DateTime__c": "2023-02-22T09:45:00Z","SF_PS_RM_Updated_By_User__c": "Test User","SF_PS_Mechanic_Id__c": "9999","SF_PS_Comments__c": "Yes api" }';
        String jsonString  =  '{ "EventType": "1", "Status": "Dispatched", "SF_PS_VDOS_OrderLine_External_Id__c": "vdostestclass1", "SF_PS_VDOS_Dispatch_Type__c": "AU", "SF_PS_RM_WO_Number__c": "112233990",  "SF_PS_Service_Resource__c": "98765", "SF_PS_VDOS_Stop_Id__c": "909090", "SF_PS_Company_Code__c" : "01", "SF_PS_Status_Reasons__c": "" }';
        req.requestBody = Blob.valueOf(jsonString);

        RestContext.request = req;
        RestContext.response= res;
        User testAdminUser = [Select Id,Name from User where UserName LIKE 'testAdminUser%' ];


        System.runAs(testAdminUser) {
                    insert new Bypass_Settings__c(SetupOwnerId=testAdminUser.Id, Bypass_Flow__c=true);

            Test.startTest();
            FSL.GlobalAPIS.addStatusTransition('Open', 'Scheduled');
            FSL.GlobalAPIS.addStatusTransition('Scheduled', 'Dispatched');
            //create Asset
            Asset testAsrt =  SBR_3_0_ServiceTestDataFactory.createAsset(true);

            //Create Exponce to Location
            ServiceTerritory  testE2Loc = SBR_3_0_ServiceTestDataFactory.createServiceTerritory(true);

            //Create Service Territory
            ServiceTerritory  testST = SBR_3_0_ServiceTestDataFactory.createServiceTerritory(true);



            //create work order
            workorder wo = SBR_3_0_ServiceTestDataFactory.createWorkOrder(false);
            wo.SF_PS_RM_WO_Number__c = '1122339900';
            wo.SF_PS_Expense_To_Location__c = testE2Loc.id;
            wo.AssetId = testAsrt.id;
            wo.ServiceTerritoryId  = testST.id;
            insert wo;



            ServiceAppointment sa = SBR_3_0_ServiceTestDataFactory.createServiceAppointment(true,wo.id);

            //create service terroteritory

            //create service resource

            ServiceResource testFactorySR = SBR_3_0_ServiceTestDataFactory.create_Service_Resource(False);
            User testUser = [Select Id,Name from User where UserName LIKE 'SRTestUser%' ];
            testFactorySR.RelatedRecordId = testUser.Id;
            testFactorySR.ResourceType = 'T';
            insert testFactorySR;

            //ceate Service Territory member
            ServiceTerritoryMember testSTM =SBR_3_0_ServiceTestDataFactory.createServiceTerritoryMember(true,testFactorySR.id,testST.id);

            try {
                SBR_3_0_API_Inspection_Appointments.create();
                system.debug('test res 2nd' + res);
            }Catch (Exception e) {
                System.debug('An Error Occur | ' + e);
            }
            Test.stopTest();
        }
    }


    @isTest
    static void testSBR_3_0_CustomUpdateWorkOrderSAStatusChange(){
                insert new Bypass_Settings__c(SetupOwnerId=UserInfo.getUserId(), Bypass_Flow__c=true);

        Credential__c cred = SBR_3_0_TestDataFactory.createCredentials(1, false)[0];
        cred.Name = 'Mule_Token_Endpoint';
        cred.Key_Id__c = 'testKey123';
        cred.Secret__c = 'secret';
        insert cred;
        //Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_Web_Order_Test());
        //Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_CreateWorkOrderTest());
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_CreateWorkOrderTest());
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/WorkOder/ApiUpdateApointment/v1';
        req.httpMethod = 'POST';
        //String jsonString = '{ "EventType": "1","SF_PS_Company_Code__c": "01","Name": "Test Resouce","SF_PS_Hourly_Billing_Rate__c": 15.0,"SF_PS_Hourly_Internal_Rate__c": 15.0,"SF_PS_Overtime_Billing_Rate__c": 15.0,"SF_PS_Overtime_Internal_Rate__c": 15.0,"SF_PS_Labor_Type__c": "I","SF_PS_Type__c": "D","IsActive": true,"SF_PS_Branch_Loc_Num__c": "6666","SF_PS_Start_Date__c": "2023-02-22","SF_PS_RM_Created_DateTime__c": "2023-02-22T09:45:00Z","SF_PS_RM_Created_By__c": "Test User","SF_PS_RM_Update_DateTime__c": "2023-02-22T09:45:00Z","SF_PS_RM_Updated_By_User__c": "Test User","SF_PS_Mechanic_Id__c": "9999","SF_PS_Comments__c": "Yes api" }';
        String jsonString  =  '{ "EventType": "1", "Status": "Dispatched", "SF_PS_VDOS_OrderLine_External_Id__c": "vdostestclass1", "SF_PS_VDOS_Dispatch_Type__c": "AU", "SF_PS_RM_WO_Number__c": "1122339900",  "SF_PS_Service_Resource__c": "98765", "SF_PS_VDOS_Stop_Id__c": "909090","SF_PS_Company_Code__c" : "01", "SF_PS_Status_Reasons__c": "" }';
        req.requestBody = Blob.valueOf(jsonString);

        RestContext.request = req;
        RestContext.response= res;
        User testAdminUser = [Select Id,Name from User where UserName LIKE 'testAdminUser%' ];


        System.runAs(testAdminUser) {
                    insert new Bypass_Settings__c(SetupOwnerId=testAdminUser.Id, Bypass_Flow__c=true);

            Test.startTest();
            //FSL.GlobalAPIS.addStatusTransition('Open', 'Scheduled');
            //FSL.GlobalAPIS.addStatusTransition('Scheduled', 'Dispatched');
            //create Asset
            Asset testAsrt =  SBR_3_0_ServiceTestDataFactory.createAsset(true);

            //Create Exponce to Location
            ServiceTerritory  testE2Loc = SBR_3_0_ServiceTestDataFactory.createServiceTerritory(true);

            //Create Service Territory
            ServiceTerritory  testST = SBR_3_0_ServiceTestDataFactory.createServiceTerritory(true);



            //create work order
            workorder wo = SBR_3_0_ServiceTestDataFactory.createWorkOrder(false);
            wo.SF_PS_RM_WO_Number__c = '01-1122900';
            wo.SF_PS_Expense_To_Location__c = testE2Loc.id;
            wo.AssetId = testAsrt.id;
            wo.ServiceTerritoryId  = testST.id;
            insert wo;



            ServiceAppointment sa = SBR_3_0_ServiceTestDataFactory.createServiceAppointment(true,wo.id);

            //create service terroteritory

            //create service resource

            ServiceResource testFactorySR = SBR_3_0_ServiceTestDataFactory.create_Service_Resource(False);
            User testUser = [Select Id,Name from User where UserName LIKE 'SRTestUser%' ];
            testFactorySR.RelatedRecordId = testUser.Id;
            testFactorySR.ResourceType = 'T';
            insert testFactorySR;

            //ceate Service Territory member
            ServiceTerritoryMember testSTM =SBR_3_0_ServiceTestDataFactory.createServiceTerritoryMember(true,testFactorySR.id,testST.id);

            try {
                SBR_3_0_API_Inspection_Appointments.create();
                system.debug('test res 2nd' + res);
            }Catch (Exception e) {
                System.debug('An Error Occur | ' + e);
            }
            Test.stopTest();
        }
    }

    @isTest
    static void testSBR_3_0_CustomUpdateWorkOrderWrongJson(){
                insert new Bypass_Settings__c(SetupOwnerId=UserInfo.getUserId(), Bypass_Flow__c=true);

        Credential__c cred = SBR_3_0_TestDataFactory.createCredentials(1, false)[0];
        cred.Name = 'Mule_Token_Endpoint';
        cred.Key_Id__c = 'testKey123';
        cred.Secret__c = 'secret';
        insert cred;
        //Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_Web_Order_Test());
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_CreateWorkOrderTest());
        //Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_Inspection_Appointments_Test());

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/WorkOder/ApiUpdateApointment/v1';
        req.httpMethod = 'POST';
        //String jsonString = '{ "EventType": "1","SF_PS_Company_Code__c": "01","Name": "Test Resouce","SF_PS_Hourly_Billing_Rate__c": 15.0,"SF_PS_Hourly_Internal_Rate__c": 15.0,"SF_PS_Overtime_Billing_Rate__c": 15.0,"SF_PS_Overtime_Internal_Rate__c": 15.0,"SF_PS_Labor_Type__c": "I","SF_PS_Type__c": "D","IsActive": true,"SF_PS_Branch_Loc_Num__c": "6666","SF_PS_Start_Date__c": "2023-02-22","SF_PS_RM_Created_DateTime__c": "2023-02-22T09:45:00Z","SF_PS_RM_Created_By__c": "Test User","SF_PS_RM_Update_DateTime__c": "2023-02-22T09:45:00Z","SF_PS_RM_Updated_By_User__c": "Test User","SF_PS_Mechanic_Id__c": "9999","SF_PS_Comments__c": "Yes api" }';
        String jsonString  =  '{ "EventType": "1", "Status": "Dispatched", "SF_PS_VDOS_OrderLine_External_Id__c": "vdostestclass1", "SF_PS_VDOS_Dispatch_Type__c": "AU", "SF_PS_RM_WO_Number__c": "1122900",  "SF_PS_Service_Resource__c": "98765", "SF_PS_VDOS_Stop_Id__c": "909090", "SF_PS_Company_Code__c" : "01", "SF_PS_Status_Reasons__c": "" ,"SF_PS_Is_Submitted__c" : True }';
        req.requestBody = Blob.valueOf(jsonString);

        RestContext.request = req;
        RestContext.response= res;
        User testAdminUser = [Select Id,Name from User where UserName LIKE 'testAdminUser%' ];


        System.runAs(testAdminUser) {
                    insert new Bypass_Settings__c(SetupOwnerId=testAdminUser.Id, Bypass_Flow__c=true);

            Test.startTest();
            FSL.GlobalAPIS.addStatusTransition('Open', 'Scheduled');
            FSL.GlobalAPIS.addStatusTransition('Scheduled', 'Dispatched');
            //create Asset
            Asset testAsrt =  SBR_3_0_ServiceTestDataFactory.createAsset(true);

            //Create Exponce to Location
            ServiceTerritory  testE2Loc = SBR_3_0_ServiceTestDataFactory.createServiceTerritory(true);

            //Create Service Territory
            ServiceTerritory  testST = SBR_3_0_ServiceTestDataFactory.createServiceTerritory(true);



            //create work order
            workorder wo = SBR_3_0_ServiceTestDataFactory.createWorkOrder(false);
            wo.SF_PS_RM_WO_Number__c = '01-1122900';
            wo.SF_PS_Expense_To_Location__c = testE2Loc.id;
            wo.AssetId = testAsrt.id;
            wo.ServiceTerritoryId  = testST.id;
            insert wo;



            ServiceAppointment sa = SBR_3_0_ServiceTestDataFactory.createServiceAppointment(true,wo.id);

            //create service terroteritory

            //create service resource

            ServiceResource testFactorySR = SBR_3_0_ServiceTestDataFactory.create_Service_Resource(False);
            User testUser = [Select Id,Name from User where UserName LIKE 'SRTestUser%' ];
            testFactorySR.RelatedRecordId = testUser.Id;
            testFactorySR.ResourceType = 'T';
            insert testFactorySR;

            //ceate Service Territory member
            ServiceTerritoryMember testSTM =SBR_3_0_ServiceTestDataFactory.createServiceTerritoryMember(true,testFactorySR.id,testST.id);

            try {
                SBR_3_0_API_Inspection_Appointments.create();
                system.debug('test res 2nd' + res);
            }Catch (Exception e) {
                System.debug('An Error Occur | ' + e);
            }
            Test.stopTest();
        }
    }

    @isTest
    static void testSBR_3_0_CustomUpdateWorkOrderRMNull(){
                insert new Bypass_Settings__c(SetupOwnerId=UserInfo.getUserId(), Bypass_Flow__c=true);

        Credential__c cred = SBR_3_0_TestDataFactory.createCredentials(1, false)[0];
        cred.Name = 'Mule_Token_Endpoint';
        cred.Key_Id__c = 'testKey123';
        cred.Secret__c = 'secret';
        insert cred;
        //Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_Web_Order_Test());
        //Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_CreateWorkOrderTest());
                Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_CreateWorkOrderTest());

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/WorkOder/ApiUpdateApointment/v1';
        req.httpMethod = 'POST';
        //String jsonString = '{ "EventType": "1","SF_PS_Company_Code__c": "01","Name": "Test Resouce","SF_PS_Hourly_Billing_Rate__c": 15.0,"SF_PS_Hourly_Internal_Rate__c": 15.0,"SF_PS_Overtime_Billing_Rate__c": 15.0,"SF_PS_Overtime_Internal_Rate__c": 15.0,"SF_PS_Labor_Type__c": "I","SF_PS_Type__c": "D","IsActive": true,"SF_PS_Branch_Loc_Num__c": "6666","SF_PS_Start_Date__c": "2023-02-22","SF_PS_RM_Created_DateTime__c": "2023-02-22T09:45:00Z","SF_PS_RM_Created_By__c": "Test User","SF_PS_RM_Update_DateTime__c": "2023-02-22T09:45:00Z","SF_PS_RM_Updated_By_User__c": "Test User","SF_PS_Mechanic_Id__c": "9999","SF_PS_Comments__c": "Yes api" }';
        String jsonString  =  '{ "EventType": "1", "Status": "Dispatched", "SF_PS_VDOS_OrderLine_External_Id__c": "vdostestclass1", "SF_PS_VDOS_Dispatch_Type__c": "AU", "SF_PS_RM_WO_Number__c": "",  "SF_PS_Service_Resource__c": "98765", "SF_PS_VDOS_Stop_Id__c": "909090", "SF_PS_Status_Reasons__c": "" }';
        req.requestBody = Blob.valueOf(jsonString);

        RestContext.request = req;
        RestContext.response= res;
        User testAdminUser = [Select Id,Name from User where UserName LIKE 'testAdminUser%' ];


        System.runAs(testAdminUser) {
                    insert new Bypass_Settings__c(SetupOwnerId=UserInfo.getUserId(), Bypass_Flow__c=true);

            Test.startTest();
            FSL.GlobalAPIS.addStatusTransition('Open', 'Scheduled');
            FSL.GlobalAPIS.addStatusTransition('Scheduled', 'Dispatched');
            //create Asset
            Asset testAsrt =  SBR_3_0_ServiceTestDataFactory.createAsset(true);

            //Create Exponce to Location
            ServiceTerritory  testE2Loc = SBR_3_0_ServiceTestDataFactory.createServiceTerritory(true);

            //Create Service Territory
            ServiceTerritory  testST = SBR_3_0_ServiceTestDataFactory.createServiceTerritory(true);



            //create work order
            workorder wo = SBR_3_0_ServiceTestDataFactory.createWorkOrder(false);
            wo.SF_PS_RM_WO_Number__c = '1122339900';
            wo.SF_PS_Expense_To_Location__c = testE2Loc.id;
            wo.AssetId = testAsrt.id;
            wo.ServiceTerritoryId  = testST.id;
            insert wo;



            ServiceAppointment sa = SBR_3_0_ServiceTestDataFactory.createServiceAppointment(true,wo.id);

            //create service terroteritory

            //create service resource

            ServiceResource testFactorySR = SBR_3_0_ServiceTestDataFactory.create_Service_Resource(False);
            User testUser = [Select Id,Name from User where UserName LIKE 'SRTestUser%' ];
            testFactorySR.RelatedRecordId = testUser.Id;
            testFactorySR.ResourceType = 'T';
            insert testFactorySR;

            //ceate Service Territory member
            ServiceTerritoryMember testSTM =SBR_3_0_ServiceTestDataFactory.createServiceTerritoryMember(true,testFactorySR.id,testST.id);

            try {
                SBR_3_0_API_Inspection_Appointments.create();
                system.debug('test res 2nd' + res);
            }Catch (Exception e) {
                System.debug('An Error Occur | ' + e);
            }
            Test.stopTest();
        }
    }

    @isTest
    static void testSBR_3_0_CustomUpdateWorkOrderSRNotFound(){
                insert new Bypass_Settings__c(SetupOwnerId=UserInfo.getUserId(), Bypass_Flow__c=true);

        Credential__c cred = SBR_3_0_TestDataFactory.createCredentials(1, false)[0];
        cred.Name = 'Mule_Token_Endpoint';
        cred.Key_Id__c = 'testKey123';
        cred.Secret__c = 'secret';
        insert cred;
        //Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_Web_Order_Test());
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_CreateWorkOrderTest());
        //Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_Inspection_Appointments_Test());

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/WorkOder/ApiUpdateApointment/v1';
        req.httpMethod = 'POST';
        //String jsonString = '{ "EventType": "1","SF_PS_Company_Code__c": "01","Name": "Test Resouce","SF_PS_Hourly_Billing_Rate__c": 15.0,"SF_PS_Hourly_Internal_Rate__c": 15.0,"SF_PS_Overtime_Billing_Rate__c": 15.0,"SF_PS_Overtime_Internal_Rate__c": 15.0,"SF_PS_Labor_Type__c": "I","SF_PS_Type__c": "D","IsActive": true,"SF_PS_Branch_Loc_Num__c": "6666","SF_PS_Start_Date__c": "2023-02-22","SF_PS_RM_Created_DateTime__c": "2023-02-22T09:45:00Z","SF_PS_RM_Created_By__c": "Test User","SF_PS_RM_Update_DateTime__c": "2023-02-22T09:45:00Z","SF_PS_RM_Updated_By_User__c": "Test User","SF_PS_Mechanic_Id__c": "9999","SF_PS_Comments__c": "Yes api" }';
        String jsonString  =  '{ "EventType": "1", "Status": "Dispatched", "SF_PS_VDOS_OrderLine_External_Id__c": "vdostestclass1", "SF_PS_VDOS_Dispatch_Type__c": "AU", "SF_PS_RM_WO_Number__c": "1122900",  "SF_PS_Service_Resource__c": "98767655", "SF_PS_VDOS_Stop_Id__c": "909090", "SF_PS_Company_Code__c" : "01", "SF_PS_Status_Reasons__c": "" }';
        req.requestBody = Blob.valueOf(jsonString);

        RestContext.request = req;
        RestContext.response= res;
        User testAdminUser = [Select Id,Name from User where UserName LIKE 'testAdminUser%' ];


        System.runAs(testAdminUser) {
                    insert new Bypass_Settings__c(SetupOwnerId=UserInfo.getUserId(), Bypass_Flow__c=true);

            Test.startTest();
            FSL.GlobalAPIS.addStatusTransition('Open', 'Scheduled');
            FSL.GlobalAPIS.addStatusTransition('Scheduled', 'Dispatched');
            //create Asset
            Asset testAsrt =  SBR_3_0_ServiceTestDataFactory.createAsset(true);

            //Create Exponce to Location
            ServiceTerritory  testE2Loc = SBR_3_0_ServiceTestDataFactory.createServiceTerritory(true);

            //Create Service Territory
            ServiceTerritory  testST = SBR_3_0_ServiceTestDataFactory.createServiceTerritory(true);



            //create work order
            workorder wo = SBR_3_0_ServiceTestDataFactory.createWorkOrder(false);
            wo.SF_PS_RM_WO_Number__c = '01-1122900';
            wo.SF_PS_Expense_To_Location__c = testE2Loc.id;
            wo.AssetId = testAsrt.id;
            wo.ServiceTerritoryId  = testST.id;
            insert wo;



            ServiceAppointment sa = SBR_3_0_ServiceTestDataFactory.createServiceAppointment(true,wo.id);

            //create service terroteritory

            //create service resource

            ServiceResource testFactorySR = SBR_3_0_ServiceTestDataFactory.create_Service_Resource(False);
            User testUser = [Select Id,Name from User where UserName LIKE 'SRTestUser%' ];
            testFactorySR.RelatedRecordId = testUser.Id;
            testFactorySR.ResourceType = 'T';
            insert testFactorySR;

            //ceate Service Territory member
            ServiceTerritoryMember testSTM =SBR_3_0_ServiceTestDataFactory.createServiceTerritoryMember(true,testFactorySR.id,testST.id);

            try {
                SBR_3_0_API_Inspection_Appointments.create();
                system.debug('test res 2nd' + res);
            }Catch (Exception e) {
                System.debug('An Error Occur | ' + e);
            }
            Test.stopTest();
        }
    }


    // To get code coverage
     @isTest
    static void testSBR_3_0_CustomUpdateWorderTest(){


        insert new Bypass_Settings__c(SetupOwnerId=UserInfo.getUserId(), Bypass_Flow__c=true);

        Credential__c cred = SBR_3_0_TestDataFactory.createCredentials(1, false)[0];
        cred.Name = 'Mule_Token_Endpoint';
        cred.Key_Id__c = 'testKey123';
        cred.Secret__c = 'secret';
        insert cred;
        //Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_Web_Order_Test());
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_CreateWorkOrderTest());
        //Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_Inspection_Appointments_Test());

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/WorkOder/ApiUpdateApointment/v1';
        req.httpMethod = 'POST';
        //String jsonString = '{ "EventType": "1","SF_PS_Company_Code__c": "01","Name": "Test Resouce","SF_PS_Hourly_Billing_Rate__c": 15.0,"SF_PS_Hourly_Internal_Rate__c": 15.0,"SF_PS_Overtime_Billing_Rate__c": 15.0,"SF_PS_Overtime_Internal_Rate__c": 15.0,"SF_PS_Labor_Type__c": "I","SF_PS_Type__c": "D","IsActive": true,"SF_PS_Branch_Loc_Num__c": "6666","SF_PS_Start_Date__c": "2023-02-22","SF_PS_RM_Created_DateTime__c": "2023-02-22T09:45:00Z","SF_PS_RM_Created_By__c": "Test User","SF_PS_RM_Update_DateTime__c": "2023-02-22T09:45:00Z","SF_PS_RM_Updated_By_User__c": "Test User","SF_PS_Mechanic_Id__c": "9999","SF_PS_Comments__c": "Yes api" }';
        String jsonString  =  '{ "EventType": "1", "Status": "Dispatched", "SF_PS_VDOS_OrderLine_External_Id__c": "vdostestclass1", "SF_PS_VDOS_Dispatch_Type__c": "AU", "SF_PS_RM_WO_Number__c": "1122900",  "SF_PS_Service_Resource__c": "98765", "SF_PS_VDOS_Stop_Id__c": "909090", "SF_PS_Company_Code__c" : "01", "SF_PS_Status_Reasons__c": "" }';
        req.requestBody = Blob.valueOf(jsonString);

        RestContext.request = req;
        RestContext.response= res;
        User testAdminUser = [Select Id,Name from User where UserName LIKE 'testAdminUser%' ];


        System.runAs(testAdminUser) {
                    insert new Bypass_Settings__c(SetupOwnerId=UserInfo.getUserId(), Bypass_Flow__c=true);

            Test.startTest();
            FSL.GlobalAPIS.addStatusTransition('Open', 'Scheduled');
            FSL.GlobalAPIS.addStatusTransition('Scheduled', 'Dispatched');
            //create Asset
            Asset testAsrt =  SBR_3_0_ServiceTestDataFactory.createAsset(true);

            //Create Exponce to Location
            ServiceTerritory  testE2Loc = SBR_3_0_ServiceTestDataFactory.createServiceTerritory(true);

            //Create Service Territory
            ServiceTerritory  testST = SBR_3_0_ServiceTestDataFactory.createServiceTerritory(true);

                  ServiceResource testFactorySR = SBR_3_0_ServiceTestDataFactory.create_Service_Resource(False);
            User testUser = [Select Id,Name from User where UserName LIKE 'SRTestUser%' ];
            testFactorySR.RelatedRecordId = testUser.Id;
            testFactorySR.ResourceType = 'T';
            insert testFactorySR;

            //ceate Service Territory member
            ServiceTerritoryMember testSTM =SBR_3_0_ServiceTestDataFactory.createServiceTerritoryMember(false,testFactorySR.id,testST.id);
			            testStm.EffectiveStartDate = system.now()-3;
            insert testStm;

            //create work order
            workorder wo = SBR_3_0_ServiceTestDataFactory.createWorkOrder(false);
            wo.SF_PS_RM_WO_Number__c = '01-1122900';
            wo.SF_PS_Expense_To_Location__c = testE2Loc.id;
            wo.AssetId = testAsrt.id;
            wo.ServiceTerritoryId  = testST.id;
            wo.status='';
            wo.SF_PS_Company_Code__c='01';
            insert wo;



              ServiceAppointment sa = SBR_3_0_ServiceTestDataFactory.createServiceAppointment(true,wo.id);
            AssignedResource ar  = new AssignedResource(ServiceAppointmentId=sa.Id,ServiceResourceId=testFactorySR.Id);
        insert ar;

            //create service terroteritory

            //create service resource


            try {
                SBR_3_0_API_Inspection_Appointments.create();
                system.debug('test res 2nd' + res);
            }Catch (Exception e) {
                System.debug('An Error Occur | ' + e);
            }
            Test.stopTest();



            SBR_3_0_CustomUpdateWorkOrder upObj = new SBR_3_0_CustomUpdateWorkOrder(jsonString);
            upObj.UpdateWorkOrderwithoutStatus(wo);
          upObj.UpdateServiceAppointmentStatus(sa,'Dispatched');

        }
    }

      // Success Test for the Updation of the Service Resource from Payload JSON
      @isTest
      static void testSBR_3_0_CustomUpdateWorkOrderFail() {
          // Insert Bypass Settings
          insert new Bypass_Settings__c(SetupOwnerId = UserInfo.getUserId(), Bypass_Flow__c = true);

          // Create and insert test credentials
          Credential__c cred = SBR_3_0_TestDataFactory.createCredentials(1, false)[0];
          cred.Name = 'Mule_Token_Endpoint';
          cred.Key_Id__c = 'testKey123';
          cred.Secret__c = 'secret';
          insert cred;

          // Set mock HTTP callout
          Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_CreateWorkOrderTest());

          // Create a test REST request
          RestRequest req = new RestRequest();
          RestResponse res = new RestResponse();
          req.requestURI = '/WorkOder/ApiUpdateApointment/v1';
          req.httpMethod = 'POST';
          String jsonString  = '{ "EventType": "1", "Status": "Dispatched", "SF_PS_VDOS_OrderLine_External_Id__c": "vdostestclass1", "SF_PS_VDOS_Dispatch_Type__c": "AU", "SF_PS_RM_WO_Number__c": "1122900",  "SF_PS_Service_Resource__c": "98765", "SF_PS_VDOS_Stop_Id__c": "909090", "SF_PS_Company_Code__c" : "01", "SF_PS_Status_Reasons__c": "" }';
          req.requestBody = Blob.valueOf(jsonString);

          RestContext.request = req;
          RestContext.response = res;

          // Query the test admin user
          User testAdminUser = [SELECT Id, Name FROM User WHERE UserName LIKE 'testAdminUser%'];

          System.runAs(testAdminUser) {
              insert new Bypass_Settings__c(SetupOwnerId = testAdminUser.Id, Bypass_Flow__c = true);

              Test.startTest();

              // Setup global APIs for status transition
              FSL.GlobalAPIS.addStatusTransition('Open', 'Scheduled');
              FSL.GlobalAPIS.addStatusTransition('Scheduled', 'Dispatched');

              // Create test data
              Asset testAsrt = SBR_3_0_ServiceTestDataFactory.createAsset(true);
              ServiceTerritory testE2Loc = SBR_3_0_ServiceTestDataFactory.createServiceTerritory(true);
              ServiceTerritory testST = SBR_3_0_ServiceTestDataFactory.createServiceTerritory(true);

              WorkOrder wo = SBR_3_0_ServiceTestDataFactory.createWorkOrder(false);
              wo.SF_PS_RM_WO_Number__c = '01-1122900';
              wo.SF_PS_Expense_To_Location__c = testE2Loc.Id;
              wo.AssetId = testAsrt.Id;
              wo.ServiceTerritoryId = testST.Id;
              insert wo;

              ServiceAppointment sa = SBR_3_0_ServiceTestDataFactory.createServiceAppointment(true, wo.Id);

              ServiceResource testFactorySR = SBR_3_0_ServiceTestDataFactory.create_Service_Resource(false);
              User testUser = [SELECT Id, Name FROM User WHERE UserName LIKE 'SRTestUser%'];
              testFactorySR.RelatedRecordId = testUser.Id;
              testFactorySR.ResourceType = 'T';
              insert testFactorySR;

              ServiceTerritoryMember testSTM = SBR_3_0_ServiceTestDataFactory.createServiceTerritoryMember(true, testFactorySR.Id, testST.Id);

              // Force an exception to cover the catch block
              try {
                  // Delete the ServiceAppointment to force the query to fail
                  delete sa;

                  SBR_3_0_CustomUpdateWorkOrder handler = new SBR_3_0_CustomUpdateWorkOrder(jsonString);
                  ServiceAppointment result = handler.getserviceAppointment(wo);
                  System.debug('Test Result: ' + result);
                  // Assert that the result is null to confirm the catch block was executed
                  System.assert(result == null, 'Expected the result to be null due to exception');
              } catch (Exception e) {
                  System.debug('An Error Occurred: ' + e);
              }

              Test.stopTest();
          }
      }

      @isTest
      static void testRelServiceResource_Exception() {
            // Insert Bypass Settings
            insert new Bypass_Settings__c(SetupOwnerId = UserInfo.getUserId(), Bypass_Flow__c = true);

            // Create and insert test credentials
            Credential__c cred = SBR_3_0_TestDataFactory.createCredentials(1, false)[0];
            cred.Name = 'Mule_Token_Endpoint';
            cred.Key_Id__c = 'testKey123';
            cred.Secret__c = 'secret';
            insert cred;

            // Set mock HTTP callout
            Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_CreateWorkOrderTest());

            // Create a test REST request
            RestRequest req = new RestRequest();
            RestResponse res = new RestResponse();
            req.requestURI = '/WorkOder/ApiUpdateApointment/v1';
            req.httpMethod = 'POST';
            String jsonString  = '{ "EventType": "1", "Status": "Dispatched", "SF_PS_VDOS_OrderLine_External_Id__c": "vdostestclass1", "SF_PS_VDOS_Dispatch_Type__c": "AU", "SF_PS_RM_WO_Number__c": "1122900",  "SF_PS_Service_Resource__c": "999999999", "SF_PS_VDOS_Stop_Id__c": "909090", "SF_PS_Company_Code__c" : "01", "SF_PS_Status_Reasons__c": "" }';
            req.requestBody = Blob.valueOf(jsonString);

            RestContext.request = req;
            RestContext.response = res;

            // Query the test admin user
            User testAdminUser = [SELECT Id, Name FROM User WHERE UserName LIKE 'testAdminUser%'];

            System.runAs(testAdminUser) {
                insert new Bypass_Settings__c(SetupOwnerId = testAdminUser.Id, Bypass_Flow__c = true);

                Test.startTest();

                // Setup global APIs for status transition
                FSL.GlobalAPIS.addStatusTransition('Open', 'Scheduled');
                FSL.GlobalAPIS.addStatusTransition('Scheduled', 'Dispatched');

                // Create test data
                Asset testAsrt = SBR_3_0_ServiceTestDataFactory.createAsset(true);
                ServiceTerritory testE2Loc = SBR_3_0_ServiceTestDataFactory.createServiceTerritory(true);
                ServiceTerritory testST = SBR_3_0_ServiceTestDataFactory.createServiceTerritory(true);

                WorkOrder wo = SBR_3_0_ServiceTestDataFactory.createWorkOrder(false);
                wo.SF_PS_RM_WO_Number__c = '01-1122900';
                wo.SF_PS_Expense_To_Location__c = testE2Loc.Id;
                wo.AssetId = testAsrt.Id;
                wo.ServiceTerritoryId = testST.Id;
                insert wo;

                ServiceAppointment sa = SBR_3_0_ServiceTestDataFactory.createServiceAppointment(true, wo.Id);

                try {
                    SBR_3_0_API_Inspection_Appointments.create();
                    system.debug('test res 2nd' + res);
                }Catch (Exception e) {
                    System.debug('An Error Occur | ' + e);
                }
                Test.stopTest();
            }
      }
    
    @isTest
	static void testExceptionLogMethod()
    {
        try
        {
            IllegalArgumentException error = new IllegalArgumentException();
            error.setMessage('Invalid Argument value');
            throw error;
        }
        catch(Exception ex)
        {
            SBR_3_0_API_Inspection_Appointments.logException(ex);
        }
    }
}