@isTest
public with sharing class SBR_3_0_API_WorkOrderQuote_Test {
    static Boolean SUCCESS = true;

    static HttpResponse res;

    @TestSetup
    static void makeData(){
        
        User testSRUser =  SBR_3_0_ServiceTestDataFactory.createServiceResourceUser(true,'1234','78923');        
        // Create Sales rep User 
        User TestSalesRep = SBR_3_0_ServiceTestDataFactory.createSalesRepUser(true,'111222');

        //Create Owner User 
        //Create Owner
        User TestOwnerUser = SBR_3_0_ServiceTestDataFactory.createOwnerUser(true, '1234','7777');

         
    }


    @isTest 
    static void testUpdateWorkOrderSuccess() {
        Credential__c cred = SBR_3_0_TestDataFactory.createCredentials(1, false)[0];
        cred.Name = 'Mule_Token_Endpoint';
        cred.Key_Id__c = 'testKey123';
        cred.Secret__c = 'secret';
        insert cred;
        
               //Create Service Resource 
        ServiceResource testSR = SBR_3_0_ServiceTestDataFactory.create_Service_Resource(False);
        User testUser = [Select Id,Name from User where UserName LIKE 'SRTestUser%' ];
        testSR.ResourceType = 'T';
        testSR.RelatedRecordId = testUser.Id;
        insert testSR;
        //Create assert 
        Asset testAsrt =  SBR_3_0_ServiceTestDataFactory.createAsset(true);
        List<Asset> testASSERT1 = [
            SELECT ID, Name ,SM_PS_Asset_Id__c
            FROM Asset 
            WHERE id =: testAsrt.id LIMIT 1];
         //Create Account 
         Account testAcc =  SBR_3_0_ServiceTestDataFactory.createAccount(false,'33333');
         insert testAcc; 
         List<Account> relAccts = [
             SELECT ID, Name
             FROM Account 
             WHERE RM_Account_Number__c = '01-33333' and Company_Code__c= '01' LIMIT 1]; 
         //Create Service Territory 
         ServiceTerritory  testST = SBR_3_0_ServiceTestDataFactory.createServiceTerritory(true);
 
         List<ServiceTerritory> str1 = [
             SELECT ID, Name
             FROM ServiceTerritory 
             WHERE id =: testST.id LIMIT 1]; 
         //Create Exponce to Location
         ServiceTerritory  testE2Loc = SBR_3_0_ServiceTestDataFactory.createServiceTerritory(true);
 
         List<ServiceTerritory> str2 = [
             SELECT ID, Name
             FROM ServiceTerritory 
             WHERE id =: testST.id LIMIT 1]; 
         //Get Sales Rep user 
         User testSlaesRep = [Select Id,Name from User where UserName LIKE 'SalesRepUser%' ];
 
         //Get Associated Location 
         //AssociatedLocation testAssloc =  SBR_3_0_ServiceTestDataFactory.createAssLOC(true,'12345678901234567890');
         //List<AssociatedLocation> assloc1 = [
         //    SELECT ID,Job_Number__c
         //    FROM AssociatedLocation 
         //    WHERE id =: testAssloc.id LIMIT 1];
         //system.debug('Asssociated Location Id'+ assloc1[0] +' --' );
 
 
         //Get Owner User 
         User testOwnerUsers = [Select Id,Name from User where UserName LIKE 'ownerTestUser%' ];
 
 
         //  Create Work Order 
         //Create Wo with SF_PS_RM_WO_Number__c - > Componey code - paload workorder no
         workOrder testWO = SBR_3_0_ServiceTestDataFactory.createWorkOrder(false);
         testWO.AccountId = testAcc.id;
         testWO.OwnerId = testOwnerUsers.id;
         testWO.AssetId = testAsrt.id;
         testWO.ServiceTerritoryId  = testST.id;
         testWO.SF_PS_Expense_To_Location__c = testE2Loc.id;
         testWO.SF_PS_Sales_Rep__c = testSlaesRep.id;
         //testWO.SF_PS_Job_Site__c =testAssloc.id;
         testWO.SF_PS_Service_Resource__c = testSR.id;
         insert testWO;
 
         List<workOrder> wotest1 = [
             SELECT ID 
             FROM workOrder 
             WHERE id =: testWO.id LIMIT 1];        
        
        SUCCESS= false;
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_WorkOrderQuoteTest());
        
        WorkOrder wo = [SELECT Id FROM WorkOrder limit 1];
        List<String> input = new List<String> ();
        input.add(wo.Id);
        Test.startTest();
        SBR_3_0_API_UpdateQuoteWorkOrder.CreateWorkOrderRMCallout(input);
        Test.stopTest();
        
    }
    @isTest 
    static void testUpdateWorkOrderFailure() {
        Credential__c cred = SBR_3_0_TestDataFactory.createCredentials(1, false)[0];
        cred.Name = 'Mule_Token_Endpoint';
        cred.Key_Id__c = 'testKey123';
        cred.Secret__c = 'secret';
        insert cred;
        
               //Create Service Resource 
        ServiceResource testSR = SBR_3_0_ServiceTestDataFactory.create_Service_Resource(False);
        User testUser = [Select Id,Name from User where UserName LIKE 'SRTestUser%' ];
        testSR.ResourceType = 'T';
        testSR.RelatedRecordId = testUser.Id;
        insert testSR;
        //Create assert 
        Asset testAsrt =  SBR_3_0_ServiceTestDataFactory.createAsset(true);
        List<Asset> testASSERT1 = [
            SELECT ID, Name ,SM_PS_Asset_Id__c
            FROM Asset 
            WHERE id =: testAsrt.id LIMIT 1];
         //Create Account 
         Account testAcc =  SBR_3_0_ServiceTestDataFactory.createAccount(false,'33333');
         insert testAcc; 
         List<Account> relAccts = [
             SELECT ID, Name
             FROM Account 
             WHERE RM_Account_Number__c = '01-33333' and Company_Code__c= '01' LIMIT 1]; 
         //Create Service Territory 
         ServiceTerritory  testST = SBR_3_0_ServiceTestDataFactory.createServiceTerritory(true);
 
         List<ServiceTerritory> str1 = [
             SELECT ID, Name
             FROM ServiceTerritory 
             WHERE id =: testST.id LIMIT 1]; 
         //Create Exponce to Location
         ServiceTerritory  testE2Loc = SBR_3_0_ServiceTestDataFactory.createServiceTerritory(true);
 
         List<ServiceTerritory> str2 = [
             SELECT ID, Name
             FROM ServiceTerritory 
             WHERE id =: testST.id LIMIT 1]; 
         //Get Sales Rep user 
         User testSlaesRep = [Select Id,Name from User where UserName LIKE 'SalesRepUser%' ];
 
         //Get Associated Location 
         //AssociatedLocation testAssloc =  SBR_3_0_ServiceTestDataFactory.createAssLOC(true,'12345678901234567890');
         //List<AssociatedLocation> assloc1 = [
         //    SELECT ID,Job_Number__c
         //    FROM AssociatedLocation 
         //    WHERE id =: testAssloc.id LIMIT 1];
         //system.debug('Asssociated Location Id'+ assloc1[0] +' --' );
 
 
         //Get Owner User 
         User testOwnerUsers = [Select Id,Name from User where UserName LIKE 'ownerTestUser%' ];
 
 
         //  Create Work Order 
         //Create Wo with SF_PS_RM_WO_Number__c - > Componey code - paload workorder no
         workOrder testWO = SBR_3_0_ServiceTestDataFactory.createWorkOrder(false);
         testWO.AccountId = testAcc.id;
         testWO.OwnerId = testOwnerUsers.id;
         testWO.AssetId = testAsrt.id;
         testWO.ServiceTerritoryId  = testST.id;
         testWO.SF_PS_Expense_To_Location__c = testE2Loc.id;
         testWO.SF_PS_Sales_Rep__c = testSlaesRep.id;
         //testWO.SF_PS_Job_Site__c =testAssloc.id;
         testWO.SF_PS_Service_Resource__c = testSR.id;
         testWO.SF_PS_Funded__c  = 'true';
         testWO.SF_PS_Date_Opened__c = NULL;
         testWO.SF_PS_Date_Opened__c = NULL;
         testWO.SF_PS_Due_Date__c    = NULL;
         insert testWO;
 
         List<workOrder> wotest1 = [
             SELECT ID 
             FROM workOrder 
             WHERE id =: testWO.id LIMIT 1];        
        
        SUCCESS= false;
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_WorkOrderUpdateQuoteTest());
        
        WorkOrder wo = [SELECT Id FROM WorkOrder limit 1];
        List<String> input = new List<String> ();
        input.add(wo.Id);
        Test.startTest();
        SBR_3_0_API_UpdateQuoteWorkOrder.CreateWorkOrderRMCallout(input);
        SBR_3_0_API_UpdateQuoteWorkOrder.WrappedResponse respWrapobj = new SBR_3_0_API_UpdateQuoteWorkOrder.WrappedResponse();
        respWrapobj.workOrderNumber = 'test';
        respWrapobj.mode = 'test';
        respWrapobj.status = 'test';
        respWrapobj.workOrderLineItems = null;
        Test.stopTest();
        
    }

}