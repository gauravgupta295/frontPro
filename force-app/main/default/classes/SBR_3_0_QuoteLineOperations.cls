/*********************************************************************************************************************
    * Apex Class: SBR_3_0_(QuoteLineOperations)
    ---------------------------------------------------------------------------------------------------------------------------------------
    * Purpose/Methods:
    * - @description Class to manage any insert/updates that needs to be done on Quote Line Items as part of trigger
    --------------------------------------------------------------------------------------------------------------------------------------
*********************************************************************************************************************/
public without sharing class SBR_3_0_QuoteLineOperations {
/**
* @description begining of class
*/
  public class SBR_3_0_QuoteLineOperationsException extends Exception{}
/**
    * @description operations on quote with new product
     * @param quoteLines Trigger.new
*/
  public static void updateQuoteLineWithProduct(List<SBQQ__QuoteLine__c> quoteLines) {
    Set<String> productSKUs = new Set<String>();
    List<SBQQ__QuoteLine__c> quoteLinesToUpdate = new List<SBQQ__QuoteLine__c>();
    for (SBQQ__QuoteLine__c quoteLine : quoteLines) {
      if (quoteLine.SBQQ__Product__c == null && quoteLine.Product_SKU_Text__c != null) {
        if (quoteLine.Product_SKU_Text__c.length() < 7) {
          Integer n = 7-quoteLine.Product_SKU_Text__c.length();
          for (Integer i=0; i<n; i++) {
            quoteLine.Product_SKU_Text__c = '0' + quoteLine.Product_SKU_Text__c;
          }
        }
        productSKUs.add(quoteLine.Product_SKU_Text__c);
        quoteLinesToUpdate.add(quoteLine);
      }
    }
    Map<String, Product2> productMap = SBR_3_0_ProductDA.getProductByExternalId(productSKUs);

    for (SBQQ__QuoteLine__c quoteLine : quoteLinesToUpdate) {
      if (productMap.containsKey(quoteLine.Product_SKU_Text__c)) {
        quoteLine.SBQQ__Product__c = productMap.get(quoteLine.Product_SKU_Text__c).Id;
      }
    }
  }
/**
     * @description operations on quoteline to update notes field based on Shift_Differential__c
    * @param quoteLines Trigger.new
    */
  public static void updateShiftDurationNotes(List<SBQQ__QuoteLine__c> quoteLines) {
    for (SBQQ__QuoteLine__c quoteLine : quoteLines) {
      if (!String.isNotBlank(quoteLine.Shift_Differential__c)) {
        if (quoteLine.Shift_Differential__c == 'S') {
          quoteLIne.Line_Item_Notes__c = 'Single Shift Rate applied. Please see Shift Rate Details section for additional details';
        }
        if (quoteLine.Shift_Differential__c == 'D') {
          quoteLIne.Line_Item_Notes__c = 'Double  Shift Rate applied. Please see Shift Rate Details section for additional details';
        }
        if (quoteLine.Shift_Differential__c == 'T') {
          quoteLIne.Line_Item_Notes__c = 'Triple Shift Rate applied. Please see Shift Rate Details section for additional details';
        }
      }
    }
  }
/**
     * @description operations on quoteline to update lines with monthly rate for specific analysis region
    * @param quoteLines Trigger.new
    */
  public static void updateQuoteLinesWithMinValues(List<SBQQ__QuoteLine__c> quoteLines) {
    for (SBQQ__QuoteLine__c quoteLine : quoteLines) {
      if ((quoteLine.Parent_Quote_Analysis_Region_Key__c == '921' || quoteLine.Parent_Quote_Analysis_Region_Key__c == '933') && quoteline.Monthly_Rate__c != null) {
        quoteLine.Min_Rate__c = quoteLine.Monthly_Rate__c;
      // SAL-27319
      } else if (quoteline.Parent_Quote_Analysis_Region_Key__c == '939') { // to be 939
        quoteLine.Min_Rate__c = quoteLine.Weekly_Rate2__c;
      } else if (quoteline.Daily_Rate__c != null) {
        quoteLine.Min_Rate__c = quoteLine.Daily_Rate__c;
      }
    }
  }
/**
    * @description operations on quoteline to update quoteheader with timestamp
    //Was getting duplicate id in list error hence modified the code to ensure no duplicates are present.
    * @param newLines Trigger.new
    * @param oldLines Trigger.oldMap
    */
  public static void updateQuoteHeaderWithTimeStamp(List<SBQQ__QuoteLine__c> newLines, Map<Id, sObject> oldLines) {
   SBR_3_0_QuoteLineTriggerHandler.beforeUpdateRecursiveCheck = true;
    Set<Id> quoteIds = new Set<Id>();
    for (SBQQ__QuoteLine__c quoteLine : newLines) {
      quoteIds.add(quoteLine.SBQQ__Quote__c);
    }
    Map<Id, SBQQ__Quote__c> quoteMap = SBR_3_0_QuoteDA.getQuotes(quoteIds);
    List<SBQQ__Quote__c> quotesToUpdate = new List<SBQQ__Quote__c>();
    for (SBQQ__QuoteLine__c quoteLine : newLines) {
      SBQQ__QuoteLine__c oldLine = (SBQQ__QuoteLine__c) oldLines.get(quoteLine.Id);
      if (quoteLine.Min_Rate__c != oldLine.Min_Rate__c || quoteLine.Daily_Rate__c != oldLine.Daily_Rate__c || quoteLine.Weekly_Rate__c != oldLine.Weekly_Rate__c || quoteLine.Monthly_Rate__c != oldLine.Monthly_Rate__c || quoteLine.Selling_Price__c != oldLine.Selling_Price__c || quoteLine.SBQQ__Quantity__c != oldLine.SBQQ__Quantity__c) {
        SBQQ__Quote__c quote = quoteMap.get(quoteLine.SBQQ__Quote__c);
        if (!quotesToUpdate.contains(quote)) {
          quote.SBQQ_Last_Line_Update__c = System.now();
          quotesToUpdate.add(quote);
        }
      }
    }
    if (!quotesToUpdate.isEmpty()) {
      SObjectAccessDecision securityDecision = Security.stripInaccessible(AccessType.UPDATABLE, quotesToUpdate);
      update securityDecision.getRecords();
      }
  }
/**
    * @description operations on quoteline to update total amount field
    * @param newLines Trigger.new
    */
  public static void updateTotalQuoteId(List<SBQQ__QuoteLine__c> newLines) {
    Set<Id> quoteIds = new Set<Id>();
    for (SBQQ__QuoteLine__c quoteLine : newLines) {
      quoteIds.add(quoteLine.SBQQ__Quote__c);
    }
    Map<Id, SBQQ__Quote__c> quoteMap = SBR_3_0_QuoteDA.getQuotes(quoteIds);
    Map<Id, SBQQ__Quote__c> mapQuotesToUpdate = new Map<Id, SBQQ__Quote__c>();
    for (SBQQ__Quote__c quote : quoteMap.values()) {
      if (quote.RecordType.developerName == 'Sales_Quote') {
        for (SBQQ__QuoteLine__c quoteLine : newLines) {
          if (quoteLine.Total_Price__c != null && quoteLine.Total_Price__c != 0) {
            Double totalAmt = quote.Total_Quoted_Amount__c != null ? quote.Total_Quoted_Amount__c : 0;
            if (mapQuotesToUpdate.containsKey(quote.Id)) {
              mapQuotesToUpdate.get(quote.Id).Total_Quoted_Amount__c = totalAmt + quoteLine.Total_Price__c;
            } else {
              quote.Total_Quoted_Amount__c = totalAmt + quoteLine.Total_Price__c;
              mapQuotesToUpdate.put(quote.Id, quote);
            }
          }
        }
      }
    }
    if (!mapQuotesToUpdate.isEmpty()) {
      update mapQuotesToUpdate.values();
    }
  }

 /**
    * @description SAL-16794  update selling price based on conditions
    * @param quoteLines Trigger.new
    */
  public static void updateSellingPrice(List<SBQQ__QuoteLine__c> quoteLines) {
    Set<String> productSKUs = new Set<String>();
    Map<String, Product2> productMap = new Map<String, Product2>();

    for (SBQQ__QuoteLine__c quoteLine : quoteLines) {
      if (String.isNotBlank(quoteLine.Product_SKU__c)) {
        productSKUs.add(quoteLine.Product_SKU__c);
      }
    }
    if (!productSKUs.isEmpty()) {
      productMap = SBR_3_0_ProductDA.getProductByExternalId(productSKUs);
    }

    for (SBQQ__QuoteLine__c quoteLine : quoteLines) {
      if (!productMap.isEmpty() && productMap.containsKey(quoteLine.Product_SKU__c)) {
        Product2 quoteLineProd = productMap.get(quoteLine.Product_SKU__c);
        if (quoteLineProd.Product_Type__c == SBR_3_0_Constants.MISC_CHARGE_ITEMS_TYPE && quoteLine.Selling_Price__c != null && quoteLine.Selling_Price__c == 0.0 && quoteLine.Cost__c != null && quoteLine.Selling_Price__c != quoteLine.Cost__c) {
          //if(quoteLine.Selling_Price__c != null && quoteLine.Selling_Price__c == 0.0 && quoteLine.Cost__c != null && quoteLine.Selling_Price__c != quoteLine.Cost__c){
          quoteLine.Selling_Price__c = quoteLine.Cost__c;
        }
      }
    }
  }
 /**
    * @description // change for SAL-19006 - BD
    * @param quoteLines Trigger.new
    */
  public static void updateRateOverridden(List<SBQQ__QuoteLine__c> quoteLines) {
    for (SBQQ__QuoteLine__c quoteLine : quoteLines) {
      if ((quoteLine.Min_Rate__c != quoteLine.Suggested_Minimum_Rate__c) || (quoteLine.Hourly_Rate__c != quoteLine.Suggested_Hourly_Rate__c) || (quoteLine.Daily_Rate__c != quoteLine.Suggested_Daily_Rate__c) || (quoteLine.Weekly_Rate__c != quoteLine.Suggested_Weekly_Rate__c) || (quoteLine.Monthly_Rate__c != quoteLine.Suggested_Monthly_Rate__c)) {
        quoteLine.Rates_Overriden__c = true;
      } else if ((quoteLine.Min_Rate__c == quoteLine.Suggested_Minimum_Rate__c) && (quoteLine.Hourly_Rate__c == quoteLine.Suggested_Hourly_Rate__c) && (quoteLine.Daily_Rate__c == quoteLine.Suggested_Daily_Rate__c) && (quoteLine.Weekly_Rate__c == quoteLine.Suggested_Weekly_Rate__c) && (quoteLine.Monthly_Rate__c == quoteLine.Suggested_Monthly_Rate__c) && (quoteLine.Rates_Overriden__c)) {
        quoteLine.Rates_Overriden__c = false;
      }
    }
  }
 /**
    * @description update to remove QuoteHeader SpecificPricingFlag
    * @param newLines newLines records
    */
  public static void updateQuoteHeaderSpecificPricingFlag(List<SBQQ__QuoteLine__c> newLines) {
    Set<Id> quoteIds = new Set<Id>();
    for (SBQQ__QuoteLine__c quoteLine : newLines) {
      quoteIds.add(quoteLine.SBQQ__Quote__c);
    }
    Map<Id, SBQQ__Quote__c> quoteMap = SBR_3_0_QuoteDA.getQuotes(quoteIds);
    List<SBQQ__Quote__c> quotesToUpdate = new List<SBQQ__Quote__c>();
    for (SBQQ__QuoteLine__c quoteLine : newLines) {
      if (quoteLine.Specific_Pricing_Flag__c == true) {
        SBQQ__Quote__c quote = quoteMap.get(quoteLine.SBQQ__Quote__c);
        if (quote.Specific_Pricing_Flag__c != true && !quotesToUpdate.contains(quote)) {
          quote.Specific_Pricing_Flag__c = true;
        }
        if (!String.isBlank(quoteLine.Specific_Pricing_Type__c) && quoteLine.Specific_Pricing_Type__c.equals(SBR_3_0_Constants.CUSTOMER_LOADED_SPECIFIC_PRICING_TYPE)) {
          quote.Is_Specific_Pricing_Flag__c = true;
        }
        if (!quotesToUpdate.contains(quote)) {
          quotesToUpdate.add(quote);
        }
      }
    }
    if (!quotesToUpdate.isEmpty()) {
      SObjectAccessDecision securityDecision = Security.stripInaccessible(AccessType.UPDATABLE, quotesToUpdate);
      update securityDecision.getRecords();
    }
  }
   /**
    * @description update to remove QuoteHeader SpecificPricingFlag
    * @param oldMap oldMap records
    */
  public static void removeQuoteHeaderSpecificPricingFlag(Map<Id, SObject> oldMap) {
    Set<Id> deletedIds = oldMap.keyset();
    List<SBQQ__QuoteLine__c> deletedLines = (List<SBQQ__QuoteLine__c>) oldMap.values();
    Set<Id> quoteIds = new Set<Id>();
    for (SBQQ__QuoteLine__c quoteLine : deletedLines) {
      if (quoteLine.Specific_Pricing_Flag__c) {
        quoteIds.add(quoteLine.SBQQ__Quote__c);
      }
    }
    Map<Id, SBQQ__Quote__c> allQuotes = SBR_3_0_QuoteDA.getQuotes(quoteIds);
    List<SBQQ__Quote__c> potentialQuotes = new List<SBQQ__Quote__c>();
    Set<Id> potentialQuoteIds = new Set<Id>();
    for (SBQQ__Quote__c quote : allQuotes.values()) {
      if (quote.Specific_Pricing_Flag__c) {
        potentialQuotes.add(quote);
        potentialQuoteIds.add(quote.Id);
      }
    }

    List<SBQQ__QuoteLine__c> allQuoteLines = SBR_3_0_QuoteLineDA.getQuoteLines(quoteIds);
     for (SBQQ__QuoteLine__c quoteLine : allQuoteLines) {
      if (!deletedIds.contains(quoteLine.Id) && potentialQuoteIds.contains(quoteLine.SBQQ__Quote__c)) {
        if (quoteLine.Specific_Pricing_Flag__c) {
        potentialQuoteIds.remove(quoteLine.SBQQ__Quote__c);
        }
      }
    }
    List<SBQQ__Quote__c> quotesToUpdate = new List<SBQQ__Quote__c>();
    for (SBQQ__Quote__c quote : potentialQuotes) {
      if (potentialQuoteIds.contains(quote.Id) && !quotesToUpdate.contains(quote)) {
         quote.Specific_Pricing_Flag__c = false;
        quotesToUpdate.add(quote);
      }
    }
    if (quotesToUpdate.size() > 0) {
         SObjectAccessDecision securityDecision = Security.stripInaccessible(AccessType.UPDATABLE, quotesToUpdate);
          update securityDecision.getRecords();
    }
  }
  /**
    * @description update total of all Line Item Contingency cost on ContingencyCatClass line Item in before trigger context
    * SAL-26932
    * @param oldMap old records
    * @param newLines Trigger.new
    */
    public static void updateTotalOnContingencyCatClass(Map<Id,SBQQ__QuoteLine__c> oldMap,List<SBQQ__QuoteLine__c> newLines) {
      Set<Id> quoteIds = new Set<Id>();
      Double calculateCost=0;
      Map<Id,Double> quoteIdToContingencyCost = new Map<Id,Double>();
      Map<Id,SBQQ__QuoteLine__c> parentToQuoteLine = new Map<Id,SBQQ__QuoteLine__c>();
      
      if(Trigger.isDelete){
        for(SBQQ__QuoteLine__c quoteLine : newLines) {
            if(quoteLine.Contingency_Cost__c!= null){
              quoteIds.add(quoteLine.SBQQ__Quote__c);
              calculateCost=0;
            }
         }
      }else{
        for (SBQQ__QuoteLine__c quoteLine : newLines) {
          if ((Trigger.IsInsert && quoteLine.Contingency_Cost__c!=null)||
               (Trigger.isUpdate && 
               oldMap.get(quoteLine.id).Contingency_Cost__c != quoteLine.Contingency_Cost__c)) {
              quoteIds.add(quoteLine.SBQQ__Quote__c);
              calculateCost=0;
          }
        }
      }
      if(quoteIds.size() >0 ){
         for(SBQQ__QuoteLine__c quoteLine : SBR_3_0_QuoteLineDA.getQuoteLines(quoteIds)){
          if(quoteLine.SBQQ__ProductName__c != 'Contingency Plan Fee' &&
             quoteLine.SBQQ__Product__r.Product_Type__c == 'Cat-Class'
            ){
              calculateCost+=quoteLine.Contingency_Cost__c;
              // total Cost of each Line Item and map to parent
              quoteIdToContingencyCost.put(quoteLine.SBQQ__Quote__c,calculateCost);
          }else if(quoteLine.SBQQ__Product__r.Class__c =='9000' && 
                  quoteLine.SBQQ__Product__r.Category__c == '155'){
                  parentToQuoteLine.put(quoteLine.SBQQ__Quote__c,quoteLine);
          }
        }
        List<SBQQ__QuoteLine__c> quoteLineToUpdate=new List<SBQQ__QuoteLine__c>();

        for(Id parentId :quoteIdToContingencyCost.keyset()){
          if(parentToQuoteLine.containsKey(parentId)){
            SBQQ__QuoteLine__c lineItem = parentToQuoteLine.get(parentId);
            lineItem.Weekly_Rate__c = quoteIdToContingencyCost.get(parentId);
            lineItem.Daily_Rate__c = quoteIdToContingencyCost.get(parentId);
            lineItem.Monthly_Rate__c = quoteIdToContingencyCost.get(parentId);
            quoteLineToUpdate.add(lineItem);
          }
        }
        if(!quoteLineToUpdate.isEmpty()){
          SObjectAccessDecision securityDecision = Security.stripInaccessible(AccessType.UPDATABLE, quoteLineToUpdate);
          update securityDecision.getRecords();
        }
      }
    }
 /**
    * @description insert quote line attributes
     * @param productOptions 
    * @param quoteLine
      @return List of quote lines to insert
    */
    public static List<SBQQ__QuoteLine__c> quoteLineToInsert(List<SBQQ__ProductOption__c> productOptions, SBQQ__QuoteLine__c quoteLine) {
      List<SBQQ__QuoteLine__c> quoteLinesToInsert = new List<SBQQ__QuoteLine__c>();
  
      for (SBQQ__ProductOption__c option : productOptions) {
          SBQQ__QuoteLine__c quoteItem = new SBQQ__QuoteLine__c();
          quoteItem.SBQQ__Quantity__c = option.SBQQ__Quantity__c * quoteLine.SBQQ__Quantity__c;
          quoteItem.SBQQ__SubscriptionScope__c = quoteLine.SBQQ__SubscriptionScope__c;
          quoteItem.Kit_Number_this_Item_Belongs_to__c = quoteLine.Product_SKU__c;
          quoteItem.SBQQ__Product__c = option.SBQQ__OptionalSKU__c;
          quoteItem.SBQQ__Quote__c = quoteLine.SBQQ__Quote__c;
          quoteLinesToInsert.add(quoteItem);
      }
  
      return quoteLinesToInsert;
  }
 /**
    * @description update quote line attributes
     * @param quoteLines 
    * @param quoteLine
    * @param productSKUToSingleOptionMap
     @return List of quote lines to update
    */
  public static List<SBQQ__QuoteLine__c> quoteLinesToUpdate(List<SBQQ__QuoteLine__c> quoteLines, SBQQ__QuoteLine__c quoteLine,Map<String,SBQQ__ProductOption__c> productSKUToSingleOptionMap) {
    List<SBQQ__QuoteLine__c> quoteLinesToUpdate = new List<SBQQ__QuoteLine__c>();
    
    for (SBQQ__QuoteLine__c ql : quoteLines) {
      if(productSKUToSingleOptionMap.containsKey(ql.Product_SKU__c)){
        ql.SBQQ__Quantity__c = productSKUToSingleOptionMap.get(ql.Product_SKU__c).SBQQ__Quantity__c * quoteLine.SBQQ__Quantity__c;
        quoteLinesToUpdate.add(ql);
      }
    }
    return quoteLinesToUpdate;
  }
   /**
    * @description //SAL-27320 - CPU time exceeded refactoring
     * @param newLines 
   */
  public static void updateQuoteLineProductSKUTextBI(List<SBQQ__QuoteLine__c> newLines){
    // Step 0 : Prepare sets of Ids to retrieve products
    Map<String, Product2> productsMap = new Map<String, Product2>();
    Set<String> productIds = new Set<String>();
    for (SBQQ__QuoteLine__c quoteLine : newLines) {
        productIds.add(quoteLine.SBQQ__Product__c);
    }
   // Step 1 : get related products map
    productsMap = SBR_3_0_ProductDA.getProductsById(productIds);
   // Step 2 : populate Product_SKU_Text__c field from products map
    if(!productsMap.isEmpty()){
      for (SBQQ__QuoteLine__c qtLine : newLines) {
          if(qtLine.SBQQ__Product__c !=  null){
               qtLine.Product_SKU_Text__c = productsMap.get(qtLine.SBQQ__Product__c)?.Product_SKU__c;
           }  
        }
      }
    }
    
  /**
    * @description //SAL-27320 - CPU time exceeded refactoring
     * @param importedLines 
   */
  public static void updateLineItemTypeIfNullBI(List<SBQQ__QuoteLine__c> importedLines){
    // Step 0 : prepare set of quote ids
    Map<String, Product2> productsMap = new Map<String, Product2>();
    Set<String> productSKUs = new Set<String>();
    for(SBQQ__QuoteLine__c quoteLine : importedLines) {
      if (quoteLine.Line_Item_Type__c == null && String.isNotBlank(quoteLine.Product_SKU_Text__c)) {
        productSKUs.add(quoteLine.Product_SKU_Text__c);
      }
    }
    // Step 1 : get related products map
    if(productSKUs != null && !productSKUs.isEmpty()){
        productsMap = SBR_3_0_ProductDA.getProductsMapByProductSKU(productSKUs);
     // Step 2 : populate Line_Item_Type__c field
        if(!productsMap.isEmpty()){
          for (SBQQ__QuoteLine__c qtLine : importedLines) {
            if(productsMap.containsKey(qtLine.SBQQ__Product__c)) {
                if (productsMap.get(qtLine.SBQQ__Product__c).Product_Type__c == 'Cat-Class') {
                  qtLine.Line_Item_Type__c = 'VR';
                } else if (productsMap.get(qtLine.SBQQ__Product__c).Inventoried_Item__c && 
                          (productsMap.get(qtLine.SBQQ__Product__c).Product_Type__c == 'Parts' || productsMap.get(qtLine.SBQQ__Product__c).Product_Type__c == 'Merchandise')) {
                  qtLine.Line_Item_Type__c = 'VS';
                } else if (productsMap.get(qtLine.SBQQ__Product__c).Miscellaneous_Charge_Item__c && 
                          !(productsMap.get(qtLine.SBQQ__Product__c).Product_Type__c == 'Parts' || productsMap.get(qtLine.SBQQ__Product__c).Product_Type__c == 'Merchandise' || productsMap.get(qtLine.SBQQ__Product__c).Stock_class__c == 'DEL')) {
                  qtLine.Line_Item_Type__c = 'YC';
                } else if (productsMap.get(qtLine.SBQQ__Product__c).Miscellaneous_Charge_Item__c && 
                productsMap.get(qtLine.SBQQ__Product__c).Type_of_Misc_Charge_Item__c == 'MS' && productsMap.get(qtLine.SBQQ__Product__c).Stock_class__c == 'DEL') {
                  qtLine.Line_Item_Type__c = 'YD';
                }
                else{
                  qtLine.Line_Item_Type__c = '';
                }
            }
        }
      }

    }

}
   /**
    * @description //SAL-27196 Update Quote Stale Totals to true after insert and delete of Order Lines
     * @param newLines 
   */
   public static void updateQuoteStaleTotals(List<SBQQ__QuoteLine__c> newLines){
      // Get product type using product Ids
    Set<Id> productIds = new Set<Id>();
    Set<Id> quoteIdsUpdateStaleTtl =  new Set<Id>();
    Boolean isLineItemUpdateOnQuote = false;
    for (SBQQ__QuoteLine__c quoteLine : newLines) {
      if(quoteLine.is_User_Added__c == true){
        productIds.add(quoteLine.SBQQ__Product__c);
      }
      else{
        quoteIdsUpdateStaleTtl.add(quoteLine.SBQQ__Quote__c);
        isLineItemUpdateOnQuote = true;
      }
    }
    Map<Id,Product2> mapProducts = new Map<Id,Product2>([Select Product_Type__c from Product2 WHERE Id in: productIds]);
    if(mapProducts.size()>0){
    for (SBQQ__QuoteLine__c quoteLine : newLines) {
      if(!quoteIdsUpdateStaleTtl.contains(quoteLine.SBQQ__Quote__c) && (mapProducts.get(quoteLine.SBQQ__Product__c).Product_Type__c == 'Cat-Class' || mapProducts.get(quoteLine.SBQQ__Product__c).Product_Type__c == 'Merchandise')) { 
        quoteIdsUpdateStaleTtl.add(quoteLine.SBQQ__Quote__c);
      }
    }
  }
    // Update SBQQ_Last_Line_Update__c to a future date/time 
    if(!quoteIdsUpdateStaleTtl.isEmpty()) {
      List<SBQQ__Quote__c> quotesToUpdate = [Select Id, SBQQ_Last_Line_Update__c,LastModifiedDate from SBQQ__Quote__c WHERE Id in: quoteIdsUpdateStaleTtl WITH SECURITY_ENFORCED];
      for(SBQQ__Quote__c quote : quotesToUpdate) {
        if(isLineItemUpdateOnQuote == false){
         quote.SBQQ_Last_Line_Update__c = system.now().addHours(2);
        }
      }
      SObjectAccessDecision securityDecision = Security.stripInaccessible(AccessType.UPDATABLE, quotesToUpdate);
      update securityDecision.getRecords();
    }
    
  }

  /**
  * @description reset line item qty to 1 for Rate Quotes only
  * SAL-27426
  * @param newLines Trigger.new
  */
  public static void updateLineItemQtyForRateQuote(List<SBQQ__QuoteLine__c> newLines) {
    // step 0 : get quote ids from quote lines
    Set<Id> quoteIds = new Set<Id>();
    for (SBQQ__QuoteLine__c quoteLine : newLines) {
      quoteIds.add(quoteLine.SBQQ__Quote__c);
    }

    // step 1 : retrieve quotes map by set of ids
    Map<Id, SBQQ__Quote__c> quoteMap = SBR_3_0_QuoteDA.getQuotes(quoteIds);

    // step 2 : set qty to 1 if match
    for (SBQQ__Quote__c quote : quoteMap.values()) {
      if (quote.RecordType.developerName == 'Rate_Quote') {
        for (SBQQ__QuoteLine__c quoteLine : newLines) {
          if(quoteLine.SBQQ__Quote__c == quote.Id){
            quoteLine.SBQQ__Quantity__c = 1;
          }
        }
      }
    }
  }
 /** 
 @description  Updates User Added Field to true for Line Item type = VS(Sales),VR(Rental)
 Cat-Class, Parts and Merchandise
 @param newLines Trigger.new
*/
public static void updateUserAddedField(List<SBQQ__QuoteLine__c> newLines){
  for (SBQQ__QuoteLine__c quoteLine : newLines) {
    // before insert
    if(quoteLine.Line_Item_Type__c == 'VR' || quoteLine.Line_Item_Type__c == 'VS'){
        quoteLine.is_User_Added__c = true;
    }
  }
}
   /**
    * @description Stamping kit number and fuel plan fields in before trigger context
    * for Quotelines created from RentalMan 
    * SF-5291,SF-5292
    * @param quoteLines Trigger.new
    */
    public static void updateFuelPlanLineItemsFromRentalMan(List < SBQQ__QuoteLine__c > quoteLines) {
      Map < String, SBQQ__QuoteLine__c > quoteLineItemMap = new Map < String, SBQQ__QuoteLine__c > ();
      User loggedInUser = SBR_3_0_UserDA.getUserById(UserInfo.getUserId());
      String loggedInUserCompanyCode = loggedInUser.CompanyName;
      Set < Id > quoteIds = new Set < Id > ();
      Map < String, SBQQ__ProductOption__c > configuredSkuToProductOptionMap = new Map < String, SBQQ__ProductOption__c > ();
      for (SBQQ__QuoteLine__c quoteLine: quoteLines) {
          quoteIds.add(quoteLine.SBQQ__Quote__c);
          quoteLineItemMap.put(quoteLine.Product_SKU__c, quoteLine);
      }
      Map < Id, SBQQ__Quote__c > quoteMap = new Map < Id, SBQQ__Quote__c > ([SELECT Id, Quote_Initiating_Channel__c, SBQQ__Status__c, Rentalman_Quote_Id__c FROM SBQQ__Quote__c WHERE Id IN: quoteIds]);
      for (SBQQ__QuoteLine__c quoteLine: quoteLines) {
          SBQQ__Quote__c parentQuote = quoteMap.get(quoteLine.SBQQ__Quote__c);
          if (String.isNotBlank(parentQuote.Rentalman_Quote_Id__c)) {
              Map < String, Object > productMap = SBR_3_0_ProductDA.getProductOptionsWithFuelCharge(new List<String>{quoteLine.SBQQ__Product__c},new List<String>{loggedInUserCompanyCode});
              if ((Boolean) productMap.get('hasFuelCharge')) {
                  quoteLine.Fuel_Plan__c = true;
                  SBQQ__ProductOption__c fuelChargeOption = (SBQQ__ProductOption__c) productMap.get('fuelChargeOption');
                  configuredSkuToProductOptionMap.put(fuelChargeOption.SBQQ__ConfiguredSKU__r.Product_SKU__c, fuelChargeOption);
                  if (quoteLineItemMap.containsKey(configuredSkuToProductOptionMap.get(quoteLine.Product_SKU__c).SBQQ__OptionalSKU__r.Product_SKU__c)) {
                      quoteLineItemMap.get(configuredSkuToProductOptionMap.get(quoteLine.Product_SKU__c).SBQQ__OptionalSKU__r.Product_SKU__c).Kit_Number_this_Item_Belongs_to__c = configuredSkuToProductOptionMap.get(quoteLine.Product_SKU__c).SBQQ__ConfiguredSKU__r.Product_SKU__c;
                      quoteLineItemMap.get(configuredSkuToProductOptionMap.get(quoteLine.Product_SKU__c).SBQQ__OptionalSKU__r.Product_SKU__c).Line_Comments__c = 'Fuel Plan for '+configuredSkuToProductOptionMap.get(quoteLine.Product_SKU__c).SBQQ__ConfiguredSKU__r.Name;
                  }
              }
          }
      }
  }
 /**
    * @description remove child Cat-Class Fuel Plan lineitems 
    * if parent fuel plan field is unchecked in after trigger context
    * SF-5291,SF-5292
    * @param newLines Trigger.new
    * @param oldLines Trigger.oldMap
    */
    public static void removeChildFuelPlanIfParentUnchecked(List < SBQQ__QuoteLine__c > newLines, Map < Id, sObject > oldLines) {
      try {
          SBR_3_0_QuoteLineTriggerHandler.beforeUpdateRecursiveCheck = true;
          Set < Id > quoteIds = new Set < Id > ();
          Map < String, SBQQ__QuoteLine__c > quoteLinesToRemove = new Map < String, SBQQ__QuoteLine__c > ();
          List < SBQQ__QuoteLine__c > getFuelPlanLineItems = new List < SBQQ__QuoteLine__c > ();
          for (SBQQ__QuoteLine__c quoteLine: newLines) {
              SBQQ__QuoteLine__c oldLine = (SBQQ__QuoteLine__c) oldLines.get(quoteLine.Id);
              if (oldLine.Fuel_Plan__c && !quoteLine.Fuel_Plan__c) {
                  quoteIds.add(quoteLine.SBQQ__Quote__c);
                  quoteLinesToRemove.put(quoteLine.Product_SKU__c, quoteLine);
              }
          }
          if (!quoteLinesToRemove.isEmpty()) {

              getFuelPlanLineItems = [select id, Kit_Number_this_Item_Belongs_to__c, SBQQ__Product__r.Name, SBQQ__Quantity__c from SBQQ__QuoteLine__c where Kit_Number_this_Item_Belongs_to__c in: quoteLinesToRemove.keyset() and(SBQQ__Product__r.Name LIKE 'Fuel Convenience Charge'  OR SBQQ__Product__r.Name LIKE '%Refill%') and SBQQ__Quote__c in: quoteIds WITH SECURITY_ENFORCED limit 1];
              if (getFuelPlanLineItems.size() > 0) {
                  for (SBQQ__QuoteLine__c queriedRecord: getFuelPlanLineItems) {
                      SBR_3_0_LineItemCartCmpController.deleteLineItems(new List < String > {queriedRecord.Id});
                  }
              }
          }

      } catch (Exception ex) {
          SBR_3_0_Log.logException(ex);
      }
  }
 /**
    * @description uncheck child Cat-Class Fuel Plan lineitems 
    * if child fuel plan is removed
    *  in after delete trigger context
    * SF-5291,SF-5292
    * @param oldLines Trigger.old
    */
    public static void uncheckFuelPlanCheckBox(List < SBQQ__QuoteLine__c > oldLines) {
      try {
          Boolean hasExistingFlag = false;
          Set < String > kitNumberBelongsTo = new Set < String > ();
          List < SBQQ__QuoteLine__c > oldQLI = oldLines;
          Set < String > quoteBelongsTo = new Set < String > ();
          List < SBQQ__QuoteLine__c > getParentLineItem = new List < SBQQ__QuoteLine__c > ();
          List < SBQQ__QuoteLine__c > qliToUpdate = new List < SBQQ__QuoteLine__c > ();
          for (SBQQ__QuoteLine__c quoteLine: oldQLI) {
              if ((quoteLine.SBQQ__ProductName__c == 'Fuel Convenience Charge' || quoteLine.SBQQ__ProductName__c.contains('Refill')) && quoteLine.Kit_Number_this_Item_Belongs_to__c != '') {
                  kitNumberBelongsTo.add(quoteLine.Kit_Number_this_Item_Belongs_to__c);
                  quoteBelongsTo.add(quoteLine.SBQQ__Quote__c);
              }
          }
          getParentLineItem = [select id, Product_SKU__c, Fuel_Plan__c, SBQQ__Quote__c from SBQQ__QuoteLine__c where Product_SKU__c IN: kitNumberBelongsTo and SBQQ__Quote__c IN: quoteBelongsTo WITH SECURITY_ENFORCED];
          if(!getParentLineItem.isEmpty())
          {
          String parentProductSKU=getParentLineItem[0].Product_SKU__c;
          //SF-5879
          List<SBQQ__QuoteLine__c> getExistingQli = [SELECT Id,Selling_Price__c,SBQQ__Quote__c FROM SBQQ__QuoteLine__c WHERE Kit_Number_this_Item_Belongs_to__c =: parentProductSKU AND SBQQ__Quote__c =: quoteBelongsTo AND (SBQQ__Product__r.Name like '%Fuel Convenience Charge%' OR SBQQ__Product__r.Name like '%Refill%') AND SBQQ__Product__r.Stock_class__c='FUEL' WITH SECURITY_ENFORCED ];
          hasExistingFlag = !getExistingQli.isEmpty();
          if (!getParentLineItem.isEmpty() && !hasExistingFlag) {
              for (SBQQ__QuoteLine__c qli: getParentLineItem) {
                  if (qli.Fuel_Plan__c) {
                      qli.Fuel_Plan__c = false;
                      qliToUpdate.add(qli);
                  }
              }
          }
        }
          if (!qliToUpdate.isEmpty()) {
              SObjectAccessDecision securityDecision = Security.stripInaccessible(AccessType.UPDATABLE, qliToUpdate);
              update securityDecision.getRecords();
          }
      } catch (Exception ex) {
          SBR_3_0_Log.logException(ex);
      }
  }

/**
  * Update Child Quantity to match Parent Cat-Class
  * SF-5330
  *@description Kit_Number_This_Item_Belongs_to__c - populated when it is required addon
   @param oldMap Trigger.oldMap
   @param newLines Trigger.newMap
  */
  public static void updateQuantityonChildLineToMatchParent(Map<Id,SBQQ__QuoteLine__c> oldMap,List<SBQQ__QuoteLine__c> newLines) {
    try{
        Map <String,Decimal> mapOfProductQuantity = new Map <String,Decimal> ();
        Set<Id> quoteIds = new Set<Id>(); 
        List<String> productSkus = new List<String>();
        for(SBQQ__QuoteLine__c quoteLine: newLines) {
          if(String.isBlank(quoteLine.Kit_Number_This_Item_Belongs_to__c) && String.isNotBlank(quoteLine.Product_SKU__c)){
            SBQQ__QuoteLine__c oldLine = oldMap.get(quoteLine.Id);
            if(quoteLine.SBQQ__Quantity__c != oldLine.SBQQ__Quantity__c) {
              quoteIds.add(quoteLine.SBQQ__Quote__c);
              productSkus.add(quoteLine.Product_SKU__c);
              mapOfProductQuantity.put(quoteLine.Product_SKU__c, quoteLine.SBQQ__Quantity__c);
            }
          } 
        }

        User loggedInUser = SBR_3_0_UserDA.getUserById(UserInfo.getUserId());
        String loggedInUserCompanyCode = loggedInUser.CompanyName;
        List<SBQQ__ProductOption__c> productOptions = SBR_3_0_ProductDA.getProductOptionsForProducts(productSkus,loggedInUserCompanyCode,'Forced Item');
        productOptions.addAll(SBR_3_0_ProductDA.getProductKitComponents(productSkus));
        Map<Id,SBQQ__ProductOption__c> mapOfProductOptions = new Map<Id,SBQQ__ProductOption__c>();
        for(SBQQ__ProductOption__c option: productOptions){
          if(!mapOfProductOptions.containsKey(option.SBQQ__OptionalSKU__c)){
            mapOfProductOptions.put(option.SBQQ__OptionalSKU__c,option);
          }
        }
        List<SBQQ__QuoteLine__c> childlines =  [select id, Kit_Number_this_Item_Belongs_to__c, SBQQ__Product__r.Name,SBQQ__Product__c, SBQQ__Quantity__c from SBQQ__QuoteLine__c where Kit_Number_this_Item_Belongs_to__c in: mapOfProductQuantity.keyset() and SBQQ__Quote__c in:quoteIds WITH SECURITY_ENFORCED];
        List<SBQQ__QuoteLine__c> updatedChildlines = new List<SBQQ__QuoteLine__c>();
        for(SBQQ__QuoteLine__c quoteLine: childlines) {
          if(String.isNotBlank(quoteLine.Kit_Number_this_Item_Belongs_to__c) && mapOfProductQuantity.containsKey(quoteLine.Kit_Number_this_Item_Belongs_to__c) && mapOfProductOptions.containsKey(quoteLine.SBQQ__Product__c)){
            if((mapOfProductOptions.get(quoteLine.SBQQ__Product__c).SBQQ__Feature__r.Name == 'Sales Addons' &&
                mapOfProductQuantity.get(quoteLine.Kit_Number_this_Item_Belongs_to__c) > quoteLine.SBQQ__Quantity__c) || 
                mapOfProductOptions.get(quoteLine.SBQQ__Product__c).SBQQ__Feature__r.Name == 'Rental Addons' || 
                mapOfProductOptions.get(quoteLine.SBQQ__Product__c).SBQQ__Feature__r.Name == 'Kit Component'){
              quoteLine.SBQQ__Quantity__c = mapOfProductOptions.get(quoteLine.SBQQ__Product__c).SBQQ__Quantity__c * mapOfProductQuantity.get(quoteLine.Kit_Number_this_Item_Belongs_to__c);
              updatedChildlines.add(quoteLine);
            }
            
          }
          //SF-5879
          else if(String.isNotBlank(quoteLine.Kit_Number_this_Item_Belongs_to__c)  && mapOfProductQuantity.containsKey(quoteLine.Kit_Number_this_Item_Belongs_to__c) && (quoteLine.SBQQ__Product__r.Name.contains('Fuel Convenience Charge') || quoteLine.SBQQ__Product__r.Name.contains('Refill'))){
             quoteLine.SBQQ__Quantity__c = mapOfProductQuantity.get(quoteLine.Kit_Number_this_Item_Belongs_to__c);
             updatedChildlines.add(quoteLine);
          
        }
      }
        if(!updatedChildlines.isEmpty()){
          SObjectAccessDecision securityDecision = Security.stripInaccessible(AccessType.UPDATABLE, updatedChildlines);
          update securityDecision.getRecords();
        }
    }catch(Exception ex){
      SBR_3_0_Log.logException(ex);
    }
  }

}