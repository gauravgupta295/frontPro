/*********************************************************************************************************************
* Apex Class: SBR_3_0_ServiceTestDataFactory
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Class to create test data for unit testing for Service team.
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION       DATE               DETAIL FEATURES
    1.0          2023-02-23          Initial version 
    2.0          2023-05-05          Mayank Jain
    3.0          2023-05-19          Mayank Jain  
	4.0			 2024-03-04			 Meghna Vijay - Tagged it as @isTest as this class creates test data for test classes
**********************************************************************************************************************************************/

public class SBR_3_0_ServiceTestDataFactory {
    private static Integer offset = 1;
    
    
        public static Id createServiceResource(){
            Integer randomNumber = Integer.valueof((Math.random() * 10));
            ServiceResource sr= new ServiceResource(Name='TEST RESOURCE'+randomNumber ,RelatedRecordId=UserInfo.getUserId(),IsActive=true);
            insert sr;
            
            return sr.Id;
        }

        public static User createServiceResourceUserWO(Boolean insertRecord, String WynneNo, string mecId){
            Profile p = [SELECT Id FROM Profile WHERE Name='Service'];
            String randomString = generateRandomString(5);
            String name = randomString;
            String osrUserOneName = 'SRTestUser2' + DateTime.now().getTime() + '@SBRtestorg.com';
            User oUser = new User(  Alias = name ,
                                    Email= name + '@sunbeltrentals.com',
                                    EmailEncodingKey = 'UTF-8', 
                                    LastName = name , 
                                    LanguageLocaleKey = 'en_US',
                                    LocaleSidKey = 'en_US', 
                                    ProfileId = p.Id,
                                    TimeZoneSidKey = 'America/Los_Angeles',
                                    SF_PS_Mechanic_Id__c = mecId,
                                    IsActive = true,
                                    City = '',
                                    Country = 'CA',
                                    countrycode = 'CA',
                                    PostalCode = 'V9B 3Y8',
                                    State = 'BC',
                                    stateCode = 'BC',
                                    Street = '2994 JACKLIN RD',
                                    Wynne_User_Name__c = WynneNo,
                                    UserName = osrUserOneName);
            if(insertRecord){
                INSERT oUser;
                PermissionSetGroup psg = [SELECT Id,Status 
                                        FROM PermissionSetGroup 
                                        WHERE DeveloperName = 'SFS_Admin' ];
                if (psg.Status != 'Updated') {
                    Test.calculatePermissionSetGroup(psg.Id);
                }
                if(!Test.isRunningTest()){
                    insert new PermissionSetAssignment(PermissionSetGroupId = psg.Id, AssigneeId = oUser.Id);
                }
                
                
            }
            return oUser;
        }
        public static User createServiceResourceUser(Boolean insertRecord, String WynneNo, string mecId){
            Profile p = [SELECT Id FROM Profile WHERE Name='Service'];
            String randomString = generateRandomString(5);
            String name = randomString;
            String osrUserOneName = 'SRTestUser1' + DateTime.now().getTime() + '@SBRtestorg.com';
            User oUser = new User(  Alias = name ,
                                    Email= name + '@sunbeltrentals.com',
                                    EmailEncodingKey = 'UTF-8', 
                                    LastName = name , 
                                    LanguageLocaleKey = 'en_US',
                                    LocaleSidKey = 'en_US', 
                                    ProfileId = p.Id,
                                    TimeZoneSidKey = 'America/Los_Angeles',
                                    SF_PS_Mechanic_Id__c = mecId,
                                    IsActive = true,
                                    City = '',
                                    Country = 'CA',
                                    countrycode = 'CA',
                                    PostalCode = 'V9B 3Y8',
                                    State = 'BC',
                                    stateCode = 'BC',
                                    Street = '2994 JACKLIN RD',
                                    Wynne_User_Name__c = WynneNo,
                                    UserName = osrUserOneName);
            if(insertRecord){
                INSERT oUser;
                PermissionSetGroup psg = [SELECT Id,Status 
                                        FROM PermissionSetGroup 
                                        WHERE DeveloperName = 'Dispatcher' ];
                if (psg.Status != 'Updated') {
                    Test.calculatePermissionSetGroup(psg.Id);
                }
                insert new PermissionSetAssignment(PermissionSetGroupId = psg.Id, AssigneeId = oUser.Id);
                
            }
            return oUser;
        }

