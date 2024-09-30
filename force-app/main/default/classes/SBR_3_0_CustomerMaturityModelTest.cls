/*********************************************************************************************************************
* Apex Class: SBR_3_0_CustomerMaturityModelTest
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods: 
* - This Test Calss is created for handeling getting data from API in SBR_3_0_CustomerMaturityModelController class
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
1.0         Saathvik Tulasi      2023-07-09             Initial version 
2.0         Manish Taneja        2023-03-11             Added new methods
********************************************************************************************************************/
@isTest(seeAllData=false) 
public class SBR_3_0_CustomerMaturityModelTest Implements HttpCalloutMock{
    public static String JSON;
    public HTTPResponse respond(HTTPRequest oRequest) {
        HttpResponse oResponse = new HttpResponse();
        oResponse.setHeader('Content-Type',SBR_3_0_Constants.APP_JSON);
        System.debug('oRequest.getEndpoint()'+oRequest.getEndpoint());
        if(oRequest.getEndpoint() == 'callout:Product_Recommendation_Feedback_Callout'){
            System.debug('feedback : '+oRequest.getEndpoint());
            String JSONFeedback = '{"data":{"message":"Feedback created successfully"}}';
            oResponse.setBody(JSONFeedback); 
            oResponse.setStatusCode(201);
        }
        else if(oRequest.getEndpoint().endsWithIgnoreCase('recommendations')){
            System.debug('recommendations : '+oRequest.getEndpoint());
            oResponse.setBody(SBR_3_0_CustomerMaturityModelTest.JSON);
            oResponse.setStatusCode(200);
        }
        else{
            System.debug('token');
            oResponse.setBody('{"token_type":"Bearer","expires_in":900,"access_token":"eyJraWQiOiI1Vk9qbHFHM2RiWktxX0RGQkJ6WEVVV0xWMU1hMGhVMEJhWWE5cm1LRzcwIiwiYWxnIjoiUlMyNTYifQ.eyJ2ZXIiOjEsImp0aSI6IkFULnR4VW1BbS1PZFhLQzNWZVJmLU03ckx0NjBHYVZjRGNSVGE5cnNETk8taTAiLCJpc3MiOiJodHRwczovL2xvZ2lucHJldmlldy5zdW5iZWx0cmVudGFscy5jb20vb2F1dGgyL2F1czFsZjMyMjZ6N1ZwekF0MWQ3IiwiYXVkIjoiaHR0cHM6Ly93d3cuc3VuYmVsdHJlbnRhbHMuY29tL29rdGEvdmVuZG9ycyIsImlhdCI6MTY5MDIwNjY2OSwiZXhwIjoxNjkwMjA3NTY5LCJjaWQiOiIwb2E0NDA0eDJxdmplWmtKcDFkNyIsInNjcCI6WyJNdWxlc29mdCJdLCJzdWIiOiIwb2E0NDA0eDJ","scope":"Mulesoft"}');
            oResponse.setStatusCode(200);
        }
        return oResponse;
    }
    @isTest
    private static void getMaturityModelResponseCredit(){
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_CustomerMaturityModelTest());
        Profile oProfile = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User oRunAsUser = SBR_3_0_TestDataFactory.createUser(FALSE,oProfile);
        oRunAsUser.RepID__c = '123499';
        INSERT oRunAsUser;
        Credential__c oCredential = SBR_3_0_TestDataFactory.createCredential();
        Id CreditRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(SBR_3_0_Constants.ACCOUNT_REC_TYPE_CREDIT).getRecordTypeId();
        List<Account> lAccounts = SBR_3_0_TestDataFactory.createAccounts(1,FALSE,SBR_3_0_Constants.ACCOUNT_REC_TYPE_CREDIT);
        lAccounts[0].AccountNumber = '10096';
        lAccounts[0].RM_Account_Number__c = '10096';
        lAccounts[0].Company_Code__c = '01';
        lAccounts[0].recordTypeId = CreditRecordTypeId;
        lAccounts[0].Lines_of_Business__c = 'EARTH MOVING SOLUTIONS';
        INSERT lAccounts;
        
