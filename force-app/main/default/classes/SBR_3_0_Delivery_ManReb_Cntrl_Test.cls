@isTest
public  class SBR_3_0_Delivery_ManReb_Cntrl_Test {
     @TestSetup
  static void makeData() {
    /*Product_Hierarchy__c prdHierachy = new Product_Hierarchy__c(
      Name = 'Test Hierarchy',
      Product_Hierarchy_Code__c = 'Test_HR_Code',
      RecordTypeId = SBR_3_0_Constants.PRODUCT_HIERARCHY_PRODUCT_SUB_CATEGORY_RT_ID
    );
    insert prdHierachy;*/

    /*List<SBQQ__Quote__c> quotes = SBR_3_0_TestDataFactory.createQuotes(
      1,
      false,
      'Sales_Quote'
    );
    insert quotes;*/
   /*
    User u = new User(id = userinfo.getuserId());
    u.Department = '1';
    u.CompanyName = '01';
    update u;
    Credential__c cred = SBR_3_0_TestDataFactory.createCredentials(1, false)[0];
    cred.Name = 'Mule_Token_Endpoint';
    cred.Key_Id__c = 'keyid';
    cred.Secret__c = 'credSecret';
    insert cred;
    */
    RecordType skuRecordType = [
      SELECT Id, Name
      FROM RecordType
      WHERE SobjectType = 'Product2' AND Name = 'SKU'
    ];
    System.debug('record type ID = ' + skuRecordType.Id);

    List<Product2> products = SBR_3_0_TestDataFactory.createProducts(3, false);
    for (Integer i = 0; i < products.size(); i++) {
      Integer j = i + 1;
      products[i].Name = 'Test Product';
      products[i].Sell_Price__c = 10;
      products[i].Product_SKU__c = j + '234567';
      products[i].Company_Code__c = '01';
      //products[i].Product_Hierarchy__c = prdHierachy.Id;
      products[i].RecordTypeId = skuRecordType.Id;
      products[i].Bulk_Item__c = false;
    }
    products[1].Name = 'Test Optional SKU';
    products[2].Name = 'Test Without Product SKU';
    products[2].Product_SKU__c = null;
    insert products;

      /*
    List<SBQQ__ProductFeature__c> features = new List<SBQQ__ProductFeature__c>();
    SBQQ__ProductFeature__c feature1 = new SBQQ__ProductFeature__c();
    feature1.Name = 'Sales Addons';
    feature1.SBQQ__Number__c = 1;
    feature1.SBQQ__ConfiguredSKU__c = products[0].Id;
    features.add(feature1);

    SBQQ__ProductFeature__c feature2 = new SBQQ__ProductFeature__c();
    feature2.Name = 'Rental Addons';
    feature2.SBQQ__Number__c = 2;
    feature2.SBQQ__ConfiguredSKU__c = products[0].Id;
    features.add(feature2);

    SBQQ__ProductFeature__c feature3 = new SBQQ__ProductFeature__c();
    feature3.Name = 'Forced Item';
    feature3.SBQQ__Number__c = 3;
    feature3.SBQQ__ConfiguredSKU__c = products[0].Id;
    features.add(feature3);

    insert features;

    List<SBQQ__ProductOption__c> options = new List<SBQQ__ProductOption__c>();
    SBQQ__ProductOption__c option1 = new SBQQ__ProductOption__c();
    option1.SBQQ__ConfiguredSKU__c = products[0].Id;
    option1.SBQQ__OptionalSKU__c = products[0].Id;
    option1.SBQQ__Feature__c = features[0].Id;
    option1.SBQQ__Number__c = 1;
    option1.Company_Code__c = '01';

    options.add(option1);

    SBQQ__ProductOption__c option2 = new SBQQ__ProductOption__c();
    option2.SBQQ__ConfiguredSKU__c = products[0].Id;
    option2.SBQQ__OptionalSKU__c = products[0].Id;
    option2.SBQQ__Feature__c = features[1].Id;
    option2.SBQQ__Number__c = 2;
    option2.Company_Code__c = '01';
    options.add(option2);

    SBQQ__ProductOption__c option3 = new SBQQ__ProductOption__c();
    option3.SBQQ__ConfiguredSKU__c = products[0].Id;
    option3.SBQQ__OptionalSKU__c = products[0].Id;
    option3.SBQQ__Feature__c = features[2].Id;
    option3.SBQQ__Number__c = 3;
    option3.Company_Code__c = '01';

    options.add(option3);
    insert options;
*/
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
	
     //Create Asset 
        Asset ast = new Asset();
        ast.Status = 'SCHEDULED FOR PICKUP';
        ast.Name = 'Test Asset';
        ast.AccountId = acct.Id;
        insert ast;
      
    // Create Analysis Region
    /*Analysis_Region__c region = new Analysis_Region__c();
    region.Analysis_Region_Key__c = '001';
    region.Name = 'Test Region';
    region.Company_Code__c = '01';
    insert region;*/

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
    jobLocation.Analysis_Region_Key__c = '921';
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
    branchLocation.OMS_Sourcing_Enabled__c = true;
    insert branchLocation;

    // Create Job Site
    AssociatedLocation jobSite = new AssociatedLocation(
      Name__c = 'Test Job Site',
      ParentRecordId = acct.Id,
      LocationId = jobLocation.Id,
      Branch__c = branchLocation.Id,
      Job_Number__c = '20221004A',
      Job_Site_Id__c = '123432'
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
      name = 'Test order1234983',
      Quote_Name__c = 'Test Quote',
      AccountId = acct.Id,
      Jobsite__c = jobSite.Id,
      Deliverymethod__c = 'Delivery',
      Status = 'Draft',
      Pricebook2Id = priceBook.Id,
      Start_Date__c = date.valueOf('2022-10-07 12:00:00'),
      EffectiveDate = date.valueOf('2022-10-07 12:00:00'),
      EndDate = date.valueOf('2022-10-08 8:00:00'),
      Earliest_Delivery_Date__c = date.valueOf('2022-09-06 12:00:00'),
      Opt_Out_RPP__c = false,
      Opt_Out_Fuel_Charge__c = false,
      Selling_Channel__c = 'SBRB2B',
      Using_3rd_Party__c = false,
      Order_Initiating_Channel__c = 'SF',
      Delivery_Charges_Override__c = false,
      Pickup_Charges_Override__c = false,
      //Duration__c = 'Custom',
      Branch__c = branchLocation.Id,
      Sourcing_Branch__c = branchLocation.Id
    );
    insert order;
	
      // Create Price Book Entry
        List<PricebookEntry> listPbe = new List<PricebookEntry>();

        SBR_3_0_TestDataFactory.createPriceBookEntries(products);
      
       Map<Id, Id> mapPBE = new Map<Id, Id>();
        for(PricebookEntry pbEntry : [SELECT Id,Product2Id FROM PricebookEntry WHERE Pricebook2Id = :Test.getStandardPricebookId()]) {
            if(pbEntry.Product2Id == products[0].Id){
                mapPBE.put(pbEntry.Product2Id, pbEntry.Id);
            }
            else if(pbEntry.Product2Id == products[1].Id){
                mapPBE.put(pbEntry.Product2Id, pbEntry.Id);
            }
            else if(pbEntry.Product2Id == products[2].Id){
                mapPBE.put(pbEntry.Product2Id, pbEntry.Id);
            }
        }
        // Create Order item
        List<OrderItem> orderItems = new List<OrderItem>();
       for(Integer i = 0; i < 3; i++){
            OrderItem orderItem = new OrderItem();
            orderItem.OrderId = order.Id;
            orderItem.Selling_Price__c = 15;
            orderItem.Product2Id = products[i].Id;
            orderItem.UnitPrice = 100;
            orderItem.Item_Number__c = i;
            orderItem.Min_Rate__c = 2;
            orderItem.Daily_Rate__c = 2.0;
            orderItem.Weekly_Rate__c = 2.0;
            orderItem.Monthly_Rate__c = 2.0;
            orderItem.PricebookEntryId = mapPBE.get(products[i].Id);
           orderItem.SBQQ__Asset__c = ast.Id;
            if(i == 0) {
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
              //  orderItem.Line_Comments__c = 'Comments';
               // orderItem.SBQQ__Number__c = 5;
            } else if (i == 1) {
                orderItem.Quantity = 3;
                //orderItem.ListPrice = pbEntry2.ListPrice;
            } else {
                orderItem.Quantity = 3;
                orderItem.Misc_Charges_Type__c = 'TRANSPORTATION CHARGE';
                orderItem.Misc_Charge__c = 20.3;
                orderItem.Misc_Charges_Tax__c = 2.34;
                orderItem.Taxable__c = false;
                orderItem.Misc_Charges_Non_Taxable__c = false;
                orderItem.Misc_Charges_Item_Tax_Rate__c = 2.0;
            }
            orderItems.add(orderItem);
        }
        insert orderItems;
    
  }
    @isTest static void testisOrderItemNotBulk() {
        list<orderItem> orderItemList = [SELECT id,orderId,SBQQ__Asset__c FROM orderitem where SBQQ__Asset__c != null  and product2.Bulk_Item__c = false];
        system.debug('orderItemList'+orderItemList.size());
        list<order> orderList = [SELECT id,Sourcing_Branch__c FROM order];
        Test.startTest();
        boolean result = SBR_3_0_Delivery_Manual_Rebal_Controller.isOrderItemNotBulk(orderList[0].Id);
        System.assertEquals(result, false);
        Test.stopTest();
    }
    
