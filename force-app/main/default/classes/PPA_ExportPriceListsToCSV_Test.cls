@isTest
public class PPA_ExportPriceListsToCSV_Test {
   
    @TestSetup
    public static void testSetup(){
        PPA_ExportPriceListsUtility_Test.createTestData();
        PPA_SeedDataForAdminLookup.loadExportCSVKey();
        PPA_SeedDataForAdminLookup.loadCustomSettings();
    }
    
    @isTest
    static void testExportSelectedPriceLists() {        
        List<String> PriceListIds = new List<String>();
        for(PPA_Price_List__c PriceList : [SELECT Id FROM PPA_Price_List__c]) {
			PriceListIds.add(PriceList.Id);			            
        }
        
        Test.startTest();
        Integer result = PPA_ExportPriceListsToCSV.exportSelectedPriceLists(PriceListIds);
        Test.stopTest();

        Assert.areEqual(6, result, 'Correct number of Price Lists not exported');
    }

    @isTest
    static void testExportSelectedPriceListsException() {        
        List<String> PriceListIds = new List<String>();
        PriceListIds.add('TEST');
        
        Test.startTest();
        Integer result = PPA_ExportPriceListsToCSV.exportSelectedPriceLists(PriceListIds);
        Test.stopTest();

        Assert.areEqual(0, result, 'Correct number of Price Lists not exported');
    }
}