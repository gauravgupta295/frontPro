/*********************************************************************************************************************
* Apex Class: SBR_3_0_LocationOperations_Test
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Test classClass to publish Location records of Branch record type to Outbox object
* - SAL-1424
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME                      DATE                 DETAIL FEATURES
    1.0         Tom Canter                         2022-09-27            Initial version    
*********************************************************************************************************************/

@isTest
public with sharing class SBR_3_0_EquipmentTypeOperations_Test {
    @isTest static void publishEquipmentTypeTest(){
        List<Equipment_Type__c> et = SBR_3_0_TestDataFactory.createEquipmentTypes(1, True);
        Id ide;
        System.debug(ide);
        for (Equipment_Type__c ets : et){
            ide=ets.Id;
        }
        List<Outbox__c> out =  [Select id from Outbox__c];
        System.Debug(out);
        System.assertNotEquals(out, null, 'Outbox did not receive the Equipment Type record');
    }

}