/**
 * @description       :
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             :
 * @last modified on  : 11-22-2022
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
 **/
public with sharing class SBR_3_0_WrapOrder {
  public class SuggestedRates {
    public Double day = 0;
    public Double weekly = 0;
    public Double monthly = 0;
  }

  public class Products {
    public transient Id lineItemId; //Added as part FRONT-9280, used trasient so that it won't include in the request
    public Integer rmLineNumber;
    public String equipmentId;
    public String catId;
    public String classId;
    public Integer quantity = 0;
    public String freeFlag;
    public String toolFlex;
    public Double hourRate = 0;
    public Double minimumRate = 0;
    public SuggestedRates suggestedRates;
    public SuggestedRates actualRates;
    public String dayRateOverride;
    public String weeklyRateOverride;
    public String monthlyRateOverride;
    public String lineComment;
    public String sfLineNumber;
    public String action;
    public String kitFlag;
    public String kitNumber;
  }

  public class Pc {
    public String id;
    public String timezoneName;
    public String timezone;
  }
  public class OrderedBy {
    public String name;
    public String phoneNumber;
    public String email;
  }
  public String rentalmanUser;

  public Integer companyId;
  public String chronos;
  public String userType;
  public Pc pc;
  public OrderedBy orderedBy;
  public String convertQuoteToOrder;
  public String sfQuoteId;
  public String rmQuoteId;
  public String sfOrderId;
  public String accountNumber;
  public String sfAccountNumber;
  public String driverLicenseState;
  public String driverLicenseNumber;
  public String fulfillmentType;
  public String deliveryInstructions;
  public String startDateTime;
  public String endDateTime;
  public String earliestDateTime;
  public String poNumber;
  public String chargeRentalProtectionPlan;    //SF-7224 changes as per: FRONT-30293,FRONT-30294
  public String optOutRPP;
  public String optOutFuelCharge;
  public Double deliveryCharge = 0;
  public String email;
  public String phoneNumber;
  public String sellingChannel;
  public String initiatingChannel;
  public String primarySalesRepId;
  public String createdBy;
  public Jobsite jobsite;
  public Double pickUpCharge = 0;
  public List<Products> products;
  public List<SalesItems> salesItems;
  public List<MiscItems> miscItems;

  public class Address {
    public String name;
    public String line1;
    public String line2;
    public String city;
    public String state;
    public String country;
    public String zip;
    public String phoneNumber;
    public String location;
    public Integer distance = 0;
  }

  public class Jobsite {
    public String id;
    public String jobsiteNumber;
    public Address address;
  }

  public class MiscItems {
    public String type;
    public Double charge = 0;
    public Double tax = 0;
    public Boolean taxExempt;
    public Boolean nonTaxable;
    public Double itemTaxRate = 0;
    public String itemNumber;
    public String stockClass;
    public String sfLineNumber;
    public String productSku;
  }

  public class SalesItems {
    public transient Id lineItemId;
    public String itemNumber;
    public String stockClass;
    public Integer quantity = 0;
    public Double unitPrice = 0;
    public String unitOfMeasure;
    public String sfLineNumber;
    public String lineComment;
    public Integer rmLineNumber;
    public String action;
    public String freeFlag; //FRONT-27716
  }

  /*START FRONT-4030,10316,10259*/
  public String marketSegment;
  public Integer territoryNumber;
  public String leaveFacilityDate;
  public String installStartDate;
  public String dismantleStartDate;
  public String systemName;
  public String useCodeA;
  public String deliveredBy;
  public String withinCityLimits;
  public String invoiceDueDateCode;
  public String paymentCode;
  public String rewardNumber;
  public String signature;
  public String printYOrN;
  public String faxEmail;
  public String pickedUpBy;
  public Boolean pickUp;
  public Payment payment;
  public List<AddressInfo> addressInfo;
  public String returnType; //FRONT-29567

  public class Payment {
    public String method;
    public Decimal amount;

    //Added for  FRONT- 14560
    public String creditCardLane;
    public String checkNumber;
  }
  public class AddressInfo {
    public String type;
    public Address address;
  }
  public String reservationId;
  /*END FRONT-4030,10316,10259*/
}