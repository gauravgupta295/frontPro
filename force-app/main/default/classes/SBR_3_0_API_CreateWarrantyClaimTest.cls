/*********************************************************************************************************************
* Apex Class: SBR_3_0_API_CreateWarrantyClaimTest
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Test Class for SBR_3_0_API_CreateWarrantyClaim
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Meghna Vijay           2024-03-07          Initial version
*********************************************************************************************************************/

@isTest
public with sharing class SBR_3_0_API_CreateWarrantyClaimTest {
    
    @testSetup
    public static void testSetupMethod() {
        User serviceResourceUser =  SBR_3_0_ServiceTestDataFactory.createServiceResourceUser(true,'1234','78923');
        User salesRepUser = SBR_3_0_ServiceTestDataFactory.createSalesRepUser(true,'111222');
        User ownerUse = SBR_3_0_ServiceTestDataFactory.createOwnerUser(true, '1234','7777');
    }

    @isTest
    static void warrantyClaimCalloutSuccess() {
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
        testWO.SF_PS_Service_Resource__c = testSR.Id;
        testWO.SF_PS_Claim_Labor_Code__c = '9000';
        testWO.SF_PS_Claim_Comments1__c = 'Test';
        testWO.SF_PS_Claim_Comments2__c = 'XYZ';
        insert testWO;
        
        ServiceAppointment serviceAppointment = SBR_3_0_ServiceTestDataFactory.createServiceAppointment(false, testWO.Id);
        serviceAppointment.FSSK__FSK_Work_Order__c = testWO.Id;
        serviceAppointment.Status = 'Scheduled';
        insert serviceAppointment;

        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_CreateWorkOrderTest());
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_WarrantyClaimMockTest());

        WorkOrder wo = [SELECT Id FROM WorkOrder limit 1];
        List<String> input = new List<String> ();
        input.add(wo.Id);
        
        Test.startTest();
        	SBR_3_0_API_CreateWorkOrder.CreateWorkOrderRMCallout(input);
        	SBR_3_0_API_CreateWarrantyClaim.createWarrantyClaim(wo.Id);
        Test.stopTest();
        WorkOrder updatedWO = [SELECT SF_PS_Claim_Num__c FROM WorkOrder WHERE Id=: wo.Id];
        System.assertEquals('12345', updatedWO?.SF_PS_Claim_Num__c, 'Claim# is set for warranty claim');
    }
    
    @isTest
    static void warrantyClaimCalloutError() {
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
        testWO.SF_PS_Service_Resource__c = testSR.Id;
        testWO.SF_PS_Claim_Labor_Code__c = '9000';
        insert testWO;
        
        ServiceAppointment serviceAppointment = SBR_3_0_ServiceTestDataFactory.createServiceAppointment(false, testWO.Id);
        serviceAppointment.FSSK__FSK_Work_Order__c = testWO.Id;
        serviceAppointment.Status = 'Scheduled';
        insert serviceAppointment;
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_CreateWorkOrderTest());
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_WarrantyClaimMockTest());
        WorkOrder wo = [SELECT Id FROM WorkOrder limit 1];
        List<String> input = new List<String> ();
        input.add(wo.Id);
        Test.startTest();
        	SBR_3_0_API_CreateWorkOrder.CreateWorkOrderRMCallout(input);
        	SBR_3_0_API_CreateWarrantyClaim.createWarrantyClaim(wo.Id);
        Test.stopTest();
		WorkOrder updatedWO = [SELECT SF_PS_Claim_Num__c FROM WorkOrder WHERE Id=: wo.Id];
        System.assertEquals(null, updatedWO?.SF_PS_Claim_Num__c, 'Claim# is not set for warranty claim');
    }
}