/*********************************************************************************************************************
* Apex Class: SBR_3_0_LineItemEditorCmpController
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* @description - Controller class for any operations for sbr_3_0_lineItemEditorCmp LWC
* - SAL-6165, SAL-6859
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Avinash Rao             2022-09-19          Initial version    
    2.0         Kaylee Gabus            2022-10-10          Updates for SAL-6165
*********************************************************************************************************************/
public with sharing class SBR_3_0_LineItemEditorCmpController {
  public static final String QUOTE_LINE_TYPE = 'SBQQ__QuoteLine__c';
  public static final String ORDER_LINE_TYPE = 'OrderItem';

  /**
   * @description
   * @param lineId     id of record
   * @return  `String` lineItemType
   */
  @AuraEnabled(Cacheable=true)
  public static String getLineItemType(String lineId) {
    return String.valueOf(Id.valueOf(lineId).getSobjectType());
  }

  /**
   * @description
   * @param parentId
   * @param objectType
   * @return  `Boolean`
   */
  @AuraEnabled(Cacheable=true)
  public static Boolean hasSeasonalRate(String parentId, String objectType) {
    Boolean hasSeasonalRate;

    if (objectType == QUOTE_LINE_TYPE) {
      SBQQ__Quote__c quote = SBR_3_0_QuoteDA.getQuote(parentId);
      hasSeasonalRate = quote.Seasonal_Quote__c;
    } else if (objectType == ORDER_LINE_TYPE) {
      Order order = SBR_3_0_OrderDA.getOrder(parentId);
      hasSeasonalRate = order.Seasonal_Order__c;
    }

    return hasSeasonalRate;
  }

  /**
   * @description
   * @param recordId
   * @return  `List<SBQQ__QuoteLine__c>`
   */
  @AuraEnabled(cacheable=true)
  public static List<SBQQ__QuoteLine__c> getQuoteLineItems(String recordId) {
    return [
      SELECT
        Id,
        Name,
        SBQQ__ProductName__c,
        Product_SKU__c,
        SBQQ__Quantity__c,
        Min_Rate__c,
        Daily_Rate__c,
        Weekly_Rate__c,
        Monthly_Rate__c,
        SBQQ__UnitCost__c,
        Total_Price__c,
        Selling_Price__c
      FROM SBQQ__QuoteLine__c
      WHERE SBQQ__Quote__c = :recordId
      WITH SECURITY_ENFORCED
    ];
  }
  /**
   * @description
   * @param parentId
   * @param objectType
   * @return  `Boolean`
   */
  @AuraEnabled(Cacheable=true)
  public static Boolean hasShiftPricing(String parentId, String objectType) {
    Boolean hasShiftPricing;

    if (objectType == QUOTE_LINE_TYPE) {
      SBQQ__Quote__c quote = SBR_3_0_QuoteDA.getQuote(parentId);
      hasShiftPricing = quote.Shift_Rate__c;
    } else if (objectType == ORDER_LINE_TYPE) {
      Order order = SBR_3_0_OrderDA.getOrder(parentId);
      hasShiftPricing = order.Shift_Order__c;
    }

    return hasShiftPricing;
  }

  /**
   * @description
   * @param parentId
   * @param objectType
   * @return  `Boolean`
   */
  @AuraEnabled(Cacheable=true)
  public static Boolean hasStandbyPricing(String parentId, String objectType) {
    Boolean hasStandbyPricing;

    if (objectType == QUOTE_LINE_TYPE) {
      SBQQ__Quote__c quote = SBR_3_0_QuoteDA.getQuote(parentId);
      hasStandbyPricing = quote.Apply_Standby_Rates__c;
    } else if (objectType == ORDER_LINE_TYPE) {
      Order order = SBR_3_0_OrderDA.getOrder(parentId);
      hasStandbyPricing = order.Apply_Standby_Rates__c;
    }

    return hasStandbyPricing;
  }

  /**
   * @description
   * @param parentId
   * @param objectType
   * @return  `Boolean`
   */
  @AuraEnabled(Cacheable=true)
  public static Boolean hasContingencyPlan(String parentId, String objectType) {
    Boolean hasContingencyPlan;

    if (objectType == QUOTE_LINE_TYPE) {
      SBQQ__Quote__c quote = SBR_3_0_QuoteDA.getQuote(parentId);
      hasContingencyPlan = quote.Contingency_Quote__c;
    } else if (objectType == ORDER_LINE_TYPE) {
      Order order = SBR_3_0_OrderDA.getOrder(parentId);
      hasContingencyPlan = order.Contingency_Order__c;
    }

    return hasContingencyPlan;
  }

  /**
   * @description
   * @param lineId
   * @param groupId
   * @param parentId
   * @return  `LineEditorWrapper`
   */
  @AuraEnabled
  public static LineEditorWrapper getLineItem(
    String lineId,
    String groupId,
    String parentId
  ) {
    LineEditorWrapper wrapper = new LineEditorWrapper();
    List<SObject> lineItems;

    wrapper.objectType = getLineItemType(lineId);
    Map<String, Object> result = SBR_3_0_ProductDA.checkProductOptionForLineItem(
      lineId,
      wrapper.objectType
    ); //SF-5291,SF-5292
    wrapper.fuelPlanInfo = (result != null && !result.isEmpty())
      ? result
      : null; //SF-5291,SF-5292
    if (wrapper.objectType == QUOTE_LINE_TYPE) {
      SBQQ__QuoteLine__c line = SBR_3_0_QuoteLineDA.getQuoteLine(lineId);
      wrapper.lineItem = line;
      wrapper.parentId = line.SBQQ__Quote__c;
      wrapper.hasExisitingFuelPlan = SBR_3_0_ProductDA.hasExistingFuelChargeLineItem(
        line.SBQQ__Quote__c,
        line.Product_SKU__c,
        wrapper.objectType
      ); //SF-5291,SF-5292
      if (String.isNotBlank(line.Kit_Number_this_Item_Belongs_to__c)) {
        List<SBQQ__ProductOption__c> productOptions = SBR_3_0_ProductDA.getProductOptionForLineItem(
          new List<String>{ line.SBQQ__Product__c },
          new List<String>{ line.Kit_Number_this_Item_Belongs_to__c }
        );
        wrapper.productOption = !productOptions.isEmpty()
          ? productOptions[0]
          : new SBQQ__ProductOption__c();
      }
    } else {
      wrapper.objectType = ORDER_LINE_TYPE;
      lineItems = SBR_3_0_OrderLineDA.getOrderItems(parentId, groupId);

      if (!lineItems.isEmpty()) {
        OrderItem oi = [
          SELECT
            Id,
            Quantity,
            OrderId,
            Product2.Bulk_Item__c,
            Product2Id,
            Kit_Number_this_Item_Belongs_to__c,
            Product2.Product_SKU__c
          FROM OrderItem
          WHERE Id = :lineId
          WITH SECURITY_ENFORCED
        ];
        // SAL-27195 & SF-5963
        if (!oi.Product2.Bulk_Item__c && lineItems.size() > 1) {
          List<OrderItem> listSerializedOI = (List<OrderItem>) lineItems;
          for (OrderItem serializedOI : listSerializedOI) {
            // SF-6178
            if (String.isBlank(groupId)) {
              serializedOI.Quantity = oi.Quantity;
            } else {
              serializedOI.Quantity = lineItems.size();
            }
          }
          lineItems = (List<SObject>) listSerializedOI;
        }

        wrapper.parentId = oi.OrderId;
        wrapper.lineItems = lineItems;
        wrapper.hasExisitingFuelPlan = SBR_3_0_ProductDA.hasExistingFuelChargeLineItem(
          oi.OrderId,
          oi.Product2.Product_SKU__c,
          wrapper.objectType
        ); //SF-5291,SF-5292
        if (String.isNotBlank(oi.Kit_Number_this_Item_Belongs_to__c)) {
          List<SBQQ__ProductOption__c> productOptions = SBR_3_0_ProductDA.getProductOptionForLineItem(
            new List<String>{ oi.Product2Id },
            new List<String>{ oi.Kit_Number_this_Item_Belongs_to__c }
          );
          wrapper.productOption = !productOptions.isEmpty()
            ? productOptions[0]
            : new SBQQ__ProductOption__c();
        }
      }
    }

    if (String.isNotBlank(wrapper.parentId)) {
      wrapper.hasContingencyPlan = hasContingencyPlan(
        wrapper.parentId,
        wrapper.objectType
      );
      wrapper.hasSeasonalRate = hasSeasonalRate(
        wrapper.parentId,
        wrapper.objectType
      );
      wrapper.hasShiftPricing = hasShiftPricing(
        wrapper.parentId,
        wrapper.objectType
      );
      wrapper.hasStandbyPricing = hasStandbyPricing(
        wrapper.parentId,
        wrapper.objectType
      );
    }

    return wrapper;
  }

  /**
   * @description
   * @param parentId
   * @param objectType
   * @return  `List<SObject>`
   */
  @AuraEnabled(Cacheable=true)
  public static List<SObject> getLineItems(Id parentId, String objectType) {
    List<SObject> lineItems;

    if (objectType == QUOTE_LINE_TYPE) {
      lineItems = SBR_3_0_QuoteLineDA.getQuoteLines(parentId);
    } else {
      lineItems = SBR_3_0_OrderLineDA.getOrderItems(parentId);
    }

    return lineItems;
  }

  /**
   * @description
   * @param quoteLines edited lineItem
   * @param orderLines edited lineItem
   * @param objectType sObjectType
   * @return  `Boolean`updatesSuccessful
   * @exception
   */
  @AuraEnabled
  public static Boolean saveSObjects(
    List<SBQQ__QuoteLine__c> quoteLines,
    List<OrderItem> orderLines,
    String objectType
  ) {
    Boolean updatesSuccessful = false;
    //Pass a JSON stringified value, based on objecttype create record type
    //avoid Uirecordapi if possible
    //create wrapper class to pass data as a json itself

    try {
      if (objectType != 'OrderItem') {
        if (Schema.sObjectType.SBQQ__QuoteLine__c.isUpdateable()) {
          update quoteLines[0];
        }
      } else {
        List<OrderItem> childLines = updateQuantityonChildLineToMatchParent(
          orderLines
        );
        if (!childLines.isEmpty()) {
          orderLines.addAll(childLines);
        }
        if (Schema.sObjectType.OrderItem.isUpdateable()) {
          update orderLines;
        }
      }
      updatesSuccessful = true;
    } catch (Exception e) {
      System.debug(
        'LineItemEditorCmpController.saveSObjects error: ' + e.getMessage()
      );
      throw new AuraHandledException(e.getMessage());
    }

    return updatesSuccessful;
  }
  /**
   * @description
   * @param orderLineIds
   * @return  `Map<ID, OrderItem>`
   */
  public static Map<ID, OrderItem> getOrderItemsMap(Set<Id> orderLineIds) {
    return new Map<ID, OrderItem>(
      [
        SELECT
          Id,
          Product_SKU__c,
          Kit_Number_This_Item_Belongs_to__c,
          orderId,
          Quantity
        FROM OrderItem
        WHERE id IN :orderLineIds
        WITH SECURITY_ENFORCED
      ]
    );
  }

  /**
   * @param   newLines
   * @return  `Set<Id>`
   */
  public static Set<Id> getOrderLineIds(List<OrderItem> newLines) {
    Set<Id> orderLineIds = new Set<Id>();
    for (OrderItem orderLine : newLines) {
      orderLineIds.add(orderLine.Id);
    }
    return orderLineIds;
  }

  /**
   * @description
   * @param productOptions
   * @return  `Map<Id, Decimal>`
   */
  public static Map<Id, SBQQ__ProductOption__c> getProductOptionMap(
    List<SBQQ__ProductOption__c> productOptions
  ) {
    Map<Id, SBQQ__ProductOption__c> mapOfProductOptions = new Map<Id, SBQQ__ProductOption__c>();
    for (SBQQ__ProductOption__c option : productOptions) {
      if (!mapOfProductOptions.containsKey(option.SBQQ__OptionalSKU__c)) {
        mapOfProductOptions.put(option.SBQQ__OptionalSKU__c, option);
      }
    }
    return mapOfProductOptions;
  }

  /**
   * @description
   * @param mapOfProductQuantities
   * @param orderIds
   * @return  `List<OrderItem>`
   */
  public static List<OrderItem> getChildLines(
    Map<String, Decimal> mapOfProductQuantities,
    Set<Id> orderIds
  ) {
    return [
      SELECT
        Id,
        Kit_Number_this_Item_Belongs_to__c,
        Product2.Name,
        Quantity,
        groupID__c,
        Product2Id
      FROM OrderItem
      WHERE
        Kit_Number_this_Item_Belongs_to__c IN :mapOfProductQuantities.keySet()
        AND OrderId IN :orderIds
      WITH SECURITY_ENFORCED
    ];
  }

  /**
   * @description
   * @param mapOfProductQuantities
   * @param mapOfOptionQuantity
   * @param childlines
   * @return  `List<OrderItem>`
   */
  public static List<OrderItem> updateChildLines(
    Map<String, Decimal> mapOfProductQuantities,
    Map<Id, SBQQ__ProductOption__c> mapOfProductOptions,
    List<OrderItem> childlines
  ) {
    List<OrderItem> updatedChildlines = new List<OrderItem>();
    Set<String> groupIds = new Set<String>();
    for (OrderItem orderLine : childlines) {
      if (
        !groupIds.contains(orderLine.groupID__c) &&
        String.isNotBlank(orderLine.groupID__c) &&
        String.isNotBlank(orderLine.Kit_Number_this_Item_Belongs_to__c) &&
        mapOfProductQuantities.containsKey(
          orderLine.Kit_Number_this_Item_Belongs_to__c
        ) &&
        mapOfProductOptions.containsKey(orderLine.Product2Id) &&
        ((mapOfProductOptions.get(orderLine.Product2Id).SBQQ__Feature__r.Name ==
        'Sales Addons' &&
        mapOfProductQuantities.get(
          orderLine.Kit_Number_this_Item_Belongs_to__c
        ) > orderLine.Quantity) ||
        mapOfProductOptions.get(orderLine.Product2Id).SBQQ__Feature__r.Name ==
        'Rental Addons')
      ) {
        orderLine.Quantity =
          mapOfProductQuantities.get(
            orderLine.Kit_Number_this_Item_Belongs_to__c
          ) * mapOfProductOptions.get(orderLine.Product2Id).SBQQ__Quantity__c;
        updatedChildlines.add(orderLine);
        groupIds.add(orderLine.groupID__c);
      } else if (
        String.isNotBlank(orderLine.Kit_Number_this_Item_Belongs_to__c) &&
        mapOfProductQuantities.containsKey(
          orderLine.Kit_Number_this_Item_Belongs_to__c
        ) &&
        mapOfProductOptions.containsKey(orderLine.Product2Id) &&
        mapOfProductOptions.get(orderLine.Product2Id).SBQQ__Feature__r.Name ==
        'Kit Component'
      ) {
        orderLine.Quantity =
          mapOfProductQuantities.get(
            orderLine.Kit_Number_this_Item_Belongs_to__c
          ) * mapOfProductOptions.get(orderLine.Product2Id).SBQQ__Quantity__c;
        updatedChildlines.add(orderLine);
      } else if (
        String.isNotBlank(orderLine.Kit_Number_This_Item_Belongs_to__c) &&
        mapOfProductQuantities.containsKey(
          orderLine.Kit_Number_This_Item_Belongs_to__c
        ) &&
        (orderLine.Product2.Name.contains('Fuel Convenience Charge') ||
        orderLine.Product2.Name.contains('Refill'))
      ) {
        orderLine.Quantity = mapOfProductQuantities.get(
          orderLine.Kit_Number_This_Item_Belongs_to__c
        );
        updatedChildlines.add(orderLine);
      }
    }
    return updatedChildlines;
  }

  /**
   * @description
   * @param newLines  updated LineItems
   * @return  `List<OrderItem>`
   */
  public static List<OrderItem> updateQuantityonChildLineToMatchParent(
    List<OrderItem> newLines
  ) {
    Set<Id> orderIds = new Set<Id>();
    List<String> productSkus = new List<String>();

    Set<Id> orderLineIds = getOrderLineIds(newLines);
    Map<ID, OrderItem> mapOfOrderItems = getOrderItemsMap(orderLineIds);

    Map<String, Decimal> mapOfProductQuantities = new Map<String, Decimal>();

    for (OrderItem orderLine : newLines) {
      OrderItem oldLineData = mapOfOrderItems.get(orderLine.Id);
      if (
        String.isBlank(oldLineData.Kit_Number_This_Item_Belongs_to__c) &&
        String.isNotBlank(oldLineData.Product_SKU__c)
      ) {
        orderIds.add(oldLineData.orderId);
        productSkus.add(oldLineData.Product_SKU__c);
        if (!mapOfProductQuantities.containsKey(oldLineData.Product_SKU__c)) {
          mapOfProductQuantities.put(
            oldLineData.Product_SKU__c,
            orderLine.Quantity
          );
        }
      }
    }

    User loggedInUser = SBR_3_0_UserDA.getUserById(UserInfo.getUserId());
    String loggedInUserCompanyCode = loggedInUser.CompanyName;

    List<SBQQ__ProductOption__c> productOptions = SBR_3_0_ProductDA.getProductOptionsForProducts(
      productSkus,
      loggedInUserCompanyCode,
      'Forced Item'
    );
    productOptions.addAll(
      SBR_3_0_ProductDA.getProductKitComponents(productSkus)
    );

    Map<Id, SBQQ__ProductOption__c> mapOfProductOptions = getProductOptionMap(
      productOptions
    );

    List<OrderItem> childlines = getChildLines(
      mapOfProductQuantities,
      orderIds
    );

    List<OrderItem> updatedChildlines = updateChildLines(
      mapOfProductQuantities,
      mapOfProductOptions,
      childlines
    );
    return updatedChildlines;
  }

  public class LineEditorWrapper {
    @AuraEnabled
    public String objectType { get; set; }
    @AuraEnabled
    public String parentId { get; set; }
    @AuraEnabled
    public SObject lineItem { get; set; }
    @AuraEnabled
    public List<SObject> lineItems { get; set; }
    @AuraEnabled
    public Boolean hasContingencyPlan { get; set; }
    @AuraEnabled
    public Boolean hasSeasonalRate { get; set; }
    @AuraEnabled
    public Boolean hasShiftPricing { get; set; }
    @AuraEnabled
    public Boolean hasStandbyPricing { get; set; }
    @AuraEnabled
    public Map<String, Object> fuelPlanInfo { get; set; } //SF-5291,SF-5292
    @AuraEnabled
    public SObject productOption { get; set; }
    @AuraEnabled
    public Boolean hasExisitingFuelPlan { get; set; } //SF-5291,SF-5292
  }
}