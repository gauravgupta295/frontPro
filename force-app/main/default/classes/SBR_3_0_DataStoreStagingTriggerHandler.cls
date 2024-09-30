/*********************************************************************************************************************
* Apex Class:  SBR_3_0_DataStoreStagingTriggerHandler
---------------------------------------------------------------------------------------------------------------------------------------
* @description :
* - Trigger handler logic for SBR_3_0_DataStoreStagingTrigger 
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME                      DATE                 DETAIL FEATURES
    1.0         Soomjeet Sahoo                     2024-04-30            Initial version 
*********************************************************************************************************************/
public with sharing class SBR_3_0_DataStoreStagingTriggerHandler {
  /**
   * @description : Method for Calling After insert logic (FRONT-17961)
   * @author soomjeet.sahoo | 05-07-2024
   * @param newDataStoreList
   **/
  public static void afterInsertLogic(
    List<SBR_3_0_Data_Store_Staging_Event__e> newDataStoreList
  ) {
    SBR_3_0_DataStoreOperations.initiateDataStoreEntries(
      (List<SBR_3_0_Data_Store_Staging_Event__e>) newDataStoreList
    );
  }
}