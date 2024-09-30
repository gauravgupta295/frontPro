/*********************************************************************************************************************
* Apex Class: SBR_3_0_ARSortOrderCalculationTest
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Test class for SBR_3_0_ARSortOrderCalculationSchedule
* - SF-905
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME                        DATE                DETAIL FEATURES
    1.0         Saathvik Tulasi                    2023-12-07             Initial version 
*********************************************************************************************************************/
@isTest(seeAllData=false) 
public class SBR_3_0_ARSortOrderCalculationTest {
	/************************************************************* Cover SBR_3_0_BatchARSortOrderCalculation Starts*************************************************************/
	public Static testMethod void SBR_3_0_BatchARSortOrderCalculation(){
        Profile oProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
		User oRunAsUser = SBR_3_0_TestDataFactory.createUser(FALSE,oProfile);
        oRunAsUser.Analysis_Region_Key__c = '921';
        INSERT oRunAsUser;
        list<Account> lAccount = SBR_3_0_TestDataFactory.createAccounts(1,TRUE);
        Analysis_Region__c oAnalysisRegion = SBR_3_0_TestDataFactory.createAnalysisRegion(TRUE,'921',lAccount[0].id);
        List<Account_Relationship__c> lAR = SBR_3_0_TestDataFactory.createAccountRelationships(10,lAccount[0].id,FALSE);
        for(Account_Relationship__c oAR : lAR){
        	oAR.User_Account__c = oRunAsUser.id; 	
        }
        INSERT lAR;
        
        System.runAs(oRunAsUser){
            try{
                Test.startTest();
                SBR_3_0_BatchARSortOrderCalculation BC = new SBR_3_0_BatchARSortOrderCalculation();
                Database.QueryLocator Ql = BC.start(null);
                BC.execute(null, lAccount);
                BC.finish(null);    
                Test.stopTest();
            }
            Catch(Exception e){
                
            }
        }
    } 
    
    public Static testMethod void SBR_3_0_ScheduleARSortOrderCalculation(){
        Profile oProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
		User oRunAsUser = SBR_3_0_TestDataFactory.createUser(FALSE,oProfile);
        oRunAsUser.Analysis_Region_Key__c = '921';
        INSERT oRunAsUser;
        list<Account> lAccount = SBR_3_0_TestDataFactory.createAccounts(1,TRUE);
        Analysis_Region__c oAnalysisRegion = SBR_3_0_TestDataFactory.createAnalysisRegion(TRUE,'921',lAccount[0].id);
        List<Account_Relationship__c> lAR = SBR_3_0_TestDataFactory.createAccountRelationships(10,lAccount[0].id,FALSE);
        for(Account_Relationship__c oAR : lAR){
        	oAR.User_Account__c = oRunAsUser.id; 	
        }
        INSERT lAR;
        
        System.runAs(oRunAsUser){
            try{
                Test.startTest();
                SBR_3_0_ARSortOrderCalculationSchedule SC = new SBR_3_0_ARSortOrderCalculationSchedule();
                String sch ='0 48 * * * ?'; 
				System.schedule('Schedule Sync Sorting', sch,SC);
                Test.stopTest();
               }
            Catch(Exception e){
                
            }
        }
    }  
    
