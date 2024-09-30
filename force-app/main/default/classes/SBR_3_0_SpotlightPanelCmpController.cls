/*********************************************************************************************************************
* Apex Class: SBR_3_0_SpotlightPanelCmpController
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Controller class for any operations for sbr_3_0_spotlightPanelCmp LWC
* - SAL-1751, SAL-1752
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Avinash Rao             2022-05-02          Initial version    
*********************************************************************************************************************/

public without sharing class SBR_3_0_SpotlightPanelCmpController {
  public static final String US_SALES_ROLE = 'Sales - US';
  public static final String CA_SALES_ROLE = 'Sales - CA';
  public static final String ERS_CUSTOM_PERMISSION = 'ERS_Equip_Rental_Specialist';
  private static Map<String, AddOn_Details> forcedItemsProductMap = new Map<String, AddOn_Details>();
  private static Map<String, AddOn_Details> rentalForcedItemsProductMap = new Map<String, AddOn_Details>();

  public SBR_3_0_SpotlightPanelCmpController() {
    //add stuff that needs to be initialized when spotlight panel is loaded
  }

  @AuraEnabled(cacheable=true)
  public static boolean hasAddLinesAccess(String recordId) {
    if (recordId != null) {
      Id recId = (Id) recordId;
      User currentUser = SBR_3_0_UserDA.getUserById(UserInfo.getUserId());
      String objectApi = recId.getSObjectType().getDescribe().getName();
      // SAL-26606
      if (objectApi == 'SBQQ__Quote__c') {
        SBQQ__Quote__c currentRecord = SBR_3_0_QuoteDA.getQuote(recordId);
        if (
          !(((currentUser.UserRole.Name == US_SALES_ROLE ||
          currentUser.UserRole.Name == CA_SALES_ROLE) &&
          currentRecord.OwnerId == currentUser.Id) ||
          ((currentUser.UserRole.Name == US_SALES_ROLE ||
          currentUser.UserRole.Name == CA_SALES_ROLE) &&
          currentRecord.CreatedById == currentUser.Id) ||
          ((currentUser.UserRole.Name == US_SALES_ROLE ||
          currentUser.UserRole.Name == CA_SALES_ROLE) &&
          currentRecord.SBQQ__SalesRep__c == currentUser.Id) ||
          (currentUser.UserRole.Name <> US_SALES_ROLE &&
          currentUser.UserRole.Name <> CA_SALES_ROLE) ||
          FeatureManagement.checkPermission(ERS_CUSTOM_PERMISSION))
        ) {
          return false;
        }
        return true;
      } else if (objectApi == 'Order') {
        Order currentRecord = SBR_3_0_OrderDA.getOrder(recordId);
        if (
          !(((currentUser.UserRole.Name == US_SALES_ROLE ||
          currentUser.UserRole.Name == CA_SALES_ROLE) &&
          currentRecord.OwnerId == currentUser.Id) ||
          ((currentUser.UserRole.Name == US_SALES_ROLE ||
          currentUser.UserRole.Name == CA_SALES_ROLE) &&
          currentRecord.CreatedById == currentUser.Id) ||
          ((currentUser.UserRole.Name == US_SALES_ROLE ||
          currentUser.UserRole.Name == CA_SALES_ROLE) &&
          currentRecord.Sales_Rep__c == currentUser.Id) ||
          (currentUser.UserRole.Name <> US_SALES_ROLE &&
          currentUser.UserRole.Name <> CA_SALES_ROLE) ||
          FeatureManagement.checkPermission(ERS_CUSTOM_PERMISSION))
        ) {
          return false;
        }
        return true;
      }
      return true;
    }
    return true;
  }

  //method to fetch and consolidate all product details
  @AuraEnabled(cacheable=true)
  public static String getAllProductDetails() {
    return 'productDetails';
  }

  //method to fetch details of selected product
  @AuraEnabled(cacheable=true)
  public static String getProductDetails(String productId) {
    Product2 p = SBR_3_0_ProductDA.getProductById(productId);
    Product_Details pd = new Product_Details(p);
    system.debug(JSON.serializePretty(pd));
    return JSON.serializePretty(pd);
  }

  //method to fetch details of multiple selected products
  @AuraEnabled(cacheable=true)
  public static List<AddOn_Details> getBulkProductDetails(
    List<String> productIds,
    String customerNumberParam
  ) {
    List<AddOn_Details> bulkDetails = new List<AddOn_Details>();

    for (
      Product2 bulkItem : SBR_3_0_ProductDA.getProductsById(
          new Set<String>(productIds)
        )
        .values()
    ) {
      bulkDetails.add(new AddOn_Details(bulkItem));
    }

    return mapRatesToProductList(bulkDetails, customerNumberParam);
  }

  //for Testing Purpose
  @AuraEnabled(cacheable=true) //FRONT-11329
  public static String getBulkAssetsProductDetails(
    List<String> productIds,
    String customerNumberParam
  ) {
    List<AddOn_Details> bulkDetails = new List<AddOn_Details>();
    Map<String, Asset> mapAssetList = new Map<String, Asset>(
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
        WHERE Id IN :productIds
      ]
    );
    for (Asset bulkItem : mapAssetList.values()) {
      bulkDetails.add(new AddOn_Details(bulkItem));
    }
    return JSON.serializePretty(
      mapRatesToAssetProductList(bulkDetails, customerNumberParam)
    );
  }
  //method to fetch add ons for selected product
  @AuraEnabled(cacheable=true)
  public static String getProductAddOns(
    String productId,
    String companyCode,
    String recordId,
    String branch
  ) {
    system.debug('company code: ' + companyCode);
    system.debug('product id: ' + productId);
    List<AddOn_Details> salesAO = new List<AddOn_Details>();
    List<AddOn_Details> rentalAO = new List<AddOn_Details>();
    //SAL-24085
    List<AddOn_Details> forcedItems = new List<AddOn_Details>();

    System.debug('company code : ' + companyCode);
    System.debug('productId: ' + productId);
    System.debug(
      'sales product options size : ' +
      SBR_3_0_ProductDA.getProductOptionsWithCompanyCode(
          productId,
          companyCode,
          'Sales Addons'
        )
        .size()
    );
    for (
      SBQQ__ProductOption__c sAO : SBR_3_0_ProductDA.getProductOptionsWithCompanyCode(
        productId,
        companyCode,
        'Sales Addons'
      )
    ) {
      salesAO.add(new AddOn_Details(sAO));
      System.debug(sAO.SBQQ__OptionalSKU__r.Name);
    }
    System.debug('Sales AO: ' + salesAO);

    System.debug(
      'rental product options size : ' +
      SBR_3_0_ProductDA.getProductOptionsWithCompanyCode(
          productId,
          companyCode,
          'Rental Addons'
        )
        .size()
    );
    for (
      SBQQ__ProductOption__c rAO : SBR_3_0_ProductDA.getProductOptionsWithCompanyCode(
        productId,
        companyCode,
        'Rental Addons'
      )
    ) {
      rentalAO.add(new AddOn_Details(rAO));
    }

    // for (SBQQ__ProductOption__c forcedItemProd : SBR_3_0_ProductDA.getProductOptionsWithCompanyCode(productId, companyCode, 'Forced Item') ) {
    //     forcedItems.add(new AddOn_Details(forcedItemProd));
    // }

    //24085, 25115
    List<AddOn_Details> salesAddonsWithForcedItems = mapConsumbalesToSalesForcedList(
      salesAO,
      productId,
      recordId,
      forcedItems
    );
    List<AddOn_Details> rentalAddonsWithForcedItems = mapBranchRatesToProductList(
      rentalAO,
      null,
      branch
    );

    // for(AddOn_Details forcedItem : forcedItems){
    //     if(!rentalForcedItemsProductMap.isEmpty() && rentalForcedItemsProductMap.containsKey(forcedItem.catClass) ){
    //         AddOn_Details rentableForceItem = rentalForcedItemsProductMap.get(forcedItem.catClass);
    //         rentalAddonsWithForcedItems.add(rentableForceItem);
    //         forcedItemsProductMap.put(forcedItem.catClass, rentableForceItem);
    //     }
    // }
    System.debug('salesAddonsWithForcedItems: ' + salesAddonsWithForcedItems);
    System.debug('rentalAddonsWithForcedItems: ' + rentalAddonsWithForcedItems);
    Product_AddOns productAO = new Product_AddOns(
      salesAddonsWithForcedItems,
      rentalAddonsWithForcedItems
    );
    // if(!forcedItemsProductMap.isEmpty()){
    //     //commente by VP temporarily
    //     //productAO.forcedItemAddOns = forcedItemsProductMap.values();
    // }

    //Product_AddOns productAO = new Product_AddOns(salesAO, mapRatesToProductList(rentalAO));
    System.debug('\n @@ addons - ' + productAO);
    return JSON.serializePretty(productAO);
  }

  //method to fetch alternate products for selected product
  @AuraEnabled(cacheable=true)
  public static String getAlternateProducts(
    String productId,
    String companyCode
  ) {
    Product2 product = SBR_3_0_ProductDA.getProductById(productId);
    List<AddOn_Details> alternateItems = new List<AddOn_Details>();

    for (
      Product2 altItems : SBR_3_0_ProductDA.getAlternateProducts(
        productId,
        companyCode,
        product.Product_Sub_Category__c,
        product.Product_Hierarchy__r.Product_Hierarchy_Code__c
      )
    ) {
      alternateItems.add(new AddOn_Details(altItems));
    }
    // ATI
    //Rates
    return JSON.serializePretty(mapRatesToProductList(alternateItems, null));
  }
  public static List<AddOn_Details> mapBranchRatesToProductList(
    List<AddOn_Details> productList,
    String customerNumberParam,
    String branch
  ) {
    Map<String, AddOn_Details> productMap = new Map<String, AddOn_Details>();
    List<String> productSKUs = new List<String>();
    List<Rates> products = new List<Rates>();
    Rates currentProduct;
    for (AddOn_Details prod : productList) {
      if (prod.catClass != null) {
        prod.addonType = 'rental';
        prod.itemType = 'rental';
        productMap.put(prod.catClass, prod);
        if (prod.catClass.isNumeric()) {
          currentProduct = new Rates();
          currentProduct.productId = prod.catClass;
          currentProduct.pc = branch;
          products.add(currentProduct);
          productSKUs.add(prod.catClass);
        }
      } else {
        productMap.put(prod.id, prod);
      }
    }

    if (!productSKUs.isEmpty()) {
      String customerNumber = '';
      if (customerNumberParam != null) {
        customerNumber = customerNumberParam;
      }
      String retVal = getProductRates(
        new GetProductRatesWrapper(customerNumber, products)
      );

      Map<String, Object> rates = (Map<String, Object>) JSON.deserializeUntyped(
        retVal
      );

      if (rates != null && !rates.isEmpty()) {
        Map<String, Object> data = (Map<String, Object>) rates.get('data');

        if (data != null && !data.isEmpty()) {
          List<Object> items = (List<Object>) data.get('items');

          if (items != null && !items.isEmpty()) {
            for (Integer i = 0; i < items.size(); i++) {
              Map<String, Object> item = (Map<String, Object>) items[i];
              Map<String, Object> ratesGroup = (Map<String, Object>) item.get(
                'rates'
              );
              Map<String, Object> suggestedRates = (Map<String, Object>) ratesGroup.get(
                'suggestedRates'
              );
              String pId = (String) item.get('productId');
              String pc = (String) item.get('pc');
              System.debug(' pId = ' + pId);
              System.debug(' productSKUs = ' + productSKUs);
              System.debug(' contain : ' + productSKUs.contains(pId));
              if (productSKUs.contains(pId)) {
                productMap.get(pId).minRate = (String) suggestedRates.get(
                  'minimum'
                );
                productMap.get(pId).ratesDaily = (String) suggestedRates.get(
                  'daily'
                );
                productMap.get(pId).ratesWeekly = (String) suggestedRates.get(
                  'weekly'
                );
                productMap.get(pId).ratesMonthly = (String) suggestedRates.get(
                  'monthly'
                );
                productMap.get(pId).rateFlag = (String) item.get('rateFlag');
                productMap.get(pId).notToExceed = String.isBlank(
                    (String) item.get('notToExceed')
                  )
                  ? ''
                  : (String) item.get('notToExceed');
                productMap.get(pId).rateBranch = pc;
              }
            }
          }
        }
      }
    }
    system.debug('###Product Map: ' + productMap.values());
    return productMap.values();
  }
  //method takes a list of products and adds rates if they exist
  public static List<AddOn_Details> mapRatesToAssetProductList(
    List<AddOn_Details> productList,
    String customerNumberParam
  ) {
    Map<String, AddOn_Details> productMap = new Map<String, AddOn_Details>();
    List<String> productSKUs = new List<String>();
    for (AddOn_Details prod : productList) {
      if (prod.catClass != null) {
        productMap.put(prod.catClass + '-' + prod.assetid, prod);
        if (prod.catClass.isNumeric()) {
          productSKUs.add(prod.catClass);
        }
      } else {
        productMap.put(prod.id, prod);
      }
    }
    if (!productSKUs.isEmpty()) {
      String customerNumber = '';
      if (customerNumberParam != null) {
        customerNumber = customerNumberParam;
      }
      String retVal = getProductRatesNew(
        new GetProductRatesWrapperNew(customerNumber, productSKUs)
      );
      Map<String, Object> rates = (Map<String, Object>) JSON.deserializeUntyped(
        retVal
      );
      if (rates != null && !rates.isEmpty()) {
        Map<String, Object> data = (Map<String, Object>) rates.get('data');
        if (data != null && !data.isEmpty()) {
          List<Object> items = (List<Object>) data.get('items');
          if (items != null && !items.isEmpty()) {
            for (Integer i = 0; i < items.size(); i++) {
              Map<String, Object> item = (Map<String, Object>) items[i];
              Map<String, Object> ratesGroup = (Map<String, Object>) item.get(
                'rates'
              );
              Map<String, Object> suggestedRates = (Map<String, Object>) ratesGroup.get(
                'suggestedRates'
              );
              String pId = (String) item.get('productId');
              System.debug(' pId = ' + pId);
              System.debug(' productSKUs = ' + productSKUs);
              System.debug(' contain : ' + productSKUs.contains(pId));
              if (productSKUs.contains(pId)) {
                for (AddOn_Details prod : productList) {
                  string key = pId + '-' + prod.assetid;
                  if (productMap.containsKey(key)) {
                    productMap.get(key).minRate = (String) suggestedRates.get(
                      'minimum'
                    );
                    productMap.get(key)
                      .ratesDaily = (String) suggestedRates.get('daily');
                    productMap.get(key)
                      .ratesWeekly = (String) suggestedRates.get('weekly');
                    productMap.get(key)
                      .ratesMonthly = (String) suggestedRates.get('monthly');
                    productMap.get(key).rateFlag = (String) item.get(
                      'rateFlag'
                    );
                    productMap.get(key).notToExceed = String.isBlank(
                        (String) item.get('notToExceed')
                      )
                      ? ''
                      : (String) item.get('notToExceed');
                  }
                }
              }
            }
          }
        }
      }
    }
    system.debug('Product Map: ' + productMap.values());
    return productMap.values();
  }
  //method takes a list of products and adds rates if they exist
  public static List<AddOn_Details> mapRatesToProductList(
    List<AddOn_Details> productList,
    String customerNumberParam
  ) {
    Map<String, AddOn_Details> productMap = new Map<String, AddOn_Details>();
    List<String> productSKUs = new List<String>();

    for (AddOn_Details prod : productList) {
      if (prod.catClass != null) {
        productMap.put(prod.catClass, prod);
        if (prod.catClass.isNumeric()) {
          productSKUs.add(prod.catClass);
        }
      } else {
        productMap.put(prod.id, prod);
      }
    }

    if (!productSKUs.isEmpty()) {
      String customerNumber = '';
      if (customerNumberParam != null) {
        customerNumber = customerNumberParam;
      }
      String retVal = getProductRatesNew(
        new GetProductRatesWrapperNew(customerNumber, productSKUs)
      );

      Map<String, Object> rates = (Map<String, Object>) JSON.deserializeUntyped(
        retVal
      );

      if (rates != null && !rates.isEmpty()) {
        Map<String, Object> data = (Map<String, Object>) rates.get('data');

        if (data != null && !data.isEmpty()) {
          List<Object> items = (List<Object>) data.get('items');

          if (items != null && !items.isEmpty()) {
            for (Integer i = 0; i < items.size(); i++) {
              Map<String, Object> item = (Map<String, Object>) items[i];
              Map<String, Object> ratesGroup = (Map<String, Object>) item.get(
                'rates'
              );
              Map<String, Object> suggestedRates = (Map<String, Object>) ratesGroup.get(
                'suggestedRates'
              );
              String pId = (String) item.get('productId');
              String pc = (String) item.get('pc');
              System.debug(' pId = ' + pId);
              System.debug(' productSKUs = ' + productSKUs);
              System.debug(' contain : ' + productSKUs.contains(pId));
              if (productSKUs.contains(pId)) {
                productMap.get(pId).minRate = (String) suggestedRates.get(
                  'minimum'
                );
                productMap.get(pId).ratesDaily = (String) suggestedRates.get(
                  'daily'
                );
                productMap.get(pId).ratesWeekly = (String) suggestedRates.get(
                  'weekly'
                );
                productMap.get(pId).ratesMonthly = (String) suggestedRates.get(
                  'monthly'
                );
                productMap.get(pId).rateFlag = (String) item.get('rateFlag');
                productMap.get(pId).notToExceed = String.isBlank(
                    (String) item.get('notToExceed')
                  )
                  ? ''
                  : (String) item.get('notToExceed');
                productMap.get(pId).rateBranch = pc;
              }
            }
          }
        }
      }
    }
    system.debug('Product Map: ' + productMap.values());
    return productMap.values();
  }

  public static List<AddOn_Details> mapConsumbalesToSalesForcedList(
    List<AddOn_Details> salesList,
    String productId,
    String recordId,
    List<AddOn_Details> forcedItems
  ) {
    Map<String, AddOn_Details> productMap = new Map<String, AddOn_Details>();
    Map<String, AddOn_Details> updatedProductMap = new Map<String, AddOn_Details>();
    Map<String, Decimal> availQuantityMap = new Map<String, Decimal>();
    List<String> productItemNumbers = new List<String>();
    Set<String> itemNumberSet = new Set<String>();
    for (AddOn_Details sale : salesList) {
      sale.addonType = 'SalesAddon'; // To identify the addon type on spotlight panel
      sale.itemType = 'sales';
      if (sale.catClass != null) {
        productMap.put(sale.catClass, sale);
        productItemNumbers.add(sale.catClass); //Revise
        itemNumberSet.add(sale.itemNumber);
      } else {
        productMap.put(sale.id, sale); //Revise
      }
    }
    //24085
    for (AddOn_Details forcedItem : forcedItems) {
      forcedItem.addonType = 'ForcedItem';
      if (forcedItem.catClass != null) {
        productMap.put(forcedItem.catClass, forcedItem);
        productItemNumbers.add(forcedItem.catClass);
        itemNumberSet.add(forcedItem.itemNumber);
      } else {
        productMap.put(forcedItem.id, forcedItem);
      }
    }
    Set<String> salesAddonProductNumberSet = new Set<String>();
    //24085
    Set<String> forcedItemAddonProductNumberSet = new Set<String>();
    Map<String, Decimal> minQuantityMap = new Map<String, Decimal>();

    String branchNumber;
    if (!productItemNumbers.isEmpty()) {
      String customerNumber = '';
      System.debug(' product Item numbers : ' + productItemNumbers);
      // Find pc from recordId
      if (recordId == null || recordId == '') {
        branchNumber = SBR_3_0_UserDA.getUserById(UserInfo.getUserId())
          .Department;
      } else {
        Id sObjectId = (Id) recordId;
        String sObjectName = sObjectId.getSObjectType().getDescribe().getName();
        if (sObjectName == 'Cart__c') {
          Cart__c cart = SBR_3_0_CartDA.getCart(sObjectId);
          branchNumber = cart.Branch__r.Branch_Location_Number__c;
        } else if (sObjectName == 'SBQQ__Quote__c') {
          SBQQ__Quote__c quote = SBR_3_0_QuoteDA.getQuote(sObjectId);
          branchNumber = quote.Branch__r.Branch_Location_Number__c;
        } else if (sObjectName == 'Order') {
          Order order = SBR_3_0_OrderDA.getOrder(sObjectId);
          branchNumber = order.Branch__r.Branch_Location_Number__c;
        } else {
          branchNumber = SBR_3_0_UserDA.getUserById(UserInfo.getUserId())
            .Department;
        }
      }
      String retVal = getConsumablesResponse(productId, branchNumber);
      System.debug('@@@consResponse');
      System.debug(JSON.serialize(retVal));
      Map<String, Object> rates = (Map<String, Object>) JSON.deserializeUntyped(
        retVal
      );

      if (rates != null && !rates.isEmpty()) {
        Map<String, Object> data = (Map<String, Object>) rates.get('data');

        if (data != null && !data.isEmpty()) {
          List<Object> suggestedItems = (List<Object>) data.get(
            'suggestedItems'
          );

          if (suggestedItems != null && !suggestedItems.isEmpty()) {
            System.debug('@@@insuggestedItemsArray');
            System.debug('suggestedItems : ' + suggestedItems.size());
            for (Integer i = 0; i < suggestedItems.size(); i++) {
              Map<String, Object> items = (Map<String, Object>) suggestedItems[
                i
              ];
              List<Object> consumables = (List<Object>) items.get(
                'consumables'
              );
              for (Integer j = 0; j < consumables.size(); j++) {
                Map<String, Object> consumable = (Map<String, Object>) consumables[
                  j
                ];
                List<Object> specGroups = (List<Object>) consumable.get(
                  'specGroups'
                );

                for (Integer k = 0; k < specGroups.size(); k++) {
                  Map<String, Object> specGroup = (Map<String, Object>) specGroups[
                    k
                  ];
                  List<Object> products = (List<Object>) specGroup.get(
                    'products'
                  );
                  // SAL-25055
                  if (products != null && products.size() > 0) {
                    for (Integer l = 0; l < products.size(); l++) {
                      Map<String, Object> product = (Map<String, Object>) products[
                        l
                      ];
                      String prodstockClass = (String) product.get(
                        'stockClass'
                      );
                      String productNumber = (String) product.get(
                        'productNumber'
                      );
                      String regionNumber = getCompanyId();
                      salesAddonProductNumberSet.add(productNumber);
                      //24085
                      Boolean isForceItem = (String) product.get('forceItem') ==
                        'Y'
                        ? true
                        : false;
                      if (isForceItem) {
                        forcedItemAddonProductNumberSet.add(productNumber);
                        if (product.get('minQuantity') != null) {
                          minQuantityMap.put(
                            productNumber,
                            (Decimal) product.get('minQuantity')
                          ); // SAL-24085
                        }
                      }
                      String pId =
                        customerNumber +
                        '-' +
                        prodstockClass +
                        '-' +
                        productNumber;
                      System.debug('pId-->' + pId);
                      System.debug('prodstockClass-->' + prodstockClass);
                      if (productItemNumbers.contains(pId)) {
                        productMap.get(pId).sellPrice = (Decimal) product.get(
                          'sellingPrice'
                        );
                      }
                      if (product.get('availQuantity') != null) {
                        availQuantityMap.put(
                          productNumber,
                          (Decimal) product.get('availQuantity')
                        ); // SAL-22398
                      }
                    }
                  }
                }
              }
              //START 25115
              List<Object> rentables = (List<Object>) items.get('rentables');
              for (Integer j = 0; j < rentables.size(); j++) {
                Map<String, Object> rentable = (Map<String, Object>) rentables[
                  j
                ];
                if (rentable != null) {
                  String equipmentNumber = (String) rentable.get(
                    'equipmentNumber'
                  );
                  System.debug('equipmentNumber-->' + equipmentNumber);

                  Boolean isForceItem = (String) rentable.get('forceItem') ==
                    'Y'
                    ? true
                    : false;
                  if (isForceItem && equipmentNumber != null) {
                    //forcedItemAddonProductNumberSet.add(equipmentNumber);
                    if (productItemNumbers.contains(equipmentNumber)) {
                      if (rentable.get('minQuantity') != null) {
                        productMap.get(equipmentNumber)
                          .minQuantity = (Decimal) rentable.get('minQuantity');
                      }
                      if (rentable.get('minRate') != null) {
                        productMap.get(equipmentNumber)
                          .minRate = String.valueOf(rentable.get('minRate'));
                      }
                      if (rentable.get('dayRate') != null) {
                        productMap.get(equipmentNumber)
                          .ratesDaily = String.valueOf(rentable.get('dayRate'));
                      }
                      if (rentable.get('wkRate') != null) {
                        productMap.get(equipmentNumber)
                          .ratesWeekly = String.valueOf(rentable.get('wkRate'));
                      }
                      if (rentable.get('moRate') != null) {
                        productMap.get(equipmentNumber)
                          .ratesMonthly = String.valueOf(
                          rentable.get('moRate')
                        );
                      }
                      productMap.get(equipmentNumber).sellPrice = 0.1;

                      rentalForcedItemsProductMap.put(
                        equipmentNumber,
                        productMap.get(equipmentNumber)
                      );
                    }
                  }
                }
              }
              //END 25115
            }
          }
        }
      }
    }

    // Compare salesAddon with what consumable api returned. We will keep only the common values to be shown on spotlight panel UI - SAL-22398
    for (String productKey : productMap.keyset()) {
      AddOn_Details adDetails = productMap.get(productKey);
      if (salesAddonProductNumberSet.contains(adDetails.itemNumber)) {
        if (availQuantityMap.get(adDetails.itemNumber) != null) {
          adDetails.availQuantity = availQuantityMap.get(adDetails.itemNumber);
        }
        updatedProductMap.put(productKey, adDetails);
      }
      //24085
      if (
        !forcedItemAddonProductNumberSet.isEmpty() &&
        ((adDetails.itemNumber != null &&
        forcedItemAddonProductNumberSet.contains(adDetails.itemNumber)) ||
        forcedItemAddonProductNumberSet.contains(adDetails.catClass))
      ) {
        if (minQuantityMap.get(adDetails.itemNumber) != null) {
          adDetails.minQuantity = minQuantityMap.get(adDetails.itemNumber);
        }
        forcedItemsProductMap.put(productKey, adDetails);
      }
    }
    system.debug('Updated Product Map Values: ' + updatedProductMap.values());
    return updatedProductMap.values();
  }

  //method to fetch kit components of selected product
  @AuraEnabled(cacheable=true)
  public static String getProductKitComponents(String productId) {
    List<SBQQ__ProductOption__c> p = SBR_3_0_ProductDA.getProductKitComponents(
      productId
    );
    return JSON.serializePretty(p);
  }

  @AuraEnabled(cacheable=true)
  public static String getProductRatesNew(GetProductRatesWrapperNew prwrapper) {
    system.debug(
      'customer number on rate request: ' + prwrapper.customerNumber
    );
    User loggedInUser = SBR_3_0_UserDA.getUserById(UserInfo.getUserId());
    Integer pc = Integer.valueOf(loggedInUser.Department);
    String companyId = '1'; //companyId here is the company code to indicate whether it's US(1) or Canada(2)
    if (loggedInUser.CompanyName != null && loggedInUser.CompanyName != '') {
      companyId = String.valueOf(Integer.valueOf(loggedInUser.CompanyName));
    }
    Rates_API_Request_BodyNew req = new Rates_API_Request_BodyNew(
      pc,
      prwrapper.products,
      prwrapper.customerNumber
    );
    String response = SBR_3_0_API_Rates.getRates(
      JSON.serializePretty(req, true),
      companyId
    );
    System.debug('response-->' + response);
    return response;
  }
  //method to fetch rates of selected products
  @AuraEnabled(cacheable=true)
  public static String getProductRates(GetProductRatesWrapper prwrapper) {
    system.debug(
      'customer number on rate request: ' + prwrapper.customerNumber
    );
    User loggedInUser = SBR_3_0_UserDA.getUserById(UserInfo.getUserId());
    Integer pc = Integer.valueOf(loggedInUser.Department);
    String companyId = '1'; //companyId here is the company code to indicate whether it's US(1) or Canada(2)
    if (loggedInUser.CompanyName != null && loggedInUser.CompanyName != '') {
      companyId = String.valueOf(Integer.valueOf(loggedInUser.CompanyName));
    }
    Rates_API_Request_Body req = new Rates_API_Request_Body(
      prwrapper.products,
      prwrapper.customerNumber
    );
    System.debug('###New Request' + JSON.serializePretty(req, true));
    String response = SBR_3_0_API_Rates.getRates(
      JSON.serializePretty(req, true),
      companyId
    );
    System.debug('response-->' + response);
    return response;
  }

  @AuraEnabled(cacheable=true)
  public static String getCompanyId() {
    User loggedInUser = SBR_3_0_UserDA.getUserById(UserInfo.getUserId());
    Integer pc = Integer.valueOf(loggedInUser.Department);
    String companyId = '1'; //companyId here is the company code to indicate whether it's US(1) or Canada(2)
    if (loggedInUser.CompanyName != null && loggedInUser.CompanyName != '') {
      companyId = String.valueOf(Integer.valueOf(loggedInUser.CompanyName));
    }
    return companyId;
  }

  @AuraEnabled(cacheable=true)
  public static String getConsumablesResponse(
    String productId,
    String branchNumber
  ) {
    String companyId = getCompanyId();

    Product2 selectedItem = SBR_3_0_ProductDA.getProductById(productId);
    String catId = selectedItem.Product_SKU__c.substring(0, 3);
    String classId = selectedItem.Product_SKU__c.substring(3);

    List<Consumables_API_Request_Body_Product> products = new List<Consumables_API_Request_Body_Product>();
    Consumables_API_Request_Body_Product prod = new Consumables_API_Request_Body_Product(
      catId,
      classId
    );
    products.add(prod);

    Consumables_API_Request_Body req = new Consumables_API_Request_Body(
      products
    );
    if (String.isNotEmpty(branchNumber)) {
      req.pc = branchNumber;
    }

    String response = SBR_3_0_API_Consumables.getConsumableRates(
      JSON.serialize(req, true),
      companyId
    );
    system.debug('consumables Request: ' + JSON.serialize(req, true));
    system.debug('consumables Response: ' + response);
    return response;
  }

  //wrapper class for req for getProductRates
  public class GetProductRatesWrapperNew {
    @AuraEnabled
    public String customerNumber { get; set; }
    @AuraEnabled
    public List<String> products { get; set; }

    public GetProductRatesWrapperNew() {
    }
    public GetProductRatesWrapperNew(
      String customerNumber,
      List<String> products
    ) {
      this.customerNumber = customerNumber;
      this.products = products;
    }
  }
  public class GetProductRatesWrapper {
    @AuraEnabled
    public String customerNumber { get; set; }
    @AuraEnabled
    public List<Rates> products { get; set; }

    public GetProductRatesWrapper() {
    }
    public GetProductRatesWrapper(String customerNumber, List<Rates> products) {
      this.customerNumber = customerNumber;
      this.products = products;
    }
  }
  public class Rates {
    @AuraEnabled
    public String pc { get; set; }
    @AuraEnabled
    public String productId { get; set; }
    public Rates() {
    }
    public Rates(String pc, String productId) {
      this.pc = pc;
      this.productId = productId;
    }
  }

  public class AddOnsWrapper {
    @AuraEnabled
    public String prodAddOns { get; set; }
    @AuraEnabled
    public String response { get; set; }
  }
  public class Rates_API_Request_BodyNew {
    public Integer accountNumber { get; set; }
    public String jobsite { get; set; }
    public Integer pc { get; set; }
    public List<Rates_API_Request_Body_Product> products { get; set; }

    public Rates_API_Request_BodyNew(
      Integer pc,
      List<String> productIds,
      String accountNumber
    ) {
      this.pc = pc;
      List<Rates_API_Request_Body_Product> pl = new List<Rates_API_Request_Body_Product>();
      for (String productId : productIds) {
        pl.add(new Rates_API_Request_Body_Product(productId));
      }
      this.products = pl;
      if (String.isNotEmpty(accountNumber)) {
        if (accountNumber.contains('-')) {
          accountNumber = accountNumber.subStringAfter('-');
        }
        this.accountNumber = Integer.valueOf(accountNumber);
      }
    }
  }
  //wrapper class for requestBody for Rates API
  public class Rates_API_Request_Body {
    public String accountNumber { get; set; }
    public String jobsite { get; set; }
    // public Integer pc {get; set;}
    public List<Rates> products { get; set; }

    public Rates_API_Request_Body(
      List<Rates> productIds,
      String accountNumber
    ) {
      //this.pc = pc;
      /*  List<Rates_API_Request_Body_Product> pl = new List<Rates_API_Request_Body_Product>();
                for (String productId : productIds){
                    pl.add(new Rates_API_Request_Body_Product(productId));
                }*/
      this.products = productIds;
      if (String.isNotEmpty(accountNumber)) {
        if (accountNumber.contains('-')) {
          accountNumber = accountNumber.subStringAfter('-');
        }
        this.accountNumber = accountNumber;
      }
    }
  }

  //wrapper class for products in Rates API request body
  public class Rates_API_Request_Body_Product {
    public String productId { get; set; }
    public Rates_API_Request_Body_Product(String productId) {
      this.productId = productId;
    }
  }

  public class Consumables_API_Request_Body {
    public List<Consumables_API_Request_Body_Product> products { get; set; }
    public String pc { get; set; }
    public Consumables_API_Request_Body(
      List<Consumables_API_Request_Body_Product> products
    ) {
      this.products = products;
    }
  }

  public class Consumables_API_Request_Body_Product {
    public String catId { get; set; }
    public String classId { get; set; }
    public Consumables_API_Request_Body_Product(String catId, String classId) {
      this.catId = catId;
      this.classId = classId;
    }
  }

  //method to fetch availabilities of selected products
  @AuraEnabled(cacheable=true)
  public static List<String> getProductAvailabilities(
    List<String> products,
    string type
  ) {
    List<String> rows = new List<String>();
    if (!products.isEmpty() && type == 'overview') {
      String Row = '[{"label": "Branch", "available": 5, "reserve": 6, "pickUp": 7, "utilization": "50%"},{"label": "District", "available": 5, "reserve": 6, "pickUp": 7, "utilization": "50%"},{"label": "Region", "available": 3, "reserve": 2, "pickUp": 5, "utilization": "70%"},{"label": "Territory", "available": 4, "reserve": 8, "pickUp": 1, "utilization": "90%"},{"label": "Company", "available": 1, "reserve": 2, "pickUp": 3, "utilization": "20%"}]';
      rows.add(row);
    } else if (!products.isEmpty() && type.toLowerCase() == 'branches') {
      String Row = '[{"label": "Branch 101", "available": 5, "reserve": 6, "pickUp": 7, "utilization": "50%"},{"label": "Branch 102", "available": 5, "reserve": 6, "pickUp": 7, "utilization": "50%"},{"label": "Branch 103", "available": 3, "reserve": 2, "pickUp": 5, "utilization": "70%"},{"label": "Branch 104", "available": 4, "reserve": 8, "pickUp": 1, "utilization": "90%"},{"label": "Branch 201", "available": 1, "reserve": 2, "pickUp": 3, "utilization": "20%"}]';
      rows.add(row);
    } else {
      CalloutException e = new CalloutException();
      e.setMessage('No Data loaded');
      throw e;
    }
    return rows;
  }

  @AuraEnabled(cacheable=true)
  public static Schema.Location getBranchChronosDetailsNew(
    String recordId,
    String objectAPIName
  ) {
    Schema.location branch = new schema.location();
    try {
      List<Schema.Location> userLocation = new List<Schema.Location>();
      SBR_3_0_Log.setRelatedRecordId(recordId);
      if (objectAPIName == 'SBQQ__Quote__c') {
        SBQQ__Quote__c quote = [
          SELECT
            Id,
            OMS_Sourcing_Enabled__c,
            Sourcing_Branch__c,
            Sourcing_Branch__r.OMS_Sourcing_Enabled__c,
            Branch__c,
            Branch__r.OMS_Sourcing_Enabled__c
          FROM SBQQ__Quote__c
          WHERE Id = :recordId
          LIMIT 1
        ];
        if (
          quote.Sourcing_Branch__c != null &&
          quote.Sourcing_Branch__r.OMS_Sourcing_Enabled__c
        ) {
          userLocation = SBR_3_0_BranchDA.getSourcingBranchLocation(
            quote.Sourcing_Branch__c
          );
        } else if (
          quote.Branch__c != null && quote.Branch__r.OMS_Sourcing_Enabled__c
        ) {
          userLocation = SBR_3_0_BranchDA.getSourcingBranchLocation(
            quote.Branch__c
          );
        } else {
          userLocation = SBR_3_0_BranchDA.getLoggedInUserLocation();
        }
        return userLocation[0];
      } else if (objectAPIName == 'Order') {
        // added for SAL-26257
        Order orderRec = [
          SELECT
            Id,
            OMS_Sourcing_Enabled__c,
            Sourcing_Branch__c,
            Sourcing_Branch__r.OMS_Sourcing_Enabled__c,
            Branch__c,
            Branch__r.OMS_Sourcing_Enabled__c
          FROM Order
          WHERE Id = :recordId
          LIMIT 1
        ];
        if (
          orderRec.Sourcing_Branch__c != null &&
          orderRec.Sourcing_Branch__r.OMS_Sourcing_Enabled__c
        ) {
          userLocation = SBR_3_0_BranchDA.getSourcingBranchLocation(
            orderRec.Sourcing_Branch__c
          );
        } else if (
          orderRec.Branch__c != null &&
          orderRec.Branch__r.OMS_Sourcing_Enabled__c
        ) {
          userLocation = SBR_3_0_BranchDA.getSourcingBranchLocation(
            orderRec.Branch__c
          );
        } else {
          userLocation = SBR_3_0_BranchDA.getLoggedInUserLocation();
        }
        return userLocation[0];
      } else {
        userLocation = SBR_3_0_BranchDA.getLoggedInUserLocation();
        return userLocation[0];
      }
    } catch (QueryException e) {
      e.setMessage('No user location found.');
      SBR_3_0_Log.logException(e);
    } finally {
      SBR_3_0_Log.saveLog();
    }
    return branch;
  }

  @AuraEnabled(cacheable=true)
  public static Schema.Location getBranchChronosDetails() {
    Schema.location branch = new schema.location();
    try {
      List<Schema.Location> userLocation = SBR_3_0_BranchDA.getLoggedInUserLocation();
      return userLocation[0];
    } catch (QueryException e) {
      e.setMessage('No user location found.');
      SBR_3_0_Log.logException(e);
    } finally {
      SBR_3_0_Log.saveLog();
    }
    return branch;
  }

  @AuraEnabled(cacheable=true)
  public static BranchDetails getProfileBranchChronosDetails(
    Id objectId,
    String objectApiName
  ) {
    Schema.location branch = new schema.location();
    BranchDetails branchDetails = new BranchDetails();
    branchDetails.isChronosEnabled = true;
    Id sourcingBranch;
    try {
      List<Schema.Location> userBranchLocation = SBR_3_0_BranchDA.getLoggedInUserLocation();
      branchDetails.isChronosEnabled = userBranchLocation.isEmpty()
        ? false
        : userBranchLocation[0].OMS_Sourcing_Enabled__c;
      if (!String.isBlank(objectId)) {
        SBR_3_0_Log.setRelatedRecordId(objectId);
        if (objectApiName == 'Order') {
          Order selectedOrder = SBR_3_0_OrderDA.getOrders(
              new Set<Id>{ objectId }
            )
            .values()[0];
          if (selectedOrder.Sourcing_Branch__c != null) {
            SBR_3_0_Log.logInfo(
              String.valueOf(selectedOrder.Sourcing_Branch__c)
            );
            sourcingBranch = selectedOrder.Sourcing_Branch__c;
          } else if (selectedOrder.Jobsite__c != null) {
            List<AssociatedLocation> jobSite = [
              SELECT Id, Branch__c
              FROM AssociatedLocation
              WHERE Id = :selectedOrder.Jobsite__c
            ];
            SBR_3_0_Log.logInfo(String.valueOf(jobSite));
            sourcingBranch = jobSite[0].Branch__c;
          }
        } else if (objectApiName == 'SBQQ__Quote__c') {
          SBQQ__Quote__c selectedQuote = SBR_3_0_QuoteDA.getQuotes(
              new Set<Id>{ objectId }
            )
            .values()[0];
          if (selectedQuote.Sourcing_Branch__c != null) {
            SBR_3_0_Log.logInfo(
              String.valueOf(selectedQuote.Sourcing_Branch__c)
            );
            sourcingBranch = selectedQuote.Sourcing_Branch__c;
          } else if (selectedQuote.Jobsite__c != null) {
            List<AssociatedLocation> jobSite = [
              SELECT Id, Branch__c
              FROM AssociatedLocation
              WHERE Id = :selectedQuote.Jobsite__c
            ];
            SBR_3_0_Log.logInfo(String.valueOf(jobSite));
            sourcingBranch = jobSite[0].Branch__c;
          }
        }
        if (sourcingBranch != null) {
          SBR_3_0_Log.logInfo(String.valueOf(sourcingBranch));
          List<Schema.Location> sourcingLocation = SBR_3_0_BranchDA.getSourcingBranchLocation(
            sourcingBranch
          );
          SBR_3_0_Log.logInfo(String.valueOf(sourcingLocation));
          branchDetails.branch = sourcingLocation.size() > 0
            ? sourcingLocation[0]
            : branch;
          SBR_3_0_Log.logInfo(String.valueOf(branchDetails));
          return branchDetails;
        }
      }

      // Updated for SAL-26964 - Chronos Enabled or OMS Enabled Flag is driven by User Location branch and not profile branch for product inquiry
      // Rest of the details are passed from profile branch, except for OMS flag

      List<Schema.Location> userProfileBranchLocation = SBR_3_0_BranchDA.getLoggedInUserProfileBranchLocation();
      if (userProfileBranchLocation.size() == 0) {
        branchDetails.branch = userBranchLocation[0];
      } else {
        branchDetails.branch = userProfileBranchLocation[0];
      }
      SBR_3_0_Log.logInfo(String.valueOf(branchDetails));
      return branchDetails;
    } catch (QueryException e) {
      e.setMessage('No user profile branch location found.');
      SBR_3_0_Log.logException(e);
    } finally {
      SBR_3_0_Log.saveLog();
    }
    branchDetails.branch = branch;
    return branchDetails;
  }

  // method to fetch phone numbers of list of Branches
  @AuraEnabled(cacheable=true)
  public static List<Schema.location> getBranchPhones(List<String> pcs) {
    List<Schema.location> branches = new List<Schema.location>();
    try {
      branches = SBR_3_0_BranchDA.getBranchPhones(pcs);
      return branches;
    } catch (QueryException e) {
      e.setMessage('No branch phones found.');
      SBR_3_0_Log.logException(e);
    } finally {
      SBR_3_0_Log.saveLog();
    }
    return branches;
  }

  @AuraEnabled(cacheable=true)
  public static string getCartRecordTypeID() {
    String analysisRegionKey;
    String recordTypeId;
    try {
      analysisRegionKey = SBR_3_0_UserLocationDA.getUserLocation(
          UserInfo.getUserId()
        )[0]
        .Analysis_Region_Key__c;
      if (analysisRegionKey == '935') {
        // Oil and Gas
        recordTypeId = Schema.SObjectType.Cart__c.getRecordTypeInfosByDeveloperName()
          .get(SBR_3_0_Constants.CART_REC_TYPE_OIL_GAS)
          .getRecordTypeId();
      } else {
        // Standard
        recordTypeId = Schema.SObjectType.Cart__c.getRecordTypeInfosByDeveloperName()
          .get(SBR_3_0_Constants.CART_REC_TYPE_NAME_STANDARD)
          .getRecordTypeId();
      }
      return recordTypeId;
    } catch (Exception e) {
      SBR_3_0_Log.logException(e);
      throw new AuraHandledException(e.getMessage());
    } finally {
      SBR_3_0_Log.saveLog();
    }
  }

  @AuraEnabled(cacheable=true)
  public static string getOilGasCartRecordTypeID() {
    // Oil and Gas
    return Schema.SObjectType.Cart__c.getRecordTypeInfosByDeveloperName()
      .get(SBR_3_0_Constants.CART_REC_TYPE_OIL_GAS)
      .getRecordTypeId();
  }

  //TODO
  @AuraEnabled
  public static List<SObject> createLineItems(
    String apiName,
    Object lineItems
  ) {
    system.debug('KAH' + lineItems);
    List<SObject> returnList = new List<SObject>();
    List<SBQQ__QuoteLine__c> quoteList = new List<SBQQ__QuoteLine__c>();
    List<OrderItem> orderList = new List<OrderItem>();
    List<Cart_Items__c> cartList = new List<Cart_Items__c>();
    System.debug('apiName->' + apiName);

    List<Object> fieldList = (List<Object>) JSON.deserializeUntyped(
      lineItems.toString()
    );

    for (Object fld : fieldList) {
      Map<String, Object> data = (Map<String, Object>) fld;
      system.debug('field Object->' + data.get('fields'));
      if (apiName == 'SBQQ__Quote__c') {
        SBQQ__QuoteLine__c quoteLine = (SBQQ__QuoteLine__c) JSON.deserializeStrict(
          JSON.serialize(data.get('fields')),
          SBQQ__QuoteLine__c.class
        );
        returnList.add(quoteLine);
        system.debug('quoteLine->' + quoteLine);
      }
      if (apiName == 'Cart__c') {
        Cart_Items__c cartLine = (Cart_Items__c) JSON.deserializeStrict(
          JSON.serialize(data.get('fields')),
          Cart_Items__c.class
        );
        returnList.add(cartLine);
      }
      if (apiName == 'Order') {
        OrderItem orderLine = (OrderItem) JSON.deserializeStrict(
          JSON.serialize(data.get('fields')),
          OrderItem.class
        );
        returnList.add(orderLine);
      }
    }

    if (!returnList.isEmpty()) {
      insert returnList;
      system.debug('returnList->' + returnList);
    }
    return returnList;
  }

  @AuraEnabled(cacheable=true)
  public static Schema.location getProfileBranchDetailsForContracts() {
    Schema.location branch = new schema.location();
    try {
      List<Schema.Location> userProfileBranchLocation = SBR_3_0_BranchDA.getLoggedInUserProfileBranchLocation();
      branch = userProfileBranchLocation[0];
      SBR_3_0_Log.logInfo(String.valueOf(branch));
    } catch (QueryException e) {
      e.setMessage('No user profile branch location found.');
      SBR_3_0_Log.logException(e);
    } finally {
      SBR_3_0_Log.saveLog();
    }
    return branch;
  }

  //wrapper class for productDetails
  public class Product_Details {
    @AuraEnabled
    public String Name { get; set; }
    @AuraEnabled
    public String CatClass { get; set; }
    @AuraEnabled
    public String Weight { get; set; }
    @AuraEnabled
    public String PrimaryImageURL { get; set; }
    @AuraEnabled
    public String Description { get; set; }
    @AuraEnabled
    public String productType { get; set; } //23583
    @AuraEnabled
    public String itemNumber { get; set; } //23583
    @AuraEnabled
    public String stockClass { get; set; } //23583
    @AuraEnabled
    public String unitOfMeasure { get; set; } //FRONT-15259,28872

    public Product_Details(Product2 p) {
      this.Name = p.Name;
      this.CatClass = p.Product_SKU__c;
      this.Weight = String.valueOf(p.MACHINE_WEIGHT_IN_POUNDS__c);
      this.PrimaryImageURL = p.Primary_Image_URL__c;
      this.Description = p.Product_Description__c;
      //23583
      this.productType = p.Product_Type__c;
      this.itemNumber = p.Item_Number__c;
      this.stockClass = p.Stock_class__c;
      this.unitOfMeasure = p.QuantityUnitOfMeasure; //FRONT-15259,28872
    }
  }

  //wrapper class for productAddOns
  public class Product_AddOns {
    @AuraEnabled
    public LIST<AddOn_Details> salesAddOns { get; set; }
    @AuraEnabled
    public LIST<AddOn_Details> rentalAddOns { get; set; }
    @AuraEnabled
    public List<AddOn_Details> forcedItemAddOns { get; set; }

    public Product_AddOns(
      LIST<AddOn_Details> salesAO,
      LIST<AddOn_Details> rentalAO
    ) {
      this.salesAddOns = salesAO;
      this.rentalAddOns = rentalAO;
    }
  }

  // wrapper class for alternate/expanded product details
  // should merge the two product detail classes at some point
  public class AddOn_Details {
    @AuraEnabled
    public String id { get; set; }
    @AuraEnabled
    public String assetid { get; set; }
    @AuraEnabled
    public String assetnumber { get; set; }
    @AuraEnabled
    public String name { get; set; }
    @AuraEnabled
    public String assetstatus { get; set; }
    @AuraEnabled
    public String catClass { get; set; }
    @AuraEnabled
    public String productType { get; set; }
    @AuraEnabled
    public String itemNumber { get; set; }
    @AuraEnabled
    public String stockClass { get; set; }
    @AuraEnabled
    public String category { get; set; }
    @AuraEnabled
    public String subcategory { get; set; }
    @AuraEnabled
    public String ratesDaily { get; set; }
    @AuraEnabled
    public String ratesWeekly { get; set; }
    @AuraEnabled
    public String ratesMonthly { get; set; }
    @AuraEnabled
    public String minRate { get; set; }
    @AuraEnabled
    public String availabilityA { get; set; }
    @AuraEnabled
    public String availabilityU { get; set; }
    @AuraEnabled
    public String availabilityR { get; set; }
    @AuraEnabled
    public Decimal sellPrice { get; set; }
    @AuraEnabled
    public Decimal availQuantity { get; set; }
    @AuraEnabled
    public String addonType { get; set; }
    @AuraEnabled
    public String itemType { get; set; }
    @AuraEnabled
    public Boolean isRequired { get; set; }
    @AuraEnabled
    public String rateFlag { get; set; }
    @AuraEnabled
    public String notToExceed { get; set; }
    //24085
    @AuraEnabled
    public Decimal minQuantity { get; set; }
    // SAL-26036
    @AuraEnabled
    public Boolean inventoriedItem { get; set; }
    @AuraEnabled
    public Boolean miscellaneousChargeItem { get; set; }
    @AuraEnabled
    public String typeOfMiscChargeItem { get; set; }
    @AuraEnabled
    public Boolean userSelectableForQuote { get; set; }
    @AuraEnabled
    public String isKit { get; set; }
    @AuraEnabled
    public Boolean isChangeable { get; set; }
    @AuraEnabled
    public String rateBranch { get; set; }
    @AuraEnabled
    public String parentSKU { get; set; }
    @AuraEnabled
    public String featureName { get; set; }

    public AddOn_Details(SBQQ__ProductOption__c ao) {
      this.id = ao.SBQQ__OptionalSKU__r.Id;
      this.name = ao.SBQQ__OptionalSKU__r.name;
      this.productType = ao.SBQQ__OptionalSKU__r.Product_Type__c;
      this.itemNumber = ao.SBQQ__OptionalSKU__r.Item_Number__c;
      this.stockClass = ao.SBQQ__OptionalSKU__r.Stock_class__c;
      this.catClass = ao.SBQQ__OptionalSKU__r.Product_SKU__c;
      this.sellPrice = ao.SBQQ__OptionalSKU__r.Sell_Price__c;
      this.isRequired = ao.SBQQ__Required__c;
      this.availQuantity = ao.SBQQ__Quantity__c != null
        ? ao.SBQQ__Quantity__c
        : 0;
      this.availabilityA = 'n/a';
      this.availabilityU = 'n/a';
      this.availabilityR = 'n/a';
      this.ratesDaily = 'n/a';
      this.ratesWeekly = 'n/a';
      this.ratesMonthly = 'n/a';
      // SAL-26036
      this.inventoriedItem = ao.SBQQ__OptionalSKU__r.Inventoried_Item__c;
      this.miscellaneousChargeItem = ao.SBQQ__OptionalSKU__r.Miscellaneous_Charge_Item__c;
      this.typeOfMiscChargeItem = ao.SBQQ__OptionalSKU__r.Type_of_Misc_Charge_Item__c;
      this.userSelectableForQuote = ao.SBQQ__OptionalSKU__r.User_Selectable_for_Quote__c;
      this.parentSKU = ao.SBQQ__ConfiguredSKU__r.Product_SKU__c;
      this.featureName = ao.SBQQ__Feature__r.Name;
    }

    public AddOn_Details(Product2 ao) {
      this.id = ao.id;
      this.name = ao.name;
      this.productType = ao.Product_Type__c;
      this.itemNumber = ao.Item_Number__c;
      this.stockClass = ao.Stock_class__c;
      this.category = ao.Product_Category__c;
      this.subcategory = ao.Product_Sub_Category__c;
      this.catClass = ao.Product_SKU__c;
      this.sellPrice = ao.Sell_Price__c;
      this.availabilityA = 'n/a';
      this.availQuantity = 0;
      this.availabilityU = 'n/a';
      this.availabilityR = 'n/a';
      this.ratesDaily = 'n/a';
      this.ratesWeekly = 'n/a';
      this.ratesMonthly = 'n/a';
      // SAL-26036
      this.inventoriedItem = ao.Inventoried_Item__c;
      this.miscellaneousChargeItem = ao.Miscellaneous_Charge_Item__c;
      this.typeOfMiscChargeItem = ao.Type_of_Misc_Charge_Item__c != null
        ? ao.Type_of_Misc_Charge_Item__c
        : '';
      this.userSelectableForQuote = ao.User_Selectable_for_Quote__c;
      this.isKit = ao.Is_Kit__c;
      this.isChangeable = ao.Changeable__c;
    }
    public AddOn_Details(Asset ao) {
      this.id = ao.Product2Id;
      this.assetid = ao.Id;
      this.name = ao.Product2.Name;
      this.assetnumber = ao.SM_PS_Equipment_Number__c;
      this.assetstatus = ao.Status;
      this.productType = ao.Product2.Product_Type__c;
      this.itemNumber = ao.Product2.Item_Number__c;
      this.stockClass = ao.Product2.Stock_class__c;
      this.category = ao.Product2.Product_Category__c;
      this.subcategory = ao.Product2.Product_Sub_Category__c;
      this.catClass = ao.Product2.Product_SKU__c;
      this.sellPrice = ao.Product2.Sell_Price__c;
      this.availabilityA = 'n/a';
      this.availQuantity = 0;
      this.availabilityU = 'n/a';
      this.availabilityR = 'n/a';
      this.ratesDaily = 'n/a';
      this.ratesWeekly = 'n/a';
      this.ratesMonthly = 'n/a';
    }
  }

  public class WrapLineItem {
    public List<LineItemDetail> lineItemDetails { get; set; }
  }
  public class LineItemDetail {
    public String apiName { get; set; }
    public Object fields { get; set; }
  }

  public class BranchDetails {
    @AuraEnabled
    public Schema.Location branch { get; set; }
    @AuraEnabled
    public Boolean isChronosEnabled { get; set; }
  }
}