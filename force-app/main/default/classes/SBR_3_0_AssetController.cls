public with sharing class SBR_3_0_AssetController {
  @AuraEnabled
  public static List<Asset> getAssetList(AssetListParams params) {
    System.debug('params >> ' + params);
    List<Asset> assetList = new List<Asset>();

    if (params.actvTab == 'CatClass') {
      assetList = getFilteredAssetsCatClass(params);
    }
    //else if(params.actvTab == 'Serial' && String.isBlank(params.searchKey)) {
    //     assetList = [
    //         SELECT
    //         Id,
    //         Name,
    //         SM_PS_Serial_Number__c,
    //         SM_PS_Asset_Record_Type_Text__c,
    //         Product2.Name,
    //         Description,
    //         SM_PS_Due_Off_Rent_Date__c,
    //         Status,
    //         SM_PS_Current_Branch_Location_Number__c,
    //         SM_PS_Equipment_Type__c,
    //         SM_PS_Cat_Class__c,
    //         SM_PS_Equipment_Condition_Comment__c,
    //         Product2.Product_SKU__c,
    //         SM_PS_Model_Year__c
    //         FROM Asset WHERE SM_PS_Serial_Number__c LIKE :'%' + params.searchKey + '%'
    //         LIMIT 50
    //     ];
    // }
    /*else if (params.actvTab == 'Asset' && String.isEmpty(params.searchKey) && params.searchKey!='') {
            assetList = [
                SELECT
                Id,
                Name,
                SM_PS_Asset_Record_Type_Text__c,
                Product2.Name,
                Description,
                SM_PS_Due_Off_Rent_Date__c,
                Status,
                SM_PS_Current_Branch_Location_Number__c,
                SM_PS_Equipment_Type__c,
                SM_PS_Cat_Class__c,
                SM_PS_Cat_Class_Description__c,
                SM_PS_Equipment_Condition_Comment__c,
                Product2.Product_SKU__c,
                SM_PS_Model_Year__c
                FROM Asset
                LIMIT 50
            ];
        }*/ else if (
      params.actvTab == 'Asset' && String.isNotBlank(params.searchKey)
    ) {
      assetList = [
        SELECT
          Id,
          Name,
          SM_PS_Asset_Record_Type_Text__c,
          Product2.Name,
          Description,
          SM_PS_Cat_Class_Description__c, //FRONT-27342
          SM_PS_Due_Off_Rent_Date__c,
          Status,
          SM_PS_Current_Branch_Location_Number__c,
          SM_PS_Equipment_Type__c,
          SM_PS_Cat_Class__c,
          SM_PS_Equipment_Condition_Comment__c,
          Product2.Product_SKU__c,
          Product2.Product_Type__c,
          Product2.Bulk_Item__c,
          Product2.PPA_CatClass__c,
          SM_PS_Model_Year__c,
          SM_PS_MiHr_Old_meter__c, //Added for Front-31380
          SM_PS_Meter_Code_MIHR__c,
          SM_PS_Meter_2_Code__c,
          (SELECT SBQQ__Asset__c, Product2Id FROM SBQQ__OrderProducts__r WHERE OrderId = :params.contractId) // Added for FRONT-31106
        FROM Asset
        WHERE Name = :params.searchKey //+ '%'
        /*OR Product2.Name LIKE :'%' + params.searchKey + '%'*/ // Commented for FRONT-14464,19115
        LIMIT 50
      ];
    } else if (
      params.actvTab == 'Serial' && String.isNotBlank(params.searchKey)
    ) {
      assetList = [
        SELECT
          id,
          Name,
          SM_PS_Serial_Number__c,
          SM_PS_Asset_Record_Type_Text__c,
          Product2.Name,
          Description,
          SM_PS_Cat_Class_Description__c, //FRONT-31901
          SM_PS_Due_Off_Rent_Date__c,
          Status,
          SM_PS_Current_Branch_Location_Number__c,
          SM_PS_Equipment_Type__c,
          SM_PS_Cat_Class__c,
          SM_PS_Equipment_Condition_Comment__c,
          Product2.Product_SKU__c,
          SM_PS_Model_Year__c,
          (SELECT SBQQ__Asset__c, Product2Id FROM SBQQ__OrderProducts__r WHERE OrderId = :params.contractId)
        FROM Asset
        WHERE SM_PS_Serial_Number__c = :params.searchKey
        LIMIT 50
      ];
    }
    return assetList;
  }

  // FRONT-15699
  @AuraEnabled(cacheable=true)
  public static List<ProductItemWrapper> getProductItemList(
    ProductItemListParams params
  ) {
    List<ProductItemWrapper> wrapperList = new List<ProductItemWrapper>();
    System.debug('===getProductItemList==params=====' + params);
    if (
      (params.actvTab == 'Cat Class Description' ||
      params.actvTab == 'Cat Class') && String.isNotBlank(params.searchKey)
    ) {
      String loc = [
          SELECT Sourcing_Branch__r.Branch_Location_Number__c
          FROM Order
          WHERE Id = :params.contractId
          LIMIT 1
        ]
        ?.Sourcing_Branch__r
        ?.Branch_Location_Number__c;
      if (params.selectedLocationFilter == 'Current Branch') {
        Map<Id, ProductItem> productItemMap = getProductItemMap(params, loc);
        // END : FRONT-15699, FRONT-17146
        system.debug('productItemMap==' + productItemMap);
        Set<Id> productIdSet = new Set<Id>();
        Map<Id, List<OrderItem>> product2IdToOrderItemMap = new Map<Id, List<OrderItem>>();
        //get bulk productIds to get related Order Items records to update the button label on Cat Class Description Tab
        for (ProductItem prodItem : productItemMap.values()) {
          if (prodItem.Product2.Bulk_Item__c) {
            productIdSet.add(prodItem.Product2Id);
          }
        }

        for (OrderItem orderItem : [
          SELECT Product2Id, OrderId
          FROM OrderItem
          WHERE OrderId = :params.contractId AND Product2Id IN :productIdSet
        ]) {
          if (!product2IdToOrderItemMap.containsKey(orderItem.Product2Id)) {
            product2IdToOrderItemMap.put(
              orderItem.Product2Id,
              new List<OrderItem>()
            );
          }
          product2IdToOrderItemMap.get(orderItem.Product2Id).add(orderItem);
        }

        for (Id prodItem : productItemMap.keySet()) {
          ProductItemWrapper wrapObj = new ProductItemWrapper();
          wrapObj.productItem = productItemMap.get(prodItem);
          wrapObj.orderItems = product2IdToOrderItemMap.get(
            productItemMap.get(prodItem).Product2Id
          );
          wrapperList.add(wrapObj);
        }
        system.debug('wrapperList==' + wrapperList);
        return wrapperList;
      } else {
        return null;
      }
    } else {
      return null;
    }
  }

  public static Map<Id, ProductItem> getProductItemMap(
    ProductItemListParams params,
    String loc
  ) {
    Map<Id, ProductItem> productItemMap = new Map<Id, ProductItem>();
    // START : FRONT-17146
    if (
      String.isNotBlank(params.itemListSearchKey) &&
      params.actvTab == 'Cat Class Description'
    ) {
      productItemMap = new Map<Id, ProductItem>(
        [
          SELECT
            Product2.PPA_CatClass__c,
            Product2.Product_SKU__c,
            Product2.Bulk_Item__c,
            Product2.itemNumberUsedByReservationsRentalOut__c,
            ProductName,
            SM_PS_Quantity_Available__c,
            SM_PS_Quantity_Reserved__c,
            Location.Branch_Location_Number__c
          FROM ProductItem
          WHERE
            ProductName LIKE :'%' + params.searchKey + '%'
            AND (ProductName LIKE :'%' + params.itemListSearchKey + '%'
            OR Product2.PPA_CatClass__c LIKE :'%' +
            params.itemListSearchKey +
            '%')
            AND Location.Branch_Location_Number__c = :loc
          LIMIT :params.limitSize // FRONT-15699
          OFFSET :params.offset // FRONT-15699
        ]
      );
    }
    // START : FRONT-15699
    else if (
      String.isBlank(params.itemListSearchKey) &&
      params.actvTab == 'Cat Class Description'
    ) {
      productItemMap = new Map<Id, ProductItem>(
        [
          SELECT
            Product2.PPA_CatClass__c,
            Product2.Product_SKU__c,
            Product2.Bulk_Item__c,
            Product2.itemNumberUsedByReservationsRentalOut__c,
            ProductName,
            SM_PS_Quantity_Available__c,
            SM_PS_Quantity_Reserved__c,
            Location.Branch_Location_Number__c
          FROM ProductItem
          WHERE
            ProductName LIKE :'%' + params.searchKey + '%'
            AND Location.Branch_Location_Number__c = :loc
          LIMIT :params.limitSize // FRONT-15699
          OFFSET :params.offset // FRONT-15699
        ]
      );
    }
    //FRONT-19000
    else if (
      String.isBlank(params.itemListSearchKey) && params.actvTab == 'Cat Class'
    ) {
      productItemMap = new Map<Id, ProductItem>(
        [
          SELECT
            Product2.Name,
            Product2.PPA_CatClass__c,
            Product2.Product_SKU__c,
            Product2.Bulk_Item__c,
            Product2.itemNumberUsedByReservationsRentalOut__c,
            ProductName,
            SM_PS_Quantity_Available__c,
            SM_PS_Quantity_Reserved__c,
            Location.Branch_Location_Number__c,
            SM_PS_Cat_Class__c
          FROM ProductItem
          WHERE
            SM_PS_Cat_Class__c LIKE :'%' + params.searchKey + '%'
            AND Location.Branch_Location_Number__c = :loc
          LIMIT :params.limitSize
          OFFSET :params.offset
        ]
      );
    }
    return productItemMap;
  }

  /*
    *********************************************************
    @Method Name    :getProductItem
    @author         :Sarang Borlepwar
    @description    :calling this method on Sbr_3_0_contractLineItemsRentalsCmp LWC implemented as a part of FRONT-20221 
    ********************************************************
    */

  @AuraEnabled(cacheable=true)
  public static List<ProductItem> getProductItem(String bulkAssetname) {
    List<ProductItem> productItemList = new List<ProductItem>();
    Schema.Location locationObj;
    Schema.Location branchinputs = new Schema.Location();
    branchinputs = SBR_3_0_SpotlightPanelCmpController.getProfileBranchDetailsForContracts();
    productItemList = [
      SELECT
        Id,
        Product2.Name,
        Product2.Bulk_Item__c,
        Product2.itemNumberUsedByReservationsRentalOut__c,
        SM_PS_Cat_Class__c,
        Product2.Product_SKU__c,
        Product2.PPA_CatClass__c
      FROM ProductItem
      WHERE
        Product2.Bulk_Item__c = TRUE
        AND Product2.itemNumberUsedByReservationsRentalOut__c = :bulkAssetname
        AND Location.Branch_Location_Number__c = :branchinputs.Branch_Location_Number__c
        AND SM_PS_Quantity_Available__c > 0
    ];
    return productItemList;
  }

  @AuraEnabled(cacheable=true)
  public static Schema.Location getLoggedInUserBranchLocation() {
    Schema.Location branchinputs = new Schema.Location();
    branchinputs = SBR_3_0_SpotlightPanelCmpController.getProfileBranchDetailsForContracts();
    return branchinputs;
  }

  /*
    *********************************************************
    @Method Name    :getFilteredAssetsCatClass
    @author         :Karthick Chandru
    @description    :calling this method on sbr_3_0_itemSearchAssetsCatClassCmp LWC implemented as a part of FRONT-18981 and FRONT-18981
    @TestCoverage   :covered this method completely on SBR_3_0_AssetControllerTest.testGetFilteredAssetsCatClassRegion
    ********************************************************
    */
  @AuraEnabled(cacheable=true)
  public static List<Asset> getFilteredAssetsCatClass(AssetListParams params) {
    List<Asset> assetList = new List<asset>();
    Schema.Location locationObj;
    Schema.Location branchinputs = new Schema.Location();
    branchinputs = SBR_3_0_SpotlightPanelCmpController.getProfileBranchDetailsForContracts();
    String sQuery;
    String selectClause = '';
    String baseWhereClause = '';
    String fullWhereClause = '';
    String orderWhereClause = '';
    String offsetclass = '';
    system.debug('inputs' + params);
    if (String.isNotBlank(params.catClass)) {
      selectClause =
        'SELECT Id,Name,SM_PS_Asset_Record_Type_Text__c,SM_PS_Serial_Number__c,' +
        'Product2.Name,Description,SM_PS_Due_Off_Rent_Date__c,' +
        'SM_PS_Cat_Class_Description__c,' +
        'Status,SM_PS_Current_Branch_Location_Number__c,SM_PS_Last_Transaction_Date__c,SM_PS_Equipment_Type__c ,' +
        'SM_PS_Cat_Class__c ,' +
        'SM_PS_Equipment_Condition_Comment__c,Product2.Product_SKU__c,Product2.PPA_CatClass__c,SM_PS_Model_Year__c,SM_PS_MiHr_Old_meter__c,SM_PS_Meter_Code_MIHR__c,SM_PS_Meter_2_Code__c';
      if (String.isNotBlank(params.contractid)) {
        orderWhereClause =
          ', (SELECT SBQQ__Asset__c, Product2Id FROM SBQQ__OrderProducts__r WHERE OrderId =\'' +
          String.escapeSingleQuotes(params.contractid) +
          '\')';
      }
      string objectname = 'FROM Asset ';
      baseWhereClause =
        ' WHERE SM_PS_Cat_Class__c like ' +
        '\'%' +
        String.escapeSingleQuotes(params.catClass) +
        '%\' ';
      if (String.isNotBlank(params.selectedLocation)) {
        Map<string, string> mapLocationFilterFields = new Map<string, string>();
        mapLocationFilterFields.put(
          'All Region Branches',
          ' and SM_PS_Region__c = \'' + branchinputs.Region__c + '\' '
        );
        mapLocationFilterFields.put(
          'All District Branches',
          ' and  SM_PS_District__c = \'' + branchinputs.District__c + '\' '
        );
        mapLocationFilterFields.put(
          'All Market Branches',
          ' and  SM_PS_Market_Name__c = \'' +
            branchinputs.Market_Name__c +
            '\' '
        );
        mapLocationFilterFields.put('All Branches', '');
        mapLocationFilterFields.put(
          'Current Branch',
          ' and SM_PS_Current_Branch_Location_Number__c  = \'' +
            branchinputs.Branch_Location_Number__c +
            '\' '
        );
        fullWhereClause = mapLocationFilterFields.get(
          String.escapeSingleQuotes(params.selectedLocation)
        );
      }
      if (String.isNotBlank(params.year)) {
        fullWhereClause +=
          'and SM_PS_Model_Year__c like ' +
          '\'%' +
          String.escapeSingleQuotes(params.year) +
          '\' ';
      }
      if (String.isNotBlank(params.loc)) {
        fullWhereClause +=
          'and SM_PS_Current_Branch_Location_Number__c = \'' +
          String.escapeSingleQuotes(params.loc) +
          '\' ';
      }
      if (
        params.statusList != null &&
        params.statusList.size() > 0 &&
        !params.statusList.contains('Any Status')
      ) {
        String picklistvalues =
          '\'' +
          String.join(params.statusList, '\',\'') +
          '\'';
        fullWhereClause += ' and Status in  (' + picklistvalues + ')';
      }
      if (String.isNotBlank(params.searchKey)) {
        fullWhereClause +=
          'and SM_PS_Cat_Class_Description__c like ' +
          '\'%' +
          String.escapeSingleQuotes(params.searchKey) +
          '%\' ';
      }
      if (params.offset != null) {
        offsetclass = ' Limit 50 OFFSET ' + params.offset;
      }
      sQuery =
        selectClause +
        orderWhereClause +
        objectname +
        baseWhereClause +
        fullWhereClause +
        offsetclass;
      System.debug('sQuery>>>' + sQuery);
      assetlist = Database.query(sQuery);
    }
    return assetList;
  }
  //FRONT-19006
  @AuraEnabled
  public static void deleteOrderItem(String orderItemId) {
    SBR_3_0_ContractController.deleteContractLineItems(
      new List<orderItem>{ new OrderItem(Id = orderItemId) }
    );
  }

  public class ProductItemWrapper {
    @AuraEnabled
    public ProductItem productItem { get; set; }
    @AuraEnabled
    public List<OrderItem> orderItems { get; set; }
  }

  public class ProductItemListParams {
    @AuraEnabled
    public String searchKey { get; set; }
    @AuraEnabled
    public String actvTab { get; set; }
    @AuraEnabled
    public String selectedLocationFilter { get; set; }
    @AuraEnabled
    public String contractId { get; set; }
    // START : FRONT-15699
    @AuraEnabled
    public Integer limitSize { get; set; }
    @AuraEnabled
    public Integer offset { get; set; }
    // END : FRONT-15699
    // FRONT-17146
    @AuraEnabled
    public String itemListSearchKey { get; set; }
  }

  public class AssetListParams {
    @AuraEnabled
    public String searchKey { get; set; }
    @AuraEnabled
    public String actvTab { get; set; }
    @AuraEnabled
    public String year { get; set; }
    @AuraEnabled
    public String loc { get; set; }
    @AuraEnabled
    public List<String> statusList { get; set; }
    @auraEnabled
    public String selectedLocation { get; set; }
    @AuraEnabled
    public String catClass { get; set; }
    @AuraEnabled
    public Integer offset { get; set; }
    @AuraEnabled
    public String contractId { get; set; }
  }

  // Added for FRONT-31381
  @AuraEnabled(cacheable=true)
  public static Double getAvailableQty(String productId) {
    Double avlQty;
    String locId = getLoggedInUserBranchLocation()?.Id;
    ProductItem prodItem = [
      SELECT SM_PS_Quantity_Available__c, Product2Id, LocationId
      FROM ProductItem
      WHERE Product2Id = :productId AND LocationId = :locId
    ];
    avlQty = prodItem.SM_PS_Quantity_Available__c;
    return avlQty;
  }
}