/*********************************************************************************************************************
* Apex Class: SBR_3_0_MaintenanceWorkRuleTemplateDA
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Methods for accessing and updating Maintenance Work Rule Template records to simplify data mocking
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME                      DATE                 DETAIL FEATURES
    1.0         Evan Kuminski, Salesforce           2023-12-04           Initial version
*********************************************************************************************************************/

public with sharing class SBR_3_0_MaintenanceWorkRuleTemplateDA implements SBR_3_0_MaintenanceWorkRuleTemplateDAI {
    public List<SVMXA360__MaintenanceWorkRuleTemplate__c> upsertMaintenanceWorkRuleTemplates(List<SVMXA360__MaintenanceWorkRuleTemplate__c> maintenanceWorkRuleTemplates) {
        upsert maintenanceWorkRuleTemplates;
        return maintenanceWorkRuleTemplates;
    }

    public List<SVMXA360__MaintenanceWorkRuleTemplate__c> getByInspectionTemplateIds(Set<Id> inspectionTemplateIds) {
        return [
                SELECT
                        Id, SM_PS_Inspection_Template__c, SVMXA360__ApplicableProductId__c,
                        SVMXA360__WorkTypeId__r.SM_PS_How_to_Maintain__c,
                        SVMXA360__WorkTypeId__r.SM_PS_How_to_Maintain_2__c,
                        SVMXA360__WorkTypeId__r.SM_PS_When_to_Perform_Step__c,
                        SVMXA360__WorkTypeId__r.SM_PS_When_to_Perform_Step_2__c
                FROM
                        SVMXA360__MaintenanceWorkRuleTemplate__c
                WHERE
                        SM_PS_Inspection_Template__c IN :inspectionTemplateIds
        ];
    }
}