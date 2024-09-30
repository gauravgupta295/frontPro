/*********************************************************************************************************************
* Apex Class: SBR_3_0_RetrieveWOPDF_Test
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Test Class for SBR_3_0_RetrieveWOPDF
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Akhil Tyagi             2023-10-31          Initial version
---------------------------------------------------------------------------------------------------------------------------------------
Note:-
* 
*********************************************************************************************************************/
@isTest
public class SBR_3_0_RetrieveWOPDF_Test {
    
    @TestSetup
    static void makeData(){
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

        // Create Analysis Region
        Analysis_Region__c region = new Analysis_Region__c(
            Analysis_Region_Key__c = '928',
            Name                   = 'Test Region',
            Company_Code__c        = '01'
        );
        insert region;

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

        User testSalesRep = SBR_3_0_ServiceTestDataFactory.createSalesRepUser(true,'111222');
        
        WorkOrder wo1 = SBR_3_0_ServiceTestDataFactory.createWorkOrder(false);
        wo1.SF_PS_RM_WO_Number__c        = '01-333221';
        wo1.SF_PS_Expense_To_Location__c = testST.id;
        wo1.AssetId                      = testAsset.id;
        wo1.ServiceTerritoryId           = testE2Loc.id;
        wo1.SF_PS_BillCustOrLoc__c       = '$';
        wo1.SF_PS_Sales_Rep__c           = testSalesRep.Id;
        wo1.SF_PS_Job_Site__c            = jobSite.Id;
        wo1.AccountId                    = acct.Id;

        WorkOrder wo2 = SBR_3_0_ServiceTestDataFactory.createWorkOrder(false);
        wo2.SF_PS_RM_WO_Number__c        = '01-333222';
        wo2.SF_PS_Expense_To_Location__c = testST.id;
        wo2.AssetId                      = testAsset.id;
        wo2.ServiceTerritoryId           = testE2Loc.id;
        wo2.SF_PS_BillCustOrLoc__c       = '$';
        wo2.SF_PS_Sales_Rep__c           = testSalesRep.Id;
        wo2.SF_PS_Job_Site__c            = jobSite.Id;
        wo2.AccountId                    = acct.Id;

        WorkOrder wo3 = SBR_3_0_ServiceTestDataFactory.createWorkOrder(false);
        wo3.SF_PS_RM_WO_Number__c        = '01-333223';
        wo3.SF_PS_Expense_To_Location__c = testST.id;
        wo3.AssetId                      = testAsset.id;
        wo3.ServiceTerritoryId           = testE2Loc.id;
        wo3.SF_PS_BillCustOrLoc__c       = '$';
        wo3.SF_PS_Sales_Rep__c           = testSalesRep.Id;
        wo3.SF_PS_Job_Site__c            = jobSite.Id;
        wo3.AccountId                    = acct.Id;

        WorkOrder wo4 = SBR_3_0_ServiceTestDataFactory.createWorkOrder(false);
        wo4.SF_PS_RM_WO_Number__c        = '01-333224';
        wo4.SF_PS_Expense_To_Location__c = testST.id;
        wo4.AssetId                      = testAsset.id;
        wo4.ServiceTerritoryId           = testE2Loc.id;
        wo4.SF_PS_BillCustOrLoc__c       = '$';
        wo4.SF_PS_Sales_Rep__c           = testSalesRep.Id;
        wo4.SF_PS_Job_Site__c            = jobSite.Id;
        wo4.AccountId                    = acct.Id;
        wo4.SF_PS_PONumber__c            = 'Error';
        insert new List<WorkOrder>{wo1, wo2, wo3, wo4};
       
        Adobe_Quote_Template__c testAdobeTemplate = new Adobe_Quote_Template__c();
        testAdobeTemplate.Name               = 'WorkOrder Invoice Template';
        testAdobeTemplate.Template__c        = 'WorkOrder';
        testAdobeTemplate.Template_Id__c     = '123456';
        insert testAdobeTemplate;
    }

    @isTest
    public static void makeRequestCompleteTest(){
        WorkOrder wo = [SELECT Id FROM WorkOrder WHERE SF_PS_RM_WO_Number__c = '01-333222' LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_GenerateWOPDFController_Mock());
        Test.startTest();
            SBR_3_0_RetrieveWOPDF.WrappedResponse response = SBR_3_0_RetrieveWOPDF.makeRequest(new Map<String, Object>{
                'repoId'        => '123456',
                'endPoint'      => 'endpoint',
                'authToken'     => 'authToken',
                'workOrderId'   => wo.Id,
                'executionFrom' => SBR_3_0_GenerateWOPDFUtility.EXECUTION_TYPE_AURA,
                'sendEmail'     => true
            });
            Assert.areEqual(SBR_3_0_GenerateWOPDFUtility.RESPONSE_STATUS_COMPLETE, response.status, 'PDF generated');
            Assert.isNotNull(response.fileBody, 'PDF Body is not null');
        Test.stopTest();
    }

