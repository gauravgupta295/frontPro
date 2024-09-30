/**
* @description       : 
* @author            : ChangeMeIn@UserSettingsUnder.SFDoc
* @group             : 
* @last modified on  : 12-27-2023
* @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@isTest
public with sharing class SBR_3_0_GetATPOnQuoteCloneCon_Test implements HttpCalloutMock {
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
        List<SBQQ__Quote__c> quoteList = new List<SBQQ__Quote__c>();
        SBQQ__Quote__c quote = new SBQQ__Quote__c(
            Quote_Name__c = 'Test Quote',
            SBQQ__Account__c = acct.Id,
            Jobsite__c = jobSite.Id,
            SBQQ__DeliveryMethod__c = 'Delivery',
            Start_Date__c = date.valueOf('2025-10-07 12:00:00'),
            End_Date__c = date.valueOf('2025-10-07 12:00:00'),
            Delivery_Date__c  = date.valueOf('2024-10-08 12:00:00'),
            Opt_Out_RPP__c = false,
            Opt_Out_Fuel_Charge__c = false,
            Selling_Channel__c = 'SBRB2B',
            Rentalman_Quote_Id__c = 'Test QId',
            Company_Code__c = '01',
            Show_Crew_Expense_Calculator__c = true,
            Branch__c = branchLocation.Id,
            Sourcing_Branch__c = branchLocation.Id
        );
        quoteList.add(quote);
        
        // Quote without a jobsite
        SBQQ__Quote__c quoteWithNoJobSite = new SBQQ__Quote__c(
            Quote_Name__c = 'Test Quote no JS',
            SBQQ__Account__c = acct.Id,
            Jobsite__c = null,
            SBQQ__DeliveryMethod__c = 'Delivery',
            Start_Date__c = date.valueOf('2024-10-07 12:00:00'),
            End_Date__c = date.valueOf('2024-10-07 12:00:00'),
            Delivery_Date__c  = date.valueOf('2025-10-08 12:00:00'),
            Opt_Out_RPP__c = false,
            Opt_Out_Fuel_Charge__c = false,
            Selling_Channel__c = 'SBRB2B',
            Rentalman_Quote_Id__c = 'Test QIdNoJS',
            Company_Code__c = '01',
            Show_Crew_Expense_Calculator__c = true,
            Branch__c = branchLocation.Id,
            Sourcing_Branch__c = branchLocation.Id
        );
        quoteList.add(quoteWithNoJobSite);
        
        // Quote without a sourcing branch
        SBQQ__Quote__c quoteWithNoSourcingBranch = new SBQQ__Quote__c(
            Quote_Name__c = 'Test Quote no SB',
            SBQQ__Account__c = acct.Id,
            Jobsite__c = null,
            SBQQ__DeliveryMethod__c = 'Delivery',
            Start_Date__c = date.valueOf('2024-10-07 12:00:00'),
            End_Date__c = date.valueOf('2024-10-07 12:00:00'),
            Delivery_Date__c  = date.valueOf('2024-10-08 12:00:00'),
            Opt_Out_RPP__c = false,
            Opt_Out_Fuel_Charge__c = false,
            Selling_Channel__c = 'SBRB2B',
            Rentalman_Quote_Id__c = 'Test QIdNOSB',
            Company_Code__c = '01',
            Show_Crew_Expense_Calculator__c = true,
            Branch__c = branchLocation.Id,
            Sourcing_Branch__c = null
        );
        quoteList.add(quoteWithNoSourcingBranch);
        
        // Quote no pickup and no delivery
        SBQQ__Quote__c quoteWithNoDeliveryMeth = new SBQQ__Quote__c(
            Quote_Name__c = 'Test Quote no method',
            SBQQ__Account__c = acct.Id,
            Jobsite__c = null,
            SBQQ__DeliveryMethod__c = '',
            Start_Date__c = date.valueOf('2024-10-07 12:00:00'),
            End_Date__c = date.valueOf('2024-10-07 12:00:00'),
            Delivery_Date__c  = date.valueOf('2024-10-08 12:00:00'),
            Opt_Out_RPP__c = false,
            Opt_Out_Fuel_Charge__c = false,
            Selling_Channel__c = 'SBRB2B',
            Rentalman_Quote_Id__c = 'Test QIdNOMeth',
            Company_Code__c = '01',
            Show_Crew_Expense_Calculator__c = true,
            Branch__c = branchLocation.Id,
            Sourcing_Branch__c = null
        );
        quoteList.add(quoteWithNoDeliveryMeth);
        
        SBQQ__Quote__c pickupQuote = new SBQQ__Quote__c(
            Quote_Name__c = 'Pickup Quote',
            SBQQ__Account__c = acct.Id,
            Jobsite__c = jobSite.Id,
            SBQQ__DeliveryMethod__c = 'Pickup',
            Start_Date__c = date.valueOf('2024-10-07 12:00:00'),
            End_Date__c = date.valueOf('2024-10-07 12:00:00'),
            Delivery_Date__c  = date.valueOf('2024-10-08 12:00:00'),
            Opt_Out_RPP__c = false,
            Opt_Out_Fuel_Charge__c = false,
            Selling_Channel__c = 'SBRB2B',
            Rentalman_Quote_Id__c = 'Test QId123',
            Company_Code__c = '01',
            Show_Crew_Expense_Calculator__c = true,
            Branch__c = branchLocation.Id,
            Sourcing_Branch__c = branchLocation.Id
        );
        quoteList.add(pickupQuote);
        insert quoteList; 
        
        User_Location__c ul = new User_Location__c();
        ul.Analysis_Region__c = region.Id;
        ul.User__c = UserInfo.getUserId();
        ul.Branch__c = branchLocation.Id;
        insert ul;
        
        List<Contact> cons = SBR_3_0_TestDataFactory.createContacts(1,acct.Id,true);
        
        
        List<Product2> listProducts= new List<Product2>();
        Product2 catClassProdcuct = SBR_3_0_TestDataFactory.createProducts(1, false)[0];
        catClassProdcuct.Product_SKU__c = '1088773';
        catClassProdcuct.Name = 'Test Product 1';
        catClassProdcuct.Product_Title_Internal__c = 'Test Product 1';
        catClassProdcuct.Product_Type__c = 'Cat-Class';
        listProducts.add(catClassProdcuct);
        
        
        Product2 catClassProdcuct1 = SBR_3_0_TestDataFactory.createProducts(1, false)[0];
        catClassProdcuct1.Product_SKU__c = '0010030';
        catClassProdcuct1.Name = 'Test Product 3';
        catClassProdcuct1.Product_Title_Internal__c = 'Test Product 3';
        catClassProdcuct1.Product_Type__c = 'Cat-Class';
        listProducts.add(catClassProdcuct1);
        
        Product2 merchandiseProdcuct = SBR_3_0_TestDataFactory.createProducts(1, false)[0];
        merchandiseProdcuct.Product_SKU__c = '01-PIPSA-817633';
        merchandiseProdcuct.Name = 'Test Product 2';
        merchandiseProdcuct.Product_Title_Internal__c = 'Test Product 2';
        merchandiseProdcuct.Product_Type__c = 'Parts';
        merchandiseProdcuct.Stock_Class__c = 'PIPSA';
        merchandiseProdcuct.Item_Number__c = '10102481';
        listProducts.add(merchandiseProdcuct);
        Insert listProducts;
        
        List<SBQQ__QuoteLine__c> lineItems = new List<SBQQ__QuoteLine__c>();
        for(Integer i = 0; i < 5; i++){
            SBQQ__QuoteLine__c qline = new SBQQ__QuoteLine__c();
            qline.SBQQ__Quote__c = quoteList[i].Id;
            qline.SBQQ__Product__c = listProducts[0].Id;
            lineItems.add(qline);
        }
        
        for(Integer i = 0; i < 5; i++){
            SBQQ__QuoteLine__c qline = new SBQQ__QuoteLine__c();
            qline.SBQQ__Quote__c = quoteList[i].Id;
            qline.SBQQ__Product__c = listProducts[1].Id;
            lineItems.add(qline);
        }
        
        for(Integer i = 0; i < 5; i++){
            SBQQ__QuoteLine__c qline = new SBQQ__QuoteLine__c();
            qline.SBQQ__Quote__c = quoteList[i].Id;
            qline.SBQQ__Product__c = listProducts[2].Id;
            lineItems.add(qline);
        }
        insert lineItems;
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
            res.setBody('{"data":{"suggestedItems":[{"catId":"108","classId":"8773","rentables":[],"consumables":[{"inventoryClass":"206","invClassDescription":"PPE, RESPIRATORY","specGroups":[{"specNumber":"206-0002","title":"Disposable Respirator","specDescription":"Disposable Respirator","minPrice":6,"maxPrice":6,"products":[{"productNumber":"01-PIPSA-817633","stockClass":"PIPSA","oemStockNumber":"10102481","productDescription":"N95 HARMFUL DUST RESPIRATOR 2 PACK","priceSchedule":"","sequence":"10","forceItem":"N","minQuantity":0,"sellingPrice":10,"availQuantity":25,"binNumber1":"SC3","binNumber2":"","binNumber3":"","rentalCat":"0","rentalClass":"0","isSerialized":false}]}]}]}]}}');
        }
        res.setStatusCode(200);
        System.debug('res 141 ->'+res);
        return res;
    }
    
    
    @isTest
    static void testExecuteSuccess()
    {
        SBQQ__Quote__c quote = [SELECT ID FROM SBQQ__Quote__c WHERE Quote_Name__c = 'Test Quote' LIMIT 1];
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_GetATPOnQuoteCloneCon_Test());
        List<SBR_3_0_GetATPOnQuoteCloneController.CloneRequest> cloneReqs=  new List<SBR_3_0_GetATPOnQuoteCloneController.CloneRequest>();
        SBR_3_0_GetATPOnQuoteCloneController.CloneRequest cloneReq= new SBR_3_0_GetATPOnQuoteCloneController.CloneRequest();
        cloneReq.quoteId = quote.Id;
        cloneReq.isAccountOrJobSiteChanged = true;
        cloneReq.objectName = 'SBQQ__Quote__c';
        cloneReqs.add(cloneReq);
        
        List<SBR_3_0_GetATPOnQuoteCloneController.cloneResponse> response = SBR_3_0_GetATPOnQuoteCloneController.updateQuoteLineItemsWithRates(cloneReqs);
        System.debug('testExecuteSuccess the response is->' + response);
        Test.stopTest();
        System.assertEquals(response[0].isSuccess , true);
        List<SBQQ__QuoteLine__c> listQuoteLines = [Select Daily_Rate__c from SBQQ__QuoteLine__c where SBQQ__Product__r.Product_SKU__c = '1088773' and SBQQ__Quote__c =: quote.Id];
        System.assertEquals(listQuoteLines[0].Daily_Rate__c , 49);
    }
    
    @isTest
    static void testWithoutJobSiteChange()
    {
        SBQQ__Quote__c quote = [SELECT ID FROM SBQQ__Quote__c WHERE Quote_Name__c = 'Test Quote' LIMIT 1];
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_GetATPOnQuoteCloneCon_Test());
        List<SBR_3_0_GetATPOnQuoteCloneController.CloneRequest> cloneReqs=  new List<SBR_3_0_GetATPOnQuoteCloneController.CloneRequest>();
        SBR_3_0_GetATPOnQuoteCloneController.CloneRequest cloneReq= new SBR_3_0_GetATPOnQuoteCloneController.CloneRequest();
        cloneReq.quoteId = quote.Id;
        cloneReq.isAccountOrJobSiteChanged = false;
        cloneReq.objectName = 'SBQQ__Quote__c';
        cloneReqs.add(cloneReq);
        
        List<SBR_3_0_GetATPOnQuoteCloneController.cloneResponse> response = SBR_3_0_GetATPOnQuoteCloneController.updateQuoteLineItemsWithRates(cloneReqs);
        System.debug('testExecuteSuccess the response is->' + response);
        Test.stopTest();
        System.assertEquals(response[0].isSuccess , true);
        List<SBQQ__QuoteLine__c> listQuoteLines = [Select Daily_Rate__c from SBQQ__QuoteLine__c where SBQQ__Product__r.Product_SKU__c = '1088773'  and SBQQ__Quote__c =: quote.Id];
        System.assertEquals(listQuoteLines[0].Daily_Rate__c , 49);
    }
    
    @isTest
    static void testExecuteOrderNoJSSuccess()
    {
        SBQQ__Quote__c quote = [SELECT ID FROM SBQQ__Quote__c WHERE Quote_Name__c = 'Test Quote no JS' LIMIT 1];
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_GetATPOnQuoteCloneCon_Test());
        List<SBR_3_0_GetATPOnQuoteCloneController.CloneRequest> cloneReqs=  new List<SBR_3_0_GetATPOnQuoteCloneController.CloneRequest>();
        SBR_3_0_GetATPOnQuoteCloneController.CloneRequest cloneReq= new SBR_3_0_GetATPOnQuoteCloneController.CloneRequest();
        cloneReq.quoteId = quote.Id;
        cloneReq.isAccountOrJobSiteChanged = true;
        cloneReq.objectName = 'SBQQ__Quote__c';
        cloneReqs.add(cloneReq);
        
        List<SBR_3_0_GetATPOnQuoteCloneController.cloneResponse> response = SBR_3_0_GetATPOnQuoteCloneController.updateQuoteLineItemsWithRates(cloneReqs);
        System.debug('testExecuteSuccess the response is->' + response);
        Test.stopTest();
        System.assertEquals(response[0].isSuccess , true);
        List<SBQQ__QuoteLine__c> listQuoteLines = [Select Daily_Rate__c from SBQQ__QuoteLine__c where SBQQ__Product__r.Product_SKU__c = '1088773'  and SBQQ__Quote__c =: quote.Id];
        System.assertEquals(listQuoteLines[0].Daily_Rate__c , 49);
    }
    
    
    @isTest
    static void testExecuteOrderNoBranchSuccess()
    {
        SBQQ__Quote__c quote = [SELECT ID FROM SBQQ__Quote__c WHERE Quote_Name__c = 'Test Quote no method' LIMIT 1];
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_GetATPOnQuoteCloneCon_Test());
        List<SBR_3_0_GetATPOnQuoteCloneController.CloneRequest> cloneReqs=  new List<SBR_3_0_GetATPOnQuoteCloneController.CloneRequest>();
        SBR_3_0_GetATPOnQuoteCloneController.CloneRequest cloneReq= new SBR_3_0_GetATPOnQuoteCloneController.CloneRequest();
        cloneReq.quoteId = quote.Id;
        cloneReq.isAccountOrJobSiteChanged = true;
        cloneReq.objectName = 'SBQQ__Quote__c';
        cloneReqs.add(cloneReq);
        
        List<SBR_3_0_GetATPOnQuoteCloneController.cloneResponse> response = SBR_3_0_GetATPOnQuoteCloneController.updateQuoteLineItemsWithRates(cloneReqs);
        System.debug('testExecuteSuccess the response is->' + response);
        Test.stopTest();
        System.assertEquals(response[0].isSuccess , true);
        List<SBQQ__QuoteLine__c> listQuoteLines = [Select Daily_Rate__c from SBQQ__QuoteLine__c where SBQQ__Product__r.Product_SKU__c = '1088773'  and SBQQ__Quote__c =: quote.Id];
        System.assertEquals(listQuoteLines[0].Daily_Rate__c , 49);
        
    }
    
    @isTest
    static void testExecuteOrderNoSBSuccess()
    {
        SBQQ__Quote__c quote = [SELECT ID FROM SBQQ__Quote__c WHERE Quote_Name__c = 'Test Quote no SB' LIMIT 1];
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_GetATPOnQuoteCloneCon_Test());
        List<SBR_3_0_GetATPOnQuoteCloneController.CloneRequest> cloneReqs=  new List<SBR_3_0_GetATPOnQuoteCloneController.CloneRequest>();
        SBR_3_0_GetATPOnQuoteCloneController.CloneRequest cloneReq= new SBR_3_0_GetATPOnQuoteCloneController.CloneRequest();
        cloneReq.quoteId = quote.Id;
        cloneReq.isAccountOrJobSiteChanged = true;
        cloneReq.objectName = 'SBQQ__Quote__c';
        cloneReqs.add(cloneReq);
        
        List<SBR_3_0_GetATPOnQuoteCloneController.cloneResponse> response = SBR_3_0_GetATPOnQuoteCloneController.updateQuoteLineItemsWithRates(cloneReqs);
        System.debug('testExecuteSuccess the response is->' + response);
        Test.stopTest();
        System.assertEquals(response[0].isSuccess , true);
        List<SBQQ__QuoteLine__c> listQuoteLines = [Select Daily_Rate__c from SBQQ__QuoteLine__c where SBQQ__Product__r.Product_SKU__c = '1088773'  and SBQQ__Quote__c =: quote.Id];
        System.assertEquals(listQuoteLines[0].Daily_Rate__c , 49);
        
    }
    
    @isTest
    static void testExecutePickupOrderSuccess()
    {
        SBQQ__Quote__c quote = [SELECT ID FROM SBQQ__Quote__c WHERE SBQQ__DeliveryMethod__c = 'Pickup'  LIMIT 1];
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_GetATPOnQuoteCloneCon_Test());
        List<SBR_3_0_GetATPOnQuoteCloneController.CloneRequest> cloneReqs=  new List<SBR_3_0_GetATPOnQuoteCloneController.CloneRequest>();
        SBR_3_0_GetATPOnQuoteCloneController.CloneRequest cloneReq= new SBR_3_0_GetATPOnQuoteCloneController.CloneRequest();
        cloneReq.quoteId = quote.Id;
        cloneReq.isAccountOrJobSiteChanged = true;
        cloneReq.objectName = 'SBQQ__Quote__c';
        cloneReqs.add(cloneReq);
        
        List<SBR_3_0_GetATPOnQuoteCloneController.cloneResponse> response = SBR_3_0_GetATPOnQuoteCloneController.updateQuoteLineItemsWithRates(cloneReqs);
        System.debug('testExecuteSuccess the response is->' + response);
        Test.stopTest();
        System.assertEquals(response[0].isSuccess , true);
        List<SBQQ__QuoteLine__c> listQuoteLines = [Select Daily_Rate__c from SBQQ__QuoteLine__c where SBQQ__Product__r.Product_SKU__c = '1088773'  and SBQQ__Quote__c =: quote.Id];
        System.assertEquals(listQuoteLines[0].Daily_Rate__c , 49);
        
    }
    
    @isTest
    static void testExecuteError()
    {
        List<SBR_3_0_GetATPOnQuoteCloneController.cloneResponse> response;
        try{
            SBQQ__Quote__c quote = [SELECT ID FROM SBQQ__Quote__c WHERE Quote_Name__c = 'Test Quote' LIMIT 1];
            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new SBR_3_0_GetATPOnQuoteCloneCon_Test());
            List<SBR_3_0_GetATPOnQuoteCloneController.CloneRequest> cloneReqs=  new List<SBR_3_0_GetATPOnQuoteCloneController.CloneRequest>();
            SBR_3_0_GetATPOnQuoteCloneController.CloneRequest cloneReq= new SBR_3_0_GetATPOnQuoteCloneController.CloneRequest();
            cloneReq.quoteId = null;
            cloneReq.isAccountOrJobSiteChanged = true;
            cloneReq.objectName = 'SBQQ__Quote__c';
            cloneReqs.add(cloneReq);
            
            response = SBR_3_0_GetATPOnQuoteCloneController.updateQuoteLineItemsWithRates(cloneReqs);
            System.debug('testExecuteSuccess the response is->' + response);
            Test.stopTest();
        }
        catch(exception e){
            System.assertEquals(response[0].isSuccess , false);
        }
    }
    
}