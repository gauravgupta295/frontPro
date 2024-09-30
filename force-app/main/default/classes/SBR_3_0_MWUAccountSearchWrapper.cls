public class SBR_3_0_MWUAccountSearchWrapper {
	public Data data; 
    public Error error;
	public class Data {
        @AuraEnabled
		public String email;
        @AuraEnabled
		public String firstName;
        @AuraEnabled
		public String lastName; 
        @AuraEnabled
		public Address address;
        @AuraEnabled
		public String driverlicenseNumber; 
        @AuraEnabled
		public String driverlicenseState; 
        @AuraEnabled
		public String accountType; 
        @AuraEnabled
		public Accounts[] accounts;
	}
    public class Error {
        @AuraEnabled
		public String message;
        @AuraEnabled
		public String errorKey;
        @AuraEnabled
		public String errorCode;
	}
	public class Address{
        @AuraEnabled
		public String line1;
        @AuraEnabled
		public String line2;
        @AuraEnabled
		public String line3;
        @AuraEnabled
		public String city;
        @AuraEnabled
		public String state;
        @AuraEnabled
		public String postalCode;
        @AuraEnabled
		public String phone;
	}
    public class Accounts{
        @AuraEnabled
		public String accountNumber;
        @AuraEnabled
		public String accountName;
        @AuraEnabled
		public String corpLinkNumber;
	}
	public static SBR_3_0_MWUAccountSearchWrapper parse(String json){
        return (SBR_3_0_MWUAccountSearchWrapper) System.JSON.deserialize(json, SBR_3_0_MWUAccountSearchWrapper.class);
    }
}