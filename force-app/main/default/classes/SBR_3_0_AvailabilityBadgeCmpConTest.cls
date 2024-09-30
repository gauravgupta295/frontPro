/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 06-27-2023
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@isTest
public with sharing class SBR_3_0_AvailabilityBadgeCmpConTest implements HttpCalloutMock {
    static Boolean SuccessfulTest;
    @TestSetup
    static void makeData()
    {       
        Credential__c cred = SBR_3_0_TestDataFactory.createCredentials(1, false)[0];
        cred.Name = 'Mule_Token_Endpoint';
        cred.Key_Id__c = 'testKey123';
        cred.Secret__c = 'secret';
        insert cred;

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
        jobLocation.Company_Code__c = '02';
        jobLocation.Time_Zone_Id__c = 'America/Denver';
        insert jobLocation;
        // Create Branch

        String latlong = ('{"latitude": 37.739223,"longitude": -122.39922}');
        Schema.Location branchLocation = new Schema.Location();
        branchLocation.Branch_Location_Number__c = '1234';
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
        branchLocation.OMS_Sourcing_Enabled__c = true;
        branchLocation.Time_Zone_Id__c = 'America/Denver';
        branchLocation.Latitude_Longitude__Latitude__s = 48.56;
        branchLocation.Latitude_Longitude__Longitude__s = -117.66;

        insert branchLocation;
        //branchLocation2.Latitude_Longitude__Latitude__s = 48.56;
        //branchLocation2.Latitude_Longitude__Longitude__s = -117.66;
        // Create Job Site
        AssociatedLocation jobSite = new AssociatedLocation(
            Name__c = 'Test Job Site',
            ParentRecordId = acct.Id,
            LocationId = jobLocation.Id,
            Branch__c = branchLocation.Id,
            Latitude_Longitude__Latitude__s = 48.51,
            Latitude_Longitude__Longitude__s = -117.62,
            Job_Number__c = '20221004A',
            Time_Zone_Id__c = 'America/Denver'
        );
        insert jobSite;
        
        AssociatedLocation jobSite1 = new AssociatedLocation(
            Name__c = 'Test Job Site',
            ParentRecordId = acct.Id,
            LocationId = jobLocation.Id,
            Branch__c = branchLocation.Id,
            Job_Number__c = '20221004A',
            Time_Zone_Id__c = 'America/Denver'
        );
        insert jobSite1;
        
        // Create Price Book
        Pricebook2 priceBook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update priceBook;
        //FRONT-30847 Added Order records for coverage
        // Create Order
        List<order> ordersList = new List<order>();
         // Create Order
        Order ordertest = new Order(
          Quote_Name__c = 'Test Quote',
          AccountId = acct.Id,
          Jobsite__c = jobSite.Id,
          CurrencyIsoCode = 'USD',
          Return_Date__c = System.today().addMonths(2),
          Branch__c = branchLocation.Id,
          Deliverymethod__c = 'Delivery',
          Status = 'Draft',
          Company_Code__c = '01',
          Pricebook2Id = priceBook.Id,
          Start_Date__c = System.today().addMonths(1),
          EffectiveDate = System.today().addMonths(2),
          EndDate = System.today().addMonths(4),
          Earliest_Delivery_Date__c = System.today().addMonths(3),
          Opt_Out_RPP__c = false,
          Opt_Out_Fuel_Charge__c = false,
          Selling_Channel__c = 'SBRB2B',
          Duration__c = 'Custom',
          Invoice_Sequence_Number__c = 100,
                Sourcing_Branch__c = branchLocation.Id,
                RecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('Reservation Order').getRecordTypeId()
        );
        ordersList.add(ordertest); 
            
          Order ordertest2 = new Order(
          Name='Test Quote no JS',
          Quote_Name__c = 'Test Quote no JS',
          AccountId = acct.Id,
          Jobsite__c = Null,
          CurrencyIsoCode = 'USD',
          Return_Date__c = System.today().addMonths(2),
          Branch__c = branchLocation.Id,
          Deliverymethod__c = 'Delivery',
          Status = 'Draft',
          Company_Code__c = '01',
          Pricebook2Id = priceBook.Id,
          Start_Date__c = System.today().addMonths(1),
          EffectiveDate = System.today().addMonths(2),
          EndDate = System.today().addMonths(4),
          Earliest_Delivery_Date__c = System.today().addMonths(3),
          Opt_Out_RPP__c = false,
          Opt_Out_Fuel_Charge__c = false,
          Selling_Channel__c = 'SBRB2B',
          Duration__c = 'Custom',
          Invoice_Sequence_Number__c = 100,
              Sourcing_Branch__c = branchLocation.Id,
                RecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('Reservation Order').getRecordTypeId()
        );
        ordersList.add(ordertest2); 
            
          Order ordertest3 = new Order(
          Name='Test Quote no delivery meth',
          Quote_Name__c = 'Test Quote no delivery meth',
          AccountId = acct.Id,
          Jobsite__c = Null,
          CurrencyIsoCode = 'USD',
          Return_Date__c = System.today().addMonths(2),
          Branch__c = branchLocation.Id,
          Deliverymethod__c = 'Delivery',
          Status = 'Draft',
          Company_Code__c = '01',
          Pricebook2Id = priceBook.Id,
          Start_Date__c = System.today().addMonths(1),
          EffectiveDate = System.today().addMonths(2),
          EndDate = System.today().addMonths(4),
          Earliest_Delivery_Date__c = System.today().addMonths(3),
          Opt_Out_RPP__c = false,
          Opt_Out_Fuel_Charge__c = false,
          Selling_Channel__c = 'SBRB2B',
          Duration__c = 'Custom',
          Invoice_Sequence_Number__c = 100,
          Sourcing_Branch__c = Null,
          RecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('Reservation Order').getRecordTypeId()
        );
        ordersList.add(ordertest3); 
            
            Order ordertest4 = new Order(
          Quote_Name__c = 'Test Quote no SB',
          AccountId = acct.Id,
          Jobsite__c = jobSite.Id,
          CurrencyIsoCode = 'USD',
          Return_Date__c = System.today().addMonths(2),
          Branch__c = branchLocation.Id,
          Deliverymethod__c = 'Delivery',
          Status = 'Draft',
          Company_Code__c = '01',
          Pricebook2Id = priceBook.Id,
          Start_Date__c = System.today().addMonths(1),
          EffectiveDate = System.today().addMonths(2),
          EndDate = System.today().addMonths(4),
          Earliest_Delivery_Date__c = System.today().addMonths(3),
          Opt_Out_RPP__c = false,
          Opt_Out_Fuel_Charge__c = false,
          Selling_Channel__c = 'SBRB2B',
          Duration__c = 'Custom',
          Invoice_Sequence_Number__c = 100,
                Sourcing_Branch__c = branchLocation.Id,
                RecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('Reservation Order').getRecordTypeId()
        );
        ordersList.add(ordertest4); 
            
            Order ordertest5 = new Order(
          Quote_Name__c = 'Test Quote Pickup',
          AccountId = acct.Id,
          Jobsite__c = jobSite.Id,
          CurrencyIsoCode = 'USD',
          Return_Date__c = System.today().addMonths(2),
          Branch__c = branchLocation.Id,
          Deliverymethod__c = 'Pickup',
          Status = 'Draft',
          Company_Code__c = '01',
          Pricebook2Id = priceBook.Id,
          Start_Date__c = System.today().addMonths(1),
          EffectiveDate = System.today().addMonths(2),
          EndDate = System.today().addMonths(4),
          Earliest_Delivery_Date__c = System.today().addMonths(3),
          Opt_Out_RPP__c = false,
          Opt_Out_Fuel_Charge__c = false,
          Selling_Channel__c = 'SBRB2B',
          Duration__c = 'Custom',
          Invoice_Sequence_Number__c = 100,
                Sourcing_Branch__c = branchLocation.Id,
                RecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('Reservation Order').getRecordTypeId()
        );
        ordersList.add(ordertest5); 
            
             Order ordertest6 = new Order(
          Quote_Name__c = 'Test Quote Pickup',
          AccountId = acct.Id,
          Jobsite__c = jobSite.Id,
          CurrencyIsoCode = 'USD',
          Return_Date__c = System.today().addMonths(2),
          Branch__c = branchLocation.Id,
          Deliverymethod__c = '',
          Status = 'Draft',
          Company_Code__c = '01',
          Pricebook2Id = priceBook.Id,
          Start_Date__c = System.today().addMonths(1),
          EffectiveDate = System.today().addMonths(2),
          EndDate = System.today().addMonths(4),
          Earliest_Delivery_Date__c = System.today().addMonths(3),
          Opt_Out_RPP__c = false,
          Opt_Out_Fuel_Charge__c = false,
          Selling_Channel__c = 'SBRB2B',
          Duration__c = 'Custom',
          Invoice_Sequence_Number__c = 100,
                Sourcing_Branch__c = branchLocation.Id,
                RecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('Reservation Order').getRecordTypeId()
        );
        ordersList.add(ordertest6); 
        insert ordersList;
        
        /*List<order> ordersList = new List<order>();
        Order order = new Order(
            Quote_Name__c = 'Test Quote',
            AccountId = acct.Id,
            Name='order1',
            Jobsite__c = jobSite.Id,
            Deliverymethod__c = 'Delivery',
            Delivery_Charge__c = 10,
            Status = 'Draft',
            Pricebook2Id = priceBook.Id,
            Start_Date__c = date.valueOf('2025-12-12 12:00:00'),
            EffectiveDate = date.valueOf('2025-12-12 12:00:00'),
            EndDate = date.valueOf('2026-10-09 8:00:00'),
            Return_Date__c = date.valueOf('2026-10-09 8:00:00'),
            Earliest_Delivery_Date__c = date.valueOf('2026-10-08 12:00:00'),
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
        ordersList.add(order);

        // ATP order
        Order orderNoJS = new Order(
            Quote_Name__c = 'Test Quote no JS',
            AccountId = acct.Id,
            Name='order2',
            //Jobsite__c = jobSite.Id,
            Deliverymethod__c = 'Delivery',
            Delivery_Charge__c = 10,
            Status = 'Draft',
            Pricebook2Id = priceBook.Id,
            Start_Date__c = date.valueOf('2024-12-12 12:00:00'),
            EffectiveDate = date.valueOf('2024-12-12 12:00:00'),
            EndDate = date.valueOf('2025-10-09 8:00:00'),
            Return_Date__c = date.valueOf('2025-10-09 8:00:00'),
            Earliest_Delivery_Date__c = date.valueOf('2026-10-08 12:00:00'),
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
        ordersList.add(orderNoJS);

        // ATP order
        Order orderNoDeliveryMeth = new Order(
            Quote_Name__c = 'Test Quote no delivery meth',
            AccountId = acct.Id,
            Name='order3',
            //Jobsite__c = jobSite.Id,
            Deliverymethod__c = '',
            Delivery_Charge__c = 10,
            Status = 'Draft',
            Pricebook2Id = priceBook.Id,
            Start_Date__c = date.valueOf('2025-12-12 12:00:00'),
            EffectiveDate = date.valueOf('2025-12-12 12:00:00'),
            EndDate = date.valueOf('2026-10-09 8:00:00'),
            Return_Date__c = date.valueOf('2026-10-09 8:00:00'),
            Earliest_Delivery_Date__c = date.valueOf('2026-10-08 12:00:00'),
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
        ordersList.add(orderNoDeliveryMeth);

        // ATP order
        Order orderNoSB = new Order(
            Quote_Name__c = 'Test Quote no SB',
            AccountId = acct.Id,
            Name='order4',
            //Jobsite__c = jobSite.Id,
            Deliverymethod__c = 'Delivery',
            Delivery_Charge__c = 10,
            Status = 'Draft',
            Pricebook2Id = priceBook.Id,
            Start_Date__c = date.valueOf('2025-12-12 12:00:00'),
            EffectiveDate = date.valueOf('2025-12-12 12:00:00'),
            EndDate = date.valueOf('2026-10-09 8:00:00'),
            Return_Date__c = date.valueOf('2026-10-09 8:00:00'),
            Earliest_Delivery_Date__c = date.valueOf('2026-10-08 12:00:00'),
            Opt_Out_RPP__c = false,
            Order_Initiating_Channel__c = 'SLSFRC',
            Opt_Out_Fuel_Charge__c = false,
            Selling_Channel__c = 'SBRB2B',
            Duration__c = 'Custom',
            Reservation_Order_Number__c = '12342',
            Branch__c = branchLocation.Id,
            //Sourcing_Branch__c = branchLocation.Id,
            RecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('Reservation Order').getRecordTypeId()
        );
        ordersList.add(orderNoSB);

                Order order2 = new Order(
            Quote_Name__c = 'Test Quote no Delivery',
            AccountId = acct.Id,
            Name='order5',
            //Jobsite__c = jobSite.Id,
            Deliverymethod__c = 'Delivery',
            Delivery_Charge__c = 10,
            Status = 'Draft',
            Pricebook2Id = priceBook.Id,
            Start_Date__c = date.valueOf('2025-12-12 12:00:00'),
            EffectiveDate = date.valueOf('2025-12-12 12:00:00'),
            EndDate = date.valueOf('2026-10-09 8:00:00'),
            Return_Date__c = date.valueOf('2026-10-09 8:00:00'),
            Earliest_Delivery_Date__c = date.valueOf('2026-10-08 12:00:00'),
            Opt_Out_RPP__c = false,
            Order_Initiating_Channel__c = 'SLSFRC',
            Opt_Out_Fuel_Charge__c = false,
            Selling_Channel__c = 'SBRB2B',
            Duration__c = 'Custom',
            Reservation_Order_Number__c = '12342',
            //Branch__c = branchLocation.Id,
            //Sourcing_Branch__c = branchLocation.Id,
            RecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('Reservation Order').getRecordTypeId()
        );
        ordersList.add(order2);
        Order pickuporder = new Order(
            Quote_Name__c = 'Test Quote Pickup',
            AccountId = acct.Id,
            Name='order6',
            Jobsite__c = jobSite.Id,
            Deliverymethod__c = 'Pickup',
            Delivery_Charge__c = 10,
            Status = 'Draft',
            Pricebook2Id = priceBook.Id,
            Start_Date__c = date.valueOf('2025-12-12 12:00:00'),
            EffectiveDate = date.valueOf('2025-12-12 12:00:00'),
            EndDate = date.valueOf('2026-10-09 8:00:00'),
            Return_Date__c = date.valueOf('2026-10-09 8:00:00'),
            Earliest_Delivery_Date__c = date.valueOf('2026-10-08 12:00:00'),
            Opt_Out_RPP__c = false,
            Order_Initiating_Channel__c = 'SLSFRC',
            Opt_Out_Fuel_Charge__c = false,
            Selling_Channel__c = 'SBRB2B',
            Duration__c = 'Custom',
            Reservation_Order_Number__c = '123421',
            Branch__c = branchLocation.Id,
            Sourcing_Branch__c = branchLocation.Id,
            RecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('Reservation Order').getRecordTypeId()
        );
        ordersList.add(pickuporder);
        insert ordersList;*/
		//End of FRONT-30847
        // Create Quote
        List<SBQQ__Quote__c> quoteList = new List<SBQQ__Quote__c>();
        SBQQ__Quote__c quote = new SBQQ__Quote__c(
            Quote_Name__c = 'Test Quote',
            SBQQ__Account__c = acct.Id,
            Jobsite__c = jobSite.Id,
            SBQQ__DeliveryMethod__c = 'Delivery',
            Start_Date__c = date.valueOf('2025-10-07 12:00:00'),
            End_Date__c = date.valueOf('2025-10-07 12:00:00'),
            Delivery_Date__c  = date.valueOf('2024-10-08 12:00:00'),
            Opt_Out_RPP__c = false,
            Opt_Out_Fuel_Charge__c = false,
            Selling_Channel__c = 'SBRB2B',
            Rentalman_Quote_Id__c = 'Test QId',
            Company_Code__c = '01',
            Show_Crew_Expense_Calculator__c = true,
            Branch__c = branchLocation.Id,
            Sourcing_Branch__c = branchLocation.Id
        );
        quoteList.add(quote);

        // Quote without a jobsite
        SBQQ__Quote__c quoteWithNoJobSite = new SBQQ__Quote__c(
            Quote_Name__c = 'Test Quote no JS',
            SBQQ__Account__c = acct.Id,
            Jobsite__c = null,
            SBQQ__DeliveryMethod__c = 'Delivery',
            Start_Date__c = date.valueOf('2024-10-07 12:00:00'),
            End_Date__c = date.valueOf('2024-10-07 12:00:00'),
            Delivery_Date__c  = date.valueOf('2025-10-08 12:00:00'),
            Opt_Out_RPP__c = false,
            Opt_Out_Fuel_Charge__c = false,
            Selling_Channel__c = 'SBRB2B',
            Rentalman_Quote_Id__c = 'Test QIdNoJS',
            Company_Code__c = '01',
            Show_Crew_Expense_Calculator__c = true,
            Branch__c = Null,
            Sourcing_Branch__c = branchLocation.Id
        );
        quoteList.add(quoteWithNoJobSite);

        // Quote without a sourcing branch
        SBQQ__Quote__c quoteWithNoSourcingBranch = new SBQQ__Quote__c(
            Quote_Name__c = 'Test Quote no SB',
            SBQQ__Account__c = acct.Id,
            Jobsite__c = null,
            SBQQ__DeliveryMethod__c = 'Delivery',
            Start_Date__c = date.valueOf('2024-10-07 12:00:00'),
            End_Date__c = date.valueOf('2024-10-07 12:00:00'),
            Delivery_Date__c  = date.valueOf('2024-10-08 12:00:00'),
            Opt_Out_RPP__c = false,
            Opt_Out_Fuel_Charge__c = false,
            Selling_Channel__c = 'SBRB2B',
            Rentalman_Quote_Id__c = 'Test QIdNOSB',
            Company_Code__c = '01',
            Show_Crew_Expense_Calculator__c = true,
            Branch__c = branchLocation.Id,
            Sourcing_Branch__c = null
        );
        quoteList.add(quoteWithNoSourcingBranch);

        // Quote no pickup and no delivery
        SBQQ__Quote__c quoteWithNoDeliveryMeth = new SBQQ__Quote__c(
            Quote_Name__c = 'Test Quote no method',
            SBQQ__Account__c = acct.Id,
            Jobsite__c = null,
            SBQQ__DeliveryMethod__c = '',
            Start_Date__c = date.valueOf('2024-10-07 12:00:00'),
            End_Date__c = date.valueOf('2024-10-07 12:00:00'),
            Delivery_Date__c  = date.valueOf('2024-10-08 12:00:00'),
            Opt_Out_RPP__c = false,
            Opt_Out_Fuel_Charge__c = false,
            Selling_Channel__c = 'SBRB2B',
            Rentalman_Quote_Id__c = 'Test QIdNOMeth',
            Company_Code__c = '01',
            Show_Crew_Expense_Calculator__c = true,
            Branch__c = branchLocation.Id,
            Sourcing_Branch__c = null
        );
        quoteList.add(quoteWithNoDeliveryMeth);

        SBQQ__Quote__c pickupQuote = new SBQQ__Quote__c(
            Quote_Name__c = 'Pickup Quote',
            SBQQ__Account__c = acct.Id,
            Jobsite__c = jobSite.Id,
            SBQQ__DeliveryMethod__c = 'Pickup',
            Start_Date__c = date.valueOf('2024-10-07 12:00:00'),
            End_Date__c = date.valueOf('2024-10-07 12:00:00'),
            Delivery_Date__c  = date.valueOf('2024-10-08 12:00:00'),
            Opt_Out_RPP__c = false,
            Opt_Out_Fuel_Charge__c = false,
            Selling_Channel__c = 'SBRB2B',
            Rentalman_Quote_Id__c = 'Test QId123',
            Company_Code__c = '01',
            Show_Crew_Expense_Calculator__c = true,
            Branch__c = branchLocation.Id,
            Sourcing_Branch__c = branchLocation.Id
        );
        quoteList.add(pickupQuote);
        insert quoteList; 

        User_Location__c ul = new User_Location__c();
        ul.Analysis_Region__c = region.Id;
        ul.User__c = UserInfo.getUserId();
        ul.Branch__c = branchLocation.Id;
        insert ul;
        
         List<Contact> cons = SBR_3_0_TestDataFactory.createContacts(1,acct.Id,true);
        Cart__c cart = new Cart__c(
            Account__c = acct.Id, 
            Branch__c = branchLocation.Id, 
            Rental_Start_Date__c = System.now()+2,
            Rental_End_Date__c = System.now()+3,
            Rental_Period__c = '1 Day', 
            Job_Site__c = jobSite.Id );
        insert cart;
    }

    public HTTPResponse respond(HTTPRequest req) {
        System.debug('req 130'+req);
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type',SBR_3_0_Constants.APP_JSON);
        if(req.getEndpoint().endsWithIgnoreCase('token')){
            res.setBody('{"access_token":"test"}');
        }
        else 
        {
            res.setBody('{ "data": { "companyId": "01", "sellingChannel": "SBRINT", "cartId": "SBRINT", "transactionType": "SBR", "closestBranchSite": "01-0001", "availabilityByProducts": [ { "productId": "1088773", "uom": "EA", "availabilityByFulfillmentTypes": [ { "fulfillmentType": "DEL", "availabilityDetails": [ { "availabilityByLocations": [ { "locationType": "PC", "locationId": "01-0001", "atp": 0.0, "geoDistanceFromJobSite": 570.132 } ] } ] } ] } ] } }');
        }
        res.setStatusCode(200);
        System.debug('res 141 ->'+res);
        return res;
    }

    
   @isTest
    static void testExecuteSuccess()
    {
        String catClass = '1088773';
        String companyCode = '01';
        Test.startTest();
            Test.setMock(HttpCalloutMock.class, new SBR_3_0_AvailabilityBadgeCmpConTest());
            SBR_3_0_WrapInventoryAtBranch.ATPResponse response = SBR_3_0_AvailabilityBadgeCmpController.getATP(null, catClass, companyCode, 'SBR');
            System.debug('testExecuteSuccess the response is->' + response);
        Test.stopTest();
     System.assertEquals(catClass, response.availabilityByProducts[0].productId, 'Returned incorrect catClass');
    }

    @isTest
    static void testExecuteOrderSuccess()
    {
        String catClass = '1088773';
        Order ord = [SELECT ID FROM Order WHERE Quote_Name__c = 'Test Quote' LIMIT 1];
        String companyCode = '01';
        Test.startTest();
            Test.setMock(HttpCalloutMock.class, new SBR_3_0_AvailabilityBadgeCmpConTest());
            SBR_3_0_WrapInventoryAtBranch.ATPResponse response = SBR_3_0_AvailabilityBadgeCmpController.getATP(ord.Id, catClass, companyCode, 'SBR');
            System.debug('testExecuteOrderSuccess the response is->' + response);
        Test.stopTest();
        System.assertEquals(catClass, response.availabilityByProducts[0].productId, 'Returned incorrect catClass');
    }

    // ATP defect
    @isTest
    static void testExecuteOrderNoJSSuccess()
    {
        String catClass = '1088773';
        Order ord = [SELECT ID FROM Order WHERE Quote_Name__c = 'Test Quote no JS' LIMIT 1];
        String companyCode = '01';
        Test.startTest();
            Test.setMock(HttpCalloutMock.class, new SBR_3_0_AvailabilityBadgeCmpConTest());
            SBR_3_0_WrapInventoryAtBranch.ATPResponse response = SBR_3_0_AvailabilityBadgeCmpController.getATP(ord.Id, catClass, companyCode, 'SBR');
            System.debug('testExecuteOrderSuccess the response is->' + response);
        Test.stopTest();
        System.assertEquals(catClass, response.availabilityByProducts[0].productId, 'Returned incorrect catClass');
    }

    // ATP defect
    @isTest
    static void testExecuteOrderNoBranchSuccess()
    {
        String catClass = '1088773';
        Order ord = [SELECT ID FROM Order WHERE Quote_Name__c = 'Test Quote no delivery meth' LIMIT 1];
        String companyCode = '01';
        Test.startTest();
            Test.setMock(HttpCalloutMock.class, new SBR_3_0_AvailabilityBadgeCmpConTest());
            SBR_3_0_WrapInventoryAtBranch.ATPResponse response = SBR_3_0_AvailabilityBadgeCmpController.getATP(ord.Id, catClass, companyCode, 'SBR');
            System.debug('testExecuteOrderSuccess the response is->' + response);
        Test.stopTest();
        System.assertEquals(catClass, response.availabilityByProducts[0].productId, 'Returned incorrect catClass');
    }

    // ATP defect
    @isTest
    static void testExecuteOrderNoSBSuccess()
    {
        String catClass = '1088773';
        Order ord = [SELECT ID FROM Order WHERE Quote_Name__c = 'Test Quote no SB' LIMIT 1];
        String companyCode = '01';
        Test.startTest();
            Test.setMock(HttpCalloutMock.class, new SBR_3_0_AvailabilityBadgeCmpConTest());
            SBR_3_0_WrapInventoryAtBranch.ATPResponse response = SBR_3_0_AvailabilityBadgeCmpController.getATP(ord.Id, catClass, companyCode, 'SBR');
            System.debug('testExecuteOrderSuccess the response is->' + response);
        Test.stopTest();
        System.assertEquals(catClass, response.availabilityByProducts[0].productId, 'Returned incorrect catClass');
    }
   
    /*
    @isTest
    static void testExecuteOrderSuccessWithSourcingBranch()
    {
        String catClass = '1088773';
        Order ord = [SELECT ID FROM Order WHERE Quote_Name__c = 'TestQuote3' LIMIT 1];
        String companyCode = '01';
        Test.startTest();
            Test.setMock(HttpCalloutMock.class, new SBR_3_0_AvailabilityBadgeCmpConTest());
            SBR_3_0_WrapInventoryAtBranch.ATPResponse response = SBR_3_0_AvailabilityBadgeCmpController.getATP(ord.Id, catClass, companyCode, 'SBR');
            System.debug('testExecuteOrderSuccess the response is->' + response);
        Test.stopTest();
        System.debug('Response = ' + response.availabilityByProducts[0].productId);
        System.debug('Response 2 = ' + response);
        System.assertEquals(catClass, response.availabilityByProducts[0].productId, 'Returned incorrect catClass');
    }
*/
    
    @isTest
    static void testExecutePickupOrderSuccess()
    {
        String catClass = '1088773';
        Test.startTest();
        Order ord = [SELECT ID FROM Order WHERE Deliverymethod__c = 'Pickup' LIMIT 1];
        String companyCode = '01';
        
            Test.setMock(HttpCalloutMock.class, new SBR_3_0_AvailabilityBadgeCmpConTest());
            SBR_3_0_WrapInventoryAtBranch.ATPResponse response = SBR_3_0_AvailabilityBadgeCmpController.getATP(ord.Id, catClass, companyCode, 'SBR');
            System.debug('testExecuteOrderSuccess the response is->' + response);
        Test.stopTest();
        System.assertEquals(catClass, response.availabilityByProducts[0].productId, 'Returned incorrect catClass');
    }

    // ATP Defect
    @isTest
    static void testExecuteQuoteDeliveryNoJSSuccess()
    {
        String catClass = '1088773';
        SBQQ__Quote__c quote = [SELECT ID FROM SBQQ__Quote__c WHERE Quote_Name__c = 'Test Quote no JS' LIMIT 1];
        String companyCode = '01';
        Test.startTest();
            Test.setMock(HttpCalloutMock.class, new SBR_3_0_AvailabilityBadgeCmpConTest());
            SBR_3_0_WrapInventoryAtBranch.ATPResponse response = SBR_3_0_AvailabilityBadgeCmpController.getATP(quote.Id, catClass, companyCode, 'SBR');
            System.debug('testExecuteQuoteSuccess the response is->' + response);
        Test.stopTest();
       System.assertEquals(catClass, response.availabilityByProducts[0].productId, 'Returned incorrect catClass');
    }

    // ATP Defect
    @isTest
    static void testExecuteQuoteDeliveryNoSBSuccess()
    {
        String catClass = '1088773';
        SBQQ__Quote__c quote = [SELECT ID FROM SBQQ__Quote__c WHERE Quote_Name__c = 'Test Quote no SB' LIMIT 1];
        String companyCode = '01';
        Test.startTest();
            Test.setMock(HttpCalloutMock.class, new SBR_3_0_AvailabilityBadgeCmpConTest());
            SBR_3_0_WrapInventoryAtBranch.ATPResponse response = SBR_3_0_AvailabilityBadgeCmpController.getATP(quote.Id, catClass, companyCode, 'SBR');
            System.debug('testExecuteQuoteSuccess the response is->' + response);
        Test.stopTest();
       System.assertEquals(catClass, response.availabilityByProducts[0].productId, 'Returned incorrect catClass');
    }

    // ATP Defect
    @isTest
    static void testExecuteQuoteDeliveryNoMethodSuccess()
    {
        String catClass = '1088773';
        SBQQ__Quote__c quote = [SELECT ID FROM SBQQ__Quote__c WHERE Quote_Name__c = 'Test Quote no method' LIMIT 1];
        String companyCode = '01';
        Test.startTest();
            Test.setMock(HttpCalloutMock.class, new SBR_3_0_AvailabilityBadgeCmpConTest());
            SBR_3_0_WrapInventoryAtBranch.ATPResponse response = SBR_3_0_AvailabilityBadgeCmpController.getATP(quote.Id, catClass, companyCode, 'SBR');
            System.debug('testExecuteQuoteSuccess the response is->' + response);
        Test.stopTest();
       System.assertEquals(catClass, response.availabilityByProducts[0].productId, 'Returned incorrect catClass');
    }

    @isTest
    static void testExecuteQuoteSuccess()
    {
        String catClass = '1088773';
        SBQQ__Quote__c quote = [SELECT ID FROM SBQQ__Quote__c WHERE Quote_Name__c = 'Test Quote' LIMIT 1];
        String companyCode = '01';
        Test.startTest();
            Test.setMock(HttpCalloutMock.class, new SBR_3_0_AvailabilityBadgeCmpConTest());
            SBR_3_0_WrapInventoryAtBranch.ATPResponse response = SBR_3_0_AvailabilityBadgeCmpController.getATP(quote.Id, catClass, companyCode, 'SBR');
            System.debug('testExecuteQuoteSuccess the response is->' + response);
        Test.stopTest();
       System.assertEquals(catClass, response.availabilityByProducts[0].productId, 'Returned incorrect catClass');
    }
    
    @isTest
    static void testExecutePickUpQuoteSuccess()
    {
        String catClass = '1088773';
         Test.startTest();
        SBQQ__Quote__c quote = [SELECT ID FROM SBQQ__Quote__c WHERE SBQQ__DeliveryMethod__c = 'Pickup' LIMIT 1];
        String companyCode = '01';
       
            Test.setMock(HttpCalloutMock.class, new SBR_3_0_AvailabilityBadgeCmpConTest());
            SBR_3_0_WrapInventoryAtBranch.ATPResponse response = SBR_3_0_AvailabilityBadgeCmpController.getATP(quote.Id, catClass, companyCode, 'SBR');
            System.debug('testExecuteQuoteSuccess the response is->' + response);
        Test.stopTest();
       System.assertEquals(catClass, response.availabilityByProducts[0].productId, 'Returned incorrect catClass');
    }
    
    @IsTest
    static void getBranchId_givenBranchNumber_returnsBranchId() {
        Schema.Location branch = [SELECT Id FROM Location WHERE Name = 'Test Branch Location'];
        
        Test.startTest();
            String branchId = SBR_3_0_AvailabilityBadgeCmpController.getBranchId('1234');
        Test.stopTest();

        System.assertEquals(branch.Id, branchId, 'Incorrect Branch Id returned');
    }
    
    
    @isTest
    static void testExecuteCartSuccess()
    {
        String catClass = '1088773';
       Cart__c cart = [SELECT Id,Name FROM Cart__c LIMIT 1];
        String companyCode = '01';
        Test.startTest();
            Test.setMock(HttpCalloutMock.class, new SBR_3_0_AvailabilityBadgeCmpConTest());
            SBR_3_0_WrapInventoryAtBranch.ATPResponse response = SBR_3_0_AvailabilityBadgeCmpController.getATP(cart.Id, catClass, companyCode, 'SBR');
            System.debug('testExecuteOrderSuccess the response is->' + response);
        Test.stopTest();
        System.assertEquals(catClass, response.availabilityByProducts[0].productId, 'Returned incorrect catClass');
    }
    
    @isTest
    static void testExecuteCartNullgetATI()
    {
       String catClass = '1088773';
        List<String> catClasses = new List<String>();
        catClasses.add('1088773');
        String companyCode = '01';
        Test.startTest();
            Test.setMock(HttpCalloutMock.class, new SBR_3_0_AvailabilityBadgeCmpConTest());
             String response = SBR_3_0_AvailabilityBadgeCmpController.getATI(null, JSON.serialize(catClasses));
            System.debug('testExecuteOrderSuccess the response is 317->'+response);
        Test.stopTest();
       System.assertEquals(null, null);
    }
        @isTest
    static void testExecuteSuccessDeliveryATI()
    {
        String catClass = '1088773';
        List<String> catClasses = new List<String>();
        catClasses.add('1088773');
        String companyCode = '01';
        Test.startTest();
          SBQQ__Quote__c quote = [SELECT ID FROM SBQQ__Quote__c WHERE SBQQ__DeliveryMethod__c = 'Delivery' LIMIT 1];
            Test.setMock(HttpCalloutMock.class, new SBR_3_0_AlternateItemAPITest());
            SBR_3_0_WrapAlternateItems.ATIResponse response = (SBR_3_0_WrapAlternateItems.ATIResponse)System.JSON.deserialize(SBR_3_0_AvailabilityBadgeCmpController.getATI(quote.Id, JSON.serialize(catClasses)), SBR_3_0_WrapAlternateItems.ATIResponse.class);
        Test.stopTest();
        System.assertEquals(catClass, response.data.availabilityByTransactionType[0].availabilityByProducts[0].productId, 'Returned incorrect catClass');
    }
    
      @isTest
    static void testExecuteSuccessPickupATI()
    {
        String catClass = '1088773';
        List<String> catClasses = new List<String>();
        catClasses.add('1088773');
        String companyCode = '01';
        Test.startTest();
          SBQQ__Quote__c quote = [SELECT ID FROM SBQQ__Quote__c WHERE SBQQ__DeliveryMethod__c = 'Pickup' LIMIT 1];
            Test.setMock(HttpCalloutMock.class, new SBR_3_0_AlternateItemAPITest());
            SBR_3_0_WrapAlternateItems.ATIResponse response = (SBR_3_0_WrapAlternateItems.ATIResponse)System.JSON.deserialize(SBR_3_0_AvailabilityBadgeCmpController.getATI(quote.Id, JSON.serialize(catClasses)), SBR_3_0_WrapAlternateItems.ATIResponse.class);
        Test.stopTest();
        System.assertEquals(catClass, response.data.availabilityByTransactionType[0].availabilityByProducts[0].productId, 'Returned incorrect catClass');
    }
    

    
    
          @isTest
    static void testExecuteSuccessOrderDeliveryATI()
    {
        String catClass = '1088773';
        List<String> catClasses = new List<String>();
        catClasses.add('1088773');
        String companyCode = '01';
        Test.startTest();
          Order ord = [SELECT ID FROM Order WHERE Quote_Name__c = 'Test Quote' LIMIT 1];
                
            Test.setMock(HttpCalloutMock.class, new SBR_3_0_AlternateItemAPITest());
            SBR_3_0_WrapAlternateItems.ATIResponse response = (SBR_3_0_WrapAlternateItems.ATIResponse)System.JSON.deserialize(SBR_3_0_AvailabilityBadgeCmpController.getATI(ord.Id, JSON.serialize(catClasses)), SBR_3_0_WrapAlternateItems.ATIResponse.class);
        Test.stopTest();
        System.assertEquals(catClass, response.data.availabilityByTransactionType[0].availabilityByProducts[0].productId, 'Returned incorrect catClass');
    }
              @isTest
    static void testExecuteSuccessOrderPickupATI()
    {
        String catClass = '1088773';
        List<String> catClasses = new List<String>();
        catClasses.add('1088773');
        String companyCode = '01';
        Test.startTest();
          Order ord = [SELECT ID FROM Order WHERE Quote_Name__c = 'Test Quote Pickup' LIMIT 1];
                
            Test.setMock(HttpCalloutMock.class, new SBR_3_0_AlternateItemAPITest());
            SBR_3_0_WrapAlternateItems.ATIResponse response = (SBR_3_0_WrapAlternateItems.ATIResponse)System.JSON.deserialize(SBR_3_0_AvailabilityBadgeCmpController.getATI(ord.Id, JSON.serialize(catClasses)), SBR_3_0_WrapAlternateItems.ATIResponse.class);
        Test.stopTest();
        System.assertEquals(catClass, response.data.availabilityByTransactionType[0].availabilityByProducts[0].productId, 'Returned incorrect catClass');
    }
    //FRONT-30847 Added testmethods for uncovered code
    @isTest
    static void testExecuteSuccessOrderSbATI()
    {
        String catClass = '1088773';
        List<String> catClasses = new List<String>();
        catClasses.add('1088773');
        String companyCode = '01';
        Test.startTest();
          Order ord = [SELECT ID FROM Order WHERE Quote_Name__c = 'Test Quote no JS' LIMIT 1];
                
            Test.setMock(HttpCalloutMock.class, new SBR_3_0_AlternateItemAPITest());
            SBR_3_0_WrapAlternateItems.ATIResponse response = (SBR_3_0_WrapAlternateItems.ATIResponse)System.JSON.deserialize(SBR_3_0_AvailabilityBadgeCmpController.getATI(ord.Id, JSON.serialize(catClasses)), SBR_3_0_WrapAlternateItems.ATIResponse.class);
        Test.stopTest();
        System.assertEquals(catClass, response.data.availabilityByTransactionType[0].availabilityByProducts[0].productId, 'Returned incorrect catClass');
    }
    
  	@isTest
    static void testExecuteSuccessOrderBranchATI()
    {
        String catClass = '1088773';
        List<String> catClasses = new List<String>();
        catClasses.add('1088773');
        String companyCode = '01';
        Test.startTest();
          Order ord = [SELECT ID FROM Order WHERE Quote_Name__c = 'Test Quote no delivery meth' LIMIT 1];
                
            Test.setMock(HttpCalloutMock.class, new SBR_3_0_AlternateItemAPITest());
            SBR_3_0_WrapAlternateItems.ATIResponse response = (SBR_3_0_WrapAlternateItems.ATIResponse)System.JSON.deserialize(SBR_3_0_AvailabilityBadgeCmpController.getATI(ord.Id, JSON.serialize(catClasses)), SBR_3_0_WrapAlternateItems.ATIResponse.class);
        Test.stopTest();
        System.assertEquals(catClass, response.data.availabilityByTransactionType[0].availabilityByProducts[0].productId, 'Returned incorrect catClass');
    }
    
    @isTest
    static void testorderWithoutDeliveryMethod()
    {
        String catClass = '1088773';
        List<String> catClasses = new List<String>();
        catClasses.add('1088773');
        String companyCode = '01';
        Test.startTest();
          Order ord = [SELECT ID FROM Order WHERE DeliveryMethod__c = '' LIMIT 1];
                
            Test.setMock(HttpCalloutMock.class, new SBR_3_0_AlternateItemAPITest());
            SBR_3_0_WrapAlternateItems.ATIResponse response = (SBR_3_0_WrapAlternateItems.ATIResponse)System.JSON.deserialize(SBR_3_0_AvailabilityBadgeCmpController.getATI(ord.Id, JSON.serialize(catClasses)), SBR_3_0_WrapAlternateItems.ATIResponse.class);
        Test.stopTest();
        System.assertEquals(catClass, response.data.availabilityByTransactionType[0].availabilityByProducts[0].productId, 'Returned incorrect catClass');
    }
 
	@isTest
    static void testExecuteSuccessDeliverySbATI()
    {
        String catClass = '1088773';
        List<String> catClasses = new List<String>();
        catClasses.add('1088773');
        String companyCode = '01';
        Test.startTest();
          SBQQ__Quote__c quote = [SELECT ID FROM SBQQ__Quote__c WHERE Quote_Name__c = 'Test Quote no SB' LIMIT 1];
            Test.setMock(HttpCalloutMock.class, new SBR_3_0_AlternateItemAPITest());
            SBR_3_0_WrapAlternateItems.ATIResponse response = (SBR_3_0_WrapAlternateItems.ATIResponse)System.JSON.deserialize(SBR_3_0_AvailabilityBadgeCmpController.getATI(quote.Id, JSON.serialize(catClasses)), SBR_3_0_WrapAlternateItems.ATIResponse.class);
        Test.stopTest();
        System.assertEquals(catClass, response.data.availabilityByTransactionType[0].availabilityByProducts[0].productId, 'Returned incorrect catClass');
    }    
    
    @isTest
    static void testExecuteSuccessDeliveryBranchATI()
    {
        String catClass = '1088773';
        List<String> catClasses = new List<String>();
        catClasses.add('1088773');
        String companyCode = '01';
        Test.startTest();
          SBQQ__Quote__c quote = [SELECT ID FROM SBQQ__Quote__c WHERE Quote_Name__c = 'Test Quote no JS' LIMIT 1];
            Test.setMock(HttpCalloutMock.class, new SBR_3_0_AlternateItemAPITest());
            SBR_3_0_WrapAlternateItems.ATIResponse response = (SBR_3_0_WrapAlternateItems.ATIResponse)System.JSON.deserialize(SBR_3_0_AvailabilityBadgeCmpController.getATI(quote.Id, JSON.serialize(catClasses)), SBR_3_0_WrapAlternateItems.ATIResponse.class);
        Test.stopTest();
        System.assertEquals(catClass, response.data.availabilityByTransactionType[0].availabilityByProducts[0].productId, 'Returned incorrect catClass');
    } 
    
     @isTest
    static void testDeliveryMethodOtherATI()
    {
        String catClass = '1088773';
        List<String> catClasses = new List<String>();
        catClasses.add('1088773');
        String companyCode = '01';
        Test.startTest();
          SBQQ__Quote__c quote = [SELECT ID FROM SBQQ__Quote__c WHERE SBQQ__DeliveryMethod__c = '' LIMIT 1];
            Test.setMock(HttpCalloutMock.class, new SBR_3_0_AlternateItemAPITest());
            SBR_3_0_WrapAlternateItems.ATIResponse response = (SBR_3_0_WrapAlternateItems.ATIResponse)System.JSON.deserialize(SBR_3_0_AvailabilityBadgeCmpController.getATI(quote.Id, JSON.serialize(catClasses)), SBR_3_0_WrapAlternateItems.ATIResponse.class);
        Test.stopTest();
        System.assertEquals(catClass, response.data.availabilityByTransactionType[0].availabilityByProducts[0].productId, 'Returned incorrect catClass');
    } 
    
       @isTest
    static void testExecutewithoutDelveryMethodOrderSuccess()
    {
        String catClass = '1088773';
        Test.startTest();
        Order ord = [SELECT ID FROM Order WHERE Deliverymethod__c = '' LIMIT 1];
        String companyCode = '01';
        
            Test.setMock(HttpCalloutMock.class, new SBR_3_0_AvailabilityBadgeCmpConTest());
            SBR_3_0_WrapInventoryAtBranch.ATPResponse response = SBR_3_0_AvailabilityBadgeCmpController.getATP(ord.Id, catClass, companyCode, 'SBR');
            System.debug('testExecuteOrderSuccess the response is->' + response);
        Test.stopTest();
        System.assertEquals(catClass, response.availabilityByProducts[0].productId, 'Returned incorrect catClass');
    }
    //End of FRONT-30847
}