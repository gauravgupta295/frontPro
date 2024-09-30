/**
 * @description       : 
 * @author            : Bill Convis - ServiceMax
 * @group             : 
 * @last modified on  : 08-19-2022
 * @last modified by  : Bill Convis - ServiceMax
 * @last modified on  : 06-27-2024
 * @last modified by  : Mohsin Ahmad - (FRONT-30848)
 
**/
@isTest
public class SBR_3_0_Api_Web_Reserve_Asset_Test implements HttpCalloutMock {
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
        Account relatedAccount = new Account();
        relatedAccount.RM_Account_Number__c = '12345';
        relatedAccount.Name = SBR_3_0_API_Web_Jobsite_DA.JOBSITEACCOUNTNAME;
        relatedAccount.BillingStreet = '123 Main Street';
        relatedAccount.BillingCity = 'Toronto';
        relatedAccount.BillingPostalCode = 'M9N7V5';
        relatedAccount.BillingState = 'ON';
        relatedAccount.BillingCountry = 'CA';
        relatedAccount.Phone = '9123456781';
        insert relatedAccount;

        Schema.Location branchLocation = new Schema.Location();
        branchLocation.Branch_Location_Number__c = '1234';
        branchLocation.Name = 'Test Branch Location';
        branchLocation.Street_Address__c = '12 Main Street';
        branchLocation.City__c = 'Toronto';
        branchLocation.Zip_Code__c = 'M7N7B3';
        branchLocation.State__c = 'ON';
        branchLocation.Country__c = 'CA';
        branchLocation.A360SPARK_ExternalId__c = '1234';
        branchLocation.RecordTypeId = SBR_3_0_Constants.LOCATION_BRANCH_RT_ID;
       
        insert branchLocation;

        List<Contact> lstContacts = SBR_3_0_TestDataFactory.createContacts(1, relatedAccount.id, true);
        List<Product2> lstProds = SBR_3_0_TestDataFactory.createProducts(1, true);
        //List<Asset> lstAsssets = SBR_3_0_TestDataFactory.createAssets(1,false,relatedAccount.id,lstContacts[0].id, branchLocation.id);
        RecordType rt = [SELECT Id, DeveloperName, IsActive, Name, SobjectType FROM RecordType
        WHERE IsActive = true AND SobjectType = 'Asset' AND Name = 'Rental Asset' ];
        Asset newAsset = new Asset();
        newAsset.RecordTypeId = rt.Id;
        newAsset.AccountID = relatedAccount.id;
        newAsset.ContactID = lstContacts[0].id;
        newAsset.SM_PS_Current_Location__c = branchLocation.id;
        newAsset.SM_PS_Assigned_Location__c = branchLocation.id;
        newAsset.Status = 'Available';
        newAsset.Name = '112233';

