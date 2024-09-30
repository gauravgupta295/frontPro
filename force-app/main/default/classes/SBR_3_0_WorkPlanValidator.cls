/*********************************************************************************************************************
* Apex Class: SBR_3_0_WorkPlanValidator
----------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Invocable class validate duplicate creation of Work Plan Template Record
----------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE          DETAIL FEATURES
    1.0         Ritesh Mohapatra      2023-Aug-7      Initial version
    2.0         Chhavi Singhal        2023-Nov-27     Adding workType & maintenancePlanTemplate as well in duplicate 
													  validation criteria 
**********************************************************************************************************************/

public class SBR_3_0_WorkPlanValidator {
   @InvocableMethod(label='Work Plan Validator' 
                     description='Method to validate duplicate creation of Work Plan Template Record'
                     category='Work Plan Template Entry')
   public static List<WorkPlanTemplate> workPlanValidator(List<Requests> requestList) {
       //Deserialize Parameters from Flow
       List<WorkPlanTemplateEntry> workPlanEntriesList = requestList.get(0).userworkPlanTempEntries;
       List<WorkStepTemplate> workPlanStepsList = requestList.get(0).userworkPlanSteps;
       String WorkPlanCompanyCode = requestList.get(0).companyCode;
       Integer NoOfEntries = requestList.get(0).userworkPlanSteps.size();
       Id workType = requestList.get(0).userWorkType;
       Id maintenancePlanTemplate = requestList.get(0).userMaintenancePlanTemplate;
       
       List<id> workPlanStepTemplateIds = new List<id>();
       List<WorkPlanTemplate> WorkPlanTemplateList = new List<WorkPlanTemplate>();
       Map<Id,List<WorkPlanTemplateEntry>> WorkPlanTempMap = new Map<Id,List<WorkPlanTemplateEntry>>();
       Map<Id,WorkPlanTemplate> WorkPlanRecordMap = new Map<Id,WorkPlanTemplate>();
       List<WorkPlanTemplate> finalWorkPlanList = new List<WorkPlanTemplate>();
       Integer counter;
       
       //Store workPlanStepTemplate Ids
       if(!workPlanStepsList.isEmpty()) {
           for(WorkStepTemplate WSTRecord : workPlanStepsList) {
               workPlanStepTemplateIds.add(WSTRecord.Id);
           }
       }
	   
       if(workType != null) {
           if(maintenancePlanTemplate != null){
               //Retrieve All Existing Work Plan Templates
               WorkPlanTemplateList = [SELECT Id, SVMX_Company_Code__c, SM_PS_Work_Type__c, SM_PS_Maintenance_Plan_Template__c,
                                              (SELECT Id, WorkStepTemplateId FROM WorkStepTemplates) 
                                       FROM WorkPlanTemplate
                                       WHERE SM_PS_Work_Type__c =: workType
                                       AND SM_PS_Maintenance_Plan_Template__c =: maintenancePlanTemplate];
           }else {
               WorkPlanTemplateList = [SELECT Id, SVMX_Company_Code__c, SM_PS_Work_Type__c,
                                              (SELECT Id, WorkStepTemplateId FROM WorkStepTemplates) 
                                       FROM WorkPlanTemplate
                                       WHERE SM_PS_Work_Type__c =: workType];
           }
           //Create Map to store existing Work Plan Templates and their Entries
           if(!WorkPlanTemplateList.isEmpty()) {
               for(WorkPlanTemplate oWorkPlanTempRec : WorkPlanTemplateList) {
                   //Chances of Duplicate Match of Work Plan Template
                   if(oWorkPlanTempRec.WorkStepTemplates.size()==NoOfEntries) {
                       //Chances of Duplicate Match of Work Plan Template
                       WorkPlanTempMap.put(oWorkPlanTempRec.id, oWorkPlanTempRec.WorkStepTemplates);
                       WorkPlanRecordMap.put(oWorkPlanTempRec.id,oWorkPlanTempRec);
                   }                
               }    
           }
           
           if(!WorkPlanTempMap.keyset().isEmpty()) {
               for(Id WorkPlanTempId : WorkPlanTempMap.keyset()) {
                   counter = 0; 
                   for(WorkPlanTemplateEntry oWPTE : WorkPlanTempMap.get(WorkPlanTempId)) {
                       if(workPlanStepTemplateIds.contains(oWPTE.WorkStepTemplateId)) {
                           counter = counter + 1;
                       }
                   }
                   //Condition for Perfect Duplicate
                   if(counter == NoOfEntries) {
                       //Perfect Match of Work Plan Template
                       finalWorkPlanList.add(WorkPlanRecordMap.get(WorkPlanTempId));
                       return finalWorkPlanList;
                   } else {
                       counter = null;
                   }
               }
           }
       }
       
       if(counter == null) {
           //No Match Found. Allow Work Plan Template Creation
           return finalWorkPlanList;
       }
       return finalWorkPlanList;
   }
    
    public class Requests {
        @InvocableVariable(label = 'Work Plan Template Entries' 
                           description = 'Variable with list of user selected Work Plan Template Entries'
                           required = false)
        public List<WorkPlanTemplateEntry> userworkPlanTempEntries;
        
        @InvocableVariable(label = 'Work Plan Step Templates' 
                           description = 'Variable with list of Work Plan Steps selected by User '
                           required = true)
        public List<WorkStepTemplate> userworkPlanSteps;
        
        @InvocableVariable(label = 'Company Code of Work Plan Template' 
                           description = 'Company Code of Work Plan Template'
                           required = true)
        public string companyCode;
        
        @InvocableVariable(label = 'Work Type of Work Plan Template' 
                           description = 'Work Type of Work Plan Template'
                           required = true)
        public Id userWorkType; 
        
        @InvocableVariable(label = 'Maintenance Plan Template of Work Plan Template' 
                           description = 'Maintenance Plan Template of Work Plan Template'
                           required = false)
        public Id userMaintenancePlanTemplate; 
    }
    
}