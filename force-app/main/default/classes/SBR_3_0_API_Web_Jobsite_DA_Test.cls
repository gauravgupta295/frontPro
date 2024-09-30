/**
 * @description       : Unit test for SBR_3_0_API_Web_Jobsite_DA
 * @author            : Salesforce
 * @group             :
 * @last modified on  : 12-13-2023
 * @last modified by  : Salesforce
**/
@isTest
private with sharing class SBR_3_0_API_Web_Jobsite_DA_Test {
    @TestSetup
    static void makeData() {
        //Make Accounts
        List<Account> testAccounts = SBR_3_0_TestDataFactory.createAccounts(2, false);
        Account acc = testAccounts[0];
        acc.RM_Account_Number__c = 'testRMnumber';
        insert acc;
        
        Account fallbackAcc = testAccounts[1];
        fallbackAcc.Name = 'Job Site Placeholder Account';
        insert fallbackAcc;
        
        //Make Locations
        Schema.Location branchLocation = SBR_3_0_TestDataFactory.createLocations(1, false, SBR_3_0_Constants.LOCATION_REC_TYPE_BRANCH)[0];
        branchLocation.Branch_Location_Number__c = '1234';
        insert branchLocation;
        
        List<Schema.Location> testJobLocations = SBR_3_0_TestDataFactory.createLocations(2, false, SBR_3_0_Constants.LOCATION_REC_TYPE_JOB_LOC);
        
        Schema.Location jobLocationAddress = testJobLocations[0];
        jobLocationAddress.Name = 'Test Address Location';
        jobLocationAddress.Street_Address__c = 'Test Street';
        jobLocationAddress.City__c = 'Test City';
        jobLocationAddress.Zip_Code__c = '123456';
        jobLocationAddress.State__c= 'CA';
        jobLocationAddress.Country__c='US';
        insert jobLocationAddress;
        
        Schema.Location jobLocationLatLong = testJobLocations[1];
        jobLocationLatLong.Name = 'Test Lat Long Location';
        jobLocationLatLong.Latitude_Longitude__latitude__s = 42.38635;
        jobLocationLatLong.Latitude_Longitude__longitude__s = -121.59855;
        insert jobLocationLatLong;
    }
    
    @isTest
    static void getRelatedAccountSuccessTest() {
        
        Id accId = [SELECT Id,RM_Account_Number__c FROM Account WHERE RM_Account_Number__c = '01-testRMnumber' LIMIT 1].Id;
        Test.startTest();
            Account result = SBR_3_0_API_Web_Jobsite_DA.getRelatedAccount('01-testRMnumber');
        Test.stopTest();
        System.assertEquals(accId, result.Id, 'Object Id does not match');
    }
    
    @isTest
    static void getRelatedAccountFailTest() {
        Id fallbackId = [SELECT Id FROM Account WHERE Name = 'Job Site Placeholder Account' LIMIT 1][0].Id;
        Test.startTest();
            Account result = SBR_3_0_API_Web_Jobsite_DA.getRelatedAccount('nonexistantNum');
        Test.stopTest();
        System.assertEquals(fallbackId, result.Id, 'Object Id does not match');
    }
    
    @isTest
    static void getRelatedBranchLocationSuccessTest() {
        Id branchId = [SELECT Id FROM Location WHERE Branch_Location_Number__c = '1234' LIMIT 1][0].Id;
        Test.startTest();
            Schema.Location result = SBR_3_0_API_Web_Jobsite_DA.getRelatedBranchLocation('1234');
        Test.stopTest();
        System.assertEquals(branchId, result.Id, 'Object Id does not match');
    }
    
    @isTest
    static void getRelatedBranchLocationFailTest() {
        Test.startTest();
            Schema.Location result = SBR_3_0_API_Web_Jobsite_DA.getRelatedBranchLocation('0987');
        Test.stopTest();
        System.assertEquals(null, result, 'Object should be null');
    }
    
    @isTest
    static void getRelatedJobLocationByAddressTest() {
        Id locationId = [SELECT Id FROM Location WHERE Name = 'Test Address Location' LIMIT 1][0].Id;
        Test.startTest();
            Schema.Location result = SBR_3_0_API_Web_Jobsite_DA.getRelatedJobLocation('Test Street', 'Test City', 'CA', '123456', 'US', 0.0, 0.0);
        Test.stopTest();
        System.assertEquals(locationId, result.Id, 'Object Id does not match');
    }
    
    @isTest
    static void getRelatedJobLocationByLatLongTest() {
        Id locationId = [SELECT Id FROM Location WHERE Name = 'Test Lat Long Location' LIMIT 1][0].Id;
        Test.startTest();
            Schema.Location result = SBR_3_0_API_Web_Jobsite_DA.getRelatedJobLocation('','','','','', 42.38635, -121.59855);
        Test.stopTest();
        System.assertEquals(locationId, result.Id, 'Object Id does not match');
    }
}