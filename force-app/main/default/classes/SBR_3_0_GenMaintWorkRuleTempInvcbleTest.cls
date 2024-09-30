/*********************************************************************************************************************
* Apex Class: SBR_3_0_GenMaintWorkRuleTempInvcbleTest
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Test classes for SBR_3_0_GenMaintWorkRuleTempInvocable
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME                      DATE                 DETAIL FEATURES
    1.0         Evan Kuminski, Salesforce           2023-12-04           Initial version
*********************************************************************************************************************/

@IsTest
public class SBR_3_0_GenMaintWorkRuleTempInvcbleTest {
    private static Integer mockIdOffset = 0;

    @IsTest
    static void generateMaintenanceWorkRuleTemplatesTest() {
        Id productId = getMockId(Product2.SObjectType);
        Id maintenancePlanTemplateId = getMockId(SVMXA360__MaintenancePlanTemplate__c.SObjectType);

        SBR_3_0_ApplicableProductDAMock applicableProductDAMock = new SBR_3_0_ApplicableProductDAMock();
        SBR_3_0_GenMaintWorkRuleTempInvocable.applicableProductDA = applicableProductDAMock;
        applicableProductDAMock.getByMaintenancePlanTemplateIdsResult = new List<SVMXA360__ApplicableProduct__c>{
                new SVMXA360__ApplicableProduct__c(
                        SVMXA360__ProductId__c = productId,
                        SVMXA360__MaintenancePlanTemplateId__c = maintenancePlanTemplateId
                )
        };

        SBR_3_0_InspectionTemplateDAMock inspectionTemplateDAMock = new SBR_3_0_InspectionTemplateDAMock();
        SBR_3_0_GenMaintWorkRuleTempInvocable.inspectionTemplateDA = inspectionTemplateDAMock;
        inspectionTemplateDAMock.getByProductIdsAndMaintenancePlanTemplateIdsResult = new List<Inspection_Template__c>{
                new Inspection_Template__c(
                        SM_PS_Product__c = productId,
                        SM_PS_Work_Plan_Template__r = new WorkPlanTemplate(
                                SM_PS_Maintenance_Plan_Template__c = maintenancePlanTemplateId
                        ),
                        SM_PS_How_to_Maintain__c = 'D',
                        SM_PS_When_to_Perform_Step__c = 1
                )
        };

        SBR_3_0_MaintenanceWorkRuleTemplateDAMock maintenanceWorkRuleTemplateDAMock = new SBR_3_0_MaintenanceWorkRuleTemplateDAMock();
        maintenanceWorkRuleTemplateDAMock.getByInspectionTemplateIdsResult = new List<SVMXA360__MaintenanceWorkRuleTemplate__c>();
        SBR_3_0_GenMaintWorkRuleTempInvocable.maintenanceWorkRuleTemplateDA = maintenanceWorkRuleTemplateDAMock;
        SBR_3_0_ConditionDAMock conditionDAMock = new SBR_3_0_ConditionDAMock();
        SBR_3_0_GenMaintWorkRuleTempInvocable.conditionDA = conditionDAMock;

        SBR_3_0_TechnicalAttributeDAMock technicalAttributeDAMock = new SBR_3_0_TechnicalAttributeDAMock();
        SBR_3_0_GenMaintWorkRuleTempInvocable.technicalAttributeDA = technicalAttributeDAMock;
        technicalAttributeDAMock.getTemplateByNameResult = new SVMXA360__SM_TA_Template__c(Id = getMockId(SVMXA360__SM_TA_Template__c.SObjectType));
        technicalAttributeDAMock.getCategoryByNameResult = new SVMXA360__SM_TA_Category__c(Id = getMockId(SVMXA360__SM_TA_Category__c.SObjectType));
        technicalAttributeDAMock.getByNamesResult = new List<SVMXA360__SM_TA_TechnicalAttribute__c>{
                new SVMXA360__SM_TA_TechnicalAttribute__c(
                        Id = getMockId(SVMXA360__SM_TA_TechnicalAttribute__c.SObjectType),
                        Name = 'Calendar Days'
                )
        };
        Test.startTest();
        {
            SBR_3_0_GenMaintWorkRuleTempInvocable.generateMaintenanceWorkRuleTemplates(null);
        }

        Assert.isNotNull(maintenanceWorkRuleTemplateDAMock.upsertedMaintenanceWorkRuleTemplates);
        Assert.isNotNull(conditionDAMock.insertedConditions);
    }

