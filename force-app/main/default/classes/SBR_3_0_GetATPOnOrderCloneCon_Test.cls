/**
* @description       : 
* @author            : ChangeMeIn@UserSettingsUnder.SFDoc
* @group             : 
* @last modified on  : 12-27-2023
* @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/

@isTest
public with sharing class SBR_3_0_GetATPOnOrderCloneCon_Test implements HttpCalloutMock {
    @TestSetup
    static void makeData()
    {       
        Credential__c cred = SBR_3_0_TestDataFactory.createCredentials(1, false)[0];
        cred.Name = 'Mule_Token_Endpoint';
        cred.Key_Id__c = 'testKey123';
        cred.Secret__c = 'secret';
        insert cred;
        //Account creation
        Account acct = SBR_3_0_TestDataFactory.createAccounts(1, true, 'Credit')[0];
        
        Analysis_Region__c region = SBR_3_0_TestDataFactory.createAnalysisRegion(false,'001' ,acct.Id);
        region.Name = 'Test Region';
        region.Company_Code__c = '01';
        Insert region;
        
        Schema.Location jobLocation = SBR_3_0_TestDataFactory.createLocations(1, false, SBR_3_0_Constants.LOCATION_REC_TYPE_JOB_LOC)[0];
        jobLocation.Analysis_Region_Key__c = '001';
        jobLocation.Company_Code__c = '02';
        jobLocation.Time_Zone_Id__c = 'America/Denver';
        jobLocation.OMS_Sourcing_Enabled__c = true;
        Insert jobLocation;
        
        Schema.Location branchLocation =SBR_3_0_TestDataFactory.createLocations(1, false, SBR_3_0_Constants.LOCATION_REC_TYPE_BRANCH)[0];
        branchLocation.Company_Code__c = 'X';
        branchLocation.Time_Zone_Name__c = 'America/Chicago';
        branchLocation.Time_Zone__c = 3;
        branchLocation.OMS_Sourcing_Enabled__c = true;
        branchLocation.Time_Zone_Id__c = 'America/Denver';
        branchLocation.Latitude_Longitude__Latitude__s = 48.56;
        branchLocation.Latitude_Longitude__Longitude__s = -117.66;
        Insert branchLocation;
        
        AssociatedLocation jobSite =SBR_3_0_TestDataFactory.createAssociatedLocations(1,acct.Id, branchLocation.Id, jobLocation.Id, false)[0];
        jobSite.Latitude_Longitude__Latitude__s = 48.51;
        jobSite.Latitude_Longitude__Longitude__s = -117.62;
        jobSite.Job_Number__c = '20221004A';
        jobSite.Time_Zone_Id__c = 'America/Denver';
        Insert jobSite;
        
        Pricebook2 priceBook = new Pricebook2( Id = Test.getStandardPricebookId(),IsActive = true );
        update priceBook;
        
        // Create Quote
        List<order> ordersList = new List<order>();
        Order order = new Order(
            Quote_Name__c = 'Test Quote',
            AccountId = acct.Id,
            Name='order1',
            Jobsite__c = jobSite.Id,
            Deliverymethod__c = 'Delivery',
            Delivery_Charge__c = 10,
            Status = 'Draft',
            Pricebook2Id = priceBook.Id,
            Start_Date__c = date.today().addDays(5),
            EffectiveDate = date.today().addDays(10),
            EndDate = date.today().addDays(15),
            Return_Date__c = date.today().addDays(20),
            Earliest_Delivery_Date__c = date.today().addDays(18),
            Opt_Out_RPP__c = false,
            Order_Initiating_Channel__c = 'SLSFRC',
            Opt_Out_Fuel_Charge__c = false,
            Selling_Channel__c = 'SBRB2B',
            Duration__c = 'Custom',
            Reservation_Order_Number__c = '12342',
            Branch__c = branchLocation.Id,
            Sourcing_Branch__c = branchLocation.Id,
            RecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('Reservation Order').getRecordTypeId()
        );
        ordersList.add(order);
        
        // ATP order
        Order orderNoJS = new Order(
            Quote_Name__c = 'Test Quote no JS',
            AccountId = acct.Id,
            Name='order2',
            //Jobsite__c = jobSite.Id,
            Deliverymethod__c = 'Delivery',
            Delivery_Charge__c = 10,
            Status = 'Draft',
            Pricebook2Id = priceBook.Id,
            Start_Date__c = date.today().addDays(5),
            EffectiveDate = date.today().addDays(10),
            EndDate = date.today().addDays(15),
            Return_Date__c = date.today().addDays(20),
            Earliest_Delivery_Date__c = date.today().addDays(18),
            Opt_Out_RPP__c = false,
            Order_Initiating_Channel__c = 'SLSFRC',
            Opt_Out_Fuel_Charge__c = false,
            Selling_Channel__c = 'SBRB2B',
            Duration__c = 'Custom',
            Reservation_Order_Number__c = '12342',
            Branch__c = branchLocation.Id,
            Sourcing_Branch__c = branchLocation.Id,
            RecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('Reservation Order').getRecordTypeId()
        );
        ordersList.add(orderNoJS);
        
        // ATP order
        Order orderNoDeliveryMeth = new Order(
            Quote_Name__c = 'Test Quote no method',
            AccountId = acct.Id,
            Name='order3',
            //Jobsite__c = jobSite.Id,
            Deliverymethod__c = '',
            Delivery_Charge__c = 10,
            Status = 'Draft',
            Pricebook2Id = priceBook.Id,
            Start_Date__c = date.today().addDays(5),
            EffectiveDate = date.today().addDays(10),
            EndDate = date.today().addDays(15),
            Return_Date__c = date.today().addDays(20),
            Earliest_Delivery_Date__c = date.today().addDays(18),
            Opt_Out_RPP__c = false,
            Order_Initiating_Channel__c = 'SLSFRC',
            Opt_Out_Fuel_Charge__c = false,
            Selling_Channel__c = 'SBRB2B',
            Duration__c = 'Custom',
            Reservation_Order_Number__c = '12342',
            Branch__c = branchLocation.Id,
            Sourcing_Branch__c = branchLocation.Id,
            RecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('Reservation Order').getRecordTypeId()
        );
        ordersList.add(orderNoDeliveryMeth);
        
        // ATP order
        Order orderNoSB = new Order(
            Quote_Name__c = 'Test Quote no SB',
            AccountId = acct.Id,
            Name='order4',
            //Jobsite__c = jobSite.Id,
            Deliverymethod__c = 'Delivery',
            Delivery_Charge__c = 10,
            Status = 'Draft',
            Pricebook2Id = priceBook.Id,
            Start_Date__c = date.today().addDays(5),
            EffectiveDate = date.today().addDays(10),
            EndDate = date.today().addDays(15),
            Return_Date__c = date.today().addDays(20),
            Earliest_Delivery_Date__c = date.today().addDays(18),
            Opt_Out_RPP__c = false,
            Order_Initiating_Channel__c = 'SLSFRC',
            Opt_Out_Fuel_Charge__c = false,
            Selling_Channel__c = 'SBRB2B',
            Duration__c = 'Custom',
            Reservation_Order_Number__c = '12342',
            Branch__c = branchLocation.Id,
            //Sourcing_Branch__c = branchLocation.Id,
            RecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('Reservation Order').getRecordTypeId()
        );
        ordersList.add(orderNoSB);
       
        Order pickuporder = new Order(
            Quote_Name__c = 'Test Quote Pickup',
            AccountId = acct.Id,
            Name='order6',
            Jobsite__c = jobSite.Id,
            Deliverymethod__c = 'Pickup',
            Delivery_Charge__c = 10,
            Status = 'Draft',
            Pricebook2Id = priceBook.Id,
            Start_Date__c = date.today().addDays(5),
            EffectiveDate = date.today().addDays(10),
            EndDate = date.today().addDays(15),
            Return_Date__c = date.today().addDays(20),
            Earliest_Delivery_Date__c = date.today().addDays(18),
            Opt_Out_RPP__c = false,
            Order_Initiating_Channel__c = 'SLSFRC',
            Opt_Out_Fuel_Charge__c = false,
            Selling_Channel__c = 'SBRB2B',
            Duration__c = 'Custom',
            Reservation_Order_Number__c = '123421',
            Branch__c = branchLocation.Id,
            Sourcing_Branch__c = branchLocation.Id,
            RecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('Reservation Order').getRecordTypeId()
        );
        ordersList.add(pickuporder);
        insert ordersList;
        
        
        User_Location__c ul = new User_Location__c();
        ul.Analysis_Region__c = region.Id;
        ul.User__c = UserInfo.getUserId();
        ul.Branch__c = branchLocation.Id;
        insert ul;
        
        List<Contact> cons = SBR_3_0_TestDataFactory.createContacts(1,acct.Id,true);
        
        
        List<Product2> products = new List<Product2>();
        for(Integer i = 0; i < 3; i++) {
            Product2 product = new Product2();
            product.Name = 'Test Product ' + i;
            if(i == 0) {
                product.Product_Type__c = 'Cat-Class';
                product.Product_SKU__c = '1088773';
                product.Category__c = '32134';
                product.Class__c = '2039';
                product.ToolFlex__c = 'N';
                product.Company_code__c = '01;02';
            }
            else if(i == 1) {
                product.Product_Type__c = 'Cat-Class';
                product.Product_SKU__c = '0010030';
                product.Category__c = '32134';
                product.Class__c = '2039';
                product.ToolFlex__c = 'N';
                product.Company_code__c = '01;02';
            } else if (i == 2) {
                product.Product_Type__c = 'Parts';
                product.Item_Number__c = '8773';
                product.Stock_Class__c = '108';
                product.Company_code__c = '01';
            }
            products.add(product);
        }
        insert products;
        // Create Price Book Entry
        List<PricebookEntry> listPbe = new List<PricebookEntry>();
        
        SBR_3_0_TestDataFactory.createPriceBookEntries(products);
        
        Map<Id, Id> mapPBE = new Map<Id, Id>();
        for(PricebookEntry pbEntry : [SELECT Id,Product2Id FROM PricebookEntry WHERE Pricebook2Id = :Test.getStandardPricebookId()]) {
            if(pbEntry.Product2Id == products[0].Id){
                mapPBE.put(pbEntry.Product2Id, pbEntry.Id);
            }
            else if(pbEntry.Product2Id == products[1].Id){
                mapPBE.put(pbEntry.Product2Id, pbEntry.Id);
            }
            else if(pbEntry.Product2Id == products[2].Id){
                mapPBE.put(pbEntry.Product2Id, pbEntry.Id);
            }
        }
        // Create Order item
        List<OrderItem> orderItems = new List<OrderItem>();
        for(Integer i = 0; i < 3; i++){
            for(Integer j = 0; j < 5; j++){
            OrderItem orderItem = new OrderItem();
            orderItem.OrderId = ordersList[j].Id;
            orderItem.Selling_Price__c = 10;
            orderItem.Product2Id = products[i].Id;
            orderItem.UnitPrice = 100;
            orderItem.Item_Number__c = i;
            orderItem.Min_Rate__c = 2;
            orderItem.Daily_Rate__c = 2.0;
            orderItem.Weekly_Rate__c = 2.0;
            orderItem.Monthly_Rate__c = 2.0;
            orderItem.PricebookEntryId = mapPBE.get(products[i].Id);
            if(i == 0 || i ==1) {
                orderItem.Hourly_Rate__c = 2.0;
                orderItem.Min_Rate__c = 2.0;
                orderItem.Quantity = 5;
                orderItem.Free_Flag__c = false;
                orderItem.Suggested_Daily_Rate__c = 2.0;
                orderItem.Suggested_Weekly_Rate__c = 2.0;
                orderItem.Suggested_Monthly_Rate__c = 2.0;
                orderItem.Daily_Rate__c = 2.0;
                orderItem.Weekly_Rate__c = 2.0;
                orderItem.Monthly_Rate__c = 2.0;
                orderItem.Rates_Overriden__c = false;
                //  orderItem.Line_Comments__c = 'Comments';
                // orderItem.SBQQ__Number__c = 5;
                orderItem.Global_Line_Number__c = 123;
            } else if (i == 2) {
                orderItem.Quantity = 3;
                orderItem.Global_Line_Number__c = 456;
            }
            orderItems.add(orderItem);
        }
        }
        insert orderItems;
    }
    
    public HTTPResponse respond(HTTPRequest req) {
        System.debug('req 130'+req);
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type',SBR_3_0_Constants.APP_JSON);
        if(req.getEndpoint().endsWithIgnoreCase('token')){
            res.setBody('{"access_token":"test"}');
        }
        if(req.getEndpoint().endsWithIgnoreCase('atp/location'))
        {
            res.setBody('{ "data": { "companyId": "01", "sellingChannel": "SBRINT", "cartId": "SBRINT", "transactionType": "SBR", "closestBranchSite": "01-0001", "lastResortBranch": "01-0001", "availabilityByProducts": [ { "productId": "1088773", "uom": "EA", "availabilityByFulfillmentTypes": [ { "fulfillmentType": "DEL", "availabilityDetails": [ { "availabilityByLocations": [ { "locationType": "PC", "locationId": "01-0001", "atp": 0.0, "geoDistanceFromJobSite": 570.132 } ] } ] } ] }, { "productId": "0010030", "uom": "EA", "availabilityByFulfillmentTypes": [ { "fulfillmentType": "DEL", "availabilityDetails": [ { "availabilityByLocations": [] } ] } ] } ] } }');
        }
        if(req.getEndpoint().endsWithIgnoreCase('rates')){
            // Rates Response here
            res.setBody('{"data":{"errorCode":"0000","errorDesc":"Success","company":"01","accountNumber":"928527","jobsiteName":"","items":[{"productId":"1088773","pc":"0268","rateFlag":"B","rateFlagDescription":"Book Rates","notToExceed":"","notToExceedDescription":"No override needed for any change.","rppPercentage":".150","needPassword":"FALSE","showAllRates":"FALSE","suggestMinimalHours":".00","isConsumerCatClass":"FALSE","isSerialized":"FALSE","customerDiscountPercentageDaily":".00","customerDiscountPercentageWeekly":".00","customerDiscountPercentageMonthly":".00","showFloorRate":null,"rates":{"suggestedRates":{"minimum":"49.00","daily":"49.00","weekly":"150.00","monthly":"445.00"},"bookRates":{"minimum":"49.00","daily":"49.00","weekly":"150.00","monthly":"445.00"}}}]}}');
        } 
        if(req.getEndpoint().endsWithIgnoreCase('consumables')){
            // Consumables Response here
            res.setBody('{"data":{"suggestedItems":[{"catId":"108","classId":"8773","rentables":[],"consumables":[{"inventoryClass":"206","invClassDescription":"PPE, RESPIRATORY","specGroups":[{"specNumber":"206-0002","title":"Disposable Respirator","specDescription":"Disposable Respirator","minPrice":6,"maxPrice":6,"products":[{"productNumber":"1088773","stockClass":"108","oemStockNumber":"8773","productDescription":"N95 HARMFUL DUST RESPIRATOR 2 PACK","priceSchedule":"","sequence":"10","forceItem":"N","minQuantity":0,"sellingPrice":10,"availQuantity":25,"binNumber1":"SC3","binNumber2":"","binNumber3":"","rentalCat":"0","rentalClass":"0","isSerialized":false}]}]}]}]}}');
        }
        res.setStatusCode(200);
        System.debug('res 141 ->'+res);
        return res;
    }
    
    
    @isTest
    static void testExecuteSuccess()
    {
        Order ord = [SELECT ID FROM Order WHERE Quote_Name__c = 'Test Quote' LIMIT 1];
        List<OrderItem> listOrderLines = [Select Daily_Rate__c from OrderItem where OrderId =: ord.Id];
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_GetATPOnOrderCloneCon_Test());
        List<SBR_3_0_GetATPOnOrderCloneController.CloneRequest> cloneReqs=  new List<SBR_3_0_GetATPOnOrderCloneController.CloneRequest>();
        SBR_3_0_GetATPOnOrderCloneController.CloneRequest cloneReq= new SBR_3_0_GetATPOnOrderCloneController.CloneRequest();
        cloneReq.orderId = ord.Id;
        cloneReq.isAccountOrJobSiteChanged = true;
        cloneReq.objectName = 'Order';
        cloneReqs.add(cloneReq);
        
        List<SBR_3_0_GetATPOnOrderCloneController.cloneResponse> response = SBR_3_0_GetATPOnOrderCloneController.updateOrderLineItemsWithRates(cloneReqs);
        System.debug('testExecuteSuccess the response is->' + response);
        Test.stopTest();
        System.assertEquals(response[0].isSuccess , true);
        List<OrderItem> listQuoteLines = [Select Daily_Rate__c from OrderItem where Product2.Product_SKU__c = '1088773' and OrderId =: ord.Id];
        System.assertEquals(listQuoteLines[0].Daily_Rate__c , 49);
    }

    @isTest
    static void testWithoutJobSiteChange()
    {
        Order ord = [SELECT ID FROM Order WHERE Quote_Name__c = 'Test Quote' LIMIT 1];
        List<OrderItem> listOrderLines = [Select Daily_Rate__c from OrderItem where OrderId =: ord.Id];
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_GetATPOnOrderCloneCon_Test());
        List<SBR_3_0_GetATPOnOrderCloneController.CloneRequest> cloneReqs=  new List<SBR_3_0_GetATPOnOrderCloneController.CloneRequest>();
        SBR_3_0_GetATPOnOrderCloneController.CloneRequest cloneReq= new SBR_3_0_GetATPOnOrderCloneController.CloneRequest();
        cloneReq.orderId = ord.Id;
        cloneReq.isAccountOrJobSiteChanged = false;
        cloneReq.objectName = 'Order';
        cloneReqs.add(cloneReq);
        
        List<SBR_3_0_GetATPOnOrderCloneController.cloneResponse> response = SBR_3_0_GetATPOnOrderCloneController.updateOrderLineItemsWithRates(cloneReqs);
        System.debug('testExecuteSuccess the response is->' + response);
        Test.stopTest();
        System.assertEquals(response[0].isSuccess , true);
        List<OrderItem> listQuoteLines = [Select Daily_Rate__c from OrderItem where Product2.Product_SKU__c = '1088773' and OrderId =: ord.Id];
        System.assertEquals(listQuoteLines[0].Daily_Rate__c , 49);
    }
    
    @isTest
    static void testExecuteOrderNoJSSuccess()
    {
        Order ord = [SELECT ID FROM Order WHERE Quote_Name__c = 'Test Quote no JS' LIMIT 1];
        List<OrderItem> listOrderLines = [Select Daily_Rate__c from OrderItem where OrderId =: ord.Id];
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_GetATPOnOrderCloneCon_Test());
        List<SBR_3_0_GetATPOnOrderCloneController.CloneRequest> cloneReqs=  new List<SBR_3_0_GetATPOnOrderCloneController.CloneRequest>();
        SBR_3_0_GetATPOnOrderCloneController.CloneRequest cloneReq= new SBR_3_0_GetATPOnOrderCloneController.CloneRequest();
        cloneReq.orderId = ord.Id;
        cloneReq.isAccountOrJobSiteChanged = true;
        cloneReq.objectName = 'Order';
        cloneReqs.add(cloneReq);
        
        List<SBR_3_0_GetATPOnOrderCloneController.cloneResponse> response = SBR_3_0_GetATPOnOrderCloneController.updateOrderLineItemsWithRates(cloneReqs);
        System.debug('testExecuteSuccess the response is->' + response);
        Test.stopTest();
        System.assertEquals(response[0].isSuccess , true);
        List<OrderItem> listQuoteLines = [Select Daily_Rate__c from OrderItem where Product2.Product_SKU__c = '1088773' and OrderId =: ord.Id];
        System.assertEquals(listQuoteLines[0].Daily_Rate__c , 49);
    }
    
    
    @isTest
    static void testExecuteOrderNoBranchSuccess()
    {
        Order ord = [SELECT ID FROM Order WHERE Quote_Name__c = 'Test Quote no method' LIMIT 1];
        List<OrderItem> listOrderLines = [Select Daily_Rate__c from OrderItem where OrderId =: ord.Id];
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_GetATPOnOrderCloneCon_Test());
        List<SBR_3_0_GetATPOnOrderCloneController.CloneRequest> cloneReqs=  new List<SBR_3_0_GetATPOnOrderCloneController.CloneRequest>();
        SBR_3_0_GetATPOnOrderCloneController.CloneRequest cloneReq= new SBR_3_0_GetATPOnOrderCloneController.CloneRequest();
        cloneReq.orderId = ord.Id;
        cloneReq.isAccountOrJobSiteChanged = true;
        cloneReq.objectName = 'Order';
        cloneReqs.add(cloneReq);
        
        List<SBR_3_0_GetATPOnOrderCloneController.cloneResponse> response = SBR_3_0_GetATPOnOrderCloneController.updateOrderLineItemsWithRates(cloneReqs);
        System.debug('testExecuteSuccess the response is->' + response);
        Test.stopTest();
        System.assertEquals(response[0].isSuccess , true);
        List<OrderItem> listQuoteLines = [Select Daily_Rate__c from OrderItem where Product2.Product_SKU__c = '1088773' and OrderId =: ord.Id];
        System.assertEquals(listQuoteLines[0].Daily_Rate__c , 49);
        
    }
    
    @isTest
    static void testExecuteOrderNoSBSuccess()
    {
        Order ord = [SELECT ID FROM Order WHERE Quote_Name__c = 'Test Quote no SB' LIMIT 1];
        List<OrderItem> listOrderLines = [Select Daily_Rate__c from OrderItem where OrderId =: ord.Id];
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_GetATPOnOrderCloneCon_Test());
        List<SBR_3_0_GetATPOnOrderCloneController.CloneRequest> cloneReqs=  new List<SBR_3_0_GetATPOnOrderCloneController.CloneRequest>();
        SBR_3_0_GetATPOnOrderCloneController.CloneRequest cloneReq= new SBR_3_0_GetATPOnOrderCloneController.CloneRequest();
        cloneReq.orderId = ord.Id;
        cloneReq.isAccountOrJobSiteChanged = true;
        cloneReq.objectName = 'Order';
        cloneReqs.add(cloneReq);
        
        List<SBR_3_0_GetATPOnOrderCloneController.cloneResponse> response = SBR_3_0_GetATPOnOrderCloneController.updateOrderLineItemsWithRates(cloneReqs);
        System.debug('testExecuteSuccess the response is->' + response);
        Test.stopTest();
        System.assertEquals(response[0].isSuccess , true);
        List<OrderItem> listQuoteLines = [Select Daily_Rate__c from OrderItem where Product2.Product_SKU__c = '1088773' and OrderId =: ord.Id];
        System.assertEquals(listQuoteLines[0].Daily_Rate__c , 49);
        
    }
    
    @isTest
    static void testExecutePickupOrderSuccess()
    {
        Order ord = [SELECT ID FROM Order WHERE Deliverymethod__c = 'Pickup' LIMIT 1];
        List<OrderItem> listOrderLines = [Select Daily_Rate__c from OrderItem where OrderId =: ord.Id];
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_GetATPOnOrderCloneCon_Test());
        List<SBR_3_0_GetATPOnOrderCloneController.CloneRequest> cloneReqs=  new List<SBR_3_0_GetATPOnOrderCloneController.CloneRequest>();
        SBR_3_0_GetATPOnOrderCloneController.CloneRequest cloneReq= new SBR_3_0_GetATPOnOrderCloneController.CloneRequest();
        cloneReq.orderId = ord.Id;
        cloneReq.isAccountOrJobSiteChanged = true;
        cloneReq.objectName = 'Order';
        cloneReqs.add(cloneReq);
        
        List<SBR_3_0_GetATPOnOrderCloneController.cloneResponse> response = SBR_3_0_GetATPOnOrderCloneController.updateOrderLineItemsWithRates(cloneReqs);
        System.debug('testExecuteSuccess the response is->' + response);
        Test.stopTest();
        System.assertEquals(response[0].isSuccess , true);
        List<OrderItem> listQuoteLines = [Select Daily_Rate__c from OrderItem where Product2.Product_SKU__c = '1088773' and OrderId =: ord.Id];
        System.assertEquals(listQuoteLines[0].Daily_Rate__c , 49);
        
    }

    @isTest
    static void testExecuteFailure()
    {
        List<SBR_3_0_GetATPOnOrderCloneController.cloneResponse> response;
        try{
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_GetATPOnOrderCloneCon_Test());
        List<SBR_3_0_GetATPOnOrderCloneController.CloneRequest> cloneReqs=  new List<SBR_3_0_GetATPOnOrderCloneController.CloneRequest>();
        SBR_3_0_GetATPOnOrderCloneController.CloneRequest cloneReq= new SBR_3_0_GetATPOnOrderCloneController.CloneRequest();
        cloneReq.orderId = null;
        cloneReq.isAccountOrJobSiteChanged = true;
        cloneReq.objectName = 'Order';
        cloneReqs.add(cloneReq);
        
        response = SBR_3_0_GetATPOnOrderCloneController.updateOrderLineItemsWithRates(cloneReqs);
        System.debug('testExecuteSuccess the response is->' + response);
        Test.stopTest();
        }
        catch(Exception e){
            System.assertEquals(response[0].isSuccess , true);
        }
       
    }
    
    
}