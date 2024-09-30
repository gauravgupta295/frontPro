@isTest
public class SBR_3_0_API_Web_Jobsite_Test implements HttpCalloutMock {
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

        createUser();

        Account relatedAccount = new Account();
        relatedAccount.RM_Account_Number__c = 'X-12345';
        relatedAccount.Name = SBR_3_0_API_Web_Jobsite_DA.JOBSITEACCOUNTNAME;
        relatedAccount.BillingStreet = '123 Main Street';
        relatedAccount.BillingCity = 'Toronto';
        relatedAccount.BillingPostalCode = 'M9N7V5';
        relatedAccount.BillingState = 'ON';
        relatedAccount.BillingCountry = 'CA';
        relatedAccount.phone = '0434675678';
        insert relatedAccount;

        Schema.Location branchLocation = new Schema.Location();
        branchLocation.Branch_Location_Number__c = '1234';
        branchLocation.Name = 'Test Branch Location';
        branchLocation.Street_Address__c = '12 Main Street';
        branchLocation.City__c = 'Toronto';
        branchLocation.Zip_Code__c = 'M7N7B3';
        branchLocation.State__c = 'ON';
        branchLocation.Country__c = 'CA';
        branchLocation.Job_Number__c='332112';
        branchLocation.RecordTypeId = SBR_3_0_Constants.LOCATION_JOB_RT_ID;
        branchLocation.Company_Code__c = 'X';
        insert branchLocation;
        
        Schema.Location branchLocation1 = new Schema.Location();
        branchLocation1.Branch_Location_Number__c = '1234';
        branchLocation1.Name = 'Test Branch Location';
        branchLocation1.Street_Address__c = '12 Main Street';
        branchLocation1.City__c = 'Toronto';
        branchLocation1.Zip_Code__c = 'M7N7B3';
        branchLocation1.State__c = 'ON';
        branchLocation1.Country__c = 'CA';
        branchLocation1.Job_Number__c='332112';
        branchLocation1.RecordTypeId = SBR_3_0_Constants.LOCATION_BRANCH_RT_ID;
        branchLocation1.Company_Code__c = 'X';
        insert branchLocation1;
        
