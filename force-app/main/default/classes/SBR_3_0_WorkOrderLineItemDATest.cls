/*********************************************************************************************************************
* Apex Class: SBR_3_0_WorkOrderLineItemDATest
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Test class for WorkOrderLineItemDA
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION       DATE               DETAIL FEATURES
    1.0          2023-02-23          Initial version    
	2.0			 2024-06-10			 Pankaj Meshram
**********************************************************************************************************************************************/
@isTest
public with sharing class SBR_3_0_WorkOrderLineItemDATest Implements HttpCalloutMock {
    static Boolean SUCCESS = true;
    static HttpResponse res;

   @TestSetup
    static void makeData(){
        User testSRUser =  SBR_3_0_ServiceTestDataFactory.createServiceResourceUser(true,'1234','78923');
        System.debug('testSRUser --- ' + testSRUser);
        User TestSalesRep = SBR_3_0_ServiceTestDataFactory.createSalesRepUser(true,'111222');
        User TestOwnerUser = SBR_3_0_ServiceTestDataFactory.createOwnerUser(true, '1234','7777'); 
    }

    public HTTPResponse respond(HTTPRequest req) {
        // Create a fake response
        res = new HttpResponse();
        res.setHeader('Content-Type',SBR_3_0_Constants.APP_JSON);
        if(req.getEndpoint().endsWithIgnoreCase('token')){
            res.setBody('{"access_token":"test"}');
            res.setStatusCode(200);
        }else if(SUCCESS) {
            res.setBody('{ "data": { "rmWONumber": "000086613723" } }');
            res.setStatusCode(200);
        }
        else if(!SUCCESS) {
            res.setBody('{ "data": { "message": "Successfull Update" } }');
            res.setStatusCode(200);
        }else {
            res.setBody('{ "error": { "message": "Invalid input parameters, parameters might contain special characters, SQL statements or script statements. Please check application logs for more information.", "errorKey": "BAD_REQUEST", "errorCode": "400-000" } }');
            res.setStatusCode(400);
        }
        return res;
    }

    @isTest 
    static void testCreateWorkOrderSuccess() {
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
        system.debug('---111-----'+ testASSERT1[0]);

         //Create Account 
         Account testAcc =  SBR_3_0_ServiceTestDataFactory.createAccount(false,'33333');
         insert testAcc;
         system.debug('account in Test Calss is --' + testAcc );
 
         List<Account> relAccts = [
             SELECT ID, Name
             FROM Account 
             WHERE RM_Account_Number__c = '01-33333' and Company_Code__c= '01' LIMIT 1];
         system.debug('in Test Test Class relAccts '+ relAccts[0] +' --' );
 
         //Create Service Territory 
         ServiceTerritory  testST = SBR_3_0_ServiceTestDataFactory.createServiceTerritory(true);
 
         List<ServiceTerritory> str1 = [
             SELECT ID, Name
             FROM ServiceTerritory 
             WHERE id =: testST.id LIMIT 1];
         system.debug('ServiceTerritory 1 test'+ str1[0] +' --' );
 
         //Create Exponce to Location
         ServiceTerritory  testE2Loc = SBR_3_0_ServiceTestDataFactory.createServiceTerritory(true);
 
         List<ServiceTerritory> str2 = [
             SELECT ID, Name
             FROM ServiceTerritory 
             WHERE id =: testST.id LIMIT 1];
         system.debug('expence to loc 2 test'+ str2[0] +' --' );
 
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
        WorkOrderLineItem woli = new WorkOrderLineItem(WorkOrderId=testWO.Id , SF_PS_Bypass_flow__c = true,SF_PS_Line_Type__c='LI',Duration=2,SF_PS_Hourly_Internal_Rate__c=200,SF_PS_Mechanic_Name__c=testSR.id); //Added for FRONT-30844  
        insert   woli;
 
         List<workOrder> wotest1 = [
             SELECT ID 
             FROM workOrder 
             WHERE id =: testWO.id LIMIT 1];
         system.debug('workorder isss  1 test'+ wotest1[0] +' --' );
        
        
        //Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_CreateWorkOrderTest());//Commented for FRONT_30844
        WorkOrder wo = [SELECT Id FROM WorkOrder limit 1];
        List<String> input = new List<String> ();
        input.add(wo.Id);
        Test.startTest();
        //SBR_3_0_API_CreateWorkOrder testCreate = new SBR_3_0_API_CreateWorkOrder();
        //SBR_3_0_API_CreateWorkOrder.CreateWorkOrderRMCallout(input);
        //SBR_3_0_ServiceTestDataFactory.createWorkOrderWithAssignedResource();
         List<WorkOrderLineItem> woliRecs=SBR_3_0_WorkOrderLineItemDA.getWoliTableRecs(testWO.Id);
        Test.stopTest();
         Assert.areNotEqual(woliRecs[0].Id,null);
    }
}