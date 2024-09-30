public with sharing class SBR_3_0_WrapInventorySources {

 /********************************************************************************************************************************************************/
    //InventorySources REQUEST
    /********************************************************************************************************************************************************/


    public class ATSRequest {
        public String companyId;
        public String cartId;
        public Double cartTotal;
        public String cartType;
        public String customerType;
        public String sellingChannel;
        public Jobsite jobsite;
        public List<Products> products;
        public List<SalesItems> salesItems;
        public String fulfillmentService;
        public String fulfillmentType;
        public Boolean overrideDistance;
        public String sourceSystem;
    }

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
		public String country;
		public String state;
		public String city;
		public String zip;
	}

	public class Jobsite {
		public Double latitude;
		public Double longitude;
		public Address address;
	}

	public class SalesItems {
		public String itemNumber;
		public String stockClass;
		public Integer quantity;
		public Integer unitPrice;
	}

 /********************************************************************************************************************************************************/
    //InventorySources RESPONSE
    /********************************************************************************************************************************************************/


    public class ATSResponse {
        public Data data;
    }
    
    public class Data {
            public String pc;
            public Double latitude;
            public Double longitude;
            public String companyId;
            public Boolean isLastResortBranch;
            public Double fulfillmentPercent;
    }
    

}