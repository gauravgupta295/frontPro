/**
 * @description       : 
 * @group             : 
 * @last modified on  : 05-07-2024
 * @last modified by  : Shreenivas Adapur
**/
@isTest
public class SBR_3_0_GeneratePDFDocQuote_Test_0 {
    
    private class MockClass implements HTTPCalloutMock
    {
        private Boolean isSuccessTest = true;
        public HttpResponse respond(HTTPRequest req) {
        // Create a fake response
        //SBR_3_0_CartPDFDocController.WrappedResponse wrapperResp = new SBR_3_0_CartPDFDocController.WrappedResponse();
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
        
    }
   @TestSetup
    static void buildRequestTest()
    {
        Credential__c cred = new Credential__c();
        cred.Name = 'Mule_Token_Endpoint' ; 
        cred.Key_Id__c  = 'Mule_Token_Endpoint';
        cred.Secret__c  = '***********************************XQzY';
        cred.Environment__c = 'SANDBOX';
        insert cred;
        
        Account acct = new Account();
        acct.RM_Account_Number__c = '414';
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
        region.Analysis_Region_Key__c = '665';
        region.Name = 'Test Regio 343';
        region.Company_Code__c = '01';
        region.Unique_name__c='1-47554428';
        insert region;
       
        Adobe_Quote_Template__c testAdobeTemplate = new Adobe_Quote_Template__c();
        testAdobeTemplate.Actual_Template__c = 'Test';
        testAdobeTemplate.Name ='Test Template';
        testAdobeTemplate.Analysis_Regions__c = '928';
        testAdobeTemplate.Template__c ='Cart';
        testAdobeTemplate.Template_Id__c ='123456';
        insert testAdobeTemplate;
        
        Profile p = [SELECT Id FROM Profile WHERE Name='Sales'];
        //create ers user clone
        String ersUserName = 'ersuser' + DateTime.now().getTime() + '@SBRtestorg.com';
        User ersu = new User(Alias = 'ers', Email='ersuser@testorg.com',
        EmailEncodingKey='UTF-8', LastName='erstest', LanguageLocaleKey='en_US',
        LocaleSidKey='en_US', ProfileId = p.Id,
        TimeZoneSidKey='America/Los_Angeles',
        UserName=ersUserName);
        ersu.RepID__c = '12344';
        insert ersu;
     
        // Create Contact
        Contact cont = new Contact();
        cont.FirstName = 'Test';
        cont.LastName = 'TEST';
        cont.AccountId = acct.id;
        cont.MobilePhone = '5555555555';
        cont.Phone = '5555555555';
        cont.Email = 'SDFIONMW@TESTEMAILSALESFORCE.com';
        cont.MailingStreet = '12 Main Street';
        cont.MailingCity = 'Toronto';
        cont.MailingPostalCode = 'M7N7B3';
        cont.MailingState = 'ON';
        cont.MailingCountry = 'CA';
        insert cont;
       
        // Create Location
        Schema.Location jobLocation1 = new Schema.Location();
        jobLocation1.Name = 'Test Job Location';
        jobLocation1.Street_Address__c = '12 Main Street';
        jobLocation1.City__c = 'Toronto';
        jobLocation1.Zip_Code__c = 'M7N7B3';
        jobLocation1.State__c = 'ON';
        jobLocation1.Country__c = 'CA';
        jobLocation1.RecordTypeId = SBR_3_0_Constants.LOCATION_JOB_RT_ID;
        jobLocation1.OMS_Sourcing_Enabled__c = true;
        jobLocation1.Distance_Multiplier__c = 50;
        jobLocation1.Analysis_Region_Key__c = '001';
        jobLocation1.Company_Code__c = '01';
        insert jobLocation1;
        // Create Branch
        Schema.Location branchLocation1 = new Schema.Location();
        branchLocation1.Branch_Location_Number__c = '720';
        branchLocation1.Name = 'Test Branch Location';
        branchLocation1.Street_Address__c = '12 Main Street';
        branchLocation1.City__c = 'Toronto';
        branchLocation1.Zip_Code__c = 'M7N7B3';
        branchLocation1.State__c = 'ON';
        branchLocation1.Country__c = 'CA';
        branchLocation1.Job_Number__c='332112';
        branchLocation1.RecordTypeId = SBR_3_0_Constants.LOCATION_BRANCH_RT_ID;
        branchLocation1.Company_Code__c = 'X';
        branchLocation1.Time_Zone_Name__c = 'America/Chicago';
        branchLocation1.Time_Zone__c = 3;
        branchLocation1.Time_Zone_Id__c = 'America/Chicago';
        branchLocation1.Analysis_Region_Key__c='003';
        insert branchLocation1;
        
        // Create Job Site
        AssociatedLocation jobSite = new AssociatedLocation(
            Name__c = 'Test Job Site',
            ParentRecordId = acct.Id,
            Branch__c = branchLocation1.Id,
            Job_Number__c = '20221107A',
            Job_Site_Id__c = 'SF20221107A',
            Street_Address__c = '12 Main Street',
            City__c = 'Toronto',
            State__c = 'ON',
            Zip_Code__c = 'M9N7V3',
            LocationId = jobLocation1.Id
        );
        insert jobSite;
       // AssociatedLocation jobSite = [select id from  AssociatedLocation limit 1];
                Cart__c cart = new Cart__c(
            Account__c = acct.Id, 
            Branch__c = branchLocation1.Id, 
            Rental_Start_Date__c = System.now()+5,
            Rental_End_Date__c = System.now()+12,
            Rental_Period__c = '7 Days',
            Job_Site__c = jobSite.Id );
            insert cart;
        // Create Quote
        SBQQ__Quote__c quote1 = new SBQQ__Quote__c(
            Branch__c=branchLocation1.id,
            Quote_Name__c = 'Test Quote',
            SBQQ__Account__c = acct.Id,
            Ordered_By__c = cont.Id,
            Jobsite__c = jobSite.Id,
            SBQQ__DeliveryMethod__c = 'Delivery',
            Start_Date__c = DateTime.now(),
            End_Date__c = DateTime.now() + 7,
            Delivery_Date__c = DateTime.now(),
            Opt_Out_RPP__c = false,
            Opt_Out_Fuel_Charge__c = false,
            Selling_Channel__c = 'SBRB2B',
           // Duration__c = 'Custom',
            //Estimated_Return_Date__c = date.valueOf('2022-10-07 12:00:00'),
            SBQQ__SalesRep__c = ersu.Id
        );

        insert quote1;

        Adobe_Quote_Template__c template = [SELECT Id, Template__c FROM Adobe_Quote_Template__c WHERE  Name ='Test Template' LIMIT 1];
         String templateId = template.Id;
        String templateWords = 'Customer {{SBQQ__Account__r.Name}}';
       
        ContentVersion cv = new ContentVersion();
        cv.VersionData = Blob.valueOf(templateWords);
        cv.Title = 'testTemplate.docx';
        cv.PathOnClient = 'testTemplate.docx';
        cv.FirstPublishLocationId = templateId;
        insert cv;
        
       ContentDocument cd = [SELECT Id,createddate FROM ContentDocument limit 1];
       cd.title = 'testTemplate.docx.pdf';
       update cd;
       SBQQ__Quote__c quote = [SELECT Id,Quote_Name__c FROM SBQQ__Quote__c LIMIT 1];
       quote.Quote_Name__c='Test Quote 1';
       
        id quoteID=quote.id;
        
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.LinkedEntityId = quote.id;
        cdl.ContentDocumentId = cd.Id;
        insert cdl;
        
        id cdlID=cdl.LinkedEntityId;
        
        string allFields = 'LastModifiedDate,SBQQ__Account__r.Name,SBQQ__Account__r.RecordType.DeveloperName,SBQQ__Account__r.BillingAddress,SBQQ__Account__r.Primary_Equipment_Used__c,SBQQ__Account__r.Credit_Code_Description__c,SBQQ__Account__r.phone,SBQQ__Account__r.email__c,SBQQ__Account__r.ShippingAddress,SBQQ__Account__r.ParentID,SBQQ__Account__r.personOtherPhone__c,SBQQ__Account__r.fax,SBQQ__Account__r.unique_preferences_hot_buttons__c,SBQQ__Account__r.rental_opportunity__c,SBQQ__Account__r.Specialty_opportunity__c,SBQQ__Account__r.other_opportunity__c,SBQQ__Account__r.strategy_last_updated__c,Jobsite__r.Branch__r.Name, Jobsite__r.Name__c, Jobsite__r.Job_Site_Id__c, Jobsite__r.Job_Number__c, Jobsite__r.Job_Reference_Number__c,Jobsite__r.latitude_longitude__c,Jobsite__r.ParentRecordId,Jobsite__r.ParentRecord.Name,Jobsite__r.Override_System_Address_Updates__c,Jobsite__r.Account_Number__c,Jobsite__r.Street_address__c,Jobsite__r.city__c,Jobsite__r.state__c,Jobsite__r.address_validation_status__c,Jobsite__r.zip_code__c,Jobsite__r.quote__r.name,SBQQ__PrimaryContact__r.Name,  SBQQ__PrimaryContact__r.Status__c, SBQQ__PrimaryContact__r.DoNotCall,SBQQ__PrimaryContact__r.mailingAddress,SBQQ__PrimaryContact__r.birthdate,SBQQ__PrimaryContact__r.leadsource,SBQQ__PrimaryContact__r.assistantName,SBQQ__PrimaryContact__r.assistantphone,SBQQ__PrimaryContact__r.HasOptedOutOfEmail,SBQQ__PrimaryContact__r.hasOptedOutOfFax,SBQQ__PrimaryContact__r.createdbyID,SBQQ__PrimaryContact__r.lastmodifiedByID,SBQQ__PrimaryContact__r.MobilePhone,SBQQ__PrimaryContact__r.phone,SBQQ__PrimaryContact__r.email,SBQQ__PrimaryContact__r.fax,SBQQ__PrimaryContact__r.Preferred_Contact_Method__c,SBQQ__PrimaryContact__r.Role__c,SBQQ__PrimaryContact__r.reportsToId,SBQQ__PrimaryContact__r.description,Branch__r.name,Branch__r.RecordType.DeveloperName,Branch__r.Street_address__c,Branch__r.city__c,Branch__r.state__c,Branch__r.zip_code__C,Branch__r.country__c,Branch__r.latitude_longitude__c,Branch__r.Delivery_instruction_1__c,Branch__r.Delivery_instruction_2__c,Branch__r.Delivery_instruction_3__c,Branch__r.Delivery_instruction_4__c,Branch__r.CreatedById,Branch__r.LastModifiedById,Branch__r.Branch_Location_Name__c,SBQQ__SalesRep__r.Name, SBQQ__SalesRep__r.Email,Ordered_by__r.Name, Ordered_by__r.FirstName, Ordered_by__r.LastName, Ordered_by__r.Email,SBQQ__Account__r.RM_Account_Number_Display__c,SBQQ__Account__r.RM_Account_Number__c';
        List<ContentDocumentLink> cdl1 = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :cv.Id limit 1];
        Map<String, Schema.SObjectField> fieldMap = SBQQ__Quote__c.sObjectType.getDescribe().fields.getMap();
        Set<String> setFieldNames = fieldMap.keySet(); 
        list<String> quoteFieldNames = new List<String>(setFieldNames);
        SBQQ__Quote__c quoteFields = Database.query('SELECT ' + String.join(quoteFieldNames, ',')    + ' FROM SBQQ__Quote__c where id=:quoteID');
        Map<String,Object> quoteMap = (Map<String,Object>)JSON.deserializeUntyped(JSON.serialize(quotefields));
       
