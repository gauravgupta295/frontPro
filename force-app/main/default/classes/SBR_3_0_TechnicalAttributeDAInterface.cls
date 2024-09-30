/*********************************************************************************************************************
* Apex Class: SBR_3_0_TechnicalAttributeDAInterface
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Methods for accessing Technical Attribute and closely related records to simplify data mocking
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME                      DATE                 DETAIL FEATURES
    1.0         Evan Kuminski, Salesforce           2023-12-04           Initial version
*********************************************************************************************************************/

public interface SBR_3_0_TechnicalAttributeDAInterface {
    List<SVMXA360__SM_TA_TechnicalAttribute__c> getByNames(Set<String> names);
    SVMXA360__SM_TA_Template__c getTemplateByName(String name);
    SVMXA360__SM_TA_Category__c getCategoryByName(String name);
}