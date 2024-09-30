trigger SBR_3_0_EquipmentType on Equipment_Type__c (after insert, after update) {
  new SBR_3_0_EquipmentTypeTriggerHandler().run();
}