/*********************************************************************************************************************
* Apex Class: SBR_3_0_WorkPlanTemplateTrigger
---------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* SERV-2671 - Autocreate a Maintenance Plan Template when Work Plan Template is updated.
---------------------------------------------------------------------------------------------------------------------
* History:
* VERSION     DEVELOPER NAME                     DATE                 DETAIL FEATURES
  1.0         Ritesh Mohapatra                   2023-Sep-08          Initial version    
***********************************************************************************************************************/


trigger SBR_3_0_WorkPlanTemplateTrigger on WorkPlanTemplate (after update) 
{
    new SBR_3_0_WorkPlanTemplateTriggerHandler().run();
}