    @IsTest
    static void getApplicableProductForInspectionTemplate_hasMatch() {
        Id mockProductId1 = getMockId(Product2.SObjectType);
        Id mockProductId2 = getMockId(Product2.SObjectType);
        Id mockMaintenancePlanTemplateId = getMockId(SVMXA360__MaintenancePlanTemplate__c.SObjectType);
        Id mockWorkPlanTemplateId = getMockId(WorkPlanTemplate.SObjectType);
        Id matchingApplicableProductId = getMockId(SVMXA360__ApplicableProduct__c.SObjectType);
        Id nonMatchingApplicableProductId = getMockId(SVMXA360__ApplicableProduct__c.SObjectType);
        WorkPlanTemplate workPlanTemplate = new WorkPlanTemplate(
                Id = mockWorkPlanTemplateId,
                SM_PS_Maintenance_Plan_Template__c = mockMaintenancePlanTemplateId
        );
        Inspection_Template__c inspectionTemplate = new Inspection_Template__c(
                SM_PS_Product__c = mockProductId1,
                SM_PS_Work_Plan_Template__c = mockWorkPlanTemplateId,
                SM_PS_Work_Plan_Template__r = workPlanTemplate
        );
        SVMXA360__ApplicableProduct__c matchingApplicableProduct = new SVMXA360__ApplicableProduct__c(
                Id = matchingApplicableProductId,
                SVMXA360__ProductId__c = mockProductId1,
                SVMXA360__MaintenancePlanTemplateId__c = mockMaintenancePlanTemplateId
        );
        SVMXA360__ApplicableProduct__c nonMatchingApplicableProduct = new SVMXA360__ApplicableProduct__c(
                Id = nonMatchingApplicableProductId,
                SVMXA360__ProductId__c = mockProductId2,
                SVMXA360__MaintenancePlanTemplateId__c = mockMaintenancePlanTemplateId
        );
        SVMXA360__ApplicableProduct__c result;
        Test.startTest();
        {
            result = SBR_3_0_GenMaintWorkRuleTempInvocable.getApplicableProductForInspectionTemplate(
                    new List<SVMXA360__ApplicableProduct__c>{
                            nonMatchingApplicableProduct, matchingApplicableProduct
                    },
                    inspectionTemplate
            );
        }
        Test.stopTest();
        Assert.areEqual(matchingApplicableProductId, result.Id);
    }

    @IsTest
    static void getApplicableProductForInspectionTemplate_hasNoMatch() {
        Id mockProductId1 = getMockId(Product2.SObjectType);
        Id mockProductId2 = getMockId(Product2.SObjectType);
        Id mockMaintenancePlanTemplateId = getMockId(SVMXA360__MaintenancePlanTemplate__c.SObjectType);
        Id mockWorkPlanTemplateId = getMockId(WorkPlanTemplate.SObjectType);
        Id mockApplicableProductId = getMockId(SVMXA360__ApplicableProduct__c.SObjectType);
        WorkPlanTemplate workPlanTemplate = new WorkPlanTemplate(
                Id = mockWorkPlanTemplateId,
                SM_PS_Maintenance_Plan_Template__c = mockMaintenancePlanTemplateId
        );
        Inspection_Template__c inspectionTemplate = new Inspection_Template__c(
                SM_PS_Product__c = mockProductId1,
                SM_PS_Work_Plan_Template__c = mockWorkPlanTemplateId,
                SM_PS_Work_Plan_Template__r = workPlanTemplate
        );
        SVMXA360__ApplicableProduct__c applicableProduct = new SVMXA360__ApplicableProduct__c(
                Id = mockApplicableProductId,
                SVMXA360__ProductId__c = mockProductId2,
                SVMXA360__MaintenancePlanTemplateId__c = mockMaintenancePlanTemplateId
        );
        Boolean encounteredException = false;
        Test.startTest();
        {
            try {
                SBR_3_0_GenMaintWorkRuleTempInvocable.getApplicableProductForInspectionTemplate(
                        new List<SVMXA360__ApplicableProduct__c>{applicableProduct},
                        inspectionTemplate
                );
            } catch (IllegalArgumentException ex) {
                encounteredException = true;
            }
        }
        Test.stopTest();
        Assert.isTrue(encounteredException);
    }

