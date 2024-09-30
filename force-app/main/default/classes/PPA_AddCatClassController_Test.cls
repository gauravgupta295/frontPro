@IsTest
public class PPA_AddCatClassController_Test {
    @TestSetup
    public static void setupTestData() {
        RecordType productRecordType = [SELECT Id FROM RecordType WHERE SObjectType = 'Product2' AND DeveloperName = 'SKU' LIMIT 1];
        
        PPA_Price_List__c priceList = new PPA_Price_List__c(Name='TEST');
        insert priceList;
        
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPricebook;
        
        Product2 testProduct = new Product2(
            RecordTypeId = productRecordType.Id,
            Name = 'Test Product',
            Category__c = '1',
            Class__c = '100',
            Status__c = 'A',
            Company_Code__c = '01',
            Product_Type__c = 'Cat-Class'
        );
        insert testProduct;
        
        Product2 likeProduct = new Product2(
            RecordTypeId = productRecordType.Id,
            Name = 'Test Product',
            Category__c = '1',
            Class__c = '200',
            Status__c = 'A',
            Company_Code__c = '01',
            Product_Type__c = 'Cat-Class'
        );
        insert likeProduct;

        Product2 nonMatchProduct = new Product2(
            RecordTypeId = productRecordType.Id,
            Name = 'Test Product',
            Category__c = '1',
            Class__c = '300',
            Status__c = 'A',
            Company_Code__c = '01',
            Product_Type__c = 'Cat-Class'
        );
        insert nonMatchProduct;
        
        PPA_Rental_CatClass__c testRentalCatClass = new PPA_Rental_CatClass__c(
            PPA_Product__c = testProduct.Id,
            PPA_Price_List__c = priceList.Id,
            PPA_Like_CatClass__c = false
        );
        insert testRentalCatClass;
        
        PPA_Rental_CatClass__c testRentalCatClass1 = new PPA_Rental_CatClass__c(
            PPA_Product__c = likeProduct.Id,
            PPA_Price_List__c = priceList.Id,
            PPA_Like_CatClass__c = true
        );
        insert testRentalCatClass1;

        PPA_CatClass_Rate__c testCatClassRate = new PPA_CatClass_Rate__c(
            PPA_CompanyId__c = '01',
            PPA_Cat__c = '1',
            PPA_Class__c = '100',
            PPA_New_Day__c = 10,
            PPA_New_Week__c = 60,
            PPA_New_Month__c = 240,
            PPA_Min_Day__c = 5,
            PPA_Min_Week__c = 30,
            PPA_Min_Month__c = 120,
            PPA_Active__c = true,
            PPA_Top_Product__c = true
        );
        insert testCatClassRate;

        PPA_CatClass_Rate__c testCatClassRate2 = new PPA_CatClass_Rate__c(
            PPA_CompanyId__c = '01',
            PPA_Cat__c = '1',
            PPA_Class__c = '300',
            PPA_New_Day__c = 20,
            PPA_New_Week__c = 40,
            PPA_New_Month__c = 140,
            PPA_Min_Day__c = 6,
            PPA_Min_Week__c = 60,
            PPA_Min_Month__c = 240,
            PPA_Active__c = true,
            PPA_Top_Product__c = true
        );
        insert testCatClassRate2;
        
        Product_Hierarchy__c testHierarchyProduct = new Product_Hierarchy__c(
            Name = 'Test Hierarchy Product',
            Product_Hierarchy_Code__c = 'Test Hierarchy Product',
            Product_Family_Type__c = 'Cat-Class'
        );
        insert testHierarchyProduct;
    }
    
