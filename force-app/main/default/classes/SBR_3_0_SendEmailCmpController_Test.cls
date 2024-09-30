/*********************************************************************************************************************
* Apex Class: SBR_3_0_SendEmailCmpController_Test
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Test class for SBR_3_0_SendEmailCmpController
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Piyush Jindal           2023-11-28          Initial version
    2.0         Piyush Jindal           2023-11-30          Added a test method for Error
*********************************************************************************************************************/
@isTest
public with sharing class SBR_3_0_SendEmailCmpController_Test {
    private static string WORK_ORDER_ID = '';

    @TestSetup
    static void makeData(){
		Test.setMock(HttpCalloutMock.class, new SBR_3_0_SendEmailCmpController_Mock());
        Credential__c cred = SBR_3_0_TestDataFactory.createCredentials(1, false)[0];
        cred.Name      = 'Mule_Token_Endpoint';
        cred.Key_Id__c = 'testKey123';
        cred.Secret__c = 'secret';
        insert cred;

        // Create Account
        Account acct =  SBR_3_0_ServiceTestDataFactory.createAccount(false,'33333');
        acct.E_mail_Address__c = 'test123@invalid.com';
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

        insert new List<WorkOrder>{wo1};
            
        WORK_ORDER_ID = String.valueOf(wo1.Id);
    }

    @isTest
    static void testSendEmail_Success() {
		String exceptionMsg = '';
        String response = '';
		String emailStr = '{"toAddresses":["test@salesforce.com"],"attachmentData":[],"senderDetails":{"senderName":"Jane Doe","senderBranchC":null,"senderPhone":null,"senderFax":null},"workOrderDetails":{"workOrderNumber":"00004779","recordTypeC":"Inspection Record","jobLocationC":null,"poNumberC":null},"recordId":"' + WORK_ORDER_ID + '"}';
		Test.setMock(HttpCalloutMock.class, new SBR_3_0_SendEmailCmpController_Mock());
		Test.startTest();
        try {
			response = SBR_3_0_SendEmailCmpController.sendEmail(emailStr);
        } catch(Exception ex){
            exceptionMsg = ex.getMessage();
        }
        Test.stopTest();

        System.assertEquals(exceptionMsg, '', 'No Exceptions');
        System.assertEquals(response, 'success', 'Email triggered');
    }
    
    @isTest
    static void testSendEmail_Error() {
		String exceptionMsg = '';
        String response = '';
		String emailStr = '{"toAddresses":["test@salesforce.com"],"attachmentData":[],"senderDetails":{"senderName":"Jane Doe","senderBranchC":null,"senderPhone":null,"senderFax":null},"workOrderDetails":{"workOrderNumber":"00004779","recordTypeC":"Inspection Record","jobLocationC":null,"poNumberC":"Error"},"recordId":"' + WORK_ORDER_ID + '"}';
		Test.setMock(HttpCalloutMock.class, new SBR_3_0_SendEmailCmpController_Mock());
		Test.startTest();
        try {
			response = SBR_3_0_SendEmailCmpController.sendEmail(emailStr);
        } catch(Exception ex){
            exceptionMsg = ex.getMessage();
        }
        Test.stopTest();

		System.assertEquals(response, 'error', 'Email could not be triggered');
    }
}