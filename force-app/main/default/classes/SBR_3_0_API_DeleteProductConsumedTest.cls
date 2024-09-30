/*********************************************************************************************************************
* Apex Class: SBR_3_0_API_DeleteProductConsumedTest
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Class to test(SBR_3_0_API_DeleteProductConsumed) the REST end point for Outbound for the Deletion of Product Consumed.
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Mayank Jain          2023-04-07             Initial version   
    2.0         Mayank Jain        	 2023-10-10             Updated code for the code cverage
	3.0			Chinmay Bhatkal		 2024-06-14				ProductItem.SM_PS_ProductItem_Id__c is a required field, Updated Code Coverage
*********************************************************************************************************************/
@isTest
public with sharing class SBR_3_0_API_DeleteProductConsumedTest implements HttpCalloutMock {
	private static boolean SUCCESS = true;

    public HTTPResponse respond(HTTPRequest req) {
        HTTPResponse res=new HTTPResponse();
        res.setHeader('Content-Type',SBR_3_0_Constants.APP_JSON);
        if(req.getEndpoint().endsWithIgnoreCase('token')){
            res.setBody('{"access_token":"test"}');
            res.setStatusCode(200);
        }else if(req.getEndpoint().contains('parts') && SUCCESS){
            res.setBody(		'{'+
            '  "workOrderNumber": 86684649,'+
            '  "mode": "U",'+
            '  "message": "Work Order processed successfully",'+
            '  "workOrderLineItems": []'+
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
        SUCCESS = true;
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
        
        Pricebook2 priceBook = new Pricebook2(
             Id = Test.getStandardPricebookId(),
             IsActive = true
         );
         update priceBook;

        Schema.Location loc = new Schema.Location(Name = 'TestLoc', Company_Code__c = '01', Branch_Location_Number__c = '1234', IsInventoryLocation = true );
        insert loc;

        Product2 pd = new Product2(name='TestProduct', CurrencyIsoCode='USD' , Stock_class__c = 'MISC',Product_SKU__c = '10870996');
        insert pd;

        ProductItem pi = new ProductItem();
        pi.Product2Id = pd.Id;
        pi.QuantityOnHand = 1;
        pi.LocationId = loc.Id;
        pi.CurrencyIsoCode='USD';
        pi.SM_PS_ProductItem_Id__c=pd.Id;
        insert pi; 



        //ProductConsumed pc =  SBR_3_0_ServiceTestDataFactory.createProductConsumedRecord(false ,testWO.id, '1231231');
        ProductConsumed pc = new ProductConsumed();
        pc.WorkOrderId = testWO.id;
        pc.SF_PS_RM_External_Id__c = '1231231';
        pc.ProductItemId = pi.Id;
        pc.QuantityConsumed = 1;
        pc.SF_PS_Parts_Line_Num__c = '123';
        //pc.SF_PS_Stock_Class__c = 'MISC';
        pc.SF_PS_Quantity__c = 1;
        pc.SF_PS_Selling_Price__c = 10;
        pc.SF_PS_Labor_Code__c = '9000';
        pc.SF_PS_Cost_Price__c = 15;
        pc.SF_PS_Line_Level_Comment__c = 'Test User';
        insert pc;
              

        //WorkOrderLineItem testwoli =  SBR_3_0_ServiceTestDataFactory.createWoli(false,testWO.id,testSR.id);
        //testwoli.SF_PS_Labor_Code__c = '9000';
        //testwoli.SF_PS_Hourly_Internal_Rate__c = 1.0;
        //testwoli.Duration = 1.0;
        //insert testwoli;
        //system.debug('testwoli is '+ testwoli);

        list<String> pcListId = new List<string>();
        pcListId.add(pc.id);
		Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_DeleteProductConsumedTest());
        test.startTest();
        SBR_3_0_API_DeleteProductConsumed.DeletePcRMCallout(pcListId);
        test.stopTest();
    }
	
    @isTest
    static void createWoliTestFail(){	
        SUCCESS=FALSE;
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
 
         User testOwnerUsers = [Select Id,Name from User where UserName LIKE 'ownerTestUser%' ];
 
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

        Product2 pd = new Product2(name='TestProduct', CurrencyIsoCode='USD' , Stock_class__c = 'MISC',Product_SKU__c = '10870996');
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
        pc.SF_PS_RM_External_Id__c = '1231231';
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
		Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_DeleteProductConsumedTest());
        test.startTest();
        SBR_3_0_API_DeleteProductConsumed.DeletePcRMCallout(pcListId);
        test.stopTest();
    }
}