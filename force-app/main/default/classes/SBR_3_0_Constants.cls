/**
 * @description       : Hold constant variables
 * @group             :
 * @last modified on  : 02-05-2024
 * @last modified by  : Hashem Abdul
 **/
public without sharing class SBR_3_0_Constants {
  // Environment Variables
  public static final String SANDBOX = 'SANDBOX';
  public static final String PRODUCTION = 'PRODUCTION';

  // Lead Variables
  public static final String LEAD_STATUS_QUALIFIED = 'Qualified';

  // Account Variables
  public static final String ACCOUNT_API_NAME = 'Account';
  public static final String ACCOUNT_STATUS_ACTIVE = 'Active';
  public static final String ACCOUNT_REC_TYPE_CREDIT = 'Credit';
  public static final String ACCOUNT_REC_TYPE_NON_CREDIT = 'Non-Credit';
  public static final String ACCOUNT_REC_TYPE_PROSPECT = 'Prospect';
  public static final String ACCOUNT_REC_TYPE_ERP = 'ERP Link';
  public static final String ACCOUNT_REC_TYPE_NAME_ERP = 'ERP_Link';
  public static final String ACCOUNT_REC_TYPE_OFFICE = 'Office';
  public static final String ACCOUNT_REC_TYPE_VENDOR = 'Vendor';
  public static final String ACCOUNT_REC_TYPE_GLOBAL = 'Global';
  public static final String ACCOUNT_REC_TYPE_NAME_GUEST = 'Guest';
  public static final String ACCOUNT_SALES_ACTIVITY_STATUS_PENDING_NON_CREDIT = 'Pending Non-Credit Conversion';
  public static final Id ACCOUNT_PROSPECT_RT_ID = Schema.getGlobalDescribe()
    .get(ACCOUNT_API_NAME)
    .getDescribe()
    .getRecordTypeInfosByName()
    .get(ACCOUNT_REC_TYPE_PROSPECT)
    .getRecordTypeId();
  public static final Id ACCOUNT_NON_CREDIT_RT_ID = Schema.getGlobalDescribe()
    .get(ACCOUNT_API_NAME)
    .getDescribe()
    .getRecordTypeInfosByName()
    .get(ACCOUNT_REC_TYPE_NON_CREDIT)
    .getRecordTypeId();
  public static final Id ACCOUNT_CREDIT_RT_ID = Schema.getGlobalDescribe()
    .get(ACCOUNT_API_NAME)
    .getDescribe()
    .getRecordTypeInfosByName()
    .get(ACCOUNT_REC_TYPE_CREDIT)
    .getRecordTypeId();
  public static final Id ACCOUNT_OFFICE_RT_ID = Schema.getGlobalDescribe()
    .get(ACCOUNT_API_NAME)
    .getDescribe()
    .getRecordTypeInfosByName()
    .get(ACCOUNT_REC_TYPE_OFFICE)
    .getRecordTypeId();
  public static final Id ACCOUNT_GUEST_RT_ID = Schema.getGlobalDescribe()
    .get(ACCOUNT_API_NAME)
    .getDescribe()
    .getRecordTypeInfosByDeveloperName()
    .get(ACCOUNT_REC_TYPE_NAME_GUEST)
    .getRecordTypeId();
  public static final Id ACCOUNT_CORP_LINK_RT_ID = Schema.getGlobalDescribe()
    .get(ACCOUNT_API_NAME)
    .getDescribe()
    .getRecordTypeInfosByDeveloperName()
    .get(ACCOUNT_REC_TYPE_NAME_ERP)
    .getRecordTypeId();

  public static final String ACCOUNT_EXTERNAL_USER = 'External_User';
  public static final String INTERNAL_SBR_USER = 'SF';
  public static final String DATA_MIGRATION_USER = 'Data_Migration_User';
  /*FRONT- 8124 : Deleted status string added to constant class*/
  public static final String ACCOUNT_STATUS_DELETED = 'Deleted';
  /*END FRONT- 8124*/

  //Associated Location Variables
  public static final String STATUS_PENDING = 'Pending';
  public static final String STATUS_VALID = 'Valid';
  public static final String STATUS_INVALID = 'Invalid';

  // Mulesoft JWT Variables
  public static final String TOKEN_KEY = 'access_token';

  // API Variables
  public static final String APP_ENCODED = 'application/x-www-form-urlencoded';
  public static final String APP_JSON = 'application/json';
  public static final String TEXT_XML = 'text/xml';

  //Location Variables
  public static final String LOCATION_API_NAME = 'Location';
  public static final String LOCATION_TYPE_JOBLOCATION = 'JobLocation';
  public static final String LOCATION_REC_TYPE_BRANCH = 'Branch';
  public static final String LOCATION_REC_TYPE_JOB_LOC = 'Shared Job Location';
  public static final String ASSOCIATED_LOCATION_API_NAME = 'AssociatedLocation';
  public static final String LOCATION_BRANCH_RT_ID = Schema.getGlobalDescribe()
    .get(LOCATION_API_NAME)
    .getDescribe()
    .getRecordTypeInfosByName()
    .get(LOCATION_REC_TYPE_BRANCH)
    .getRecordTypeId();
  public static final String LOCATION_JOB_RT_ID = Schema.getGlobalDescribe()
    .get(LOCATION_API_NAME)
    .getDescribe()
    .getRecordTypeInfosByName()
    .get(LOCATION_REC_TYPE_JOB_LOC)
    .getRecordTypeId();

  public static final String EXTERNAL_USER_PERMISSION_NAME = 'External_User';

  //Equipment Type Variables
  public static final String EQUIPMENTTYPE_API_NAME = 'Equipment_Type__c';

  // Cart Variables
  public static final String CART_REC_TYPE_OIL_GAS = 'Oil_Gas';
  public static final String CART_REC_TYPE_NAME_STANDARD = 'Standard';

  // Product Hierarchy variables
  public static final String PRODUCT_HIERARCHY_API_NAME = 'Product_Hierarchy__c';
  public static final String PRODUCT_HIERARCHY_REC_TYPE_PRODUCT_SUB_CATEGORY = 'Product Sub-Category';
  public static final Id PRODUCT_HIERARCHY_PRODUCT_SUB_CATEGORY_RT_ID = Schema.getGlobalDescribe()
    .get(PRODUCT_HIERARCHY_API_NAME)
    .getDescribe()
    .getRecordTypeInfosByName()
    .get(PRODUCT_HIERARCHY_REC_TYPE_PRODUCT_SUB_CATEGORY)
    .getRecordTypeId();

  // Product Variables
  public static final String PRODUCT_API_NAME = 'Product2';
  public static final String PRODUCT_REC_TYPE_ESKU = 'e_sku';
  public static final String PRODUCT_REC_TYPE_SKU = 'SKU';
  public static final Id PRODUCT_REC_TYPE_ESKU_ID = Schema.getGlobalDescribe()
    .get(PRODUCT_API_NAME)
    .getDescribe()
    .getRecordTypeInfosByDeveloperName()
    .get(PRODUCT_REC_TYPE_ESKU)
    .getRecordTypeId();
  public static final Id PRODUCT_REC_TYPE_SKU_ID = Schema.getGlobalDescribe()
    .get(PRODUCT_API_NAME)
    .getDescribe()
    .getRecordTypeInfosByDeveloperName()
    .get(PRODUCT_REC_TYPE_SKU)
    .getRecordTypeId();

  public static final String PRODUCT_STOCK_CLASS_MISC = 'MISC'; //25119

  //Product Item Variables
  public static final string PRODUCT_ITEM_API_NAME = 'ProductItem';

  //Profile Variables
  public static final String PROFILE_NAME_ADMIN = 'System Administrator';
  public static final String PROFILE_NAME_BUSINESS_ADMIN = 'Business Administrator';

  //Project Variables
  public static final String PROJECT_API_NAME = 'Project__c';

  //Quote Varibales
  public static final String QUOTE_API_NAME = 'SBQQ__Quote__c';
  public static final String QUOTE_REC_TYPE_RENTAL_QUOTE = 'Rental_Quote';
  public static final Id QUOTE_REC_TYPE_RENTAL_QUOTE_ID = Schema.getGlobalDescribe()
    .get(QUOTE_API_NAME)
    .getDescribe()
    .getRecordTypeInfosByDeveloperName()
    .get(QUOTE_REC_TYPE_RENTAL_QUOTE)
    .getRecordTypeId();

  //Order Variables
  public static final String ORDER_API_NAME = 'Order';
  public static final String ORDER_REC_TYPE_CONTRACT_ORDER = 'Contract_Order';
  public static final String ORDER_REC_TYPE_RESERVATION_ORDER = 'Reservation_Order';
  public static final String ORDER_REC_TYPE_RESERVATION_ORDER_LOCKED = 'Canceled_Reservation_Order';
  public static final String ORDER_REC_TYPE_SALES_ORDER = 'Sales_Order';
  public static final Id ORDER_REC_TYPE_CONTRACT_ORDER_ID = Schema.getGlobalDescribe()
    .get(ORDER_API_NAME)
    .getDescribe()
    .getRecordTypeInfosByDeveloperName()
    .get(ORDER_REC_TYPE_CONTRACT_ORDER)
    .getRecordTypeId();
  public static final Id ORDER_REC_TYPE_RESERVATION_ORDER_ID = Schema.getGlobalDescribe()
    .get(ORDER_API_NAME)
    .getDescribe()
    .getRecordTypeInfosByDeveloperName()
    .get(ORDER_REC_TYPE_RESERVATION_ORDER)
    .getRecordTypeId();
  public static final Id ORDER_REC_TYPE_RESLOCKED_ORDER_ID = Schema.getGlobalDescribe()
    .get(ORDER_API_NAME)
    .getDescribe()
    .getRecordTypeInfosByDeveloperName()
    .get(ORDER_REC_TYPE_RESERVATION_ORDER_LOCKED)
    .getRecordTypeId();

  //Order Detail Variables
  public static final String ORDER_DETAIL_TYPE = 'ReturnOrder';

  //Order Product Variables
  public static final String CUSTOMER_LOADED_SPECIFIC_PRICING_TYPE = 'Customer Loaded';

  //Campaign Variables
  public static final String CAMPAIGN_API_NAME = 'Campaign';
  public static final String CAMPAIGN_REC_TYPE_SALES = 'Sales';

  //Asset Variables
  public static final String ASSET_API_NAME = 'Asset';

  //Integration Variables
  public static final String INITIATING_CHANNEL = 'SLSFRC';
  public static final String SELLING_CHANNEL = 'SBRINT';
  public static final String LOCATIONTYPE_JOBSITE = 'Jobsite';
  public static final String LOCATIONTYPE_BRANCH = 'Branch';
  public static final String ATP_FULFILLMENTTYPE_DELIVERY = 'DEL';
  public static final String ATP_TRANSACTIONTYPE_ALL = 'ALL';
  public static final String FULFILLMENT_TYPE_DELIVERY = 'Delivery';
  public static final String FULFILLMENT_TYPE_PICKUP = 'Pickup';
  public static final String SALESFORCE = 'salesForce';
  public static final String INT_DATE_FORMAT = 'yyyy-MM-dd\'T\'HH:mm:ss\'Z\'';
  public static final String CAT_CLASS = 'Cat-Class';
  public static final String PARTS = 'Parts';
  public static final String MERCHANDISE = 'Merchandise';
  public static final String SUGGESTED_RATES = 'SUGGESTED';
  public static final String ERROR_MSG = 'Something went wrong, Please contact your System Admin.';
  //public static final String SBR_SELLING_CHANNEL = 'SBRB2B';
  public static final String TRANSPORTATION_SURCHARGE = 'TRANSPORTATION SURCHARGE';

  public static final String MISC_CHARGE_ITEMS_TYPE = 'MISC Charge Items';

  //Account Management Change Request variables
  public static final String Approval_Status_Submitted = 'Submitted';
  public static final String Approval_Status_Pending = 'Pending';
  public static final String Account_Management_Change_Request_API_NAME = 'Account_Management_Change_Request__c';
  public static final String Account_Relationship_Change_API_NAME = 'Account_Relationship_Change';
  public static final String OSR_Fingerprinting_Change_API_NAME = 'OSR_Fingerprinting_Change';
  public static final String Strategic_Type_Change_API_NAME = 'Strategic_Type_Change';
  public static final Id Account_Relationship_Change_RecordTypeId = Schema.getGlobalDescribe()
    .get(Account_Management_Change_Request_API_NAME)
    .getDescribe()
    .getRecordTypeInfosByDeveloperName()
    .get(Account_Relationship_Change_API_NAME)
    .getRecordTypeId();
  public static final Id OSR_Fingerprinting_Change_RecordTypeId = Schema.getGlobalDescribe()
    .get(Account_Management_Change_Request_API_NAME)
    .getDescribe()
    .getRecordTypeInfosByDeveloperName()
    .get(OSR_Fingerprinting_Change_API_NAME)
    .getRecordTypeId();
  public static final Id Strategic_Type_Change_RecordTypeId = Schema.getGlobalDescribe()
    .get(Account_Management_Change_Request_API_NAME)
    .getDescribe()
    .getRecordTypeInfosByDeveloperName()
    .get(Strategic_Type_Change_API_NAME)
    .getRecordTypeId();

  public static final String FULFILLMENT_SERVICE_URGENT = 'URGENT';
  public static final String FULFILLMENT_TYPE_CPU = 'CPU';

  //Resource Absence Integration Constants:Start
  public static final String ABSENCE_CORRECTION = 'correction';
  public static final String ABSENCE_APPROVED = 'approved';
  public static final String ABSENCE_COMPLETED = 'successfully completed';
  public static final String ABSENCE_CANCELED = 'canceled';
  public static final String ABSENCE_CORRECTED = 'corrected';
  public static final String ABSENCE_TYPE_VACATION = 'Vacation';
  public static final Integer ABSENCE_END_TIME_HOURS = 23;
  public static final Integer ABSENCE_END_TIME_MINUTES = 59;
  public static final Integer ABSENCE_START_TIME_HOURS = 12;
  public static final Integer ABSENCE_START_TIME_MINUTES = 0;
  //Resource Absence Integration Constants:End
  /* FRONT-10481 : Constants Values for productItem records */
  public static final String PRODUCTITEM_PARTS_AND_MERCH_RECORDTYPE_DEVELOPERNAME = 'Parts_and_Merchandise';
  public static final String PRODUCTITEM_FIELDSET_FOR_SALES_SEARCH_DEVELOPERNAME = 'SBR_SalesProductItemSearchFS';
  /*END : FRONT-10481*/
  //Comment Variables
  //SF-5848
  public static final String COMMENT_API_NAME = 'Comment__c';
  public static final String COLLECTION_COMMENT_REC_TYPE = 'Collection_Comment';

  // Account Relationship
  public static final String ACCOUNT_RELATIONSHIP_API_NAME = 'Account_Relationship__c';
  public static final String ACCOUNT_RELATIONSHIP_REC_TYPE_TRACKING = 'Tracking';
  public static final Id ACCOUNT_RELATIONSHIP_TRACKING_RT_ID = Schema.getGlobalDescribe()
    .get(ACCOUNT_RELATIONSHIP_API_NAME)
    .getDescribe()
    .getRecordTypeInfosByName()
    .get(ACCOUNT_RELATIONSHIP_REC_TYPE_TRACKING)
    .getRecordTypeId();
  
  // Damage Estimator
  public static final String BILLED_STATUS = 'BILLED';
  public static final String OPEN_STATUS = 'OPEN';
  public static final String SEND_TO_RM_STATUS = 'SEND TO RM';
  public static final String CLOSED_WITHOUT_BILLED_STATUS = 'CLOSED WITHOUT BILLED';
  public static final String CLOSE_WITHOUT_BILLING_REASON_AUTO_CLOSED = 'C7 - Auto-Closed';
}