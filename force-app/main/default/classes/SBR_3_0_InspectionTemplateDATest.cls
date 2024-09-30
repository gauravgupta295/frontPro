/*********************************************************************************************************************
* Apex Class: SBR_3_0_InspectionTemplateDATest
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Test classes for SBR_3_0_InspectionTemplateDA
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME                      DATE                 DETAIL FEATURES
    1.0         Evan Kuminski, Salesforce           2023-12-04           Initial version
*********************************************************************************************************************/

@IsTest
private class SBR_3_0_InspectionTemplateDATest {
    @IsTest
    static void getByProductIdsAndMaintenancePlanTemplateIdsTest() {
        Product2 product = new Product2(
                Name = 'TEST'
        );
        insert product;

        SVMXA360__MaintenancePlanTemplate__c maintenancePlanTemplate = new SVMXA360__MaintenancePlanTemplate__c(
                SVMXA360__MaintenancePlanUnitOfTime__c = 'Years',
                SVMXA360__MaintenancePlanDuration__c = 1
        );
        insert maintenancePlanTemplate;

        WorkPlanTemplate workPlanTemplate = new WorkPlanTemplate(
                Name = 'TEST',
                SM_PS_Maintenance_Plan_Template__c = maintenancePlanTemplate.Id
        );
        insert workPlanTemplate;

        Inspection_Template__c inspectionTemplate = new Inspection_Template__c(
                SM_PS_Product__c = product.Id,
                SM_PS_Work_Plan_Template__c = workPlanTemplate.Id
        );
        insert inspectionTemplate;

        List<Inspection_Template__c> results;
        Test.startTest();
        {
            results = new SBR_3_0_InspectionTemplateDA().getByProductIdsAndMaintenancePlanTemplateIds(
                    new Set<Id>{product.Id},
                    new Set<Id>{maintenancePlanTemplate.Id}
            );
        }
        Test.stopTest();

        Assert.isFalse(results.isEmpty());
    }
}