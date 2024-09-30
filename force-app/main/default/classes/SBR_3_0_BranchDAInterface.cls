/*********************************************************************************************************************
* Apex Class: SBR_3_0_BranchDAInterface
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Interface class for Branch/Location/Profit Center Data Access
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Kunal Patel           2022-04-12            Initial version
    2.0         Konrad Haight         2022-05-26            Added getLocationsByIds      
*********************************************************************************************************************/
public interface SBR_3_0_BranchDAInterface {
    Map<Id, Schema.Location> getBranches();
    Map<Id, Schema.Location> getLocationsByIds(Set<Id> locationIds);
    Map<Id, Schema.Location> getLocationReadinessFields(Set<Id> locationIds);
    List<Schema.Location> getBranchesFiltered(SBR_3_0_GoogleMapCmpController.FilterWrapper wrapper);
    Schema.Location getLocation(Id id);
    Map<String,Schema.Location> getBranchByNumbers(Set<String> branchNumbers);
}