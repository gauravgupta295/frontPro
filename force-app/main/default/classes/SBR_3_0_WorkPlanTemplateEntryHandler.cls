/*********************************************************************************************************************
Apex Class : SBR_3_0_WorkPlanTemplateEntryHandler
---------------------------------------------------------------------------------------------------------------------
Purpose/Methods: Operations on Change, Create and Delete of Work Plan Template Entry Records (SERV-2640)
---------------------------------------------------------------------------------------------------------------------
History:
VERSION     DEVELOPER NAME                      DATE                 DETAIL FEATURES
1.0         Ritesh Mohapatra (ServiceMax)       2023-08-24           Initial version   
*********************************************************************************************************************/
public with sharing class SBR_3_0_WorkPlanTemplateEntryHandler extends SBR_3_0_TriggerHandler 
{
        @TestVisible
        private Map<Id, Schema.WorkPlanTemplateEntry> oldWPTEntryMap;
        @TestVisible
        private Map<Id, Schema.WorkPlanTemplateEntry> newWPTEntryMap;
    	@TestVisible
        private List<Schema.WorkPlanTemplateEntry> newWPTEntryList;
    
        public SBR_3_0_WorkPlanTemplateEntryHandler() 
        {
            this.oldWPTEntryMap = (Map<Id, Schema.WorkPlanTemplateEntry>) Trigger.oldMap;
            this.newWPTEntryMap = (Map<Id, Schema.WorkPlanTemplateEntry>) Trigger.newMap;
            this.newWPTEntryList = (List<Schema.WorkPlanTemplateEntry>) Trigger.new;
        }
    
        public override void beforeInsert() 
        {
            SBR_3_0_WorkPlanTemplateEntryOperations.workPlanTemplateValidation(this.oldWPTEntryMap, this.newWPTEntryList);
        }
    
    	
    	public override void beforeDelete() 
        {
            SBR_3_0_WorkPlanTemplateEntryOperations.workPlanTemplateValidation(this.oldWPTEntryMap, this.newWPTEntryList);
        }
     
}