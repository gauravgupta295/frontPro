/*********************************************************************************************************************
* Apex Class: SBR_3_0_CreateQuotesPayloadGenerator
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Generating payload for send Quote to Rentalman (via Mulesoft) when it is created in Salesforce
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Arpita Agarwal         2022-09-23             Initial version    
*********************************************************************************************************************/
public with sharing class SBR_3_0_CreateQuotesPayloadGenerator {
  static SBR_3_0_EditQuotesWrapper quoteEditWrapper;
  static SBQQ__Quote__c quote;
  public static String generatePayload(SBQQ__Quote__c quoteInstance) {
    quoteEditWrapper = new SBR_3_0_EditQuotesWrapper();
    quote = quoteInstance;
    generateWrapper();
    System.debug(
      '\n ====request====' + JSON.serializePretty(quoteEditWrapper, true)
    );
    return JSON.serialize(quoteEditWrapper, true);
  }
  private static void generateWrapper() {
    quoteEditWrapper.sfQuoteId = quote.Name;
    quoteEditWrapper.sellingChannel = SBR_3_0_Constants.SELLING_CHANNEL;
    quoteEditWrapper.initiatingChannel = SBR_3_0_Constants.INITIATING_CHANNEL;
    quoteEditWrapper.rentalmanUser = 'WROHR';
    String accountNumber;
    Account currentAccount = new Account();
    if (quote.SBQQ__Account__r != null) {
      if (quote.SBQQ__Account__r.RM_Account_Number__c != null) {
        accountNumber = quote.SBQQ__Account__r.RM_Account_Number__c;
        if (accountNumber.contains('-')) {
          accountNumber = accountNumber.subStringAfter('-');
        }
        if (quote.SBQQ__Account__r.Record_Type_Text__c == 'Non-Credit') {
          quoteEditWrapper.accountNumber = '0';
        } else if (quote.SBQQ__Account__r.Record_Type_Text__c != 'Non-Credit') {
          quoteEditWrapper.accountNumber = accountNumber;
        }
      } else {
        currentAccount = SBR_3_0_AccountDA.getAccountRMNumberAndType(
          quote.SBQQ__Account__r.Id,
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
            if (quote.SBQQ__Account__r.Record_Type_Text__c == 'Non-Credit') {
              quoteEditWrapper.accountNumber = '0';
            } else if (
              quote.SBQQ__Account__r.Record_Type_Text__c != 'Non-Credit'
            ) {
              quoteEditWrapper.accountNumber = accountNumber;
            }
          }
          quoteEditWrapper.userType = currentAccount.Record_Type_Text__c ==
            'Credit'
            ? 'credit'
            : null;
        } else {
          quoteEditWrapper.accountNumber = '0';
        }
      }

      quoteEditWrapper.sfAccountNumber = quote.SBQQ__Account__r.SF_Account_Number__c;
      if (
        String.isNotBlank(quote.SBQQ__Account__r.Driver_s_License_State__c) &&
        String.isNotBlank(quote.SBQQ__Account__r.Drivers_License__c)
      ) {
        quoteEditWrapper.driverLicenseState = quote.SBQQ__Account__r.Driver_s_License_State__c;
        quoteEditWrapper.driverLicenseNumber = quote.SBQQ__Account__r.Drivers_License__c;
      }
    }
    quoteEditWrapper.userType = quote.SBQQ__Account__r.Record_Type_Text__c ==
      'Credit' ||
      quote.SBQQ__Account__r.Record_Type_Text__c == 'Corp Link'
      ? 'credit'
      : 'cash';
    quoteEditWrapper.poNumber = quote.P_O_Num__c;
    quoteEditWrapper.fulfillmentType = quote.SBQQ__DeliveryMethod__c;
    quoteEditWrapper.returnType = quote.Pick_Up__c ? 'Pickup' : 'Dropoff';
    quoteEditWrapper.startDateTime = quote.Start_Date__c != null
      ? quote.Start_Date__c.formatGMT(SBR_3_0_Constants.INT_DATE_FORMAT)
      : null;
    quoteEditWrapper.endDateTime = quote.End_Date__c != null
      ? quote.End_Date__c.formatGMT(SBR_3_0_Constants.INT_DATE_FORMAT)
      : null;
    quoteEditWrapper.primarySalesRepId = quote.SBQQ__SalesRep__r.RepID__c;
    quoteEditWrapper.earliestDateTime = quote.Delivery_Date__c != null
      ? quote.Delivery_Date__c.formatGMT(SBR_3_0_Constants.INT_DATE_FORMAT)
      : null;
    quoteEditWrapper.territoryNumber = quote.Jobsite__r.Territory_Number__c !=
      null
      ? Integer.valueOf(quote.Jobsite__r.Territory_Number__c)
      : null;
    quoteEditWrapper.useCodeA = quote.Use_Code__c;
    quoteEditWrapper.preBillRentals = quote.Pre_Bill_Rentals__c ? 'Y' : 'N';
    quoteEditWrapper.proRateRentals = quote.Pro_Rate_Rentals__c ? 'Y' : 'N';
    quoteEditWrapper.dayOfMonthToBillOn = quote.Day_of_Month_to_Bill_on__c;
    quoteEditWrapper.printRatesOnContracts = quote.Print_Rates_on_Contracts__c;
    //quoteEditWrapper.optOutRPP = quote.Opt_Out_RPP__c ? 'Y' : 'N';    //commented as per FRONT-30293,30294
    quoteEditWrapper.chargeRentalProtectionPlan = quote.RPP__c;         //FRONT-30293,30294
    quoteEditWrapper.marketSegment = quote.Market_Segment__c != null
      ? quote.Market_Segment__c
      : null;
    quoteEditWrapper.withinCityLimits = quote.Within_City_Limits__c;
    quoteEditWrapper.sourceCode = quote.Source_Code__c;
    quoteEditWrapper.invoiceDueDateCode = quote.Invoice_Due_Date_Code__c;
    quoteEditWrapper.paymentCode = quote.Payment_Code__c;
    quoteEditWrapper.billingCode = quote.Billing_Code__c;
    quoteEditWrapper.rewardNumber = quote.Reward_Number__c;
    quoteEditWrapper.signature = quote.Signature__c;
    quoteEditWrapper.printYOrN = quote.Print__c ? 'Y' : 'N';
    quoteEditWrapper.faxEmail = quote.Fax_Email__c ? 'Y' : 'N';
    quoteEditWrapper.leaveFacilityDate = quote.Leave_Facility_Date__c != null
      ? quote.Leave_Facility_Date__c.formatGMT(
          SBR_3_0_Constants.INT_DATE_FORMAT
        )
      : null;
    quoteEditWrapper.installStartDate = quote.Install_Start_Date__c != null
      ? quote.Install_Start_Date__c.formatGMT(SBR_3_0_Constants.INT_DATE_FORMAT)
      : null;
    quoteEditWrapper.dismantleStartDate = quote.Dismantle_Start_Date__c != null
      ? quote.Dismantle_Start_Date__c.formatGMT(
          SBR_3_0_Constants.INT_DATE_FORMAT
        )
      : null;
    quoteEditWrapper.comments = quote.Quote_Header_Comments__c;
    quoteEditWrapper.deliveryCharge = quote.Delivery_Charges__c;
    quoteEditWrapper.deliveryInstructions = quote.Delivery_Special_Instructions__c;
    quoteEditWrapper.deliveredBy = quote.Delivered_By__c;
    quoteEditWrapper.cartId = quote.Cart__r.Name;
    quoteEditWrapper.pickedUpBy = quote.Picked_Up_By__c;
    quoteEditWrapper.pickUp = quote.Pick_Up__c;
    setPC();
    if (quote.SBQQ__Account__r.Record_Type_Text__c != 'Non-Credit') {
      setJobsite();
    }
    setOrderedBy();
    groupOrderLines(quote.SBQQ__LineItems__r);
    if (quote.SBQQ__Account__r.Record_Type_Text__c == 'Non-Credit') {
      setPayment();
      setAddressInfo();
    }
  }

  private static void setPayment() {
    quoteEditWrapper.payment = new SBR_3_0_EditQuotesWrapper.Payment();
    quoteEditWrapper.payment.method = quote.Cash_Customer_Payment_Method__c !=
      null
      ? quote.Cash_Customer_Payment_Method__c
      : 'P';
    quoteEditWrapper.payment.amount = quote.Cash_Customer_Payment_Amount__c !=
      null
      ? Integer.valueOf(quote.Cash_Customer_Payment_Amount__c)
      : 0;
  }

  private static void setAddressInfo() {
    if (
      !String.isBlank(quote.SBQQ__Account__r.Name) &&
      !String.isBlank(quote.SBQQ__Account__r.BillingStreet) &&
      !String.isBlank(quote.SBQQ__Account__r.BillingCity) &&
      !String.isBlank(quote.SBQQ__Account__r.BillingStateCode) &&
      !String.isBlank(quote.SBQQ__Account__r.BillingPostalCode) &&
      !String.isBlank(quote.SBQQ__Account__r.Phone)
    ) {
      List<SBR_3_0_EditQuotesWrapper.AddressInfo> addressInfoList = new List<SBR_3_0_EditQuotesWrapper.AddressInfo>();
      SBR_3_0_EditQuotesWrapper.AddressInfo addressInfo = new SBR_3_0_EditQuotesWrapper.AddressInfo();
      addressInfo.address = new SBR_3_0_EditQuotesWrapper.Address();
      addressInfo.type = 'shippingAddress';
      addressInfo.address.name = quote.SBQQ__Account__r.Name;
      addressInfo.address.line1 = quote.SBQQ__Account__r.BillingStreet.toUpperCase();
      addressInfo.address.line2 = quote.SBQQ__Account__r.BillingStreet;
      addressInfo.address.city = quote.SBQQ__Account__r.BillingCity.toUpperCase();
      addressInfo.address.state = quote.SBQQ__Account__r.BillingStateCode.toUpperCase();
      addressInfo.address.country = quote.SBQQ__Account__r.BillingCountry.toUpperCase();
      addressInfo.address.zip = quote.SBQQ__Account__r.BillingPostalCode.toUpperCase();
      addressInfo.address.phoneNumber = quote.SBQQ__Account__r.Phone;
      addressInfoList.add(addressInfo);
      quoteEditWrapper.addressInfo = addressInfoList;
    }
  }

  private static void setPC() {
    quoteEditWrapper.pc = new SBR_3_0_EditQuotesWrapper.Pc();
    if (
      quote.Sourcing_Branch__c != null &&
      quote.Sourcing_Branch__r.Latitude_Longitude__Longitude__s != null &&
      quote.Sourcing_Branch__r.Latitude_Longitude__Latitude__s != null
    ) {
      quoteEditWrapper.pc.id = quote.Sourcing_Branch__r.Branch_Location_Number__c;
      if (quote.Sourcing_Branch__r?.Time_Zone_Id__c != null) {
        quoteEditWrapper.pc.timezoneName = quote.Sourcing_Branch__r
          ?.Time_Zone_Id__c;
      } else {
        User loggedInUser = SBR_3_0_UserDA.getUserById(UserInfo.getUserId());
        quoteEditWrapper.pc.timezoneName = loggedInUser?.TimeZoneSidKey;
      }
    } else {
      quoteEditWrapper.pc.id = quote.Branch__r.Branch_Location_Number__c;
      if (quote.Branch__r.Time_Zone_Id__c != null) {
        quoteEditWrapper.pc.timezoneName = quote.Branch__r.Time_Zone_Id__c;
      } else {
        User loggedInUser = SBR_3_0_UserDA.getUserById(UserInfo.getUserId());
        quoteEditWrapper.pc.timezoneName = loggedInUser?.TimeZoneSidKey;
      }
    }
  }

  private static void setJobsite() {
    quoteEditWrapper.jobsite = new SBR_3_0_EditQuotesWrapper.Jobsite();
    quoteEditWrapper.jobsite.address = new SBR_3_0_EditQuotesWrapper.Address();
    quoteEditWrapper.jobsite.jobsiteNumber = quote.Jobsite__r.Job_Number__c;
    quoteEditWrapper.jobsite.address.name = quote.Jobsite__r.Location.Name;
    quoteEditWrapper.jobsite.address.line1 = quote.Jobsite__r.Location.Street_Address__c.toUpperCase();
    quoteEditWrapper.jobsite.address.line2 = quote.Jobsite__r.Location.Street_Address_2__c;
    quoteEditWrapper.jobsite.address.city = quote.Jobsite__r.Location.City__c.toUpperCase();
    quoteEditWrapper.jobsite.address.state = quote.Jobsite__r.Location.State__c.toUpperCase();
    quoteEditWrapper.jobsite.address.country = quote.Jobsite__r.Location.Country__c.toUpperCase();
    quoteEditWrapper.jobsite.address.zip = quote.Jobsite__r.Location.Zip_Code__c.toUpperCase();
    quoteEditWrapper.jobsite.address.phoneNumber = quote.Jobsite__r.Job_Site_Contact__c !=
      null
      ? quote.Jobsite__r.Job_Site_Contact__c.replaceAll('[^0-9]', '')
      : null;
    quoteEditWrapper.jobsite.address.location = quote.Jobsite__r.Location.Name;
  }

  private static void setOrderedBy() {
    quoteEditWrapper.orderedBy = new SBR_3_0_EditQuotesWrapper.OrderedBy();
    String concatName =
      quote.Ordered_by__r.LastName +
      ', ' +
      quote.Ordered_by__r.FirstName;
    Integer maxSize = 20;
    if (concatName.length() > maxSize) {
      concatName = concatName.substring(0, maxSize);
    }
    quoteEditWrapper.orderedBy.name = concatName;
    quoteEditWrapper.orderedBy.phoneNumber = quote.Ordered_by__r.Phone;
    quoteEditWrapper.orderedBy.email = quote.Ordered_by__r.Email;
  }

  private static void groupOrderLines(List<SBQQ__QuoteLine__c> quoteItems) {
    quoteEditWrapper.products = new List<SBR_3_0_EditQuotesWrapper.Products>();
    quoteEditWrapper.salesItems = new List<SBR_3_0_EditQuotesWrapper.SalesItems>(); ////FRONT-13623
    for (SBQQ__QuoteLine__c quoteItemRec : quoteItems) {
      if (
        quoteItemRec.SBQQ__Product__r.Product_Type__c ==
        SBR_3_0_Constants.CAT_CLASS
      ) {
        setProduct(quoteItemRec);
      } else if (
        quoteItemRec.SBQQ__Product__r.Product_Type__c ==
        SBR_3_0_Constants.PARTS ||
        quoteItemRec.SBQQ__Product__r.Product_Type__c ==
        SBR_3_0_Constants.MERCHANDISE ||
        (quoteItemRec.is_User_Added__c &&
        (quoteItemRec.SBQQ__Product__r.Product_Type__c == 'MISC Charge Items' ||
        quoteItemRec.SBQQ__Product__r.Product_Type__c == 'Misc-Charge'))
      ) {
        setSalesItem(quoteItemRec);
      }
    }
  }

  private static void setProduct(SBQQ__QuoteLine__c quoteItem) {
    SBR_3_0_EditQuotesWrapper.Products product = new SBR_3_0_EditQuotesWrapper.Products();
    product.actualRates = new SBR_3_0_EditQuotesWrapper.ActualRates();
    product.rateSource = new SBR_3_0_EditQuotesWrapper.RateSource();
    if (quoteItem.RM_Quote_Line_Number__c != null) {
      product.rmLineNumber = quoteItem.RM_Quote_Line_Number__c?.intValue();
      product.action = String.isNotBlank(quoteItem.Action__c)
        ? quoteItem.Action__c
        : 'UPDATE';
    } else {
      product.action = String.isNotBlank(quoteItem.Action__c)
        ? quoteItem.Action__c
        : 'ADD';
    }
    product.sfLineNumber = String.valueOf(quoteItem.QuoteItemNumber__c);
    product.catId = quoteItem.SBQQ__Product__r.Category__c;
    product.classId = quoteItem.SBQQ__Product__r.Class__c;
    product.quantity = quoteItem.SBQQ__Quantity__c.intValue();
    product.hourRate = quoteItem.Hourly_Rate__c != null
      ? quoteItem.Hourly_Rate__c
      : 0;
    product.minimumRate = quoteItem.Min_Rate__c;
    product.equipmentId = quoteItem.SBQQ__Product__r.Bulk_Item__c
      ? quoteItem.SBQQ__Product__r?.itemNumberUsedByReservationsRentalOut__c
      : quoteItem.SBQQ__Product__r.Category__c +
        quoteItem.SBQQ__Product__r.Class__c; //SAL-24130
    product.discountPercent = quoteItem.Discount_Percentage__c;
    product.lineComment = quoteItem.Line_Comments__c;
    product.actualRates.day = quoteItem.Daily_Rate__c;
    product.actualRates.weekly = quoteItem.Weekly_Rate__c;
    product.actualRates.monthly = quoteItem.Monthly_Rate__c;
    product.rateSource.monthSrc = quoteItem.Month_Rate_source_code__c;
    product.rateSource.weekSrc = quoteItem.Week_Rate_Source_Code__c;
    product.rateSource.daySrc = quoteItem.Day_Rate_Source_Code__c;
    product.lineItemId = quoteItem.Id;
    product.freeFlag = quoteItem.Free_Flag__c ? 'Y' : 'N'; // FRONT-27346
    //FRONT-21013
    product.kitNumber = quoteItem.Kit_Number_This_Item_Belongs_To__c;
    if (String.isNotBlank(product.kitNumber)) {
      product.kitFlag = quoteItem.Kit_component_item_or_neither__c;
    }
    quoteEditWrapper.products.add(product);
  }

  //FRONT-13623
  private static void setSalesItem(SBQQ__QuoteLine__c quoteItem) {
    SBR_3_0_EditQuotesWrapper.SalesItems salesItem = new SBR_3_0_EditQuotesWrapper.SalesItems();
    if (quoteItem.RM_Quote_Line_Number__c != null) {
      salesItem.rmLineNumber = quoteItem.RM_Quote_Line_Number__c?.intValue();
      salesItem.action = String.isNotBlank(quoteItem.Action__c)
        ? quoteItem.Action__c
        : 'UPDATE';
    } else {
      salesItem.action = String.isNotBlank(quoteItem.Action__c)
        ? quoteItem.Action__c
        : 'ADD';
    }
    salesItem.sfLineNumber = String.valueOf(quoteItem.QuoteItemNumber__c);
    salesItem.itemNumber = quoteItem.SBQQ__Product__r.Item_Number__c;
    salesItem.quantity = quoteItem.SBQQ__Quantity__c.intValue();
    salesItem.stockClass = quoteItem.SBQQ__Product__r.Stock_class__c;
    salesItem.unitPrice = quoteItem.Selling_Price__c;
    salesItem.unitOfMeasure = quoteItem.Unit_of_Measure__c;
    salesItem.lineComment = quoteItem.Line_Comments__c;
    salesItem.freeFlag = quoteItem.Free_Flag__c ? 'Y' : 'N'; // FRONT-27346
    // salesItem.lineItemId = quoteItem.Id;
    quoteEditWrapper.salesItems.add(salesItem);
  }

  // COMMENTING THE BELOW CODE AS THE RATE VALIDATION STORIES ARE CURRENTLY UNTAGGED FROM THE SPRINT AND WILL COME IN FUTURE SPRINT

  // //FRONT-2185
  // public static SBR_3_0_EditQuotesWrapper getPayloadWrapper(SBQQ__Quote__c quoteInstance) {
  //     quoteEditWrapper = new SBR_3_0_EditQuotesWrapper();
  //     quote = quoteInstance;
  //     generateWrapper();
  //     return quoteEditWrapper;
  // }
}