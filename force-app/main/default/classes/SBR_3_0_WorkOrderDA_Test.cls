/*********************************************************************************************************************
* Apex Class: SBR_3_0_WorkOrderDA_Test 
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Test class for SBR_3_0_WorkOrderDA
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION       DATE               DETAIL FEATURES
1.0          2023-02-23          Initial version
2.0			 2023-06-12			 Mayank Jain
3.0          2024-06-10			 Pankaj Meshram
**********************************************************************************************************************************************/

@isTest
public class SBR_3_0_WorkOrderDA_Test implements HttpCalloutMock {
    
    public HTTPResponse respond(HTTPRequest req) {
        HTTPResponse res=new HTTPResponse();
        res.setHeader('Content-Type',SBR_3_0_Constants.APP_JSON);
        if(req.getEndpoint().endsWithIgnoreCase('token')){
            res.setBody('{"access_token":"test"}');
            res.setStatusCode(200);
        }else if(req.getEndpoint().endsWithIgnoreCase('insideLabor')){
            res.setBody(		'{'+
                        '  "workOrderNumber": 86684649,'+
                        '  "mode": "U",'+
                        '  "message": "Work Order processed successfully",'+
                        '  "workOrderLineItems": [ { "rmLineNumber": 9999, "rmUniqueId": 12345678911, "referenceLineNumber": "" } ]'+
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
        
        insert new Bypass_Settings__c(SetupOwnerId=UserInfo.getUserId(), Bypass_Flow__c=true);
        Credential__c cred = SBR_3_0_TestDataFactory.createCredentials(1, false)[0];
        cred.Name = 'Mule_Token_Endpoint';
        cred.Key_Id__c = 'testKey123';
        cred.Secret__c = 'secret';
        insert cred;
        
        // //Create User
        // User testSRUser =  SBR_3_0_ServiceTestDataFactory.createServiceResourceUser(true,'1234','78923');
        // System.debug('testSRUser --- ' + testSRUser);
        
        // Perform DML operations on setup objects within System.runAs()
        System.runAs(new User(Id = UserInfo.getUserId())) {
            //Create User
            User testSRUser =  SBR_3_0_ServiceTestDataFactory.createServiceResourceUser(true,'1234','78923');
            System.debug('testSRUser --- ' + testSRUser);
            
            // Create Sales rep User 
            User TestSalesRep = SBR_3_0_ServiceTestDataFactory.createSalesRepUser(true,'111222');
            
            //Create Owner User 
            //Create Owner
            User TestOwnerUser = SBR_3_0_ServiceTestDataFactory.createOwnerUser(true, '1234','7777');
            
        }
        
        //Create Service Resource 
        ServiceResource testSR = SBR_3_0_ServiceTestDataFactory.create_Service_Resource(False);
        User testUser = [Select Id,Name from User where UserName LIKE 'SRTestUser%' ];
        testSR.ResourceType = 'T';
        testSR.RelatedRecordId = testUser.Id;
        insert testSR;
        //Create assert 
        Asset testAsrt =  SBR_3_0_ServiceTestDataFactory.createAsset(true);
        
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
        AssociatedLocation testAssloc =  SBR_3_0_ServiceTestDataFactory.createAssLOC(true,'12345678901234567890');
        List<AssociatedLocation> assloc1 = [
            SELECT ID,Job_Number__c
            FROM AssociatedLocation 
            WHERE id =: testAssloc.id LIMIT 1];
        system.debug('Asssociated Location Id'+ assloc1[0] +' --' );
        
        
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
        testWO.SF_PS_Job_Site__c =testAssloc.id;
        testWO.SF_PS_Service_Resource__c = testSR.id;
        insert testWO;
        
        List<workOrder> wotest1 = [
            SELECT ID 
            FROM workOrder 
            WHERE id =: testWO.id LIMIT 1];
        system.debug('workorder isss  1 test'+ wotest1[0] +' --' );
        
        Pricebook2 priceBook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update priceBook;
        
        Schema.Location loc = new Schema.Location(Name = 'TestLoc', Company_Code__c = '01', Branch_Location_Number__c = '1234', IsInventoryLocation = true );
        insert loc;
        
        system.debug('Loc is ' + loc );
        
        
        Product2 pd = new Product2(name='TestProduct', CurrencyIsoCode='USD' , Stock_class__c = 'MISC',Product_SKU__c = '10870996');
        insert pd;
        
        system.debug('pd is ' + pd );
        
        ProductItem pi = new ProductItem();
        pi.Product2Id = pd.Id;
        pi.QuantityOnHand = 1;
        pi.LocationId = loc.Id;
        pi.CurrencyIsoCode='USD';
        pi.SM_PS_ProductItem_Id__c = pd.Id; 
        insert pi; 
        
        system.debug('pi is ' + pi );
        
        
        WorkOrderLineItem testwoli =  SBR_3_0_ServiceTestDataFactory.createWoli(false,testWO.id,testSR.id);
        testwoli.SF_PS_Labor_Code__c = '9000';
        testwoli.SF_PS_Hourly_Internal_Rate__c = 1.0;
        testwoli.Duration = 1.0;
        insert testwoli;
        
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
        
        
        system.debug('workorder ProductConsumed '+ pc +' --' );
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_CreateWorkOrderLineItemsTest());
        
        SF_PS_Quoted_Part__c qp=new SF_PS_Quoted_Part__c();
        qp.SF_PS_WorkOrderId__c=testWO.id;
        qp.SF_PS_RM_External_Id__c='123321';
        // qp.sf QuantityConsumed = 1;
        qp.SF_PS_Quoted_Parts_Line_Num__c = '123';
        qp.SF_PS_Quantity__c = 1;
        qp.SF_PS_Selling_Price__c = 10;
        qp.SF_PS_Labor_Code__c = '9000';
        qp.SF_PS_Cost_Price__c = 15;
        qp.SF_PS_Line_Level_Comment__c = 'Test User';
        insert qp;
        
        Quote_Line_Item__c testqli= SBR_3_0_ServiceTestDataFactory.createqli(false,testWO.id,testSR.id);
        testqli.SF_PS_Labor_Code__c = '9000';
        testqli.SF_PS_Hourly_Internal_Rate__c = 1.0;
        testqli.SF_PS_Duration__c = 1.0;
        testqli.SF_PS_Line_Type__c ='LI ';
        testqli.SF_PS_Bypass_flow__c = true;
        insert testqli;
        
        
    }
    
    @isTest
    static void testGetWorkOrders(){
        
        WorkOrder wo =[SELECT Id , SF_PS_RM_WO_Number__c FROM WorkOrder where SF_PS_RM_WO_Number__c =  '01-33322' LIMIT 1]; 
        Set<String> woSet = new Set<String>{ wo.Id };
            Test.startTest();
        
        PermissionSetLicense psl = [SELECT Id FROM PermissionSetLicense WHERE DeveloperName = 'SalesforceCPQ_CPQStandardPerm'];
        List<PermissionSetLicenseAssign> pslList =[	Select Id, AssigneeId , Assignee.Name, PermissionSetLicense.DeveloperName  , 
         										PermissionSetLicenseId 
         										from PermissionSetLicenseAssign 
         										where PermissionSetLicense.DeveloperName = 'SalesforceCPQ_CPQStandardPerm' 
         										AND AssigneeId = : UserInfo.getUserId()];
        if (pslList.size()==0){
        insert new PermissionSetLicenseAssign(AssigneeId = UserInfo.getUserId(), PermissionSetLicenseId = psl.Id);
        }
        
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Integration_API_Access'];
        List <PermissionSetAssignment> permSetCheck = [SELECT Id from PermissionSetAssignment WHERE PermissionSetId = : ps.Id
                                                       AND AssigneeId = : UserInfo.getUserId()];
        if (permSetCheck.size()==0){
            insert new PermissionSetAssignment(AssigneeId = UserInfo.getUserId(), PermissionSetId = ps.Id);
        }
        
        List<WorkOrder> retrievedwo = SBR_3_0_WorkOrderDA.getWorkOrders(woSet);
        Test.stopTest();
        
        System.assertEquals(wo.Id, retrievedwo[0].Id, 'A WorkOrder should be retrieved');
    }
    
    @isTest
    static void testgetRelatedAccount(){
        
        WorkOrder wo =[SELECT Id,AccountId, SF_PS_RM_WO_Number__c FROM WorkOrder where SF_PS_RM_WO_Number__c =  '01-33322' LIMIT 1]; 
        Set<String> woSet = new Set<String>{ wo.Id };
            Test.startTest();
        
        PermissionSetLicense psl = [SELECT Id FROM PermissionSetLicense WHERE DeveloperName = 'SalesforceCPQ_CPQStandardPerm'];
        List<PermissionSetLicenseAssign> pslList =[	Select Id, AssigneeId , Assignee.Name, PermissionSetLicense.DeveloperName  , 
         										PermissionSetLicenseId 
         										from PermissionSetLicenseAssign 
         										where PermissionSetLicense.DeveloperName = 'SalesforceCPQ_CPQStandardPerm' 
         										AND AssigneeId = : UserInfo.getUserId()];
        if (pslList.size()==0){
        insert new PermissionSetLicenseAssign(AssigneeId = UserInfo.getUserId(), PermissionSetLicenseId = psl.Id);
        }
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Integration_API_Access'];
        List <PermissionSetAssignment> permSetCheck = [SELECT Id from PermissionSetAssignment WHERE PermissionSetId = : ps.Id
                                                       AND AssigneeId = : UserInfo.getUserId()];
        if (permSetCheck.size()==0){
            insert new PermissionSetAssignment(AssigneeId = UserInfo.getUserId(), PermissionSetId = ps.Id);
        }
        
        List<Account> retrievedAcc = SBR_3_0_WorkOrderDA.getRelatedAccount('01-33333', '01');
        Test.stopTest();
        
        System.assertEquals(retrievedAcc.size() , 1, 'An Account should be retrieved' );
    }
    
    @isTest
    static void testgetUser(){
        
        User testOwnerUsers = [Select Id,Name from User where UserName LIKE 'ownerTestUser%' LIMIT 1 ];
        Test.startTest();
        
        PermissionSetLicense psl = [SELECT Id FROM PermissionSetLicense WHERE DeveloperName = 'SalesforceCPQ_CPQStandardPerm'];
        List<PermissionSetLicenseAssign> pslList =[	Select Id, AssigneeId , Assignee.Name, PermissionSetLicense.DeveloperName  , 
         										PermissionSetLicenseId 
         										from PermissionSetLicenseAssign 
         										where PermissionSetLicense.DeveloperName = 'SalesforceCPQ_CPQStandardPerm' 
         										AND AssigneeId = : UserInfo.getUserId()];
        if (pslList.size()==0){
        insert new PermissionSetLicenseAssign(AssigneeId = UserInfo.getUserId(), PermissionSetLicenseId = psl.Id);
        }
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Integration_API_Access'];
        List <PermissionSetAssignment> permSetCheck = [SELECT Id from PermissionSetAssignment WHERE PermissionSetId = : ps.Id
                                                       AND AssigneeId = : UserInfo.getUserId()];
        if (permSetCheck.size()==0){
            insert new PermissionSetAssignment(AssigneeId = UserInfo.getUserId(), PermissionSetId = ps.Id);
        }
        
        List<User> retrieveduser = SBR_3_0_WorkOrderDA.getUser('1234');
        Test.stopTest();
        
        System.assertEquals(retrieveduser.size() , 1, 'An Account should be retrieved' );
    }
    
    @isTest
    static void testgetrelAsset(){
        
        
        Test.startTest();
        Asset asrt = new Asset();
        asrt.Name = 'testAsrts';
        asrt.SM_PS_Company_Code__c = '01';
        asrt.SM_PS_Equipment_Number__c = '1018880';
        asrt.SM_PS_Asset_Id__c = '01-1018880';
        insert asrt;
        
        List<Asset> retrievdAsset = SBR_3_0_WorkOrderDA.getrelAsset(asrt.SM_PS_Asset_Id__c);
        Test.stopTest();
        
        System.assertEquals(retrievdAsset.size() , 1, 'An Assert should be retrieved' );
    }
    
    @isTest
    static void testgetrelST(){
        
        Test.startTest();
        
        List<ServiceTerritory> retrievedST = SBR_3_0_WorkOrderDA.getrelST('1234' , 'US');
        Test.stopTest();
        
        System.assertEquals(retrievedST.size() , 1, 'An ServiceTerritory should be retrieved' );
    }
    
    @isTest
    static void testgetrelUser(){
        
        Test.startTest();
        
        List<User> retrievedUser = SBR_3_0_WorkOrderDA.getrelUser('111222');
        Test.stopTest();
        
        System.assertEquals(retrievedUser.size() , 1, 'An User should be retrieved' );
    }
    
    @isTest
    static void testgetrelJobSite(){
        
        Test.startTest();
        
        List<AssociatedLocation> retrievedAssociatedLocation = SBR_3_0_WorkOrderDA.getrelJobSite('12345678901234567890');
        Test.stopTest();
        System.assertEquals(retrievedAssociatedLocation.size() , 1, 'An AssociatedLocation should be retrieved' );
    }
    
    @isTest
    static void testgetrelServiceResourceLineItems(){
        
        Test.startTest();
        
        List<ServiceResource> retrievedServiceResource = SBR_3_0_WorkOrderDA.getrelServiceResourceLineItems('78923');
        Test.stopTest();
        System.assertEquals(retrievedServiceResource.size() , 1, 'An ServiceResource should be retrieved' );
    }
    
    @isTest
    static void testgetrelServiceResource(){
        
        Test.startTest();
        
        List<ServiceResource> retrievedServiceResource = SBR_3_0_WorkOrderDA.getrelServiceResource('78923');
        Test.stopTest();
        System.assertEquals(retrievedServiceResource.size() , 1, 'An ServiceResource should be retrieved' );
    }
    //Added lines to cover getrelProdItems method for FRONT- 30844
     @isTest
     static void testgetrelProdItems(){
    
        Test.startTest();
        List<ProductItem> retrievedServiceResource = SBR_3_0_WorkOrderDA.getrelProdItems('10870996','10870996');
       	Test.stopTest();
        //System.assertEquals(retrievedServiceResource.size() , 1, 'An ServiceResource should be retrieved' );
    }
    //End of FRONT-30844
    @isTest
    static void testgetLinesToDelete(){
        
        Set<String> lines = new Set<String>{ '3322123' };
            Test.startTest();
        
        List<WorkOrderLineItem> retrievedServiceResource = SBR_3_0_WorkOrderDA.getLinesToDelete(lines);
        Test.stopTest();
        System.assertEquals(retrievedServiceResource.size() , 1, 'An ServiceResource should be retrieved' );
    }
    
    @isTest
    static void testgetQuoteLinesToDelete(){
        
        Set<String> lines = new Set<String>{ '3322123' };
            Test.startTest();
        
        List<Quote_Line_Item__c> retrievedServiceResource = SBR_3_0_WorkOrderDA.getQuoteLinesToDelete(lines);
        Test.stopTest();
        //System.assertEquals(retrievedServiceResource.size() , 1, 'An ServiceResource should be retrieved' );
    }
    
    @isTest
    static void  testgetWorkOrderLineItems(){
        WorkOrderLineItem woli =[SELECT Id, SF_PS_RM_External_Id__c FROM WorkOrderLineItem where SF_PS_RM_External_Id__c = '3322123' LIMIT 1]; 
        Set<String> woliSet = new Set<String>{ woli.Id };
            Test.startTest();
        
        PermissionSetLicense psl = [SELECT Id FROM PermissionSetLicense WHERE DeveloperName = 'SalesforceCPQ_CPQStandardPerm'];
        List<PermissionSetLicenseAssign> pslList =[	Select Id, AssigneeId , Assignee.Name, PermissionSetLicense.DeveloperName  , 
         										PermissionSetLicenseId 
         										from PermissionSetLicenseAssign 
         										where PermissionSetLicense.DeveloperName = 'SalesforceCPQ_CPQStandardPerm' 
         										AND AssigneeId = : UserInfo.getUserId()];
        if (pslList.size()==0){
        insert new PermissionSetLicenseAssign(AssigneeId = UserInfo.getUserId(), PermissionSetLicenseId = psl.Id);
        }
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Integration_API_Access'];
        List <PermissionSetAssignment> permSetCheck = [SELECT Id from PermissionSetAssignment WHERE PermissionSetId = : ps.Id
                                                       AND AssigneeId = : UserInfo.getUserId()];
        if (permSetCheck.size()==0){
            insert new PermissionSetAssignment(AssigneeId = UserInfo.getUserId(), PermissionSetId = ps.Id);
        }
        
        List<WorkOrderLineItem> retrievedWorkOrderLineItem = SBR_3_0_WorkOrderDA.getWorkOrderLineItems(woliSet);
        Test.stopTest();
        
        System.assertEquals(woli.Id, retrievedWorkOrderLineItem[0].Id, 'A WorkOrder should be retrieved');
    }
    
    @isTest
    static void  testgetgetQuoteLineItems(){
        Quote_Line_Item__c qli =[SELECT Id, SF_PS_RM_External_Id__c FROM Quote_Line_Item__c where SF_PS_RM_External_Id__c = '3322123' LIMIT 1]; 
        Set<String> qliSet = new Set<String>{ qli.Id };
            Test.startTest();
        
        PermissionSetLicense psl = [SELECT Id FROM PermissionSetLicense WHERE DeveloperName = 'SalesforceCPQ_CPQStandardPerm'];
        List<PermissionSetLicenseAssign> pslList =[	Select Id, AssigneeId , Assignee.Name, PermissionSetLicense.DeveloperName  , 
         										PermissionSetLicenseId 
         										from PermissionSetLicenseAssign 
         										where PermissionSetLicense.DeveloperName = 'SalesforceCPQ_CPQStandardPerm' 
         										AND AssigneeId = : UserInfo.getUserId()];
        if (pslList.size()==0){
        insert new PermissionSetLicenseAssign(AssigneeId = UserInfo.getUserId(), PermissionSetLicenseId = psl.Id);
        }
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Integration_API_Access'];
        List <PermissionSetAssignment> permSetCheck = [SELECT Id from PermissionSetAssignment WHERE PermissionSetId = : ps.Id
                                                       AND AssigneeId = : UserInfo.getUserId()];
        if (permSetCheck.size()==0){
            insert new PermissionSetAssignment(AssigneeId = UserInfo.getUserId(), PermissionSetId = ps.Id);
        }
        
        List<Quote_Line_Item__c> retrievedQli = SBR_3_0_WorkOrderDA.getQuoteLineItems(qliSet);
        Test.stopTest();
        
        System.assertEquals(qli.Id, retrievedQli[0].Id, 'A QLI should be retrieved');
    }
    
    @isTest
    static void testgetProductConsumed(){  
        
        ProductConsumed pc =[SELECT Id, SF_PS_RM_External_Id__c FROM ProductConsumed where SF_PS_RM_External_Id__c = '1231231' LIMIT 1 ]; 
        Set<String> pcSet = new Set<String>{ pc.Id };
            Test.startTest();
        
        List<ProductConsumed> retrievedProductConsumed = SBR_3_0_WorkOrderDA.getProductConsumed(pcSet);
        Test.stopTest();
        
        System.assertEquals(pc.Id, retrievedProductConsumed[0].Id, 'A ProductConsumed should be retrieved');
    }
    
    
    @isTest
    static void testgetgetQuotedParts(){
        SF_PS_Quoted_Part__c qp =[SELECT Id, SF_PS_RM_External_Id__c FROM SF_PS_Quoted_Part__c where SF_PS_RM_External_Id__c='123321' LIMIT 1]; 
        Set<String> qpSet = new Set<String>{ qp.Id };
            Test.startTest();
        
        PermissionSetLicense psl = [SELECT Id FROM PermissionSetLicense WHERE DeveloperName = 'SalesforceCPQ_CPQStandardPerm'];
        List<PermissionSetLicenseAssign> pslList =[	Select Id, AssigneeId , Assignee.Name, PermissionSetLicense.DeveloperName  , 
         										PermissionSetLicenseId 
         										from PermissionSetLicenseAssign 
         										where PermissionSetLicense.DeveloperName = 'SalesforceCPQ_CPQStandardPerm' 
         										AND AssigneeId = : UserInfo.getUserId()];
        if (pslList.size()==0){
        insert new PermissionSetLicenseAssign(AssigneeId = UserInfo.getUserId(), PermissionSetLicenseId = psl.Id);
        }
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Integration_API_Access'];
        List <PermissionSetAssignment> permSetCheck = [SELECT Id from PermissionSetAssignment WHERE PermissionSetId = : ps.Id
                                                       AND AssigneeId = : UserInfo.getUserId()];
        if (permSetCheck.size()==0){
            insert new PermissionSetAssignment(AssigneeId = UserInfo.getUserId(), PermissionSetId = ps.Id);
        }
        
        List<SF_PS_Quoted_Part__c> retrievedqp = SBR_3_0_WorkOrderDA.getQuotedParts(qpSet);
        Test.stopTest();
        
        System.assertEquals(qp.Id, retrievedqp[0].Id, 'A QP should be retrieved');
    }
    
    @isTest
    static void testGetRecordType(){
        
        Test.startTest();
        
        List<RecordType> getRecType = SBR_3_0_WorkOrderDA.getWorkOrderRecordType('SF_PS_Inspection_Record','WorkOrder');
        Test.stopTest();
        System.assertEquals(getRecType.size() , 1, 'An ServiceTerritory should be retrieved' );
    }
    @isTest
    static void testGetrelProd(){
        
        Test.startTest();
        
        List<Product2> getRecType = SBR_3_0_WorkOrderDA.getrelProd('12345');
        Test.stopTest();
        //System.assertEquals(getRecType.size() , 0, 'An ServiceTerritory should be retrieved' );
    }
    
    //Added lines to cover getrelProdConsumedToWO & getrelQuotedPartsToWO methods for FRONT- 30844
    @isTest
    static void getrelProdConsumedToWOTest(){
        List<workOrder> wotest1 = [SELECT ID FROM workOrder LIMIT 1];
        String woId = wotest1[0].Id;
        SBR_3_0_WorkOrderDA.getrelProdConsumedToWO(woId);
    }
    
    @isTest
    static void getrelQuotedPartsToWOTest(){
        List<workOrder> wotest1 = [SELECT ID FROM workOrder LIMIT 1];
        String woId = wotest1[0].Id;
        SBR_3_0_WorkOrderDA.getrelQuotedPartsToWO(woId);
    }
    
    @isTest
    static void getCreditLinesToDeleteTest(){
        List<workOrder> wotest1 = [SELECT ID FROM workOrder LIMIT 1];
        String woId = wotest1[0].Id;
        SF_PS_Credit_Line_Item__c cli = new SF_PS_Credit_Line_Item__c(SF_PS_RM_External_Id__c='123',WorkOrderId__c=woId);
		insert cli;
        Set<String> lines = new Set<String>();
        lines.add(cli.SF_PS_RM_External_Id__c);
        SBR_3_0_WorkOrderDA.getCreditLinesToDelete(lines);
    }
    //End of FRONT- 30844
}