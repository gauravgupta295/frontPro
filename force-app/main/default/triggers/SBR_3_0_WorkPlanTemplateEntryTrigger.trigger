/*********************************************************************************************************************
Apex Trigger : SBR_3_0_WorkPlanTemplateEntryTrigger
---------------------------------------------------------------------------------------------------------------------
Purpose/Methods: Operations on Change, Create and Delete of Work Plan Template Entry Records (SERV-2640)
---------------------------------------------------------------------------------------------------------------------
History:
VERSION     DEVELOPER NAME                      DATE                 DETAIL FEATURES
1.0         Ritesh Mohapatra (ServiceMax)       2023-08-24           Initial version   
*********************************************************************************************************************/
trigger SBR_3_0_WorkPlanTemplateEntryTrigger on WorkPlanTemplateEntry (before insert, before update, before delete) 
{
	new SBR_3_0_WorkPlanTemplateEntryHandler().run();
}