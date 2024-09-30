/*********************************************************************************************************************
* Apex Class: SBR_3_0_InspectionTemplateOperations
----------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - SERV-4125 - Validate duplicate creation of Inspection Template
---------------------------------------------------------------------------------------------------------------------
* History:
* VERSION     DEVELOPER NAME                    DATE                DETAIL FEATURES
    1.0       Ritesh Mohapatra                  2023-Sep-19         Initial version
    2.0       Evan Kuminski                     2023-Oct-19         Added generateEqpMaintenanceStepOutboxesOnDeactivation()
                                                                    Generates Outbox records for related Eqp Maintenance Steps
                                                                    when an Inspection Template is deactivated
    3.0       Evan Kuminski                     2023-Dec-19         Update inspectionTempValidation() to only check the current 
                                                                    Work Plan Template for Inspection Template duplicates
*********************************************************************************************************************/

public class SBR_3_0_InspectionTemplateOperations
{
    @TestVisible private static SBR_3_0_EqpMaintenanceStepDAI eqpMaintenanceStepDA = new SBR_3_0_EqpMaintenanceStepDA();
    @Testvisible private static final String ACTIVE_STATUS = 'Active';

	public static void inspectionTempValidation (List<Inspection_Template__c > newInsTempList, Map<Id, Inspection_Template__c> oldInsTempMap)
    {
        
        Set<Id> assetIdSet = new Set<Id>();
        Set<Id> workPlanTemplateIdSet = new Set<Id>();
        Map<Id,Inspection_Template__c> insTempMap = new Map<Id,Inspection_Template__c>();
        Map<Id,Inspection_Template__c> prodTempMap = new Map<Id,Inspection_Template__c>();

        for(Inspection_Template__c insRecord : newInsTempList)
        {
            if((oldInsTempMap != null && oldInsTempMap.get(insRecord.id).SM_PS_Asset__c!=insRecord.SM_PS_Asset__c && insRecord.SM_PS_Asset__c!=null) ||
               (oldInsTempMap == null && insRecord.SM_PS_Asset__c!=null))
            { 
                assetIdSet.add(insRecord.SM_PS_Asset__c);
                workPlanTemplateIdSet.add(insRecord.SM_PS_Work_Plan_Template__c);
                insTempMap.put(insRecord.SM_PS_Asset__c,insRecord);
            }
        }
        
        if(!assetIdSet.isEmpty())
        {
            for(Asset oAssetRecord : [SELECT Id, Product2Id FROM Asset WHERE ID IN : assetIdSet])
            {
                if(oAssetRecord.Product2Id!=null)
                {
                    prodTempMap.put(oAssetRecord.Product2Id,insTempMap.get(oAssetRecord.id));
                } 
            }
        }
        
        if(!prodTempMap.keySet().isEmpty())
        {
            for(Inspection_Template__c oldInsRecord : [
                    SELECT
                            Id, SM_PS_Product__c, SM_PS_Work_Plan_Template__c
                    FROM
                            Inspection_Template__c
                    WHERE
                            SM_PS_Product__c IN: prodTempMap.keySet() AND
                            SM_PS_Work_Plan_Template__c IN :workPlanTemplateIdSet
            ]) {
                Inspection_Template__c inspectionTemplate = prodTempMap.get(oldInsRecord.SM_PS_Product__c);
                if(
                        inspectionTemplate.SM_PS_Work_Plan_Template__c == oldInsRecord.SM_PS_Work_Plan_Template__c &&
                        inspectionTemplate.SM_PS_Product__c == oldInsRecord.SM_PS_Product__c
                ) {
                    inspectionTemplate.addError('This Asset\'s Cat Class Product is already assigned to this Work Plan Template');
                }
            }
        }
    }

    public static void generateEqpMaintenanceStepOutboxesOnDeactivation(
            List<Inspection_Template__c > newInspectionTemplates,
            Map<Id, Inspection_Template__c> oldInspectionTemplates
    ) {
        Set<Id> inspectionTemplateIdsToQuery = new Set<Id>();
        for (Inspection_Template__c newInspectionTemplate : newInspectionTemplates) {
            Inspection_Template__c oldInspectionTemplate = oldInspectionTemplates.get(newInspectionTemplate.Id);
            System.debug(oldInspectionTemplate.SM_PS_Status__c);
            System.debug(newInspectionTemplate.SM_PS_Status__c);
            if(oldInspectionTemplate.SM_PS_Status__c == ACTIVE_STATUS && newInspectionTemplate.SM_PS_Status__c != ACTIVE_STATUS) {
                inspectionTemplateIdsToQuery.add(newInspectionTemplate.Id);
            }
        }
        System.debug(inspectionTemplateIdsToQuery);
        if(inspectionTemplateIdsToQuery.isEmpty()) {
            return;
        }

        List<SM_PS_Eqp_Maintenance_Step__c> splitEqpMaintenanceSteps = new List<SM_PS_Eqp_Maintenance_Step__c>();
        List<SM_PS_Eqp_Maintenance_Step__c> eqpMaintenanceStepsToProcess = eqpMaintenanceStepDA.getAllFieldsByInspectionTemplateIds(inspectionTemplateIdsToQuery);
        Formula.recalculateFormulas(eqpMaintenanceStepsToProcess);
        for (SM_PS_Eqp_Maintenance_Step__c eqpMaintenanceStep : eqpMaintenanceStepsToProcess) {
            splitEqpMaintenanceSteps.addAll(
                    (List<SM_PS_Eqp_Maintenance_Step__c>)SBR_3_0_CopySObjectsByCompanyCode.generateFromCompanyCodes(
                            eqpMaintenanceStep,
                            SM_PS_Eqp_Maintenance_Step__c.SM_PS_Company_Code__c,
                            SBR_3_0_CopySObjectsByCompanyCode.splitCompanyCodeString(eqpMaintenanceStep.SM_PS_Company_Code__c)
                    )
            );
        }

        System.debug(splitEqpMaintenanceSteps);

        SBR_3_0_PublishToOutboxWithoutQuery publishToOutboxWithoutQuery = new SBR_3_0_PublishToOutboxWithoutQuery(
                splitEqpMaintenanceSteps, SM_PS_Eqp_Maintenance_Step__c.getSObjectType(),
                new Set<SObjectField>{ SM_PS_Eqp_Maintenance_Step__c.SM_PS_Company_Code__c },
                SBR_3_0_PublishToOutboxWithoutQuery.DELETE_RECORD_SOURCE_OF_UPDATE
        );
        publishToOutboxWithoutQuery.setRecordTypeOverride('Eqp Maintenance Step');
        publishToOutboxWithoutQuery.stageOutboxChanges();
        SBR_3_0_PublishToOutboxWithoutQuery.publishAllOutboxes();
    }
}