/*********************************************************************************************************************
 * Apex Class: Sbr_3_0_ContractController
 *********************************************************************************************************************/
public with sharing class Sbr_3_0_ContractController {
  /**
   * @description       : getContractLineItemColumns
   * @author            : Gaurav Gupta
   * MethodName         : getContractLineItemColumns
   **/
  @AuraEnabled(cacheable=true)
  public static List<CustomDataTableCmpColumn__mdt> getContractLineItemColumns(String contractContext) {

    Map<String, String>  VARIANT_MAPPING_TO_CONTEXT= new Map<String, String>{'Rentals' => 'Contract Rental Line Item', 'Consumables' => 'Contract Sales/Misc Line Item'};
    return [
      SELECT
        ID,
        MasterLabel,
        Context__c,
        Label,
        Field_Name__c,
        fixedWidth__c,
        IsEditable__c,
        IsSortable__c,
        Order__c,
        Parent_Object__c,
        Type__c,
        Width_Unit__c
      FROM CustomDataTableCmpColumn__mdt
      WHERE Context__c =: VARIANT_MAPPING_TO_CONTEXT.get(contractContext) //Added for FRONT-28988
    ];
  }

  /**
   * @description       : getContractRentalLineItems
   * @author            : Gaurav Gupta
   * MethodName         : getContractRentalLineItems
   **/
  @AuraEnabled(cacheable=true)
  public static List<OrderItem> getContractRentalLineItems(string recordId) {
    return [
      SELECT
        ID,
        Product2.Name,
        Product2.Product_SKU__c,
        Product2.itemNumberUsedByReservationsRentalOut__c,
        Product2.Bulk_Item__c,
        SBQQ__Asset__c,
        SBQQ__Asset__r.Name,
        Meter_Reading_Out__c,
        Quantity,
        Min_Rate__c,
        Min_Rate2__c,
        Daily_Rate2__c,
        Weekly_Rate2__c,
        Monthly_Rate2__c,
        Selling_Price__c,
        UnitPrice,
        Total_Price__c,
        groupID__c,
        Cat_Class__c,
        Product2Id,
        Line_Comments__c,
        Specific_Pricing_Type__c,
        Suggested_Daily_Rate__c,
        Suggested_Weekly_Rate__c,
        Suggested_Monthly_Rate__c,
        Product2.Product_Type__c,
        Product2.Type_of_Misc_Charge_Item__c,
        Misc_Charges_Type__c,
        Product2.User_Select__c,
        Product2.Stock_class__c,
        Product2.Is_Kit__c,
        Product2.PPA_CatClass__c,
        is_Line_Item_Hidden__c,
        Line_Item_Type__c,
        is_User_Added__c,
        Status__c,
        Status_Created_Qty__c,
        Status_Filled_Qty__c,
        Status_Cancelled_Qty__c,
        Allow_Cancel__c,
        Discount_Percentage__c,
        //Added for Front-16656
        SBQQ__Asset__r.SM_PS_MiHr_Old_meter__c,
        SBQQ__Asset__r.SM_PS_Meter_Code_MIHR__c,
        SBQQ__Asset__r.SM_PS_Meter_2_Code__c,
        Free_Flag__c,
        Date_Time_Out__c
      FROM ORDERITEM
      WHERE ORDERID = :recordId AND Product2.Product_Type__c = 'Cat-Class'
      WITH USER_MODE
    ];
  }

  /**
   * @description       : getContractSalesLineItems
   * @author            : Gaurav Gupta
   * MethodName         : getContractSalesLineItems
   **/
  @AuraEnabled(cacheable=true)
  public static List<OrderItem> getContractSalesLineItems(string recordId) {
    return [
      SELECT
        ID,
        Product2.Name,
        Product2.Product_SKU__c,
        Product2.itemNumberUsedByReservationsRentalOut__c,
        Product2.Bulk_Item__c,
        SBQQ__Asset__c,
        SBQQ__Asset__r.Name,
        Meter_Reading_Out__c,
        Quantity,
        Min_Rate__c,
        Min_Rate2__c,
        Daily_Rate2__c,
        Weekly_Rate2__c,
        Monthly_Rate2__c,
        Selling_Price__c,
        UnitPrice,
        Total_Price__c,
        groupID__c,
        Cat_Class__c,
        Product2Id,
        Line_Comments__c,
        Order_Item_Unit_Of_Measure__c,
        Misc_Charge__c,
        Specific_Pricing_Type__c,
        Suggested_Daily_Rate__c,
        Suggested_Weekly_Rate__c,
        Suggested_Monthly_Rate__c,
        Product2.Product_Type__c,
        Product2.Type_of_Misc_Charge_Item__c,
        Misc_Charges_Type__c,
        Product2.User_Select__c,
        Product2.Stock_class__c,
        Product2.Is_Kit__c,
        Product2.Item_Number__c,
        is_Line_Item_Hidden__c,
        Line_Item_Type__c,
        is_User_Added__c,
        Status__c,
        Status_Created_Qty__c,
        Status_Filled_Qty__c,
        Status_Cancelled_Qty__c,
        Allow_Cancel__c,
        Discount_Percentage__c,
        Cost__c,
        Free_Flag__c,
        Order.Sourcing_Branch__c
      FROM ORDERITEM
      WHERE
        ORDERID = :recordId
        AND (Product2.Product_Type__c = 'Merchandise'
        OR Product2.Product_Type__c = 'Parts'
        OR Product2.Product_Type__c = 'Misc-Charge'
        OR Product2.Product_Type__c = 'MISC Charge Items')
      WITH USER_MODE
    ];
  }

  /**
   * @description       : getContractDeliveryLineItems
   * @author            : Amy
   * MethodName         : getContractDeliveryLineItems
   **/
  @AuraEnabled(cacheable=true)
  public static List<OrderItem> getContractDeliveryLineItems(string recordId) {
    return [
      SELECT
        ID,
        Product2.Name,
        Product2.Product_SKU__c,
        Product2.itemNumberUsedByReservationsRentalOut__c,
        Product2.Bulk_Item__c,
        SBQQ__Asset__c,
        SBQQ__Asset__r.Name,
        Meter_Reading_Out__c,
        Quantity,
        Min_Rate__c,
        Min_Rate2__c,
        Daily_Rate2__c,
        Weekly_Rate2__c,
        Monthly_Rate2__c,
        Selling_Price__c,
        UnitPrice,
        Total_Price__c,
        groupID__c,
        Cat_Class__c,
        Product2Id,
        Line_Comments__c,
        Specific_Pricing_Type__c,
        Suggested_Daily_Rate__c,
        Suggested_Weekly_Rate__c,
        Suggested_Monthly_Rate__c,
        Product2.Product_Type__c,
        Product2.Type_of_Misc_Charge_Item__c,
        Misc_Charges_Type__c,
        Product2.User_Select__c,
        Product2.Stock_class__c,
        Product2.Is_Kit__c,
        is_Line_Item_Hidden__c,
        Line_Item_Type__c,
        is_User_Added__c,
        Status__c,
        Status_Created_Qty__c,
        Status_Filled_Qty__c,
        Status_Cancelled_Qty__c,
        Allow_Cancel__c,
        Discount_Percentage__c
      FROM ORDERITEM
      WHERE
        ORDERID = :recordId
        AND Product2.Product_Type__c = 'MISC Charge Items'
        AND Product2.Stock_class__c = 'DEL'
      WITH USER_MODE
    ];
  }

  /**
   * @description       : getContractAncillaryLineItems
   * @author            : Amy
   * MethodName         : getContractAncillaryLineItems
   **/
  @AuraEnabled(cacheable=true)
  public static List<OrderItem> getContractAncillaryLineItems(string recordId) {
    return [
      SELECT
        ID,
        Product2.Name,
        Product2.Product_SKU__c,
        Product2.itemNumberUsedByReservationsRentalOut__c,
        Product2.Bulk_Item__c,
        SBQQ__Asset__c,
        SBQQ__Asset__r.Name,
        Meter_Reading_Out__c,
        Quantity,
        Min_Rate__c,
        Min_Rate2__c,
        Daily_Rate2__c,
        Weekly_Rate2__c,
        Monthly_Rate2__c,
        Selling_Price__c,
        UnitPrice,
        Total_Price__c,
        groupID__c,
        Cat_Class__c,
        Product2Id,
        Line_Comments__c,
        Specific_Pricing_Type__c,
        Suggested_Daily_Rate__c,
        Suggested_Weekly_Rate__c,
        Suggested_Monthly_Rate__c,
        Product2.Product_Type__c,
        Product2.Type_of_Misc_Charge_Item__c,
        Misc_Charges_Type__c,
        Product2.User_Select__c,
        Product2.Stock_class__c,
        Product2.Is_Kit__c,
        is_Line_Item_Hidden__c,
        Line_Item_Type__c,
        is_User_Added__c,
        Status__c,
        Status_Created_Qty__c,
        Status_Filled_Qty__c,
        Status_Cancelled_Qty__c,
        Allow_Cancel__c,
        Discount_Percentage__c
      FROM ORDERITEM
      WHERE
        ORDERID = :recordId
        AND (Line_Item_Type__c = 'YC'
        OR (Product2.Product_Type__c = 'MISC Charge Items'
        AND Product2.Stock_class__c != 'DEL'
        AND is_User_Added__c = FALSE))
      WITH USER_MODE
    ];
  }

  /**
   * @description       : deleteContractLineItems
   * @author            : Gaurav Gaur
   * MethodName         : deleteContractLineItems
   **/
  @AuraEnabled
  public static void deleteContractLineItems(List<OrderItem> orderItemList) {
    delete orderItemList;
  }
}