        public static User createServiceResourceEmpNoUser(Boolean insertRecord, String WynneNo, string empNumber){
            Profile p = [SELECT Id FROM Profile WHERE Name='Service'];
            String randomString = generateRandomString(5);
            String name = randomString;
            String osrUserOneName = 'SRTestUser' + DateTime.now().getTime() + '@SBRtestorg.com';
            User oUser = new User(  Alias = name ,
                                    Email= name + '@sunbeltrentals.com',
                                    EmailEncodingKey = 'UTF-8', 
                                    LastName = name , 
                                    LanguageLocaleKey = 'en_US',
                                    LocaleSidKey = 'en_US', 
                                    ProfileId = p.Id,
                                    TimeZoneSidKey = 'America/Los_Angeles',
                                    EmployeeNumber = empNumber,
                                    IsActive = true,
                                    City = '',
                                    Country = 'CA',
                                    countrycode = 'CA',
                                    PostalCode = 'V9B 3Y8',
                                    State = 'BC',
                                    stateCode = 'BC',
                                    Street = '2994 JACKLIN RD',
                                    Wynne_User_Name__c = WynneNo,
                                    UserName = osrUserOneName);
            if(insertRecord){
                INSERT oUser;
                PermissionSetGroup psg = [SELECT Id,Status 
                                        FROM PermissionSetGroup 
                                        WHERE DeveloperName = 'Dispatcher' ];
                if (psg.Status != 'Updated') {
                    Test.calculatePermissionSetGroup(psg.Id);
                }
                insert new PermissionSetAssignment(PermissionSetGroupId = psg.Id, AssigneeId = oUser.Id);
            }
            return oUser;
        }
        
        public static User createServiceResourceUserEMPWO(Boolean insertRecord, String WynneNo, string empNumber){
            Profile p = [SELECT Id FROM Profile WHERE Name='Service'];
            String randomString = generateRandomString(5);
            String name = randomString;
            String osrUserOneName = 'SRTestUser2' + DateTime.now().getTime() + '@SBRtestorg.com';
            User oUser = new User(  Alias = name ,
                                    Email= name + '@sunbeltrentals.com',
                                    EmailEncodingKey = 'UTF-8', 
                                    LastName = name , 
                                    LanguageLocaleKey = 'en_US',
                                    LocaleSidKey = 'en_US', 
                                    ProfileId = p.Id,
                                    TimeZoneSidKey = 'America/Los_Angeles',
                                    EmployeeNumber = empNumber,
                                    IsActive = true,
                                    City = '',
                                    Country = 'CA',
                                    countrycode = 'CA',
                                    PostalCode = 'V9B 3Y8',
                                    State = 'BC',
                                    stateCode = 'BC',
                                    Street = '2994 JACKLIN RD',
                                    Wynne_User_Name__c = WynneNo,
                                    UserName = osrUserOneName);
            if(insertRecord){
                INSERT oUser;
                PermissionSetGroup psg = [SELECT Id,Status 
                                        FROM PermissionSetGroup 
                                        WHERE DeveloperName = 'SFS_Admin' ];
                if (psg.Status != 'Updated') {
                    Test.calculatePermissionSetGroup(psg.Id);
                }
                insert new PermissionSetAssignment(PermissionSetGroupId = psg.Id, AssigneeId = oUser.Id);
                
            }
            return oUser;
        }

