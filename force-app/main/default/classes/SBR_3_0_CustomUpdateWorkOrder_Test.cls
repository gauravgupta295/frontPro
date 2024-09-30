@isTest
public with sharing class SBR_3_0_CustomUpdateWorkOrder_Test {
    @TestSetup
    static void makeData(){
        
        //Create Test User
        User testUser = SBR_3_0_ServiceTestDataFactory.createServiceResourceEmpNoUser(true,'1234','98765');
        User testAdminUser = SBR_3_0_ServiceTestDataFactory.createSystemAdminUser(true,'8898','987644');
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Integration_API_Access'];
        List <PermissionSetAssignment> permSetCheck = [SELECT Id from PermissionSetAssignment WHERE PermissionSetId = : ps.Id
                                                       AND AssigneeId = : UserInfo.getUserId()];
    }
    //Success Test for the Updation Of the Service Resource from Payload Json
    @isTest
    static void testCustomUpdateWorkOrder(){
        insert new Bypass_Settings__c(SetupOwnerId=UserInfo.getUserId(), Bypass_Flow__c=true);
        
        Credential__c cred = SBR_3_0_TestDataFactory.createCredentials(1, false)[0];
        cred.Name = 'Mule_Token_Endpoint';
        cred.Key_Id__c = 'testKey123';
        cred.Secret__c = 'secret';
        insert cred;
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/WorkOder/ApiUpdateApointment/v1';
        req.httpMethod = 'POST';
        String jsonString  =  '{ "EventType": "1", "Status": "Dispatched", "SF_PS_VDOS_OrderLine_External_Id__c": "vdostestclass1", "SF_PS_VDOS_Dispatch_Type__c": "AU", "SF_PS_RM_WO_Number__c": "1122900",  "SF_PS_Service_Resource__c": "98765", "SF_PS_VDOS_Stop_Id__c": "909090", "SF_PS_Company_Code__c" : "01", "SF_PS_Status_Reasons__c": "" }';
        
        req.requestBody = Blob.valueOf(jsonString);
        
        RestContext.request = req;
        RestContext.response= res;
        User testAdminUser = [Select Id,Name from User where UserName LIKE 'testAdminUser%' ];       
        
        
        Test.startTest();
        FSL.GlobalAPIS.addStatusTransition('Open', 'Scheduled');
        FSL.GlobalAPIS.addStatusTransition('Scheduled', 'Dispatched');
        //create Asset
        Asset testAsrt =  SBR_3_0_ServiceTestDataFactory.createAsset(true);
        
        //Create Exponce to Location
        ServiceTerritory  testE2Loc = SBR_3_0_ServiceTestDataFactory.createServiceTerritory(true);
        
        //Create Service Territory 
        ServiceTerritory  testST = SBR_3_0_ServiceTestDataFactory.createServiceTerritory(true);
        //create work order 
        workorder wo = SBR_3_0_ServiceTestDataFactory.createWorkOrder(false);
        wo.SF_PS_RM_WO_Number__c = '01-1122900';
        wo.SF_PS_Expense_To_Location__c = testE2Loc.id;
        wo.AssetId = testAsrt.id;
        wo.ServiceTerritoryId  = testST.id;
        insert wo;
                
        ServiceAppointment sa = SBR_3_0_ServiceTestDataFactory.createServiceAppointment(true,wo.id);
       
        //create service resource 
        
        ServiceResource testFactorySR = SBR_3_0_ServiceTestDataFactory.create_Service_Resource(False);
        User testUser = [Select Id,Name from User where UserName LIKE 'SRTestUser%' ];
        testFactorySR.RelatedRecordId = testUser.Id;
        testFactorySR.ResourceType = 'T';
        insert testFactorySR;
        
        //ceate Service Territory member 
        ServiceTerritoryMember testSTM =SBR_3_0_ServiceTestDataFactory.createServiceTerritoryMember(true,testFactorySR.id,testST.id);

        SBR_3_0_CustomUpdateWorkOrder co = new SBR_3_0_CustomUpdateWorkOrder(jsonString);
        String returnVal = co.syncWorkOrderToSF();
        Test.stopTest();
        
    }
    @isTest
    static void testCustomUpdateWorkOrder1(){
        insert new Bypass_Settings__c(SetupOwnerId=UserInfo.getUserId(), Bypass_Flow__c=true);
        
        Credential__c cred = SBR_3_0_TestDataFactory.createCredentials(1, false)[0];
        cred.Name = 'Mule_Token_Endpoint';
        cred.Key_Id__c = 'testKey123';
        cred.Secret__c = 'secret';
        insert cred;
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/WorkOder/ApiUpdateApointment/v1';
        req.httpMethod = 'POST';
        String jsonString  =  '{ "EventType": "1", "Status": "Dispatched", "SF_PS_VDOS_OrderLine_External_Id__c": "vdostestclass1", "SF_PS_VDOS_Dispatch_Type__c": "AU", "SF_PS_RM_WO_Number__c": "1122900",  "SF_PS_Service_Resource__c": "98765", "SF_PS_VDOS_Stop_Id__c": "909090", "SF_PS_Company_Code__c" : "01", "SF_PS_Status_Reasons__c": "" }';
        
        req.requestBody = Blob.valueOf(jsonString);
        
        RestContext.request = req;
        RestContext.response= res;
        User testAdminUser = [Select Id,Name from User where UserName LIKE 'testAdminUser%' ];       
        
        
        Test.startTest();
       // FSL.GlobalAPIS.addStatusTransition('Open', 'Scheduled');
      //  FSL.GlobalAPIS.addStatusTransition('Scheduled', 'Dispatched');
        //create Asset
        Asset testAsrt =  SBR_3_0_ServiceTestDataFactory.createAsset(true);
        
        //Create Exponce to Location
        ServiceTerritory  testE2Loc = SBR_3_0_ServiceTestDataFactory.createServiceTerritory(true);
        
        //Create Service Territory 
        ServiceTerritory  testST = SBR_3_0_ServiceTestDataFactory.createServiceTerritory(true);
        //create work order 
        workorder wo = SBR_3_0_ServiceTestDataFactory.createWorkOrder(false);
        wo.SF_PS_RM_WO_Number__c = '01-1122900';
        wo.SF_PS_Expense_To_Location__c = testE2Loc.id;
        wo.AssetId = testAsrt.id;
        wo.ServiceTerritoryId  = testST.id;
        insert wo;
        
        workorder wo1 = SBR_3_0_ServiceTestDataFactory.createWorkOrder(false);
        wo1.SF_PS_RM_WO_Number__c = '01-1132900';
        wo1.SF_PS_Expense_To_Location__c = testE2Loc.id;
        wo1.AssetId = testAsrt.id;
        wo1.ServiceTerritoryId  = testST.id;
        insert wo1;
                
        ServiceAppointment sa = SBR_3_0_ServiceTestDataFactory.createServiceAppointment(true,wo.id);
       
        //create service resource 
        
        ServiceResource testFactorySR = SBR_3_0_ServiceTestDataFactory.create_Service_Resource(False);
        User testUser = [Select Id,Name from User where UserName LIKE 'SRTestUser%' ];
        testFactorySR.RelatedRecordId = testUser.Id;
        testFactorySR.ResourceType = 'T';
        insert testFactorySR;
        
        //ceate Service Territory member 
        ServiceTerritoryMember testSTM =SBR_3_0_ServiceTestDataFactory.createServiceTerritoryMember(true,testFactorySR.id,testST.id);

        SBR_3_0_CustomUpdateWorkOrder co = new SBR_3_0_CustomUpdateWorkOrder(jsonString);
        String returnVal = co.syncWorkOrderToSF();
        co.getserviceAppointment(wo1);
        Test.stopTest();
        
    }
    @isTest
    static void testCustomUpdateWorkOrder2(){
        insert new Bypass_Settings__c(SetupOwnerId=UserInfo.getUserId(), Bypass_Flow__c=true);
        
        Credential__c cred = SBR_3_0_TestDataFactory.createCredentials(1, false)[0];
        cred.Name = 'Mule_Token_Endpoint';
        cred.Key_Id__c = 'testKey123';
        cred.Secret__c = 'secret';
        insert cred;
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/WorkOder/ApiUpdateApointment/v1';
        req.httpMethod = 'POST';
        String jsonString  =  '{ "EventType": "1", "Status": "Dispatched", "SF_PS_VDOS_OrderLine_External_Id__c": "vdostestclass1", "SF_PS_VDOS_Dispatch_Type__c": "AU", "SF_PS_RM_WO_Number__c": "",  "SF_PS_Service_Resource__c": "98765", "SF_PS_VDOS_Stop_Id__c": "909090", "SF_PS_Company_Code__c" : "", "SF_PS_Status_Reasons__c": "" }';
        
        req.requestBody = Blob.valueOf(jsonString);
        
        RestContext.request = req;
        RestContext.response= res;
        User testAdminUser = [Select Id,Name from User where UserName LIKE 'testAdminUser%' ];       
        
        
        Test.startTest();
       // FSL.GlobalAPIS.addStatusTransition('Open', 'Scheduled');
      //  FSL.GlobalAPIS.addStatusTransition('Scheduled', 'Dispatched');
        //create Asset
        Asset testAsrt =  SBR_3_0_ServiceTestDataFactory.createAsset(true);
        
        //Create Exponce to Location
        ServiceTerritory  testE2Loc = SBR_3_0_ServiceTestDataFactory.createServiceTerritory(true);
        
        //Create Service Territory 
        ServiceTerritory  testST = SBR_3_0_ServiceTestDataFactory.createServiceTerritory(true);
        //create work order 
        workorder wo = SBR_3_0_ServiceTestDataFactory.createWorkOrder(false);
        wo.SF_PS_RM_WO_Number__c = '01-1122900';
        wo.SF_PS_Expense_To_Location__c = testE2Loc.id;
        wo.AssetId = testAsrt.id;
        wo.ServiceTerritoryId  = testST.id;
        insert wo;
                
        ServiceAppointment sa = SBR_3_0_ServiceTestDataFactory.createServiceAppointment(true,wo.id);
       
        //create service resource 
        
        ServiceResource testFactorySR = SBR_3_0_ServiceTestDataFactory.create_Service_Resource(False);
        User testUser = [Select Id,Name from User where UserName LIKE 'SRTestUser%' ];
        testFactorySR.RelatedRecordId = testUser.Id;
        testFactorySR.ResourceType = 'T';
        insert testFactorySR;
        
        //ceate Service Territory member 
        ServiceTerritoryMember testSTM =SBR_3_0_ServiceTestDataFactory.createServiceTerritoryMember(true,testFactorySR.id,testST.id);

        SBR_3_0_CustomUpdateWorkOrder co = new SBR_3_0_CustomUpdateWorkOrder(jsonString);
        String returnVal = co.syncWorkOrderToSF();
        Test.stopTest();
        
    }
   
    @isTest 
    static void testCustomUpdateWorkOrderelse(){
        insert new Bypass_Settings__c(SetupOwnerId=UserInfo.getUserId(), Bypass_Flow__c=true);
        
        Credential__c cred = SBR_3_0_TestDataFactory.createCredentials(1, false)[0];
        cred.Name = 'Mule_Token_Endpoint';
        cred.Key_Id__c = 'testKey123';
        cred.Secret__c = 'secret';
        insert cred;
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/WorkOder/ApiUpdateApointment/v1';
        req.httpMethod = 'POST';
        String jsonString  =  '{ "EventType": "1", "Status": "Dispatch", "SF_PS_VDOS_OrderLine_External_Id__c": "vdostestclass1", "SF_PS_VDOS_Dispatch_Type__c": "AU", "SF_PS_RM_WO_Number__c": "1122900",  "SF_PS_Service_Resource__c": "98765", "SF_PS_VDOS_Stop_Id__c": "909090", "SF_PS_Company_Code__c" : "01", "SF_PS_Status_Reasons__c": "" }';
        
        req.requestBody = Blob.valueOf(jsonString);
        
        RestContext.request = req;
        RestContext.response= res;
        User testAdminUser = [Select Id,Name from User where UserName LIKE 'testAdminUser%' ];       
        
        
        Test.startTest();
        FSL.GlobalAPIS.addStatusTransition('Open', 'Scheduled');
        FSL.GlobalAPIS.addStatusTransition('Scheduled', 'Dispatched');
        //create Asset
        Asset testAsrt =  SBR_3_0_ServiceTestDataFactory.createAsset(true);
        
        //Create Exponce to Location
        ServiceTerritory  testE2Loc = SBR_3_0_ServiceTestDataFactory.createServiceTerritory(true);
        
        //Create Service Territory 
        ServiceTerritory  testST = SBR_3_0_ServiceTestDataFactory.createServiceTerritory(true);
        //create work order 
        workorder wo = SBR_3_0_ServiceTestDataFactory.createWorkOrder(false);
        wo.SF_PS_RM_WO_Number__c = '01-1122900';
        wo.SF_PS_Expense_To_Location__c = testE2Loc.id;
        wo.AssetId = testAsrt.id;
        wo.ServiceTerritoryId  = testST.id;
        insert wo;
                
        ServiceAppointment sa = SBR_3_0_ServiceTestDataFactory.createServiceAppointment(true,wo.id);
       
        //create service resource 
        
        ServiceResource testFactorySR = SBR_3_0_ServiceTestDataFactory.create_Service_Resource(False);
        User testUser = [Select Id,Name from User where UserName LIKE 'SRTestUser%' ];
        testFactorySR.RelatedRecordId = testUser.Id;
        testFactorySR.ResourceType = 'T';
        insert testFactorySR;
        
        //ceate Service Territory member 
        ServiceTerritoryMember testSTM =SBR_3_0_ServiceTestDataFactory.createServiceTerritoryMember(true,testFactorySR.id,testST.id);

        SBR_3_0_CustomUpdateWorkOrder co = new SBR_3_0_CustomUpdateWorkOrder(jsonString);
        String returnVal = co.syncWorkOrderToSF();
        Test.stopTest();
        
    }    
    @isTest 
    static void testCustomUpdateWorkOrderelse1(){
        insert new Bypass_Settings__c(SetupOwnerId=UserInfo.getUserId(), Bypass_Flow__c=true);
        
        Credential__c cred = SBR_3_0_TestDataFactory.createCredentials(1, false)[0];
        cred.Name = 'Mule_Token_Endpoint';
        cred.Key_Id__c = 'testKey123';
        cred.Secret__c = 'secret';
        insert cred;
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/WorkOder/ApiUpdateApointment/v1';
        req.httpMethod = 'POST';
        String jsonString  =  '{ "EventType": "1", "Status": "Unable to Complete", "SF_PS_VDOS_OrderLine_External_Id__c": "vdostestclass1", "SF_PS_VDOS_Dispatch_Type__c": "AU", "SF_PS_RM_WO_Number__c": "1122900",  "SF_PS_Service_Resource__c": "98765", "SF_PS_VDOS_Stop_Id__c": "909090", "SF_PS_Company_Code__c" : "01", "SF_PS_Status_Reasons__c": "" }';
        
        req.requestBody = Blob.valueOf(jsonString);
        
        RestContext.request = req;
        RestContext.response= res;
        User testAdminUser = [Select Id,Name from User where UserName LIKE 'testAdminUser%' ];       
        
        
        Test.startTest();
        FSL.GlobalAPIS.addStatusTransition('Open', 'Scheduled');
        FSL.GlobalAPIS.addStatusTransition('Scheduled', 'Dispatched');
        //create Asset
        Asset testAsrt =  SBR_3_0_ServiceTestDataFactory.createAsset(true);
        
        //Create Exponce to Location
        ServiceTerritory  testE2Loc = SBR_3_0_ServiceTestDataFactory.createServiceTerritory(true);
        
        //Create Service Territory 
        ServiceTerritory  testST = SBR_3_0_ServiceTestDataFactory.createServiceTerritory(true);
        //create work order 
        workorder wo = SBR_3_0_ServiceTestDataFactory.createWorkOrder(false);
        wo.SF_PS_RM_WO_Number__c = '01-1122900';
        wo.SF_PS_Expense_To_Location__c = testE2Loc.id;
        wo.AssetId = testAsrt.id;
        wo.ServiceTerritoryId  = testST.id;
        insert wo;
                
        ServiceAppointment sa = SBR_3_0_ServiceTestDataFactory.createServiceAppointment(true,wo.id);
       
        //create service resource 
        
        ServiceResource testFactorySR = SBR_3_0_ServiceTestDataFactory.create_Service_Resource(False);
        User testUser = [Select Id,Name from User where UserName LIKE 'SRTestUser%' ];
        testFactorySR.RelatedRecordId = testUser.Id;
        testFactorySR.ResourceType = 'T';
        insert testFactorySR;
        
        //ceate Service Territory member 
        ServiceTerritoryMember testSTM =SBR_3_0_ServiceTestDataFactory.createServiceTerritoryMember(true,testFactorySR.id,testST.id);

        SBR_3_0_CustomUpdateWorkOrder co = new SBR_3_0_CustomUpdateWorkOrder(jsonString);
        String returnVal = co.syncWorkOrderToSF();
        try{
            wo.SF_PS_RM_WO_Number__c = '02-1122900';
            update wo;
             SBR_3_0_CustomUpdateWorkOrder co1 = new SBR_3_0_CustomUpdateWorkOrder(jsonString);
             co1.getWorkOrder();          
        }catch (Exception e){
            system.debug('exception'+e);
        }
        Test.stopTest();
        
    } 
    @isTest 
    static void testCustomUpdateWorkOrderPMWONULL(){
        insert new Bypass_Settings__c(SetupOwnerId=UserInfo.getUserId(), Bypass_Flow__c=true);
        
        Credential__c cred = SBR_3_0_TestDataFactory.createCredentials(1, false)[0];
        cred.Name = 'Mule_Token_Endpoint';
        cred.Key_Id__c = 'testKey123';
        cred.Secret__c = 'secret';
        insert cred;
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/WorkOder/ApiUpdateApointment/v1';
        req.httpMethod = 'POST';
        String jsonString  =  '{ "EventType": "1", "Status": "Unable to Complete", "SF_PS_VDOS_OrderLine_External_Id__c": "vdostestclass1", "SF_PS_VDOS_Dispatch_Type__c": "AU", "SF_PS_RM_WO_Number__c": "",  "SF_PS_Service_Resource__c": "98765", "SF_PS_VDOS_Stop_Id__c": "909090", "SF_PS_Company_Code__c" : "01", "SF_PS_Status_Reasons__c": "" }';
        
        req.requestBody = Blob.valueOf(jsonString);
        
        RestContext.request = req;
        RestContext.response= res;
        User testAdminUser = [Select Id,Name from User where UserName LIKE 'testAdminUser%' ];       
        
        
        Test.startTest();
        FSL.GlobalAPIS.addStatusTransition('Open', 'Scheduled');
        FSL.GlobalAPIS.addStatusTransition('Scheduled', 'Dispatched');
        //create Asset
        Asset testAsrt =  SBR_3_0_ServiceTestDataFactory.createAsset(true);
        
        //Create Exponce to Location
        ServiceTerritory  testE2Loc = SBR_3_0_ServiceTestDataFactory.createServiceTerritory(true);
        
        //Create Service Territory 
        ServiceTerritory  testST = SBR_3_0_ServiceTestDataFactory.createServiceTerritory(true);
        //create work order 
        workorder wo = SBR_3_0_ServiceTestDataFactory.createWorkOrder(false);
        wo.SF_PS_RM_WO_Number__c = '01-1122900';
        wo.SF_PS_Expense_To_Location__c = testE2Loc.id;
        wo.AssetId = testAsrt.id;
        wo.ServiceTerritoryId  = testST.id;
        insert wo;
                
        ServiceAppointment sa = SBR_3_0_ServiceTestDataFactory.createServiceAppointment(true,wo.id);
       
        //create service resource 
        
        ServiceResource testFactorySR = SBR_3_0_ServiceTestDataFactory.create_Service_Resource(False);
        User testUser = [Select Id,Name from User where UserName LIKE 'SRTestUser%' ];
        testFactorySR.RelatedRecordId = testUser.Id;
        testFactorySR.ResourceType = 'T';
        insert testFactorySR;
        
        //ceate Service Territory member 
        ServiceTerritoryMember testSTM =SBR_3_0_ServiceTestDataFactory.createServiceTerritoryMember(true,testFactorySR.id,testST.id);

        SBR_3_0_CustomUpdateWorkOrder co = new SBR_3_0_CustomUpdateWorkOrder(jsonString);
        String returnVal = co.syncWorkOrderToSF();
        Test.stopTest();
        
    } 
}