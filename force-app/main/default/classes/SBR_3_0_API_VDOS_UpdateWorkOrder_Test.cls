/*********************************************************************************************************************
* Apex Class: SBR_3_0_API_VDOS_UpdateWorkOrder_Test
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Test Class for SBR_3_0_API_VDOS_UpdateWorkOrder
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Shubham Tunkikar        2023-10-31          Initial version
    2.0         Piyush Jindal           2023-12-01          Code Cleanup
    3.0         Piyush Jindal           2023-12-02          Added a test method as changes were made in the SBR_3_0_API_VDOS_UpdateWorkOrder
    4.0         Piyush Jindal           2023-12-05          Added a test method as changes were made in the SBR_3_0_API_VDOS_UpdateWorkOrder
*********************************************************************************************************************/
@isTest()
public with sharing class SBR_3_0_API_VDOS_UpdateWorkOrder_Test {

    @testSetup
    public static void testSetupMethod() {
        User serviceResourceUser =  SBR_3_0_ServiceTestDataFactory.createServiceResourceUser(true,'1234','78923');
        User salesRepUser = SBR_3_0_ServiceTestDataFactory.createSalesRepUser(true,'111222');
        User ownerUse = SBR_3_0_ServiceTestDataFactory.createOwnerUser(true, '1234','7777');
    }

    @isTest
    static void workOrderVDOSCalloutTest() {
        insert new Bypass_Settings__c(SetupOwnerId=UserInfo.getUserId(), Bypass_Flow__c=true);
        Credential__c cred = SBR_3_0_TestDataFactory.createCredentials(1, false)[0];
        cred.Name = 'Mule_Token_Endpoint';
        cred.Key_Id__c = 'testKey123';
        cred.Secret__c = 'secret';
        insert cred;

        //Create Service Resource
        ServiceResource testSR = SBR_3_0_ServiceTestDataFactory.create_Service_Resource(False);
        User testUser = [SELECT Id, Name
                        FROM User
                        WHERE UserName LIKE 'SRTestUser%' LIMIT 1];
        testSR.ResourceType = 'T';
        testSR.RelatedRecordId = testUser.Id;
        insert testSR;

        //Create Asset
        Asset testAsrt =  SBR_3_0_ServiceTestDataFactory.createAsset(true);

        //Create Account
        Account testAcc =  SBR_3_0_ServiceTestDataFactory.createAccount(false,'33333');
        insert testAcc;

        List<Account> relAccts = [SELECT Id, Name
                                    FROM Account
                                    WHERE RM_Account_Number__c = '01-33333'
                                    AND Company_Code__c= '01' LIMIT 1];

        //Create Service Territory
        ServiceTerritory  testST = SBR_3_0_ServiceTestDataFactory.createServiceTerritory(true);

        List<ServiceTerritory> str1 = [SELECT Id, Name
                                        FROM ServiceTerritory
                                        WHERE Id =: testST.Id LIMIT 1];

        //Create Exponce to Location
        ServiceTerritory  testE2Loc = SBR_3_0_ServiceTestDataFactory.createServiceTerritory(true);

        List<ServiceTerritory> str2 = [SELECT Id, Name
                                        FROM ServiceTerritory
                                        WHERE Id =: testST.Id LIMIT 1];

        //Get Sales Rep user
        User testSlaesRep = [SELECT Id, Name
                                FROM User
                                WHERE UserName LIKE 'SalesRepUser%' LIMIT 1];

        //Get Owner User
        User testOwnerUsers = [SELECT Id, Name
                                FROM User
                                WHERE UserName LIKE 'ownerTestUser%' LIMIT 1];

        //Create Wo with SF_PS_RM_WO_Number__c - > Componey code - paload workorder no
        WorkOrder testWO = SBR_3_0_ServiceTestDataFactory.createWorkOrder(false);
        testWO.AccountId = testAcc.Id;
        testWO.OwnerId = testOwnerUsers.Id;
        testWO.AssetId = testAsrt.Id;
        testWO.ServiceTerritoryId  = testST.Id;
        testWO.SF_PS_Expense_To_Location__c = testE2Loc.Id;
        testWO.SF_PS_Sales_Rep__c = testSlaesRep.Id;
        testWO.SF_PS_RM_WO_Number__c = '243697';
        testWO.Status = 'Scheduled';
        testWO.SF_PS_Claim_Type__c = 'N';
        testWO.SF_PS_Service_Resource__c = testSR.Id;
        insert testWO;

        ServiceAppointment serviceAppointment = SBR_3_0_ServiceTestDataFactory.createServiceAppointment(false, testWO.Id);
        serviceAppointment.FSSK__FSK_Work_Order__c = testWO.Id;
        serviceAppointment.Status = 'Scheduled';
        insert serviceAppointment;

        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_VDOS_UpdateWorkOrder_Mock());

        List<String> input = new List<String> ();
        input.add(testWO.Id);

        Test.startTest();
        SBR_3_0_API_VDOS_UpdateWorkOrder.workOrderVDOSCallout(input);
        Test.stopTest();

        WorkOrder newWO = [SELECT SF_PS_RM_WO_Number__c
                            FROM WorkOrder LIMIT 1];

        System.assertEquals('243697', newWO?.SF_PS_RM_WO_Number__c, 'Work Order found.');
    }

    @isTest
    static void workOrderVDOSWONotFoundCalloutTest() {
        insert new Bypass_Settings__c(SetupOwnerId=UserInfo.getUserId(), Bypass_Flow__c=true);
        Credential__c cred = SBR_3_0_TestDataFactory.createCredentials(1, false)[0];
        cred.Name = 'Mule_Token_Endpoint';
        cred.Key_Id__c = 'testKey123';
        cred.Secret__c = 'secret';
        insert cred;

        //Create Service Resource
        ServiceResource testSR = SBR_3_0_ServiceTestDataFactory.create_Service_Resource(False);
        User testUser = [SELECT Id, Name
                            FROM User
                            WHERE UserName LIKE 'SRTestUser%' LIMIT 1];
        testSR.ResourceType = 'T';
        testSR.RelatedRecordId = testUser.Id;
        insert testSR;

        //Create assert
        Asset testAsrt =  SBR_3_0_ServiceTestDataFactory.createAsset(true);

        //Create Account
        Account testAcc =  SBR_3_0_ServiceTestDataFactory.createAccount(false,'33333');
        insert testAcc;

        List<Account> relAccts = [SELECT Id, Name
                                    FROM Account
                                    WHERE RM_Account_Number__c = '01-33333'
                                    AND Company_Code__c= '01' LIMIT 1];

        //Create Service Territory
        ServiceTerritory  testST = SBR_3_0_ServiceTestDataFactory.createServiceTerritory(true);

        List<ServiceTerritory> str1 = [SELECT Id, Name
                                        FROM ServiceTerritory
                                        WHERE Id =: testST.Id LIMIT 1];

        //Create Exponce to Location
        ServiceTerritory  testE2Loc = SBR_3_0_ServiceTestDataFactory.createServiceTerritory(true);

        List<ServiceTerritory> str2 = [SELECT Id, Name
                                        FROM ServiceTerritory
                                        WHERE Id =: testST.Id LIMIT 1];

        //Get Sales Rep user
        User testSlaesRep = [SELECT Id, Name
                                FROM User
                                WHERE UserName LIKE 'SalesRepUser%' LIMIT 1];

        //Get Owner User
        User testOwnerUsers = [SELECT Id, Name
                                FROM User
                                WHERE UserName LIKE 'ownerTestUser%' LIMIT 1];

        //Create Wo with SF_PS_RM_WO_Number__c - > Componey code - paload workorder no
        WorkOrder testWO = SBR_3_0_ServiceTestDataFactory.createWorkOrder(false);
        testWO.AccountId = testAcc.Id;
        testWO.OwnerId = testOwnerUsers.Id;
        testWO.AssetId = testAsrt.Id;
        testWO.ServiceTerritoryId  = testST.Id;
        testWO.SF_PS_Expense_To_Location__c = testE2Loc.Id;
        testWO.SF_PS_Sales_Rep__c = testSlaesRep.Id;
        testWO.SF_PS_RM_WO_Number__c = '243698';
        testWO.Status = 'Scheduled';
        testWO.SF_PS_Claim_Type__c = 'N';
        testWO.SF_PS_Service_Resource__c = testSR.Id;
        insert testWO;

        ServiceAppointment serviceAppointment = SBR_3_0_ServiceTestDataFactory.createServiceAppointment(false, testWO.Id);
        serviceAppointment.FSSK__FSK_Work_Order__c = testWO.Id;
        serviceAppointment.Status = 'Scheduled';
        insert serviceAppointment;

        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_VDOS_UpdateWorkOrder_Mock());

        List<String> input = new List<String> ();
        input.add(testWO.Id);

        String exceptionMsg = '';

        try {
            Test.startTest();
            SBR_3_0_API_VDOS_UpdateWorkOrder.workOrderVDOSCallout(input);
            Test.stopTest();
        } catch (Exception ex) {
            exceptionMsg = ex.getMessage();
        }
        System.assertEquals('', exceptionMsg, 'No Error found.');
    }

    @isTest
    static void workOrderOpenVDOSCalloutTest() {
        insert new Bypass_Settings__c(SetupOwnerId=UserInfo.getUserId(), Bypass_Flow__c=true);
        Credential__c cred = SBR_3_0_TestDataFactory.createCredentials(1, false)[0];
        cred.Name = 'Mule_Token_Endpoint';
        cred.Key_Id__c = 'testKey123';
        cred.Secret__c = 'secret';
        insert cred;

        //Create Service Resource
        ServiceResource testSR = SBR_3_0_ServiceTestDataFactory.create_Service_Resource(False);
        User testUser = [SELECT Id, Name
                        FROM User
                        WHERE UserName LIKE 'SRTestUser%' LIMIT 1];
        testSR.ResourceType = 'T';
        testSR.RelatedRecordId = testUser.Id;
        insert testSR;

        //Create assert
        Asset testAsrt =  SBR_3_0_ServiceTestDataFactory.createAsset(true);

        //Create Account
        Account testAcc =  SBR_3_0_ServiceTestDataFactory.createAccount(false,'33333');
        insert testAcc;

        List<Account> relAccts = [SELECT Id, Name
                                FROM Account
                                WHERE RM_Account_Number__c = '01-33333'
                                AND Company_Code__c= '01' LIMIT 1];

        //Create Service Territory
        ServiceTerritory  testST = SBR_3_0_ServiceTestDataFactory.createServiceTerritory(true);

        List<ServiceTerritory> str1 = [SELECT Id, Name
                                        FROM ServiceTerritory
                                        WHERE Id =: testST.Id LIMIT 1];

        //Create Exponce to Location
        ServiceTerritory  testE2Loc = SBR_3_0_ServiceTestDataFactory.createServiceTerritory(true);

        List<ServiceTerritory> str2 = [SELECT Id, Name
                                        FROM ServiceTerritory
                                        WHERE Id =: testST.Id LIMIT 1];

        //Get Sales Rep user
        User testSlaesRep = [Select Id,Name from User where UserName LIKE 'SalesRepUser%' ];

        //Get Owner User
        User testOwnerUsers = [Select Id,Name from User where UserName LIKE 'ownerTestUser%' ];

        //Create Wo with SF_PS_RM_WO_Number__c - > Componey code - paload workorder no
        WorkOrder testWO = SBR_3_0_ServiceTestDataFactory.createWorkOrder(false);
        testWO.AccountId = testAcc.Id;
        testWO.OwnerId = testOwnerUsers.Id;
        testWO.AssetId = testAsrt.Id;
        testWO.ServiceTerritoryId  = testST.Id;
        testWO.SF_PS_Expense_To_Location__c = testE2Loc.Id;
        testWO.SF_PS_Sales_Rep__c = testSlaesRep.Id;
        testWO.SF_PS_RM_WO_Number__c = '243697';
        testWO.Status = 'O';
        testWO.SF_PS_Claim_Type__c = 'N';
        testWO.SF_PS_Service_Resource__c = testSR.Id;
        testWO.SF_PS_VDOS_OrderLine_External_Id__c = '123456789';
        insert testWO;

        ServiceAppointment serviceAppointment = SBR_3_0_ServiceTestDataFactory.createServiceAppointment(false, testWO.Id);
        serviceAppointment.FSSK__FSK_Work_Order__c = testWO.Id;
        insert serviceAppointment;

        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_VDOS_UpdateWorkOrder_Mock());

        List<String> input = new List<String> ();
        input.add(testWO.Id);

        Test.startTest();
        SBR_3_0_API_VDOS_UpdateWorkOrder.workOrderVDOSCallout(input);
        Test.stopTest();

        WorkOrder newWO = [SELECT SF_PS_RM_WO_Number__c
                            FROM WorkOrder LIMIT 1];

        System.assertEquals('243697', newWO.SF_PS_RM_WO_Number__c, 'Work Order Found');
    }

    @isTest
    static void workOrderInRouteVDOSCalloutTest() {
        insert new Bypass_Settings__c(SetupOwnerId=UserInfo.getUserId(), Bypass_Flow__c=true);
        Credential__c cred = SBR_3_0_TestDataFactory.createCredentials(1, false)[0];
        cred.Name = 'Mule_Token_Endpoint';
        cred.Key_Id__c = 'testKey123';
        cred.Secret__c = 'secret';
        insert cred;

        //Create Service Resource
        ServiceResource testSR = SBR_3_0_ServiceTestDataFactory.create_Service_Resource(False);
        User testUser = [SELECT Id, Name
                            FROM User
                            WHERE UserName LIKE 'SRTestUser%' LIMIT 1];
        testSR.ResourceType = 'T';
        testSR.RelatedRecordId = testUser.Id;
        insert testSR;

        //Create assert
        Asset testAsrt =  SBR_3_0_ServiceTestDataFactory.createAsset(true);

        //Create Account
        Account testAcc =  SBR_3_0_ServiceTestDataFactory.createAccount(false,'33333');
        insert testAcc;

        List<Account> relAccts = [SELECT Id, Name
                                    FROM Account
                                    WHERE RM_Account_Number__c = '01-33333'
                                    AND Company_Code__c= '01' LIMIT 1];

        //Create Service Territory
        ServiceTerritory  testST = SBR_3_0_ServiceTestDataFactory.createServiceTerritory(true);

        List<ServiceTerritory> str1 = [SELECT Id, Name
                                        FROM ServiceTerritory
                                        WHERE Id =: testST.Id LIMIT 1];

        //Create Exponce to Location
        ServiceTerritory  testE2Loc = SBR_3_0_ServiceTestDataFactory.createServiceTerritory(true);

        List<ServiceTerritory> str2 = [SELECT Id, Name
                                        FROM ServiceTerritory
                                        WHERE Id =: testST.Id LIMIT 1];

        //Get Sales Rep user
        User testSlaesRep = [Select Id,Name from User where UserName LIKE 'SalesRepUser%' ];

        //Get Owner User
        User testOwnerUsers = [Select Id,Name from User where UserName LIKE 'ownerTestUser%' ];

        //Create Wo with SF_PS_RM_WO_Number__c - > Componey code - paload workorder no
        WorkOrder testWO = SBR_3_0_ServiceTestDataFactory.createWorkOrder(false);
        testWO.AccountId = testAcc.Id;
        testWO.OwnerId = testOwnerUsers.Id;
        testWO.AssetId = testAsrt.Id;
        testWO.ServiceTerritoryId  = testST.Id;
        testWO.SF_PS_Expense_To_Location__c = testE2Loc.Id;
        testWO.SF_PS_Sales_Rep__c = testSlaesRep.Id;
        testWO.SF_PS_RM_WO_Number__c = '243697';
        testWO.Status = 'In Route';
        testWO.SF_PS_Claim_Type__c = 'N';
        testWO.SF_PS_Service_Resource__c = testSR.Id;
        testWO.SF_PS_VDOS_OrderLine_External_Id__c = '123456789';
        insert testWO;

        ServiceAppointment serviceAppointment = SBR_3_0_ServiceTestDataFactory.createServiceAppointment(false, testWO.Id);
        serviceAppointment.FSSK__FSK_Work_Order__c = testWO.Id;
        insert serviceAppointment;

        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_VDOS_UpdateWorkOrder_Mock());

        List<String> input = new List<String> ();
        input.add(testWO.Id);

        Test.startTest();
        SBR_3_0_API_VDOS_UpdateWorkOrder.workOrderVDOSCallout(input);
        Test.stopTest();

        WorkOrder newWO = [SELECT SF_PS_RM_WO_Number__c
                            FROM WorkOrder LIMIT 1];

        System.assertEquals('243697', newWO.SF_PS_RM_WO_Number__c, 'Work Order Found');
    }

    @isTest
    static void workOrderOpenVDOSCalloutErrorTest() {
        insert new Bypass_Settings__c(SetupOwnerId=UserInfo.getUserId(), Bypass_Flow__c=true);
        Credential__c cred = SBR_3_0_TestDataFactory.createCredentials(1, false)[0];
        cred.Name = 'Mule_Token_Endpoint';
        cred.Key_Id__c = 'testKey123';
        cred.Secret__c = 'secret';
        insert cred;

        //Create Service Resource
        ServiceResource testSR = SBR_3_0_ServiceTestDataFactory.create_Service_Resource(False);
        User testUser = [SELECT Id, Name
                            FROM User
                            WHERE UserName LIKE 'SRTestUser%' LIMIT 1];
        testSR.ResourceType = 'T';
        testSR.RelatedRecordId = testUser.Id;
        insert testSR;

        //Create assert
        Asset testAsrt =  SBR_3_0_ServiceTestDataFactory.createAsset(true);

        //Create Account
        Account testAcc =  SBR_3_0_ServiceTestDataFactory.createAccount(false,'33333');
        insert testAcc;

        List<Account> relAccts = [SELECT Id, Name
                                    FROM Account
                                    WHERE RM_Account_Number__c = '01-33333'
                                    AND Company_Code__c= '01' LIMIT 1];

        //Create Service Territory
        ServiceTerritory  testST = SBR_3_0_ServiceTestDataFactory.createServiceTerritory(true);

        List<ServiceTerritory> str1 = [SELECT Id, Name
                                        FROM ServiceTerritory
                                        WHERE Id =: testST.Id LIMIT 1];

        //Create Exponce to Location
        ServiceTerritory  testE2Loc = SBR_3_0_ServiceTestDataFactory.createServiceTerritory(true);

        List<ServiceTerritory> str2 = [SELECT Id, Name
                                        FROM ServiceTerritory
                                        WHERE Id =: testST.Id LIMIT 1];

        //Get Sales Rep user
        User testSlaesRep = [SELECT Id, Name
                                FROM User
                                WHERE UserName LIKE 'SalesRepUser%' LIMIT 1];

        //Get Owner User
        User testOwnerUsers = [SELECT Id, Name
                                FROM User
                                WHERE UserName LIKE 'ownerTestUser%' ];

        //Create Wo with SF_PS_RM_WO_Number__c - > Componey code - paload workorder no
        WorkOrder testWO = SBR_3_0_ServiceTestDataFactory.createWorkOrder(false);
        testWO.AccountId = testAcc.Id;
        testWO.OwnerId = testOwnerUsers.Id;
        testWO.AssetId = testAsrt.Id;
        testWO.ServiceTerritoryId  = testST.Id;
        testWO.SF_PS_Expense_To_Location__c = testE2Loc.Id;
        testWO.SF_PS_Sales_Rep__c = testSlaesRep.Id;
        testWO.SF_PS_RM_WO_Number__c = '';
        testWO.Status = 'O';
        testWO.SF_PS_Claim_Type__c = 'N';
        testWO.SF_PS_Service_Resource__c = testSR.Id;
        insert testWO;

        ServiceAppointment serviceAppointment = SBR_3_0_ServiceTestDataFactory.createServiceAppointment(false, testWO.Id);
        serviceAppointment.FSSK__FSK_Work_Order__c = testWO.Id;
        serviceAppointment.Status = 'test';
        insert serviceAppointment;

        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_VDOS_UpdateWorkOrder_Mock());

        List<String> input = new List<String> ();
        input.add(testWO.Id);

        Integer exceptionLogsCount = [SELECT count()
                                        FROM Exception_Log__c];
        Test.startTest();
        SBR_3_0_API_VDOS_UpdateWorkOrder.workOrderVDOSCallout(input);
        Test.stopTest();

        Integer exceptionLogsUpdatedCount = [SELECT count()
                                                FROM Exception_Log__c];

        System.assertEquals(exceptionLogsCount + 1, exceptionLogsUpdatedCount, 'Exception Log generated.');
    }
}