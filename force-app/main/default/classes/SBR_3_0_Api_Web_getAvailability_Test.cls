/**
 * 
 * @author Thomas E. Canter
 * @since 9/13/2022
 */
@IsTest
public with sharing class SBR_3_0_Api_Web_getAvailability_Test {
    Static List<Product2> lstProds;
    Static List<Schema.ProductItem> productItems;
    Static List<Schema.Location> locs;
    @TestSetup
    static void makeData(){
        lstProds = SBR_3_0_TestDataFactory.createProducts(1, true);
        // Create a Location
        locs = SBR_3_0_TestDataFactory.createInventoryLocations(1, false, 'Branch');
        Schema.Location loc = locs[0];
        loc.District__c = 'BALTIMORE DELAWARE DISTRICT';
        loc.Region__c = 'REGION 02';
        loc.Territory__c = 'EAST TERRITORY';
        loc.Company__c = 'SUNBELT RENTALS';
        insert locs;

        // Create a Product Item
        productItems = SBR_3_0_TestDataFactory.createProductItems(1, false, lstProds[0].id, locs[0].id);
        Schema.ProductItem pi = productItems[0];
        pi.SM_PS_Cat_Class__c = '0090030';
        pi.SM_PS_Quantity_Available__c = 10;
        pi.SM_PS_Quantity_Reserved__c = 5; 
        pi.SM_PS_Quantity_on_Scheduled_Pick_Up__c = 7;
        pi.SM_PS_Quantity_on_Rent__c = 15;
        pi.SM_PS_Number_of_Rental_Units__c = 32;
        insert productItems;
    

    }
    @isTest
    public static void branchTestWeb(){
        makeData();
        Schema.Location loc = locs[0];
        SBR_3_0_Api_Web_getAvailability.getAvailabilityWeb('Branch', loc.Name, productItems[0].SM_PS_Cat_Class__c);
        String response = RestContext.response?.responseBody?.ToString();
        test.startTest();
        System.Debug('SBR_3_0_Api_Web_getAvailability_Test: branchTestWeb ' + response);
        System.assert(response.contains('"Quantity_Available":10.0'), 'Expected Quantity_Available to be 10.0, received incorrect value');
        System.assert(response.contains('"Quantity_Reserved":5.0'), 'Expected Quantity_Reserved to be 5.0, received incorrect value');
        System.assert(response.contains('"Quantity_on_Scheduled_Pick_Up":7.0'), 'Expected Quantity_on_Scheduled_Pick_Up to be 7.0, received incorrect value');
        test.stopTest();
    }
    @isTest
    public static void districtTestWeb(){
        makeData();
        Schema.Location loc = locs[0];
        SBR_3_0_Api_Web_getAvailability.getAvailabilityWeb('District', loc.Name, productItems[0].SM_PS_Cat_Class__c);
        String response = RestContext.response?.responseBody?.ToString();
        System.Debug('SBR_3_0_Api_Web_getAvailability_Test: districtTestWeb ' + response);
        test.startTest();
        System.assertEquals(response, null, 'Expected no results found, received incorrect value');
        test.stopTest();
    }
    @isTest
    public static void regionTestWeb(){
        makeData();
        Schema.Location loc = locs[0];
        SBR_3_0_Api_Web_getAvailability.getAvailabilityWeb('Region', loc.Name, productItems[0].SM_PS_Cat_Class__c);
        String response = RestContext.response?.responseBody?.ToString();
        System.Debug('SBR_3_0_Api_Web_getAvailability_Test: regionTestWeb ' + response);
        test.startTest();
        System.assertEquals(response, null, 'Expected no results found, received incorrect value');
        test.stopTest();
    }
    @isTest
    public static void territoryTestWeb(){
        makeData();
        Schema.Location loc = locs[0];
        SBR_3_0_Api_Web_getAvailability.getAvailabilityWeb('Territory', loc.Name, productItems[0].SM_PS_Cat_Class__c);
        String response = RestContext.response?.responseBody?.ToString();
        System.Debug('SBR_3_0_Api_Web_getAvailability_Test: territoryTestWeb ' + response);
        test.startTest();
        System.assertEquals(response, null, 'Expected no results found, received incorrect value');
        test.stopTest();
    }
    @isTest
    public static void companyTestWeb(){
        makeData();
        Schema.Location loc = locs[0];
        SBR_3_0_Api_Web_getAvailability.getAvailabilityWeb('Company', loc.Name, productItems[0].SM_PS_Cat_Class__c);
        String response = RestContext.response?.responseBody?.ToString();
        System.Debug('SBR_3_0_Api_Web_getAvailability_Test: companyTest ' + response);
        test.startTest();
        System.assertEquals(response, null, 'Expected no results found, received incorrect value');
        test.stopTest();
    }
    @isTest
    public static void invalidLevelNameWeb(){
        makeData();
        Schema.Location loc = locs[0];
        SBR_3_0_Api_Web_getAvailability.getAvailabilityWeb('INVALID', loc.Name, productItems[0].SM_PS_Cat_Class__c);
        String response = RestContext.response?.responseBody?.ToString();
        System.Debug('SBR_3_0_Api_Web_getAvailability_Test: invalidLevelName ' + response);
        test.startTest();
        System.assertEquals(response, null, 'Expected error message, received incorrect value');
        test.stopTest();
    }
    @isTest
    public static void branchTest(){
        makeData();
        Schema.Location loc = locs[0];
        List<AggregateResult> response = SBR_3_0_Api_Web_getAvailability.getAvailability('Branch', loc.Name, productItems[0].SM_PS_Cat_Class__c);
        
        test.startTest();
        System.Debug('SBR_3_0_Api_Web_getAvailability_Test: branchTest ' + response);
        System.assertNotEquals(response, null, 'Expected response');
        test.stopTest();
    }
    @isTest
    public static void districtTest(){
        makeData();
        Schema.Location loc = locs[0];
        List<AggregateResult> response = SBR_3_0_Api_Web_getAvailability.getAvailability('Branch', loc.Name, productItems[0].SM_PS_Cat_Class__c);
        test.startTest();
        System.Debug('SBR_3_0_Api_Web_getAvailability_Test: branchTest ' + response);
        System.assertNotEquals(response, null, 'Expected response');
        test.stopTest();
    }
    @isTest
    public static void regionTest(){
        makeData();
        Schema.Location loc = locs[0];
        List<AggregateResult> response = SBR_3_0_Api_Web_getAvailability.getAvailability('Branch', loc.Name, productItems[0].SM_PS_Cat_Class__c);
        test.startTest();
        System.Debug('SBR_3_0_Api_Web_getAvailability_Test: branchTest ' + response);
        System.assertNotEquals(response, null, 'Expected response');
        test.stopTest();
    }
    @isTest
    public static void territoryTest(){
        makeData();
        Schema.Location loc = locs[0];
        List<AggregateResult> response = SBR_3_0_Api_Web_getAvailability.getAvailability('Branch', loc.Name, productItems[0].SM_PS_Cat_Class__c);
        System.Debug('SBR_3_0_Api_Web_getAvailability_Test: territoryTest ' + response);
        test.startTest();
        System.assertNotEquals(response, null, 'Expected response');
        test.stopTest();
    }
    @isTest
    public static void companyTest(){
        makeData();
        Schema.Location loc = locs[0];
        List<AggregateResult> response = SBR_3_0_Api_Web_getAvailability.getAvailability('Branch', loc.Name, productItems[0].SM_PS_Cat_Class__c);
        System.Debug('SBR_3_0_Api_Web_getAvailability_Test: companyTest ' + response);
        test.startTest();
        System.assertNotEquals(response, null, 'Expected response');
        test.stopTest();
    }
    @isTest
    public static void invalidLevelName(){
        makeData();
        Schema.Location loc = locs[0];
        List<AggregateResult> response = SBR_3_0_Api_Web_getAvailability.getAvailability('INVALID', loc.Name, productItems[0].SM_PS_Cat_Class__c);
        System.Debug('SBR_3_0_Api_Web_getAvailability_Test: invalidLevelName ' + response);
        test.startTest();
        System.assertEquals(response, null, 'Expected response');
        test.stopTest();
    }
}