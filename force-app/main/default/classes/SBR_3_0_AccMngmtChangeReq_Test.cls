@isTest
public with sharing class SBR_3_0_AccMngmtChangeReq_Test {
    @TestSetup
    static void makeData(){
        
        Account acc = SBR_3_0_TestDataFactory.createAccounts(1, true)[0];
        User u = SBR_3_0_TestDataFactory.createUsers(1, false)[0];
        u.FirstName = 'John';
        u.LastName = 'Doe';
        u.Rep_Type__c = 'General Tool';
        insert u;                   
    }

    public Static testMethod void WyneeSalesRepTestMappingTest() {
        List<Account> accList = [Select id from Account LIMIT 1];
        Profile oProfile = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User adminUser = SBR_3_0_TestDataFactory.createUser(TRUE,oProfile);
        Wynne_Sales_Rep_Mapping__mdt[] wyneeSalesList = [Select id, CRMRepType__c, Managed__c,SalesRepType__c,WynneSalesRepType__c from Wynne_Sales_Rep_Mapping__mdt];
        System.runas(adminUser){
            List<User> uList =  [SELECT id, isActive,ProfileId FROM User where firstname = 'John' LIMIT 1];
            uList[0].Rep_Type__c = 'General Tool';
            uList[0].Country = 'US';
            update uList[0];
            Account_Management_Change_Request__c acmr = new Account_Management_Change_Request__c();
            acmr.Account__c = accList[0].Id;
            acmr.Sales_Rep__c = uList[0].Id;
            insert acmr;
            System.assertEquals(acmr.Managed__c, false);
            
        }
    }
}