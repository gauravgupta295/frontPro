@isTest
public with sharing class SBR_3_0_CrewOperations_Test {
     @TestSetup
    static void makeData(){
        List<Product2> products = SBR_3_0_TestDataFactory.createProducts(1, false);
        products[0].Product_SKU__c = 'XXXXX';
        insert products;

        List<Schema.location> location = SBR_3_0_TestDataFactory.createLocations(1,false,'Branch');
        location[0].Analysis_Region_Key__c = '921';
        insert location;
        
        List<SBQQ__Quote__c> quotes = SBR_3_0_TestDataFactory.createQuotes(1, true, SBR_3_0_Constants.QUOTE_REC_TYPE_RENTAL_QUOTE);
		quotes[0].Branch__c = location[0].Id;
        update quotes;
        
        List<SBQQ__QuoteLine__c> beforeQuoteLines = SBR_3_0_TestDataFactory.createQuoteLines(1, false, quotes[0].Id );
        
        

    }

    private static String TASK = 'Orientation';
    @isTest
    static void testCreateOrUpdateCrewSummary() {
        List<SBQQ__Quote__c> quotes = SBR_3_0_TestDataFactory.createQuotes(1, true, SBR_3_0_Constants.QUOTE_REC_TYPE_RENTAL_QUOTE);
        Test.startTest();
        List<Crew__c> createCrew=   SBR_3_0_TestDataFactory.createCrew(2, false, TASK, quotes[0].Id);
        //    SBR_3_0_TestDataFactory.createCrew(2, false, TASK, quotes[0].Id);
        for(Crew__c crew:createCrew)
        {
            crew.Crew__c=0;
        }
        insert createCrew;
        test.stopTest();

        List<Crew_Summary__c> crewSummaries = [SELECT Id FROM Crew_Summary__c];
        List<Crew__c> crews = [SELECT Id FROM Crew__c];

        System.assertEquals(1, crewSummaries.size());
        System.assertEquals(2, crews.size());
    }

    @isTest
    static void testDeleteCrewSummary() {
       List<SBQQ__Quote__c> quotes = [SELECT Id FROM SBQQ__Quote__c];          
       
        List<Crew__c> createCrew=   SBR_3_0_TestDataFactory.createCrew(1, false, TASK, quotes[0].Id);
        //    SBR_3_0_TestDataFactory.createCrew(2, false, TASK, quotes[0].Id);
        for(Crew__c crew:createCrew)
        {
            crew.Crew__c=0;
          
        }
        insert createCrew;
       list<crew__C> crews= [select id,crew_summary__c,Crew_summary__r.Name from  crew__C where id in :createCrew];
        system.debug(crews);
       Crew_Summary__c crwsm =[select id,name from Crew_Summary__c where id=:crews[0].Crew_Summary__c];

        Test.startTest();
            delete createCrew;
        test.stopTest();

        List<Crew_Summary__c> crewSummaries = [SELECT Id FROM Crew_Summary__c];
        List<Crew__c> crewsAfter = [SELECT Id FROM Crew__c];

        System.assertEquals(0, crewSummaries.size());
        System.assertEquals(0, crewsAfter.size());
    }

    @isTest
    static void testcalculateQuoteLineDetails() {
        
        List<SBR_3_0_CrewOperations.CrewQuoteResponse> responseList = new List<SBR_3_0_CrewOperations.CrewQuoteResponse>();
        SBR_3_0_CrewOperations.CrewQuoteResponse response = new SBR_3_0_CrewOperations.CrewQuoteResponse();
        response.crewCount = 5;
        response.stHours = 40.0;
        response.otHours = 10.0;
        response.stCost = 2000.0;
        response.otCost = 500.0;

        responseList.add(response);

		List<Account> lAccount = SBR_3_0_TestDataFactory.createAccounts(1,TRUE);
        
        Analysis_Region__c region = new Analysis_Region__c();
        region.Analysis_Region_Key__c = '921';
        region.Name = 'Test Region';
        region.Company_Code__c = '01';
        insert region;
        
        Schema.Location jobLocation = new Schema.Location();
        jobLocation.Name = 'Test Job Location';
        jobLocation.Street_Address__c = '12 Main Street';
        jobLocation.City__c = 'Toronto';
        jobLocation.Zip_Code__c = 'M7N7B3';
        jobLocation.State__c = 'ON';
        jobLocation.Country__c = 'CA';
        jobLocation.RecordTypeId = SBR_3_0_Constants.LOCATION_BRANCH_RT_ID;
        jobLocation.OMS_Sourcing_Enabled__c = true;
        jobLocation.Distance_Multiplier__c = 50;
        jobLocation.Analysis_Region_Key__c = '921';
        jobLocation.Company_Code__c = '01';
        insert jobLocation;
        
       List<SBQQ__Quote__c> quotes = [SELECT Id, Analysis_Region_Key__c, Company_Code__c, SBQQ__BillingCity__c FROM SBQQ__Quote__c]; 
        for(SBQQ__Quote__c q : quotes){
            q.Company_Code__c = '01';
            q.Branch__c = jobLocation.Id;
        }
        update quotes;
       
        List<Crew__c> createCrew=   SBR_3_0_TestDataFactory.createCrew(1, false, TASK, quotes[0].Id);
        //    SBR_3_0_TestDataFactory.createCrew(2, false, TASK, quotes[0].Id);
        for(Crew__c crew:createCrew)
        {
            crew.Crew__c=0;
          
        }
        Database.insert(createCrew,false);
        
        list<Crew__c> crews= [select id,Task__c,crew_summary__c,Crew_summary__r.Name from  Crew__c where id in :createCrew];
        List<Crew_Summary__c> crwsm =[select Id, Name, Quote__c, Task_Type__c, Total__c from Crew_Summary__c where id=:crews[0].Crew_Summary__c];
        System.debug('crew summary test data ---> '+ crwsm);
        Map<String, Crew_Summary__c> crewSummaryMap = new Map<String, Crew_Summary__c>(); 
        for (Crew_Summary__c crewSummary : crwsm) {
            crewSummaryMap.put((crewSummary.Quote__c + crewSummary.Task_Type__c), crewSummary);
        }

        List<SBR_3_0_CrewOperations.CrewQuoteRequest> reqList = new List<SBR_3_0_CrewOperations.CrewQuoteRequest> ();

        SBR_3_0_CrewOperations.CrewQuoteRequest req = new SBR_3_0_CrewOperations.CrewQuoteRequest();

        req.crewId = createCrew[0].Id;

        req.quoteId= quotes[0].Id;

        reqList.add(req);
        
        Product2 prod = [SELECT Id, Product_SKU__c from Product2 WHERE Product_SKU__c = 'XXXXX'];
        System.debug('product test data ---> '+ prod);
        System.debug('quote test data ---> '+ quotes[0]);
        

        String EXP_RT_ID = Schema.getGlobalDescribe().get('Expense_Crew_Mapping__c').getDescribe().getRecordTypeInfosByName().get('Expense Mapping').getRecordTypeId();
        String CREWSUM_RT_ID = Schema.getGlobalDescribe().get('Expense_Crew_Mapping__c').getDescribe().getRecordTypeInfosByName().get('Crew Mapping').getRecordTypeId();
        
        Expense_Crew_Mapping__c mapping = new Expense_Crew_Mapping__c();
        mapping.RecordTypeId=CREWSUM_RT_ID;
        mapping.Company_Code__c='01';
        mapping.Expense_Crew_Type__c='Orientation';
        mapping.SF_Product_SKU__c=prod.Id;
        mapping.Analysis_Region__c=region.Id;
        
        insert mapping;
        
        
        Test.startTest();
        List<SBR_3_0_CrewOperations.CrewQuoteResponse> resList = SBR_3_0_CrewOperations.calculateQuoteLineDetails(reqList);
        test.stopTest();

        //SBR_3_0_CrewOperations.CrewQuoteResponse resp = resList[0];

        //System.assertNotEquals(0, resp.crewCount);

    }

}