/**
 * @description       :  Class to test SBR_3_0_AccountDA_Test
---------------------------------------------------------------------------------------------------------------------------------------
* @author            : Kunal Patel
* @last modified on  : 05-07-2024
* @last modified by  : Kunal Patel
**/
@isTest
public without sharing class SBR_3_0_AccountDA_Test {
    
    @TestSetup
    static void makeData(){        
        List<Account> officeAccountList = SBR_3_0_TestDataFactory.createAccounts(2, false, SBR_3_0_Constants.ACCOUNT_REC_TYPE_OFFICE);
        Integer j=1;
        for(Account accOffice :officeAccountList){
            if(j == 1){
            	accOffice.Name = 'First Test Account';
            }else{
            	accOffice.Name = 'Second Test Account';
            }
            j++;
        }
        insert officeAccountList;
        
        List<Account> accountList = SBR_3_0_TestDataFactory.createAccounts(2, false, SBR_3_0_Constants.ACCOUNT_REC_TYPE_PROSPECT);
		Integer i = 1;
        for (Account acc : accountList) {
            acc.Name = 'Test Account - ' + Integer.valueof((Math.random() * 10000)).format();
            if(i==1) {
                acc.Sales_Activity_Status__c = 'Watchlist';
                acc.RM_Account_Number__c = '123-11';
                acc.BillingPostalCode = Integer.valueof((Math.random() * 10000)).format(); // to pass dupe rule
                acc.Override_Address__Latitude__s = 12.12;
                acc.Override_Address__Longitude__s = 12.12;
            }
            else if(i==2) {
                acc.Sales_Activity_Status__c = 'Dormant';
                acc.BillingPostalCode = Integer.valueof((Math.random() * 10000)).format(); // to pass dupe rule
            }
            acc.Managed_w_OSR_Fingerprint__c = true;
            acc.Sales_Rep_commission__c = true;
            acc.Account_Id__c = String.valueOf(i);
            acc.Plant_Ready_Required__c = true;
            acc.Company_Code__c = '01';
            //accountsWithUpdatedFields.add(acc);
            i++;
        }
        insert accountList;
        
        Integer count=1;
        for(Account accOffice :officeAccountList){
            String acId;
            if(count!=2){
                acId = accOffice.Id;
            }
            else if(count==2) {
                accOffice.ParentId = acId;
            }
            count++;
        }
        update officeAccountList;
        
        Id userId = UserInfo.getUserId();
		
		List<Account_Relationship__c> accRelList = new List<Account_Relationship__c>();
        Account_Relationship__c ar = new Account_Relationship__c();
        ar.Account_ID__c = accountList[1].Id;
        ar.User_Account__c = userId;
        ar.Rank__c = 1;
		accRelList.add(ar);
        
        Account_Relationship__c ar1 = new Account_Relationship__c();
        ar1.Account_ID__c = officeAccountList[0].Id;
        ar1.User_Account__c = userId;
        ar1.Rank__c = 1;
		accRelList.add(ar1);
        insert accRelList;
        
        //SADAPUR
        String uniqueUserName = 'testAdminUser' + DateTime.now().getTime() + '@SBRtestorg.com';
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User testUser = new User(Alias = 'standt', Email = 'standarduser@testorg.com', EmailEncodingKey = 'UTF-8',
                                    LastName = 'Testing', LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US',
                                    ProfileId = p.Id, TimeZoneSidKey = 'America/Los_Angeles', UserName = uniqueUserName,
                                    CompanyName = '01');
        insert testUser;
    }
    
    /********************
     * To cover parent-parent-parent scenario
     * *****************/
     @isTest 
    static void testGetAccounts3(){
        
        List<Account> prospectAccountList = SBR_3_0_TestDataFactory.createAccounts(10, false, SBR_3_0_Constants.ACCOUNT_REC_TYPE_PROSPECT);
        insert prospectAccountList;
        List<Account> accountList = new List<Account>();
        Test.startTest();
        accountList = SBR_3_0_AccountDA.getAccounts();
        List<Account> accList = [Select id,RM_Account_Number__c,ParentId from account where RM_Account_Number__c != null and recordtype.name = 'prospect' order by createddate desc limit 10];
        
		List<Account> accountUpdatedList = new List<Account>();
		accList[2].ParentId = accList[3].Id;
        accList[2].RM_Account_Number__c = null;
		accountUpdatedList.add(accList[2]);
        
        accList[1].ParentId = accList[2].Id;
        accList[1].RM_Account_Number__c = null;
		accountUpdatedList.add(accList[1]);
        
        accList[0].ParentId = accList[1].Id;
        accList[0].RM_Account_Number__c = null;
        accountUpdatedList.add(accList[0]);
		update accountUpdatedList;
	
			
		String acc = SBR_3_0_AccountDA.getAccountRMNumber(accList[0].id, true);
		SBR_3_0_AccountDA.getAccountsFromLatLong(accList);
		SBR_3_0_AccountDA.getAccount(accList[0].id);
		SBR_3_0_AccountDA.getAccountRMNumberAndType(accList[0].id, true);
        Test.stopTest();
        Assert.isNotNull(acc,'RMNumber not null');
    }
    
    /********************
     * To cover parent-parent-parent-parent scenario
     * *****************/
     @isTest 
    static void testGetAccounts4(){
        
        List<Account> prospectAccountList = SBR_3_0_TestDataFactory.createAccounts(10, false, SBR_3_0_Constants.ACCOUNT_REC_TYPE_PROSPECT);
        insert prospectAccountList;
        List<Account> accountList = new List<Account>();
        Test.startTest();
        accountList = SBR_3_0_AccountDA.getAccounts();
        List<Account> accList = [Select id,RM_Account_Number__c,ParentId from account where RM_Account_Number__c != null and recordtype.name = 'prospect' order by createddate desc limit 10];
        system.debug('accList::'+accList.size()+'  ----------------     '+accList);
        
		List<Account> accountUpdatedList = new List<Account>();
		accList[3].ParentId = accList[4].Id;
        accList[3].RM_Account_Number__c = null;
		accountUpdatedList.add(accList[3]);
        
        accList[2].ParentId = accList[3].Id;
        accList[2].RM_Account_Number__c = null;
		accountUpdatedList.add(accList[2]);
        
        accList[1].ParentId = accList[2].Id;
        accList[1].RM_Account_Number__c = null;
		accountUpdatedList.add(accList[1]);
        
        accList[0].ParentId = accList[1].Id;
        accList[0].RM_Account_Number__c = null;
		accountUpdatedList.add(accList[0]);
        update accountUpdatedList;
        
		String acc = SBR_3_0_AccountDA.getAccountRMNumber(accList[0].id, true);
		SBR_3_0_AccountDA.getAccountsFromLatLong(accList);
		SBR_3_0_AccountDA.getAccount(accList[0].id);
		SBR_3_0_AccountDA.getAccountRMNumberAndType(accList[0].id, true);
        Test.stopTest();
        Assert.isNotNull(acc,'RMNumber not null');
    }
    
    /********************
     * To cover parent-parent-parent-parent-parent scenario
     * *****************/
     @isTest 
    static void testGetAccounts5(){
        
        List<Account> prospectAccountList = SBR_3_0_TestDataFactory.createAccounts(10, false, SBR_3_0_Constants.ACCOUNT_REC_TYPE_PROSPECT);
        insert prospectAccountList;
        List<Account> accountList = new List<Account>();
        Test.startTest();
        accountList = SBR_3_0_AccountDA.getAccounts();
        List<Account> accList = [Select id,RM_Account_Number__c,ParentId from account where RM_Account_Number__c != null and recordtype.name = 'prospect' order by createddate desc limit 10];
        system.debug('accList::'+accList.size()+'  ----------------     '+accList);
        
		List<Account> accountUpdatedList = new List<Account>();
		accList[4].ParentId = accList[5].Id;
        accList[4].RM_Account_Number__c = null;
		accountUpdatedList.add(accList[4]);
        
        accList[3].ParentId = accList[4].Id;
        accList[3].RM_Account_Number__c = null;
		accountUpdatedList.add(accList[3]);
        
        accList[2].ParentId = accList[3].Id;
        accList[2].RM_Account_Number__c = null;
		accountUpdatedList.add(accList[2]);
        
        accList[1].ParentId = accList[2].Id;
        accList[1].RM_Account_Number__c = null;
		accountUpdatedList.add(accList[1]);
        
        accList[0].ParentId = accList[1].Id;
        accList[0].RM_Account_Number__c = null;
		accountUpdatedList.add(accList[0]);
        update accountUpdatedList;
        
		String acc = SBR_3_0_AccountDA.getAccountRMNumber(accList[0].id, true);
		SBR_3_0_AccountDA.getAccountsFromLatLong(accList);
		SBR_3_0_AccountDA.getAccount(accList[0].id);
		SBR_3_0_AccountDA.getAccountRMNumberAndType(accList[0].id, true);
		Test.stopTest();
        Assert.isNotNull(acc,'RMNumber not null');
    }
    
    
    
    @isTest
    static void testSearchAccounts1() {
        List<Account> acc1 = [SELECT ID, recordtype.name, ParentId FROM Account];
        SBR_3_0_GoogleMapCmpController.FilterWrapper wrapper = new SBR_3_0_GoogleMapCmpController.FilterWrapper();
        wrapper.accountSearch = 'Test';
        wrapper.top25Accounts = false;
        wrapper.top50Accounts = false;
        wrapper.watchlistAccounts = false;
        wrapper.topXAccounts = false;
        wrapper.rankRangeAccounts = false;
        wrapper.showOffices = true;
        wrapper.searchAccounts = true;
        wrapper.includeTracked = false;

        Account acc = [SELECT ID, recordtype.name, ParentId FROM Account WHERE RecordTypeId = :SBR_3_0_Constants.ACCOUNT_OFFICE_RT_ID LIMIT 1];
        Id[] fixedSearchResults = new Id[1];
        fixedSearchResults[0] = acc.Id;
        Test.setFixedSearchResults(fixedSearchResults);

        Test.startTest();
            List<SBR_3_0_AccountDA.AccountWrapper> testAccounts = SBR_3_0_AccountDA.getAccountsFiltered(wrapper);
        Test.stopTest();
    }
    
    @isTest
    static void testGetAccountWithLock() {
        Account acc = [SELECT ID FROM Account LIMIT 1];
       
        Test.startTest();
            Account testAccount = SBR_3_0_AccountDA.getAccountWithLock(acc.Id);
        Test.stopTest();
    }
    
    @isTest
    static void testGetAccountsWithIds() {
        Set<Id> ids = new Set<Id>();
        List<Account> accountsList = [SELECT Id FROM Account];
        for(Account account : accountsList) {
            ids.add(account.Id);
        }
        Map<Id, Account> accounts = new Map<Id, Account>();
        Test.startTest();
            accounts = SBR_3_0_AccountDA.getAccounts(ids);
        Test.stopTest();
    }

    @isTest 
    static void testGetAccounts(){
        List<Account> accountList = new List<Account>();
        Test.startTest();
            accountList = SBR_3_0_AccountDA.getAccounts();
            List<Account> accList = [Select id,RM_Account_Number__c,ParentId from account];
            String acc = SBR_3_0_AccountDA.getAccountRMNumber(accList[0].id, true);
            SBR_3_0_AccountDA.getAccountsFromLatLong(accList);
            SBR_3_0_AccountDA.getAccount(accList[0].id);
            SBR_3_0_AccountDA.getAccountRMNumberAndType(accList[0].id, true);
        Test.stopTest();
        Assert.isNotNull(acc,'RMNumber not null');
    }
    
    /********************
     * To cover parent scenario
     * *****************/
     @isTest 
    static void testGetAccounts1(){
        List<Account> accountList = new List<Account>();
        Test.startTest();
            accountList = SBR_3_0_AccountDA.getAccounts();
            List<Account> accList = [Select id,RM_Account_Number__c,ParentId from account];
			system.debug('accList::'+accList.size()+'  ----------------     '+accList);
			accList[0].RM_Account_Number__c = null;
			accList[0].ParentId = accList[3].Id;
			update accList[0];
        
            String acc = SBR_3_0_AccountDA.getAccountRMNumber(accList[0].id, true);
            SBR_3_0_AccountDA.getAccountsFromLatLong(accList);
            SBR_3_0_AccountDA.getAccount(accList[0].id);
            SBR_3_0_AccountDA.getAccountRMNumberAndType(accList[0].id, true);
        Test.stopTest();
        Assert.isNotNull(acc,'RMNumber not null');
    }
    
    /********************
     * To cover parent-parent scenario
     * *****************/
     @isTest 
    static void testGetAccounts2(){
        List<Account> accountList = new List<Account>();
        Test.startTest();
            accountList = SBR_3_0_AccountDA.getAccounts();
            List<Account> accList = [Select id,RM_Account_Number__c,ParentId from account];
			system.debug('accList::'+accList.size()+'  ----------------     '+accList);
			List<Account> accountUpdatedList = new List<Account>();
			accList[2].RM_Account_Number__c = null;
			accList[2].ParentId = accList[3].Id;
			accountUpdatedList.add(accList[2]);
			
			accList[0].RM_Account_Number__c = null;
			accList[0].ParentId = accList[2].Id;
			accountUpdatedList.add(accList[0]);
			update accountUpdatedList;

            String acc = SBR_3_0_AccountDA.getAccountRMNumber(accList[0].id, true);
            SBR_3_0_AccountDA.getAccountsFromLatLong(accList);
            SBR_3_0_AccountDA.getAccount(accList[0].id);
            SBR_3_0_AccountDA.getAccountRMNumberAndType(accList[0].id, true);
        Test.stopTest();
        Assert.isNotNull(acc,'RMNumber not null');
    }

    @isTest
    static void testGetTopAccount() {
        List<SBR_3_0_AccountDA.AccountWrapper> accountWrapperList = new List<SBR_3_0_AccountDA.AccountWrapper>();

        Test.startTest();
            accountWrapperList = SBR_3_0_AccountDA.getTopAccounts(UserInfo.getUserId());
            Id aId = accountWrapperList[0].account.Id;
            Set<Id> accIds = new Set<Id>();
            accIds.add(aId);
            Set<Id> userIds = new Set<Id>();
            userIds.add(UserInfo.getUserId());
            Map<Id, Account_Relationship__c> arList = SBR_3_0_AccountDA.getAccountRelationShipAccountId(accIds, userIds);
            System.assertEquals(arList.get(aId).Rank__c, 1, 'Assert Success');
        Test.stopTest();
    }

    @isTest
    static void testGetAccountsByRecordType() {
       
        Test.startTest();
            List<Account> testAccounts = SBR_3_0_AccountDA.getAccountsByRecordTypeName(SBR_3_0_Constants.ACCOUNT_REC_TYPE_PROSPECT);
            System.assertEquals('123-11', testAccounts[0].RM_Account_Number__c,'Assert Success');
        Test.stopTest();
    }

    @isTest
    static void testGetAccountsReadinessFields() {
        Map<Id, Account> accountMap = new Map<Id, Account>([SELECT ID FROM Account]);
       
        Test.startTest();
            Map<Id, Account> testAccounts = SBR_3_0_AccountDA.getAccountReadinessFields(accountMap.keySet());
            System.assertEquals(accountMap.keySet().size(), testAccounts.keySet().size(),'Assert Success');
        Test.stopTest();
    }

    @isTest
    static void testGetAccountsLatLngStatus() {
        Map<Id, Account> accountMap = new Map<Id, Account>([SELECT ID FROM Account]);
       
        Test.startTest();
            List<Account> testAccounts = SBR_3_0_AccountDA.getAccountsLatLongStatus(accountMap.keySet());
            System.assertEquals(accountMap.keySet().size(), testAccounts.size(),'Assert Success');
        Test.stopTest();
    }

    @isTest
    static void testGetAccountsName() {
        Map<Id, Account> accountMap = new Map<Id, Account>([SELECT ID FROM Account]);
       
        Test.startTest();
            Map<Id, Account> testAccounts = SBR_3_0_AccountDA.getAccountsName(accountMap.keySet());
            System.assertEquals(accountMap.keySet().size(), testAccounts.keySet().size(),'Assert Success');
        Test.stopTest();
    }
    
    @isTest
    static void testGetAccountsById() {

        SBR_3_0_GoogleMapCmpController.FilterWrapper wrapper = new SBR_3_0_GoogleMapCmpController.FilterWrapper();
        wrapper.accountSearch = 'Test';
        wrapper.top25Accounts = true;
        wrapper.top50Accounts = true;
        wrapper.watchlistAccounts = true;
        wrapper.topXAccounts = true;
        wrapper.topXAccountsValue = '100';
        wrapper.rankRangeAccounts = true;
        wrapper.rankRangeAccountsStart = '0';
        wrapper.rankRangeAccountsEnd = '100';
        wrapper.accountRecordType = JSON.serialize(new List<String>{'Prospect'});
        wrapper.showOffices = true;
        wrapper.searchAccounts = false;
        wrapper.includeTracked = true;

        Test.startTest();
            List<SBR_3_0_AccountDA.AccountWrapper> testAccounts = SBR_3_0_AccountDA.getAccountsFiltered(wrapper);
        Test.stopTest();

    }
    
    
    @isTest
    static void testSearchAccounts() {

        SBR_3_0_GoogleMapCmpController.FilterWrapper wrapper = new SBR_3_0_GoogleMapCmpController.FilterWrapper();
        wrapper.accountSearch = 'Test';
        wrapper.top25Accounts = false;
        wrapper.top50Accounts = false;
        wrapper.watchlistAccounts = false;
        wrapper.topXAccounts = false;
        wrapper.rankRangeAccounts = false;
        wrapper.showOffices = true;
        wrapper.searchAccounts = true;
        wrapper.includeTracked = false;

        Account acc = [SELECT ID FROM Account WHERE RM_Account_Number__c = '123-11' LIMIT 1];

        Id[] fixedSearchResults = new Id[1];
        fixedSearchResults[0] = acc.Id;
        Test.setFixedSearchResults(fixedSearchResults);

        Test.startTest();
            List<SBR_3_0_AccountDA.AccountWrapper> testAccounts = SBR_3_0_AccountDA.getAccountsFiltered(wrapper);
        Test.stopTest();

    }

    @isTest
    static void testGetAccountRelationshipsForUsers() {

        Set<String> userIds = new Set<String>();
        userIds.add(UserInfo.getUserId());

        Test.startTest();
            List<AggregateResult> ars = SBR_3_0_AccountDA.getAccountRelationshipsForUsers(userIds);
        Test.stopTest();

        System.assertEquals(ars.size(), 1, 'Assert Success');
    }

    @isTest
    static void testGetAccountRelationshipsForUsersLowestRank() {

        SBR_3_0_GoogleMapCmpController.FilterWrapper wrapper = new SBR_3_0_GoogleMapCmpController.FilterWrapper();
        wrapper.userTerritories = UserInfo.getUserId();

        Test.startTest();
            Decimal result = SBR_3_0_AccountDA.getAccountRelationshipsForUsersLowestRank(wrapper);
        Test.stopTest();

        System.assertEquals(result, 1, 'Assert Success');
    }

    @isTest
    static void testGetAccountByRmAccountNumber() {

       Test.startTest();
        Account result = SBR_3_0_AccountDA.getAccountByRmAccountNumber('123-11');
        Map<Id, Account> result2 = SBR_3_0_AccountDA.getAccountsByRMNumbers(new Set<String>{''});
        
        Test.stopTest();

        System.assertNotEquals(result.Id, null, 'Assert Success');
        System.assertNotEquals(result2.size(), null, 'Assert Success');
    }


    @isTest
    static void testGetAccountRelationShipAccountId() {

        Map<Id, Account> accsMap = new Map<Id, Account>([SELECT ID FROM Account]);

        Test.startTest();
            Map<Id, Account_Relationship__c> result = SBR_3_0_AccountDA.getAccountRelationShipAccountId(accsMap.keySet(), new Set<Id>{UserInfo.getUserId()});
        Test.stopTest();

        System.assertEquals(result.size(), 2, 'Assert Success');
    }

    @isTest
    static void testGetAccountsForRM() {

        User testUser = [SELECT Id FROM User WHERE UserName LIKE 'testAdminUser%'];
        List<Account> testAccounts = SBR_3_0_AccountDA.getAccounts();
        System.runAs(testUser) {
            Test.startTest();
            
            Account rmAccount = SBR_3_0_AccountDA.getAccountsForRM(testAccounts[0].Id);
           Assert.areEqual(testAccounts[0].Id, rmAccount.Id, 'Assert Success');
            Test.stopTest();
        }
    }

    @isTest
    static void testGetDefaultLocationAndJobsite() {
        List<Account> testAccounts = SBR_3_0_AccountDA.getAccounts();
        Set<Id> accIds = new Set<Id>();
        accIds.add(testAccounts[0].Id);
        Test.startTest();
            List<Account> resultAccounts = SBR_3_0_AccountDA.getAccountDefaultLocationAndJobsite(accIds);
            System.assertEquals(true, accIds.contains(resultAccounts[0].Id), 'Assert Success');
        Test.stopTest();
    }
   
    @isTest
    static void testGetContactAccount() {
        List<Account> testAccounts = SBR_3_0_AccountDA.getAccounts();

        Test.startTest();
            Account contAccount = SBR_3_0_AccountDA.getContactAccount(testAccounts[0].Id);
            System.assertEquals(testAccounts[0].Id, contAccount.Id, 'Assert Success');
        Test.stopTest();
    }
}