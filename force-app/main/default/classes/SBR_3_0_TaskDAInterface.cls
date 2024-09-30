/*********************************************************************************************************************
* Apex Class: SBR_3_0_TaskDAInterface
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Interface class for Task Data Access
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Kunal Patel             2022-07-20          Initial version    
*********************************************************************************************************************/
public interface SBR_3_0_TaskDAInterface {
    List<Task> getTasks();
    List<Task> getTasksByOwner(Id ownerId);
    Task getTask(Id id);
    List<Task> getTasksFiltered(SBR_3_0_GoogleMapCmpController.FilterWrapper wrapper);
    String inClausify(Set<Id> ids);
}