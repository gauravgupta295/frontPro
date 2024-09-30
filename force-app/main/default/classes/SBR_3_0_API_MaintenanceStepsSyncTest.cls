@isTest
public class SBR_3_0_API_MaintenanceStepsSyncTest implements HttpCalloutMock{
    @TestSetup
    static void makeData(){

        User testSRUser =  SBR_3_0_ServiceTestDataFactory.createServiceResourceUser(true,'1234','78923');
        System.debug('testSRUser --- ' + testSRUser);
        
        // Create Sales rep User 
        User TestSalesRep = SBR_3_0_ServiceTestDataFactory.createSalesRepUser(true,'111222');

        //Create Owner User 
        //Create Owner
        User TestOwnerUser = SBR_3_0_ServiceTestDataFactory.createOwnerUser(true, '1234','7777');

    }
    
    @isTest
    static void syncMaintenanceStepsToRMTest(){
        Credential__c cred = SBR_3_0_TestDataFactory.createCredentials(1, false)[0];
        cred.Name = 'Mule_Token_Endpoint';
        cred.Key_Id__c = 'testKey123';
        cred.Secret__c = 'secret';
        insert cred;
        //Create Service Resource 
        ServiceResource testSR = SBR_3_0_ServiceTestDataFactory.create_Service_Resource(False);
        User testUser = [Select Id,Name from User where UserName LIKE 'SRTestUser%' ];
        testSR.ResourceType = 'T';
        testSR.RelatedRecordId = testUser.Id;
        insert testSR;

        //Create assert 
        Asset testAsrt =  SBR_3_0_ServiceTestDataFactory.createAsset(true);
        List<Asset> testASSERT1 = [
            SELECT ID, Name ,SM_PS_Asset_Id__c
            FROM Asset 
            WHERE id =: testAsrt.id LIMIT 1];
        system.debug('---111-----'+ testASSERT1[0]);


        //Create Account 
        Account testAcc =  SBR_3_0_ServiceTestDataFactory.createAccount(false,'33333');
        insert testAcc;
        system.debug('account in Test Calss is --' + testAcc );

        List<Account> relAccts = [
            SELECT ID, Name
            FROM Account 
            WHERE RM_Account_Number__c = '01-33333' and Company_Code__c= '01' LIMIT 1];
        system.debug('in Test Test Class relAccts '+ relAccts[0] +' --' );

        //Create Service Territory 
        ServiceTerritory  testST = SBR_3_0_ServiceTestDataFactory.createServiceTerritory(true);

        List<ServiceTerritory> str1 = [
            SELECT ID, Name
            FROM ServiceTerritory 
            WHERE id =: testST.id LIMIT 1];
        system.debug('ServiceTerritory 1 test'+ str1[0] +' --' );

        //Create Exponce to Location
        ServiceTerritory  testE2Loc = SBR_3_0_ServiceTestDataFactory.createServiceTerritory(true);

        List<ServiceTerritory> str2 = [
            SELECT ID, Name
            FROM ServiceTerritory 
            WHERE id =: testST.id LIMIT 1];
        system.debug('expence to loc 2 test'+ str2[0] +' --' );

        //Get Sales Rep user 
        User testSlaesRep = [Select Id,Name from User where UserName LIKE 'SalesRepUser%' ];

        //Get Associated Location 
        AssociatedLocation testAssloc =  SBR_3_0_ServiceTestDataFactory.createAssLOC(true,'12345678901234567890');
        List<AssociatedLocation> assloc1 = [
            SELECT ID,Job_Number__c
            FROM AssociatedLocation 
            WHERE id =: testAssloc.id LIMIT 1];
        system.debug('Asssociated Location Id'+ assloc1[0] +' --' );


        //Get Owner User 
        User testOwnerUser = [Select Id,Name from User where UserName LIKE 'ownerTestUser%' ];


        //  Create Work Order 
        //Create Wo with SF_PS_RM_WO_Number__c - > Componey code - paload workorder no
        workOrder testWO = SBR_3_0_ServiceTestDataFactory.createWorkOrder(false);
        testWO.AccountId = testAcc.id;
        testWO.OwnerId = testOwnerUser.id;
        testWO.AssetId = testAsrt.id;
        testWO.ServiceTerritoryId  = testST.id;
        testWO.SF_PS_Expense_To_Location__c = testE2Loc.id;
        testWO.SF_PS_Sales_Rep__c = testSlaesRep.id;
        testWO.SF_PS_Job_Site__c =testAssloc.id;
        testWO.SF_PS_Service_Resource__c = testSR.id;
        insert testWO;
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_MaintenanceStepsSyncTest());
        Test.startTest();
        //create maintenance step
        SF_PS_Maintenance_Steps__c mst=new SF_PS_Maintenance_Steps__c(
        SF_PS_Work_Order__c=testWo.id,
        SF_PS_RM_Mtce_Mechanic_Name__c=testSR.id,
        SF_PS_RM_Mtce_Steps_Y_N__c='Y',
        SF_PS_RM_Mtce_Steps_Meter_Reading_Out__c=5.0,
        SF_PS_RM_Mtce_Steps_Description__c='testdesc',
        SF_PS_RM_Mtce_Steps_Pass_Fail__c='N',
        SF_PS_RM_Mtce_Steps_Meter_Reading_In__c=12.4,
        //SF_PS_RM_External_Id__c='1234',
        SF_PS_RM_Mtce_Steps_StepNumber__c='4',
        CurrencyIsoCode='USD');
        insert mst;
        mst.SF_PS_RM_Mtce_Steps_Pass_Fail__c='P';
        update mst;
        Test.stopTest();
 }
    
    public HTTPResponse respond(HTTPRequest req) {
        HTTPResponse res=new HTTPResponse();
        res.setHeader('Content-Type',SBR_3_0_Constants.APP_JSON);
        if(req.getEndpoint().endsWithIgnoreCase('token')){
            res.setBody('{"access_token":"test"}');
            res.setStatusCode(200);
        }else if(req.getEndpoint().endsWithIgnoreCase('steps')){
            res.setBody(		'{'+
		'  "workOrderNumber": 86684649,'+
		'  "mode": "U",'+
		'  "message": "Work Order processed successfully",'+
		'  "workOrderLineItems": []'+
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
}