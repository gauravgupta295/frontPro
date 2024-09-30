/*********************************************************************************************************************
* Apex Class: SBR_3_0_DamageEstimatorSelectiveTest
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Test class of SBR_3_0_DamageEstimatorSelective
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Meghna Vijay          2023-01-18            Initial version   
*********************************************************************************************************************/

@isTest
public with sharing class SBR_3_0_DamageEstimatorSelectiveTest implements HttpCalloutMock {

    public HTTPResponse respond(HTTPRequest req) {
        HTTPResponse res=new HTTPResponse();
        res.setHeader('Content-Type',SBR_3_0_Constants.APP_JSON);
        if(req.getEndpoint().endsWithIgnoreCase('token')){
            res.setBody('{"access_token":"test"}');
            res.setStatusCode(200);
        }else if(req.getEndpoint().endsWithIgnoreCase('insideLabor')){
            res.setBody(		'{'+
                        '  "workOrderNumber": 86684649,'+
                        '  "mode": "U",'+
                        '  "message": "Work Order processed successfully",'+
                        '  "workOrderLineItems": [ { "rmLineNumber": 9999, "rmUniqueId": 12345678911, "referenceLineNumber": "" } ]'+
                        '}');
            res.setStatusCode(200);
        }else {
            res.setBody(		'{'+
                        '  "errors": {'+
                        '    "ind": true,'+
                        '    "code": "WOCRTT2000",'+
                        '    "text": "Invalid claim type entered. Valid types are N, D, M, or S..",'+
                        '    "reference": "1496"'+
                        '  }'+
                        '}');
            res.setStatusCode(400);
        }
        return res;
    }
    @TestSetup
    static void createTestData(){

        insert new Bypass_Settings__c(SetupOwnerId=UserInfo.getUserId(), Bypass_Flow__c=true);
        Credential__c cred = SBR_3_0_TestDataFactory.createCredentials(1, false)[0];
        cred.Name = 'Mule_Token_Endpoint';
        cred.Key_Id__c = 'testKey123';
        cred.Secret__c = 'secret';
        insert cred;

        // Perform DML operations on setup objects within System.runAs()
        System.runAs(new User(Id = UserInfo.getUserId())) {
            //Create User
            User newServiceResourceUser =  SBR_3_0_ServiceTestDataFactory.createServiceResourceUser(true,'1234','78923');
            
            // Create Sales rep User 
            User newSalesRepUser = SBR_3_0_ServiceTestDataFactory.createSalesRepUser(true,'111222');
            
        }

        //Create Service Resource 
        ServiceResource testSR = SBR_3_0_ServiceTestDataFactory.create_Service_Resource(false);
        User testSalesRepUser = [Select Id,Name from User where UserName LIKE 'SRTestUser%' ];
        testSR.ResourceType = 'T';
        testSR.RelatedRecordId = testSalesRepUser.Id;
        insert testSR;
        //Create assert 
        Asset testAsrt =  SBR_3_0_ServiceTestDataFactory.createAsset(true);
        
        //Create Account 
        Account testAcc =  SBR_3_0_ServiceTestDataFactory.createAccount(false,'33333');
        insert testAcc;

        //Create Service Territory 
        ServiceTerritory  testST = SBR_3_0_ServiceTestDataFactory.createServiceTerritory(true);

        //Get Sales Rep user 
        User testSalesRep = [Select Id,Name from User where UserName LIKE 'SalesRepUser%' ];

        //Create Exponce to Location
        ServiceTerritory  testE2Loc = SBR_3_0_ServiceTestDataFactory.createServiceTerritory(true);

        WorkOrder testWO = SBR_3_0_ServiceTestDataFactory.createWorkOrder(false);
        testWO.AccountId = testAcc.id;
        testWO.AssetId = testAsrt.id;
        testWO.ServiceTerritoryId  = testST.id;
        testWO.SF_PS_Expense_To_Location__c = testE2Loc.id;
        testWO.SF_PS_Service_Resource__c = testSR.id;
        testWO.SF_PS_Work_Order_Des__c = 'DAMAGE - RPP CLAIM';
        testWO.SF_PS_Claim_Type__c = 'D';
        testWO.SF_PS_Complaint__c = 'Test complaint';
        testWO.SF_PS_BillCustOrLoc__c = 'L';
        testWO.SF_PS_ExpenseCode__c = 'DRPP';
        insert testWO;

        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_CreateWorkOrderTest());

        SF_PS_Damage_Estimator__c testDamageEstimator = SBR_3_0_ServiceTestDataFactory.createDamageEstimatorRecord(testWO.Id,true);

    }

    @isTest
    static void testGetDamageEstimatorByIdSet() {
        SF_PS_Damage_Estimator__c testDamageEstimatorRec = [SELECT Id FROM SF_PS_Damage_Estimator__c LIMIT 1];
        Test.startTest();
        SF_PS_Damage_Estimator__c retrievedDamageEstimatorRec = 
        SBR_3_0_DamageEstimatorSelective.getDamageEstimatorById(testDamageEstimatorRec.Id);
        System.assertEquals(retrievedDamageEstimatorRec != null, true, 'Damage estimator record is not null');
        Test.stopTest();
    }
}