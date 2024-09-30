/*********************************************************************************************************************
* Apex Class: SBR_3_0_ConditionDAInterface
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Methods for creating Condition records to simplify data mocking
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME                      DATE                 DETAIL FEATURES
    1.0         Evan Kuminski, Salesforce           2023-12-04           Initial version
*********************************************************************************************************************/

public interface SBR_3_0_ConditionDAInterface {
    List<SVMXA360__SM_Condition__c> insertConditions(List<SVMXA360__SM_Condition__c> conditions);
}