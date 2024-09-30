/*********************************************************************************************************************
* Apex Class: Sbr_3_0_ContractController_Test
----------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Test class for Sbr_3_0_ContractController 
*********************************************************************************************************************/

@isTest
public with sharing class Sbr_3_0_ContractController_Test {
  /**
   * @description       : Test Class for SBR_3_0_OrderItemOperations class
   * @author            : Amy
   * MethodName         : makeData
   **/
  @TestSetup
  static void makeData() {
    Id recordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName()
      .get('Create_Contract')
      .getRecordTypeId();
    Credential__c cred = SBR_3_0_TestDataFactory.createCredentials(1, false)[0];
    cred.Name = 'Mule_Token_Endpoint';
    cred.Key_Id__c = 'testKey123';
    cred.Secret__c = 'secret';
    insert cred;

    // Prepare Data
    // Activate Price Book
    Pricebook2 priceBook = new Pricebook2(
      Id = Test.getStandardPricebookId(),
      IsActive = true
    );
    update priceBook;
    // Create Account
    Account acct = new Account();
    acct.RM_Account_Number__c = '4';
    acct.Company_Code__c = '01';
    acct.Name = 'Test Account';
    acct.Record_Type_Text__c = 'Credit';
    acct.E_mail_Address__c = '123@asdf.com';
    acct.Phone = '1234567899';
    acct.BillingStreet = '123 Main Street';
    acct.BillingCity = 'Toronto';
    acct.BillingPostalCode = 'M9N7V5';
    acct.BillingState = 'ON';
    acct.BillingCountry = 'CA';
    acct.Drivers_License__c = 'AKF';
    acct.Driver_s_License_State__c = 'AL';
    insert acct;

    // Create Contact
    Contact contact = SBR_3_0_TestDataFactory.createContacts(
      1,
      acct.Id,
      true
    )[0];
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
    branchLocation.Branch_Location_Number__c = '0720';
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
    branchLocation.Time_Zone_Id__c = 'America/Chicago';
    branchLocation.Latitude_Longitude__Latitude__s = 40.464390;
    branchLocation.Latitude_Longitude__Longitude__s = -80.601060;
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

    // Create Order
    Order order = new Order(
      AccountId = acct.Id,
      Jobsite__c = jobSite.Id,
      Deliverymethod__c = 'Delivery',
      Delivery_Charge__c = 10,
      Status = 'Draft',
      Pricebook2Id = priceBook.Id,
      Start_Date__c = date.valueOf('2022-12-12 12:00:00'),
      EffectiveDate = date.valueOf('2022-12-12 12:00:00'),
      EndDate = date.valueOf('2023-10-09 8:00:00'),
      Return_Date__c = date.valueOf('2023-10-09 8:00:00'),
      Earliest_Delivery_Date__c = date.valueOf('2022-10-08 12:00:00'),
      Opt_Out_RPP__c = false,
      Order_Initiating_Channel__c = 'SLSFRC',
      Opt_Out_Fuel_Charge__c = false,
      Selling_Channel__c = 'SBRB2B',
      RecordTypeId = recordTypeId,
      Duration__c = 'Custom'
    );

    insert order;
    // Create Product
    List<Product2> products = new List<Product2>();
    for (Integer i = 0; i < 3; i++) {
      Product2 product = new Product2();
      product.Name = 'Test Product ' + i;
      if (i == 0) {
        product.Product_Type__c = 'Cat-Class';
        product.Product_SKU__c = '1234567';
        product.Category__c = '32134';
        product.Class__c = '2039';
        product.ToolFlex__c = 'N';
        product.Company_code__c = '01';
      } else if (i == 1) {
        product.Product_Type__c = 'Parts';
        product.Item_Number__c = '1234GH';
        product.Stock_Class__c = 'DEL';
        product.Company_code__c = '01';
      } else {
        product.Product_Type__c = 'MISC Charge Items';
        product.Item_Number__c = '1285JC';
        product.Stock_Class__c = 'DEL';
        product.Company_code__c = '01';
      }
      products.add(product);
    }
    insert products;
    // Create Price Book Entry
    List<PricebookEntry> listPbe = new List<PricebookEntry>();

    SBR_3_0_TestDataFactory.createPriceBookEntries(products);

    Map<Id, Id> mapPBE = new Map<Id, Id>();
    for (PricebookEntry pbEntry : [
      SELECT Id, Product2Id
      FROM PricebookEntry
      WHERE Pricebook2Id = :Test.getStandardPricebookId()
    ]) {
      if (pbEntry.Product2Id == products[0].Id) {
        mapPBE.put(pbEntry.Product2Id, pbEntry.Id);
      } else if (pbEntry.Product2Id == products[1].Id) {
        mapPBE.put(pbEntry.Product2Id, pbEntry.Id);
      } else if (pbEntry.Product2Id == products[2].Id) {
        mapPBE.put(pbEntry.Product2Id, pbEntry.Id);
      }
    }
    // Create Order item
    List<OrderItem> orderItems = new List<OrderItem>();
    for (Integer i = 0; i < 3; i++) {
      OrderItem orderItem = new OrderItem();
      orderItem.OrderId = order.Id;
      orderItem.Selling_Price__c = 10;
      orderItem.Product2Id = products[i].Id;
      orderItem.UnitPrice = 100;
      orderItem.Item_Number__c = i;
      orderItem.Min_Rate__c = 2;
      orderItem.Daily_Rate__c = 2.0;
      orderItem.Weekly_Rate__c = 2.0;
      orderItem.Monthly_Rate__c = 2.0;
      orderItem.PricebookEntryId = mapPBE.get(products[i].Id);
      if (i == 0) {
        orderItem.Hourly_Rate__c = 2.0;
        orderItem.Min_Rate__c = 2.0;
        orderItem.Quantity = 5;
        orderItem.Free_Flag__c = false;
        orderItem.Suggested_Daily_Rate__c = 2.0;
        orderItem.Suggested_Weekly_Rate__c = 2.0;
        orderItem.Suggested_Monthly_Rate__c = 2.0;
        orderItem.Daily_Rate__c = 2.0;
        orderItem.Weekly_Rate__c = 2.0;
        orderItem.Monthly_Rate__c = 2.0;
        orderItem.Rates_Overriden__c = false;
        orderItem.Global_Line_Number__c = 123;
        orderItem.Line_Item_Type__c = 'YC';
      } else if (i == 1) {
        orderItem.Quantity = 3;
        orderItem.Global_Line_Number__c = 456;
      } else {
        orderItem.Quantity = 3;
        orderItem.Misc_Charges_Type__c = 'TRANSPORTATION CHARGE';
        orderItem.Misc_Charge__c = 20.3;
        orderItem.Misc_Charges_Tax__c = 2.34;
        orderItem.Taxable__c = false;
        orderItem.Misc_Charges_Non_Taxable__c = false;
        orderItem.Misc_Charges_Item_Tax_Rate__c = 2.0;
        orderItem.Global_Line_Number__c = 412;
      }
      orderItems.add(orderItem);
    }
    insert orderItems;
  }

  /**
   * @description       : testGetItemSearchColumns
   * @author            : Amy
   * MethodName         : testGetItemSearchColumns
   **/

  @isTest
  static void testGetItemSearchColumns() {
    List<CustomDataTableCmpColumn__mdt> result = new List<CustomDataTableCmpColumn__mdt>();
    Test.startTest();
    result = Sbr_3_0_ContractController.getContractLineItemColumns('Rentals');
    Test.stopTest();
    Assert.areEqual(
      result.size() > 0,
      true,
      'Contract Line Item Columns not found'
    );
  }
  /**
   * @description       : getContractRentalLineItemsTest
   * @author            : Amy
   * MethodName         : getContractRentalLineItemsTest
   **/

  @isTest
  static void getContractRentalLineItemsTest() {
    Order order1 = [SELECT Id FROM Order][0];
    Test.startTest();
    List<OrderItem> orderItems = Sbr_3_0_ContractController.getContractRentalLineItems(
      order1.Id
    );
    Test.stopTest();
    Assert.areEqual(
      orderItems.size() > 0,
      true,
      'Contract Rental Items not found'
    );
  }

  /**
   * @description       : getContractSalesLineItemsTest
   * @author            : Amy
   * MethodName         : getContractSalesLineItemsTest
   **/

  @isTest
  static void getContractSalesLineItemsTest() {
    Order order2 = [SELECT Id FROM Order][0];
    Test.startTest();
    List<OrderItem> orderItems = Sbr_3_0_ContractController.getContractSalesLineItems(
      order2.Id
    );
    Test.stopTest();
    Assert.areEqual(orderItems.size() > 0, true, 'Sales Items not found');
  }

  /**
   * @description       : getContractDeliveryLineItemsTest
   * @author            : Amy
   * MethodName         : getContractDeliveryLineItemsTest
   **/

  @isTest
  static void getContractDeliveryLineItemsTest() {
    Order order3 = [SELECT Id FROM Order][0];
    Test.startTest();
    List<OrderItem> orderItems = Sbr_3_0_ContractController.getContractDeliveryLineItems(
      order3.Id
    );
    Test.stopTest();
    Assert.areEqual(orderItems.size() > 0, true, 'Delivery Items not found');
  }

  /**
   * @description       : getContractAncillaryLineItemsTest
   * @author            : Amy
   * MethodName         : getContractAncillaryLineItemsTest
   **/

  @isTest
  static void getContractAncillaryLineItemsTest() {
    Order order4 = [SELECT Id FROM Order][0];
    Test.startTest();
    List<OrderItem> orderItems = Sbr_3_0_ContractController.getContractAncillaryLineItems(
      order4.Id
    );
    Test.stopTest();
    Assert.areEqual(orderItems.size() > 0, true, 'Ancillary Items not found');
  }
}