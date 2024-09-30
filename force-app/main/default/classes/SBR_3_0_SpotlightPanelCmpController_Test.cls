/*********************************************************************************************************************
* Apex Class: SBR_3_0_SpotlightPanelCmpController_Test
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Test class for SBR_3_0_SpotlightPanelCmpController
* - SAL-1752
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
1.0         Avinash Rao           2022-05-05            Initial version
2.0         Konrad Haight         2022-08-18            Added Tests  
3.0         Hamza Askour          2023-06-14            Added Tests
*********************************************************************************************************************/
@isTest
public with sharing class SBR_3_0_SpotlightPanelCmpController_Test {
    @TestSetup
    static void makeData() {
        Product_Hierarchy__c prdHierachy = new Product_Hierarchy__c(
            Name = 'Test Hierarchy',
            Product_Hierarchy_Code__c = 'Test_HR_Code',
            RecordTypeId = SBR_3_0_Constants.PRODUCT_HIERARCHY_PRODUCT_SUB_CATEGORY_RT_ID
        );
        insert prdHierachy;
        
        List<SBQQ__Quote__c> quotes = SBR_3_0_TestDataFactory.createQuotes(
            1,
            false,
            'Sales_Quote'
        );
        insert quotes;
        
        User u = new User(id = userinfo.getuserId());
        u.Department = '1';
        u.CompanyName = '01';
        update u;
        Credential__c cred = SBR_3_0_TestDataFactory.createCredentials(1, false)[0];
        cred.Name = 'Mule_Token_Endpoint';
        cred.Key_Id__c = 'keyid';
        cred.Secret__c = 'credSecret';
        insert cred;
        
        RecordType skuRecordType = [
            SELECT Id, Name
            FROM RecordType
            WHERE SobjectType = 'Product2' AND Name = 'SKU'
        ];
        System.debug('record type ID = ' + skuRecordType.Id);
        
        List<Product2> products = SBR_3_0_TestDataFactory.createProducts(3, false);
        for (Integer i = 0; i < products.size(); i++) {
            Integer j = i + 1;
            products[i].Name = 'Test Product';
            products[i].Sell_Price__c = 10;
            products[i].Product_SKU__c = j + '234567';
            products[i].Company_Code__c = '01';
            products[i].Product_Hierarchy__c = prdHierachy.Id;
            products[i].RecordTypeId = skuRecordType.Id;
        }
        products[1].Name = 'Test Optional SKU';
        products[2].Name = 'Test Without Product SKU';
        products[2].Product_SKU__c = null;
        insert products;
        
        List<Asset> assetsList = SBR_3_0_TestDataFactory.createAssets(1, false);
      	assetsList[0].Product2Id = products[0].Id;
        insert assetsList; 
        
        List<SBQQ__ProductFeature__c> features = new List<SBQQ__ProductFeature__c>();
        SBQQ__ProductFeature__c feature1 = new SBQQ__ProductFeature__c();
        feature1.Name = 'Sales Addons';
        feature1.SBQQ__Number__c = 1;
        feature1.SBQQ__ConfiguredSKU__c = products[0].Id;
        features.add(feature1);
        
        SBQQ__ProductFeature__c feature2 = new SBQQ__ProductFeature__c();
        feature2.Name = 'Rental Addons';
        feature2.SBQQ__Number__c = 2;
        feature2.SBQQ__ConfiguredSKU__c = products[0].Id;
        features.add(feature2);
        
        SBQQ__ProductFeature__c feature3 = new SBQQ__ProductFeature__c();
        feature3.Name = 'Forced Item';
        feature3.SBQQ__Number__c = 3;
        feature3.SBQQ__ConfiguredSKU__c = products[0].Id;
        features.add(feature3);
        
        insert features;
        
        List<SBQQ__ProductOption__c> options = new List<SBQQ__ProductOption__c>();
        SBQQ__ProductOption__c option1 = new SBQQ__ProductOption__c();
        option1.SBQQ__ConfiguredSKU__c = products[0].Id;
        option1.SBQQ__OptionalSKU__c = products[0].Id;
        option1.SBQQ__Feature__c = features[0].Id;
        option1.SBQQ__Number__c = 1;
        option1.Company_Code__c = '01';
        
        options.add(option1);
        
        SBQQ__ProductOption__c option2 = new SBQQ__ProductOption__c();
        option2.SBQQ__ConfiguredSKU__c = products[0].Id;
        option2.SBQQ__OptionalSKU__c = products[0].Id;
        option2.SBQQ__Feature__c = features[1].Id;
        option2.SBQQ__Number__c = 2;
        option2.Company_Code__c = '01';
        options.add(option2);
        
        SBQQ__ProductOption__c option3 = new SBQQ__ProductOption__c();
        option3.SBQQ__ConfiguredSKU__c = products[0].Id;
        option3.SBQQ__OptionalSKU__c = products[0].Id;
        option3.SBQQ__Feature__c = features[2].Id;
        option3.SBQQ__Number__c = 3;
        option3.Company_Code__c = '01';
        
        options.add(option3);
        insert options;
        
        Account acct = new Account();
        acct.RM_Account_Number__c = '4';
        acct.Company_Code__c = '01';
        acct.Name = 'Test Account';
        acct.Record_Type_Text__c = 'Credit';
        acct.E_mail_Address__c = '123@asdf.com';
        acct.Phone = '1234567890';
        acct.BillingStreet = '123 Main Street';
        acct.BillingCity = 'Toronto';
        acct.BillingPostalCode = 'M9N7V5';
        acct.BillingState = 'ON';
        acct.BillingCountry = 'CA';
        acct.Drivers_License__c = 'AKF';
        acct.Driver_s_License_State__c = 'AL';
        insert acct;
        
        // Create Analysis Region
        Analysis_Region__c region = new Analysis_Region__c();
        region.Analysis_Region_Key__c = '001';
        region.Name = 'Test Region';
        region.Company_Code__c = '01';
        insert region;
        
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
        jobLocation.Analysis_Region_Key__c = '921';
        jobLocation.Company_Code__c = '01';
        jobLocation.Branch_Location_Number__c ='0123';
        jobLocation.Phone__c = '11231231234';
        insert jobLocation;
        
        // Create Branch
        Schema.Location branchLocation = new Schema.Location();
        branchLocation.Branch_Location_Number__c = '720';
        branchLocation.Name = 'Test Branch Location';
        branchLocation.Street_Address__c = '12 Main Street';
        branchLocation.City__c = 'Toronto';
        branchLocation.Zip_Code__c = 'M7N7B3';
        branchLocation.State__c = 'ON';
        branchLocation.Country__c = 'CA';
        branchLocation.Job_Number__c = '332112';
        branchLocation.RecordTypeId = SBR_3_0_Constants.LOCATION_BRANCH_RT_ID;
        branchLocation.Company_Code__c = 'X';
        branchLocation.Time_Zone_Name__c = 'America/Chicago';
        branchLocation.Time_Zone__c = 3;
        branchLocation.OMS_Sourcing_Enabled__c = true;
        insert branchLocation;
        
        // Create Job Site
        AssociatedLocation jobSite = new AssociatedLocation(
            Name__c = 'Test Job Site',
            ParentRecordId = acct.Id,
            LocationId = jobLocation.Id,
            Branch__c = branchLocation.Id,
            Job_Number__c = '20221004A',
            Job_Site_Id__c = '123432'
        );
        insert jobSite;
        
        // Create Price Book
        Pricebook2 priceBook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update priceBook;
        
        // Create Order
        Order order = new Order(
            Quote_Name__c = 'Test Quote',
            AccountId = acct.Id,
            Jobsite__c = jobSite.Id,
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
            Using_3rd_Party__c = false,
            Order_Initiating_Channel__c = 'SF',
            Delivery_Charges_Override__c = false,
            Pickup_Charges_Override__c = false,
            //Duration__c = 'Custom',
            Branch__c = branchLocation.Id,
            Sourcing_Branch__c = branchLocation.Id
        );
        insert order;
        
       /* Id quoteRecType = Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosByDeveloperName()
            .get('Rate_Quote')
            .getRecordTypeId();
        SBQQ__Quote__c quote = SBR_3_0_TestDataFactory.createQuoteWithSourcingBranch(
            true,
            'Test Order Blanla 234',
            quoteRecType
        );
        SBQQ__Quote__c quoteUpdated = new SBQQ__Quote__c(
            Id = quote.Id,
            Branch__c = branchLocation.Id
        );
        update quoteUpdated;*/
    }
    @isTest
    static void testHasAddLinesAccessWithOrder() {
        Order orderResult = [SELECT Id, Name FROM Order LIMIT 1];
        Test.startTest();
        Boolean result = SBR_3_0_SpotlightPanelCmpController.hasAddLinesAccess(
            orderResult.Id
        );
        Test.stopTest();
        System.assertEquals(result, true);
    }
    
    @isTest
    static void testHasAddLinesAccessWithQuote() {
        SBQQ__Quote__c quote = [SELECT Id, Name FROM SBQQ__Quote__c LIMIT 1];
        Test.startTest();
        Boolean result = SBR_3_0_SpotlightPanelCmpController.hasAddLinesAccess(
            quote.Id
        );
        Test.stopTest();
        System.assertEquals(result, true);
    }
    
    /*  @isTest
static void testCreateLineItems(){
Order order = [SELECT Id, Name FROM Order LIMIT 1];
List<OrderItem> orderItems = new List<OrderItem>();
OrderItem orderItem = new OrderItem(
OrderId = order.Id,
Quantity = 3,
UnitPrice = 1
);

Test.startTest();
List<SObject> result = SBR_3_0_SpotlightPanelCmpController.createLineItems('Order',(Object)orderItem);
Test.stopTest();
} */
    
    @isTest
    static void testGetProductDetails() {
        List<Product2> products = [
            SELECT Id, Name
            FROM Product2
            WHERE Name = 'Test Product'
        ];
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_SpotlightCalloutMock());
        Test.startTest();
        SBR_3_0_SpotlightPanelCmpController.Product_Details productDetails = (SBR_3_0_SpotlightPanelCmpController.Product_Details) JSON.deserializeStrict(
            SBR_3_0_SpotlightPanelCmpController.getProductDetails(products[0].Id),
            SBR_3_0_SpotlightPanelCmpController.Product_Details.class
        );
        SBR_3_0_SpotlightPanelCmpController spc = new SBR_3_0_SpotlightPanelCmpController();
        SBR_3_0_SpotlightPanelCmpController.getAllProductDetails();
        Test.stopTest();
        
        System.assertEquals(products[0].Name, productDetails.Name);
    }
    
    @isTest
    static void testGetBulkProductDetails() {
        List<Product2> products = [
            SELECT Id, Name
            FROM Product2
            WHERE Name = 'Test Product'
        ];
        List<Id> productIds = new List<Id>();
        productIds.add(products[0].Id);
        String customerNumber = '';
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_SpotlightCalloutMock());
        List<SBR_3_0_SpotlightPanelCmpController.AddOn_Details> bulkProductDetails = SBR_3_0_SpotlightPanelCmpController.getBulkProductDetails(
            productIds,
            customerNumber
        );
        Test.stopTest();
        
        System.assertEquals(products[0].Name, bulkProductDetails[0].name);
    }
    @isTest
    static void testGetBulkAssetProductDetails() {
        /*List<Asset> assetsList = SBR_3_0_TestDataFactory.createAssets(1, false);
        insert assetsList;
        
        List<Asset> assetIds = [
            SELECT id, name, product2.Product_SKU__c
            FROM asset
            WHERE id = :assetsList[0].Id
        ];
       
        List<Product2> products = [
            SELECT Id, Name, Product_SKU__c
            FROM Product2
            WHERE Name = 'Test Product'
        ];
        assetIds[0].Product2Id = products[0].Id;
        update assetIds;
        */
        List<Asset> assetIds = [select id from Asset]; 
        List<Id> listIds = new List<Id>();
        listIds.add(assetIds[0].Id);
        String customerNumber = '';
        
        
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_SpotlightCalloutMock());
         Test.startTest(); 
        List<SBR_3_0_SpotlightPanelCmpController.AddOn_Details> bulkProductDetails = (List<SBR_3_0_SpotlightPanelCmpController.AddOn_Details>) JSON.deserializeStrict(
            SBR_3_0_SpotlightPanelCmpController.getBulkAssetsProductDetails(
                listIds,
                customerNumber
            ),
            List<SBR_3_0_SpotlightPanelCmpController.AddOn_Details>.class
        );
        Test.stopTest();
        
        // System.assertEquals(assetsList[0].Name, bulkProductDetails[0].name);
    }
    @isTest
    static void testGetProductAddOns() {
        List<Product2> products = [
            SELECT Id, Name
            FROM Product2
            WHERE Name = 'Test Product'
        ];
        List<Product2> products2 = [
            SELECT Id, Name
            FROM Product2
            WHERE Name = 'Test Optional SKU'
        ];
        
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_SpotlightCalloutMock());
        
        List<Schema.Location> branch = [select id from Location where name= 'Test Branch Location'];
        
        Test.startTest();
        SBR_3_0_SpotlightPanelCmpController.Product_AddOns productAddOns1 = (SBR_3_0_SpotlightPanelCmpController.Product_AddOns) JSON.deserializeStrict(
            SBR_3_0_SpotlightPanelCmpController.getProductAddOns(
                products[0].Id,
                '01',
                '',
                branch[0].Id
            ),
            SBR_3_0_SpotlightPanelCmpController.Product_AddOns.class
        );
        List<SBQQ__Quote__c> quotes = [SELECT Id FROM SBQQ__Quote__c];
        SBR_3_0_SpotlightPanelCmpController.Product_AddOns productAddOns2 = (SBR_3_0_SpotlightPanelCmpController.Product_AddOns) JSON.deserializeStrict(
            SBR_3_0_SpotlightPanelCmpController.getProductAddOns(
                products[0].Id,
                '01',
                quotes[0]?.Id,
                branch[0].Id
            ),
            SBR_3_0_SpotlightPanelCmpController.Product_AddOns.class
        );
        SBR_3_0_SpotlightPanelCmpController.Product_AddOns productAddOns3 = (SBR_3_0_SpotlightPanelCmpController.Product_AddOns) JSON.deserializeStrict(
            SBR_3_0_SpotlightPanelCmpController.getProductAddOns(
                products[0].Id,
                '01',
                products[0]?.Id,
                branch[0].Id
            ),
            SBR_3_0_SpotlightPanelCmpController.Product_AddOns.class
        );
        List<Order> orders = [SELECT Id FROM Order limit 1];
        SBR_3_0_SpotlightPanelCmpController.Product_AddOns productAddOns4 = (SBR_3_0_SpotlightPanelCmpController.Product_AddOns) JSON.deserializeStrict(
            SBR_3_0_SpotlightPanelCmpController.getProductAddOns(
                products[0].Id,
                '01',
                orders[0]?.Id,
                branch[0].Id
            ),
            SBR_3_0_SpotlightPanelCmpController.Product_AddOns.class
        );
        
        Test.stopTest();
        
        System.assertEquals(0, productAddOns1.salesAddOns.size());
    }
    
    public class SBR_3_0_SpotlightCalloutMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            // Create a fake response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', SBR_3_0_Constants.APP_JSON);
            if (req.getEndpoint().endsWithIgnoreCase('token')) {
                res.setBody('{"access_token":"test"}');
            } else {
                res.setBody(
                    '{"data":{"errorCode":"0000","errorDesc":"Success","company":"01","customer":"4","jobsite":"CO MEDIMMUNE BOULDER","location":"0720","suggestedItems":[{"rentables":[{ "equipmentNumber":"1234567","forceItem": "Y","minQuantity":1,"minRate":1,"dayRate":1,"wkRate":1,"moRate":1}],"consumables":[{"specGroups":[{"products":[{"stockClass":"TEST","productNumber":"123456789","forceItem" : "Y","minQuantity" : 1,"availQuantity" : 2}]}]}]}],"items":[{"catId":"123","classId":"4567","productId":"1234567","rateFlag":"B","rateFlagDescription":"Book Rates","notToExceed":"","notToExceedDescription":"No override needed for any change.","rppPercentage":".000","needPassword":"FALSE","showAllRates":"FALSE","suggestMinimalHours":".00","isConsumerCatClass":"FALSE","isSerialized":"FALSE","customerDiscountPercentageDaily":".00","customerDiscountPercentageWeekly":".00","customerDiscountPercentageMonthly":".00","customerMonthly":null,"rates":{"suggestedRates":{"minimum":".00","daily":".00","weekly":".00","monthly":".00"},"bookRates":{"minimum":".00","daily":".00","weekly":".00","monthly":".00"}}}]}}'
                );
            }
            res.setStatusCode(200);
            return res;
        }
    }
    
    @isTest
    static void getBranchWithValidUser() {
        Id user = UserInfo.getUserId();
        List<Schema.Location> branch  = [select id from Location where name= 'Test Branch Location'];
        User_location__c userLocation = new user_location__c(
            branch__c = branch[0].Id,
            User__c = user
        );
        
        
        insert userLocation;
        Test.startTest();
        Schema.Location testLocation = SBR_3_0_SpotlightPanelCmpController.getBranchChronosDetails();
        Test.stopTest();
        
        System.assertEquals(branch[0].Id, testLocation.Id);
    }
    
    @isTest
    static void getPhonesWithValidBranch() {
        List<Schema.Location> branches = [SELECT ID,Phone__c from Location where Name = 'Test Job Location'];
        List<String> pcs = new List<String>();
        pcs.add('0123');
      
        Test.startTest();
        update branches;
        List<Schema.Location> testLocation = SBR_3_0_SpotlightPanelCmpController.getBranchPhones(pcs);
        Test.stopTest();
        
        System.assertEquals(branches[0].Phone__c, testLocation[0].Phone__c);
    }
    @istest
    static void getkit() {
        List<Product2> products = [
            SELECT Id, Name
            FROM Product2
            WHERE Name = 'Test Product'
        ];
        List<Product2> products2 = [
            SELECT Id, Name
            FROM Product2
            WHERE Name = 'Test Optional SKU'
        ];
        SBQQ__ProductFeature__c feature = new SBQQ__ProductFeature__c();
        feature.Name = 'Kit Component';
        feature.SBQQ__Number__c = 1;
        feature.SBQQ__ConfiguredSKU__c = products[0].Id;
        insert feature;
        SBQQ__ProductOption__c option = new SBQQ__ProductOption__c();
        option.SBQQ__ConfiguredSKU__c = products[0].Id;
        option.SBQQ__OptionalSKU__c = products2[0].Id;
        option.SBQQ__Feature__c = feature.Id;
        option.SBQQ__Number__c = 1;
        insert option;
        string response = SBR_3_0_SpotlightPanelCmpController.getProductKitComponents(
            products[0].Id
        );
        system.assertNotEquals(string.isBlank(response), true);
    }
    
    /*@istest
    static void TestgetProductRates() {
        List<Product2> products = [
            SELECT Id, Name
            FROM Product2
            WHERE Name = 'Test Product'
        ];
        SBR_3_0_SpotlightPanelCmpController.GetProductRatesWrapper wrap = new SBR_3_0_SpotlightPanelCmpController.GetProductRatesWrapper(
            '1111',
            new List<string>{ products[0].Id }
        );
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_SpotlightCalloutMock());
        Test.startTest();
        string response = SBR_3_0_SpotlightPanelCmpController.getProductRates(wrap);
        Test.StopTest();
        system.assertNotEquals(string.isBlank(response), true);
    }*/
    
    @istest
    static void TestgetProductAvailabilities() {
        List<Product2> products = [
            SELECT Id, Name
            FROM Product2
            WHERE Name = 'Test Product'
        ];
        
        SBR_3_0_SpotlightPanelCmpController.getProductAvailabilities(
            new List<string>{ products[0].Id },
            'overview'
        );
        SBR_3_0_SpotlightPanelCmpController.getProductAvailabilities(
            new List<string>{ products[0].Id },
            'branches'
        );
    }
    
    @istest
    static void TestgetProductAvailabilitiesException() {
        Boolean isError = false;
        try {
            SBR_3_0_SpotlightPanelCmpController.getProductAvailabilities(
                new List<string>(),
                'overview'
            );
        } catch (Exception e) {
            isError = true;
            system.assertEquals(e.getMessage(), 'No Data loaded');
        }
        system.assertEquals(isError, true);
    }
    
    @istest
    static void TestAlternateProds() {
        final String PRODUCT_1_SKU = '1234';
        final String PRODUCT_2_SKU = '123002';
        
        Product_Hierarchy__c prdHierachy = [SELECT Id FROM Product_Hierarchy__c];
        
        Product2 product2 = new Product2(
            Name = 'Test Product 2',
            Product_Title_Internal__c = 'Test Product 2',
            Product_SKU__c = PRODUCT_2_SKU,
            Product_Hierarchy__c = prdHierachy.Id
        );
        insert product2;
        
        List<Product2> products = [
            SELECT Id, Name, Product_Hierarchy__c
            FROM Product2
            WHERE Name = 'Test Product'
        ];
        Product2 product1 = new Product2(
            Name = 'Test Product 1',
            Product_Title_Internal__c = 'Test Product 1',
            Product_SKU__c = PRODUCT_1_SKU,
            Product_Hierarchy__c = products[0].Product_Hierarchy__c,
            RecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName()
            .get('SKU')
            .getRecordTypeId(),
            Company_Code__c = '1111'
        );
        insert product1;
        List<Product2> products2 = [
            SELECT Id, Name
            FROM Product2
            WHERE Name = 'Test Optional SKU'
        ];
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_SpotlightCalloutMock());
        Test.startTest();
        String response = SBR_3_0_SpotlightPanelCmpController.getAlternateProducts(
            products[0].Id,
            '1111'
        );
        Test.stopTest();
        system.assertNotEquals(string.isBlank(response), true);
    }
    
    @istest
    static void TestgetCartRecordTypeID() {
        Id user = UserInfo.getUserID();
        /* List<Schema.Location> branch = SBR_3_0_TestDataFactory.createInventoryLocations(
            1,
            true,
            'Branch'
        );
        Analysis_Region__c region = new Analysis_Region__c();
        region.Analysis_Region_Key__c = '935';
        region.Name = 'Test Region';
        region.Company_Code__c = '01';
        insert region;*/
        List<Schema.Location> branch = [select id from Location where name= 'Test Branch Location'];
        Analysis_Region__c region = [select id ,name from Analysis_Region__c where name='Test Region' limit 1];
         Test.startTest();
        User_location__c userLocation = new user_location__c(
            branch__c = branch[0].Id,
            User__c = user,
            Analysis_Region2__c = region.Id
        );
        insert userLocation;
        
        //userLocation.Analysis_Region2__c = region.Id;
        //update userLocation;
       
        SBR_3_0_SpotlightPanelCmpController.getCartRecordTypeID();
         Test.stopTest();
        SBR_3_0_SpotlightPanelCmpController.GetProductRatesWrapper getProdrWrap = new SBR_3_0_SpotlightPanelCmpController.GetProductRatesWrapper();
        SBR_3_0_SpotlightPanelCmpController.AddOnsWrapper aoWrapper = new SBR_3_0_SpotlightPanelCmpController.AddOnsWrapper();
        aoWrapper.prodAddOns = 'prodAddOns';
        aoWrapper.response = 'response';
       
        system.debug(
            [
                SELECT
                Id,
                Branch__r.Branch_Location_Number__c,
                Branch__c,
                user__c,
                Analysis_Region_Key__c
                FROM User_Location__c
                WHERE User__c = :user
            ]
        );
    }
    
    @istest
    static void TestgetOilAndGasCartRecordTypeID() {
        Test.startTest();
        SBR_3_0_SpotlightPanelCmpController.getOilGasCartRecordTypeID();
        Test.stopTest();
    }
    
    //hamza
    @isTest
    static void getProfileBranchWithOrderContextWithJobSite() {
        // Id orderRecType = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('Order').getRecordTypeId();
        // Order order = SBR_3_0_TestDataFactory.createOrder(true,'Test Order',orderRecType);
        List<Order> orders = [
            SELECT Id, Jobsite__c
            FROM Order
            WHERE Quote_Name__c = 'Test Quote'
        ];
        Test.startTest();
        Schema.Location testLocation = SBR_3_0_SpotlightPanelCmpController.getProfileBranchChronosDetails(
            orders[0].Id,
            'Order'
        )
            .branch;
        AssociatedLocation jobSite = [
            SELECT Id, Branch__c
            FROM AssociatedLocation
            WHERE Id = :orders[0].Jobsite__c
        ];
        Test.stopTest();
        System.assertNotEquals(testLocation.Id, '', 'location does not exist ...');
        System.assertEquals(
            testLocation.Id,
            jobSite.Branch__c,
            'not sourcing branch of the current ordre ...'
        );
    }
    @isTest
    static void getProfileBranchWithOrderContextWithSourcingBranch() {
        //Id orderRecType = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('Order').getRecordTypeId();
        //Order order = SBR_3_0_TestDataFactory.createOrderWithSourcingBranch(true,'Test Order Blanla',orderRecType);
        List<Order> orders = [
            SELECT Id, Sourcing_Branch__c
            FROM Order
            WHERE Quote_Name__c = 'Test Quote'
        ];
        Test.startTest();
        Schema.Location testLocation = SBR_3_0_SpotlightPanelCmpController.getProfileBranchChronosDetails(
            orders[0].Id,
            'Order'
        )
            .branch;
        Test.stopTest();
        System.debug('testLocation = ' + testLocation);
        System.debug('sourcing branch = ' + orders[0].Sourcing_Branch__c);
        System.assertNotEquals(testLocation.Id, '', 'location does not exist ...');
        System.assertEquals(
            testLocation.Id,
            orders[0].Sourcing_Branch__c,
            'not sourcing branch of the current ordre ...'
        );
    }
     /*
    @isTest
    static void getProfileBranchWithQuoteContext() {
        //Id quoteRecType = Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosByDeveloperName().get('Rate_Quote').getRecordTypeId();
        //SBQQ__Quote__c quote = SBR_3_0_TestDataFactory.createQuote(true,'Test Order Blanla 234',quoteRecType);
        List<SBQQ__Quote__c> quotes = [
            SELECT Id, Jobsite__c
            FROM SBQQ__Quote__c
            WHERE Quote_Name__c = 'Test Quote'
        ];
        
        Test.startTest();
        Schema.Location testLocation = SBR_3_0_SpotlightPanelCmpController.getProfileBranchChronosDetails(
            quotes[0].Id,
            'SBQQ__Quote__c'
        )
            .branch;
        AssociatedLocation jobSite = [
            SELECT Id, Branch__c
            FROM AssociatedLocation
            WHERE Id = :quotes[0].Jobsite__c
        ];
        Test.stopTest();
        System.debug('testLocation = ' + testLocation);
        System.debug('sourcing branch quote = ' + jobSite.Branch__c);
        System.assertNotEquals(testLocation.Id, '', 'location does not exist ...');
        System.assertEquals(
            testLocation.Id,
            jobSite.Branch__c,
            'not sourcing branch of the current ordre ...'
        );
    }
    @isTest
    static void getProfileBranchWithQuoteContextSourcingBranch() {
        //Id quoteRecType = Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosByDeveloperName().get('Rate_Quote').getRecordTypeId();
        //SBQQ__Quote__c quote = SBR_3_0_TestDataFactory.createQuoteWithSourcingBranch(true,'Test Order Blanla 234',quoteRecType);
        List<SBQQ__Quote__c> quotes = [
            SELECT Id, Sourcing_Branch__c
            FROM SBQQ__Quote__c
            WHERE Quote_Name__c = 'Test Quote'
        ];
        
        Test.startTest();
        Schema.Location testLocation = SBR_3_0_SpotlightPanelCmpController.getProfileBranchChronosDetails(
            quotes[0].Id,
            'SBQQ__Quote__c'
        )
            .branch;
        Test.stopTest();
        System.assertNotEquals(testLocation.Id, '', 'location does not exist ...');
        System.assertEquals(
            testLocation.Id,
            quotes[0].Sourcing_Branch__c,
            'not sourcing branch of the current ordre ...'
        );
    }
    
    @isTest
    static void getBranchChronosDetailsNewWithQuoteSourcingBranch() {
        List<SBQQ__Quote__c> quotes = [
            SELECT Id, Sourcing_Branch__c
            FROM SBQQ__Quote__c
            WHERE Quote_Name__c = 'Test Quote'
        ];
        Test.startTest();
        Schema.Location loc = SBR_3_0_SpotlightPanelCmpController.getBranchChronosDetailsNew(
            quotes[0].Id,
            'SBQQ__Quote__c'
        );
        Test.stopTest();
        
        System.assertNotEquals(loc.Id, '', 'location does not exist ...');
        System.assertEquals(
            loc.Id,
            quotes[0].Sourcing_Branch__c,
            'not sourcing branch of the current quote ...'
        );
    }
   @isTest
    static void getBranchChronosDetailsNewWithQuoteSB() {
        List<SBQQ__Quote__c> quotes = [
            SELECT Id, Branch__c, Sourcing_Branch__c
            FROM SBQQ__Quote__c
            WHERE Quote_Name__c = 'Test Quote'
        ];
        Test.startTest();
        Schema.Location loc = SBR_3_0_SpotlightPanelCmpController.getBranchChronosDetailsNew(
            quotes[0].Id,
            'SBQQ__Quote__c'
        );
        Test.stopTest();
        
        System.assertNotEquals(loc.Id, '', 'location does not exist ...');
        System.assertEquals(
            loc.Id,
            quotes[0].Sourcing_Branch__c,
            'not sourcing branch of the current quote ...'
        );
    }
    */
    @isTest
    static void getBranchChronosDetailsNewWithOrderSourcingBranch() {
        List<Order> orders = [
            SELECT Id, Sourcing_Branch__c
            FROM Order
            WHERE Quote_Name__c = 'Test Quote'
        ];
        Test.startTest();
        Schema.Location loc = SBR_3_0_SpotlightPanelCmpController.getBranchChronosDetailsNew(
            orders[0].Id,
            'Order'
        );
        Test.stopTest();
        
        System.assertNotEquals(loc.Id, '', 'location does not exist ...');
        System.assertEquals(
            loc.Id,
            orders[0].Sourcing_Branch__c,
            'not sourcing branch of the current quote ...'
        );
    }
}