/*********************************************************************************************************************
* Apex Class: SBR_3_0_QuoteLineDA
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Class provides SOQL calls to retrieve specific quote line details
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Delvin Riley			2023-10-12			Initial version  
*********************************************************************************************************************/

public with sharing class SBR_3_0_QuoteLineDA implements SBR_3_0_QuoteLineDAI {
  public static SBQQ__QuoteLine__c getQuoteLine(String lineId) {
    //SF-5291,SF-5292 added Kit number and fuel plan fields
    return [
      SELECT
        Id,
        Apply_Standby_Rates__c,
        Kit_Number_this_Item_Belongs_to__c,
        Total_Price__c,
        SBQQ__Product__c,
        SBQQ__Product__r.Sell_Price__c,
        Contingency_Cost__c,
        Daily_Rate__c,
        Hourly_Rate__c,
        Line_Comments__c,
        Line_Item_Notes__c,
        Line_Name__c,
        Min_Rate__c,
        Monthly_Rate__c,
        Product_SKU__c,
        Rates_Overriden__c,
        SBQQ__Quantity__c,
        Seasonal_Multiplier__c,
        Selling_Price__c,
        Shift_Differential__c,
        Weekly_Rate__c,
        Seasonal_Rate__c,
        Rates_Branch__c,
        SBQQ__Product__r.Item_Number__c,
        SBQQ__Product__r.Stock_class__c,
        SBQQ__Product__r.Category__c,
        SBQQ__Product__r.Class__c,
        SBQQ__Product__r.Name,
        SBQQ__Product__r.Product_Type__c,
        SBQQ__Quote__c,
        SBQQ__Quote__r.Address_Type__c,
        SBQQ__Quote__r.Distance_to_Job_Site__c,
        SBQQ__Quote__r.Drivers_license_Number__c,
        SBQQ__Quote__r.Drivers_license_State__c,
        SBQQ__Quote__r.End_Date__c,
        SBQQ__Quote__r.Delivery_Charges_Override__c,
        SBQQ__Quote__r.Delivery_Charge__c,
        SBQQ__Quote__r.Pickup_Charge__c,
        SBQQ__Quote__r.Pickup_Charges_Override__c,
        SBQQ__Quote__r.Rates_To_Be_Used__c,
        SBQQ__Quote__r.SBQQ__DeliveryMethod__c,
        SBQQ__Quote__r.Start_Date__c,
        Specific_Pricing_Type__c,
        Specific_Pricing_Flag__c,
        SBQQ__Quote__r.Branch__r.Branch_Location_Number__c,
        SBQQ__Quote__r.Branch__r.Latitude_Longitude__Latitude__s,
        Fuel_Plan__c,
        SBQQ__Quote__r.Branch__r.Latitude_Longitude__Longitude__s,
        SBQQ__Quote__r.Branch__r.Time_Zone_Id__c,
        Suggested_Daily_Rate__c,
        Suggested_Minimum_Rate__c,
        Suggested_Monthly_Rate__c,
        Suggested_Weekly_Rate__c,
        SBQQ__Quote__r.Jobsite__r.City__c,
        SBQQ__Quote__r.Jobsite__r.Latitude_Longitude__Latitude__s,
        SBQQ__Quote__r.Jobsite__r.Latitude_Longitude__Longitude__s,
        SBQQ__Quote__r.Jobsite__r.State__c,
        SBQQ__Quote__r.Jobsite__r.Street_Address__c,
        SBQQ__Quote__r.Jobsite__r.Zip_Code__c,
        SBQQ__Quote__r.SBQQ__Account__r.RM_Account_Number__c,
        Override_Discount__c,
        SBQQ__Quote__r.Quote_Discount__c,
        Line_Item_Type__c,
        Discount_Percentage__c,
        SBQQ__Quote__r.Rentalman_Quote_Id__c,
        SBQQ__Quote__r.Submitted_to_Wynne__c,
        Misc_Charges_Type__c,
        Added_by_Crew_Expense__c
      FROM SBQQ__QuoteLine__c
      WHERE Id = :lineId
    ];
  }

  //25119 SBQQ__Product__r.Name,is_Forced_Item__c
  public static List<SBQQ__QuoteLine__c> getQuoteLines(String quoteId) {
    //SF-5291,SF-5292
    return [
      SELECT
        Id,
        SBQQ__ProductName__c,
        Apply_Standby_Rates__c,
        Contingency_Cost__c,
        Daily_Rate__c,
        Hourly_Rate__c,
        Line_Comments__c,
        Line_Item_Notes__c,
        Line_Name__c,
        is_User_Added__c,
        Min_Rate__c,
        Monthly_Rate__c,
        Product_SKU__c,
        Rates_Overriden__c,
        SBQQ__Quantity__c,
        Seasonal_Multiplier__c,
        Selling_Price__c,
        Shift_Differential__c,
        Weekly_Rate__c,
        Rates_Branch__c,
        SBQQ__Product__r.Item_Number__c,
        SBQQ__Product__r.Stock_class__c,
        SBQQ__Product__r.Category__c,
        SBQQ__Product__r.Class__c,
        SBQQ__Product__r.Product_Type__c,
        SBQQ__Product__r.Name,
        is_Forced_Item__c,
        SBQQ__Quote__c,
        SBQQ__Quote__r.Address_Type__c,
        SBQQ__Quote__r.Distance_to_Job_Site__c,
        SBQQ__Quote__r.Drivers_license_Number__c,
        SBQQ__Quote__r.Drivers_license_State__c,
        SBQQ__Quote__r.End_Date__c,
        SBQQ__Quote__r.Delivery_Charges_Override__c,
        SBQQ__Quote__r.Delivery_Charge__c,
        SBQQ__Quote__r.Pickup_Charge__c,
        SBQQ__Quote__r.Pickup_Charges_Override__c,
        SBQQ__Quote__r.Rates_To_Be_Used__c,
        SBQQ__Quote__r.SBQQ__DeliveryMethod__c,
        SBQQ__Quote__r.Start_Date__c,
        Specific_Pricing_Type__c,
        Specific_Pricing_Flag__c,
        SBQQ__Quote__r.Branch__r.Branch_Location_Number__c,
        SBQQ__Quote__r.Branch__r.Latitude_Longitude__Latitude__s,
        SBQQ__Quote__r.Branch__r.Latitude_Longitude__Longitude__s,
        SBQQ__Quote__r.Branch__r.Time_Zone_Id__c,
        Kit_Number_this_Item_Belongs_to__c,
        SBQQ__Quote__r.Jobsite__r.City__c,
        SBQQ__Quote__r.Jobsite__r.Latitude_Longitude__Latitude__s,
        SBQQ__Quote__r.Jobsite__r.Latitude_Longitude__Longitude__s,
        SBQQ__Quote__r.Jobsite__r.State__c,
        SBQQ__Quote__r.Jobsite__r.Street_Address__c,
        SBQQ__Quote__r.Jobsite__r.Zip_Code__c,
        SBQQ__Quote__r.SBQQ__Account__r.RM_Account_Number__c,
        Override_Discount__c,
        Line_Composite_Key__c,
        SBQQ__PricebookEntryId__c,
        Global_Line_Number__c,
        Total_Price__c,
        Line_Item_Type__c,
        Misc_Charges_Type__c,
        Added_by_Crew_Expense__c
      FROM SBQQ__QuoteLine__c
      WHERE SBQQ__Quote__c = :quoteId
    ];
  }

  // last modified for SAL-26036
  public static List<SBQQ__QuoteLine__c> getQuoteLines(Set<Id> quoteIds) {
    //SF-5291,SF-5292
    return [
      SELECT
        Id,
        SBQQ__ProductName__c,
        Apply_Standby_Rates__c,
        Contingency_Cost__c,
        Daily_Rate__c,
        Hourly_Rate__c,
        Line_Comments__c,
        Line_Item_Notes__c,
        Line_Name__c,
        is_User_Added__c,
        Min_Rate__c,
        Monthly_Rate__c,
        Product_SKU__c,
        Rates_Overriden__c,
        SBQQ__Quantity__c,
        Seasonal_Multiplier__c,
        Selling_Price__c,
        Shift_Differential__c,
        Weekly_Rate__c,
        SBQQ__Product__r.Item_Number__c,
        SBQQ__Product__r.Stock_class__c,
        SBQQ__Product__r.Category__c,
        SBQQ__Product__r.Class__c,
        SBQQ__Product__r.Product_Type__c,
        SBQQ__Product__r.Inventoried_Item__c,
        SBQQ__Product__r.Miscellaneous_Charge_Item__c,
        SBQQ__Product__r.Type_of_Misc_Charge_Item__c,
        SBQQ__Quote__c,
        SBQQ__Quote__r.Address_Type__c,
        SBQQ__Quote__r.Distance_to_Job_Site__c,
        SBQQ__Quote__r.Drivers_license_Number__c,
        SBQQ__Quote__r.Drivers_license_State__c,
        SBQQ__Quote__r.End_Date__c,
        SBQQ__Quote__r.Delivery_Charges_Override__c,
        SBQQ__Quote__r.Delivery_Charge__c,
        SBQQ__Quote__r.Pickup_Charge__c,
        SBQQ__Quote__r.Pickup_Charges_Override__c,
        SBQQ__Quote__r.Rates_To_Be_Used__c,
        SBQQ__Quote__r.SBQQ__DeliveryMethod__c,
        SBQQ__Quote__r.Start_Date__c,
        Specific_Pricing_Type__c,
        Specific_Pricing_Flag__c,
        SBQQ__Quote__r.Branch__r.Branch_Location_Number__c,
        SBQQ__Quote__r.Branch__r.Latitude_Longitude__Latitude__s,
        SBQQ__Quote__r.Branch__r.Latitude_Longitude__Longitude__s,
        SBQQ__Quote__r.Branch__r.Time_Zone_Id__c,
        SBQQ__Quote__r.Jobsite__r.City__c,
        SBQQ__Quote__r.Jobsite__r.Latitude_Longitude__Latitude__s,
        SBQQ__Quote__r.Jobsite__r.Latitude_Longitude__Longitude__s,
        SBQQ__Quote__r.Jobsite__r.State__c,
        SBQQ__Quote__r.Jobsite__r.Street_Address__c,
        SBQQ__Quote__r.Jobsite__r.Zip_Code__c,
        SBQQ__Quote__r.SBQQ__Account__r.RM_Account_Number__c,
        Override_Discount__c,
        Kit_Number_this_Item_Belongs_to__c,
        Line_Composite_Key__c,
        SBQQ__PricebookEntryId__c,
        Global_Line_Number__c,
        Total_Price__c,
        Line_Item_Type__c,
        Misc_Charges_Type__c,
        Added_by_Crew_Expense__c
      FROM SBQQ__QuoteLine__c
      WHERE SBQQ__Quote__c IN :quoteIds
    ];
  }

  public static Map<String, SBQQ__QuoteLine__c> getQuoteLinesMap(
    String quoteId
  ) {
    Map<String, SBQQ__QuoteLine__c> m = new Map<String, SBQQ__QuoteLine__c>();
    for (SBQQ__QuoteLine__c line : getQuoteLines(quoteId)) {
      //23899
      if (line.Line_Composite_Key__c != null) {
        m.put(line.Line_Composite_Key__c, line);
      } else {
        m.put(line.Id, line);
      }
    }
    return m;
  }

  public static List<SBQQ__QuoteLine__c> getQuoteLineByLineCompositeKey(
    List<String> lineCompositeKeys
  ) {
    return [
      SELECT Id
      FROM SBQQ__QuoteLine__c
      WHERE Line_Composite_Key__c = :lineCompositeKeys
    ];
  }

  public static List<SBQQ__QuoteLine__c> getQuoteLinesForScaffoldingQuotes(
    Set<Id> quoteIds
  ) {
    return [
      SELECT
        Id,
        Name,
        SBQQ__Quote__c,
        Misc_Charges_Type__c,
        SBQQ__Quote__r.Dismantle__c,
        SBQQ__Product__c,
        SBQQ__Quote__r.Erect__c,
        Start_Date__c
      FROM SBQQ__QuoteLine__c
      WHERE SBQQ__Quote__c IN :quoteIds AND Line_Name__c = 'ELABOR'
    ];
  }

  public static List<SBQQ__QuoteLine__c> getQuoteLinesForEDLaborQuotes(
    Set<Id> quoteIds,
    String chargeType
  ) {
    return [
      SELECT Id, Name, SBQQ__Quote__c, Misc_Charges_Type__c, SBQQ__Product__c
      FROM SBQQ__QuoteLine__c
      WHERE
        Line_Name__c = 'ELABOR'
        AND Misc_Charges_Type__c = :chargeType
        AND SBQQ__Quote__c IN :quoteIds
    ];
  }

  public static List<SBQQ__QuoteLine__c> getQuoteLinesForEDScaffoldingLaborQuotes(
    Set<Id> quoteIds
  ) {
    return [
      SELECT Id, Name, SBQQ__Quote__c, Misc_Charges_Type__c
      FROM SBQQ__QuoteLine__c
      WHERE
        Line_Name__c = 'ELABOR'
        AND SBQQ__Quote__c IN :quoteIds
        AND Misc_Charges_Type__c IN ('Erect', 'Dismantle')
    ];
  }

  //SAL-26002
  public static List<SBQQ__QuoteLine__c> getQuoteLines(
    Set<String> quoteLineItemsIds
  ) {
    return [
      SELECT
        Id,
        Apply_Standby_Rates__c,
        Contingency_Cost__c,
        Daily_Rate__c,
        Hourly_Rate__c,
        Line_Comments__c,
        Line_Item_Notes__c,
        Line_Name__c,
        Min_Rate__c,
        Monthly_Rate__c,
        Product_SKU__c,
        Rates_Overriden__c,
        SBQQ__Quantity__c,
        Seasonal_Multiplier__c,
        Selling_Price__c,
        Shift_Differential__c,
        Weekly_Rate__c,
        SBQQ__Product__r.Item_Number__c,
        SBQQ__Product__r.Stock_class__c,
        SBQQ__Product__r.Category__c,
        SBQQ__Product__r.Class__c,
        SBQQ__Product__r.Product_Type__c,
        SBQQ__Quote__c,
        SBQQ__Quote__r.Address_Type__c,
        SBQQ__Quote__r.Distance_to_Job_Site__c,
        SBQQ__Quote__r.Drivers_license_Number__c,
        SBQQ__Quote__r.Drivers_license_State__c,
        SBQQ__Quote__r.End_Date__c,
        SBQQ__Quote__r.Delivery_Charges_Override__c,
        SBQQ__Quote__r.Delivery_Charge__c,
        SBQQ__Quote__r.Pickup_Charge__c,
        SBQQ__Quote__r.Pickup_Charges_Override__c,
        SBQQ__Quote__r.Rates_To_Be_Used__c,
        SBQQ__Quote__r.SBQQ__DeliveryMethod__c,
        SBQQ__Quote__r.Start_Date__c,
        Specific_Pricing_Type__c,
        Specific_Pricing_Flag__c,
        SBQQ__Quote__r.Branch__r.Branch_Location_Number__c,
        SBQQ__Quote__r.Branch__r.Latitude_Longitude__Latitude__s,
        SBQQ__Quote__r.Branch__r.Latitude_Longitude__Longitude__s,
        SBQQ__Quote__r.Branch__r.Time_Zone_Id__c,
        Suggested_Daily_Rate__c,
        Suggested_Minimum_Rate__c,
        Suggested_Monthly_Rate__c,
        Suggested_Weekly_Rate__c,
        SBQQ__Quote__r.Jobsite__r.City__c,
        SBQQ__Quote__r.Jobsite__r.Latitude_Longitude__Latitude__s,
        SBQQ__Quote__r.Jobsite__r.Latitude_Longitude__Longitude__s,
        SBQQ__Quote__r.Jobsite__r.State__c,
        SBQQ__Quote__r.Jobsite__r.Street_Address__c,
        SBQQ__Quote__r.Jobsite__r.Zip_Code__c,
        SBQQ__Quote__r.SBQQ__Account__r.RM_Account_Number__c,
        Override_Discount__c,
        SBQQ__Quote__r.Quote_Discount__c,
        SBQQ__Quote__r.Company_Code__c,
        Misc_Charges_Type__c,
        Added_by_Crew_Expense__c
      FROM SBQQ__QuoteLine__c
      WHERE Id IN :quoteLineItemsIds
    ];
  }
  //P2P Update
  public static Map<String, SBQQ__QuoteLine__c> punchoutGetQuoteLinesMap(
    String quoteId
  ) {
    Map<String, SBQQ__QuoteLine__c> m = new Map<String, SBQQ__QuoteLine__c>();
    for (SBQQ__QuoteLine__c line : getQuoteLines(quoteId)) {
      m.put(line.Id, line);
    }
    return m;
  }
  
  //SAL - 27019/27018
  public static List<SBQQ__QuoteLine__c> getQuoteLinesRelatedToKit(
    List<String> relatedKitId
  ) {
    return [
      SELECT
        Id,
        Kit_Number_this_Item_Belongs_to__c,
        Apply_Standby_Rates__c,
        Contingency_Cost__c,
        Daily_Rate__c,
        Hourly_Rate__c,
        Line_Comments__c,
        Line_Item_Notes__c,
        Line_Name__c,
        Min_Rate__c,
        Monthly_Rate__c,
        Product_SKU__c,
        Rates_Overriden__c,
        SBQQ__Quantity__c,
        Seasonal_Multiplier__c,
        Selling_Price__c,
        Shift_Differential__c,
        Weekly_Rate__c,
        SBQQ__Product__r.Item_Number__c,
        SBQQ__Product__r.Stock_class__c,
        SBQQ__Product__r.Category__c,
        SBQQ__Product__r.Class__c,
        SBQQ__Product__r.Product_Type__c,
        SBQQ__Quote__c,
        SBQQ__Quote__r.Address_Type__c,
        SBQQ__Quote__r.Distance_to_Job_Site__c,
        SBQQ__Quote__r.Drivers_license_Number__c,
        SBQQ__Quote__r.Drivers_license_State__c,
        SBQQ__Quote__r.End_Date__c,
        SBQQ__Quote__r.Delivery_Charges_Override__c,
        SBQQ__Quote__r.Delivery_Charge__c,
        SBQQ__Quote__r.Pickup_Charge__c,
        SBQQ__Quote__r.Pickup_Charges_Override__c,
        SBQQ__Quote__r.Rates_To_Be_Used__c,
        SBQQ__Quote__r.SBQQ__DeliveryMethod__c,
        SBQQ__Quote__r.Start_Date__c,
        Specific_Pricing_Type__c,
        Specific_Pricing_Flag__c,
        SBQQ__Quote__r.Branch__r.Branch_Location_Number__c,
        SBQQ__Quote__r.Branch__r.Latitude_Longitude__Latitude__s,
        SBQQ__Quote__r.Branch__r.Latitude_Longitude__Longitude__s,
        SBQQ__Quote__r.Branch__r.Time_Zone_Id__c,
        Suggested_Daily_Rate__c,
        Suggested_Minimum_Rate__c,
        Suggested_Monthly_Rate__c,
        Suggested_Weekly_Rate__c,
        SBQQ__Quote__r.Jobsite__r.City__c,
        SBQQ__Quote__r.Jobsite__r.Latitude_Longitude__Latitude__s,
        SBQQ__Quote__r.Jobsite__r.Latitude_Longitude__Longitude__s,
        SBQQ__Quote__r.Jobsite__r.State__c,
        SBQQ__Quote__r.Jobsite__r.Street_Address__c,
        SBQQ__Quote__r.Jobsite__r.Zip_Code__c,
        SBQQ__Quote__r.SBQQ__Account__r.RM_Account_Number__c,
        Override_Discount__c,
        SBQQ__Quote__r.Quote_Discount__c,
        SBQQ__Quote__r.Company_Code__c,
        Misc_Charges_Type__c,
        Added_by_Crew_Expense__c
      FROM SBQQ__QuoteLine__c
      WHERE Kit_Number_this_Item_Belongs_to__c IN :relatedKitId
    ];
  }
}