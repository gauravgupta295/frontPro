/************************************************
Class Name : SBR_3_0_Api_Web_Reserve_Asset_V2_Test
Developer Name : Ritesh Mohapatra (ServiceMax)
Created Date : 2023/05/09
*************************************************
Modification History :
2023/05/09 - Ritesh Mohapatra - Initial Version
************************************************/
@isTest
public class SBR_3_0_Api_Web_Reserve_Asset_V2_Test implements HttpCalloutMock {
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
        relatedAccount.Phone  = '9874563217';
        relatedAccount.Company_Code__c = '01';
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
        
        RecordType rt = [SELECT Id, DeveloperName, IsActive, Name, SobjectType FROM RecordType WHERE IsActive = true AND SobjectType = 'Asset' AND Name = 'Rental Asset' ];
        
        Asset newAsset = new Asset();
        newAsset.RecordTypeId = rt.Id;
        newAsset.AccountID = relatedAccount.id;
        newAsset.ContactID = lstContacts[0].id;
        newAsset.SM_PS_Current_Location__c = branchLocation.id;
        newAsset.SM_PS_Assigned_Location__c = branchLocation.id;
        newAsset.Status = 'Available';
        newAsset.Name = '112233';
        newAsset.SM_PS_Category__c = '657';
        newAsset.SM_PS_Class__c = '657';
        newAsset.Status = 'Available';
        newAsset.SM_PS_Company_Code__c = '01';
        newAsset.SM_PS_Cat_Class__c = 'TESTCATCLASS';
        newAsset.SM_PS_Last_Transaction_Date__c = Date.today();
  
        insert newAsset;
        
        // Create Product
        List<Product2> products = new List<Product2>();
        for(Integer i = 0; i < 3; i++) {
            Product2 product = new Product2();
            product.Name = 'Test Product ' + i;
            if(i == 0) {
                product.Product_Type__c = 'Cat-Class';
                product.Product_SKU__c = '123456';
                product.Category__c = '32134';
                product.Class__c = '2039';
                product.ToolFlex__c = 'N';
                product.isSerialized = true;
                product.Stock_class__c = '';
                product.Bulk_Item__c=false;
                product.Status__c='A';
                product.Company_code__c ='01;02';
            } else if (i == 1) {
                product.Product_Type__c = 'Parts';
                product.Item_Number__c = '1234GH';
                product.Stock_Class__c = 'AIMFV';
                product.isSerialized = true;
                product.Company_code__c ='01;02';
            } else {
                product.Product_Type__c = '';
                product.Item_Number__c = '1285JC';
                product.Stock_Class__c = 'UJEKL';
                product.Company_code__c ='01;02';
            }
            products.add(product);
        }
        insert products;
        
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
        jobLocation.Analysis_Region_Key__c = '945';
        jobLocation.Company_Code__c = '01';
        insert jobLocation;
        
        // Create Job Site
        AssociatedLocation jobSite = new AssociatedLocation(
            Name__c = 'Test Job Site',
            ParentRecordId = relatedAccount.Id,
            LocationId = jobLocation.Id,
            Branch__c = branchLocation.Id,
            Job_Number__c = '20221004A'
        );
        insert jobSite;
        
        // Create Price Book
        Pricebook2 priceBook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update priceBook;
                
        // Create Price Book Entries
        SBR_3_0_TestDataFactory.createPriceBookEntries(products);
        
