/*********************************************************************************************************************
* Apex Class: SBR_3_0_InspectionTemplateTriggerHandler
----------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - SERV-4125 - Validate duplicate creation of Inspection Template
---------------------------------------------------------------------------------------------------------------------
* History:
* VERSION     DEVELOPER NAME                    DATE                DETAIL FEATURES
    1.0       Ritesh Mohapatra                  2023-Sep-19        Initial version
    2.0       Evan Kuminski                     2023-Oct-19        Add call to generateEqpMaintenanceStepOutboxesOnDeactivation()
*********************************************************************************************************************/

public class SBR_3_0_InspectionTemplateTriggerHandler extends SBR_3_0_TriggerHandler
{
	@TestVisible
    private Map<Id, Inspection_Template__c > oldInsTempMap;
    @TestVisible
    private Map<Id, Inspection_Template__c > newInsTempMap;
    @TestVisible
    private List<Inspection_Template__c > newInsTempList;
    @TestVisible
    
    private Boolean isUpdateValue;
    
    public SBR_3_0_InspectionTemplateTriggerHandler() {
        this.oldInsTempMap = (Map<Id, Inspection_Template__c >) Trigger.oldMap;
        this.newInsTempMap = (Map<Id, Inspection_Template__c >) Trigger.newMap;
        this.newInsTempList = (List<Inspection_Template__c >) Trigger.new;
        this.isUpdateValue = Trigger.isUpdate;
    }
    
    public override void beforeInsert() 
    {   
        SBR_3_0_InspectionTemplateOperations.inspectionTempValidation(newInsTempList, oldInsTempMap);

    }
    
    public override void beforeUpdate()
    {
        SBR_3_0_InspectionTemplateOperations.inspectionTempValidation(newInsTempList, oldInsTempMap);
        SBR_3_0_InspectionTemplateOperations.generateEqpMaintenanceStepOutboxesOnDeactivation(newInsTempList, oldInsTempMap);
    }
}