    @IsTest
    public static void testGetCatClassRecordsTrue() {
        PPA_Price_List__c priceList = [SELECT Id FROM PPA_Price_List__c LIMIT 1];
        Product2 testProduct = [SELECT Id,Name FROM Product2 LIMIT 1];
        PPA_CatClass_Rate__c testCatClassRate = [SELECT Id,PPA_New_Day__c, PPA_New_Week__c, PPA_New_Month__c FROM PPA_CatClass_Rate__c LIMIT 1];
        PPA_Rental_CatClass__c testRentalCatClass = [SELECT Id FROM PPA_Rental_CatClass__c where PPA_Like_CatClass__c = true LIMIT 1];
        
        Map<String, Object> resultMap;
            
        Test.startTest();
        List<Map<String, Object>> result = PPA_AddCatClassController.getCatClassRecords(priceList.Id, '01', null, null, null, null, false, true);
        Test.stopTest();

        System.assertEquals(1, result.size(), 'The result size should be 1');
        
        if (result[0].get('Source') == 'likeCatClass'){
            resultMap = result[0];
        }
        else {
            resultMap = result[1];
        }
        System.assertEquals(testRentalCatClass.Id, resultMap.get('Id'), 'The Id should match the rental cat class Id');
        System.assertEquals('likeCatClass', resultMap.get('Source'), 'The Source should be likecatclass');
        System.assertEquals(true, resultMap.get('isSelectable'), 'The isSelectable should be false');
    }
    @IsTest
    public static void testGetCatClassRecordsFalse() {
        PPA_Price_List__c priceList = [SELECT Id FROM PPA_Price_List__c LIMIT 1];
        Product2 testProduct = [SELECT Id,Name FROM Product2 LIMIT 1];
        PPA_CatClass_Rate__c testCatClassRate = [SELECT Id,PPA_New_Day__c, PPA_New_Week__c, PPA_New_Month__c FROM PPA_CatClass_Rate__c LIMIT 1];
        PPA_Rental_CatClass__c testRentalCatClass = [SELECT Id FROM PPA_Rental_CatClass__c where PPA_Like_CatClass__c = true LIMIT 1];
        
        Map<String, Object> resultMap;
            
        Test.startTest();
        List<Map<String, Object>> result = PPA_AddCatClassController.getCatClassRecords(priceList.Id, '01', null, null, null, null, false, false);
        Test.stopTest();

        System.assertEquals(3, result.size(), 'The result size should be 3');

        
        for (Map<String, Object> mp : result) {
            if(mp.get('Source') == 'likeCatClass'){
                resultMap = mp;
            }
            else {
                resultMap = mp;
            }
        }

        System.assertEquals(testRentalCatClass.Id, resultMap.get('Id'), 'The Id should match the rental cat class Id');
        System.assertEquals('likeCatClass', resultMap.get('Source'), 'The Source should be likeCatClass');
        System.assertEquals(true, resultMap.get('isSelectable'), 'The isSelectable should be false');
    }

    @IsTest
    public static void testGetCatClassRecordsNoRecords() {
        PPA_Price_List__c priceList = [SELECT Id FROM PPA_Price_List__c LIMIT 1];
        Product2 testProduct = [SELECT Id,Name FROM Product2 LIMIT 1];
        PPA_CatClass_Rate__c testCatClassRate = [SELECT Id,PPA_New_Day__c, PPA_New_Week__c, PPA_New_Month__c FROM PPA_CatClass_Rate__c LIMIT 1];
        PPA_Rental_CatClass__c testRentalCatClass = [SELECT Id FROM PPA_Rental_CatClass__c where PPA_Like_CatClass__c = true LIMIT 1];
        
        Map<String, Object> resultMap;
            
        Test.startTest();
        List<Map<String, Object>> result = PPA_AddCatClassController.getCatClassRecords(priceList.Id, '01', 'TEST', 'TEST', 'TEST', 'TEST', false, false);
        Test.stopTest();

        System.assertEquals(0, result.size(), 'The result size should be 0');        
    }

    @IsTest
    public static void testGetCatClassRecordsTopProduct() {
        PPA_Price_List__c priceList = [SELECT Id FROM PPA_Price_List__c LIMIT 1];
        Product2 testProduct = [SELECT Id,Name FROM Product2 LIMIT 1];
        PPA_CatClass_Rate__c testCatClassRate = [SELECT Id,PPA_New_Day__c, PPA_New_Week__c, PPA_New_Month__c FROM PPA_CatClass_Rate__c LIMIT 1];
        PPA_Rental_CatClass__c testRentalCatClass = [SELECT Id FROM PPA_Rental_CatClass__c where PPA_Like_CatClass__c = true LIMIT 1];
        
        Map<String, Object> resultMap;
            
        Test.startTest();
        List<Map<String, Object>> result = PPA_AddCatClassController.getCatClassRecords(priceList.Id, '01', 'TEST', 'TEST', 'TEST', 'TEST', true, true);
        Test.stopTest();

        System.assertEquals(0, result.size(), 'The result size should be 0');        
    }
    