        public static User createSystemAdminUser(Boolean insertRecord, String WynneNo, string mecId){
            Profile p = [SELECT Id FROM Profile WHERE Name='Service'];
            String randomString = generateRandomString(5);
            String name = randomString;
            String osrUserOneName = 'testAdminUser' + DateTime.now().getTime() + '@SBRtestorg.com';
            User oUser = new User(  Alias = name ,
                                    Email= name + '@sunbeltrentals.com',
                                    EmailEncodingKey = 'UTF-8', 
                                    LastName = name , 
                                    LanguageLocaleKey = 'en_US',
                                    LocaleSidKey = 'en_US', 
                                    ProfileId = p.Id,
                                    TimeZoneSidKey = 'America/Los_Angeles',
                                    SF_PS_Mechanic_Id__c = mecId,
                                    IsActive = true,
                                    City = '',
                                    Country = 'CA',
                                    countrycode = 'CA',
                                    PostalCode = 'V9B 3Y8',
                                    State = 'BC',
                                    stateCode = 'BC',
                                    Street = '2994 JACKLIN RD',
                                    Wynne_User_Name__c = WynneNo,
                                    UserName = osrUserOneName);
            if(insertRecord){
                INSERT oUser;
            }
            return oUser;
        }

        public static User createOwnerUser(Boolean insertRecord, String WynneNo, string mecId){
            Profile p = [SELECT Id FROM Profile WHERE Name='Service'];
            String randomString = generateRandomString(5);
            String name = randomString;
            String osrUserOneName = 'ownerTestUser' + DateTime.now().getTime() + '@SBRtestorg.com';
            User oUser = new User(  Alias = name ,
                                    Email= name + '@sunbeltrentals.com',
                                    EmailEncodingKey = 'UTF-8', 
                                    LastName = name , 
                                    LanguageLocaleKey = 'en_US',
                                    LocaleSidKey = 'en_US', 
                                    ProfileId = p.Id,
                                    TimeZoneSidKey = 'America/Los_Angeles',
                                    SF_PS_Mechanic_Id__c = mecId,
                                    IsActive = true,
                                    City = '',
                                    Country = 'CA',
                                    countrycode = 'CA',
                                    PostalCode = 'V9B 3Y8',
                                    State = 'BC',
                                    stateCode = 'BC',
                                    Street = '2994 JACKLIN RD',
                                    Wynne_User_Name__c = WynneNo,
                                    UserName = osrUserOneName);
            if(insertRecord){
                INSERT oUser;
                PermissionSetGroup psg = [SELECT Id,Status 
                                        FROM PermissionSetGroup 
                                        WHERE DeveloperName = 'Dispatcher' ];
                if (psg.Status != 'Updated') {
                    Test.calculatePermissionSetGroup(psg.Id);
                }
                insert new PermissionSetAssignment(PermissionSetGroupId = psg.Id, AssigneeId = oUser.Id);
            }
            return oUser;
        }



