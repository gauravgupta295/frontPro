function formatNumber(num, isDollar) {
    const formattingOptions = {
     style: "decimal",  // or "currency" for currency formatting
     currency: "USD",   // If using currency formatting
     maximumFractionDigits: 2,
     minimumFractionDigits: 2,
   };
   let result = new Intl.NumberFormat("en-US", formattingOptions).format(Number(num));
   return isDollar ? ('$' + result) : result;
}

export const quoteFields = [
    'SBQQ__Quote__c.OwnerId',
    'SBQQ__Quote__c.RPP_Amount__c',
    'SBQQ__Quote__c.Total_Misc__c',
    'SBQQ__Quote__c.Total_Quoted_Amount__c',
    'SBQQ__Quote__c.Total_Rental_Amount__c',
    'SBQQ__Quote__c.Total_Sales_Amount__c',
    'SBQQ__Quote__c.Total_Sales_Taxes__c',
    'SBQQ__Quote__c.Id',
    'SBQQ__Quote__c.Rentalman_Quote_Id__c',
    'SBQQ__Quote__c.Submitted_to_Wynne__c',
    'SBQQ__Quote__c.SBQQ_Status_Reason__c'
];

export const orderFields = [
    'Order.OwnerId',
    'Order.RPP_Amount__c',
    'Order.Total_Misc__c',
    'Order.Total_Rental_Amount__c',
    'Order.Total_Sales_Amount__c',
    'Order.Total_Sales_Taxes__c',
    'Order.Id',
    'Order.Order_Discount__c',
    'Order.Reservation_Order_Number__c',
    'Order.Contract_Order_Number__c',
    'Order.Submitted_to_Wynne__c'
];

export const userFields = [
    'User.Id',
    'User.Name',
    'User.Profile.Name',
    'User.CompanyName'
];

export const cartFields = [
    'Cart__c.OwnerId',
    'Cart__c.Total__c',
    'Cart__c.Sub_Total__c',
    'Cart__c.Tax__c',
    'Cart__c.Total_Delivery_Pickup__c'
];

export const rentalColumnNames = [
    'Sale_Price',
    'Min_Rate',
    'Contingency_Cost',
    'Seasonal_Multiplier'
];

export const salesColumnNames = [
    'Daily_Rate',
    'Weekly_Rate',
    'Cat_Class',
    'Monthly_Rate',
    'Min_Rate',
    'Contingency_Cost',
    'Seasonal_Multiplier'
];

export const deliveryColumnNames = [
    'Daily_Rate',
    'Weekly_Rate',
    'Cat_Class',
    'Monthly_Rate',
    'Quantity',
    'Sale_Price',
    'Min_Rate',
    'Contingency_Cost',
    'Seasonal_Multiplier',
    'Notes'
];

export const ancillaryColumnNames = [
    'Daily_Rate',
    'Weekly_Rate',
    'Cat_Class',
    'Monthly_Rate',
    'Notes',
    'Min_Rate',
    'Contingency_Cost',
    'Seasonal_Multiplier'
];

export const cartItemFields = [
    'Cart_Items__c.Id',
    'Cart_Items__c.Name',
    'Cart_Items__c.Cat_Class__c',
    'Cart_Items__c.Quantity__c',
    'Cart_Items__c.Minimum_Price__c',
    'Cart_Items__c.Daily_Price__c',
    'Cart_Items__c.Weekly_Price__c',
    'Cart_Items__c.Monthly_Price__c',
    'Cart_Items__c.Misc_Sales_Price__c',
    'Cart_Items__c.Item_Subtotal__c',
    'Cart_Items__c.Product__c',
    'Cart_Items__c.Product__r.Is_Kit__c',
    'Cart_Items__c.Product__r.Changeable__c',
    'Cart_Items__c.Product__r.Category__c',
    'Cart_Items__c.Product__r.Class__c',
    'Cart_Items__c.Product__r.Product_Type__c',
    'Cart_Items__c.Product__r.Type_of_Misc_Charge_Item__c',
    'Cart_Items__c.Product__r.Item_Number__c',
    'Cart_Items__c.Product__r.Stock_class__c',
    'Cart_Items__c.Product__r.Salesforce_Managed_Kit__c', // SAL-27182
    'Cart_Items__c.is_User_Added__c',
    'Cart_Items__c.Product__r.User_Selectable_for_Quote__c',
    'Cart_Items__c.Line_Item_Type__c',
    'Cart_Items__c.Kit_Number_This_Item_Belongs_To__c',//SF-5291,SF-5292
    'Cart_Items__c.Fuel_Plan__c',//SF-5291,SF-5292
    'Cart_Items__c.Line_Comments__c',//SF-5997
    'Cart_Items__c.is_Forced_Item__c',//SF-5303
    'Cart_Items__c.Rates_Branch__c',
    'Cart_Items__c.Product__r.Miscellaneous_Charge_Item__c'
];

