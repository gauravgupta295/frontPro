@isTest(seeAllData=false) 
public class SBR_3_0_BatchARSortOrderTest {
	/************************************************************* Cover SBR_3_0_AccountRelationshipOperations Starts*************************************************************/
	public Static testMethod void SBR_3_0_AccountRelationshipOperations(){
        Profile oProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
		User oRunAsUser = SBR_3_0_TestDataFactory.createUser(TRUE,oProfile);
        list<Account> lAccount = SBR_3_0_TestDataFactory.createAccounts(1,TRUE);
        List<Account_Relationship__c> lAR = SBR_3_0_TestDataFactory.createAccountRelationships(10,lAccount[0].id,TRUE);
        System.runAs(oRunAsUser){
            Test.startTest();
            SBR_3_0_BatchARSortOrderCalculation BC = new SBR_3_0_BatchARSortOrderCalculation();
			Database.executeBatch(BC);
            Test.stopTest();
        }
    }    
    /************************************************************* Cover SBR_3_0_AccountRelationshipOperations Ends*************************************************************/
}