/*********************************************************************************************************************
* Apex Class: SBR_3_0_EmailRepsOfNewAssgnTest
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Test class for SBR_3_0_BatchInvocableRe_Rank_AR
* - SF-905
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME                        DATE                DETAIL FEATURES
    1.0         Saathvik Tulasi                    2023-06-13             Initial version 
*********************************************************************************************************************/
@isTest(seeAllData=false) 
public class SBR_3_0_EmailRepsOfNewAssgnTest {
    /************************************************************* Cover SBR_3_0_EmailRepsOfNewAssgnSchedule Starts*************************************************************/
	public Static testMethod void SBR_3_0_EmailRepsOfNewAssgnSchedule(){
        Profile oProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
		User oRunAsUser = SBR_3_0_TestDataFactory.createUser(FALSE,oProfile);
        oRunAsUser.Analysis_Region_Key__c = '921';
        INSERT oRunAsUser;
        list<Account> lAccount = SBR_3_0_TestDataFactory.createAccounts(1,TRUE);
        List<Account_Relationship__c> lAR = SBR_3_0_TestDataFactory.createAccountRelationships(10,lAccount[0].id,FALSE);
        for(Account_Relationship__c oAR : lAR){
        	oAR.User_Account__c = oRunAsUser.id;	    
        }
        INSERT lAR;
        Analysis_Region__c oAR = SBR_3_0_TestDataFactory.createAnalysisRegion(TRUE,'921',lAccount[0].id);
        System.runAs(oRunAsUser){
            try{
                Test.startTest();
                SBR_3_0_EmailRepsOfNewAssgnSchedule SC = new SBR_3_0_EmailRepsOfNewAssgnSchedule();
                String sch ='0 48 * * * ?'; 
				System.schedule('Schedule Email Reps of new Assignment',sch,SC);
                Test.stopTest();
            }
            Catch(Exception e){
                
            }
        }
    }   
    public Static testMethod void SBR_3_0_EmailRepsOfNewAssgnScheduleSingle(){
        Profile oProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
		User oRunAsUser = SBR_3_0_TestDataFactory.createUser(FALSE,oProfile);
        oRunAsUser.Analysis_Region_Key__c = '921';
        INSERT oRunAsUser;
        list<Account> lAccount = SBR_3_0_TestDataFactory.createAccounts(1,TRUE);
        List<Account_Relationship__c> lAR = SBR_3_0_TestDataFactory.createAccountRelationships(10,lAccount[0].id,FALSE);
        for(Account_Relationship__c oAR : lAR){
        	oAR.User_Account__c = oRunAsUser.id;	    
        }
        INSERT lAR;
        Analysis_Region__c oAR = SBR_3_0_TestDataFactory.createAnalysisRegion(TRUE,'921',lAccount[0].id);
        System.runAs(oRunAsUser){
            try{
                Test.startTest();
                SBR_3_0_BatchEmailRepsOfNewAssignments BC = new SBR_3_0_BatchEmailRepsOfNewAssignments(lAR[0].id);
                Database.executeBatch(BC);
                Test.stopTest();
            }
            Catch(Exception e){
                
            }
        }
    }   
    /************************************************************* Cover SBR_3_0_EmailRepsOfNewAssgnSchedule Ends*************************************************************/
}