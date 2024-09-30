@isTest
public class PPA_TransportationLWCController_Test {
    
    @testSetup
    static void makeData(){
        List<PPA_Price_List__c> PriceLists = new List<PPA_Price_List__c>();
		List<PPA_Transportation__c> TransRecs = new List<PPA_Transportation__c>();

        PriceLists.add(new PPA_Price_List__c(Name='TEST'));
        insert PriceLists;
		
		TransRecs.add(new PPA_Transportation__c(PPA_Price_List__c=PriceLists[0].Id,
                                                PPA_Transportation_Type__c='Union',
                                                PPA_New_Band1__c=100,
                                                PPA_New_Band2__c=100,
                                                PPA_New_Band3__c=100,
                                                PPA_New_Band4__c=100,
                                                PPA_New_Excess__c=100,
                                                PPA_Rates_Loaded__c=true
                                                ));
		insert TransRecs;
    }

    @isTest
    public static void getRecordsTest() {
        PPA_Price_List__c PriceList;
        List<PPA_Transportation__c> catClass;

        Test.startTest();
        PriceList = [SELECT Id FROM PPA_Price_List__c LIMIT 1];
        catClass = PPA_TransportationLWCController.getRecords(PriceList.Id, 'Union');
        Assert.isNotNull(catClass[0].Id);
        Test.stopTest();
    }
    
    @isTest
    public static void clearTransportationRatesTest() {
        PPA_Transportation__c TransRec;
		List<Id> recIds = new List<Id>();
        PPA_Price_List__c PriceList;
        List<PPA_Transportation__c> TransRecs = new List<PPA_Transportation__c>();
        Exception_Log__c log;

        PriceList = [SELECT Id FROM PPA_Price_List__c LIMIT 1];        
        TransRec = [SELECT Id FROM PPA_Transportation__c LIMIT 1];
        
        Test.startTest();
        // Test with valid Trans Id
        recIds.add(TransRec.Id);
        PPA_TransportationLWCController.clearTransportationRates(recIds);
        TransRec = [SELECT Id, PPA_Rates_Loaded__c, PPA_New_Band1__c FROM PPA_Transportation__c LIMIT 1];
        Assert.isNull(TransRec.PPA_New_Band1__c,'Band1 was not cleared out as expected');

        TransRec.PPA_Rates_Loaded__c = true;
        TransRecs.add(TransRec);
        update TransRecs;

        // This is for the exception handler
        recIds.add(PriceList.Id);        
        PPA_TransportationLWCController.clearTransportationRates(recIds);
        TransRec = [SELECT Id, PPA_Rates_Loaded__c FROM PPA_Transportation__c LIMIT 1];
        Assert.isTrue(TransRec.PPA_Rates_Loaded__c,'The Rates Loaded was set to false');

        log = [SELECT Id FROM Exception_Log__c LIMIT 1];
        Assert.isNotNull(log.Id, 'No exception log was created');
        Test.stopTest();
    }    
}