@isTest
private class SBR_3_0_AvailabilityController_Test {
	
     @TestSetup
    static void makeData(){
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
        
        Product_Hierarchy__c prdHierachy = new Product_Hierarchy__c(Name = 'Test Hierarchy', 
        Product_Hierarchy_Code__c = 'Test_HR_Code', RecordTypeId = SBR_3_0_Constants.PRODUCT_HIERARCHY_PRODUCT_SUB_CATEGORY_RT_ID);
        insert prdHierachy;
        
        Id skuRecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('SKU').getRecordTypeId();
        
        // Create Product
        Product2 prod = new Product2(Name = 'Test Product 1', Product_Title_Internal__c = 'Test Product 1', Product_SKU__c = '1234567', Product_Type__c = 'Cat-Class',RecordTypeId=skuRecordTypeId,Product_Hierarchy__c = prdHierachy.Id,Status__c = 'A',Bulk_Item__c = false,Company_Code__c='01');
        Product2 prod2 = new Product2(Name = 'Test Product 2', Product_Title_Internal__c = 'Test Product 2', Product_SKU__c = '01-PIPSA-817633', Product_Type__c = 'Cat-Class',RecordTypeId=skuRecordTypeId,Product_Hierarchy__c = prdHierachy.Id,Status__c = 'A',Bulk_Item__c = false,Company_Code__c='01');
        Product2 prod3 = new Product2(Name = 'Test Product 3', Product_Title_Internal__c = 'Test Product 3', Product_SKU__c = '123003',Product_Type__c = 'Cat-Class',RecordTypeId=skuRecordTypeId,Product_Hierarchy__c = prdHierachy.Id,Status__c = 'A',Bulk_Item__c = false,Company_Code__c='01');
        insert prod;
        insert prod2;
        insert prod3;
        
        SBQQ__ProductFeature__c featureObj = new SBQQ__ProductFeature__c(
                Name = 'Rental Addons',
                Product_Feature_Load_Ext_ID__c = prod.Product_SKU__c + '_' + 'Rental Addons',
                SBQQ__ConfiguredSKU__c = prod.Id,
                SBQQ__MinOptionCount__c = 1,
                SBQQ__Number__c = 1
        );
		insert featureObj;
        
        SBQQ__ProductFeature__c salesObj = new SBQQ__ProductFeature__c(
            Name = 'Sales Addons',
            Product_Feature_Load_Ext_ID__c = prod.Product_SKU__c + '_' + 'Sales Addons',
            SBQQ__ConfiguredSKU__c = prod.Id,
            SBQQ__MinOptionCount__c = 1,
            SBQQ__Number__c = 1
        );
        insert salesObj;
        
        SBQQ__ProductOption__c prodOption = new SBQQ__ProductOption__c(
            SBQQ__ConfiguredSKU__c = prod.Id,
            SBQQ__OptionalSKU__c = prod2.Id,
            SBQQ__Number__c = 1,
            SBQQ__Feature__c = featureObj.Id,
            SBQQ__Required__c = true,
            Company_Code__c='01' ,
            SBQQ__Quantity__c = 1 
        );
        insert prodOption;
        
        SBQQ__ProductOption__c prodOption1 = new SBQQ__ProductOption__c(
            SBQQ__ConfiguredSKU__c = prod.Id,
            SBQQ__OptionalSKU__c = prod3.Id,
            SBQQ__Number__c = 1,
            SBQQ__Feature__c = salesObj.Id,
            SBQQ__Required__c = true,
            Company_Code__c='01' ,
            SBQQ__Quantity__c = 1 
        );
        insert prodOption1;
        
        //FRONT-30847- Start
        // Create Order
         List<order> ordersList = new List<order>();
         
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
        insert ordersList;
		*/
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
            Branch__c = branchLocation.Id,
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
    
   // Mocking HTTP callouts
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        private Integer statusCode;
        private Boolean noLastResortBranch;

        MockHttpResponseGenerator(Integer statusCode) {
            this.statusCode = statusCode;
        }
        
        MockHttpResponseGenerator(Integer statusCode,Boolean noLastResortBranch) {
            this.statusCode = statusCode;
            this.noLastResortBranch = noLastResortBranch;
        }

        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setStatusCode(statusCode);
            res.setHeader('Content-Type',SBR_3_0_Constants.APP_JSON);
            if(req.getEndpoint().endsWithIgnoreCase('token')){
                // Access Token Response
                res.setBody('{"access_token":"test"}');
        	}else if(req.getEndpoint().endsWithIgnoreCase('rates') && statusCode == 200){
            	// Rates Response here
            	res.setBody('{ "data": { "errorCode": "0000", "errorDesc": "Success", "company": "01", "customer": "4", "jobsite": "CO MEDIMMUNE BOULDER", "location": "0720", "items": [ { "catId": "123", "classId": "4567", "productId": "123003", "rateFlag": "B", "rateFlagDescription": "Book Rates", "notToExceed": "", "notToExceedDescription": "No override needed for any change.", "rppPercentage": ".000", "needPassword": "FALSE", "showAllRates": "FALSE", "suggestMinimalHours": ".00", "isConsumerCatClass": "FALSE", "isSerialized": "FALSE", "customerDiscountPercentageDaily": ".00", "customerDiscountPercentageWeekly": ".00", "customerDiscountPercentageMonthly": ".00", "customerMonthly": null, "rates": { "suggestedRates": { "minimum": "10", "daily": "10", "weekly": "70", "monthly": "300" }, "bookRates": { "minimum": ".00", "daily": ".00", "weekly": ".00", "monthly": ".00" } } } ] } }');
        	}else if(req.getEndpoint().endsWithIgnoreCase('atp/location') && statusCode == 200  && noLastResortBranch == true)
            {
                res.setBody('{"data":{"companyId":"01","sellingChannel":"SBRINT","cartId":"SBRINT","transactionType":"SBR","closestBranchSite":"01-0001","lastResortBranch":"","availabilityByProducts":[{"productId":"123003","uom":"EA","availabilityByFulfillmentTypes":[{"fulfillmentType":"DEL","availabilityDetails":[{"availabilityByLocations":[{"locationType":"PC","locationId":"01-0001","atp":0,"geoDistanceFromJobSite":570.132}]}]}]},{"productId":"0898789","uom":"EA","availabilityByFulfillmentTypes":[{"fulfillmentType":"DEL","availabilityDetails":[{"availabilityByLocations":[]}]}]}]}}');
            }else if(req.getEndpoint().endsWithIgnoreCase('alternate'))
        	{
            	res.setBody('{ "data": { "companyId": "01", "sellingChannel": "SBRB2B", "cartId": "5242f682-13de-4b77-a654-612a62ab782e", "availabilityByTransactionType": [ { "transactionType": "SBR", "availabilityByProducts": [ { "productId": "123003", "uom": "EA", "availabilityByFulfillmentTypes": [ { "fulfillmentType": "DEL", "availabilityDetails": [ { "availabilityByLocations": [ { "locationType": "PC", "locationId": "01-0001", "atp": 0, "geoDistanceFromJobSite": 569.837 } ] } ] } ] }, { "productId": "1428123", "uom": "EA", "availabilityByFulfillmentTypes": [ { "fulfillmentType": "DEL", "availabilityDetails": [ { "availabilityByLocations": [ { "locationType": "PC", "locationId": "01-0001", "atp": 0, "geoDistanceFromJobSite": 569.837 } ] } ] } ] } ] } ] } }');
        	}else if(req.getEndpoint().endsWithIgnoreCase('consumables')){
            // Consumables Response here
            res.setBody('{"data":{"suggestedItems":[{"catId":"20","classId":"615","rentables":[],"consumables":[{"inventoryClass":"206","invClassDescription":"PPE, RESPIRATORY","specGroups":[{"specNumber":"206-0002","title":"Disposable Respirator","specDescription":"Disposable Respirator","minPrice":6,"maxPrice":6,"products":[{"productNumber":"0898789","stockClass":"PIPSA","oemStockNumber":"10102481","productDescription":"N95 HARMFUL DUST RESPIRATOR 2 PACK","priceSchedule":"","sequence":"10","forceItem":"N","minQuantity":0,"sellingPrice":6,"availQuantity":25,"binNumber1":"SC3","binNumber2":"","binNumber3":"","rentalCat":"0","rentalClass":"0","isSerialized":false}]}]}]}]}}');
        }
            return res;
        }
    }
    
    @isTest static void testfindAlternateProductsByLocation(){
        
        Product2 product = [SELECT Id from Product2 where name = 'Test Product 1'];
            
        Test.startTest();
        	 Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200,true));
             String response = SBR_3_0_AvailabilityController.findAlternateProductsByLocation(null,product.Id,'01','0506',null);
        Test.stopTest();
        SYSTEM.debug('testfindAlternateProductsByLocation Response '+JSON.deserialize(response,Map<String,String>.class));
        Map<String,String> result = (Map<String,String>)JSON.deserialize(response,Map<String,String>.class);
        List<SBR_3_0_SpotlightPanelCmpController.AddOn_Details> formattedResponse = (List<SBR_3_0_SpotlightPanelCmpController.AddOn_Details>)JSON.deserialize(result.get('alternateProducts'),List<SBR_3_0_SpotlightPanelCmpController.AddOn_Details>.class);
        Assert.areEqual(2,formattedResponse.size(),'Received Rates for 2 Alternate Products');
    }
    
    
}