        Analysis_Region__c oAR = SBR_3_0_TestDataFactory.createAnalysisRegion(FALSE,'934',lAccounts[0].id);
        oAR.Name = 'EARTH MOVING SOLUTIONS';
        INSERT oAR;
        Customer_Spend__c oCS = SBR_3_0_TestDataFactory.createCustomerSpend(FALSE,oAR.id,lAccounts[0].id);
        oCS.Current_TTM_Spend__c = 2000;
        INSERT oCS; 
        String JSONFull = '{"data":{"companyCode":"01","customerId":458628,"products":[{"productRating":1,"productScore":0.55,"productRecordType":1,"catClass":"007-0030","catClassDescription":"20 SINGLE MANLIFT S/P","productCategoryDesc":"ONE MAN DRIVABLE","productLineOfBusiness":"GENERAL TOOL & EQUIPMENT","productLineOfBusinessValue":920,"productRecommendationType":"upSell","productModelVersion":"30.0","productUsedRating":0,"productUsedQty":0},{"productRating":2,"productScore":0.46,"productRecordType":1,"catClass":"107-2018","catClassDescription":"1T PORTABLE HEAT PUMP/AC/DEHU","productCategoryDesc":"COOLING - SPOT COOLER","productLineOfBusiness":"CLIMATE CONTROL DIVISION","productLineOfBusinessValue":934,"productRecommendationType":"upSell","productModelVersion":"30.0","productUsedRating":0,"productUsedQty":0},{"productRating":"0","productScore":0,"productRecordType":"2","catClass":"107-2019","catClassDescription":"AC/DEHU 1.5T W/HEAT","productCategoryDesc":"COOLING - SPOT COOLER","productLineOfBusiness":"CLIMATE CONTROL DIVISION","productLineOfBusinessValue":"934","productRecommendationType":"upSell","productModelVersion":"0.0","productUsedRating":1,"productUsedQty":13}]}}';
        SBR_3_0_CustomerMaturityModelTest.JSON = JSONFull;
        System.runAs(oRunAsUser){
            Test.startTest();
            SBR_3_0_CustomerMaturityModelController.MaturityModelResponse oResults = SBR_3_0_CustomerMaturityModelController.getMaturityModelResponse(lAccounts[0].id);
            Test.stopTest();
            System.debug('oResults'+oResults);
            System.AssertEquals(1,Integer.valueOf(oResults.CurrentLOBUsed));
            System.AssertEquals(FALSE,oResults.isOfficeAccount);
        }
    }
    
    @isTest
    private static void getUpsellProductRecommendationFeedbackValidate(){
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_CustomerMaturityModelTest());
        Profile oProfile = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User oRunAsUser = SBR_3_0_TestDataFactory.createUser(FALSE,oProfile);
        oRunAsUser.RepID__c = '12349';
        INSERT oRunAsUser;
        Credential__c oCredential = SBR_3_0_TestDataFactory.createCredential();
        Id CreditRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Credit').getRecordTypeId();
        List<Account> lAccounts = SBR_3_0_TestDataFactory.createAccounts(1,FALSE,SBR_3_0_Constants.ACCOUNT_REC_TYPE_CREDIT);
        lAccounts[0].AccountNumber = '10097';
        lAccounts[0].RM_Account_Number__c = '10097';
        lAccounts[0].Company_Code__c = '01';
        lAccounts[0].recordTypeId = CreditRecordTypeId;
        lAccounts[0].Lines_of_Business__c = 'EARTH MOVING SOLUTIONS';
        INSERT lAccounts;
        
        Analysis_Region__c oAR = SBR_3_0_TestDataFactory.createAnalysisRegion(FALSE,'934',lAccounts[0].id);
        oAR.Name = 'EARTH MOVING SOLUTIONS';
        INSERT oAR;
        Customer_Spend__c oCS = SBR_3_0_TestDataFactory.createCustomerSpend(FALSE,oAR.id,lAccounts[0].id);
        oCS.Current_TTM_Spend__c = 2000;
        INSERT oCS; 
        String JSONFull = '{"data":{"companyCode":"01","customerId":458628,"products":[{"productRating":1,"productScore":0.55,"productRecordType":1,"catClass":"007-0030","catClassDescription":"20 SINGLE MANLIFT S/P","productCategoryDesc":"ONE MAN DRIVABLE","productLineOfBusiness":"GENERAL TOOL & EQUIPMENT","productLineOfBusinessValue":920,"productRecommendationType":"upSell","productModelVersion":"30.0","productUsedRating":0,"productUsedQty":0},{"productRating":2,"productScore":0.46,"productRecordType":1,"catClass":"107-2018","catClassDescription":"1T PORTABLE HEAT PUMP/AC/DEHU","productCategoryDesc":"COOLING - SPOT COOLER","productLineOfBusiness":"CLIMATE CONTROL DIVISION","productLineOfBusinessValue":934,"productRecommendationType":"upSell","productModelVersion":"30.0","productUsedRating":0,"productUsedQty":0},{"productRating":"0","productScore":0,"productRecordType":"2","catClass":"107-2019","catClassDescription":"AC/DEHU 1.5T W/HEAT","productCategoryDesc":"COOLING - SPOT COOLER","productLineOfBusiness":"CLIMATE CONTROL DIVISION","productLineOfBusinessValue":"934","productRecommendationType":"upSell","productModelVersion":"0.0","productUsedRating":1,"productUsedQty":13}]}}';
        SBR_3_0_CustomerMaturityModelTest.JSON = JSONFull;
        Account NewAccount = 	[	
            SELECT
            Id,
            Company_Code__c,
            RM_Account_Number_Display__c, 
            AccountNumber,
            ParentId,
            RecordtypeId
            FROM
            Account
            WHERE
            Id =: lAccounts[0].id
        ];
        
        Product_Recommendation_Feedback__c oFeedback = new Product_Recommendation_Feedback__c();
        oFeedback.Cat_Class_Key__c = '007-0030';
        oFeedback.Feedback_Type__c = 'bad';
        oFeedback.Name = '007-0030_'+NewAccount.RM_Account_Number_Display__c+'_'+oRunAsUser.RepID__c;
        oFeedback.Model_Version__c = '30.0';
        oFeedback.Description__c = 'Test';
        oFeedback.Category__c = 'Test';
        oFeedback.Additional_comments__c = 'Test';
        oFeedback.Rep_ID__c = oRunAsUser.RepID__c;
        oFeedback.Company_Code__c = Integer.valueOf(NewAccount.Company_Code__c);
        oFeedback.Rep_Type__c = oRunAsUser.Rep_Type__c;
        oFeedback.Account_number__c = NewAccount.RM_Account_Number_Display__c;
        oFeedback.User__c = oRunAsUser.id;
        oFeedback.Account__c= NewAccount.id;
        INSERT oFeedback;
        
        System.runAs(oRunAsUser){
            Test.startTest();
            SBR_3_0_CustomerMaturityModelController.MaturityModelResponse oResults = SBR_3_0_CustomerMaturityModelController.getMaturityModelResponse(lAccounts[0].id);
            Test.stopTest();
            System.debug('oResults'+oResults); 
            System.AssertEquals(1,Integer.valueOf(oResults.CurrentLOBUsed));
            System.AssertEquals(FALSE,oResults.isOfficeAccount);
        }
    }
    
    @isTest
    private static void getCrosssellProductRecommendationFeedbackValidate(){
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_CustomerMaturityModelTest());
        Profile oProfile = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User oRunAsUser = SBR_3_0_TestDataFactory.createUser(FALSE,oProfile);
        oRunAsUser.RepID__c = '12347';
        INSERT oRunAsUser;
        Credential__c oCredential = SBR_3_0_TestDataFactory.createCredential();
        Id CreditRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Credit').getRecordTypeId();
        List<Account> lAccounts = SBR_3_0_TestDataFactory.createAccounts(1,FALSE,SBR_3_0_Constants.ACCOUNT_REC_TYPE_CREDIT);
        lAccounts[0].AccountNumber = '10098';
        lAccounts[0].RM_Account_Number__c = '10098';
        lAccounts[0].Company_Code__c = '01';
        lAccounts[0].recordTypeId = CreditRecordTypeId;
        lAccounts[0].Lines_of_Business__c = 'EARTH MOVING SOLUTIONS';
        INSERT lAccounts;
        
        Analysis_Region__c oAR = SBR_3_0_TestDataFactory.createAnalysisRegion(FALSE,'934',lAccounts[0].id);
        oAR.Name = 'EARTH MOVING SOLUTIONS';
        INSERT oAR;
        Customer_Spend__c oCS = SBR_3_0_TestDataFactory.createCustomerSpend(FALSE,oAR.id,lAccounts[0].id);
        oCS.Current_TTM_Spend__c = 2000;
        INSERT oCS; 
        String JSONFull = '{"data":{"companyCode":"01","customerId":458628,"products":[{"productRating":1,"productScore":0.55,"productRecordType":1,"catClass":"009-0070","catClassDescription":"20 SINGLE MANLIFT S/P","productCategoryDesc":"ONE MAN DRIVABLE","productLineOfBusiness":"GENERAL TOOL & EQUIPMENT","productLineOfBusinessValue":920,"productRecommendationType":"CrossSell","productModelVersion":"30.0","productUsedRating":0,"productUsedQty":0},{"productRating":2,"productScore":0.46,"productRecordType":1,"catClass":"107-2018","catClassDescription":"1T PORTABLE HEAT PUMP/AC/DEHU","productCategoryDesc":"COOLING - SPOT COOLER","productLineOfBusiness":"CLIMATE CONTROL DIVISION","productLineOfBusinessValue":934,"productRecommendationType":"upSell","productModelVersion":"30.0","productUsedRating":0,"productUsedQty":0},{"productRating":"0","productScore":0,"productRecordType":"2","catClass":"107-2019","catClassDescription":"AC/DEHU 1.5T W/HEAT","productCategoryDesc":"COOLING - SPOT COOLER","productLineOfBusiness":"CLIMATE CONTROL DIVISION","productLineOfBusinessValue":"934","productRecommendationType":"upSell","productModelVersion":"0.0","productUsedRating":1,"productUsedQty":13}]}}';
        SBR_3_0_CustomerMaturityModelTest.JSON = JSONFull;
        Account NewAccount = 	[	
            SELECT
            Id,
            Company_Code__c,
            RM_Account_Number_Display__c, 
            AccountNumber,
            ParentId,
            RecordtypeId
            FROM
            Account
            WHERE
            Id =: lAccounts[0].id
        ];
        
        Product_Recommendation_Feedback__c oFeedback2 = new Product_Recommendation_Feedback__c();
        oFeedback2.Cat_Class_Key__c = '009-0070';
        oFeedback2.Feedback_Type__c = 'good';
        oFeedback2.Name = '009-0070_'+'10096'+'_'+oRunAsUser.RepID__c;
        oFeedback2.Model_Version__c = '30.0';
        oFeedback2.Description__c = 'Test';
        oFeedback2.Category__c = 'Test';
        oFeedback2.Additional_comments__c = 'Test';
        oFeedback2.Rep_ID__c = oRunAsUser.RepID__c;
        oFeedback2.Company_Code__c = Integer.valueOf(lAccounts[0].Company_Code__c);
        oFeedback2.Rep_Type__c = oRunAsUser.Rep_Type__c;
        oFeedback2.Account_number__c = '10096';
        oFeedback2.User__c = oRunAsUser.id;
        oFeedback2.Account__c= lAccounts[0].id;
        INSERT oFeedback2;
        
        System.runAs(oRunAsUser){
            Test.startTest();
            Account oAccount = [SELECT Id FROM Account WHERE recordTypeId =: CreditRecordTypeId limit 1];
            SBR_3_0_CustomerMaturityModelController.MaturityModelResponse oResults = SBR_3_0_CustomerMaturityModelController.getMaturityModelResponse(lAccounts[0].id);
            Test.stopTest();
            System.debug('oResults'+oResults);
            System.AssertEquals(1,Integer.valueOf(oResults.CurrentLOBUsed));
            System.AssertEquals(FALSE,oResults.isOfficeAccount);
        }
    }
    
    @isTest
    private static void getMaturityModelResponseOffice(){
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_CustomerMaturityModelTest());
        Profile oProfile = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User oRunAsUser = SBR_3_0_TestDataFactory.createUser(FALSE,oProfile);
        oRunAsUser.RepID__c = '12348';
        INSERT oRunAsUser;
        Credential__c oCredential = SBR_3_0_TestDataFactory.createCredential();
        Id CreditRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Credit').getRecordTypeId();
        List<Account> lAccounts1 = SBR_3_0_TestDataFactory.createAccounts(2,FALSE,SBR_3_0_Constants.ACCOUNT_REC_TYPE_CREDIT);
        lAccounts1[0].AccountNumber = '10099';
        lAccounts1[0].RM_Account_Number__c = '10099';
        lAccounts1[0].Company_Code__c = '01';
        lAccounts1[0].recordTypeId = CreditRecordTypeId;
        lAccounts1[0].Lines_of_Business__c = 'EARTH MOVING SOLUTIONS';
        INSERT lAccounts1;
        Id OfficeRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Office').getRecordTypeId();
        List<Account> lAccounts2 = SBR_3_0_TestDataFactory.createAccounts(1,FALSE,SBR_3_0_Constants.ACCOUNT_REC_TYPE_OFFICE);
        lAccounts2[0].AccountNumber = '10080';
        lAccounts2[0].RM_Account_Number__c = '10080';
        lAccounts2[0].Company_Code__c = '01';
        lAccounts2[0].recordTypeId = OfficeRecordTypeId;
        lAccounts2[0].Lines_of_Business__c = 'EARTH MOVING SOLUTIONS';
        lAccounts2[0].ParentId = lAccounts1[0].Id;
        INSERT lAccounts2;
        
        Analysis_Region__c oAR = SBR_3_0_TestDataFactory.createAnalysisRegion(FALSE,'934',lAccounts2[0].id);
        oAR.Name = 'EARTH MOVING SOLUTIONS';
        INSERT oAR;
        Customer_Spend__c oCS = SBR_3_0_TestDataFactory.createCustomerSpend(FALSE,oAR.id,lAccounts2[0].id);
        oCS.Current_TTM_Spend__c = 2000;
        INSERT oCS; 
        String JSONFull = '{"data":{"companyCode":"01","customerId":458628,"products":[{"productRating":1,"productScore":0.55,"productRecordType":1,"catClass":"007-0030","catClassDescription":"20 SINGLE MANLIFT S/P","productCategoryDesc":"ONE MAN DRIVABLE","productLineOfBusiness":"GENERAL TOOL & EQUIPMENT","productLineOfBusinessValue":920,"productRecommendationType":"upSell","productModelVersion":"30.0","productUsedRating":0,"productUsedQty":0},{"productRating":2,"productScore":0.46,"productRecordType":1,"catClass":"107-2018","catClassDescription":"1T PORTABLE HEAT PUMP/AC/DEHU","productCategoryDesc":"COOLING - SPOT COOLER","productLineOfBusiness":"CLIMATE CONTROL DIVISION","productLineOfBusinessValue":934,"productRecommendationType":"upSell","productModelVersion":"30.0","productUsedRating":0,"productUsedQty":0},{"productRating":"0","productScore":0,"productRecordType":"2","catClass":"107-2019","catClassDescription":"AC/DEHU 1.5T W/HEAT","productCategoryDesc":"COOLING - SPOT COOLER","productLineOfBusiness":"CLIMATE CONTROL DIVISION","productLineOfBusinessValue":"934","productRecommendationType":"upSell","productModelVersion":"0.0","productUsedRating":1,"productUsedQty":13}]}}';
        SBR_3_0_CustomerMaturityModelTest.JSON = JSONFull;
        System.runAs(oRunAsUser){
            Test.startTest();
            try{
                SBR_3_0_CustomerMaturityModelController.MaturityModelResponse oResults = SBR_3_0_CustomerMaturityModelController.getMaturityModelResponse(lAccounts2[0].id);
                System.debug('oResults'+oResults);
                System.AssertEquals(1,Integer.valueOf(oResults.CurrentLOBUsed));
                System.AssertEquals(TRUE,oResults.isOfficeAccount);
            }
            Catch(Exception e){
                
            }
            Test.stopTest();
        }
    }
    
    @isTest
    private static void getMaturityModelResponseCrossSell(){
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_CustomerMaturityModelTest());
        Profile oProfile = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User oRunAsUser = SBR_3_0_TestDataFactory.createUser(FALSE,oProfile);
        oRunAsUser.RepID__c = '123411';
        INSERT oRunAsUser;
        Credential__c oCredential = SBR_3_0_TestDataFactory.createCredential();
        Id CreditRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Credit').getRecordTypeId();
        List<Account> lAccounts = SBR_3_0_TestDataFactory.createAccounts(1,FALSE,SBR_3_0_Constants.ACCOUNT_REC_TYPE_CREDIT);
        lAccounts[0].AccountNumber = '10080';
        lAccounts[0].RM_Account_Number__c = '10081';
        lAccounts[0].Company_Code__c = '01';
        lAccounts[0].recordTypeId = CreditRecordTypeId;
        lAccounts[0].Lines_of_Business__c = 'EARTH MOVING SOLUTIONS';
        INSERT lAccounts;
        
        Analysis_Region__c oAR = SBR_3_0_TestDataFactory.createAnalysisRegion(FALSE,'934',lAccounts[0].id);
        oAR.Name = 'EARTH MOVING SOLUTIONS';
        INSERT oAR;
        Customer_Spend__c oCS = SBR_3_0_TestDataFactory.createCustomerSpend(FALSE,oAR.id,lAccounts[0].id);
        oCS.Current_TTM_Spend__c = 2000;
        INSERT oCS; 
        String JSONFull = '{"data":{"companyCode":"01","customerId":458628,"products":[{"productRating":1,"productScore":0.55,"productRecordType":1,"catClass":"007-0030","catClassDescription":"20 SINGLE MANLIFT S/P","productCategoryDesc":"ONE MAN DRIVABLE","productLineOfBusiness":"GENERAL TOOL & EQUIPMENT","productLineOfBusinessValue":920,"productRecommendationType":"crossSell","productModelVersion":"30.0","productUsedRating":0,"productUsedQty":0},{"productRating":2,"productScore":0.46,"productRecordType":1,"catClass":"107-2018","catClassDescription":"1T PORTABLE HEAT PUMP/AC/DEHU","productCategoryDesc":"COOLING - SPOT COOLER","productLineOfBusiness":"CLIMATE CONTROL DIVISION","productLineOfBusinessValue":934,"productRecommendationType":"upSell","productModelVersion":"30.0","productUsedRating":0,"productUsedQty":0},{"productRating":"0","productScore":0,"productRecordType":"2","catClass":"107-2019","catClassDescription":"AC/DEHU 1.5T W/HEAT","productCategoryDesc":"COOLING - SPOT COOLER","productLineOfBusiness":"CLIMATE CONTROL DIVISION","productLineOfBusinessValue":"934","productRecommendationType":"upSell","productModelVersion":"0.0","productUsedRating":1,"productUsedQty":13}]}}';
        SBR_3_0_CustomerMaturityModelTest.JSON = JSONFull;
        System.runAs(oRunAsUser){
            Test.startTest();
            SBR_3_0_CustomerMaturityModelController.MaturityModelResponse oResults = SBR_3_0_CustomerMaturityModelController.getMaturityModelResponse(lAccounts[0].id);
            System.debug('oResults'+oResults);
            System.AssertEquals(1,Integer.valueOf(oResults.CurrentLOBUsed));
            System.AssertEquals(FALSE,oResults.isOfficeAccount);
            Test.stopTest();
        }
    }
    
    @isTest
    private static void getMaturityModelResponseCreditNoTTM(){
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_CustomerMaturityModelTest());
        Profile oProfile = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User oRunAsUser = SBR_3_0_TestDataFactory.createUser(FALSE,oProfile);
        oRunAsUser.RepID__c = '1234512';
        INSERT oRunAsUser;
        Credential__c oCredential = SBR_3_0_TestDataFactory.createCredential();
        Id CreditRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Credit').getRecordTypeId();
        List<Account> lAccounts = SBR_3_0_TestDataFactory.createAccounts(1,FALSE,SBR_3_0_Constants.ACCOUNT_REC_TYPE_CREDIT);
        lAccounts[0].AccountNumber = '10082';
        lAccounts[0].RM_Account_Number__c = '10082';
        lAccounts[0].Company_Code__c = '01';
        lAccounts[0].recordTypeId = CreditRecordTypeId;
        lAccounts[0].Lines_of_Business__c = 'EARTH MOVING SOLUTIONS';
        INSERT lAccounts;
        
        Analysis_Region__c oAR = SBR_3_0_TestDataFactory.createAnalysisRegion(FALSE,'934',lAccounts[0].id);
        oAR.Name = 'EARTH MOVING SOLUTIONS';
        INSERT oAR;
        Customer_Spend__c oCS = SBR_3_0_TestDataFactory.createCustomerSpend(FALSE,oAR.id,lAccounts[0].id);
        INSERT oCS; 
        String JSONFull = '{"data":{"companyCode":"01","customerId":458628,"products":[{"productRating":1,"productScore":0.55,"productRecordType":1,"catClass":"007-0030","catClassDescription":"20 SINGLE MANLIFT S/P","productCategoryDesc":"ONE MAN DRIVABLE","productLineOfBusiness":"GENERAL TOOL & EQUIPMENT","productLineOfBusinessValue":920,"productRecommendationType":"upSell","productModelVersion":"30.0","productUsedRating":0,"productUsedQty":0},{"productRating":2,"productScore":0.46,"productRecordType":1,"catClass":"107-2018","catClassDescription":"1T PORTABLE HEAT PUMP/AC/DEHU","productCategoryDesc":"COOLING - SPOT COOLER","productLineOfBusiness":"CLIMATE CONTROL DIVISION","productLineOfBusinessValue":934,"productRecommendationType":"upSell","productModelVersion":"30.0","productUsedRating":0,"productUsedQty":0},{"productRating":"0","productScore":0,"productRecordType":"2","catClass":"107-2019","catClassDescription":"AC/DEHU 1.5T W/HEAT","productCategoryDesc":"COOLING - SPOT COOLER","productLineOfBusiness":"CLIMATE CONTROL DIVISION","productLineOfBusinessValue":"934","productRecommendationType":"upSell","productModelVersion":"0.0","productUsedRating":1,"productUsedQty":13}]}}';
        SBR_3_0_CustomerMaturityModelTest.JSON = JSONFull;
        System.runAs(oRunAsUser){
            Test.startTest();
            try{
                SBR_3_0_CustomerMaturityModelController.MaturityModelResponse oResults = SBR_3_0_CustomerMaturityModelController.getMaturityModelResponse(lAccounts[0].id);
                System.debug('oResults'+oResults);
                System.AssertEquals(1,Integer.valueOf(oResults.CurrentLOBUsed));
                System.AssertEquals(FALSE,oResults.isOfficeAccount);
            }
            Catch(Exception e){
            }
            Test.stopTest();
        }
    }
    
    @isTest
    private static void getMaturityModelResponseCreditNotFound(){
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_CustomerMaturityModelTest());
        Profile oProfile = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User oRunAsUser = SBR_3_0_TestDataFactory.createUser(FALSE,oProfile);
        oRunAsUser.RepID__c = '12346';
        INSERT oRunAsUser;
        Credential__c oCredential = SBR_3_0_TestDataFactory.createCredential();
        Id CreditRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Credit').getRecordTypeId();
        List<Account> lAccounts = SBR_3_0_TestDataFactory.createAccounts(1,FALSE,SBR_3_0_Constants.ACCOUNT_REC_TYPE_CREDIT);
        lAccounts[0].AccountNumber = '10083';
        lAccounts[0].RM_Account_Number__c = '10083';
        lAccounts[0].Company_Code__c = '01';
        lAccounts[0].recordTypeId = CreditRecordTypeId;
        lAccounts[0].Lines_of_Business__c = 'EARTH MOVING SOLUTIONS';
        INSERT lAccounts;
        
        Analysis_Region__c oAR = SBR_3_0_TestDataFactory.createAnalysisRegion(FALSE,'930',lAccounts[0].id);
        oAR.Name = 'EARTH MOVING SOLUTIONS';
        INSERT oAR;
        Customer_Spend__c oCS = SBR_3_0_TestDataFactory.createCustomerSpend(FALSE,oAR.id,lAccounts[0].id);
        oCS.Current_TTM_Spend__c = 2000;
        INSERT oCS; 
        // update recomendation start
       // User oRunAsUser = SBR_3_0_TestDataFactory.createUser(FALSE,oProfile);
       // oRunAsUser.RepID__c = '123410';
       // INSERT oRunAsUser;
        Account oAccount = 	[	
            SELECT
            Id,
            Company_Code__c,
            RM_Account_Number_Display__c, 
            AccountNumber,
            ParentId,
            RecordtypeId
            FROM
            Account
            WHERE
            Id =: lAccounts[0].id
        ];
        System.debug('oAccount'+oAccount);  
        Product_Recommendation_Feedback__c oFeedback = new Product_Recommendation_Feedback__c();
        oFeedback.Cat_Class_Key__c = '007-0030';
        oFeedback.Feedback_Type__c = 'good';
        oFeedback.Name = '007-0030_'+oAccount.RM_Account_Number_Display__c+'_'+oRunAsUser.RepID__c;
        oFeedback.Model_Version__c = '28.0';
        oFeedback.Description__c = 'Test';
        oFeedback.Category__c = 'Test';
        oFeedback.Additional_comments__c = 'Test';
        oFeedback.Rep_ID__c = oRunAsUser.RepID__c;
        oFeedback.Company_Code__c = Integer.valueOf(oAccount.Company_Code__c);
        oFeedback.Rep_Type__c = oRunAsUser.Rep_Type__c;
        oFeedback.Account_number__c = oAccount.RM_Account_Number_Display__c;
        oFeedback.User__c = oRunAsUser.id;
        oFeedback.Account__c= oAccount.id;
        INSERT oFeedback;
 		// update recomendation stop 
        String JSONFull = '{"data":{"companyCode":"01","customerId":458628,"products":[{"productRating":1,"productScore":0.55,"productRecordType":1,"catClass":"007-0030","catClassDescription":"20 SINGLE MANLIFT S/P","productCategoryDesc":"ONE MAN DRIVABLE","productLineOfBusiness":"GENERAL TOOL & EQUIPMENT","productLineOfBusinessValue":920,"productRecommendationType":"upSell","productModelVersion":"30.0","productUsedRating":0,"productUsedQty":0},{"productRating":2,"productScore":0.46,"productRecordType":1,"catClass":"107-2018","catClassDescription":"1T PORTABLE HEAT PUMP/AC/DEHU","productCategoryDesc":"COOLING - SPOT COOLER","productLineOfBusiness":"CLIMATE CONTROL DIVISION","productLineOfBusinessValue":934,"productRecommendationType":"upSell","productModelVersion":"30.0","productUsedRating":0,"productUsedQty":0},{"productRating":"0","productScore":0,"productRecordType":"2","catClass":"107-2019","catClassDescription":"AC/DEHU 1.5T W/HEAT","productCategoryDesc":"COOLING - SPOT COOLER","productLineOfBusiness":"CLIMATE CONTROL DIVISION","productLineOfBusinessValue":"934","productRecommendationType":"upSell","productModelVersion":"0.0","productUsedRating":1,"productUsedQty":13}]}}';
        SBR_3_0_CustomerMaturityModelTest.JSON = JSONFull;
        System.runAs(oRunAsUser){
            Test.startTest();
            SBR_3_0_CustomerMaturityModelController.MaturityModelResponse oResults = SBR_3_0_CustomerMaturityModelController.getMaturityModelResponse(lAccounts[0].id);
            System.debug('oResults'+oResults);
            System.AssertEquals(1,Integer.valueOf(oResults.CurrentLOBUsed));
            System.AssertEquals(FALSE,oResults.isOfficeAccount);
 			// update recomendation start
 			list<String> lRecommendations = new list<String>();
            lRecommendations.add('{"name":"007-0030","id":"Upsell","state":"dislike","version":"30.0"}');
            lRecommendations.add('{"name":"107-2018","id":"Upsell","state":"like","version":"30.0"}');
            try
            {
            Boolean isInserted = SBR_3_0_CustomerMaturityModelController.updateRecommendations(lRecommendations,'Test',oAccount);
 			// update recomendation stop
            }
            catch(exception e)
            {
            }     
            Test.stopTest();
        }
    }
    /************************************************************* Cover updateRecommendations Starts*************************************************************/
    public Static testMethod void updateRecommendations(){
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_CustomerMaturityModelTest());
        Profile oProfile = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        Credential__c oCredential = SBR_3_0_TestDataFactory.createCredential();
        Id CreditRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Credit').getRecordTypeId();
        List<Account> lAccounts = SBR_3_0_TestDataFactory.createAccounts(1,FALSE,SBR_3_0_Constants.ACCOUNT_REC_TYPE_CREDIT);
        lAccounts[0].AccountNumber = '10096';
        lAccounts[0].RM_Account_Number__c = '10096';
        lAccounts[0].Company_Code__c = '01';
        lAccounts[0].recordTypeId = CreditRecordTypeId;
        INSERT lAccounts;
        User oRunAsUser = SBR_3_0_TestDataFactory.createUser(FALSE,oProfile);
        oRunAsUser.RepID__c = '123410';
        INSERT oRunAsUser;
        Account oAccount = 	[	
            SELECT
            Id,
            Company_Code__c,
            RM_Account_Number_Display__c, 
            AccountNumber,
            ParentId,
            RecordtypeId
            FROM
            Account
            WHERE
            Id =: lAccounts[0].id
        ];
        System.debug('oAccount'+oAccount);  
        Product_Recommendation_Feedback__c oFeedback = new Product_Recommendation_Feedback__c();
        oFeedback.Cat_Class_Key__c = '007-0030';
        oFeedback.Feedback_Type__c = 'good';
        oFeedback.Name = '007-0030_'+oAccount.RM_Account_Number_Display__c+'_'+oRunAsUser.RepID__c;
        oFeedback.Model_Version__c = '28.0';
        oFeedback.Description__c = 'Test';
        oFeedback.Category__c = 'Test';
        oFeedback.Additional_comments__c = 'Test';
        oFeedback.Rep_ID__c = oRunAsUser.RepID__c;
        oFeedback.Company_Code__c = Integer.valueOf(oAccount.Company_Code__c);
        oFeedback.Rep_Type__c = oRunAsUser.Rep_Type__c;
        oFeedback.Account_number__c = oAccount.RM_Account_Number_Display__c;
        oFeedback.User__c = oRunAsUser.id;
        oFeedback.Account__c= oAccount.id;
        INSERT oFeedback;
        
        System.runAs(oRunAsUser){
            Test.startTest();
            list<String> lRecommendations = new list<String>();
            lRecommendations.add('{"name":"007-0030","id":"Upsell","state":"dislike","version":"30.0"}');
            lRecommendations.add('{"name":"107-2018","id":"Upsell","state":"like","version":"30.0"}');
            try
            {
            Boolean isInserted = SBR_3_0_CustomerMaturityModelController.updateRecommendations(lRecommendations,'Test',oAccount);
            System.AssertEquals(TRUE,isInserted);
            }
            catch(exception e)
            {              
            }
            Test.stopTest();
        }
    }
    /************************************************************* Cover updateRecommendations Ends*************************************************************/
    /************************************************************* Cover getCustomMetadataResponse Starts*************************************************************/
    public Static testMethod void getCustomMetadataResponse(){
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_CustomerMaturityModelTest());
        Profile oProfile = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User oRunAsUser = SBR_3_0_TestDataFactory.createUser(TRUE,oProfile);
        System.runAs(oRunAsUser){
            Test.startTest();
            list<String> lRecommendations = new list<String>();
            Map<String,SBR_3_0_Customer_Maturity_Model_Labels__mdt> mLabels = SBR_3_0_CustomerMaturityModelController.getCustomMetadataResponse();
            System.AssertNotEquals(NULL,mLabels);
            Test.stopTest();
        }
    }
    /************************************************************* Cover getCustomMetadataResponse Ends*************************************************************/
}