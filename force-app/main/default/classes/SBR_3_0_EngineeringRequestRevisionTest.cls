/*********************************************************************************************************************
* Apex Class: SBR_3_0_EngineeringRequestRevisionTest
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Test class for SBR_3_0_EngineeringRequestRevision
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME                        DATE                DETAIL FEATURES
    1.0         Aditee Churiwala                     2022-12-14              Initial version   
*********************************************************************************************************************/
@isTest
public class SBR_3_0_EngineeringRequestRevisionTest {
	@TestSetup
    static void makeData(){
        // Create Account
        Account acct = new Account();
        acct.RM_Account_Number__c = '4';
        acct.Company_Code__c = '01';
        acct.Name = 'Test Account';
        acct.Record_Type_Text__c = 'Credit';
        acct.E_mail_Address__c = '123@asdf.com';
        acct.Phone = '1234567890';
        acct.BillingStreet = '123 Main Street';
        acct.BillingCity = 'Toronto';
        acct.BillingPostalCode = 'M9N7V5';
        acct.BillingState = 'ON';
        acct.BillingCountry = 'CA';
        acct.Drivers_License__c = 'AKF';
        acct.Driver_s_License_State__c = 'AL';
        insert acct;
       // Account acct = SBR_3_0_TestDataFactory.createAccounts(1, true, null)[0];
        // Create Analysis Region
        Analysis_Region__c region = new Analysis_Region__c();
        region.Analysis_Region_Key__c = '001';
        region.Name = 'Test Region';
        region.Company_Code__c = '01';
        insert region;
        // Create Location
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
        // Create Branch
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
        insert branchLocation;
        // Create Job Site
        AssociatedLocation jobSite = new AssociatedLocation(
            Name__c = 'Test Job Site',
            ParentRecordId = acct.Id,
            LocationId = jobLocation.Id,
            Branch__c = branchLocation.Id,
            Job_Number__c = '20221004A',
            Job_Site_Id__c ='SF-92999999999'
        );
        insert jobSite;
        
                Pricebook2 priceBook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update priceBook;
        
        Order orderRecord = new Order(Contract_Order_Number__c = '102939',   
                                      Type = 'SalesOrder',                         
                                      Status = 'Draft', 
                                      Name = 'Test Order',
                                      Start_Date__c = System.today().addMonths(1),
                                      EffectiveDate = System.today().addMonths(2),
                                      EndDate = System.today().addMonths(4),
                                      Earliest_Delivery_Date__c = System.today().addMonths(3),
                                      Pricebook2Id = priceBook.Id,
                                      RecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('Contract Order').getRecordTypeId(),
                                      AccountId = acct.id);
        insert orderRecord;

        
        // Create Eng Req
        Engineering_Request__c  engReq = new Engineering_Request__c ();
            engReq.Branch__c = branchLocation.Id;
            engReq.Jobsite__c = jobSite.Id;
            engReq.Customer__c = acct.Id;
            engReq.Eng_Job_Number__c = 12;
            engReq.Name = 'Test';
            engReq.Product_Line__c = 'Excavation Shoring';
            engReq.Status__c = 'New';
            engReq.Support_Type__c = 'Trench';
            engReq.Order__c  = orderRecord.id;
        insert engReq;
    }
    @isTest 
    static void testCreateRevision() {
        Engineering_Request__c engReq = [SELECT Id FROM Engineering_Request__c LIMIT 1];
        Test.startTest();
       		SBR_3_0_EngineeringRequestRevision.cloneEngineeringRequest(engReq.Id, '');
        Test.stopTest();

        Integer count = [SELECT count() FROM Engineering_Request__c];
        System.assertEquals(2, count);
    }
     @isTest 
    static void testCreateRevision2() {
        Engineering_Request__c engReq = [SELECT Id FROM Engineering_Request__c LIMIT 1];
        Test.startTest();
       		SBR_3_0_EngineeringRequestRevision.cloneEngineeringRequest(engReq.Id, '');
        Test.stopTest();

        Integer count = [SELECT count() FROM Engineering_Request__c];
        System.assertEquals(2, count);
    }
    
    @isTest 
    static void testCreateOrder() {
        Engineering_Request__c engReq = [SELECT Id,Order__c, Branch__c,Jobsite__c,Customer__c FROM Engineering_Request__c LIMIT 1];
        Test.startTest();
        	Engineering_Request__c  engReqs = new Engineering_Request__c ();
            engReqs.Branch__c = engReq.Branch__c;
            engReqs.Jobsite__c = engReq.Jobsite__c;
            engReqs.Customer__c = engReq.Customer__c;
            engReqs.Order__c = engReq.Order__c;
            engReqs.Eng_Job_Number__c = 12;
            engReqs.Name = 'Test';
            engReqs.Product_Line__c = 'Excavation Shoring';
            engReqs.Status__c = 'New';
            engReqs.Support_Type__c = 'Trench';
        	engReqs.Source_Engineering_Request__c = engReq.Id;
        	insert engReqs;
       		SBR_3_0_EngineeringRequestRevision.cloneEngineeringRequest(engReq.Id, engReqs.Id);
            SBR_3_0_EngineeringRequestRevision.searchOriginalRequest(engReqs.Id);
        Test.stopTest();

        Integer count = [SELECT count() FROM Engineering_Request__c];
        //System.assertEquals(2, count);
    }
    
    
    
}