    @IsTest
    static void getAdvancedExpressionValue_oneOrTwo() {
        String result;
        Test.startTest();
        {
            result = SBR_3_0_GenMaintWorkRuleTempInvocable.getAdvancedExpressionValue(
                    new Inspection_Template__c(
                            SM_PS_How_to_Maintain__c = 'D',
                            SM_PS_When_to_Perform_Step__c = 1,
                            SM_PS_How_to_Maintain_2__c = 'R',
                            SM_PS_When_to_Perform_Step_2__c = 2
                    )
            );
        }
        Test.stopTest();

        Assert.areEqual('1 OR 2', result);
    }

    @IsTest
    static void getAdvancedExpressionValue_one() {
        String result;
        Test.startTest();
        {
            result = SBR_3_0_GenMaintWorkRuleTempInvocable.getAdvancedExpressionValue(
                    new Inspection_Template__c(
                            SM_PS_How_to_Maintain__c = 'D',
                            SM_PS_When_to_Perform_Step__c = 1
                    )
            );
        }
        Test.stopTest();

        Assert.areEqual('1', result);
    }

    @IsTest
    static void getAdvancedExpressionValue_exception() {
        Boolean encounteredException = false;
        Test.startTest();
        {
            try {
                SBR_3_0_GenMaintWorkRuleTempInvocable.getAdvancedExpressionValue(new Inspection_Template__c());
            } catch (IllegalArgumentException ex) {
                encounteredException = true;
            }
        }
        Test.stopTest();

        Assert.isTrue(encounteredException);
    }

    @IsTest
    static void generateCondition_one() {
        String howToMaintain = 'D';
        Decimal whenToPerformStep = 1;
        Id mockWorkTypeId = getMockId(WorkType.SObjectType);
        WorkType workType = new WorkType(
                Id = mockWorkTypeId,
                SM_PS_How_to_Maintain__c = howToMaintain,
                SM_PS_When_to_Perform_Step__c = whenToPerformStep
        );

        Id mockMaintenanceWorkRuleTemplateId = getMockId(SVMXA360__MaintenanceWorkRuleTemplate__c.SObjectType);
        SVMXA360__MaintenanceWorkRuleTemplate__c maintenanceWorkRuleTemplate = new SVMXA360__MaintenanceWorkRuleTemplate__c(
                Id = mockMaintenanceWorkRuleTemplateId,
                SVMXA360__WorkTypeId__c = mockWorkTypeId,
                SVMXA360__WorkTypeId__r = workType
        );

        Id mockTechnicalAttributeId = getMockId(SVMXA360__SM_TA_TechnicalAttribute__c.SObjectType);
        Map<String, Id> howToMaintainAbbreviationToId = new Map<String, Id>{
                howToMaintain => mockTechnicalAttributeId
        };

        Id mockTechnicalAttributeCategoryId = getMockId(SVMXA360__SM_TA_Category__c.SObjectType);
        SBR_3_0_GenMaintWorkRuleTempInvocable.technicalAttributeCategoryId = mockTechnicalAttributeCategoryId;

        SVMXA360__SM_Condition__c result;

        Test.startTest();
        {
            result = SBR_3_0_GenMaintWorkRuleTempInvocable.generateCondition(maintenanceWorkRuleTemplate, howToMaintainAbbreviationToId, 1);
        }
        Test.stopTest();

        Assert.areEqual(1, result.SVMXA360__Sequence__c);
        Assert.areEqual(String.valueOf(whenToPerformStep), result.SVMXA360__Operand__c);
        Assert.areEqual(mockTechnicalAttributeId, result.SVMXA360__TechnicalAttribute__c);
        Assert.areEqual(mockMaintenanceWorkRuleTemplateId, result.SVMXA360__MaintenanceWorkRuleTemplate__c);
        Assert.areEqual(mockTechnicalAttributeCategoryId, result.SVMXA360__TechnicalAttributeCategory__c);
    }

