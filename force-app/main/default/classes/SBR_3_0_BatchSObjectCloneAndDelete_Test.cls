/**
* @group             : 
* @last modified on  : 11-14-2023
* @last modified by  : Hamza B
**/
@isTest
public class SBR_3_0_BatchSObjectCloneAndDelete_Test {
    
    @isTest
    static void testBatchSObjectCloseAndDeleteSuccess(){
        Account acct = new Account();
        acct.RM_Account_Number__c = '9';
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
        SBR_3_0_TriggerHandler.bypass('SBR_3_0_AccountTriggerHandler');//bypass trigger
        insert acct;
        
        Schema.Location jobLocation = new Schema.Location();
        jobLocation.Name = 'Test Job Location1';
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
        branchLocation.Name = 'Test Branch Location1';
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
        branchLocation.Time_Zone_Id__c = '1111';
        branchLocation.OMS_Sourcing_Enabled__c = true;
        branchLocation.Analysis_Region_Key__c = '921';
        branchLocation.Latitude_Longitude__Latitude__s = 47.09;
        branchLocation.Latitude_Longitude__Longitude__s = 47.09;
        insert branchLocation;
        
        // Create Job Site
        AssociatedLocation jobSite = new AssociatedLocation(
            Name__c = 'Test Job Site1',
            Latitude_Longitude__Latitude__s = 48.51,
            Latitude_Longitude__Longitude__s = -117.62,
            ParentRecordId = acct.Id,
            LocationId = jobLocation.Id,
            Branch__c = branchLocation.Id,
            Job_Number__c = '20221004A'
        );
        insert jobSite;
        
        Pricebook2 priceBook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update priceBook;
        Order order = SBR_3_0_TestDataFactory.createOrder(true, 'Test Order', Schema.SObjectType.Order.getRecordTypeInfosByName().get('Reservation Order').getRecordTypeId());
        
        /* 
// Create Order
Order order = new Order(
Quote_Name__c = 'Test Quote5',
AccountId = acct.Id,
Jobsite__c = jobSite.Id,
Deliverymethod__c = 'Delivery',
Delivery_Charge__c = 0,
Status = 'Draft',
Pricebook2Id = priceBook.Id,
Start_Date__c = system.today().addMonths(1),
EffectiveDate = system.today().addMonths(1),
EndDate = system.today().addMonths(2),
Return_Date__c = system.today().addMonths(3),
Estimated_Return_Date__c = system.today().addMonths(3),
Earliest_Delivery_Date__c = system.today().addMonths(1),
Opt_Out_RPP__c = false,
Order_Initiating_Channel__c = 'SLSFRC',
Opt_Out_Fuel_Charge__c = false,
Selling_Channel__c = 'SBRB2B',
Duration__c = 'Custom',
Reservation_Order_Number__c = '12342',
Branch__c = branchLocation.Id,
Sourcing_Branch__c = branchLocation.Id,
RecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('Reservation Order').getRecordTypeId()
);
insert order;
*/
        Product2 prod2 = new Product2();
        prod2.Name = 'Test Product 2';
        prod2.Product_Type__c = 'Cat-Class';
        prod2.Product_SKU__c = '123877';
        prod2.Category__c = '32234';
        prod2.Class__c = '2049';
        prod2.ToolFlex__c = 'N';
        insert prod2;
        
        List<PricebookEntry> pbEntry = new List<PricebookEntry>();
        PricebookEntry stdPbe = new PricebookEntry();
        stdPbe.Product2Id = prod2.Id;
        stdPbe.Pricebook2Id = Test.getStandardPricebookId();
        stdPbe.IsActive = true;
        stdPbe.UnitPrice = 1020;
        stdPbe.CurrencyIsoCode = 'USD';
        pbEntry.add(stdPbe);
        insert pbEntry;
        
        OrderItem ordItem = new OrderItem(
            OrderId = order.Id,
            Product2Id = prod2.Id,
            Quantity = 5,
            UnitPrice = 100,
            PricebookEntryId = pbEntry[0].Id
        );
        
        insert ordItem;
        
        Map<String, Object> newFieldValue = new Map<String, Object>();
        newFieldValue.put('Product2Id', prod2.Id);
        
        Conversion_Log__c cLog = new Conversion_Log__c();
        cLog.Error_Message__c = 'tes';
        cLog.New_Value__c='new';
        clog.Old_Value__c='old';
        clog.Type__c='type';
        insert cLog;
        
        String whereClause = 'Product2Id = \'' + prod2.Id + '\'';
        
        Test.startTest();
        
        Id batchJobId = Database.executeBatch(new SBR_3_0_BatchSObjectCloneAndDelete('OrderItem', newFieldValue, 
                                                                                     whereClause, '', cLog,pbEntry, new List<String>{'SBR_3_0_OrderItemTriggerHandler'}), 20);
        
        Test.stopTest();
    }
    @isTest
    static void testBatchSObjectCloseAndDelSuccessOrderBY(){
        Account acct = new Account();
        acct.RM_Account_Number__c = '9';
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
        SBR_3_0_TriggerHandler.bypass('SBR_3_0_AccountTriggerHandler');//bypass trigger
        insert acct;
        
        Schema.Location jobLocation = new Schema.Location();
        jobLocation.Name = 'Test Job Location1';
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
        branchLocation.Name = 'Test Branch Location1';
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
        branchLocation.Time_Zone_Id__c = '1111';
        branchLocation.OMS_Sourcing_Enabled__c = true;
        branchLocation.Analysis_Region_Key__c = '921';
        branchLocation.Latitude_Longitude__Latitude__s = 47.09;
        branchLocation.Latitude_Longitude__Longitude__s = 47.09;
        insert branchLocation;
        
        // Create Job Site
        AssociatedLocation jobSite = new AssociatedLocation(
            Name__c = 'Test Job Site1',
            Latitude_Longitude__Latitude__s = 48.51,
            Latitude_Longitude__Longitude__s = -117.62,
            ParentRecordId = acct.Id,
            LocationId = jobLocation.Id,
            Branch__c = branchLocation.Id,
            Job_Number__c = '20221004A'
        );
        insert jobSite;
        
        Pricebook2 priceBook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update priceBook;
        Order order = SBR_3_0_TestDataFactory.createOrder(true, 'Test Order', Schema.SObjectType.Order.getRecordTypeInfosByName().get('Reservation Order').getRecordTypeId());
        
        /* 
// Create Order
Order order = new Order(
Quote_Name__c = 'Test Quote5',
AccountId = acct.Id,
Jobsite__c = jobSite.Id,
Deliverymethod__c = 'Delivery',
Delivery_Charge__c = 0,
Status = 'Draft',
Pricebook2Id = priceBook.Id,
Start_Date__c = system.today().addMonths(1),
EffectiveDate = system.today().addMonths(1),
EndDate = system.today().addMonths(2),
Return_Date__c = system.today().addMonths(3),
Estimated_Return_Date__c = system.today().addMonths(3),
Earliest_Delivery_Date__c = system.today().addMonths(1),
Opt_Out_RPP__c = false,
Order_Initiating_Channel__c = 'SLSFRC',
Opt_Out_Fuel_Charge__c = false,
Selling_Channel__c = 'SBRB2B',
Duration__c = 'Custom',
Reservation_Order_Number__c = '12342',
Branch__c = branchLocation.Id,
Sourcing_Branch__c = branchLocation.Id,
RecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('Reservation Order').getRecordTypeId()
);
insert order;
*/
        Product2 prod2 = new Product2();
        prod2.Name = 'Test Product 2';
        prod2.Product_Type__c = 'Cat-Class';
        prod2.Product_SKU__c = '123877';
        prod2.Category__c = '32234';
        prod2.Class__c = '2049';
        prod2.ToolFlex__c = 'N';
        insert prod2;
        
        List<PricebookEntry> pbEntry = new List<PricebookEntry>();
        PricebookEntry stdPbe = new PricebookEntry();
        stdPbe.Product2Id = prod2.Id;
        stdPbe.Pricebook2Id = Test.getStandardPricebookId();
        stdPbe.IsActive = true;
        stdPbe.UnitPrice = 1020;
        stdPbe.CurrencyIsoCode = 'USD';
        pbEntry.add(stdPbe);
        insert pbEntry;
        
        OrderItem ordItem = new OrderItem(
            OrderId = order.Id,
            Product2Id = prod2.Id,
            Quantity = 5,
            UnitPrice = 100,
            PricebookEntryId = pbEntry[0].Id
        );
        
        insert ordItem;
        
        Map<String, Object> newFieldValue = new Map<String, Object>();
        newFieldValue.put('Product2Id', prod2.Id);
        
        Conversion_Log__c cLog = new Conversion_Log__c();
        cLog.Error_Message__c = 'tes';
        cLog.New_Value__c='new';
        clog.Old_Value__c='old';
        clog.Type__c='type';
        insert cLog;
        
        String whereClause = 'Product2Id = \'' + prod2.Id + '\'';
        
        Test.startTest();
        
        Id batchJobId = Database.executeBatch(new SBR_3_0_BatchSObjectCloneAndDelete('OrderItem', newFieldValue, 
                                                                                     whereClause, ' Product2Id DESC', cLog,pbEntry, new List<String>{'SBR_3_0_OrderItemTriggerHandler'}), 20);
        
        Test.stopTest();
    }
}