/*********************************************************************************************************************
Apex Class : SBR_3_0_WorkPlanTemplateEntryOpsTest
---------------------------------------------------------------------------------------------------------------------
Purpose/Methods: Unit Test Class for SBR_3_0_WorkPlanTemplateEntryOperations
---------------------------------------------------------------------------------------------------------------------
History:
VERSION     DEVELOPER NAME                      DATE                 DETAIL FEATURES
1.0         Ritesh Mohapatra (ServiceMax)       2023-Sep-11           Initial version  
1.1		    Chhavi Singhal					    2023-Nov-02			  Removed field references & running test class as System Admin
*********************************************************************************************************************/
@isTest
public class SBR_3_0_WorkPlanTemplateEntryOpsTest 
{
	@isTest
    static void workPlanTemplateValTest()
    {
        Profile pfl = [SELECT Id FROM Profile WHERE Name='System Administrator'];
       	User admin = SBR_3_0_TestDataFactory.createUser(true, pfl);
       	System.runAs(admin) {
            //Create Work Plan Template
            WorkPlanTemplate newWPT = new WorkPlanTemplate();
            newWPT.Name = 'RANDOM WPT';
            newWPT.SM_PS_Status__c = 'Draft';
            insert newWPT; 
            
            //Create Work Step Template
            WorkStepTemplate newStep1 = new WorkStepTemplate();
            newStep1.Name = 'Test Step 1';
            newStep1.IsActive = TRUE;
            newStep1.SM_PS_Step_Number__c = '123456';
            
            WorkStepTemplate newStep2 = new WorkStepTemplate();
            newStep2.Name = 'Test Step 2';
            newStep2.IsActive = TRUE;
            newStep2.SM_PS_Step_Number__c = '213411';
            
            WorkStepTemplate newStep3 = new WorkStepTemplate();
            newStep3.Name = 'Test Step 3';
            newStep3.IsActive = TRUE;
            newStep3.SM_PS_Step_Number__c = '546456';
            
            WorkStepTemplate newStep4 = new WorkStepTemplate();
            newStep4.Name = 'Test Step 4';
            newStep4.IsActive = TRUE;
            newStep4.SM_PS_Step_Number__c = '546457';
            
            List<WorkStepTemplate> newStepList = new List<WorkStepTemplate>();
            newStepList.add(newStep1);
            newStepList.add(newStep2);
            newStepList.add(newStep3);
            newStepList.add(newStep4);
            
            Insert newStepList;
            
            //Create Work Plan Template Entry
            WorkPlanTemplateEntry entry1 = new WorkPlanTemplateEntry();
            entry1.WorkPlanTemplateId = newWPT.id;
            entry1.WorkStepTemplateId = newStep1.id;
            
            WorkPlanTemplateEntry entry2 = new WorkPlanTemplateEntry();
            entry2.WorkPlanTemplateId = newWPT.id;
            entry2.WorkStepTemplateId = newStep2.id;
            
            WorkPlanTemplateEntry entry3 = new WorkPlanTemplateEntry();
            entry3.WorkPlanTemplateId = newWPT.id;
            entry3.WorkStepTemplateId = newStep3.id;
            
            List<WorkPlanTemplateEntry> newPlanTempEntryList = new List<WorkPlanTemplateEntry>();
            newPlanTempEntryList.add(entry1);
            newPlanTempEntryList.add(entry2);
            newPlanTempEntryList.add(entry3);
            
            Insert newPlanTempEntryList;
            
            //TESTING RECORDS
            
            WorkPlanTemplate newWPT2 = new WorkPlanTemplate();
            newWPT2.Name = 'RANDOM WPT 2';
            newWPT2.SM_PS_Status__c = 'Draft';
            insert newWPT2;
            
            //Create Work Plan Template Entry
            WorkPlanTemplateEntry entry4 = new WorkPlanTemplateEntry();
            entry4.WorkPlanTemplateId = newWPT2.id;
            entry4.WorkStepTemplateId = newStep1.id;
            
            WorkPlanTemplateEntry entry5 = new WorkPlanTemplateEntry();
            entry5.WorkPlanTemplateId = newWPT2.id;
            entry5.WorkStepTemplateId = newStep2.id;
            
            List<WorkPlanTemplateEntry> newPlanTempEntryList2 = new List<WorkPlanTemplateEntry>();
            newPlanTempEntryList.add(entry4);
            newPlanTempEntryList.add(entry5);
            
            Insert newPlanTempEntryList2;
            
            WorkPlanTemplateEntry entry6 = new WorkPlanTemplateEntry();
            entry6.WorkPlanTemplateId = newWPT2.id;
            entry6.WorkStepTemplateId = newStep3.id;
            insert entry6;
            
            WorkPlanTemplateEntry entry7 = new WorkPlanTemplateEntry();
            entry7.WorkPlanTemplateId = newWPT2.id;
            entry7.WorkStepTemplateId = newStep4.id;
            insert entry7;
            
            delete entry7;
        }
    }
}