        public static ServiceResource create_Service_Resource(Boolean insertRecords){
            ServiceResource sr = new ServiceResource();
            sr.name = 'Test Resouce';
            sr.SF_PS_Company_Code__c = '01';
            sr.SF_PS_Hourly_Billing_Rate__c = 5.0;
            sr.SF_PS_Hourly_Internal_Rate__c = 5.0;
            sr.SF_PS_Overtime_Billing_Rate__c = 5.0;
            sr.SF_PS_Overtime_Internal_Rate__c = 5.0;
            sr.SF_PS_Labor_Type__c = 'I';
            sr.SF_PS_Type__c = 'D';
            sr.ResourceType = 'D';
            sr.IsActive = True;
            sr.SF_PS_Branch_Loc_Num__c = '1234';
            sr.SF_PS_Comments__c = 'Created By Test Factory';
            sr.SF_PS_RM_Created_DateTime__c = system.now().addHours(-1);
            sr.SF_PS_RM_Created_By__c = 'Test Factory';
            sr.SF_PS_RM_Update_DateTime__c = system.now().addMinutes(-10);
            sr.SF_PS_RM_Updated_By_User__c = 'API Call';
            sr.RelatedRecordId = UserInfo.getUserId();
            if(insertRecords){
                insert sr;
            }
            return sr;
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
        
        public static workOrder createWorkOrder(Boolean insertRecords){
            
            Workorder wo = new Workorder();
            wo.Status = 'Open';  
            //wo.OwnerId = '1234';  //ID
            wo.CurrencyIsoCode =    'USD';
            //wo.AssetId =  ''; //ID 
            //wo.SVMXA360_ContactPhone_c =    '7036004000';
            wo.SF_PS_Authorized_By__c =     'mayankTEST';
            wo.SF_PS_BillCustOrLoc__c =     'L';
            wo.SF_PS_PONumber__c =  '';
            wo.SF_PS_RM_WO_Number__c =  '01-33322';
            wo.SF_PS_Cause__c =     '';
            wo.SF_PS_Company_Code__c =  '01';
            wo.SF_PS_Complaint__c =     '';
            wo.SF_PS_Cure__c =  '';
            wo.SF_PS_ExpenseCode__c =   'RR';
            wo.SF_PS_LaborCode__c =     '9100';
            wo.SF_PS_Current_MiHr__c =  0.0;
            wo.SF_PS_Repair_Ticket__c = 0.0;
            wo.SF_PS_Work_Order_Des__c = 'CHECK IN RETURN';
            wo.SF_PS_Current_MiHr2__c =  0.0;
            wo.SF_PS_Service_Call__c =  'Y';
            wo.SF_PS_Warranty_Amt_Expected__c =     0.0;
            //wo.SF_PS_Expense_To_Location__c =   createServiceTerritory(true).Id; //ID
            //wo.SF_PS_Current_Loc__c =   '1234';         //ID
            wo.SF_PS_Claim_Type__c =    'N';
            wo.SF_PS_Actual_Claim_Amt__c =  0.0;
            wo.SF_PS_Claim_Paid_Date__c =   Date.newInstance(2016, 12, 9);
            wo.SF_PS_Claim_Num__c =     '';
            wo.SF_PS_Date_Claim_Filed__c =  Date.newInstance(2016, 12, 9);
            //wo.SF_PS_Sales_Rep__c =     '111222';       //ID
            wo.SF_PS_Funded__c =    'Y';
            wo.SF_PS_Closed_Date__c =   system.now().addDays(-1);
            wo.SF_PS_Date_Opened__c =   system.now().addDays(-1);
            wo.SF_PS_Charge_GSTTax__c = 'Y';
            wo.SF_PS_Charge_PSTTax__c = 'Y';
        // wo.AccountId =  '728589'; //ID
            wo.SF_PS_Drivers_License_Number__c =    '';
            //wo.SF_PS_Job_Site__c =  '';             //ID
            wo.SF_PS_Job_Location__c = '';             //ID
            wo.SF_PS_Due_Date__c =  system.now().addDays(-1);
            //wo.SF_PS_Service_Resource__c =  '1234';     //ID
            wo.SF_PS_Labor_Des_Comments__c =    '';
            wo.SF_PS_Labor_Des_Internal__c =    '';
            wo.SF_PS_RM_Last_Maint_By__c =  '';
            wo.SF_PS_RM_Last_Maint_DateTime__c =    system.now().addDays(-1);
            wo.SF_PS_Inv_Seq_Num__c =   1234;
            wo.SF_PS_License_State__c =     'OH';

            if(insertRecords){
                insert wo;
            }
            return wo;

        }

        public static WorkOrderLineItem createWorkOrderLineItem(Boolean insertRecords){
            WorkOrderLineItem woli = new WorkOrderLineItem();
            woli.Duration= 0;
            woli.SF_PS_Labor_Code__c='1000 - ENGINE';
            //woli.SF_PS_Mechanic_Name__c='78923';
            woli.SF_PS_Hourly_Internal_Rate__c= 0 ;
            woli.SF_PS_RM_Labor_Line_Item_Number__c='';
            woli.SF_PS_RM_External_Id__c='332212';
            woli.SF_PS_Line_Type__c='LI';
            woli.SF_PS_Mileage_Charge__c='Mileage Charge';
            woli.SF_PS_RM_Item_Number__c='87213';

            if (insertRecords){
                insert woli;
            }
            return woli;

        }

        public static ProductConsumed createProductConsumed(Boolean insertRecords){
            ProductConsumed pc = new ProductConsumed();
            pc.SF_PS_RM_External_Id__c='1231231';
            pc.SF_PS_Parts_Line_Num__c='';
            pc.SF_PS_Selling_Price__c=0;
            pc.SF_PS_Cost_Price__c=0;
            pc.SF_PS_Line_Type__c='WO';
            //pc.Product2Id='10870996';
            pc.SF_PS_Quantity__c=1;
            //pc.SF_PS_Unit_Of_Measure__c='EA';
            pc.SF_PS_Labor_Code__c='1000 - ENGINE';
            pc.SF_PS_Line_Level_Comment__c='string';
            pc.SF_PS_List_Price__c=0;

            if(insertRecords){
                insert pc;
            }
            return pc;
        }
        public static Asset createAsset (Boolean insertRecords){
            Asset asrt = new Asset();
            asrt.Name = 'testAsrt';
            asrt.SM_PS_Company_Code__c = '01';
            asrt.SM_PS_Equipment_Number__c = '1018879';
            asrt.SM_PS_Asset_Id__c = '01-1018879';
            asrt.RecordTypeId = Schema.SObjectType.Asset.getRecordTypeInfosByName().get('Customer-Owned Asset').getRecordTypeId();
            if(insertRecords){
                insert asrt;
            }
            return asrt;
        }

        public static Account createAccount(Boolean insertRecords, string accountNo){
            Id devRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Credit').getRecordTypeId();
            Account a = new Account();
            A.Name = 'TestName'+ DateTime.now().getTime() + generateRandomString(5); 
            a.Company_Name__c = 'Test' + DateTime.now().getTime() + generateRandomString(5);
            a.Status__c = SBR_3_0_Constants.ACCOUNT_STATUS_ACTIVE;
            a.Phone = '9999999999';         // Updated for Bug SAL-8356 
            a.BillingStreet = 'Test Street';
            a.BillingCity = 'Manassas';
            a.BillingState = 'IN';
            a.BillingPostalCode = '20111';
            a.BillingCountry = 'US';
            a.ShippingStreet = 'Test Street';
            a.ShippingCity = 'Manassas';
            a.ShippingState = 'IN';
            a.ShippingPostalCode = '20111';
            a.ShippingCountry = 'US';
            a.RecordTypeId  = devRecordTypeId;
            //a.RecordTypeId = '0128G000000GzdGQAS';
            a.Company_Code__c = '01';
            a.RM_Account_Number__c = accountNo;
            if(insertRecords == true) {
                insert a;
                system.debug('thisis in Test Calss account' + a);
            }
            return a;
        }

        public static ServiceTerritory createServiceTerritory (Boolean insertRecords){

            OperatingHours oh = new OperatingHours(Name='TEST_Hours',TimeZone='America/Halifax');
            insert oh;
            string name  = generateRandomString(5) + DateTime.now().getTime();
            ServiceTerritory st= new ServiceTerritory(Name=name,OperatingHoursId=oh.Id,IsActive=true,Branch_Location_Number__c = '1234',CountryCode = 'US');
            if(insertRecords){
            insert st;
            }
            return st;
        }

        public static User createSalesRepUser(Boolean insertRecord, String Sales_Rep){
            Profile p = [SELECT Id FROM Profile WHERE Name='Service'];
            String randomString = generateRandomString(5);
            String name = randomString;
            String osrUserOneName = 'SalesRepUser' + DateTime.now().getTime() + '@SBRtestorg.com';
            User oUser = new User(  Alias = name ,
                                    Email= name + '@sunbeltrentals.com',
                                    EmailEncodingKey = 'UTF-8', 
                                    LastName = name , 
                                    LanguageLocaleKey = 'en_US',
                                    LocaleSidKey = 'en_US', 
                                    ProfileId = p.Id,
                                    TimeZoneSidKey = 'America/Los_Angeles',
                                    SF_PS_Mechanic_Id__c = '8888',
                                    IsActive = true,
                                    City = '',
                                    Country = 'CA',
                                    countrycode = 'CA',
                                    PostalCode = 'V9B 3Y8',
                                    State = 'BC',
                                    stateCode = 'BC',
                                    Street = '2994 JACKLIN RD',
                                    RepID__c = Sales_Rep,
                                    UserName = osrUserOneName);
            if(insertRecord){
                INSERT oUser;
            }
            return oUser;
        }

        public static AssociatedLocation createAssLOC(Boolean insertRecord , string JobNo  ){
            Schema.Location loc = new Schema.Location(Name = 'TestLoc', Company_Code__c = '01', Branch_Location_Number__c = '1234');
            insert loc;

            system.debug('is Loc is Created ?? '+ loc);

            Schema.Location branchLocation = new Schema.Location();
            branchLocation.Branch_Location_Number__c = '1234';
            branchLocation.Name = 'Test Branch Location';
            branchLocation.Street_Address__c = '12 Main Street';
            branchLocation.City__c = 'Toronto';
            branchLocation.Zip_Code__c = 'M7N7B3';
            branchLocation.State__c = 'ON';
            branchLocation.Country__c = 'CA';
            branchLocation.Job_Number__c='332112';
            branchLocation.RecordTypeId = SBR_3_0_Constants.LOCATION_BRANCH_RT_ID;
            branchLocation.Company_Code__c = '01';
            insert branchLocation;

            system.debug('is branchLocation Created' + branchLocation);


            AssociatedLocation assLoc = new AssociatedLocation(Job_Number__c  = JobNo,
            Name__c = 'Test Job Site',
            ParentRecordId = createAccount(true,'5555').Id,
            Branch__c = branchLocation.Id,
            Job_Site_Id__c = 'SF20221107A',
            Street_Address__c = '12 Main Street',
            City__c = 'Toronto',
            State__c = 'ON',
            Zip_Code__c = 'M9N7V3',
            LocationId = loc.Id );
            if(insertRecord){
                insert assLoc;
            }
            return assLoc;
        }
        
        public static WorkOrderLineItem createWoli(Boolean insertRecord ,id woId, id mecid){
            WorkOrderLineItem woli = new WorkOrderLineItem();
            woli.WorkOrderId = woId;
            woli.Duration = 1;
            woli.SF_PS_Mechanic_Name__c = mecid;
            woli.SF_PS_RM_External_Id__c = '3322123';
            woli.SF_PS_Hourly_Internal_Rate__c = 5;
            if (insertRecord) {
                insert woli;
            }
            return woli;
        }

        
        public static Quote_Line_Item__c createqli(Boolean insertRecord ,id woId, id mecid){
            Quote_Line_Item__c qli = new Quote_Line_Item__c();
            qli.WorkOrderId__c = woId;
            qli.SF_PS_Duration__c = 1;
            qli.SF_PS_Mechanic_Name__c = mecid;
            qli.SF_PS_RM_External_Id__c = '3322123';
            if (insertRecord) {
                insert qli;
            }
            return qli;
        }

        public static SF_PS_Maintenance_Steps__c createMaintenanceSteps(Boolean insertRecord, Id woId, Id mechId ){
            SF_PS_Maintenance_Steps__c ms = new SF_PS_Maintenance_Steps__c();
            ms.SF_PS_Work_Order__c = woId;
            ms.SF_PS_RM_External_Id__c = '9812390812';
            ms.SF_PS_RM_Mtce_Mechanic_Name__c = mechId;
            ms.SF_PS_RM_Mtce_Steps_StepNumber__c = '1';
            if (insertRecord) {
                insert ms;
            }
            return ms;

        }

        public static DueForService__c createDueForServiceRecord(Boolean insertRecord, Id assetNumber, String companyCode){
            DueForService__c ds = new DueForService__c();
            ds.SM_PS_External_ID__c = '123234688731';
            ds.SM_PS_Step_Number__c = '1';
            ds.SM_PS_Equipment_Number__c = assetNumber;
            ds.SM_PS_Company_Code__c = companyCode;
            if (insertRecord){
                insert ds;
            }
            return ds;
        }

        public static ProductConsumed createProductConsumedRecord (Boolean insertRecord ,id woId, String extNo){
            
            Schema.Location loc = new Schema.Location(Name = 'TestLoc', Company_Code__c = '01', Branch_Location_Number__c = '1234', IsInventoryLocation = true );
            insert loc;
            
            Product2 pd = new Product2(name='TestProduct', Product_SKU__c='10870996');
            insert pd;

            ProductItem pi = new ProductItem();
            pi.Product2Id = pd.Id;
            pi.QuantityOnHand = 1;
            pi.LocationId = loc.Id;
            //Added as part of deployment fix
            pi.SM_PS_ProductItem_Id__c = generateRandomString(10);
            insert pi;
            

            ProductConsumed pc = new ProductConsumed();
            pc.WorkOrderId = woId;
            pc.SF_PS_RM_External_Id__c = extNo;
            pc.ProductItemId = pi.Id;
            pc.QuantityConsumed = 1;
            if(insertRecord){
                insert pc;
            }
            return pc;
        }

        public static ProductConsumed createProductConsumedRecordFail (Boolean insertRecord ,id woId, String extNo){
            
            Schema.Location loc = new Schema.Location(Name = 'TestLoc', Company_Code__c = '01', Branch_Location_Number__c = '1234', IsInventoryLocation = true );
            insert loc;
            
            Product2 pd = new Product2(name='TestProduct');
            insert pd;

            ProductItem pi = new ProductItem();
            pi.Product2Id = pd.Id;
            pi.QuantityOnHand = 1;
            pi.LocationId = loc.Id;
            //Added as part of deployment fix
            pi.SM_PS_ProductItem_Id__c = generateRandomString(10);
            insert pi;
            

            ProductConsumed pc = new ProductConsumed();
            pc.WorkOrderId = woId;
            pc.SF_PS_RM_External_Id__c = extNo;
            pc.ProductItemId = pi.Id;
            pc.QuantityConsumed = 1;
            if(insertRecord){
                insert pc;
            }
            return pc;
        }
        public static ServiceAppointment createServiceAppointment (Boolean insertRecord, id wo){

            ServiceAppointment sa = new ServiceAppointment(
                ParentRecordId=wo,
                EarliestStartTime = system.now(),
                DueDate = system.now()+5,
                SchedStartTime=System.Now(),
                SchedEndTime=(System.Now()+2),
                //Status='Open', 
                Duration = 15,
                DurationType = 'Minutes');    
            if(insertRecord){
                insert sa;
            }
            return sa;
        }

        public static ServiceTerritoryMember createServiceTerritoryMember (Boolean insertRecord,id sr, id st){

            ServiceTerritoryMember stm = new ServiceTerritoryMember();

            
            stm.ServiceResourceId =sr;
            stm.ServiceTerritoryId = st;
            stm.TerritoryType = 'P';
            stm.EffectiveStartDate = system.now();
            if(insertRecord){
                insert stm;
            }
            return stm;

        }

        public static WorkStepTemplate createWorkStepTemplate(Boolean insertRecord) {
            WorkStepTemplate template = new WorkStepTemplate(
                    Name = 'TEST WORK STEP TEMPLATE ' + offset++
            );
            if(insertRecord) {
                insert template;
            }
            return template;
        }

        public static Inspection_Template__c createInspectionTemplate(Boolean insertRecord) {
            Inspection_Template__c inspectionTemplate = new Inspection_Template__c();
            if(insertRecord) {
                insert inspectionTemplate;
            }
            return inspectionTemplate;
        }

        /************************
        @method :  Create Damage Estimator
        @description : Test data to create damage estimator
        @param : String woId, Boolean isInsert
        @return : SF_PS_Damage_Estimator__c
        *************************/
        public static SF_PS_Damage_Estimator__c createDamageEstimatorRecord(String woId, Boolean isInsert) {
            SF_PS_Damage_Estimator__c damageEstimatorRec = new SF_PS_Damage_Estimator__c();
            damageEstimatorRec.SF_PS_Work_Order_Number__c = woId;
            if(isInsert) {
                insert damageEstimatorRec;
            }
            return damageEstimatorRec;
        }

        public static SM_PS_Equipment_Contract_History__c createEquipmentContractHistory(Id orderId, Boolean isInsert) {
            SM_PS_Equipment_Contract_History__c equipConHistoryRec = new SM_PS_Equipment_Contract_History__c();
            equipConHistoryRec.SM_PS_Contract_Order__c = orderId;
            if(isInsert) {
                insert equipConHistoryRec;
            }
            return equipConHistoryRec;
        }

        public static Order createOrder(Id accountId, Boolean isInsert) {
            Order orderRec = new Order(AccountId = accountId);
            if(isInsert) {
                insert orderRec;
            }
            return orderRec;
        }

}