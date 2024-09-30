/*********************************************************************************************************************
* Apex Class: SBR_3_0_ApplicableProductDA
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Methods for accessing Applicable Product records to simplify data mocking
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME                      DATE                 DETAIL FEATURES
    1.0         Evan Kuminski, Salesforce           2023-12-04           Initial version
*********************************************************************************************************************/

public with sharing class SBR_3_0_ApplicableProductDA implements SBR_3_0_ApplicableProductDAInterface {
    public List<SVMXA360__ApplicableProduct__c> getByMaintenancePlanTemplateIds(List<Id> maintenancePlanTemplateIds) {
        return [
                SELECT
                        Id, SVMXA360__ProductId__c, SVMXA360__MaintenancePlanTemplateId__c
                FROM
                        SVMXA360__ApplicableProduct__c
                WHERE
                        SVMXA360__MaintenancePlanTemplateId__c IN :maintenancePlanTemplateIds
        ];
    }
}