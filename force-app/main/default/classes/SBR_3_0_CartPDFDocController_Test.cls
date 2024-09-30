@isTest
public with sharing class SBR_3_0_CartPDFDocController_Test Implements HttpCalloutMock {
    static Boolean isSuccessTest = true;
    public HttpResponse respond(HTTPRequest req) {
        // Create a fake response
        SBR_3_0_CartPDFDocController.WrappedResponse wrapperResp = new SBR_3_0_CartPDFDocController.WrappedResponse();
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
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_CartPDFDocController_Test());
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

        Cart__c cart = new Cart__c(
            Account__c = acct.Id, 
            Branch__c = branchLocation.Id, 
            Rental_Start_Date__c = System.now()+2,
            Rental_End_Date__c = System.now()+3,
            Rental_Period__c = '1 Day',
            Job_Site__c = jobSite.Id );
        insert cart;
       
        Adobe_Quote_Template__c testAdobeTemplate = new Adobe_Quote_Template__c();
        testAdobeTemplate.Actual_Template__c = 'Test';
        testAdobeTemplate.Name ='Test Template';
        testAdobeTemplate.Analysis_Regions__c = '928';
        testAdobeTemplate.Template__c ='Cart';
        testAdobeTemplate.Template_Id__c ='123456';
        insert testAdobeTemplate;
    }

    @isTest static void getTemplatesTest(){
        Cart__c cart = [SELECT Id,Name FROM Cart__c LIMIT 1];
        Adobe_Quote_Template__c template = [SELECT Id FROM Adobe_Quote_Template__c WHERE  Name ='Test Template' LIMIT 1];
        Exception e = null;
        Assert.isNotNull(template);
        String analysisRegion=null;

        Test.startTest();
            try{
                List<Adobe_Quote_Template__c> templates = SBR_3_0_CartPDFDocController.getTemplates(cart.Id);
                analysisRegion = templates[0].Analysis_Regions__c;
				//analysisRegion = null;
            }
            catch(Exception ex) {
                e = ex;
            }
        Test.stopTest(); 
        Assert.isNotNull(analysisRegion);
        Assert.areEqual('928', analysisRegion); 
    }

    @isTest static void buildRequestTest(){
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_CartPDFDocController_Test());

        SBR_3_0_CartPDFDocController.WrappedResponse res = new SBR_3_0_CartPDFDocController.WrappedResponse();
        Test.startTest();
        Cart__c cart = [SELECT Id,Name FROM Cart__c LIMIT 1];
        Adobe_Quote_Template__c template = [SELECT Id, Template__c FROM Adobe_Quote_Template__c WHERE  Name ='Test Template' LIMIT 1];
        
        Assert.isNotNull(cart);
        Exception e = null;
        String templateId = template.Id;
        String templateWords = '{{Cart__c.Name}}';
       
        ContentVersion cv = new ContentVersion();
        cv.VersionData = Blob.valueOf(templateWords);
        cv.Title = 'testTemplate.docx';
        cv.PathOnClient = 'testTemplate.docx';
        cv.FirstPublishLocationId = templateId;
        try{
            insert cv;
				
           
                SBR_3_0_CartPDFDocController.TemplateWrapper templateWrapper = SBR_3_0_CartPDFDocController.loadCartFields(cart.Id);
                res = SBR_3_0_CartPDFDocController.buildRequest(templateWrapper.data, templateId,cv.Title);
                SBR_3_0_CartPDFDocController.WrappedResponse wrappedRes = SBR_3_0_CartPDFDocController.RetrieveFile(res.body, res.httpDocGenEndPoint, res.httpDocGenAuthToken);
                SBR_3_0_CartPDFDocController.WrappedResponse wrappedResSave = SBR_3_0_CartPDFDocController.saveFile(wrappedRes.base64Body, templateWrapper.pdfTitle+'.pdf', cart.Id);
             	SBR_3_0_CartPDFDocController.WrappedResponse wrappedResSave1 = SBR_3_0_CartPDFDocController.saveFile(wrappedRes.base64Body, '', cart.Id);
                SBR_3_0_CartPDFDocController.WrappedResponse wrappedResSaveSameName = SBR_3_0_CartPDFDocController.saveFile(wrappedRes.base64Body, templateWrapper.pdfTitle+'.pdf', cart.Id);
            Test.stopTest();
            Assert.isNotNull(res);
            Assert.isNotNull(templateWrapper.pdfTitle);
            Assert.isNotNull(wrappedResSave);
        }catch(Exception ex) {
            e = ex;
            System.debug('ex->'+e.getMessage());
        }
    }
    
    @isTest
    static void buildNonEmptyCartRequestTest() {
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_CartPDFDocController_Test());

        SBR_3_0_CartPDFDocController.WrappedResponse res = new SBR_3_0_CartPDFDocController.WrappedResponse();
        
        Cart__c cart = [SELECT Id,Name FROM Cart__c LIMIT 1];
        Cart_Items__c item = new Cart_Items__c(
            Cart__c = cart.Id
        );
        insert item;
        Adobe_Quote_Template__c template = [SELECT Id, Template__c FROM Adobe_Quote_Template__c WHERE  Name ='Test Template' LIMIT 1];
        
        Assert.isNotNull(cart);
        Exception e = null;
        String templateId = template.Id;
        String templateWords = '{{Cart__c.Name}}';
       
        ContentVersion cv = new ContentVersion();
        cv.VersionData = Blob.valueOf(templateWords);
        cv.Title = 'testTemplate.docx';
        cv.PathOnClient = 'testTemplate.docx';
        cv.FirstPublishLocationId = templateId;
        
        try{
            insert cv;
				
            Test.startTest();
                SBR_3_0_CartPDFDocController.TemplateWrapper templateWrapper = SBR_3_0_CartPDFDocController.loadCartFields(cart.Id);
                res = SBR_3_0_CartPDFDocController.buildRequest(templateWrapper.data, templateId,cv.Title);
                SBR_3_0_CartPDFDocController.WrappedResponse wrappedRes = SBR_3_0_CartPDFDocController.RetrieveFile(res.body, res.httpDocGenEndPoint, res.httpDocGenAuthToken);
                SBR_3_0_CartPDFDocController.WrappedResponse wrappedResSave = SBR_3_0_CartPDFDocController.saveFile(wrappedRes.base64Body, templateWrapper.pdfTitle+'.pdf', cart.Id);
                SBR_3_0_CartPDFDocController.WrappedResponse wrappedResSaveSameName = SBR_3_0_CartPDFDocController.saveFile(wrappedRes.base64Body, templateWrapper.pdfTitle+'.pdf', cart.Id);
           		SBR_3_0_CartPDFDocController.WrappedResponse wrappedRes1 = SBR_3_0_CartPDFDocController.RetrieveFile('', res.httpDocGenEndPoint, res.httpDocGenAuthToken);
            Test.stopTest();
            Assert.isNotNull(res);
            Assert.isNotNull(templateWrapper.pdfTitle);
            Assert.isNotNull(wrappedResSave);
        }catch(Exception ex) {
            e = ex;
            System.debug('ex->'+e.getMessage());
        }
    }
    /*@isTest
    static void test(){
         Test.startTest();
        SBR_3_0_CartPDFDocController.getAllFieldsForSObject('Account','0018G00000LeQw2QAF');
        Test.stopTest();
    }*/
}