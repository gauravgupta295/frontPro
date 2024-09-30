/*********************************************************************************************************************
* Apex Class: SBR_3_0_AutoCloseEstimatorBatchTest
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Test class for SBR_3_0_AutoCloseEstimatorBatch
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
1.0         Meghna Vijay          2024-04-04             Initial version
*********************************************************************************************************************/
@isTest
public class SBR_3_0_AutoCloseEstimatorBatchTest {
	
    @testSetup
    public static void testSetupMethod() {
        User serviceResourceUser =  SBR_3_0_ServiceTestDataFactory.createServiceResourceUser(true,'1234','78923');
        User salesRepUser = SBR_3_0_ServiceTestDataFactory.createSalesRepUser(true,'111222');
        User ownerUse = SBR_3_0_ServiceTestDataFactory.createOwnerUser(true, '1234','7777');
    }
    
    @isTest
    static void testAutoClose_Success() {
        insert new Bypass_Settings__c(SetupOwnerId=UserInfo.getUserId(), Bypass_Flow__c=true);
        List<SF_PS_Damage_Estimator__c> damageEstimatorList = new List<SF_PS_Damage_Estimator__c>();
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
        testWO.SF_PS_Work_Order_Des__c = 'ANNUAL INSPECTION';
        insert testWO;
        
        ServiceAppointment serviceAppointment = SBR_3_0_ServiceTestDataFactory.createServiceAppointment(false, testWO.Id);
        serviceAppointment.FSSK__FSK_Work_Order__c = testWO.Id;
        serviceAppointment.Status = 'Scheduled';
        insert serviceAppointment;
		
        for(Integer i=0; i<200; i++) {
            SF_PS_Damage_Estimator__c damageEstimatorObj = new SF_PS_Damage_Estimator__c ();
            damageEstimatorObj.SF_PS_Work_Order_Number__c = testWO.Id;
            damageEstimatorObj.SF_PS_Estimated_Completion__c = System.Today();
            damageEstimatorObj.SF_PS_Estimated_Cost_Labor__c = 23.12;
            damageEstimatorObj.SF_PS_Estimated_Cost_Labor_Hours__c = 2;
            damageEstimatorObj.SF_PS_Estimated_Cost_Misc__c = 23.12;
            damageEstimatorObj.SF_PS_Estimated_Cost_Parts__c = 23.12;
            damageEstimatorObj.SF_PS_Estimator_Reason_Code__c = 'RP';
            damageEstimatorObj.SF_PS_Invoice_Comment1__c = 'Comment 1';
            damageEstimatorObj.SF_PS_Status__c = 'OPEN';
            damageEstimatorList.add(damageEstimatorObj);
            
        }
        insert damageEstimatorList;

        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_CreateWorkOrderTest());
        WorkOrder wo = [SELECT Id FROM WorkOrder limit 1];
        List<String> input = new List<String> ();
        input.add(wo.Id);
        
        Test.startTest();
        	ID batchprocessid = Database.executeBatch(new SBR_3_0_AutoCloseEstimatorBatch());
      	Test.stopTest();
        List<SF_PS_Damage_Estimator__c> damageEstimatorClosedList = [SELECT Id FROM SF_PS_Damage_Estimator__c WHERE SF_PS_Status__c= 'CLOSED WITHOUT BILLED'
                                                                        AND SF_PS_Close_Without_Billing_Reason__c = 'C7 - Auto-Closed'];
        Assert.areEqual(200,damageEstimatorClosedList.size(), 'Damage estimator has been auto-closed');
    }
}