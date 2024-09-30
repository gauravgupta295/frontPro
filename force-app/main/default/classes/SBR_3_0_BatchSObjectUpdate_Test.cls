/*********************************************************************************************************************
* Apex Class: SBR_3_0_BatchSObjectUpdate_Test
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Test class for SBR_3_0_BatchSObjectUpdate
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Gopal Raj            2024-06-26             Initial version    
*********************************************************************************************************************/
@IsTest
public class SBR_3_0_BatchSObjectUpdate_Test  {
    static Boolean SUCCESS;
  
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
        
        //Get Owner User 
        User testOwnerUsers = [Select Id,Name from User where UserName LIKE 'ownerTestUser%' ];
        
        //  Create Work Order 
        
        workOrder testWO = SBR_3_0_ServiceTestDataFactory.createWorkOrder(false);
        testWO.AccountId = testAcc.id;
        testWO.OwnerId = testOwnerUsers.id;
        testWO.AssetId = testAsrt.id;
        testWO.ServiceTerritoryId  = testST.id;
        testWO.SF_PS_Expense_To_Location__c = testE2Loc.id;
        testWO.SF_PS_Sales_Rep__c = testSlaesRep.id;
        testWO.SF_PS_Service_Resource__c = testSR.id;
        insert testWO;
        
        WorkOrderLineItem testwoli =  SBR_3_0_ServiceTestDataFactory.createWoli(false,testWO.id,testSR.id);
        testwoli.SF_PS_Labor_Code__c = '9000';
        testwoli.SF_PS_Hourly_Internal_Rate__c = 1.0;
        testwoli.Duration = 1.0;
        insert testwoli;
        
        list<String> woliListId = new List<string>();
        woliListId.add(testwoli.id);
        
        test.startTest();
        String sObjectName = 'WorkOrderLineItem';
        Map<String,Object> nameValues = new Map<String,Object>();
        nameValues.put('SF_PS_Labor_Code__c', testwoli.SF_PS_Labor_Code__c);
        String whereClause = 'SF_PS_Labor_Code__c = \'' + testwoli.SF_PS_Labor_Code__c + '\'';
        
        Conversion_Log__c cLog = new Conversion_Log__c();
        cLog.Error_Message__c = 'tes';
        cLog.New_Value__c='new';
        clog.Old_Value__c='old';
        clog.Type__c='type';
        insert cLog;
        
        Product2 prod2 = new Product2();
        prod2.Name = 'Test Product 2';
        prod2.Product_Type__c = 'Cat-Class';
        prod2.Product_SKU__c = '123877';
        prod2.Category__c = '32234';
        prod2.Class__c = '2049';
        prod2.ToolFlex__c = 'N';
        insert prod2;
        
        List<PricebookEntry> pbEntry = new List<PricebookEntry>();
        PricebookEntry stdPbe = new PricebookEntry();
        stdPbe.Product2Id = prod2.Id;
        stdPbe.Pricebook2Id = Test.getStandardPricebookId();
        stdPbe.IsActive = true;
        stdPbe.UnitPrice = 1020;
        stdPbe.CurrencyIsoCode = 'USD';
        pbEntry.add(stdPbe);
        insert pbEntry;
        
        SBR_3_0_BatchSObjectUpdate obj = new SBR_3_0_BatchSObjectUpdate(sObjectName,nameValues,whereClause,cLog,pbEntry,new List<String>{'SBR_3_0_OrderItemTriggerHandler'});
        Id batchJobId = Database.executeBatch(obj,20);
        
        test.stopTest();
        
    }
    
}