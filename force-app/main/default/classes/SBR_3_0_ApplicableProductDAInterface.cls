/*********************************************************************************************************************
* Apex Class: SBR_3_0_ApplicableProductDAInterface
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Methods for accessing Applicable Product records to simplify data mocking
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME                      DATE                 DETAIL FEATURES
    1.0         Evan Kuminski, Salesforce           2023-12-04           Initial version
*********************************************************************************************************************/

public interface SBR_3_0_ApplicableProductDAInterface {
    List<SVMXA360__ApplicableProduct__c> getByMaintenancePlanTemplateIds(List<Id> maintenancePlanTemplateIds);
}