/**
 * Created by ekuminski on 12/4/2023.
 */

@IsTest
private class SBR_3_0_MaintenanceWorkRuleTemplateDATst {
    @IsTest
    static void upsertMaintenanceWorkRuleTemplatesTest() {
        List<SVMXA360__MaintenanceWorkRuleTemplate__c> results;
        Test.startTest();
        {
            results = new SBR_3_0_MaintenanceWorkRuleTemplateDA().upsertMaintenanceWorkRuleTemplates(
                    new List<SVMXA360__MaintenanceWorkRuleTemplate__c>{
                            new SVMXA360__MaintenanceWorkRuleTemplate__c()
                    }
            );
        }
        Test.stopTest();
        Assert.isNotNull(results[0].Id);
    }

    @IsTest
    static void getByInspectionTemplateIdsTets() {
        Id inspectionTemplateId = SBR_3_0_ServiceTestDataFactory.createInspectionTemplate(true).Id;
        insert new SVMXA360__MaintenanceWorkRuleTemplate__c(SM_PS_Inspection_Template__c = inspectionTemplateId);
        List<SVMXA360__MaintenanceWorkRuleTemplate__c> results;
        Test.startTest();
        {
            results = new SBR_3_0_MaintenanceWorkRuleTemplateDA().getByInspectionTemplateIds(new Set<Id>{inspectionTemplateId});
        }
        Test.stopTest();
        Assert.isFalse(results.isEmpty());
    }
}