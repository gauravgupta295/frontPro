/*********************************************************************************************************************
* Apex Class: SBR_3_0_EditQuotesWrapper 
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Wrapper class for creating request for edit quote scenario 
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
1.0             Neeraj Kumar          2023-12-11            Initial version    
*********************************************************************************************************************/
public class SBR_3_0_EditQuotesWrapper {
  public String sfQuoteId;
  public String sellingChannel;
  public String initiatingChannel;
  public String rentalmanUser;
  public String accountNumber;
  public String sfAccountNumber;
  public String userType;
  public String poNumber;
  public String fulfillmentType;
  public String driverLicenseState;
  public String driverLicenseNumber;
  public String returnType;
  public String startDateTime;
  public String endDateTime;
  public String earliestDateTime;
  public String primarySalesRepId;
  public Integer territoryNumber;
  public String useCodeA;
  public String preBillRentals;
  public String proRateRentals;
  public String billingIndicator;
  public Double dayOfMonthToBillOn;
  public String printRatesOnContracts;
  public String optOutRPP;
  public String chargeRentalProtectionPlan;    //FRONT-30293,30294
  public String marketSegment;
  public String withinCityLimits;
  public String sourceCode;
  public String invoiceDueDateCode;
  public String paymentCode;
  public String billingCode;
  public String rewardNumber;
  public String signature;
  public String printYOrN;
  public String faxEmail;
  public String leaveFacilityDate;
  public String installStartDate;
  public String dismantleStartDate;
  public String comments;
  public Decimal deliveryCharge;
  public String deliveryDate;
  public String deliveryInstructions;
  public String deliveredBy;
  public String cartId;
  public OrderedBy orderedBy;
  public String pickedUpBy;
  public Boolean pickUp;
  public Pc pc;
  public Jobsite jobsite;
  public List<Products> products;
  public List<AddressInfo> addressInfo;
  public List<SalesItems> salesItems;

  public class OrderedBy {
    public String phoneNumber;
    public String name;
    public String email;
  }

  public class Pc {
    public String timezoneName;
    public String id;
  }

  public class Jobsite {
    public String jobsiteNumber;
    public Address address;
  }

  public class Address {
    public String name;
    public String line1;
    public String line2;
    public String city;
    public String state;
    public String country;
    public String zip;
    public String location;
    public String phoneNumber;
  }

  public class AddressInfo {
    public String type;
    public Address address;
  }

  public class Products {
    public transient Id lineItemId; //Added as part FRONT-2185, used trasient so that it won't include in the request
    public Decimal rmLineNumber;
    public String action;
    public String sfLineNumber;
    public String catId;
    public String classId;
    public Integer quantity;
    public Decimal hourRate;
    public Decimal minimumRate;
    public String equipmentId;
    public Decimal discountPercent;
    public String lineComment;
    public ActualRates actualRates;
    public RateSource rateSource;
    public String kitFlag; //FRONT-21013
    public String kitNumber; //FRONT-21013
    public String freeFlag; //FRONT-27346
  }

  public class ActualRates {
    public Decimal weekly;
    public Decimal monthly;
    public Decimal day;
  }

  public class RateSource {
    public String monthSrc;
    public String weekSrc;
    public String daySrc;
  }

  public Payment payment;
  public class Payment {
    public String method;
    public Integer amount;
  }

  //FRONT-13623
  public class SalesItems {
    public transient Id lineItemId;
    public Integer rmLineNumber;
    public String sfLineNumber;
    public String itemNumber;
    public Integer quantity;
    public String stockClass;
    public Decimal unitPrice;
    public String unitOfMeasure;
    public String lineComment;
    public String action;
    public String freeFlag; //FRONT-27346
  }
}