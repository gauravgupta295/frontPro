/*********************************************************************************************************************
* Apex Class: SBR_3_0_WrapContract
----------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Wrapper class to generate the Create Contract API Payload
----------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
1.0             Nilesh Jaiswal          2024-05-27          Initial version   
*********************************************************************************************************************/
public without sharing class SBR_3_0_WrapContract {
  public String companyId;
  public String sfOrderId;
  public String cartId;
  public String sellingChannel;
  public String initiatingChannel;
  public String rentalmanUser;
  public String startDateTime;
  public String endDateTime;
  public String comments;
  public String marketSegment;
  public Customer customer;
  public Pc pc;
  public Jobsite jobsite;
  public SalesRepInfo salesRepInfo;
  public Payment payment;
  public DeliveryInfo deliveryInfo;
  public ReturnInfo returnInfo;
  public OrderedBy orderedBy;
  public Billings billings;
  public List<AddressInfo_Z> addressInfo;
  public AdditionalInfo additionalInfo;
  public List<Products> products;
  public List<SalesItems> salesItems;
  public List<MiscItems> miscItems;
  public String reservationNumberToBeConverted;

  public class AdditionalInfo {
    public Integer territoryNumber;
    public String withinCityLimits;
    public String sourceCode;
    public String systemName;
  }

  public class Products {
    public String sfLineNumber;
    public String catId;
    public String classId;
    public Integer quantity = 0;
    public String equipmentNumber;
    public Double minimumRate;
    public Double hourRate;
    public Double dayRate;
    public Double weekRate;
    public Double monthRate;
    public Double discountPercent;
    public String dayRateOverrideCode;
    public String weekRateOverrideCode;
    public String monthRateOverrideCode;
    public Double mileageMeterReadingOut;
    public String startDateTime;
    public Integer numberOfCreditDays = 0;
    public Double numberOfCreditHours;
    public String creditReasonCode;
    public String freeFlag;
    public String lineComment;
    public Integer rmLineNumber;
    public String requestedCatId;
    public String requestedClassId;
    public String kitFlag;
    public String kitNumber;
  }

  public class Address {
    public String line1;
    public String line2;
    public String city;
    public String state;
    public String country;
    public String zip;
    public String phoneNumber;
    public String location;
  }

  public class Customer {
    public String accountNumber;
    public String driverLicenseState;
    public String driverLicenseNumber;
    public String name;
    public List<AddressInfo> addressInfo;
    public Integer socialSecurityNumber;
    public Integer dateOfBirth;
    public String employedBy;
    public String workPhoneNumber;
    public String vehicleLicensePlateNumber;
    public String vehicleLicensePlateState;
    public String webCashFirstName;
    public String webCashLastName;
    public String webCashDlState;
    public String webCashDlNumber;
    public Integer webCashDlExpireDate;
    public Integer webCashDob;
  }

  public class OrderedBy {
    public String name;
    public String phoneNumber;
    public String email;
  }

  public class AddressInfo_Z {
    public String type;
    public Address_Z address;
  }

  public class DeliveryInfo {
    public String fulfillmentType;
    public String deliveryInstructions;
  }

  public class AddressInfo {
    public String type;
    public Address address;
  }

  public class Payment {
    public String method;
    public Double amount;
    public String creditCardLane;
    public String checkNumber;
  }

  public class Billings {
    public String poNumber;
    public Double deliveryCharge;
    public Double pickUpCharge;
    public String chargeRentalProtectionPlan;
  }

  public class Pc {
    public String id;
    public String timezoneName;
  }

  public class SalesRepInfo {
    public String primarySalesRepId;
    public String secondarySalesRepId;
  }

  public class MiscItems {
    public String sfLineNumber;
    public String itemNumber;
    public String stockClass;
    public String productSku;
    public String type;
    public Double charge;
    public Double tax;
    public Boolean taxExempt;
    public Boolean nonTaxable;
    public Double itemTaxRate;
    public Integer rmLineNumber;
    public String freeFlag;
    public Integer quantity;
    public Double unitPrice;
    public String unitOfMeasure;
    public String lineComment;
  }

  public class Address_Z {
    public String name;
    public String line1;
    public String line2;
    public String city;
    public String state;
    public String country;
    public String zip;
    public String phoneNumber;
  }

  public class ReturnInfo {
    public String returnType;
  }

  public class SalesItems {
    public Integer rmLineNumber;
    public String sfLineNumber;
    public String itemNumber;
    public String stockClass;
    public String freeFlag;
    public Integer quantity;
    public Double unitPrice;
    public String unitOfMeasure;
    public String lineComment;
  }

  public class Jobsite {
    public String jobsiteNumber;
    public Address address;
  }
}