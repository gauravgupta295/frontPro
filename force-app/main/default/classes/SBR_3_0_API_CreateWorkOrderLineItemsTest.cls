/*********************************************************************************************************************
* Apex Class: SBR_3_0_API_CreateWorkOrderLineItemsTest
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Test and Mock WorkOrderLineItems (Labor) and mimic SF to Rentalman (via Mulesoft) when it is created in Salesforce
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION       DATE               DETAIL FEATURES
1.0          	----------        	Initial version 
2.0          	----------          Mayank Jain - Update In Functionality 
3.0				11-Jan-2024			Mayank Jain - Bulkified Code 
**********************************************************************************************************************************************/

@isTest
public with sharing class SBR_3_0_API_CreateWorkOrderLineItemsTest implements HttpCalloutMock{
    
	static Boolean SUCCESS;
    
     public HTTPResponse respond(HTTPRequest req) {
        HTTPResponse res=new HTTPResponse();
        res.setHeader('Content-Type',SBR_3_0_Constants.APP_JSON);
        if(req.getEndpoint().endsWithIgnoreCase('token')){
            res.setBody('{"access_token":"test"}');
            res.setStatusCode(200);
        }else if(req.getEndpoint().endsWithIgnoreCase('insideLabor') && SUCCESS ){
            res.setBody(		'{'+
		'  "workOrderNumber": 86684649,'+
		'  "mode": "U",'+
		'  "message": "Work Order processed successfully",'+
		'  "workOrderLineItems": [ { "workOrderLineItemNumber": 9999, "uniqueId": 12345678911, "sourceReferenceLineNumber": "" } ]'+
		'}');
            res.setStatusCode(200);
        }else if(req.getEndpoint().endsWithIgnoreCase('mileageCharges') && SUCCESS){
            res.setBody(		'{'+
		'  "workOrderNumber": 86684649,'+
		'  "mode": "U",'+
		'  "message": "Work Order processed successfully",'+
		'  "workOrderLineItems": [ { "workOrderLineItemNumber": 9999, "uniqueId": 12345678911, "sourceReferenceLineNumber": "" } ]'+
		'}');
            res.setStatusCode(200);
        }else {
            res.setBody(		'{'+
		'  "errors": {'+
		'    "ind": true,'+
		'    "code": "WOCRTT2000",'+
		'    "text": "Invalid claim type entered. Valid types are N, D, M, or S..",'+
		'    "reference": "1496"'+
		'  }'+
		'}');
            res.setStatusCode(400);
        }
        return res;
    }
    
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
    static void createWoliTest(){	
        insert new Bypass_Settings__c(SetupOwnerId=UserInfo.getUserId(), Bypass_Flow__c=true);
        Credential__c cred = SBR_3_0_TestDataFactory.createCredentials(1, false)[0];
        cred.Name = 'Mule_Token_Endpoint';
        cred.Key_Id__c = 'testKey123';
        cred.Secret__c = 'secret';
        insert cred;
        SUCCESS = true;
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
 
         //List<workOrder> wotest1 = [
         //    SELECT ID 
         //    FROM workOrder 
         //    WHERE id =: testWO.id LIMIT 1];
        
        WorkOrderLineItem testwoli =  SBR_3_0_ServiceTestDataFactory.createWoli(false,testWO.id,testSR.id);
        testwoli.SF_PS_Labor_Code__c = '9000';
        testwoli.SF_PS_Hourly_Internal_Rate__c = 1.0;
        testwoli.SF_PS_RM_Labor_Line_Item_Number__c = '9999';
        testwoli.SF_PS_RM_External_Id__c = '';
        testwoli.Duration = 1.0;
        insert testwoli;

        list<String> woliListId = new List<string>();
        woliListId.add(testwoli.id);

		Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_CreateWorkOrderLineItemsTest());
        test.startTest();
        SBR_3_0_API_CreateWorkOrderLineItems.WorkOrderRMCallout(woliListId);
        test.stopTest();

		WorkOrderLineItem woliUpdated = [Select id,SF_PS_RM_Labor_Line_Item_Number__c, SF_PS_RM_External_Id__c from WorkOrderLineItem where id =: testwoli.id limit 1 ][0];
		System.assertEquals('9999', woliUpdated.SF_PS_RM_Labor_Line_Item_Number__c, 'Updaet was not succcessfull');
    }
    
    @isTest
    static void createWoliTravelTest(){	
        insert new Bypass_Settings__c(SetupOwnerId=UserInfo.getUserId(), Bypass_Flow__c=true);
        Credential__c cred = SBR_3_0_TestDataFactory.createCredentials(1, false)[0];
        cred.Name = 'Mule_Token_Endpoint';
        cred.Key_Id__c = 'testKey123';
        cred.Secret__c = 'secret';
        insert cred;
        SUCCESS = true;
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
        WorkOrderLineItem testwoli =  SBR_3_0_ServiceTestDataFactory.createWoli(false,testWO.id,testSR.id);
        testwoli.SF_PS_Labor_Code__c = '9000';
        testwoli.SF_PS_Hourly_Internal_Rate__c = 1.0;
        testwoli.Duration = 1.0;
        testwoli.SF_PS_Line_Type__c = 'MC';
        testwoli.SF_PS_RM_External_Id__c = '';
        testwoli.SF_PS_RM_Labor_Line_Item_Number__c = '9999';
        insert testwoli;
        list<String> woliListId = new List<string>();
        woliListId.add(testwoli.id);
		Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_CreateWorkOrderLineItemsTest());
        test.startTest();
        SBR_3_0_API_CreateWorkOrderLineItems.WorkOrderRMCallout(woliListId);
        test.stopTest();
		
        WorkOrderLineItem woliUpdated = [Select id,SF_PS_RM_Labor_Line_Item_Number__c, SF_PS_RM_External_Id__c from WorkOrderLineItem where id =: testwoli.id limit 1 ][0];
		System.assertEquals('9999', woliUpdated.SF_PS_RM_Labor_Line_Item_Number__c, 'Updaet was not succcessfull');
  
    }

    @isTest
    static void createWoliTestFail(){	
        insert new Bypass_Settings__c(SetupOwnerId=UserInfo.getUserId(), Bypass_Flow__c=true);
        Credential__c cred = SBR_3_0_TestDataFactory.createCredentials(1, false)[0];
        cred.Name = 'Mule_Token_Endpoint';
        cred.Key_Id__c = 'testKey123';
        cred.Secret__c = 'secret';
        insert cred;
        SUCCESS = false;
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
        WorkOrderLineItem testwoli =  SBR_3_0_ServiceTestDataFactory.createWoli(false,testWO.id,testSR.id);
        testwoli.SF_PS_Labor_Code__c = '9000';
        testwoli.SF_PS_Hourly_Internal_Rate__c = 1.0;
        testwoli.Duration = 1.0;
        insert testwoli;
        list<String> woliListId = new List<string>();
        woliListId.add(testwoli.id);
		Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_CreateWorkOrderLineItemsTest());
        test.startTest();
        SBR_3_0_API_CreateWorkOrderLineItems.WorkOrderRMCallout(woliListId);
        test.stopTest();
    }

}