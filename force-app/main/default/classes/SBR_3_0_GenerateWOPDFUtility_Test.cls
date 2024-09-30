@isTest
public class SBR_3_0_GenerateWOPDFUtility_Test {

    @TestSetup
    static void makeData(){
        User testOwnerUser = SBR_3_0_ServiceTestDataFactory.createOwnerUser(true, '1234','7777');
    }

    @isTest
    public static void getWorkOrderTest(){
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_GenerateWOPDFController_Mock());
        
        Credential__c cred = SBR_3_0_TestDataFactory.createCredentials(1, false)[0];
        cred.Name      = 'Mule_Token_Endpoint';
        cred.Key_Id__c = 'testKey123';
        cred.Secret__c = 'secret';
        insert cred;

        // Create Account
        Account acct =  SBR_3_0_ServiceTestDataFactory.createAccount(false,'33333');
        acct.E_mail_Address__c = '123@asdf.com';
        acct.Company_Code__c   = '01';
        insert acct;

        // Create Location
        Schema.Location jobLocation = new Schema.Location();
        jobLocation.Name                    = 'Test Job Location';
        jobLocation.Street_Address__c       = '12 Main Street';
        jobLocation.City__c                 = 'Toronto';
        jobLocation.Zip_Code__c             = 'M7N7B3';
        jobLocation.State__c                = 'ON';
        jobLocation.Country__c              = 'CA';
        jobLocation.RecordTypeId            = SBR_3_0_Constants.LOCATION_JOB_RT_ID;
        jobLocation.OMS_Sourcing_Enabled__c = true;
        jobLocation.Distance_Multiplier__c  = 50;
        jobLocation.Analysis_Region_Key__c  = '928';
        jobLocation.Company_Code__c         = '01';
        insert jobLocation;

        // Create Branch
        Schema.Location branchLocation = new Schema.Location();
        branchLocation.Branch_Location_Number__c = '720';
        branchLocation.Name                      = 'Test Branch Location';
        branchLocation.Street_Address__c         = '12 Main Street';
        branchLocation.City__c                   = 'Toronto';
        branchLocation.Zip_Code__c               = 'M7N7B3';
        branchLocation.State__c                  = 'ON';
        branchLocation.Country__c                = 'CA';
        branchLocation.Job_Number__c             ='332112';
        branchLocation.RecordTypeId              = SBR_3_0_Constants.LOCATION_BRANCH_RT_ID;
        branchLocation.Company_Code__c           = 'X';
        branchLocation.Time_Zone_Name__c         = 'America/Chicago';
        branchLocation.Time_Zone__c              = 3;
        branchLocation.Analysis_Region_Key__c    = '928';
        insert branchLocation;

        // Create Job Site
        AssociatedLocation jobSite = new AssociatedLocation(
            Name__c        = 'Test Job Site',
            ParentRecordId = acct.Id,
            LocationId     = jobLocation.Id,
            Branch__c      = branchLocation.Id,
            Job_Number__c  = '20221004A'
        );
        insert jobSite;

        // Create Asset
        Asset testAsset = SBR_3_0_ServiceTestDataFactory.createAsset(true);
            
        //Create Exponce to Location
        ServiceTerritory testE2Loc = SBR_3_0_ServiceTestDataFactory.createServiceTerritory(true);
        
        //Create Service Territory 
        OperatingHours oh = new OperatingHours(
            Name     = 'TEST_Hours1',
            TimeZone = 'America/Halifax'
        );
        insert oh;

        ServiceTerritory testST = new ServiceTerritory(
            Name                      = 'TestHr',
            OperatingHoursId          = oh.Id,
            IsActive                  = true,
            Branch_Location_Number__c = '1234',
            CountryCode               = 'US'
        );
        insert testST;

        User testSalesRep  = SBR_3_0_ServiceTestDataFactory.createSalesRepUser(true,'111222');
        
