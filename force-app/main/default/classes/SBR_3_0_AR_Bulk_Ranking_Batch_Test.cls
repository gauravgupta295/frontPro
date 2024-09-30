/*********************************************************************************************************************
* Apex Class: SBR_3_0_AR_Bulk_Ranking_Batch_Test
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - This Test class will cover SBR_3_0_ARSortOrderCalculationSchedule 
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME                        DATE                DETAIL FEATURES
    1.0         Saathvik Tulasi                    2023-12-21             Initial version 
*********************************************************************************************************************/
@isTest(seeAllData=false) 
public class SBR_3_0_AR_Bulk_Ranking_Batch_Test {
	public Static testMethod void SBR_3_0_ARSortOrderCalculationScheduleUser(){
        List<Customer_spend__c> spendList = new List<Customer_spend__c>();
        Id CreditrRecordTypeId = Account.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Credit').getRecordTypeId();

        Profile oProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
		User oRunAsUser = SBR_3_0_TestDataFactory.createUser(TRUE,oProfile);
        User User1 = SBR_3_0_TestDataFactory.createUser(FALSE,oProfile);
        User1.Analysis_Region_Key__c = '921';
        INSERT User1;
        list<Account> lAccount = SBR_3_0_TestDataFactory.createAccounts(1,FALSE);
        lAccount[0].RecordTypeId = CreditrRecordTypeId;
        INSERT lAccount;
        Analysis_Region__c oAnalysisRegion = SBR_3_0_TestDataFactory.createAnalysisRegion(TRUE,'921',lAccount[0].id);
        oAnalysisRegion.Name = 'TRAFFIC SAFETY';
        update oAnalysisRegion;
        Customer_Spend__c oCustomerSpend1 = SBR_3_0_TestDataFactory.createCustomerSpend(FALSE,oAnalysisRegion.id,lAccount[0].id);
        oCustomerSpend1.Current_TTM_Spend__c = 1000;
        spendList.add(oCustomerSpend1);
        Customer_Spend__c oCustomerSpend2 = SBR_3_0_TestDataFactory.createCustomerSpend(FALSE,oAnalysisRegion.id,lAccount[0].id);
        oCustomerSpend2.Current_TTM_Spend__c = 1000;
        spendList.add(oCustomerSpend2);
        Customer_Spend__c oCustomerSpend3 = SBR_3_0_TestDataFactory.createCustomerSpend(FALSE,oAnalysisRegion.id,lAccount[0].id);
        spendList.add(oCustomerSpend3);
        INSERT spendList;
        
        List<Account_Relationship__c> lAR = SBR_3_0_TestDataFactory.createAccountRelationships(10,lAccount[0].id,FALSE);
        lAR[0].User_Account__c = User1.id;
        lAR[1].User_Account__c = User1.id;
        lAR[2].User_Account__c = User1.id;
        lAR[0].Customer_Spend__c = oCustomerSpend1.id;
        lAR[1].Customer_Spend__c = oCustomerSpend2.id;
        lAR[2].Rank__c = 5;
        INSERT lAR;
        List<User> lUsersToProcess = new List<User>();
        lUsersToProcess.add(User1);
        
        
        list<Analysis_Region__c> lAnalysisRegions = new list<Analysis_Region__c>();
        lAnalysisRegions.add(oAnalysisRegion);
        String ObjectAPIName = 'User';
        System.runAs(oRunAsUser){
            Test.startTest();
                SBR_3_0_AR_Ranking_Batch BC = new SBR_3_0_AR_Ranking_Batch(lUsersToProcess,lAnalysisRegions,ObjectAPIName);
            	Database.executeBatch(BC);
            Test.stopTest();
            List<Account_Relationship__c> lARDB = [SELECT Id,Rank__c FROM Account_Relationship__c Order BY Rank__c ASC];
            System.AssertEquals(10,lARDB.size());
        }
    }    
    public Static testMethod void SBR_3_0_ARSortOrderCalculationScheduleAR(){
        List<Customer_spend__c> spendList = new List<Customer_spend__c>();
        Id CreditrRecordTypeId = Account.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Credit').getRecordTypeId();

        Profile oProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
		User oRunAsUser = SBR_3_0_TestDataFactory.createUser(TRUE,oProfile);
        User User1 = SBR_3_0_TestDataFactory.createUser(FALSE,oProfile);
        User1.Analysis_Region_Key__c = '921';
        INSERT User1;
        
        System.runAs(oRunAsUser){
        list<Account> lAccount = SBR_3_0_TestDataFactory.createAccounts(1,FALSE);
        lAccount[0].RecordTypeId = CreditrRecordTypeId;
        INSERT lAccount;
        Analysis_Region__c oAnalysisRegion = SBR_3_0_TestDataFactory.createAnalysisRegion(TRUE,'921',lAccount[0].id);
        oAnalysisRegion.Name = 'TRAFFIC SAFETY';
        update oAnalysisRegion;
        Customer_Spend__c oCustomerSpend1 = SBR_3_0_TestDataFactory.createCustomerSpend(FALSE,oAnalysisRegion.id,lAccount[0].id);
        oCustomerSpend1.Current_TTM_Spend__c = 1000;
        spendList.add(oCustomerSpend1);
        Customer_Spend__c oCustomerSpend2 = SBR_3_0_TestDataFactory.createCustomerSpend(FALSE,oAnalysisRegion.id,lAccount[0].id);
        oCustomerSpend2.Current_TTM_Spend__c = 1000;
        spendList.add(oCustomerSpend2);
        Customer_Spend__c oCustomerSpend3 = SBR_3_0_TestDataFactory.createCustomerSpend(FALSE,oAnalysisRegion.id,lAccount[0].id);
        spendList.add(oCustomerSpend3);
        INSERT spendList;
        
        List<Account_Relationship__c> lAR = SBR_3_0_TestDataFactory.createAccountRelationships(10,lAccount[0].id,FALSE);
        lAR[0].User_Account__c = User1.id;
        lAR[1].User_Account__c = User1.id;
        lAR[2].User_Account__c = User1.id;
        lAR[0].Customer_Spend__c = oCustomerSpend1.id;
        lAR[1].Customer_Spend__c = oCustomerSpend2.id;
        lAR[2].Rank__c = 5;
        INSERT lAR;
        List<User> lUsersToProcess = new List<User>();
        lUsersToProcess.add(User1);
        
        list<Analysis_Region__c> lAnalysisRegions = new list<Analysis_Region__c>();
        lAnalysisRegions.add(oAnalysisRegion);
        String ObjectAPIName = 'Analysis_Region__c';
            Test.startTest();
                SBR_3_0_AR_Ranking_Batch BC = new SBR_3_0_AR_Ranking_Batch(lUsersToProcess,lAnalysisRegions,ObjectAPIName);
            	Database.executeBatch(BC);
            Test.stopTest();
            List<Account_Relationship__c> lARDB = [SELECT Id,Rank__c FROM Account_Relationship__c Order BY Rank__c ASC];
            System.AssertEquals(10,lARDB.size());
        }
    }    
    /************************************************************* Cover SBR_3_0_ARSortOrderCalculationSchedule Ends*************************************************************/
}