/*********************************************************************************************************************
* Apex Class: SBR_3_0_ConditionDATest
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Test classes for SBR_3_0_ConditionDA
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME                      DATE                 DETAIL FEATURES
    1.0         Evan Kuminski, Salesforce           2023-12-04           Initial version
*********************************************************************************************************************/

@IsTest
private class SBR_3_0_ConditionDATest {
    @IsTest
    static void insertConditionsTest() {
        List<SVMXA360__SM_Condition__c> conditionsToInsert = new List<SVMXA360__SM_Condition__c>{
                new SVMXA360__SM_Condition__c()
        };
        Test.startTest();
        {
            new SBR_3_0_ConditionDA().insertConditions(conditionsToInsert);
        }
        Test.stopTest();
        Assert.isNotNull(conditionsToInsert[0].Id);
    }
}