    @IsTest
    static void generateCondition_two() {
        String howToMaintain = 'D';
        Decimal whenToPerformStep = 2;
        Id mockWorkTypeId = getMockId(WorkType.SObjectType);
        WorkType workType = new WorkType(
                Id = mockWorkTypeId,
                SM_PS_How_to_Maintain_2__c = howToMaintain,
                SM_PS_When_to_Perform_Step_2__c = whenToPerformStep
        );

        Id mockMaintenanceWorkRuleTemplateId = getMockId(SVMXA360__MaintenanceWorkRuleTemplate__c.SObjectType);
        SVMXA360__MaintenanceWorkRuleTemplate__c maintenanceWorkRuleTemplate = new SVMXA360__MaintenanceWorkRuleTemplate__c(
                Id = mockMaintenanceWorkRuleTemplateId,
                SVMXA360__WorkTypeId__c = mockWorkTypeId,
                SVMXA360__WorkTypeId__r = workType
        );

        Id mockTechnicalAttributeId = getMockId(SVMXA360__SM_TA_TechnicalAttribute__c.SObjectType);
        Map<String, Id> howToMaintainAbbreviationToId = new Map<String, Id>{
                howToMaintain => mockTechnicalAttributeId
        };

        Id mockTechnicalAttributeCategoryId = getMockId(SVMXA360__SM_TA_Category__c.SObjectType);
        SBR_3_0_GenMaintWorkRuleTempInvocable.technicalAttributeCategoryId = mockTechnicalAttributeCategoryId;

        SVMXA360__SM_Condition__c result;

        Test.startTest();
        {
            result = SBR_3_0_GenMaintWorkRuleTempInvocable.generateCondition(maintenanceWorkRuleTemplate, howToMaintainAbbreviationToId, 2);
        }
        Test.stopTest();

        Assert.areEqual(2, result.SVMXA360__Sequence__c);
        Assert.areEqual(String.valueOf(whenToPerformStep), result.SVMXA360__Operand__c);
        Assert.areEqual(mockTechnicalAttributeId, result.SVMXA360__TechnicalAttribute__c);
        Assert.areEqual(mockMaintenanceWorkRuleTemplateId, result.SVMXA360__MaintenanceWorkRuleTemplate__c);
        Assert.areEqual(mockTechnicalAttributeCategoryId, result.SVMXA360__TechnicalAttributeCategory__c);
    }

    @IsTest
    static void generateCondition_three() {
        Boolean encounteredException = false;
        Test.startTest();
        {
            try {
                SBR_3_0_GenMaintWorkRuleTempInvocable.generateCondition(null, null, 3);
            } catch (IllegalArgumentException ex) {
                encounteredException = true;
            }
        }
        Test.stopTest();

        Assert.isTrue(encounteredException);
    }

