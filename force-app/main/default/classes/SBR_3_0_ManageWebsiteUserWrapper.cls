public class SBR_3_0_ManageWebsiteUserWrapper {
	public Data data; 
    public Error error;
    public String token_type;
    public String expires_in;
    public String access_token;
    public String scope;
	public class Data {
        @AuraEnabled
		public String companyCode;
        @AuraEnabled
		public String accountNumber;
        @AuraEnabled
		public Users[] users;
        @AuraEnabled
		public String userType;
        @AuraEnabled
		public String firstName;
        @AuraEnabled
		public String lastName; 
        @AuraEnabled
		public String message; 
        @AuraEnabled
		public String userGuid; 
	}
    public class Error {
        @AuraEnabled
		public String message;
        @AuraEnabled
		public String errorKey;
        @AuraEnabled
		public String errorCode;
	}
	public class Users {
        @AuraEnabled
		public String firstName;
        @AuraEnabled
		public String lastName;
        @AuraEnabled
		public String email;
        @AuraEnabled
		public String lastLoginDateTime;
	}
	public static SBR_3_0_ManageWebsiteUserWrapper parse(String json){
        return (SBR_3_0_ManageWebsiteUserWrapper) System.JSON.deserialize(json, SBR_3_0_ManageWebsiteUserWrapper.class);
    }
}