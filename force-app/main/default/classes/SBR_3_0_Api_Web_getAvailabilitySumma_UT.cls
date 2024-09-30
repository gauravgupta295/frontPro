/**
 * 
 * @author Ritesh Mohapatra
 * @since 9/13/2022
 * @update 9/14/2022
 */
@IsTest
public with sharing class SBR_3_0_Api_Web_getAvailabilitySumma_UT
{
    Static List<Product2> lstProds;
    Static List<Schema.ProductItem> productItems;
    Static List<Schema.Location> locs;

    static void makeData()
    {
        lstProds = SBR_3_0_TestDataFactory.createProducts(1, true);
        // Create a Location
        locs = SBR_3_0_TestDataFactory.createInventoryLocations(1, false, 'Branch');
        Schema.Location loc = locs[0];
        loc.Name = 'BALTIMORE LOC';
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
    public static void getAvailabilitySummaryWebTest()
    {
        makeData();
        Schema.Location loc = locs[0];
        List<String> products = new List<String>();
        products.add(productItems[0].SM_PS_Cat_Class__c);
        String completeProductsString = '\'' + String.join(products, '\',\'') + '\'';
        completeProductsString = '(' + completeProductsString + ')';
        test.startTest();
        SBR_3_0_Api_Web_getAvailabilitySummary.getAvailabilitySummaryWeb(locs[0].Name,completeProductsString);
        String response = RestContext.response.responseBody.ToString();
        test.stopTest();
        System.assertNotEquals(response,'{"errorMessage":"no results found"}');

    }
    @isTest
    public static void getAvailabilitySummaryTest()
    {
        makeData();
        Schema.Location loc = locs[0];
        List<String> products = new List<String>();
        products.add(productItems[0].SM_PS_Cat_Class__c);
        String completeProductsString = '\'' + String.join(products, '\',\'') + '\'';
        completeProductsString = '(' + completeProductsString + ')';
        test.startTest();
        List<AggregateResult> response = SBR_3_0_Api_Web_getAvailabilitySummary.getAvailabilitySummary(locs[0].Name,completeProductsString);
        System.assertEquals(response[0].get('Quantity_Available'),productItems[0].SM_PS_Quantity_Available__c);
        test.stopTest();    
    }

}