    @IsTest
    public static void testFetchHierarchyProducts() {
        Product_Hierarchy__c testHierarchyProduct = [SELECT Id,Name, Product_Hierarchy_Code__c FROM Product_Hierarchy__c LIMIT 1];

        Test.startTest();
        List<Map<String,Object>> result = PPA_AddCatClassController.fetchHierarchyProducts();
        Test.stopTest();

        System.assertEquals(testHierarchyProduct.Name.toUpperCase(), result[0].get('Name'), 'The Name should match the test hierarchy product Name');
    }
    
    @IsTest
    public static void testHandleUpdateProducts() {
        PPA_Price_List__c priceList = [SELECT Id FROM PPA_Price_List__c LIMIT 1];
        Product2 testProduct = [SELECT Id, Name FROM Product2 LIMIT 1];
        PPA_Rental_CatClass__c testRentalCatClass = [SELECT Id FROM PPA_Rental_CatClass__c where PPA_Like_CatClass__c = true LIMIT 1];
              
        // Prepare the JSON string for updateProducts
        Map<String, Object> updateProductMap = new Map<String, Object>{
            'Source' => 'Product',
            'recordId' => testProduct.Id,
            'priceListId' => priceList.Id,
            'NewDay' => 10,
            'NewWeek' => 50,
            'NewMonth' => 200,
            'MinDay' => 5,
            'MinWeek' => 25,
            'MinMonth' => 100    
        };
            
        Map<String, Object> updateProductMap2 = new Map<String, Object>{
            'Source' => 'likeCatClass',
            'recordId' => testRentalCatClass.Id
        };
        String updateProductsJson = JSON.serialize(new List<Object>{ updateProductMap, updateProductMap2 });

        system.debug(updateProductsJson);
        
        Test.startTest();
        PPA_AddCatClassController.handleUpdateProducts(updateProductsJson);
        Test.stopTest();
        
        PPA_Rental_CatClass__c updatedRecord = [SELECT Id, PPA_New_Day__c, PPA_New_Week__c, PPA_New_Month__c, PPA_Min_Day__c, PPA_Min_Week__c, PPA_Min_Month__c, PPA_Like_CatClass__c, PPA_CatClass_Added__c
                                                FROM PPA_Rental_CatClass__c WHERE PPA_Product__c = :testProduct.Id AND PPA_CatClass_Added__c = true AND PPA_New_Day__c != null  LIMIT 1];

        // Perform assertions
        System.assertEquals(10, updatedRecord.PPA_New_Day__c, 'The NewDay should be updated');
        System.assertEquals(50, updatedRecord.PPA_New_Week__c, 'The NewWeek should be updated');
        System.assertEquals(200, updatedRecord.PPA_New_Month__c, 'The NewMonth should be updated');
        System.assertEquals(false, updatedRecord.PPA_Like_CatClass__c, 'PPA_Like_CatClass__c should be false');
        System.assertEquals(true, updatedRecord.PPA_CatClass_Added__c, 'PPA_CatClass_Added__c should be true');
    }

    @IsTest
    public static void testHandleUpdateProductsException() {
        PPA_Price_List__c priceList = [SELECT Id FROM PPA_Price_List__c LIMIT 1];
              
        // Prepare the JSON string for updateProducts
        Map<String, Object> updateProductMap = new Map<String, Object>{
            'Source' => 'Product',
            'recordId' => priceList.Id,
            'priceListId' => priceList.Id,
            'NewDay' => 1000,
            'NewWeek' => 50,
            'NewMonth' => 200,
            'MinDay' => 5,
            'MinWeek' => 25,
            'MinMonth' => 100    
        };
            
        String updateProductsJson = JSON.serialize(new List<Object>{ updateProductMap });
        
        Test.startTest();
        PPA_AddCatClassController.handleUpdateProducts(updateProductsJson);
        Test.stopTest();
        
        List<PPA_Rental_CatClass__c> updatedRecord = [SELECT Id, PPA_New_Day__c
                                                        FROM PPA_Rental_CatClass__c
                                                       WHERE PPA_Price_List__c = :priceList.Id
                                                         AND PPA_Like_CatClass__c = false
                                                         AND PPA_CatClass_Added__c = true
                                                         AND PPA_New_Day__c = 1000
                                                       LIMIT 1];

        // Perform assertions
        System.assertEquals(0, updatedRecord.size(), 'No record should be found');
    }
}