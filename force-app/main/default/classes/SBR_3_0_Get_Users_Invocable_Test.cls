/*********************************************************************************************************************
* Apex Class: SBR_3_0_Get_Users_Invocable_Test
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Test class for SBR_3_0_Get_User_Records_Invocable
* - 
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME                        DATE                DETAIL FEATURES
    1.0         Saathvik Tulasi                    09-29-2023             Initial version 
*********************************************************************************************************************/
@isTest(seeAllData=false) 
public class SBR_3_0_Get_Users_Invocable_Test {
	/************************************************************* Cover getUserRecords Starts*************************************************************/
	public Static testMethod void getUserRecordsWithNoTTM(){
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_FetchTimezone_MockSuccess());
        Profile oProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
		User oRunAsUser = SBR_3_0_TestDataFactory.createUser(FALSE,oProfile);
        oRunAsUser.Analysis_Region_Key__c = '921';
        oRunAsUser.CompanyName = '01';
        INSERT oRunAsUser;
        list<Id> lARIds = new list<Id>();
        list<Account> lAccount = SBR_3_0_TestDataFactory.createAccounts(1,TRUE,'Credit');
        List<Account_Relationship__c> lAR = SBR_3_0_TestDataFactory.createAccountRelationships(10,lAccount[0].id,FALSE);
        Analysis_Region__c oAR = SBR_3_0_TestDataFactory.createAnalysisRegion(FALSE,'921',lAccount[0].id);
        oAR.Name = 'IN-STORE';
        oAR.Company_Code__c = '01';
        INSERT oAR;
        lARIds.add(oAR.id);	
        Customer_Spend__c oCS = SBR_3_0_TestDataFactory.createCustomerSpend(TRUE,oAR.id,lAccount[0].id);
        for(Account_Relationship__c oAR1 : lAR){
        	oAR1.User_Account__c = oRunAsUser.id;
            oAR1.Customer_Spend__c = oCS.id;
            oAR1.Rank__c = 100;
        }
        INSERT lAR;
        
