/*********************************************************************************************************************
* Apex Class: SBR_3_0_EqpMaintenanceStepDAI
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Methods for accessing Eqp Maintenance Step records
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME                      DATE                 DETAIL FEATURES
    1.0         Evan Kuminski, Salesforce           2023-10-19           Initial version
*********************************************************************************************************************/

public interface SBR_3_0_EqpMaintenanceStepDAI {
    List<SM_PS_Eqp_Maintenance_Step__c> getAllFieldsByInspectionTemplateIds(Iterable<Id> inspectionTemplateIds);
}