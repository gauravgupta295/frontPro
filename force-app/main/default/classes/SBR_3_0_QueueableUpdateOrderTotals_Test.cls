@isTest
public class SBR_3_0_QueueableUpdateOrderTotals_Test {

    @TestSetup
    static void makeData(){
        
        Profile pfl = [SELECT id FROM Profile WHERE Name='System Administrator'];
        User admin = SBR_3_0_TestDataFactory.createUser(true, pfl);
        
    }
    
    @IsTest
    static void test_SBR_3_0_QueueableUpdateOrderTotals(){
        
        User admin = [SELECT Id FROM User WHERE Profile.Name='System Administrator' and isActive = true LIMIT 1];
        System.runAs(admin){
            Test.startTest();
            System.enqueueJob(new SBR_3_0_QueueableUpdateOrderTotals('preTestAccounts'));
            Test.stopTest();
        }
        
    }    
}