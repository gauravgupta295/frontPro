@isTest
public class SBR_3_0_API_Web_Product_Test implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest request) {
        // Create a fake response
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setBody('{"success":true,"errorMsg":"","data":""}');
        response.setStatusCode(200);
        return response; 
    }

    @TestSetup
    static void makeData(){
        // Create Price Book
        Pricebook2 priceBook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update priceBook;
        // Create Product Hierarchy
        Product_Hierarchy__c prdHierachy = new Product_Hierarchy__c(Name = 'Test Hierarchy', 
        Product_Hierarchy_Code__c = 'Test_HR_Code', RecordTypeId = SBR_3_0_Constants.PRODUCT_HIERARCHY_PRODUCT_SUB_CATEGORY_RT_ID);
        insert prdHierachy;
        // Create Product2
        List<Product2> products = new List<Product2>();
        products.add(new Product2(Name = 'Test Product 5', Product_Title_Internal__c = 'Test Product 5', Product_SKU__c = '123005', Product_Hierarchy__c = prdHierachy.Id, Product_Type__c = 'Cat-Class'));
        products.add(new Product2(Name = 'Test Product 6', Product_Title_Internal__c = 'Test Product 6', Product_SKU__c = '123006', Product_Hierarchy__c = prdHierachy.Id, Product_Type__c = 'Cat-Class'));
        insert products;
        Product2 prod = new Product2(Name = 'Test Product 1', Product_Title_Internal__c = 'Test Product 1', Product_SKU__c = '123001', Product_Hierarchy__c = prdHierachy.Id, Product_Type__c = 'Cat-Class');
        insert prod;
        // Create Message
        Message__c msg1 = new Message__c(Name = 'Message 1', Product_Message_Id__c = '01_0000001', Company_Code__c = '01', Message_Number__c = '0000001', Description__c = 'Test Message Description');
        Message__c msg2 = new Message__c(Name = 'Message 2', Product_Message_Id__c = '01_0000002', Company_Code__c = '01', Message_Number__c = '0000002', Description__c = 'Test Message Description');
        Message__c msg3 = new Message__c(Name = 'Message 3', Product_Message_Id__c = '01_0000003', Company_Code__c = '01', Message_Number__c = '0000003', Description__c = 'Test Message Description');
        insert new List<Message__c>{msg1, msg2, msg3};
        // Insert Product Feature
        SBQQ__ProductFeature__c featureObj = new SBQQ__ProductFeature__c(
                Name = 'Sales Addons',
                Product_Feature_Load_Ext_ID__c = prod.Product_SKU__c + '_' + 'Sales Addons',
                SBQQ__ConfiguredSKU__c = prod.Id,
                SBQQ__MinOptionCount__c = 1,
                SBQQ__Number__c = 1
        );
        insert featureObj;
        // Insert Product Message
        Product_Message__c prodMsgRecord1 = new Product_Message__c(
                Product_Message_Id__c = prod.Product_SKU__c + '-' + prod.Product_SKU__c + '_' + msg1.Message_Number__c,
                Product__c = prod.Id,
                Message__c = msg1.Id,
                Message_Number__c = msg1.Message_Number__c,
                Product_SKU__c = prod.Product_SKU__c,
                Screen__c = true,
                Print__c = true
        );
        Product_Message__c prodMsgRecord2 = new Product_Message__c(
                Product_Message_Id__c = prod.Product_SKU__c + '-' + prod.Product_SKU__c + '_' + msg2.Message_Number__c,
                Product__c = prod.Id,
                Message__c = msg2.Id,
                Message_Number__c = msg2.Message_Number__c,
                Product_SKU__c = prod.Product_SKU__c,
                Screen__c = true
        );
        Product_Message__c prodMsgRecord3 = new Product_Message__c(
                Product_Message_Id__c = prod.Product_SKU__c + '-' + prod.Product_SKU__c + '_' + msg3.Message_Number__c,
                Product__c = prod.Id,
                Message__c = msg3.Id,
                Message_Number__c = msg3.Message_Number__c,
                Product_SKU__c = prod.Product_SKU__c,
                Print__c = true
        );

        List<Product_Message__c> productMessages = new List<Product_Message__c>{prodMsgRecord1, prodMsgRecord2, prodMsgRecord3};
        insert productMessages;

        // Insert Product Options
        Product2 prod2 = new Product2(Name = 'Test Product 3', Product_Title_Internal__c = 'Test Product 3', Product_SKU__c = '123003', Product_Hierarchy__c = prdHierachy.Id, Product_Type__c = 'Cat-Class');
        insert prod2;
        SBQQ__ProductOption__c prodOption = new SBQQ__ProductOption__c(
            Product_Optional_SKU__c = '123001-123003',
            SBQQ__ConfiguredSKU__c = prod.Id,
            SBQQ__OptionalSKU__c = prod2.Id,
            SBQQ__Number__c = 1,
            SBQQ__Feature__c = featureObj.Id
        );
        insert prodOption;
    }

    @isTest
    static void testCreateProductSuccess(){

        //would prefer an assertion but coverage passes
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_Web_Product_Test());
        RestRequest request = new RestRequest();
        request.requestUri = 'https://yourInstance.salesforce.com/services/apexrest/Product/ApiCreate/v1/';
        request.httpMethod = 'POST';

        SBR_3_0_CustomCreateProduct.ProductRequestWrapper requestWrapper = new SBR_3_0_CustomCreateProduct.ProductRequestWrapper();
        requestWrapper.printMessages = '01_0000001,01_0000003';
        requestWrapper.screenMessages = '01_0000002,01_0000003';
        requestWrapper.hierarchyCode = 'Test_HR_Code';
        requestWrapper.options_suggested  = new List<SBQQ__ProductOption__c>();
        requestWrapper.options_suggested.add(new SBQQ__ProductOption__c(Product_Optional_SKU__c = '01-123002-123001', SBQQ__Quantity__c = 1, SBQQ__Number__c = 1));
        requestWrapper.options_kit  = new List<SBQQ__ProductOption__c>();
        requestWrapper.options_kit.add(new SBQQ__ProductOption__c(Product_Optional_SKU__c = '01-123002-123005', SBQQ__Quantity__c = 1, SBQQ__Number__c = 1));
        requestWrapper.options_forced  = new List<SBQQ__ProductOption__c>();
        requestWrapper.options_forced.add(new SBQQ__ProductOption__c(Product_Optional_SKU__c = '01-123002-123006', SBQQ__Quantity__c = 1, SBQQ__Number__c = 1));
        requestWrapper.data = new Product2(Name = 'Test Product 2', Product_Title_Internal__c = 'Test Product 2', Product_SKU__c = '123002', Product_Type__c = 'Cat-Class');
        
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf(JSON.serialize(requestWrapper));
        RestContext.request = request;
        Test.startTest();
        SBR_3_0_API_Web_Product.createUpdateProduct();
        Test.stopTest();
        // Check if product is inserted
        Map<String, Product2> insertedProductMap = SBR_3_0_ProductDA.getProductByExternalId(new Set<String>{'123002'});
        Product2 insertedProduct = insertedProductMap.values()[0]; 
        // Check if product feature is inserted
        Map<String, SBQQ__ProductFeature__c> productFeatures = SBR_3_0_ProductDA.getProductFeatures(insertedProduct.Id);
        system.assert(productFeatures.size() == 2, 'Product feature is not inserted');
        // Check if product messages are inserted
        Map<String, Product_Message__c> productMessages = SBR_3_0_ProductDA.getProductMessages(insertedProduct.Id);
        system.assert(productMessages.size() == 3, 'Product messages are not inserted');
        // Check if product option is inserted inserted
        Map<String, SBQQ__ProductOption__c> productOptions = SBR_3_0_ProductDA.getProductOptions(insertedProduct.Id);
        system.assert(productOptions.size() == 3, 'Product option is not inserted');
    }

    @isTest
    static void testUpdateProductSuccess(){
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_Web_Product_Test());
        RestRequest request = new RestRequest();
        request.requestUri = 'https://yourInstance.salesforce.com/services/apexrest/Product/ApiCreate/v1/';
        request.httpMethod = 'POST';

        SBR_3_0_CustomCreateProduct.ProductRequestWrapper requestWrapper = new SBR_3_0_CustomCreateProduct.ProductRequestWrapper();
        requestWrapper.printMessages = '01_0000001,01_0000003';
        requestWrapper.screenMessages = '01_0000002,01_0000003';
        requestWrapper.hierarchyCode = 'Test_HR_Code';
        requestWrapper.options_suggested = new List<SBQQ__ProductOption__c>();
        requestWrapper.options_suggested.add(new SBQQ__ProductOption__c(Product_Optional_SKU__c = '01-123001-123003', SBQQ__Quantity__c = 1, SBQQ__Number__c = 1));
        requestWrapper.options_kit  = new List<SBQQ__ProductOption__c>();
        requestWrapper.options_kit.add(new SBQQ__ProductOption__c(Product_Optional_SKU__c = '01-123001-123005', SBQQ__Quantity__c = 1, SBQQ__Number__c = 1));
        requestWrapper.options_forced  = new List<SBQQ__ProductOption__c>();
        requestWrapper.options_forced.add(new SBQQ__ProductOption__c(Product_Optional_SKU__c = '01-123001-123006', SBQQ__Quantity__c = 1, SBQQ__Number__c = 1));
        requestWrapper.data = new Product2(Name = 'Test Product 1', Product_Title_Internal__c = 'Test Product 1', Product_SKU__c = '123001', Product_Type__c = 'Cat-Class');
        
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf(JSON.serialize(requestWrapper));
        RestContext.request = request;

        Test.startTest();
        SBR_3_0_API_Web_Product.createUpdateProduct();
        Test.stopTest();
        // Check if product is updated
        Map<String, Product2> updatedProductMap = SBR_3_0_ProductDA.getProductByExternalId(new Set<String>{'123001'});
        system.debug(updatedProductMap);
        system.assert(updatedProductMap.size() > 0, 'Product is not upserted');
        Product2 updatedProduct = updatedProductMap.values()[0]; 
        // Check if product feature is upserted
        Map<String, SBQQ__ProductFeature__c> productFeatures = SBR_3_0_ProductDA.getProductFeatures(updatedProduct.Id);
        system.debug(productFeatures);
        system.assert(productFeatures.size() == 2, 'Product feature is not upserted');
        // Check if product messages are upserted
        Map<String, Product_Message__c> productMessages = SBR_3_0_ProductDA.getProductMessages(updatedProduct.Id);
        system.assert(productMessages.size() == 3, 'Product messages are not upserted');
        // Check if product option is upserted
        Map<String, SBQQ__ProductOption__c> productOptions = SBR_3_0_ProductDA.getProductOptions(updatedProduct.Id);
        system.assert(productOptions.size() == 3, 'Product option is not upserted');
    }

    @isTest
    static void testProductCreateFail1(){
        // Error when Product Hierarchy does not exist
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_Web_Product_Test());
        RestRequest request = new RestRequest();
        request.requestUri = 'https://yourInstance.salesforce.com/services/apexrest/Product/ApiCreate/v1/';
        request.httpMethod = 'POST';

        SBR_3_0_CustomCreateProduct.ProductRequestWrapper requestWrapper = new SBR_3_0_CustomCreateProduct.ProductRequestWrapper();
        requestWrapper.printMessages = '01_0000001,01_0000003';
        requestWrapper.screenMessages = '01_0000002,01_0000003';
        requestWrapper.hierarchyCode = 'Test_HR_Code_Invalid';
        requestWrapper.options_suggested = new List<SBQQ__ProductOption__c>();
        requestWrapper.options_suggested.add(new SBQQ__ProductOption__c(Product_Optional_SKU__c = '123002-123001', SBQQ__Quantity__c = 1));
        requestWrapper.data = new Product2(Name = 'Test Product 2', Product_Title_Internal__c = 'Test Product 2', Product_SKU__c = '123002', Product_Type__c = 'Cat-Class');
        
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf(JSON.serialize(requestWrapper));
        RestContext.request = request;

        SBR_3_0_API_Web_Product.createUpdateProduct();

    }

    @isTest
    static void testProductCreateFail2(){
        // Error when Message does not exist
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_Web_Product_Test());
        RestRequest request = new RestRequest();
        request.requestUri = 'https://yourInstance.salesforce.com/services/apexrest/Product/ApiCreate/v1/';
        request.httpMethod = 'POST';

        SBR_3_0_CustomCreateProduct.ProductRequestWrapper requestWrapper = new SBR_3_0_CustomCreateProduct.ProductRequestWrapper();
        requestWrapper.printMessages = '01_0000001,01_0000003,01_0000004';
        requestWrapper.screenMessages = '01_0000002,01_0000003';
        requestWrapper.hierarchyCode = 'Test_HR_Code';
        requestWrapper.options_suggested = new List<SBQQ__ProductOption__c>();
        requestWrapper.options_suggested.add(new SBQQ__ProductOption__c(Product_Optional_SKU__c = '123002-123001', SBQQ__Quantity__c = 1));
        requestWrapper.data = new Product2(Name = 'Test Product 2', Product_Title_Internal__c = 'Test Product 2', Product_SKU__c = '123002', Product_Type__c = 'Cat-Class');
        
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf(JSON.serialize(requestWrapper));
        RestContext.request = request;

        SBR_3_0_API_Web_Product.createUpdateProduct();


    }

    @isTest
    static void testProductCreateFail3(){
        // Error when optional product does not exist
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_Web_Product_Test());
        RestRequest request = new RestRequest();
        request.requestUri = 'https://yourInstance.salesforce.com/services/apexrest/Product/ApiCreate/v1/';
        request.httpMethod = 'POST';

        SBR_3_0_CustomCreateProduct.ProductRequestWrapper requestWrapper = new SBR_3_0_CustomCreateProduct.ProductRequestWrapper();
        requestWrapper.printMessages = '01_0000001,01_0000003';
        requestWrapper.screenMessages = '01_0000002,01_0000003';
        requestWrapper.hierarchyCode = 'Test_HR_Code';
        requestWrapper.options_suggested = new List<SBQQ__ProductOption__c>();
        requestWrapper.options_suggested.add(new SBQQ__ProductOption__c(Product_Optional_SKU__c = '123002-123010', SBQQ__Quantity__c = 1, SBQQ__Number__c = 1));
        requestWrapper.data = new Product2(Name = 'Test Product 2', Product_Title_Internal__c = 'Test Product 2', Product_SKU__c = '123002', Product_Type__c = 'Cat-Class');
        
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf(JSON.serialize(requestWrapper));
        RestContext.request = request;

        SBR_3_0_API_Web_Product.createUpdateProduct();

    }
}