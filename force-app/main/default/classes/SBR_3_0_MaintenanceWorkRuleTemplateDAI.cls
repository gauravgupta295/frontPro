/*********************************************************************************************************************
* Apex Class: SBR_3_0_MaintenanceWorkRuleTemplateDAI
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Methods for accessing and updating Maintenance Work Rule Template records to simplify data mocking
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME                      DATE                 DETAIL FEATURES
    1.0         Evan Kuminski, Salesforce           2023-12-04           Initial version
*********************************************************************************************************************/

public interface SBR_3_0_MaintenanceWorkRuleTemplateDAI {
    List<SVMXA360__MaintenanceWorkRuleTemplate__c> upsertMaintenanceWorkRuleTemplates(List<SVMXA360__MaintenanceWorkRuleTemplate__c> maintenanceWorkRuleTemplates);
    List<SVMXA360__MaintenanceWorkRuleTemplate__c> getByInspectionTemplateIds(Set<Id> inspectionTemplateIds);
}