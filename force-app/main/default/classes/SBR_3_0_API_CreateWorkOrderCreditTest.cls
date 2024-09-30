/*********************************************************************************************************************
* Apex Class: SBR_3_0_API_CreateWorkOrderCreditTest
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Test Class for Creating, Updating and Deleting Work Order Quote
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
1.0             Mayank Jain         2023-12-28             Initial version
*********************************************************************************************************************/

@isTest
public class SBR_3_0_API_CreateWorkOrderCreditTest Implements HttpCalloutMock {
    static Boolean SUCCESS;
    
    static HttpResponse res;
    
    @TestSetup
    static void makeData(){
        
        User testSRUser =  SBR_3_0_ServiceTestDataFactory.createServiceResourceUser(true,'1234','78923');
        System.debug('testSRUser --- ' + testSRUser);
        
        // Create Sales rep User 
        User TestSalesRep = SBR_3_0_ServiceTestDataFactory.createSalesRepUser(true,'111222');
        
        //Create Owner User 
        //Create Owner
        User TestOwnerUser = SBR_3_0_ServiceTestDataFactory.createOwnerUser(true, '1234','7777');
        
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
            res.setStatusCode(400);
        }else {
            res.setBody('{ "error": { "message": "Invalid input parameters, parameters might contain special characters, SQL statements or script statements. Please check application logs for more information.", "errorKey": "BAD_REQUEST", "errorCode": "400-000" } }');
            res.setStatusCode(400);
        }
        return res;
    }
    @isTest
    static void testCreateWorkOrderSuccess() {
        //Get Custom setting 
        insert new Bypass_Settings__c(SetupOwnerId=UserInfo.getUserId(), Bypass_Flow__c=true);
        
        Credential__c cred = SBR_3_0_TestDataFactory.createCredentials(1, false)[0];
        cred.Name = 'Mule_Token_Endpoint';
        cred.Key_Id__c = 'testKey123';
        cred.Secret__c = 'secret';
        insert cred;
	
        SBR_3_0_API_CreateWorkOrderCreditTest.SUCCESS = true;
        
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
        
        List<workOrder> wotest1 = [
            SELECT ID 
            FROM workOrder 
            WHERE id =: testWO.id LIMIT 1];
        system.debug('workorder isss  1 test'+ wotest1[0] +' --' );
        
        
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_CreateWorkOrderCreditTest());
        WorkOrder wo = [SELECT Id FROM WorkOrder limit 1];
        List<String> input = new List<String> ();
        input.add(wo.Id);
        
        // Set the required fields for the Work Order Line Item
        SF_PS_Credit_Line_Item__c  newCreditLineItem = new SF_PS_Credit_Line_Item__c();
        newCreditLineItem.WorkOrderId__c = wo.id; // Assign the Work Order Id
        newCreditLineItem.SF_PS_Hr_Mi_To_Credit__c = 2;
        newCreditLineItem.SF_PS_Vendor_PO_Num__c= '456636';
        newCreditLineItem.SF_PS_PO_Cost__c= 4;
        newCreditLineItem.SF_PS_Outside_Labor_Des__c = 'TestClass Test';
        newCreditLineItem.SF_PS_Credit_Rate_Hr_Mi__c = 2.0;
        newCreditLineItem.SF_PS_Line_Type__c = 'LI';
        
        insert newCreditLineItem;
        
        SF_PS_Credit_Line_Item__c  newCreditLineItemOutside = new SF_PS_Credit_Line_Item__c();
        newCreditLineItemOutside.WorkOrderId__c = wo.id; // Assign the Work Order Id
        newCreditLineItemOutside.SF_PS_Hr_Mi_To_Credit__c = 2;
        newCreditLineItemOutside.SF_PS_Vendor_PO_Num__c= '456637';
        newCreditLineItemOutside.SF_PS_PO_Cost__c= 4;
        newCreditLineItemOutside.SF_PS_Outside_Labor_Des__c = 'TestClass Test';
        newCreditLineItemOutside.SF_PS_Credit_Rate_Hr_Mi__c = 2.0;
        newCreditLineItemOutside.SF_PS_Line_Type__c = 'LO';
        
        insert newCreditLineItemOutside;
        
        
        SF_PS_Credit_Line_Item__c  newCreditLineItemMilage = new SF_PS_Credit_Line_Item__c();
        newCreditLineItemMilage.WorkOrderId__c = wo.id; // Assign the Work Order Id
        newCreditLineItemMilage.SF_PS_Hr_Mi_To_Credit__c = 2;
        newCreditLineItemMilage.SF_PS_Vendor_PO_Num__c= '456638';
        newCreditLineItemMilage.SF_PS_PO_Cost__c= 4;
        newCreditLineItemMilage.SF_PS_Outside_Labor_Des__c = 'TestClass Test';
        newCreditLineItemMilage.SF_PS_Credit_Rate_Hr_Mi__c = 2.0;
        newCreditLineItem.SF_PS_Line_Type__c = 'MC';
        
        insert newCreditLineItemMilage;
        
        SF_PS_Credited_Part__c cliPart = new SF_PS_Credited_Part__c();
        cliPart.SF_PS_Work_Order__c  = wo.Id;
        //cliPart.itemNumber = cp.SF_PS_Product__r.Item_Number__c;
        //cliPart.SF_PS_Stock_Class__c = cp.SF_PS_Stock_Class__c;
        cliPart.SF_PS_Parts_To_Credit__c = 2.0;
        //cliPart.unitOfMeasure = cp.SF_PS_Product__r.QuantityUnitOfMeasure;
        //cliPart.sellingPrice = cp.SF_PS_Selling_Price__c == null ? 0.0 : (cp.SF_PS_Selling_Price__c).setScale(2) ;
        //cliPart.laborCode = cp.SF_PS_Labor_Code__c== null ? 0 :Integer.valueOf(cp.SF_PS_Labor_Code__c);
        //cliPart.cost = cp.SF_PS_Cost_Price__c == null ? 0.0 : (cp.SF_PS_Cost_Price__c).setScale(2);
        cliPart.SF_PS_Line_Level_Comment__c = 'TestCalss Test';
        insert cliPart;
        
        
        Test.startTest();
        //SBR_3_0_API_CreateWorkOrder testCreate = new SBR_3_0_API_CreateWorkOrder();
        SBR_3_0_API_CreateWorkOrderCredit.CreateWorkOrderRMCallout(input);
        Test.stopTest();
        
        WorkOrder newWO = [SELECT SF_PS_RM_WO_Number__c FROM WorkOrder];
        System.assertEquals('01-33322', newWO.SF_PS_RM_WO_Number__c);
    }

	@isTest
    static void testCreateWorkOrderFail() {
        //Get Custom setting 
        insert new Bypass_Settings__c(SetupOwnerId=UserInfo.getUserId(), Bypass_Flow__c=true);
        
        Credential__c cred = SBR_3_0_TestDataFactory.createCredentials(1, false)[0];
        cred.Name = 'Mule_Token_Endpoint';
        cred.Key_Id__c = 'testKey123';
        cred.Secret__c = 'secret';
        insert cred;
	
        SBR_3_0_API_CreateWorkOrderCreditTest.SUCCESS = false;
        
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
        
        List<workOrder> wotest1 = [
            SELECT ID 
            FROM workOrder 
            WHERE id =: testWO.id LIMIT 1];
        system.debug('workorder isss  1 test'+ wotest1[0] +' --' );
        
        
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_CreateWorkOrderCreditTest());
        WorkOrder wo = [SELECT Id FROM WorkOrder limit 1];
        List<String> input = new List<String> ();
        input.add(wo.Id);
        
        // Set the required fields for the Work Order Line Item
        SF_PS_Credit_Line_Item__c  newCreditLineItem = new SF_PS_Credit_Line_Item__c();
        newCreditLineItem.WorkOrderId__c = wo.id; // Assign the Work Order Id
        newCreditLineItem.SF_PS_Hr_Mi_To_Credit__c = 2;
        newCreditLineItem.SF_PS_Vendor_PO_Num__c= '456636';
        newCreditLineItem.SF_PS_PO_Cost__c= 4;
        newCreditLineItem.SF_PS_Outside_Labor_Des__c = 'TestClass Test';
        newCreditLineItem.SF_PS_Credit_Rate_Hr_Mi__c = 2.0;
        newCreditLineItem.SF_PS_Line_Type__c = 'LI';
        
        insert newCreditLineItem;
        
        SF_PS_Credit_Line_Item__c  newCreditLineItemOutside = new SF_PS_Credit_Line_Item__c();
        newCreditLineItemOutside.WorkOrderId__c = wo.id; // Assign the Work Order Id
        newCreditLineItemOutside.SF_PS_Hr_Mi_To_Credit__c = 2;
        newCreditLineItemOutside.SF_PS_Vendor_PO_Num__c= '456637';
        newCreditLineItemOutside.SF_PS_PO_Cost__c= 4;
        newCreditLineItemOutside.SF_PS_Outside_Labor_Des__c = 'TestClass Test';
        newCreditLineItemOutside.SF_PS_Credit_Rate_Hr_Mi__c = 2.0;
        newCreditLineItemOutside.SF_PS_Line_Type__c = 'LO';
        
        insert newCreditLineItemOutside;
        
        
        SF_PS_Credit_Line_Item__c  newCreditLineItemMilage = new SF_PS_Credit_Line_Item__c();
        newCreditLineItemMilage.WorkOrderId__c = wo.id; // Assign the Work Order Id
        newCreditLineItemMilage.SF_PS_Hr_Mi_To_Credit__c = 2;
        newCreditLineItemMilage.SF_PS_Vendor_PO_Num__c= '456638';
        newCreditLineItemMilage.SF_PS_PO_Cost__c= 4;
        newCreditLineItemMilage.SF_PS_Outside_Labor_Des__c = 'TestClass Test';
        newCreditLineItemMilage.SF_PS_Credit_Rate_Hr_Mi__c = 2.0;
        newCreditLineItem.SF_PS_Line_Type__c = 'MC';
        
        insert newCreditLineItemMilage;
        
        SF_PS_Credited_Part__c cliPart = new SF_PS_Credited_Part__c();
        cliPart.SF_PS_Work_Order__c  = wo.Id;
        //cliPart.itemNumber = cp.SF_PS_Product__r.Item_Number__c;
        //cliPart.SF_PS_Stock_Class__c = cp.SF_PS_Stock_Class__c;
        cliPart.SF_PS_Parts_To_Credit__c = 2.0;
        //cliPart.unitOfMeasure = cp.SF_PS_Product__r.QuantityUnitOfMeasure;
        //cliPart.sellingPrice = cp.SF_PS_Selling_Price__c == null ? 0.0 : (cp.SF_PS_Selling_Price__c).setScale(2) ;
        //cliPart.laborCode = cp.SF_PS_Labor_Code__c== null ? 0 :Integer.valueOf(cp.SF_PS_Labor_Code__c);
        //cliPart.cost = cp.SF_PS_Cost_Price__c == null ? 0.0 : (cp.SF_PS_Cost_Price__c).setScale(2);
        cliPart.SF_PS_Line_Level_Comment__c = 'TestCalss Test';
        insert cliPart;
        
        
        Test.startTest();
        //SBR_3_0_API_CreateWorkOrder testCreate = new SBR_3_0_API_CreateWorkOrder();
        SBR_3_0_API_CreateWorkOrderCredit.CreateWorkOrderRMCallout(input);
        Test.stopTest();
        
        WorkOrder newWO = [SELECT SF_PS_RM_WO_Number__c FROM WorkOrder];
        System.assertEquals('01-33322', newWO.SF_PS_RM_WO_Number__c);
    }
    
    // Add more test methods for other functionalities if needed
    
}