/**
 * @description       :
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             :
 * @last modified on  : 07-04-2023
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
 **/
public with sharing class SBR_3_0_ProductDA implements SBR_3_0_ProductDAI {
  /**
   * @description
   * @param productId
   * @return  `List`
   */
  @AuraEnabled
  public static Product2 getProductById(String productId) {
    return [
      SELECT
        Id,
        Name,
        Product_SKU__c,
        Product_Description__c,
        MACHINE_WEIGHT_IN_POUNDS__c,
        Primary_Image_URL__c,
        Product_Sub_Category__c,
        Product_Type__c,
        Item_Number__c,
        Stock_class__c,
        Product_Hierarchy__r.Product_Hierarchy_Code__c,
        QuantityUnitOfMeasure //FRONT-32188
      FROM Product2
      WHERE Id = :productId
      WITH SECURITY_ENFORCED
    ];
  }
  /**
   * @description
   * @param externalIds
   * @return  `Map<String, Product2>`
   */
  public static Map<String, Product2> getProductByExternalId(
    Set<String> externalIds
  ) {
    Map<String, Product2> returnVal = new Map<String, Product2>();
    List<Product2> prodList = [
      SELECT ID, Product_SKU__c, Product_Type__c, RecordType.Name
      FROM Product2
      WHERE Product_SKU__c IN :externalIds
      WITH SECURITY_ENFORCED
    ];

    for (Product2 prd : prodList) {
      returnVal.put(prd.Product_SKU__c, prd);
    }

    return returnVal;
  }

  /**
   * @description
   * @param externalIds
   * @return  `Map<String, Product2>`
   */
  public static Map<String, PricebookEntry> getPriceBookEntrieswithProductSKUs(
    Set<String> skus
  ) {
    Map<String, PricebookEntry> priceBookEntries = new Map<String, PricebookEntry>();
    for (PricebookEntry pe : [
      SELECT
        Id,
        Product2.Product_SKU__c,
        Product2.ID,
        Product2.Product_Type__c,
        Product2.RecordType.Name,
        UnitPrice,
        Pricebook2.name,
        CurrencyIsoCode
      FROM PricebookEntry
      WHERE Product2.Product_SKU__c IN :skus
      WITH SECURITY_ENFORCED
    ]) {
      priceBookEntries.put(pe.Product2.Product_SKU__c, pe);
    }
    return priceBookEntries;
  }

  /**
    * @description  
    * @param productSkus
      @param companyCode
    * @return  `Map<String, Object>`
    */
  @AuraEnabled(cacheable=true) //SF-5291,SF-5292
  public static Map<String, Object> getProductOptionsWithFuelCharge(
    List<String> productIds,
    List<String> companyCode
  ) {
    Map<String, Object> result = new Map<String, Object>();
    // 04.02.2024:PS-5287:SG:Added a null check for companyCode and replace it with empty List if it is null - to avoid "Argument Null" exception in the below SOQL where String.escapeSingleQuotes method is used in the where clause.
    if (companyCode == null || companyCode.isEmpty()) {
      companyCode = new List<String>();
    }
    try {
      List<SBQQ__ProductOption__c> prodOptionList = [
        SELECT
          Id,
          Name,
          SBQQ__Quantity__c,
          SBQQ__OptionalSKU__r.Id,
          SBQQ__OptionalSKU__r.Item_Number__c,
          SBQQ__OptionalSKU__r.Product_Type__c,
          SBQQ__OptionalSKU__r.Stock_class__c,
          SBQQ__OptionalSKU__r.Name,
          SBQQ__OptionalSKU__r.Product_SKU__c,
          SBQQ__OptionalSKU__r.Sell_Price__c,
          SBQQ__Required__c,
          Company_Code__c,
          SBQQ__OptionalSKU__r.Inventoried_Item__c,
          SBQQ__OptionalSKU__r.Miscellaneous_Charge_Item__c,
          SBQQ__ConfiguredSKU__c,
          SBQQ__ConfiguredSKU__r.name,
          SBQQ__OptionalSKU__r.Type_of_Misc_Charge_Item__c,
          SBQQ__OptionalSKU__r.User_Selectable_for_Quote__c,
          SBQQ__ConfiguredSKU__r.Product_SKU__c
        FROM SBQQ__ProductOption__c
        WHERE
          Company_Code__c IN :companyCode
          AND SBQQ__OptionalSKU__r.RecordType.Name = 'SKU'
          AND SBQQ__Feature__c IN (
            SELECT Id
            FROM SBQQ__ProductFeature__c
            WHERE Name IN ('Sales Addons', 'Rental Addons')
          )
          AND SBQQ__ConfiguredSKU__c IN :productIds
          AND SBQQ__OptionalSKU__r.Name = 'Fuel Convenience Charge'
          AND SBQQ__OptionalSKU__r.Stock_class__c = 'FUEL'
        WITH SECURITY_ENFORCED
      ];
      if (!prodOptionList.isEmpty()) {
        for (Integer i = 0; i < prodOptionList.size(); i++) {
          SBQQ__ProductOption__c prodOption = prodOptionList[i];
          String configuredSKU = prodOption.SBQQ__ConfiguredSKU__c;
          result.put(configuredSKU, prodOption);
        }
      } else {
        return null;
      }
    } catch (Exception ex) {
      SBR_3_0_Log.logException(ex);
    }
    System.debug(' result returned-->' + result);
    return result;
  }

  /*@AuraEnabled(cacheable=true) //SF-5291,SF-5292
public static Map<String, Object> getProductOptionsWithFuelCharge(List<String> productIds, String companyCode) {
    Map<String, Object> result = new Map<String, Object>();

    try {
        List<SBQQ__ProductOption__c> prodOptionList = [
            SELECT Id, Name, SBQQ__Quantity__c, SBQQ__OptionalSKU__r.Id, SBQQ__OptionalSKU__r.Item_Number__c,
                SBQQ__OptionalSKU__r.Product_Type__c, SBQQ__OptionalSKU__r.Stock_class__c, SBQQ__OptionalSKU__r.Name,
                SBQQ__OptionalSKU__r.Product_SKU__c, SBQQ__OptionalSKU__r.Sell_Price__c, SBQQ__Required__c,
                SBQQ__OptionalSKU__r.Inventoried_Item__c, SBQQ__OptionalSKU__r.Miscellaneous_Charge_Item__c, SBQQ__ConfiguredSKU__c,
                SBQQ__OptionalSKU__r.Type_of_Misc_Charge_Item__c, SBQQ__OptionalSKU__r.User_Selectable_for_Quote__c, SBQQ__ConfiguredSKU__r.Product_SKU__c
            FROM SBQQ__ProductOption__c
            WHERE Company_Code__c = :String.escapeSingleQuotes(companyCode)
            AND SBQQ__OptionalSKU__r.RecordType.Name = 'SKU'
            AND SBQQ__Feature__c IN (SELECT Id FROM SBQQ__ProductFeature__c WHERE Name in ('Sales Addons','Rental Addons'))
            AND SBQQ__ConfiguredSKU__c = :productIds
        ];

        for (SBQQ__ProductOption__c prodOption : prodOptionList) {
            String productName = prodOption.SBQQ__OptionalSKU__r.Name;
            if ((productName.contains('Refill') || productName.contains('Fuel Convenience Charge')) && prodOption.SBQQ__OptionalSKU__r.Stock_class__c=='FUEL') {
                result.put('hasFuelCharge', true);
                result.put('fuelChargeOption', prodOption);
                 return result;
            }
        }
    result.put('hasFuelCharge', false);
    } catch (Exception ex) {
        SBR_3_0_Log.logException(ex);
    }

    return result;
}
*/

  /**
   * @description
   * @return  `Map<String, Product2>`
   */
  public static List<Product2> getdlvrGenericProducts() {
    return [
      SELECT
        Id,
        Status__c,
        Name,
        Product_Title_Internal__c,
        Company_Code__c,
        Product_SKU__c,
        Type_of_Misc_Charge_Item__c,
        Product_Type__c,
        Stock_class__c,
        Item_Number__c
      FROM Product2
      WHERE
        Item_Number__c = 'ITEMNOTFOUND'
        OR (Stock_class__c = 'DEL'
        AND Product_Type__c = 'MISC Charge Items'
        AND (Item_Number__c = 'PICKUP'
        OR Item_Number__c = 'DELIVERY'))
      WITH SECURITY_ENFORCED
    ];
  }

  /**
   * @description
   * @return  `Map<String, Product2>`
   */
  public static Map<String, Product2> getGenericProductForEachCompanyCodes() {
    Map<String, Product2> genericProducts = new Map<String, Product2>();
    for (Product2 prod : [
      SELECT ID, Product_SKU__c, Company_Code__c
      FROM Product2
      WHERE Item_Number__c = 'ITEMNOTFOUND'
      WITH SECURITY_ENFORCED
    ]) {
      genericProducts.put(prod.Company_Code__c, prod);
    }
    return genericProducts;
  }
  /**
   * @description
   * @param productHierarchyCode
   * @return  `Product_Hierarchy__c`
   */
  public static Product_Hierarchy__c getProductHierarchyByCode(
    String productHierarchyCode
  ) {
    List<Product_Hierarchy__c> prodHierarchy = [
      SELECT
        Id,
        Name,
        Product_Hierarchy_Code__c,
        Parent_Code__r.Name,
        Parent_Code__r.Parent_Code__r.Filter_Level__c,
        Parent_Code__r.Parent_Code__r.Name
      FROM Product_Hierarchy__c
      WHERE Product_Hierarchy_Code__c = :productHierarchyCode
      WITH SECURITY_ENFORCED
      ORDER BY LastModifiedDate DESC
      LIMIT 1
    ];
    if (prodHierarchy.isEmpty()) {
      return null;
    } else {
      return prodHierarchy[0];
    }
  }
  /**
    * @description  
    * @param filterLevel
      @param parentCodeName
      @param parentCodeIds
      @param isSubCategory
      @param orderByName
    * @return  `List<Product_Hierarchy__c>`
    */

  public static List<Product_Hierarchy__c> getProductCategoryOptions(
    Integer filterLevel,
    String parentCodeName,
    Set<Id> parentCodeIds,
    Boolean isSubCategory,
    Boolean orderByName
  ) {
    String query = 'SELECT Id, Name, Parent_Code__c, Parent_Code__r.Name from Product_Hierarchy__c';
    String whereClause = ' WHERE Product_Family_Type__c = \'Cat-Class\'';
    if (filterLevel != null && filterLevel > 0) {
      whereClause += ' AND Filter_Level__c = \'' + filterLevel.format() + '\'';
    }
    if (String.isNotBlank(parentCodeName)) {
      whereClause +=
        ' AND Parent_Code__r.Name = \'' +
        String.escapeSingleQuotes(parentCodeName) +
        '\'';
    }
    if (parentCodeIds != null && parentCodeIds.size() > 0) {
      whereClause += ' AND Parent_Code__c IN ' + inClausify(parentCodeIds);
    }
    if (isSubCategory) {
      whereClause += ' AND RecordType.Name = \'Product Sub-Category\'';
    }
    if (orderByName) {
      whereClause += ' ORDER BY Name';
    }

    query += whereClause;
    return Database.query(query); // NOPMD
  }
  /**
   * @description
   * @param productId
   * @return  `Map<String, SBQQ__ProductFeature__c>`
   */
  public static Map<String, SBQQ__ProductFeature__c> getProductFeatures(
    Id productId
  ) {
    Map<String, SBQQ__ProductFeature__c> returnVal = new Map<String, SBQQ__ProductFeature__c>();
    List<SBQQ__ProductFeature__c> prodFeatures = [
      SELECT
        Id,
        Name,
        Product_Feature_Load_Ext_ID__c,
        SBQQ__ConfiguredSKU__c,
        SBQQ__MinOptionCount__c,
        SBQQ__Number__c
      FROM SBQQ__ProductFeature__c
      WHERE SBQQ__ConfiguredSKU__c = :productId
      WITH SECURITY_ENFORCED
      ORDER BY LastModifiedDate DESC
    ];
    if (prodFeatures <> null && !prodFeatures.isEmpty()) {
      for (SBQQ__ProductFeature__c feature : prodFeatures) {
        returnVal.put(feature.Name, feature);
      }
    }

    return returnVal;
  }
  /**
   * @description
   * @param externalIds
   * @return  `Map<String, Message__c>`
   */
  public static Map<String, Message__c> getMessageRecordsByExternalId(
    Set<String> externalIds
  ) {
    Map<String, Message__c> returnVal = new Map<String, Message__c>();
    List<Message__c> messages = [
      SELECT
        Id,
        Description__c,
        Message_Number__c,
        Company_Code__c,
        Product_Message_Id__c,
        CurrencyIsoCode
      FROM Message__c
      WHERE Product_Message_Id__c IN :externalIds
      WITH SECURITY_ENFORCED
      ORDER BY LastModifiedDate DESC
    ];
    if (messages <> null && !messages.isEmpty()) {
      for (Message__c msg : messages) {
        if (!returnVal.containsKey(msg.Product_Message_Id__c)) {
          returnVal.put(msg.Product_Message_Id__c, msg);
        }
      }
    }

    return returnVal;
  }
  /**
   * @description
   * @param productId
   * @return  `Map<String, Product_Message__c>`
   */
  public static Map<String, Product_Message__c> getProductMessages(
    Id productId
  ) {
    Map<String, Product_Message__c> returnVal = new Map<String, Product_Message__c>();
    List<Product_Message__c> productMessages = [
      SELECT
        Id,
        Name,
        Product_Message_Id__c,
        Product_SKU__c,
        Message_Number__c,
        Message__c,
        Message__r.Product_Message_Id__c,
        Product__c,
        Print__c,
        Screen__c
      FROM Product_Message__c
      WHERE Product__c = :productId
      WITH SECURITY_ENFORCED
      ORDER BY LastModifiedDate DESC
    ];
    if (!productMessages.isEmpty()) {
      for (Product_Message__c msg : productMessages) {
        if (
          msg.Product_Message_Id__c <> null &&
          !returnVal.containsKey(msg.Product_Message_Id__c)
        ) {
          returnVal.put(msg.Product_Message_Id__c, msg);
        }
      }
    }

    return returnVal;
  }
  /**
   * @description
   * @param searching
   * @return  `List<ProductItem>`
   */
  public static List<ProductItem> fetchProductItemById(Set<Id> searching) {
    return [
      SELECT
        ID,
        SM_PS_Quantity_Available__c,
        SM_PS_Quantity_on_Rent__c,
        SM_PS_Quantity_Returned__c,
        SM_PS_Quantity_Reserved__c
      FROM ProductItem
      WHERE ID IN :searching
    ];
  }
  /**
    * @description  
    * @param searching
      @param locSearch
    * @return  `List<ProductItem>`
    */
  public static List<ProductItem> fetchProductItemByIdandLocationId(
    Set<Id> searching,
    Set<Id> locSearch
  ) {
    return [
      SELECT
        ID,
        SM_PS_Quantity_Available__c,
        SM_PS_Quantity_on_Rent__c,
        SM_PS_Quantity_Returned__c,
        SM_PS_Quantity_Reserved__c
      FROM ProductItem
      WHERE ID IN :searching AND LocationId IN :locSearch
    ];
  }
  /**
   * @description
   * @param productId
   * @return  `Map<String, SBQQ__ProductOption__c>`
   */
  public static Map<String, SBQQ__ProductOption__c> getProductOptions(
    Id productId
  ) {
    Map<String, SBQQ__ProductOption__c> returnVal = new Map<String, SBQQ__ProductOption__c>();
    List<SBQQ__ProductOption__c> productOptions = [
      SELECT
        Id,
        Name,
        SBQQ__ConfiguredSKU__c,
        SBQQ__Feature__c,
        SBQQ__OptionalSKU__c,
        Product_Optional_SKU__c
      FROM SBQQ__ProductOption__c
      WHERE SBQQ__ConfiguredSKU__c = :productId
      WITH SECURITY_ENFORCED
      ORDER BY LastModifiedDate DESC
    ];
    if (!productOptions.isEmpty()) {
      for (SBQQ__ProductOption__c prodOpt : productOptions) {
        if (
          prodOpt.Product_Optional_SKU__c <> null &&
          !returnVal.containsKey(prodOpt.Product_Optional_SKU__c)
        ) {
          returnVal.put(prodOpt.Product_Optional_SKU__c, prodOpt);
        }
      }
    }

    return returnVal;
  }
  /**
    * @description  
    * @param productId
      @param companyCode
      @param addonName
    * @return  `List<SBQQ__ProductOption__c>`
    */
  public static List<SBQQ__ProductOption__c> getProductOptionsWithCompanyCode(
    String productId,
    String companyCode,
    String addonName
  ) {
    String query =
      'SELECT Id, Name,SBQQ__Quantity__c,SBQQ__OptionalSKU__r.Id, SBQQ__OptionalSKU__r.Item_Number__c, SBQQ__OptionalSKU__r.Product_Type__c, SBQQ__OptionalSKU__r.Stock_class__c, SBQQ__OptionalSKU__r.Name, SBQQ__OptionalSKU__r.Product_SKU__c, SBQQ__OptionalSKU__r.Sell_Price__c, SBQQ__Required__c, SBQQ__OptionalSKU__r.Inventoried_Item__c,  SBQQ__OptionalSKU__r.Miscellaneous_Charge_Item__c,  SBQQ__OptionalSKU__r.Type_of_Misc_Charge_Item__c,  SBQQ__OptionalSKU__r.User_Selectable_for_Quote__c,SBQQ__ConfiguredSKU__r.Product_SKU__c,SBQQ__ConfiguredSKU__c,SBQQ__Feature__r.Name,SBQQ__Feature__c ' +
      ' FROM SBQQ__ProductOption__c WHERE ';

    // SAL-22442: filtering E-sku addons from spotlight panel UI
    query +=
      'Company_Code__c = \'' +
      String.escapeSingleQuotes(companyCode) +
      '\' AND SBQQ__OptionalSKU__r.RecordType.Name =\'SKU\' AND SBQQ__Feature__c IN ' +
      '(SELECT Id FROM SBQQ__ProductFeature__c WHERE SBQQ__ConfiguredSKU__c = \'' +
      String.escapeSingleQuotes(productId) +
      '\' AND Name = \'' +
      String.escapeSingleQuotes(addonName) +
      '\')';

    //System.debug('@@Database.query(query)::'+Database.query(query));
    return Database.query(query); // NOPMD
  }
  /**
    * @description  
    * @param productId
      @param companyCode
      @param subCategory
      @param productHierarchyCode
    * @return  `List<Product2>`
    */
  public static List<Product2> getAlternateProducts(
    String productId,
    String companyCode,
    String subCategory,
    String productHierarchyCode
  ) {
    return [
      SELECT
        Id,
        Name,
        Product_SKU__c,
        Sell_Price__c,
        Product_Category__c,
        Product_Sub_Category__c,
        Product_Category_Txt__c,
        Product_Sub_Category_Txt__c,
        Product_Type__c,
        Item_Number__c,
        Stock_class__c,
        Inventoried_Item__c,
        Miscellaneous_Charge_Item__c,
        Type_of_Misc_Charge_Item__c,
        User_Selectable_for_Quote__c,
        Is_Kit__c,
        Changeable__c
      FROM Product2
      WHERE
        Product_Sub_Category__c = :String.escapeSingleQuotes(subCategory)
        AND RecordType.DeveloperName = 'SKU'
        AND Company_Code__c INCLUDES (:String.escapeSingleQuotes(companyCode))
        AND (NOT Id = :String.escapeSingleQuotes(productId))
        AND Product_Type__c = 'Cat-Class'
        AND Status__c = 'A'
        AND Product_Hierarchy__r.Product_Hierarchy_Code__c = :String.escapeSingleQuotes(
          productHierarchyCode
        )
        AND Bulk_Item__c = FALSE
      WITH SECURITY_ENFORCED
    ];
  }
  /**
   * @description
   * @param productId
   * @return  `List<SBQQ__ProductOption__c>`
   */
  public static List<SBQQ__ProductOption__c> getProductKitComponents(
    String productId
  ) {
    return [
      SELECT
        Id,
        Name,
        SBQQ__ProductName__c,
        SBQQ__Quantity__c,
        SBQQ__ConfiguredSKU__c,
        SBQQ__OptionalSKU__c,
        SBQQ__OptionalSKU__r.Category__c,
        SBQQ__OptionalSKU__r.Class__c,
        SBQQ__OptionalSKU__r.Product_SKU__c,
        SBQQ__OptionalSKU__r.Inventoried_Item__c,
        SBQQ__OptionalSKU__r.Miscellaneous_Charge_Item__c,
        SBQQ__OptionalSKU__r.Type_of_Misc_Charge_Item__c,
        SBQQ__OptionalSKU__r.Product_Type__c,
        SBQQ__OptionalSKU__r.Stock_class__c
      FROM SBQQ__ProductOption__c
      WHERE
        SBQQ__Feature__r.Name = 'Kit Component'
        AND SBQQ__ConfiguredSKU__r.Id = :productId
        AND SBQQ__Quantity__c > 0
      WITH SECURITY_ENFORCED
    ];
  }
  /**
   * @description
   * @param productSkus
   * @return  `List<SBQQ__ProductOption__c>`
   */
  public static List<SBQQ__ProductOption__c> getProductKitComponents(
    List<String> productSkus
  ) {
    return [
      SELECT
        Id,
        Name,
        SBQQ__ProductName__c,
        SBQQ__Quantity__c,
        SBQQ__ConfiguredSKU__c,
        SBQQ__ConfiguredSKU__r.Changeable__c,
        SBQQ__OptionalSKU__c,
        SBQQ__OptionalSKU__r.Category__c,
        SBQQ__OptionalSKU__r.Class__c,
        SBQQ__OptionalSKU__r.Product_SKU__c,
        SBQQ__OptionalSKU__r.Inventoried_Item__c,
        SBQQ__OptionalSKU__r.Miscellaneous_Charge_Item__c,
        SBQQ__ConfiguredSKU__r.Is_Kit__c,
        SBQQ__OptionalSKU__r.Type_of_Misc_Charge_Item__c,
        SBQQ__OptionalSKU__r.Product_Type__c,
        SBQQ__OptionalSKU__r.Stock_class__c,
        SBQQ__ConfiguredSKU__r.Product_SKU__c,
        SBQQ__OptionalSKU__r.Id,
        SBQQ__OptionalSKU__r.Item_Number__c,
        SBQQ__OptionalSKU__r.Name,
        SBQQ__OptionalSKU__r.Sell_Price__c,
        SBQQ__Required__c,
        SBQQ__Feature__r.Name
      FROM SBQQ__ProductOption__c
      WHERE
        SBQQ__Feature__r.Name = 'Kit Component'
        AND SBQQ__ConfiguredSKU__r.Product_SKU__c IN :productSkus
        AND SBQQ__Quantity__c > 0
      WITH SECURITY_ENFORCED
    ];
  }
  /**
   * @description
   * @return  `List<Product2>`
   */
  public static List<Product2> getEDLaborProduct() {
    String eLaborSKU = System.Label.E_Labor_Product_SKU;
    String dLaborSKU = System.Label.D_Labor_Product_SKU;
    Set<String> skuIds = new Set<String>{ eLaborSKU, dLaborSKU };
    return [
      SELECT
        Id,
        Name,
        Product_SKU__c,
        Sell_Price__c,
        Product_Category__c,
        Product_Sub_Category__c,
        Product_Category_Txt__c,
        Product_Sub_Category_Txt__c
      FROM Product2
      WHERE Product_SKU__c IN :skuIds
      WITH SECURITY_ENFORCED
      LIMIT 2
    ];
  }
  /**
    * @description  
      @param ids
    * @return  `Map<String, Product2>`
    */
  public static Map<String, Product2> getProductsById(Set<String> ids) {
    return new Map<String, Product2>(
      [
        SELECT
          ID,
          Name,
          Product_SKU__c,
          Product_Type__c,
          Product_Category__c,
          Product_Sub_Category__c,
          Product_Category_Txt__c,
          Product_Sub_Category_Txt__c,
          IsSerialized,
          Sell_Price__c,
          Stock_class__c,
          Status__c,
          Bulk_Item__c,
          Item_Number__c,
          Inventoried_Item__c,
          Miscellaneous_Charge_Item__c,
          Type_of_Misc_Charge_Item__c,
          User_Selectable_for_Quote__c,
          Is_Kit__c,
          Changeable__c
        FROM Product2
        WHERE Id IN :ids
      ]
    );
  }

  /** 
    * @description SAL-27320
      @param ids
    * @return  `Map<String, Product2>`
    */
  public static Map<String, Product2> getProductsMapByProductSKU(
    Set<String> ids
  ) {
    return new Map<String, Product2>(
      [
        SELECT
          ID,
          Name,
          Product_SKU__c,
          Product_Type__c,
          Product_Category__c,
          Product_Sub_Category__c,
          Product_Category_Txt__c,
          Product_Sub_Category_Txt__c,
          IsSerialized,
          Sell_Price__c,
          Stock_class__c,
          Status__c,
          Bulk_Item__c,
          Item_Number__c,
          Inventoried_Item__c,
          Miscellaneous_Charge_Item__c,
          Type_of_Misc_Charge_Item__c,
          User_Selectable_for_Quote__c
        FROM Product2
        WHERE Product_SKU__c IN :ids
      ]
    );
  }
  /**
    * @description  
      @param itemNumber
      @param stockCLass
      @param companyCode
    * @return  `Map<String, Product2>`
    */
  public static Map<String, Product2> getItemClassProduct(
    String itemNumber,
    String stockCLass,
    String companyCode
  ) {
    return new Map<String, Product2>(
      [
        SELECT ID, Name
        FROM Product2
        WHERE
          Item_Number__c = :itemNumber
          AND Stock_class__c = :stockCLass
          AND Company_Code__c = :companyCode
      ]
    );
  }
  /** 
    * @description
      @param ids
    * @return  `String`
    */
  public static String inClausify(Set<Id> ids) {
    String inClause = String.format(
      '(\'\'{0}\'\')',
      new List<String>{ String.join(new List<Id>(ids), '\',\'') }
    );
    return inClause;
  }
  /** 
    * @description
      @param productSKUs
    * @return  `List<Product2>`
    */
  public static List<Product2> getProductsByProductSKU(
    Set<String> productSKUs
  ) {
    return [
      SELECT
        ID,
        Name,
        Product_SKU__c,
        Product_Type__c,
        Product_Category__c,
        Product_Sub_Category__c,
        Product_Category_Txt__c,
        Product_Sub_Category_Txt__c,
        IsSerialized,
        Sell_Price__c,
        Stock_class__c,
        Status__c,
        Bulk_Item__c,
        Item_Number__c,
        Inventoried_Item__c,
        Miscellaneous_Charge_Item__c,
        Type_of_Misc_Charge_Item__c,
        User_Selectable_for_Quote__c,
        Is_Kit__c,
        Changeable__c
      FROM Product2
      WHERE Product_SKU__c IN :productSKUs
      WITH SECURITY_ENFORCED
    ];
  }

  /** 
    * @description SAL-26002
      @param productSkus
      @param companyCode
      @param addonName
    * @return  `List<SBQQ__ProductOption__c>`
    */
  public static List<SBQQ__ProductOption__c> getProductOptionsForProducts(
    List<String> productSkus,
    String companyCode,
    String addonName
  ) {
    String query =
      'SELECT Id, Name,SBQQ__ConfiguredSKU__r.Changeable__c,SBQQ__ConfiguredSKU__r.Is_Kit__c,SBQQ__Quantity__c,SBQQ__ConfiguredSKU__c,SBQQ__ConfiguredSKU__r.Product_SKU__c, SBQQ__OptionalSKU__r.Id, SBQQ__OptionalSKU__r.Item_Number__c, SBQQ__OptionalSKU__r.Product_Type__c, SBQQ__OptionalSKU__r.Stock_class__c, SBQQ__OptionalSKU__r.Name, SBQQ__OptionalSKU__r.Product_SKU__c, SBQQ__OptionalSKU__r.Sell_Price__c, SBQQ__Required__c, SBQQ__Feature__r.Name,SBQQ__OptionalSKU__r.Inventoried_Item__c,SBQQ__OptionalSKU__r.Miscellaneous_Charge_Item__c,SBQQ__OptionalSKU__r.Type_of_Misc_Charge_Item__c,SBQQ__OptionalSKU__r.User_Selectable_for_Quote__c' +
      ' FROM SBQQ__ProductOption__c WHERE ';
    companyCode = companyCode != null ? companyCode : '';
    if (addonName == 'Forced Item') {
      query +=
        'Company_Code__c = \'' +
        String.escapeSingleQuotes(companyCode) +
        '\' AND SBQQ__OptionalSKU__r.RecordType.Name =\'SKU\' AND SBQQ__Required__c = true AND SBQQ__Feature__c IN ' +
        '(SELECT Id FROM SBQQ__ProductFeature__c WHERE SBQQ__ConfiguredSKU__r.Product_SKU__c IN: productSkus AND Name in (\'Rental Addons\', \'Sales Addons\'))';
    } else if (addonName == 'ALL') {
      // TO query sales addons, rental addons, kit components
      query +=
        'Company_Code__c = \'' +
        String.escapeSingleQuotes(companyCode) +
        '\' AND SBQQ__OptionalSKU__r.RecordType.Name =\'SKU\' AND SBQQ__Feature__c IN ' +
        '(SELECT Id FROM SBQQ__ProductFeature__c WHERE SBQQ__ConfiguredSKU__r.Product_SKU__c IN: productSkus AND Name in (\'Rental Addons\', \'Sales Addons\', \'Kit Component\'))';
    } else {
      addonName = addonName != null ? addonName : '';
      query +=
        'Company_Code__c = \'' +
        String.escapeSingleQuotes(companyCode) +
        '\' AND SBQQ__OptionalSKU__r.RecordType.Name =\'SKU\' AND SBQQ__Required__c = false AND SBQQ__Feature__c IN ' +
        '(SELECT Id FROM SBQQ__ProductFeature__c WHERE SBQQ__ConfiguredSKU__r.Product_SKU__c IN: productSkus AND Name = \'' +
        String.escapeSingleQuotes(addonName) +
        '\')';
    }
    return Database.query(query); // NOPMD
  }

  /**
   * @description //SAL-25998
   * @return  `Map<String, Product2>`
   */
  public static Map<String, Product2> getDeliveryPickupProds() {
    Map<String, Product2> deliveryPickupProds = new Map<String, Product2>();
    for (Product2 prod : [
      SELECT
        Id,
        Status__c,
        Name,
        Product_Title_Internal__c,
        Company_Code__c,
        Product_SKU__c,
        Type_of_Misc_Charge_Item__c,
        Product_Type__c,
        Stock_class__c,
        Item_Number__c
      FROM Product2
      WHERE
        Stock_class__c = 'DEL'
        AND Product_Type__c = 'MISC Charge Items'
        AND (Item_Number__c = 'PICKUP'
        OR Item_Number__c = 'DELIVERY')
      WITH SECURITY_ENFORCED
    ]) {
      deliveryPickupProds.put(prod.Product_SKU__c, prod);
    }
    return deliveryPickupProds;
  }

  /** 
    * @description //SF-5330 - Query Product Option for lineitem
      @param optionalSKU
      @param kitNumber
    * @return  `List<SBQQ__ProductOption__c>`
    */
  public static List<SBQQ__ProductOption__c> getProductOptionForLineItem(
    List<String> optionalSKU,
    List<String> kitNumber
  ) {
    User loggedInUser = SBR_3_0_UserDA.getUserById(UserInfo.getUserId());
    String loggedInUserCompanyCode = loggedInUser.CompanyName;
    List<SBQQ__ProductOption__c> productOption = new List<SBQQ__ProductOption__c>();
    //SF-7537 (remove -and SBQQ__Required__c = true- from SOQL)
    productOption = [
      SELECT
        id,
        SBQQ__Required__c,
        SBQQ__Feature__r.Name,
        SBQQ__Quantity__c,
        SBQQ__OptionalSKU__c,
        SBQQ__ConfiguredSKU__r.Product_SKU__c
      FROM SBQQ__ProductOption__c
      WHERE
        SBQQ__OptionalSKU__c IN :optionalSKU
        AND SBQQ__ConfiguredSKU__r.Product_SKU__c IN :kitNumber
        AND Company_Code__c = :loggedInUserCompanyCode
      WITH SECURITY_ENFORCED
    ];
    return productOption;
  }

  /** 
    * @description //SF-5850 - Query Product Option for lineitem
      @param optionalSKU
      @param kitNumber
    * @return  `String`
    */
  @AuraEnabled(cacheable=true)
  public static String getProductOptionForLineItems(
    List<String> optionalSKU,
    List<String> kitNumber
  ) {
    List<SBQQ__ProductOption__c> productOptions = getProductOptionForLineItem(
      optionalSKU,
      kitNumber
    );
    return JSON.serialize(productOptions);
  }

  /**
   * @description Used to check if the parent lineitem is containing a Fuel Plan
   *  and disabling the edit on the related child line item
   * @param kitNumber String value with the Kit number
   * @param objectType String value to indicate the type of object.
   * @return `ProductWrapper`
   */
  @AuraEnabled(cacheable=true) //SF-5291,SF-5292
  public static ProductWrapper getParentCatClassWithFuelPlan(
    String kitNumber,
    String objectType
  ) {
    ProductWrapper wrapper = new ProductWrapper();

    try {
      if (objectType != 'OrderItem') {
        List<SBQQ__QuoteLine__c> qli = [
          SELECT
            Id,
            Line_Comments__c,
            Fuel_Plan__c,
            Line_Item_Type__c,
            SBQQ__Product__r.Name
          FROM SBQQ__QuoteLine__c
          WHERE
            Product_SKU_Text__c = :kitNumber
            AND SBQQ__Product__r.Product_Type__c = 'Cat-Class'
            AND Line_Item_Type__c = 'VR'
            AND Fuel_Plan__c = TRUE
          WITH SECURITY_ENFORCED
          LIMIT 1
        ];

        if (!qli.isEmpty() && qli[0].SBQQ__Product__r.Name != '') {
          wrapper.lineComments =
            'Fuel Plan for ' + qli[0].SBQQ__Product__r.Name;
          wrapper.hasFuelCatClassParent = true;
        }
      } else {
        List<OrderItem> oli = [
          SELECT
            Id,
            Line_Comments__c,
            Fuel_Plan__c,
            Line_Item_Type__c,
            Product2.Name
          FROM OrderItem
          WHERE
            Product_SKU_Text__c = :kitNumber
            AND Product2.Product_Type__c = 'Cat-Class'
            AND Line_Item_Type__c = 'VR'
            AND Fuel_Plan__c = TRUE
          WITH SECURITY_ENFORCED
          LIMIT 1
        ];

        if (!oli.isEmpty() && oli[0].Product2.Name != '') {
          wrapper.lineComments = 'Fuel Plan for ' + oli[0].Product2.Name;
          wrapper.hasFuelCatClassParent = true;
        }
      }
    } catch (Exception ex) {
      SBR_3_0_Log.logException(ex);
    }

    return wrapper;
  }

  /**
   * @description Method to cehck if the Parent line item is having a Fuel Product associated
   * @param lineId The lineId of the record
   * @param objectType The product SKU of the Parent product
   * @return A Map of string Object,indicating the fuel flag and the details of the Fuel Item
   */
  @AuraEnabled(cacheable=true) //SF-5291,SF-5292
  public static Map<String, Object> checkProductOptionForLineItem(
    String lineId,
    String objectType
  ) {
    Map<String, Object> result = new Map<String, Object>();

    try {
      User loggedInUser = SBR_3_0_UserDA.getUserById(UserInfo.getUserId());
      String loggedInUserCompanyCode = loggedInUser.CompanyName;
      Map<String, Object> productOptionResult = new Map<String, Object>();
      Boolean hasFuelCharge;

      if (objectType != 'OrderItem') {
        List<SBQQ__QuoteLine__c> quoteLines = [
          SELECT
            Id,
            Fuel_Plan__c,
            Kit_Number_this_Item_Belongs_to__c,
            Product_SKU__c,
            SBQQ__Product__c,
            Product_SKU_Text__c
          FROM SBQQ__QuoteLine__c
          WHERE Id = :lineId
          WITH SECURITY_ENFORCED
        ];

        if (!quoteLines.isEmpty()) {
          SBQQ__QuoteLine__c lineItem = quoteLines[0];
          productOptionResult = SBR_3_0_ProductDA.getProductOptionsWithFuelCharge(
            new List<String>{ lineItem.SBQQ__Product__c },
            new List<String>{ loggedInUserCompanyCode }
          );
          if (productOptionResult != null && !productOptionResult.isEmpty()) {
            return productOptionResult;
          } else {
            return null;
          }
        }
      } else {
        List<OrderItem> orderLines = [
          SELECT
            Id,
            Line_Comments__c,
            Fuel_Plan__c,
            Kit_Number_This_Item_Belongs_to__c,
            Product2.Id,
            Product2.Name
          FROM OrderItem
          WHERE Id = :lineId
          WITH SECURITY_ENFORCED
        ];
        if (!orderLines.isEmpty()) {
          OrderItem lineItem = orderLines[0];
          productOptionResult = SBR_3_0_ProductDA.getProductOptionsWithFuelCharge(
            new List<String>{ lineItem.Product2.Id },
            new List<String>{ loggedInUserCompanyCode }
          );
          if (productOptionResult != null && !productOptionResult.isEmpty()) {
            return productOptionResult;
          } else {
            return null;
          }
        }
      }
    } catch (Exception ex) {
      SBR_3_0_Log.logException(ex);
    }

    return result;
  }

  /**
   * @description Method to cehck if there are existing Fuel Line Items
   * @param currRecordId The current record Id context
   * @param productSKU The product SKU of the Parent product
   * @param objectType The type of Object context
   * @return A boolean flag indicating the whether it has or not
   */
  @AuraEnabled(cacheable=true) //SF-5291,SF-5292
  public static Boolean hasExistingFuelChargeLineItem(
    String currRecordId,
    String productSKU,
    String objectType
  ) {
    Boolean hasExistingFlag = false;

    try {
      if (objectType != 'OrderItem') {
        List<SBQQ__QuoteLine__c> qli = [
          SELECT Id
          FROM SBQQ__QuoteLine__c
          WHERE
            Kit_Number_this_Item_Belongs_to__c = :productSKU
            AND SBQQ__Quote__c = :currRecordId
            AND SBQQ__Product__r.Name = 'Fuel Convenience Charge'
          WITH SECURITY_ENFORCED
        ];
        hasExistingFlag = !qli.isEmpty();
      } else {
        List<OrderItem> oli = [
          SELECT
            Id,
            Line_Comments__c,
            Fuel_Plan__c,
            Line_Item_Type__c,
            Product2.Name
          FROM OrderItem
          WHERE
            Kit_Number_This_Item_Belongs_to__c = :productSKU
            AND OrderId = :currRecordId
            AND Product2.Name = 'Fuel Convenience Charge'
          WITH SECURITY_ENFORCED
        ];
        hasExistingFlag = !oli.isEmpty();
      }
    } catch (Exception ex) {
      SBR_3_0_Log.logException(ex);
    }

    return hasExistingFlag;
  }

  /**
   * @description Wrapper Class to set the flag to identify a fuel product
   * @return null
   */
  public class ProductWrapper { //SF-5291,SF-5292
    @AuraEnabled
    public String lineComments { get; set; }
    @AuraEnabled
    public Boolean hasFuelCatClassParent { get; set; }
  }
}