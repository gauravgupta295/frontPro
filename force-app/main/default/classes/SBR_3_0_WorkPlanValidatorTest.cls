/*********************************************************************************************************************
* Apex Class: SBR_3_0_WorkPlanValidatorTest
----------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Test Class for SBR_3_0_WorkPlanValidatorTest
----------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME        DATE            DETAIL FEATURES
    1.0         Ritesh Mohapatra      2023-Aug-10     Initial version
	2.0         Chhavi Singhal        2023-Nov-29     Modified Test Class according to new WPT Validations
**********************************************************************************************************************/
@isTest
public class SBR_3_0_WorkPlanValidatorTest {
    @TestSetup
    static void dataSetup() {
        //Maintenance Plan Template  Record Creation
        SVMXA360__MaintenancePlanTemplate__c mptRecord = new SVMXA360__MaintenancePlanTemplate__c();
        mptRecord.Name = 'TEST MAINTENANCE PLAN TEMPLATE';
        mptRecord.SVMXA360__GenerationTimeframe__c = 14;
        mptRecord.SVMXA360__GenerationTimeframeType__c = 'Days';
        mptRecord.SVMXA360__MaintenancePlanDuration__c = 10;
        mptRecord.SVMXA360__MaintenancePlanUnitOfTime__c = 'Days';
        mptRecord.SM_PS_Company_Code__c = '01';
        mptRecord.SVMXA360__IsActive__c = TRUE;
        insert mptRecord;
        
        //Work Type Record Creation
        WorkType workTypeRec = new WorkType();
        workTypeRec.Name = 'TEST WORK TYPE';
        workTypeRec.EstimatedDuration = 1.00;
        workTypeRec.DurationType = 'Hours';
        insert workTypeRec;
        
        //Work Plan Template Record Creation
        WorkPlanTemplate newWPTRecord = new WorkPlanTemplate();
        newWPTRecord.Name = 'TEST WORK PLAN TEMPLATE';
        newWPTRecord.SM_PS_Status__c = 'Draft';
        newWPTRecord.SVMX_Company_Code__c = '01';
        newWPTRecord.Description = 'Test Work Plan';
        newWPTRecord.SM_PS_Work_Type__c = workTypeRec.Id;
        newWPTRecord.SM_PS_Maintenance_Plan_Template__c = mptRecord.Id;
        insert newWPTRecord;
        
        //Work Step Template Record Creation
        WorkStepTemplate workStepTemplate1 = new WorkStepTemplate();
        workStepTemplate1.Name = 'WORK STEP TEMPLATE STEP 1';
        workStepTemplate1.IsActive = TRUE; 
        workStepTemplate1.SM_PS_Step_Number__c = '10192';
        insert workStepTemplate1;
        
        WorkStepTemplate workStepTemplate2 = new WorkStepTemplate();
        workStepTemplate2.Name = 'WORK STEP TEMPLATE STEP 2';
        workStepTemplate2.IsActive = TRUE; 
        workStepTemplate2.SM_PS_Step_Number__c = '10193';
        insert workStepTemplate2;
        
        WorkStepTemplate workStepTemplate3 = new WorkStepTemplate();
        workStepTemplate3.Name = 'WORK STEP TEMPLATE STEP 3';
        workStepTemplate3.IsActive = TRUE; 
        workStepTemplate3.SM_PS_Step_Number__c = '10194';
        insert workStepTemplate3;
        
        //Work Plan Template Entry Record Creation
        WorkPlanTemplateEntry workPlanTemplateEntry1 = new WorkPlanTemplateEntry();
        workPlanTemplateEntry1.WorkPlanTemplateId = newWPTRecord.Id;
        workPlanTemplateEntry1.WorkStepTemplateId = workStepTemplate1.Id;
        workPlanTemplateEntry1.ExecutionOrder = 1;
        insert workPlanTemplateEntry1;
        
        WorkPlanTemplateEntry workPlanTemplateEntry2 = new WorkPlanTemplateEntry();
        workPlanTemplateEntry2.WorkPlanTemplateId = newWPTRecord.Id;
        workPlanTemplateEntry2.WorkStepTemplateId = workStepTemplate2.Id;
        workPlanTemplateEntry2.ExecutionOrder = 2;
        insert workPlanTemplateEntry2;
        
        WorkPlanTemplateEntry workPlanTemplateEntry3 = new WorkPlanTemplateEntry();
        workPlanTemplateEntry3.WorkPlanTemplateId = newWPTRecord.Id;
        workPlanTemplateEntry3.WorkStepTemplateId = workStepTemplate3.Id;
        workPlanTemplateEntry3.ExecutionOrder = 3;
        insert workPlanTemplateEntry3;
    }
    
    @isTest
    static void validationWPT_TestMethod1()
    {
        List<WorkPlanTemplate> WPTList1 = new List<WorkPlanTemplate>();
        List<WorkStepTemplate> WSTList1 = [SELECT Id FROM WorkStepTemplate
                                          WHERE Name = 'WORK STEP TEMPLATE STEP 1' OR Name = 'WORK STEP TEMPLATE STEP 2'];
		WorkType workTypeRec = [SELECT Id FROM WorkType];
        
        SBR_3_0_WorkPlanValidator.Requests requestBody1 = new SBR_3_0_WorkPlanValidator.Requests();
        List<SBR_3_0_WorkPlanValidator.Requests> requestBodyList1 = new List<SBR_3_0_WorkPlanValidator.Requests>();
        requestBody1.companyCode = '01';
        requestBody1.userworkPlanSteps = WSTList1;
        requestBody1.userWorkType = workTypeRec.Id;
        requestBodyList1.add(requestBody1);
        
        Test.startTest();
        	WPTList1 = SBR_3_0_WorkPlanValidator.workPlanValidator(requestBodyList1);
        Test.stopTest();
    }
    
    @isTest
    static void validationWPT_TestMethod2()
    { 
        List<WorkPlanTemplate> WPTList2 = new List<WorkPlanTemplate>();
        List<WorkStepTemplate> WSTList2 = [SELECT Id FROM WorkStepTemplate];
		WorkType workTypeRec = [SELECT Id FROM WorkType];
		SVMXA360__MaintenancePlanTemplate__c mptRecord = [SELECT Id FROM SVMXA360__MaintenancePlanTemplate__c];
            
		SBR_3_0_WorkPlanValidator.Requests requestBody2 = new SBR_3_0_WorkPlanValidator.Requests();  
        List<SBR_3_0_WorkPlanValidator.Requests> requestBodyList2 = new List<SBR_3_0_WorkPlanValidator.Requests>();
        requestBody2.companyCode = '01';
        requestBody2.userworkPlanSteps = WSTList2;
        requestBody2.userWorkType = workTypeRec.Id;
        requestBody2.userMaintenancePlanTemplate = mptRecord.Id;
        requestBodyList2.add(requestBody2);
        
        Test.startTest();
        	WPTList2 = SBR_3_0_WorkPlanValidator.workPlanValidator(requestBodyList2);
        Test.stopTest();
        
    } 
}