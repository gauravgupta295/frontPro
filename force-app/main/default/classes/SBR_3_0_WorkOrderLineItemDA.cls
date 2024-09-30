/*********************************************************************************************************************
* Apex Class: SBR_3_0_WorkOrderLineItemDA
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Concrete class for WorkOrderLineItem
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION       DATE               DETAIL FEATURES
    1.0          2023-02-23          Initial version    
**********************************************************************************************************************************************/

public with sharing class SBR_3_0_WorkOrderLineItemDA implements SBR_3_0_WorkOrderLineItemDAInterface {
    // Get all Woli records by workOrder Id
    @AuraEnabled//(cacheable=true)
    public static List<WorkOrderLineItem> getWoliTableRecs(ID recId){
       List<WorkOrderLineItem> woliRecs = new List<WorkOrderLineItem>();

       woliRecs =[select Id,SF_PS_Mechanic_Id__c,SF_PS_Mechanic_Name__c,
                  SF_PS_Mechanic_Name__r.SF_PS_Mechanic_Id__c, 
                  SF_PS_Mechanic_Name__r.SF_PS_Labor_Type__c,
                  SF_PS_Mechanic_Name__r.Name,SF_PS_Mechanic_Name__r.Id,
                  SF_PS_Mechanic_Name__r.SF_PS_Hourly_Internal_Rate__c,
                  SF_PS_Mechanic_Name__r.ResourceType, SF_PS_Mechanic_Name__r.IsActive,
                  toLabel(SF_PS_Line_Type__c),SF_PS_Labor_Code__c,Duration, SF_PS_Extended_Rate__c
                 from WorkOrderLineItem 
                 where WorkOrder.Id= :recId];

      return  woliRecs;

    }
}