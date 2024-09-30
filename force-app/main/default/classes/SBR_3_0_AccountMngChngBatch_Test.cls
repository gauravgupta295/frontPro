/**
* @description       : Test Class for SBR_3_0_AccountMngChngReqNightlyBatch Apex Class
* @author            : Prachi Agarwal
* @group             : 
* @last modified on  : 01-02-2024
* @last modified by  : Prachi Agarwal
**/
@isTest
private class SBR_3_0_AccountMngChngBatch_Test {
    
    @TestSetup
    static void makeData(){        
        List<Account> accountList = SBR_3_0_TestDataFactory.createAccounts(1, false, SBR_3_0_Constants.ACCOUNT_REC_TYPE_PROSPECT);
        
        Account acc = accountList[0];
        acc.Sales_Activity_Status__c = 'Watchlist';
        acc.RM_Account_Number__c = '123-11';
        acc.BillingPostalCode = Integer.valueof((Math.random() * 10000)).format(); 
        acc.Override_Address__Latitude__s = 12.12;
        acc.Override_Address__Longitude__s = 12.12;
        acc.Managed_w_OSR_Fingerprint__c = false;
        acc.Sales_Rep_commission__c = true;
        acc.Account_Id__c = '1234';
        acc.Plant_Ready_Required__c = true;
        insert acc;
        
        User u = SBR_3_0_TestDataFactory.createUsers(1, false)[0];
        u.FirstName = 'John';
        u.LastName = 'Doe';
        u.Rep_Type__c = 'General Tool';
        insert u;   
        
        Account_Relationship__c ar = new Account_Relationship__c();
        ar.Account_ID__c = acc.Id;
        ar.User_Account__c = u.Id;
        ar.Rank__c = 1;
        insert ar; 
        
        Account_Management_Change_Request__c accMgmt = new Account_Management_Change_Request__c(
            Approval_Status__c = 'Approved',
            Effective_Date__c = Date.today(),
            account__c= acc.Id,
            Managed_w_OSR_Fingerprint__c= true,
            Current_Sales_Rep__c = u.Id
        );
        insert accMgmt;
    }
    
    @isTest
    static void testAccMngChngOSRFingerprint() {
        
        Account_Management_Change_Request__c accManagement = [Select Id,Name,Managed_w_OSR_Fingerprint__c from Account_Management_Change_Request__c where Approval_Status__c='Approved' LIMIT 1];
        
        accManagement.recordTypeId = SBR_3_0_Constants.OSR_Fingerprinting_Change_RecordTypeId;
        update accManagement;
        
        Test.startTest();
        SBR_3_0_AccountMngChngReqNightlyBatch batch = new SBR_3_0_AccountMngChngReqNightlyBatch();
        Database.executeBatch(batch);
        Test.stopTest();
        
        System.assertEquals(accManagement.Managed_w_OSR_Fingerprint__c, true, 'Managed With OSR Future Status must be true');
    }   
    
    @isTest
    static void testAccMngChngStrategicType() {
        
        Account_Management_Change_Request__c accManagement = [Select Id,Name,Managed_w_OSR_Fingerprint__c from Account_Management_Change_Request__c where Approval_Status__c='Approved' LIMIT 1];
        
        accManagement.recordTypeId = SBR_3_0_Constants.Strategic_Type_Change_RecordTypeId;
        update accManagement;
        
        Test.startTest();
        SBR_3_0_AccountMngChngReqNightlyBatch batch = new SBR_3_0_AccountMngChngReqNightlyBatch();
        Database.executeBatch(batch);
        Test.stopTest();
        
        System.assertEquals(accManagement.Managed_w_OSR_Fingerprint__c, true, 'Managed With OSR Future Status must be true');
    }   
    
    @isTest
    static void testAccMngAccRelChng() {
        
        Account_Management_Change_Request__c accManagement = [Select Id,Name,Managed_w_OSR_Fingerprint__c from Account_Management_Change_Request__c where Approval_Status__c='Approved' LIMIT 1];
        
        accManagement.recordTypeId = SBR_3_0_Constants.Account_Relationship_Change_RecordTypeId;
        update accManagement;
        
        Test.startTest();
        SBR_3_0_AccountMngChngReqNightlyBatch batch = new SBR_3_0_AccountMngChngReqNightlyBatch();
        Database.executeBatch(batch);
        Test.stopTest();
        
        System.assertEquals(accManagement.Managed_w_OSR_Fingerprint__c, true, 'Managed With OSR Future Status must be true');
    }  
    
    @isTest
    static void testAccountMngChng() {
        
        Account_Relationship__c accRelationship = [Select Id from Account_Relationship__c LIMIT 1];
        
        Account_Management_Change_Request__c accManagement = [Select Id,Name,Managed_w_OSR_Fingerprint__c from Account_Management_Change_Request__c where Approval_Status__c='Approved' LIMIT 1];
        
        accManagement.recordTypeId = SBR_3_0_Constants.Account_Relationship_Change_RecordTypeId;
        accManagement.Account_Relationship__c = accRelationship.Id;
        update accManagement;
        
        Test.startTest();
        SBR_3_0_AccountMngChngReqNightlyBatch batch = new SBR_3_0_AccountMngChngReqNightlyBatch();
        Database.executeBatch(batch);
        Test.stopTest();
        
        System.assertEquals(accManagement.Managed_w_OSR_Fingerprint__c, true, 'Managed With OSR Future Status must be true');
    }   
}