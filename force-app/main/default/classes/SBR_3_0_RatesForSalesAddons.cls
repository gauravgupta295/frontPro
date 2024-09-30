/**
 * @description       : Logic to get rates for sales addons using consumables api
 * @author            : Pavan Konduru
 * @group             : 
 * @last modified on  : 03-12-2024
 * @last modified by  : Pavan Konduru
**/
public with sharing class SBR_3_0_RatesForSalesAddons {

    /**
    * @description Method to fetch salesaddon rates using consumable api
    * @author Pavan Konduru | 03-11-2024 
    * @param salesAddons 
    * @param branchNumber 
    * @return List<SBR_3_0_AddOnDetails> 
    **/
   public static List<SBR_3_0_AddOnDetails> getSalesAddonRates(List<SBR_3_0_AddOnDetails> salesAddons,String branchNumber){

    // Sales Addon API call for Rates
    String consumableResponse = callConsumableAPI(salesAddons,branchNumber);

    List<SBR_3_0_AddOnDetails> formattedResponse = formatSalesAddonData(salesAddons,consumableResponse);
    SBR_3_0_Log.logInfo(JSON.serializePretty(formattedResponse));
    return formattedResponse;

}
    
 /**
    * @description Method to call consumable api
    * @author Pavan Konduru | 03-11-2024 
    * @param salesAddons 
    * @param branchNumber 
    * @return String 
    **/
   static String callConsumableAPI(List<SBR_3_0_AddOnDetails> salesAddons, String branchNumber){

    // SF-6493 - USing Map to add unique products for bulk items in consumable api request
    Map<String,SBR_3_0_API_ConsumablesRequest.Products> productMap = new Map<String,SBR_3_0_API_ConsumablesRequest.Products>();
    for(SBR_3_0_AddOnDetails addOn: salesAddons){
        String sku = addOn.parentSKU;
        SBR_3_0_API_ConsumablesRequest.Products prod = new SBR_3_0_API_ConsumablesRequest.Products();
        prod.catId = sku.substring(0,3);
        prod.classId = sku.substring(3);
        if(!productMap.containsKey(sku)){
            productMap.put(sku,prod);
        }            
    }
    SBR_3_0_API_ConsumablesRequest req = new SBR_3_0_API_ConsumablesRequest();
    req.products = productMap.values();

    if(String.isNotEmpty(branchNumber)){ req.pc = branchNumber;}
    String companyCode = (loggedInUser.CompanyName != null &&  loggedInUser.CompanyName != '') ? loggedInUser.CompanyName : null;
    String response = SBR_3_0_API_Consumables.getConsumableRates(JSON.serialize(req,true), companyCode);
    return response;  
}

/**
    * @description Method to format Sales addon data for Bulk Add
    * @author Pavan Konduru | 03-11-2024 
    * @param salesList 
    * @param consumableResponse 
    * @return List<SBR_3_0_AddOnDetails> 
    **/
   public static List<SBR_3_0_AddOnDetails> formatSalesAddonData(List<SBR_3_0_AddOnDetails> salesList, String consumableResponse) {
    Map<String, SBR_3_0_AddOnDetails> productMap = new Map<String, SBR_3_0_AddOnDetails>();
    Map<String, SBR_3_0_AddOnDetails> updatedProductMap = new Map<String, SBR_3_0_AddOnDetails>();
    Map<String, Decimal> availQuantityMap = new Map<String, Decimal>();
    List<String> productItemNumbers = new List<String>();
    Set<String> itemNumberSet = new Set<String>();
    
    populateSalesProductMaps(salesList, productMap, productItemNumbers, itemNumberSet);

    Set<String> salesAddonProductNumberSet = new Set<String>();
    Set<String> forcedItemAddonProductNumberSet = new Set<String>();
    Map<String, Decimal> minQuantityMap = new Map<String, Decimal>();

    processConsumableResponse(consumableResponse, productItemNumbers, availQuantityMap, minQuantityMap, salesAddonProductNumberSet, forcedItemAddonProductNumberSet, productMap);

    finalizeProductMap(productMap,salesAddonProductNumberSet,availQuantityMap,forcedItemAddonProductNumberSet,minQuantityMap,updatedProductMap);

    return updatedProductMap.values();
}

/**
* @description prepare data variables to use in formatSalesAddonData
* @author Pavan Konduru | 03-12-2024 
* @param salesList 
* @param productMap 
* @param productItemNumbers 
* @param itemNumberSet 
**/
private static void populateSalesProductMaps(List<SBR_3_0_AddOnDetails> salesList, Map<String, SBR_3_0_AddOnDetails> productMap, List<String> productItemNumbers, Set<String> itemNumberSet) {
    for (SBR_3_0_AddOnDetails sale : salesList) {
        sale.addonType = 'SalesAddon';

        if (sale.catClass != null) {
            productMap.put(sale.catClass, sale);
            productItemNumbers.add(sale.catClass);
            itemNumberSet.add(sale.itemNumber);
        } else {
            productMap.put(sale.id, sale);
        }
    }
}

/**
* @description 
* @author Pavan Konduru | 03-12-2024 
* @param consumableResponse 
* @param productItemNumbers 
* @param availQuantityMap 
* @param minQuantityMap 
* @param salesAddonProductNumberSet 
* @param forcedItemAddonProductNumberSet 
* @param productMap 
**/
private static void processConsumableResponse(String consumableResponse, List<String> productItemNumbers, Map<String, Decimal> availQuantityMap, Map<String, Decimal> minQuantityMap, Set<String> salesAddonProductNumberSet, Set<String> forcedItemAddonProductNumberSet, Map<String, SBR_3_0_AddOnDetails> productMap) {
    Map<String, Object> rates = (Map<String, Object>) JSON.deserializeUntyped(consumableResponse);

    if (rates == null || !rates.containsKey('data')){
        return;
    }
    Map<String, Object> data = (Map<String, Object>) rates.get('data');

    if (data == null || !data.containsKey('suggestedItems')) {
        return;
    }
    List<Object> suggestedItems = (List<Object>) data.get('suggestedItems');
    processSuggestedItems(productMap, productItemNumbers, availQuantityMap, minQuantityMap, salesAddonProductNumberSet, forcedItemAddonProductNumberSet, suggestedItems);
}

/**
* @description 
* @author Pavan Konduru | 03-12-2024 
* @param productMap 
* @param productItemNumbers 
* @param availQuantityMap 
* @param minQuantityMap 
* @param salesAddonProductNumberSet 
* @param forcedItemAddonProductNumberSet 
* @param suggestedItems 
**/
private static void processSuggestedItems(Map<String, SBR_3_0_AddOnDetails> productMap, List<String> productItemNumbers, Map<String, Decimal> availQuantityMap, Map<String, Decimal> minQuantityMap, Set<String> salesAddonProductNumberSet, Set<String> forcedItemAddonProductNumberSet, List<Object> suggestedItems) {
    
    if (suggestedItems == null) {
        return;
    }
    for (Integer i = 0; i < suggestedItems.size(); i++) {
        Map<String, Object> items = (Map<String, Object>) suggestedItems[i];
        List<Object> consumables = (List<Object>) items.get('consumables');

        processConsumables(consumables,productMap,productItemNumbers,availQuantityMap,minQuantityMap,salesAddonProductNumberSet,forcedItemAddonProductNumberSet);
        List<Object> rentables = (List<Object>) items.get('rentables');
        processRentables(rentables,productMap,productItemNumbers);
    }
}

private static void processConsumables( List<Object> consumables,Map<String, SBR_3_0_AddOnDetails> productMap, List<String> productItemNumbers, Map<String, Decimal> availQuantityMap, Map<String, Decimal> minQuantityMap, Set<String> salesAddonProductNumberSet, Set<String> forcedItemAddonProductNumberSet){
    for (Integer j = 0; j < consumables.size(); j++) {
        Map<String, Object> consumable = (Map<String, Object>) consumables[j];
        List<Object> specGroups = (List<Object>) consumable.get('specGroups');
        processSpecGroups(productMap, productItemNumbers, availQuantityMap, minQuantityMap, salesAddonProductNumberSet, forcedItemAddonProductNumberSet, specGroups);
    }
}

/**
* @description 
* @author Pavan Konduru | 03-12-2024 
* @param productMap 
* @param productItemNumbers 
* @param availQuantityMap 
* @param minQuantityMap 
* @param salesAddonProductNumberSet 
* @param forcedItemAddonProductNumberSet 
* @param specGroups 
**/
private static void processSpecGroups(Map<String, SBR_3_0_AddOnDetails> productMap, List<String> productItemNumbers, Map<String, Decimal> availQuantityMap, Map<String, Decimal> minQuantityMap, Set<String> salesAddonProductNumberSet, Set<String> forcedItemAddonProductNumberSet, List<Object> specGroups) {
    for (Integer k = 0; k < specGroups.size(); k++) {
        Map<String, Object> specGroup = (Map<String, Object>) specGroups[k];
        List<Object> products = (List<Object>) specGroup.get('products');

        if (products != null && products.size() > 0) {
            processProducts(productMap, productItemNumbers, availQuantityMap, minQuantityMap, salesAddonProductNumberSet, forcedItemAddonProductNumberSet, products);
        }
    }
}

/**
* @description 
* @author Pavan Konduru | 03-12-2024 
* @param productMap 
* @param productItemNumbers 
* @param availQuantityMap 
* @param minQuantityMap 
* @param salesAddonProductNumberSet 
* @param forcedItemAddonProductNumberSet 
* @param products 
**/
private static void processProducts(Map<String, SBR_3_0_AddOnDetails> productMap, List<String> productItemNumbers, Map<String, Decimal> availQuantityMap, Map<String, Decimal> minQuantityMap, Set<String> salesAddonProductNumberSet, Set<String> forcedItemAddonProductNumberSet, List<Object> products) {
    for (Integer l = 0; l < products.size(); l++) {
        Map<String, Object> product = (Map<String, Object>) products[l];
        String prodstockClass = (String) product.get('stockClass');
        String productNumber = (String) product.get('productNumber');
        salesAddonProductNumberSet.add(productNumber);

        Boolean isForceItem = (String) product.get('forceItem') == 'Y' ? true : false;
        if (isForceItem) {
            forcedItemAddonProductNumberSet.add(productNumber);
            if (product.get('minQuantity') != null) {
                minQuantityMap.put(productNumber, (Decimal) product.get('minQuantity'));
            }
        }

        String pId = prodstockClass + '-' + productNumber;
        if (productItemNumbers.contains(pId)) {
            productMap.get(pId).sellPrice = (Decimal) product.get('sellingPrice');
        }

        if (product.get('availQuantity') != null) {
            availQuantityMap.put(productNumber, (Decimal) product.get('availQuantity'));
        }
    }
}

/**
* @description 
* @author Pavan Konduru | 03-12-2024 
* @param rentables 
* @param productMap 
* @param productItemNumbers 
**/
private static void processRentables(List<Object> rentables,Map<String, SBR_3_0_AddOnDetails> productMap,List<String> productItemNumbers){
for (Integer j = 0; j < rentables.size(); j++){
        Map<String, Object> rentable = (Map<String, Object>) rentables[j];
        if(rentable==null){
            continue;
        }
        String equipmentNumber = (String) rentable.get('equipmentNumber');
        Boolean isForceItem = (String) rentable.get('forceItem') == 'Y' ? true : false;
        if(!isForceItem && equipmentNumber == null){
            continue;
        }
        //forcedItemAddonProductNumberSet.add(equipmentNumber);
        if (productItemNumbers.contains(equipmentNumber)){
            updateProductMap(productMap,rentable,equipmentNumber);
        }
    }
}

/**
* @description 
* @author Pavan Konduru | 03-12-2024 
* @param productMap 
* @param rentable 
* @param equipmentNumber 
**/
private static void updateProductMap(Map<String, SBR_3_0_AddOnDetails> productMap,Map<String, Object> rentable,String equipmentNumber){
    if(rentable.get('minQuantity')!=null){
        productMap.get(equipmentNumber).minQuantity = (Decimal)rentable.get('minQuantity');
    }
    if(rentable.get('minRate')!=null){
        productMap.get(equipmentNumber).minRate = String.valueOf(rentable.get('minRate'));
    }
    if(rentable.get('dayRate')!=null){
        productMap.get(equipmentNumber).ratesDaily = String.valueOf(rentable.get('dayRate'));
    }
    if(rentable.get('wkRate')!=null){
        productMap.get(equipmentNumber).ratesWeekly = String.valueOf(rentable.get('wkRate'));
    }
    if(rentable.get('moRate')!=null){
        productMap.get(equipmentNumber).ratesMonthly = String.valueOf(rentable.get('moRate'));
    }
    productMap.get(equipmentNumber).sellPrice = 0.1;
}

/**
* @description 
* @author Pavan Konduru | 03-12-2024 
* @param productMap 
* @param salesAddonProductNumberSet 
* @param availQuantityMap 
* @param forcedItemAddonProductNumberSet 
* @param minQuantityMap 
* @param updatedProductMap 
**/
private static void finalizeProductMap(Map<String, SBR_3_0_AddOnDetails> productMap,Set<String> salesAddonProductNumberSet,Map <String, Decimal> availQuantityMap,Set<String> forcedItemAddonProductNumberSet,Map <String, Decimal> minQuantityMap,Map <String, SBR_3_0_AddOnDetails> updatedProductMap){
    for(String productKey : productMap.keyset()){
        SBR_3_0_AddOnDetails adDetails = productMap.get(productKey);
        if(salesAddonProductNumberSet.contains(adDetails.itemNumber)){
            if(availQuantityMap.get(adDetails.itemNumber)!=null){
                adDetails.availQuantity=availQuantityMap.get(adDetails.itemNumber);
            }                
            updatedProductMap.put(productKey,adDetails);
        }
    
        if(!forcedItemAddonProductNumberSet.isEmpty() && ((adDetails.itemNumber !=null && forcedItemAddonProductNumberSet.contains(adDetails.itemNumber) ) || forcedItemAddonProductNumberSet.contains(adDetails.catClass)) && minQuantityMap.get(adDetails.itemNumber)!=null ){
                adDetails.minQuantity = minQuantityMap.get(adDetails.itemNumber);         
        }
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