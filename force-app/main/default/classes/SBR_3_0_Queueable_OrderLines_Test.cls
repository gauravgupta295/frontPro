/**
 * @description       : Test class for SBR_3_0_Queueable_OrderLines.
 * @last modified on  : 02/18/2024
**/
@istest
public class SBR_3_0_Queueable_OrderLines_Test {
@testsetup
    public static void createData()
    {
        
        String PRODUCT_1_SKU = '123001';
        String PRODUCT_2_SKU = '123002';
        Account acct = new Account(
            RM_Account_Number__c = '12345',
            Name = SBR_3_0_API_Web_Jobsite_DA.JOBSITEACCOUNTNAME,
            BillingStreet = '123 Main Street',
            BillingCity = 'test',
            BillingPostalCode = '20173',
            BillingState = 'VA',
            BillingCountry = 'US',
            Company_Code__c = '01',
                Phone='3322114455'
        );
        insert acct;

        // Create Price Book
        Pricebook2 priceBook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
            );
        update priceBook;
    
        Product_Hierarchy__c prdHierachy = new Product_Hierarchy__c(
            Name = 'Test Hierarchy',
            Product_Hierarchy_Code__c = 'Test_HR_Code',
            RecordTypeId = SBR_3_0_Constants.PRODUCT_HIERARCHY_PRODUCT_SUB_CATEGORY_RT_ID
        );
        insert prdHierachy;
        List<Product2> products = new List<Product2>();
        Product2 product = new Product2(
            Name = 'Test Product 1',
            Product_Title_Internal__c = 'Test Product 1',
            Product_SKU__c = PRODUCT_1_SKU,
            Product_Hierarchy__c = prdHierachy.Id,
          
            Item_Number__c = '1',
            Status__c='A',
            Bulk_Item__c=false,
            IsSerialized=true,
            Company_Code__c='01',
            Product_Type__c=SBR_3_0_Constants.CAT_CLASS
        );
        products.add(product);
        

        Product2 product2 = new Product2(
            Name = 'Test Product 2',
            Product_Title_Internal__c = 'Test Product 2',
            Product_SKU__c = PRODUCT_2_SKU,
            Product_Hierarchy__c = prdHierachy.Id,
            
            Item_Number__c = '2',
            Product_Type__c=SBR_3_0_Constants.MERCHANDISE,
            Status__c='A',
            Bulk_Item__c=false,
            IsSerialized=true,
            Company_Code__c='01'
       
        );
        products.add(product2);
        insert products;

        SBR_3_0_TestDataFactory.createPriceBookEntries(products);

        PricebookEntry pbEntry = [SELECT Id FROM PricebookEntry WHERE Pricebook2Id = :Test.getStandardPricebookId() AND Product2Id = :product.Id LIMIT 1];
        PricebookEntry pbEntry2 = [SELECT Id FROM PricebookEntry WHERE Pricebook2Id = :Test.getStandardPricebookId() AND Product2Id = :product2.Id LIMIT 1];


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
            Duration__c = 'Custom',
            Distance_to_Job_Site__c = 90,
            Rates_To_Be_Used__c = 'Suggested',
            Branch__c = branchLocation.Id
        );
        insert quote;


        List<SBQQ__QuoteLine__c> qlines = new List<SBQQ__QuoteLine__c>();
        SBQQ__QuoteLine__c quoteLine = new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, 
            SBQQ__Product__c = product.Id, Hourly_Rate__c = 4, Min_Rate__c = 4, Daily_Rate__c = 4,
            Weekly_Rate__c = 4, Monthly_Rate__c = 4, SBQQ__Quantity__c=1,
            Selling_Price__c = 12);
        qlines.add(quoteLine);

        SBQQ__QuoteLine__c quoteLine2 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, 
            SBQQ__Product__c = product2.Id, Hourly_Rate__c = 4, Min_Rate__c = 4, Daily_Rate__c = 4,
            Weekly_Rate__c = 4, Monthly_Rate__c = 4, SBQQ__Quantity__c=1,
            Selling_Price__c = 12);
        qlines.add(quoteLine2);
        insert qlines;

        Order order = new Order(
            AccountId = acct.Id,
            Name = 'Test Order',
            BillingCity = 'Test City',
            Contingency_Order__c = true,
            EffectiveDate = Date.today(),
            Pricebook2Id = Test.getStandardPricebookId(),
            Status = 'Draft',
            Seasonal_Order__c = true,
            Apply_Standby_Rates__c = true,
            Shift_Order__c = true,
            Company_Code__c = '01',
            Deliverymethod__c = 'Delivery',
            Start_Date__c = System.now().addMonths(2),
            Estimated_Return_Date__c = System.now().addMonths(3),
            Branch__c = branchLocation.Id
        );
        insert order;
        
        List<OrderItem> ois = new List<OrderItem>();
        OrderItem orderLine = new OrderItem(OrderId = order.Id, Product2Id = product.Id, 
            PricebookEntryId = pbEntry.Id, Quantity = 2, Quantity__c= 3, UnitPrice = 3.0, 
            Hourly_Rate__c=5, Min_Rate__c =2, Daily_Rate__c=5, Weekly_Rate__c=10, Monthly_Rate__c=100,
            Selling_Price__c = 12);
        ois.add(orderLine);

        OrderItem orderLine2 = new OrderItem(OrderId = order.Id, Product2Id = product2.Id, 
            PricebookEntryId = pbEntry2.Id, Quantity = 4,Quantity__c= 2,  UnitPrice = 2.00,
            Hourly_Rate__c=5, Min_Rate__c =2, Daily_Rate__c=5, Weekly_Rate__c=10, Monthly_Rate__c=100,
            Selling_Price__c = 12);
        ois.add(orderLine2);
        insert ois;

    }
    @istest
    static void executeQueueableForAfterInsertOI()
    {
        
      order insertedOrder=  [select id from order limit 1];
         List<OrderItem> orderItems= SBR_3_0_OrderLineDA.getOrderItems(insertedOrder.Id);
        set<string> itemIds = new set<String>();
        Set<String> orderIds = new Set<String>();
        for(orderItem item:orderItems)
        {
            itemIds.add(item.Id);
            orderIds.add(item.OrderId);
        }
        test.startTest();
        System.enqueueJob(new SBR_3_0_Queueable_OrderLines(itemIds,itemIds,orderIds));
        List<orderItem> ori= [select id from orderitem where orderId=:insertedOrder.Id];
        test.stopTest();

        System.assertEquals(2, ori.size(), 'The retrieved Items does not match the expected results.');
     }
}