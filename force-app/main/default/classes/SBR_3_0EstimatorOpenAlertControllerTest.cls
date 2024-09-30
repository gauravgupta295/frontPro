/********************************************************************************************************************
* Apex Class: SBR_3_0_EstimatorOpenAlertController
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Test class of SBR_3_0_DamageEstimatorSelective
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Meghna Vijay          2024-02-22            Initial version   
*********************************************************************************************************************/

@isTest
public with sharing class SBR_3_0EstimatorOpenAlertControllerTest {

    @TestSetup
    static void createTestData() {
        insert new Bypass_Settings__c(SetupOwnerId=UserInfo.getUserId(), Bypass_Flow__c=true);
        Credential__c cred = SBR_3_0_TestDataFactory.createCredentials(1, false)[0];
        cred.Name = 'Mule_Token_Endpoint';
        cred.Key_Id__c = 'testKey123';
        cred.Secret__c = 'secret';
        insert cred;

        // Perform DML operations on setup objects within System.runAs()
        System.runAs(new User(Id = UserInfo.getUserId())) {
            //Create User
            User newServiceResourceUser =  SBR_3_0_ServiceTestDataFactory.createServiceResourceUser(true,'1234','78923');
            
            // Create Sales rep User 
            User newSalesRepUser = SBR_3_0_ServiceTestDataFactory.createSalesRepUser(true,'111222');
            
        }

        //Create Service Resource 
        ServiceResource testSR = SBR_3_0_ServiceTestDataFactory.create_Service_Resource(false);
        User testSalesRepUser = [Select Id,Name from User where UserName LIKE 'SRTestUser%' ];
        testSR.ResourceType = 'T';
        testSR.RelatedRecordId = testSalesRepUser.Id;
        insert testSR;
        //Create assert 
        Asset testAsrt =  SBR_3_0_ServiceTestDataFactory.createAsset(true);
        
        //Create Account 
        Account testAcc =  SBR_3_0_ServiceTestDataFactory.createAccount(false,'33333');
        insert testAcc;

        //Create Service Territory 
        ServiceTerritory  testST = SBR_3_0_ServiceTestDataFactory.createServiceTerritory(true);

        //Get Sales Rep user 
        User testSalesRep = [Select Id,Name from User where UserName LIKE 'SalesRepUser%' ];

        //Create Exponce to Location
        ServiceTerritory  testE2Loc = SBR_3_0_ServiceTestDataFactory.createServiceTerritory(true);

        WorkOrder testWO = SBR_3_0_ServiceTestDataFactory.createWorkOrder(false);
        testWO.AccountId = testAcc.id;
        testWO.AssetId = testAsrt.id;
        testWO.ServiceTerritoryId  = testST.id;
        testWO.SF_PS_Expense_To_Location__c = testE2Loc.id;
        testWO.SF_PS_Service_Resource__c = testSR.id;
        testWO.SF_PS_Work_Order_Des__c = 'DAMAGE - RPP CLAIM';
        testWO.SF_PS_Claim_Type__c = 'D';
        testWO.SF_PS_Complaint__c = 'Test complaint';
        testWO.SF_PS_BillCustOrLoc__c = 'L';
        testWO.SF_PS_ExpenseCode__c = 'DRPP';
        testWO.SF_PS_LaborCode__c = '9000';
        insert testWO;

        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_CreateWorkOrderTest());

        SF_PS_Damage_Estimator__c testDamageEstimator = new SF_PS_Damage_Estimator__c();
        testDamageEstimator.SF_PS_Work_Order_Number__c = testWO.Id;  
        testDamageEstimator.SF_PS_Status__c = 'OPEN';
        insert testDamageEstimator;
    }

    @isTest
    static void testGetEstimatorOpenDays() {
        WorkOrder testWO = [SELECT Id FROM WorkOrder LIMIT 1];
        SF_PS_Damage_Estimator__c testDamageEstimatorRec = [SELECT Id FROM SF_PS_Damage_Estimator__c LIMIT 1];
        System.assertEquals(0,SBR_3_0_EstimatorOpenAlertController.getEstimatorOpenDays(testWO.Id),'Estimator days is 0');
        System.assertEquals(0,SBR_3_0_EstimatorOpenAlertController.getEstimatorOpenDays(testDamageEstimatorRec.Id),'Estimator days is 0 on damage estimator');
    }
}