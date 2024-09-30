/*********************************************************************************************************************
* Apex Class: SBR_3_0_InspectionTemplateDATest
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Used to generate Maintenance Work Rule Templates and Conditions when an Inspection Template is activated
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME                      DATE                 DETAIL FEATURES
    1.0         Evan Kuminski, Salesforce           2023-12-04           Initial version
*********************************************************************************************************************/

public with sharing class SBR_3_0_GenMaintWorkRuleTempInvocable {
    @TestVisible private static SBR_3_0_ApplicableProductDAInterface applicableProductDA = new SBR_3_0_ApplicableProductDA();
    @TestVisible private static SBR_3_0_ConditionDAInterface conditionDA = new SBR_3_0_ConditionDA();
    @TestVisible private static SBR_3_0_InspectionTemplateDAInterface inspectionTemplateDA = new SBR_3_0_InspectionTemplateDA();
    @TestVisible private static SBR_3_0_MaintenanceWorkRuleTemplateDAI maintenanceWorkRuleTemplateDA = new SBR_3_0_MaintenanceWorkRuleTemplateDA();
    @TestVisible private static SBR_3_0_TechnicalAttributeDAInterface technicalAttributeDA = new SBR_3_0_TechnicalAttributeDA();

    @TestVisible private static Id technicalAttributeTemplateId;
    @TestVisible private static Id technicalAttributeCategoryId;

    private static final Map<String, String> HOW_TO_MAINTAIN_NAME_TO_ABBREVIATION = new Map<String, String>{
            'Calendar Days' => 'D',
            'Rental Days' => 'R',
            'Meter' => 'M'
    };

    @TestVisible private static final Map<String, Integer> TECHNICAL_ATTRIBUTE_PRIORITY_MAP = new Map<String, Integer>{
            'D' => 0, 'R' => 1, 'M' => 2
    };

    @InvocableMethod(Label='Generate Maintenance Work Rule Templates')
    public static void generateMaintenanceWorkRuleTemplates(List<Id> maintenancePlanTemplateIds) {
        List<SVMXA360__ApplicableProduct__c> applicableProducts = applicableProductDA.getByMaintenancePlanTemplateIds(maintenancePlanTemplateIds);

        Set<Id> productIdsFromApplicableProducts = new Set<Id>();
        Set<Id> maintenancePlanTemplateIdsFromApplicableProducts = new Set<Id>();

        for (SVMXA360__ApplicableProduct__c applicableProduct : applicableProducts) {
            productIdsFromApplicableProducts.add(applicableProduct.SVMXA360__ProductId__c);
            maintenancePlanTemplateIdsFromApplicableProducts.add(applicableProduct.SVMXA360__MaintenancePlanTemplateId__c);
        }

        List<Inspection_Template__c> inspectionTemplates = inspectionTemplateDA.getByProductIdsAndMaintenancePlanTemplateIds(
                productIdsFromApplicableProducts, maintenancePlanTemplateIdsFromApplicableProducts
        );

        for(Integer i = 0; i < inspectionTemplates.size(); i++) {
            Boolean shouldRemove = true;
            for (SVMXA360__ApplicableProduct__c applicableProduct : applicableProducts) {
                if(
                        inspectionTemplates[i].SM_PS_Product__c == applicableProduct.SVMXA360__ProductId__c &&
                        inspectionTemplates[i].SM_PS_Work_Plan_Template__r.SM_PS_Maintenance_Plan_Template__c == applicableProduct.SVMXA360__MaintenancePlanTemplateId__c
                ) {
                    shouldRemove = false;
                    break;
                }
            }
            if(shouldRemove) {
                inspectionTemplates.remove(i--);
            }
        }

        Set<Id> inspectionTemplateIds = new Set<Id>();
        for (Inspection_Template__c inspectionTemplate : inspectionTemplates) {
            inspectionTemplateIds.add(inspectionTemplate.Id);
        }

        List<SVMXA360__MaintenanceWorkRuleTemplate__c> maintenanceWorkRuleTemplatesToUpdate =
                maintenanceWorkRuleTemplateDA.getByInspectionTemplateIds(inspectionTemplateIds);
        Set<Id> inspectionTempIdsWithExistingMaintWorkRuleTemp = new Set<Id>();
        for (SVMXA360__MaintenanceWorkRuleTemplate__c maintenanceWorkRuleTemplate : maintenanceWorkRuleTemplatesToUpdate) {
            inspectionTempIdsWithExistingMaintWorkRuleTemp.add(maintenanceWorkRuleTemplate.SM_PS_Inspection_Template__c);
        }

        List<SVMXA360__MaintenanceWorkRuleTemplate__c> maintenanceWorkRuleTemplatesToInsert = new List<SVMXA360__MaintenanceWorkRuleTemplate__c>();
        for (Inspection_Template__c inspectionTemplate : inspectionTemplates) {
            if(!inspectionTempIdsWithExistingMaintWorkRuleTemp.contains(inspectionTemplate.Id)) {
                maintenanceWorkRuleTemplatesToInsert.add(new SVMXA360__MaintenanceWorkRuleTemplate__c(
                        SM_PS_Inspection_Template__c = inspectionTemplate.Id,
                        Name = inspectionTemplate.SF_PS_Work_Type__r.Name,
                        CurrencyIsoCode = 'USD',
                        SVMXA360__ApplicableProductId__c = getApplicableProductForInspectionTemplate(applicableProducts, inspectionTemplate).Id,
                        SVMXA360__AdvancedExpression__c = getAdvancedExpressionValue(inspectionTemplate),
                        SVMXA360__MaintenancePlanTemplateId__c = inspectionTemplate.SM_PS_Work_Plan_Template__r.SM_PS_Maintenance_Plan_Template__c,
                        SVMXA360__Type__c = 'Condition',
                        SVMXA360__WorkTypeId__c = inspectionTemplate.SF_PS_Work_Type__c,
                        SVMXA360__WorkTypeId__r = inspectionTemplate.SF_PS_Work_Type__r,
                        SVMXA360__SM_TechnicalAttributeTemplate__c = getTechnicalAttributeTemplateId()
                ));
            }
        }

        List<SVMXA360__MaintenanceWorkRuleTemplate__c> maintenanceWorkRuleTemplatesToUpsert = new List<SVMXA360__MaintenanceWorkRuleTemplate__c>();
        maintenanceWorkRuleTemplatesToUpsert.addAll(maintenanceWorkRuleTemplatesToInsert);
        maintenanceWorkRuleTemplatesToUpsert.addAll(maintenanceWorkRuleTemplatesToUpdate);
        maintenanceWorkRuleTemplatesToUpsert.sort(new MaintenanceWorkRuleComparator());

        Map<Id, Integer> nextSortOrderByProductId = new Map<Id, Integer>();
        for (SVMXA360__MaintenanceWorkRuleTemplate__c maintenanceWorkRuleTemplate : maintenanceWorkRuleTemplatesToUpsert) {
            if(!nextSortOrderByProductId.containsKey(maintenanceWorkRuleTemplate.SVMXA360__ApplicableProductId__c)) {
                nextSortOrderByProductId.put(maintenanceWorkRuleTemplate.SVMXA360__ApplicableProductId__c, 1);
            }
            maintenanceWorkRuleTemplate.SVMXA360__SortOrder__c = nextSortOrderByProductId.get(maintenanceWorkRuleTemplate.SVMXA360__ApplicableProductId__c);
            nextSortOrderByProductId.put(
                    maintenanceWorkRuleTemplate.SVMXA360__ApplicableProductId__c,
                    nextSortOrderByProductId.get(maintenanceWorkRuleTemplate.SVMXA360__ApplicableProductId__c) + 1
            );
        }

        maintenanceWorkRuleTemplateDA.upsertMaintenanceWorkRuleTemplates(maintenanceWorkRuleTemplatesToUpsert);
        conditionDA.insertConditions(generateConditions(maintenanceWorkRuleTemplatesToInsert));
    }

    @TestVisible
    private static SVMXA360__ApplicableProduct__c getApplicableProductForInspectionTemplate(
            List<SVMXA360__ApplicableProduct__c> potentialApplicableProducts, Inspection_Template__c inspectionTemplate
    ) {
        for (SVMXA360__ApplicableProduct__c potentialApplicableProduct : potentialApplicableProducts) {
            if (
                    potentialApplicableProduct.SVMXA360__ProductId__c == inspectionTemplate.SM_PS_Product__c &&
                    potentialApplicableProduct.SVMXA360__MaintenancePlanTemplateId__c == inspectionTemplate.SM_PS_Work_Plan_Template__r.SM_PS_Maintenance_Plan_Template__c
            ) {
                return potentialApplicableProduct;
            }
        }
        throw new IllegalArgumentException('No matching Applicable Product found for Inspection Template ' + inspectionTemplate.Id);
    }

    @TestVisible
    private static String getAdvancedExpressionValue(Inspection_Template__c inspectionTemplate) {
        if(
                inspectionTemplate.SM_PS_How_to_Maintain__c != null &&
                inspectionTemplate.SM_PS_How_to_Maintain__c != '' &&
                inspectionTemplate.SM_PS_When_to_Perform_Step__c != null
        ) {
            if(
                    inspectionTemplate.SM_PS_How_to_Maintain_2__c != null &&
                    inspectionTemplate.SM_PS_How_to_Maintain_2__c != '' &&
                    inspectionTemplate.SM_PS_When_to_Perform_Step_2__c != null
            ) {
                return '1 OR 2';
            } else {
                return '1';
            }
        } else {
            throw new IllegalArgumentException('How to Maintain or When to Perform Step on Inspection Template ' + inspectionTemplate.Id + ' are blank.');
        }
    }

    @TestVisible
    private static SVMXA360__SM_Condition__c generateCondition(
            SVMXA360__MaintenanceWorkRuleTemplate__c maintenanceWorkRuleTemplate,
            Map<String, Id> howToMaintainAbbreviationToId,
            Integer sequence
    ) {
        SObjectField howToMaintain, whenToPerformStep;
        switch on sequence {
            when 1 {
                howToMaintain = WorkType.SM_PS_How_to_Maintain__c;
                whenToPerformStep = WorkType.SM_PS_When_to_Perform_Step__c;
            }
            when 2 {
                howToMaintain = WorkType.SM_PS_How_to_Maintain_2__c;
                whenToPerformStep = WorkType.SM_PS_When_to_Perform_Step_2__c;
            }
            when else {
                throw new IllegalArgumentException('Invalid sequence number passed to generateCondition()');
            }
        }
        return new SVMXA360__SM_Condition__c(
                SVMXA360__ConditionType__c = 'Frequency',
                SVMXA360__StartAt__c = '0',
                SVMXA360__StopAt__c = '999999999',
                SVMXA360__Sequence__c = sequence,
                SVMXA360__Operator__c = 'Every',
                SVMXA360__Operand__c = String.valueOf(maintenanceWorkRuleTemplate?.SVMXA360__WorkTypeId__r?.get(whenToPerformStep)),
                SVMXA360__TechnicalAttribute__c = howToMaintainAbbreviationToId.get((String)maintenanceWorkRuleTemplate?.SVMXA360__WorkTypeId__r?.get(howToMaintain)),
                SVMXA360__Threshold__c = 100,
                SVMXA360__MaintenanceWorkRuleTemplate__c = maintenanceWorkRuleTemplate.Id,
                SVMXA360__TechnicalAttributeCategory__c = getTechnicalAttributeCategoryId()
        );
    }

    @TestVisible
    private static List<SVMXA360__SM_Condition__c> generateConditions(List<SVMXA360__MaintenanceWorkRuleTemplate__c> maintenanceWorkRuleTemplates) {
        Map<String, Id> howToMaintainAbbreviationToId = new Map<String, Id>();
        for (SVMXA360__SM_TA_TechnicalAttribute__c technicalAttribute  : technicalAttributeDA.getByNames(HOW_TO_MAINTAIN_NAME_TO_ABBREVIATION.keySet())) {
            howToMaintainAbbreviationToId.put(
                    HOW_TO_MAINTAIN_NAME_TO_ABBREVIATION.get(technicalAttribute.Name),
                    technicalAttribute.Id
            );
        }

        List<SVMXA360__SM_Condition__c> results = new List<SVMXA360__SM_Condition__c>();
        for (SVMXA360__MaintenanceWorkRuleTemplate__c maintenanceWorkRuleTemplate : maintenanceWorkRuleTemplates) {
            results.add(generateCondition(maintenanceWorkRuleTemplate, howToMaintainAbbreviationToId, 1));
            if(
                    maintenanceWorkRuleTemplate.SVMXA360__WorkTypeId__r.SM_PS_How_to_Maintain_2__c != null &&
                            maintenanceWorkRuleTemplate.SVMXA360__WorkTypeId__r.SM_PS_When_to_Perform_Step_2__c != null
            ) {
                results.add(generateCondition(maintenanceWorkRuleTemplate, howToMaintainAbbreviationToId, 2));
            }
        }
        return results;
    }

    @TestVisible
    private static Id getTechnicalAttributeTemplateId() {
        if(technicalAttributeTemplateId == null) {
            technicalAttributeTemplateId = technicalAttributeDA.getTemplateByName('SBR 3.0 Maintenance Template')?.Id;
        }
        return technicalAttributeTemplateId;
    }

    @TestVisible
    private static Id getTechnicalAttributeCategoryId() {
        if(technicalAttributeCategoryId == null) {
            technicalAttributeCategoryId = technicalAttributeDA.getCategoryByName('Maintenance')?.Id;
        }
        return technicalAttributeCategoryId;
    }

    public class MaintenanceWorkRuleComparator implements Comparator<SVMXA360__MaintenanceWorkRuleTemplate__c> {
        public Integer compare(SVMXA360__MaintenanceWorkRuleTemplate__c param1, SVMXA360__MaintenanceWorkRuleTemplate__c param2) {
            Integer technicalAttributePriority1 = TECHNICAL_ATTRIBUTE_PRIORITY_MAP.get(param1.SVMXA360__WorkTypeId__r.SM_PS_How_to_Maintain__c);
            Integer technicalAttributePriority2 = TECHNICAL_ATTRIBUTE_PRIORITY_MAP.get(param2.SVMXA360__WorkTypeId__r.SM_PS_How_to_Maintain__c);
            if(technicalAttributePriority1 == technicalAttributePriority2) {
                if(param1.SVMXA360__WorkTypeId__r.SM_PS_When_to_Perform_Step__c > param2.SVMXA360__WorkTypeId__r.SM_PS_When_to_Perform_Step__c) {
                    return -1;
                } else if(param1.SVMXA360__WorkTypeId__r.SM_PS_When_to_Perform_Step__c < param2.SVMXA360__WorkTypeId__r.SM_PS_When_to_Perform_Step__c) {
                    return 1;
                } else {
                    return 0;
                }
            } else {
                return technicalAttributePriority1 - technicalAttributePriority2;
            }
        }
    }
}