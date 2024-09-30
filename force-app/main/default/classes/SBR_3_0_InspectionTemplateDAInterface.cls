/*********************************************************************************************************************
* Apex Class: SBR_3_0_InspectionTemplateDAInterface
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Methods for accessing Inspection Template records to simplify data mocking
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME                      DATE                 DETAIL FEATURES
    1.0         Evan Kuminski, Salesforce           2023-12-04           Initial version
*********************************************************************************************************************/

public interface SBR_3_0_InspectionTemplateDAInterface {
    List<Inspection_Template__c> getByProductIdsAndMaintenancePlanTemplateIds(Set<Id> productIds, Set<Id> maintenancePlanTemplateIds);
}