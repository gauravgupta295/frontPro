/*********************************************************************************************************************
* Apex Class: SBR_3_0_EqpMaintenanceStepDATest
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Test class for SBR_3_0_EqpMaintenanceStepDA
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME                      DATE                 DETAIL FEATURES
    1.0         Evan Kuminski, Salesforce           2023-10-19           Initial version
*********************************************************************************************************************/

@IsTest
private class SBR_3_0_EqpMaintenanceStepDATest {
    @TestSetup
    private static void setupData() {
        Inspection_Template__c inspectionTemplate = new Inspection_Template__c();
        insert inspectionTemplate;
        insert new SM_PS_Eqp_Maintenance_Step__c(SM_PS_Inspection_Template__c = inspectionTemplate.Id);
    }

    @IsTest
    private static void getAllFieldsByInspectionTemplateIds() {
        Id inspectionTemplateId = [SELECT Id FROM Inspection_Template__c][0].Id;
        List<SM_PS_Eqp_Maintenance_Step__c> results;
        Test.startTest();
        {
            results = new SBR_3_0_EqpMaintenanceStepDA().getAllFieldsByInspectionTemplateIds(new List<Id>{inspectionTemplateId});
        }
        Test.stopTest();

        Assert.areEqual(inspectionTemplateId, results[0].SM_PS_Inspection_Template__c);
    }

    @IsTest
    private static void getAllFieldsString() {
        String result;
        Test.startTest();
        {
            result = SBR_3_0_EqpMaintenanceStepDA.getAllFieldsString().toLowerCase();
        }
        Test.stopTest();

        for (String field : SM_PS_Eqp_Maintenance_Step__c.SObjectType.getDescribe().fields.getMap().keySet()) {
            Assert.isTrue(result.contains(field.toLowerCase()), 'Failed to find ' + field);
        }
    }
}