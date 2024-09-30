@isTest(seeAllData=false) 
public class SBR_3_0_BatchEmailRepsOfNewAssignTest {
/************************************************************* Cover SBR_3_0_BatchEmailRepsOfNewAssignments Starts*************************************************************/
	public Static testMethod void SBR_3_0_BatchEmailRepsOfNewAssignTest(){
        Profile oProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
		User oRunAsUser = SBR_3_0_TestDataFactory.createUser(TRUE,oProfile);
        list<Account> lAccount = SBR_3_0_TestDataFactory.createAccounts(1,TRUE);
        List<Account_Relationship__c> lAR = SBR_3_0_TestDataFactory.createAccountRelationships(10,lAccount[0].id,TRUE);
        System.runAs(oRunAsUser){
            Test.startTest();
            SBR_3_0_BatchEmailRepsOfNewAssignments BC = new SBR_3_0_BatchEmailRepsOfNewAssignments();
			Database.executeBatch(BC);
            Test.stopTest();
        }
    }    
    
    public Static testMethod void SBR_3_0_BatchEmailRepsOfNewAssignTestwithUserAccount(){
        Profile oProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
		User oRunAsUser = SBR_3_0_TestDataFactory.createUser(TRUE,oProfile);
        list<Account> lAccount = SBR_3_0_TestDataFactory.createAccounts(1,TRUE);
        List<Account_Relationship__c> lAR = SBR_3_0_TestDataFactory.createAccountRelationships(1,lAccount[0].id,FALSE);
        lAR[0].User_Account__c = oRunAsUser.Id;
        insert lAR;
        System.runAs(oRunAsUser){
            Test.startTest();
            SBR_3_0_BatchEmailRepsOfNewAssignments BC = new SBR_3_0_BatchEmailRepsOfNewAssignments();
			Database.executeBatch(BC);
            Test.stopTest();
        }
    }  
    /************************************************************* Cover SBR_3_0_BatchEmailRepsOfNewAssignments Ends*************************************************************/
}