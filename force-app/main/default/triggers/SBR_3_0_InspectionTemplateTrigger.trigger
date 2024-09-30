/*********************************************************************************************************************
* Apex Class: SBR_3_0_InspectionTemplateTrigger
---------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* SERV-4125 - Validate duplicate creation of Inspection Template
---------------------------------------------------------------------------------------------------------------------
* History:
* VERSION     DEVELOPER NAME                     DATE                 DETAIL FEATURES
  1.0         Ritesh Mohapatra                   2023-Sep-19          Initial version
  2.0         Evan Kuminski                      2023-Oct-19          Now also runs before update
***********************************************************************************************************************/
trigger SBR_3_0_InspectionTemplateTrigger on Inspection_Template__c (before insert, before update)
{
    new SBR_3_0_InspectionTemplateTriggerHandler().run();
}