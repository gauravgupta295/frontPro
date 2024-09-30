/*********************************************************************************************************************
* Apex Class: SBR_3_0_ProjectDAInterface
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Interface class for Project Data Access
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Kunal Patel           2022-03-18            Initial version    
*********************************************************************************************************************/
public interface SBR_3_0_ProjectDAInterface {
    Map<Id, Project__c> getProjects(Set<Id> ids);
    List<Project__c> getProjects();
    Project__c getProject(Id id);
    List<Project__c> getProjectsFiltered(SBR_3_0_GoogleMapCmpController.FilterWrapper wrapper);
    List<String> getUsersProjectDodgeTypes(Id userId);
    List<String> getUsersProjectDodgePhases(Id userId);
    Decimal getUsersProjectMinValuation(Id userId);
    Boolean canUserViewPECProject(Id userId);
    Map_Default_Filter__mdt getMapDefaultFilter(String analysisRegionKey, String repType);
    String inClausify(Set<String> stringSet);
}