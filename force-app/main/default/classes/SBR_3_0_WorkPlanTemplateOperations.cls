/*********************************************************************************************************************
* Apex Class: SBR_3_0_WorkPlanTemplateOperations
----------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Class to manage trigger logic for Work Plan Template
* - SERV-2671 - Autocreate a Maintenance Plan Template when Work Plan Template is updated.
---------------------------------------------------------------------------------------------------------------------
* History:
* VERSION     DEVELOPER NAME                    DATE                DETAIL FEATURES
    1.0       Ritesh Mohapatra                  2023-Sep-08         Initial version 
*********************************************************************************************************************/
public class SBR_3_0_WorkPlanTemplateOperations 
{
    public static void createMaintenancePlanTemplate(Map<Id, WorkPlanTemplate> newWorkPlanTmpMap, Map<Id, WorkPlanTemplate> oldWorkPlanTmpMap)
    {
       Map<Id,WorkPlanTemplate> newWorkPlanTemplateMap = new Map<Id,WorkPlanTemplate>();
       List<SVMXA360__MaintenancePlanTemplate__c> FinalMPList = new List<SVMXA360__MaintenancePlanTemplate__c>();
       for(WorkPlanTemplate newWPTRecord : newWorkPlanTmpMap.values())
       {
          System.debug('*** Entering Code');
          System.debug('*** newWPTRecord.isActive: '+newWPTRecord.isActive);
          System.debug('*** oldWorkPlanTmpMap.get(newWPTRecord.id).isActive: '+oldWorkPlanTmpMap.get(newWPTRecord.id).isActive);
           
          if(newWPTRecord.isActive == TRUE && oldWorkPlanTmpMap.get(newWPTRecord.id).isActive == FALSE)
             {
                  if(newWPTRecord.SM_PS_Work_Type__c !=null )
                  {
                         System.debug('*** Entering Main Code');
                         newWorkPlanTemplateMap.put(newWPTRecord.id,newWPTRecord); 
                  }
             }            
       }
        if(!newWorkPlanTemplateMap.keyset().isEmpty())
        {
             List<SVMXA360__MaintenancePlanTemplate__c> mpList = [SELECT Id, SVMXA360__WorkTypeId__c 
                                                                   FROM SVMXA360__MaintenancePlanTemplate__c 
                                                                   WHERE SM_PS_Work_Plan_Template__c IN : newWorkPlanTemplateMap.keyset()];  
             System.debug('*** mpList : '+mpList);
             if(!mpList.isEmpty())
             {
                 for(SVMXA360__MaintenancePlanTemplate__c mpRec : mpList)
                 {
                     if(mpRec.SVMXA360__WorkTypeId__c!=null)
                     {
                         newWorkPlanTemplateMap.remove(mpRec.SVMXA360__WorkTypeId__c);
                     }
                 }
             }
            
            if(!newWorkPlanTemplateMap.isEmpty())
            {
                for(WorkPlanTemplate newWPT : newWorkPlanTemplateMap.values())
            	{
                     SVMXA360__MaintenancePlanTemplate__c newMP = new SVMXA360__MaintenancePlanTemplate__c();
                 	 newMP.SM_PS_Work_Plan_Template__c = newWPT.id;
                     newMP.SVMXA360__IsActive__c = TRUE;
                     
                     newMP.SVMXA360__WorkOrderGenerationMethod__c = 'WorkOrderPerAsset';
                     newMP.SVMXA360__MaintenancePlanDuration__c = 99;
                     newMP.SVMXA360__WorkTypeId__c = newWPT.SM_PS_Work_Type__c ;
                     newMP.SVMXA360__MaintenancePlanUnitOfTime__c = 'Years';
                     newMP.SVMXA360__DoesAutoGenerateWorkOrders__c = TRUE;
                     newMP.SVMXA360__DoesGenerateUponCompletion__c = TRUE;
                     FinalMPList.add(newMP);
            	} 
            }  
        }
        System.debug('*** FinalMPList : '+FinalMPList);
        if(!FinalMPList.isEmpty())
        {
           insert FinalMPList;
        }
    }       
}