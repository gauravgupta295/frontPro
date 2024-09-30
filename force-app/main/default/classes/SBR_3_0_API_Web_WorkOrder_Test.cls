/*********************************************************************************************************************
* Apex Class: SBR_3_0_API_Web_WorkOrder_Test
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Class to test the rest end point for inbound work orders.
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION       DATE               DETAIL FEATURES
1.0          2023-02-23          Initial version 
2.0          2023-05-10          Harry Rokad   
**********************************************************************************************************************************************/

@isTest
public class SBR_3_0_API_Web_WorkOrder_Test  Implements HttpCalloutMock  {
    public HTTPResponse respond(HTTPRequest request) {
        // Create a fake response
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setBody('Success');
        response.setStatusCode(200);
        return response; 
    }
    
    // Generate a random string
    public static String generateRandomString(Integer len) {
        final String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz';
        String randStr = '';
        while (randStr.length() < len) {
            Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
            randStr += chars.substring(idx, idx+1);
        }
        return randStr; 
    }
    
    @TestSetup
    static void makeData(){
                
        //Create Run Test User as System Admin
        //User runTestClassUser = SBR_3_0_ServiceTestDataFactory.createSystemAdminRunUser(true,'12347','9812912317');
        //system.debug('Checkpoint 11::'+runTestClassUser +'::'+runTestClassUser.profileId);
        //Create Test User
        User testUser = SBR_3_0_ServiceTestDataFactory.createServiceResourceUserWO(true,'1234','981291231');
        User testAdminUser = SBR_3_0_ServiceTestDataFactory.createSystemAdminUser(true,'8898','987644'); 
        
        // insert new PermissionSetAssignment(AssigneeId=UserInfo.getUserId(),
        //                            PermissionSetId=mockedPermissionSetId);
        
        PermissionSetLicense psl = [SELECT Id FROM PermissionSetLicense WHERE DeveloperName = 'SalesforceCPQ_CPQStandardPerm'];
        List<PermissionSetLicenseAssign> pslList =[	Select Id, AssigneeId , Assignee.Name, PermissionSetLicense.DeveloperName  , 
                                                   PermissionSetLicenseId 
                                                   from PermissionSetLicenseAssign 
                                                   where PermissionSetLicense.DeveloperName = 'SalesforceCPQ_CPQStandardPerm' 
                                                   AND AssigneeId = : testAdminUser.Id];
        List<PermissionSetLicenseAssign> pslListuser =[	Select Id, AssigneeId , Assignee.Name, PermissionSetLicense.DeveloperName  , 
                                                   PermissionSetLicenseId 
                                                   from PermissionSetLicenseAssign 
                                                   where PermissionSetLicense.DeveloperName = 'SalesforceCPQ_CPQStandardPerm' 
                                                   AND AssigneeId = : UserInfo.getUserId()];
        if (pslList.size()==0){
            insert new PermissionSetLicenseAssign(AssigneeId = testAdminUser.Id, PermissionSetLicenseId = psl.Id);
        }
        if (pslListuser.size()==0){
            insert new PermissionSetLicenseAssign(AssigneeId = UserInfo.getUserId(), PermissionSetLicenseId = psl.Id);
        }
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Integration_API_Access'];
        List <PermissionSetAssignment> permSetCheck = [SELECT Id from PermissionSetAssignment WHERE PermissionSetId = : ps.Id
                                                       AND AssigneeId = : testAdminUser.Id];
        if (permSetCheck.size()==0){
            insert new PermissionSetAssignment(AssigneeId = testAdminUser.Id, PermissionSetId = ps.Id);
        }
        
        List <PermissionSetAssignment> permSetCheckuser = [SELECT Id from PermissionSetAssignment WHERE PermissionSetId = : ps.Id
                                                       AND AssigneeId = : UserInfo.getUserId()];
        if (permSetCheckuser.size()==0){
            insert new PermissionSetAssignment(AssigneeId = UserInfo.getUserId(), PermissionSetId = ps.Id);
        }
		
        
    }
    