    @isTest static void testnullifyAssetRecord() {
        list<orderItem> orderItemList = [SELECT id,orderId,SBQQ__Asset__c FROM orderitem where SBQQ__Asset__c != null  and product2.Bulk_Item__c = false];
        system.debug('orderItemList'+orderItemList.size());
        list<order> orderList = [SELECT id,Sourcing_Branch__c FROM order];
        Test.startTest();
        string resultSuccess = SBR_3_0_Delivery_Manual_Rebal_Controller.nullifyAssetRecord(orderItemList[0].orderId,orderList[0].Sourcing_Branch__c);
        System.assertEquals(resultSuccess, 'success');
        string resultError = SBR_3_0_Delivery_Manual_Rebal_Controller.nullifyAssetRecord(orderItemList[0].orderId,'');
         System.assertEquals(resultError, 'error');
        Test.stopTest();
    }
    
    @isTest static void testnullifyAssetRecordNegative() {
        list<orderItem> orderItemList = [SELECT id,orderId,SBQQ__Asset__c FROM orderitem where SBQQ__Asset__c != null  and product2.Bulk_Item__c = false];
        system.debug('orderItemList'+orderItemList.size());
        list<order> orderList = [SELECT id,Sourcing_Branch__c FROM order];
        Test.startTest();
        string resultError = SBR_3_0_Delivery_Manual_Rebal_Controller.nullifyAssetRecord(orderItemList[0].orderId,'');
         System.assertEquals(resultError, 'error');
        Test.stopTest();
    }
}