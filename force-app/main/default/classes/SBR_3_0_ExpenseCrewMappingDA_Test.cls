/*********************************************************************************************************************
* Apex Class: SBR_3_0_ExpenseCrewMappingDA
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Test class for SBR_3_0_ExpenseCrewMappingDA
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Soni Pinjala         	2023-09-04          Initial version    
*********************************************************************************************************************/
@isTest
public class SBR_3_0_ExpenseCrewMappingDA_Test {
    static testMethod void testgetExpenseCrewMappingForScaffoldingQuote(){
        
        List<Product2> products = SBR_3_0_TestDataFactory.createProducts(1, false);
        products[0].Product_SKU__c = 'XXXXX';
        insert products;
        
        Analysis_Region__c region = new Analysis_Region__c();
        region.Analysis_Region_Key__c = '921';
        region.Name = 'Test Region';
        region.Company_Code__c = '01';
        insert region;
        
        Schema.Location branchLocation = new Schema.Location();
        branchLocation.Branch_Location_Number__c = '720';
        branchLocation.Name = 'Test Branch Location';
        branchLocation.Street_Address__c = '12 Main Street';
        branchLocation.City__c = 'Toronto';
        branchLocation.Zip_Code__c = 'M7N7B3';
        branchLocation.State__c = 'ON';
        branchLocation.Analysis_Region_Key__c = '921';
        branchLocation.Country__c = 'CA';
        branchLocation.Job_Number__c='332112';
        branchLocation.RecordTypeId = SBR_3_0_Constants.LOCATION_BRANCH_RT_ID;
        branchLocation.Company_Code__c = 'X';
        branchLocation.Time_Zone_Name__c = 'America/Chicago';
        branchLocation.Time_Zone__c = 3;
        branchLocation.Time_Zone_Id__c = 'America/Chicago';
        insert branchLocation;
        
        List<SBQQ__Quote__c> quotes = SBR_3_0_TestDataFactory.createQuotes(1, true, SBR_3_0_Constants.QUOTE_REC_TYPE_RENTAL_QUOTE);
        quotes[0].Company_Code__c  = '01';
        quotes[0].Branch__c =branchLocation.Id;
        quotes[0].Account_Record_Type_Txt__c = 'Credit';
        update quotes[0];
        List<Crew__c> createCrew=   SBR_3_0_TestDataFactory.createCrew(1, false, 'Orientation', quotes[0].Id);
        List<SBQQ__Quote__c> quoteRec= [Select Id,Branch__c,Company_Code__c, Branch__r.Analysis_Region_Key__c, Analysis_Region_Key__c from SBQQ__Quote__c ];
        
        
        String EXP_RT_ID = Schema.getGlobalDescribe().get('Expense_Crew_Mapping__c').getDescribe().getRecordTypeInfosByName().get('Expense Mapping').getRecordTypeId();
        String CREWSUM_RT_ID = Schema.getGlobalDescribe().get('Expense_Crew_Mapping__c').getDescribe().getRecordTypeInfosByName().get('Crew Mapping').getRecordTypeId();
        
        Expense_Crew_Mapping__c exCrewMapping = new Expense_Crew_Mapping__c();
        exCrewMapping.RecordTypeId=CREWSUM_RT_ID;
        exCrewMapping.Company_Code__c='01';
        exCrewMapping.Expense_Crew_Type__c='Orientation';
        exCrewMapping.SF_Product_SKU__c=products[0].Id;
        exCrewMapping.Analysis_Region__c=region.Id;
        
        insert exCrewMapping;
        
        Test.startTest();
        List<Expense_Crew_Mapping__c> result = SBR_3_0_ExpenseCrewMappingDA.getExpenseCrewMappingForScaffoldingQuote(quoteRec[0]);
        Test.stopTest();
        System.assertEquals(result[0].Company_Code__c, '01');
    }
    
