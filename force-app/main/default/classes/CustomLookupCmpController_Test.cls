/*********************************************************************************************************************
* Apex Class: CustomLookupCmpController_Test
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* @description - Test class for CustomLookupCmpController
*
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
1.0             Hamza Benlafkih         2022-02-23          Initial version    
*********************************************************************************************************************/
@isTest
public with sharing class CustomLookupCmpController_Test {
    @testSetup static void setupTestData() {
        List<Account> accounts = SBR_3_0_TestDataFactory.createAccounts(2, false);
        accounts[0].Name = 'TestOne';
        accounts[1].Name = 'TestTwo';
        insert accounts;
        Id accId = accounts[0].Id;
        Id accId1 = accounts[1].Id; 
        accounts[1].ParentId = accId;
        update accounts[1];
        SBR_3_0_TestDataFactory.createContacts(5, accId, true);
        SBR_3_0_TestDataFactory.createContacts(1, accId1, true);
        List<AppDefinition> app=[SELECT DurableId, Label FROM AppDefinition where label='Sales'];
        Map<String,Object> fldValByFldName = new Map<String,Object> {
            'AppDefinitionId' =>app[0].DurableId ,
                'FormFactor' => 'Large',
                'UserId' => UserInfo.getUserId()
                };
         List<UserAppInfo> info=new List<UserAppInfo>{(UserAppInfo)JSON.deserialize(JSON.serialize(fldValByFldName),UserAppInfo.class)};
         insert info;             
    }
    static testMethod void testgetLookupValues() {
        Test.startTest();
        List<Account> acc = [Select id from Account];
        List<Account> accounts = (List<Account>) CustomLookupCmpController.getLookupValues('Test', 'Account', 'Name = \'TestOne\'','Name','Name',5);
        Test.stopTest();
        System.assert(accounts.size()>0);
    }
    static testMethod void testgetinitRecord() {
        Test.startTest();
        List<Account> acc = [Select id from Account];
        Account testAcc = (Account) CustomLookupCmpController.getinitRecord(acc[0].id,'Account','Owner.Name');
        Test.stopTest();
        System.assert(testAcc!=null);
    }
    static testMethod void testgetRecentlyCreatedRecords() {
        Test.startTest();
        List<Account> acc = [Select id from Account];
        List<Account> accounts = (List<Account>)CustomLookupCmpController.gerRecentlyCreatedRecords('Account','Owner.Name','Name = \'TestOne\'',5);
        Test.stopTest();
        System.assert(accounts.size()>0);
    }
    
}