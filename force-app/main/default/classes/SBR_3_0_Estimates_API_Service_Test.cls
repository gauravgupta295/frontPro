@isTest
public with sharing class SBR_3_0_Estimates_API_Service_Test {

    @TestSetup
    static void makeData(){
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
            else if(req.getEndpoint().endsWithIgnoreCase('estimates')){
            res.setBody('{"sourceWorkOrderNumber":"12345","workOrderNumber":999999999999,"estimatesItems":[{"itemNumber":"ALT001","stockClass":"ELEAL","quantity":1,"unitOfMeasure":"EA","sellingPrice":500,"listPrice":0,"discountPercent":1,"sku":0,"sourceReferenceLineNumber":"35242a41-3a7d-459e-bce4-f687eb640ece"},{"itemNumber":"AA-BATTERY","stockClass":"BATTE","quantity":1,"unitOfMeasure":"EA","sellingPrice":2.252,"listPrice":0,"discountPercent":4,"sku":0,"sourceReferenceLineNumber":"0137d827-5243-475f-b71a-06e23e1a10c1"}],"taxInformation":[{"taxOnSales":151.04,"totalInvoiceAmount":1852.79,"stateTaxAmount":68.07,"countyTaxAmount":0}]}');
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
         
         Pricebook2 priceBook = new Pricebook2(
              Id = Test.getStandardPricebookId(),
              IsActive = true
          );
          update priceBook;
 
         Schema.Location loc = new Schema.Location(Name = 'TestLoc', Company_Code__c = '01', Branch_Location_Number__c = '1234', IsInventoryLocation = true );
         insert loc;
 
         system.debug('Loc is ' + loc );
 
 
          Product2 pd = new Product2(name='TestProduct', CurrencyIsoCode='USD' , Stock_class__c = 'MISC',Product_SKU__c = '10870996',QuantityUnitOfMeasure = 'EA');
          insert pd;
 
          system.debug('pd is ' + pd );
  
          ProductItem pi = new ProductItem();
          pi.Product2Id = pd.Id;
          pi.QuantityOnHand = 1;
          pi.LocationId = loc.Id;
          pi.CurrencyIsoCode='USD';
          insert pi; 
 
          system.debug('pi is ' + pi );
 
         
         //ProductConsumed pc =  SBR_3_0_ServiceTestDataFactory.createProductConsumedRecord(false ,testWO.id, '1231231');
         ProductConsumed pc = new ProductConsumed();
         pc.WorkOrderId = testWO.id;
         pc.SF_PS_RM_External_Id__c = '1231231';
         pc.ProductItemId = pi.Id;
         pc.QuantityConsumed = 1;
         pc.SF_PS_Parts_Line_Num__c = '123';
         //pc.SF_PS_Stock_Class__c = 'MISC';
         pc.SF_PS_Quantity__c = 1;
         pc.SF_PS_Selling_Price__c = 10;
         pc.SF_PS_Labor_Code__c = '9000';
         pc.SF_PS_Cost_Price__c = 15;
         pc.SF_PS_Line_Level_Comment__c = 'Test User';
         insert pc;
 
         system.debug('workorder ProductConsumed '+ pc +' --' );
         
        String jsonString = '{"insideLabor":[{"insideLaborHours":-9999.99,"insideLaborRate":9999999.99,"laborCode":0,"mechanicId":"string","sourceReferenceLineNumber":"string"}],"outsideLabor":[{"laborCode":0,"outsideLaborCost":-99999999.99,"outsideLaborPrice":99999999.99,"outsideLaborPoNumber":0,"sourceReferenceLineNumber":"string"}],"mileage":{"laborCode":0,"mileageMiles":-9999.99,"mileageRate":9999.999,"sourceReferenceLineNumber":"string"},"parts":[{"cost":999999999.999,"discountPercent":999.99,"itemNumber":"string","laborCode":0,"orderQuantity":-99999.99,"sellingPrice":999999999.999,"sourceReferenceLineNumber":"string","stockClass":"strin","unitOfMeasure":"st"},{"unitOfMeasure":"st","stockClass":"strin","sourceReferenceLineNumber":"string","sellingPrice":999999999.999,"orderQuantity":-99999.99,"laborCode":0,"itemNumber":"string","discountPercent":999.99,"cost":999999999.999}]}';
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        // Call the makeTheCallout method
        SBR_3_0_Estimates_API_Service.parseWorkOrder(testWO.Id,jsonString);
        Test.stopTest();

        // Add assertions based on the expected behavior
        System.assertEquals('{"sourceWorkOrderNumber":"12345","workOrderNumber":999999999999,"estimatesItems":[{"itemNumber":"ALT001","stockClass":"ELEAL","quantity":1,"unitOfMeasure":"EA","sellingPrice":500,"listPrice":0,"discountPercent":1,"sku":0,"sourceReferenceLineNumber":"35242a41-3a7d-459e-bce4-f687eb640ece"},{"itemNumber":"AA-BATTERY","stockClass":"BATTE","quantity":1,"unitOfMeasure":"EA","sellingPrice":2.252,"listPrice":0,"discountPercent":4,"sku":0,"sourceReferenceLineNumber":"0137d827-5243-475f-b71a-06e23e1a10c1"}],"taxInformation":[{"taxOnSales":151.04,"totalInvoiceAmount":1852.79,"stateTaxAmount":68.07,"countyTaxAmount":0}]}', SBR_3_0_Estimates_API_Service.returnPayload);
    }
}