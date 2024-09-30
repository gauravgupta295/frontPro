public with sharing class SBR_3_0_WrapInventoryAtBranch {

    /********************************************************************************************************************************************************/
    //InventoryAtBranch REQUEST
    /********************************************************************************************************************************************************/

    public class ATPRequest {
        @AuraEnabled
        public String orgId; // new
        @AuraEnabled
        public String cartId; // new
        @AuraEnabled
        public String requestedDeliveryDate;
        @AuraEnabled
        public String fulfillmentType;
        //@AuraEnabled
        //public String transactionType; // new
        @AuraEnabled
        public String sellingChannel; // new
        @AuraEnabled
        public String locationType; // new
        @AuraEnabled
        public Boolean includeZeroATP; // new
        @AuraEnabled
        public Integer limitBranchByDistanceCount; // new
         @AuraEnabled
        public String timezoneId; // new
        @AuraEnabled
        public List<Products> products; // new
        @AuraEnabled
        public Double latitude; // new
        @AuraEnabled
        public Double longitude; // new
    }

	public class OrderLines {
        @AuraEnabled
		public List<Products> products;
	}

    public class Products {
		public String productId;
		public String uom;
	}

    public class ATPResponse {
        @AuraEnabled
        public String orgId;
        @AuraEnabled
        public String sellingChannel;
        @AuraEnabled
        public String transactionType;
        @AuraEnabled
        public String cartId;
        @AuraEnabled
        public String closestBranchSite;
        @AuraEnabled
        public String lastResortBranch;
        @AuraEnabled
        public List<AvailabilityByProducts> availabilityByProducts;
    }   

	public class AvailabilityByProducts {
        @AuraEnabled
		public String productId;
        @AuraEnabled
		public String uom;
        @AuraEnabled
		public List<AvailabilityByFulfillmentTypes> availabilityByFulfillmentTypes;
	}

   
    public class AvailabilityByFulfillmentTypes {
        @AuraEnabled
		public String fulfillmentType;
        @AuraEnabled
		public List<AvailabilityDetails> availabilityDetails;
	}

	public class AvailabilityDetails {
        @AuraEnabled
		public List<AvailabilityByLocations> availabilityByLocations;
	}

	public class AvailabilityByLocations {
        @AuraEnabled
		public String locationId; // new
        @AuraEnabled
		public String locationType; // new
        @AuraEnabled
		public Double atp;
        @AuraEnabled
		public String geoDistanceFromJobSite; // new
	}
}