    @IsTest
    static void generateConditionsTest() {
        Id mockWorkTypeId = getMockId(WorkType.SObjectType);
        WorkType workType = new WorkType(
                Id = mockWorkTypeId,
                SM_PS_How_to_Maintain__c = 'D',
                SM_PS_When_to_Perform_Step__c = 1,
                SM_PS_How_to_Maintain_2__c = 'R',
                SM_PS_When_to_Perform_Step_2__c = 2
        );

        Id mockMaintenanceWorkRuleTemplateId = getMockId(SVMXA360__MaintenanceWorkRuleTemplate__c.SObjectType);
        SVMXA360__MaintenanceWorkRuleTemplate__c maintenanceWorkRuleTemplate = new SVMXA360__MaintenanceWorkRuleTemplate__c(
                Id = mockMaintenanceWorkRuleTemplateId,
                SVMXA360__WorkTypeId__c = mockWorkTypeId,
                SVMXA360__WorkTypeId__r = workType
        );

        Id mockTechnicalAttributeCategoryId = getMockId(SVMXA360__SM_TA_Category__c.SObjectType);
        SBR_3_0_GenMaintWorkRuleTempInvocable.technicalAttributeCategoryId = mockTechnicalAttributeCategoryId;

        SBR_3_0_TechnicalAttributeDAMock technicalAttributeDAMock = new SBR_3_0_TechnicalAttributeDAMock();
        SBR_3_0_GenMaintWorkRuleTempInvocable.technicalAttributeDA = technicalAttributeDAMock;
        technicalAttributeDAMock.getByNamesResult = new List<SVMXA360__SM_TA_TechnicalAttribute__c>{
                new SVMXA360__SM_TA_TechnicalAttribute__c(
                        Id = getMockId(SVMXA360__SM_TA_TechnicalAttribute__c.SObjectType),
                        Name = 'Calendar Days'
                ),
                new SVMXA360__SM_TA_TechnicalAttribute__c(
                        Id = getMockId(SVMXA360__SM_TA_TechnicalAttribute__c.SObjectType),
                        Name = 'Rental Days'
                )
        };

        List<SVMXA360__SM_Condition__c> results;

        Test.startTest();
        {
            results = SBR_3_0_GenMaintWorkRuleTempInvocable.generateConditions(
                    new List<SVMXA360__MaintenanceWorkRuleTemplate__c>{maintenanceWorkRuleTemplate}
            );
        }
        Test.stopTest();

        Assert.areEqual(2, results.size());

    }

    @IsTest
    static void maintenanceWorkRuleComparator_sameTechnicalAttribute_shouldReturnPositive() {
        SVMXA360__MaintenanceWorkRuleTemplate__c maintenanceWorkRuleTemplate1 = new SVMXA360__MaintenanceWorkRuleTemplate__c(
                SVMXA360__WorkTypeId__r = new WorkType(
                        SM_PS_How_to_Maintain__c = 'D',
                        SM_PS_When_to_Perform_Step__c = 1
                )
        );
        SVMXA360__MaintenanceWorkRuleTemplate__c maintenanceWorkRuleTemplate2 = new SVMXA360__MaintenanceWorkRuleTemplate__c(
                SVMXA360__WorkTypeId__r = new WorkType(
                        SM_PS_How_to_Maintain__c = 'D',
                        SM_PS_When_to_Perform_Step__c = 2
                )
        );
        Integer result;

        Test.startTest();
        {
            result = new SBR_3_0_GenMaintWorkRuleTempInvocable.MaintenanceWorkRuleComparator().compare(
                    maintenanceWorkRuleTemplate1, maintenanceWorkRuleTemplate2
            );
        }
        Test.stopTest();

        Assert.isTrue(result > 0);
    }