        WorkOrder wo1 = SBR_3_0_ServiceTestDataFactory.createWorkOrder(false);
        wo1.RecordTypeId                 = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get(SBR_3_0_GenerateWOPDFUtility.WORKORDER_RECORDTYPE_INSPECTION).getRecordTypeId();
        wo1.SF_PS_RM_WO_Number__c        = '01-333221';
        wo1.SF_PS_Expense_To_Location__c = testST.id;
        wo1.AssetId                      = testAsset.id;
        wo1.ServiceTerritoryId           = testE2Loc.id;
        wo1.SF_PS_BillCustOrLoc__c       = '$';
        wo1.SF_PS_Sales_Rep__c           = testSalesRep.Id;
        wo1.SF_PS_Job_Site__c            = jobSite.Id;
        wo1.AccountId                    = acct.Id;
        wo1.SF_PS_Invoice_Date__c        = Date.today();

        WorkOrder wo2 = SBR_3_0_ServiceTestDataFactory.createWorkOrder(false);
        wo2.RecordTypeId                 = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get(SBR_3_0_GenerateWOPDFUtility.WORKORDER_RECORDTYPE_CREDIT).getRecordTypeId();
        wo2.SF_PS_RM_WO_Number__c        = '01-333222';
        wo2.SF_PS_Expense_To_Location__c = testST.id;
        wo2.AssetId                      = testAsset.id;
        wo2.ServiceTerritoryId           = testE2Loc.id;
        wo2.SF_PS_BillCustOrLoc__c       = '$';
        wo2.SF_PS_Sales_Rep__c           = testSalesRep.Id;
        wo2.SF_PS_Job_Site__c            = jobSite.Id;
        wo2.AccountId                    = acct.Id;

        WorkOrder wo3 = SBR_3_0_ServiceTestDataFactory.createWorkOrder(false);
        wo3.RecordTypeId                 = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get(SBR_3_0_GenerateWOPDFUtility.WORKORDER_RECORDTYPE_QUOTE).getRecordTypeId();
        wo3.SF_PS_RM_WO_Number__c        = '01-333223';
        wo3.SF_PS_Expense_To_Location__c = testST.id;
        wo3.AssetId                      = testAsset.id;
        wo3.ServiceTerritoryId           = testE2Loc.id;
        wo3.SF_PS_BillCustOrLoc__c       = 'C';
        wo3.SF_PS_Sales_Rep__c           = testSalesRep.Id;
        wo3.SF_PS_Job_Site__c            = jobSite.Id;
        wo3.AccountId                    = acct.Id;
        insert new List<WorkOrder>{wo1, wo2, wo3};

        Test.startTest();
            // Invoice WO
            WorkOrder wo = [SELECT Id FROM WorkOrder WHERE SF_PS_RM_WO_Number__c = '01-333221' LIMIT 1];
            WorkOrder invoiceWO = SBR_3_0_GenerateWOPDFUtility.getWorkOrder(wo.Id);
            Assert.areEqual(SBR_3_0_GenerateWOPDFUtility.WORKORDER_RECORDTYPE_INSPECTION, invoiceWO.RecordType.DeveloperName);

            // Credit WO
            wo = [SELECT Id FROM WorkOrder WHERE SF_PS_RM_WO_Number__c = '01-333222' LIMIT 1];
            WorkOrder creditWO = SBR_3_0_GenerateWOPDFUtility.getWorkOrder(wo.Id);
            Assert.areEqual(SBR_3_0_GenerateWOPDFUtility.WORKORDER_RECORDTYPE_CREDIT, creditWO.RecordType.DeveloperName);

