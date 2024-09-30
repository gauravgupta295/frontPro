/**
 * @description       : 
 * @author            : Hamza B
 * @group             : 
 * @last modified on  : 12-18-2023
 * @last modified by  : Hamza B
**/
@isTest
public class SBR_3_0_AccountManagementCRTest {

    @TestSetup
    static void makeData(){
        Profile oProfile = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User adminUser = SBR_3_0_TestDataFactory.createUser(false,oProfile);
        adminUser.FirstName = 'Hamza';
        adminUser.LastName = 'Ben01';
        insert adminUser;
 
        List<Account_Management_Change_Request__c> accMngList = new List<Account_Management_Change_Request__c>();
        List<Id> recordTypeIdList = new List<Id>();
        recordTypeIdList.add(SBR_3_0_Constants.Account_Relationship_Change_RecordTypeId);
        recordTypeIdList.add(SBR_3_0_Constants.OSR_Fingerprinting_Change_RecordTypeId);
        recordTypeIdList.add(SBR_3_0_Constants.Strategic_Type_Change_RecordTypeId);
        System.runAs(adminUser){
            List<Account> accList = SBR_3_0_TestDataFactory.createAccounts(3, true);
            for (Integer i = 0; i < 3; i++) {
               Account_Management_Change_Request__c amcr = new Account_Management_Change_Request__c(
                  Name = 'Test Record ' + i,
                  Approval_Status__c = 'Submitted',
                  Account__c = accList[i].Id,
                  recordTypeId = recordTypeIdList[i]
               );
               accMngList.add(amcr);
            }
            insert accMngList;
        } 
    }
    
    @isTest
    private static void getAccountManagementCRColumnsTest() {
        User adminUser =  [SELECT id, FirstName, LastName FROM User where FirstName = 'Hamza' and LastName = 'Ben01' LIMIT 1][0];
        String filterName = 'My Pending Requests for Account Relationships';
        System.runAs(adminUser){
            Test.startTest();
            SBR_3_0_AccountManagementCRController.getAccountManagementCRColumns(filterName);
            Test.stopTest();
        }
    }
    
    @isTest
    private static void getAccountManagmentCRRecordsPRAccRTest() {
        User adminUser =  [SELECT id, FirstName, LastName FROM User where FirstName = 'Hamza' and LastName = 'Ben01' LIMIT 1][0];

        String filterName = 'My Pending Requests for Account Relationships';
        System.runAs(adminUser){
            Test.startTest();
            SBR_3_0_AccountManagementCRController.getAccountManagmentCRRecords(filterName, '');
            Test.stopTest();
        }
    }
    
    @isTest
    private static void getAccountManagmentCRRecordsPendingRequestOSRTest() {
        User adminUser =  [SELECT id, FirstName, LastName FROM User where FirstName = 'Hamza' and LastName = 'Ben01' LIMIT 1][0];

        String filterName = 'Approver View - Pending OSR Fingerprint Updates';
        System.runAs(adminUser){
            Test.startTest();
            SBR_3_0_AccountManagementCRController.getAccountManagmentCRRecords(filterName, '');
            Test.stopTest();
        }
    }
    
    @isTest
    private static void getAccountManagmentCRRecordsPendingRequestStratigicTest() {
        User adminUser =  [SELECT id, FirstName, LastName FROM User where FirstName = 'Hamza' and LastName = 'Ben01' LIMIT 1][0];

        String filterName = 'Requestor View - My Pending Strategic Type Updates';
        System.runAs(adminUser){
            Test.startTest();
            SBR_3_0_AccountManagementCRController.getAccountManagmentCRRecords(filterName, '');
            Test.stopTest();
        }
    }
    
    @isTest
    private static void getAccountManagmentCRRecordsSubmitAccRelChReqTest() {
        User adminUser =  [SELECT id, FirstName, LastName FROM User where FirstName = 'Hamza' and LastName = 'Ben01' LIMIT 1][0];

        String filterName = System.Label.SBR_3_0_Account_Management_CR_Submitted_Account_Relationship_Change_Requests;
        System.runAs(adminUser){
            Test.startTest();
            SBR_3_0_AccountManagementCRController.getAccountManagmentCRRecords(filterName, 'Test Record');
            Test.stopTest();
        }
    }
    
    @isTest
    private static void getAccountManagmentCRRecordsCRStratTypeChReqTest() {
        User adminUser =  [SELECT id, FirstName, LastName FROM User where FirstName = 'Hamza' and LastName = 'Ben01' LIMIT 1][0];

        String filterName = System.Label.SBR_3_0_Account_Management_CR_Strategic_Type_Change_Requests;
        System.runAs(adminUser){
            Test.startTest();
            SBR_3_0_AccountManagementCRController.getAccountManagmentCRRecords(filterName, 'Test Record');
            Test.stopTest();
        }
    }

    @isTest
    private static void sendNoteficationsForAccountManagementCRBATest() {
        User adminUser =  [SELECT id, FirstName, LastName FROM User where FirstName = 'Hamza' and LastName = 'Ben01' LIMIT 1][0];
        List<Account_Management_Change_Request__c> accMngList = [SELECT Id FROM Account_Management_Change_Request__c];
        String filterName = 'My Pending Requests for Account Relationships';
        String ClicledButton = System.Label.SBR_3_0_Account_Management_CR_Button_Approve;
        String comment = 'comment from user interface';
        
        System.runAs(adminUser){
            Test.startTest();
            SBR_3_0_AccountManagementCRController.sendNoteficationsForAccountManagementCR(accMngList, ClicledButton, comment, filterName);
            Test.stopTest();
        }
    }
    
    @isTest
    private static void sendNoteficationsForAccountManagementCRBRTest() {
        User adminUser =  [SELECT id, FirstName, LastName FROM User where FirstName = 'Hamza' and LastName = 'Ben01' LIMIT 1][0];
        List<Account_Management_Change_Request__c> accMngList = [SELECT Id FROM Account_Management_Change_Request__c];
        String filterName = 'My Pending Requests for Account Relationships';
        String comment = 'comment from user interface';
        String ClicledButton = System.Label.SBR_3_0_Account_Management_CR_Button_Reject;

        System.runAs(adminUser){
            Test.startTest();
            SBR_3_0_AccountManagementCRController.sendNoteficationsForAccountManagementCR(accMngList, ClicledButton, comment, filterName);
            Test.stopTest();
        }
    }
    
    @isTest
    private static void sendNoteficationsForAccountManagementCRBRecallTest() {
        User adminUser =  [SELECT id, FirstName, LastName FROM User where FirstName = 'Hamza' and LastName = 'Ben01' LIMIT 1][0];
        List<Account_Management_Change_Request__c> accMngList = [SELECT Id FROM Account_Management_Change_Request__c];
        String filterName = 'My Pending Requests for Account Relationships';
        String comment = 'comment from user interface';
        String ClicledButton = System.Label.SBR_3_0_Account_Management_CR_Button_Recall;
        
        System.runAs(adminUser){
            Test.startTest();
            SBR_3_0_AccountManagementCRController.sendNoteficationsForAccountManagementCR(accMngList, ClicledButton, comment, filterName);
            Test.stopTest();
        }
    }
}