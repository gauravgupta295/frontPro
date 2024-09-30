/*********************************************************************************************************************
* Apex Class: SBR_3_0_JobsiteDA_Test
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* @description - Class to test SBR_3_0_JobSiteSurveyDA
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME                  DATE                    DETAIL FEATURES
    1.0         Shreenivas Adapur               2024-01-26              Initial version
*********************************************************************************************************************/
@isTest public class SBR_3_0_JobSiteSurveyDA_Test {
    
    /**
    * @description make Data method
    * @author Shreenivas Adapur | 01-26-2024 
    **/
    @TestSetup
    static void makeData(){
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_JSSPDFDocController_Test());
        Credential__c cred = SBR_3_0_TestDataFactory.createCredentials(1, false)[0];
        cred.Name = 'Mule_Token_Endpoint';
        cred.Key_Id__c = 'testKey123';
        cred.Secret__c = 'secret';
        insert cred;
        // Create Account
        Account acct = new Account();
        acct.RM_Account_Number__c = '4';
        acct.Company_Code__c = '01';
        acct.Name = 'Test Account';
        acct.Record_Type_Text__c = 'Credit';
        acct.E_mail_Address__c = '123@asdf.com';
        acct.Phone = '1234567890';
        acct.BillingStreet = '123 Main Street';
        acct.BillingCity = 'Toronto';
        acct.BillingPostalCode = 'M9N7V5';
        acct.BillingState = 'ON';
        acct.BillingCountry = 'CA';
        acct.Drivers_License__c = 'AKF';
        acct.Driver_s_License_State__c = 'AL';
        insert acct;
        // Create Analysis Region
        Analysis_Region__c region = new Analysis_Region__c();
        region.Analysis_Region_Key__c = '928';
        region.Name = 'Test Region';
        region.Company_Code__c = '01';
        insert region;
        // Create Branch
        Schema.Location branchLocation = new Schema.Location();
        branchLocation.Branch_Location_Number__c = '720';
        branchLocation.Name = 'Test Branch Location';
        branchLocation.Street_Address__c = '12 Main Street';
        branchLocation.City__c = 'Toronto';
        branchLocation.Zip_Code__c = 'M7N7B3';
        branchLocation.State__c = 'ON';
        branchLocation.Country__c = 'CA';
        branchLocation.Job_Number__c='332112';
        branchLocation.RecordTypeId = SBR_3_0_Constants.LOCATION_BRANCH_RT_ID;
        branchLocation.Company_Code__c = 'X';
        branchLocation.Time_Zone_Name__c = 'America/Chicago';
        branchLocation.Time_Zone__c = 3;
        branchLocation.Analysis_Region_Key__c = '928';
        insert branchLocation;

        Jobsite_Survey__c jobSiteSurvey = new Jobsite_Survey__c(
            sbr_ProfitCenterId__c = branchLocation.Id,
            Name = 'Test Scaffold JSS'

            );
        insert jobSiteSurvey;
    }
    
    static testMethod void testGetJobSiteSurveyAnalysisRgn(){
        Test.startTest();
        Jobsite_Survey__c jobSiteSurveyRecord = [SELECT Id,Name FROM Jobsite_Survey__c LIMIT 1];

        Jobsite_Survey__c jobSiteSurvey = SBR_3_0_JobSiteSurveyDA.getJobSiteSurveyAnalysisRgn(jobSiteSurveyRecord.Id);
        String analysisRegion = jobSiteSurvey.sbr_ProfitCenterId__r.Analysis_Region_Key__c;
        Test.stopTest();
        Assert.areEqual('928', analysisRegion);
    }
   
}