/*********************************************************************************************************************
* Apex Class: SBR_3_0_CustomDataTableCmpController
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Controller class for loading data for sbr_3_0_customDataTableCmp LWC
* - SAL-1351
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Avinash Rao             2022-05-18          Initial version
    2.0         Harry Rokad             2022-06-21          Commented out the constructor *Apex PMD*
    3.0         Avinash Rao             2022-06-29          Adding search and filter capabilities get products
    4.0         Kaylee Gabus            2022-10-13          Adding search capabilities for order items
    5.0         Bhavesh Dhamecha        2023-03-14          SAL-16762 
    6.0         Shruti Gujarathi        2023-01-10          SAL-26801: On list view change, added additional search key as the list view name (super category).
    7.0         Sohail Azam		        2023-05-10          SAL-26864: Escaping special characters & | ! ( ) { } [ ] ^ " ~ * ? : \ ' + -, if used for search.
    8.0         Soomjeet Sahoo          2023-11-15          FRONT-10481
*********************************************************************************************************************/
public without sharing class SBR_3_0_CustomDataTableCmpController {
  // public SBR_3_0_CustomDataTableCmpController() {

  // }
  @AuraEnabled(cacheable=true)
  public static List<CustomDataTableCmpColumn__mdt> getItemSearchColumns() {
    try {
      return CustomDataTableCmpColumn__mdt.getAll().values();
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  // The method now uses SOSL query to fetch filtered products.  SAL-26601
  // There may be updates needed based on Product_type__c filtering based on user feedback
  @AuraEnabled(cacheable=true)
  public static List<Product2> getFilteredProducts(
    Integer offset,
    String queryParams,
    Integer batchSize,
    String searchKey,
    String whereClause
  ) {
    try {
      String searchableFields = 'Product_SKU__c, Search_Word__c, Item_Number__c';
      String sWildCardText = '%' + String.escapeSingleQuotes(searchKey) + '%';
      String catClass =
        '%' +
        String.escapeSingleQuotes(searchKey.replace('-', '')) +
        '%';

      String baseWhereClause = ' WHERE Show_on_PI__c = true ';
      String orderByClause = ' ORDER BY Product_Category_Txt__c ASC, Class__c ASC'; //SAL-26801
      String limitClause = ' LIMIT ' + batchSize;
      String offsetClause = ' OFFSET ' + offset;
      List<Product2> filteredProducts = new List<Product2>();
      List<List<sObject>> listOfResults = new List<List<sObject>>();
      String strKey;
      String listViewName;

      System.debug('whereClause-->' + whereClause);

      //SAL-26801 Get the super category name
      if (
        whereClause != null &&
        whereClause.startsWith(' AND Filter_Level_1__c = ')
      ) {
        listViewName = whereClause.replaceAll(' AND Filter_Level_1__c = ', '');
        listViewName = listViewName.split(' AND ')[0];
        listViewName = listViewName.substring(1, listViewName.length() - 1);
        listViewName = String.escapeSingleQuotes(listViewName);
        //Commented line below, Duplicate replacement of \\-
        //listViewName = listViewName.replaceAll('[\\-]','\\\\-');
        listViewName = listViewName.replaceAll(
          '([\\&|!(){}\\[\\]^"~*?:\\\\\'+\\-])',
          '\\\\$1'
        );
      }
      System.debug('listViewName > ' + listViewName);

      if (String.isNotBlank(searchKey)) {
        searchKey = String.escapeSingleQuotes(searchKey);
        //SF-8096 Commented line below, Duplicate replacement of \\-
        //searchKey = searchKey.replaceAll('[\\-]','\\\\-');
        searchKey = searchKey.replaceAll(
          '([\\&|!(){}\\[\\]^"~*?:\\\\\'+\\-])',
          '\\\\$1'
        );

        strKey = searchKey + '*';
      } else {
        // When default list view is searched, we need some search term and hence using cat ( to match cat-class products )

        if (String.isBlank(listViewName))
          strKey = 'cat\\-class';
        else
          strKey = listViewName; //SAL-26801 pass the super cat name to the SOSL search string
      }

      String soslQuery =
        baseWhereClause +
        whereClause +
        orderByClause +
        limitClause +
        offsetClause;
      String soslQueryStr =
        'FIND {' +
        strKey +
        '} IN ALL FIELDS Returning Product2(Id, Product_SKU__c, Name, Primary_Image_URL__c, Product_Type__c, Product_Category__c, Product_Sub_Category__c, Product_Category_Txt__c, Product_Sub_Category_Txt__c, Is_Kit__c, Changeable__c, Salesforce_Managed_Kit__c, Item_Number__c, Stock_class__c, Inventoried_Item__c, Miscellaneous_Charge_Item__c, Type_of_Misc_Charge_Item__c, User_Selectable_for_Quote__c ' +
        soslQuery +
        ' )';

      System.debug(sWildCardText + ' << soslQueryStr >> ' + soslQueryStr);

      listOfResults = search.query(soslQueryStr);
      filteredProducts = listOfResults[0];
      return filteredProducts;
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  @AuraEnabled(cacheable=true)
  public static List<Product2> getFilteredProductsForAssetInquiry(
    Integer offset,
    String queryParams,
    Integer batchSize,
    String searchKey,
    String whereClause
  ) {
    try {
      String searchableFields = 'Product_SKU__c, Search_Word__c, Item_Number__c';
      String sWildCardText = '%' + String.escapeSingleQuotes(searchKey) + '%';
      String sQuery;
      String selectClause = '';
      String selectFields = '';
      String baseWhereClause = '';
      String fullWhereClause = '';
      //String orderByClause = ' ORDER BY CreatedDate DESC';
      String limitClause = ' LIMIT ' + batchSize;
      String offsetClause = ' OFFSET ' + offset;

      if (String.isNotBlank(searchableFields)) {
        List<String> stringArray = searchableFields.split(',');
        for (String s : stringArray) {
          fullWhereClause += ' OR ' + s + ' LIKE: sWildCardText';
          //selectFields += ', ' + s;
        }
      }
      System.debug('Main whereClause: ' + whereClause);
      if (String.isNotBlank(whereClause)) {
        fullWhereClause += ')' + whereClause;
      } else {
        fullWhereClause += ')';
      }

      selectClause = 'SELECT Id, Product_SKU__c, Name, Primary_Image_URL__c, Product_Category__c, Product_Sub_Category__c, Product_Sub_Category_Txt__c FROM Product2';
      baseWhereClause = ' WHERE Status__c = \'A\' AND (Name LIKE: sWildCardText';

      // if(String.isNotBlank(whereClause)) {
      //     fullWhereClause = fullWhereClause + ' AND ' + whereClause;
      // }

      sQuery =
        selectClause +
        baseWhereClause +
        fullWhereClause +
        limitClause +
        offsetClause;

      List<Product2> filteredProducts = new List<Product2>();
      for (Product2 p : Database.query(sQuery)) {
        filteredProducts.add(p);
      }
      return filteredProducts;
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  @AuraEnabled(cacheable=true)
  public static List<Asset> getFilteredAssets(
    Integer offset,
    Integer batchSize,
    String searchKey,
    String whereClause
  ) {
    try {
      String searchableFields = 'SM_PS_Cat_Class__c, Name, Status, RecordType.Name';
      String sWildCardText = '%' + String.escapeSingleQuotes(searchKey) + '%';
      String sQuery;
      String selectClause = '';
      String baseWhereClause = '';
      String fullWhereClause = '';
      String limitClause = '';
      String offsetClause = '';

      if (batchSize != null) {
        limitClause = ' LIMIT ' + batchSize;
      }
      if (offset != null && offset >= 0) {
        offsetClause = ' OFFSET ' + offset;
      }

      if (String.isNotBlank(searchKey)) {
        if (String.isNotBlank(searchableFields)) {
          List<String> stringArray = searchableFields.split(',');
          boolean isFirst = true;
          for (String s : stringArray) {
            if (isFirst) {
              fullWhereClause += '(' + s + ' LIKE: sWildCardText';
              isFirst = false;
            } else {
              fullWhereClause += ' OR ' + s + ' LIKE: sWildCardText';
            }
          }
        }

        if (String.isNotBlank(whereClause)) {
          fullWhereClause += ') AND ' + whereClause;
        } else {
          fullWhereClause += ')';
        }
      } else {
        fullWhereClause += whereClause;
      }

      System.debug('fu*llWhereClause :' + fullWhereClause);
      selectClause =
        'SELECT Id, SM_PS_Cat_Class__c, SM_PS_Equipment_Number__c,' +
        'SM_PS_Assigned_Location__r.Branch_Location_Number__c,' +
        'Name, Description,SM_PS_Last_Transaction_Date__c,SM_PS_Current_Location__r.Branch_Location_Number__c,' +
        'Product2.Name ,RecordTypeId, RecordType.Name, Status, SM_PS_Miscellaneous_Options__c,' +
        'SM_PS_Make__c, SM_PS_Model__c, SM_PS_Serial_Number__c, SM_PS_Model_Year__c, ' +
        'A360SPARK_TotalOperatingHours__c, Quantity, SBQQ__OriginalUnitCost__c, SM_PS_Book_Value__c, SM_PS_Sell_Price__c,' +
        'SM_PS_Cat_Class_Description__c,Product2.Product_SKU__c, SM_PS_Last_Transaction_Invoice_Number__c,' +
        'Product2.Product_Type__c, Product2.Product_Category__c, Product2.Product_Sub_Category__c, Product2.Is_Kit__c, Product2.Changeable__c FROM Asset';
      //FRONT-10327 - added a check so that if fullWhereClause is blank then WHERE keyword is not required
      baseWhereClause = String.isNotBlank(fullWhereClause) ? ' WHERE ' : ' ';

      sQuery =
        selectClause +
        baseWhereClause +
        fullWhereClause +
        limitClause +
        offsetClause;
      System.debug('sQuery' + sQuery);
      List<Asset> filteredAssets = new List<Asset>();
      for (Asset a : Database.query(sQuery)) {
        filteredAssets.add(a);
      }
      return filteredAssets;
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  @AuraEnabled(cacheable=true)
  public static List<Product_Hierarchy__c> getProductSuperCategories() {
    try {
      //            List<Product_Hierarchy__c> categoryOptions = [SELECT Id, Name from Product_Hierarchy__c WHERE RecordType.Name = 'Super Category' AND Product_Family_Type__c = 'Cat-Class'];
      List<Product_Hierarchy__c> categoryOptions = SBR_3_0_ProductDA.getProductCategoryOptions(
        1,
        null,
        null,
        false,
        true
      );

      //List<Product_Hierarchy__c> categoryOptions = [SELECT Id, Name from Product_Hierarchy__c WHERE Filter_Level__c = '1' AND Product_Family_Type__c = 'Cat-Class'];

      return removeDuplicateCategories(categoryOptions);
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  @AuraEnabled(cacheable=true)
  public static List<Category_Details> getProductCategories(
    String superCategory
  ) {
    try {
      List<Product_Hierarchy__c> categoryOptions;
      Map<String, Category_Details> categoryMap = new Map<String, Category_Details>();
      Set<Id> categoryIDs = new Set<Id>();
      List<Product_Hierarchy__c> subCategoryOptions;

      if (String.isBlank(superCategory) || superCategory == 'All Items') {
        categoryOptions = SBR_3_0_ProductDA.getProductCategoryOptions(
          2,
          null,
          null,
          false,
          true
        );

        //categoryOptions = [SELECT Id, Name, Parent_Code__r.Name from Product_Hierarchy__c
        //                    WHERE RecordType.Name = 'Product Category' AND Product_Family_Type__c = 'Cat-Class' ORDER BY Name];
        //WHERE Filter_Level__c = '2' AND Product_Family_Type__c = 'Cat-Class' ORDER BY Name];
      } else {
        categoryOptions = SBR_3_0_ProductDA.getProductCategoryOptions(
          2,
          superCategory,
          null,
          false,
          true
        );

        //categoryOptions = [SELECT Id, Name, Parent_Code__r.Name from Product_Hierarchy__c
        //                    WHERE RecordType.Name = 'Product Category' AND Product_Family_Type__c = 'Cat-Class' AND Parent_Code__r.Name =: superCategory ORDER BY Name];
        //WHERE Filter_Level__c = '2' AND Product_Family_Type__c = 'Cat-Class' AND Parent_Code__r.Name =: superCategory ORDER BY Name];
      }

      //categoryOptions = removeDuplicateCategories(categoryOptions); //commented as part of SAL-26801
      for (Product_Hierarchy__c opt : categoryOptions) {
        categoryIDs.add(opt.Id);
        categoryMap.put(opt.Id, new Category_Details(opt)); // SAL-26801 updated key from Name to Id
      }

      subCategoryOptions = SBR_3_0_ProductDA.getProductCategoryOptions(
        null,
        null,
        categoryIDs,
        true,
        true
      );

      //subCategoryOptions = [SELECT Id, Name, Parent_Code__r.Name from Product_Hierarchy__c
      //    WHERE RecordType.Name = 'Product Sub-Category' AND Product_Family_Type__c = 'Cat-Class' AND Parent_Code__c IN :categoryIDs ORDER BY Name];

      //subCategoryOptions = removeDuplicateCategories(subCategoryOptions);  //commented as part of SAL-26801
      for (Product_Hierarchy__c opt : subCategoryOptions) {
        if (
          opt.Parent_Code__c != null &&
          categoryMap.containsKey(opt.Parent_Code__c)
        ) {
          categoryMap.get(opt.Parent_Code__c).subCategories.add(opt);
          categoryMap.get(opt.Parent_Code__c).hasSubCategory = true;
        }
      }

      return categoryMap.values();
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  public static List<Product_Hierarchy__c> removeDuplicateCategories(
    List<Product_Hierarchy__c> categoryOptions
  ) {
    Map<String, Product_Hierarchy__c> categoryMap = new Map<String, Product_Hierarchy__c>();

    for (Product_Hierarchy__c opt : categoryOptions) {
      categoryMap.put(opt.name, opt);
    }

    return categoryMap.values();
  }

  @AuraEnabled(Cacheable=true)
  public static List<String> getOrderItemStatusOptions() {
    List<String> activeOptions = new List<String>();
    List<PicklistEntry> picklistOptions = Asset.Status.getDescribe()
      .getPicklistValues();

    for (PicklistEntry option : picklistOptions) {
      if (option.isActive()) {
        activeOptions.add(option.getValue());
      }
    }

    return activeOptions;
  }

  @AuraEnabled(Cacheable=false)
  public static List<OrderItem> getFilteredOrderItems(
    String orderId,
    Integer offset,
    Integer batchSize,
    String searchKey,
    String whereClause
  ) {
    try {
      String searchableFields = 'Item_Name__c, SBQQ__Asset__r.SM_PS_Asset_Id__c,Product2.Name';

      String sWildCardText = '%' + String.escapeSingleQuotes(searchKey) + '%';
      sWildCardText = sWildCardText.replace('\\\'', '\'');
      String sQuery;
      String selectClause = '';
      String baseWhereClause = '';
      String fullWhereClause = '';
      String limitClause = ' LIMIT ' + batchSize;
      String offsetClause = ' OFFSET ' + offset;
      String productTypeFilter = 'Cat-Class';

      if (String.isNotBlank(searchKey)) {
        fullWhereClause = 'AND (Product_SKU__c LIKE: sWildCardText';
        if (String.isNotBlank(searchableFields)) {
          List<String> stringArray = searchableFields.split(',');
          for (String s : stringArray) {
            fullWhereClause += ' OR ' + s + ' LIKE: sWildCardText';
          }
        }

        fullWhereClause += ')';
      }

      if (String.isNotBlank(whereClause)) {
        fullWhereClause += whereClause;
      }

      //Contract_Number__c, Reservation_Number__c, 13808- Pickup_Ticket_Request_By__c , SAL-16762 - Product2.Bulk_Item__c,Product2.itemNumberUsedByReservationsRentalOut__c
      //25058 Order_Item_Detail__r.Quantity__c
      // Added Status_Created_Qty__c,Status_Pick_Created_Qty__c for SAL-23569
      selectClause =
        'SELECT Id, Item_Name__c, Quantity__c, Quantity, Product2.Name, Product2.Product_SKU__c, SBQQ__Asset__r.Name, Status_Created_Qty__c,Status_Pick_Created_Qty__c, ' +
        'SBQQ__Asset__r.SM_PS_Make__c, SBQQ__Asset__r.SM_PS_Model__c, SBQQ__Asset__r.SM_PS_Serial_Number__c, SBQQ__Asset__r.SM_PS_Model_Year__c, ' +
        'SBQQ__Asset__r.SM_PS_Asset_Id__c, SBQQ__Asset__r.Status, Status__c, Order.Jobsite__r.JobsiteName__c, ' +
        'Order.ContractId, Order.Branch_Email__c, SBQQ__Contract__r.ContractNumber, ' +
        'Order_Item_Detail__r.Pickup_Ticket__c, Order_Item_Detail__r.Pickup_Ticket_Request_By__c, Order_Item_Detail__r.Quantity__c,Order_Item_Detail__r.Created_Qty__c,' +
        'Order_Item_Detail__r.Pickup_Requested_Date__c, Order_Item_Detail__r.Service_Requested_Date__c, ' +
        'Order_Item_Detail__r.Service_Ticket_Contact__c, Order_Item_Detail__r.Order_Item_Comments__c, Order.Branch__r.Branch_Email__c,Product2.IsSerialized,Product2.Bulk_Item__c,Product2.itemNumberUsedByReservationsRentalOut__c, toLabel(SBQQ__Asset__r.Status) statusLabel FROM OrderItem';
      baseWhereClause = ' WHERE OrderId =: orderId AND Product2.Product_Type__c =: productTypeFilter AND is_Asset_Item_Hidden__c = false';

      if (batchSize == null && offset == null) {
        Integer remainingRows = (Limits.getLimitQueryRows() -
        Limits.getQueryRows());

        limitClause = ' LIMIT ' + remainingRows;
        sQuery = selectClause + baseWhereClause + fullWhereClause + limitClause;
      } else {
        sQuery =
          selectClause +
          baseWhereClause +
          fullWhereClause +
          limitClause +
          offsetClause;
      }
      System.debug('Print get filtered order items query ' + sQuery);
      List<OrderItem> filteredOrderItems = new List<OrderItem>();
      for (OrderItem oi : Database.query(sQuery)) {
        filteredOrderItems.add(oi);
        System.debug(oi);
      }

      return filteredOrderItems;
    } catch (Exception e) {
      System.debug(
        'CustomDataTableCmpController.getFilteredOrderItems error: ' + e
      );

      throw new AuraHandledException(e.getMessage());
    }
  }

  // checks if the catClass respects the format XXX-XXXX
  private static Boolean isFormattedCatClass(String catClass) {
    String catClassRegex = '^\\d{3}-\\d{4}$';
    Pattern pattern = Pattern.compile(catClassRegex);
    Matcher matcher = pattern.matcher(catClass);
    return matcher.matches();
  }

  public class Category_Details {
    @AuraEnabled
    public String Id { get; set; }
    @AuraEnabled
    public String Name { get; set; }
    @AuraEnabled
    public String Parent { get; set; }
    @AuraEnabled
    public Boolean hasSubCategory { get; set; }
    @AuraEnabled
    public List<Product_Hierarchy__c> subCategories { get; set; }

    public Category_Details(Product_Hierarchy__c cat) {
      this.Id = cat.Id;
      this.Name = cat.Name;
      this.Parent = cat.Parent_Code__r.Name;
      this.hasSubCategory = false;
      this.subCategories = new List<Product_Hierarchy__c>();
    }
  }

  @AuraEnabled(cacheable=true)
  public static List<Product2> getFilteredProductsFL(
    Integer offset,
    String queryParams,
    Integer batchSize,
    String searchKey,
    String whereClause,
    Boolean isCatClass
  ) {
    //FRONT-11313
    try {
      //String searchableFields = 'Product_SKU__c, Search_Word__c, Item_Number__c'; // FRONT-11313
      String sWildCardText = '%' + String.escapeSingleQuotes(searchKey) + '%';
      String sQuery;
      String selectClause = '';
      String selectFields = '';
      String baseWhereClause = '';
      String fullWhereClause = '';
      //String orderByClause = ' ORDER BY CreatedDate DESC';
      String limitClause = ' LIMIT ' + batchSize;
      String offsetClause = ' OFFSET ' + offset;

      //FRONT-11313
      // if (String.isNotBlank(searchableFields)) {
      //     List<String> stringArray = searchableFields.split(',');
      //     for (String s : stringArray) {
      //         fullWhereClause += ' OR ' + s + ' LIKE: sWildCardText';
      //         // selectFields += ', ' + s;
      //     }
      // }
      //FRONT-11313 start
      if (isCatClass) {
        fullWhereClause += 'Product_SKU__c LIKE: sWildCardText';
      } else {
        fullWhereClause += 'Name LIKE: sWildCardText';
      }
      //FRONT-11313 end

      if (String.isNotBlank(whereClause)) {
        fullWhereClause += ')' + whereClause;
      } else {
        fullWhereClause += ')';
      }

      selectClause = 'SELECT Id, Product_SKU__c, Name, Primary_Image_URL__c, Product_Type__c, Product_Category__c, Product_Sub_Category__c, Is_Kit__c, Changeable__c, Item_Number__c, Stock_class__c FROM Product2';
      //baseWhereClause = ' WHERE Show_on_PI__c = true AND (Name LIKE: sWildCardText'; //FRONT-11313
      baseWhereClause = ' WHERE Show_on_PI__c = true AND ('; //FRONT-11313

      // if(String.isNotBlank(whereClause)) {
      //     fullWhereClause = fullWhereClause + ' AND ' + whereClause;
      // }

      sQuery =
        selectClause +
        baseWhereClause +
        fullWhereClause +
        limitClause +
        offsetClause;
      List<Product2> filteredProducts = Database.query(sQuery);
      // List<Product2> filteredProducts = new List<Product2>();
      System.debug('sQuery-->' + sQuery);

      /* for(Product2 p : Database.query(sQuery)){
filteredProducts.add(p);
}
System.debug('filteredProducts-->'+filteredProducts.size());*/
      return filteredProducts;
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  @AuraEnabled(cacheable=true)
  public static OtherLocationWrapper getFilteredAssetsOtherLocations(
    Integer sourcingBranchOffset,
    Integer otherBranchOffset,
    Integer batchSize,
    String searchKey,
    String whereClause,
    Boolean isInitialLoad,
    String locationInfo
  ) {
    try {
      Schema.Location locationObj;
      OtherLocationWrapper wrapperObj = new OtherLocationWrapper();
      if (String.isNotBlank(locationInfo)) {
        locationObj = (Schema.Location) JSON.deserialize(
          locationInfo,
          Schema.Location.class
        );
      }
      String searchableFields = 'SM_PS_Cat_Class__c, Name, Status, RecordType.Name';
      String sWildCardText = '%' + String.escapeSingleQuotes(searchKey) + '%';
      String sQuery;
      String selectClause = '';
      String baseWhereClause = '';
      String fullWhereClause = '';
      String limitClause = '';
      String offsetClause1 = '';
      String offsetClause2 = '';
      Integer tempSourcingBranchOffset = 0;
      Integer tempOtherBranchOffset = 0;

      if (batchSize != null) {
        limitClause = ' LIMIT ' + batchSize;
      }
      if (sourcingBranchOffset != null && sourcingBranchOffset >= 0) {
        offsetClause1 = ' OFFSET ' + sourcingBranchOffset;
      }
      if (otherBranchOffset != null && otherBranchOffset >= 0) {
        offsetClause2 = ' OFFSET ' + otherBranchOffset;
      }

      if (String.isNotBlank(searchKey)) {
        if (String.isNotBlank(searchableFields)) {
          List<String> stringArray = searchableFields.split(',');
          boolean isFirst = true;
          for (String s : stringArray) {
            if (isFirst) {
              fullWhereClause += '(' + s + ' LIKE: sWildCardText';
              isFirst = false;
            } else {
              fullWhereClause += ' OR ' + s + ' LIKE: sWildCardText';
            }
          }
          fullWhereClause += ') ';
        }
      }

      selectClause =
        'SELECT Id, SM_PS_Cat_Class__c, SM_PS_Equipment_Number__c,' +
        'SM_PS_Assigned_Location__r.Branch_Location_Number__c,' +
        'Name, Description,SM_PS_Last_Transaction_Date__c,SM_PS_Current_Location__r.Branch_Location_Number__c,' +
        'Product2.Name ,RecordTypeId, RecordType.Name, Status, SM_PS_Miscellaneous_Options__c,' +
        'SM_PS_Make__c, SM_PS_Model__c, SM_PS_Serial_Number__c, SM_PS_Model_Year__c, ' +
        'A360SPARK_TotalOperatingHours__c, Quantity, SBQQ__OriginalUnitCost__c, SM_PS_Book_Value__c, SM_PS_Sell_Price__c,' +
        'SM_PS_Cat_Class_Description__c,Product2.Product_SKU__c, SM_PS_Last_Transaction_Invoice_Number__c,' +
        'Product2.Product_Type__c, Product2.Product_Category__c, Product2.Product_Sub_Category__c, Product2.Is_Kit__c, Product2.Changeable__c FROM Asset';
      baseWhereClause = ' WHERE ';
      String sourcingBranchWhereClause = '';
      if (String.isNotBlank(locationInfo)) {
        sourcingBranchWhereClause =
          ' AND SM_PS_Current_Branch_Location_Number__c = \'' +
          locationObj?.Branch_Location_Number__c +
          '\' ';
      }
      String finalSourcingLocationClause =
        whereClause + sourcingBranchWhereClause;
      sQuery =
        selectClause +
        baseWhereClause +
        fullWhereClause +
        (String.isNotBlank(fullWhereClause)
          ? ' AND ' + finalSourcingLocationClause
          : finalSourcingLocationClause) +
        limitClause +
        offsetClause1;
      System.debug('sQuerySourcingLoaction>>>' + sQuery);
      List<Asset> filteredAssets = (List<Asset>) Database.query(sQuery);
      if (!filteredAssets.isEmpty() && isInitialLoad) {
        tempSourcingBranchOffset = filteredAssets.size();
      } else {
        tempSourcingBranchOffset = sourcingBranchOffset + 50;
      }

      if (filteredAssets.size() < 50) {
        String otherBranchWhereClause = '';
        if (String.isNotBlank(locationInfo)) {
          otherBranchWhereClause =
            ' AND (SM_PS_Region__c = \'' +
            locationObj?.Region__c +
            '\' ';
          otherBranchWhereClause +=
            ' OR SM_PS_District__c = \'' +
            locationObj?.District__c +
            '\' ';
          otherBranchWhereClause +=
            ' OR SM_PS_Market_Name__c = \'' +
            locationObj?.Market_Name__c +
            '\') ';
        }
        String finalOtherLocationClause = whereClause + otherBranchWhereClause;
        limitClause = ' LIMIT ' + (batchSize - filteredAssets.size());

        sQuery =
          selectClause +
          baseWhereClause +
          fullWhereClause +
          (String.isNotBlank(fullWhereClause)
            ? ' AND ' + finalOtherLocationClause
            : finalOtherLocationClause) +
          limitClause +
          offsetClause2;
        System.debug('sQueryOtherLocation>>>' + sQuery);
        List<Asset> otherAssets = (List<Asset>) Database.query(sQuery);
        if (!otherAssets.isEmpty() && isInitialLoad) {
          tempOtherBranchOffset = otherAssets.size();
        } else {
          tempOtherBranchOffset = filteredAssets.size() == 0
            ? (otherBranchOffset + 50)
            : (batchSize - filteredAssets.size());
        }
        filteredAssets.addAll(otherAssets);
      }
      wrapperObj.sourcingBranchOffset = tempSourcingBranchOffset != null
        ? tempSourcingBranchOffset
        : 0;
      wrapperObj.otherBranchOffset = tempOtherBranchOffset != null
        ? tempOtherBranchOffset
        : 0;
      wrapperObj.assetList = filteredAssets;
      system.debug('wrapperObj>>>' + wrapperObj);
      return wrapperObj;
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  public class OtherLocationWrapper {
    @AuraEnabled
    public Integer sourcingBranchOffset { get; set; }
    @AuraEnabled
    public Integer otherBranchOffset { get; set; }
    @AuraEnabled
    public List<Asset> assetList { get; set; }
  }

  /* FRONT-10481 : Fetching ProductItems for Sales product Inquiry search*/
  @AuraEnabled(cacheable=true)
  public static List<ProductItem> getAllProductItemsForSalesProductInquiry() {
    String partsAndMerchRecTypeDevName = SBR_3_0_Constants.PRODUCTITEM_PARTS_AND_MERCH_RECORDTYPE_DEVELOPERNAME;
    List<ProductItem> allProductItemsToBeReturned = new List<ProductItem>();

    try {
      String productItemsQuery =
        'SELECT ' +
        getAllFieldsFromFS(
          SBR_3_0_Constants.PRODUCTITEM_FIELDSET_FOR_SALES_SEARCH_DEVELOPERNAME,
          SBR_3_0_Constants.PRODUCT_ITEM_API_NAME
        ) +
        ' FROM ' +
        SBR_3_0_Constants.PRODUCT_ITEM_API_NAME +
        ' WHERE RecordType.DeveloperName =: partsAndMerchRecTypeDevName LIMIT 60';

      allProductItemsToBeReturned = Database.query(
        String.escapeSingleQuotes(productItemsQuery)
      );
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
    return allProductItemsToBeReturned;
  }

  private static String getAllFieldsFromFS(String fSName, String objName) {
    String commaSeparatedFieldApiNames = '';
    for (
      Schema.FieldSetMember fsMem : getFSetMembersFromFSName(fSName, objName)
    ) {
      commaSeparatedFieldApiNames =
        commaSeparatedFieldApiNames +
        fsMem.getFieldPath() +
        ',';
    }
    return commaSeparatedFieldApiNames.removeEnd(',');
  }

  private static List<Schema.FieldSetMember> getFSetMembersFromFSName(
    String fSName,
    String objName
  ) {
    List<Schema.FieldSetMember> opFSMs = new List<Schema.FieldSetMember>();
    if (!String.isBlank(fSName) && !String.isBlank(objName)) {
      Map<String, Schema.SObjectType> describeMapGlobal = Schema.getGlobalDescribe();
      Schema.SObjectType typeObj = describeMapGlobal.get(objName);
      Schema.DescribeSObjectResult describeSobjectRes = typeObj.getDescribe();
      Schema.FieldSet fieldSetObj = describeSobjectRes.FieldSets.getMap()
        .get(fSName);
      opFSMs = fieldSetObj.getFields();
    }
    return opFSMs;
  }
  /* END : FRONT-10481*/

  /* FRONT-11319 : Fetching Asset Details */
  @AuraEnabled(Cacheable=false)
  public static Asset_Details getAssetDetails(String assetId) {
    system.debug('assetId=' + assetId);
    Asset_Details assetDeatilsObj = new Asset_Details();
    Asset assObj = [
      SELECT
        id,
        SM_PS_Cat_Class__c,
        Status,
        Name,
        SM_PS_Equipment_Number__c,
        SM_PS_Make__c,
        SM_PS_Model__c,
        SM_PS_Serial_Number__c,
        SM_PS_Model_Year__c,
        SM_PS_Current_MiHr__c,
        Quantity,
        SM_PS_Original_Cost__c,
        SM_PS_Book_Value__c,
        SM_PS_Sell_Price__c,
        SM_PS_Cat_Class_Description__c,
        Description,
        SM_PS_Last_Transaction_Invoice_Number__c,
        Product2.Product_SKU__c,
        Product2.name,
        SM_PS_Miscellaneous_Options__c
      FROM asset
      WHERE id = :assetId
    ];
    assetDeatilsObj.catClass = assObj.SM_PS_Cat_Class__c;
    assetDeatilsObj.Status = assObj.Status;
    assetDeatilsObj.assetNumber = assObj.SM_PS_Equipment_Number__c;
    assetDeatilsObj.make = assObj.SM_PS_Make__c;
    assetDeatilsObj.model = assObj.SM_PS_Model__c;
    assetDeatilsObj.serial = assObj.SM_PS_Serial_Number__c;
    assetDeatilsObj.year = assObj.SM_PS_Model_Year__c;
    assetDeatilsObj.prodname = assObj.Product2.name;
    assetDeatilsObj.hours = String.valueOf(assObj.SM_PS_Current_MiHr__c);
    assetDeatilsObj.qty = String.valueOf(assObj.Quantity);
    assetDeatilsObj.originalCost = String.valueOf(
      assObj.SM_PS_Original_Cost__c
    );
    assetDeatilsObj.bookValue = String.valueOf(assObj.SM_PS_Book_Value__c);
    assetDeatilsObj.sellPrice = String.valueOf(assObj.SM_PS_Sell_Price__c);
    assetDeatilsObj.description = assObj.SM_PS_Miscellaneous_Options__c;
    if (assObj.SM_PS_Last_Transaction_Invoice_Number__c != null) {
      system.debug('assObj=' + assObj.SM_PS_Last_Transaction_Invoice_Number__c);
      List<Order> contractOrderLst = new List<Order>();
      contractOrderLst = [
        SELECT
          id,
          Job_Location__c,
          Contract_Order_Number__c,
          Name,
          Account.Name,
          Jobsite__c,
          Jobsite__r.Name__c,
          Sales_Rep__r.Name,
          Order_By__r.Name,
          Branch__c
        FROM Order
        WHERE
          Contract_Order_Number__c = :assObj.SM_PS_Last_Transaction_Invoice_Number__c
          AND RecordType.Name = 'Contract Order'
        ORDER BY Createddate DESC
      ];
      if (!contractOrderLst.isEmpty() && contractOrderLst.size() > 0) {
        system.debug(
          'contractOrderLst=' + contractOrderLst[0].Contract_Order_Number__c
        );
        assetDeatilsObj.contractOrderNumber = contractOrderLst[0]
          .Contract_Order_Number__c;
        assetDeatilsObj.customerName = contractOrderLst[0].Account.Name;
        assetDeatilsObj.jobSiteRecord = contractOrderLst[0].Jobsite__r.Name__c;
        assetDeatilsObj.jobSiteAddress = contractOrderLst[0].Job_Location__c;
        assetDeatilsObj.salesRep = contractOrderLst[0].Sales_Rep__r.Name;
        assetDeatilsObj.orderBy = contractOrderLst[0].Order_By__r.Name;
        assetDeatilsObj.branch604 = contractOrderLst[0].Branch__c;
        //assetDeatilsObj.totalBilled = contractOrderLst[0].SM_PS_Book_Value__c;
      }
    }
    system.debug('assetDeatilsObj' + assetDeatilsObj);
    return assetDeatilsObj;
  }

  public class Asset_Details {
    @AuraEnabled
    public String catClass { get; set; }
    @AuraEnabled
    public String Status { get; set; }
    @AuraEnabled
    public String assetNumber { get; set; }
    @AuraEnabled
    public String make { get; set; }
    @AuraEnabled
    public String model { get; set; }
    @AuraEnabled
    public String serial { get; set; }
    @AuraEnabled
    public String year { get; set; }
    @AuraEnabled
    public String hours { get; set; }
    @AuraEnabled
    public String qty { get; set; }
    @AuraEnabled
    public String originalCost { get; set; }
    @AuraEnabled
    public String bookValue { get; set; }
    @AuraEnabled
    public String sellPrice { get; set; }
    @AuraEnabled
    public String description { get; set; }
    @AuraEnabled
    public String contractOrderNumber { get; set; }
    @AuraEnabled
    public String customerName { get; set; }
    @AuraEnabled
    public String jobSiteRecord { get; set; }
    @AuraEnabled
    public String jobSiteAddress { get; set; }
    @AuraEnabled
    public String salesRep { get; set; }
    @AuraEnabled
    public String orderBy { get; set; }
    @AuraEnabled
    public String branch604 { get; set; }
    @AuraEnabled
    public String totalBilled { get; set; }
    @AuraEnabled
    public String prodname { get; set; }
  }
  /* END : FRONT-11319*/
}