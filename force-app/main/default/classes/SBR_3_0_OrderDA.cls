/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 06-24-2024
 * @last modified by  : Salesforce
 * 1.1         Bhavesh Dhamecha    17-03-2023        Updated class from with sharing to without sharing for SAL-19645
 * 1.2         Venkat.             09-23-2023        Updated getOrderItems to include new fields
 * 1.3         Hashem Abdul        01-31-2024        Get Order Item Details Regardless of Asset Status (SF-6500)
 * 1.4         Hashem Abdul        02-02-2024        SF-6748 - Fix issue with Unable to lock row
**/
public without sharing class SBR_3_0_OrderDA implements SBR_3_0_OrderDAI {

    /**
     * @description queries order payment information
     * @param orderId Id of the order to query
     * @return List of orders, queried by orderId.
     */
    public static List<Order> getPaymentOrder(Id orderId) {
        return
            [SELECT
                Id,
                Company_Code__c,
                Contract_Order_Number__c,
                CreatedById,
                CurrencyIsoCode,
                Invoice_Sequence_Number__c,
                OrderNumber,
                OwnerId,
                Reservation_Order_Number__c,
                Return_Date__c,
                Sourcing_Branch__r.Branch_Location_Number__c
             FROM
                Order
             WHERE
                Id = :orderId
             WITH SECURITY_ENFORCED];
      }

      /**
       * @description gets payment account information
       * @param  accountId accountId Id of the account to query
       * @return List of account(s) matching accountId
       */
      public static List<Account> getPaymentAccount(Id accountId) {
        return
            [SELECT
                Id,
                Branch_Location_Number__c,
                Company_Code__c,
                CreatedById,
                CurrencyIsoCode,
                OwnerId,
                Salesforce_Account_Number__c
             FROM
                Account
             WHERE
                Id = :accountId
             WITH SECURITY_ENFORCED];
      }

      /**
       * @description getUsers description
       * @param  userId userId description
       * @return        return description
       */
      public static List<User> getUsers(Id userId) {
        return
            [SELECT
                Id,
                CompanyName,
                CurrencyIsoCode,
                Department,
                Wynne_User_Name__c
             FROM
                User
             WHERE
                Id = :userId
             WITH SECURITY_ENFORCED];
      }

    /**
     * @description   - to get an order by Id
     * @param orderId - to get an specific order by Id
     * @return        `Order` - order found by Id
     */
    public static Order getOrder(Id orderId) {
        return
            [SELECT
                Id,
                Apply_Standby_Rates__c,
                Branch__r.Branch_Location_Number__c,
                Company_Code__c,
                Contingency_Order__c,
                Contract_Order_Number__c,
                CreatedById,
                CurrencyIsoCode,
                OwnerId,
                Reservation_Order_Number__c,
                Sales_Rep__c,
                Seasonal_Order__c,
                Shift_Order__c,
                Sourcing_Branch__c
            FROM
                Order
            WHERE
                Id = :orderId
            WITH SECURITY_ENFORCED];
    }

    /**
     * @description getEodTill description
     * @param  eodTillRecordId Id of the End_of_Day_Till__c record
     * @return List of end of day till records matching the odTillRecordId
     */
    public static List<End_of_Day_Till__c> getEodTill(Id eodTillRecordId){
        return [
            SELECT
                Id,
                Amex__c,
                Amex_ROA__c,
                Cash_Sales__c,
                CreatedDate,
                CurrencyIsoCode,
                Deposits_Taken__c,
                Diners_Club__c,
                Diners_Club_ROA__c,
                Discover__c,
                Discover_ROA__c,
                Drawer_Bills_Fifty__c,
                Drawer_Bills_Five__c,
                Drawer_Bills_Hundred__c,
                Drawer_Bills_One__c,
                Drawer_Bills_Ten__c,
                Drawer_Bills_Twenty__c,
                Drawer_Bills_Two__c,
                Drawer_Coins_Dime__c,
                Drawer_Coins_Fifty__c,
                Drawer_Coins_Nickel__c,
                Drawer_Coins_One__c,
                Drawer_Coins_Penny__c,
                Drawer_Coins_Quarter__c,
                Inter_Location_Cash__c,
                Last_Edited_By_RM_User__c,
                MasterCard__c,
                MasterCard_ROA__c,
                Net_Cash_From_Invoice__c,
                Next_Day_Drawer__c,
                Refunds_Not_Given__c,
                Start_Drawer__c,
                Submitted__c,
                Submitted_Date__c,
                Till_Date__c,
                Total_Cash__c,
                Total_Checks__c,
                Total_Credit_Cards__c,
                Total_Currency__c,
                Total_Deposit__c,
                Total_Deposit_in_Bank__c,
                Total_Drawer__c,
                Total_ROA_Checks__c,
                Total_Transaction__c,
                Uncollected__c,
                Visa__c,
                Visa_ROA__c,
                Wire_Transfer__c
            FROM
                End_of_Day_Till__c
            WHERE
                Id = :eodTillRecordId];
    }

    /**
     * @description        - Retrieve the branch based on the branch number and company code
     * @param branchNumber - String representation of the branch number
     * @param cc  - String representation of the company code
     * @return  - `Schema.Location` - a single `SBQQ__Quote__c` record is returned.
     */
    public static Schema.Location getRelatedBranchLocation(String branchNumber, String cc){
        return
            [SELECT
                Id,
                Branch_Location_Number__c
             FROM
                Location
             WHERE
                Recordtype.Name = :SBR_3_0_Constants.LOCATION_REC_TYPE_BRANCH
                AND Branch_Location_Number__c = :branchNumber
                AND Company_Code__c = :cc
             WITH SECURITY_ENFORCED
             LIMIT 1] ?? null;
    }

    /**
     * @description Retrieves a list of account with given account number.
     * @param relatedAccountNumber - String - required field for query filter.
     * @return  - `List<Account>` - List of account records.
     */
    public static List<Account> getRelatedAccount(String relatedAccountNumber){
        return [
            SELECT
                Id,
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
                BillingCity,
                BillingCountry,
                BillingPostalCode,
                BillingState,
                BillingStreet,
                BillingLatitude,
                BillingLongitude,
                Override_Address__Street__s,
                Override_Address__City__s,
                Override_Address__Statecode__s,
                Override_Address__PostalCode__s,
                Override_Address__Countrycode__s,
                Override_Address__Latitude__s,
                Override_Address__Longitude__s
            FROM
                Account
            WHERE
                RM_Account_Number__c = :relatedAccountNumber
            WITH SECURITY_ENFORCED
            LIMIT 1];// PS:5620:SG: Removed the FOR Update Keyword that is causing the row locks.
    }

    /**
     * @description Get Orders using Order Ids
     * @author Hashem Abdul | 02-02-2024
     * @param ids
     * @return Map<Id, Order>
     **/
    public static Map<Id, Order> getOrders(Set<Id> ids) {
        return new Map<Id, Order>([
            SELECT
                Name,
                RecordTypeId,
                Market_Segment__c,
                Install_Start_Date__c,
                AccountId,
                Account.BillingStreet,
                Account.BillingCity,
                Account.BillingStateCode,
                Account.BillingCountry,
                Account.BillingPostalCode,
                Account.BirthDate__c,
                Account.Company_Code__c,
                Account.Date_of_Birth__c,
                Account.DL_Expiration_Date__c,
                Account.Drivers_License__c,
                Account.Driver_s_License_State__c,
                Account.E_mail_Address__c,
                Account.Email__c,
                Account.Employed_By__c,
                Account.Free_Delivery__c,
                Account.Free_Pickup__c,
                Account.Name,
                Account.Phone,
                Account.Record_Type_Text__c,
                Account.RM_Account_Number__c,
                Account.RM_Cash_Number__c,
                Account.RM_Cash_State__c,
                Account.SF_Account_Number__c,
                Account.ShippingStreet,
                Account.ShippingCity,
                Account.ShippingStateCode,
                Account.ShippingCountry,
                Account.ShippingPostalCode,
                Account.Social_Security_Number__c,
                Branch__r.Analysis_Region_key__c,
                Branch__r.Branch_Location_Number__c,
                Branch__r.Latitude_Longitude__Latitude__s,
                Branch__r.Latitude_Longitude__Longitude__s,
                Branch__r.OMS_Sourcing_Enabled__c,
                Branch__r.Time_Zone_Id__c,
                Cart_ID__c,
                Cash_Customer_Payment_Method__c,
                Cash_Customer_Payment_Amount__c,
                Company_Code__c,
                Contract_Order_Number__c,
                CreatedBy.Name,
                Created_By_Users_Branch__r.OMS_Sourcing_Enabled__c,
                Delivered_By__c,
                Deliverymethod__c,
                Delivery_Charge__c,
                Delivery_Charges__c,
                Delivery_Charges_Override__c,
                Delivery_Instructions__c,
                Dismantle_Start_Date__c,
                Distance_to_Job_Site__c,
                Driver_License_Number__c,
                Driver_License_State__c,
                Earliest_Delivery_Date__c,
                EffectiveDate,
                EndDate,
                Estimated_Return_Date__c,
                Expense_Notes__c,
                Fax_Email__c,
                Invoice_Due_Date_Code__c,
                Is_RPP_Charge__c,
                IsDeliveryOptionsChanged__c,
                Jobsite__r.Branch__r.Branch_Location_Number__c,
                Jobsite__r.Branch__r.Time_Zone__c,
                Jobsite__r.Branch__r.Time_Zone_Id__c,
                Jobsite__r.Branch__r.Time_Zone_Name__c,
                Jobsite__r.City__c,
                Jobsite__r.JobsiteName__c,
                Jobsite__r.Job_Number__c,
                Jobsite__r.Job_Site_Contact__c,
                Jobsite__r.Job_Site_Id__c,
                Jobsite__r.Latitude_Longitude__Latitude__s,
                Jobsite__r.Latitude_Longitude__Longitude__s,
                Jobsite__r.LocationId,
                Jobsite__r.Location.City__c,
                Jobsite__r.Location.Country__c,
                Jobsite__r.Location.Distance_Multiplier__c,
                Jobsite__r.Location.Latitude_Longitude__Latitude__s,
                Jobsite__r.Location.Latitude_Longitude__Longitude__s,
                Jobsite__r.Location.Name,
                Jobsite__r.Location.OMS_Sourcing_Enabled__c,
                Jobsite__r.Location.State__c,
                Jobsite__r.Location.Street_Address__c,
                Jobsite__r.Location.Street_Address_2__c,
                Jobsite__r.Location.Zip_Code__c,
                Jobsite__r.State__c,
                Jobsite__r.Street_Address__c,
                Jobsite__r.Territory_Number__c,
                Jobsite__r.Time_Zone_Id__c,
                Jobsite__r.Zip_Code__c,
                LastOrderItemUpdated__c,
                Leave_Facility_Date__c,
                Number_of_Trucks__c,
                OMS_Sourcing_Enabled__c,
                Opt_Out_RPP__c,
                Opt_Out_Fuel_Charge__c,
                OrderNumber,
                Order_Initiating_Channel__c,
                Order_By__r.Email,
                Order_By__r.Phone,
                Order_By__r.Firstname,
                Order_By__r.Lastname,
                Order_By__r.MobilePhone,
                Order_Header_Comments__c,
                Payment_Code__c,
                Pick_Up__c,
                Picked_Up_By__c,
                Pickup_Charge__c,
                Pickup_Charges__c,
                Pickup_Charges_Override__c,
                PoNumber,
                Print__c,
                Start_Date__c,
                Rentalman_Quote_Id__c,
                Reservation_Order_Number__c,
                Return_Date__c,
                Reward_Number__c,
                RM_Account_Number__c,
                RPP__c,
                Sales_Rep__r.RepID__c,
                SBQQ__Quote__r.Name,
                SBQQ__Quote__c,
                Secondary_Rep__c,
                Selling_Channel__c,
                Signature__c,
                Source_Code__c,
                Sourcing_Branch__r.Branch_Location_Number__c,
                Sourcing_Branch__r.Latitude_Longitude__Latitude__s,
                Sourcing_Branch__r.Latitude_Longitude__Longitude__s,
                Sourcing_Branch__r.Time_Zone_Id__c,
                Specific_Pricing_Flag__c,
                Territory_Number__c,
                Total_Suggested_Delivery__c,
                Total_Suggested_Pickup__c,
                Use_Code__c,
                Using_3rd_Party__c,
                Within_City_Limits__c,
                (SELECT
                    Id,
                    Action__c,
                    Cat_Class__c,
                    Contract_Line_Number__c,
                    Credit_Reason_Code__c,
                    Daily_Rate__c,
                    Daily_Rate2__c,
                    Date_Time_Out__c,
                    Discount_Percentage__c,
                    Equipment_Comments__c,
                    Free_Flag__c,
                    Global_Line_Number__c,
                    Hourly_Rate__c,
                    is_User_Added__c,
                    is_Forced_Item__c,
                    Item_Marked_For_Cancellation__c,
                    Item_Number__c,
                    Kit_component_item_or_neither__c,
                    Kit_Number_This_Item_Belongs_To__c,
                    Line_Comments__c,
                    Line_Item_Type__c,
                    ListPrice,
                    Meter_Reading_Out__c,
                    Min_RA__c,
                    Min_Rate__c,
                    Misc_Charge__c,
                    Misc_Charges_Item_Tax_Rate__c,
                    Misc_Charges_Non_Taxable__c,
                    Misc_Charges_Tax__c,
                    Misc_Charges_Type__c,
                    Monthly_Rate__c,
                    Monthly_Rate2__c,
                    Number_of_Credit_Days__c,
                    Number_of_Credit_Hours__c,
                    Order_Item_Unit_Of_Measure__c,
                    OrderItemNumber,
                    Product2Id,
                    Product2.Bulk_Item__c,
                    Product2.Category__c,
                    Product2.Class__c,
                    Product2.Item_Number__c,
                    Product2.itemNumberUsedByReservationsRentalOut__c,
                    Product2.Name,
                    Product2.Product_SKU__c,
                    Product2.Product_Type__c,
                    Product2.QuantityUnitOfMeasure,
                    Product2.SBQQ__Taxable__c,
                    Product2.Stock_Class__c,
                    Product2.Tax__c,
                    Product2.ToolFlex__c,
                    Quantity,
                    Quantity__c,
                    Rates_Branch__c,
                    Rates_Overriden__c,
                    Reservation_Line_Number__c,
                    Requested_Category__c,
                    Requested_Class__c,
                    SBQQ__Asset__r.SM_PS_Equipment_Number__c,
                    Selling_Price__c,
                    Suggested_Daily_Rate__c,
                    Suggested_Minimum_Rate__c,
                    Suggested_Monthly_Rate__c,
                    Suggested_Weekly_Rate__c,
                    Taxable__c,
                    Unit_of_Measure__c,
                    UnitPrice,
                    Weekly_Rate__c,
                    Weekly_Rate2__c
                FROM
                    OrderItems)
            FROM
                Order
            WHERE
                Id = :ids
            FOR UPDATE]); // added Product2.Bulk_Item__c,Product2.itemNumberUsedByReservationsRentalOut__c for SAL-24243
    }

    /**
     * @description Get a List of Order Items
     * @author Hashem Abdul | 02-06-2024
     * @param orderItemIds
     * @return List<OrderItem>
     **/
    public static List<OrderItem> getOrderItems(Set<Id> orderItemIds) {
        return new List<OrderItem>(
            [SELECT
                ID,
                Daily_Rate_Calc__c,
                Daily_Rate_Calc_AutoFill__c,
                Daily_Rate2__c,
                Extended_Weight__c,
                Extended_Weight_Autofill__c,
                Min_Rate_Calc__c,
                Min_Rate_Calc_Autofill__c,
                Monthly_Rate_Calc__c,
                Monthly_Rate_Calc_Autofill__c,
                Monthly_Rate2__c,
                Product2Id,
                OrderId,
                Quantity,
                Specific_Pricing_Flag__c,
                Specific_Pricing_Type__c,
                Suggested_Daily_Rate__c,
                Suggested_Daily_Rate_Calc_AutoFill__c,
                Suggested_Minimum_Rate__c,
                Suggested_Minimum_Rate_Calc_AutoFill__c,
                Suggested_Monthly_Rate__c,
                Suggested_Monthly_Rate_Calc_AutoFill__c,
                Suggested_Weekly_Rate__c,
                Suggested_Weekly_Rate_Calc_AutoFill__c,
                Weekly_Rate_Calc__c,
                Weekly_Rate_Calc_Autofill__c,
                Weekly_Rate2__c
            FROM
                OrderItem
            WHERE
                Id IN :orderItemIds
        ]);
    }

    /**
     * @description               - Get Order Item Details By Pickup Ticket Numbers
     * @param pickupTicketNumbers - List of String containing Pickup Ticket Numbers
     * @return - `List<Order_Item_Detail__c>` - List of Order Item Details
     */
    public static List<Order_Item_Detail__c> getOrdItmDtlsByPickupTicketNumbers(List<String> pickupTicketNumbers){
        return new List<Order_Item_Detail__c> (
            [SELECT
                Id,
                Line_Item__c,
                Pickup_Ticket__c,
                Return_Order_Number__c
             FROM
                Order_Item_Detail__c
             WHERE
                 Pickup_Ticket__c in :pickupTicketNumbers]);
    }

    /**
     * @description //25058, SF-6500 - Get Order Item details regardless of Asset status
     * @author Hashem Abdul | 01-31-2024
     * @param orderLineItemId
     * @return List<Order_Item_Detail__c>
     **/
    public static List<Order_Item_Detail__c> getScheduledPickUpTktDtlsByOrderLineItemId(String orderLineItemId){
       
        List<Order_Item_Detail__c> scheduledPickUpTktDtlsList = new List<Order_Item_Detail__c>();
        List<Order_Item_Detail__c> pickupTicketOIDRecords = 
            [SELECT
                Id,
                Created_Qty__c,
                Line_Item__c,
                Line_Item__r.OrderId,
                Line_Item__r.SBQQ__Asset__r.Status,
                Line_Item__r.Status__c,
                Order_Item_Comments__c,
                Order_Type__c,
                Pickup_Requested_Date__c,
                Pickup_Ticket__c,
                Pickup_Ticket_Request_By__c,
                Pickup_Ticket_Requested_By__r.Name,
                Quantity__c
            FROM
                Order_Item_Detail__c
            WHERE
                Line_Item__c = :orderLineItemId
                AND Pickup_Ticket__c != NULL
                AND Order_Type__c = :SBR_3_0_Constants.ORDER_DETAIL_TYPE
            WITH SECURITY_ENFORCED
            ORDER BY
                CreatedDate DESC];

        if(!pickupTicketOIDRecords.isEmpty()) {
            scheduledPickUpTktDtlsList.addAll(pickupTicketOIDRecords);
        }
        return scheduledPickUpTktDtlsList;
    }

    /**
     * @description          - Get Contract Order By Contract Number and Company Code
     * @param contractNumber - String - required field for query filter
     * @param companyCode    - String - required field for query filter
     * @return               `List<Order>` - List of Order that matches the given contract number and company code.
     */
    public static List<Order> getContractOrderByContractNum(String contractNumber, String companyCode){
        return [SELECT
            Id,
            AccountId,
            Account.RM_Account_Number__c,
            Account.RM_Account_Number_Display__c,
            Account.ShippingCity,
            Account.ShippingCountry,
            Account.ShippingLatitude,
            Account.ShippingLongitude,
            Account.ShippingPostalCode,
            Account.ShippingState,
            Account.ShippingStreet,
            Branch__c,
            Branch__r.Branch_Location_Number__c,
            Jobsite__c,
            Jobsite__r.Job_Site_Id__c,
            Lock_Initial_Totals__c,
            Rentalman_System_Date_Time__c,
            Sales_Rep__c,
            Sales_Rep__r.RepID__c,
            Secondary_Rep__c,
            Secondary_Rep__r.RepID__c,
            Status,
            Time_Zone_Offset__c
        FROM
            Order
        WHERE
            Contract_Order_Number__c = :contractNumber
            AND Company_Code__c = :companyCode
        WITH SECURITY_ENFORCED
        LIMIT 1
        FOR UPDATE];
    }

    // SAL-23458  - Removed recordType argument from this method
    /**
     * @description             - Get Reservation Order By Reservation Number and companyCode
     * @param reservationNumber - String -  required field for query filter
     * @param companyCode       - String - required field for query filter   
     * @return  - `List<Order>` - List of Order that matches the given reservation number and company code.
     */
    public static List<Order> getReservationOrderByResNum(String reservationNumber, String companyCode){
        return [SELECT
            Id,
            AccountId,
            Account.RM_Account_Number__c,
            Account.RM_Account_Number_Display__c,
            Account.ShippingCity,
            Account.ShippingCountry,
            Account.ShippingLatitude,
            Account.ShippingLongitude,
            Account.ShippingPostalCode,
            Account.ShippingState,
            Account.ShippingStreet,
            Branch__c,
            Branch__r.Branch_Location_Number__c,
            Contract_Order_Number__c,
            Jobsite__c,
            Jobsite__r.Job_Site_Id__c,
            Jobsite__r.Time_Zone_Id__c,
            Lock_Initial_Totals__c,
            Rentalman_System_Date_Time__c,
            Reservation_Order_Number__c,
            Status,
            Sales_Rep__c,
            Sales_Rep__r.RepID__c,
            Secondary_Rep__c,
            Secondary_Rep__r.RepID__c,
            Time_Zone_Offset__c
        FROM
            Order
        WHERE
            Reservation_Order_Number__c = :reservationNumber
            AND Company_Code__c = :companyCode
            AND (RecordTypeId = :SBR_3_0_Constants.ORDER_REC_TYPE_RESERVATION_ORDER_ID
            OR RecordTypeId = :SBR_3_0_Constants.ORDER_REC_TYPE_RESLOCKED_ORDER_ID)
        WITH SECURITY_ENFORCED
        LIMIT 1
        FOR UPDATE];
    }

    /**
     * @description    - Retrieve a list of `Order` matching the given set of Ids.
     * @param recordId - Record Id of type `Order`.
     * @return         `List<Order>` - a list of `Order` record.
     */
    public static List<Order> getOrderDtlsForTotalTaxUpdate(String recordId){
        return [SELECT
            Id,
            Aggregated_Status_Invoiced_Qty__c,
            Company_Code__c,
            Contract_Order_Number__c,
            Deliverymethod__c,
            Lock_Initial_Totals__c,
            OrderNumber,
            RecordTypeId,
            Rentalman_Quote_Id__c,
            Reservation_Order_Number__c,
            RM_Account_Number__c,
            RPP_Amount__c,
            Status,
            Sub_Type__c,
            Total_Delivery_Pickup__c,
            Total_Misc__c,
            Total_Ordered_Amount__c,
            Total_Rental_Amount__c,
            Total_Sales_Amount__c,
            Total_Sales_Taxes__c,
            (Select
                Id,
                Global_Line_Number__c,
                Line_Composite_Key__c,
                Misc_Charges_Item_Tax_Rate__c,
                Misc_Charges_Tax__c,
                Product2Id,
                Rental_Tax__c,
                Sales_Tax__c,
                SBQQ__TaxAmount__c,
                Total_Price__c
             From
                OrderItems)
         From
            Order
         Where
            Id =:recordId
         WITH SECURITY_ENFORCED
         LIMIT 1
         FOR UPDATE];
    }

    /**
     * @description - Retrieve a list of active Order Status picklist values.
     * @return      `List<String>` - List of Order Status picklist values.
     */
    @AuraEnabled(Cacheable = true)
    public static List<String> getOrderSubTypeOptions() {
        List<String> activeOptions = new List<String>();
        List<PicklistEntry> picklistOptions = Order.Sub_Type__c.getDescribe().getPicklistValues();
        for (PicklistEntry option : picklistOptions) {
            if (option.isActive()) {
                activeOptions.add(option.getValue());
            }
        }
        return activeOptions;
    }

    /**
     * @description //FRONT-7422,7423 START
     * @param  orderIds Ids of orders to query
     * @return A map of order ids to orders
     */
    public static Map<Id, Order> getOrdersWithItems(Set<Id> orderIds) {
        return new Map<Id, Order>([SELECT
            Id,
            Branch__r.Branch_Location_Number__c,
            Company_Code__c,
            Deliverymethod__c,
            Earliest_Delivery_Date__c,
            (SELECT
                Id,
                Order_Item_Unit_of_Measure__c,
                Product2.Product_SKU__c
             FROM
                OrderItems
             WHERE
                Product2.Product_Type__c = 'Cat-Class'
            )
         FROM
            Order
         WHERE
            Id = :orderIds
            AND RecordTypeId = :SBR_3_0_Constants.ORDER_REC_TYPE_RESERVATION_ORDER_ID]);
    }
    //FRONT-7422,7423 END
}