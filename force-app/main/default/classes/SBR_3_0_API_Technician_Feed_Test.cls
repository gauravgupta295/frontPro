/*********************************************************************************************************************
* Apex Class: SBR_3_0_API_Technician_Feed_Test
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose:
* - This is the Test Calss for the SBR_3_0_API_Technician_Feed Class
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Mayank Jain 			2023-04-28			Initial version  
*********************************************************************************************************************/
@isTest
public with sharing class SBR_3_0_API_Technician_Feed_Test implements HttpCalloutMock  {
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
        //Create Test User
        User testUser = SBR_3_0_ServiceTestDataFactory.createServiceResourceUser(true,'1234','9999');
    }

    //Success Test for the Updation Of the Service Resource from Payload Json
    @isTest
    static void testupdateServiceResource(){
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/ServiceResource/ApiUpdateResource/v1/*';
        req.httpMethod = 'POST';
        String jsonString = '{ "EventType": "1","SF_PS_Company_Code__c": "01","Name": "Test Resouce","SF_PS_Hourly_Billing_Rate__c": 15.0,"SF_PS_Hourly_Internal_Rate__c": 15.0,"SF_PS_Overtime_Billing_Rate__c": 15.0,"SF_PS_Overtime_Internal_Rate__c": 15.0,"SF_PS_Labor_Type__c": "I","SF_PS_Type__c": "D","IsActive": true,"SF_PS_Branch_Loc_Num__c": "6666","SF_PS_Start_Date__c": "2023-02-22","SF_PS_RM_Created_DateTime__c": "2023-02-22T09:45:00Z","SF_PS_RM_Created_By__c": "Test User","SF_PS_RM_Update_DateTime__c": "2023-02-22T09:45:00Z","SF_PS_RM_Updated_By_User__c": "Test User","SF_PS_Mechanic_Id__c": "9999","SF_PS_Comments__c": "Yes api" }';
        req.requestBody = Blob.valueOf(jsonString);
        
        RestContext.request = req;
        RestContext.response= res;

        
        Test.startTest();
        ServiceResource testFactorySR = SBR_3_0_ServiceTestDataFactory.create_Service_Resource(False);
        User testUser = [Select Id,Name from User where UserName LIKE 'SRTestUser%' ];
        testFactorySR.RelatedRecordId = testUser.Id;
        insert testFactorySR;

        try {
            SBR_3_0_API_Technician_Feed.updateServiceResource();
            system.debug('test res 2nd' + res);
        }Catch (Exception e) {
            System.debug('An Error Occur | ' + e);
        }    
        Test.stopTest();
    }

    //Falier Test for the Updation Of the Wrong Service Resource from Payload Json
    @isTest
    static void testupdateServiceResourceNOSR(){
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/ServiceResource/ApiUpdateResource/v1/*';
        req.httpMethod = 'POST';
        //giving Wrong MechId for the NOSR
        String jsonString = '{ "EventType": "1","SF_PS_Company_Code__c": "01","Name": "Test Resouce","SF_PS_Hourly_Billing_Rate__c": 15.0,"SF_PS_Hourly_Internal_Rate__c": 15.0,"SF_PS_Overtime_Billing_Rate__c": 15.0,"SF_PS_Overtime_Internal_Rate__c": 15.0,"SF_PS_Labor_Type__c": "I","SF_PS_Type__c": "D","IsActive": true,"SF_PS_Branch_Loc_Num__c": "6666","SF_PS_Start_Date__c": "2023-02-22","SF_PS_RM_Created_DateTime__c": "2023-02-22T09:45:00Z","SF_PS_RM_Created_By__c": "Test User","SF_PS_RM_Update_DateTime__c": "2023-02-22T09:45:00Z","SF_PS_RM_Updated_By_User__c": "Test User","SF_PS_Mechanic_Id__c": "0011","SF_PS_Comments__c": "Yes api" }';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf(jsonString);
        
        RestContext.request = req;
        RestContext.response= res;


        Test.startTest();
        ServiceResource testFactorySR = SBR_3_0_ServiceTestDataFactory.create_Service_Resource(False);
        User testUser = [Select Id,Name from User where UserName LIKE 'SRTestUser%' ];
        testFactorySR.RelatedRecordId = testUser.Id;
        insert testFactorySR;
        try {
            SBR_3_0_API_Technician_Feed.updateServiceResource();
        }Catch (Exception e) {
            System.debug('An Error Occur | ' + e);
        }    
        Test.stopTest();
    }
    //Falier Test for the Updation Of the Service Resource from Incorrect Payload Json
    @isTest
    static void testupdateServiceResourceFALIER(){
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/ServiceResource/ApiUpdateResource/v1/*';
        req.httpMethod = 'POST';
        //Creating a wrong Json for the Test Falier
        String jsonString = '{ "EventType": "1","SF_PS_Company_Code__c": "01","Name": "Test Resouce","SF_PS_Hourly_Billing_Rate__c": 15.0,"SF_PS_Hourly_Internal_Rate__c": 15.0,"SF_PS_Overtime_Billing_Rate__c": 15.0,"SF_PS_Overtime_Internal_Rate__c": 15.0,"SF_PS_Labor_Type__c": "I","SF_PS_Type__c": "D","IsActive": True,"SF_PS_Branch_Loc_Num__c": "6666","SF_PS_Start_Date__c": "2023-02-22","SF_PS_RM_Created_DateTime__c": "2023-02-22T09:45:00Z","SF_PS_RM_Created_By__c": "Test User","SF_PS_RM_Update_DateTime__c": "2023-02-22T09:45:00Z","SF_PS_RM_Updated_By_User__c": "Test User","SF_PS_Mechanic_Id__c": "12344","SF_PS_Comments__c": "Yes api" }';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf(jsonString);
        
        RestContext.request = req;
        RestContext.response= res;


        Test.startTest();
        ServiceResource testFactorySR = SBR_3_0_ServiceTestDataFactory.create_Service_Resource(False);
        User testUser = [Select Id,Name from User where UserName LIKE 'SRTestUser%' ];
        testFactorySR.RelatedRecordId = testUser.Id;
        insert testFactorySR;
        try {
            SBR_3_0_API_Technician_Feed.updateServiceResource();
        }Catch (Exception e) {
            System.debug('An Error Occur | ' + e);
        }    
        Test.stopTest();
        
    }

   
}