        newAsset.SM_PS_Company_Code__c = '12';
        newAsset.SM_PS_Class__c = '444';
        newAsset.SM_PS_Category__c = '555';
        //newAsset.SM_PS_Cat_Class__c = '112233AHIFODIFHDFHDIOFIFHDSSSSCCIIFODSIII';
        newAsset.SM_PS_Last_Transaction_Date__c = Date.today();
        insert newAsset;

    }

       // Test if API Reserves and Asset
       @isTest
       static void testreserveAssetAPI(){
           Test.setMock(HttpCalloutMock.class, new SBR_3_0_Api_Web_Reserve_Asset_Test());
           
           Asset thisAsset = [SELECT ID, SM_PS_Cat_Class__c, SM_PS_Equipment_Number__c FROM ASSET WHERE NAME = '112233'];
           


           List<Equipment_on_Hold__c> lstEqHolds = SBR_3_0_TestDataFactory.createEquipmentOnHold(2, true, thisAsset.Id, thisAsset.SM_PS_Cat_Class__c);
           Equipment_on_Hold__c eqHold = lstEqHolds[0];
           Equipment_on_Hold__c eqHold2 = lstEqHolds[1];
           eqHold.SM_PS_Equipment_Number__c = thisAsset.Id;
           eqHold.SM_PS_Hold_Request_From_Date__c = Date.valueOf('2022-08-01');
           eqHold.SM_PS_Hold_Request_To_Date__c = Date.valueOf('2022-12-01');
           update eqHold;
           eqHold2.SM_PS_Equipment_Number__c = thisAsset.Id;
           eqHold2.SM_PS_Hold_Request_From_Date__c = Date.valueOf('2022-08-01');
           eqHold2.SM_PS_Hold_Request_To_Date__c = Date.valueOf('2022-12-01');
           update eqHold2;

           RestRequest request = new RestRequest();
           request.requestUri = 'https://yourInstance.salesforce.com/services/ASSET/ReserveAsset/v1/';
           request.httpMethod = 'POST';
           request.addHeader('Content-Type', 'application/json');
           SBR_3_0_Api_Web_Reserve_Asset.ReserveAssetWrapper assetWrapper = new SBR_3_0_Api_Web_Reserve_Asset.ReserveAssetWrapper();
           //OrderLines
           List<SBR_3_0_Api_Web_Reserve_Asset.OrderLines> lstorderLines = new List<SBR_3_0_Api_Web_Reserve_Asset.OrderLines>();
           SBR_3_0_Api_Web_Reserve_Asset.OrderLines orderLine = new SBR_3_0_Api_Web_Reserve_Asset.OrderLines();
           SBR_3_0_Api_Web_Reserve_Asset.OrderLines orderLine2 = new SBR_3_0_Api_Web_Reserve_Asset.OrderLines();
           //Locations
           List<SBR_3_0_Api_Web_Reserve_Asset.Locations> lstlocs  = new List<SBR_3_0_Api_Web_Reserve_Asset.Locations>();
           SBR_3_0_Api_Web_Reserve_Asset.Locations loc = new SBR_3_0_Api_Web_Reserve_Asset.Locations();
           //Dates
           SBR_3_0_Api_Web_Reserve_Asset.Dates reqDates  = new SBR_3_0_Api_Web_Reserve_Asset.Dates();
           //Requested Delivery Date
           SBR_3_0_Api_Web_Reserve_Asset.RequestedDeliveryDate reqDelDate = new SBR_3_0_Api_Web_Reserve_Asset.RequestedDeliveryDate();
           //Create the Asset Wrapper
           assetWrapper.customerId = '12';
           assetWrapper.orderId = 'ORDER5554444';
           assetWrapper.orgId = '12';
           //Create the Order Line
           orderLine.productId = '555444';
           orderLine.orderLineId = 'ORDERLINEID';
           //Create the Second Order Line orderLine2
           orderLine2.productId = '555444';
           orderLine2.orderLineId = 'ORDERLINEID2';
           //Create the Location
           loc.locationId = '1234';
           loc.locationType = 'Branch';
           lstlocs.add(loc);
           orderLine.locations = lstlocs;
           orderLine2.locations = lstlocs;
           //Setup the Requested Deliver Date
           reqDelDate.min =  DateTime.valueOf('2022-07-01 16:53:30');
           reqDelDate.max =  DateTime.valueOf('2022-09-01 16:53:30');
           reqDates.requestedDeliveryDate = reqDelDate;
           orderLine.dates = reqDates;
           orderLine2.dates = reqDates;
           lstorderLines.add(orderLine);
           lstorderLines.add(orderLine2);
           //Now add to Asset Wrapper
           assetWrapper.orderLines =   lstorderLines;
           request.requestBody = Blob.valueOf(JSON.serialize(assetWrapper));
           RestContext.request = request;
           
           //String response = 'SUCCESS';
           Test.startTest();
           SBR_3_0_Api_Web_Reserve_Asset.reserveAsset();
           //system.assertEquals('Success', response, 'Jobsite API did not return Success!');
          
           Test.stopTest();
           
       }
    
    @isTest
       static void testreserveAssetAPI3(){
           Test.setMock(HttpCalloutMock.class, new SBR_3_0_Api_Web_Reserve_Asset_Test());
           
           Asset thisAsset = [SELECT ID, SM_PS_Cat_Class__c, SM_PS_Equipment_Number__c FROM ASSET WHERE NAME = '112233'];
           
           List<Equipment_on_Hold__c> lstEqHolds = SBR_3_0_TestDataFactory.createEquipmentOnHold(2, true, thisAsset.Id, thisAsset.SM_PS_Cat_Class__c);
           Equipment_on_Hold__c eqHold = lstEqHolds[0];
           Equipment_on_Hold__c eqHold2 = lstEqHolds[1];
           eqHold.SM_PS_Equipment_Number__c = thisAsset.Id;
           eqHold.SM_PS_Hold_Request_From_Date__c = Date.valueOf('2022-08-01');
           eqHold.SM_PS_Hold_Request_To_Date__c = Date.valueOf('2022-12-01');
           update eqHold;
           eqHold2.SM_PS_Equipment_Number__c = thisAsset.Id;
           eqHold2.SM_PS_Hold_Request_From_Date__c = Date.valueOf('2022-08-01');
           eqHold2.SM_PS_Hold_Request_To_Date__c = Date.valueOf('2022-12-01');
           update eqHold2;

           RestRequest request = new RestRequest();
           request.requestUri = 'https://yourInstance.salesforce.com/services/ASSET/ReserveAsset/v1/';
           request.httpMethod = 'POST';
           request.addHeader('Content-Type', 'application/json');
           SBR_3_0_Api_Web_Reserve_Asset.ReserveAssetWrapper assetWrapper = new SBR_3_0_Api_Web_Reserve_Asset.ReserveAssetWrapper();
           //OrderLines
           List<SBR_3_0_Api_Web_Reserve_Asset.OrderLines> lstorderLines = new List<SBR_3_0_Api_Web_Reserve_Asset.OrderLines>();
           SBR_3_0_Api_Web_Reserve_Asset.OrderLines orderLine = new SBR_3_0_Api_Web_Reserve_Asset.OrderLines();
           SBR_3_0_Api_Web_Reserve_Asset.OrderLines orderLine2 = new SBR_3_0_Api_Web_Reserve_Asset.OrderLines();
           //Locations
           List<SBR_3_0_Api_Web_Reserve_Asset.Locations> lstlocs  = new List<SBR_3_0_Api_Web_Reserve_Asset.Locations>();
           SBR_3_0_Api_Web_Reserve_Asset.Locations loc = new SBR_3_0_Api_Web_Reserve_Asset.Locations();
           //Dates
           SBR_3_0_Api_Web_Reserve_Asset.Dates reqDates  = new SBR_3_0_Api_Web_Reserve_Asset.Dates();
           //Requested Delivery Date
           SBR_3_0_Api_Web_Reserve_Asset.RequestedDeliveryDate reqDelDate = new SBR_3_0_Api_Web_Reserve_Asset.RequestedDeliveryDate();
           //Create the Asset Wrapper
           assetWrapper.customerId = '12';
           assetWrapper.orderId = 'ORDER5554444';
           assetWrapper.orgId = '12';
           //Create the Order Line
           orderLine.productId = '555444';
           orderLine.orderLineId = 'ORDERLINEID';
           //Create the Second Order Line orderLine2
           orderLine2.productId = '555444';
           orderLine2.orderLineId = 'ORDERLINEID2';
           //Create the Location
           loc.locationId = '1234';
           loc.locationType = 'Branch';
           lstlocs.add(loc);
           orderLine.locations = lstlocs;
           orderLine2.locations = lstlocs;
           //Setup the Requested Deliver Date
           reqDelDate.min =  DateTime.valueOf('2022-07-01 16:53:30');
           reqDelDate.max =  DateTime.valueOf('2024-09-01 16:53:30');
           reqDates.requestedDeliveryDate = reqDelDate;
           orderLine.dates = reqDates;
           orderLine2.dates = reqDates;
           lstorderLines.add(orderLine);
           lstorderLines.add(orderLine2);
           //Now add to Asset Wrapper
           assetWrapper.orderLines =   lstorderLines;
           request.requestBody = Blob.valueOf(JSON.serialize(assetWrapper));
           RestContext.request = request;
           
           //String response = 'SUCCESS';
           Test.startTest();
           SBR_3_0_Api_Web_Reserve_Asset.reserveAsset();
           //system.assertEquals('Success', response, 'Jobsite API did not return Success!');
          
           Test.stopTest();
           
       }
    
    // Test if API Reserves and Asset
       @isTest
       static void testreserveAssetAPI2(){
           Test.setMock(HttpCalloutMock.class, new SBR_3_0_Api_Web_Reserve_Asset_Test());
           
           Asset thisAsset = [SELECT ID, SM_PS_Cat_Class__c, SM_PS_Equipment_Number__c FROM ASSET WHERE NAME = '112233'];
           


           List<Equipment_on_Hold__c> lstEqHolds = SBR_3_0_TestDataFactory.createEquipmentOnHold(2, true, thisAsset.Id, thisAsset.SM_PS_Cat_Class__c);
           Equipment_on_Hold__c eqHold = lstEqHolds[0];
           Equipment_on_Hold__c eqHold2 = lstEqHolds[1];
           eqHold.SM_PS_Equipment_Number__c = thisAsset.Id;
           update eqHold;
           eqHold2.SM_PS_Equipment_Number__c = thisAsset.Id;
           eqHold2.SM_PS_Hold_Request_From_Date__c = Date.valueOf('2022-08-01');
           eqHold2.SM_PS_Hold_Request_To_Date__c = Date.valueOf('2022-12-01');
           update eqHold2;

           RestRequest request = new RestRequest();
           request.requestUri = 'https://yourInstance.salesforce.com/services/ASSET/ReserveAsset/v1/';
           request.httpMethod = 'POST';
           request.addHeader('Content-Type', 'application/json');
           SBR_3_0_Api_Web_Reserve_Asset.ReserveAssetWrapper assetWrapper = new SBR_3_0_Api_Web_Reserve_Asset.ReserveAssetWrapper();
    
           //Create the Asset Wrapper
           assetWrapper.customerId = '12';
           assetWrapper.orderId = 'ORDER5554444';
           assetWrapper.orgId = '12';
           
           //Now add to Asset Wrapper
           assetWrapper.orderLines =   new List<SBR_3_0_Api_Web_Reserve_Asset.OrderLines>();
           request.requestBody = Blob.valueOf(JSON.serialize(assetWrapper));
           RestContext.request = request;
           
           //String response = 'SUCCESS';
           Test.startTest();
           SBR_3_0_Api_Web_Reserve_Asset obj = new SBR_3_0_Api_Web_Reserve_Asset();
          	String orgId = obj.orgId;
           String orderId = obj.orderId;
           String custId = obj.customerId;
           //List<OrderLines> orderLines = obj.orderLines;
           SBR_3_0_Api_Web_Reserve_Asset.reserveAsset();
           //system.assertEquals('Success', response, 'Jobsite API did not return Success!');
          
           Test.stopTest();
           
       }
		
}