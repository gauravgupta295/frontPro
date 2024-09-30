/*********************************************************************************************************************
* Apex Class: SBR_3_0_LeadDAInterface
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Interface class for Lead Data Access
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Kunal Patel           2022-02-09            Initial version    
*********************************************************************************************************************/
public interface SBR_3_0_LeadDAInterface {
    LeadStatus getLeadStatus(String status);
    List<Lead> getLeads();
    List<Lead> getLeadsByIds(Set<Id> leadIds);
    Map<Id, Lead> getLeadsMap(Set<Id> leadIds);
    List<Lead> getLeadsLatLongStatus(Set<Id> leadIds);
    Lead getLead(Id id);
    List<Lead> getLeadsFiltered(SBR_3_0_GoogleMapCmpController.FilterWrapper wrapper);
    String inClausify(Set<Id> ids);
}