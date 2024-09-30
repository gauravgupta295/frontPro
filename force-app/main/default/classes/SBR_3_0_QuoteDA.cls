/**
 * @description       :
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             :
 * @last modified on  : 03-28-2024
 * @last modified by  : Hashem Abdul
 **/
public without sharing class SBR_3_0_QuoteDA implements SBR_3_0_QuoteDAI {
  /**
   * @description - to get a quote by Id
   * @param quoteId - to get an specific quote by Id
   * @return      SBQQ__Quote__c  -returns an instance of SBQQ__Quote__c
   */
  @AuraEnabled(cacheable=true)
  public static SBQQ__Quote__c getQuote(String quoteId) {
    return [
      SELECT
        Id,
        OwnerId,
        CreatedById,
        SBQQ__Account__r.Company_Code__c,
        Contingency_Quote__c,
        Company_Code__c,
        Branch__r.Branch_Location_Number__c,
        Sourcing_Branch__r.Branch_Location_Number__c,
        Seasonal_Quote__c,
        Analysis_Region_Key__c,
        Show_Crew_Expense_Calculator__c,
        Shift_Rate__c,
        Shift_Pricing_Required__c,
        Standby_Pricing__c,
        Contingency_Plan__c,
        Apply_Standby_Rates__c,
        OT_Burden__c,
        SBQQ__SalesRep__c,
        ST_Burden__c,
        OT_Overhead__c,
        SBQQ__Account__r.RecordType.DeveloperName,
        Delivery_Date__c,
        Start_Date__c,
        SBQQ__Status__c,
        Created_By_Users_Branch__r.OMS_Sourcing_Enabled__c,
        ST_Overhead__c,
        OT_Profit__c,
        Delivery_Charges_Override__c,
        Delivery_Charges__c,
        ST_Profit__c,
        OT_Average__c,
        ST_Average__c,
        RecordType.DeveloperName
      FROM SBQQ__Quote__c
      WHERE Id = :quoteId
      WITH SECURITY_ENFORCED
    ];
  }

  /**
   * @description - to get list of quote for property with given IDs
   * @param ids   - set of quote Ids
   * @return      Map<Id, SBQQ__Quote__c> - map of quotes with ids as map keys
   */
  public static Map<Id, SBQQ__Quote__c> getQuotes(Set<Id> ids) {
    return new Map<Id, SBQQ__Quote__c>(
      [
        SELECT
          Name,
          Analysis_Region_Key__c,
          Est_End_Date__c,
          OMS_Sourcing_Enabled__c,
          Cart__c,
          Jobsite__r.Location.OMS_Sourcing_Enabled__c,
          SBQQ__Account__r.Company_Code__c,
          SBQQ__Account__r.RM_Account_Number__c,
          SBQQ__Account__r.SF_Account_Number__c,
          SBQQ__Account__r.Drivers_License__c,
          SBQQ__Account__r.Driver_s_License_State__c,
          Branch__c,
          Sourcing_Branch__c,
          Sourcing_Branch__r.Branch_Location_Number__c,
          Sourcing_Branch__r.Time_Zone_Id__c,
          Sourcing_Branch__r.Latitude_Longitude__Longitude__s,
          Sourcing_Branch__r.Latitude_Longitude__Latitude__s,
          SBQQ__DeliveryMethod__c,
          RecordType.DeveloperName,
          Total_Quoted_Amount__c,
          Start_Date__c,
          End_Date__c,
          P_O_Num__c,
          RPP__c,
          SBQQ__Account__r.Email__c,
          SBQQ__Account__r.Phone,
          Selling_Channel__c,
          Sales_Rep_ID__c,
          Jobsite__r.Branch__r.Branch_Location_Number__c,
          Jobsite__r.JobsiteName__c,
          Jobsite__r.Branch__r.Time_Zone_Id__c,
          Jobsite__r.Branch__r.TimeZone,
          Specific_Pricing_Flag__c,
          Jobsite__r.LocationId,
          Jobsite__r.Job_Number__c,
          Jobsite__r.Location.Name,
          Jobsite__r.Location.Street_Address__c,
          Jobsite__r.Location.Street_Address_2__c,
          Jobsite__r.Location.City__c,
          Jobsite__r.Time_Zone_Id__c,
          Jobsite__r.Location.State__c,
          Jobsite__r.Location.Country__c,
          Jobsite__r.Location.Zip_Code__c,
          SBQQ__Account__r.Record_Type_Text__c,
          SBQQ__Account__r.E_mail_Address__c,
          SBQQ__Notes__c,
          Delivery_Date__c,
          Jobsite__r.Job_Site_Contact_0__r.Phone,
          Jobsite__r.Location.Distance_Multiplier__c,
          Delivery_Charge__c,
          Delivery_Charges__c,
          Pickup_Charge__c,
          Pickup_Charges__c,
          Opt_Out_RPP__c,
          Opt_Out_Fuel_Charge__c,
          Branch__r.Branch_Location_Number__c,
          Branch__r.Latitude_Longitude__Latitude__s,
          Branch__r.Latitude_Longitude__Longitude__s,
          Branch__r.Time_Zone_Id__c,
          Branch__r.Analysis_Region_Key__c,
          Ordered_by__r.Email,
          Ordered_by__r.Phone,
          Ordered_by__r.LastName,
          Ordered_by__r.FirstName,
          Ordered_by__r.MobilePhone,
          Drivers_license_State__c,
          Drivers_license_Number__c,
          Distance_to_Job_Site__c,
          Rates_To_Be_Used__c,
          Address_Type__c,
          Delivery_Charges_Override__c,
          Pickup_Charges_Override__c,
          Total_Suggested_Delivery__c,
          Total_Suggested_Pickup__c,
          Number_of_Trucks__c,
          Using_3rd_Party__c,
          Jobsite__r.Street_Address__c,
          Jobsite__r.City__c,
          Jobsite__r.State__c,
          Jobsite__r.Zip_Code__c,
          Jobsite__r.Latitude_Longitude__Latitude__s,
          Jobsite__r.Latitude_Longitude__Longitude__s,
          Company_Code__c,
          SBQQ__Account__c,
          SBQQ_Last_Line_Update__c,
          SBQQ__LastCalculatedOn__c,
          Created_By_Users_Branch__r.OMS_Sourcing_Enabled__c,
		  Market_Segment__c,
          Territory_Number__c,
          Leave_Facility_Date__c,
          Install_Start_Date__c,
          Dismantle_Start_Date__c,
          Rentalman_Quote_Id__c,
          SBQQ__SalesRep__r.RepID__c,
          Jobsite__r.Job_Site_Contact__c,
          Jobsite__r.Job_Site_Id__c,
          Cash_Customer_Payment_Method__c,
          Cash_Customer_Payment_Amount__c,
          SBQQ__Account__r.Name,
          SBQQ__Account__r.BillingStreet,
          SBQQ__Account__r.BillingCity,
          SBQQ__Account__r.BillingStateCode,
          SBQQ__Account__r.BillingCountry,
          SBQQ__Account__r.BillingPostalCode,
          Use_Code__c,
          Pre_Bill_Rentals__c,
          Pro_Rate_Rentals__c,
          Day_of_Month_to_Bill_on__c,
          Print_Rates_on_Contracts__c,
          Within_City_Limits__c,
          Source_Code__c,
          Invoice_Due_Date_Code__c,
          Billing_Code__c,
          Reward_Number__c,
          Print__c,
          Fax_Email__c,
          Quote_Header_Comments__c,
          Delivery_Special_Instructions__c,
          Cart__r.Name,
          Pick_Up__c,
          Payment_Code__c,
          Signature__c,
          Delivered_By__c,
          RM_Account_Number__c,
          Jobsite__r.Territory_Number__c,
          Picked_Up_By__c,
          Branch__r.OMS_Sourcing_Enabled__c,
          (
            SELECT
              SBQQ__Quantity__c,
              Rates_Branch__c,
              Product_SKU__c,
              Selling_Price__c,
              Hourly_Rate__c,
              Suggested_Daily_Rate__c,
              Suggested_Weekly_Rate__c,
              Suggested_Monthly_Rate__c,
              Free_Flag__c,
              RM_Quote_Line_Number__c,
              Action__c,
              Discount_Percentage__c,
              Month_Rate_source_code__c,
              Week_Rate_Source_Code__c,
              Day_Rate_Source_Code__c,
              Suggested_Minimum_Rate__c,
              SBQQ__ListPrice__c,
              Rates_Overriden__c,
              SBQQ__Number__c,
              QuoteItemNumber__c,
              Misc_Charges_Type__c,
              Misc_Charges_Non_Taxable__c,
              Misc_Charges_Tax__c,
              SBQQ__Taxable__c,
              Misc_Charges_Item_Tax_Rate__c,
              Daily_Rate__c,
              Weekly_Rate__c,
              Monthly_Rate__c,
              Min_Rate__c,
              SBQQ__Product__r.Bulk_Item__c,
              SBQQ__Product__r.itemNumberUsedByReservationsRentalOut__c,
              SBQQ__Product__r.Product_SKU__c,
              SBQQ__Product__r.Category__c,
              Line_Comments__c,
              SBQQ__Product__r.Class__c,
              SBQQ__Product__r.ToolFlex__c,
              SBQQ__Product__r.Product_Type__c,
              SBQQ__Product__r.Tax__c,
              SBQQ__Product__r.SBQQ__Taxable__c,
              SBQQ__Product__r.Stock_Class__c,
              Equipment_Notes__c,
              SBQQ__Product__r.Item_Number__c,
              Unit_of_Measure__c,
              SBQQ__UnitCost__c,
              is_User_Added__c,
              Added_by_Crew_Expense__c,
              is_Forced_Item__c,
              Daily_Rate2__c,
              Weekly_Rate2__c,
              Monthly_Rate2__c,
              Kit_Number_this_Item_Belongs_to__c,
              Kit_component_item_or_neither__c
            FROM SBQQ__LineItems__r
          )
        FROM SBQQ__Quote__c
        WHERE Id = :ids
      ]
    );
  }

  /**
   * @description - method to get the list of `SBQQ__Quote__c` records within the set of `Id`'s passed.
   * @param recordTypeDevName - `SBQQ__Quote__c` record type developer name.
   * @return                  `Id` - `SBQQ__Quote__c` record Id.
   */
  public static Id getRecordTypeId(String recordTypeDevName) {
    return Schema.getGlobalDescribe()
      .get(SBR_3_0_Constants.QUOTE_API_NAME)
      .getDescribe()
      .getRecordTypeInfosByDeveloperName()
      .get(recordTypeDevName)
      .getRecordTypeId();
  }

  /**
   * @description    - Retrieves a list of SBR Quotes by a list of Quote Ids
   * @param quoteIds - Set of Quote Ids
   * @return         `List<SBQQ__Quote__c>` - List of quotes
   */
  public static List<SBQQ__Quote__c> getScaffoldingQuotes(Set<Id> quoteIds) {
    return [
      SELECT
        Id,
        Name,
        Analysis_Region_Key__c,
        Erect__c,
        Move_Cost_Crew_Summary__c,
        Move_Cost_Expense__c,
        Dismantle__c,
        Company_Code__c,
        Erection_Allocation__c,
        Dismantle_Allocation__c
      FROM SBQQ__Quote__c
      WHERE
        Id IN :quoteIds
        AND Analysis_Region_Key__c IN ('921', '933')
        AND Show_Crew_Expense_Calculator__c = TRUE
      WITH SECURITY_ENFORCED
    ];
  }

  /**
   * @description - Retrieve a record of `SBQQ__Quote__c` matching the given set of rentalmanId and companyCode.
   * @param rentalmanQuoteId - Rental Contract Id.
   * @param companyCode    - Salesforce Company Code value from picklist.
   * @return                 `SBQQ__Quote__c` - a single `SBQQ__Quote__c` record.
   */
  public static SBQQ__Quote__c getQuoteByRentalmanQuoteId(
    String rentalmanQuoteId,
    String companyCode
  ) {
    return [
      SELECT Id
      FROM SBQQ__Quote__c
      WHERE
        Rentalman_Quote_Id__c = :rentalmanQuoteId
        AND Company_Code__c = :companyCode
      WITH SECURITY_ENFORCED
      LIMIT 1
    ];
  }

  /**
   * @description - Retrieve a list of `SBQQ__Quote__c` matching the given set of Ids.
   * @param rentalmanQuoteId - Rental Contract Id.
   * @return  - `SBQQ__Quote__c` - a List of `SBQQ__Quote__c` record.
   */
  public static List<SBQQ__Quote__c> getQuoteByRentalmanQuoteId(
    String rentalmanQuoteId
  ) {
    return [
      SELECT
        Id,
        SBQQ__Account__r.RM_Account_Number_Display__c,
        Branch__r.Branch_Location_Number__c,
        Jobsite__r.Job_Site_Id__c,
        SBQQ__SalesRep__c,
        SBQQ__SalesRep__r.RepID__c,
        Secondary_Rep__c,
        Secondary_Rep__r.RepID__c
      FROM SBQQ__Quote__c
      WHERE Rentalman_Quote_Id__c = :rentalmanQuoteId
      WITH SECURITY_ENFORCED
      LIMIT 1
    ];
  }

  /**
   * @description -  retrieves a list of account with given account number.
   * @param relatedAccountNumber - String - required field for query filter.
   * @return - `List<Account>` - List of account records.
   */
  public static List<Account> getRelatedAccount(String relatedAccountNumber) {
    List<Account> relAccts = [
      SELECT
        ID,
        Name,
        RM_Account_Number__c,
        RecordTypeId,
        ShippingCity,
        ShippingCountry,
        ShippingPostalCode,
        ShippingState,
        ShippingStreet,
        ShippingLatitude,
        ShippingLongitude,
        Override_Address__Street__s,
        Override_Address__City__s,
        Override_Address__StateCode__s,
        Override_Address__PostalCode__s,
        Override_Address__CountryCode__s,
        Override_Address__Latitude__s,
        Override_Address__Longitude__s,
        BillingStreet,
        BillingCity,
        BillingState,
        BillingPostalCode,
        BillingCountry,
        BillingLatitude,
        BillingLongitude,
        Record_Type_Text__c
      FROM Account
      WHERE RM_Account_Number__c = :relatedAccountNumber
      WITH SECURITY_ENFORCED
      LIMIT 1
    ];

    return relAccts;
  }

  /**
   * @description -  retrieves a list of account with given account Id.
   * @param accountId - String - required field for query filter.
   * @return -  `List<Account>` - List of account records.
   */
  public static List<Account> getRelatedAccountId(String accountId) {
    List<Account> relAccts = [
      SELECT
        ID,
        Name,
        RM_Account_Number__c,
        RecordTypeId,
        ShippingCity,
        ShippingCountry,
        ShippingPostalCode,
        ShippingState,
        ShippingStreet,
        ShippingLatitude,
        ShippingLongitude,
        BillingStreet,
        BillingCity,
        BillingState,
        BillingPostalCode,
        BillingCountry,
        BillingLatitude,
        BillingLongitude,
        Override_Address__Street__s,
        Override_Address__City__s,
        Override_Address__StateCode__s,
        Override_Address__PostalCode__s,
        Override_Address__CountryCode__s,
        Override_Address__Latitude__s,
        Override_Address__Longitude__s,
        Record_Type_Text__c
      FROM Account
      WHERE Id = :accountId
      WITH SECURITY_ENFORCED
      LIMIT 1
    ];

    return relAccts;
  }

  /**
   * @description -  retrieves a list of Quotes with given quote Id.
   * @param quoteId - String - required field for query filter.
   * @return -  `List<SBQQ__Quote__c>` - List of Quote records.
   */
  public static List<SBQQ__Quote__c> getOrderDtlsForTotalTaxUpdate(
    String quoteId
  ) {
    return [
      SELECT
        Id,
        Name,
        Total_Misc__c,
        SBQQ__DeliveryMethod__c,
        Total_Delivery_Pickup__c,
        Total_Rental_Amount__c,
        RPP_Amount__c,
        Total_Sales_Amount__c,
        Total_Sales_Taxes__c,
        Total_Quoted_Amount__c,
        SBQQ__Status__c,
        RecordTypeId,
        RM_Account_Number__c,
        Company_Code__c,
        Rentalman_Quote_Id__c,
        (
          SELECT
            id,
            Line_Composite_Key__c,
            Misc_Charges_Item_Tax_Rate__c,
            Misc_Charges_Tax__c,
            Rental_Tax__c,
            Sales_Tax__c,
            Global_Line_Number__c,
            Total_Price__c
          FROM SBQQ__LineItems__r
        )
      FROM SBQQ__Quote__c
      WHERE Id = :quoteId
      LIMIT 1
      FOR UPDATE
    ];
  }

  public static SBQQ__Quote__c punchoutGetQuote(String quoteId) {
    return ([
      SELECT
        Rentalman_Quote_Id__c,
        Id,
        Name,
        Est_End_Date__c,
        OMS_Sourcing_Enabled__c,
        Cart__c,
        Jobsite__r.Location.OMS_Sourcing_Enabled__c,
        SBQQ__Account__r.Company_Code__c,
        SBQQ__Account__r.RM_Account_Number__c,
        SBQQ__Account__r.SF_Account_Number__c,
        SBQQ__Account__r.Drivers_License__c,
        SBQQ__Account__r.Driver_s_License_State__c,
        SBQQ__DeliveryMethod__c,
        RecordType.DeveloperName,
        Total_Quoted_Amount__c,
        Start_Date__c,
        End_Date__c,
        P_O_Num__c,
        RPP__c,
        SBQQ__Account__r.Email__c,
        SBQQ__Account__r.Phone,
        Selling_Channel__c,
        Sales_Rep_ID__c,
        SBQQ__Status__c,
        Submitted_to_Wynne__c,
        Jobsite__r.Branch__r.Branch_Location_Number__c,
        Jobsite__r.JobsiteName__c,
        Jobsite__r.Branch__r.Time_Zone_Id__c,
        Jobsite__r.Branch__r.TimeZone,
        P2P_Transmit_Status__c,
        SBQQ__Account__r.RM_Account_Number_Display__c,
        Jobsite__r.LocationId,
        Jobsite__r.Job_Number__c,
        Jobsite__r.Location.Name,
        Jobsite__r.Location.Street_Address__c,
        Jobsite__r.Location.Street_Address_2__c,
        Jobsite__r.Job_Site_Id__c,
        Jobsite__r.Location.City__c,
        Jobsite__r.Location.State__c,
        Jobsite__r.Location.Country__c,
        Jobsite__r.Location.Zip_Code__c,
        SBQQ__Account__r.Record_Type_Text__c,
        SBQQ__Account__r.E_mail_Address__c,
        SBQQ__Notes__c,
        Delivery_Date__c,
        Jobsite__r.Job_Site_Contact_0__r.Phone,
        Jobsite__r.Location.Distance_Multiplier__c,
        Delivery_Charge__c,
        Delivery_Charges__c,
        Pickup_Charge__c,
        Opt_Out_RPP__c,
        Opt_Out_Fuel_Charge__c,
        Branch__r.Branch_Location_Number__c,
        Branch__r.Latitude_Longitude__Latitude__s,
        Branch__r.Latitude_Longitude__Longitude__s,
        Branch__r.Time_Zone_Id__c,
        Branch__r.Analysis_Region_Key__c,
        Ordered_by__r.Email,
        Ordered_by__r.Phone,
        Ordered_by__r.LastName,
        Ordered_by__r.FirstName,
        Drivers_license_State__c,
        Drivers_license_Number__c,
        Distance_to_Job_Site__c,
        Rates_To_Be_Used__c,
        Address_Type__c,
        Delivery_Charges_Override__c,
        Pickup_Charges_Override__c,
        CurrencyIsoCode__c,
        Jobsite__r.Street_Address__c,
        Jobsite__r.City__c,
        Jobsite__r.State__c,
        Jobsite__r.Zip_Code__c,
        Jobsite__r.Latitude_Longitude__Latitude__s,
        Jobsite__r.Latitude_Longitude__Longitude__s,
        Company_Code__c,
        SBQQ__Account__c,
        (
          SELECT
            SBQQ__Quantity__c,
            Product_SKU__c,
            Selling_Price__c,
            Hourly_Rate__c,
            Suggested_Daily_Rate__c,
            Suggested_Weekly_Rate__c,
            Suggested_Monthly_Rate__c,
            Free_Flag__c,
            Suggested_Minimum_Rate__c,
            SBQQ__ListPrice__c,
            Rates_Overriden__c,
            SBQQ__Number__c,
            QuoteItemNumber__c,
            Misc_Charges_Type__c,
            Misc_Charges_Non_Taxable__c,
            Misc_Charges_Tax__c,
            SBQQ__Taxable__c,
            Misc_Charges_Item_Tax_Rate__c,
            Daily_Rate__c,
            Weekly_Rate__c,
            Monthly_Rate__c,
            Min_Rate__c,
            SBQQ__Product__r.Product_SKU__c,
            SBQQ__Product__r.Category__c,
            Line_Comments__c,
            SBQQ__Product__r.Class__c,
            SBQQ__Product__r.ToolFlex__c,
            SBQQ__Product__r.Product_Type__c,
            SBQQ__Product__r.Tax__c,
            SBQQ__Product__r.SBQQ__Taxable__c,
            SBQQ__Product__r.Stock_Class__c,
            SBQQ__Product__r.Item_Number__c,
            Unit_of_Measure__c,
            SBQQ__UnitCost__c
          FROM SBQQ__LineItems__r
        )
      FROM SBQQ__Quote__c
      WHERE Id = :quoteId
    ]);
  }

  public static SBQQ__Quote__c punchoutGetQuoteResponse(string quoteId) {
    return ([
      SELECT
        Id,

        Name,
        SBQQ__Account__r.RM_Account_Number__c,
        SBQQ__Account__r.RM_Account_Number_Display__c,
        SBQQ__Account__r.Name,
        SBQQ__Account__r.Company_Code__c,
        Createdby.Name,
        Createdby.FirstName,
        Createdby.LastName,
        LastModifiedby.Name,
        LastModifiedby.FirstName,
        LastModifiedby.LastName,
        RecordType.Name,
        Jobsite__r.Name__c,
        Jobsite__r.Street_Address__c,
        Jobsite__r.Street_Address_2__c,
        Jobsite__r.City__c,
        Jobsite__r.State__c,
        Jobsite__r.Zip_Code__c,
        CreatedDate,
        SBQQ__Status__c,
        Start_Date__c,
        Est_End_Date__c,
        Quote_Initiating_Channel__c,
        Delivery__c,
        SBQQ__NetAmount__c,
        CreatedDate__c,
        SBQQ__DeliveryMethod__c,
        Total_Quoted_Amount__c,
        Ordered_by__r.Id,
        Ordered_by__r.Name,
        Ordered_by__r.LastName,
        Ordered_by__r.FirstName,
        Ordered_by__r.Email,
        Ordered_by__r.Phone,
        Total_Rental_Amount__c,
        CurrencyIsoCode,
        Jobsite__r.Branch__c,
        Total_Misc__c,
        Total_Delivery_Pickup__c,
        Total_Ancillary__c,
        RPP_Amount__c,
        Total_Sales_Amount__c,
        Total_Sales_Taxes__c,
        Total_Estimated_Revenue__c,
        LastModifiedDate,
        LastModifiedById,
        CreatedById,
        Rentalman_Quote_Id__c,
        Job_Location__c,
        Job_Site_Contact__c,
        Branch_Location_Number__c,
        P_O_Num__c,
        Jobsite__r.Job_Site_Contact_0__r.Name,
        Jobsite__r.Job_Site_Contact_0__r.Phone,
        Jobsite__r.Job_Number__c,
        Branch__r.Branch_Location_Number__c,
        Branch__r.Name,
        Branch__r.Street_Address__c,
        Branch__r.Street_Address_2__c,
        Branch__r.City__c,
        Branch__r.State__c,
        Branch__r.Zip_Code__c,
        Branch__r.Time_Zone_Id__c,
        Branch__r.Time_Zone_Name__c,
        Delivery_Special_Instructions__c,
        Opt_Out_RPP__c,
        Opt_Out_Fuel_Charge__c,

        P2P_Transmit_Status__c,
        Selling_Channel__c,
        Branch__r.Email__c,
        Branch__r.Phone__c,
        Jobsite__r.Job_Site_Contact__c,
        Jobsite__r.Contact_Name__c,
        Delivery_Charges__c,
        Pickup_Charges__c,
        End_Date__c,
        Jobsite__r.Job_Site_Id__c,
        Branch__r.Analysis_Region__c,
        Branch__r.Fax_Phone_Number__c,
        Branch__r.Hours_Operation1__c,
        Branch__r.Hours_Operation2__c,
        Branch__r.Hours_Operation3__c,
        Branch__r.Speciality__c,
        Branch__r.Speciality1__c,
        Company_Code__c,
        Distance_to_Job_Site__c,
        Jobsite__r.Customer_Note1__c,
        Jobsite__r.Customer_Note2__c,
        Jobsite__r.Id,
        SBQQ__Account__r.Account_Status__c,
        SBQQ__Account__r.ERP_Link_Type__c,
        Unit_of_Distance__c,
        Employee_ID__c,
        Delivery_Charge__c,
        Pickup_Charge__c,
        Rentalman_Quote_Id_Display__c,
        (
          SELECT
            Id,
            Free_Flag__c,
            Hourly_Rate__c,
            Product_SKU__c,
            Weekly_Rate__c,
            SBQQ__ListPrice__c,
            SBQQ__Quote__c,
            Line_Item_Type__c,
            Name,
            RM_Quote_Line_Number__c,
            Branch_Location_Number__c,
            SBQQ__Product__c,
            Stock_class__c,
            SBQQ__Quantity__c,
            Rates_Overriden__c,
            Min_Rate__c,
            Daily_Rate__c,
            Monthly_Rate__c,
            Rental_Protection_Amount__c,
            Selling_Price__c,
            Unit_of_Measure__c,
            Date_Time_Out__c,
            Date_Time_In_or_Estimated_Return__c,
            Discount_Percentage__c,
            Cost__c,
            SBQQ__Taxable__c,
            Rentalman_System_Date_Time__c,
            Kit_Number_this_Item_belongs_to__c,
            Rate_Used__c,
            Hourly_Book_Rate__c,
            Minimum_Book_Rate__c,
            Monthly_Book_Rate__c,
            Shift_Differential__c,
            Day_Rate_Source_Code__c,
            Week_Rate_Source_Code__c,
            Month_Rate_source_code__c,
            Rentalman_Last_Maintained_Date_time__c,
            Rentalman_Last_Maintained_by__c,
            Legacy_Quote_Line_ID__c,
            Global_Line_Number__c,
            Rentalman_Creation_Date_Time__c,
            SBQQ__Product__r.Stock_class__c,
            SBQQ__Product__r.itemNumberUsedByReservationsRentalOut__c,
            SBQQ__Product__r.Item_Number__c,
            SBQQ__Product__r.Product_Type__c,
            SF_Line_Number__c,
            Misc_Charge__c,
            Misc_Charges_Type__c,
            Delivery_Method__c,
            SBQQ__Product__r.Name,
            SBQQ__Product__r.Primary_Image_URL__c,
            TotalPrice__c,
            Total_Price__c,
            is_Forced_Item__c,
            SBQQ__ProductName__c
          FROM SBQQ__LineItems__r
        )
      FROM SBQQ__Quote__c
      WHERE Id = :quoteId
    ]);
  }
}