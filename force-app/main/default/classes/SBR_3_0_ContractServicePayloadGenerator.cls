/*********************************************************************************************************************
* Apex Class: SBR_3_0_ContractServicePayloadGenerator
----------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Payload generator class for Create Contract API
----------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
1.0             Nilesh Jaiswal          2024-05-27          Initial version   
*********************************************************************************************************************/
public without sharing class SBR_3_0_ContractServicePayloadGenerator {
  static SBR_3_0_WrapContract orderWrapper;
  static Order order;
  public static String makeADepositDetails = '';

  public static String generatePayload(Order orderInstance) {
    orderWrapper = new SBR_3_0_WrapContract();
    order = orderInstance;
    generateWrapper();
    System.debug('\n @@ request =' + JSON.serializePretty(orderWrapper, true));
    return JSON.serialize(orderWrapper, true);
  }

  private static void generateWrapper() {
    orderWrapper.companyId = String.isNotBlank(order.Company_Code__c)
      ? order.Company_Code__c
      : '01';
    orderWrapper.sfOrderId = order.OrderNumber;
    orderWrapper.cartId = order.Cart_ID__c;
    orderWrapper.sellingChannel = SBR_3_0_Constants.SELLING_CHANNEL;
    orderWrapper.initiatingChannel = SBR_3_0_Constants.INITIATING_CHANNEL;
    orderWrapper.rentalmanUser = 'WROHR';
    orderWrapper.startDateTime = order.Start_Date__c != null
      ? order.Start_Date__c.formatGMT(SBR_3_0_Constants.INT_DATE_FORMAT)
      : null;
    orderWrapper.endDateTime = order.Return_Date__c != null
      ? order.Return_Date__c.formatGMT(SBR_3_0_Constants.INT_DATE_FORMAT)
      : null;
    orderWrapper.comments = order.Order_Header_Comments__c;
    orderWrapper.marketSegment = order.Market_Segment__c != null
      ? order.Market_Segment__c
      : null;
    orderWrapper.reservationNumberToBeConverted = order.Rentalman_Quote_Id__c !=
      null
      ? order.Rentalman_Quote_Id__c
      : order.Reservation_Order_Number__c;

    setCustomer();
    setPC();
    setSalesRepInfo();
    if (order.Account.Record_Type_Text__c == 'Non-Credit') {
      setPaymentDetails();
    }
    if (order.Account.Record_Type_Text__c == 'Credit') {
      setJobSite();
    }
    setDeliveryInfo();
    setReturnInfo();
    setOrderedBy();
    setBillingInfo();
    setAddressInfo();
    setAdditionalInfo();
    groupOrderLines(order.OrderItems);
  }

  private static void setAdditionalInfo() {
    SBR_3_0_WrapContract.AdditionalInfo additionalInfo = new SBR_3_0_WrapContract.AdditionalInfo();
    additionalInfo.territoryNumber = order.Jobsite__r.Territory_Number__c !=
      null
      ? Integer.valueOf(order.Jobsite__r.Territory_Number__c)
      : null;
    additionalInfo.withinCityLimits = order.Within_City_Limits__c;
    additionalInfo.sourceCode = order.Source_Code__c;
    additionalInfo.systemName = 'SF';
    orderWrapper.additionalInfo = additionalInfo;
  }

  private static void setCustomer() {
    SBR_3_0_WrapContract.Customer customer = new SBR_3_0_WrapContract.Customer();
    customer.accountNumber = getAccountNumber();

    if (order.Account.Record_Type_Text__c == 'Non-Credit') {
      setCashCustomer(customer);
    }

    //Optional except for Web-Guest Account
    if (order.Account.Record_Type_Text__c == 'Guest') {
      customer.webCashFirstName = order.Account.Name;
      customer.webCashLastName = order.Account.Name;
      customer.webCashDlState = order.Account.Driver_s_License_State__c;
      customer.webCashDlNumber = order.Account.Drivers_License__c;
      customer.webCashDlExpireDate = order.Account.DL_Expiration_Date__c != null
        ? getFormattedDate(order.Account.DL_Expiration_Date__c)
        : null;
      customer.webCashDob = order.Account.BirthDate__c != null
        ? getFormattedDate(order.Account.BirthDate__c)
        : null;
    }
    orderWrapper.customer = customer;
  }

  private static void setCashCustomer(SBR_3_0_WrapContract.Customer customer) {
    //Needed only for Cash Customers
    customer.driverLicenseState = order.Account.RM_Cash_State__c;
    customer.driverLicenseNumber = order.Account.RM_Cash_Number__c;
    customer.name = order.Account.Name;
    customer.socialSecurityNumber = order.Account.Social_Security_Number__c !=
      null
      ? Integer.valueOf(order.Account.Social_Security_Number__c)
      : null;
    customer.dateOfBirth = order.Account.Date_of_Birth__c != null
      ? getFormattedDate(order.Account.Date_of_Birth__c)
      : null;
    customer.employedBy = order.Account.Employed_By__c;
    customer.workPhoneNumber = order.Account.Phone;
    customer.addressInfo = getBillingAddress();
  }

  private static void setOrderedBy() {
    SBR_3_0_WrapContract.OrderedBy orderedBy = new SBR_3_0_WrapContract.OrderedBy();
    String concatName =
      order.Order_By__r.LastName +
      ', ' +
      order.Order_By__r.FirstName;

    Integer maxSize = 20;
    if (concatName.length() > maxSize) {
      concatName = concatName.substring(0, maxSize);
    }
    orderedBy.name = concatName;
    orderedBy.phoneNumber = order.Order_By__r.Phone;
    orderedBy.email = order.Order_By__r.Email;
    orderWrapper.orderedBy = orderedBy;
  }

  private static void groupOrderLines(List<OrderItem> orderItems) {
    orderWrapper.products = new List<SBR_3_0_WrapContract.Products>();
    orderWrapper.salesItems = new List<SBR_3_0_WrapContract.SalesItems>();
    orderWrapper.miscItems = new List<SBR_3_0_WrapContract.MiscItems>();

    for (OrderItem orderItem : orderItems) {
      if (orderItem.Product2.Product_Type__c == SBR_3_0_Constants.CAT_CLASS) {
        setProduct(orderItem);
      } else if (
        orderItem.Product2.Product_Type__c == SBR_3_0_Constants.PARTS ||
        orderItem.Product2.Product_Type__c == SBR_3_0_Constants.MERCHANDISE
      ) {
        setSalesItems(orderItem);
      } else if (
        orderItem.Product2.Product_Type__c == 'MISC Charge Items' ||
        orderItem.Product2.Product_Type__c == 'Misc-Charge'
      ) {
        setMiscItems(orderItem);
      }
    }
  }

  private static void setProduct(OrderItem orderItem) {
    SBR_3_0_WrapContract.Products product = new SBR_3_0_WrapContract.Products();
    product.sfLineNumber = orderItem.OrderItemNumber;
    product.catId = orderItem.Product2.Category__c;
    product.classId = orderItem.Product2.Class__c;
    product.quantity = orderItem.Quantity != null
      ? orderItem.Quantity.intValue()
      : 0;
    product.minimumRate = orderItem.Min_Rate__c;
    product.hourRate = orderItem.Hourly_Rate__c;
    product.dayRate = orderItem.Daily_Rate__c;
    product.weekRate = orderItem.Weekly_Rate__c;
    product.monthRate = orderItem.Monthly_Rate__c;
    product.discountPercent = orderItem.Discount_Percentage__c;
    product.dayRateOverrideCode = orderItem.Rates_Overriden__c ? 'Y' : 'N';
    product.weekRateOverrideCode = orderItem.Rates_Overriden__c ? 'Y' : 'N';
    product.monthRateOverrideCode = orderItem.Rates_Overriden__c ? 'Y' : 'N';
    product.mileageMeterReadingOut = orderitem.Meter_Reading_Out__c;
    product.startDateTime = orderItem.Date_Time_Out__c != null
      ? orderItem.Date_Time_Out__c.formatGMT(SBR_3_0_Constants.INT_DATE_FORMAT)
      : null;
    product.numberOfCreditDays = orderitem.Number_of_Credit_Days__c != null
      ? orderitem.Number_of_Credit_Days__c.intValue()
      : 0;
    product.numberOfCreditHours = orderitem.Number_of_Credit_Hours__c;
    product.creditReasonCode = orderItem.Credit_Reason_Code__c;
    product.freeFlag = orderItem.Free_Flag__c ? 'Y' : 'N';
    product.lineComment = orderItem.Line_Comments__c;
    product.rmLineNumber = orderItem.Contract_Line_Number__c != null
      ? Integer.valueOf(orderItem.Contract_Line_Number__c)
      : null;
    product.requestedCatId = orderItem.Requested_Category__c;
    product.requestedClassId = orderItem.Requested_Class__c;
    product.kitFlag = orderItem.Kit_component_item_or_neither__c;
    product.kitNumber = orderItem.Kit_Number_This_Item_Belongs_To__c;
    product.equipmentNumber = orderItem.Product2.Bulk_Item__c
      ? orderItem.Product2?.itemNumberUsedByReservationsRentalOut__c
      : orderItem.Product2.Category__c + orderItem.Product2.Class__c;
    //if kitFlag is Y then send kitnumber value to equipmentNumber as well
    if (orderItem.Kit_component_item_or_neither__c == 'Y') {
      product.equipmentNumber = orderItem.Kit_Number_This_Item_Belongs_To__c;
    }
    orderWrapper.products.add(product);
  }

  private static void setSalesItems(OrderItem orderItem) {
    SBR_3_0_WrapContract.SalesItems salesItem = new SBR_3_0_WrapContract.SalesItems();
    orderWrapper.salesItems = new List<SBR_3_0_WrapContract.SalesItems>();
    salesItem.rmLineNumber = orderItem.Contract_Line_Number__c != null
      ? Integer.valueOf(orderItem.Contract_Line_Number__c)
      : null;
    salesItem.sfLineNumber = String.valueOf(orderItem.OrderItemNumber);
    salesItem.itemNumber = orderItem.Product2.Item_Number__c;
    salesItem.stockClass = orderItem.Product2.Stock_Class__c;
    salesItem.freeFlag = orderItem.Free_Flag__c ? 'Y' : 'N';
    salesItem.quantity = orderItem.Quantity != null
      ? orderItem.Quantity.intValue()
      : 0;
    salesItem.unitPrice = orderItem.Selling_Price__c;
    salesItem.unitOfMeasure = orderItem.Order_Item_Unit_Of_Measure__c;
    salesItem.lineComment = orderItem.Line_Comments__c;
    orderWrapper.salesItems.add(salesItem);
  }

  private static void setMiscItems(OrderItem orderItem) {
    SBR_3_0_WrapContract.MiscItems miscItem = new SBR_3_0_WrapContract.MiscItems();
    orderWrapper.miscItems = new List<SBR_3_0_WrapContract.MiscItems>();
    miscItem.rmLineNumber = orderItem.Contract_Line_Number__c != null
      ? Integer.valueOf(orderItem.Contract_Line_Number__c)
      : null;
    miscItem.quantity = orderItem.Quantity != null
      ? orderItem.Quantity.intValue()
      : 0;
    miscItem.unitPrice = orderItem.Selling_Price__c;
    miscItem.unitOfMeasure = orderItem.Order_Item_Unit_Of_Measure__c;
    miscItem.freeFlag = orderItem.Free_Flag__c ? 'Y' : 'N';
    miscItem.lineComment = orderItem.Line_Comments__c;
    miscItem.sfLineNumber = String.valueOf(orderItem.OrderItemNumber);
    miscItem.itemNumber = orderItem.Product2.Item_Number__c;
    miscItem.stockClass = orderItem.Product2.Stock_Class__c;
    miscItem.productSku = orderItem.Product2.Product_SKU__c;
    miscItem.type = orderItem.Misc_Charges_Type__c;
    miscItem.charge = orderItem.Misc_Charge__c;
    miscItem.tax = orderItem.Misc_Charges_Tax__c;
    miscItem.taxExempt = orderItem.Taxable__c;
    miscItem.nonTaxable = orderItem.Misc_Charges_Non_Taxable__c;
    miscItem.itemTaxRate = orderItem.Misc_Charges_Item_Tax_Rate__c;
    orderWrapper.miscItems.add(miscItem);
  }

  private static void setSalesRepInfo() {
    SBR_3_0_WrapContract.SalesRepInfo salesRepInfo = new SBR_3_0_WrapContract.SalesRepInfo();
    salesRepInfo.primarySalesRepId = order.Sales_Rep__r.RepID__c;
    salesRepInfo.secondarySalesRepId = order.Secondary_Rep__c;
    orderWrapper.salesRepInfo = salesRepInfo;
  }

  private static void setPaymentDetails() {
    SBR_3_0_WrapContract.Payment paymentInfo = new SBR_3_0_WrapContract.Payment();
    paymentInfo.method = order.Cash_Customer_Payment_Method__c;
    paymentInfo.amount = order.Cash_Customer_Payment_Amount__c;
    List<Payments__c> paymentList = [
      SELECT Check_Number__c, Terminal__c
      FROM Payments__c
      WHERE Order__c = :order.Id
      LIMIT 1
    ];
    if (!paymentList.isEmpty()) {
      paymentInfo.creditCardLane = paymentList[0].Terminal__c;
      paymentInfo.checkNumber = paymentList[0].Check_Number__c;
    }
    orderWrapper.payment = paymentInfo;
  }

  private static void setDeliveryInfo() {
    SBR_3_0_WrapContract.DeliveryInfo deliveryInfo = new SBR_3_0_WrapContract.DeliveryInfo();
    deliveryInfo.fulfillmentType = order.DeliveryMethod__c;
    deliveryInfo.deliveryInstructions = order.Delivery_Instructions__c;
    orderWrapper.deliveryInfo = deliveryInfo;
  }

  private static void setReturnInfo() {
    SBR_3_0_WrapContract.ReturnInfo returnInfo = new SBR_3_0_WrapContract.ReturnInfo();
    returnInfo.returnType = order.Pick_Up__c ? 'Pickup' : 'Dropoff';
    orderWrapper.returnInfo = returnInfo;
  }

  private static void setBillingInfo() {
    SBR_3_0_WrapContract.Billings billingInfo = new SBR_3_0_WrapContract.Billings();
    billingInfo.poNumber = order.PoNumber;
    billingInfo.deliveryCharge = order.Delivery_Charge__c;
    billingInfo.pickUpCharge = order.Pickup_Charge__c;
    //billingInfo.chargeRentalProtectionPlan = order.Is_RPP_Charge__c == 'Yes'? 'Y' : 'N';    //commented as per FRONT-30293,30294
    billingInfo.chargeRentalProtectionPlan = order.RPP__c;    //FRONT-30293,30294
    orderWrapper.billings = billingInfo;
  }

  private static void setPC() {
    SBR_3_0_WrapContract.Pc pc = new SBR_3_0_WrapContract.Pc();
    if (order.Sourcing_Branch__c != null) {
      pc.id = order.Sourcing_Branch__r.Branch_Location_Number__c;
      if (order.Sourcing_Branch__r?.Time_Zone_Id__c != null) {
        pc.timezoneName = order.Sourcing_Branch__r?.Time_Zone_Id__c;
      } else {
        User loggedInUser = SBR_3_0_UserDA.getUserById(UserInfo.getUserId());
        pc.timezoneName = loggedInUser?.TimeZoneSidKey;
      }
    } else {
      pc.id = order.Branch__r.Branch_Location_Number__c;
      if (order.Branch__r.Time_Zone_Id__c != null) {
        pc.timezoneName = order.Branch__r.Time_Zone_Id__c;
      } else {
        User loggedInUser = SBR_3_0_UserDA.getUserById(UserInfo.getUserId());
        pc.timezoneName = loggedInUser?.TimeZoneSidKey;
      }
    }
    orderWrapper.pc = pc;
  }

  private static void setJobSite() {
    SBR_3_0_WrapContract.Jobsite jobSite = new SBR_3_0_WrapContract.Jobsite();
    jobSite.address = new SBR_3_0_WrapContract.Address();
    jobSite.jobsiteNumber = order.Jobsite__r.Job_Number__c;
    jobSite.address.location = '';
    orderWrapper.jobSite = jobSite;
  }

  private static Integer getFormattedDate(Date dtValue) {
    String strDateValue =
      String.valueOf(dtValue.year()) +
      String.valueOf(dtValue.month()) +
      String.valueOf(dtValue.day());
    return Integer.valueOf(strDateValue);
  }

  private static void setAddressInfo() {
    if (
      !String.isBlank(order.Account.Name) &&
      !String.isBlank(order.Account.ShippingStreet) &&
      !String.isBlank(order.Account.ShippingCity) &&
      !String.isBlank(order.Account.ShippingStateCode) &&
      !String.isBlank(order.Account.ShippingCountry) &&
      !String.isBlank(order.Account.ShippingPostalCode) &&
      !String.isBlank(order.Account.Phone)
    ) {
      List<SBR_3_0_WrapContract.AddressInfo_Z> addressInfoList = new List<SBR_3_0_WrapContract.AddressInfo_Z>();
      SBR_3_0_WrapContract.AddressInfo_Z addressInfo = new SBR_3_0_WrapContract.AddressInfo_Z();
      addressInfo.address = new SBR_3_0_WrapContract.Address_Z();
      addressInfo.type = 'shipping';
      addressInfo.address.name = order.Account.Name;
      addressInfo.address.line1 = order.Account.ShippingStreet.toUpperCase();
      addressInfo.address.line2 = order.Account.ShippingStreet;
      addressInfo.address.city = order.Account.ShippingCity.toUpperCase();
      addressInfo.address.state = order.Account.ShippingStateCode.toUpperCase();
      addressInfo.address.country = order.Account.ShippingCountry.toUpperCase();
      addressInfo.address.zip = order.Account.ShippingPostalCode.toUpperCase();
      addressInfo.address.phoneNumber = order.Account.Phone;
      addressInfoList.add(addressInfo);
      orderWrapper.addressInfo = addressInfoList;
    }
  }

  private static List<SBR_3_0_WrapContract.AddressInfo> getBillingAddress() {
    List<SBR_3_0_WrapContract.AddressInfo> addressInfoList = new List<SBR_3_0_WrapContract.AddressInfo>();
    if (
      !String.isBlank(order.Account.BillingStreet) &&
      !String.isBlank(order.Account.BillingCity) &&
      !String.isBlank(order.Account.BillingStateCode) &&
      !String.isBlank(order.Account.BillingCountry) &&
      !String.isBlank(order.Account.BillingPostalCode) &&
      !String.isBlank(order.Account.Phone)
    ) {
      SBR_3_0_WrapContract.AddressInfo addressInfo = new SBR_3_0_WrapContract.AddressInfo();
      addressInfo.type = 'billing';
      addressInfo.address = new SBR_3_0_WrapContract.Address();
      addressInfo.address.line1 = order.Account.BillingStreet.toUpperCase();
      addressInfo.address.line2 = order.Account.BillingStreet;
      addressInfo.address.city = order.Account.BillingCity.toUpperCase();
      addressInfo.address.state = order.Account.BillingStateCode.toUpperCase();
      addressInfo.address.country = order.Account.BillingCountry.toUpperCase();
      addressInfo.address.zip = order.Account.BillingPostalCode.toUpperCase();
      addressInfo.address.phoneNumber = order.Account.Phone;
      addressInfoList.add(addressInfo);
    }
    return addressInfoList;
  }

  private static String getAccountNumber() {
    String accountNumber;
    Account currentAccount = new Account();
    if (order.Account != null) {
      if (order.Account.RM_Account_Number__c != null) {
        accountNumber = order.Account.RM_Account_Number__c;
        if (accountNumber.contains('-')) {
          accountNumber = accountNumber.subStringAfter('-');
        }
        if (order.Account.Record_Type_Text__c == 'Non-Credit') {
          accountNumber = '0';
        }
      } else {
        currentAccount = SBR_3_0_AccountDA.getAccountRMNumberAndType(
          order.AccountId,
          true
        );
        if (
          currentAccount != null &&
          currentAccount.RM_Account_Number__c != null
        ) {
          if (currentAccount.RM_Account_Number__c.contains('-')) {
            accountNumber = currentAccount.RM_Account_Number__c.subStringAfter(
              '-'
            );

            if (order.Account.Record_Type_Text__c == 'Non-Credit') {
              accountNumber = '0';
            }
          }
        } else {
          accountNumber = '0';
        }
      }
    }
    return accountNumber;
  }
}