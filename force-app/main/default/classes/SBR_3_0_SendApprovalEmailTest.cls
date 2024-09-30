/*********************************************************************************************************************
* Apex Class: SBR_3_0_SendApprovalEmailTest
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Test class for SBR_3_0_SendApprovalEmailSchedule
* - SF-5859
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME                        DATE                DETAIL FEATURES
    1.0         Saathvik Tulasi                    2023-12-07             Initial version 
*********************************************************************************************************************/
@IsTest
public class SBR_3_0_SendApprovalEmailTest {
	/************************************************************* Cover SBR_3_0_SendApprovalEmailBatch Starts*************************************************************/
    @IsTest
    public Static void SBR_3_0_SendApprovalEmailBatch(){
        Profile oProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
		User adminRunUser = SBR_3_0_TestDataFactory.createUser(TRUE,oProfile);
		User oRunAsUser = SBR_3_0_TestDataFactory.createUser(FALSE,oProfile);
        oRunAsUser.Analysis_Region_Key__c = '921';
        oRunAsUser.FirstName = 'John';
        oRunAsUser.LastName = 'Doe'; 
        oRunAsUser.Rep_Type__c = 'General Tool';
        oRunAsUser.Country = 'CA';
        INSERT oRunAsUser;

        System.runAs(adminRunUser){
            list<Account> lAccount = SBR_3_0_TestDataFactory.createAccounts(1,TRUE);
            Analysis_Region__c oAnalysisRegion = SBR_3_0_TestDataFactory.createAnalysisRegion(TRUE,'921',lAccount[0].id);
            List<Account_Relationship__c> lAR = SBR_3_0_TestDataFactory.createAccountRelationships(1,lAccount[0].id,FALSE);
            for(Account_Relationship__c oAR : lAR){
                oAR.User_Account__c = oRunAsUser.id; 	    
            }
            INSERT lAR;

            List<Account_Management_Change_Request__c> acmrList = new List<Account_Management_Change_Request__c>();
            acmrList.add(new Account_Management_Change_Request__c(
                Account__c = lAccount[0].Id,
                Sales_Rep__c = oRunAsUser.Id,
                Approval_Status__c = 'Submitted',
                recordTypeId = Schema.SObjectType.Account_Management_Change_Request__c.getRecordTypeInfosByDeveloperName().get('Account_Relationship_Change').getRecordTypeId()
            ));
            acmrList.add(new Account_Management_Change_Request__c(
                Account__c = lAccount[0].Id,
                Sales_Rep__c = oRunAsUser.Id,
                Approval_Status__c = 'Submitted',
                recordTypeId = Schema.SObjectType.Account_Management_Change_Request__c.getRecordTypeInfosByDeveloperName().get('Strategic_Type_Change').getRecordTypeId()
            ));
            acmrList.add(new Account_Management_Change_Request__c(
                Account__c = lAccount[0].Id,
                Sales_Rep__c = oRunAsUser.Id,
                Approval_Status__c = 'Submitted',
                recordTypeId = Schema.SObjectType.Account_Management_Change_Request__c.getRecordTypeInfosByDeveloperName().get('OSR_Fingerprinting_Change').getRecordTypeId()
            ));
            insert acmrList;

            Test.setCreatedDate(acmrList[0].Id, System.now().addDays(-1));
            Test.setCreatedDate(acmrList[1].Id, System.now().addDays(-1));
            Test.setCreatedDate(acmrList[2].Id, System.now().addDays(-1));

            try{
                Test.startTest();
                SBR_3_0_SendApprovalEmailSchedule SC = new SBR_3_0_SendApprovalEmailSchedule();
                String sch ='0 48 * * * ?'; 
				System.schedule('Schedule Sync Sorting', sch,SC);
                Test.stopTest();
            }
            Catch(Exception e){
                
            }
        }
    }   
    /************************************************************* Cover SBR_3_0_SendApprovalEmailBatch Ends*************************************************************/

    @IsTest(SeeAllData=true)
    public Static void SBR_3_0_SendApprovalEmailQueuable(){
		Profile oProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
		User adminRunUser = SBR_3_0_TestDataFactory.createUser(TRUE,oProfile);
		User oRunAsUser = SBR_3_0_TestDataFactory.createUser(FALSE,oProfile);
        oRunAsUser.Analysis_Region_Key__c = '921';
        oRunAsUser.FirstName = 'John';
        oRunAsUser.LastName = 'Doe';
        oRunAsUser.Rep_Type__c = 'General Tool';
        oRunAsUser.Country = 'CA';
        oRunAsUser.Email = 'Test@test.com';
        INSERT oRunAsUser;
        
        List<Group> groups = [SELECT Id FROM Group WHERE DeveloperName in ('Account_Relationship_Change', 'EVP', 'Commissions_Team')];
        List<GroupMember> gms = new List<GroupMember>();
        


        for(Group grp: groups){
            GroupMember gm = new GroupMember(
                GroupId = grp.Id,
                UserOrGroupId = oRunAsUser.Id);
            gms.add(gm);    
        }

        if(!gms.isEmpty()){
            insert gms;
        }

        System.runAs(adminRunUser){
            list<Account> lAccount = SBR_3_0_TestDataFactory.createAccounts(1,TRUE);
            Analysis_Region__c oAnalysisRegion = SBR_3_0_TestDataFactory.createAnalysisRegion(TRUE,'921',lAccount[0].id);
            List<Account_Relationship__c> lAR = SBR_3_0_TestDataFactory.createAccountRelationships(1,lAccount[0].id,FALSE);
            for(Account_Relationship__c oAR : lAR){
                oAR.User_Account__c = oRunAsUser.id; 	    
            }
            INSERT lAR;

            List<Account_Management_Change_Request__c> acmrList = new List<Account_Management_Change_Request__c>();
            acmrList.add(new Account_Management_Change_Request__c(
                Account__c = lAccount[0].Id,
                Sales_Rep__c = oRunAsUser.Id,
                Approval_Status__c = 'Submitted',
                recordTypeId = Schema.SObjectType.Account_Management_Change_Request__c.getRecordTypeInfosByDeveloperName().get('Strategic_Type_Change').getRecordTypeId()
            ));

            acmrList.add(new Account_Management_Change_Request__c(
                Account__c = lAccount[0].Id,
                Sales_Rep__c = oRunAsUser.Id,
                Approval_Status__c = 'Submitted',
                recordTypeId = Schema.SObjectType.Account_Management_Change_Request__c.getRecordTypeInfosByDeveloperName().get('OSR_Fingerprinting_Change').getRecordTypeId()
            ));
            acmrList.add(new Account_Management_Change_Request__c(
                Account__c = lAccount[0].Id,
                Sales_Rep__c = oRunAsUser.Id,
                Approval_Status__c = 'Submitted',
                recordTypeId = Schema.SObjectType.Account_Management_Change_Request__c.getRecordTypeInfosByDeveloperName().get('Account_Relationship_Change').getRecordTypeId()
            ));
            
            
            insert acmrList;

            SBR_3_0_SendApprovalEmailQueueable qb = new SBR_3_0_SendApprovalEmailQueueable(
                new List<Account_Management_Change_Request__c>{acmrList[0]},
                new List<Account_Management_Change_Request__c>{acmrList[1]},
                new List<Account_Management_Change_Request__c>{acmrList[2]}
            );
            Test.startTest();
                System.enqueueJob(qb);
            Test.stopTest();

            System.assert(SBR_3_0_SendApprovalEmailQueueable.emailLimits >= 3, 'Looks like email is not sent');
        }
    }   
}