/*********************************************************************************************************************
* Apex Class: SBR_3_0_WorkPlanTemplateOperationsTest
----------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Test Class for SBR_3_0_WorkPlanTemplateOperations
* - SERV-2671 - Autocreate a Maintenance Plan Template when Work Plan Template is updated.
----------------------------------------------------------------------------------------------------------------------------------
* History:
* VERSION     DEVELOPER NAME                    DATE                DETAIL FEATURES
    1.0       Ritesh Mohapatra                  2023-Sep-08         Initial version 
	1.1		  Chhavi Singhal					2023-Nov-02			Removed field references & running test class as System Admin
***********************************************************************************************************************************/
@isTest
public class SBR_3_0_WorkPlanTemplateOperationsTest 
{
	@isTest
    static void createMPTemplatesTest()
    {
       Profile pfl = [SELECT Id FROM Profile WHERE Name='System Administrator'];
       User admin = SBR_3_0_TestDataFactory.createUser(true, pfl);
       System.runAs(admin) { 
           Test.startTest();
           
           WorkType newWType = new WorkType();
           newWType.Name = 'Test Work Type';
           newWType.EstimatedDuration = 9;
           insert newWType;
      
           WorkPlanTemplate newWPT = new WorkPlanTemplate();
           newWPT.Name = 'RANDOM WPT';
           newWPT.SM_PS_Work_Type__c = newWType.id;
           insert newWPT; 
            
           newWPT.IsActive = TRUE;
           newWPT.SM_PS_Status__c = 'Active';
           update newWPT;
            
           newWPT.IsActive = FALSE;
           newWPT.SM_PS_Status__c = 'Draft';
           update newWPT;
            
           newWPT.IsActive = TRUE;
           newWPT.SM_PS_Status__c = 'Active';
           update newWPT;
            
           Test.stopTest();
       }
    }
}