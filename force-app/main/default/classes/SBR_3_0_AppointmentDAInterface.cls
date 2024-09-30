/*********************************************************************************************************************
* Apex Class: SBR_3_0_AppointmentDAInterface
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Interface class for Appointment Data Access
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Kunal Patel           2022-03-15            Initial version    
*********************************************************************************************************************/
public interface SBR_3_0_AppointmentDAInterface {
    Event getAppointment(Id id);
    Map<Id, Event> getAppointments(Set<Id> ids);
    List<Event> getAppointmentsByOwner(Id id);
    Map<Id, List<Event>> getAppointmentsByOwners(Set<Id> ids);
    List<Event> getAppointmentsFiltered(SBR_3_0_GoogleMapCmpController.FilterWrapper wrapper);
    String inClausify(Set<Id> ids);
}