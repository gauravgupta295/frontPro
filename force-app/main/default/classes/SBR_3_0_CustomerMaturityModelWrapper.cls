public with sharing class SBR_3_0_CustomerMaturityModelWrapper {
    public Data data; 
    public Error error;
    public String access_token;
	public class Data {
        @AuraEnabled
		public String companyKey;
        @AuraEnabled
		public String customerKey;
        @AuraEnabled
		public Products[] products;
    }
    public class Error {
        @AuraEnabled
		public String message;
        @AuraEnabled
		public String errorKey;
        @AuraEnabled
		public String errorCode;
	}
    public class Products {
        @AuraEnabled
		public String productRating;
        @AuraEnabled
		public String productScore;
        @AuraEnabled
		public String productRecordType;
        @AuraEnabled
		public String catClass;
        @AuraEnabled
		public String catClassDescription;
        @AuraEnabled
		public String productCategoryDesc;
        @AuraEnabled
		public String productLineOfBusiness;
        @AuraEnabled
		public String productLineOfBusinessValue;
        @AuraEnabled
		public String productRecommendationType;
        @AuraEnabled
		public String productModelVersion;
        @AuraEnabled
		public String productUsedRating;
        @AuraEnabled
		public String productUsedQty;
    }
    public static SBR_3_0_CustomerMaturityModelWrapper parse(String json){
        return (SBR_3_0_CustomerMaturityModelWrapper) System.JSON.deserialize(json, SBR_3_0_CustomerMaturityModelWrapper.class);
    }
}