export const quoteLineFields = [
    'SBQQ__QuoteLine__c.Id',
    'SBQQ__QuoteLine__c.SBQQ__ProductName__c',
    'SBQQ__QuoteLine__c.Product_SKU__c',
    'SBQQ__QuoteLine__c.SBQQ__Quantity__c',
    'SBQQ__QuoteLine__c.Min_Rate__c',
    'SBQQ__QuoteLine__c.Daily_Rate2__c',
    'SBQQ__QuoteLine__c.Weekly_Rate2__c',
    'SBQQ__QuoteLine__c.Monthly_Rate2__c',
    'SBQQ__QuoteLine__c.Selling_Price__c',
    'SBQQ__QuoteLine__c.SBQQ__UnitCost__c',
    'SBQQ__QuoteLine__c.Total_Price__c',
    'SBQQ__QuoteLine__c.Specific_Pricing_Type__c',
    'SBQQ__QuoteLine__c.Suggested_Daily_Rate__c',
    'SBQQ__QuoteLine__c.Suggested_Weekly_Rate__c',
    'SBQQ__QuoteLine__c.Suggested_Monthly_Rate__c',
    'SBQQ__QuoteLine__c.SBQQ__Product__c',
    'SBQQ__QuoteLine__c.Line_Comments__c',
    'SBQQ__QuoteLine__c.SBQQ__Product__r.Is_Kit__c',
    'SBQQ__QuoteLine__c.SBQQ__Product__r.Changeable__c',
    'SBQQ__QuoteLine__c.SBQQ__Product__r.Product_Type__c',
    'SBQQ__QuoteLine__c.SBQQ__Product__r.Category__c',
    'SBQQ__QuoteLine__c.SBQQ__Product__r.Class__c',
    'SBQQ__QuoteLine__c.SBQQ__Product__r.Type_of_Misc_Charge_Item__c',
    'SBQQ__QuoteLine__c.Misc_Charges_Type__c',
    'SBQQ__QuoteLine__c.SBQQ__Product__r.User_Select__c',
    'SBQQ__QuoteLine__c.SBQQ__Product__r.Stock_class__c',
    'SBQQ__QuoteLine__c.SBQQ__Product__r.Salesforce_Managed_Kit__c', // SAL-27182
    'SBQQ__QuoteLine__c.Line_Item_Type__c',
    'SBQQ__QuoteLine__c.is_User_Added__c',
    'SBQQ__QuoteLine__c.Added_by_Crew_Expense__c',
    'SBQQ__QuoteLine__c.SBQQ__Product__r.User_Selectable_for_Quote__c',
    'SBQQ__QuoteLine__c.Kit_Number_this_Item_Belongs_to__c',//SF-5291,SF-5292
    'SBQQ__QuoteLine__c.Fuel_Plan__c',//SF-5291,SF-5292
    'SBQQ__QuoteLine__c.is_Forced_Item__c',//SF-5303
    'SBQQ__QuoteLine__c.Rates_Branch__c',
    'SBQQ__QuoteLine__c.SBQQ__Product__r.Miscellaneous_Charge_Item__c'
];

export const orderItemFields = [
    'OrderItem.Id',
    'OrderItem.Product2.Name',
    'OrderItem.Product2.Product_SKU__c',
    'OrderItem.Product_SKU__c',
    'OrderItem.Quantity',
    'OrderItem.Min_Rate__c',
    'OrderItem.Daily_Rate2__c',
    'OrderItem.Weekly_Rate2__c',
    'OrderItem.Monthly_Rate2__c',
    'OrderItem.Selling_Price__c',
    'OrderItem.UnitPrice',
    'OrderItem.Total_Price__c',
    'OrderItem.groupID__c',
    'OrderItem.Cat_Class__c',
    'OrderItem.Product2Id',
    'OrderItem.Line_Comments__c',
    'OrderItem.Specific_Pricing_Type__c',
    'OrderItem.Suggested_Daily_Rate__c',
    'OrderItem.Suggested_Weekly_Rate__c',
    'OrderItem.Suggested_Monthly_Rate__c',
    'OrderItem.Product2.Product_Type__c',
    'OrderItem.Product2.Type_of_Misc_Charge_Item__c',
    'OrderItem.Misc_Charges_Type__c',
    'OrderItem.Product2.User_Select__c',
    'OrderItem.Product2.Stock_class__c',
    'OrderItem.Product2.Category__c',
    'OrderItem.Product2.Class__c',
    'OrderItem.Product2.Is_Kit__c',
    'OrderItem.Product2.Changeable__c',
    'OrderItem.Product2.Salesforce_Managed_Kit__c', // SAL-27182
    'OrderItem.is_Line_Item_Hidden__c',
    'OrderItem.Line_Item_Type__c',
    'OrderItem.is_User_Added__c',
    'OrderItem.Product2.User_Selectable_for_Quote__c',
    'OrderItem.Kit_Number_This_Item_Belongs_To__c',//SF-5291,SF-5292
    'OrderItem.Fuel_Plan__c',//SF-5291,SF-5292
    'OrderItem.is_Forced_Item__c',//SF-5303
    'OrderItem.Rates_Branch__c',
    'OrderItem.Product2.Miscellaneous_Charge_Item__c'
];

export {
    formatNumber
}