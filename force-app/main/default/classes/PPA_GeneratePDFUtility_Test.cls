@isTest
public class PPA_GeneratePDFUtility_Test {

    @TestSetup
    public static void makeData(){
        PPA_SeedDataForAdminLookup.loadCustomSettings();

        PPA_Price_List__c priceList = new PPA_Price_List__c();
        priceList.Name='TEST';
        insert priceList;

        PPA_Rental_CatClass__c catClass = new PPA_Rental_CatClass__c();
        catClass.PPA_Price_List__c = priceList.Id;
        catClass.PPA_Rates_Loaded__c = true;
        catClass.PPA_New_Day__c = 100.00;
        insert CatClass;

        List<PPA_Transportation__c> trans = new List<PPA_Transportation__c>();
        trans.add(new PPA_Transportation__c(PPA_Price_List__c = priceList.Id, PPA_Transportation_Type__c = 'Union', PPA_Truck_Type__c = 'Pickup / Stakebody'));
        trans.add(new PPA_Transportation__c(PPA_Price_List__c = priceList.Id, PPA_Transportation_Type__c = 'NonUnion', PPA_Truck_Type__c = 'Pickup / Stakebody', PPA_Rates_Loaded__c=true, PPA_Old_Band1__c=100.00, PPA_Old_Band2__c=100.00, PPA_Old_Band3__c=100.00, PPA_Old_Band4__c=100.00, PPA_Old_Excess__c=2.00));
        trans.add(new PPA_Transportation__c(PPA_Price_List__c = priceList.Id, PPA_Transportation_Type__c = 'NonUnion', PPA_Truck_Type__c = 'Tractor', PPA_Rates_Loaded__c=true, PPA_New_Band1__c=100.00, PPA_New_Band2__c=100.00, PPA_New_Band3__c=100.00, PPA_New_Band4__c=100.00, PPA_New_Excess__c=2.00));
        insert trans;
    }
}