    @isTest
    public static void makeRequestCompleteEmailFailTest(){
        WorkOrder wo = [SELECT Id FROM WorkOrder WHERE SF_PS_RM_WO_Number__c = '01-333224' LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_GenerateWOPDFController_Mock());
        Test.startTest();
            SBR_3_0_RetrieveWOPDF.WrappedResponse response = SBR_3_0_RetrieveWOPDF.makeRequest(new Map<String, Object>{
                'repoId'        => '123456',
                'endPoint'      => 'endpoint',
                'authToken'     => 'authToken',
                'workOrderId'   => wo.Id,
                'executionFrom' => SBR_3_0_GenerateWOPDFUtility.EXECUTION_TYPE_AURA,
                'sendEmail'     => true
            });
            Assert.areEqual(SBR_3_0_GenerateWOPDFUtility.RESPONSE_STATUS_INCOMPLETE, response.status, 'PDF generated');
        Test.stopTest();
    }

    @isTest
    public static void makeRequestInProgressTest(){
        WorkOrder wo = [SELECT Id FROM WorkOrder WHERE SF_PS_RM_WO_Number__c = '01-333222' LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_GenerateWOPDFController_Mock());
        Test.startTest();
            SBR_3_0_RetrieveWOPDF.WrappedResponse response = SBR_3_0_RetrieveWOPDF.makeRequest(new Map<String, Object>{
                'repoId'        => '123457',
                'endPoint'      => 'endpoint',
                'authToken'     => 'authToken',
                'workOrderId'   => wo.Id,
                'executionFrom' => SBR_3_0_GenerateWOPDFUtility.EXECUTION_TYPE_AURA,
                'sendEmail'     => true
            });
            Assert.areEqual(SBR_3_0_GenerateWOPDFUtility.RESPONSE_STATUS_INPROGRESS, response.status, 'PDF is being generated');
        Test.stopTest();
    }

    @isTest
    public static void retrievePDFInProgressTest(){
        WorkOrder wo = [SELECT Id FROM WorkOrder WHERE SF_PS_RM_WO_Number__c = '01-333222' LIMIT 1];
        List<List<String>> data = new List<List<String>>();
        data.add(new List<String>{ '123457', 'endpoint', 'authToken', wo.Id } );
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_GenerateWOPDFController_Mock());
        Test.startTest();
            List<SBR_3_0_RetrieveWOPDF.WrappedResponse> response = SBR_3_0_RetrieveWOPDF.retrievePDF(data);
            Assert.areEqual(SBR_3_0_GenerateWOPDFUtility.RESPONSE_STATUS_INPROGRESS, response[0].status, 'PDF is being generated');
        Test.stopTest();
    }

    @isTest
    public static void makeRequestIncompleteTest(){
        WorkOrder wo = [SELECT Id FROM WorkOrder WHERE SF_PS_RM_WO_Number__c = '01-333222' LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_GenerateWOPDFController_Mock());
        Test.startTest();
            SBR_3_0_RetrieveWOPDF.WrappedResponse response = SBR_3_0_RetrieveWOPDF.makeRequest(new Map<String, Object>{
                'repoId'        => '123458',
                'endPoint'      => 'endpoint',
                'authToken'     => 'authToken',
                'workOrderId'   => wo.Id,
                'executionFrom' => SBR_3_0_GenerateWOPDFUtility.EXECUTION_TYPE_AURA,
                'sendEmail'     => true
            });
            Assert.areEqual(SBR_3_0_GenerateWOPDFUtility.RESPONSE_STATUS_INCOMPLETE, response.status, 'Error during callout');
        Test.stopTest();
    }

    @isTest
    public static void retrievePDFExceptionTest(){
        WorkOrder wo = [SELECT Id FROM WorkOrder WHERE SF_PS_RM_WO_Number__c = '01-333222' LIMIT 1];
        List<List<String>> data = new List<List<String>>();
        data.add(new List<String>{ '123457', 'endpoint', 'authToken', wo.Id } );
        Test.startTest();
            try{
                List<SBR_3_0_RetrieveWOPDF.WrappedResponse> response = SBR_3_0_RetrieveWOPDF.retrievePDF(data);
            } catch(Exception ex){}
        Test.stopTest();
    }
}