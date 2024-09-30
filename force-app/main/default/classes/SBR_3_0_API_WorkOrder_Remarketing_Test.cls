/*********************************************************************************************************************
* Apex Class: SBR_3_0_API_WorkOrder_Remarketing_Test
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Test class for SBR_3_0_API_WorkOrder_Remarketing
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Harry Rokad          2024-01-15             Initial version 
    2.0         Pankaj Meshram		 2024-06-10	            Pankaj Meshram
*********************************************************************************************************************/
@isTest
public with sharing class SBR_3_0_API_WorkOrder_Remarketing_Test {

    @TestSetup
    static void makeData(){
        PermissionSetLicense cpqLicense = [SELECT MasterLabel, DeveloperName FROM PermissionSetLicense WHERE Developername = 'SalesforceCPQ_CPQStandardPerm'];
        
        List<PermissionSetLicenseAssign> existingAssignments = [SELECT Id FROM PermissionSetLicenseAssign WHERE AssigneeId = :UserInfo.getUserId() AND PermissionSetLicenseId = :cpqLicense.Id LIMIT 1];
        
        if (existingAssignments.isEmpty()) {
            PermissionSetLicenseAssign cpqLicenseAssign = new PermissionSetLicenseAssign(AssigneeId = UserInfo.getUserId(), PermissionSetLicenseId = cpqLicense.Id);
            insert cpqLicenseAssign;
        }
        
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Integration_API_Access'];
        List <PermissionSetAssignment> permSetCheck = [SELECT Id from PermissionSetAssignment WHERE PermissionSetId = : ps.Id
                                                    AND AssigneeId = : UserInfo.getUserId()];
        if (permSetCheck.size()==0){
        insert new PermissionSetAssignment(AssigneeId = UserInfo.getUserId(), PermissionSetId = ps.Id);
        }

        User testSRUser =  SBR_3_0_ServiceTestDataFactory.createServiceResourceUser(true,'1234','78923');
        System.debug('testSRUser --- ' + testSRUser);
        
        // Create Sales rep User 
        User TestSalesRep = SBR_3_0_ServiceTestDataFactory.createSalesRepUser(true,'111222');

                //Create Owner User 
        //Create Owner
        User TestOwnerUser = SBR_3_0_ServiceTestDataFactory.createOwnerUser(true, '1234','7777');
        System.debug('TestOwnerUser --- ' + TestOwnerUser);



    }
    // Mock class for HTTP callout
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            // Create a mock response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            if (req.getEndpoint().endsWithIgnoreCase('token')){
                res.setBody('{"access_token":"test"}');
                res.setStatusCode(200);
            }
            else if(req.getEndpoint().endsWithIgnoreCase('remarketing')){
            res.setBody('{Success}');
            res.setStatusCode(200);
            }
            return res;
        }
    }
    


    @isTest
    static void testMakeTheCallout() {
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
          //AssociatedLocation testAssloc =  SBR_3_0_ServiceTestDataFactory.createAssLOC(true,'12345678901234567890');
          //List<AssociatedLocation> assloc1 = [
          //    SELECT ID,Job_Number__c
          //    FROM AssociatedLocation 
          //    WHERE id =: testAssloc.id LIMIT 1];
          //system.debug('Asssociated Location Id'+ assloc1[0] +' --' );
  

          //Get Owner User 
          User testOwnerUsers = [Select Id,Name,Wynne_User_Name__c from User where UserName LIKE 'ownerTestUser%' ];
          system.debug('hello');
          system.debug('testOwnerUsers'+testOwnerUsers);
  
  
          //  Create Work Order 
          //Create Wo with SF_PS_RM_WO_Number__c - > Componey code - paload workorder no
          workOrder testWO = SBR_3_0_ServiceTestDataFactory.createWorkOrder(false);
          testWO.AccountId = testAcc.id;
          testWO.OwnerId = testOwnerUsers.id;
          testWO.AssetId = testAsrt.id;
          testWO.ServiceTerritoryId  = testST.id;
          testWO.SF_PS_Expense_To_Location__c = testE2Loc.id;
          testWO.SF_PS_Sales_Rep__c = testSlaesRep.id;
          //testWO.SF_PS_Job_Site__c =testAssloc.id;
          testWO.SF_PS_Service_Resource__c = testSR.id;
          insert testWO;
  
          List<workOrder> wotest1 = [
              SELECT ID 
              FROM workOrder 
              WHERE id =: testWO.id LIMIT 1];
          system.debug('workorder isss  1 test'+ wotest1[0] +' --' );
         
        //  Pricebook2 priceBook = new Pricebook2(
        //       Id = Test.getStandardPricebookId(),
        //       IsActive = true
        //   );
        //   update priceBook;
        // System.runAs(new User(Id = UserInfo.getUserId())) {
        // Uncommented for test coverage FRONT-30844
             SF_PS_Equipment_Images__c img = new SF_PS_Equipment_Images__c(
                 SF_PS_Work_Order__c = testWO.Id,
                 Image_Name__c = 'Test Image',
                 Image_Public_Link__c = 'http://example.com/image'
             );
             insert img;
        // End of FRONT-30844
        // }
        List<String> inputIds = new List<String>{ testWO.Id };
         
        String jsonString = '{"data":[{"equipmentNumber":"ABC123","imageName":"Image1","imagePublicLink":"http://example.com/image1"},{"equipmentNumber":"ABC123","imageName":"Image2","imagePublicLink":"http://example.com/image2"}]}';
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        SBR_3_0_API_WorkOrder_Remarketing.callRichieBrothers(inputIds);
        Test.stopTest();

}

}