        // Create Order
        Order order = new Order(
            Quote_Name__c = 'Test Quote',
            AccountId = relatedAccount.id,
            CurrencyIsoCode = 'USD',
            Reservation_Order_Number__c = '657000',
            Jobsite__c = jobSite.Id,
            branch__c = branchLocation.id,
            Deliverymethod__c = 'Delivery',
            Status = 'Draft',
            Pricebook2Id = priceBook.Id,
            Start_Date__c = date.valueOf('2022-10-07 12:00:00'),
            EffectiveDate = date.valueOf('2022-10-07 12:00:00'),
            EndDate = date.valueOf('2022-10-08 8:00:00'),
            Earliest_Delivery_Date__c = date.valueOf('2022-09-06 12:00:00'),
            Opt_Out_RPP__c = false,
            Opt_Out_Fuel_Charge__c = false,
            Selling_Channel__c = 'SBRB2B',
            Duration__c = 'Custom',
            Company_Code__c = '01'
        );
        insert order;
    }

       // Test if API Reserves and Asset
       @isTest
       static void testreserveAssetAPI(){
        /*User adminUSer = [Select Id from User where Profile.NAme = 'System Administrator' AND ISActive = true LIMIT 1];
        List<PermissionSetLicenseAssign> pslaList = new List<PermissionSetLicenseAssign>();
        for(PermissionSetLicense psl : [SELECT id FROM PermissionSetLicense Where MasterLAbel ='Salesforce CPQ License' OR MasterLabel = 'Salesforce CPQ AA License'
            OR MasterLAbel = 'Field Service Scheduling' OR MasterLAbel = 'CRM Analytics Plus']) {
                pslaList.add(new PermissionSetLicenseAssign(AssigneeId = adminUSer.Id, PermissionSetLicenseId = psl.Id));
        }
        insert pslaList;
        PermissionSet baPermSet = [SELECT Id FROM PermissionSet WHERE Name = 'Business_Admin1'];
        insert new PermissionSetAssignment(AssigneeId = adminUser.id, PermissionSetId = baPermSet.Id);
        
        List<PermissionSetAssignment> baPSAList = [Select AssigneeId from PermissionSetAssignment 
            Where PermissionSet.Name='Business_Admin1' AND Assignee.IsActive=true LIMIT 1];
        Id userId = !baPSAList.isEmpty() ? baPSAList[0].AssigneeId : UserInfo.getUSerId();
        User adminUSer = [Select Id from User where Id =: userId];*/
        
        List<User> userList = new List<User>();
        Profile p2 = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        String adminUserName = 'systemadmin' + DateTime.now().getTime() + '@SBRtestorg.com';
        User adminUser = new User(Alias = 'standt', Email='systemadmin@testorg.com',
        EmailEncodingKey='UTF-8', LastName='adminTest', LanguageLocaleKey='en_US',
        LocaleSidKey='en_US', ProfileId = p2.Id,
        TimeZoneSidKey='America/Los_Angeles',
        UserName=adminUserName);
        userList.add(adminUser);
        insert userList;
           
        PermissionSet ps = [SELECT Id 
                    FROM PermissionSet 
                    WHERE Name = 'Assets_Full_Access'];
		insert new PermissionSetAssignment(AssigneeId = userList[0].id, PermissionSetId = ps.Id);
           
        Order order = [SELECT Id, CurrencyIsoCode,Pricebook2Id FROM Order WHERE Quote_Name__c = 'Test Quote'];
       
        Product2 productsRec =  [SELECT Id FROM Product2 WHERE Product_Type__c = 'Cat-Class'];
        PricebookEntry pbEntry = [SELECT Id,Product2Id,CurrencyIsoCode FROM PricebookEntry WHERE Pricebook2Id = :Test.getStandardPricebookId() AND Product2Id = :productsRec.Id LIMIT 1];        
    
           
        // Create Order item
        List<OrderItem> orderItems = new List<OrderItem>();
        OrderItem orderItem = new OrderItem();
        orderItem.Global_Line_Number__c = 456456;
        orderItem.Product2Id = productsRec.Id;
        orderItem.Reservation_Line_Number__c = 12345;
        orderItem.OrderId = order.id;
        orderItem.UnitPrice = 100;
        orderItem.Item_Number__c = 0;
        orderItem.PricebookEntryId = pbEntry.Id;        
        orderItem.Hourly_Rate__c = 2.0;
        orderItem.Min_Rate__c = 0;
        orderItem.Quantity = 5;
        orderItem.Free_Flag__c = false;
        orderItem.Suggested_Daily_Rate__c = 2.0;
        orderItem.Suggested_Weekly_Rate__c = 2.0;
        orderItem.Suggested_Monthly_Rate__c = 2.0;
        orderItem.Daily_Rate__c = 2.0;
        orderItem.Weekly_Rate__c = 4.0;
        orderItem.Monthly_Rate__c = 6.0;
        orderItem.Rates_Overriden__c = false;
        
        System.runAs(userList[0]) {
        
           Test.setMock(HttpCalloutMock.class, new SBR_3_0_Api_Web_Reserve_Asset_V2_Test());
           
           Asset thisAsset = [SELECT ID, Name, SM_PS_Cat_Class__c, SM_PS_Equipment_Number__c FROM ASSET WHERE NAME =: '112233'];
           thisAsset.SM_PS_Cat_Class__c = 'TESTCATCLASS2';
           update thisAsset;
           
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
           request.requestUri = 'https://yourInstance.salesforce.com/services/ASSET/ReserveAsset/v2/';
           request.httpMethod = 'POST';
           request.addHeader('Content-Type', 'application/json');
           
           SBR_3_0_Api_Web_Reserve_Asset_V2.ReserveAssetWrapper assetWrapper = new SBR_3_0_Api_Web_Reserve_Asset_V2.ReserveAssetWrapper();
           //OrderLines
           List<SBR_3_0_Api_Web_Reserve_Asset_V2.OrderLines> lstorderLines = new List<SBR_3_0_Api_Web_Reserve_Asset_V2.OrderLines>();
           SBR_3_0_Api_Web_Reserve_Asset_V2.OrderLines orderLine = new SBR_3_0_Api_Web_Reserve_Asset_V2.OrderLines();
           SBR_3_0_Api_Web_Reserve_Asset_V2.OrderLines orderLine2 = new SBR_3_0_Api_Web_Reserve_Asset_V2.OrderLines();
           
           //Locations
           List<SBR_3_0_Api_Web_Reserve_Asset_V2.Locations> lstlocs  = new List<SBR_3_0_Api_Web_Reserve_Asset_V2.Locations>();
           SBR_3_0_Api_Web_Reserve_Asset_V2.Locations loc = new SBR_3_0_Api_Web_Reserve_Asset_V2.Locations();
           
           //Dates
           SBR_3_0_Api_Web_Reserve_Asset_V2.Dates reqDates  = new SBR_3_0_Api_Web_Reserve_Asset_V2.Dates();
           
           //Requested Delivery Date
           SBR_3_0_Api_Web_Reserve_Asset_V2.RequestedDeliveryDate reqDelDate = new SBR_3_0_Api_Web_Reserve_Asset_V2.RequestedDeliveryDate();
           
           SBR_3_0_Api_Web_Reserve_Asset_V2.CustomFields customfieldsType  = new SBR_3_0_Api_Web_Reserve_Asset_V2.CustomFields();
            
           //Create the Location
           loc.locationId = '01-1234';
           loc.locationType = 'Branch';
           lstlocs.add(loc);
           
           //Setup the Requested Deliver Date
           reqDelDate.min =  '2023-05-03T20:00:00Z';
           reqDelDate.max =  '2023-05-03T20:45:00Z';
           reqDates.requestedDeliveryDate = reqDelDate;
           
           //Setup extnEstimatedReturnDate
           customfieldsType.extnEstimatedReturnDate ='2023-05-17T20:45:00Z';
           reqDates.customFields = customfieldsType;
           
           //Create the Asset Wrapper
           //assetWrapper.customerId = '12';
           assetWrapper.orderId = '657000';
           assetWrapper.orgId = '01';
           
           //Create the Order Line
           orderLine.productId = '657657';
           orderLine.orderLineId = 456456;
           orderLine.locations = lstlocs;
           orderLine.dates = reqDates;
           
           //Create the Second Order Line orderLine2
           orderLine2.productId = 'TESTCATCLASS';
           orderLine2.orderLineId = 123123;
           orderLine2.locations = lstlocs;
           orderLine2.dates = reqDates;
           
           
           lstorderLines.add(orderLine);
           lstorderLines.add(orderLine2);
           
           //Now add to Asset Wrapper
           assetWrapper.orderLines =   lstorderLines;
           request.requestBody = Blob.valueOf(JSON.serialize(assetWrapper));
           RestContext.request = request;
           
           
           //String response = 'SUCCESS';
           Test.startTest();
           SBR_3_0_Api_Web_Reserve_Asset_V2.tempMethod();
           insert orderItem;
           SBR_3_0_Api_Web_Reserve_Asset_V2.reserveAsset();
           
           //Setup the Requested Deliver Date
           reqDelDate.min =  '2023-04-03T20:00:00Z';
           reqDelDate.max =  '2023-04-03T20:45:00Z';
           reqDates.requestedDeliveryDate = reqDelDate;
           
           orderLine.dates = reqDates;
           lstorderLines.clear();
           lstorderLines.add(orderLine);
           assetWrapper.orderLines =   lstorderLines;
           request.requestBody = Blob.valueOf(JSON.serialize(assetWrapper));
           RestContext.request = request;
           SBR_3_0_Api_Web_Reserve_Asset_V2.reserveAsset();
           
           orderLine.productId = '989989';
		   lstorderLines.clear();
           lstorderLines.add(orderLine);
           assetWrapper.orderLines =   lstorderLines;
           request.requestBody = Blob.valueOf(JSON.serialize(assetWrapper));
           RestContext.request = request;
           
           SBR_3_0_Api_Web_Reserve_Asset_V2.reserveAsset();
           
           orderLine.productId = '';
		   lstorderLines.clear();
           lstorderLines.add(orderLine);
           assetWrapper.orderLines =   lstorderLines;
           request.requestBody = Blob.valueOf(JSON.serialize(assetWrapper));
           RestContext.request = request;
           
           SBR_3_0_Api_Web_Reserve_Asset_V2.reserveAsset();
           
               SBR_3_0_Api_Web_Reserve_Asset_V2.ReservedDates objResDates = new SBR_3_0_Api_Web_Reserve_Asset_V2.ReservedDates(null, null);
               objResDates.overlapExists(null, null);
               objResDates.overlapExists(System.today(), System.today().addMonths(1));
               objResDates = new SBR_3_0_Api_Web_Reserve_Asset_V2.ReservedDates(System.today(), System.today().addMonths(1));
               objResDates.overlapExists(System.today(), System.today().addMonths(1));
           Test.stopTest();
       }
       }

}