    public Static testMethod void SBR_3_0_BatchARSortOrderCalculationwithDiffRepTypes(){
        Profile oProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
		User oRunAsUser = SBR_3_0_TestDataFactory.createUser(FALSE,oProfile);
        oRunAsUser.Rep_Type__c = 'Strategic Customer Manager';
        INSERT oRunAsUser;
        
        User User2 = SBR_3_0_TestDataFactory.createUser(FALSE,oProfile);       
        User2.Rep_Type__c = 'Strategic Account';
        INSERT User2;
        
        User User3 = SBR_3_0_TestDataFactory.createUser(FALSE,oProfile);
        User3.Rep_Type__c = 'Pump and Power';
        INSERT User3;
        
        list<Account> lAccount = SBR_3_0_TestDataFactory.createAccounts(1,TRUE);
        List<Account_Relationship__c> lAR = SBR_3_0_TestDataFactory.createAccountRelationships(1,lAccount[0].id,FALSE);
        for(Account_Relationship__c oAR : lAR){
        	oAR.User_Account__c = oRunAsUser.id; 	
        }
        INSERT lAR;
        
        List<Account_Relationship__c> lAR2 = SBR_3_0_TestDataFactory.createAccountRelationships(1,lAccount[0].id,FALSE);
        for(Account_Relationship__c oAR : lAR2){
        	oAR.User_Account__c = User2.id; 	
        }
        INSERT lAR2;
        
        List<Account_Relationship__c> lAR3 = SBR_3_0_TestDataFactory.createAccountRelationships(1,lAccount[0].id,FALSE);
        for(Account_Relationship__c oAR : lAR3){
        	oAR.User_Account__c = User3.id; 	
        }
        INSERT lAR3;
        
        System.runAs(oRunAsUser){
            try{
                Test.startTest();
                SBR_3_0_BatchARSortOrderCalculation BC = new SBR_3_0_BatchARSortOrderCalculation();
                Database.QueryLocator Ql = BC.start(null);
                BC.execute(null, lAccount);
                BC.finish(null);    
                Test.stopTest();
            }
            Catch(Exception e){
                
            }
        }
    }   
    public Static testMethod void SBR_3_0_BatchARSortOrderCalculationwithDiffRepTypesAll(){
        Profile oProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
		User oRunAsUser = SBR_3_0_TestDataFactory.createUser(FALSE,oProfile);
        oRunAsUser.Rep_Type__c = 'Strategic Customer Manager';
        INSERT oRunAsUser;
        
        User User2 = SBR_3_0_TestDataFactory.createUser(FALSE,oProfile);       
        User2.Rep_Type__c = 'Strategic Account';
        INSERT User2;
        
        User User3 = SBR_3_0_TestDataFactory.createUser(FALSE,oProfile);
        User3.Rep_Type__c = 'Pump and Power';
        INSERT User3;
        
        list<Account> lAccount = SBR_3_0_TestDataFactory.createAccounts(1,TRUE);
        List<Account_Relationship__c> lAR = SBR_3_0_TestDataFactory.createAccountRelationships(1,lAccount[0].id,FALSE);
        for(Account_Relationship__c oAR : lAR){
        	oAR.User_Account__c = oRunAsUser.id; 	
        }
        INSERT lAR;
        
        List<Account_Relationship__c> lAR2 = SBR_3_0_TestDataFactory.createAccountRelationships(1,lAccount[0].id,FALSE);
        for(Account_Relationship__c oAR : lAR2){
        	oAR.User_Account__c = User2.id; 	
        }
        INSERT lAR2;
        
        List<Account_Relationship__c> lAR3 = SBR_3_0_TestDataFactory.createAccountRelationships(1,lAccount[0].id,FALSE);
        for(Account_Relationship__c oAR : lAR3){
        	oAR.User_Account__c = User3.id; 	
        }
        INSERT lAR3;
        
        System.runAs(oRunAsUser){
            try{
                Test.startTest();
                SBR_3_0_BatchARSortOrderCalculation BC = new SBR_3_0_BatchARSortOrderCalculation(true);
                Database.executeBatch(BC); 
                Test.stopTest();
            }
            Catch(Exception e){
                
            }
        }
    }   
    public Static testMethod void SBR_3_0_BatchARSortOrderCalculationwithDiffRepTypesSingle(){
        Profile oProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
		User oRunAsUser = SBR_3_0_TestDataFactory.createUser(FALSE,oProfile);
        oRunAsUser.Rep_Type__c = 'Strategic Customer Manager';
        INSERT oRunAsUser;
        
        User User2 = SBR_3_0_TestDataFactory.createUser(FALSE,oProfile);       
        User2.Rep_Type__c = 'Strategic Account';
        INSERT User2;
        
        User User3 = SBR_3_0_TestDataFactory.createUser(FALSE,oProfile);
        User3.Rep_Type__c = 'Pump and Power';
        INSERT User3;
        
        list<Account> lAccount = SBR_3_0_TestDataFactory.createAccounts(1,TRUE);
        List<Account_Relationship__c> lAR = SBR_3_0_TestDataFactory.createAccountRelationships(1,lAccount[0].id,FALSE);
        for(Account_Relationship__c oAR : lAR){
        	oAR.User_Account__c = oRunAsUser.id; 	
        }
        INSERT lAR;
        
        List<Account_Relationship__c> lAR2 = SBR_3_0_TestDataFactory.createAccountRelationships(1,lAccount[0].id,FALSE);
        for(Account_Relationship__c oAR : lAR2){
        	oAR.User_Account__c = User2.id; 	
        }
        INSERT lAR2;
        
        List<Account_Relationship__c> lAR3 = SBR_3_0_TestDataFactory.createAccountRelationships(1,lAccount[0].id,FALSE);
        for(Account_Relationship__c oAR : lAR3){
        	oAR.User_Account__c = User3.id; 	
        }
        INSERT lAR3;
        
        System.runAs(oRunAsUser){
            try{
                Test.startTest();
                SBR_3_0_BatchARSortOrderCalculation BC = new SBR_3_0_BatchARSortOrderCalculation(lAccount[0].id);
                Database.executeBatch(BC);
                Test.stopTest();
            }
            Catch(Exception e){
                
            }
        }
    }   
    /************************************************************* Cover SBR_3_0_BatchInvocableRe_Rank_AR Ends*************************************************************/
}