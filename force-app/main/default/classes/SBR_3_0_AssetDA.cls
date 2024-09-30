public with sharing class SBR_3_0_AssetDA {
  private static final List<String> Statuses = new List<String>{
    'Available',
    'DOWN - LESS THAN 20 DAYS',
    'DOWN - MORE THAN 20 DAYS',
    'RETURNED - NEED CHECK OUT',
    'SCHEDULED FOR PICKUP'
  }; // Changed As Part Of FRONT-23272
  private static final List<String> Order_Statuses = new List<String>{
    'ON RENT',
    'ON RENT PURCHASE',
    'SCHEDULED FOR PICKUP'
  };

  @auraEnabled
  public static List<Asset> fetchAssetsBasedOnStatus(
    String catClass,
    String branchNumber
  ) {
    return [
      SELECT
        NAME,
        SM_PS_Current_Branch_Location_Number__c,
        status,
        SM_PS_Cat_Class__c,
        SM_PS_Asset_Id__c,
        SM_PS_Make__c
      FROM ASSET
      WHERE
        SM_PS_Current_Branch_Location_Number__c = :branchNumber
        AND RecordType.DeveloperName = 'RENTAL_ASSET'
        AND SM_PS_Cat_Class__c = :catClass
        AND status IN :Statuses
    ];
  }

  @AuraEnabled(cacheable=true)
  public static AssetInformationWrapper fetchAssetInformation(String assetId) {
    AssetInformationWrapper assetWrapper = new AssetInformationWrapper();
    // Get Asset Information based on asset Id
    Asset asset = [
      SELECT
        Id,
        Description,
        Name,
        Quantity,
        ProductDescription,
        SM_PS_Asset_Id__c,
        SM_PS_Assigned_Location__c,
        SM_PS_Book_Value__c,
        SM_PS_Make__c,
        SM_PS_Model__c,
        SM_PS_Model_Year__c,
        SM_PS_Original_Cost__c,
        SM_PS_Sell_Price__c,
        SM_PS_Serial_Number__c,
        SM_PS_Year_to_Hours_Rent__c
      FROM Asset
      WHERE SM_PS_Asset_Id__c = :assetId
      LIMIT 1
    ];

    // Get Order Information
    List<OrderItem> orderItems = [
      SELECT
        Id,
        OrderId,
        Order.Sales_Rep__r.FirstName,
        Order.Sales_Rep__r.LastName,
        Order.Sales_Rep__r.Name,
        Order.Branch__r.Phone__c,
        Order.Order_By__r.FirstName,
        Order.Order_By__r.LastName,
        Order.Order_By__r.Name,
        Order.Day_of_month_to_bill_on__c,
        Order.Account.Name,
        Cost__c,
        Order.Jobsite__r.Name__c,
        Order.Jobsite__r.Contact_Name__c,
        Daily_Rate2__c,
        Weekly_Rate2__c,
        Monthly_Rate2__c,
        Order.Contract.ContractNumber,
        Order.Contract_Order_Number__c,
        Order.ContractId,
        Total_Amount_Billed__c,
        Order.OrderNumber
      FROM OrderItem
      WHERE
        SBQQ__Asset__r.SM_PS_Asset_Id__c = :assetId
        AND Status__c IN :Order_Statuses
      LIMIT 1
    ];

    assetWrapper.asset = asset;

    if (orderItems != null && orderItems.size() > 0) {
      assetWrapper.order = orderItems[0];
    }

    return assetWrapper;
  }

  public static List<Asset> fetchAssetsBlueYonder(
    String orgId,
    Set<String> setCatClass,
    Set<String> setLocations
  ) {
    return [
      SELECT
        ID,
        SM_PS_Company_Code__c,
        SM_PS_Category__c,
        SM_PS_Class__c,
        SM_PS_Cat_Class__c,
        SM_PS_Machine_Weight__c,
        SM_PS_Current_Location__c,
        SM_PS_Equipment_Number__c,
        SM_PS_Assigned_Location__c,
        Name,
        Description,
        SM_PS_Assigned_Location__r.A360SPARK_ExternalId__c,
        SM_PS_Current_Location__r.Branch_Location_Number__c
      FROM ASSET
      WHERE
        SM_PS_Company_Code__c = :orgId
        AND SM_PS_Cat_Class__c IN :setCatClass
        AND SM_PS_Current_Location__r.Branch_Location_Number__c IN :setLocations
      ORDER BY SM_PS_Last_Transaction_Date__c ASC
    ];
  }

  public class AssetInformationWrapper {
    @AuraEnabled
    public Asset asset { get; set; }
    @AuraEnabled
    public OrderItem order { get; set; }
  }

  public static Map<String, Asset> getAssetsByNumbers(
    Set<String> assetNumbers
  ) {
    Map<String, Asset> assets = new Map<String, Asset>();

    for (Asset asset : [
      SELECT Id, Name, SBQQ__Number__c
      FROM Asset
      WHERE Name IN :assetNumbers
    ]) {
      assets.put(asset.Name, asset);
    }
    return assets;
  }

  public static List<Asset> getAssetsByProduct(String productId) {
    return [
      SELECT
        ID,
        SM_PS_Equipment_Number__c,
        SM_PS_Assigned_Location__r.Branch_Location_Number__c,
        Name,
        Description,
        SM_PS_Last_Transaction_Date__c,
        SM_PS_Current_Location__r.Branch_Location_Number__c,
        Product2.Name
      FROM ASSET
      WHERE Product2Id = :productId
      ORDER BY SM_PS_Last_Transaction_Date__c ASC
    ];
  }

  public static Map<String, Asset> getAssetssById(Set<String> ids) {
    return new Map<String, Asset>(
      [
        SELECT
          ID,
          SM_PS_Equipment_Number__c,
          Status,
          Product2Id,
          Name,
          Product2.Name,
          Product2.Product_SKU__c,
          Product2.Product_Type__c,
          Product2.Product_Category__c,
          Product2.Product_Sub_Category__c,
          Product2.IsSerialized,
          Product2.Sell_Price__c,
          Product2.Stock_class__c,
          Product2.Bulk_Item__c,
          Product2.Item_Number__c
        FROM Asset
        WHERE Id IN :ids
      ]
    );
  }

  public static List<Asset> getAssetsByEqpLocation(
    String loc,
    String catClass
  ) {
    return [
      SELECT
        Id,
        Name,
        SM_PS_Asset_Record_Type_Text__c,
        Product2.Name,
        Description,
        SM_PS_Due_Off_Rent_Date__c,
        SM_PS_Cat_Class_Description__c,
        Status,
        SM_PS_Current_Branch_Location_Number__c,
        SM_PS_Equipment_Type__c,
        SM_PS_Cat_Class__c,
        SM_PS_Equipment_Condition_Comment__c,
        Product2.Product_SKU__c,
        SM_PS_Model_Year__c
      FROM Asset
      WHERE
        SM_PS_Current_Branch_Location_Number__c = :loc
        AND SM_PS_Cat_Class__c = :catClass
    ];
  }

  public static List<Asset> getAssetsBySearchKey(
    String searchKey,
    String catClass
  ) {
    return [
      SELECT
        Id,
        Name,
        SM_PS_Asset_Record_Type_Text__c,
        Product2.Name,
        Description,
        SM_PS_Due_Off_Rent_Date__c,
        SM_PS_Cat_Class_Description__c,
        Status,
        SM_PS_Current_Branch_Location_Number__c,
        SM_PS_Equipment_Type__c,
        SM_PS_Cat_Class__c,
        SM_PS_Equipment_Condition_Comment__c,
        Product2.Product_SKU__c,
        SM_PS_Model_Year__c
      FROM Asset
      WHERE
        SM_PS_Cat_Class_Description__c LIKE :'%' + searchKey + '%'
        AND SM_PS_Cat_Class__c = :catClass
    ];
  }

  public static List<Asset> getAssetsByYear(
    String year,
    String catClass,
    Integer offset
  ) {
    return [
      SELECT
        Id,
        Name,
        SM_PS_Asset_Record_Type_Text__c,
        Product2.Name,
        Description,
        SM_PS_Due_Off_Rent_Date__c,
        SM_PS_Cat_Class_Description__c,
        Status,
        SM_PS_Current_Branch_Location_Number__c,
        SM_PS_Equipment_Type__c,
        SM_PS_Cat_Class__c,
        SM_PS_Equipment_Condition_Comment__c,
        Product2.Product_SKU__c,
        SM_PS_Model_Year__c
      FROM Asset
      WHERE
        SM_PS_Model_Year__c LIKE :'%' + year
        AND SM_PS_Cat_Class__c = :catClass
      LIMIT 10
      OFFSET :offset
    ];
  }

  public static List<Asset> getAssetsByYearLoc(
    String year,
    String loc,
    String catClass
  ) {
    return [
      SELECT
        Id,
        Name,
        SM_PS_Asset_Record_Type_Text__c,
        Product2.Name,
        Description,
        SM_PS_Due_Off_Rent_Date__c,
        SM_PS_Cat_Class_Description__c,
        Status,
        SM_PS_Current_Branch_Location_Number__c,
        SM_PS_Equipment_Type__c,
        SM_PS_Cat_Class__c,
        SM_PS_Equipment_Condition_Comment__c,
        Product2.Product_SKU__c,
        SM_PS_Model_Year__c
      FROM Asset
      WHERE
        SM_PS_Model_Year__c LIKE :'%' + year
        AND SM_PS_Current_Branch_Location_Number__c = :loc
        AND SM_PS_Cat_Class__c = :catClass
    ];
  }

  public static List<Asset> getAssetsByLocSearchKey(
    String searchKey,
    String loc,
    String catClass
  ) {
    return [
      SELECT
        Id,
        Name,
        SM_PS_Asset_Record_Type_Text__c,
        Product2.Name,
        Description,
        SM_PS_Due_Off_Rent_Date__c,
        SM_PS_Cat_Class_Description__c,
        Status,
        SM_PS_Current_Branch_Location_Number__c,
        SM_PS_Equipment_Type__c,
        SM_PS_Cat_Class__c,
        SM_PS_Equipment_Condition_Comment__c,
        Product2.Product_SKU__c,
        SM_PS_Model_Year__c
      FROM Asset
      WHERE
        SM_PS_Cat_Class_Description__c LIKE :'%' + searchKey + '%'
        AND SM_PS_Current_Branch_Location_Number__c = :loc
        AND SM_PS_Cat_Class__c = :catClass
    ];
  }

  public static List<Asset> getAssetsByLocSearchKeyYear(
    String searchKey,
    String loc,
    String year,
    String catClass
  ) {
    return [
      SELECT
        Id,
        Name,
        SM_PS_Asset_Record_Type_Text__c,
        Product2.Name,
        Description,
        SM_PS_Due_Off_Rent_Date__c,
        SM_PS_Cat_Class_Description__c,
        Status,
        SM_PS_Current_Branch_Location_Number__c,
        SM_PS_Equipment_Type__c,
        SM_PS_Cat_Class__c,
        SM_PS_Equipment_Condition_Comment__c,
        Product2.Product_SKU__c,
        SM_PS_Model_Year__c
      FROM Asset
      WHERE
        SM_PS_Cat_Class_Description__c LIKE :'%' + searchKey + '%'
        AND SM_PS_Current_Branch_Location_Number__c = :loc
        AND SM_PS_Model_Year__c LIKE :'%' + year
        AND SM_PS_Cat_Class__c = :catClass
    ];
  }

  public static List<Asset> getAssetsByYearSearchKey(
    String searchKey,
    String year,
    String catClass
  ) {
    return [
      SELECT
        Id,
        Name,
        SM_PS_Asset_Record_Type_Text__c,
        Product2.Name,
        Description,
        SM_PS_Due_Off_Rent_Date__c,
        SM_PS_Cat_Class_Description__c,
        Status,
        SM_PS_Current_Branch_Location_Number__c,
        SM_PS_Equipment_Type__c,
        SM_PS_Cat_Class__c,
        SM_PS_Equipment_Condition_Comment__c,
        Product2.Product_SKU__c,
        SM_PS_Model_Year__c
      FROM Asset
      WHERE
        SM_PS_Cat_Class_Description__c LIKE :'%' + searchKey + '%'
        AND SM_PS_Model_Year__c LIKE :'%' + year
        AND SM_PS_Cat_Class__c = :catClass
    ];
  }

  public static List<Asset> getAssetsByCatClass(
    String catClass,
    Integer offset
  ) {
    return [
      SELECT
        Id,
        Name,
        SM_PS_Asset_Record_Type_Text__c,
        Product2.Name,
        Description,
        SM_PS_Due_Off_Rent_Date__c,
        SM_PS_Cat_Class_Description__c,
        Status,
        SM_PS_Current_Branch_Location_Number__c,
        SM_PS_Equipment_Type__c,
        SM_PS_Cat_Class__c,
        SM_PS_Equipment_Condition_Comment__c,
        Product2.Product_SKU__c,
        SM_PS_Model_Year__c
      FROM Asset
      WHERE SM_PS_Cat_Class__c = :catClass
      LIMIT 10
      OFFSET :offset
    ];
  }

  public static List<Asset> getAssetsByStatusList(
    List<String> statusList,
    String catClass
  ) {
    return [
      SELECT
        Id,
        Name,
        SM_PS_Asset_Record_Type_Text__c,
        Product2.Name,
        Description,
        SM_PS_Due_Off_Rent_Date__c,
        SM_PS_Cat_Class_Description__c,
        Status,
        SM_PS_Current_Branch_Location_Number__c,
        SM_PS_Equipment_Type__c,
        SM_PS_Cat_Class__c,
        SM_PS_Equipment_Condition_Comment__c,
        Product2.Product_SKU__c,
        SM_PS_Model_Year__c
      FROM Asset
      WHERE Status IN :statusList AND SM_PS_Cat_Class__c = :catClass
    ];
  }

  public static List<Asset> getAssetsBySearchKeyStatusList(
    List<String> statusList,
    String searchKey,
    String catClass
  ) {
    return [
      SELECT
        Id,
        Name,
        SM_PS_Asset_Record_Type_Text__c,
        Product2.Name,
        Description,
        SM_PS_Due_Off_Rent_Date__c,
        SM_PS_Cat_Class_Description__c,
        Status,
        SM_PS_Current_Branch_Location_Number__c,
        SM_PS_Equipment_Type__c,
        SM_PS_Cat_Class__c,
        SM_PS_Equipment_Condition_Comment__c,
        Product2.Product_SKU__c,
        SM_PS_Model_Year__c
      FROM Asset
      WHERE
        SM_PS_Cat_Class_Description__c LIKE :'%' + searchKey + '%'
        AND Status IN :statusList
        AND SM_PS_Cat_Class__c = :catClass
    ];
  }

  public static List<Asset> getAssetsByYearStatusList(
    List<String> statusList,
    String year,
    String catClass
  ) {
    return [
      SELECT
        Id,
        Name,
        SM_PS_Asset_Record_Type_Text__c,
        Product2.Name,
        Description,
        SM_PS_Due_Off_Rent_Date__c,
        SM_PS_Cat_Class_Description__c,
        Status,
        SM_PS_Current_Branch_Location_Number__c,
        SM_PS_Equipment_Type__c,
        SM_PS_Cat_Class__c,
        SM_PS_Equipment_Condition_Comment__c,
        Product2.Product_SKU__c,
        SM_PS_Model_Year__c
      FROM Asset
      WHERE
        SM_PS_Model_Year__c LIKE :'%' + year
        AND Status IN :statusList
        AND SM_PS_Cat_Class__c = :catClass
    ];
  }

  public static List<Asset> getAssetsByStatusLoc(
    List<String> statusList,
    String loc,
    String catClass
  ) {
    return [
      SELECT
        Id,
        Name,
        SM_PS_Asset_Record_Type_Text__c,
        Product2.Name,
        Description,
        SM_PS_Due_Off_Rent_Date__c,
        SM_PS_Cat_Class_Description__c,
        Status,
        SM_PS_Current_Branch_Location_Number__c,
        SM_PS_Equipment_Type__c,
        SM_PS_Cat_Class__c,
        SM_PS_Equipment_Condition_Comment__c,
        Product2.Product_SKU__c,
        SM_PS_Model_Year__c
      FROM Asset
      WHERE
        SM_PS_Current_Branch_Location_Number__c = :loc
        AND Status IN :statusList
        AND SM_PS_Cat_Class__c = :catClass
    ];
  }

  public static List<Asset> getAssetsByYearStatusListSearchKey(
    List<String> statusList,
    String year,
    String searchKey,
    String catClass
  ) {
    return [
      SELECT
        Id,
        Name,
        SM_PS_Asset_Record_Type_Text__c,
        Product2.Name,
        Description,
        SM_PS_Due_Off_Rent_Date__c,
        SM_PS_Cat_Class_Description__c,
        Status,
        SM_PS_Current_Branch_Location_Number__c,
        SM_PS_Equipment_Type__c,
        SM_PS_Cat_Class__c,
        SM_PS_Equipment_Condition_Comment__c,
        Product2.Product_SKU__c,
        SM_PS_Model_Year__c
      FROM Asset
      WHERE
        SM_PS_Cat_Class_Description__c LIKE :'%' + searchKey + '%'
        AND Status IN :statusList
        AND SM_PS_Model_Year__c LIKE :'%' + year
        AND SM_PS_Cat_Class__c = :catClass
    ];
  }

  public static List<Asset> getAssetsByYearStatusListLoc(
    List<String> statusList,
    String year,
    String loc,
    String catClass
  ) {
    return [
      SELECT
        Id,
        Name,
        SM_PS_Asset_Record_Type_Text__c,
        Product2.Name,
        Description,
        SM_PS_Due_Off_Rent_Date__c,
        SM_PS_Cat_Class_Description__c,
        Status,
        SM_PS_Current_Branch_Location_Number__c,
        SM_PS_Equipment_Type__c,
        SM_PS_Cat_Class__c,
        SM_PS_Equipment_Condition_Comment__c,
        Product2.Product_SKU__c,
        SM_PS_Model_Year__c
      FROM Asset
      WHERE
        Status IN :statusList
        AND SM_PS_Current_Branch_Location_Number__c = :loc
        AND SM_PS_Model_Year__c LIKE :'%' + year
        AND SM_PS_Cat_Class__c = :catClass
    ];
  }

  public static List<Asset> getAssetsBySearchKeyStatusListLoc(
    List<String> statusList,
    String searchKey,
    String loc,
    String catClass
  ) {
    return [
      SELECT
        Id,
        Name,
        SM_PS_Asset_Record_Type_Text__c,
        Product2.Name,
        Description,
        SM_PS_Due_Off_Rent_Date__c,
        SM_PS_Cat_Class_Description__c,
        Status,
        SM_PS_Current_Branch_Location_Number__c,
        SM_PS_Equipment_Type__c,
        SM_PS_Cat_Class__c,
        SM_PS_Equipment_Condition_Comment__c,
        Product2.Product_SKU__c,
        SM_PS_Model_Year__c
      FROM Asset
      WHERE
        SM_PS_Cat_Class_Description__c LIKE :'%' + searchKey + '%'
        AND Status IN :statusList
        AND SM_PS_Current_Branch_Location_Number__c = :loc
        AND SM_PS_Cat_Class__c = :catClass
    ];
  }

  public static List<Asset> getAssetsBySearchKeyStatusListLocYear(
    List<String> statusList,
    String searchKey,
    String loc,
    String year,
    String catClass
  ) {
    return [
      SELECT
        Id,
        Name,
        SM_PS_Asset_Record_Type_Text__c,
        Product2.Name,
        Description,
        SM_PS_Due_Off_Rent_Date__c,
        SM_PS_Cat_Class_Description__c,
        Status,
        SM_PS_Current_Branch_Location_Number__c,
        SM_PS_Equipment_Type__c,
        SM_PS_Cat_Class__c,
        SM_PS_Equipment_Condition_Comment__c,
        Product2.Product_SKU__c,
        SM_PS_Model_Year__c
      FROM Asset
      WHERE
        SM_PS_Model_Year__c LIKE :'%' + year
        AND SM_PS_Cat_Class_Description__c LIKE :'%' + searchKey + '%'
        AND Status IN :statusList
        AND SM_PS_Current_Branch_Location_Number__c = :loc
        AND SM_PS_Cat_Class__c = :catClass
    ];
  }

  @AuraEnabled(cacheable=true)
  public static List<Asset> getAssetFilteredRecords(
    string locationNumber,
    List<string> catClassList
  ) {
    List<Asset> assetList = new List<Asset>();
    try {
      if (String.isNotBlank(locationNumber) && catClassList.size() > 0) {
        assetList = [
          SELECT
            id,
            SM_PS_Cat_Class__c,
            SM_PS_Cat_Class_Description__c,
            Status,
            SM_PS_Miscellaneous_Options__c,
            SM_PS_Make__c,
            SM_PS_Asset_Id__c
          FROM Asset
          WHERE
            Status != NULL
            AND SM_PS_Current_Branch_Location_Number__c = :locationNumber
            AND SM_PS_Cat_Class__c IN :catClassList
          WITH SECURITY_ENFORCED
        ];
      }
    } catch (Exception ex) {
      SBR_3_0_LogException.LogIt(ex);
      if (!Test.isRunningTest()) {
        throw ex;
      }
    }
    return assetList;
  }
  //FRONT-16637
  public static List<Asset> getAssetsByCatClassWithRelatedOrderItems(
    String orderId,
    String catClass,
    Integer offset
  ) {
    return [
      SELECT
        Id,
        Name,
        SM_PS_Asset_Record_Type_Text__c,
        Product2.Name,
        Description,
        SM_PS_Due_Off_Rent_Date__c,
        SM_PS_Cat_Class_Description__c,
        Status,
        SM_PS_Current_Branch_Location_Number__c,
        SM_PS_Equipment_Type__c,
        SM_PS_Cat_Class__c,
        SM_PS_Equipment_Condition_Comment__c,
        Product2.Product_SKU__c,
        SM_PS_Model_Year__c,
        (
          SELECT SBQQ__Asset__c, Product2Id
          FROM SBQQ__OrderProducts__r
          WHERE OrderId = :orderId
        )
      FROM Asset
      WHERE SM_PS_Cat_Class__c = :catClass
      LIMIT 10
      OFFSET :offset
    ];
  }
}