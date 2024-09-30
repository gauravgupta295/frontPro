/**
 * @description       : Apex controller for getting Availability & Reserved data.
 * @author            : soomjeet.sahoo
 * @group             : Salesforce
 * @changes : soomjeet.sahoo   12-14-2023
 * @changes : Lakshya Khandelwal  22-Apr-2024   Added method fetchReservedOrderItems
 **/
@SuppressWarnings('PMD.ExcessiveParameterList')
public with sharing class SBR_3_0_PartsAndMerchAvailCmpController {
  /* FRONT - 12297,12298
  Field Mappings for availability modal
    | UI Label    | Field Name              | Api Name                              |
    | ----------- | ----------------------- | ------------------------------------- |
    | Rsv/Ord     | Order Quantity          | SM_PS_Order_Quantity__c              |
    | Avail       | Available Quantity      | SM_PS_PartsMerch_Available_Quantity__c |
    | Open W/O    | Quantity on Open WO     | SM_PS_Quantity_on_Open_WO__c           |
    | Open PO     | Quantity on Open Rental | SM_PS_Quantity_on_Open_Rental__c       |
    | In Transit  | Quantity in Transit     | SM_PS_Quantity_in_Transit_            |
    | Transit Out | Quantity Transfered Out | SM_PS_Quantity_Transfered_Out__c       |
  */
  @testVisible
  private static final String PARTS_AND_MERCH_RECORDTYPE_DEVELOPERNAME = SBR_3_0_Constants.PRODUCTITEM_PARTS_AND_MERCH_RECORDTYPE_DEVELOPERNAME;
  private static final String SOQL_TEMPLATE =
    'SELECT Location.{0} branch_name,' +
    'SUM(SM_PS_Order_Quantity__c) rsv_ord, ' +
    'SUM(SM_PS_PartsMerch_Available_Quantity__c) avail, ' +
    'SUM(SM_PS_Quantity_on_Open_WO__c) open_wo, ' +
    'SUM(SM_PS_Quantity_on_Open_Rental__c) open_po, ' +
    'SUM(SM_PS_Quantity_in_Transit__c) trans_in, ' +
    'SUM(SM_PS_Quantity_Transfered_Out__c) trans_out ' +
    'FROM ProductItem WHERE RecordType.DeveloperName =: PARTS_AND_MERCH_RECORDTYPE_DEVELOPERNAME ' +
    'AND Location.{1} =:location ' +
    'AND Product2Id in: productIds GROUP BY Location.{0}';

  /**
   * @description : returns availability data based on label/tab value.
   * @author soomjeet.sahoo | 12-14-2023
   * @param locationRec
   * @param labelType
   * @param productIds
   * @param isSpotlightPanelAggregated
   * @return List<AggregateResult>
   **/
  @AuraEnabled(cacheable=true)
  public static List<AggregateResult> getAllAvailabilityDetailsAggregated(
    string locationRec,
    String labelType,
    List<String> productIds,
    Boolean isSpotlightPanelAggregated
  ) {
    List<AggregateResult> availabilityResults = new List<AggregateResult>();
    try {
      String upperCasedLabelType = labelType?.toUpperCase();
      /* getting location info as Schema.location */
      Schema.location locationInformation = (Schema.location) JSON.deserialize(
        locationRec,
        Schema.location.class
      );
      String location = '';
      String query;
      List<String> queryParameters;
      switch on upperCasedLabelType {
        when 'BRANCH' {
          //Adding for branch
          location = locationInformation?.Id;
          queryParameters = new List<String>{
            'Branch_Location_Number__c',
            'Id'
          };
        }
        when 'DISTRICT' {
          //Adding for district
          location = locationInformation?.District__c;
          if (!isSpotlightPanelAggregated) {
            queryParameters = new List<String>{
              'Branch_Location_Number__c',
              'District__c'
            };
          } else {
            queryParameters = new List<String>{ 'District__c', 'District__c' };
          }
        }
        when 'REGION' {
          //Adding for region
          location = locationInformation?.Region__c;
          if (!isSpotlightPanelAggregated) {
            queryParameters = new List<String>{
              'Branch_Location_Number__c',
              'Region__c'
            };
          } else {
            queryParameters = new List<String>{ 'Region__c', 'Region__c' };
          }
        }
        when 'COMPANY' {
          //Adding for company
          location = locationInformation?.Company__c;
          if (!isSpotlightPanelAggregated) {
            queryParameters = new List<String>{
              'Branch_Location_Number__c',
              'Company__c'
            };
          } else {
            queryParameters = new List<String>{ 'Company__c', 'Company__c' };
          }
        }
      }

      query = String.format(SOQL_TEMPLATE, queryParameters);

      availabilityResults = Database.query(String.escapeSingleQuotes(query));
    } catch (Exception exp) {
      System.debug(
        'Exception at ' + exp.getCause() + ' :: ' + exp.getStackTraceString()
      );
      throw new AuraHandledException(exp.getMessage());
    }
    return availabilityResults;
  }

  /**
   * @description : returns aggregated value for spotlight consumable overview display for each labelType.
   * @author soomjeet.sahoo | 12-14-2023
   * @param locationRec
   * @param productIds
   * @return List<SBR_3_0_AvailabilityCmpController.AvailabilityWrapper>
   **/
  @AuraEnabled(cacheable=true)
  public static List<SBR_3_0_AvailabilityCmpController.AvailabilityWrapper> getConsumableSpotlightAvailabilityValues(
    string locationRec,
    List<String> productIds
  ) {
    List<SBR_3_0_AvailabilityCmpController.AvailabilityWrapper> wrapperValues = new List<SBR_3_0_AvailabilityCmpController.AvailabilityWrapper>();
    try {
      List<AggregateResult> branchSummaryResults = getAllAvailabilityDetailsAggregated(
        locationRec,
        'branch',
        productIds,
        true
      );
      wrapperValues.add(getSummedValues(branchSummaryResults, 'branch'));

      List<AggregateResult> districtSummaryResults = getAllAvailabilityDetailsAggregated(
        locationRec,
        'district',
        productIds,
        true
      );
      wrapperValues.add(getSummedValues(districtSummaryResults, 'district'));

      List<AggregateResult> regionSummaryResults = getAllAvailabilityDetailsAggregated(
        locationRec,
        'region',
        productIds,
        true
      );
      wrapperValues.add(getSummedValues(regionSummaryResults, 'region'));

      List<AggregateResult> companySummaryResults = getAllAvailabilityDetailsAggregated(
        locationRec,
        'company',
        productIds,
        true
      );
      wrapperValues.add(getSummedValues(companySummaryResults, 'company'));
    } catch (Exception exp) {
      System.debug(
        'Exception at ' + exp.getCause() + ' :: ' + exp.getStackTraceString()
      );
      throw new AuraHandledException(exp.getMessage());
    }
    return wrapperValues;
  }

  /**
   * @description : creates wrapper variables for spotlight availability wrapper
   * @author soomjeet.sahoo | 12-14-2023
   * @param aggRes
   * @param labelType
   * @return SBR_3_0_AvailabilityCmpController.AvailabilityWrapper
   **/
  private static SBR_3_0_AvailabilityCmpController.AvailabilityWrapper getSummedValues(
    List<AggregateResult> aggRes,
    String labelType
  ) {
    SBR_3_0_AvailabilityCmpController.AvailabilityWrapper resOp = new SBR_3_0_AvailabilityCmpController.AvailabilityWrapper();
    resOp.label = labelType.toUpperCase();
    resOp.available = '0';
    resOp.reserve = '0';
    resOp.pickUp = '0';
    resOp.utilization = '0';

    for (AggregateResult agg : aggRes) {
      String agglabel = (agg.get('branch_name') != null &&
        labelType == 'branch')
        ? 'Branch: PC' + (String) agg.get('branch_name')
        : labelType.toUppercase();
      resOp.label = agglabel;
      resOp.available = agg.get('avail') != null
        ? String.valueOf(agg.get('avail')).substringBefore('.')
        : '0';
      resOp.reserve = agg.get('rsv_ord') != null
        ? String.valueOf(agg.get('rsv_ord'))?.substringBefore('.')
        : '0';
      resOp.pickUp = agg.get('open_wo') != null
        ? String.valueOf(agg.get('open_wo'))?.substringBefore('.')
        : '0';
      resOp.utilization = agg.get('open_po') != null
        ? String.valueOf(agg.get('open_po'))?.substringBefore('.')
        : '0';
    }
    return resOp;
  }

  /**
   * @description : FRONT-23024 Method to get OrderItem records for Reserved SubTab in Sales Tab
   * @author : Lakshya Khandelwal   22-Apr-2024
   * @params : productIds - List of Product Ids
   **/
  @AuraEnabled(cacheable=true)
  public static List<OrderItem> fetchReservedOrderItems(
    String locationId,
    List<String> productIds
  ) {
    List<OrderItem> reservedTabOrderItemList = new List<OrderITem>();
    try {
      if (OrderItem.SObjectType.getDescribe().isAccessible()) {
        reservedTabOrderItemList = [
          SELECT
            Id,
            Order.Reservation_Order_Number__c,
            Order.Account.Name,
            Order.Start_Date__c,
            order.Estimated_Return_Date__c,
            Status_Filled_Qty__c,
            Status_Created_Qty__c,
            Quantity,
            Reserved_Item__c
          FROM OrderItem
          WHERE Product2Id IN :productIds
          AND Order.Sourcing_Branch__c = :locationId
          AND Reserved_Item__c = TRUE
        ];
      }
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
    return reservedTabOrderItemList;
  }
}