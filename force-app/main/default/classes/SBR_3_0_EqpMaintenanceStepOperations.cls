/*********************************************************************************************************************
* Apex Class: SBR_3_0_EqpMaintenanceStepOperations
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Methods used SBR_3_0_EqpMaintenanceStepTriggerHandler
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME                      DATE                 DETAIL FEATURES
    1.0         Evan Kuminski, Salesforce           2023-10-19           Initial version
*********************************************************************************************************************/

public with sharing class SBR_3_0_EqpMaintenanceStepOperations {
    @TestVisible private static final String ACTIVE_STATUS = 'Active';

    public static void publishUpdatesToOutbox(
            List<SM_PS_Eqp_Maintenance_Step__c> newEqpMaintenanceSteps,
            Map<Id, SM_PS_Eqp_Maintenance_Step__c> oldEqpMaintenanceStepsById
    ) {
        List<SM_PS_Eqp_Maintenance_Step__c> eqpMaintenanceStepsToPublish = new List<SM_PS_Eqp_Maintenance_Step__c>();
        for (SM_PS_Eqp_Maintenance_Step__c newEqpMaintenanceStep : newEqpMaintenanceSteps) {
            SM_PS_Eqp_Maintenance_Step__c oldEqpMaintenanceStep = oldEqpMaintenanceStepsById.get(newEqpMaintenanceStep.Id);
            if(shouldPublishOutbox(newEqpMaintenanceStep, oldEqpMaintenanceStep)) {
                eqpMaintenanceStepsToPublish.addAll(
                        (List<SM_PS_Eqp_Maintenance_Step__c>)SBR_3_0_CopySObjectsByCompanyCode.createUpdatedSObjectCopiesByCompanyCode(
                                newEqpMaintenanceStep, SM_PS_Eqp_Maintenance_Step__c.SM_PS_Company_Code__c,
                                SBR_3_0_CopySObjectsByCompanyCode.splitCompanyCodeString(newEqpMaintenanceStep.SM_PS_Company_Code__c),
                                SBR_3_0_CopySObjectsByCompanyCode.splitCompanyCodeString(oldEqpMaintenanceStep.SM_PS_Company_Code__c),
                                false
                        )
                );
            }
        }

        SBR_3_0_PublishToOutboxWithoutQuery publishToOutboxWithoutQuery = new SBR_3_0_PublishToOutboxWithoutQuery(
                eqpMaintenanceStepsToPublish, SM_PS_Eqp_Maintenance_Step__c.getSObjectType(),
                new Set<SObjectField>{ SM_PS_Eqp_Maintenance_Step__c.SM_PS_Company_Code__c },
                SBR_3_0_PublishToOutboxWithoutQuery.UPDATE_RECORD_SOURCE_OF_UPDATE
        );
        publishToOutboxWithoutQuery.setRecordTypeOverride('Eqp Maintenance Step');
        publishToOutboxWithoutQuery.stageOutboxChanges();
        SBR_3_0_PublishToOutboxWithoutQuery.publishAllOutboxes();
    }

    @TestVisible private static Boolean shouldPublishOutbox(
            SM_PS_Eqp_Maintenance_Step__c newEqpMaintenanceStep, SM_PS_Eqp_Maintenance_Step__c oldEqpMaintenanceStep
    ) {
        if(newEqpMaintenanceStep.SM_PS_Status__c != ACTIVE_STATUS) {
            return false;
        }
        for (SObjectField field : SM_PS_Eqp_Maintenance_Step__c.SObjectType.getDescribe().fields.getMap().values()) {
            if (newEqpMaintenanceStep.get(field) != oldEqpMaintenanceStep.get(field)) {
                return true;
            }
        }

        return false;
    }
}