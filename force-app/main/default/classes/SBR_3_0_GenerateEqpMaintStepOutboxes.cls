/*********************************************************************************************************************
* Apex Class: SBR_3_0_GenerateEqpMaintStepOutboxes
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Generates creation Outbox records for all Eqp Maintenance Steps related to the record Ids in inspectionTemplateIds
* - Intended to be called from a flow to ensure this runs after the flow that generates Eqp Maintenance Steps for an Inspection Template
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME                      DATE                 DETAIL FEATURES
    1.0         Evan Kuminski, Salesforce           2023-10-19           Initial version
*********************************************************************************************************************/

public with sharing class SBR_3_0_GenerateEqpMaintStepOutboxes {
    @TestVisible private static SBR_3_0_EqpMaintenanceStepDAI eqpMaintenanceStepDA = new SBR_3_0_EqpMaintenanceStepDA();

    @InvocableMethod(Label='Generate Outboxes for New Eqp Maintenance Steps')
    public static void generateOutboxesForNewEqpMaintenanceSteps(List<Id> inspectionTemplateIds) {
        List<SM_PS_Eqp_Maintenance_Step__c> splitEqpMaintenanceSteps = new List<SM_PS_Eqp_Maintenance_Step__c>();
        for (SM_PS_Eqp_Maintenance_Step__c eqpMaintenanceStep : eqpMaintenanceStepDA.getAllFieldsByInspectionTemplateIds(inspectionTemplateIds)) {
            splitEqpMaintenanceSteps.addAll(
                    (List<SM_PS_Eqp_Maintenance_Step__c>)SBR_3_0_CopySObjectsByCompanyCode.generateFromCompanyCodes(
                            eqpMaintenanceStep,
                            SM_PS_Eqp_Maintenance_Step__c.SM_PS_Company_Code__c,
                            SBR_3_0_CopySObjectsByCompanyCode.splitCompanyCodeString(eqpMaintenanceStep.SM_PS_Company_Code__c)
                    )
            );
        }

        SBR_3_0_PublishToOutboxWithoutQuery publishToOutboxWithoutQuery = new SBR_3_0_PublishToOutboxWithoutQuery(
                splitEqpMaintenanceSteps, SM_PS_Eqp_Maintenance_Step__c.getSObjectType(),
                new Set<SObjectField>{ SM_PS_Eqp_Maintenance_Step__c.SM_PS_Company_Code__c },
                SBR_3_0_PublishToOutboxWithoutQuery.CREATE_RECORD_SOURCE_OF_UPDATE
        );
        publishToOutboxWithoutQuery.setRecordTypeOverride('Eqp Maintenance Step');
        publishToOutboxWithoutQuery.stageOutboxChanges();
        SBR_3_0_PublishToOutboxWithoutQuery.publishAllOutboxes();
    }
}