/**
 * @description       : Apex subscription trigger for SBR_3_0_Data_Store_Staging_Event__e events (FRONT-17961)
 * @author            : soomjeet.sahoo
 * @group             : Salesforce.com
 * @last modified on  : 04-29-2024
 * @last modified by  : soomjeet.sahoo
 **/
trigger SBR_3_0_DataStoreStagingTrigger on SBR_3_0_Data_Store_Staging_Event__e(
  after insert
) {
  SBR_3_0_DataStoreStagingTriggerHandler.afterInsertLogic(Trigger.New);
}