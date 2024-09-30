/*********************************************************************************************************************
* Apex Class: SBR_3_0_TerritoryDA
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Concrete class for Territory Data Access
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Rohan Dhavale         2023-09-01            Initial version    
*********************************************************************************************************************/
public with sharing class SBR_3_0_TerritoryDA implements SBR_3_0_TerritoryDAInterface {
    
    public static List<Territory__c> getTerritories(Set<Id> userIds){
      return [SELECT Id, OwnerId, Territory_ID__c FROM Territory__c WHERE OwnerId IN :userIds];
    }
}