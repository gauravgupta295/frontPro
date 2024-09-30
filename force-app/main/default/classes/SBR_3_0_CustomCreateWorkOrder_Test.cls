@isTest
public class SBR_3_0_CustomCreateWorkOrder_Test  Implements HttpCalloutMock  {
    public HTTPResponse respond(HTTPRequest request) {
        // Create a fake response
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setBody('Success');
        response.setStatusCode(200);
        return response; 
    }
    @TestSetup
    static void makeData(){
        
        //Create Run Test User as System Admin
        //User runTestClassUser = SBR_3_0_ServiceTestDataFactory.createSystemAdminRunUser(true,'12347','9812912317');
        //system.debug('Checkpoint 11::'+runTestClassUser +'::'+runTestClassUser.profileId);
        //Create Test User
        User testUser = SBR_3_0_ServiceTestDataFactory.createServiceResourceUserWO(true,'1234','981291231');
        User testAdminUser = SBR_3_0_ServiceTestDataFactory.createSystemAdminUser(true,'8898','987644'); 
        testAdminUser.RepID__c = '127691';
        update testAdminUser;
        // insert new PermissionSetAssignment(AssigneeId=UserInfo.getUserId(),
        //                            PermissionSetId=mockedPermissionSetId);
        
        PermissionSetLicense psl = [SELECT Id FROM PermissionSetLicense WHERE DeveloperName = 'SalesforceCPQ_CPQStandardPerm'];
        List<PermissionSetLicenseAssign> pslList =[	Select Id, AssigneeId , Assignee.Name, PermissionSetLicense.DeveloperName  , 
                                                   PermissionSetLicenseId 
                                                   from PermissionSetLicenseAssign 
                                                   where PermissionSetLicense.DeveloperName = 'SalesforceCPQ_CPQStandardPerm' 
                                                   AND AssigneeId = : testAdminUser.Id];
        if (pslList.size()==0){
            insert new PermissionSetLicenseAssign(AssigneeId = testAdminUser.Id, PermissionSetLicenseId = psl.Id);
        }
        
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Integration_API_Access'];
        List <PermissionSetAssignment> permSetCheck = [SELECT Id from PermissionSetAssignment WHERE PermissionSetId = : ps.Id
                                                       AND AssigneeId = : testAdminUser.Id];
        if (permSetCheck.size()==0){
            insert new PermissionSetAssignment(AssigneeId = testAdminUser.Id, PermissionSetId = ps.Id);
        }
        
        
    }
    
    
 
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
        
        
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_CreateWorkOrdTest());
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
        //    insert new Bypass_Settings__c(SetupOwnerId=testAdminUser.Id, Bypass_Flow__c=true);
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
        ServiceTerritoryMember testSTM =SBR_3_0_ServiceTestDataFactory.createServiceTerritoryMember(true,testFactorySR.id,testST.id);
        
        SBR_3_0_CustomCreateWorkOrder co = new SBR_3_0_CustomCreateWorkOrder(jsonString);
        String returnVal = co.syncWorkOrderToSF();
        Test.stopTest();
        // }
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
        
        
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_CreateWorkOrdTest());
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
        /*System.runAs(testAdminUser){
insert new Bypass_Settings__c(SetupOwnerId=testAdminUser.Id, Bypass_Flow__c=true);*/
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
        ServiceTerritoryMember testSTM =SBR_3_0_ServiceTestDataFactory.createServiceTerritoryMember(true,testFactorySR.id,testST.id);
        //}
        
        SBR_3_0_CustomCreateWorkOrder co = new SBR_3_0_CustomCreateWorkOrder(jsonString);
        String returnVal = co.syncWorkOrderToSF(); 
        Test.stopTest();
        // }
        
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
        
        
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_CreateWorkOrdTest());
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/WorkOrderCredit/ApiCreate/v1/*';
        req.httpMethod = 'POST';
        String jsonString = '{"data":{"EventType":"1","Status":"Open","OwnerId":"1234","RecordTypeId" : "WORK ORDER","CurrencyIsoCode":"USD","Pricebook2Id":"'+pricebookId+'","AssetId":"1018879","SVMXA360_ContactPhone_c":"7036004000","SF_PS_Authorized_By__c":"","SF_PS_BillCustOrLoc__c":"L","SF_PS_PONumber__c":"","SF_PS_RM_WO_Number__c":"333222","SF_PS_Expense_To_Location__c":"1234","SF_PS_Expense_To_Loc__c":"1234","SF_PS_Cause__c":"","SF_PS_Company_Code__c":"01","SF_PS_Complaint__c":"","SF_PS_Cure__c":"","SF_PS_ExpenseCode__c":"RR","SF_PS_LaborCode__c":"9100","SF_PS_Cust_Eqp_Description__c":"","SF_PS_Current_MiHr__c":0,"SF_PS_Repair_Ticket__c":0,"SF_PS_Work_Order_Des__c":"WORK ORDER CREDIT","SF_PS_Current_MiHr2__c":0,"SF_PS_Service_Call__c":"Y","SF_PS_Warranty_Amt_Expected__c":0,"SF_PS_Claim_Type__c":"N","SF_PS_Actual_Claim_Amt__c":0,"SF_PS_Service_Resource__c":"981291231","SF_PS_Claim_Paid_Date__c":"2023-02-22","SF_PS_Claim_Num__c":"","SF_PS_Date_Claim_Filed__c":"2023-02-22","SF_PS_Sales_Rep__c":"","SF_PS_Funded__c":"Y","SF_PS_Closed_Date__c":"2023-02-22T09:45:00Z","SF_PS_Current_Loc__c":"1234","SF_PS_Date_Opened__c":"2023-02-22T09:45:00Z","SF_PS_Charge_GST_Tax__c":false,"SF_PS_Charge_PST_Tax__c":false,"SF_PS_Drivers_License_Number__c":"","SF_PS_Job_Site__c":"","SF_PS_Job_Location__c":"","SF_PS_Due_Date__c":"2023-02-22T09:45:00Z","SF_PS_Labor_Des_Comments__c":"","SF_PS_Labor_Des_Internal__c":"","SF_PS_RM_Last_Maint_By__c":"","SF_PS_RM_Last_Maint_DateTime__c":"2023-02-22T09:45:00Z","SF_PS_Inv_Seq_Num__c":1234,"SF_PS_License_State__c":"OH"},"CreditLineItem":[{"SF_PS_Duration__c":1,"SF_PS_Labor_Code__c":"1000","SF_PS_Mechanic_Name__c":"981291231","SF_PS_Hourly_Internal_Rate__c":0,"SF_PS_RM_Labor_Line_Item_Number__c":"","SF_PS_RM_External_Id__c":"3322123","SF_PS_Line_Type__c":"LI","SF_PS_Mileage_Charge__c":"MileageCharge","SF_PS_RM_Item_Number__c":"87213143"}],"CreditParts":[{"SF_PS_RM_External_Id__c":"1231231","SF_PS_Parts_Line_Num__c":"","SF_PS_ItemType__c": "P","SF_PS_Selling_Price__c":0,"SF_PS_Cost_Price__c":0,"SF_PS_Line_Type__c":"LI","SF_PS_Product2Id__c":"10870996","SF_PS_Quantity__c":1,"SF_PS_Unit_Of_Measure__c":"EA","SF_PS_Labor_Code__c":"1000","SF_PS_Line_Level_Comment__c":"string","SF_PS_List_Price__c":0}],"deletedLines":[{"SF_PS_RM_External_Id__c":""}]}';
        //request.requestBody = Blob.valueOf(JSON.serialize(jsonString));
        req.requestBody = Blob.valueOf(jsonString);
        
        RestContext.request = req;
        RestContext.response= res;
        
        User testAdminUser = [Select Id,Name from User where UserName LIKE 'testAdminUser%' ];
        system.debug('test request' + req);
        system.debug('test res' + res);
        /* System.runAs(testAdminUser){
insert new Bypass_Settings__c(SetupOwnerId=testAdminUser.Id, Bypass_Flow__c=true);*/
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
        ServiceTerritoryMember testSTM =SBR_3_0_ServiceTestDataFactory.createServiceTerritoryMember(true,testFactorySR.id,testST.id);
        //}
        
        
        SBR_3_0_CustomCreateWorkOrder co = new SBR_3_0_CustomCreateWorkOrder(jsonString);
        String returnVal = co.syncWorkOrderToSF();    
        Test.stopTest();
        // }
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
        
        
        
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_CreateWorkOrdTest());
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
        /*System.runAs(testAdminUser){
insert new Bypass_Settings__c(SetupOwnerId=testAdminUser.Id, Bypass_Flow__c=true);*/
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
        ServiceTerritoryMember testSTM =SBR_3_0_ServiceTestDataFactory.createServiceTerritoryMember(true,testFactorySR.id,testST.id);
        
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
        
        
        
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_CreateWorkOrdTest());
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
        /*System.runAs(testAdminUser){
insert new Bypass_Settings__c(SetupOwnerId=testAdminUser.Id, Bypass_Flow__c=true);*/
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
        ServiceTerritoryMember testSTM =SBR_3_0_ServiceTestDataFactory.createServiceTerritoryMember(true,testFactorySR.id,testST.id);
        
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
        
        
        
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_CreateWorkOrdTest());
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
        /*System.runAs(testAdminUser){
insert new Bypass_Settings__c(SetupOwnerId=testAdminUser.Id, Bypass_Flow__c=true);*/
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
        ServiceTerritoryMember testSTM =SBR_3_0_ServiceTestDataFactory.createServiceTerritoryMember(true,testFactorySR.id,testST.id);
        
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
        
        
        
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_CreateWorkOrdTest());
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
        /*System.runAs(testAdminUser){
insert new Bypass_Settings__c(SetupOwnerId=testAdminUser.Id, Bypass_Flow__c=true);*/
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
        ServiceTerritoryMember testSTM =SBR_3_0_ServiceTestDataFactory.createServiceTerritoryMember(true,testFactorySR.id,testST.id);
        
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
        
        
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_CreateWorkOrdTest());
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
        /*System.runAs(testAdminUser){
insert new Bypass_Settings__c(SetupOwnerId=testAdminUser.Id, Bypass_Flow__c=true);*/
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
        ServiceTerritoryMember testSTM =SBR_3_0_ServiceTestDataFactory.createServiceTerritoryMember(true,testFactorySR.id,testST.id);
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
        
        
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_CreateWorkOrdTest());
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
        /* System.runAs(testAdminUser){
insert new Bypass_Settings__c(SetupOwnerId=testAdminUser.Id, Bypass_Flow__c=true);*/
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
        ServiceTerritoryMember testSTM =SBR_3_0_ServiceTestDataFactory.createServiceTerritoryMember(true,testFactorySR.id,testST.id);
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
    static void testupdateWorkOrderCredit1(){
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
        
        
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_CreateWorkOrdTest());
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/WorkOrderCredit/ApiCreate/v1/*';
        req.httpMethod = 'POST';
        String jsonString = '{"data":{"EventType":"1","Status":"Open","OwnerId":"1234","RecordTypeId" : "WORK ORDER","CurrencyIsoCode":"USD","Pricebook2Id":"'+pricebookId+'","AssetId":"1018879","SVMXA360_ContactPhone_c":"7036004000","SF_PS_Authorized_By__c":"","SF_PS_BillCustOrLoc__c":"L","SF_PS_PONumber__c":"","SF_PS_RM_WO_Number__c":"333222","SF_PS_RM_Credited_WO_Number__c":"333221","SF_PS_Expense_To_Location__c":"1234","SF_PS_Expense_To_Loc__c":"1234","SF_PS_Cause__c":"","SF_PS_Company_Code__c":"01","SF_PS_Complaint__c":"","SF_PS_Cure__c":"","SF_PS_ExpenseCode__c":"RR","SF_PS_LaborCode__c":"9100","SF_PS_Cust_Eqp_Description__c":"","SF_PS_Current_MiHr__c":0,"SF_PS_Repair_Ticket__c":0,"SF_PS_Work_Order_Des__c":"WORK ORDER CREDIT","SF_PS_Current_MiHr2__c":0,"SF_PS_Service_Call__c":"Y","SF_PS_Warranty_Amt_Expected__c":0,"SF_PS_Claim_Type__c":"N","SF_PS_Actual_Claim_Amt__c":0,"SF_PS_Service_Resource__c":"981291231","SF_PS_Claim_Paid_Date__c":"2023-02-22","SF_PS_Claim_Num__c":"","SF_PS_Date_Claim_Filed__c":"2023-02-22","SF_PS_Sales_Rep__c":"","SF_PS_Funded__c":"Y","SF_PS_Closed_Date__c":"2023-02-22T09:45:00Z","SF_PS_Current_Loc__c":"1234","SF_PS_Date_Opened__c":"2023-02-22T09:45:00Z","SF_PS_Charge_GST_Tax__c":false,"SF_PS_Charge_PST_Tax__c":false,"SF_PS_Drivers_License_Number__c":"","SF_PS_Job_Site__c":"","SF_PS_Job_Location__c":"","SF_PS_Due_Date__c":"2023-02-22T09:45:00Z","SF_PS_Labor_Des_Comments__c":"","SF_PS_Labor_Des_Internal__c":"","SF_PS_RM_Last_Maint_By__c":"","SF_PS_RM_Last_Maint_DateTime__c":"2023-02-22T09:45:00Z","SF_PS_Inv_Seq_Num__c":1234,"SF_PS_License_State__c":"OH"},"CreditLineItem":[{"SF_PS_Duration__c":1,"SF_PS_Labor_Code__c":"1000","SF_PS_Mechanic_Name__c":"981291231","SF_PS_Hourly_Internal_Rate__c":0,"SF_PS_RM_Labor_Line_Item_Number__c":"","SF_PS_RM_External_Id__c":"3322123","SF_PS_Line_Type__c":"LI","SF_PS_Mileage_Charge__c":"MileageCharge","SF_PS_RM_Item_Number__c":"87213143"}],"CreditParts":[{"SF_PS_RM_External_Id__c":"1231231","SF_PS_Parts_Line_Num__c":"","SF_PS_ItemType__c": "P","SF_PS_Selling_Price__c":0,"SF_PS_Cost_Price__c":0,"SF_PS_Line_Type__c":"LI","SF_PS_Product2Id__c":"10870996","SF_PS_Quantity__c":1,"SF_PS_Unit_Of_Measure__c":"EA","SF_PS_Labor_Code__c":"1000","SF_PS_Line_Level_Comment__c":"string","SF_PS_List_Price__c":0}],"deletedLines":[{"SF_PS_RM_External_Id__c":""}]}';
        //request.requestBody = Blob.valueOf(JSON.serialize(jsonString));
        req.requestBody = Blob.valueOf(jsonString);
        
        RestContext.request = req;
        RestContext.response= res;
        
        User testAdminUser = [Select Id,Name from User where UserName LIKE 'testAdminUser%' ];
        system.debug('test request' + req);
        system.debug('test res' + res);
        /* System.runAs(testAdminUser){
insert new Bypass_Settings__c(SetupOwnerId=testAdminUser.Id, Bypass_Flow__c=true);*/
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
        workorder wop = SBR_3_0_ServiceTestDataFactory.createWorkOrder(false);
        wop.SF_PS_RM_WO_Number__c = '01-333221';
        wop.SF_PS_Expense_To_Location__c = testST.id;
        wop.AssetId = testAsrt.id;
        wop.ServiceTerritoryId  = testE2Loc.id;
        wop.SF_PS_Service_Resource__c = testFactorySR.id;
        wop.Pricebook2Id= standardPricebook.id;
        insert wop;
        
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
        ServiceTerritoryMember testSTM =SBR_3_0_ServiceTestDataFactory.createServiceTerritoryMember(true,testFactorySR.id,testST.id);
        //}
        
        
        SBR_3_0_CustomCreateWorkOrder co = new SBR_3_0_CustomCreateWorkOrder(jsonString);
        String returnVal = co.syncWorkOrderToSF();    
        Test.stopTest();
        // }
    }
    
    @isTest
    static void testupdateWorkOrderCredit2(){
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
         User testAdminUser = [Select Id,Name from User where UserName LIKE 'testAdminUser%' ];        
        List<Account> acc = SBR_3_0_TestDataFactory.createAccounts(1, true);
        acc[0].RM_Account_Number__c = acc[0].Company_Code__c+'-'+acc[0].id;
        update acc[0];
        List<Schema.Location> branch = SBR_3_0_TestDataFactory.createLocations(1, true, 'Branch');
        List<Schema.Location> jobLoc = SBR_3_0_TestDataFactory.createLocations(1, true, 'Shared Job Location');
        List<AssociatedLocation> al = SBR_3_0_TestDataFactory.createAssociatedLocations(1, acc[0].Id, branch[0].Id, jobLoc[0].Id, true);  
        
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_CreateWorkOrdTest());
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/WorkOrderCredit/ApiCreate/v1/*';
        req.httpMethod = 'POST';
        String jsonString = '{"data":{"EventType":"1","Status":"Open","OwnerId":"1234","RecordTypeId" : "WORK ORDER","CurrencyIsoCode":"USD","Pricebook2Id":"'+pricebookId+'","AssetId":"1018879","SVMXA360_ContactPhone_c":"7036004000","SF_PS_Authorized_By__c":"","SF_PS_BillCustOrLoc__c":"L","SF_PS_PONumber__c":"","SF_PS_RM_WO_Number__c":"333222","AccountId":"'+acc[0].Id+'","SF_PS_Job_Site__c":"'+al[0].Job_Number__c+'","SF_PS_Expense_To_Location__c":"1234","SF_PS_Expense_To_Loc__c":"1234","SF_PS_Cause__c":"","SF_PS_Company_Code__c":"01","SF_PS_Complaint__c":"","SF_PS_Cure__c":"","SF_PS_ExpenseCode__c":"RR","SF_PS_LaborCode__c":"9100","SF_PS_Cust_Eqp_Description__c":"","SF_PS_Current_MiHr__c":0,"SF_PS_Repair_Ticket__c":0,"SF_PS_Work_Order_Des__c":"WORK ORDER CREDIT","SF_PS_Current_MiHr2__c":0,"SF_PS_Service_Call__c":"Y","SF_PS_Warranty_Amt_Expected__c":0,"SF_PS_Claim_Type__c":"N","SF_PS_Actual_Claim_Amt__c":0,"SF_PS_Service_Resource__c":"981291231","SF_PS_Claim_Paid_Date__c":"2023-02-22","SF_PS_Claim_Num__c":"","SF_PS_Date_Claim_Filed__c":"2023-02-22","SF_PS_Sales_Rep__c":"127691","SF_PS_Funded__c":"Y","SF_PS_Closed_Date__c":"2023-02-22T09:45:00Z","SF_PS_Current_Loc__c":"1234","SF_PS_Date_Opened__c":"2023-02-22T09:45:00Z","SF_PS_Charge_GST_Tax__c":false,"SF_PS_Charge_PST_Tax__c":false,"SF_PS_Drivers_License_Number__c":"","SF_PS_Job_Location__c":"","SF_PS_Due_Date__c":"2023-02-22T09:45:00Z","SF_PS_Labor_Des_Comments__c":"","SF_PS_Labor_Des_Internal__c":"","SF_PS_RM_Last_Maint_By__c":"","SF_PS_RM_Last_Maint_DateTime__c":"2023-02-22T09:45:00Z","SF_PS_Inv_Seq_Num__c":1234,"SF_PS_License_State__c":"OH"},"CreditLineItem":[{"SF_PS_Duration__c":1,"SF_PS_Labor_Code__c":"1000","SF_PS_Mechanic_Name__c":"981291231","SF_PS_Hourly_Internal_Rate__c":0,"SF_PS_RM_Labor_Line_Item_Number__c":"","SF_PS_RM_External_Id__c":"3322123","SF_PS_Line_Type__c":"LI","SF_PS_Mileage_Charge__c":"MileageCharge","SF_PS_RM_Item_Number__c":"87213143"}],"CreditParts":[{"SF_PS_RM_External_Id__c":"1231231","SF_PS_Parts_Line_Num__c":"","SF_PS_ItemType__c": "P","SF_PS_Selling_Price__c":0,"SF_PS_Cost_Price__c":0,"SF_PS_Line_Type__c":"LI","SF_PS_Product2Id__c":"10870996","SF_PS_Quantity__c":1,"SF_PS_Unit_Of_Measure__c":"EA","SF_PS_Labor_Code__c":"1000","SF_PS_Line_Level_Comment__c":"string","SF_PS_List_Price__c":0}],"deletedLines":[{"SF_PS_RM_External_Id__c":""}]}';
        
        req.requestBody = Blob.valueOf(jsonString);
        
        RestContext.request = req;
        RestContext.response= res;
        
       
        system.debug('test request' + req);
        system.debug('test res' + res);
        /* System.runAs(testAdminUser){
insert new Bypass_Settings__c(SetupOwnerId=testAdminUser.Id, Bypass_Flow__c=true);*/
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
        ServiceTerritoryMember testSTM =SBR_3_0_ServiceTestDataFactory.createServiceTerritoryMember(true,testFactorySR.id,testST.id);
        //}
        
        
        SBR_3_0_CustomCreateWorkOrder co = new SBR_3_0_CustomCreateWorkOrder(jsonString);
        String returnVal = co.syncWorkOrderToSF();    
        Test.stopTest();
        // }
    }
     @isTest
    static void testupdateServiceResource1(){
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
        
        
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_CreateWorkOrdTest());
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/WorkOrder/ApiCreate/v1/*';
        req.httpMethod = 'POST';
        String jsonString = '{"data":{"EventType":"1","Status":"Open","OwnerId":"1234","RecordTypeId" : "WORK ORDER","CurrencyIsoCode":"USD","Pricebook2Id":"'+pricebookId+'","AssetId":"1018879","SVMXA360_ContactPhone_c":"7036004000","SF_PS_Authorized_By__c":"","SF_PS_BillCustOrLoc__c":"L","SF_PS_PONumber__c":"","SF_PS_RM_WO_Number__c":"333222","SF_PS_Expense_To_Location__c":"1234","SF_PS_Expense_To_Loc__c":"1234","SF_PS_Cause__c":"","SF_PS_Company_Code__c":"01","SF_PS_Complaint__c":"","SF_PS_Cure__c":"","SF_PS_ExpenseCode__c":"RR","SF_PS_LaborCode__c":"9100","SF_PS_Cust_Eqp_Description__c":"","SF_PS_Current_MiHr__c":0,"SF_PS_Repair_Ticket__c":0,"SF_PS_Work_Order_Des__c":"CHECK IN RETURN","SF_PS_Current_MiHr2__c":0,"SF_PS_Service_Call__c":"Y","SF_PS_Warranty_Amt_Expected__c":0,"SF_PS_Claim_Type__c":"N","SF_PS_Actual_Claim_Amt__c":0,"SF_PS_Service_Resource__c":"981291231","SF_PS_Claim_Paid_Date__c":"2023-02-22","SF_PS_Claim_Num__c":"","SF_PS_Date_Claim_Filed__c":"2023-02-22","SF_PS_Sales_Rep__c":"","SF_PS_Funded__c":"Y","SF_PS_Closed_Date__c":"2023-02-22T09:45:00Z","SF_PS_Current_Loc__c":"1234","SF_PS_Date_Opened__c":"2023-02-22T09:45:00Z","SF_PS_Charge_GST_Tax__c":false,"SF_PS_Charge_PST_Tax__c":false,"SF_PS_Drivers_License_Number__c":"","SF_PS_Job_Site__c":"","SF_PS_Job_Location__c":"","SF_PS_Due_Date__c":"2023-02-22T09:45:00Z","SF_PS_Labor_Des_Comments__c":"","SF_PS_Labor_Des_Internal__c":"","SF_PS_RM_Last_Maint_By__c":"","SF_PS_RM_Last_Maint_DateTime__c":"2023-02-22T09:45:00Z","SF_PS_Inv_Seq_Num__c":1234,"SF_PS_License_State__c":"OH"},"WorkOrderLineItem":[{"Duration":1,"SF_PS_Labor_Code__c":"1000","SF_PS_Mechanic_Name__c":"981291231","SF_PS_Hourly_Internal_Rate__c":0,"SF_PS_RM_Labor_Line_Item_Number__c":"","SF_PS_RM_External_Id__c":"3322123","SF_PS_Line_Type__c":"LI","SF_PS_Mileage_Charge__c":"MileageCharge","SF_PS_RM_Item_Number__c":"87213143"}],"ProductConsumed":[{"SF_PS_RM_External_Id__c":"1231231","SF_PS_Parts_Line_Num__c":"","SF_PS_Selling_Price__c":0,"SF_PS_Cost_Price__c":0,"SF_PS_Line_Type__c":"WO","Product2Id":"10870996","SF_PS_Quantity__c":1,"SF_PS_Unit_Of_Measure__c":"EA","SF_PS_Labor_Code__c":"1000","SF_PS_Line_Level_Comment__c":"string","SF_PS_List_Price__c":0}],"maintenanceSteps":[{"SF_PS_RM_Mtce_Mechanic_Name__c":"981291231","SF_PS_RM_External_Id__c":9812390812,"SF_PS_RM_Mtce_Steps_Y_N__c":"Y","SF_PS_RM_Mtce_Steps_StepNumber__c":"2","SF_PS_RM_Mtce_Steps_Meter_Reading_In__c":0,"SF_PS_RM_Mtce_Steps_Meter_Reading_Out__c":0,"SF_PS_RM_Mtce_Steps_Description__c":"","SF_PS_RM_Mtce_Steps_Pass_Fail__c":"P"}],"deletedLines":[{"SF_PS_RM_External_Id__c":""}]}';
        req.requestBody = Blob.valueOf(jsonString);
        
        RestContext.request = req;
        RestContext.response= res;
        
        User testAdminUser = [Select Id,Name from User where UserName LIKE 'testAdminUser%' ];
        system.debug('test request' + req);
        system.debug('test res' + res);
        //System.runAs(testAdminUser){
        //    insert new Bypass_Settings__c(SetupOwnerId=testAdminUser.Id, Bypass_Flow__c=true);
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
        ServiceTerritoryMember testSTM =SBR_3_0_ServiceTestDataFactory.createServiceTerritoryMember(true,testFactorySR.id,testST.id);
        
        SBR_3_0_CustomCreateWorkOrder co = new SBR_3_0_CustomCreateWorkOrder(jsonString);
        String returnVal = co.syncWorkOrderToSF();
        Test.stopTest();
        // }
    }
    
     @isTest
    static void testupdateServiceResource2(){
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
        
        
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_CreateWorkOrdTest());
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/WorkOrder/ApiCreate/v1/*';
        req.httpMethod = 'POST';
        String jsonString = '{"data":{"EventType":"1","Status":"Open","OwnerId":"1234","RecordTypeId" : "WORK ORDER","CurrencyIsoCode":"USD","Pricebook2Id":"'+pricebookId+'","AssetId":"1018879","SVMXA360_ContactPhone_c":"7036004000","SF_PS_Authorized_By__c":"","SF_PS_BillCustOrLoc__c":"L","SF_PS_PONumber__c":"","SF_PS_RM_WO_Number__c":"333222","SF_PS_Expense_To_Location__c":"1234","SF_PS_Expense_To_Loc__c":"1234","SF_PS_Cause__c":"","SF_PS_Company_Code__c":"01","SF_PS_Complaint__c":"","SF_PS_Cure__c":"","SF_PS_ExpenseCode__c":"RR","SF_PS_LaborCode__c":"9100","SF_PS_Cust_Eqp_Description__c":"","SF_PS_Current_MiHr__c":0,"SF_PS_Repair_Ticket__c":0,"SF_PS_Work_Order_Des__c":"CHECK IN RETURN","SF_PS_Current_MiHr2__c":0,"SF_PS_Service_Call__c":"Y","SF_PS_Warranty_Amt_Expected__c":0,"SF_PS_Claim_Type__c":"N","SF_PS_Actual_Claim_Amt__c":0,"SF_PS_Service_Resource__c":"981291231","SF_PS_Claim_Paid_Date__c":"2023-02-22","SF_PS_Claim_Num__c":"","SF_PS_Date_Claim_Filed__c":"2023-02-22","SF_PS_Sales_Rep__c":"","SF_PS_Funded__c":"Y","SF_PS_Closed_Date__c":"2023-02-22T09:45:00Z","SF_PS_Current_Loc__c":"1234","SF_PS_Date_Opened__c":"2023-02-22T09:45:00Z","SF_PS_Charge_GST_Tax__c":false,"SF_PS_Charge_PST_Tax__c":false,"SF_PS_Drivers_License_Number__c":"","SF_PS_Job_Site__c":"","SF_PS_Job_Location__c":"","SF_PS_Due_Date__c":"2023-02-22T09:45:00Z","SF_PS_Labor_Des_Comments__c":"","SF_PS_Labor_Des_Internal__c":"","SF_PS_RM_Last_Maint_By__c":"","SF_PS_RM_Last_Maint_DateTime__c":"2023-02-22T09:45:00Z","SF_PS_Inv_Seq_Num__c":1234,"SF_PS_License_State__c":"OH"},"WorkOrderLineItem":[{"Duration":1,"SF_PS_Labor_Code__c":"1000","SF_PS_Mechanic_Name__c":"981291231","SF_PS_Hourly_Internal_Rate__c":0,"SF_PS_RM_Labor_Line_Item_Number__c":"","SF_PS_RM_External_Id__c":"3322123","SF_PS_Line_Type__c":"LI","SF_PS_Mileage_Charge__c":"MileageCharge","SF_PS_RM_Item_Number__c":"87213143"}],"ProductConsumed":[{"SF_PS_RM_External_Id__c":"1231231","SF_PS_Parts_Line_Num__c":"","SF_PS_Selling_Price__c":0,"SF_PS_Cost_Price__c":0,"SF_PS_Line_Type__c":"WO","Product2Id":"10870996","SF_PS_Quantity__c":1,"SF_PS_Unit_Of_Measure__c":"EA","SF_PS_Labor_Code__c":"1000","SF_PS_Line_Level_Comment__c":"string","SF_PS_List_Price__c":0}],"maintenanceSteps":[{"SF_PS_RM_Mtce_Mechanic_Name__c":"981291231","SF_PS_RM_External_Id__c":9812390812,"SF_PS_RM_Mtce_Steps_Y_N__c":"Y","SF_PS_RM_Mtce_Steps_StepNumber__c":"2","SF_PS_RM_Mtce_Steps_Meter_Reading_In__c":0,"SF_PS_RM_Mtce_Steps_Meter_Reading_Out__c":0,"SF_PS_RM_Mtce_Steps_Description__c":"","SF_PS_RM_Mtce_Steps_Pass_Fail__c":"P"}],"deletedLines":[{"SF_PS_RM_External_Id__c":"123456"}]}';
        req.requestBody = Blob.valueOf(jsonString);
        
        RestContext.request = req;
        RestContext.response= res;
        
        User testAdminUser = [Select Id,Name from User where UserName LIKE 'testAdminUser%' ];
        system.debug('test request' + req);
        system.debug('test res' + res);
        //System.runAs(testAdminUser){
        //    insert new Bypass_Settings__c(SetupOwnerId=testAdminUser.Id, Bypass_Flow__c=true);
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
        workorder wo = SBR_3_0_ServiceTestDataFactory.createWorkOrder(false);
        wo.SF_PS_RM_WO_Number__c = '01-333222';
        wo.SF_PS_Expense_To_Location__c = testST.id;
        wo.AssetId = testAsrt.id;
        wo.ServiceTerritoryId  = testE2Loc.id;
        wo.SF_PS_Service_Resource__c = testFactorySR.id;
        wo.Pricebook2Id= standardPricebook.id;
        //wo.ParentWorkOrderId = wop.Id;
        insert wo;
        
        
        
        
        WorkOrderLineItem testwoli =  SBR_3_0_ServiceTestDataFactory.createWoli(false,wo.id,testFactorySR.id);
        testwoli.Duration = 1;
        testwoli.SF_PS_RM_External_Id__c = '123456';
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
        ServiceTerritoryMember testSTM =SBR_3_0_ServiceTestDataFactory.createServiceTerritoryMember(true,testFactorySR.id,testST.id);
        
        SBR_3_0_CustomCreateWorkOrder co = new SBR_3_0_CustomCreateWorkOrder(jsonString);
        String returnVal = co.syncWorkOrderToSF();
        Test.stopTest();
        // }
    }
    
    
}