        try{
            SBR_3_0_GeneratePDFDocQuote.buildRequest(quoteMap,templateId,cv.Title);
        }
        catch(Exception e)
        {
            system.debug(e.getLineNumber()+ '  '+e.getStackTraceString()+ '  '+e.getMessage());
        }
        string s='hahaha';
        SBR_3_0_GeneratePDFDocQuote.saveFile(s,cv.Title,quoteID);
    }
    
     @isTest
     static void buildRequestTest_0()   
    {
        Account acct = [select id from account limit 1];
       
        //insert acct;
        // Create Analysis Region
        Analysis_Region__c region = new Analysis_Region__c();
        region.Analysis_Region_Key__c = '765';
        region.Name = 'Test Regiogh 343';
        region.Company_Code__c = '01';
        region.Unique_name__c='1-489756928';
        insert region;
       
        Adobe_Quote_Template__c testAdobeTemplate = new Adobe_Quote_Template__c();
        testAdobeTemplate.Actual_Template__c = 'Test';
        testAdobeTemplate.Name ='Test Template';
        testAdobeTemplate.Analysis_Regions__c = '928';
        testAdobeTemplate.Template__c ='Cart';
        insert testAdobeTemplate;
        
        Profile p = [SELECT Id FROM Profile WHERE Name='Sales'];
        //create ers user clone
        String ersUserName = 'ersuser' + DateTime.now().getTime() + '@SBRtestorg.com';
        User ersu = new User(Alias = 'ers', Email='ersuser@testorg.com',
        EmailEncodingKey='UTF-8', LastName='erstest', LanguageLocaleKey='en_US',
        LocaleSidKey='en_US', ProfileId = p.Id,
        TimeZoneSidKey='America/Los_Angeles',
        UserName=ersUserName);
        ersu.RepID__c = '123545';
        insert ersu;

        // Create Contact
        Contact cont = new Contact();
        cont.FirstName = 'Test@@';
        cont.LastName = 'TEST@@';
        cont.AccountId = acct.id;
        cont.MobilePhone = '5345555555';
        cont.Phone = '5555578555';
        cont.Email = 'SD12ONMW@TESTEerMAILSALESFORCE.com';
        cont.MailingStreet = '12 Maain Street';
        cont.MailingCity = 'Toraonto';
        cont.MailingPostalCode = 'M7N7B3';
        cont.MailingState = 'ON';
        cont.MailingCountry = 'CA';
        insert cont;
       
        // Create Location
        Schema.Location jobLocation1 = new Schema.Location();
        jobLocation1.Name = 'Test Job Location';
        jobLocation1.Street_Address__c = '12 Main Street';
        jobLocation1.City__c = 'Toronto';
        jobLocation1.Zip_Code__c = 'M7N7B3';
        jobLocation1.State__c = 'ON';
        jobLocation1.Country__c = 'CA';
        jobLocation1.RecordTypeId = SBR_3_0_Constants.LOCATION_JOB_RT_ID;
        jobLocation1.OMS_Sourcing_Enabled__c = true;
        jobLocation1.Distance_Multiplier__c = 50;
        jobLocation1.Analysis_Region_Key__c = '001';
        jobLocation1.Company_Code__c = '01';
        insert jobLocation1;
        // Create Branch
        Schema.Location branchLocation1 = new Schema.Location();
        branchLocation1.Branch_Location_Number__c = '720';
        branchLocation1.Name = 'Test Branch Location';
        branchLocation1.Street_Address__c = '12 Main Street';
        branchLocation1.City__c = 'Toronto';
        branchLocation1.Zip_Code__c = 'M7N7B3';
        branchLocation1.State__c = 'ON';
        branchLocation1.Country__c = 'CA';
        branchLocation1.Job_Number__c='332112';
        branchLocation1.RecordTypeId = SBR_3_0_Constants.LOCATION_BRANCH_RT_ID;
        branchLocation1.Company_Code__c = '1';
        branchLocation1.Time_Zone_Name__c = 'America/Chicago';
        branchLocation1.Time_Zone__c = 3;
        branchLocation1.Time_Zone_Id__c = 'America/Chicago';
        branchLocation1.Analysis_Region_Key__c='003';
        insert branchLocation1;
        // Create Job Site
        AssociatedLocation jobSite =[select id from AssociatedLocation limit 1];
        Cart__c cart = new Cart__c(
            Account__c = acct.Id, 
            Branch__c = branchLocation1.Id, 
            Rental_Start_Date__c = System.now()+5,
            Rental_End_Date__c = System.now()+12,
            Rental_Period__c = '7 Days',
            Job_Site__c = jobSite.Id );
            insert cart;
        // Create Quote
        SBQQ__Quote__c quote1 = new SBQQ__Quote__c(
            Branch__c=branchLocation1.id,
            Quote_Name__c = 'Test Quotetr',
            SBQQ__Account__c = acct.Id,
            Ordered_By__c = cont.Id,
            Jobsite__c = jobSite.Id,
            SBQQ__DeliveryMethod__c = 'Delivery',
            Start_Date__c = date.valueOf('2022-10-07 12:00:00'),
            End_Date__c = date.valueOf('2022-10-08 8:00:00'),
            Delivery_Date__c = date.valueOf('2022-10-07 12:00:00'),
            Opt_Out_RPP__c = false,
            Opt_Out_Fuel_Charge__c = false,
            Selling_Channel__c = 'SBRB2B',
            //Duration__c = 'Custom',
            SBQQ__SalesRep__c = ersu.Id
        );
        insert quote1;

        Adobe_Quote_Template__c template = [SELECT Id, Template__c FROM Adobe_Quote_Template__c WHERE  Name ='Test Template' LIMIT 1];
         String templateId = template.Id;
        String templateWords = 'Customer {{SBQQ__Account__r.Name}}';
       
        ContentVersion cv = new ContentVersion();
        cv.VersionData = Blob.valueOf(templateWords);
        cv.Title = 'testTemplate.docx';
        cv.PathOnClient = 'testTemplate.docx';
        cv.FirstPublishLocationId = templateId;
        insert cv;
        
        ContentDocument cd = [SELECT Id,createddate FROM ContentDocument limit 1];
        cd.title = 'testTemplate.docx.pdf';
        update cd;
     
        SBQQ__Quote__c quote = [SELECT Id,Quote_Name__c FROM SBQQ__Quote__c where Quote_Name__c='Test Quotetr'LIMIT 1];
     
        id quoteID=quote.id;
        
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.LinkedEntityId = quote.id;
        cdl.ContentDocumentId = cd.Id;
        insert cdl;
        
        id cdlID=cdl.LinkedEntityId;
        
       Test.setMock(HttpCalloutMock.class, new MockClass());
        
        string allFields = 'LastModifiedDate,SBQQ__Account__r.Name,SBQQ__Account__r.RecordType.DeveloperName,SBQQ__Account__r.BillingAddress,SBQQ__Account__r.Primary_Equipment_Used__c,SBQQ__Account__r.Credit_Code_Description__c,SBQQ__Account__r.phone,SBQQ__Account__r.email__c,SBQQ__Account__r.ShippingAddress,SBQQ__Account__r.ParentID,SBQQ__Account__r.personOtherPhone__c,SBQQ__Account__r.fax,SBQQ__Account__r.unique_preferences_hot_buttons__c,SBQQ__Account__r.rental_opportunity__c,SBQQ__Account__r.Specialty_opportunity__c,SBQQ__Account__r.other_opportunity__c,SBQQ__Account__r.strategy_last_updated__c,Jobsite__r.Branch__r.Name, Jobsite__r.Name__c, Jobsite__r.Job_Site_Id__c, Jobsite__r.Job_Number__c, Jobsite__r.Job_Reference_Number__c,Jobsite__r.latitude_longitude__c,Jobsite__r.ParentRecordId,Jobsite__r.ParentRecord.Name,Jobsite__r.Override_System_Address_Updates__c,Jobsite__r.Account_Number__c,Jobsite__r.Street_address__c,Jobsite__r.city__c,Jobsite__r.state__c,Jobsite__r.address_validation_status__c,Jobsite__r.zip_code__c,Jobsite__r.quote__r.name,SBQQ__PrimaryContact__r.Name,  SBQQ__PrimaryContact__r.Status__c, SBQQ__PrimaryContact__r.DoNotCall,SBQQ__PrimaryContact__r.mailingAddress,SBQQ__PrimaryContact__r.birthdate,SBQQ__PrimaryContact__r.leadsource,SBQQ__PrimaryContact__r.assistantName,SBQQ__PrimaryContact__r.assistantphone,SBQQ__PrimaryContact__r.HasOptedOutOfEmail,SBQQ__PrimaryContact__r.hasOptedOutOfFax,SBQQ__PrimaryContact__r.createdbyID,SBQQ__PrimaryContact__r.lastmodifiedByID,SBQQ__PrimaryContact__r.MobilePhone,SBQQ__PrimaryContact__r.phone,SBQQ__PrimaryContact__r.email,SBQQ__PrimaryContact__r.fax,SBQQ__PrimaryContact__r.Preferred_Contact_Method__c,SBQQ__PrimaryContact__r.Role__c,SBQQ__PrimaryContact__r.reportsToId,SBQQ__PrimaryContact__r.description,Branch__r.name,Branch__r.RecordType.DeveloperName,Branch__r.Street_address__c,Branch__r.city__c,Branch__r.state__c,Branch__r.zip_code__C,Branch__r.country__c,Branch__r.latitude_longitude__c,Branch__r.Delivery_instruction_1__c,Branch__r.Delivery_instruction_2__c,Branch__r.Delivery_instruction_3__c,Branch__r.Delivery_instruction_4__c,Branch__r.CreatedById,Branch__r.LastModifiedById,Branch__r.Branch_Location_Name__c,SBQQ__SalesRep__r.Name, SBQQ__SalesRep__r.Email,Ordered_by__r.Name, Ordered_by__r.FirstName, Ordered_by__r.LastName, Ordered_by__r.Email,SBQQ__Account__r.RM_Account_Number_Display__c,SBQQ__Account__r.RM_Account_Number__c';
        List<ContentDocumentLink> cdl1 = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :cv.Id limit 1];
        Map<String, Schema.SObjectField> fieldMap = SBQQ__Quote__c.sObjectType.getDescribe().fields.getMap();
        Set<String> setFieldNames = fieldMap.keySet(); 
        list<String> quoteFieldNames = new List<String>(setFieldNames);

