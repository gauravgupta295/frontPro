/*********************************************************************************************************************
* Apex Class: SBR_3_0_WorkPlanTemplateTriggerHandler
----------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Class to manage trigger logic for Work Plan Template
* - SERV-2671 - Autocreate a Maintenance Plan Template when Work Plan Template is updated.
---------------------------------------------------------------------------------------------------------------------
* History:
* VERSION     DEVELOPER NAME                    DATE                DETAIL FEATURES
    1.0       Ritesh Mohapatra                  2023-Sep-08         Initial version 
*********************************************************************************************************************/
public class SBR_3_0_WorkPlanTemplateTriggerHandler extends SBR_3_0_TriggerHandler
{

	@TestVisible
    private Map<Id, WorkPlanTemplate > oldWorkPlanTmpMap;
    @TestVisible
    private Map<Id, WorkPlanTemplate > newWorkPlanTmpMap;
    @TestVisible
    private List<WorkPlanTemplate > newWorkPlanTmpList;
    @TestVisible
    private Boolean isUpdateValue;
    
    public SBR_3_0_WorkPlanTemplateTriggerHandler() {
        this.oldWorkPlanTmpMap = (Map<Id, WorkPlanTemplate >) Trigger.oldMap;
        this.newWorkPlanTmpMap = (Map<Id, WorkPlanTemplate >) Trigger.newMap;
        this.newWorkPlanTmpList = (List<WorkPlanTemplate >) Trigger.new;
        this.isUpdateValue = Trigger.isUpdate;
    }
    
    public override void afterUpdate() 
    {    
        SBR_3_0_WorkPlanTemplateOperations.createMaintenancePlanTemplate(newWorkPlanTmpMap,oldWorkPlanTmpMap);

    }
}