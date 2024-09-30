/*****************************************************************************************************************
* Apex Class: SBR_3_0_ServiceResourceDAInterface
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Interface for SBR_3_0_ServiceResourceDA class
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION       DATE               DETAIL FEATURES
    1.0          2023-02-23          Initial version        
*********************************************************************************************************************/
public interface SBR_3_0_ServiceResourceDAInterface {
    Id getServiceResourceIdFromWorkOrderId(Id workOderId);
    List<ServiceResource> getServiceResourceById(Id serviceResId);
    Boolean validateLoggedInResourcePermissionSetGroup(Id userId,String psgApiName);
    List<ServiceTerritoryMember> getServiceResourcePrimaryTerittory(Id usrId);

}