        SBQQ__Quote__c quoteFields = Database.query('SELECT ' + String.join(quoteFieldNames, ',')    + ' FROM SBQQ__Quote__c where id=:quoteID');
        Map<String,Object> quoteMap = (Map<String,Object>)JSON.deserializeUntyped(JSON.serialize(quotefields));
        System.runAs(ersu){
            Test.startTest();
        SBR_3_0_GeneratePDFDocQuote.buildRequest(quoteMap,templateId,cv.Title);
       
         Test.StopTest();
        string s='hahaha';
        SBR_3_0_GeneratePDFDocQuote.saveFile(s,cv.Title,quoteID);
        }
    }

    @isTest static void getTemplatesTest(){
   
       // Cart__c cart = [SELECT Id,Name FROM Cart__c LIMIT 1];
        Adobe_Quote_Template__c template = [SELECT Id FROM Adobe_Quote_Template__c WHERE  Name ='Test Template' LIMIT 1];
         SBQQ__Quote__c quote=[select id from SBQQ__Quote__c limit 1];
        Schema.Location branchLocation1=[select id ,Analysis_Region_Key__c from location where name='Test Branch Location' limit 1];

        Test.startTest();
           
        List<Adobe_Quote_Template__c> templates = SBR_3_0_GeneratePDFDocQuote.getTemplates(quote.Id);
        branchLocation1.Analysis_Region_Key__c=null;
        update branchLocation1;

        List<Adobe_Quote_Template__c> templates1 = SBR_3_0_GeneratePDFDocQuote.getTemplates(quote.Id);
        Test.stopTest(); 

    }
    
    @isTest static void loadQuoteFieldsTest(){
      Profile p = [SELECT Id FROM Profile WHERE Name='Sales'];
        //create ers user clone
        String ersUserName = 'ersuser' + DateTime.now().getTime() + '@SBRtestorg.com';
        User ersu = new User(Alias = 'ers', Email='ersuser@testorg.com',
        EmailEncodingKey='UTF-8', LastName='erstest', LanguageLocaleKey='en_US',
        LocaleSidKey='en_US', ProfileId = p.Id,
        TimeZoneSidKey='America/Los_Angeles',
        UserName=ersUserName);
        ersu.RepID__c = '12346';
        insert ersu;
        // Create Account
      account acct=[select id from account limit 1];
      
        // Create Analysis Region
        Analysis_Region__c region = new Analysis_Region__c();
        region.Analysis_Region_Key__c = '081';
        region.Name = 'Tegst Reghgion';
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
        branchLocation.Time_Zone_Id__c = 'America/Chicago';
     branchLocation.Analysis_Region_Key__c='003';
        insert branchLocation;
        // Create Job Site
        AssociatedLocation jobSite = [select id from  AssociatedLocation limit 1];
        
        // Create Quote
        SBQQ__Quote__c quote = new SBQQ__Quote__c(
            Branch__c=branchLocation.id,
            Quote_Name__c = 'Test Quote',
            SBQQ__Account__c = acct.Id,
            Ordered_By__c = [select id from contact limit 1].id,
            Jobsite__c = jobSite.Id,
            SBQQ__DeliveryMethod__c = 'Delivery',
            Start_Date__c = date.valueOf('2022-10-07 12:00:00'),
            End_Date__c = date.valueOf('2022-10-08 8:00:00'),
            Delivery_Date__c = date.valueOf('2022-10-07 12:00:00'),
            Opt_Out_RPP__c = false,
            Opt_Out_Fuel_Charge__c = false,
            Selling_Channel__c = 'SBRB2B',
            //Duration__c = 'Custom',
            SBQQ__SalesRep__c = ersu.Id
        );
        insert quote;
        Cart__c cart = [SELECT Id,Name FROM Cart__c LIMIT 1];
        Adobe_Quote_Template__c template = [SELECT Id FROM Adobe_Quote_Template__c WHERE  Name ='Test Template' LIMIT 1];
        Exception e = null;
        
        Test.startTest();
        SBR_3_0_GeneratePDFDocQuote.loadQuoteFields(quote.Id);
        Test.stopTest(); 
    }

    @isTest
    static void testRetrieveFile() {

        // Set up test data
        String repoId = 'test_repo_id';
        String endPoint = 'https://example.com';
        String authToken = 'test_auth_token';
        String pdfBody = '%PDF test PDF body';

        // Set up HTTPMock
        Test.setMock(HttpCalloutMock.class, new MockClass());
        Test.startTest();
        // Call the method being tested
        SBR_3_0_GeneratePDFDocQuote.RetrieveFile(repoId, endPoint, authToken);
        Test.StopTest();
        // Verify the response
        SBR_3_0_GeneratePDFDocQuote.DocGenRequestWrapper  docGrW=new SBR_3_0_GeneratePDFDocQuote.DocGenRequestWrapper();
        Map<String,Object> mp=new Map<String,Object>();
        docGrW.inputPayload=mp;
        docGrW.templateId='@345ty';
    }

}