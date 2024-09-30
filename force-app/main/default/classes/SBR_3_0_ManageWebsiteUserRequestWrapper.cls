public class SBR_3_0_ManageWebsiteUserRequestWrapper {
	public boolean overideNonCredit;
    public Integer accountNumber;
    public String accountName;
    public Customer customer; 
    public Requester requester; 
	public class Customer {
        @AuraEnabled
		public String email;
        @AuraEnabled
		public String firstName;
        @AuraEnabled
		public String lastName;
        @AuraEnabled
		public Boolean isAdmin;
    }
    public class Requester {
        @AuraEnabled
		public String email;
        @AuraEnabled
		public String firstName;
        @AuraEnabled
		public String lastName;
        @AuraEnabled
		public Integer employeeId;
    }
    public static SBR_3_0_ManageWebsiteUserRequestWrapper parse(String json){
        return (SBR_3_0_ManageWebsiteUserRequestWrapper) System.JSON.deserialize(json, SBR_3_0_ManageWebsiteUserRequestWrapper.class);
    }
}