            // Quote WO
            wo = [SELECT Id FROM WorkOrder WHERE SF_PS_RM_WO_Number__c = '01-333223' LIMIT 1];
            WorkOrder quoteWO = SBR_3_0_GenerateWOPDFUtility.getWorkOrder(wo.Id);
            Assert.areEqual(SBR_3_0_GenerateWOPDFUtility.WORKORDER_RECORDTYPE_QUOTE, quoteWO.RecordType.DeveloperName);
        Test.stopTest();
    }

    @isTest
    public static void getWorkOrderMapTest(){
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_GenerateWOPDFController_Mock());

        Credential__c cred = SBR_3_0_TestDataFactory.createCredentials(1, false)[0];
        cred.Name      = 'Mule_Token_Endpoint';
        cred.Key_Id__c = 'testKey123';
        cred.Secret__c = 'secret';
        insert cred;

        // Create Account
        Account acct =  SBR_3_0_ServiceTestDataFactory.createAccount(false,'33333');
        acct.E_mail_Address__c = '123@asdf.com';
        acct.Company_Code__c   = '01';
        insert acct;

        // Create Location
        Schema.Location jobLocation = new Schema.Location();
        jobLocation.Name                    = 'Test Job Location';
        jobLocation.Street_Address__c       = '12 Main Street';
        jobLocation.City__c                 = 'Toronto';
        jobLocation.Zip_Code__c             = 'M7N7B3';
        jobLocation.State__c                = 'ON';
        jobLocation.Country__c              = 'CA';
        jobLocation.RecordTypeId            = SBR_3_0_Constants.LOCATION_JOB_RT_ID;
        jobLocation.OMS_Sourcing_Enabled__c = true;
        jobLocation.Distance_Multiplier__c  = 50;
        jobLocation.Analysis_Region_Key__c  = '928';
        jobLocation.Company_Code__c         = '01';
        insert jobLocation;

        // Create Branch
        Schema.Location branchLocation = new Schema.Location();
        branchLocation.Branch_Location_Number__c = '720';
        branchLocation.Name                      = 'Test Branch Location';
        branchLocation.Street_Address__c         = '12 Main Street';
        branchLocation.City__c                   = 'Toronto';
        branchLocation.Zip_Code__c               = 'M7N7B3';
        branchLocation.State__c                  = 'ON';
        branchLocation.Country__c                = 'CA';
        branchLocation.Job_Number__c             ='332112';
        branchLocation.RecordTypeId              = SBR_3_0_Constants.LOCATION_BRANCH_RT_ID;
        branchLocation.Company_Code__c           = 'X';
        branchLocation.Time_Zone_Name__c         = 'America/Chicago';
        branchLocation.Time_Zone__c              = 3;
        branchLocation.Analysis_Region_Key__c    = '928';
        insert branchLocation;

        // Create Job Site
        AssociatedLocation jobSite = new AssociatedLocation(
            Name__c        = 'Test Job Site',
            ParentRecordId = acct.Id,
            LocationId     = jobLocation.Id,
            Branch__c      = branchLocation.Id,
            Job_Number__c  = '20221004A'
        );
        insert jobSite;

        // Create Asset
        Asset testAsset = SBR_3_0_ServiceTestDataFactory.createAsset(true);
            
        //Create Exponce to Location
        ServiceTerritory testE2Loc = SBR_3_0_ServiceTestDataFactory.createServiceTerritory(true);
        
        //Create Service Territory 
        OperatingHours oh = new OperatingHours(
            Name     = 'TEST_Hours1',
            TimeZone = 'America/Halifax'
        );
        insert oh;

        ServiceTerritory testST = new ServiceTerritory(
            Name                      = 'TestHr',
            OperatingHoursId          = oh.Id,
            IsActive                  = true,
            Branch_Location_Number__c = '1234',
            CountryCode               = 'US'
        );
        insert testST;

        User testSalesRep  = SBR_3_0_ServiceTestDataFactory.createSalesRepUser(true,'111222');
        
        WorkOrder wo1 = SBR_3_0_ServiceTestDataFactory.createWorkOrder(false);
        wo1.RecordTypeId                 = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get(SBR_3_0_GenerateWOPDFUtility.WORKORDER_RECORDTYPE_INSPECTION).getRecordTypeId();
        wo1.SF_PS_RM_WO_Number__c        = '01-333221';
        wo1.SF_PS_Expense_To_Location__c = testST.id;
        wo1.AssetId                      = testAsset.id;
        wo1.ServiceTerritoryId           = testE2Loc.id;
        wo1.SF_PS_BillCustOrLoc__c       = '$';
        wo1.SF_PS_Sales_Rep__c           = testSalesRep.Id;
        wo1.SF_PS_Job_Site__c            = jobSite.Id;
        wo1.AccountId                    = acct.Id;
        wo1.SF_PS_Invoice_Date__c        = Date.today();

        WorkOrder wo2 = SBR_3_0_ServiceTestDataFactory.createWorkOrder(false);
        wo2.RecordTypeId                 = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get(SBR_3_0_GenerateWOPDFUtility.WORKORDER_RECORDTYPE_CREDIT).getRecordTypeId();
        wo2.SF_PS_RM_WO_Number__c        = '01-333222';
        wo2.SF_PS_Expense_To_Location__c = testST.id;
        wo2.AssetId                      = testAsset.id;
        wo2.ServiceTerritoryId           = testE2Loc.id;
        wo2.SF_PS_BillCustOrLoc__c       = '$';
        wo2.SF_PS_Sales_Rep__c           = testSalesRep.Id;
        wo2.SF_PS_Job_Site__c            = jobSite.Id;
        wo2.AccountId                    = acct.Id;

        //Get Owner User 
        User testOwnerUser = [SELECT Id, Name FROM User WHERE UserName LIKE 'ownerTestUser%' LIMIT 1];
        WorkOrder wo3 = SBR_3_0_ServiceTestDataFactory.createWorkOrder(false);
        wo3.RecordTypeId                 = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get(SBR_3_0_GenerateWOPDFUtility.WORKORDER_RECORDTYPE_QUOTE).getRecordTypeId();
        wo3.SF_PS_RM_WO_Number__c        = '01-333223';
        wo3.SF_PS_Expense_To_Location__c = testST.id;
        wo3.AssetId                      = testAsset.id;
        wo3.ServiceTerritoryId           = testE2Loc.id;
        wo3.SF_PS_BillCustOrLoc__c       = 'C';
        wo3.SF_PS_Sales_Rep__c           = testSalesRep.Id;
        wo3.SF_PS_Job_Site__c            = jobSite.Id;
        wo3.AccountId                    = acct.Id;
        wo3.OwnerId                      = testOwnerUser.id;
        insert new List<WorkOrder>{wo1, wo2, wo3};

        WorkPlan wp = new WorkPlan(
            SF_PS_Company_Code__c = '01',
            Description           = 'Test Description',
            ExecutionOrder        = 1,
            Name                  = 'Test',
            ParentRecordId        = wo1.Id,
            WorkOrderId           = wo1.Id
        );
        insert wp;

        WorkStep ws = new WorkStep(
            Name                 = 'Test Step',
            WorkPlanId           = wp.Id,
            SM_PS_Step_Number__c = '1',
            SM_PS_Search_Word__c = 'test' 
        );
        insert ws;

        ServiceResource testSR = SBR_3_0_ServiceTestDataFactory.create_Service_Resource(False);
        testSR.ResourceType = 'T';
        testSR.RelatedRecordId = UserInfo.getUserId();
        insert testSR;

        Quote_Line_Item__c qli = new Quote_Line_Item__c();
        qli.WorkOrderId__c                = wo3.Id;
        qli.SF_PS_Duration__c             = 2;
        qli.SF_PS_Labor_Code__c           = '9000';
        qli.SF_PS_Hourly_Internal_Rate__c = 20;
        qli.SF_PS_Extended_Amt__c         = 20;
        qli.SF_PS_Line_Type__c            = 'LI';
        qli.SF_PS_Mechanic_Name__c        = testSR.Id;
        insert qli;

        Test.startTest();
            // Invoice WO
            WorkOrder wo = [SELECT Id FROM WorkOrder WHERE SF_PS_RM_WO_Number__c = '01-333221' LIMIT 1];
            WorkOrder invoiceWO = SBR_3_0_GenerateWOPDFUtility.getWorkOrder(wo.Id);
            Map<String, Object> invoiceWOMap = SBR_3_0_GenerateWOPDFUtility.getWorkOrderMap(invoiceWO);
            Assert.isNotNull(invoiceWOMap);

            // Credit WO
            wo = [SELECT Id FROM WorkOrder WHERE SF_PS_RM_WO_Number__c = '01-333222' LIMIT 1];
            WorkOrder creditWO = SBR_3_0_GenerateWOPDFUtility.getWorkOrder(wo.Id);
            Map<String, Object> creditWOMap = SBR_3_0_GenerateWOPDFUtility.getWorkOrderMap(creditWO);
            Assert.isNotNull(creditWOMap);

            // Quote WO
            wo = [SELECT Id FROM WorkOrder WHERE SF_PS_RM_WO_Number__c = '01-333223' LIMIT 1];
            WorkOrder quoteWO = SBR_3_0_GenerateWOPDFUtility.getWorkOrder(wo.Id);
            Map<String, Object> quoteWOMap = SBR_3_0_GenerateWOPDFUtility.getWorkOrderMap(quoteWO);
            Assert.isNotNull(quoteWOMap);
        Test.stopTest();
    }
    
    @isTest
    public static void getInspectionWOMapTest(){
        Map<String, Object> testMap = new Map<String, Object>{
            'WorkOrderLineItems' => new Map<String, Object>{
                'done'      => true,
                'totalSize' => 1,
                'records'   => new List<Object>{
                    new Map<String, Object>{
                        'attributes'                    => 'someValue',
                        'SF_PS_Extended_Rate__c'        => 10,
                        'SF_PS_Hourly_Internal_Rate__c' => 10
                    }
                }
            },
            'ProductsConsumed' => new Map<String, Object>{
                'done'      => true,
                'totalSize' => 1,
                'records'   => new List<Object>{
                    new Map<String, Object>{
                        'attributes'             => 'someValue',
                        'SF_PS_Selling_Price__c' => 10,
                        'SF_PS_Sub_Total__c'     => 10,
                        'SF_PS_Product_Item__r'  => new Map<String, Object>{'attributes' => 'someValue'},
                        'SF_PS_ItemType__c'      => 'M'
                    },
                    new Map<String, Object>{
                        'attributes'             => 'someValue',
                        'SF_PS_Selling_Price__c' => 10,
                        'SF_PS_Sub_Total__c'     => 10,
                        'SF_PS_Product_Item__r'  => new Map<String, Object>{'attributes' => 'someValue'},
                        'SF_PS_ItemType__c'      => 'P'
                    },
                    new Map<String, Object>{
                        'attributes'             => 'someValue',
                        'SF_PS_Selling_Price__c' => 10,
                        'SF_PS_Sub_Total__c'     => 10,
                        'SF_PS_Product_Item__r'  => new Map<String, Object>{'attributes' => 'someValue'},
                        'SF_PS_ItemType__c'      => 'MI'
                    }
                }
            }
        };
        Test.startTest();
            SBR_3_0_GenerateWOPDFUtility.getInspectionWOMap(testMap);
            Assert.areEqual(false, ((Map<String, Object>)testMap.get('WorkOrderLineItems')).containsKey('done'), 'done attribute removed from map');
        Test.stopTest();
    }

    @isTest
    public static void getCreditWOMapTest(){
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_GenerateWOPDFController_Mock());
        
        Credential__c cred = SBR_3_0_TestDataFactory.createCredentials(1, false)[0];
        cred.Name      = 'Mule_Token_Endpoint';
        cred.Key_Id__c = 'testKey123';
        cred.Secret__c = 'secret';
        insert cred;

        // Create Account
        Account acct =  SBR_3_0_ServiceTestDataFactory.createAccount(false,'33333');
        acct.E_mail_Address__c = '123@asdf.com';
        acct.Company_Code__c   = '01';
        insert acct;

        // Create Location
        Schema.Location jobLocation = new Schema.Location();
        jobLocation.Name                    = 'Test Job Location';
        jobLocation.Street_Address__c       = '12 Main Street';
        jobLocation.City__c                 = 'Toronto';
        jobLocation.Zip_Code__c             = 'M7N7B3';
        jobLocation.State__c                = 'ON';
        jobLocation.Country__c              = 'CA';
        jobLocation.RecordTypeId            = SBR_3_0_Constants.LOCATION_JOB_RT_ID;
        jobLocation.OMS_Sourcing_Enabled__c = true;
        jobLocation.Distance_Multiplier__c  = 50;
        jobLocation.Analysis_Region_Key__c  = '928';
        jobLocation.Company_Code__c         = '01';
        insert jobLocation;

        // Create Branch
        Schema.Location branchLocation = new Schema.Location();
        branchLocation.Branch_Location_Number__c = '720';
        branchLocation.Name                      = 'Test Branch Location';
        branchLocation.Street_Address__c         = '12 Main Street';
        branchLocation.City__c                   = 'Toronto';
        branchLocation.Zip_Code__c               = 'M7N7B3';
        branchLocation.State__c                  = 'ON';
        branchLocation.Country__c                = 'CA';
        branchLocation.Job_Number__c             ='332112';
        branchLocation.RecordTypeId              = SBR_3_0_Constants.LOCATION_BRANCH_RT_ID;
        branchLocation.Company_Code__c           = 'X';
        branchLocation.Time_Zone_Name__c         = 'America/Chicago';
        branchLocation.Time_Zone__c              = 3;
        branchLocation.Analysis_Region_Key__c    = '928';
        insert branchLocation;

        // Create Job Site
        AssociatedLocation jobSite = new AssociatedLocation(
            Name__c        = 'Test Job Site',
            ParentRecordId = acct.Id,
            LocationId     = jobLocation.Id,
            Branch__c      = branchLocation.Id,
            Job_Number__c  = '20221004A'
        );
        insert jobSite;

        // Create Asset
        Asset testAsset = SBR_3_0_ServiceTestDataFactory.createAsset(true);
            
        //Create Exponce to Location
        ServiceTerritory testE2Loc = SBR_3_0_ServiceTestDataFactory.createServiceTerritory(true);
        
        //Create Service Territory 
        OperatingHours oh = new OperatingHours(
            Name     = 'TEST_Hours1',
            TimeZone = 'America/Halifax'
        );
        insert oh;

        ServiceTerritory testST = new ServiceTerritory(
            Name                      = 'TestHr',
            OperatingHoursId          = oh.Id,
            IsActive                  = true,
            Branch_Location_Number__c = '1234',
            CountryCode               = 'US'
        );
        insert testST;

        User testSalesRep  = SBR_3_0_ServiceTestDataFactory.createSalesRepUser(true,'111222');
        
        WorkOrder wo1 = SBR_3_0_ServiceTestDataFactory.createWorkOrder(false);
        wo1.RecordTypeId                 = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get(SBR_3_0_GenerateWOPDFUtility.WORKORDER_RECORDTYPE_INSPECTION).getRecordTypeId();
        wo1.SF_PS_RM_WO_Number__c        = '01-333221';
        wo1.SF_PS_Expense_To_Location__c = testST.id;
        wo1.AssetId                      = testAsset.id;
        wo1.ServiceTerritoryId           = testE2Loc.id;
        wo1.SF_PS_BillCustOrLoc__c       = '$';
        wo1.SF_PS_Sales_Rep__c           = testSalesRep.Id;
        wo1.SF_PS_Job_Site__c            = jobSite.Id;
        wo1.AccountId                    = acct.Id;
        wo1.SF_PS_Invoice_Date__c        = Date.today();
        insert wo1;

        WorkPlan wp = new WorkPlan(
            SF_PS_Company_Code__c = '01',
            Description           = 'Test Description',
            ExecutionOrder        = 1,
            Name                  = 'Test',
            ParentRecordId        = wo1.Id,
            WorkOrderId           = wo1.Id
        );
        insert wp;

        Map<String, Object> testMap = new Map<String, Object>{
            'ParentWorkOrderId'    => wo1.Id,
            'Credit_Line_Items__r' => new Map<String, Object>{
                'done'      => true,
                'totalSize' => 1,
                'records'   => new List<Object>{
                    new Map<String, Object>{
                        'attributes'                 => 'someValue',
                        'SF_PS_Credit_Rate_Hr_Mi__c' => 10,
                        'SF_PS_Extended_Amt__c'      => 10
                    }
                }
            },
            'Credited_Parts__r' => new Map<String, Object>{
                'done'      => true,
                'totalSize' => 1,
                'records'   => new List<Object>{
                    new Map<String, Object>{
                        'attributes'            => 'someValue',
                        'SF_PS_Credit_Price__c' => 10,
                        'SF_PS_Extended_Amt__c' => 10,
                        'SF_PS_ItemType__c'     => 'MI'
                    },
                    new Map<String, Object>{
                        'attributes'            => 'someValue',
                        'SF_PS_Credit_Price__c' => 10,
                        'SF_PS_Extended_Amt__c' => 10,
                        'SF_PS_ItemType__c'     => 'M'
                    },
                    new Map<String, Object>{
                        'attributes'            => 'someValue',
                        'SF_PS_Credit_Price__c' => 10,
                        'SF_PS_Extended_Amt__c' => 10,
                        'SF_PS_ItemType__c'     => 'P'
                    }
                }
            }
        };
        Test.startTest();
            SBR_3_0_GenerateWOPDFUtility.getCreditWOMap(testMap);
            Assert.areEqual(false, ((Map<String, Object>)testMap.get('Credit_Line_Items__r')).containsKey('done'), 'done attribute removed from map');
        Test.stopTest();
    }

    @isTest
    public static void getQuoteWOMapTest(){
        Map<String, Object> testMap = new Map<String, Object>{
            'Quote_Line_Items__r' => new Map<String, Object>{
                'done'      => true,
                'totalSize' => 1,
                'records'   => new List<Object>{
                    new Map<String, Object>{
                        'attributes'                    => 'someValue',
                        'SF_PS_Hourly_Internal_Rate__c' => 10,
                        'SF_PS_Extended_Amt__c'         => 10
                    }
                }
            },
            'Quoted_Parts__r' => new Map<String, Object>{
                'done'      => true,
                'totalSize' => 1,
                'records'   => new List<Object>{
                    new Map<String, Object>{
                        'attributes'             => 'someValue',
                        'SF_PS_Selling_Price__c' => 10,
                        'SF_PS_Sub_Total__c'     => 10,
                        'SF_PS_ProductItem__r'   => new Map<String, Object>{'attributes' => 'someValue'},
                        'SF_PS_ItemType__c'      => 'MI'
                    },
                    new Map<String, Object>{
                        'attributes'             => 'someValue',
                        'SF_PS_Selling_Price__c' => 10,
                        'SF_PS_Sub_Total__c'     => 10,
                        'SF_PS_ProductItem__r'   => new Map<String, Object>{'attributes' => 'someValue'},
                        'SF_PS_ItemType__c'      => 'M'
                    },
                    new Map<String, Object>{
                        'attributes'             => 'someValue',
                        'SF_PS_Selling_Price__c' => 10,
                        'SF_PS_Sub_Total__c'     => 10,
                        'SF_PS_ProductItem__r'   => new Map<String, Object>{'attributes' => 'someValue'},
                        'SF_PS_ItemType__c'      => 'P'
                    }
                }
            }
        };
        Test.startTest();
            SBR_3_0_GenerateWOPDFUtility.getQuoteWOMap(testMap);
            Assert.areEqual(false, ((Map<String, Object>)testMap.get('Quote_Line_Items__r')).containsKey('done'), 'done attribute removed from map');
        Test.stopTest();
    }
}