    @IsTest
    static void maintenanceWorkRuleComparator_sameTechnicalAttribute_shouldReturnNegative() {
        SVMXA360__MaintenanceWorkRuleTemplate__c maintenanceWorkRuleTemplate1 = new SVMXA360__MaintenanceWorkRuleTemplate__c(
                SVMXA360__WorkTypeId__r = new WorkType(
                        SM_PS_How_to_Maintain__c = 'D',
                        SM_PS_When_to_Perform_Step__c = 2
                )
        );
        SVMXA360__MaintenanceWorkRuleTemplate__c maintenanceWorkRuleTemplate2 = new SVMXA360__MaintenanceWorkRuleTemplate__c(
                SVMXA360__WorkTypeId__r = new WorkType(
                        SM_PS_How_to_Maintain__c = 'D',
                        SM_PS_When_to_Perform_Step__c = 1
                )
        );
        Integer result;

        Test.startTest();
        {
            result = new SBR_3_0_GenMaintWorkRuleTempInvocable.MaintenanceWorkRuleComparator().compare(
                    maintenanceWorkRuleTemplate1, maintenanceWorkRuleTemplate2
            );
        }
        Test.stopTest();

        Assert.isTrue(result < 0);
    }

    @IsTest
    static void maintenanceWorkRuleComparator_sameTechnicalAttribute_shouldReturnZero() {
        SVMXA360__MaintenanceWorkRuleTemplate__c maintenanceWorkRuleTemplate = new SVMXA360__MaintenanceWorkRuleTemplate__c(
                SVMXA360__WorkTypeId__r = new WorkType(
                        SM_PS_How_to_Maintain__c = 'D',
                        SM_PS_When_to_Perform_Step__c = 1
                )
        );
        Integer result;

        Test.startTest();
        {
            result = new SBR_3_0_GenMaintWorkRuleTempInvocable.MaintenanceWorkRuleComparator().compare(
                    maintenanceWorkRuleTemplate, maintenanceWorkRuleTemplate
            );
        }
        Test.stopTest();

        Assert.areEqual(0, result);
    }

    @IsTest
    static void maintenanceWorkRuleComparator_differentTechnicalAttribute() {
        SVMXA360__MaintenanceWorkRuleTemplate__c maintenanceWorkRuleTemplate1 = new SVMXA360__MaintenanceWorkRuleTemplate__c(
                SVMXA360__WorkTypeId__r = new WorkType(SM_PS_How_to_Maintain__c = 'D')
        );
        SVMXA360__MaintenanceWorkRuleTemplate__c maintenanceWorkRuleTemplate2 = new SVMXA360__MaintenanceWorkRuleTemplate__c(
                SVMXA360__WorkTypeId__r = new WorkType(SM_PS_How_to_Maintain__c = 'R')
        );
        Integer result;

        Test.startTest();
        {
            result = new SBR_3_0_GenMaintWorkRuleTempInvocable.MaintenanceWorkRuleComparator().compare(
                    maintenanceWorkRuleTemplate1, maintenanceWorkRuleTemplate2
            );
        }
        Test.stopTest();

        Assert.isTrue(result < 0);
    }

    @IsTest
    static void getTechnicalAttributeTemplateIdTest() {
        Id mockTemplateId = getMockId(SVMXA360__SM_TA_Template__c.SObjectType);
        SBR_3_0_TechnicalAttributeDAMock technicalAttributeDAMock = new SBR_3_0_TechnicalAttributeDAMock();
        SBR_3_0_GenMaintWorkRuleTempInvocable.technicalAttributeDA = technicalAttributeDAMock;
        technicalAttributeDAMock.getTemplateByNameResult = new SVMXA360__SM_TA_Template__c(Id = mockTemplateId);
        Id result;
        Test.startTest();
        {
            result = SBR_3_0_GenMaintWorkRuleTempInvocable.getTechnicalAttributeTemplateId();
        }
        Test.stopTest();

        Assert.isNotNull(result);
        Assert.areEqual(mockTemplateId, result);
    }

