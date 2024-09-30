/*********************************************************************************************************************
* Apex Class: SBR_3_0_BatchUpdateARSalesRep_Test
---------------------------------------------------------------------------------------------------------------------------------------
* - SF-6742
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME                      DATE                DETAIL FEATURES
1.0             Manish Taneja                    2024-02-05             Initial version 
*********************************************************************************************************************
* @description This Test class is for Batch update Sales Rep in Account Reationship Record.
*/ 
@isTest(seeAllData=false) 
public class SBR_3_0_BatchUpdateARSalesRep_Test {
/** 
* @description test class implementation
*/
    public Static testMethod void accountRelationshipOperations(){
/** 
* @description test Method implementation
*/
        Profile oProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User oRunAsUser = SBR_3_0_TestDataFactory.createUser(FALSE,oProfile);
        oRunAsUser.CompanyName = '01';
        Insert oRunAsUser;
        Profile oProfile1 = [SELECT Id FROM Profile WHERE Name = 'Sales'];
        User oRunAsUser1 = SBR_3_0_TestDataFactory.createUser(FALSE,oProfile1);
        oRunAsUser1.RepID__c = '9876540';
        oRunAsUser1.Analysis_Region_Key__c = '920';
        oRunAsUser1.CompanyName = '01';
        Insert oRunAsUser1;
        list<Account> lAccount = SBR_3_0_TestDataFactory.createAccounts(1,TRUE,'Credit');
        List<Account_Relationship__c> lAR = SBR_3_0_TestDataFactory.createAccountRelationships(1,lAccount[0].id,FALSE);
        for (Account_Relationship__c ar: lAR){
            ar.Sales_Rep_ID__c = 9876540;
        }
        INSERT lAR;
        System.runAs(oRunAsUser){
            Test.startTest();
            SBR_3_0_BatchUpdateARSalesRep batchCon = new SBR_3_0_BatchUpdateARSalesRep();
            Database.QueryLocator queryLoc = batchCon.start(null);
            batchCon.execute(null, lAR);
            batchCon.finish(null);    
            Test.stopTest();
        }
    }  
      
     public static testMethod void testScheduler() {
            
            SBR_3_0_BatchUpdateARSalesRepSchedule scheduler = new SBR_3_0_BatchUpdateARSalesRepSchedule();
            
            // Schedule the job
            Test.startTest();
            String jobId = System.schedule('Test SBR_3_0_BatchUpdateARSalesRepSchedule', '0 0 1 * * ? *', scheduler);
            Test.stopTest();
            
            CronTrigger scheduledJob = [SELECT Id FROM CronTrigger WHERE Id = :jobId LIMIT 1];
            System.assertNotEquals(null, scheduledJob, 'Scheduler job should be scheduled');
        }

}