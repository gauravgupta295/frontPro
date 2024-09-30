@IsTest
public class SBR_3_0_ExpenseOperations_Test {
    
   
    
    @IsTest
    public static void updateQuoteLineForScaffoldingTest()
    {

        Account acct = new Account(
            RM_Account_Number__c = '12345',
            Name = SBR_3_0_API_Web_Jobsite_DA.JOBSITEACCOUNTNAME,
            BillingStreet = '123 Main Street',
            BillingCity = 'test',
            BillingPostalCode = '20173',
            BillingState = 'VA',
            BillingCountry = 'US',
            Company_Code__c = '01',
            phone='3445354635'
        );
        insert acct;
        
         // Create Branch
        Schema.Location branchLocation = new Schema.Location();
        branchLocation.Branch_Location_Number__c = '720';
        branchLocation.Name = 'Test Branch Location';
        branchLocation.Street_Address__c = '12 Main Street';
        branchLocation.City__c = 'Toronto';
        branchLocation.Zip_Code__c = 'M7N7B3';
        branchLocation.State__c = 'ON';
        branchLocation.Country__c = 'CA';
        branchLocation.Latitude_Longitude__Latitude__s = 56.77395;
        branchLocation.Latitude_Longitude__Longitude__s = -111.42814;
        branchLocation.Job_Number__c='332112';
        branchLocation.RecordTypeId = SBR_3_0_Constants.LOCATION_BRANCH_RT_ID;
        branchLocation.Company_Code__c = 'X';
        branchLocation.Analysis_Region_Key__c = '921';
        branchLocation.Time_Zone_Name__c = 'America/Chicago';
        branchLocation.Time_Zone__c = 3;
        insert branchLocation;

        SBQQ__Quote__c quote = new SBQQ__Quote__c(
            SBQQ__BillingCity__c = 'Test City',
            Contingency_Plan__c = true,
            Seasonal_Quote__c = true,
            Shift_Pricing_Required__c = true,
            Standby_Pricing__c = true,
            Company_Code__c = '01',
            SBQQ__Account__c = acct.Id,
            SBQQ__DeliveryMethod__c = 'Delivery',
            Start_Date__c = System.now().addMonths(2),
            End_Date__c = System.now().addMonths(3),
            Duration__c = 'Custom',
            Distance_to_Job_Site__c = 90,
            Rates_To_Be_Used__c = 'Suggested',
            Branch__c = branchLocation.Id,
            Submitted_to_Wynne__c=true
        );
        insert quote;
        String EXP_RT_ID = Schema.getGlobalDescribe().get('Expense_Crew_Mapping__c').getDescribe().getRecordTypeInfosByName().get('Expense Mapping').getRecordTypeId();
        
        Analysis_Region__c region = new Analysis_Region__c();
        region.Analysis_Region_Key__c = '921';
        region.Name = 'Test Region';
        region.Company_Code__c = '01';
        insert region;
        
        List<Product2> lProducts = SBR_3_0_TestDataFactory.createProducts(1,false);
        lProducts[0].Product_SKU__c = System.Label.E_Labor_Product_SKU;
        insert lProducts[0];
        
        Expense_Crew_Mapping__c mapping = new Expense_Crew_Mapping__c();
        mapping.RecordTypeId=EXP_RT_ID;
        mapping.Company_Code__c='01';
        mapping.Expense_Crew_Type__c='Hotel';
        mapping.SF_Product_SKU__c=lProducts[0].Id;
        mapping.Analysis_Region__c=region.Id;
        insert mapping;
            
        SBR_Expense__c ex = new SBR_Expense__c();
        ex.Quote_Expenses__c = quote.Id;
        ex.Quantity__c = 5;
        ex.Price__c = 5;
        ex.Analysis_Region_Key__c = '921';
        ex.ExpenseType__c = 'Hotel';
        ex.Product_Lookup__c  = lProducts[0]?.id;    
        Test.startTest();
        insert ex;
        
        list <SBR_Expense__c> expList=new list<SBR_Expense__c>();
        expList.add(ex);
        SBR_3_0_ExpenseOperations.updateQuoteLineForScaffolding(expList);
        Test.stopTest();
        system.assertEquals([select id from SBR_Expense__c ].size(),1);
        
        
    }
    
    

}