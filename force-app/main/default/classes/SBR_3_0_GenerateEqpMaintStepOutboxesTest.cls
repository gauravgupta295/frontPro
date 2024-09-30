/*********************************************************************************************************************
* Apex Class: SBR_3_0_GenerateEqpMaintStepOutboxesTest
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Tests for SBR_3_0_GenerateEqpMaintStepOutboxes
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME                      DATE                 DETAIL FEATURES
    1.0         Evan Kuminski, Salesforce           2023-10-19           Initial version
*********************************************************************************************************************/

@IsTest
private class SBR_3_0_GenerateEqpMaintStepOutboxesTest {
    @IsTest
    static void testOutboxGeneration() {
        Id mockEqpMaintenanceStepId = SM_PS_Eqp_Maintenance_Step__c.SObjectType.getDescribe().keyPrefix + '000000000000';
        SBR_3_0_EqpMaintenanceStepDAMock eqpMaintenanceStepDAMock = new SBR_3_0_EqpMaintenanceStepDAMock();
        eqpMaintenanceStepDAMock.results = new List<SM_PS_Eqp_Maintenance_Step__c>{
                new SM_PS_Eqp_Maintenance_Step__c(Id=mockEqpMaintenanceStepId, SM_PS_Company_Code__c='01')
        };
        SBR_3_0_GenerateEqpMaintStepOutboxes.eqpMaintenanceStepDA = eqpMaintenanceStepDAMock;

        Test.startTest();
        {
            SBR_3_0_GenerateEqpMaintStepOutboxes.generateOutboxesForNewEqpMaintenanceSteps(
                    new List<Id>{Inspection_Template__c.SObjectType.getDescribe().keyPrefix + '000000000000'}
            );
        }
        Test.stopTest();

        List<Outbox__c> results = [SELECT Id, Record_Id__c, Record_Source_Of_Update__c FROM Outbox__c];
        Assert.areEqual(1, results.size());
        Assert.areEqual(mockEqpMaintenanceStepId, results[0].Record_Id__c);
        Assert.areEqual(SBR_3_0_PublishToOutboxWithoutQuery.CREATE_RECORD_SOURCE_OF_UPDATE, results[0].Record_Source_Of_Update__c);
    }

    public class SBR_3_0_EqpMaintenanceStepDAMock implements SBR_3_0_EqpMaintenanceStepDAI {
        List<SM_PS_Eqp_Maintenance_Step__c> results;
        public List<SM_PS_Eqp_Maintenance_Step__c> getAllFieldsByInspectionTemplateIds(Iterable<Id> inspectionTemplateIds) {
            return results;
        }
    }
}