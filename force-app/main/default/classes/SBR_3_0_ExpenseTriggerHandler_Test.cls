/*********************************************************************************************************************
* Apex Class: SBR_3_0_ExpenseTriggerHandler
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Test class for Expense Trigger
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Soni Pinjala         	2023-08-29          Initial version    
*********************************************************************************************************************/
@isTest
public class SBR_3_0_ExpenseTriggerHandler_Test {

    @TestSetup
    static void makeData() {
        Account acct = new Account(
            RM_Account_Number__c = '12345',
            Name = SBR_3_0_API_Web_Jobsite_DA.JOBSITEACCOUNTNAME,
            BillingStreet = '123 Main Street',
            BillingCity = 'test',
            BillingPostalCode = '20173',
            BillingState = 'VA',
            BillingCountry = 'US',
            Company_Code__c = '1',
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
            Company_Code__c = '1',
            SBQQ__Account__c = acct.Id,
            SBQQ__DeliveryMethod__c = 'Delivery',
            Start_Date__c = System.now().addMonths(2),
            End_Date__c = System.now().addMonths(3),
            //Duration__c = 'Custom',
            Distance_to_Job_Site__c = 90,
            Rates_To_Be_Used__c = 'Suggested',
            Branch__c = branchLocation.Id
        );
        insert quote;
		List<Product2> lProducts = SBR_3_0_TestDataFactory.createProducts(1,TRUE);
        SBR_Expense__c testExpense  = new SBR_Expense__c();
        testExpense .Quote_Expenses__c = quote.Id;
        testExpense .Quantity__c = 5;
        testExpense .Price__c = 5;
        testExpense .Analysis_Region_Key__c = '921';
        testExpense .ExpenseType__c = 'Safety/Consumables';
        testExpense .Product_Lookup__c  = lProducts[0]?.id;
        insert testExpense ;

    }
    
    @isTest
    static void testAfterUpdateandDelete(){
        
        List<SBR_Expense__c> exp = [SELECT Id, Analysis_Region_Key__c from SBR_Expense__c WHERE Analysis_Region_Key__c = '921'];
        exp[0].Analysis_Region_Key__c = '933';
        update exp;
        System.assertEquals('933', exp[0].Analysis_Region_Key__c);
        delete exp[0];
    }
}