    //Success Test for the Updation Of the Service Resource from Payload Json
    @isTest
    static void testupdateServiceResource(){
        //Get Custom setting 
        insert new Bypass_Settings__c(SetupOwnerId=UserInfo.getUserId(), Bypass_Flow__c=true);
        
        
        //Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_Web_Order_Test());
        Credential__c cred = SBR_3_0_TestDataFactory.createCredentials(1, false)[0];
        cred.Name = 'Mule_Token_Endpoint';
        cred.Key_Id__c = 'testKey123';
        cred.Secret__c = 'secret';
        insert cred;
        
        Id pricebookId = Test.getStandardPricebookId();
        Pricebook2 standardPricebook = new Pricebook2(
            name= 'Standard Price Book',
            Id = pricebookId,
            IsActive = true
        );
        update standardPricebook;
        system.debug('standardPricebook is' + standardPricebook.id);
        
        
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_Web_WorkOrder_Test());
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/WorkOrder/ApiCreate/v1/*';
        req.httpMethod = 'POST';
        //String jsonString = '{ "EventType": "1","SF_PS_Company_Code__c": "01","Name": "Test Resouce","SF_PS_Hourly_Billing_Rate__c": 15.0,"SF_PS_Hourly_Internal_Rate__c": 15.0,"SF_PS_Overtime_Billing_Rate__c": 15.0,"SF_PS_Overtime_Internal_Rate__c": 15.0,"SF_PS_Labor_Type__c": "I","SF_PS_Type__c": "D","IsActive": true,"SF_PS_Branch_Loc_Num__c": "6666","SF_PS_Start_Date__c": "2023-02-22","SF_PS_RM_Created_DateTime__c": "2023-02-22T09:45:00Z","SF_PS_RM_Created_By__c": "Test User","SF_PS_RM_Update_DateTime__c": "2023-02-22T09:45:00Z","SF_PS_RM_Updated_By_User__c": "Test User","SF_PS_Mechanic_Id__c": "9999","SF_PS_Comments__c": "Yes api" }';
        // Old JSON String jsonString = '{"data":{"EventType":"1","Status":"Open","OwnerId":"1234","CurrencyIsoCode":"USD","AssetId":"1018879","SVMXA360_ContactPhone_c":"7036004000","SF_PS_Authorized_By__c":"","SF_PS_BillCustOrLoc__c":"L","SF_PS_PONumber__c":"","SF_PS_RM_WO_Number__c":"333222", "SF_PS_Expense_To_Location__c" : "1234","SF_PS_Cause__c":"","SF_PS_Company_Code__c":"01","SF_PS_Complaint__c":"","SF_PS_Cure__c":"","SF_PS_ExpenseCode__c":"RR","SF_PS_LaborCode__c":"9100","SF_PS_Cust_Eqp_Description__c":"","SF_PS_Current_MiHr__c":0.000,"SF_PS_Repair_Ticket__c":0,"SF_PS_Work_Order_Des__c":"CHECK IN RETURN","SF_PS_Current_MiHr2__c":0.000,"SF_PS_Service_Call__c":"Y","SF_PS_Warranty_Amt_Expected__c":0.00,"SF_PS_Claim_Type__c":"N","SF_PS_Actual_Claim_Amt__c":0.00, "SF_PS_Service_Resource__c":"50607", "SF_PS_Claim_Paid_Date__c":"2023-02-22","SF_PS_Claim_Num__c":"","SF_PS_Date_Claim_Filed__c":"2023-02-22","SF_PS_Sales_Rep__c":"111222","SF_PS_Funded__c":"Y","SF_PS_Closed_Date__c":"2023-02-22T09:45:00Z","SF_PS_Current_Loc__c": "0784", "SF_PS_Date_Opened__c":"2023-02-22T09:45:00Z","SF_PS_Charge_GST_Tax__c":false,"SF_PS_Charge_PST_Tax__c":false,"SF_PS_Drivers_License_Number__c":"","SF_PS_Job_Site__c":"","SF_PS_Job_Location__c":"","SF_PS_Due_Date__c":"2023-02-22T09:45:00Z","SF_PS_Labor_Des_Comments__c":"","SF_PS_Labor_Des_Internal__c":"","SF_PS_RM_Last_Maint_By__c":"","SF_PS_RM_Last_Maint_DateTime__c":"2023-02-22T09:45:00Z","SF_PS_Inv_Seq_Num__c":1234,"SF_PS_License_State__c":"OH"},"WorkOrderLineItem":[{"Duration":0.00,"SF_PS_Labor_Code__c":"1000","SF_PS_Mechanic_Name__c":"50607","SF_PS_Hourly_Internal_Rate__c":0.00,"SF_PS_RM_Labor_Line_Item_Number__c":"","SF_PS_RM_External_Id__c":"53474688","SF_PS_Line_Type__c":"LI","SF_PS_Mileage_Charge__c":"MileageCharge","SF_PS_RM_Item_Number__c":"87213143"}],"deletedLines": []}';
        String jsonString = '{"data":{"EventType":"1","Status":"Open","OwnerId":"1234","RecordTypeId" : "WORK ORDER","CurrencyIsoCode":"USD","Pricebook2Id":"'+pricebookId+'","AssetId":"1018879","SVMXA360_ContactPhone_c":"7036004000","SF_PS_Authorized_By__c":"","SF_PS_BillCustOrLoc__c":"L","SF_PS_PONumber__c":"","SF_PS_RM_WO_Number__c":"333222","SF_PS_Expense_To_Location__c":"1234","SF_PS_Expense_To_Loc__c":"1234","SF_PS_Cause__c":"","SF_PS_Company_Code__c":"01","SF_PS_Complaint__c":"","SF_PS_Cure__c":"","SF_PS_ExpenseCode__c":"RR","SF_PS_LaborCode__c":"9100","SF_PS_Cust_Eqp_Description__c":"","SF_PS_Current_MiHr__c":0,"SF_PS_Repair_Ticket__c":0,"SF_PS_Work_Order_Des__c":"CHECK IN RETURN","SF_PS_Current_MiHr2__c":0,"SF_PS_Service_Call__c":"Y","SF_PS_Warranty_Amt_Expected__c":0,"SF_PS_Claim_Type__c":"N","SF_PS_Actual_Claim_Amt__c":0,"SF_PS_Service_Resource__c":"981291231","SF_PS_Claim_Paid_Date__c":"2023-02-22","SF_PS_Claim_Num__c":"","SF_PS_Date_Claim_Filed__c":"2023-02-22","SF_PS_Sales_Rep__c":"","SF_PS_Funded__c":"Y","SF_PS_Closed_Date__c":"2023-02-22T09:45:00Z","SF_PS_Current_Loc__c":"1234","SF_PS_Date_Opened__c":"2023-02-22T09:45:00Z","SF_PS_Charge_GST_Tax__c":false,"SF_PS_Charge_PST_Tax__c":false,"SF_PS_Drivers_License_Number__c":"","SF_PS_Job_Site__c":"","SF_PS_Job_Location__c":"","SF_PS_Due_Date__c":"2023-02-22T09:45:00Z","SF_PS_Labor_Des_Comments__c":"","SF_PS_Labor_Des_Internal__c":"","SF_PS_RM_Last_Maint_By__c":"","SF_PS_RM_Last_Maint_DateTime__c":"2023-02-22T09:45:00Z","SF_PS_Inv_Seq_Num__c":1234,"SF_PS_License_State__c":"OH"},"WorkOrderLineItem":[{"Duration":1,"SF_PS_Labor_Code__c":"1000","SF_PS_Mechanic_Name__c":"981291231","SF_PS_Hourly_Internal_Rate__c":0,"SF_PS_RM_Labor_Line_Item_Number__c":"","SF_PS_RM_External_Id__c":"3322123","SF_PS_Line_Type__c":"LI","SF_PS_Mileage_Charge__c":"MileageCharge","SF_PS_RM_Item_Number__c":"87213143"}],"ProductConsumed":[{"SF_PS_RM_External_Id__c":"1231231","SF_PS_Parts_Line_Num__c":"","SF_PS_Selling_Price__c":0,"SF_PS_Cost_Price__c":0,"SF_PS_Line_Type__c":"WO","Product2Id":"10870996","SF_PS_Quantity__c":1,"SF_PS_Unit_Of_Measure__c":"EA","SF_PS_Labor_Code__c":"1000","SF_PS_Line_Level_Comment__c":"string","SF_PS_List_Price__c":0}],"maintenanceSteps":[{"SF_PS_RM_Mtce_Mechanic_Name__c":"981291231","SF_PS_RM_External_Id__c":9812390812,"SF_PS_RM_Mtce_Steps_Y_N__c":"Y","SF_PS_RM_Mtce_Steps_StepNumber__c":"1","SF_PS_RM_Mtce_Steps_Meter_Reading_In__c":0,"SF_PS_RM_Mtce_Steps_Meter_Reading_Out__c":0,"SF_PS_RM_Mtce_Steps_Description__c":"","SF_PS_RM_Mtce_Steps_Pass_Fail__c":"P"}],"deletedLines":[{"SF_PS_RM_External_Id__c":""}]}';
        //request.requestBody = Blob.valueOf(JSON.serialize(jsonString));
        req.requestBody = Blob.valueOf(jsonString);
        
        RestContext.request = req;
        RestContext.response= res;
        
        User testAdminUser = [Select Id,Name from User where UserName LIKE 'testAdminUser%' ];
        system.debug('test request' + req);
        system.debug('test res' + res);
        
        //System.runAs(testAdminUser){
            insert new Bypass_Settings__c(SetupOwnerId=testAdminUser.Id, Bypass_Flow__c=true);
            Test.startTest();
            Asset testAsrt =  SBR_3_0_ServiceTestDataFactory.createAsset(true);
            
            //Create Exponce to Location
            ServiceTerritory  testE2Loc = SBR_3_0_ServiceTestDataFactory.createServiceTerritory(true);
            
            //Create Service Territory 
            //ServiceTerritory  testST = SBR_3_0_ServiceTestDataFactory.createServiceTerritory(false);
            OperatingHours oh = new OperatingHours(Name='TEST_Hours1',TimeZone='America/Halifax');
            insert oh;
            string name  ='TestHr';
        
            ServiceTerritory testST= new ServiceTerritory(Name=name,OperatingHoursId=oh.Id,IsActive=true,Branch_Location_Number__c = '1234',CountryCode = 'US');
            insert testST;
            
            ServiceResource testFactorySR = SBR_3_0_ServiceTestDataFactory.create_Service_Resource(false);
            User testUser = [Select Id,Name from User where UserName LIKE 'SRTestUser2%' Limit 1 ];
            testFactorySR.RelatedRecordId = testUser.Id;
            testFactorySR.ResourceType = 'T';
            insert testFactorySR;
            //create work order
            //workorder wop = SBR_3_0_ServiceTestDataFactory.createWorkOrder(false);
            //wop.SF_PS_RM_WO_Number__c = '01-333223234';
            //wop.SF_PS_Expense_To_Location__c = testST.id;
            //wop.AssetId = testAsrt.id;
            //wop.ServiceTerritoryId  = testE2Loc.id;
            //wop.SF_PS_Service_Resource__c = testFactorySR.id;
            //insert wop;
            Id worecordType = Schema.SObjectType.workorder.getRecordTypeInfosByName().get('Inspection Record').getRecordTypeId();

            //create work order 
            workorder wo = SBR_3_0_ServiceTestDataFactory.createWorkOrder(false);
            wo.SF_PS_RM_WO_Number__c = '01-333222';
            wo.SF_PS_Expense_To_Location__c = testST.id;
            wo.AssetId = testAsrt.id;
            wo.ServiceTerritoryId  = testE2Loc.id;
            wo.SF_PS_Service_Resource__c = testFactorySR.id;
            wo.Pricebook2Id= standardPricebook.id;
            wo.recordTypeId =  worecordType;
        	wo.SF_PS_RM_Quote_Num__c = '12-352672';
            //wo.ParentWorkOrderId = wop.Id;
            insert wo;
            
            WorkOrderLineItem testwoli =  SBR_3_0_ServiceTestDataFactory.createWoli(false,wo.id,testFactorySR.id);
            testwoli.Duration = 1;
            if (testwoli != null) {
                insert testwoli;
            }
            //create product consumed
            ProductConsumed testPc =  SBR_3_0_ServiceTestDataFactory.createProductConsumedRecord(true ,wo.id, '1231231');
        
            //SF_PS_Maintenance_Steps__c testMc = SBR_3_0_ServiceTestDataFactory.createMaintenanceSteps(true,wo.id,testFactorySR.id);
            DueForService__c testDS = SBR_3_0_ServiceTestDataFactory.createDueForServiceRecord(true,testAsrt.id, '01');
            
            //ProductConsumed testPc =  SBR_3_0_ServiceTestDataFactory.createProductConsumedRecord(true ,wo.id, '1231239');
            //ceate Service Territory member 
            
            Profile objProfile = [Select Id, Name from Profile where Name =: 'System Administrator' limit 1];
            User objeUser = [Select Id, ProfileId from User where Id=: UserInfo.getUserId()];
            
            //User testrunUser = [Select Id,Name from User where SF_PS_Mechanic_Id__c='9812912317' ];
            //User AdminRunUser = [Select Id,Name from User where UserName LIKE 'AdminRunUser%' ];
            //system.debug('AdminRunUseris '+ AdminRunUser);
            System.debug('testFactorySR.id ' + testFactorySR.id);
            System.debug('testST.id ' + testST.id);
            //ServiceTerritoryMember testSTM =SBR_3_0_ServiceTestDataFactory.createServiceTerritoryMember(true,testFactorySR1.id,testST1.id);
            try {
                SBR_3_0_API_Web_WorkOrder.create();
                //system.assertEquals(200,res.statusCode);
                system.debug('test res 1st' + res);
            }Catch (Exception e) {
                System.debug('An Error Occur | ' + e);
                //system.assertEquals('Related Sales Rep not found!', e.getMessage(), 'Order API did not return Success!');
            }    
            Test.stopTest();
        //}
    }
   
   
    //Success Test for the Updation Of the Service Resource from Payload Json
    @isTest
    static void testupdateWOwithparent(){
        //Get Custom setting 
        insert new Bypass_Settings__c(SetupOwnerId=UserInfo.getUserId(), Bypass_Flow__c=true);
        
        
        //Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_Web_Order_Test());
        Credential__c cred = SBR_3_0_TestDataFactory.createCredentials(1, false)[0];
        cred.Name = 'Mule_Token_Endpoint';
        cred.Key_Id__c = 'testKey123';
        cred.Secret__c = 'secret';
        insert cred;
        
        Id pricebookId = Test.getStandardPricebookId();
        Pricebook2 standardPricebook = new Pricebook2(
            name= 'Standard Price Book',
            Id = pricebookId,
            IsActive = true
        );
        update standardPricebook;
        system.debug('standardPricebook is' + standardPricebook.id);
        
        
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_Web_WorkOrder_Test());
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/WorkOrder/ApiCreate/v1/*';
        req.httpMethod = 'POST';
        //String jsonString = '{ "EventType": "1","SF_PS_Company_Code__c": "01","Name": "Test Resouce","SF_PS_Hourly_Billing_Rate__c": 15.0,"SF_PS_Hourly_Internal_Rate__c": 15.0,"SF_PS_Overtime_Billing_Rate__c": 15.0,"SF_PS_Overtime_Internal_Rate__c": 15.0,"SF_PS_Labor_Type__c": "I","SF_PS_Type__c": "D","IsActive": true,"SF_PS_Branch_Loc_Num__c": "6666","SF_PS_Start_Date__c": "2023-02-22","SF_PS_RM_Created_DateTime__c": "2023-02-22T09:45:00Z","SF_PS_RM_Created_By__c": "Test User","SF_PS_RM_Update_DateTime__c": "2023-02-22T09:45:00Z","SF_PS_RM_Updated_By_User__c": "Test User","SF_PS_Mechanic_Id__c": "9999","SF_PS_Comments__c": "Yes api" }';
        // Old JSON String jsonString = '{"data":{"EventType":"1","Status":"Open","OwnerId":"1234","CurrencyIsoCode":"USD","AssetId":"1018879","SVMXA360_ContactPhone_c":"7036004000","SF_PS_Authorized_By__c":"","SF_PS_BillCustOrLoc__c":"L","SF_PS_PONumber__c":"","SF_PS_RM_WO_Number__c":"333222", "SF_PS_Expense_To_Location__c" : "1234","SF_PS_Cause__c":"","SF_PS_Company_Code__c":"01","SF_PS_Complaint__c":"","SF_PS_Cure__c":"","SF_PS_ExpenseCode__c":"RR","SF_PS_LaborCode__c":"9100","SF_PS_Cust_Eqp_Description__c":"","SF_PS_Current_MiHr__c":0.000,"SF_PS_Repair_Ticket__c":0,"SF_PS_Work_Order_Des__c":"CHECK IN RETURN","SF_PS_Current_MiHr2__c":0.000,"SF_PS_Service_Call__c":"Y","SF_PS_Warranty_Amt_Expected__c":0.00,"SF_PS_Claim_Type__c":"N","SF_PS_Actual_Claim_Amt__c":0.00, "SF_PS_Service_Resource__c":"50607", "SF_PS_Claim_Paid_Date__c":"2023-02-22","SF_PS_Claim_Num__c":"","SF_PS_Date_Claim_Filed__c":"2023-02-22","SF_PS_Sales_Rep__c":"111222","SF_PS_Funded__c":"Y","SF_PS_Closed_Date__c":"2023-02-22T09:45:00Z","SF_PS_Current_Loc__c": "0784", "SF_PS_Date_Opened__c":"2023-02-22T09:45:00Z","SF_PS_Charge_GST_Tax__c":false,"SF_PS_Charge_PST_Tax__c":false,"SF_PS_Drivers_License_Number__c":"","SF_PS_Job_Site__c":"","SF_PS_Job_Location__c":"","SF_PS_Due_Date__c":"2023-02-22T09:45:00Z","SF_PS_Labor_Des_Comments__c":"","SF_PS_Labor_Des_Internal__c":"","SF_PS_RM_Last_Maint_By__c":"","SF_PS_RM_Last_Maint_DateTime__c":"2023-02-22T09:45:00Z","SF_PS_Inv_Seq_Num__c":1234,"SF_PS_License_State__c":"OH"},"WorkOrderLineItem":[{"Duration":0.00,"SF_PS_Labor_Code__c":"1000","SF_PS_Mechanic_Name__c":"50607","SF_PS_Hourly_Internal_Rate__c":0.00,"SF_PS_RM_Labor_Line_Item_Number__c":"","SF_PS_RM_External_Id__c":"53474688","SF_PS_Line_Type__c":"LI","SF_PS_Mileage_Charge__c":"MileageCharge","SF_PS_RM_Item_Number__c":"87213143"}],"deletedLines": []}';
        String jsonString = '{"data":{"EventType":"1","Status":"Open","OwnerId":"1234","RecordTypeId" : "WORK ORDER","SF_PS_RM_Quote_Num__c":"333225","CurrencyIsoCode":"USD","Pricebook2Id":"'+pricebookId+'","AssetId":"1018879","SVMXA360_ContactPhone_c":"7036004000","SF_PS_Authorized_By__c":"","SF_PS_BillCustOrLoc__c":"L","SF_PS_PONumber__c":"","SF_PS_RM_WO_Number__c":"333222","SF_PS_Expense_To_Location__c":"1234","SF_PS_Expense_To_Loc__c":"1234","SF_PS_Cause__c":"","SF_PS_Company_Code__c":"01","SF_PS_Complaint__c":"","SF_PS_Cure__c":"","SF_PS_ExpenseCode__c":"RR","SF_PS_LaborCode__c":"9100","SF_PS_Cust_Eqp_Description__c":"","SF_PS_Current_MiHr__c":0,"SF_PS_Repair_Ticket__c":0,"SF_PS_Work_Order_Des__c":"CHECK IN RETURN","SF_PS_Current_MiHr2__c":0,"SF_PS_Service_Call__c":"Y","SF_PS_Warranty_Amt_Expected__c":0,"SF_PS_Claim_Type__c":"N","SF_PS_Actual_Claim_Amt__c":0,"SF_PS_Service_Resource__c":"981291231","SF_PS_Claim_Paid_Date__c":"2023-02-22","SF_PS_Claim_Num__c":"","SF_PS_Date_Claim_Filed__c":"2023-02-22","SF_PS_Sales_Rep__c":"","SF_PS_Funded__c":"Y","SF_PS_Closed_Date__c":"2023-02-22T09:45:00Z","SF_PS_Current_Loc__c":"1234","SF_PS_Date_Opened__c":"2023-02-22T09:45:00Z","SF_PS_Charge_GST_Tax__c":false,"SF_PS_Charge_PST_Tax__c":false,"SF_PS_Drivers_License_Number__c":"","SF_PS_Job_Site__c":"","SF_PS_Job_Location__c":"","SF_PS_Due_Date__c":"2023-02-22T09:45:00Z","SF_PS_Labor_Des_Comments__c":"","SF_PS_Labor_Des_Internal__c":"","SF_PS_RM_Last_Maint_By__c":"","SF_PS_RM_Last_Maint_DateTime__c":"2023-02-22T09:45:00Z","SF_PS_Inv_Seq_Num__c":1234,"SF_PS_License_State__c":"OH"},"WorkOrderLineItem":[{"Duration":1,"SF_PS_Labor_Code__c":"1000","SF_PS_Mechanic_Name__c":"981291231","SF_PS_Hourly_Internal_Rate__c":0,"SF_PS_RM_Labor_Line_Item_Number__c":"","SF_PS_RM_External_Id__c":"3322123","SF_PS_Line_Type__c":"LI","SF_PS_Mileage_Charge__c":"MileageCharge","SF_PS_RM_Item_Number__c":"87213143"}],"ProductConsumed":[{"SF_PS_RM_External_Id__c":"1231231","SF_PS_Parts_Line_Num__c":"","SF_PS_Selling_Price__c":0,"SF_PS_Cost_Price__c":0,"SF_PS_Line_Type__c":"WO","Product2Id":"10870996","SF_PS_Quantity__c":1,"SF_PS_Unit_Of_Measure__c":"EA","SF_PS_Labor_Code__c":"1000","SF_PS_Line_Level_Comment__c":"string","SF_PS_List_Price__c":0}],"maintenanceSteps":[{"SF_PS_RM_Mtce_Mechanic_Name__c":"981291231","SF_PS_RM_External_Id__c":9812390812,"SF_PS_RM_Mtce_Steps_Y_N__c":"Y","SF_PS_RM_Mtce_Steps_StepNumber__c":"1","SF_PS_RM_Mtce_Steps_Meter_Reading_In__c":0,"SF_PS_RM_Mtce_Steps_Meter_Reading_Out__c":0,"SF_PS_RM_Mtce_Steps_Description__c":"","SF_PS_RM_Mtce_Steps_Pass_Fail__c":"P"}],"deletedLines":[{"SF_PS_RM_External_Id__c":""}]}';
        //request.requestBody = Blob.valueOf(JSON.serialize(jsonString));
        req.requestBody = Blob.valueOf(jsonString);
        
        RestContext.request = req;
        RestContext.response= res;
        
        User testAdminUser = [Select Id,Name from User where UserName LIKE 'testAdminUser%' ];
        system.debug('test request' + req);
        system.debug('test res' + res);
        
        //System.runAs(testAdminUser){
            insert new Bypass_Settings__c(SetupOwnerId=testAdminUser.Id, Bypass_Flow__c=true);
            Test.startTest();
            Asset testAsrt =  SBR_3_0_ServiceTestDataFactory.createAsset(true);
            
            //Create Exponce to Location
            ServiceTerritory  testE2Loc = SBR_3_0_ServiceTestDataFactory.createServiceTerritory(true);
            
            //Create Service Territory 
            //ServiceTerritory  testST = SBR_3_0_ServiceTestDataFactory.createServiceTerritory(false);
            OperatingHours oh = new OperatingHours(Name='TEST_Hours1',TimeZone='America/Halifax');
            insert oh;
            string name  ='TestHr';
        
            ServiceTerritory testST= new ServiceTerritory(Name=name,OperatingHoursId=oh.Id,IsActive=true,Branch_Location_Number__c = '1234',CountryCode = 'US');
            insert testST;
            
            ServiceResource testFactorySR = SBR_3_0_ServiceTestDataFactory.create_Service_Resource(false);
            User testUser = [Select Id,Name from User where UserName LIKE 'SRTestUser2%' Limit 1 ];
            testFactorySR.RelatedRecordId = testUser.Id;
            testFactorySR.ResourceType = 'T';
            insert testFactorySR;
            //create work order
            //workorder wop = SBR_3_0_ServiceTestDataFactory.createWorkOrder(false);
            //wop.SF_PS_RM_WO_Number__c = '01-333223234';
            //wop.SF_PS_Expense_To_Location__c = testST.id;
            //wop.AssetId = testAsrt.id;
            //wop.ServiceTerritoryId  = testE2Loc.id;
            //wop.SF_PS_Service_Resource__c = testFactorySR.id;
            //insert wop;
            Id worecordType = Schema.SObjectType.workorder.getRecordTypeInfosByName().get('Inspection Record').getRecordTypeId();
			
        	//workorderQuote(Parent)
			
			workorder woquote = SBR_3_0_ServiceTestDataFactory.createWorkOrder(false);
            woquote.SF_PS_RM_WO_Number__c = '01-333225';
            woquote.SF_PS_Expense_To_Location__c = testST.id;
            woquote.AssetId = testAsrt.id;
            woquote.ServiceTerritoryId  = testE2Loc.id;
            woquote.SF_PS_Service_Resource__c = testFactorySR.id;
            woquote.Pricebook2Id= standardPricebook.id;
            woquote.recordTypeId =Schema.SObjectType.workorder.getRecordTypeInfosByName().get('Quote').getRecordTypeId();
            //wo.ParentWorkOrderId = wop.Id;
            insert woquote;


            //create work order 
            workorder wo = SBR_3_0_ServiceTestDataFactory.createWorkOrder(false);
            wo.SF_PS_RM_WO_Number__c = '01-333222';
            wo.SF_PS_Expense_To_Location__c = testST.id;
            wo.AssetId = testAsrt.id;
            wo.ServiceTerritoryId  = testE2Loc.id;
            wo.SF_PS_Service_Resource__c = testFactorySR.id;
            wo.Pricebook2Id= standardPricebook.id;
            wo.recordTypeId =  worecordType;
        	wo.SF_PS_RM_Quote_Num__c = '12-352672';
            //wo.ParentWorkOrderId = wop.Id;
            insert wo;
            
            WorkOrderLineItem testwoli =  SBR_3_0_ServiceTestDataFactory.createWoli(false,wo.id,testFactorySR.id);
            testwoli.Duration = 1;
            if (testwoli != null) {
                insert testwoli;
            }
            //create product consumed
            ProductConsumed testPc =  SBR_3_0_ServiceTestDataFactory.createProductConsumedRecord(true ,wo.id, '1231231');
        
            //SF_PS_Maintenance_Steps__c testMc = SBR_3_0_ServiceTestDataFactory.createMaintenanceSteps(true,wo.id,testFactorySR.id);
            DueForService__c testDS = SBR_3_0_ServiceTestDataFactory.createDueForServiceRecord(true,testAsrt.id, '01');
            
            //ProductConsumed testPc =  SBR_3_0_ServiceTestDataFactory.createProductConsumedRecord(true ,wo.id, '1231239');
            //ceate Service Territory member 
            
            Profile objProfile = [Select Id, Name from Profile where Name =: 'System Administrator' limit 1];
            User objeUser = [Select Id, ProfileId from User where Id=: UserInfo.getUserId()];
            
            //User testrunUser = [Select Id,Name from User where SF_PS_Mechanic_Id__c='9812912317' ];
            //User AdminRunUser = [Select Id,Name from User where UserName LIKE 'AdminRunUser%' ];
            //system.debug('AdminRunUseris '+ AdminRunUser);
            System.debug('testFactorySR.id ' + testFactorySR.id);
            System.debug('testST.id ' + testST.id);
            //ServiceTerritoryMember testSTM =SBR_3_0_ServiceTestDataFactory.createServiceTerritoryMember(true,testFactorySR1.id,testST1.id);
            try {
                SBR_3_0_API_Web_WorkOrder.create();
                //system.assertEquals(200,res.statusCode);
                system.debug('test res 1st' + res);
            }Catch (Exception e) {
                System.debug('An Error Occur | ' + e);
                //system.assertEquals('Related Sales Rep not found!', e.getMessage(), 'Order API did not return Success!');
            }    
            Test.stopTest();
        //}
    }
    
    @isTest
    static void testupdateworkorderQuote(){
        //Get Custom setting 
        insert new Bypass_Settings__c(SetupOwnerId=UserInfo.getUserId(), Bypass_Flow__c=true);
        
        
        //Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_Web_Order_Test());
        Credential__c cred = SBR_3_0_TestDataFactory.createCredentials(1, false)[0];
        cred.Name = 'Mule_Token_Endpoint';
        cred.Key_Id__c = 'testKey123';
        cred.Secret__c = 'secret';
        insert cred;
        
        Id pricebookId = Test.getStandardPricebookId();
        Pricebook2 standardPricebook = new Pricebook2(
            name= 'Standard Price Book',
            Id = pricebookId,
            IsActive = true
        );
        update standardPricebook;
        system.debug('standardPricebook is' + standardPricebook.id);
        
        
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_Web_WorkOrder_Test());
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/WorkOrderQuote/ApiCreate/v1/*';
        req.httpMethod = 'POST';
        //String jsonString = '{ "EventType": "1","SF_PS_Company_Code__c": "01","Name": "Test Resouce","SF_PS_Hourly_Billing_Rate__c": 15.0,"SF_PS_Hourly_Internal_Rate__c": 15.0,"SF_PS_Overtime_Billing_Rate__c": 15.0,"SF_PS_Overtime_Internal_Rate__c": 15.0,"SF_PS_Labor_Type__c": "I","SF_PS_Type__c": "D","IsActive": true,"SF_PS_Branch_Loc_Num__c": "6666","SF_PS_Start_Date__c": "2023-02-22","SF_PS_RM_Created_DateTime__c": "2023-02-22T09:45:00Z","SF_PS_RM_Created_By__c": "Test User","SF_PS_RM_Update_DateTime__c": "2023-02-22T09:45:00Z","SF_PS_RM_Updated_By_User__c": "Test User","SF_PS_Mechanic_Id__c": "9999","SF_PS_Comments__c": "Yes api" }';
        // Old JSON String jsonString = '{"data":{"EventType":"1","Status":"Open","OwnerId":"1234","CurrencyIsoCode":"USD","AssetId":"1018879","SVMXA360_ContactPhone_c":"7036004000","SF_PS_Authorized_By__c":"","SF_PS_BillCustOrLoc__c":"L","SF_PS_PONumber__c":"","SF_PS_RM_WO_Number__c":"333222", "SF_PS_Expense_To_Location__c" : "1234","SF_PS_Cause__c":"","SF_PS_Company_Code__c":"01","SF_PS_Complaint__c":"","SF_PS_Cure__c":"","SF_PS_ExpenseCode__c":"RR","SF_PS_LaborCode__c":"9100","SF_PS_Cust_Eqp_Description__c":"","SF_PS_Current_MiHr__c":0.000,"SF_PS_Repair_Ticket__c":0,"SF_PS_Work_Order_Des__c":"CHECK IN RETURN","SF_PS_Current_MiHr2__c":0.000,"SF_PS_Service_Call__c":"Y","SF_PS_Warranty_Amt_Expected__c":0.00,"SF_PS_Claim_Type__c":"N","SF_PS_Actual_Claim_Amt__c":0.00, "SF_PS_Service_Resource__c":"50607", "SF_PS_Claim_Paid_Date__c":"2023-02-22","SF_PS_Claim_Num__c":"","SF_PS_Date_Claim_Filed__c":"2023-02-22","SF_PS_Sales_Rep__c":"111222","SF_PS_Funded__c":"Y","SF_PS_Closed_Date__c":"2023-02-22T09:45:00Z","SF_PS_Current_Loc__c": "0784", "SF_PS_Date_Opened__c":"2023-02-22T09:45:00Z","SF_PS_Charge_GST_Tax__c":false,"SF_PS_Charge_PST_Tax__c":false,"SF_PS_Drivers_License_Number__c":"","SF_PS_Job_Site__c":"","SF_PS_Job_Location__c":"","SF_PS_Due_Date__c":"2023-02-22T09:45:00Z","SF_PS_Labor_Des_Comments__c":"","SF_PS_Labor_Des_Internal__c":"","SF_PS_RM_Last_Maint_By__c":"","SF_PS_RM_Last_Maint_DateTime__c":"2023-02-22T09:45:00Z","SF_PS_Inv_Seq_Num__c":1234,"SF_PS_License_State__c":"OH"},"WorkOrderLineItem":[{"Duration":0.00,"SF_PS_Labor_Code__c":"1000","SF_PS_Mechanic_Name__c":"50607","SF_PS_Hourly_Internal_Rate__c":0.00,"SF_PS_RM_Labor_Line_Item_Number__c":"","SF_PS_RM_External_Id__c":"53474688","SF_PS_Line_Type__c":"LI","SF_PS_Mileage_Charge__c":"MileageCharge","SF_PS_RM_Item_Number__c":"87213143"}],"deletedLines": []}';
        String jsonString = '{"data":{"EventType":"1","Status":"Open","OwnerId":"1234","RecordTypeId" : "WORK ORDER QUOTE","CurrencyIsoCode":"USD","Pricebook2Id":"'+pricebookId+'","AssetId":"1018879","SVMXA360_ContactPhone_c":"7036004000","SF_PS_Authorized_By__c":"","SF_PS_BillCustOrLoc__c":"L","SF_PS_PONumber__c":"","SF_PS_RM_WO_Number__c":"333222","SF_PS_Expense_To_Location__c":"1234","SF_PS_Expense_To_Loc__c":"1234","SF_PS_Cause__c":"","SF_PS_Company_Code__c":"01","SF_PS_Complaint__c":"","SF_PS_Cure__c":"","SF_PS_ExpenseCode__c":"RR","SF_PS_LaborCode__c":"9100","SF_PS_Cust_Eqp_Description__c":"","SF_PS_Current_MiHr__c":0,"SF_PS_Repair_Ticket__c":0,"SF_PS_Work_Order_Des__c":"CHECK IN RETURN","SF_PS_Current_MiHr2__c":0,"SF_PS_Service_Call__c":"Y","SF_PS_Warranty_Amt_Expected__c":0,"SF_PS_Claim_Type__c":"N","SF_PS_Actual_Claim_Amt__c":0,"SF_PS_Service_Resource__c":"981291231","SF_PS_Claim_Paid_Date__c":"2023-02-22","SF_PS_Claim_Num__c":"","SF_PS_Date_Claim_Filed__c":"2023-02-22","SF_PS_Sales_Rep__c":"","SF_PS_Funded__c":"Y","SF_PS_Closed_Date__c":"2023-02-22T09:45:00Z","SF_PS_Current_Loc__c":"1234","SF_PS_Date_Opened__c":"2023-02-22T09:45:00Z","SF_PS_Charge_GST_Tax__c":false,"SF_PS_Charge_PST_Tax__c":false,"SF_PS_Drivers_License_Number__c":"","SF_PS_Job_Site__c":"","SF_PS_Job_Location__c":"","SF_PS_Due_Date__c":"2023-02-22T09:45:00Z","SF_PS_Labor_Des_Comments__c":"","SF_PS_Labor_Des_Internal__c":"","SF_PS_RM_Last_Maint_By__c":"","SF_PS_RM_Last_Maint_DateTime__c":"2023-02-22T09:45:00Z","SF_PS_Inv_Seq_Num__c":1234,"SF_PS_License_State__c":"OH"},"QuoteLineItem":[{"SF_PS_Duration__c":1,"SF_PS_Labor_Code__c":"1000","SF_PS_Mechanic_Name__c":"981291231","SF_PS_Hourly_Internal_Rate__c":0,"SF_PS_RM_Labor_Line_Item_Number__c":"","SF_PS_RM_External_Id__c":"3322123","SF_PS_Line_Type__c":"LI","SF_PS_Mileage_Charge__c":"MileageCharge","SF_PS_RM_Item_Number__c":"87213143"}],"QuotedParts":[{"SF_PS_RM_External_Id__c":"1231231","SF_PS_Parts_Line_Num__c":"","SF_PS_ItemType__c": "P","SF_PS_Selling_Price__c":0,"SF_PS_Cost_Price__c":0,"SF_PS_Line_Type__c":"LI","SF_PS_Product2Id__c":"10870996","SF_PS_Quantity__c":1,"SF_PS_Unit_Of_Measure__c":"EA","SF_PS_Labor_Code__c":"1000","SF_PS_Line_Level_Comment__c":"string","SF_PS_List_Price__c":0}],"maintenanceSteps":[{"SF_PS_RM_Mtce_Mechanic_Name__c":"981291231","SF_PS_RM_External_Id__c":9812390812,"SF_PS_RM_Mtce_Steps_Y_N__c":"Y","SF_PS_RM_Mtce_Steps_StepNumber__c":"1","SF_PS_RM_Mtce_Steps_Meter_Reading_In__c":0,"SF_PS_RM_Mtce_Steps_Meter_Reading_Out__c":0,"SF_PS_RM_Mtce_Steps_Description__c":"","SF_PS_RM_Mtce_Steps_Pass_Fail__c":"P"}],"deletedLines":[{"SF_PS_RM_External_Id__c":""}]}';
        //request.requestBody = Blob.valueOf(JSON.serialize(jsonString));
        req.requestBody = Blob.valueOf(jsonString);
        
        RestContext.request = req;
        RestContext.response= res;
        
        User testAdminUser = [Select Id,Name from User where UserName LIKE 'testAdminUser%' ];
        system.debug('test request' + req);
        system.debug('test res' + res);
        //System.runAs(testAdminUser){
            insert new Bypass_Settings__c(SetupOwnerId=testAdminUser.Id, Bypass_Flow__c=true);
            Test.startTest();
            Asset testAsrt =  SBR_3_0_ServiceTestDataFactory.createAsset(true);
            
            //Create Exponce to Location
            ServiceTerritory  testE2Loc = SBR_3_0_ServiceTestDataFactory.createServiceTerritory(true);
            
            //Create Service Territory 
            //ServiceTerritory  testST = SBR_3_0_ServiceTestDataFactory.createServiceTerritory(false);
            OperatingHours oh = new OperatingHours(Name='TEST_Hours1',TimeZone='America/Halifax');
            insert oh;
            string name  ='TestHr';
            ServiceTerritory testST= new ServiceTerritory(Name=name,OperatingHoursId=oh.Id,IsActive=true,Branch_Location_Number__c = '1234',CountryCode = 'US');
            insert testST;
            
            ServiceResource testFactorySR = SBR_3_0_ServiceTestDataFactory.create_Service_Resource(false);
            User testUser = [Select Id,Name from User where UserName LIKE 'SRTestUser2%' Limit 1 ];
            testFactorySR.RelatedRecordId = testUser.Id;
            testFactorySR.ResourceType = 'T';
            insert testFactorySR;
            
            //create work order
            //workorder wop = SBR_3_0_ServiceTestDataFactory.createWorkOrder(false);
            //wop.SF_PS_RM_WO_Number__c = '01-333223234';
            //wop.SF_PS_Expense_To_Location__c = testST.id;
            //wop.AssetId = testAsrt.id;
            //wop.ServiceTerritoryId  = testE2Loc.id;
            //wop.SF_PS_Service_Resource__c = testFactorySR.id;
            //insert wop;
            
            //create work order 
            workorder wo = SBR_3_0_ServiceTestDataFactory.createWorkOrder(false);
            wo.SF_PS_RM_WO_Number__c = '01-333222';
            wo.SF_PS_Expense_To_Location__c = testST.id;
            wo.AssetId = testAsrt.id;
            wo.ServiceTerritoryId  = testE2Loc.id;
            wo.SF_PS_Service_Resource__c = testFactorySR.id;
            wo.Pricebook2Id= standardPricebook.id;
            wo.recordTypeId =Schema.SObjectType.workorder.getRecordTypeInfosByName().get('Quote').getRecordTypeId();
            //wo.ParentWorkOrderId = wop.Id;
            insert wo;
            
            
            
            
            WorkOrderLineItem testwoli =  SBR_3_0_ServiceTestDataFactory.createWoli(false,wo.id,testFactorySR.id);
            testwoli.Duration = 1;
            if (testwoli != null) {
                insert testwoli;
            }
            //create product consumed
            ProductConsumed testPc =  SBR_3_0_ServiceTestDataFactory.createProductConsumedRecord(true ,wo.id, '1231231');
            //SF_PS_Maintenance_Steps__c testMc = SBR_3_0_ServiceTestDataFactory.createMaintenanceSteps(true,wo.id,testFactorySR.id);
            DueForService__c testDS = SBR_3_0_ServiceTestDataFactory.createDueForServiceRecord(true,testAsrt.id, '01');
            
            //ProductConsumed testPc =  SBR_3_0_ServiceTestDataFactory.createProductConsumedRecord(true ,wo.id, '1231239');
            //ceate Service Territory member 
            
            Profile objProfile = [Select Id, Name from Profile where Name =: 'System Administrator' limit 1];
            User objeUser = [Select Id, ProfileId from User where Id=: UserInfo.getUserId()];
            
            //User testrunUser = [Select Id,Name from User where SF_PS_Mechanic_Id__c='9812912317' ];
            //User AdminRunUser = [Select Id,Name from User where UserName LIKE 'AdminRunUser%' ];
            //system.debug('AdminRunUseris '+ AdminRunUser);
            System.debug('testFactorySR.id ' + testFactorySR.id);
            System.debug('testST.id ' + testST.id);
            //System.runAs(testrunUser) {
            //ServiceTerritoryMember testSTM =SBR_3_0_ServiceTestDataFactory.createServiceTerritoryMember(true,testFactorySR.id,testST.id);
            //}
            
            
            
            try {
                SBR_3_0_API_Web_WorkOrderQuote.create();
                //system.assertEquals(200,res.statusCode);
                system.debug('test res 1st' + res);
            }Catch (Exception e) {
                System.debug('An Error Occur | ' + e);
                //system.assertEquals('Related Sales Rep not found!', e.getMessage(), 'Order API did not return Success!');
            }    
            Test.stopTest();
        //}
        
    }
    
    @isTest
    static void testupdateWorkOrderCredit(){
        //Get Custom setting 
        insert new Bypass_Settings__c(SetupOwnerId=UserInfo.getUserId(), Bypass_Flow__c=true);
        
        
        //Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_Web_Order_Test());
        Credential__c cred = SBR_3_0_TestDataFactory.createCredentials(1, false)[0];
        cred.Name = 'Mule_Token_Endpoint';
        cred.Key_Id__c = 'testKey123';
        cred.Secret__c = 'secret';
        insert cred;
        
        Id pricebookId = Test.getStandardPricebookId();
        Pricebook2 standardPricebook = new Pricebook2(
            name= 'Standard Price Book',
            Id = pricebookId,
            IsActive = true
        );
        update standardPricebook;
        system.debug('standardPricebook is' + standardPricebook.id);
        
        
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_Web_WorkOrder_Test());
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/WorkOrderCredit/ApiCreate/v1/*';
        req.httpMethod = 'POST';
        //String jsonString = '{ "EventType": "1","SF_PS_Company_Code__c": "01","Name": "Test Resouce","SF_PS_Hourly_Billing_Rate__c": 15.0,"SF_PS_Hourly_Internal_Rate__c": 15.0,"SF_PS_Overtime_Billing_Rate__c": 15.0,"SF_PS_Overtime_Internal_Rate__c": 15.0,"SF_PS_Labor_Type__c": "I","SF_PS_Type__c": "D","IsActive": true,"SF_PS_Branch_Loc_Num__c": "6666","SF_PS_Start_Date__c": "2023-02-22","SF_PS_RM_Created_DateTime__c": "2023-02-22T09:45:00Z","SF_PS_RM_Created_By__c": "Test User","SF_PS_RM_Update_DateTime__c": "2023-02-22T09:45:00Z","SF_PS_RM_Updated_By_User__c": "Test User","SF_PS_Mechanic_Id__c": "9999","SF_PS_Comments__c": "Yes api" }';
        // Old JSON String jsonString = '{"data":{"EventType":"1","Status":"Open","OwnerId":"1234","CurrencyIsoCode":"USD","AssetId":"1018879","SVMXA360_ContactPhone_c":"7036004000","SF_PS_Authorized_By__c":"","SF_PS_BillCustOrLoc__c":"L","SF_PS_PONumber__c":"","SF_PS_RM_WO_Number__c":"333222", "SF_PS_Expense_To_Location__c" : "1234","SF_PS_Cause__c":"","SF_PS_Company_Code__c":"01","SF_PS_Complaint__c":"","SF_PS_Cure__c":"","SF_PS_ExpenseCode__c":"RR","SF_PS_LaborCode__c":"9100","SF_PS_Cust_Eqp_Description__c":"","SF_PS_Current_MiHr__c":0.000,"SF_PS_Repair_Ticket__c":0,"SF_PS_Work_Order_Des__c":"CHECK IN RETURN","SF_PS_Current_MiHr2__c":0.000,"SF_PS_Service_Call__c":"Y","SF_PS_Warranty_Amt_Expected__c":0.00,"SF_PS_Claim_Type__c":"N","SF_PS_Actual_Claim_Amt__c":0.00, "SF_PS_Service_Resource__c":"50607", "SF_PS_Claim_Paid_Date__c":"2023-02-22","SF_PS_Claim_Num__c":"","SF_PS_Date_Claim_Filed__c":"2023-02-22","SF_PS_Sales_Rep__c":"111222","SF_PS_Funded__c":"Y","SF_PS_Closed_Date__c":"2023-02-22T09:45:00Z","SF_PS_Current_Loc__c": "0784", "SF_PS_Date_Opened__c":"2023-02-22T09:45:00Z","SF_PS_Charge_GST_Tax__c":false,"SF_PS_Charge_PST_Tax__c":false,"SF_PS_Drivers_License_Number__c":"","SF_PS_Job_Site__c":"","SF_PS_Job_Location__c":"","SF_PS_Due_Date__c":"2023-02-22T09:45:00Z","SF_PS_Labor_Des_Comments__c":"","SF_PS_Labor_Des_Internal__c":"","SF_PS_RM_Last_Maint_By__c":"","SF_PS_RM_Last_Maint_DateTime__c":"2023-02-22T09:45:00Z","SF_PS_Inv_Seq_Num__c":1234,"SF_PS_License_State__c":"OH"},"WorkOrderLineItem":[{"Duration":0.00,"SF_PS_Labor_Code__c":"1000","SF_PS_Mechanic_Name__c":"50607","SF_PS_Hourly_Internal_Rate__c":0.00,"SF_PS_RM_Labor_Line_Item_Number__c":"","SF_PS_RM_External_Id__c":"53474688","SF_PS_Line_Type__c":"LI","SF_PS_Mileage_Charge__c":"MileageCharge","SF_PS_RM_Item_Number__c":"87213143"}],"deletedLines": []}';
        String jsonString = '{"data":{"EventType":"1","Status":"Open","OwnerId":"1234","RecordTypeId" : "WORK ORDER","CurrencyIsoCode":"USD","Pricebook2Id":"'+pricebookId+'","AssetId":"1018879","SVMXA360_ContactPhone_c":"7036004000","SF_PS_Authorized_By__c":"","SF_PS_BillCustOrLoc__c":"L","SF_PS_PONumber__c":"","SF_PS_RM_WO_Number__c":"333222","SF_PS_Expense_To_Location__c":"1234","SF_PS_Expense_To_Loc__c":"1234","SF_PS_Cause__c":"","SF_PS_Company_Code__c":"01","SF_PS_Complaint__c":"","SF_PS_Cure__c":"","SF_PS_ExpenseCode__c":"RR","SF_PS_LaborCode__c":"9100","SF_PS_Cust_Eqp_Description__c":"","SF_PS_Current_MiHr__c":0,"SF_PS_Repair_Ticket__c":0,"SF_PS_Work_Order_Des__c":"WORK ORDER CREDIT","SF_PS_Current_MiHr2__c":0,"SF_PS_Service_Call__c":"Y","SF_PS_Warranty_Amt_Expected__c":0,"SF_PS_Claim_Type__c":"N","SF_PS_Actual_Claim_Amt__c":0,"SF_PS_Service_Resource__c":"981291231","SF_PS_Claim_Paid_Date__c":"2023-02-22","SF_PS_Claim_Num__c":"","SF_PS_Date_Claim_Filed__c":"2023-02-22","SF_PS_Sales_Rep__c":"","SF_PS_Funded__c":"Y","SF_PS_Closed_Date__c":"2023-02-22T09:45:00Z","SF_PS_Current_Loc__c":"1234","SF_PS_Date_Opened__c":"2023-02-22T09:45:00Z","SF_PS_Charge_GST_Tax__c":false,"SF_PS_Charge_PST_Tax__c":false,"SF_PS_Drivers_License_Number__c":"","SF_PS_Job_Site__c":"","SF_PS_Job_Location__c":"","SF_PS_Due_Date__c":"2023-02-22T09:45:00Z","SF_PS_Labor_Des_Comments__c":"","SF_PS_Labor_Des_Internal__c":"","SF_PS_RM_Last_Maint_By__c":"","SF_PS_RM_Last_Maint_DateTime__c":"2023-02-22T09:45:00Z","SF_PS_Inv_Seq_Num__c":1234,"SF_PS_License_State__c":"OH"},"CreditLineItem":[{"SF_PS_Duration__c":1,"SF_PS_Labor_Code__c":"1000","SF_PS_Mechanic_Name__c":"981291231","SF_PS_Hourly_Internal_Rate__c":0,"SF_PS_RM_Labor_Line_Item_Number__c":"","SF_PS_RM_External_Id__c":"3322123","SF_PS_Line_Type__c":"LI","SF_PS_Mileage_Charge__c":"MileageCharge","SF_PS_RM_Item_Number__c":"87213143"}],"CreditParts":[{"SF_PS_RM_External_Id__c":"1231231","SF_PS_Parts_Line_Num__c":"","SF_PS_ItemType__c": "P","SF_PS_Selling_Price__c":0,"SF_PS_Cost_Price__c":0,"SF_PS_Line_Type__c":"LI","SF_PS_Product2Id__c":"10870996","SF_PS_Quantity__c":1,"SF_PS_Unit_Of_Measure__c":"EA","SF_PS_Labor_Code__c":"1000","SF_PS_Line_Level_Comment__c":"string","SF_PS_List_Price__c":0}],"deletedLines":[{"SF_PS_RM_External_Id__c":""}]}';
        //request.requestBody = Blob.valueOf(JSON.serialize(jsonString));
        req.requestBody = Blob.valueOf(jsonString);
        
        RestContext.request = req;
        RestContext.response= res;
        
        User testAdminUser = [Select Id,Name from User where UserName LIKE 'testAdminUser%' ];
        system.debug('test request' + req);
        system.debug('test res' + res);
        //System.runAs(testAdminUser){
            insert new Bypass_Settings__c(SetupOwnerId=testAdminUser.Id, Bypass_Flow__c=true);
            Test.startTest();
            Asset testAsrt =  SBR_3_0_ServiceTestDataFactory.createAsset(true);
            
            //Create Exponce to Location
            ServiceTerritory  testE2Loc = SBR_3_0_ServiceTestDataFactory.createServiceTerritory(true);
            
            //Create Service Territory 
            //ServiceTerritory  testST = SBR_3_0_ServiceTestDataFactory.createServiceTerritory(false);
            OperatingHours oh = new OperatingHours(Name='TEST_Hours1',TimeZone='America/Halifax');
            insert oh;
            string name  ='TestHr';
            ServiceTerritory testST= new ServiceTerritory(Name=name,OperatingHoursId=oh.Id,IsActive=true,Branch_Location_Number__c = '1234',CountryCode = 'US');
            insert testST;
            
            ServiceResource testFactorySR = SBR_3_0_ServiceTestDataFactory.create_Service_Resource(false);
            User testUser = [Select Id,Name from User where UserName LIKE 'SRTestUser2%' Limit 1 ];
            testFactorySR.RelatedRecordId = testUser.Id;
            testFactorySR.ResourceType = 'T';
            insert testFactorySR;
            
            //create work order
            //workorder wop = SBR_3_0_ServiceTestDataFactory.createWorkOrder(false);
            //wop.SF_PS_RM_WO_Number__c = '01-333223234';
            //wop.SF_PS_Expense_To_Location__c = testST.id;
            //wop.AssetId = testAsrt.id;
            //wop.ServiceTerritoryId  = testE2Loc.id;
            //wop.SF_PS_Service_Resource__c = testFactorySR.id;
            //insert wop;
            
            //Get Work order Credit Record Type
            List<RecordType> recTypeList = [
                SELECT Id, DeveloperName FROM RecordType WHERE DeveloperName =: 'SF_PS_Credit' AND SobjectType =: 'WorkOrder' LIMIT 1];
            
            //create work order 
            workorder wo = SBR_3_0_ServiceTestDataFactory.createWorkOrder(false);
            wo.SF_PS_RM_WO_Number__c = '01-333222';
            wo.SF_PS_Expense_To_Location__c = testST.id;
            wo.SF_PS_Work_Order_Des__c = 'WORK ORDER CREDIT';
            wo.AssetId = testAsrt.id;
            wo.ServiceTerritoryId  = testE2Loc.id;
            wo.SF_PS_Service_Resource__c = testFactorySR.id;
            wo.Pricebook2Id= standardPricebook.id;
            wo.RecordTypeId = recTypeList[0].id;
            //wo.ParentWorkOrderId = wop.Id;
            insert wo;
            
            
            
            
            WorkOrderLineItem testwoli =  SBR_3_0_ServiceTestDataFactory.createWoli(false,wo.id,testFactorySR.id);
            testwoli.Duration = 1;
            if (testwoli != null) {
                insert testwoli;
            }
            //create product consumed
            ProductConsumed testPc =  SBR_3_0_ServiceTestDataFactory.createProductConsumedRecord(true ,wo.id, '1231231');
            //SF_PS_Maintenance_Steps__c testMc = SBR_3_0_ServiceTestDataFactory.createMaintenanceSteps(true,wo.id,testFactorySR.id);
            DueForService__c testDS = SBR_3_0_ServiceTestDataFactory.createDueForServiceRecord(true,testAsrt.id, '01');
            
            //ProductConsumed testPc =  SBR_3_0_ServiceTestDataFactory.createProductConsumedRecord(true ,wo.id, '1231239');
            //ceate Service Territory member 
            
            Profile objProfile = [Select Id, Name from Profile where Name =: 'System Administrator' limit 1];
            User objeUser = [Select Id, ProfileId from User where Id=: UserInfo.getUserId()];
            
            //User testrunUser = [Select Id,Name from User where SF_PS_Mechanic_Id__c='9812912317' ];
            //User AdminRunUser = [Select Id,Name from User where UserName LIKE 'AdminRunUser%' ];
            //system.debug('AdminRunUseris '+ AdminRunUser);
            System.debug('testFactorySR.id ' + testFactorySR.id);
            System.debug('testST.id ' + testST.id);
            //System.runAs(testrunUser) {
            //ServiceTerritoryMember testSTM =SBR_3_0_ServiceTestDataFactory.createServiceTerritoryMember(true,testFactorySR.id,testST.id);
            //}
            
            
            
            try {
                SBR_3_0_API_Web_WorkOrderCredit.create();
                //system.assertEquals(200,res.statusCode);
                system.debug('test res 1st' + res);
            }Catch (Exception e) {
                System.debug('An Error Occur | ' + e);
                //system.assertEquals('Related Sales Rep not found!', e.getMessage(), 'Order API did not return Success!');
            }    
            Test.stopTest();
        //}
    }

	@isTest
    static void testupdateCreditWithParent(){
        //Get Custom setting 
        insert new Bypass_Settings__c(SetupOwnerId=UserInfo.getUserId(), Bypass_Flow__c=true);
        
        
        //Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_Web_Order_Test());
        Credential__c cred = SBR_3_0_TestDataFactory.createCredentials(1, false)[0];
        cred.Name = 'Mule_Token_Endpoint';
        cred.Key_Id__c = 'testKey123';
        cred.Secret__c = 'secret';
        insert cred;
        
        Id pricebookId = Test.getStandardPricebookId();
        Pricebook2 standardPricebook = new Pricebook2(
            name= 'Standard Price Book',
            Id = pricebookId,
            IsActive = true
        );
        update standardPricebook;
        system.debug('standardPricebook is' + standardPricebook.id);
        
        
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_Web_WorkOrder_Test());
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/WorkOrderCredit/ApiCreate/v1/*';
        req.httpMethod = 'POST';
        //String jsonString = '{ "EventType": "1","SF_PS_Company_Code__c": "01","Name": "Test Resouce","SF_PS_Hourly_Billing_Rate__c": 15.0,"SF_PS_Hourly_Internal_Rate__c": 15.0,"SF_PS_Overtime_Billing_Rate__c": 15.0,"SF_PS_Overtime_Internal_Rate__c": 15.0,"SF_PS_Labor_Type__c": "I","SF_PS_Type__c": "D","IsActive": true,"SF_PS_Branch_Loc_Num__c": "6666","SF_PS_Start_Date__c": "2023-02-22","SF_PS_RM_Created_DateTime__c": "2023-02-22T09:45:00Z","SF_PS_RM_Created_By__c": "Test User","SF_PS_RM_Update_DateTime__c": "2023-02-22T09:45:00Z","SF_PS_RM_Updated_By_User__c": "Test User","SF_PS_Mechanic_Id__c": "9999","SF_PS_Comments__c": "Yes api" }';
        // Old JSON String jsonString = '{"data":{"EventType":"1","Status":"Open","OwnerId":"1234","CurrencyIsoCode":"USD","AssetId":"1018879","SVMXA360_ContactPhone_c":"7036004000","SF_PS_Authorized_By__c":"","SF_PS_BillCustOrLoc__c":"L","SF_PS_PONumber__c":"","SF_PS_RM_WO_Number__c":"333222", "SF_PS_Expense_To_Location__c" : "1234","SF_PS_Cause__c":"","SF_PS_Company_Code__c":"01","SF_PS_Complaint__c":"","SF_PS_Cure__c":"","SF_PS_ExpenseCode__c":"RR","SF_PS_LaborCode__c":"9100","SF_PS_Cust_Eqp_Description__c":"","SF_PS_Current_MiHr__c":0.000,"SF_PS_Repair_Ticket__c":0,"SF_PS_Work_Order_Des__c":"CHECK IN RETURN","SF_PS_Current_MiHr2__c":0.000,"SF_PS_Service_Call__c":"Y","SF_PS_Warranty_Amt_Expected__c":0.00,"SF_PS_Claim_Type__c":"N","SF_PS_Actual_Claim_Amt__c":0.00, "SF_PS_Service_Resource__c":"50607", "SF_PS_Claim_Paid_Date__c":"2023-02-22","SF_PS_Claim_Num__c":"","SF_PS_Date_Claim_Filed__c":"2023-02-22","SF_PS_Sales_Rep__c":"111222","SF_PS_Funded__c":"Y","SF_PS_Closed_Date__c":"2023-02-22T09:45:00Z","SF_PS_Current_Loc__c": "0784", "SF_PS_Date_Opened__c":"2023-02-22T09:45:00Z","SF_PS_Charge_GST_Tax__c":false,"SF_PS_Charge_PST_Tax__c":false,"SF_PS_Drivers_License_Number__c":"","SF_PS_Job_Site__c":"","SF_PS_Job_Location__c":"","SF_PS_Due_Date__c":"2023-02-22T09:45:00Z","SF_PS_Labor_Des_Comments__c":"","SF_PS_Labor_Des_Internal__c":"","SF_PS_RM_Last_Maint_By__c":"","SF_PS_RM_Last_Maint_DateTime__c":"2023-02-22T09:45:00Z","SF_PS_Inv_Seq_Num__c":1234,"SF_PS_License_State__c":"OH"},"WorkOrderLineItem":[{"Duration":0.00,"SF_PS_Labor_Code__c":"1000","SF_PS_Mechanic_Name__c":"50607","SF_PS_Hourly_Internal_Rate__c":0.00,"SF_PS_RM_Labor_Line_Item_Number__c":"","SF_PS_RM_External_Id__c":"53474688","SF_PS_Line_Type__c":"LI","SF_PS_Mileage_Charge__c":"MileageCharge","SF_PS_RM_Item_Number__c":"87213143"}],"deletedLines": []}';
        String jsonString = '{"data":{"EventType":"1","Status":"Open","OwnerId":"1234","RecordTypeId" : "WORK ORDER","SF_PS_RM_Credited_WO_Number__c": "333226" ,"CurrencyIsoCode":"USD","Pricebook2Id":"'+pricebookId+'","AssetId":"1018879","SVMXA360_ContactPhone_c":"7036004000","SF_PS_Authorized_By__c":"","SF_PS_BillCustOrLoc__c":"L","SF_PS_PONumber__c":"","SF_PS_RM_WO_Number__c":"333222","SF_PS_Expense_To_Location__c":"1234","SF_PS_Expense_To_Loc__c":"1234","SF_PS_Cause__c":"","SF_PS_Company_Code__c":"01","SF_PS_Complaint__c":"","SF_PS_Cure__c":"","SF_PS_ExpenseCode__c":"RR","SF_PS_LaborCode__c":"9100","SF_PS_Cust_Eqp_Description__c":"","SF_PS_Current_MiHr__c":0,"SF_PS_Repair_Ticket__c":0,"SF_PS_Work_Order_Des__c":"WORK ORDER CREDIT","SF_PS_Current_MiHr2__c":0,"SF_PS_Service_Call__c":"Y","SF_PS_Warranty_Amt_Expected__c":0,"SF_PS_Claim_Type__c":"N","SF_PS_Actual_Claim_Amt__c":0,"SF_PS_Service_Resource__c":"981291231","SF_PS_Claim_Paid_Date__c":"2023-02-22","SF_PS_Claim_Num__c":"","SF_PS_Date_Claim_Filed__c":"2023-02-22","SF_PS_Sales_Rep__c":"","SF_PS_Funded__c":"Y","SF_PS_Closed_Date__c":"2023-02-22T09:45:00Z","SF_PS_Current_Loc__c":"1234","SF_PS_Date_Opened__c":"2023-02-22T09:45:00Z","SF_PS_Charge_GST_Tax__c":false,"SF_PS_Charge_PST_Tax__c":false,"SF_PS_Drivers_License_Number__c":"","SF_PS_Job_Site__c":"","SF_PS_Job_Location__c":"","SF_PS_Due_Date__c":"2023-02-22T09:45:00Z","SF_PS_Labor_Des_Comments__c":"","SF_PS_Labor_Des_Internal__c":"","SF_PS_RM_Last_Maint_By__c":"","SF_PS_RM_Last_Maint_DateTime__c":"2023-02-22T09:45:00Z","SF_PS_Inv_Seq_Num__c":1234,"SF_PS_License_State__c":"OH"},"CreditLineItem":[{"SF_PS_Duration__c":1,"SF_PS_Labor_Code__c":"1000","SF_PS_Mechanic_Name__c":"981291231","SF_PS_Hourly_Internal_Rate__c":0,"SF_PS_RM_Labor_Line_Item_Number__c":"","SF_PS_RM_External_Id__c":"3322123","SF_PS_Line_Type__c":"LI","SF_PS_Mileage_Charge__c":"MileageCharge","SF_PS_RM_Item_Number__c":"87213143"}],"CreditParts":[{"SF_PS_RM_External_Id__c":"1231231","SF_PS_Parts_Line_Num__c":"","SF_PS_ItemType__c": "P","SF_PS_Selling_Price__c":0,"SF_PS_Cost_Price__c":0,"SF_PS_Line_Type__c":"LI","SF_PS_Product2Id__c":"10870996","SF_PS_Quantity__c":1,"SF_PS_Unit_Of_Measure__c":"EA","SF_PS_Labor_Code__c":"1000","SF_PS_Line_Level_Comment__c":"string","SF_PS_List_Price__c":0}],"deletedLines":[{"SF_PS_RM_External_Id__c":""}]}';
        //request.requestBody = Blob.valueOf(JSON.serialize(jsonString));
        req.requestBody = Blob.valueOf(jsonString);
        
        RestContext.request = req;
        RestContext.response= res;
        
        User testAdminUser = [Select Id,Name from User where UserName LIKE 'testAdminUser%' ];
        system.debug('test request' + req);
        system.debug('test res' + res);
        //System.runAs(testAdminUser){
            insert new Bypass_Settings__c(SetupOwnerId=testAdminUser.Id, Bypass_Flow__c=true);
            Test.startTest();
            Asset testAsrt =  SBR_3_0_ServiceTestDataFactory.createAsset(true);
            
            //Create Exponce to Location
            ServiceTerritory  testE2Loc = SBR_3_0_ServiceTestDataFactory.createServiceTerritory(true);
            
            //Create Service Territory 
            //ServiceTerritory  testST = SBR_3_0_ServiceTestDataFactory.createServiceTerritory(false);
            OperatingHours oh = new OperatingHours(Name='TEST_Hours1',TimeZone='America/Halifax');
            insert oh;
            string name  ='TestHr';
            ServiceTerritory testST= new ServiceTerritory(Name=name,OperatingHoursId=oh.Id,IsActive=true,Branch_Location_Number__c = '1234',CountryCode = 'US');
            insert testST;
            
            ServiceResource testFactorySR = SBR_3_0_ServiceTestDataFactory.create_Service_Resource(false);
            User testUser = [Select Id,Name from User where UserName LIKE 'SRTestUser2%' Limit 1 ];
            testFactorySR.RelatedRecordId = testUser.Id;
            testFactorySR.ResourceType = 'T';
            insert testFactorySR;
            
            //create work order
            //workorder wop = SBR_3_0_ServiceTestDataFactory.createWorkOrder(false);
            //wop.SF_PS_RM_WO_Number__c = '01-333223234';
            //wop.SF_PS_Expense_To_Location__c = testST.id;
            //wop.AssetId = testAsrt.id;
            //wop.ServiceTerritoryId  = testE2Loc.id;
            //wop.SF_PS_Service_Resource__c = testFactorySR.id;
            //insert wop;
            
            //Get Work order Credit Record Type
            List<RecordType> recTypeList = [
                SELECT Id, DeveloperName FROM RecordType WHERE DeveloperName =: 'SF_PS_Credit' AND SobjectType =: 'WorkOrder' LIMIT 1];
        	    
        	//create work order Inspection (Parent)
            workorder woispection = SBR_3_0_ServiceTestDataFactory.createWorkOrder(false);
            woIspection.SF_PS_RM_WO_Number__c = '01-333226';
            woIspection.SF_PS_Expense_To_Location__c = testST.id;
            woIspection.AssetId = testAsrt.id;
            woIspection.ServiceTerritoryId  = testE2Loc.id;
            woIspection.SF_PS_Service_Resource__c = testFactorySR.id;
            woIspection.Pricebook2Id= standardPricebook.id;
            woIspection.recordTypeId =  Schema.SObjectType.workorder.getRecordTypeInfosByName().get('Inspection Record').getRecordTypeId();
            insert woIspection;
        
            //create work order 
            workorder wo = SBR_3_0_ServiceTestDataFactory.createWorkOrder(false);
            wo.SF_PS_RM_WO_Number__c = '01-333222';
            wo.SF_PS_Expense_To_Location__c = testST.id;
            wo.SF_PS_Work_Order_Des__c = 'WORK ORDER CREDIT';
            wo.AssetId = testAsrt.id;
            wo.ServiceTerritoryId  = testE2Loc.id;
            wo.SF_PS_Service_Resource__c = testFactorySR.id;
            wo.Pricebook2Id= standardPricebook.id;
            wo.RecordTypeId = recTypeList[0].id;
            //wo.ParentWorkOrderId = wop.Id;
            insert wo;
            
            
            
            
            WorkOrderLineItem testwoli =  SBR_3_0_ServiceTestDataFactory.createWoli(false,wo.id,testFactorySR.id);
            testwoli.Duration = 1;
            if (testwoli != null) {
                insert testwoli;
            }
            //create product consumed
            ProductConsumed testPc =  SBR_3_0_ServiceTestDataFactory.createProductConsumedRecord(true ,wo.id, '1231231');
            //SF_PS_Maintenance_Steps__c testMc = SBR_3_0_ServiceTestDataFactory.createMaintenanceSteps(true,wo.id,testFactorySR.id);
            DueForService__c testDS = SBR_3_0_ServiceTestDataFactory.createDueForServiceRecord(true,testAsrt.id, '01');
            
            //ProductConsumed testPc =  SBR_3_0_ServiceTestDataFactory.createProductConsumedRecord(true ,wo.id, '1231239');
            //ceate Service Territory member 
            
            Profile objProfile = [Select Id, Name from Profile where Name =: 'System Administrator' limit 1];
            User objeUser = [Select Id, ProfileId from User where Id=: UserInfo.getUserId()];
            
            //User testrunUser = [Select Id,Name from User where SF_PS_Mechanic_Id__c='9812912317' ];
            //User AdminRunUser = [Select Id,Name from User where UserName LIKE 'AdminRunUser%' ];
            //system.debug('AdminRunUseris '+ AdminRunUser);
            System.debug('testFactorySR.id ' + testFactorySR.id);
            System.debug('testST.id ' + testST.id);
            //System.runAs(testrunUser) {
            //ServiceTerritoryMember testSTM =SBR_3_0_ServiceTestDataFactory.createServiceTerritoryMember(true,testFactorySR.id,testST.id);
            //}
            
            
            
            try {
                SBR_3_0_API_Web_WorkOrderCredit.create();
                //system.assertEquals(200,res.statusCode);
                system.debug('test res 1st' + res);
            }Catch (Exception e) {
                System.debug('An Error Occur | ' + e);
                //system.assertEquals('Related Sales Rep not found!', e.getMessage(), 'Order API did not return Success!');
            }    
            Test.stopTest();
        //}
    }
    
     
    @isTest
    static void testupdateServiceResourceFail(){
        
        //Get Custom setting 
        insert new Bypass_Settings__c(SetupOwnerId=UserInfo.getUserId(), Bypass_Flow__c=true);
        //Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_Web_Order_Test());
        Credential__c cred = SBR_3_0_TestDataFactory.createCredentials(1, false)[0];
        cred.Name = 'Mule_Token_Endpoint';
        cred.Key_Id__c = 'testKey123';
        cred.Secret__c = 'secret';
        insert cred;
        
        Id pricebookId = Test.getStandardPricebookId();
        Pricebook2 standardPricebook = new Pricebook2(
            name= 'Standard Price Book',
            Id = pricebookId,
            IsActive = true
        );
        update standardPricebook;
        system.debug('standardPricebook is' + standardPricebook.id);
        
        
        
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_Web_WorkOrder_Test());
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/WorkOrder/ApiCreate/v1/*';
        req.httpMethod = 'POST';
        //String jsonString = '{ "EventType": "1","SF_PS_Company_Code__c": "01","Name": "Test Resouce","SF_PS_Hourly_Billing_Rate__c": 15.0,"SF_PS_Hourly_Internal_Rate__c": 15.0,"SF_PS_Overtime_Billing_Rate__c": 15.0,"SF_PS_Overtime_Internal_Rate__c": 15.0,"SF_PS_Labor_Type__c": "I","SF_PS_Type__c": "D","IsActive": true,"SF_PS_Branch_Loc_Num__c": "6666","SF_PS_Start_Date__c": "2023-02-22","SF_PS_RM_Created_DateTime__c": "2023-02-22T09:45:00Z","SF_PS_RM_Created_By__c": "Test User","SF_PS_RM_Update_DateTime__c": "2023-02-22T09:45:00Z","SF_PS_RM_Updated_By_User__c": "Test User","SF_PS_Mechanic_Id__c": "9999","SF_PS_Comments__c": "Yes api" }';
        // Old JSON String jsonString = '{"data":{"EventType":"1","Status":"Open","OwnerId":"1234","CurrencyIsoCode":"USD","AssetId":"1018879","SVMXA360_ContactPhone_c":"7036004000","SF_PS_Authorized_By__c":"","SF_PS_BillCustOrLoc__c":"L","SF_PS_PONumber__c":"","SF_PS_RM_WO_Number__c":"333222", "SF_PS_Expense_To_Location__c" : "1234","SF_PS_Cause__c":"","SF_PS_Company_Code__c":"01","SF_PS_Complaint__c":"","SF_PS_Cure__c":"","SF_PS_ExpenseCode__c":"RR","SF_PS_LaborCode__c":"9100","SF_PS_Cust_Eqp_Description__c":"","SF_PS_Current_MiHr__c":0.000,"SF_PS_Repair_Ticket__c":0,"SF_PS_Work_Order_Des__c":"CHECK IN RETURN","SF_PS_Current_MiHr2__c":0.000,"SF_PS_Service_Call__c":"Y","SF_PS_Warranty_Amt_Expected__c":0.00,"SF_PS_Claim_Type__c":"N","SF_PS_Actual_Claim_Amt__c":0.00, "SF_PS_Service_Resource__c":"50607", "SF_PS_Claim_Paid_Date__c":"2023-02-22","SF_PS_Claim_Num__c":"","SF_PS_Date_Claim_Filed__c":"2023-02-22","SF_PS_Sales_Rep__c":"111222","SF_PS_Funded__c":"Y","SF_PS_Closed_Date__c":"2023-02-22T09:45:00Z","SF_PS_Current_Loc__c": "0784", "SF_PS_Date_Opened__c":"2023-02-22T09:45:00Z","SF_PS_Charge_GST_Tax__c":false,"SF_PS_Charge_PST_Tax__c":false,"SF_PS_Drivers_License_Number__c":"","SF_PS_Job_Site__c":"","SF_PS_Job_Location__c":"","SF_PS_Due_Date__c":"2023-02-22T09:45:00Z","SF_PS_Labor_Des_Comments__c":"","SF_PS_Labor_Des_Internal__c":"","SF_PS_RM_Last_Maint_By__c":"","SF_PS_RM_Last_Maint_DateTime__c":"2023-02-22T09:45:00Z","SF_PS_Inv_Seq_Num__c":1234,"SF_PS_License_State__c":"OH"},"WorkOrderLineItem":[{"Duration":0.00,"SF_PS_Labor_Code__c":"1000","SF_PS_Mechanic_Name__c":"50607","SF_PS_Hourly_Internal_Rate__c":0.00,"SF_PS_RM_Labor_Line_Item_Number__c":"","SF_PS_RM_External_Id__c":"53474688","SF_PS_Line_Type__c":"LI","SF_PS_Mileage_Charge__c":"MileageCharge","SF_PS_RM_Item_Number__c":"87213143"}],"deletedLines": []}';
        String jsonString = '{"data":{"EventType":"1","Status":"Open","OwnerId":"1234","CurrencyIsoCode":"USD","Pricebook2Id":"'+pricebookId+'","AssetId":"1018879","SVMXA360_ContactPhone_c":"7036004000","SF_PS_Authorized_By__c":"","SF_PS_BillCustOrLoc__c":"L","SF_PS_PONumber__c":"","SF_PS_RM_WO_Number__c":"333222","SF_PS_Expense_To_Location__c":"1234","SF_PS_Expense_To_Loc__c":"1234","SF_PS_Cause__c":"","SF_PS_Company_Code__c":"","SF_PS_Complaint__c":"","SF_PS_Cure__c":"","SF_PS_ExpenseCode__c":"RR","SF_PS_LaborCode__c":"9100","SF_PS_Cust_Eqp_Description__c":"","SF_PS_Current_MiHr__c":0,"SF_PS_Repair_Ticket__c":0,"SF_PS_Work_Order_Des__c":"CHECK IN RETURN","SF_PS_Current_MiHr2__c":0,"SF_PS_Service_Call__c":"Y","SF_PS_Warranty_Amt_Expected__c":0,"SF_PS_Claim_Type__c":"N","SF_PS_Actual_Claim_Amt__c":0,"SF_PS_Service_Resource__c":"981291231","SF_PS_Claim_Paid_Date__c":"2023-02-22","SF_PS_Claim_Num__c":"","SF_PS_Date_Claim_Filed__c":"2023-02-22","SF_PS_Sales_Rep__c":"111222","SF_PS_Funded__c":"Y","SF_PS_Closed_Date__c":"2023-02-22T09:45:00Z","SF_PS_Current_Loc__c":"1234","SF_PS_Date_Opened__c":"2023-02-22T09:45:00Z","SF_PS_Charge_GST_Tax__c":false,"SF_PS_Charge_PST_Tax__c":false,"SF_PS_Drivers_License_Number__c":"","SF_PS_Job_Site__c":"","SF_PS_Job_Location__c":"","SF_PS_Due_Date__c":"2023-02-22T09:45:00Z","SF_PS_Labor_Des_Comments__c":"","SF_PS_Labor_Des_Internal__c":"","SF_PS_RM_Last_Maint_By__c":"","SF_PS_RM_Last_Maint_DateTime__c":"2023-02-22T09:45:00Z","SF_PS_Inv_Seq_Num__c":1234,"SF_PS_License_State__c":"OH"},"WorkOrderLineItem":[{"Duration":0,"SF_PS_Labor_Code__c":"1000","SF_PS_Mechanic_Name__c":"981291231","SF_PS_Hourly_Internal_Rate__c":0,"SF_PS_RM_Labor_Line_Item_Number__c":"","SF_PS_RM_External_Id__c":"3322123","SF_PS_Line_Type__c":"LI","SF_PS_Mileage_Charge__c":"MileageCharge","SF_PS_RM_Item_Number__c":"87213143"}],"ProductConsumed":[{"SF_PS_RM_External_Id__c":"1231231","SF_PS_Parts_Line_Num__c":"","SF_PS_Selling_Price__c":0,"SF_PS_Cost_Price__c":0,"SF_PS_Line_Type__c":"WO","Product2Id":"10870996","SF_PS_Quantity__c":1,"SF_PS_Unit_Of_Measure__c":"EA","SF_PS_Labor_Code__c":"1000","SF_PS_Line_Level_Comment__c":"string","SF_PS_List_Price__c":0}],"maintenanceSteps":[{"SF_PS_RM_Mtce_Mechanic_Name__c":"981291231","SF_PS_RM_External_Id__c":9812390812,"SF_PS_RM_Mtce_Steps_Y_N__c":"Y","SF_PS_RM_Mtce_Steps_StepNumber__c":0,"SF_PS_RM_Mtce_Steps_Meter_Reading_In__c":0,"SF_PS_RM_Mtce_Steps_Meter_Reading_Out__c":0,"SF_PS_RM_Mtce_Steps_Description__c":"","SF_PS_RM_Mtce_Steps_Pass_Fail__c":"P"}],"deletedLines":[{"SF_PS_RM_External_Id__c":""}]}';
        //request.requestBody = Blob.valueOf(JSON.serialize(jsonString));
        req.requestBody = Blob.valueOf(jsonString);
        
        RestContext.request = req;
        RestContext.response= res;
        
        User testAdminUser = [Select Id,Name from User where UserName LIKE 'testAdminUser%' ];
        system.debug('test request' + req);
        system.debug('test res' + res);
        //System.runAs(testAdminUser){
            insert new Bypass_Settings__c(SetupOwnerId=testAdminUser.Id, Bypass_Flow__c=true);
            Test.startTest();
            Asset testAsrt =  SBR_3_0_ServiceTestDataFactory.createAsset(true);
            
            //Create Exponce to Location
            ServiceTerritory  testE2Loc = SBR_3_0_ServiceTestDataFactory.createServiceTerritory(true);
            
            //Create Service Territory 
            //ServiceTerritory  testST = SBR_3_0_ServiceTestDataFactory.createServiceTerritory(false);
            OperatingHours oh = new OperatingHours(Name='TEST_Hours1',TimeZone='America/Halifax');
            insert oh;
            string name  ='TestHr';
            ServiceTerritory testST= new ServiceTerritory(Name=name,OperatingHoursId=oh.Id,IsActive=true,Branch_Location_Number__c = '1234',CountryCode = 'US');
            insert testST;
            
            ServiceResource testFactorySR = SBR_3_0_ServiceTestDataFactory.create_Service_Resource(false);
            User testUser = [Select Id,Name from User where UserName LIKE 'SRTestUser2%' LIMIT 1 ];
            testFactorySR.RelatedRecordId = testUser.Id;
            testFactorySR.ResourceType = 'T';
            insert testFactorySR;
            
            
            //create work order 
            workorder wo = SBR_3_0_ServiceTestDataFactory.createWorkOrder(false);
            wo.SF_PS_RM_WO_Number__c = '01-333222';
            wo.SF_PS_Expense_To_Location__c = testST.id;
            wo.AssetId = testAsrt.id;
            wo.ServiceTerritoryId  = testE2Loc.id;
            wo.SF_PS_Service_Resource__c = testFactorySR.id;
            wo.Pricebook2Id= standardPricebook.id;
            wo.recordTypeId =Schema.SObjectType.workorder.getRecordTypeInfosByName().get('Inspection Record').getRecordTypeId();
            
            insert wo;
            
            
            WorkOrderLineItem testwoli =  SBR_3_0_ServiceTestDataFactory.createWoli(false,wo.id,testFactorySR.id);
            testwoli.Duration = 1;
            if (testwoli != null) {
                insert testwoli;
            }
            //create product consumed
            ProductConsumed testPc =  SBR_3_0_ServiceTestDataFactory.createProductConsumedRecord(true ,wo.id, '1231231');
            SF_PS_Maintenance_Steps__c testMc = SBR_3_0_ServiceTestDataFactory.createMaintenanceSteps(true,wo.id,testFactorySR.id);
            
            //ProductConsumed testPc =  SBR_3_0_ServiceTestDataFactory.createProductConsumedRecord(true ,wo.id, '1231239');
            //ceate Service Territory member 
            User testrunUser = [Select Id,Name from User where UserName LIKE 'testAdminUser%' ];
            //User AdminRunUser = [Select Id,Name from User where UserName LIKE 'AdminRunUser%' ];
            //system.debug('AdminRunUseris '+ AdminRunUser);
            //System.runAs(AdminRunUser){
            //ServiceTerritoryMember testSTM =SBR_3_0_ServiceTestDataFactory.createServiceTerritoryMember(true,testFactorySR.id,testST.id);
            
            //}
            
            
            
            try {
                SBR_3_0_API_Web_WorkOrder.create();
                //system.assertEquals(200,res.statusCode);
                system.debug('test res 1st' + res);
            }Catch (Exception e) {
                System.debug('An Error Occur | ' + e);
                //system.assertEquals('Related Sales Rep not found!', e.getMessage(), 'Order API did not return Success!');
            }    
            Test.stopTest();
       // }
        
        
    }
    @isTest
    static void testWorkOrderFail(){
        
        //Get Custom setting 
        insert new Bypass_Settings__c(SetupOwnerId=UserInfo.getUserId(), Bypass_Flow__c=true);
        //Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_Web_Order_Test());
        Credential__c cred = SBR_3_0_TestDataFactory.createCredentials(1, false)[0];
        cred.Name = 'Mule_Token_Endpoint';
        cred.Key_Id__c = 'testKey123';
        cred.Secret__c = 'secret';
        insert cred;
        
        Id pricebookId = Test.getStandardPricebookId();
        Pricebook2 standardPricebook = new Pricebook2(
            name= 'Standard Price Book',
            Id = pricebookId,
            IsActive = true
        );
        update standardPricebook;
        system.debug('standardPricebook is' + standardPricebook.id);
        
        
        
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_Web_WorkOrder_Test());
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/WorkOrder/ApiCreate/v1/*';
        req.httpMethod = 'POST';
        //String jsonString = '{ "EventType": "1","SF_PS_Company_Code__c": "01","Name": "Test Resouce","SF_PS_Hourly_Billing_Rate__c": 15.0,"SF_PS_Hourly_Internal_Rate__c": 15.0,"SF_PS_Overtime_Billing_Rate__c": 15.0,"SF_PS_Overtime_Internal_Rate__c": 15.0,"SF_PS_Labor_Type__c": "I","SF_PS_Type__c": "D","IsActive": true,"SF_PS_Branch_Loc_Num__c": "6666","SF_PS_Start_Date__c": "2023-02-22","SF_PS_RM_Created_DateTime__c": "2023-02-22T09:45:00Z","SF_PS_RM_Created_By__c": "Test User","SF_PS_RM_Update_DateTime__c": "2023-02-22T09:45:00Z","SF_PS_RM_Updated_By_User__c": "Test User","SF_PS_Mechanic_Id__c": "9999","SF_PS_Comments__c": "Yes api" }';
        // Old JSON String jsonString = '{"data":{"EventType":"1","Status":"Open","OwnerId":"1234","CurrencyIsoCode":"USD","AssetId":"1018879","SVMXA360_ContactPhone_c":"7036004000","SF_PS_Authorized_By__c":"","SF_PS_BillCustOrLoc__c":"L","SF_PS_PONumber__c":"","SF_PS_RM_WO_Number__c":"333222", "SF_PS_Expense_To_Location__c" : "1234","SF_PS_Cause__c":"","SF_PS_Company_Code__c":"01","SF_PS_Complaint__c":"","SF_PS_Cure__c":"","SF_PS_ExpenseCode__c":"RR","SF_PS_LaborCode__c":"9100","SF_PS_Cust_Eqp_Description__c":"","SF_PS_Current_MiHr__c":0.000,"SF_PS_Repair_Ticket__c":0,"SF_PS_Work_Order_Des__c":"CHECK IN RETURN","SF_PS_Current_MiHr2__c":0.000,"SF_PS_Service_Call__c":"Y","SF_PS_Warranty_Amt_Expected__c":0.00,"SF_PS_Claim_Type__c":"N","SF_PS_Actual_Claim_Amt__c":0.00, "SF_PS_Service_Resource__c":"50607", "SF_PS_Claim_Paid_Date__c":"2023-02-22","SF_PS_Claim_Num__c":"","SF_PS_Date_Claim_Filed__c":"2023-02-22","SF_PS_Sales_Rep__c":"111222","SF_PS_Funded__c":"Y","SF_PS_Closed_Date__c":"2023-02-22T09:45:00Z","SF_PS_Current_Loc__c": "0784", "SF_PS_Date_Opened__c":"2023-02-22T09:45:00Z","SF_PS_Charge_GST_Tax__c":false,"SF_PS_Charge_PST_Tax__c":false,"SF_PS_Drivers_License_Number__c":"","SF_PS_Job_Site__c":"","SF_PS_Job_Location__c":"","SF_PS_Due_Date__c":"2023-02-22T09:45:00Z","SF_PS_Labor_Des_Comments__c":"","SF_PS_Labor_Des_Internal__c":"","SF_PS_RM_Last_Maint_By__c":"","SF_PS_RM_Last_Maint_DateTime__c":"2023-02-22T09:45:00Z","SF_PS_Inv_Seq_Num__c":1234,"SF_PS_License_State__c":"OH"},"WorkOrderLineItem":[{"Duration":0.00,"SF_PS_Labor_Code__c":"1000","SF_PS_Mechanic_Name__c":"50607","SF_PS_Hourly_Internal_Rate__c":0.00,"SF_PS_RM_Labor_Line_Item_Number__c":"","SF_PS_RM_External_Id__c":"53474688","SF_PS_Line_Type__c":"LI","SF_PS_Mileage_Charge__c":"MileageCharge","SF_PS_RM_Item_Number__c":"87213143"}],"deletedLines": []}';
        String jsonString = '{"data":{"EventType":"1","Status":"Open","OwnerId":"14","CurrencyIsoCode":"USD","Pricebook2Id":"'+pricebookId+'","AssetId":"1018879","SVMXA360_ContactPhone_c":"7036004000","SF_PS_Authorized_By__c":"","SF_PS_BillCustOrLoc__c":"L","SF_PS_PONumber__c":"","SF_PS_RM_WO_Number__c":"333222","SF_PS_Expense_To_Location__c":"1234","SF_PS_Expense_To_Loc__c":"1234","SF_PS_Cause__c":"","SF_PS_Company_Code__c":"","SF_PS_Complaint__c":"","SF_PS_Cure__c":"","SF_PS_ExpenseCode__c":"RR","SF_PS_LaborCode__c":"9100","SF_PS_Cust_Eqp_Description__c":"","SF_PS_Current_MiHr__c":0,"SF_PS_Repair_Ticket__c":0,"SF_PS_Work_Order_Des__c":"CHECK IN RETURN","SF_PS_Current_MiHr2__c":0,"SF_PS_Service_Call__c":"Y","SF_PS_Warranty_Amt_Expected__c":0,"SF_PS_Claim_Type__c":"N","SF_PS_Actual_Claim_Amt__c":0,"SF_PS_Service_Resource__c":"981291231","SF_PS_Claim_Paid_Date__c":"2023-02-22","SF_PS_Claim_Num__c":"","SF_PS_Date_Claim_Filed__c":"2023-02-22","SF_PS_Sales_Rep__c":"111222","SF_PS_Funded__c":"Y","SF_PS_Closed_Date__c":"2023-02-22T09:45:00Z","SF_PS_Current_Loc__c":"1234","SF_PS_Date_Opened__c":"2023-02-22T09:45:00Z","SF_PS_Charge_GST_Tax__c":false,"SF_PS_Charge_PST_Tax__c":false,"SF_PS_Drivers_License_Number__c":"","SF_PS_Job_Site__c":"","SF_PS_Job_Location__c":"","SF_PS_Due_Date__c":"2023-02-22T09:45:00Z","SF_PS_Labor_Des_Comments__c":"","SF_PS_Labor_Des_Internal__c":"","SF_PS_RM_Last_Maint_By__c":"","SF_PS_RM_Last_Maint_DateTime__c":"2023-02-22T09:45:00Z","SF_PS_Inv_Seq_Num__c":1234,"SF_PS_License_State__c":"OH"},"WorkOrderLineItem":[{"Duration":0,"SF_PS_Labor_Code__c":"1000","SF_PS_Mechanic_Name__c":"981291231","SF_PS_Hourly_Internal_Rate__c":0,"SF_PS_RM_Labor_Line_Item_Number__c":"","SF_PS_RM_External_Id__c":"3322123","SF_PS_Line_Type__c":"LI","SF_PS_Mileage_Charge__c":"MileageCharge","SF_PS_RM_Item_Number__c":"87213143"}],"ProductConsumed":[{"SF_PS_RM_External_Id__c":"1231231","SF_PS_Parts_Line_Num__c":"","SF_PS_Selling_Price__c":0,"SF_PS_Cost_Price__c":0,"SF_PS_Line_Type__c":"WO","Product2Id":"10870996","SF_PS_Quantity__c":1,"SF_PS_Unit_Of_Measure__c":"EA","SF_PS_Labor_Code__c":"1000","SF_PS_Line_Level_Comment__c":"string","SF_PS_List_Price__c":0}],"maintenanceSteps":[{"SF_PS_RM_Mtce_Mechanic_Name__c":"981291231","SF_PS_RM_External_Id__c":9812390812,"SF_PS_RM_Mtce_Steps_Y_N__c":"Y","SF_PS_RM_Mtce_Steps_StepNumber__c":0,"SF_PS_RM_Mtce_Steps_Meter_Reading_In__c":0,"SF_PS_RM_Mtce_Steps_Meter_Reading_Out__c":0,"SF_PS_RM_Mtce_Steps_Description__c":"","SF_PS_RM_Mtce_Steps_Pass_Fail__c":"P"}],"deletedLines":[{"SF_PS_RM_External_Id__c":""}]}';
        //request.requestBody = Blob.valueOf(JSON.serialize(jsonString));
        req.requestBody = Blob.valueOf(jsonString);
        
        RestContext.request = req;
        RestContext.response= res;
        
        User testAdminUser = [Select Id,Name from User where UserName LIKE 'testAdminUser%' ];
        system.debug('test request' + req);
        system.debug('test res' + res);
        //System.runAs(testAdminUser){
            insert new Bypass_Settings__c(SetupOwnerId=testAdminUser.Id, Bypass_Flow__c=true);
            Test.startTest();
            Asset testAsrt =  SBR_3_0_ServiceTestDataFactory.createAsset(true);
            
            //Create Exponce to Location
            ServiceTerritory  testE2Loc = SBR_3_0_ServiceTestDataFactory.createServiceTerritory(true);
            
            //Create Service Territory 
            //ServiceTerritory  testST = SBR_3_0_ServiceTestDataFactory.createServiceTerritory(false);
            OperatingHours oh = new OperatingHours(Name='TEST_Hours1',TimeZone='America/Halifax');
            insert oh;
            string name  ='TestHr';
            ServiceTerritory testST= new ServiceTerritory(Name=name,OperatingHoursId=oh.Id,IsActive=true,Branch_Location_Number__c = '1234',CountryCode = 'US');
            insert testST;
            
            ServiceResource testFactorySR = SBR_3_0_ServiceTestDataFactory.create_Service_Resource(false);
            User testUser = [Select Id,Name from User where UserName LIKE 'SRTestUser2%' LIMIT 1 ];
            testFactorySR.RelatedRecordId = testUser.Id;
            testFactorySR.ResourceType = 'T';
            insert testFactorySR;
            
            
            //create work order 
            workorder wo = SBR_3_0_ServiceTestDataFactory.createWorkOrder(false);
            wo.SF_PS_RM_WO_Number__c = '01-333222';
            wo.SF_PS_Expense_To_Location__c = testST.id;
            wo.AssetId = testAsrt.id;
            wo.ServiceTerritoryId  = testE2Loc.id;
            wo.SF_PS_Service_Resource__c = testFactorySR.id;
            wo.Pricebook2Id= standardPricebook.id;
            wo.recordTypeId =Schema.SObjectType.workorder.getRecordTypeInfosByName().get('Inspection Record').getRecordTypeId();
            insert wo;
            
            
            WorkOrderLineItem testwoli =  SBR_3_0_ServiceTestDataFactory.createWoli(false,wo.id,testFactorySR.id);
            testwoli.Duration = 1;
            if (testwoli != null) {
                insert testwoli;
            }
            //create product consumed
            ProductConsumed testPc =  SBR_3_0_ServiceTestDataFactory.createProductConsumedRecord(true ,wo.id, '1231231');
            SF_PS_Maintenance_Steps__c testMc = SBR_3_0_ServiceTestDataFactory.createMaintenanceSteps(true,wo.id,testFactorySR.id);
            
            //ProductConsumed testPc =  SBR_3_0_ServiceTestDataFactory.createProductConsumedRecord(true ,wo.id, '1231239');
            //ceate Service Territory member 
            User testrunUser = [Select Id,Name from User where UserName LIKE 'testAdminUser%' ];
            //User AdminRunUser = [Select Id,Name from User where UserName LIKE 'AdminRunUser%' ];
            //system.debug('AdminRunUseris '+ AdminRunUser);
            //System.runAs(AdminRunUser){
            //ServiceTerritoryMember testSTM =SBR_3_0_ServiceTestDataFactory.createServiceTerritoryMember(true,testFactorySR.id,testST.id);
            
            //}
            
            
            
            try {
                SBR_3_0_API_Web_WorkOrder.create();
                //system.assertEquals(200,res.statusCode);
                system.debug('test res 1st' + res);
            }Catch (Exception e) {
                System.debug('An Error Occur | ' + e);
                //system.assertEquals('Related Sales Rep not found!', e.getMessage(), 'Order API did not return Success!');
            }    
            Test.stopTest();
        //}
        
        
    }
    @isTest
    static void testQuoteFail(){
        
        //Get Custom setting 
        insert new Bypass_Settings__c(SetupOwnerId=UserInfo.getUserId(), Bypass_Flow__c=true);
        //Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_Web_Order_Test());
        Credential__c cred = SBR_3_0_TestDataFactory.createCredentials(1, false)[0];
        cred.Name = 'Mule_Token_Endpoint';
        cred.Key_Id__c = 'testKey123';
        cred.Secret__c = 'secret';
        insert cred;
        
        Id pricebookId = Test.getStandardPricebookId();
        Pricebook2 standardPricebook = new Pricebook2(
            name= 'Standard Price Book',
            Id = pricebookId,
            IsActive = true
        );
        update standardPricebook;
        system.debug('standardPricebook is' + standardPricebook.id);
        
        
        
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_Web_WorkOrder_Test());
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/WorkOrder/ApiCreate/v1/*';
        req.httpMethod = 'POST';
        //String jsonString = '{ "EventType": "1","SF_PS_Company_Code__c": "01","Name": "Test Resouce","SF_PS_Hourly_Billing_Rate__c": 15.0,"SF_PS_Hourly_Internal_Rate__c": 15.0,"SF_PS_Overtime_Billing_Rate__c": 15.0,"SF_PS_Overtime_Internal_Rate__c": 15.0,"SF_PS_Labor_Type__c": "I","SF_PS_Type__c": "D","IsActive": true,"SF_PS_Branch_Loc_Num__c": "6666","SF_PS_Start_Date__c": "2023-02-22","SF_PS_RM_Created_DateTime__c": "2023-02-22T09:45:00Z","SF_PS_RM_Created_By__c": "Test User","SF_PS_RM_Update_DateTime__c": "2023-02-22T09:45:00Z","SF_PS_RM_Updated_By_User__c": "Test User","SF_PS_Mechanic_Id__c": "9999","SF_PS_Comments__c": "Yes api" }';
        // Old JSON String jsonString = '{"data":{"EventType":"1","Status":"Open","OwnerId":"1234","CurrencyIsoCode":"USD","AssetId":"1018879","SVMXA360_ContactPhone_c":"7036004000","SF_PS_Authorized_By__c":"","SF_PS_BillCustOrLoc__c":"L","SF_PS_PONumber__c":"","SF_PS_RM_WO_Number__c":"333222", "SF_PS_Expense_To_Location__c" : "1234","SF_PS_Cause__c":"","SF_PS_Company_Code__c":"01","SF_PS_Complaint__c":"","SF_PS_Cure__c":"","SF_PS_ExpenseCode__c":"RR","SF_PS_LaborCode__c":"9100","SF_PS_Cust_Eqp_Description__c":"","SF_PS_Current_MiHr__c":0.000,"SF_PS_Repair_Ticket__c":0,"SF_PS_Work_Order_Des__c":"CHECK IN RETURN","SF_PS_Current_MiHr2__c":0.000,"SF_PS_Service_Call__c":"Y","SF_PS_Warranty_Amt_Expected__c":0.00,"SF_PS_Claim_Type__c":"N","SF_PS_Actual_Claim_Amt__c":0.00, "SF_PS_Service_Resource__c":"50607", "SF_PS_Claim_Paid_Date__c":"2023-02-22","SF_PS_Claim_Num__c":"","SF_PS_Date_Claim_Filed__c":"2023-02-22","SF_PS_Sales_Rep__c":"111222","SF_PS_Funded__c":"Y","SF_PS_Closed_Date__c":"2023-02-22T09:45:00Z","SF_PS_Current_Loc__c": "0784", "SF_PS_Date_Opened__c":"2023-02-22T09:45:00Z","SF_PS_Charge_GST_Tax__c":false,"SF_PS_Charge_PST_Tax__c":false,"SF_PS_Drivers_License_Number__c":"","SF_PS_Job_Site__c":"","SF_PS_Job_Location__c":"","SF_PS_Due_Date__c":"2023-02-22T09:45:00Z","SF_PS_Labor_Des_Comments__c":"","SF_PS_Labor_Des_Internal__c":"","SF_PS_RM_Last_Maint_By__c":"","SF_PS_RM_Last_Maint_DateTime__c":"2023-02-22T09:45:00Z","SF_PS_Inv_Seq_Num__c":1234,"SF_PS_License_State__c":"OH"},"WorkOrderLineItem":[{"Duration":0.00,"SF_PS_Labor_Code__c":"1000","SF_PS_Mechanic_Name__c":"50607","SF_PS_Hourly_Internal_Rate__c":0.00,"SF_PS_RM_Labor_Line_Item_Number__c":"","SF_PS_RM_External_Id__c":"53474688","SF_PS_Line_Type__c":"LI","SF_PS_Mileage_Charge__c":"MileageCharge","SF_PS_RM_Item_Number__c":"87213143"}],"deletedLines": []}';
        String jsonString = '{"data":{"EventType":"1","Status":"Open","OwnerId":"1234","CurrencyIsoCode":"USD","Pricebook2Id":"'+pricebookId+'","AssetId":"1018879","SVMXA360_ContactPhone_c":"7036004000","SF_PS_Authorized_By__c":"","SF_PS_BillCustOrLoc__c":"L","SF_PS_PONumber__c":"","SF_PS_RM_WO_Number__c":"333222","SF_PS_Expense_To_Location__c":"1234","SF_PS_Expense_To_Loc__c":"1234","SF_PS_Cause__c":"","SF_PS_Company_Code__c":"","SF_PS_Complaint__c":"","SF_PS_Cure__c":"","SF_PS_ExpenseCode__c":"RR","SF_PS_LaborCode__c":"9100","SF_PS_Cust_Eqp_Description__c":"","SF_PS_Current_MiHr__c":0,"SF_PS_Repair_Ticket__c":0,"SF_PS_Work_Order_Des__c":"CHECK IN RETURN","SF_PS_Current_MiHr2__c":0,"SF_PS_Service_Call__c":"Y","SF_PS_Warranty_Amt_Expected__c":0,"SF_PS_Claim_Type__c":"N","SF_PS_Actual_Claim_Amt__c":0,"SF_PS_Service_Resource__c":"981291231","SF_PS_Claim_Paid_Date__c":"2023-02-22","SF_PS_Claim_Num__c":"","SF_PS_Date_Claim_Filed__c":"2023-02-22","SF_PS_Sales_Rep__c":"111222","SF_PS_Funded__c":"Y","SF_PS_Closed_Date__c":"2023-02-22T09:45:00Z","SF_PS_Current_Loc__c":"1234","SF_PS_Date_Opened__c":"2023-02-22T09:45:00Z","SF_PS_Charge_GST_Tax__c":false,"SF_PS_Charge_PST_Tax__c":false,"SF_PS_Drivers_License_Number__c":"","SF_PS_Job_Site__c":"","SF_PS_Job_Location__c":"","SF_PS_Due_Date__c":"2023-02-22T09:45:00Z","SF_PS_Labor_Des_Comments__c":"","SF_PS_Labor_Des_Internal__c":"","SF_PS_RM_Last_Maint_By__c":"","SF_PS_RM_Last_Maint_DateTime__c":"2023-02-22T09:45:00Z","SF_PS_Inv_Seq_Num__c":1234,"SF_PS_License_State__c":"OH"},"WorkOrderLineItem":[{"Duration":0,"SF_PS_Labor_Code__c":"1000","SF_PS_Mechanic_Name__c":"981291231","SF_PS_Hourly_Internal_Rate__c":0,"SF_PS_RM_Labor_Line_Item_Number__c":"","SF_PS_RM_External_Id__c":"3322123","SF_PS_Line_Type__c":"LI","SF_PS_Mileage_Charge__c":"MileageCharge","SF_PS_RM_Item_Number__c":"87213143"}],"ProductConsumed":[{"SF_PS_RM_External_Id__c":"1231231","SF_PS_Parts_Line_Num__c":"","SF_PS_Selling_Price__c":0,"SF_PS_Cost_Price__c":0,"SF_PS_Line_Type__c":"WO","Product2Id":"10870996","SF_PS_Quantity__c":1,"SF_PS_Unit_Of_Measure__c":"EA","SF_PS_Labor_Code__c":"1000","SF_PS_Line_Level_Comment__c":"string","SF_PS_List_Price__c":0}],"maintenanceSteps":[{"SF_PS_RM_Mtce_Mechanic_Name__c":"981291231","SF_PS_RM_External_Id__c":9812390812,"SF_PS_RM_Mtce_Steps_Y_N__c":"Y","SF_PS_RM_Mtce_Steps_StepNumber__c":0,"SF_PS_RM_Mtce_Steps_Meter_Reading_In__c":0,"SF_PS_RM_Mtce_Steps_Meter_Reading_Out__c":0,"SF_PS_RM_Mtce_Steps_Description__c":"","SF_PS_RM_Mtce_Steps_Pass_Fail__c":"P"}],"deletedLines":[{"SF_PS_RM_External_Id__c":""}]}';
        //request.requestBody = Blob.valueOf(JSON.serialize(jsonString));
        req.requestBody = Blob.valueOf(jsonString);
        
        RestContext.request = req;
        RestContext.response= res;
        
        User testAdminUser = [Select Id,Name from User where UserName LIKE 'testAdminUser%' ];
        system.debug('test request' + req);
        system.debug('test res' + res);
        //System.runAs(testAdminUser){
            insert new Bypass_Settings__c(SetupOwnerId=testAdminUser.Id, Bypass_Flow__c=true);
            Test.startTest();
            Asset testAsrt =  SBR_3_0_ServiceTestDataFactory.createAsset(true);
            
            //Create Exponce to Location
            ServiceTerritory  testE2Loc = SBR_3_0_ServiceTestDataFactory.createServiceTerritory(true);
            
            //Create Service Territory 
            //ServiceTerritory  testST = SBR_3_0_ServiceTestDataFactory.createServiceTerritory(false);
            OperatingHours oh = new OperatingHours(Name='TEST_Hours1',TimeZone='America/Halifax');
            insert oh;
            string name  ='TestHr';
            ServiceTerritory testST= new ServiceTerritory(Name=name,OperatingHoursId=oh.Id,IsActive=true,Branch_Location_Number__c = '1234',CountryCode = 'US');
            insert testST;
            
            ServiceResource testFactorySR = SBR_3_0_ServiceTestDataFactory.create_Service_Resource(false);
            User testUser = [Select Id,Name from User where UserName LIKE 'SRTestUser2%' LIMIT 1 ];
            testFactorySR.RelatedRecordId = testUser.Id;
            testFactorySR.ResourceType = 'T';
            insert testFactorySR;
            
            
            //create work order 
            workorder wo = SBR_3_0_ServiceTestDataFactory.createWorkOrder(false);
            wo.SF_PS_RM_WO_Number__c = '01-333222';
            wo.SF_PS_Expense_To_Location__c = testST.id;
            wo.AssetId = testAsrt.id;
            wo.ServiceTerritoryId  = testE2Loc.id;
            wo.SF_PS_Service_Resource__c = testFactorySR.id;
            wo.Pricebook2Id= standardPricebook.id;
            wo.recordTypeId =Schema.SObjectType.workorder.getRecordTypeInfosByName().get('Inspection Record').getRecordTypeId();
            insert wo;
            
            
            WorkOrderLineItem testwoli =  SBR_3_0_ServiceTestDataFactory.createWoli(false,wo.id,testFactorySR.id);
            testwoli.Duration = 1;
            if (testwoli != null) {
                insert testwoli;
            }
            //create product consumed
            ProductConsumed testPc =  SBR_3_0_ServiceTestDataFactory.createProductConsumedRecord(true ,wo.id, '1231231');
            SF_PS_Maintenance_Steps__c testMc = SBR_3_0_ServiceTestDataFactory.createMaintenanceSteps(true,wo.id,testFactorySR.id);
            
            //ProductConsumed testPc =  SBR_3_0_ServiceTestDataFactory.createProductConsumedRecord(true ,wo.id, '1231239');
            //ceate Service Territory member 
            User testrunUser = [Select Id,Name from User where UserName LIKE 'testAdminUser%' ];
            //User AdminRunUser = [Select Id,Name from User where UserName LIKE 'AdminRunUser%' ];
            //system.debug('AdminRunUseris '+ AdminRunUser);
            //System.runAs(AdminRunUser){
            //ServiceTerritoryMember testSTM =SBR_3_0_ServiceTestDataFactory.createServiceTerritoryMember(true,testFactorySR.id,testST.id);
            
            //}
            
            
            
            try {
                SBR_3_0_API_Web_WorkOrderQuote.create();
                //system.assertEquals(200,res.statusCode);
                system.debug('test res 1st' + res);
            }Catch (Exception e) {
                System.debug('An Error Occur | ' + e);
                //system.assertEquals('Related Sales Rep not found!', e.getMessage(), 'Order API did not return Success!');
            }    
            Test.stopTest();
        //}
        
        
    }
    
    @isTest
    static void testCreditFail(){
        
        //Get Custom setting 
        insert new Bypass_Settings__c(SetupOwnerId=UserInfo.getUserId(), Bypass_Flow__c=true);
        //Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_Web_Order_Test());
        Credential__c cred = SBR_3_0_TestDataFactory.createCredentials(1, false)[0];
        cred.Name = 'Mule_Token_Endpoint';
        cred.Key_Id__c = 'testKey123';
        cred.Secret__c = 'secret';
        insert cred;
        
        Id pricebookId = Test.getStandardPricebookId();
        Pricebook2 standardPricebook = new Pricebook2(
            name= 'Standard Price Book',
            Id = pricebookId,
            IsActive = true
        );
        update standardPricebook;
        system.debug('standardPricebook is' + standardPricebook.id);
        
        
        
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_Web_WorkOrder_Test());
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/WorkOrder/ApiCreate/v1/*';
        req.httpMethod = 'POST';
        //String jsonString = '{ "EventType": "1","SF_PS_Company_Code__c": "01","Name": "Test Resouce","SF_PS_Hourly_Billing_Rate__c": 15.0,"SF_PS_Hourly_Internal_Rate__c": 15.0,"SF_PS_Overtime_Billing_Rate__c": 15.0,"SF_PS_Overtime_Internal_Rate__c": 15.0,"SF_PS_Labor_Type__c": "I","SF_PS_Type__c": "D","IsActive": true,"SF_PS_Branch_Loc_Num__c": "6666","SF_PS_Start_Date__c": "2023-02-22","SF_PS_RM_Created_DateTime__c": "2023-02-22T09:45:00Z","SF_PS_RM_Created_By__c": "Test User","SF_PS_RM_Update_DateTime__c": "2023-02-22T09:45:00Z","SF_PS_RM_Updated_By_User__c": "Test User","SF_PS_Mechanic_Id__c": "9999","SF_PS_Comments__c": "Yes api" }';
        // Old JSON String jsonString = '{"data":{"EventType":"1","Status":"Open","OwnerId":"1234","CurrencyIsoCode":"USD","AssetId":"1018879","SVMXA360_ContactPhone_c":"7036004000","SF_PS_Authorized_By__c":"","SF_PS_BillCustOrLoc__c":"L","SF_PS_PONumber__c":"","SF_PS_RM_WO_Number__c":"333222", "SF_PS_Expense_To_Location__c" : "1234","SF_PS_Cause__c":"","SF_PS_Company_Code__c":"01","SF_PS_Complaint__c":"","SF_PS_Cure__c":"","SF_PS_ExpenseCode__c":"RR","SF_PS_LaborCode__c":"9100","SF_PS_Cust_Eqp_Description__c":"","SF_PS_Current_MiHr__c":0.000,"SF_PS_Repair_Ticket__c":0,"SF_PS_Work_Order_Des__c":"CHECK IN RETURN","SF_PS_Current_MiHr2__c":0.000,"SF_PS_Service_Call__c":"Y","SF_PS_Warranty_Amt_Expected__c":0.00,"SF_PS_Claim_Type__c":"N","SF_PS_Actual_Claim_Amt__c":0.00, "SF_PS_Service_Resource__c":"50607", "SF_PS_Claim_Paid_Date__c":"2023-02-22","SF_PS_Claim_Num__c":"","SF_PS_Date_Claim_Filed__c":"2023-02-22","SF_PS_Sales_Rep__c":"111222","SF_PS_Funded__c":"Y","SF_PS_Closed_Date__c":"2023-02-22T09:45:00Z","SF_PS_Current_Loc__c": "0784", "SF_PS_Date_Opened__c":"2023-02-22T09:45:00Z","SF_PS_Charge_GST_Tax__c":false,"SF_PS_Charge_PST_Tax__c":false,"SF_PS_Drivers_License_Number__c":"","SF_PS_Job_Site__c":"","SF_PS_Job_Location__c":"","SF_PS_Due_Date__c":"2023-02-22T09:45:00Z","SF_PS_Labor_Des_Comments__c":"","SF_PS_Labor_Des_Internal__c":"","SF_PS_RM_Last_Maint_By__c":"","SF_PS_RM_Last_Maint_DateTime__c":"2023-02-22T09:45:00Z","SF_PS_Inv_Seq_Num__c":1234,"SF_PS_License_State__c":"OH"},"WorkOrderLineItem":[{"Duration":0.00,"SF_PS_Labor_Code__c":"1000","SF_PS_Mechanic_Name__c":"50607","SF_PS_Hourly_Internal_Rate__c":0.00,"SF_PS_RM_Labor_Line_Item_Number__c":"","SF_PS_RM_External_Id__c":"53474688","SF_PS_Line_Type__c":"LI","SF_PS_Mileage_Charge__c":"MileageCharge","SF_PS_RM_Item_Number__c":"87213143"}],"deletedLines": []}';
        String jsonString = '{"data":{"EventType":"1","Status":"Open","OwnerId":"1234","CurrencyIsoCode":"USD","Pricebook2Id":"'+pricebookId+'","AssetId":"1018879","SVMXA360_ContactPhone_c":"7036004000","SF_PS_Authorized_By__c":"","SF_PS_BillCustOrLoc__c":"L","SF_PS_PONumber__c":"","SF_PS_RM_WO_Number__c":"333222","SF_PS_Expense_To_Location__c":"1234","SF_PS_Expense_To_Loc__c":"1234","SF_PS_Cause__c":"","SF_PS_Company_Code__c":"","SF_PS_Complaint__c":"","SF_PS_Cure__c":"","SF_PS_ExpenseCode__c":"RR","SF_PS_LaborCode__c":"9100","SF_PS_Cust_Eqp_Description__c":"","SF_PS_Current_MiHr__c":0,"SF_PS_Repair_Ticket__c":0,"SF_PS_Work_Order_Des__c":"CHECK IN RETURN","SF_PS_Current_MiHr2__c":0,"SF_PS_Service_Call__c":"Y","SF_PS_Warranty_Amt_Expected__c":0,"SF_PS_Claim_Type__c":"N","SF_PS_Actual_Claim_Amt__c":0,"SF_PS_Service_Resource__c":"981291231","SF_PS_Claim_Paid_Date__c":"2023-02-22","SF_PS_Claim_Num__c":"","SF_PS_Date_Claim_Filed__c":"2023-02-22","SF_PS_Sales_Rep__c":"111222","SF_PS_Funded__c":"Y","SF_PS_Closed_Date__c":"2023-02-22T09:45:00Z","SF_PS_Current_Loc__c":"1234","SF_PS_Date_Opened__c":"2023-02-22T09:45:00Z","SF_PS_Charge_GST_Tax__c":false,"SF_PS_Charge_PST_Tax__c":false,"SF_PS_Drivers_License_Number__c":"","SF_PS_Job_Site__c":"","SF_PS_Job_Location__c":"","SF_PS_Due_Date__c":"2023-02-22T09:45:00Z","SF_PS_Labor_Des_Comments__c":"","SF_PS_Labor_Des_Internal__c":"","SF_PS_RM_Last_Maint_By__c":"","SF_PS_RM_Last_Maint_DateTime__c":"2023-02-22T09:45:00Z","SF_PS_Inv_Seq_Num__c":1234,"SF_PS_License_State__c":"OH"},"WorkOrderLineItem":[{"Duration":0,"SF_PS_Labor_Code__c":"1000","SF_PS_Mechanic_Name__c":"981291231","SF_PS_Hourly_Internal_Rate__c":0,"SF_PS_RM_Labor_Line_Item_Number__c":"","SF_PS_RM_External_Id__c":"3322123","SF_PS_Line_Type__c":"LI","SF_PS_Mileage_Charge__c":"MileageCharge","SF_PS_RM_Item_Number__c":"87213143"}],"ProductConsumed":[{"SF_PS_RM_External_Id__c":"1231231","SF_PS_Parts_Line_Num__c":"","SF_PS_Selling_Price__c":0,"SF_PS_Cost_Price__c":0,"SF_PS_Line_Type__c":"WO","Product2Id":"10870996","SF_PS_Quantity__c":1,"SF_PS_Unit_Of_Measure__c":"EA","SF_PS_Labor_Code__c":"1000","SF_PS_Line_Level_Comment__c":"string","SF_PS_List_Price__c":0}],"maintenanceSteps":[{"SF_PS_RM_Mtce_Mechanic_Name__c":"981291231","SF_PS_RM_External_Id__c":9812390812,"SF_PS_RM_Mtce_Steps_Y_N__c":"Y","SF_PS_RM_Mtce_Steps_StepNumber__c":0,"SF_PS_RM_Mtce_Steps_Meter_Reading_In__c":0,"SF_PS_RM_Mtce_Steps_Meter_Reading_Out__c":0,"SF_PS_RM_Mtce_Steps_Description__c":"","SF_PS_RM_Mtce_Steps_Pass_Fail__c":"P"}],"deletedLines":[{"SF_PS_RM_External_Id__c":""}]}';
        //request.requestBody = Blob.valueOf(JSON.serialize(jsonString));
        req.requestBody = Blob.valueOf(jsonString);
        
        RestContext.request = req;
        RestContext.response= res;
        
        User testAdminUser = [Select Id,Name from User where UserName LIKE 'testAdminUser%' ];
        system.debug('test request' + req);
        system.debug('test res' + res);
        //System.runAs(testAdminUser){
            insert new Bypass_Settings__c(SetupOwnerId=testAdminUser.Id, Bypass_Flow__c=true);
            Test.startTest();
            Asset testAsrt =  SBR_3_0_ServiceTestDataFactory.createAsset(true);
            
            //Create Exponce to Location
            ServiceTerritory  testE2Loc = SBR_3_0_ServiceTestDataFactory.createServiceTerritory(true);
            
            //Create Service Territory 
            //ServiceTerritory  testST = SBR_3_0_ServiceTestDataFactory.createServiceTerritory(false);
            OperatingHours oh = new OperatingHours(Name='TEST_Hours1',TimeZone='America/Halifax');
            insert oh;
            string name  ='TestHr';
            ServiceTerritory testST= new ServiceTerritory(Name=name,OperatingHoursId=oh.Id,IsActive=true,Branch_Location_Number__c = '1234',CountryCode = 'US');
            insert testST;
            
            ServiceResource testFactorySR = SBR_3_0_ServiceTestDataFactory.create_Service_Resource(false);
            User testUser = [Select Id,Name from User where UserName LIKE 'SRTestUser2%' LIMIT 1 ];
            testFactorySR.RelatedRecordId = testUser.Id;
            testFactorySR.ResourceType = 'T';
            insert testFactorySR;
            
            
            //create work order 
            workorder wo = SBR_3_0_ServiceTestDataFactory.createWorkOrder(false);
            wo.SF_PS_RM_WO_Number__c = '01-333222';
            wo.SF_PS_Expense_To_Location__c = testST.id;
            wo.AssetId = testAsrt.id;
            wo.ServiceTerritoryId  = testE2Loc.id;
            wo.SF_PS_Service_Resource__c = testFactorySR.id;
            wo.Pricebook2Id= standardPricebook.id;
            wo.recordTypeId =Schema.SObjectType.workorder.getRecordTypeInfosByName().get('Credit').getRecordTypeId();
            insert wo;
            
            
            WorkOrderLineItem testwoli =  SBR_3_0_ServiceTestDataFactory.createWoli(false,wo.id,testFactorySR.id);
            testwoli.Duration = 1;
            if (testwoli != null) {
                insert testwoli;
            }
            //create product consumed
            //
            ProductConsumed testPc =  SBR_3_0_ServiceTestDataFactory.createProductConsumedRecord(true ,wo.id, '1231231');
            SF_PS_Maintenance_Steps__c testMc = SBR_3_0_ServiceTestDataFactory.createMaintenanceSteps(true,wo.id,testFactorySR.id);
            
            //ProductConsumed testPc =  SBR_3_0_ServiceTestDataFactory.createProductConsumedRecord(true ,wo.id, '1231239');
            //ceate Service Territory member 
            User testrunUser = [Select Id,Name from User where UserName LIKE 'testAdminUser%' ];
            //User AdminRunUser = [Select Id,Name from User where UserName LIKE 'AdminRunUser%' ];
            //system.debug('AdminRunUseris '+ AdminRunUser);
            //System.runAs(AdminRunUser){
            //ServiceTerritoryMember testSTM =SBR_3_0_ServiceTestDataFactory.createServiceTerritoryMember(true,testFactorySR.id,testST.id);
            
            //}
            
            
            
            try {
                SBR_3_0_API_Web_WorkOrderCredit.create();
                //system.assertEquals(200,res.statusCode);
                system.debug('test res 1st' + res);
            }Catch (Exception e) {
                System.debug('An Error Occur | ' + e);
                //system.assertEquals('Related Sales Rep not found!', e.getMessage(), 'Order API did not return Success!');
            }    
            Test.stopTest();
        //}
        
    }
    
    
    @isTest
    static void testAssetworkorderQuote(){
        //Get Custom setting 
        insert new Bypass_Settings__c(SetupOwnerId=UserInfo.getUserId(), Bypass_Flow__c=true);
        
        
        //Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_Web_Order_Test());
        Credential__c cred = SBR_3_0_TestDataFactory.createCredentials(1, false)[0];
        cred.Name = 'Mule_Token_Endpoint';
        cred.Key_Id__c = 'testKey123';
        cred.Secret__c = 'secret';
        insert cred;
        
        Id pricebookId = Test.getStandardPricebookId();
        Pricebook2 standardPricebook = new Pricebook2(
            name= 'Standard Price Book',
            Id = pricebookId,
            IsActive = true
        );
        update standardPricebook;
        system.debug('standardPricebook is' + standardPricebook.id);
        
        
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_Web_WorkOrder_Test());
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/WorkOrderQuote/ApiCreate/v1/*';
        req.httpMethod = 'POST';
        //String jsonString = '{ "EventType": "1","SF_PS_Company_Code__c": "01","Name": "Test Resouce","SF_PS_Hourly_Billing_Rate__c": 15.0,"SF_PS_Hourly_Internal_Rate__c": 15.0,"SF_PS_Overtime_Billing_Rate__c": 15.0,"SF_PS_Overtime_Internal_Rate__c": 15.0,"SF_PS_Labor_Type__c": "I","SF_PS_Type__c": "D","IsActive": true,"SF_PS_Branch_Loc_Num__c": "6666","SF_PS_Start_Date__c": "2023-02-22","SF_PS_RM_Created_DateTime__c": "2023-02-22T09:45:00Z","SF_PS_RM_Created_By__c": "Test User","SF_PS_RM_Update_DateTime__c": "2023-02-22T09:45:00Z","SF_PS_RM_Updated_By_User__c": "Test User","SF_PS_Mechanic_Id__c": "9999","SF_PS_Comments__c": "Yes api" }';
        // Old JSON String jsonString = '{"data":{"EventType":"1","Status":"Open","OwnerId":"1234","CurrencyIsoCode":"USD","AssetId":"1018879","SVMXA360_ContactPhone_c":"7036004000","SF_PS_Authorized_By__c":"","SF_PS_BillCustOrLoc__c":"L","SF_PS_PONumber__c":"","SF_PS_RM_WO_Number__c":"333222", "SF_PS_Expense_To_Location__c" : "1234","SF_PS_Cause__c":"","SF_PS_Company_Code__c":"01","SF_PS_Complaint__c":"","SF_PS_Cure__c":"","SF_PS_ExpenseCode__c":"RR","SF_PS_LaborCode__c":"9100","SF_PS_Cust_Eqp_Description__c":"","SF_PS_Current_MiHr__c":0.000,"SF_PS_Repair_Ticket__c":0,"SF_PS_Work_Order_Des__c":"CHECK IN RETURN","SF_PS_Current_MiHr2__c":0.000,"SF_PS_Service_Call__c":"Y","SF_PS_Warranty_Amt_Expected__c":0.00,"SF_PS_Claim_Type__c":"N","SF_PS_Actual_Claim_Amt__c":0.00, "SF_PS_Service_Resource__c":"50607", "SF_PS_Claim_Paid_Date__c":"2023-02-22","SF_PS_Claim_Num__c":"","SF_PS_Date_Claim_Filed__c":"2023-02-22","SF_PS_Sales_Rep__c":"111222","SF_PS_Funded__c":"Y","SF_PS_Closed_Date__c":"2023-02-22T09:45:00Z","SF_PS_Current_Loc__c": "0784", "SF_PS_Date_Opened__c":"2023-02-22T09:45:00Z","SF_PS_Charge_GST_Tax__c":false,"SF_PS_Charge_PST_Tax__c":false,"SF_PS_Drivers_License_Number__c":"","SF_PS_Job_Site__c":"","SF_PS_Job_Location__c":"","SF_PS_Due_Date__c":"2023-02-22T09:45:00Z","SF_PS_Labor_Des_Comments__c":"","SF_PS_Labor_Des_Internal__c":"","SF_PS_RM_Last_Maint_By__c":"","SF_PS_RM_Last_Maint_DateTime__c":"2023-02-22T09:45:00Z","SF_PS_Inv_Seq_Num__c":1234,"SF_PS_License_State__c":"OH"},"WorkOrderLineItem":[{"Duration":0.00,"SF_PS_Labor_Code__c":"1000","SF_PS_Mechanic_Name__c":"50607","SF_PS_Hourly_Internal_Rate__c":0.00,"SF_PS_RM_Labor_Line_Item_Number__c":"","SF_PS_RM_External_Id__c":"53474688","SF_PS_Line_Type__c":"LI","SF_PS_Mileage_Charge__c":"MileageCharge","SF_PS_RM_Item_Number__c":"87213143"}],"deletedLines": []}';
        String jsonString = '{"data":{"EventType":"1","Status":"Open","OwnerId":"1234","RecordTypeId" : "WORK ORDER QUOTE","CurrencyIsoCode":"USD","Pricebook2Id":"'+pricebookId+'","AssetId":"00721","SVMXA360_ContactPhone_c":"7036004000","SF_PS_Authorized_By__c":"","SF_PS_BillCustOrLoc__c":"L","SF_PS_PONumber__c":"","SF_PS_RM_WO_Number__c":"333222","SF_PS_Expense_To_Location__c":"1234","SF_PS_Expense_To_Loc__c":"1234","SF_PS_Cause__c":"","SF_PS_Company_Code__c":"01","SF_PS_Complaint__c":"","SF_PS_Cure__c":"","SF_PS_ExpenseCode__c":"RR","SF_PS_LaborCode__c":"9100","SF_PS_Cust_Eqp_Description__c":"","SF_PS_Current_MiHr__c":0,"SF_PS_Repair_Ticket__c":0,"SF_PS_Work_Order_Des__c":"CHECK IN RETURN","SF_PS_Current_MiHr2__c":0,"SF_PS_Service_Call__c":"Y","SF_PS_Warranty_Amt_Expected__c":0,"SF_PS_Claim_Type__c":"N","SF_PS_Actual_Claim_Amt__c":0,"SF_PS_Service_Resource__c":"981291231","SF_PS_Claim_Paid_Date__c":"2023-02-22","SF_PS_Claim_Num__c":"","SF_PS_Date_Claim_Filed__c":"2023-02-22","SF_PS_Sales_Rep__c":"","SF_PS_Funded__c":"Y","SF_PS_Closed_Date__c":"2023-02-22T09:45:00Z","SF_PS_Current_Loc__c":"1234","SF_PS_Date_Opened__c":"2023-02-22T09:45:00Z","SF_PS_Charge_GST_Tax__c":false,"SF_PS_Charge_PST_Tax__c":false,"SF_PS_Drivers_License_Number__c":"","SF_PS_Job_Site__c":"","SF_PS_Job_Location__c":"","SF_PS_Due_Date__c":"2023-02-22T09:45:00Z","SF_PS_Labor_Des_Comments__c":"","SF_PS_Labor_Des_Internal__c":"","SF_PS_RM_Last_Maint_By__c":"","SF_PS_RM_Last_Maint_DateTime__c":"2023-02-22T09:45:00Z","SF_PS_Inv_Seq_Num__c":1234,"SF_PS_License_State__c":"OH"},"QuoteLineItem":[{"SF_PS_Duration__c":1,"SF_PS_Labor_Code__c":"1000","SF_PS_Mechanic_Name__c":"981291231","SF_PS_Hourly_Internal_Rate__c":0,"SF_PS_RM_Labor_Line_Item_Number__c":"","SF_PS_RM_External_Id__c":"3322123","SF_PS_Line_Type__c":"LI","SF_PS_Mileage_Charge__c":"MileageCharge","SF_PS_RM_Item_Number__c":"87213143"}],"QuotedParts":[{"SF_PS_RM_External_Id__c":"1231231","SF_PS_Parts_Line_Num__c":"","SF_PS_ItemType__c": "P","SF_PS_Selling_Price__c":0,"SF_PS_Cost_Price__c":0,"SF_PS_Line_Type__c":"WO","SF_PS_Product2Id__c":"10870996","SF_PS_Quantity__c":1,"SF_PS_Unit_Of_Measure__c":"EA","SF_PS_Labor_Code__c":"1000","SF_PS_Line_Level_Comment__c":"string","SF_PS_List_Price__c":0}],"maintenanceSteps":[{"SF_PS_RM_Mtce_Mechanic_Name__c":"981291231","SF_PS_RM_External_Id__c":9812390812,"SF_PS_RM_Mtce_Steps_Y_N__c":"Y","SF_PS_RM_Mtce_Steps_StepNumber__c":"1","SF_PS_RM_Mtce_Steps_Meter_Reading_In__c":0,"SF_PS_RM_Mtce_Steps_Meter_Reading_Out__c":0,"SF_PS_RM_Mtce_Steps_Description__c":"","SF_PS_RM_Mtce_Steps_Pass_Fail__c":"P"}],"deletedLines":[{"SF_PS_RM_External_Id__c":""}]}';
        //request.requestBody = Blob.valueOf(JSON.serialize(jsonString));
        req.requestBody = Blob.valueOf(jsonString);
        
        RestContext.request = req;
        RestContext.response= res;
        
        User testAdminUser = [Select Id,Name from User where UserName LIKE 'testAdminUser%' ];
        system.debug('test request' + req);
        system.debug('test res' + res);
        //System.runAs(testAdminUser){
            insert new Bypass_Settings__c(SetupOwnerId=testAdminUser.Id, Bypass_Flow__c=true);
            Test.startTest();
            Asset testAsrt =  SBR_3_0_ServiceTestDataFactory.createAsset(true);
            
            //Create Exponce to Location
            ServiceTerritory  testE2Loc = SBR_3_0_ServiceTestDataFactory.createServiceTerritory(true);
            
            //Create Service Territory 
            //ServiceTerritory  testST = SBR_3_0_ServiceTestDataFactory.createServiceTerritory(false);
            OperatingHours oh = new OperatingHours(Name='TEST_Hours1',TimeZone='America/Halifax');
            insert oh;
            string name  ='TestHr';
            ServiceTerritory testST= new ServiceTerritory(Name=name,OperatingHoursId=oh.Id,IsActive=true,Branch_Location_Number__c = '1234',CountryCode = 'US');
            insert testST;
            
            ServiceResource testFactorySR = SBR_3_0_ServiceTestDataFactory.create_Service_Resource(false);
            User testUser = [Select Id,Name from User where UserName LIKE 'SRTestUser2%' Limit 1 ];
            testFactorySR.RelatedRecordId = testUser.Id;
            testFactorySR.ResourceType = 'T';
            insert testFactorySR;
            
            //create work order
            //workorder wop = SBR_3_0_ServiceTestDataFactory.createWorkOrder(false);
            //wop.SF_PS_RM_WO_Number__c = '01-333223234';
            //wop.SF_PS_Expense_To_Location__c = testST.id;
            //wop.AssetId = testAsrt.id;
            //wop.ServiceTerritoryId  = testE2Loc.id;
            //wop.SF_PS_Service_Resource__c = testFactorySR.id;
            //insert wop;
            
            //create work order 
            workorder wo = SBR_3_0_ServiceTestDataFactory.createWorkOrder(false);
            wo.SF_PS_RM_WO_Number__c = '01-333222';
            wo.SF_PS_Expense_To_Location__c = testST.id;
            wo.AssetId = testAsrt.id;
            wo.ServiceTerritoryId  = testE2Loc.id;
            wo.SF_PS_Service_Resource__c = testFactorySR.id;
            wo.Pricebook2Id= standardPricebook.id;
            wo.recordTypeId =Schema.SObjectType.workorder.getRecordTypeInfosByName().get('Inspection Record').getRecordTypeId();
            //wo.ParentWorkOrderId = wop.Id;
            insert wo;
            
            
            
            
            WorkOrderLineItem testwoli =  SBR_3_0_ServiceTestDataFactory.createWoli(false,wo.id,testFactorySR.id);
            testwoli.Duration = 1;
            if (testwoli != null) {
                insert testwoli;
            }
            //create product consumed
            ProductConsumed testPc =  SBR_3_0_ServiceTestDataFactory.createProductConsumedRecord(true ,wo.id, '1231231');
            //SF_PS_Maintenance_Steps__c testMc = SBR_3_0_ServiceTestDataFactory.createMaintenanceSteps(true,wo.id,testFactorySR.id);
            DueForService__c testDS = SBR_3_0_ServiceTestDataFactory.createDueForServiceRecord(true,testAsrt.id, '01');
            
            //ProductConsumed testPc =  SBR_3_0_ServiceTestDataFactory.createProductConsumedRecord(true ,wo.id, '1231239');
            //ceate Service Territory member 
            
            Profile objProfile = [Select Id, Name from Profile where Name =: 'System Administrator' limit 1];
            User objeUser = [Select Id, ProfileId from User where Id=: UserInfo.getUserId()];
            
            //User testrunUser = [Select Id,Name from User where SF_PS_Mechanic_Id__c='9812912317' ];
            //User AdminRunUser = [Select Id,Name from User where UserName LIKE 'AdminRunUser%' ];
            //system.debug('AdminRunUseris '+ AdminRunUser);
            System.debug('testFactorySR.id ' + testFactorySR.id);
            System.debug('testST.id ' + testST.id);
            //System.runAs(testrunUser) {
            //ServiceTerritoryMember testSTM =SBR_3_0_ServiceTestDataFactory.createServiceTerritoryMember(true,testFactorySR.id,testST.id);
            //}
            
            
            
            try {
                SBR_3_0_API_Web_WorkOrderQuote.create();
                //system.assertEquals(200,res.statusCode);
                system.debug('test res 1st' + res);
            }Catch (Exception e) {
                System.debug('An Error Occur | ' + e);
                //system.assertEquals('Related Sales Rep not found!', e.getMessage(), 'Order API did not return Success!');
            }    
            Test.stopTest();
        //}
        
    }
    @isTest
    static void testupdateServiceResourceAsset(){
        //Get Custom setting 
        insert new Bypass_Settings__c(SetupOwnerId=UserInfo.getUserId(), Bypass_Flow__c=true);
        
        
        //Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_Web_Order_Test());
        Credential__c cred = SBR_3_0_TestDataFactory.createCredentials(1, false)[0];
        cred.Name = 'Mule_Token_Endpoint';
        cred.Key_Id__c = 'testKey123';
        cred.Secret__c = 'secret';
        insert cred;
        
        Id pricebookId = Test.getStandardPricebookId();
        Pricebook2 standardPricebook = new Pricebook2(
            name= 'Standard Price Book',
            Id = pricebookId,
            IsActive = true
        );
        update standardPricebook;
        system.debug('standardPricebook is' + standardPricebook.id);
        
        
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_Web_WorkOrder_Test());
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/WorkOrder/ApiCreate/v1/*';
        req.httpMethod = 'POST';
        //String jsonString = '{ "EventType": "1","SF_PS_Company_Code__c": "01","Name": "Test Resouce","SF_PS_Hourly_Billing_Rate__c": 15.0,"SF_PS_Hourly_Internal_Rate__c": 15.0,"SF_PS_Overtime_Billing_Rate__c": 15.0,"SF_PS_Overtime_Internal_Rate__c": 15.0,"SF_PS_Labor_Type__c": "I","SF_PS_Type__c": "D","IsActive": true,"SF_PS_Branch_Loc_Num__c": "6666","SF_PS_Start_Date__c": "2023-02-22","SF_PS_RM_Created_DateTime__c": "2023-02-22T09:45:00Z","SF_PS_RM_Created_By__c": "Test User","SF_PS_RM_Update_DateTime__c": "2023-02-22T09:45:00Z","SF_PS_RM_Updated_By_User__c": "Test User","SF_PS_Mechanic_Id__c": "9999","SF_PS_Comments__c": "Yes api" }';
        // Old JSON String jsonString = '{"data":{"EventType":"1","Status":"Open","OwnerId":"1234","CurrencyIsoCode":"USD","AssetId":"1018879","SVMXA360_ContactPhone_c":"7036004000","SF_PS_Authorized_By__c":"","SF_PS_BillCustOrLoc__c":"L","SF_PS_PONumber__c":"","SF_PS_RM_WO_Number__c":"333222", "SF_PS_Expense_To_Location__c" : "1234","SF_PS_Cause__c":"","SF_PS_Company_Code__c":"01","SF_PS_Complaint__c":"","SF_PS_Cure__c":"","SF_PS_ExpenseCode__c":"RR","SF_PS_LaborCode__c":"9100","SF_PS_Cust_Eqp_Description__c":"","SF_PS_Current_MiHr__c":0.000,"SF_PS_Repair_Ticket__c":0,"SF_PS_Work_Order_Des__c":"CHECK IN RETURN","SF_PS_Current_MiHr2__c":0.000,"SF_PS_Service_Call__c":"Y","SF_PS_Warranty_Amt_Expected__c":0.00,"SF_PS_Claim_Type__c":"N","SF_PS_Actual_Claim_Amt__c":0.00, "SF_PS_Service_Resource__c":"50607", "SF_PS_Claim_Paid_Date__c":"2023-02-22","SF_PS_Claim_Num__c":"","SF_PS_Date_Claim_Filed__c":"2023-02-22","SF_PS_Sales_Rep__c":"111222","SF_PS_Funded__c":"Y","SF_PS_Closed_Date__c":"2023-02-22T09:45:00Z","SF_PS_Current_Loc__c": "0784", "SF_PS_Date_Opened__c":"2023-02-22T09:45:00Z","SF_PS_Charge_GST_Tax__c":false,"SF_PS_Charge_PST_Tax__c":false,"SF_PS_Drivers_License_Number__c":"","SF_PS_Job_Site__c":"","SF_PS_Job_Location__c":"","SF_PS_Due_Date__c":"2023-02-22T09:45:00Z","SF_PS_Labor_Des_Comments__c":"","SF_PS_Labor_Des_Internal__c":"","SF_PS_RM_Last_Maint_By__c":"","SF_PS_RM_Last_Maint_DateTime__c":"2023-02-22T09:45:00Z","SF_PS_Inv_Seq_Num__c":1234,"SF_PS_License_State__c":"OH"},"WorkOrderLineItem":[{"Duration":0.00,"SF_PS_Labor_Code__c":"1000","SF_PS_Mechanic_Name__c":"50607","SF_PS_Hourly_Internal_Rate__c":0.00,"SF_PS_RM_Labor_Line_Item_Number__c":"","SF_PS_RM_External_Id__c":"53474688","SF_PS_Line_Type__c":"LI","SF_PS_Mileage_Charge__c":"MileageCharge","SF_PS_RM_Item_Number__c":"87213143"}],"deletedLines": []}';
        String jsonString = '{"data":{"EventType":"1","Status":"Open","OwnerId":"1234","RecordTypeId" : "WORK ORDER","CurrencyIsoCode":"USD","Pricebook2Id":"'+pricebookId+'","AssetId":"00700","SVMXA360_ContactPhone_c":"7036004000","SF_PS_Authorized_By__c":"","SF_PS_BillCustOrLoc__c":"L","SF_PS_PONumber__c":"","SF_PS_RM_WO_Number__c":"333222","SF_PS_Expense_To_Location__c":"1234","SF_PS_Expense_To_Loc__c":"1234","SF_PS_Cause__c":"","SF_PS_Company_Code__c":"01","SF_PS_Complaint__c":"","SF_PS_Cure__c":"","SF_PS_ExpenseCode__c":"RR","SF_PS_LaborCode__c":"9100","SF_PS_Cust_Eqp_Description__c":"","SF_PS_Current_MiHr__c":0,"SF_PS_Repair_Ticket__c":0,"SF_PS_Work_Order_Des__c":"CHECK IN RETURN","SF_PS_Current_MiHr2__c":0,"SF_PS_Service_Call__c":"Y","SF_PS_Warranty_Amt_Expected__c":0,"SF_PS_Claim_Type__c":"N","SF_PS_Actual_Claim_Amt__c":0,"SF_PS_Service_Resource__c":"981291231","SF_PS_Claim_Paid_Date__c":"2023-02-22","SF_PS_Claim_Num__c":"","SF_PS_Date_Claim_Filed__c":"2023-02-22","SF_PS_Sales_Rep__c":"","SF_PS_Funded__c":"Y","SF_PS_Closed_Date__c":"2023-02-22T09:45:00Z","SF_PS_Current_Loc__c":"1234","SF_PS_Date_Opened__c":"2023-02-22T09:45:00Z","SF_PS_Charge_GST_Tax__c":false,"SF_PS_Charge_PST_Tax__c":false,"SF_PS_Drivers_License_Number__c":"","SF_PS_Job_Site__c":"","SF_PS_Job_Location__c":"","SF_PS_Due_Date__c":"2023-02-22T09:45:00Z","SF_PS_Labor_Des_Comments__c":"","SF_PS_Labor_Des_Internal__c":"","SF_PS_RM_Last_Maint_By__c":"","SF_PS_RM_Last_Maint_DateTime__c":"2023-02-22T09:45:00Z","SF_PS_Inv_Seq_Num__c":1234,"SF_PS_License_State__c":"OH"},"WorkOrderLineItem":[{"Duration":1,"SF_PS_Labor_Code__c":"1000","SF_PS_Mechanic_Name__c":"981291231","SF_PS_Hourly_Internal_Rate__c":0,"SF_PS_RM_Labor_Line_Item_Number__c":"","SF_PS_RM_External_Id__c":"3322123","SF_PS_Line_Type__c":"LI","SF_PS_Mileage_Charge__c":"MileageCharge","SF_PS_RM_Item_Number__c":"87213143"}],"ProductConsumed":[{"SF_PS_RM_External_Id__c":"1231231","SF_PS_Parts_Line_Num__c":"","SF_PS_Selling_Price__c":0,"SF_PS_Cost_Price__c":0,"SF_PS_Line_Type__c":"WO","Product2Id":"10870996","SF_PS_Quantity__c":1,"SF_PS_Unit_Of_Measure__c":"EA","SF_PS_Labor_Code__c":"1000","SF_PS_Line_Level_Comment__c":"string","SF_PS_List_Price__c":0}],"maintenanceSteps":[{"SF_PS_RM_Mtce_Mechanic_Name__c":"981291231","SF_PS_RM_External_Id__c":9812390812,"SF_PS_RM_Mtce_Steps_Y_N__c":"Y","SF_PS_RM_Mtce_Steps_StepNumber__c":"1","SF_PS_RM_Mtce_Steps_Meter_Reading_In__c":0,"SF_PS_RM_Mtce_Steps_Meter_Reading_Out__c":0,"SF_PS_RM_Mtce_Steps_Description__c":"","SF_PS_RM_Mtce_Steps_Pass_Fail__c":"P"}],"deletedLines":[{"SF_PS_RM_External_Id__c":""}]}';
        //request.requestBody = Blob.valueOf(JSON.serialize(jsonString));
        req.requestBody = Blob.valueOf(jsonString);
        
        RestContext.request = req;
        RestContext.response= res;
        
        User testAdminUser = [Select Id,Name from User where UserName LIKE 'testAdminUser%' ];
        system.debug('test request' + req);
        system.debug('test res' + res);
        //System.runAs(testAdminUser){
            insert new Bypass_Settings__c(SetupOwnerId=testAdminUser.Id, Bypass_Flow__c=true);
            Test.startTest();
            Asset testAsrt =  SBR_3_0_ServiceTestDataFactory.createAsset(true);
            
            //Create Exponce to Location
            ServiceTerritory  testE2Loc = SBR_3_0_ServiceTestDataFactory.createServiceTerritory(true);
            
            //Create Service Territory 
            //ServiceTerritory  testST = SBR_3_0_ServiceTestDataFactory.createServiceTerritory(false);
            OperatingHours oh = new OperatingHours(Name='TEST_Hours1',TimeZone='America/Halifax');
            insert oh;
            string name  ='TestHr';
            ServiceTerritory testST= new ServiceTerritory(Name=name,OperatingHoursId=oh.Id,IsActive=true,Branch_Location_Number__c = '1234',CountryCode = 'US');
            insert testST;
            
            ServiceResource testFactorySR = SBR_3_0_ServiceTestDataFactory.create_Service_Resource(false);
            User testUser = [Select Id,Name from User where UserName LIKE 'SRTestUser2%' Limit 1 ];
            testFactorySR.RelatedRecordId = testUser.Id;
            testFactorySR.ResourceType = 'T';
            insert testFactorySR;
            
            //create work order
            //workorder wop = SBR_3_0_ServiceTestDataFactory.createWorkOrder(false);
            //wop.SF_PS_RM_WO_Number__c = '01-333223234';
            //wop.SF_PS_Expense_To_Location__c = testST.id;
            //wop.AssetId = testAsrt.id;
            //wop.ServiceTerritoryId  = testE2Loc.id;
            //wop.SF_PS_Service_Resource__c = testFactorySR.id;
            //insert wop;
            
            //create work order 
            workorder wo = SBR_3_0_ServiceTestDataFactory.createWorkOrder(false);
            wo.SF_PS_RM_WO_Number__c = '01-333222';
            wo.SF_PS_Expense_To_Location__c = testST.id;
            wo.AssetId = testAsrt.id;
            wo.ServiceTerritoryId  = testE2Loc.id;
            wo.SF_PS_Service_Resource__c = testFactorySR.id;
            wo.Pricebook2Id= standardPricebook.id;
            wo.recordTypeId =Schema.SObjectType.workorder.getRecordTypeInfosByName().get('Inspection Record').getRecordTypeId();
            //wo.ParentWorkOrderId = wop.Id;
            insert wo;
            
            
            
            
            WorkOrderLineItem testwoli =  SBR_3_0_ServiceTestDataFactory.createWoli(false,wo.id,testFactorySR.id);
            testwoli.Duration = 1;
            if (testwoli != null) {
                insert testwoli;
            }
            //create product consumed
            ProductConsumed testPc =  SBR_3_0_ServiceTestDataFactory.createProductConsumedRecord(true ,wo.id, '1231231');
            //SF_PS_Maintenance_Steps__c testMc = SBR_3_0_ServiceTestDataFactory.createMaintenanceSteps(true,wo.id,testFactorySR.id);
            DueForService__c testDS = SBR_3_0_ServiceTestDataFactory.createDueForServiceRecord(true,testAsrt.id, '01');
            
            //ProductConsumed testPc =  SBR_3_0_ServiceTestDataFactory.createProductConsumedRecord(true ,wo.id, '1231239');
            //ceate Service Territory member 
            
            Profile objProfile = [Select Id, Name from Profile where Name =: 'System Administrator' limit 1];
            User objeUser = [Select Id, ProfileId from User where Id=: UserInfo.getUserId()];
            
            //User testrunUser = [Select Id,Name from User where SF_PS_Mechanic_Id__c='9812912317' ];
            //User AdminRunUser = [Select Id,Name from User where UserName LIKE 'AdminRunUser%' ];
            //system.debug('AdminRunUseris '+ AdminRunUser);
            System.debug('testFactorySR.id ' + testFactorySR.id);
            System.debug('testST.id ' + testST.id);
            //System.runAs(testrunUser) {
            //ServiceTerritoryMember testSTM =SBR_3_0_ServiceTestDataFactory.createServiceTerritoryMember(true,testFactorySR.id,testST.id);
            //}
            
            
            
            try {
                SBR_3_0_API_Web_WorkOrder.create();
                //system.assertEquals(200,res.statusCode);
                system.debug('test res 1st' + res);
            }Catch (Exception e) {
                System.debug('An Error Occur | ' + e);
                //system.assertEquals('Related Sales Rep not found!', e.getMessage(), 'Order API did not return Success!');
            }    
            Test.stopTest();
        }
       
    //}
    
    
    // @isTest
    // static void testSyncWorkOrderToSF_Success() {
    //     // Prepare sample request data in JSON format
    
    //     RestResponse res = new RestResponse(); 
    //     Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_Web_Product_Test());
    //     RestRequest request = new RestRequest();
    //     request.requestUri = 'https://yourInstance.salesforce.com/services/apexrest/Quote/ApiCreate/v1/';
    //     request.httpMethod = 'POST';
    //     request.addHeader('Content-Type', 'application/json');
    //     Test.startTest();
    
    
    //     // Set up the mock HTTP request
    //     Test.startTest();
    //     RestRequest request = new RestRequest();
    //     request.requestURI = '/services/apexrest/WorkOrder/ApiCreate/v1';
    //     request.httpMethod = 'POST';
    //     request.requestBody = Blob.valueOf(requestBody);
    //     RestContext.request = request;
    
    //     // Set up the mock response for SBR_3_0_WorkOrderDA class
    //     Test.setMock(HttpCalloutMock.class, new SBR_3_0_WorkOrderDA());
    
    //     // Call the API method
    //     SBR_3_0_API_Web_WorkOrder.create();
    
    //     // Verify the response
    //     RestResponse response = RestContext.response;
    //     System.assertEquals(200, response.statusCode, 'Expected status code: 200');
    //     Map<String, Object> responseBody = (Map<String, Object>) JSON.deserializeUntyped(response.responseBody.toString());
    //     System.assertEquals('Success', responseBody.get('Status'), 'Expected Status: Success');
    //     System.assertNotEquals(null, responseBody.get('Message'), 'Expected non-null Message');
    
    //     Test.stopTest();
    //     }
    
   
}