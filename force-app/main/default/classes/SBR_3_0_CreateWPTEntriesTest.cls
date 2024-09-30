/*********************************************************************************************************************
* Apex Class: SBR_3_0_CreateWPTEntriesTest
----------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Test Class for SBR_3_0_CreateWorkPlanTemplateEntries
----------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME        DATE             DETAIL FEATURES
    1.0         Ritesh Mohapatra      2023-Sep-11      Initial version
	1.1		    Chhavi Singhal	      2023-Nov-02	   Removed field references & running test class as System Admin
**********************************************************************************************************************/
@isTest
public class SBR_3_0_CreateWPTEntriesTest 
{
	@isTest
    static void createWPTETest()
    {
        Profile pfl = [SELECT Id FROM Profile WHERE Name='System Administrator'];
       	User admin = SBR_3_0_TestDataFactory.createUser(true, pfl);
       	System.runAs(admin) {
            SBR_3_0_CreateWorkPlanTemplateEntries.Requests reqRecord = new SBR_3_0_CreateWorkPlanTemplateEntries.Requests();
            List<SBR_3_0_CreateWorkPlanTemplateEntries.Requests> reqRecordList = new List<SBR_3_0_CreateWorkPlanTemplateEntries.Requests>();   
            
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
            newStep1.CurrencyIsoCode = 'USD';
            
            WorkStepTemplate newStep2 = new WorkStepTemplate();
            newStep2.Name = 'Test Step 2';
            newStep2.IsActive = TRUE;
            newStep2.SM_PS_Step_Number__c = '213411';
            newStep2.CurrencyIsoCode = 'USD';
            
            WorkStepTemplate newStep3 = new WorkStepTemplate();
            newStep3.Name = 'Test Step 3';
            newStep3.IsActive = TRUE;
            newStep3.SM_PS_Step_Number__c = '546456';
            newStep3.CurrencyIsoCode = 'USD';
            
            WorkStepTemplate newStep4 = new WorkStepTemplate();
            newStep4.Name = 'Test Step 4';
            newStep4.IsActive = TRUE;
            newStep4.SM_PS_Step_Number__c = '546457';
            newStep4.CurrencyIsoCode = 'USD';
            
            List<WorkStepTemplate> newStepList = new List<WorkStepTemplate>();
            newStepList.add(newStep1);
            newStepList.add(newStep2);
            newStepList.add(newStep3);
            newStepList.add(newStep4);
            
            Insert newStepList;
            
            reqRecord.userSelectedSteps = newStepList;
            reqRecord.workPlanTemplateID = newWPT.id;
            reqRecordList.add(reqRecord);
            
            Test.StartTest();
            SBR_3_0_CreateWorkPlanTemplateEntries.createWPTEntries(reqRecordList);
            Test.StopTest();
        }
    }
}