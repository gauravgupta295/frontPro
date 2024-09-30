/*********************************************************************************************************************
* Apex Class: SBR_3_0_InspectionTemplateDA
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Methods for accessing Inspection Template records to simplify data mocking
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME                      DATE                 DETAIL FEATURES
    1.0         Evan Kuminski, Salesforce           2023-12-04           Initial version
*********************************************************************************************************************/

public with sharing class SBR_3_0_InspectionTemplateDA implements SBR_3_0_InspectionTemplateDAInterface {
    public List<Inspection_Template__c> getByProductIdsAndMaintenancePlanTemplateIds(Set<Id> productIds, Set<Id> maintenancePlanTemplateIds) {
        return [
                SELECT
                        Id, SM_PS_How_to_Maintain__c, SM_PS_How_to_Maintain_2__c, SM_PS_Product__c,
                        SM_PS_When_to_Perform_Step__c, SM_PS_When_to_Perform_Step_2__c,
                        SM_PS_Work_Plan_Template__r.SM_PS_Maintenance_Plan_Template__c, SF_PS_Work_Type__r.Name,
                        SF_PS_Work_Type__r.SM_PS_How_to_Maintain__c, SF_PS_Work_Type__r.SM_PS_How_to_Maintain_2__c,
                        SF_PS_Work_Type__r.SM_PS_When_to_Perform_Step__c,
                        SF_PS_Work_Type__r.SM_PS_When_to_Perform_Step_2__c
                FROM
                        Inspection_Template__c
                WHERE
                        SM_PS_Product__c IN :productIds AND
                        SM_PS_Work_Plan_Template__r.SM_PS_Maintenance_Plan_Template__c IN :maintenancePlanTemplateIds
        ];
    }
}