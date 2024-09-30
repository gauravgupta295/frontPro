@isTest
public with sharing class PPA_CatClassMassEditController_Test {

    @TestSetup
    static void makeData() {
        List<PPA_Price_List__c> PriceLists = new List<PPA_Price_List__c>();
		List<PPA_Rental_CatClass__c> CatClass = new List<PPA_Rental_CatClass__c>();

        PriceLists.add(new PPA_Price_List__c(Name='TEST'));
        insert PriceLists;
        
        CatClass.add(new PPA_Rental_CatClass__c(PPA_Price_List__c=PriceLists[0].Id,
                                                PPA_New_Day__c=100,
                                                PPA_New_Week__c=200,
                                                PPA_New_Month__c=500
                                                ));        

        insert CatClass;
    }

    @isTest
    public static void applyMassEditUpdatesTest() {
        PPA_Rental_CatClass__c catClass1;
        PPA_Rental_CatClass__c catClass2;
        String inputStr;

        catClass1 = [SELECT Id FROM PPA_Rental_CatClass__c LIMIT 1];
        inputStr = '[{"recordId": "' + catClass1.Id + '", "newDayValue": "150", "newWeekValue": "250", "newMonthValue": "550"}]';

        Test.startTest();
        PPA_CatClassMassEditController.applyMassEditUpdates(inputStr);
        catClass2 = [SELECT Id, PPA_New_Day__c, PPA_New_Week__c, PPA_New_Month__c, PPA_UpdatedBy_Mass_Edit__c
                       FROM PPA_Rental_CatClass__c LIMIT 1];

        Assert.areEqual(catClass2.PPA_New_Day__c, 150, 'New Day was not updated as expected');
        Assert.areEqual(catClass2.PPA_New_Week__c, 250, 'New Week was not updated as expected');
        Assert.areEqual(catClass2.PPA_New_Month__c, 550, 'New Month was not updated as expected');
        Assert.isTrue(catClass2.PPA_UpdatedBy_Mass_Edit__c, 'Updates by Mass Edit was not set correctly');
        Test.stopTest();
    }

    @isTest
    public static void applyMassEditUpdatesTestException() {
        PPA_Rental_CatClass__c catClass1;
        PPA_Rental_CatClass__c catClass2;
        String inputStr;

        inputStr = '[{"recordId": "", "newDayValue": "150", "newWeekValue": "250", "newMonthValue": "550"}]';

        Test.startTest();
        PPA_CatClassMassEditController.applyMassEditUpdates(inputStr);

        catClass2 = [SELECT Id, PPA_New_Day__c, PPA_New_Week__c, PPA_New_Month__c, PPA_UpdatedBy_Mass_Edit__c
                       FROM PPA_Rental_CatClass__c LIMIT 1];

        Assert.areEqual(catClass2.PPA_New_Day__c, 100, 'New Day was not the original value');
        Assert.areEqual(catClass2.PPA_New_Week__c, 200, 'New Week was not the original value');
        Assert.areEqual(catClass2.PPA_New_Month__c, 500, 'New Month was not the original value');
        Assert.isFalse(catClass2.PPA_UpdatedBy_Mass_Edit__c, 'Updates by Mass Edit was not the original value');
        Test.stopTest();
    }
}