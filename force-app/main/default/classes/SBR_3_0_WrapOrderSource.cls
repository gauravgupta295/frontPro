/*********************************************************************************************************************
* Apex Class: SBR_3_0_WrapOrderSource
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Wrapper class for SBR_3_0_API_ReservationSourcingCall
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Aditee Churiwala        2023-01-27             Initial version    
*********************************************************************************************************************/
public class SBR_3_0_WrapOrderSource {

    public String companyId;
    public String cartId;
    public Decimal cartTotal;
    public String cartType;
    //public String customerType;
    public String sellingChannel;
    public Jobsite jobsite;
	public PC pc;
    public List<Products> products;
	public List<SalesItems> salesItems;
    public String fulfillmentService;
    public String fulfillmentType;
    //public Boolean overrideDistance;
    public String sourceSystem;
    
    public class Products {
        public String requestedDeliveryDate;
		public String lineId;
		public String uom;
        public Integer quantity;
		public String productId;
		public String productType;
		public String catId;
	    public String classId;
	}
    public class Address {
		public String line1;
		public String line2;
		public String city;
		public String state;
		public String country;
		public String zip;
	}

	public class Jobsite {
		public Decimal latitude;
		public Decimal longitude;
		public Address address;
		public String timezoneId;
	}

    public class PC {
        public String id;
	}

    public class SalesItems {
		public String itemNumber;
		public String stockClass;
		public Integer quantity;
		public Double unitPrice;
	}
	//Added for FRONT-30844
	public static SBR_3_0_WrapOrderSource parse(String json){
        return (SBR_3_0_WrapOrderSource) System.JSON.deserialize(json, SBR_3_0_WrapOrderSource.class);
    }
}