        list<SBR_3_0_Get_User_Records_Invocable.RequetToRerank> lRequest = new list<SBR_3_0_Get_User_Records_Invocable.RequetToRerank>();
        SBR_3_0_Get_User_Records_Invocable.RequetToRerank oRequest = new SBR_3_0_Get_User_Records_Invocable.RequetToRerank();
        oRequest.Ids = lARIds;
        oRequest.ObjectAPIName = 'Analysis_Region__c';
        lRequest.add(oRequest);
        System.runAs(oRunAsUser){
            try{
                Test.startTest();
                SBR_3_0_Get_User_Records_Invocable.getUserRecords(lRequest);
                Test.stopTest();
            }
            Catch(Exception e){
                
            }
        }
    }   
    public Static testMethod void getUserRecordsWithTTM(){
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_FetchTimezone_MockSuccess());
        Profile oProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
		User oRunAsUser = SBR_3_0_TestDataFactory.createUser(FALSE,oProfile);
        oRunAsUser.Analysis_Region_Key__c = '921';
        oRunAsUser.CompanyName = '01';
        INSERT oRunAsUser;
        list<Id> lARIds = new list<Id>();
        list<Account> lAccount = SBR_3_0_TestDataFactory.createAccounts(1,TRUE,'Credit');
        List<Account_Relationship__c> lAR = SBR_3_0_TestDataFactory.createAccountRelationships(10,lAccount[0].id,FALSE);
        Analysis_Region__c oAR = SBR_3_0_TestDataFactory.createAnalysisRegion(FALSE,'921',lAccount[0].id);
        oAR.Name = 'IN-STORE';
        oAR.Company_Code__c = '01';
        INSERT oAR;
        lARIds.add(oAR.id);	
        Customer_Spend__c oCS = SBR_3_0_TestDataFactory.createCustomerSpend(FALSE,oAR.id,lAccount[0].id);
        oCS.Current_TTM_Spend__c = 200;
        INSERT oCS;
        for(Account_Relationship__c oAR1 : lAR){
        	oAR1.User_Account__c = oRunAsUser.id;
            oAR1.Customer_Spend__c = oCS.id;
        }
        INSERT lAR;
        
        list<SBR_3_0_Get_User_Records_Invocable.RequetToRerank> lRequest = new list<SBR_3_0_Get_User_Records_Invocable.RequetToRerank>();
        SBR_3_0_Get_User_Records_Invocable.RequetToRerank oRequest = new SBR_3_0_Get_User_Records_Invocable.RequetToRerank();
        oRequest.Ids = lARIds;
        oRequest.ObjectAPIName = 'Analysis_Region__c';
        lRequest.add(oRequest);
        System.runAs(oRunAsUser){
            try{
                Test.startTest();
                SBR_3_0_Get_User_Records_Invocable.getUserRecords(lRequest);
                Test.stopTest();
            }
            Catch(Exception e){
                
            }
        }
    }   
    public Static testMethod void getUserRecordsWithTTMForUserIds(){
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_FetchTimezone_MockSuccess());
        Profile oProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
		User oRunAsUser = SBR_3_0_TestDataFactory.createUser(FALSE,oProfile);
        oRunAsUser.Analysis_Region_Key__c = '921';
        oRunAsUser.CompanyName = '01';
        INSERT oRunAsUser;
        list<Id> lUserIds = new list<Id>();
        list<Account> lAccount = SBR_3_0_TestDataFactory.createAccounts(1,TRUE,'Credit');
        List<Account_Relationship__c> lAR = SBR_3_0_TestDataFactory.createAccountRelationships(10,lAccount[0].id,FALSE);
        Analysis_Region__c oAR = SBR_3_0_TestDataFactory.createAnalysisRegion(FALSE,'921',lAccount[0].id);
        oAR.Name = 'IN-STORE';
        oAR.Company_Code__c = '01';
        INSERT oAR;
        lUserIds.add(oRunAsUser.id);	
        Customer_Spend__c oCS = SBR_3_0_TestDataFactory.createCustomerSpend(FALSE,oAR.id,lAccount[0].id);
        oCS.Current_TTM_Spend__c = 200;
        INSERT oCS;
        for(Account_Relationship__c oAR1 : lAR){
        	oAR1.User_Account__c = oRunAsUser.id;
            oAR1.Customer_Spend__c = oCS.id;
            oAR1.Rank__c = 99999;
        }
        INSERT lAR;
        
        list<SBR_3_0_Get_User_Records_Invocable.RequetToRerank> lRequest = new list<SBR_3_0_Get_User_Records_Invocable.RequetToRerank>();
        SBR_3_0_Get_User_Records_Invocable.RequetToRerank oRequest = new SBR_3_0_Get_User_Records_Invocable.RequetToRerank();
        oRequest.Ids = lUserIds;
        oRequest.ObjectAPIName = 'User';
        lRequest.add(oRequest);
        System.runAs(oRunAsUser){
            try{
                Test.startTest();
                SBR_3_0_Get_User_Records_Invocable.getUserRecords(lRequest);
                Test.stopTest();
            }
            Catch(Exception e){
                
            }
        }
    }   
    public Static testMethod void getUserRecordsWithNoTTMForUserIds(){
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_FetchTimezone_MockSuccess());
        Profile oProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
		User oRunAsUser = SBR_3_0_TestDataFactory.createUser(FALSE,oProfile);
        oRunAsUser.Analysis_Region_Key__c = '921';
        oRunAsUser.CompanyName = '01';
        INSERT oRunAsUser;
        list<Id> lUserIds = new list<Id>();
        list<Account> lAccount = SBR_3_0_TestDataFactory.createAccounts(1,TRUE,'Credit');
        List<Account_Relationship__c> lAR = SBR_3_0_TestDataFactory.createAccountRelationships(10,lAccount[0].id,FALSE);
        Analysis_Region__c oAR = SBR_3_0_TestDataFactory.createAnalysisRegion(FALSE,'921',lAccount[0].id);
        oAR.Name = 'IN-STORE';
        oAR.Company_Code__c = '01';
        INSERT oAR;
        lUserIds.add(oRunAsUser.id);	
        Customer_Spend__c oCS = SBR_3_0_TestDataFactory.createCustomerSpend(FALSE,oAR.id,lAccount[0].id);
        INSERT oCS;
        for(Account_Relationship__c oAR1 : lAR){
        	oAR1.User_Account__c = oRunAsUser.id;
            oAR1.Customer_Spend__c = oCS.id;
        }
        INSERT lAR;
        
        list<SBR_3_0_Get_User_Records_Invocable.RequetToRerank> lRequest = new list<SBR_3_0_Get_User_Records_Invocable.RequetToRerank>();
        SBR_3_0_Get_User_Records_Invocable.RequetToRerank oRequest = new SBR_3_0_Get_User_Records_Invocable.RequetToRerank();
        oRequest.Ids = lUserIds;
        oRequest.ObjectAPIName = 'User';
        lRequest.add(oRequest);
        System.runAs(oRunAsUser){
            try{
                Test.startTest();
                SBR_3_0_Get_User_Records_Invocable.getUserRecords(lRequest);
                Test.stopTest();
            }
            Catch(Exception e){
                
            }
        }
    }   
    /************************************************************* Cover getUserRecords Ends*************************************************************/
}