    static testMethod void testgetExpenseCrewMapping(){
        
        List<Product2> products = SBR_3_0_TestDataFactory.createProducts(1, false);
        products[0].Product_SKU__c = 'XXXXX';
        insert products;
        
        Analysis_Region__c region = new Analysis_Region__c();
        region.Analysis_Region_Key__c = '921';
        region.Name = 'Test Region';
        region.Company_Code__c = '01';
        insert region;
        
        Schema.Location branchLocation = new Schema.Location();
        branchLocation.Branch_Location_Number__c = '720';
        branchLocation.Name = 'Test Branch Location';
        branchLocation.Street_Address__c = '12 Main Street';
        branchLocation.City__c = 'Toronto';
        branchLocation.Zip_Code__c = 'M7N7B3';
        branchLocation.State__c = 'ON';
        branchLocation.Analysis_Region_Key__c = '921';
        branchLocation.Country__c = 'CA';
        branchLocation.Job_Number__c='332112';
        branchLocation.RecordTypeId = SBR_3_0_Constants.LOCATION_BRANCH_RT_ID;
        branchLocation.Company_Code__c = 'X';
        branchLocation.Time_Zone_Name__c = 'America/Chicago';
        branchLocation.Time_Zone__c = 3;
        branchLocation.Time_Zone_Id__c = 'America/Chicago';
        insert branchLocation;
        
        List<SBQQ__Quote__c> quotes = SBR_3_0_TestDataFactory.createQuotes(1, true, SBR_3_0_Constants.QUOTE_REC_TYPE_RENTAL_QUOTE);
        quotes[0].Company_Code__c  = '01';
        quotes[0].Branch__c =branchLocation.Id;
        update quotes[0];
        List<SBQQ__Quote__c> quoteRec= [Select Id,Branch__c,Company_Code__c, Branch__r.Analysis_Region_Key__c, Analysis_Region_Key__c from SBQQ__Quote__c ];
        List<Crew__c> createCrew=   SBR_3_0_TestDataFactory.createCrew(1, false, 'Mobilization', quotes[0].Id);
        
        String EXP_RT_ID = Schema.getGlobalDescribe().get('Expense_Crew_Mapping__c').getDescribe().getRecordTypeInfosByName().get('Expense Mapping').getRecordTypeId();
        String CREWSUM_RT_ID = Schema.getGlobalDescribe().get('Expense_Crew_Mapping__c').getDescribe().getRecordTypeInfosByName().get('Crew Mapping').getRecordTypeId();
        
        Expense_Crew_Mapping__c exCrewMapping = new Expense_Crew_Mapping__c();
        exCrewMapping.RecordTypeId=EXP_RT_ID;
        exCrewMapping.Company_Code__c='01';
        exCrewMapping.Expense_Crew_Type__c='Mobilization';
        exCrewMapping.SF_Product_SKU__c=products[0].Id;
        exCrewMapping.Analysis_Region__c=region.Id;
        
        insert exCrewMapping;
        
        Test.startTest();
        List<Expense_Crew_Mapping__c> result = SBR_3_0_ExpenseCrewMappingDA.getExpenseCrewMappingForProductSKU(quoteRec[0], products[0].Id);
        Expense_Crew_Mapping__c result1 = SBR_3_0_ExpenseCrewMappingDA.getExpenseCrewMapping(quoteRec[0],'Mobilization');
        List<Expense_Crew_Mapping__c> result2 = SBR_3_0_ExpenseCrewMappingDA.getExpenseCrewMapping(quoteRec,new Set<String>{'Mobilization'});
        List<Expense_Crew_Mapping__c> result3 = SBR_3_0_ExpenseCrewMappingDA.getExpenseCrewMappingForProductSKU(quoteRec,new Set<String>{'Mobilization'});
        Test.stopTest();
        System.assertEquals(result1.Analysis_Region_Key__c, '921');
        System.assert(result2.size() > 0);
    }
}