    @IsTest
    static void getTechnicalAttributeCategoryIdTest() {
        Id mockCategoryId = getMockId(SVMXA360__SM_TA_Category__c.SObjectType);
        SBR_3_0_TechnicalAttributeDAMock technicalAttributeDAMock = new SBR_3_0_TechnicalAttributeDAMock();
        SBR_3_0_GenMaintWorkRuleTempInvocable.technicalAttributeDA = technicalAttributeDAMock;
        technicalAttributeDAMock.getCategoryByNameResult = new SVMXA360__SM_TA_Category__c(Id = mockCategoryId);
        Id result;
        Test.startTest();
        {
            result = SBR_3_0_GenMaintWorkRuleTempInvocable.getTechnicalAttributeCategoryId();
        }
        Test.stopTest();

        Assert.isNotNull(result);
        Assert.areEqual(mockCategoryId, result);
    }

    private static Id getMockId(SObjectType sObjectType) {
        return (Id)(sObjectType.getDescribe().keyPrefix + String.valueOf(mockIdOffset++).leftPad(12, '0'));
    }

    class SBR_3_0_ApplicableProductDAMock implements SBR_3_0_ApplicableProductDAInterface {
        List<SVMXA360__ApplicableProduct__c> getByMaintenancePlanTemplateIdsResult;
        public List<SVMXA360__ApplicableProduct__c> getByMaintenancePlanTemplateIds(List<Id> maintenancePlanTemplateIds) {
            return getByMaintenancePlanTemplateIdsResult;
        }
    }

    class SBR_3_0_ConditionDAMock implements SBR_3_0_ConditionDAInterface {
        List<SVMXA360__SM_Condition__c> insertedConditions;
        public List<SVMXA360__SM_Condition__c> insertConditions(List<SVMXA360__SM_Condition__c> conditions) {
            insertedConditions = conditions;
            return conditions;
        }
    }

    class SBR_3_0_InspectionTemplateDAMock implements SBR_3_0_InspectionTemplateDAInterface {
        List<Inspection_Template__c> getByProductIdsAndMaintenancePlanTemplateIdsResult;
        public List<Inspection_Template__c> getByProductIdsAndMaintenancePlanTemplateIds(Set<Id> productIds, Set<Id> maintenancePlanTemplateIds) {
            return getByProductIdsAndMaintenancePlanTemplateIdsResult;
        }
    }

    class SBR_3_0_MaintenanceWorkRuleTemplateDAMock implements SBR_3_0_MaintenanceWorkRuleTemplateDAI {
        List<SVMXA360__MaintenanceWorkRuleTemplate__c> upsertedMaintenanceWorkRuleTemplates;
        public List<SVMXA360__MaintenanceWorkRuleTemplate__c> upsertMaintenanceWorkRuleTemplates(List<SVMXA360__MaintenanceWorkRuleTemplate__c> maintenanceWorkRuleTemplates) {
            upsertedMaintenanceWorkRuleTemplates = maintenanceWorkRuleTemplates;
            return maintenanceWorkRuleTemplates;
        }

        List<SVMXA360__MaintenanceWorkRuleTemplate__c> getByInspectionTemplateIdsResult;
        public List<SVMXA360__MaintenanceWorkRuleTemplate__c> getByInspectionTemplateIds(Set<Id> inspectionTemplateIds) {
            return getByInspectionTemplateIdsResult;
        }
    }

    class SBR_3_0_TechnicalAttributeDAMock implements SBR_3_0_TechnicalAttributeDAInterface {
        public List<SVMXA360__SM_TA_TechnicalAttribute__c> getByNamesResult;
        public List<SVMXA360__SM_TA_TechnicalAttribute__c> getByNames(Set<String> names) {
            return getByNamesResult;
        }

        SVMXA360__SM_TA_Template__c getTemplateByNameResult;
        public SVMXA360__SM_TA_Template__c getTemplateByName(String name) {
            return getTemplateByNameResult;
        }

        SVMXA360__SM_TA_Category__c getCategoryByNameResult;
        public SVMXA360__SM_TA_Category__c getCategoryByName(String name) {
            return getCategoryByNameResult;
        }
    }
}