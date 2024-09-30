@isTest
public class SBR_3_0_OrderLineDA_Test {
  @TestSetup
  static void makeData() {
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
    branchLocation.Job_Number__c = '332112';
    branchLocation.RecordTypeId = SBR_3_0_Constants.LOCATION_BRANCH_RT_ID;
    branchLocation.Company_Code__c = 'X';
    branchLocation.Time_Zone_Name__c = 'America/Chicago';
    branchLocation.Time_Zone__c = 3;
    branchLocation.Analysis_Region_Key__c = '293';
    insert branchLocation;

    // Create Job Site
    AssociatedLocation jobSite = new AssociatedLocation(
      Name__c = 'Test Job Site',
      ParentRecordId = acct.Id,
      LocationId = jobLocation.Id,
      Branch__c = branchLocation.Id,
      Job_Number__c = '20221004A'
    );
    insert jobSite;

    // Create Price Book
    Pricebook2 priceBook = new Pricebook2(
      Id = Test.getStandardPricebookId(),
      IsActive = true
    );
    update priceBook;

    // Create Order
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
      Duration__c = 'Custom'
    );
    insert order;

    SVMXA360__SM_TA_Template__c smTaTemplate = new SVMXA360__SM_TA_Template__c();
    smTaTemplate.Name = 'SBR 3.0 Maintenance Template';
    smTaTemplate.SVMXA360__DeveloperName__c = 'SBR_3_0_Maintenance_Template';
    insert smTaTemplate;

    // Create Product
    List<Product2> products = new List<Product2>();
    for (Integer i = 0; i < 3; i++) {
      Product2 product = new Product2();
      product.Name = 'Test Product ' + i;
      if (i == 0) {
        product.Product_Type__c = 'Cat-Class';
        product.Product_SKU__c = '123456';
        product.Category__c = '32134';
        product.Class__c = '2039';
        product.ToolFlex__c = 'N';
        product.isSerialized = true;
      } else if (i == 1) {
        product.Product_Type__c = 'Parts';
        product.Item_Number__c = '1234GH';
        product.Stock_Class__c = 'AIMFV';
        product.isSerialized = true;
      } else {
        product.Product_Type__c = '';
        product.Item_Number__c = '1285JC';
        product.Stock_Class__c = 'UJEKL';
      }
      products.add(product);
    }
    insert products;

    List<PricebookEntry> pes = new List<PricebookEntry>();
    for (Product2 product : products) {
      PricebookEntry pe = new PricebookEntry();
      pe.Pricebook2Id = Test.getStandardPricebookId();
      pe.Product2Id = product.Id;
      pe.UnitPrice = 100;
      pe.IsActive = true;
      pe.UseStandardPrice = false;
      pes.add(pe);
    }
    insert pes;
    Product2 prod = [
      SELECT Id, Product_SKU__c
      FROM Product2
      WHERE Product_Type__c = 'Cat-Class'
    ];

    List<OrderItem> orderItems = new List<OrderItem>();

    for (Integer i = 0; i < 5; i++) {
      OrderItem orderItem = new OrderItem();
      orderItem.OrderId = order.Id;
      orderItem.Product2Id = prod.Id;
      orderItem.UnitPrice = 100;
      orderItem.Item_Number__c = 0;
      orderItem.PricebookEntryId = pes[0].Id;
      orderItem.Hourly_Rate__c = 2.0;
      orderItem.Min_Rate__c = 2.0;
      orderItem.Quantity = 5;
      orderItem.Cost__c = 10;
      orderItem.groupID__c = '123';
      orderItem.Free_Flag__c = false;
      orderItem.Suggested_Daily_Rate__c = 2.0;
      orderItem.Suggested_Weekly_Rate__c = 2.0;
      orderItem.Suggested_Monthly_Rate__c = 2.0;
      orderItem.Selling_Price__c = 2.0;
      orderItem.Daily_Rate__c = 2.0;
      orderItem.Weekly_Rate__c = 2.0;
      orderItem.Monthly_Rate__c = 2.0;
      orderItem.Rates_Overriden__c = false;
      orderItems.add(orderItem);
    }

    insert orderItems;
  }

  @isTest
  public static void getOrderItemsTest() {
    Order order = [SELECT Id FROM Order LIMIT 1];

    Test.startTest();
    List<OrderItem> orderItems = SBR_3_0_OrderLineDA.getOrderItems(order.Id);
    List<OrderItem> orderItemList = SBR_3_0_OrderLineDA.getOrderItems(
      new Set<Id>{ Order.Id }
    );
    List<OrderItem> orderItemWithGroupId = SBR_3_0_OrderLineDA.getOrderItems(
      order.Id,
      '123'
    );
    Test.stopTest();

    System.assertEquals(
      5,
      orderItems.size(),
      'Did not return expected number of order items'
    );
    System.assertEquals(
      5,
      orderItemList.size(),
      'Did not return expected number of order items'
    );
    System.assertEquals(
      5,
      orderItemWithGroupId.size(),
      'Did not return expected number of order items'
    );
  }
}