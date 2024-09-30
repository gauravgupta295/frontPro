/*********************************************************************************************************************
* Apex Class: SBR_3_0_API_Estimates
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* @description       : Fetch Estimates using Mulesoft
* @last modified on  : 07-11-2023
* @last modified by  : Amanjot Kaur
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
1.0         Hashem Abdul          2022-05-11            Initial version  
2.0         Amanjot kaur          07-11-2023            added Api log methods
*********************************************************************************************************************/
public with sharing class SBR_3_0_API_Estimates {
  private static final String APINAME = 'Estimates_API';
  public static final String PIPELINE = 'pipeline';
  public static final String NON_PIPELINE = 'non_pipeline';
  
  public static String estEndDate = String.Valueof(Date.today());
  
  public static String requestLabel1;
  public static String requestLabel2;
  
  public static Schema.Location locationData; //23506
  public static SBR_3_0_API_EstimatesRequestWrapper secondEstimateRequest;
  public static String secondEstimateCompanyCode;
  public static Boolean  makeSecondEstimateCall = false;
  
  @AuraEnabled
  public static String getEstimates(String estimatesRequestJson, String companyId) {
    String returnPayload;
    try {
      returnPayload = SBR_3_0_Generic_Callout.callEndpoint(estimatesRequestJson, APINAME, companyId);
      SBR_3_0_Log.logAPIDetails(estimatesRequestJson, returnPayload,APINAME);
      SBR_3_0_Log.logInfo('\n Estimates Response = ' + returnPayload  );
    } catch (CalloutException mException) {
      insert new Exception_Log__c(Name = mException.getTypeName(), Exception_Message__c = mException.getMessage());
    }
    finally{
      SBR_3_0_Log.saveLog();
    }
    return returnPayload;
  }
  
  public static SBR_3_0_API_EstimatesResponseWrapper getEstimate(Id recordId) {
    
    SBR_3_0_API_EstimatesResponseWrapper result = new SBR_3_0_API_EstimatesResponseWrapper();
    try {
      SBR_3_0_Log.setRelatedRecordId(recordId);
      SBR_3_0_API_EstimatesRequestWrapper requestWrapper = buildRequest(recordId);
      String body = JSON.serialize(requestWrapper, true);
      body = body.replace('override_x', 'override');
      body = body.replace('null', '\"\"');
      
      secondEstimateRequest = requestWrapper;
      secondEstimateCompanyCode = requestWrapper.companyCode;
      String resp = getEstimates(body, requestWrapper.companyCode);
      SBR_3_0_Log.logAPIDetails(body, resp,APINAME);
      
      result = (SBR_3_0_API_EstimatesResponseWrapper) JSON.deserialize(resp, SBR_3_0_API_EstimatesResponseWrapper.class);
     
    } catch (Exception ex) {
      SBR_3_0_Log.logException(ex);
      throw new SBR_3_0_API_Estimates_Exception(ex.getMessage());
    }finally{
      SBR_3_0_Log.saveLog();
    }
    
    return result;
  }
  
  public static SBR_3_0_API_EstimatesRequestWrapper buildRequest(Id recordId) {
    String objectApi = recordId.getSObjectType().getDescribe().getName();
    String objectLabel = recordId.getSObjectType().getDescribe().getLabel();
    
    SBR_3_0_API_EstimatesRequestWrapper reqWrapper = new SBR_3_0_API_EstimatesRequestWrapper();
    
    if (objectApi == 'SBQQ__Quote__c') {
      SBQQ__Quote__c quote = SBR_3_0_QuoteDA.getQuotes(new Set<Id>{ recordId }).get(recordId);
      reqWrapper = buildQuoteRequest(quote);
    } else if (objectApi == 'Order') {
      Order order = SBR_3_0_OrderDA.getOrders(new Set<Id>{ recordId }).get(recordId);
      reqWrapper = buildOrderRequest(order);
    }
    
    return reqWrapper;
  }
  
  public static SBR_3_0_API_EstimatesRequestWrapper buildOrderRequest(Order order) {
    SBR_3_0_API_EstimatesRequestWrapper reqWrapper = new SBR_3_0_API_EstimatesRequestWrapper();
    
    /*
    SAL-22191
    (1) If the Account has an RM Account# (i.e. Credit or Non-Credit), use RM Account#
    (2) If the Account does not have an RM Account # then
    (3) If the Parent account in the hierarchy has the RM Account# then use that RM#
    (4) Else if it has Driver’s license information, use that
    (5) Else use 0 (zero) as the RM Account# in the request
    */
    String accountNumber = SBR_3_0_AccountDA.getAccountRMNumber(order.AccountId, true);
    //Modified for FRONT-19294
    if (accountNumber != null) {
      if (accountNumber.contains('-')) {
        accountNumber = accountNumber.subStringAfter('-');
        if (order.Account.Record_Type_Text__c == 'Non-Credit') {
          reqWrapper.account = 0;
        } else if (order.Account.Record_Type_Text__c != 'Non-Credit') {
        reqWrapper.account = Integer.valueOf(accountNumber);
        }
      }
    } else if (order.Driver_License_State__c != null && order.Driver_License_Number__c != null) {
      reqWrapper.driverLicenseState = order.Driver_License_State__c;
      reqWrapper.driverLicenseNumber = order.Driver_License_Number__c;
    } else {
      reqWrapper.account = 0;
    }
    
    // General mappings
    if (order.Company_Code__c == null) {
      throw new SBR_3_0_API_Estimates_Exception('Company Code is required');
    }
    reqWrapper.companyCode = order.Company_Code__c.replace('0', '');
    if (order.Deliverymethod__c == null) {
      throw new SBR_3_0_API_Estimates_Exception('Delivery Method is required');
    }
    reqWrapper.orderType = order.Deliverymethod__c;
    reqWrapper.jobNumber = order.Branch__r.Branch_Location_Number__c;
    //Modified for FRONT-19294
    if (reqWrapper.account == 0) {
      reqWrapper.driverLicenseState = order.Driver_License_State__c;
      reqWrapper.driverLicenseNumber = order.Driver_License_Number__c;
    }
    if (order.Start_Date__c < System.now()) {
      throw new SBR_3_0_API_Estimates_Exception('Start Date cannot be in the past');
    }
    if (order.Start_Date__c == null) {
      throw new SBR_3_0_API_Estimates_Exception('Start Date is required');
    }
    reqWrapper.startDateAndTime = order.Start_Date__c.format('yyyy-MM-dd') + 'T' + order.Start_Date__c.format('HH:mm:ss.SSSXXX');
    if (order.Estimated_Return_Date__c == null) {
      throw new SBR_3_0_API_Estimates_Exception('End Date is required');
    }
    //reqWrapper.endDateAndTime = order.Estimated_Return_Date__c.format('yyyy-MM-dd') + 'T' + order.Estimated_Return_Date__c.format('HH:mm:ss.SSSXXX');
    if (order.Return_Date__c != null) {
      reqWrapper.endDateAndTime = order.Return_Date__c.format('yyyy-MM-dd') + 'T' + order.Return_Date__c.format('HH:mm:ss.SSSXXX');
    }
    if (order.Estimated_Return_Date__c != null) {
      estEndDate = order.Estimated_Return_Date__c.format('yyyy-MM-dd') + 'T' + order.Estimated_Return_Date__c.format('HH:mm:ss.SSSXXX'); 
    }
    //reqWrapper.distance = 90;
    reqWrapper.ratesToBeUsed = 'SUGGESTED';
    
    // Build PC
    reqWrapper.pc = new List<SBR_3_0_API_EstimatesRequestWrapper.PC>();
    SBR_3_0_API_EstimatesRequestWrapper.PC pce = new SBR_3_0_API_EstimatesRequestWrapper.PC();
    
    //23575
    if (locationData != null) {
      //23506
      pce.id = Integer.valueof(locationData.Branch_Location_Number__c);
      pce.latitude = locationData.Latitude_Longitude__Latitude__s;
      pce.longitude = locationData.Latitude_Longitude__Longitude__s;
      if (locationData?.Time_Zone_Id__c != null) {
        pce.timezone = locationData?.Time_Zone_Id__c;
      } else {
        User loggedInUser = SBR_3_0_UserDA.getUserById(UserInfo.getUserId());
        String userTimeZone = loggedInUser?.TimeZoneSidKey;
        pce.timezone = userTimeZone;
      }
    } 
     else if (order.Sourcing_Branch__c != null && order.Sourcing_Branch__r.Latitude_Longitude__Longitude__s != null && order.Sourcing_Branch__r.Latitude_Longitude__Latitude__s != null) {
      pce.id = Integer.valueof(order.Sourcing_Branch__r.Branch_Location_Number__c);
      pce.latitude = order.Sourcing_Branch__r.Latitude_Longitude__Latitude__s;
      pce.longitude = order.Sourcing_Branch__r.Latitude_Longitude__Longitude__s;
      
      if (order.Sourcing_Branch__r?.Time_Zone_Id__c != null) {
        pce.timezone = order.Sourcing_Branch__r?.Time_Zone_Id__c;
      } else {
        User loggedInUser = SBR_3_0_UserDA.getUserById(UserInfo.getUserId());
        String userTimeZone = loggedInUser?.TimeZoneSidKey;
        pce.timezone = userTimeZone;
      }
    } else {
      if (order.Branch__r.Branch_Location_Number__c == null) {
        throw new SBR_3_0_API_Estimates_Exception('Branch Location Number is required');
      }
      pce.id = Integer.valueof(order.Branch__r.Branch_Location_Number__c);
      if (order.Branch__r.Latitude_Longitude__Latitude__s == null) {
        throw new SBR_3_0_API_Estimates_Exception('Branch Latitude is required');
      }
      pce.latitude = order.Branch__r.Latitude_Longitude__Latitude__s;
      if (order.Branch__r.Latitude_Longitude__Longitude__s == null) {
        throw new SBR_3_0_API_Estimates_Exception('Branch Longitude is required');
      }
      pce.longitude = order.Branch__r.Latitude_Longitude__Longitude__s;
      
      if (order.Branch__r?.Time_Zone_Id__c != null) {
        pce.timezone = order.Branch__r?.Time_Zone_Id__c;
      } else {
        User loggedInUser = SBR_3_0_UserDA.getUserById(UserInfo.getUserId());
        String userTimeZone = loggedInUser?.TimeZoneSidKey;
        pce.timezone = userTimeZone;
      }
    }
    
    reqWrapper.pc.add(pce);
    
    // Build Address
    reqWrapper.address = new List<SBR_3_0_API_EstimatesRequestWrapper.Address>();
    SBR_3_0_API_EstimatesRequestWrapper.Address addr = new SBR_3_0_API_EstimatesRequestWrapper.Address();
    addr.type = 'jobsite';
    addr.line1 = order.Jobsite__r.Street_Address__c;
    addr.city = order.Jobsite__r.City__c;
    addr.state = order.Jobsite__r.State__c;
    addr.zip = order.Jobsite__r.Zip_Code__c;
    addr.latitude = order.Jobsite__r.Latitude_Longitude__Latitude__s;
    addr.longitude = order.Jobsite__r.Latitude_Longitude__Longitude__s;
    reqWrapper.address.add(addr);
    
    // Build Deliver
    reqWrapper.delivery = new List<SBR_3_0_API_EstimatesRequestWrapper.Delivery>();
    SBR_3_0_API_EstimatesRequestWrapper.Delivery d = new SBR_3_0_API_EstimatesRequestWrapper.Delivery();
    d.chargesOverride = order.Delivery_Charges_Override__c;
    if (order.Delivery_Charges_Override__c == true && order.Delivery_Charges__c == null) {
      throw new SBR_3_0_API_Estimates_Exception('Delivery Charge is required');
    }
    if (order.Delivery_Charges_Override__c == false && order.Delivery_Charge__c != null ) {
        if(order.Number_of_Trucks__c != null && order.Number_of_Trucks__c >1 && order.Total_Suggested_Delivery__c!=null && order.Delivery_Charge__c != order.Total_Suggested_Delivery__c){
               d.charges = order.Total_Suggested_Delivery__c.toPlainString();
               d.chargesOverride = true;
        }
        else{
               d.charges = order.Delivery_Charge__c.toPlainString();

        }
    }
    if(order.Delivery_Charges_Override__c == true && order.Delivery_Charges__c != null)
    {
      d.charges = order.Delivery_Charges__c.toPlainString();
    }
    reqWrapper.delivery.add(d);
    
    // Build Pickup
    reqWrapper.pickup = new List<SBR_3_0_API_EstimatesRequestWrapper.Pickup>();
    SBR_3_0_API_EstimatesRequestWrapper.Pickup p = new SBR_3_0_API_EstimatesRequestWrapper.Pickup();
    p.chargesOverride = order.Pickup_Charges_Override__c;
    if (order.Pickup_Charges_Override__c == true && order.Pickup_Charges__c == null) {
      throw new SBR_3_0_API_Estimates_Exception('Pickup Charge is required');
    }
    if (order.Pickup_Charges_Override__c == false && order.Pickup_Charge__c != null) {
          if(order.Number_of_Trucks__c != null && order.Number_of_Trucks__c >1 && order.Total_Suggested_Pickup__c!=null && order.Pickup_Charge__c != order.Total_Suggested_Pickup__c){
            p.charges = order.Total_Suggested_Pickup__c.toPlainString();
            p.chargesOverride = true;
          }
          else{
                 p.charges = order.Pickup_Charge__c.toPlainString();

          }
    }
    if (order.Pickup_Charges_Override__c == true && order.Pickup_Charges__c != null)
    {
      p.charges = order.Pickup_Charges__c.toPlainString();
    }
    reqWrapper.pickup.add(p);
    if(order.Pickup_Charges_Override__c == false && order.Pickup_Charge__c == null
     && order.Delivery_Charges_Override__c == false && order.Delivery_Charge__c == null)
    {
      makeSecondEstimateCall = true;
    }
    // Build Order Lines
    reqWrapper.orderLines = new List<SBR_3_0_API_EstimatesRequestWrapper.OrderLine>();
    SBR_3_0_API_EstimatesRequestWrapper.OrderLine orderLine = new SBR_3_0_API_EstimatesRequestWrapper.OrderLine();
    orderLine.salesItems = new List<SBR_3_0_API_EstimatesRequestWrapper.SalesItem>();
    orderLine.products = new List<SBR_3_0_API_EstimatesRequestWrapper.Product>();
    
    
    for (OrderItem lineItem : order.OrderItems) {
      if (lineItem.Product2.Product_Type__c == SBR_3_0_Constants.CAT_CLASS) {
        SBR_3_0_API_EstimatesRequestWrapper.Product prod = new SBR_3_0_API_EstimatesRequestWrapper.Product();
        
        if (lineItem.Product2.Product_SKU__c == null) {
          throw new SBR_3_0_API_Estimates_Exception('Line Item Product SKU is required');
        }
        //prod.catId = String.valueOf(lineItem.Product2.Product_SKU__c).substring(0,2); // first 3
        prod.catId = String.valueOf(lineItem.Product2.Category__c);
        
        // String classId = String.valueOf(lineItem.Product2.Product_SKU__c);
        // prod.classId = classId.substring(classId.length() - 5, classId.length() - 1);  // last 4
        prod.classId = String.valueOf(lineItem.Product2.Class__c);
        
        if (lineItem.Quantity == null) {
          throw new SBR_3_0_API_Estimates_Exception('Line Item Quantity is required');
        }
        prod.quantity = lineItem.Quantity.intValue();
        SBR_3_0_API_EstimatesRequestWrapper.Rate rate = new SBR_3_0_API_EstimatesRequestWrapper.Rate();
        rate.override_x = true; //SAL-26681
        //change for SAL-19006
        if ((lineItem.Product2.Product_Type__c == SBR_3_0_Constants.CAT_CLASS && lineItem.Selling_Price__c == null && lineItem.Rates_Overriden__c == true) && (lineItem.Hourly_Rate__c == null || lineItem.Min_Rate__c == null || lineItem.Daily_Rate2__c == null || lineItem.Weekly_Rate2__c == null || lineItem.Monthly_Rate2__c == null)) {
          throw new SBR_3_0_API_Estimates_Exception('All Line Item Rates are required');
        }
        rate.hourly = String.valueOf(lineItem.Hourly_Rate__c);
        rate.minimum = String.valueOf(lineItem.Min_Rate__c);
        rate.daily = String.valueOf(lineItem.Daily_Rate2__c);
        rate.weekly = String.valueOf(lineItem.Weekly_Rate2__c);
        rate.monthly = String.valueOf(lineItem.Monthly_Rate2__c);
        
        prod.rates = rate;
        orderLine.products.add(prod);
      } else if(
      ((lineItem.Product2.Product_Type__c == SBR_3_0_Constants.PARTS || lineItem.Product2.Product_Type__c == SBR_3_0_Constants.MERCHANDISE || (lineItem.Product2.Product_Type__c ==  SBR_3_0_Constants.MISC_CHARGE_ITEMS_TYPE && lineItem.is_User_Added__c ))
      &&
      (lineItem.Product2 != null && lineItem.Product2.Item_Number__c != null && lineItem.Product2.Stock_Class__c != null && lineItem.Selling_Price__c != null && lineItem.Quantity != null )
      )
      || 
      (lineItem.is_Forced_Item__c !=null && lineItem.is_Forced_Item__c && lineItem.Product2.Stock_class__c!= null && lineItem.Product2.Stock_class__c == SBR_3_0_Constants.PRODUCT_STOCK_CLASS_MISC )//25119    
      ) 
      {
        
        SBR_3_0_API_EstimatesRequestWrapper.SalesItem si = new SBR_3_0_API_EstimatesRequestWrapper.SalesItem();
        si.itemNumber = lineItem.Product2.Item_Number__c;
        si.stockClass = lineItem.Product2.Stock_class__c;
        si.unitPrice = lineItem.Selling_Price__c;
        si.quantity = lineItem.Quantity.intValue();
        orderLine.salesItems.add(si);
      }
    }
    
    if (orderLine.products.size() == 0) {
      throw new SBR_3_0_API_Estimates_Exception('Cat Class Products are required');
    }
    
    reqWrapper.orderLines.add(orderLine);
    
    return reqWrapper;
  }
  
  public static SBR_3_0_API_EstimatesRequestWrapper buildQuoteRequest(SBQQ__Quote__c quote) {
    SBR_3_0_API_EstimatesRequestWrapper reqWrapper = new SBR_3_0_API_EstimatesRequestWrapper();
    
    /*
    SAL-22191
    (1) If the Account has an RM Account# (i.e. Credit or Non-Credit), use RM Account#
    (2) If the Account does not have an RM Account # then
    (3) If the Parent account in the hierarchy has the RM Account# then use that RM#
    (4) Else if it has Driver’s license information, use that
    (5) Else use 0 (zero) as the RM Account# in the request
    */
    String accountNumber = SBR_3_0_AccountDA.getAccountRMNumber(quote.SBQQ__Account__c, true);
    //Modified for FRONT-19294
    if (accountNumber != null) {
      if (accountNumber.contains('-')) {
        accountNumber = accountNumber.subStringAfter('-');
        if (quote.SBQQ__Account__r.Record_Type_Text__c == 'Non-Credit') {
          reqWrapper.account = 0;
        } else if (quote.SBQQ__Account__r.Record_Type_Text__c != 'Non-Credit') {
          reqWrapper.account = Integer.valueOf(accountNumber);
        }
      } else {
        reqWrapper.account = Integer.valueOf(accountNumber);
      }
    } else if (quote.Drivers_license_State__c != null && quote.Drivers_license_Number__c != null) {
      reqWrapper.driverLicenseState = quote.Drivers_license_State__c;
      reqWrapper.driverLicenseNumber = quote.Drivers_license_Number__c;
    } else {
      reqWrapper.account = 0;
    }
    
    // General mappings
    if (quote.Company_Code__c == null) {
      throw new SBR_3_0_API_Estimates_Exception('Company Code is required');
    }
    reqWrapper.companyCode = quote.Company_Code__c.replace('0', '');
    if (quote.SBQQ__DeliveryMethod__c == null) {
      throw new SBR_3_0_API_Estimates_Exception('Delivery Method is required');
    }
    reqWrapper.orderType = quote.SBQQ__DeliveryMethod__c;
    reqWrapper.jobNumber = quote.Branch__r.Branch_Location_Number__c;
    //Modified for FRONT-19294
    if (reqWrapper.account == 0) {
      reqWrapper.driverLicenseState = quote.Drivers_license_State__c;
      reqWrapper.driverLicenseNumber = quote.Drivers_license_Number__c;
    }
    if (quote.Start_Date__c == null) {
      throw new SBR_3_0_API_Estimates_Exception('Start Date is required');
    }
    if (quote.Start_Date__c < System.now()) {
      throw new SBR_3_0_API_Estimates_Exception('Start Date cannot be in the past. Please update the Start Date field to future date/time and try again.');
    }
    reqWrapper.startDateAndTime = quote.Start_Date__c.format('yyyy-MM-dd') + 'T' + quote.Start_Date__c.format('HH:mm:ss.SSSXXX');
    if (quote.End_Date__c == null) {
      throw new SBR_3_0_API_Estimates_Exception('End Date is required');
    }
    reqWrapper.endDateAndTime = quote.End_Date__c.format('yyyy-MM-dd') + 'T' + quote.End_Date__c.format('HH:mm:ss.SSSXXX');
    
    if (quote.Est_End_Date__c != null) {
      estEndDate = quote.Est_End_Date__c.format('yyyy-MM-dd') + 'T' + quote.Est_End_Date__c.format('HH:mm:ss.SSSXXX'); //22305
    }       
    reqWrapper.ratesToBeUsed = SBR_3_0_Constants.SUGGESTED_RATES;
    
    // Build PC
    reqWrapper.pc = new List<SBR_3_0_API_EstimatesRequestWrapper.PC>();
    SBR_3_0_API_EstimatesRequestWrapper.PC pce = new SBR_3_0_API_EstimatesRequestWrapper.PC();
    
    //23575        
    if (locationData != null) {
      //23506
      pce.id = Integer.valueof(locationData.Branch_Location_Number__c);
      pce.latitude = locationData.Latitude_Longitude__Latitude__s;
      pce.longitude = locationData.Latitude_Longitude__Longitude__s;
      if (locationData?.Time_Zone_Id__c != null) {
        pce.timezone = locationData?.Time_Zone_Id__c;
      } else {
        User loggedInUser = SBR_3_0_UserDA.getUserById(UserInfo.getUserId());
        String userTimeZone = loggedInUser?.TimeZoneSidKey;
        pce.timezone = userTimeZone;
      }
    } else if (quote.Sourcing_Branch__c != null && quote.Sourcing_Branch__r.Latitude_Longitude__Longitude__s != null 
    && quote.Sourcing_Branch__r.Latitude_Longitude__Latitude__s != null) 
    {
      pce.id = Integer.valueof(quote.Sourcing_Branch__r.Branch_Location_Number__c);
      pce.latitude = quote.Sourcing_Branch__r.Latitude_Longitude__Latitude__s;
      pce.longitude = quote.Sourcing_Branch__r.Latitude_Longitude__Longitude__s;
      if (quote.Sourcing_Branch__r?.Time_Zone_Id__c != null) {
        pce.timezone = quote.Sourcing_Branch__r?.Time_Zone_Id__c;
      } else {
        User loggedInUser = SBR_3_0_UserDA.getUserById(UserInfo.getUserId());
        String userTimeZone = loggedInUser?.TimeZoneSidKey;
        pce.timezone = userTimeZone;
      }
    } 
    else {
      if (quote.Branch__r.Branch_Location_Number__c == null) {
        throw new SBR_3_0_API_Estimates_Exception('Branch Location Number is required');
      }
      pce.id = Integer.valueof(quote.Branch__r.Branch_Location_Number__c);
      if (quote.Branch__r.Latitude_Longitude__Latitude__s == null) {
        throw new SBR_3_0_API_Estimates_Exception('Branch Latitude is required');
      }
      pce.latitude = quote.Branch__r.Latitude_Longitude__Latitude__s;
      if (quote.Branch__r.Latitude_Longitude__Longitude__s == null) {
        throw new SBR_3_0_API_Estimates_Exception('Branch Longitude is required');
      }
      pce.longitude = quote.Branch__r.Latitude_Longitude__Longitude__s;
      
      if (quote.Branch__r?.Time_Zone_Id__c != null) {
        pce.timezone = quote.Branch__r?.Time_Zone_Id__c;
      } else {
        User loggedInUser = SBR_3_0_UserDA.getUserById(UserInfo.getUserId());
        String userTimeZone = loggedInUser?.TimeZoneSidKey;
        pce.timezone = userTimeZone;
      }
    }
    
    reqWrapper.pc.add(pce);
    
    // Build Address
    reqWrapper.address = new List<SBR_3_0_API_EstimatesRequestWrapper.Address>();
    SBR_3_0_API_EstimatesRequestWrapper.Address addr = new SBR_3_0_API_EstimatesRequestWrapper.Address();
    if (String.isBlank(quote.Address_type__c)) {
      addr.type = 'jobsite';
    } else {
      addr.type = quote.Address_type__c;
    }
    addr.line1 = quote.Jobsite__r.Street_Address__c;
    addr.city = quote.Jobsite__r.City__c;
    addr.state = quote.Jobsite__r.State__c;
    addr.zip = quote.Jobsite__r.Zip_Code__c;
    addr.latitude = quote.Jobsite__r.Latitude_Longitude__Latitude__s;
    addr.longitude = quote.Jobsite__r.Latitude_Longitude__Longitude__s;
    reqWrapper.address.add(addr);
    
    // Build Deliver
    reqWrapper.delivery = new List<SBR_3_0_API_EstimatesRequestWrapper.Delivery>();
    SBR_3_0_API_EstimatesRequestWrapper.Delivery d = new SBR_3_0_API_EstimatesRequestWrapper.Delivery();
    d.chargesOverride = quote.Delivery_Charges_Override__c;
    if (quote.Delivery_Charges_Override__c == true && quote.Delivery_Charges__c == null) {
     
      throw new SBR_3_0_API_Estimates_Exception('Delivery Charge is required');
    }
    if (quote.Delivery_Charges_Override__c == false && quote.Delivery_Charge__c != null ) {
      if(quote.Number_of_Trucks__c != null && quote.Number_of_Trucks__c >1 && quote.Total_Suggested_Delivery__c!=null && quote.Delivery_Charge__c != quote.Total_Suggested_Delivery__c){
        d.charges = quote.Total_Suggested_Delivery__c.toPlainString();
        d.chargesOverride = true;
        }
        else{
              d.charges = quote.Delivery_Charge__c.toPlainString();

        }
    }
    if(quote.Delivery_Charges_Override__c == true && quote.Delivery_Charges__c != null)
    {
      d.charges = quote.Delivery_Charges__c.toPlainString();
    }
    
    reqWrapper.delivery.add(d);
    
    // Build Pickup
    reqWrapper.pickup = new List<SBR_3_0_API_EstimatesRequestWrapper.Pickup>();
    SBR_3_0_API_EstimatesRequestWrapper.Pickup p = new SBR_3_0_API_EstimatesRequestWrapper.Pickup();
    p.chargesOverride = quote.Pickup_Charges_Override__c;
    if (quote.Pickup_Charges_Override__c == true && quote.Pickup_Charges__c == null) {
      throw new SBR_3_0_API_Estimates_Exception('Pickup Charge is required');
    }
    if (quote.Pickup_Charges_Override__c == false && quote.Pickup_Charge__c != null) {
      if(quote.Number_of_Trucks__c != null && quote.Number_of_Trucks__c >1 && quote.Total_Suggested_Pickup__c!=null && quote.Pickup_Charge__c != quote.Total_Suggested_Pickup__c){
        p.charges = quote.Total_Suggested_Pickup__c.toPlainString();
        p.chargesOverride = true;
      }
      else{
             p.charges = quote.Pickup_Charge__c.toPlainString();

      }
      
    }
    if (quote.Pickup_Charges_Override__c == true && quote.Pickup_Charges__c != null)
    {
      p.charges = quote.Pickup_Charges__c.toPlainString();
    }
    reqWrapper.pickup.add(p);
    
    // Build Order Lines
    reqWrapper.orderLines = new List<SBR_3_0_API_EstimatesRequestWrapper.OrderLine>();
    SBR_3_0_API_EstimatesRequestWrapper.OrderLine orderLine = new SBR_3_0_API_EstimatesRequestWrapper.OrderLine();
    orderLine.salesItems = new List<SBR_3_0_API_EstimatesRequestWrapper.SalesItem>();
    orderLine.products = new List<SBR_3_0_API_EstimatesRequestWrapper.Product>();
    
    for (SBQQ__QuoteLine__c lineItem : quote.SBQQ__LineItems__r) {
      
      if (lineItem.SBQQ__Product__r.Product_Type__c == SBR_3_0_Constants.CAT_CLASS) {
        SBR_3_0_API_EstimatesRequestWrapper.Product prod = new SBR_3_0_API_EstimatesRequestWrapper.Product();
        
        if (lineItem.Product_SKU__c == null) {
          throw new SBR_3_0_API_Estimates_Exception('Line Item Product SKU is required');
        }
        //prod.catId = String.valueOf(lineItem.Product_SKU__c).substring(0,2); // first 3
        prod.catId = String.valueOf(lineItem.SBQQ__Product__r.Category__c);
        
        // String classId = String.valueOf(lineItem.Product_SKU__c);
        // prod.classId = classId.substring(classId.length() - 5, classId.length() - 1);  // last 4
        prod.classId = String.valueOf(lineItem.SBQQ__Product__r.Class__c);
        
        if (lineItem.SBQQ__Quantity__c == null) {
          throw new SBR_3_0_API_Estimates_Exception('Line Item Quantity is required');
        }
        prod.quantity = lineItem.SBQQ__Quantity__c.intValue();
        SBR_3_0_API_EstimatesRequestWrapper.Rate rate = new SBR_3_0_API_EstimatesRequestWrapper.Rate();
        rate.override_x = true;//SAL-26681
        //change for SAL-19006
        
        if ((lineItem.SBQQ__Product__r.Product_Type__c == SBR_3_0_Constants.CAT_CLASS && lineItem.Selling_Price__c == null && lineItem.Rates_Overriden__c == true) && (lineItem.Hourly_Rate__c == null || lineItem.Min_Rate__c == null || lineItem.Daily_Rate2__c == null || lineItem.Weekly_Rate2__c == null || lineItem.Monthly_Rate2__c == null)) {
          throw new SBR_3_0_API_Estimates_Exception('All Line Item Rates are required');
        }
        rate.hourly = String.valueOf(lineItem.Hourly_Rate__c);
        rate.minimum = String.valueOf(lineItem.Min_Rate__c);
        rate.daily = String.valueOf(lineItem.Daily_Rate2__c);
        rate.weekly = String.valueOf(lineItem.Weekly_Rate2__c);
        rate.monthly = String.valueOf(lineItem.Monthly_Rate2__c);
        
        prod.rates = rate;
        orderLine.products.add(prod);
        
      } else if( 
      ((lineItem.SBQQ__Product__r.Product_Type__c == SBR_3_0_Constants.PARTS || lineItem.SBQQ__Product__r.Product_Type__c == SBR_3_0_Constants.MERCHANDISE || (lineItem.SBQQ__Product__r.Product_Type__c ==  SBR_3_0_Constants.MISC_CHARGE_ITEMS_TYPE && lineItem.is_User_Added__c ))
      &&
      (lineItem.SBQQ__Product__c != null && lineItem.SBQQ__Product__r.Item_Number__c != null && lineItem.SBQQ__Product__r.Stock_Class__c != null && lineItem.Selling_Price__c != null && lineItem.SBQQ__Quantity__c != null)
      )
      || (lineItem.is_Forced_Item__c !=null && lineItem.is_Forced_Item__c && lineItem.SBQQ__Product__r.Stock_class__c!= null && lineItem.SBQQ__Product__r.Stock_class__c == SBR_3_0_Constants.PRODUCT_STOCK_CLASS_MISC )//25119
	  || lineItem.Added_by_Crew_Expense__c // SAL-27341
      ) 
      {
        system.debug('prod 353');
        SBR_3_0_API_EstimatesRequestWrapper.SalesItem si = new SBR_3_0_API_EstimatesRequestWrapper.SalesItem();
        si.itemNumber = lineItem.SBQQ__Product__r.Item_Number__c;
        si.stockClass = lineItem.SBQQ__Product__r.Stock_class__c;
        si.unitPrice = lineItem.Selling_Price__c;
        si.quantity = lineItem.SBQQ__Quantity__c.intValue();
        orderLine.salesItems.add(si);
      }
    }
    
    if (orderLine.products.size() == 0) {
      throw new SBR_3_0_API_Estimates_Exception('Cat Class Products are required');
    }
    
    reqWrapper.orderLines.add(orderLine);
    
    return reqWrapper;
  }
  //SAL-22305, SADAPUR
  public static Map<String, SBR_3_0_API_EstimatesResponseWrapper> getPipeLineDatedEstimates(Id recordId) {
    Map<String, SBR_3_0_API_EstimatesResponseWrapper> estimatesRespWrapperMap = new Map<String, SBR_3_0_API_EstimatesResponseWrapper>();
    SBR_3_0_API_EstimatesResponseWrapper result = new SBR_3_0_API_EstimatesResponseWrapper();
    
    String objectApi = recordId.getSObjectType().getDescribe().getName();
    String body = '';
    SBR_3_0_API_EstimatesRequestWrapper requestWrapper = new SBR_3_0_API_EstimatesRequestWrapper();
    try {
      if (objectApi == 'SBQQ__Quote__c') {
        SBQQ__Quote__c quote = SBR_3_0_QuoteDA.getQuotes(new Set<Id>{ recordId }).get(recordId);
        requestWrapper = SBR_3_0_API_Estimates.buildQuoteRequest(quote);
      } else if (objectApi == 'Order') {
        Order order = SBR_3_0_OrderDA.getOrders(new Set<Id>{ recordId }).get(recordId);
        requestWrapper = SBR_3_0_API_Estimates.buildOrderRequest(order);
      }
      
      body = JSON.serialize(requestWrapper, true);
      body = body.replace('override_x', 'override');
      body = body.replace('null', '\"\"');
     
      secondEstimateRequest = requestWrapper;
      secondEstimateCompanyCode = requestWrapper.companyCode;
      String resp = getEstimates(body, requestWrapper.companyCode);
      
      result = (SBR_3_0_API_EstimatesResponseWrapper) JSON.deserialize(resp, SBR_3_0_API_EstimatesResponseWrapper.class);
      estimatesRespWrapperMap.put(NON_PIPELINE, result);
      
      //Set Pipeline period end date(Est_End_Date__c or Estimated_Return_Date__c) as EndDate
      if (estEndDate != String.Valueof(Date.today())) {
        requestWrapper.endDateAndTime = estEndDate;
        body = JSON.serialize(requestWrapper, true);
        body = body.replace('override_x', 'override');
        body = body.replace('null', '\"\"');
        
        secondEstimateRequest = requestWrapper;
        secondEstimateCompanyCode = requestWrapper.companyCode;
        resp = getEstimates(body, requestWrapper.companyCode);
        
        result = (SBR_3_0_API_EstimatesResponseWrapper) JSON.deserialize(resp, SBR_3_0_API_EstimatesResponseWrapper.class);
        estimatesRespWrapperMap.put(PIPELINE, result);
      }
    } catch (Exception ex) {
      
      throw new SBR_3_0_API_Estimates_Exception(ex.getMessage());
    }
    
    return estimatesRespWrapperMap;
  }
  //23506
  public static Map<String, SBR_3_0_API_EstimatesResponseWrapper> getEstimatesFromSourcingBranch(Id recordId, Schema.Location sourcingBranchData) {
    locationData = sourcingBranchData;
    Map<String, SBR_3_0_API_EstimatesResponseWrapper> estimatesRespWrapperMap = new Map<String, SBR_3_0_API_EstimatesResponseWrapper>();
    estimatesRespWrapperMap = getPipeLineDatedEstimates(recordId);
    return estimatesRespWrapperMap;
  }
  
  public class SBR_3_0_API_Estimates_Exception extends Exception {
  }
}