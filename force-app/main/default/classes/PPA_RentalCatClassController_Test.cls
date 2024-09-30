@isTest
public class PPA_RentalCatClassController_Test {
    @testSetup
    static void makeData(){
        List<PPA_Price_List__c> PriceLists = new List<PPA_Price_List__c>();
		List<PPA_Rental_CatClass__c> catClass = new List<PPA_Rental_CatClass__c>();

        PriceLists.add(new PPA_Price_List__c(Name='TEST'));
        insert PriceLists;
        
        catClass.add(new PPA_Rental_CatClass__c(PPA_Price_List__c=PriceLists[0].Id, PPA_New_Day__c=100, PPA_Like_CatClass__c=false));
        insert catClass;   
    }

    @isTest
    public static void fetchRentalCatClassTest() {
        PPA_Price_List__c PriceList;
        List<PPA_Rental_CatClass__c> catClass = new List<PPA_Rental_CatClass__c>();

        Test.startTest();
        PriceList = [SELECT Id FROM PPA_Price_List__c LIMIT 1];
        catClass = PPA_RentalCatClassController.fetchRentalCatClass(PriceList.Id);
        Assert.isNotNull(catClass[0].Id);
        Test.stopTest();
    }

    @isTest
    public static void deleteSelectedRecordsTest() {
        PPA_Price_List__c PriceList;
        List<PPA_Rental_CatClass__c> catClass = new List<PPA_Rental_CatClass__c>();
        List<Id> deleteIds = new List<Id>();

        Test.startTest();
        PriceList = [SELECT Id FROM PPA_Price_List__c LIMIT 1];
        deleteIds.add(PriceList.Id);
        PPA_RentalCatClassController.deleteSelectedRecords(deleteIds);
        PriceList = [SELECT Id FROM PPA_Price_List__c LIMIT 1];
        Assert.isNotNull(PriceList.Id, 'Price List was not retrieve successfully');

        deleteIds = new List<Id>();
        catClass = [SELECT Id FROM PPA_Rental_CatClass__c LIMIT 1];
        deleteIds.add(catClass[0].Id);
        PPA_RentalCatClassController.deleteSelectedRecords(deleteIds);
        catClass = [SELECT Id, PPA_Like_CatClass__c FROM PPA_Rental_CatClass__c WHERE Id IN :deleteIds LIMIT 1];
        Assert.isTrue(catClass[0].PPA_Like_CatClass__c,'Record Id was not converted to Like CatClass as expected');
        Test.stopTest();
    }


    @isTest
    public static void fetchMonthOnlyMetaDataTest() {
        List<PPA_CatClass_Owner_Update_Month_Only__mdt> monthOnlyValues = new List<PPA_CatClass_Owner_Update_Month_Only__mdt>();
        List<PPA_Rental_CatClass__c> catClass = new List<PPA_Rental_CatClass__c>();

        Test.startTest();
        monthOnlyValues = PPA_RentalCatClassController.fetchMonthOnlyMetaData();
        Assert.isTrue(monthOnlyValues.size() > 0 );
        Test.stopTest();
    }
    @isTest
    public static void updateRecords(){
        PPA_Price_List__c PriceList;
        PriceList = [SELECT Id FROM PPA_Price_List__c LIMIT 1];
        PPA_Rental_CatClass__c rentalCatClass;
        rentalCatClass = [SELECT Id,PPA_New_Day__c,PPA_New_Week__c,PPA_New_Month__c FROM PPA_Rental_CatClass__c WHERE PPA_Price_List__c =:PriceList.Id LIMIT 1];
        Map<string, PPA_Rental_CatClass__c> rccMap = new Map<string, PPA_Rental_CatClass__c>();
        rccMap.put(rentalCatClass.Id, rentalCatClass);
        string inputParam = '[' + JSON.serialize(rccMap) + ']';
        Test.startTest();
        string output = PPA_RentalCatClassController.updateRecords(inputParam);
        System.assertEquals(output, rentalCatClass.Id + ' updated successfully.');
        Test.stopTest();
    }
}