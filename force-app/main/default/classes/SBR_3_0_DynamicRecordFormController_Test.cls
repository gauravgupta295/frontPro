/*********************************************************************************************************************
* Apex Class: SBR_3_0_DynamicRecordFormController_Test
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Class to test SBR_3_0_DynamicRecordFormController
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME                  DATE                    DETAIL FEATURES
    1.0         Gaurav Gaur                     2023-10-18              Initial version    
*********************************************************************************************************************/
@isTest public class  SBR_3_0_DynamicRecordFormController_Test {
    
    @TestSetup
    static void testSetup() {
        Account acct = new Account(
            RM_Account_Number__c = '12345',
            Name = SBR_3_0_API_Web_Jobsite_DA.JOBSITEACCOUNTNAME,
            BillingStreet = '123 Main Street',
            BillingCity = 'test',
            BillingPostalCode = '20173',
            BillingState = 'VA',
            BillingCountry = 'US',
            Phone = '1234567890');
        insert acct;

        Pricebook2 priceBook = new Pricebook2(
			Id = Test.getStandardPricebookId(),
			IsActive = true
		);
		update priceBook;
        
        Schema.Location branchLocation = new Schema.Location();
		branchLocation.Branch_Location_Number__c = '720';
		branchLocation.Name = 'Test Branch Location';
		branchLocation.Street_Address__c = '12 Main Street';
		branchLocation.City__c = 'Toronto';
		branchLocation.Zip_Code__c = 'M7N7B3';
		branchLocation.State__c = 'ON';
		branchLocation.Country__c = 'CA';
		branchLocation.Job_Number__c='332112';
		branchLocation.RecordTypeId = SBR_3_0_Constants.LOCATION_BRANCH_RT_ID;
		branchLocation.Company_Code__c = 'X';
		branchLocation.Time_Zone_Name__c = 'America/Chicago';
		branchLocation.Time_Zone__c = 3;
		branchLocation.Analysis_Region_Key__c ='293';
		insert branchLocation;
        
        Schema.Location jobLocation = new Schema.Location();
		jobLocation.Name = 'Test Job Location';
		jobLocation.Street_Address__c = '12 Main Street';
		jobLocation.City__c = 'Toronto';
		jobLocation.Zip_Code__c = 'M7N7B3';
		jobLocation.State__c = 'ON';
		jobLocation.Country__c = 'CA';
		jobLocation.RecordTypeId = SBR_3_0_Constants.LOCATION_JOB_RT_ID;
		jobLocation.OMS_Sourcing_Enabled__c = true;
		jobLocation.Distance_Multiplier__c = 50;
		jobLocation.Analysis_Region_Key__c = '001';
		jobLocation.Company_Code__c = '01';
		insert jobLocation;
        
        AssociatedLocation jobSite = new AssociatedLocation(
			Name__c = 'Test Job Site',
			ParentRecordId = acct.Id,
			LocationId = jobLocation.Id,
			Branch__c = branchLocation.Id,
			Job_Number__c = '20221004A'
		);
		insert jobSite;
        
		Order order = new Order(
			Quote_Name__c = 'Test Quote',
			AccountId = acct.Id,
			Jobsite__c = jobSite.Id,
			Branch__c = branchLocation.Id,
			Deliverymethod__c = 'Delivery',
			Status = 'Draft',
			Company_Code__c = '01',
			Pricebook2Id = priceBook.Id,
			Start_Date__c = date.valueOf('2022-10-07 12:00:00'),
			EffectiveDate = date.valueOf('2022-10-07 12:00:00'),
			EndDate = date.valueOf('2022-10-08 8:00:00'),
			Earliest_Delivery_Date__c = date.valueOf('2022-10-07 12:00:00'),
			Opt_Out_RPP__c = false,
			Opt_Out_Fuel_Charge__c = false,
			Selling_Channel__c = 'SBRB2B',
			Duration__c = 'Custom',
            Account_Record_Type_Txt__c='Credit'
		);
		insert order;
    }

    static testMethod void testGetConfigurations(){
        Test.startTest();
        Object obj = SBR_3_0_DynamicRecordFormController.getConfigurations('Order_Detail_Tab');
        //string s = SBR_3_0_DynamicRecordFormController.getStyleSheet('sbr_3_0_CustomDatatableCSS');
        Test.stopTest();
        System.assertNotEquals(null,obj);
    }
    
    static testMethod void testCheckRecord(){
        SBQQ__Quote__c quote = new SBQQ__Quote__c(Account_Record_Type_Txt__c='Credit');
        insert quote;
        Test.startTest();
        Order orderRecord = [SELECT Id FROM Order LIMIT 1];
        Boolean val = SBR_3_0_DynamicRecordFormController.checkRecord('SBQQ__Quote__c', quote.Id);
        Boolean valOrder = SBR_3_0_DynamicRecordFormController.checkRecord('Order', orderRecord.Id);

        Test.stopTest();
        System.assertEquals(false, val);
        System.assertEquals(false, valOrder);
    }
    
}