/*********************************************************************************************************************
* Apex Class: SBR_3_0_API_CreateProductConsumedTest
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Test and Mock ProductConsume (Parts) and mimic SF to Rentalman (via Mulesoft) when it is created in Salesforce
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
1.0             Mayank Jain          	-------             Initial version
2.0				Mayank Jain 			---------			Updated Functionality 
3.0				Mayank Jain				11-Jan-2024			Bulkified Product Consumed
*********************************************************************************************************************/

@isTest
public with sharing class SBR_3_0_API_CreateProductConsumedTest implements HttpCalloutMock {
    
    private static Boolean SUCCESS;
    
    public HTTPResponse respond(HTTPRequest req) {
		HTTPResponse res=new HTTPResponse();
        res.setHeader('Content-Type',SBR_3_0_Constants.APP_JSON);
        if(req.getEndpoint().endsWithIgnoreCase('token')){
            res.setBody('{"access_token":"test"}');
            res.setStatusCode(200);
        }else if(req.getEndpoint().endsWithIgnoreCase('parts') && SUCCESS ){
			res.setBody('{ "workOrderNumber": 86684649, "mode": "U", "message": "Work Order processed successfully",' +
						'"workOrderLineItems":[{"workOrderLineItemNumber": 123 ,"uniqueId": 1231231}]}');
            res.setStatusCode(200);
        }else {
            res.setBody('{"errors": {"ind": true,"code": "WOCRTT2000","text": "Invalid claim type entered. Valid types are N, D, M, or S..",'+
						'"reference": "1496"}}');
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
    static void createPcTest(){	
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
         testWO.SF_PS_Service_Resource__c = testSR.id;
         insert testWO;
 
         List<workOrder> wotest1 = [
             SELECT ID 
             FROM workOrder 
             WHERE id =: testWO.id LIMIT 1];
        Pricebook2 priceBook = new Pricebook2(
             Id = Test.getStandardPricebookId(),
             IsActive = true
         );
         update priceBook;

        Schema.Location loc = new Schema.Location(Name = 'TestLoc', Company_Code__c = '01', Branch_Location_Number__c = '1234', IsInventoryLocation = true );
        insert loc;

         Product2 pd = new Product2(name='TestProduct', CurrencyIsoCode='USD' , Stock_class__c = 'MISC',Product_SKU__c = '10870996',QuantityUnitOfMeasure = 'EA');
         insert pd;

         
         ProductItem pi = new ProductItem();
         pi.Product2Id = pd.Id;
         pi.QuantityOnHand = 1;
         pi.LocationId = loc.Id;
         pi.CurrencyIsoCode='USD';
         pi.SM_PS_ProductItem_Id__c=pd.Id;
         insert pi; 

        ProductConsumed pc = new ProductConsumed();
        pc.WorkOrderId = testWO.id;
        pc.SF_PS_RM_External_Id__c = '';
        pc.ProductItemId = pi.Id;
        pc.QuantityConsumed = 1;
        pc.SF_PS_Parts_Line_Num__c = '123';
        pc.SF_PS_Quantity__c = 1;
        pc.SF_PS_Selling_Price__c = 10;
        pc.SF_PS_Labor_Code__c = '9000';
        pc.SF_PS_Cost_Price__c = 15;
        pc.SF_PS_Line_Level_Comment__c = 'Test User';
        pc.SF_PS_Discount_Percentage__c = 0;
        pc.SF_PS_Orig_Selling_Price__c = 10;
        insert pc;

        

        list<String> pcListId = new List<string>();
        pcListId.add(pc.id);
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_CreateProductConsumedTest());
        SBR_3_0_API_CreateProductConsumed.ProductConsumedCreateRMCallout(pcListId);
        test.stopTest();
		ProductConsumed pcUpdated = [Select id,SF_PS_RM_External_Id__c, SF_PS_Parts_Line_Num__c from ProductConsumed where id =: pc.id limit 1 ][0];
		System.assertEquals('123', pcUpdated.SF_PS_Parts_Line_Num__c, 'Updaet was not succcessfull');
    }
    
    @isTest
    static void createPcTestFail(){	
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
         testWO.SF_PS_Service_Resource__c = testSR.id;
         insert testWO;
 
         List<workOrder> wotest1 = [
             SELECT ID 
             FROM workOrder 
             WHERE id =: testWO.id LIMIT 1];
        Pricebook2 priceBook = new Pricebook2(
             Id = Test.getStandardPricebookId(),
             IsActive = true
         );
         update priceBook;

        Schema.Location loc = new Schema.Location(Name = 'TestLoc', Company_Code__c = '01', Branch_Location_Number__c = '1234', IsInventoryLocation = true );
        insert loc;

         Product2 pd = new Product2(name='TestProduct', CurrencyIsoCode='USD' , Stock_class__c = 'MISC',Product_SKU__c = '10870996',QuantityUnitOfMeasure = 'EA');
         insert pd;

         
         ProductItem pi = new ProductItem();
         pi.Product2Id = pd.Id;
         pi.QuantityOnHand = 1;
         pi.LocationId = loc.Id;
         pi.CurrencyIsoCode='USD';
         pi.SM_PS_ProductItem_Id__c=pd.Id;
         insert pi; 

        ProductConsumed pc = new ProductConsumed();
        pc.WorkOrderId = testWO.id;
        //pc.SF_PS_RM_External_Id__c = '1231231';
        pc.ProductItemId = pi.Id;
        pc.QuantityConsumed = 1;
        pc.SF_PS_Parts_Line_Num__c = '123';
        pc.SF_PS_Quantity__c = 1;
        pc.SF_PS_Selling_Price__c = 10;
        pc.SF_PS_Labor_Code__c = '9000';
        pc.SF_PS_Cost_Price__c = 15;
        pc.SF_PS_Line_Level_Comment__c = 'Test User';
        insert pc;

        list<String> pcListId = new List<string>();
        pcListId.add(pc.id);
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_CreateProductConsumedTest());
        SBR_3_0_API_CreateProductConsumed.ProductConsumedCreateRMCallout(pcListId);
        test.stopTest();
    }
   
}