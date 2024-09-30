/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 12-15-2023
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@isTest(seeAllData=false) 
public class SBR_3_0_Populate_Customer_Spend_Test {
	/************************************************************* Cover SBR_3_0_Populate_Customer_Spend_Test Starts*************************************************************/
	@isTest()
    public Static void SBR_3_0_Populate_Customer_Spend_Test(){
        Profile oProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
		User oRunAsUser = SBR_3_0_TestDataFactory.createUser(TRUE,oProfile);
        list<Account> lAccount = SBR_3_0_TestDataFactory.createAccounts(1,TRUE);
        List<Account_Relationship__c> lAR = SBR_3_0_TestDataFactory.createAccountRelationships(10,lAccount[0].id,FALSE);
        User oUser = SBR_3_0_TestDataFactory.createUser(FALSE,oProfile);
        oUser.Analysis_Region_Key__c = '920';
        oUser.CompanyName = '1234';
        INSERT oUser;
        Analysis_Region__c oAnalysisRegion = new Analysis_Region__c(
            Analysis_Region_Key__c = '920',
        	Company_Code__c = '1234',
            Name= 'GENERAL TOOL'
        );	
        insert oAnalysisRegion;

        for(Account_Relationship__c oAR : lAR){
        	oAR.User_Account__c = oUser.id;
        }
        INSERT lAR;
        System.runAs(oRunAsUser){
            Test.startTest();
            Customer_Spend__c oCustomerSpend = SBR_3_0_TestDataFactory.createCustomerSpend(TRUE,oAnalysisRegion.id,lAccount[0].id);
            SBR_3_0_Populate_Customer_Spend_Schedule SC = new SBR_3_0_Populate_Customer_Spend_Schedule();
            String cronExp = '0 0 12 * * ?';
            System.schedule('Populate Customer Spend', cronExp, SC);
			Test.stopTest();
        }
    }  
    
    @isTest
    public Static void SBR_3_0_Populate_Customer_Spend_Single_Test(){
        Profile oProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
		User oRunAsUser = SBR_3_0_TestDataFactory.createUser(TRUE,oProfile);
        list<Account> lAccount = SBR_3_0_TestDataFactory.createAccounts(1,TRUE);
        List<Account_Relationship__c> lAR = SBR_3_0_TestDataFactory.createAccountRelationships(10,lAccount[0].id,FALSE);
        User oUser = SBR_3_0_TestDataFactory.createUser(FALSE,oProfile);
        oUser.Analysis_Region_Key__c = '920';
        oUser.CompanyName = '1234';
        INSERT oUser;
        Analysis_Region__c oAnalysisRegion = new Analysis_Region__c(
            Analysis_Region_Key__c = '920',
        	Company_Code__c = '1234',
            Name= 'GENERAL TOOL'
        );	
        insert oAnalysisRegion;
        for(Account_Relationship__c oAR : lAR){
        	oAR.User_Account__c = oUser.id;
        }
        INSERT lAR;
        System.runAs(oRunAsUser){
            Test.startTest();
            Customer_Spend__c oCustomerSpend = SBR_3_0_TestDataFactory.createCustomerSpend(TRUE,oAnalysisRegion.id,lAccount[0].id);
            SBR_3_0_Batch_Populate_Customer_Spend BC = new SBR_3_0_Batch_Populate_Customer_Spend(lAR[0].id);
			Database.executeBatch(BC);
            Test.stopTest();
        }
    }    
    /************************************************************* Cover SBR_3_0_Populate_Customer_Spend_Test Ends*************************************************************/
}