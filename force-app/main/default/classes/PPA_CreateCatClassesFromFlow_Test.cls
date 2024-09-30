@isTest
public class PPA_CreateCatClassesFromFlow_Test {

    @TestSetup
    static void testSetup(){
        List<PPA_Price_List__c> priceLists = new List<PPA_Price_List__c>();
        priceLists.add(new PPA_Price_List__c(Name='TESTOLD'));
        priceLists.add(new PPA_Price_List__c(Name='TESTNEW'));
        insert priceLists;
        
        List<PPA_Rental_CatClass__c> catClasses = new List<PPA_Rental_CatClass__c>();
        catClasses.add(new PPA_Rental_CatClass__c(PPA_Price_List__c=priceLists[0].Id));
        insert catClasses;
    }

    @isTest
    public static void createCatClassesTest() {
        List<PPA_CreateCatClassesFromFlow.Inputs> inputs = new List<PPA_CreateCatClassesFromFlow.Inputs>();
        List<PPA_CreateCatClassesFromFlow.Outputs> outputs = new List<PPA_CreateCatClassesFromFlow.Outputs>();
        PPA_CreateCatClassesFromFlow.Inputs input = new PPA_CreateCatClassesFromFlow.Inputs();
        
        PPA_Price_List__c priceList = [SELECT Id FROM PPA_Price_List__c WHERE Name='TESTOLD' LIMIT 1];
        PPA_Price_List__c newPriceList = [SELECT Id FROM PPA_Price_List__c WHERE Name='TESTNEW' LIMIT 1];

        List<PPA_Rental_CatClass__c> catClasses = [SELECT Id,PPA_Price_List__c,PPA_Product__c,PPA_New_Day__c,PPA_New_Week__c,PPA_New_Month__c,
                                                          PPA_Apply_Rate_Type__c,PPA_Avg_Charged_Day__c,PPA_Avg_Charged_Month__c,PPA_Avg_Charged_Week__c,
                                                          PPA_Bench_Day__c,PPA_Bench_Month__c,PPA_Bench_Week__c,PPA_CatClassOwner__c,CurrencyIsoCode,
                                                          PPA_Old_Day__c,PPA_Old_Month__c,PPA_Old_Week__c,PPA_Customer__c,PPA_Day_Count__c,PPA_Day_Rental__c,
                                                          PPA_Like_CatClass__c,PPA_Loaded_Day__c,PPA_Loaded_Month__c,PPA_Loaded_Week__c,PPA_MasterSort__c,
                                                          PPA_Min_Day__c,PPA_Min_Month__c,PPA_Min_Rate__c,PPA_Min_Week__c,PPA_Month_Count__c,PPA_Month_Rental__c,
                                                          PPA_Num_Customers__c,PPA_Rates_Loaded__c,PPA_Region__c,PPA_Rental_Desc__c,PPA_Rental_Revenue__c,
                                                          PPA_Market_Day__c,PPA_Market_Month__c,PPA_Market_Week__c,PPA_Times_Rented__c,PPA_Week_Count__c,PPA_Week_Rental__c, 
                                                          PPA_Managed_Account_Day__c, PPA_Managed_Account_Week__c, PPA_Managed_Account_Month__c, 
                                                          PPA_Non_Managed_Account_Day__c, PPA_Non_Managed_Account_Week__c, PPA_Non_Managed_Account_Month__c, 
                                                          PPA_National_Account_Day__c, PPA_National_Account_Week__c, PPA_National_Account_Month__c
                                                     FROM PPA_Rental_CatClass__c
                                                    WHERE PPA_Price_List__c = :priceList.Id];
        
        input.priceListId = newPriceList.Id;
        input.rev1CatClasses = catClasses;
        inputs.add(input);

        outputs = PPA_CreateCatClassesFromFlow.createCatClasses(inputs);

        Assert.areEqual('0', outputs[0].errorCode, 'Error was returned from the create Cat Class method');
        Assert.areEqual(1, outputs[0].newCatClasses.size(), 'New CatClasses were not created as expected');
    }

    @isTest
    public static void createCatClassesTestException() {
        List<PPA_CreateCatClassesFromFlow.Inputs> inputs = new List<PPA_CreateCatClassesFromFlow.Inputs>();
        List<PPA_CreateCatClassesFromFlow.Outputs> outputs = new List<PPA_CreateCatClassesFromFlow.Outputs>();
        PPA_CreateCatClassesFromFlow.Inputs input = new PPA_CreateCatClassesFromFlow.Inputs();
        
        PPA_Price_List__c priceList = [SELECT Id FROM PPA_Price_List__c WHERE Name='TESTOLD' LIMIT 1];
        PPA_Price_List__c newPriceList = [SELECT Id FROM PPA_Price_List__c WHERE Name='TESTNEW' LIMIT 1];

        List<PPA_Rental_CatClass__c> catClasses = [SELECT Id,PPA_Price_List__c
                                                     FROM PPA_Rental_CatClass__c
                                                    WHERE PPA_Price_List__c = :priceList.Id];
        
        input.priceListId = newPriceList.Id;
        input.rev1CatClasses = catClasses;
        inputs.add(input);

        outputs = PPA_CreateCatClassesFromFlow.createCatClasses(inputs);

        Assert.areEqual('-1', outputs[0].errorCode, 'Error was not returned as expected');
    }    
}