/*********************************************************************************************************************
* Apex Class: SBR_3_0_InspectionTemplateDATest
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Test classes for SBR_3_0_ApplicableProductDA
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME                      DATE                 DETAIL FEATURES
    1.0         Evan Kuminski, Salesforce           2023-12-04           Initial version
*********************************************************************************************************************/

@IsTest
private class SBR_3_0_ApplicableProductDATest {
    @IsTest
    static void getByMaintenancePlanTemplateIdsTest() {
        Product2 product = new Product2(
                Name = 'TEST'
        );
        insert product;

        SVMXA360__MaintenancePlanTemplate__c maintenancePlanTemplate = new SVMXA360__MaintenancePlanTemplate__c(
                SVMXA360__MaintenancePlanUnitOfTime__c = 'Years',
                SVMXA360__MaintenancePlanDuration__c = 1
        );
        insert maintenancePlanTemplate;

        SVMXA360__ApplicableProduct__c applicableProduct = new SVMXA360__ApplicableProduct__c(
                SVMXA360__MaintenancePlanTemplateId__c = maintenancePlanTemplate.Id,
                SVMXA360__ProductId__c = product.Id
        );
        insert applicableProduct;

        List<SVMXA360__ApplicableProduct__c> results;

        Test.startTest();
        {
            results = new SBR_3_0_ApplicableProductDA().getByMaintenancePlanTemplateIds(
                    new List<Id>{maintenancePlanTemplate.Id}
            );
        }
        Test.stopTest();

        Assert.isFalse(results.isEmpty());
    }
}