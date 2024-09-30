public class SBR_3_0_MWUAccountEmailSearchWrapper {
	public Data data; 
    public Error error;
	public class Data {
        @AuraEnabled
		public Users[] users;
	}
    public class Users {
        @AuraEnabled
		public String email;
    }
    public class Error {
        @AuraEnabled
		public String message;
        @AuraEnabled
		public String errorKey;
        @AuraEnabled
		public String errorCode;
	}
	public static SBR_3_0_MWUAccountEmailSearchWrapper parse(String json){
        return (SBR_3_0_MWUAccountEmailSearchWrapper) System.JSON.deserialize(json, SBR_3_0_MWUAccountEmailSearchWrapper.class);
    }
}