/*********************************************************************************************************************
* Apex Class: SBR_3_0_CreateWorkPlanTemplateEntries
----------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Invocable class create Work Plan Templates
----------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE          DETAIL FEATURES
    1.0         Ritesh Mohapatra      2023-Aug-28      Initial version
    2.0         Chhavi Singhal        2023-Oct-12      WorkPlanTemplateEntry fields updated
**********************************************************************************************************************/
public class SBR_3_0_CreateWorkPlanTemplateEntries 
{
   @InvocableMethod(label='Create Work Plan Template Entries' 
                     description='Class to Create Work Plan Template Entries'
                     category='Work Plan Template Entry')
   public static void createWPTEntries(List<Requests> requestList)
   {
       List<WorkStepTemplate> SelectedSteps = requestList[0].userSelectedSteps;
       String WorkPlanTempId  = requestList[0].workPlanTemplateID;
       Integer ExecutionOrderCounter ;
       
       List<WorkPlanTemplateEntry> finalWPTEList = new List<WorkPlanTemplateEntry>();
       if(requestList[0].userSelectedSteps.size()>0)
       {
           ExecutionOrderCounter = 0;
           for(WorkStepTemplate newStep : SelectedSteps)
           {	
               ExecutionOrderCounter = ExecutionOrderCounter+1;
               
               WorkPlanTemplateEntry newWPTEntry = new WorkPlanTemplateEntry();
               newWPTEntry.ExecutionOrder = ExecutionOrderCounter;
               newWPTEntry.WorkPlanTemplateId = WorkPlanTempId; 
               newWPTEntry.WorkStepTemplateId = newStep.id;
               newWPTEntry.CurrencyIsoCode = newStep.CurrencyIsoCode;
              
               finalWPTEList.add(newWPTEntry);
           }
           
           if(finalWPTEList.size()>0)
           {
               insert finalWPTEList;
           }
       }
   }
   public class Requests
   {
        @InvocableVariable(label = 'Work Step Templates List' 
                           description = 'Work Step Templates List'
                           required = true)
        public List<WorkStepTemplate> userSelectedSteps;
       
       	@InvocableVariable(label = 'Work Plan Template Id Created' 
                           description = 'Work Plan Template Id Created'
                           required = true)
        public String workPlanTemplateID;
   }
}