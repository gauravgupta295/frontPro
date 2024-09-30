public with sharing class SBR_3_0_WrapQuote {
    public class SuggestedRates {
        public Double day;
        public Double weekly;
        public Double monthly;
    }
    public class Products {
        public String equipmentId;
        public String catId;
        public String classId;
        public Integer quantity;
        public String freeFlag;
        public String toolFlex;
        public Double hourRate;
        public Double minimumRate;
        public SuggestedRates suggestedRates;
        public SuggestedRates actualRates;
        public String dayRateOverride;
        public String weeklyRateOverride;
        public String monthlyRateOverride;
        public String lineComment;
        public String sfLineNumber;
    }
    public class Pc {
        public String id;
        public String timezoneName;
    }
    public class OrderedBy{
        public String name;
        public String phoneNumber;
        public String email;
    }

    public String chronos;
    public String userType;
    public Pc pc;
    public OrderedBy orderedBy;
    public String sfQuoteId;
    public String accountNumber;
    public String sfAccountNumber;
    public String driverLicenseState;
    public String driverLicenseNumber;
    public String deliveryInstructions;
    public String startDateTime;
    public String endDateTime;
    public String earliestDateTime;
    public String poNumber;
    public String chargeRentalProtectionPlan;    //SF-7224 changes as per: FRONT-30293,FRONT-30294
    public String optOutRPP;
    public String optOutFuelCharge;
    public Double deliveryCharge;
    //public String email;
    //public String phoneNumber ;
    public String sellingChannel;
    public String primarySalesRepId;
    public Jobsite jobsite;
    public Double pickUpCharge;
    public String initiatingChannel;
    public String fulfillmentType;
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
        public Integer distance;
    }
    public class Jobsite {
        public String id;
        public String jobsiteNumber;
        public Address address;
    }
    public class MiscItems {
        public String type;
        public double charge;
        public double tax;
        public Boolean taxExempt;
        public Boolean nonTaxable;
        public Double itemTaxRate;
        public String itemNumber;
        public String stockClass;
        public String sfLineNumber;
        public String productSku;
    }
    public class SalesItems {
        public String itemNumber;
        public String stockClass;
        public Integer quantity;
        public Double unitPrice;
        public String sfLineNumber;
    }
}