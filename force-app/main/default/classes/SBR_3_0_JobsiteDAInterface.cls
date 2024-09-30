/*********************************************************************************************************************
* Apex Class: SBR_3_0_JobsiteDAInterface
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Interface class for Jobsite Data Access
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Kunal Patel           2022-05-04            Initial version    
    1.2         Viren Patel           2022-09-06            Added getRelatedAccount, getRelatedJobLocation, getRelatedBranchLocation
*********************************************************************************************************************/
public interface SBR_3_0_JobsiteDAInterface {
    List<AssociatedLocation> getJobsitesByAccounts(Set<Id> accIds);
    Account getRelatedAccount(String rmAccountNumber);
    Schema.Location getRelatedJobLocation(SBR_3_0_WrapAddress a);
    Schema.Location getRelatedBranchLocation(String branchNumber, String cc);
    List<AssociatedLocation> getJobSitesFiltered(SBR_3_0_GoogleMapCmpController.FilterWrapper wrapper);
    String inClausify(Set<Id> ids);
}