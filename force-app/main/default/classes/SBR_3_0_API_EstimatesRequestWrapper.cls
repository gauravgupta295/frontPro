/*********************************************************************************************************************
* Apex Class: SBR_3_0_API_EstimatesRequestWrapper
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Request Wrapper class for Estimates API
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Kunal Patel          2022-11-17             Initial version    
*********************************************************************************************************************/
public class SBR_3_0_API_EstimatesRequestWrapper {

    public String companyCode;
    public String orderType;
    public List<PC> pc;
    public String jobNumber;
    public Integer account;
    public String driverLicenseState;
    public String driverLicenseNumber;
    public String startDateAndTime;
    public String endDateAndTime;
    //public Integer distance;
    public String ratesToBeUsed;
    public List<Delivery> delivery;
    public List<Pickup> pickup;
    public List<OrderLine> orderLines;
    public List<Address> address;

    public class PC {
        public Integer id;
        public Decimal latitude;
        public Decimal longitude;
        public String timezone;
    }

    public class Address {
        public String type;
        public String line1;
        public String city;
        public String state;
        public String zip;
        public Decimal latitude;
        public Decimal longitude;
    }

    public class Delivery {
        public Boolean chargesOverride;
        public String charges;
    }

    public class Pickup {
        public Boolean chargesOverride;
        public String charges;
    }

    public class OrderLine {
        public List<SalesItem> salesItems;
        public List<Product> products;
    }

    public class SalesItem {
        public String itemNumber;
        public String stockClass;
        public Decimal unitPrice;
        public Integer quantity;
    }

    public class Product {
        public String catId;
        public String classId;
        public Integer quantity;
        public Rate rates;
    }

    public class Rate {
        public Boolean override_x;
        public String hourly;
        public String minimum;
        public String daily;
        public String weekly;
        public String monthly;
    }
}