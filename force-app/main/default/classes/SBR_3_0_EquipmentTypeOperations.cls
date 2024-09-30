/*********************************************************************************************************************
* Apex Class: SBR_3_0_EquipmentTypeOperations
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Class to publish Equipment Type to Outbox object
* - SAL-1424
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME                      DATE                 DETAIL FEATURES
    1.0         Tom Canter                          2022-09-27           Initial version    
*********************************************************************************************************************/

public with sharing class SBR_3_0_EquipmentTypeOperations {

  public static void publishEquipmentType(Map<Id, Equipment_Type__c> newEquipmentTypeMap){
      Map<Id, Equipment_Type__c> equipmentTypeToPublish = new Map<Id, Equipment_Type__c>();

      for (Id ide : newEquipmentTypeMap.keySet()){    
        equipmentTypeToPublish.put(ide, newEquipmentTypeMap.get(ide));
      }
      if (equipmentTypeToPublish.size()>0){
        SBR_3_0_PublishRecordsToOutbox publishEquipmentType = new SBR_3_0_PublishRecordsToOutbox(equipmentTypeToPublish, SBR_3_0_Constants.EQUIPMENTTYPE_API_NAME);
        publishEquipmentType.publish();
      }
  }

}