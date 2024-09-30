@isTest
public with sharing class SBR_3_0_API_Approve_Test implements HttpCalloutMock{
    static Boolean SUCCESSTEST = true;
    public HTTPResponse respond(HTTPRequest req) {
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type',SBR_3_0_Constants.APP_JSON);
        if(req.getEndpoint().endsWithIgnoreCase('token')){
            res.setBody('{"access_token":"test"}');
        }else {
            res.setBody('');
        }
        if(SUCCESSTEST) {
            res.setStatusCode(200);
        }
        else {
            res.setStatusCode(400);
        }
        return res;
    }

    @TestSetup
    static void makeData(){
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_Approve_Test());
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
        acct.Account_Type__c = 'Credit';
        acct.E_mail_Address__c = '123@asdf.com';
        acct.Phone = '12345678';
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
        region.Analysis_Region_Key__c = '001';
        region.Name = 'Test Region';
        region.Company_Code__c = '01';
        insert region;
        // Create Location
        Schema.Location jobLocation = new Schema.Location();
        jobLocation.Name = 'Test Job Location';
        jobLocation.Street_Address__c = '12 Main Street';
        jobLocation.City__c = 'Toronto';
        jobLocation.Zip_Code__c = 'M7N7B3';
        jobLocation.State__c = 'ON';
        jobLocation.Country__c = 'CA';
        jobLocation.RecordTypeId = SBR_3_0_Constants.LOCATION_JOB_RT_ID;
        jobLocation.OMS_Sourcing_Enabled__c = true;
        jobLocation.Distance_Multiplier__c = 50;
        jobLocation.Analysis_Region_Key__c = '001';
        jobLocation.Company_Code__c = '01';
        insert jobLocation;
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
        insert branchLocation;
        // Create Job Site
        AssociatedLocation jobSite = new AssociatedLocation(
            Name__c = 'Test Job Site',
            ParentRecordId = acct.Id,
            LocationId = jobLocation.Id,
            Branch__c = branchLocation.Id,
            Job_Number__c = '20221004A'
        );
        insert jobSite;
        // Create Quote
        SBQQ__Quote__c quote = new SBQQ__Quote__c(
            Quote_Name__c = 'Test Quote',
            SBQQ__Account__c = acct.Id,
            Jobsite__c = jobSite.Id,
            SBQQ__DeliveryMethod__c = 'Delivery',
            Start_Date__c = date.valueOf('2022-10-07 12:00:00'),
            End_Date__c = date.valueOf('2022-10-07 12:00:00'),
            Opt_Out_RPP__c = false,
            Opt_Out_Fuel_Charge__c = false,
            Selling_Channel__c = 'SBRB2B'
        );
        insert quote;
        // Create Approval Rule
        sbaa__ApprovalRule__c approvalRule = new sbaa__ApprovalRule__c();
        approvalRule.Name = 'Test Level 1';
        approvalRule.sbaa__TargetObject__c = 'SBQQ__Quote__c';
        approvalRule.sbaa__ApprovalStep__c = 1;
        insert approvalRule;
        // Create Approval
        List<sbaa__Approval__c> approvals = new List<sbaa__Approval__c>();
        for (Integer i = 1; i < 3; i++) {
            sbaa__Approval__c approval = new sbaa__Approval__c();
            approval.sbaa__Status__c = 'Requested';
            approval.sbaa__ApprovalStep__c = 1;
            approval.sbaa__RecordField__c = 'Quote__c';
            approval.sbaa__Rule__c = approvalRule.Id;
            approval.Quote__c = quote.Id;
            approval.sbaa__CommentsLong__c = 'TEST';
            approval.sbaa__AssignedTo__c=userinfo.getuserId();
            approvals.add(approval);
        }
        insert approvals;
    }

    @isTest
    static void testApproveSuccess() {
        SUCCESSTEST = true;
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_Approve_Test());
        sbaa__Approval__c approval = new sbaa__Approval__c();
        approval = [SELECT Id, sbaa__CommentsLong__c, sbaa__ApprovedBy__c FROM sbaa__Approval__c LIMIT 1];

        Exception e = null;
        Test.startTest();
        try{
            SBR_3_0_API_Approve apiApprove = new SBR_3_0_API_Approve(approval.Id, approval.sbaa__CommentsLong__c, approval.sbaa__ApprovedBy__c);
            SBR_3_0_API_Approve.Approve(approval.Id, approval.sbaa__CommentsLong__c, approval.sbaa__ApprovedBy__c);
            SBR_3_0_API_Approve.BulkApprove(new List<String>{approval.Id},new List<String>{approval.sbaa__CommentsLong__c});
        }
        catch(Exception ex) {
            e = ex;
        }
        Test.stopTest();

        System.assert(e == null, 'Approval should be successful');
    }
}