       // SBR_3_0_TestDataFactory.createCredentials(1, true);
        Credential__c c = new Credential__c();
            c.Name = 'Mule_Token_Endpoint';
            c.Environment__c = SBR_3_0_Constants.SANDBOX;
            c.Key_Id__c = 'Mule_Token_Endpoint';
            insert c;
        //Mule_Token_Endpoint
    }

    // Test if API Provided empty company code
    @isTest
    static void testWebJobSiteApiWithEmptyCompanyCode(){
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_Web_Jobsite_Test());
        Test.startTest();
        RestRequest request = new RestRequest();
        request.requestUri = 'https://yourInstance.salesforce.com/services/JobSite/ApiCreate/v1';
        request.httpMethod = 'POST';
        // jSiteWrapper.jobSiteDetailsJson = '{ "Within_City_Limits__c": "Yes", "Job_Number__c: "23112312", "Use__c":"true", "Source_Code__c": "test", "Fax_Phone_Number__c": "1231231234", "Daily_Divisor__c": "12", "Customer_Ref1__c": "test", "Lien_Date__c":"05/03/2022" }';
        request.addHeader('Content-Type', 'application/json');
        String json = '{'+
		'	\"branchNumber\": \"1234\",'+
        '	\"jobLocationName\": \"test\",'+
		'	\"rmAccountNumber\": \"12345\",'+
        '	\"jobSiteId\": \"12346\",'+
        '	\"address\": {'+
        '           \"city\":\"Toronto\",'+
        '      		\"country\":\"CA\",'+
        '      		\"state\":\"ON\",'+
        '      		\"street1\":\"test\",'+
        '       	\"zip\":\"M7N7B3\"'+
        '},'+
		'	\"data\": {'+
		'		\"Company_Code__c\": \"\"'+
		'	}'+	
		'}';
        request.requestBody = Blob.valueOf(json);
        //request.requestBody = Blob.valueOf(JSON.serialize(jSiteWrapper) + ', "data": {"Company_Code__c": "X"}}');
        RestContext.request = request;
        system.debug('test request' + request);

       // String response = SBR_3_0_API_Web_Jobsite.createJobSite();
        try {
               SBR_3_0_API_Web_Jobsite.createJobSite();        
            }
        catch (Exception e) {
            System.debug('exc from test : ' + e.getMessage());
        }
        //system.assertEquals('{"status":"Success","message":"Jobsite Created"}', response, 'Jobsite API did not return Success!');
        List<Exception_Log__c> exc = new List<Exception_Log__c>();
		exc = [Select Id,Exception_Message__c from Exception_Log__c];
        System.debug('exc from SOQL : ' + exc);
        system.assert(exc[0].Exception_Message__c.contains('Related Branch not found!'), 'Test Failed for Empty Address');

        Test.stopTest();
    }

    // Test if API Provided invalid jobSiteId
    @isTest
    static void testWebJobSiteApiWithEmptyJobSiteId(){
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_Web_Jobsite_Test());
        Test.startTest();

        RestRequest request = new RestRequest();
        request.requestUri = 'https://yourInstance.salesforce.com/services/JobSite/ApiCreate/v1/';
        request.httpMethod = 'POST';
        // jSiteWrapper.jobSiteDetailsJson = '{ "Within_City_Limits__c": "Yes", "Job_Number__c: "23112312", "Use__c":"true", "Source_Code__c": "test", "Fax_Phone_Number__c": "1231231234", "Daily_Divisor__c": "12", "Customer_Ref1__c": "test", "Lien_Date__c":"05/03/2022" }';
        request.addHeader('Content-Type', 'application/json');
        String json = '{'+
		'	\"branchNumber\": \"1234\",'+
        '	\"salesRepId\": \"\",'+
        '	\"jobLocationName\": \"test\",'+
		'	\"rmAccountNumber\": \"12345\",'+
        '	\"jobSiteId\": \"\",'+
        '	\"address\": {'+
        '           \"city\":\"Toronto\",'+
        '      		\"country\":\"CA\",'+
        '      		\"state\":\"ON\",'+
        '      		\"street1\":\"test\",'+
        '       	\"zip\":\"M7N7B3\"'+
        '},'+
		'	\"data\": {'+
		'		\"Company_Code__c\": \"X\",'+
        '		\"Job_Number__c\": \"23112312\"'+
		'	}'+	
		'}';
        request.requestBody = Blob.valueOf(json);
        //request.requestBody = Blob.valueOf(JSON.serialize(jSiteWrapper) + ', "data": {"Company_Code__c": "X"}}');
        RestContext.request = request;
        system.debug('test request' + request);

        try {
             SBR_3_0_API_Web_Jobsite.createJobSite();
            }
        catch (Exception e) {
        }
        List<Exception_Log__c> exc = new List<Exception_Log__c>();
		exc = [Select Id,Exception_Message__c from Exception_Log__c];
        system.assert(exc[0].Exception_Message__c.contains('Job_Site_Id__c not specified'), 'Jobsite API did not return Success!');
        Test.stopTest();
    }

    @isTest static void testSuccess(){
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_Web_Jobsite_Test());
        Test.startTest();
        RestRequest request = new RestRequest();
        request.requestUri = 'https://yourInstance.salesforce.com/services/JobSite/ApiCreate/v1/abc';
        request.httpMethod = 'POST';
        // jSiteWrapper.jobSiteDetailsJson = '{ "Within_City_Limits__c": "Yes", "Job_Number__c: "23112312", "Use__c":"true", "Source_Code__c": "test", "Fax_Phone_Number__c": "1231231234", "Daily_Divisor__c": "12", "Customer_Ref1__c": "test", "Lien_Date__c":"05/03/2022" }';
        request.addHeader('Content-Type', 'application/json');
        //[]\\\request.requestBody = Blob.valueOf(JSON.serialize(jSiteWrapper) + ', "data": {"Company_Code__c": "X", "Job_Number__c": 8675309}}');
         
        String json = '{'+
		'	\"branchNumber\": \"1234\",'+
        '	\"salesRepId\": \"12346\",'+
        '	\"jobLocationName\": \"test\",'+
		'	\"rmAccountNumber\": \"12345\",'+
        '	\"jobSiteId\": \"1234\",'+
        '	\"address\": {'+
        '           \"city\":\"Toronto\",'+
        '      		\"country\":\"CA\",'+
        '      		\"state\":\"ON\",'+
        '      		\"street1\":\"test\",'+
        '       	\"zip\":\"M7N7B3\"'+
        '},'+
		'	\"data\": {'+
		'		\"Company_Code__c\": \"X\",'+
        '		\"Job_Number__c\": \"23112312\"'+
		'	}'+	
		'}';
        request.requestBody = Blob.valueOf(json);
        RestContext.request = request;
        system.debug('test request' + request);

       // String response = SBR_3_0_API_Web_Jobsite.createJobSite();
       
        try {
             	SBR_3_0_API_Web_Jobsite.createJobSite();
            	
            }
        catch (Exception e) {

            //system.assertEquals('Related Sales Rep not found!', e.getMessage(), 'Jobsite API did not return Success!');
           // system.assertEquals('{"status":"Success","message":"Jobsite Created"}', e.getMessage(), 'Jobsite API did not return Success!');
        }
        List<Exception_Log__c> exc = new List<Exception_Log__c>();
		exc = [Select Id,Exception_Message__c from Exception_Log__c];
	    system.assertEquals(0, exc.size(), 'Jobsite API did not return Success!');

        Test.stopTest();
    }

     @isTest
     static void testWebJobSiteApiWithEmptyBranch(){
         Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_Web_Jobsite_Test());
         Test.startTest();
        RestRequest request = new RestRequest();
        request.requestUri = 'https://yourInstance.salesforce.com/services/JobSite/ApiCreate/v1/';
         request.httpMethod = 'POST';
         request.addHeader('Content-Type', 'application/json');
         String json = '{'+
		'	\"branchNumber\": \"\",'+
        '	\"salesRepId\": \"12346\",'+
        '	\"jobLocationName\": \"test\",'+
		'	\"rmAccountNumber\": \"12345\",'+
        '	\"jobSiteId\": \"1234\",'+
        '	\"address\": {'+
        '           \"city\":\"Toronto\",'+
        '      		\"country\":\"CA\",'+
        '      		\"state\":\"ON\",'+
        '      		\"street1\":\"test\",'+
        '       	\"zip\":\"M7N7B3\"'+
        '},'+
		'	\"data\": {'+
		'		\"Company_Code__c\": \"X\",'+
        '		\"Job_Number__c\": \"23112312\"'+
		'	}'+	
		'}';
         request.requestBody = Blob.valueOf(json);
         //request.requestBody = Blob.valueOf(JSON.serialize(jSiteWrapper) + ',"data": {"Company_Code__c": "X", "Job_Number__c": 8675309}}');
         RestContext.request = request;
         try{
             SBR_3_0_API_Web_Jobsite.createJobSite();
         } catch(Exception ex){
             system.assert(ex.getMessage().contains('Cannot find/create job location'), 'Test Failed for Empty Address');
         }
         List<Exception_Log__c> exc = [Select Id,Exception_Message__c from Exception_Log__c];  
         
         system.assert(exc[0].Exception_Message__c.contains('Related Branch not found!'), 'Test Failed for Empty Address');
         Test.stopTest();
     }
    @future
    static void createUser() {
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
    }
}