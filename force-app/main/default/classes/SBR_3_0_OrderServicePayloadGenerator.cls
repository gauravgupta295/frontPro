public class SBR_3_0_OrderServicePayloadGenerator {
  static SBR_3_0_WrapOrder orderWrapper;
  static Order order;
  public static String makeADepositDetails = '';

  public static String generatePayload(Order orderInstance) {
    orderWrapper = new SBR_3_0_WrapOrder();
    order = orderInstance;
    generateWrapper();
    System.debug('\n @@ request =' + JSON.serializePretty(orderWrapper, true));
    return JSON.serialize(orderWrapper, true);
  }

  private static void generateWrapper() {
    orderWrapper.rentalmanUser = 'WROHR';
    orderWrapper.marketSegment = order.Market_Segment__c != null
      ? order.Market_Segment__c
      : null;

    orderWrapper.sfOrderId = order.OrderNumber;
    orderWrapper.territoryNumber = order.Jobsite__r.Territory_Number__c != null
      ? Integer.valueOf(order.Jobsite__r.Territory_Number__c)
      : null;
    orderWrapper.leaveFacilityDate = order.Leave_Facility_Date__c != null
      ? order.Leave_Facility_Date__c.formatGMT(
          SBR_3_0_Constants.INT_DATE_FORMAT
        )
      : null;
    orderWrapper.installStartDate = order.Install_Start_Date__c != null
      ? order.Install_Start_Date__c.formatGMT(SBR_3_0_Constants.INT_DATE_FORMAT)
      : null;
    orderWrapper.dismantleStartDate = order.Dismantle_Start_Date__c != null
      ? order.Dismantle_Start_Date__c.formatGMT(
          SBR_3_0_Constants.INT_DATE_FORMAT
        )
      : null;

    orderWrapper.systemName = 'TRAINING';
    orderWrapper.companyId = !String.isBlank(order.Company_Code__c)
      ? Integer.valueOf(order.Company_Code__c)
      : 1;

    String rmQuoteIdSansCompanyCode = '';
    if (!String.IsBlank(order.Rentalman_Quote_Id__c)) {
      if (order.Rentalman_Quote_Id__c.contains('-')) {
        rmQuoteIdSansCompanyCode = order.Rentalman_Quote_Id__c.substringAfter(
          '-'
        );
      } else {
        rmQuoteIdSansCompanyCode = order.Rentalman_Quote_Id__c;
      }
    }

    if (isConvertQuoteToOrder() || Test.isRunningTest()) {
      //Convert Quote to Order - on RM side this is Conver to Order API
      orderWrapper.convertQuoteToOrder = 'Y';
      orderWrapper.rmQuoteId = rmQuoteIdSansCompanyCode;
      orderWrapper.sfQuoteId = order.SBQQ__Quote__r.Name;
      orderWrapper.rmQuoteId = rmQuoteIdSansCompanyCode;
    } else {
      //Submit an Order which is not converted from Quote to Order first - on RM side this is Order creation API
      orderWrapper.convertQuoteToOrder = 'N';
    }
    orderWrapper.userType = order.Account.Record_Type_Text__c == 'Credit' ||
      order.Account.Record_Type_Text__c == 'Corp Link'
      ? 'credit'
      : 'cash'; //

    String accountNumber;
    Account currentAccount = new Account();

    if (order.Account != null) {
      if (order.Account.RM_Account_Number__c != null) {
        accountNumber = order.Account.RM_Account_Number__c;
        if (accountNumber.contains('-')) {
          accountNumber = accountNumber.subStringAfter('-');
        }
        if (order.Account.Record_Type_Text__c == 'Non-Credit') {
          orderWrapper.accountNumber = '0';
        } else if (order.Account.Record_Type_Text__c != 'Non-Credit') {
          orderWrapper.accountNumber = accountNumber;
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
              orderWrapper.accountNumber = '0';
            } else if (order.Account.Record_Type_Text__c != 'Non-Credit') {
              orderWrapper.accountNumber = accountNumber;
            }
          }
          orderWrapper.userType = currentAccount.Record_Type_Text__c == 'Credit'
            ? 'credit'
            : null;
        } else {
          orderWrapper.accountNumber = '0';
        }
      }

      orderWrapper.sfAccountNumber = order.Account.SF_Account_Number__c;
      if (
        String.isNotBlank(order.Account.Driver_s_License_State__c) &&
        String.isNotBlank(order.Account.Drivers_License__c)
      ) {
        orderWrapper.driverLicenseState = order.Account.RM_Cash_State__c;
        orderWrapper.driverLicenseNumber = order.Account.RM_Cash_Number__c;
      }
    }

    orderWrapper.fulfillmentType = order.Deliverymethod__c;
    orderWrapper.deliveryInstructions = null;
    orderWrapper.startDateTime = order.Start_Date__c != null
      ? order.Start_Date__c.formatGMT(SBR_3_0_Constants.INT_DATE_FORMAT)
      : null;
    orderWrapper.endDateTime = order.Return_Date__c != null
      ? order.Return_Date__c.formatGMT(SBR_3_0_Constants.INT_DATE_FORMAT)
      : null;
    orderWrapper.earliestDateTime = order.Earliest_Delivery_Date__c != null
      ? order.Earliest_Delivery_Date__c.formatGMT(
          SBR_3_0_Constants.INT_DATE_FORMAT
        )
      : null; // optional

    orderWrapper.poNumber = order.PoNumber;
    //orderWrapper.optOutRPP = order.Opt_Out_RPP__c ? 'Y' : 'N';    //commented as per FRONT-30293,30294
    orderWrapper.chargeRentalProtectionPlan = order.RPP__c;         //FRONT-30293,30294
    orderWrapper.optOutFuelCharge = order.Opt_Out_Fuel_Charge__c ? 'Y' : 'N';
    orderWrapper.deliveryCharge = order.Delivery_Charge__c;
    orderWrapper.phoneNumber = order.Account.Phone != null
      ? order.Account.Phone.replaceAll('[^0-9]', '')
      : '0000000000';

    orderWrapper.sellingChannel = SBR_3_0_Constants.SELLING_CHANNEL;
    orderWrapper.initiatingChannel = SBR_3_0_Constants.INITIATING_CHANNEL;
    orderWrapper.primarySalesRepId = order.Sales_Rep__r.RepID__c;
    orderWrapper.pickUpCharge = order.Pickup_Charge__c != null
      ? order.Pickup_Charge__c
      : 0;
    orderWrapper.useCodeA = order.Use_Code__c;
    orderWrapper.deliveredBy = order.Delivered_By__c;
    orderWrapper.withinCityLimits = order.Within_City_Limits__c;
    orderWrapper.invoiceDueDateCode = order.Invoice_Due_Date_Code__c;
    orderWrapper.paymentCode = order.Payment_Code__c;
    orderWrapper.rewardNumber = order.Reward_Number__c;
    orderWrapper.signature = order.Signature__c;
    orderWrapper.printYOrN = order.Print__c ? 'Y' : 'N';
    orderWrapper.faxEmail = order.Fax_Email__c ? 'Y' : 'N';
    orderWrapper.pickedUpBy = order.Picked_Up_By__c;
    orderWrapper.returnType = order.Pick_Up__c ? 'Pickup' : 'Dropoff';

    setPC();
    if (order.Account.Record_Type_Text__c != 'Non-Credit') {
      setJobsite();
    }
    setOrderedBy();
    groupOrderLines(order.OrderItems);
    if (order.Account.Record_Type_Text__c == 'Non-Credit') {
      setPaymentDetails();
      setAddressInfo();
    }
  }

  private static void setAddressInfo() {
    if (
      !String.isBlank(order.Account.Name) &&
      !String.isBlank(order.Account.BillingStreet) &&
      !String.isBlank(order.Account.BillingCity) &&
      !String.isBlank(order.Account.BillingStateCode) &&
      !String.isBlank(order.Account.BillingPostalCode) &&
      !String.isBlank(order.Account.Phone)
    ) {
      List<SBR_3_0_WrapOrder.AddressInfo> addressInfoList = new List<SBR_3_0_WrapOrder.AddressInfo>();
      SBR_3_0_WrapOrder.AddressInfo addressInfo = new SBR_3_0_WrapOrder.AddressInfo();
      addressInfo.address = new SBR_3_0_WrapOrder.Address();
      addressInfo.type = 'shippingAddress';
      addressInfo.address.name = order.Account.Name;
      addressInfo.address.line1 = order.Account.BillingStreet.toUpperCase();
      addressInfo.address.line2 = order.Account.BillingStreet;
      addressInfo.address.city = order.Account.BillingCity.toUpperCase();
      addressInfo.address.state = order.Account.BillingStateCode.toUpperCase();
      addressInfo.address.country = order.Account.BillingCountry.toUpperCase();
      addressInfo.address.zip = order.Account.BillingPostalCode.toUpperCase();
      addressInfo.address.phoneNumber = order.Account.Phone;
      addressInfoList.add(addressInfo);
      orderWrapper.addressInfo = addressInfoList;
    }
  }

  private static void setPC() {
    orderWrapper.pc = new SBR_3_0_WrapOrder.Pc();
    if (
      order.Sourcing_Branch__c != null &&
      order.Sourcing_Branch__r.Latitude_Longitude__Longitude__s != null &&
      order.Sourcing_Branch__r.Latitude_Longitude__Latitude__s != null
    ) {
      orderWrapper.pc.id = order.Sourcing_Branch__r.Branch_Location_Number__c;
      if (order.Sourcing_Branch__r?.Time_Zone_Id__c != null) {
        orderWrapper.pc.timezoneName = order.Sourcing_Branch__r
          ?.Time_Zone_Id__c;
      } else {
        User loggedInUser = SBR_3_0_UserDA.getUserById(UserInfo.getUserId());
        orderWrapper.pc.timezoneName = loggedInUser?.TimeZoneSidKey;
      }
    } else {
      orderWrapper.pc.id = order.Branch__r.Branch_Location_Number__c;
      if (order.Branch__r.Time_Zone_Id__c != null) {
        orderWrapper.pc.timezoneName = order.Branch__r.Time_Zone_Id__c;
      } else {
        User loggedInUser = SBR_3_0_UserDA.getUserById(UserInfo.getUserId());
        orderWrapper.pc.timezoneName = loggedInUser?.TimeZoneSidKey;
      }
    }
  }

  private static void setJobsite() {
    orderWrapper.jobsite = new SBR_3_0_WrapOrder.Jobsite();
    orderWrapper.jobsite.address = new SBR_3_0_WrapOrder.Address();
    orderWrapper.jobsite.id = order.Jobsite__r.Job_Site_Id__c;
    orderWrapper.jobsite.jobsiteNumber = order.Jobsite__r.Job_Number__c;
    orderWrapper.jobsite.address.name = order.Jobsite__r.Location.Name;
    orderWrapper.jobsite.address.line1 = order.Jobsite__r.Location.Street_Address__c.toUpperCase();
    orderWrapper.jobsite.address.line2 = order.Jobsite__r.Location.Street_Address_2__c;
    orderWrapper.jobsite.address.city = order.Jobsite__r.Location.City__c.toUpperCase();
    orderWrapper.jobsite.address.state = order.Jobsite__r.Location.State__c.toUpperCase();
    orderWrapper.jobsite.address.country = order.Jobsite__r.Location.Country__c.toUpperCase();
    orderWrapper.jobsite.address.zip = order.Jobsite__r.Location.Zip_Code__c.toUpperCase();
    orderWrapper.jobsite.address.phoneNumber = order.Jobsite__r.Job_Site_Contact__c !=
      null
      ? order.Jobsite__r.Job_Site_Contact__c.replaceAll('[^0-9]', '')
      : null;

    orderWrapper.jobsite.address.location = order.Jobsite__r.Location.Name;
  }

  private static void setOrderedBy() {
    orderWrapper.orderedBy = new SBR_3_0_WrapOrder.OrderedBy();
    String concatName =
      order.Order_By__r.LastName +
      ', ' +
      order.Order_By__r.FirstName;

    Integer maxSize = 20;
    if (concatName.length() > maxSize) {
      concatName = concatName.substring(0, maxSize);
    }
    orderWrapper.orderedBy.name = concatName;
    orderWrapper.orderedBy.phoneNumber = order.Order_By__r.Phone;
    orderWrapper.orderedBy.email = order.Order_By__r.Email;
  }

  private static void groupOrderLines(List<OrderItem> orderItems) {
    orderWrapper.products = new List<SBR_3_0_WrapOrder.Products>();
    orderWrapper.salesItems = new List<SBR_3_0_WrapOrder.SalesItems>();
    // orderWrapper.miscItems = new List<SBR_3_0_WrapOrder.MiscItems>();
    for (OrderItem orderItemRec : orderItems) {
      if (
        orderItemRec.Product2.Product_Type__c == SBR_3_0_Constants.CAT_CLASS
      ) {
        setProduct(orderItemRec);
      } else if (
        orderItemRec.Product2.Product_Type__c == SBR_3_0_Constants.PARTS ||
        orderItemRec.Product2.Product_Type__c ==
        SBR_3_0_Constants.MERCHANDISE ||
        (orderItemRec.is_User_Added__c &&
        (orderItemRec.Product2.Product_Type__c == 'MISC Charge Items' ||
        orderItemRec.Product2.Product_Type__c == 'Misc-Charge'))
      ) {
        setSalesItem(orderItemRec);
      }
      // else if(order.Reservation_Order_Number__c == null){
      //   setMiscItem(orderItemRec);
      // }
    }
  }

  private static void setProduct(OrderItem orderItem) {
    SBR_3_0_WrapOrder.Products product = new SBR_3_0_WrapOrder.Products();
    product.equipmentId = orderItem.Product2.Bulk_Item__c
      ? orderItem.Product2?.itemNumberUsedByReservationsRentalOut__c
      : orderItem.Product2.Category__c + orderItem.Product2.Class__c; //SAL-24130

    product.suggestedRates = new SBR_3_0_WrapOrder.SuggestedRates();
    product.actualRates = new SBR_3_0_WrapOrder.SuggestedRates();
    product.hourRate = orderItem.Hourly_Rate__c != null
      ? orderItem.Hourly_Rate__c
      : 0;

    if (orderItem.Reservation_Line_Number__c != null) {
      product.action = String.isNotBlank(orderItem.Action__c)
        ? orderItem.Action__c
        : 'UPDATE';
    } else {
      product.action = String.isNotBlank(orderItem.Action__c)
        ? orderItem.Action__c
        : 'ADD';
    }
    product.rmLineNumber = orderItem.Reservation_Line_Number__c?.intValue();
    product.minimumRate = orderItem.Min_Rate__c;
    product.catId = orderItem.Product2.Category__c;
    product.classId = orderItem.Product2.Class__c;
    product.quantity = orderItem.Item_Marked_For_Cancellation__c
      ? 0
      : orderItem.Quantity.intValue();
    product.suggestedRates.day = orderItem.Suggested_Daily_Rate__c;
    product.suggestedRates.weekly = orderItem.Suggested_Weekly_Rate__c;
    product.suggestedRates.monthly = orderItem.Suggested_Monthly_Rate__c;
    product.actualRates.day = orderItem.Daily_Rate__c;
    product.actualRates.weekly = orderItem.Weekly_Rate__c;
    product.actualRates.monthly = orderItem.Monthly_Rate__c;
    product.dayRateOverride = orderItem.Rates_Overriden__c ? 'Y' : 'N';
    product.weeklyRateOverride = orderItem.Rates_Overriden__c ? 'Y' : 'N';
    product.monthlyRateOverride = orderItem.Rates_Overriden__c ? 'Y' : 'N';
    product.lineComment = orderItem.Equipment_Comments__c;
    product.sfLineNumber = String.valueOf(orderItem.OrderItemNumber);
    product.lineItemId = orderItem.Id; //Added as part FRONT-9280
    product.kitNumber = orderItem.Kit_Number_This_Item_Belongs_To__c;
    product.freeFlag = orderItem.Free_Flag__c ? 'Y' : 'N'; //FRONT-27716
    if (String.isNotBlank(product.kitNumber)) {
      product.kitFlag = orderItem.Kit_component_item_or_neither__c;
    }
    orderWrapper.products.add(product);
  }

  private static Boolean isConvertQuoteToOrder() {
    if (order.Rentalman_Quote_Id__c != null && order.SBQQ__Quote__c != null) {
      return true;
    } else {
      return false;
    }
  }

  //FRONT-13623
  private static void setSalesItem(OrderItem orderItem) {
    SBR_3_0_WrapOrder.SalesItems salesItem = new SBR_3_0_WrapOrder.SalesItems();
    if (orderItem.Reservation_Line_Number__c != null) {
      salesItem.action = String.isNotBlank(orderItem.Action__c)
        ? orderItem.Action__c
        : 'UPDATE';
    } else {
      salesItem.action = String.isNotBlank(orderItem.Action__c)
        ? orderItem.Action__c
        : 'ADD';
    }
    salesItem.rmLineNumber = orderItem.Reservation_Line_Number__c?.intValue();
    salesItem.sfLineNumber = String.valueOf(orderItem.OrderItemNumber);
    salesItem.itemNumber = orderItem.Product2.Item_Number__c;
    salesItem.quantity = orderItem.Item_Marked_For_Cancellation__c
      ? 0
      : orderItem.Quantity.intValue();
    salesItem.stockClass = orderItem.Product2.Stock_Class__c;
    salesItem.unitPrice = orderItem.Selling_Price__c;
    salesItem.unitOfMeasure = orderItem.Order_Item_Unit_Of_Measure__c;
    salesItem.lineComment = orderItem.Line_Comments__c;
    salesItem.freeFlag = orderItem.Free_Flag__c ? 'Y' : 'N'; //FRONT-27716
    // salesItem.lineItemId = orderItem.Id;
    orderWrapper.salesItems.add(salesItem);
  }

  // COMMENTING THE BELOW CODE AS THE RATE VALIDATION STORIES ARE CURRENTLY UNTAGGED FROM THE SPRINT AND WILL COME IN FUTURE SPRINT

  // //FRONT-9280
  // public static SBR_3_0_WrapOrder getPayloadWrapper(Order orderInstance) {
  //   orderWrapper = new SBR_3_0_WrapOrder();
  //   order = orderInstance;
  //   generateWrapper();
  //   return orderWrapper;
  // }

  // private static void setMiscItem(OrderItem orderItem) {
  //     SBR_3_0_WrapOrder.MiscItems miscItems = new SBR_3_0_WrapOrder.MiscItems();
  //     miscItems.type = orderItem.Misc_Charges_Type__c;
  //     miscItems.charge = orderItem.Selling_Price__c;
  //     miscItems.tax = orderItem.Misc_Charges_Tax__c;
  //     miscItems.taxExempt = orderItem.Taxable__c;
  //     miscItems.nonTaxable = orderItem.Misc_Charges_Non_Taxable__c;
  //     miscItems.itemTaxRate = orderItem.Misc_Charges_Item_Tax_Rate__c;
  //     miscItems.itemNumber = orderItem.Product2.Item_Number__c;
  //     miscItems.stockClass = orderItem.Product2.Stock_Class__c;
  //     miscItems.sfLineNumber = String.valueOf(orderItem.OrderItemNumber);
  //     miscItems.productSku = orderItem.Product2.Product_SKU__c;
  //     orderWrapper.miscItems.add(miscItems);
  //   }
  @TestVisible
  private static void setPaymentDetails() {
    try {
      SBR_3_0_WrapOrder.Payment paymentDetails = new SBR_3_0_WrapOrder.Payment();
      Map<String, String> mapOfPaymentMenthodAnnotation = new Map<String, String>{
        'Visa' => 'V',
        'Amex' => 'A',
        'Cash Currency' => 'C',
        'Discover' => 'D',
        'Interac Debit' => 'G',
        'Check' => 'K',
        'Mastercard' => 'M',
        'No Refund Given' => 'N',
        'Pay on Return' => 'P',
        'Refund Request (Corporate)' => 'R',
        'Uncollected' => 'U',
        'Visa' => 'V',
        'Diners Club' => 'X'
      };
      Map<String, Object> paymentDetailsObject = (Map<String, Object>) JSON.deserializeUntyped(
        makeADepositDetails
      );
      String PMselected = (String) paymentDetailsObject.get('paymentMethod');

      SBR_3_0_Generic_Callout.PaymentMethod = (String) paymentDetailsObject.get(
        'paymentMethod'
      );

      paymentDetails.method = mapOfPaymentMenthodAnnotation.get(PMselected);
      paymentDetails.amount = (Decimal) paymentDetailsObject.get(
        'amountCollected'
      );
      if (
        (mapOfPaymentMenthodAnnotation.get(PMselected) == 'A' ||
        mapOfPaymentMenthodAnnotation.get(PMselected) == 'V' ||
        mapOfPaymentMenthodAnnotation.get(PMselected) == 'D' ||
        mapOfPaymentMenthodAnnotation.get(PMselected) == 'M' ||
        mapOfPaymentMenthodAnnotation.get(PMselected) == 'X' ||
        mapOfPaymentMenthodAnnotation.get(PMselected) == 'G')
      ) {
        //Make sure CreditCardlane is passed only if card is selected.
        paymentDetails.creditCardLane = (String.valueOf(
            paymentDetailsObject.get('terminal')
          ) == null ||
          String.valueOf(paymentDetailsObject.get('terminal')) == '')
          ? '0'
          : String.valueOf(paymentDetailsObject.get('terminal'))
              .split('ID: ')[1];
      }
      if (mapOfPaymentMenthodAnnotation.get(PMselected) == 'K') {
        paymentDetails.checkNumber = String.valueOf(
          paymentDetailsObject.get('checkNumber')
        );
      }
      orderWrapper.Payment = paymentDetails;
    } catch (Exception Ex) {
      system.debug('Error Line 2' + Ex.getStackTraceString());
      system.debug('Error Message 2' + Ex.getMessage());
    }
  }
}