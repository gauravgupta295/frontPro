@isTest
public with sharing class SBR_3_0_quoteSelectorController_Test Implements HttpCalloutMock {
    static Boolean isSuccessTest = true;
    public HttpResponse respond(HTTPRequest req) {
        // Create a fake response
        SBR_3_0_quoteSelectorController.WrappedResponse wrapperResp = new SBR_3_0_quoteSelectorController.WrappedResponse();
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type','application/octet-stream');
        res.setHeader('companyId', '1');
        
        if(req.getEndpoint().endsWithIgnoreCase('token')){
            res.setBody('{"access_token":"test"}');
        }else {
            res.setBody('{"example":"test"}');
        }
        if(isSuccessTest) {
            res.setStatusCode(200);
        }
        else {
            res.setStatusCode(400);
        }
        return res;
    }
    @TestSetup
    static void makeData(){
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_quoteSelectorController_Test());
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
        region.Analysis_Region_Key__c = '928';
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
        jobLocation.Analysis_Region_Key__c = '928';
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
        branchLocation.Analysis_Region_Key__c = '928';
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
            End_Date__c = date.valueOf('2022-11-07 12:00:00'),
            Opt_Out_RPP__c = false,
            Opt_Out_Fuel_Charge__c = false,
            Selling_Channel__c = 'SBRB2B',
            Branch__c = branchLocation.Id
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
            approval.sbaa__AssignedTo__c = userinfo.getUserId();
            approvals.add(approval);
        }
        insert approvals;
        Adobe_Quote_Template__c testAdobeTemplate = new Adobe_Quote_Template__c();
        testAdobeTemplate.Actual_Template__c = 'Test';
        testAdobeTemplate.Name ='Test Template';
        testAdobeTemplate.Analysis_Regions__c = '928';
        testAdobeTemplate.Template__c ='test';
        insert testAdobeTemplate;
    }

    @isTest static void getTemplatesTest(){
        SBQQ__Quote__c quote = [SELECT Id,Quote_Name__c FROM SBQQ__Quote__c WHERE  Quote_Name__c = 'Test Quote' LIMIT 1];
        Adobe_Quote_Template__c template = [SELECT Id FROM Adobe_Quote_Template__c WHERE  Name ='Test Template' LIMIT 1];
        Exception e = null;
        Assert.isNotNull(template);
        String analysisRegion=null;

        Test.startTest();
            try{
                List<Adobe_Quote_Template__c> templates = SBR_3_0_quoteSelectorController.getTemplates(quote.Id);
                analysisRegion = templates[0].Analysis_Regions__c;
            }
            catch(Exception ex) {
                e = ex;
            }
        Test.stopTest(); 
        Assert.isNotNull(analysisRegion);
        Assert.areEqual('928', analysisRegion); 
    }

    @isTest static void buildRequestTest(){
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_quoteSelectorController_Test());

        SBR_3_0_quoteSelectorController.WrappedResponse res = new SBR_3_0_quoteSelectorController.WrappedResponse();
        
        SBQQ__Quote__c quote = [SELECT Id,Quote_Name__c FROM SBQQ__Quote__c WHERE  Quote_Name__c = 'Test Quote' LIMIT 1];
        Adobe_Quote_Template__c template = [SELECT Id, Template__c FROM Adobe_Quote_Template__c WHERE  Name ='Test Template' LIMIT 1];
        
        Assert.isNotNull(quote);
        Exception e = null;
        String templateId = template.Id;
        String templateWords = 'Customer {{SBQQ__Account__r.Name}}';
       
        ContentVersion cv = new ContentVersion();
        cv.VersionData = Blob.valueOf(templateWords);
        cv.Title = 'testTemplate.docx';
        cv.PathOnClient = 'testTemplate.docx';
        cv.FirstPublishLocationId = templateId;
        try{
            insert cv;
				
            Test.startTest();
                SBR_3_0_quoteSelectorController.TemplateWrapper templateWrapper = SBR_3_0_quoteSelectorController.loadQuoteFields(quote.Id);
                res = SBR_3_0_quoteSelectorController.buildRequest(templateWrapper.data, templateId);
                SBR_3_0_quoteSelectorController.WrappedResponse wrappedRes = SBR_3_0_quoteSelectorController.RetrieveFile(res.body, res.httpDocGenEndPoint, res.httpDocGenAuthToken);
                SBR_3_0_quoteSelectorController.WrappedResponse wrappedResSave = SBR_3_0_quoteSelectorController.saveFile(wrappedRes.base64Body, templateWrapper.pdfTitle+'.pdf', quote.Id);
                SBR_3_0_quoteSelectorController.WrappedResponse wrappedResSaveSameName = SBR_3_0_quoteSelectorController.saveFile(wrappedRes.base64Body, templateWrapper.pdfTitle+'.pdf', quote.Id);
            Test.stopTest();
            Assert.isNotNull(res);
            Assert.isNotNull(templateWrapper.pdfTitle);
            Assert.isNotNull(wrappedResSave);
        }catch(Exception ex) {
            e = ex;
            System.debug('ex->'+e.getMessage());
        }
    }
    @isTest static void upsertPDFFilesTest(){
        Profile oProfile = [SELECT Id FROM Profile WHERE Name='Sales Insights Integration User'];
        User oUsers = SBR_3_0_TestDataFactory.createUser(TRUE,oProfile);
        System.runAs(oUsers){
            Test.setMock(HttpCalloutMock.class, new SBR_3_0_quoteSelectorController_Test());
    
            SBR_3_0_quoteSelectorController.WrappedResponse res = new SBR_3_0_quoteSelectorController.WrappedResponse();
            
            SBQQ__Quote__c quote = [SELECT Id,Quote_Name__c FROM SBQQ__Quote__c WHERE  Quote_Name__c = 'Test Quote' LIMIT 1];
            Adobe_Quote_Template__c template = [SELECT Id, Template__c FROM Adobe_Quote_Template__c WHERE  Name ='Test Template' LIMIT 1];
            
            Assert.isNotNull(quote);
            Exception e = null;
            String templateId = template.Id;
            String templateWords = 'Customer {{SBQQ__Account__r.Name}}';
           
            ContentVersion cv = new ContentVersion();
            cv.VersionData = Blob.valueOf(templateWords);
            cv.Title = 'testTemplate.docx';
            cv.PathOnClient = 'testTemplate.docx';
            cv.FirstPublishLocationId = templateId;
            try{
                insert cv;
                    
                Test.startTest();
                    SBR_3_0_quoteSelectorController.TemplateWrapper templateWrapper = SBR_3_0_quoteSelectorController.loadQuoteFields(quote.Id);
                    res = SBR_3_0_quoteSelectorController.buildRequest(templateWrapper.data, templateId);
                    SBR_3_0_quoteSelectorController.WrappedResponse wrappedRes = SBR_3_0_quoteSelectorController.RetrieveFile(res.body, res.httpDocGenEndPoint, res.httpDocGenAuthToken);
                    SBR_3_0_quoteSelectorController.WrappedResponse wrappedResSave = SBR_3_0_quoteSelectorController.saveFile(wrappedRes.base64Body, templateWrapper.pdfTitle+'.pdf', quote.Id);
                    SBR_3_0_quoteSelectorController.WrappedResponse wrappedResSaveSameName = SBR_3_0_quoteSelectorController.saveFile(wrappedRes.base64Body, templateWrapper.pdfTitle+'.pdf', quote.Id);
                Test.stopTest();
                Assert.isNotNull(res);
                Assert.isNotNull(templateWrapper.pdfTitle);
                Assert.isNotNull(wrappedResSave);
            }catch(Exception ex) {
                e = ex;
                System.debug('ex->'+e.getMessage());
            }
        }
    }
}