/**
 * @description       : Helper class to format rates for Bulk Add UI
 * @author            : Pavan Konduru
 * @group             :
 * @last modified on  : 03-11-2024
 * @last modified by  : Pavan Konduru
 **/
public with sharing class SBR_3_0_RatesHelper {
  /**
    * @description 
    * @author Pavan Konduru | 03-11-2024 
    * @param ratesResponse 
    * @param productDetails 
    * @param accountNumber 
    * @param branchNumber 
    * @param productAddOns 
    * @return List<SBR_3_0_AddOnDetails> 
    **/
   public static List<SBR_3_0_AddOnDetails> formatRatesForBulk(String ratesResponse, List<SBR_3_0_AddOnDetails> productDetails, String accountNumber, String branchNumber, Map<String, List<SBR_3_0_AddOnDetails>> productAddOns) {
    List<SBR_3_0_AddOnDetails> formattedResponse = new List<SBR_3_0_AddOnDetails>();
    SBR_3_0_Log.logInfo('productAddOns'+JSON.serializePretty(productAddOns));
    // Rental Addons
    addAddOnDetailsToList(productAddOns, 'Rental Addons', productDetails);

    // Kit Components
    addAddOnDetailsToList(productAddOns, 'Kit Component', productDetails);

    // Cat Class Products
    formattedResponse.addAll(formatRatesResponseForBulk(ratesResponse, productDetails, accountNumber, branchNumber));

    // Sales Addons
    addSalesAddonsToList(formattedResponse, productAddOns, 'Sales Addons', branchNumber);

    return formattedResponse;
}


/**
* @description 
* @author Pavan Konduru | 03-11-2024 
* @param productAddOns 
* @param key 
* @param productDetails 
**/
private static void addAddOnDetailsToList(Map<String, List<SBR_3_0_AddOnDetails>> productAddOns, String key, List<SBR_3_0_AddOnDetails> productDetails) {
    if (productAddOns.containsKey(key) && productAddOns.get(key) != null) {
        productDetails.addAll(productAddOns.get(key));
    }
}

/**
* @description 
* @author Pavan Konduru | 03-11-2024 
* @param formattedResponse 
* @param productAddOns 
* @param key 
* @param branchNumber 
**/
private static void addSalesAddonsToList(List<SBR_3_0_AddOnDetails> formattedResponse, Map<String, List<SBR_3_0_AddOnDetails>> productAddOns, String key, String branchNumber) {
    if (productAddOns.containsKey(key) && productAddOns.get(key) != null) {
        List<SBR_3_0_AddOnDetails> salesAddonList = SBR_3_0_RatesForSalesAddons.getSalesAddonRates(productAddOns.get(key), branchNumber);
        formattedResponse.addAll(salesAddonList);
    }
}

 /**
    * @description 
    * @author Pavan Konduru | 03-11-2024 
    * @param ratesResponse 
    * @param productDetails 
    * @param customerNumberParam 
    * @param branchNumber 
    * @return List<SBR_3_0_AddOnDetails> 
    **/
   public static  List<SBR_3_0_AddOnDetails> formatRatesResponseForBulk(String ratesResponse,  List <SBR_3_0_AddOnDetails> productDetails,String customerNumberParam,String branchNumber){

    Map <String, SBR_3_0_AddOnDetails> productMap = new Map <String, SBR_3_0_AddOnDetails>();
    List <String> productSKUs = new List<String>();

    populateProductMap(productDetails, branchNumber, productMap, productSKUs);

    if (!productSKUs.isEmpty()) {
        processRatesResponse(ratesResponse, customerNumberParam, productMap, productSKUs);
    }       
    return productMap.values();
}

 /**
    * @description 
    * @author Pavan Konduru | 03-11-2024 
    * @param productDetails 
    * @param branchNumber 
    * @param productMap 
    * @param productSKUs 
    **/
   private static void populateProductMap(List<SBR_3_0_AddOnDetails> productDetails, String branchNumber, Map<String, SBR_3_0_AddOnDetails> productMap, List<String> productSKUs) {
    for (SBR_3_0_AddOnDetails prod : productDetails) {
        prod.rateBranch = branchNumber;

        if (prod.catClass != null) {
            productMap.put(prod.catClass, prod);

            if (prod.catClass.isNumeric()) {
                productSKUs.add(prod.catClass);
            }
        } else {
            productMap.put(prod.id, prod);
        }
    }
}

/**
* @description 
* @author Pavan Konduru | 03-11-2024 
* @param ratesResponse 
* @param customerNumberParam 
* @param productMap 
* @param productSKUs 
**/
private static void processRatesResponse(String ratesResponse, String customerNumberParam, Map<String, SBR_3_0_AddOnDetails> productMap, List<String> productSKUs) {
    Map<String, Object> rates = (Map<String, Object>) JSON.deserializeUntyped(ratesResponse);

    if (rates != null && rates.containsKey('data')) {
        Map<String, Object> data = (Map<String, Object>) rates.get('data');

        if (data != null && data.containsKey('items')) {
            List<Object> items = (List<Object>) data.get('items');
                processRatesItems(items, productMap, productSKUs);
        }
    }
}

/**
* @description 
* @author Pavan Konduru | 03-11-2024 
* @param items 
* @param productMap 
* @param productSKUs 
**/
private static void processRatesItems(List<Object> items, Map<String, SBR_3_0_AddOnDetails> productMap, List<String> productSKUs) {
    if (items != null) {
        for (Integer i = 0; i < items.size(); i++) {
            Map<String, Object> item = (Map<String, Object>) items[i];
            Map<String, Object> ratesGroup = (Map<String, Object>) item.get('rates');
            Map<String, Object> suggestedRates = (Map<String, Object>) ratesGroup.get('suggestedRates');
            String pId = (String) item.get('productId');
    
            if (productSKUs.contains(pId)) {
                updateProductDetails(productMap.get(pId), suggestedRates, item);
            }
        }
    }
}

/**
* @description 
* @author Pavan Konduru | 03-11-2024 
* @param productDetails 
* @param suggestedRates 
* @param item 
**/
private static void updateProductDetails(SBR_3_0_AddOnDetails productDetails, Map<String, Object> suggestedRates, Map<String, Object> item) {
    productDetails.minRate = (String) suggestedRates.get('minimum');
    productDetails.ratesDaily = (String) suggestedRates.get('daily');
    productDetails.ratesWeekly = (String) suggestedRates.get('weekly');
    productDetails.ratesMonthly = (String) suggestedRates.get('monthly');
    productDetails.rateFlag = (String) item.get('rateFlag');
    productDetails.notToExceed = String.isBlank((String) item.get('notToExceed')) ? '' : (String) item.get('notToExceed');
    productDetails.rateBranch = (String) item.get('pc');
    productDetails.isProfileBranchUsed = SBR_3_0_RatesController.isProfileBranchUsed;
  }

   /**
    * @description 
    * @author Pavan Konduru | 03-11-2024 
    * @param productSkus 
    * @param productLocationMap 
    * @return Map<String, List<SBR_3_0_AddOnDetails>> 
    **/
   public static Map<String,List<SBR_3_0_AddOnDetails>> getProductAddOns(List<String> productSkus,Map<String,String> productLocationMap) {

    Map<String,List<SBR_3_0_AddOnDetails>> mapOfTypeAddon = new Map<String,List<SBR_3_0_AddOnDetails>>();
    String companyCode = (loggedInUser.CompanyName != null &&  loggedInUser.CompanyName != '') ? loggedInUser.CompanyName : null;
    for (SBQQ__ProductOption__c option : SBR_3_0_ProductDA.getProductOptionsForProducts(productSkus,companyCode,'ALL') ) {
        
        SBR_3_0_AddOnDetails ao = new SBR_3_0_AddOnDetails(option);
        ao.rateBranch = productLocationMap.get(ao.parentSKU);
        if(ao.featureName == 'Rental Addons'){
            productLocationMap.put(ao.catClass,ao.rateBranch);
        }else if(ao.featureName == 'Kit Component' && ao.availQuantity > 0){
            productLocationMap.put(ao.catClass,ao.rateBranch);
        }  

        if(!mapOfTypeAddon.containsKey(ao.featureName)){
            mapOfTypeAddon.put(ao.featureName,new List<SBR_3_0_AddOnDetails>());
        }
        mapOfTypeAddon.get(ao.featureName).add(ao);
    }

    return mapOfTypeAddon;
}

/**
    * @description 
    * @author Pavan Konduru | 03-11-2024 
    * @param productSkus 
    * @param productLocationMap 
    * @return List<SBR_3_0_AddOnDetails> 
    **/
   public static List<SBR_3_0_AddOnDetails> getProducts(List<String> productSkus,Map<String,String> productLocationMap) {

    List <SBR_3_0_AddOnDetails> products = new  List <SBR_3_0_AddOnDetails>();

    for (Product2 product : SBR_3_0_ProductDA.getProductsByProductSKU(new Set<String>(productSkus))) {
        SBR_3_0_AddOnDetails prod = new SBR_3_0_AddOnDetails(product);
        prod.rateBranch = productLocationMap.get(prod.catClass);
        products.add(prod);
    }

    return products;

}

/**
    * @description Method to convert Map<String, String> to List<ProductDetails>
    * @author Pavan Konduru | 03-11-2024 
    * @param productLocationMap 
    * @param branchNumber 
    * @return List<SBR_3_0_API_RatesRequestWrapper.Products> 
    **/
   public static List<SBR_3_0_API_RatesRequestWrapper.Products> mapToProductDetailsList(Map<String, String> productLocationMap,String branchNumber) {
    List<SBR_3_0_API_RatesRequestWrapper.Products> products = new List<SBR_3_0_API_RatesRequestWrapper.Products>();
    
    for (String productId : productLocationMap.keySet()) {
        SBR_3_0_API_RatesRequestWrapper.Products product = new SBR_3_0_API_RatesRequestWrapper.Products();
        product.pc = !String.isEmpty(productLocationMap.get(productId)) && productLocationMap.get(productId).contains('-') ?  productLocationMap.get(productId).split('-')[1] : branchNumber;
        product.productId = productId;
        products.add(product);
    }
    
    return products;
}

 /**
     * @description Sets location details based on the provided object and location type.
     * @author Pavan Konduru | 03-11-2024
     * @param atpReqObj The ATP request object to be populated with details.
     * @param locationObj The object containing location details.
     * @param locationType The type of location (e.g., Jobsite, Branch).
     **/
    public static void setLocationDetails(SBR_3_0_WrapInventoryAtBranch.ATPRequest atpReqObj, sObject locationObj, String locationType) {
      if (locationObj <> NULL &&
          locationObj.get('Latitude_Longitude__Latitude__s') <> NULL &&
          locationObj.get('Latitude_Longitude__Longitude__s') <> NULL) {
          atpReqObj.latitude = (Double)locationObj.get('Latitude_Longitude__Latitude__s');
          atpReqObj.longitude = (Double)locationObj.get('Latitude_Longitude__Longitude__s');
          atpReqObj.locationType = locationType;
          // SAL-25138
          atpReqObj.timezoneId = (String)locationObj.get('Time_Zone_Id__c');
      }
  }

  /**
   * @description Sets default location details if the delivery method is not 'Delivery' or 'Pickup'.
   * @author Pavan Konduru | 03-11-2024
   * @param atpReqObj The ATP request object to be populated with details.
   * @param locationObj The object containing location details.
   **/
  public static void setDefaultLocationDetails(SBR_3_0_WrapInventoryAtBranch.ATPRequest atpReqObj, Schema.Location locationObj) {
      Datetime myDateTime = Datetime.now();
      String formatted = myDateTime.formatGmt(SBR_3_0_Constants.INT_DATE_FORMAT);
      atpReqObj.requestedDeliveryDate = formatted;

      if (locationObj.Latitude_Longitude__Latitude__s <> NULL &&
          locationObj.Latitude_Longitude__longitude__s <> NULL) {
          atpReqObj.latitude = locationObj.Latitude_Longitude__Latitude__s;
          atpReqObj.longitude = locationObj.Latitude_Longitude__longitude__s;
          atpReqObj.locationType = SBR_3_0_Constants.LOCATIONTYPE_BRANCH;
          // SAL-25138
          atpReqObj.timezoneId = locationObj.Time_Zone_Id__c;
      }
  }

private static User loggedInUser{
  get{
      if(loggedInUser == null){
          loggedInUser = SBR_3_0_UserDA.getUserById(UserInfo.getUserId());
      }
      return loggedInUser;
  }
  set;
}

}