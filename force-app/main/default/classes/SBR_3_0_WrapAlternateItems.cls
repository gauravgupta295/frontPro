public with sharing class SBR_3_0_WrapAlternateItems {

    /********************************************************************************************************************************************************/
    //AlternateItems REQUEST 
    /********************************************************************************************************************************************************/
    public class ATIRequest {

		// public String companyId; // Per SAL-23555, we are moving companyId to request header
        public String cartId;
        public String sellingChannel;
		Public String timezoneId;
		public String requestedDeliveryDate; // optional
		public String transactionType;
		public String fulfillmentType;
		public Boolean includeZeroATP;
		//public Integer limitBranchByDistanceCount; // optional
		public String locationType; // optional
		public Double latitude;
		public Double longitude;
		public List<Products> products;
    }
    public class Products {
		public String productId;
		public String uom;
	}

    /********************************************************************************************************************************************************/
    // AlternateItems RESPONSE
    /********************************************************************************************************************************************************/
    public class ATIResponse{
        public Data data;
    }

	public class Data {
		public String cartId;
		public String companyId;
		public String sellingChannel;
		public List<AvailabilityByTransactionType> availabilityByTransactionType;
	}

	public class AvailabilityByTransactionType {
		public String transactionType;
		public String lastResortBranch;
		public List<AvailabilityByProduct> availabilityByProducts;
	}

	public class AvailabilityByProduct {
		public String productId;
		public String uom;
		public List<AvailabilityByFulfillmentType> availabilityByFulfillmentTypes; 
	}

	public class AvailabilityByFulfillmentType {
		public String fulfillmentType;
		public List<AvailabilityDetail> availabilityDetails;
	}

	public class AvailabilityDetail {
		public List<AvailabilityByLocation> availabilityByLocations;
	}

	public class AvailabilityByLocation {
		public String locationId;
		public String locationType;
		public Double atp;
		public String geoDistanceFromJobSite;
	}
}