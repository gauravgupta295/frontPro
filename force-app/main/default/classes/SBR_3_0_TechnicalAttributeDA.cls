/*********************************************************************************************************************
* Apex Class: SBR_3_0_TechnicalAttributeDA
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Methods for accessing Technical Attribute and closely related records to simplify data mocking
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME                      DATE                 DETAIL FEATURES
    1.0         Evan Kuminski, Salesforce           2023-12-04           Initial version
*********************************************************************************************************************/

public with sharing class SBR_3_0_TechnicalAttributeDA implements SBR_3_0_TechnicalAttributeDAInterface {
    public List<SVMXA360__SM_TA_TechnicalAttribute__c> getByNames(Set<String> names) {
        return [
                SELECT
                        Id, Name
                FROM
                        SVMXA360__SM_TA_TechnicalAttribute__c
                WHERE
                        Name IN :names
        ];
    }

    public SVMXA360__SM_TA_Template__c getTemplateByName(String name) {
        return [SELECT Id FROM SVMXA360__SM_TA_Template__c WHERE Name = :name LIMIT 1];
    }

    public SVMXA360__SM_TA_Category__c getCategoryByName(String name) {
        return [SELECT Id FROM SVMXA360__SM_TA_Category__c WHERE Name = :name LIMIT 1];
    }
}