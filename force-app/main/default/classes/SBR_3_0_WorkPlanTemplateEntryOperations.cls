/*********************************************************************************************************************
Apex Class : SBR_3_0_WorkPlanTemplateEntryOperations
---------------------------------------------------------------------------------------------------------------------
Purpose/Methods: Operations on Change, Create and Delete of Work Plan Template Entry Records (SERV-2640)
---------------------------------------------------------------------------------------------------------------------
History:
VERSION     DEVELOPER NAME                      DATE                 DETAIL FEATURES
1.0         Ritesh Mohapatra (ServiceMax)       2023-08-24           Initial version   
*********************************************************************************************************************/

public class SBR_3_0_WorkPlanTemplateEntryOperations 
{
	 public static void workPlanTemplateValidation(Map<Id, Schema.WorkPlanTemplateEntry> oldWPTEntryMap, List<Schema.WorkPlanTemplateEntry> newWPTEntryList)
     {
         SBR_3_0_WorkPlanValidator.Requests newRequest = new SBR_3_0_WorkPlanValidator.Requests();
         List<SBR_3_0_WorkPlanValidator.Requests> newRequestList = new List<SBR_3_0_WorkPlanValidator.Requests>();
         
         Set<Id> WPTemplateIdSet = new Set<Id>();
         Set<WorkStepTemplate> WPTempEntryInsertSet = new Set<WorkStepTemplate>();
         Set<WorkStepTemplate> WPTempEntryDeleteSet = new Set<WorkStepTemplate>();
         
         Map<Id,List<WorkStepTemplate>> workPlanIDStepIDMap = new Map<Id,List<WorkStepTemplate>>();
         Map<Id,List<WorkStepTemplate>> ExistingWorkPlanIDStepIDMap = new Map<Id,List<WorkStepTemplate>>();
         Map<Id,String> WorkPlanCompanyCodeMap = new Map<Id,String>();
         List<WorkPlanTemplateEntry> restrictManageList = new List<WorkPlanTemplateEntry>();
         
         if(Trigger.isInsert)
         {
             System.debug('**Insert');
             for(WorkPlanTemplateEntry WPTEntryInsert : newWPTEntryList)
             {
                 if(WPTEntryInsert.SVMX_Work_Plan_Template_Status__c != 'Draft') 
                    
                 {
                     restrictManageList.add(WPTEntryInsert);
                 }
                 
                 WPTemplateIdSet.add(WPTEntryInsert.WorkPlanTemplateId);
                 WorkStepTemplate newWST = new WorkStepTemplate();
                 newWST.Id = WPTEntryInsert.WorkStepTemplateId;
                 WPTempEntryInsertSet.add(newWST);
             }
             
             if(restrictManageList.size()>0)
             {
                 restrictManageList[0].addError('Record can only be edited when Work Plan Template Status = Draft');
             }
         }
         
         if(Trigger.isDelete)
         {
             for(WorkPlanTemplateEntry WPTEntryDelete : oldWPTEntryMap.values())
             {
                 if(WPTEntryDelete.SVMX_Work_Plan_Template_Status__c != 'Draft') 
                    
                 {
                     restrictManageList.add(WPTEntryDelete); 
                 }
                 
                 WPTemplateIdSet.add(WPTEntryDelete.WorkPlanTemplateId);
                 WorkStepTemplate newWST = new WorkStepTemplate();
                 newWST.Id = WPTEntryDelete.WorkStepTemplateId;
                 WPTempEntryDeleteSet.add(newWST);
             }
             
             if(restrictManageList.size()>0)
             {
                 restrictManageList[0].addError('Record can only be edited when Work Plan Template Status = Draft');
             }
         }
		 
         System.debug('***WPTemplateIdSet: '+WPTemplateIdSet);
         if(!WPTemplateIdSet.isEmpty())
         {
             //Query Existing StepTemplateIds for the said Work Plan Template
             List<WorkPlanTemplate> legacyWorkPlanTempList = [SELECT Id, 
                                                                     SVMX_Company_Code__c, 
                                                                     (SELECT Id, WorkPlanTemplateId, WorkStepTemplateId FROM WorkStepTemplates) 
                                                               FROM WorkPlanTemplate 
                                                               WHERE ID IN : WPTemplateIdSet];
             
              for(WorkPlanTemplate WPTemp : legacyWorkPlanTempList)
              {
                 System.debug('***WPTemp.WorkStepTemplates: '+WPTemp.WorkStepTemplates);
                 if(WPTemp.WorkStepTemplates.size()>0)
                 {
                     for(WorkPlanTemplateEntry newWPTEntry : WPTemp.WorkStepTemplates)
                     {
                             //Adds Existing Step IDs of Same Plan Template to Validate Duplication
                             WorkStepTemplate newStep = new WorkStepTemplate();
                             newStep.id = newWPTEntry.WorkStepTemplateId;
                         	
                             if(workPlanIDStepIDMap.keyset().contains(newWPTEntry.WorkPlanTemplateId))
                             {  
                                 workPlanIDStepIDMap.get(newWPTEntry.WorkPlanTemplateId).add(newStep);
                             }
                             
                             else
                             {   
                                 workPlanIDStepIDMap.put(newWPTEntry.WorkPlanTemplateId,new List<WorkStepTemplate>{newStep});
                             } 
                             
                     }
                  } 
                     
                  WorkPlanCompanyCodeMap.put(WPTemp.id,WPTemp.SVMX_Company_Code__c);
              }
             
             for(WorkPlanTemplate WPTemp : legacyWorkPlanTempList)
             {
                 if(workPlanIDStepIDMap.keySet().size()>0)
                 {
                     if(Trigger.isInsert && WPTempEntryInsertSet.size()>0 )
                     {
                         workPlanIDStepIDMap.get(WPTemp.id).addAll(WPTempEntryInsertSet);
                     }
                     
                     if(Trigger.isDelete && WPTempEntryDeleteSet.size()>0)
                     {
                         for(WorkStepTemplate oRec : WPTempEntryDeleteSet)
                         
                         {
                             removeObjectFromList(workPlanIDStepIDMap.get(WPTemp.id),oRec);
                         }
                     }
                 }
             }
             
             if(workPlanIDStepIDMap.keySet().size()==1)
             {
                     for(Id WPTempId :workPlanIDStepIDMap.keySet())
                     {
                         newRequest.userworkPlanSteps = workPlanIDStepIDMap.get(WPTempId);
                         newRequest.companyCode = WorkPlanCompanyCodeMap.get(WPTempId);
                         newRequestList.add(newRequest);
                     }
                     
                     List<WorkPlanTemplate> validatedList = SBR_3_0_WorkPlanValidator.workPlanValidator(newRequestList);
                     
                     if(!validatedList.isEmpty())
                     {
                         WorkPlanTemplate dupPlanTemplate = [SELECT Id, Name FROM WorkPlanTemplate WHERE Id =: validatedList[0].id];
                         if(Trigger.isInsert)
                         newWPTEntryList[0].addError('Duplicate Work Template Found. Name = '+dupPlanTemplate.Name);
                         if(Trigger.isDelete)
                         oldWPTEntryMap.values()[0].addError('Duplicate Work Template Found. Name = '+dupPlanTemplate.Name);
                     }
             }
         }
	 }
    
    public static void removeObjectFromList(List<SObject> lst, SObject o) 
    {
        for (Integer i = lst.size() - 1; i >= 0 ; --i) 
        {
            if (lst.get(i) == o || lst.get(i).get('id') == o.get('id')) {
                lst.remove(i); 
            }
        }
	}
}