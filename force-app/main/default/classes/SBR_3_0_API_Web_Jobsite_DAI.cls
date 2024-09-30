public interface SBR_3_0_API_Web_Jobsite_DAI {
    Account getRelatedAccount(String rmAccountNumber);
    Schema.Location getRelatedBranchLocation(String branchNumber);
    Schema.Location getRelatedJobLocation(String street1, String city, String state, String zip, String country, Decimal latitude, Decimal longitude);
}