/*********************************************************************************************************************
* Apex Class: SBR_3_0_OpportunityDAInterface
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Interface class for Opportunity Data Access
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Kunal Patel             2022-07-19          Initial version    
*********************************************************************************************************************/
public interface SBR_3_0_OpportunityDAInterface {
    Map<Id, Opportunity> getOpportunities(Set<Id> ids);
    List<Opportunity> getOpportunities();
    Opportunity getOpportunity(Id id);
    List<Opportunity> getOpportunityFiltered(SBR_3_0_GoogleMapCmpController.FilterWrapper wrapper);
}