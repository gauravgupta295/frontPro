/*********************************************************************************************************************
* Apex Class: SBR_3_0_WorkStepTemplateOperations
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Methods used by SBR_3_0_WorkStepTemplateTriggerHandler
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME                      DATE                 DETAIL FEATURES
    1.0         Evan Kuminski, Salesforce           2023-08-18           Initial version
    2.0         Evan Kuminski, Salesforce           2023-10-05           New logic for setting Record Source of Update
                                                                         Insert all Outboxes at once to reduce DML usage
    3.0         Evan Kuminski, Salesforce           2023-10-19           Moved some functionality to other classes for
                                                                         more effective code reuse
*********************************************************************************************************************/

public with sharing class SBR_3_0_WorkStepTemplateOperations {
    public static void publishSendToRentalManRecords(List<WorkStepTemplate> newWorkStepTemplates, Map<Id, WorkStepTemplate> oldWorkStepTemplatesById) {
        List<WorkStepTemplate> workStepTemplateToPublishAsNew = new List<WorkStepTemplate>();
        List<WorkStepTemplate> workStepTemplateToPublishAsUpdated = new List<WorkStepTemplate>();
        List<WorkStepTemplate> workStepTemplateToPublishAsDeleted = new List<WorkStepTemplate>();
        Set<SObjectField> fieldsToCheckForChanges = new Set<SObjectField>{
                WorkStepTemplate.Name, WorkStepTemplate.SM_PS_Company_Code__c, WorkStepTemplate.SM_PS_Labor_Code__c,
                WorkStepTemplate.SM_PS_Maintenance_Step_Y_N__c, WorkStepTemplate.SM_PS_Salesforce_Only__c,
                WorkStepTemplate.SM_PS_Search_Word__c, WorkStepTemplate.SM_PS_Send_to_RM__c
        };
        for (WorkStepTemplate newWorkStepTemplate : newWorkStepTemplates) {
            if(newWorkStepTemplate.SM_PS_Send_to_RM__c && !newWorkStepTemplate.SM_PS_Salesforce_Only__c && newWorkStepTemplate.IsActive) {
                Boolean hasRelevantChange = false;
                for (SObjectField field : fieldsToCheckForChanges) {
                    if(newWorkStepTemplate.get(field) != oldWorkStepTemplatesById.get(newWorkStepTemplate.Id).get(field)) {
                        hasRelevantChange = true;
                        break;
                    }
                }
                if(hasRelevantChange && newWorkStepTemplate.IsActive) {
                    WorkStepTemplate oldWorkStepTemplate = oldWorkStepTemplatesById.get(newWorkStepTemplate.Id);
                    Boolean isSendToRmChangedToTrue = newWorkStepTemplate.SM_PS_Send_to_RM__c == true && oldWorkStepTemplate.SM_PS_Send_to_RM__c == false;
                    Set<String> oldSplitCompanyCode = SBR_3_0_CopySObjectsByCompanyCode.splitCompanyCodeString(oldWorkStepTemplate.SM_PS_Company_Code__c);
                    Set<String> newSplitCompanyCode = SBR_3_0_CopySObjectsByCompanyCode.splitCompanyCodeString(newWorkStepTemplate.SM_PS_Company_Code__c);
                    workStepTemplateToPublishAsNew.addAll(
                            (List<WorkStepTemplate>)SBR_3_0_CopySObjectsByCompanyCode.createNewSObjectCopiesByCompanyCode(
                                    newWorkStepTemplate, WorkStepTemplate.SM_PS_Company_Code__c, oldSplitCompanyCode,
                                    newSplitCompanyCode, isSendToRmChangedToTrue
                            )
                    );
                    workStepTemplateToPublishAsUpdated.addAll(
                            (List<WorkStepTemplate>)SBR_3_0_CopySObjectsByCompanyCode.createUpdatedSObjectCopiesByCompanyCode(
                                    newWorkStepTemplate, WorkStepTemplate.SM_PS_Company_Code__c, oldSplitCompanyCode,
                                    newSplitCompanyCode, isSendToRmChangedToTrue
                            )
                    );
                    if(newWorkStepTemplate.SM_PS_Company_Code__c != oldWorkStepTemplatesById.get(newWorkStepTemplate.Id).SM_PS_Company_Code__c) {
                        workStepTemplateToPublishAsDeleted.addAll(
                                (List<WorkStepTemplate>)SBR_3_0_CopySObjectsByCompanyCode.createDeletedSObjectCopiesByCompanyCode(
                                        newWorkStepTemplate, WorkStepTemplate.SM_PS_Company_Code__c, oldSplitCompanyCode,
                                        newSplitCompanyCode, newWorkStepTemplate.IsActive
                                )
                        );
                    }
                }
            }
        }
        stageWithRecordSourceOfUpdate(workStepTemplateToPublishAsNew, SBR_3_0_PublishToOutboxWithoutQuery.CREATE_RECORD_SOURCE_OF_UPDATE);
        stageWithRecordSourceOfUpdate(workStepTemplateToPublishAsUpdated, SBR_3_0_PublishToOutboxWithoutQuery.UPDATE_RECORD_SOURCE_OF_UPDATE);
        stageWithRecordSourceOfUpdate(workStepTemplateToPublishAsDeleted, SBR_3_0_PublishToOutboxWithoutQuery.DELETE_RECORD_SOURCE_OF_UPDATE);
        SBR_3_0_PublishToOutboxWithoutQuery.publishAllOutboxes();
    }

    public static void publishDeactivatedSendToRentalManRecords(List<WorkStepTemplate> newWorkStepTemplates, Map<Id, WorkStepTemplate> oldWorkStepTemplatesById) {
        List<WorkStepTemplate> deactivatedWorkStepTemplates = new List<WorkStepTemplate>();
        for (WorkStepTemplate newWorkStepTemplate : newWorkStepTemplates) {
            WorkStepTemplate oldWorkStepTemplate = oldWorkStepTemplatesById.get(newWorkStepTemplate.Id);
            if(
                    newWorkStepTemplate.SM_PS_Send_to_RM__c &&
                    !newWorkStepTemplate.SM_PS_Salesforce_Only__c &&
                    !newWorkStepTemplate.IsActive &&
                    oldWorkStepTemplate.IsActive
            ) {
                deactivatedWorkStepTemplates.addAll(
                        (List<WorkStepTemplate>)SBR_3_0_CopySObjectsByCompanyCode.createDeletedSObjectCopiesByCompanyCode(
                                newWorkStepTemplate, WorkStepTemplate.SM_PS_Company_Code__c,
                                SBR_3_0_CopySObjectsByCompanyCode.splitCompanyCodeString(newWorkStepTemplate.SM_PS_Company_Code__c),
                                SBR_3_0_CopySObjectsByCompanyCode.splitCompanyCodeString(oldWorkStepTemplate.SM_PS_Company_Code__c),
                                false
                        )
                );
            }
        }
        stageWithRecordSourceOfUpdate(deactivatedWorkStepTemplates, SBR_3_0_PublishToOutboxWithoutQuery.DELETE_RECORD_SOURCE_OF_UPDATE);
        SBR_3_0_PublishToOutboxWithoutQuery.publishAllOutboxes();
    }

    private static void stageWithRecordSourceOfUpdate(List<WorkStepTemplate> workStepTemplates, String recordSourceOfUpdate) {
        (new SBR_3_0_PublishToOutboxWithoutQuery(
                workStepTemplates, WorkStepTemplate.getSObjectType(),
                new Set<SObjectField>{ WorkStepTemplate.SM_PS_Company_Code__c }, recordSourceOfUpdate
        )).stageOutboxChanges();
    }
}