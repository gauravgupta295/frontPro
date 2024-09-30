/*********************************************************************************************************************
* Apex Class: SBR_3_0_AccountOperations_Test
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Test Class to manage handler logic for Accounts
* - SAL-473,1502
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME                        DATE                DETAIL FEATURES
    1.0         Harry Patel,Viren Patel           2022-04-04               Initial version    
    1.2         Lakshya Khandelwal                2023-06-27               FRONT-3524 : Added updateDriverslicenseTestInsertForInvalidRMState and updateDriverslicenseTestUpdateForInvalidRMState
*********************************************************************************************************************/



@isTest
public with sharing class SBR_3_0_AccountOperations_Test {

    @TestSetup
    static void makeData(){
        
        setUpUsers();

        Credential__c cred = SBR_3_0_TestDataFactory.createCredentials(1, false)[0];
        cred.Name = 'Mule_Token_Endpoint';
        cred.Key_Id__c = 'keyid';
        cred.Secret__c ='credSecret';
        insert cred;
        
        Schema.Location loc = new Schema.Location();
        loc.recordTypeId = SBR_3_0_Constants.LOCATION_BRANCH_RT_ID;
        loc.Name = '1799 Innovation Point';
        loc.Street_Address__c = '1799 Innovation Point';
        loc.State__c = 'SC';
        loc.Zip_Code__c = '29715';
        loc.Branch_Location_Number__c = '0411';
        insert loc;

        User_Location__c ul = new User_Location__c(User__c = UserInfo.getUserId(), Branch__c = loc.Id);
        insert ul;
        
        // List<Account> testAccounts = SBR_3_0_TestDataFactory.createAccounts(1, false, SBR_3_0_Constants.ACCOUNT_REC_TYPE_PROSPECT);
        // Account acc = testAccounts[0];
        // acc.Name = 'OSR Test Account';
        // upsert acc;
                        
        // List<Account_Relationship__c> testARs = SBR_3_0_TestDataFactory.createAccountRelationships(1, acc.Id, true);
                        
    }

    @isTest static void publishProspectAccountTest(){
        List<Account> acc =SBR_3_0_TestDataFactory.createAccounts(1, True, 'Prospect');
        Id ide;
        System.debug(ide);
            for (Account sob:acc){
                sob.put('Sales_Activity_Status__c','Pending Non-Credit Conversion');
                ide=sob.Id;
            }
                        
            // System.debug(ide);
            Update acc;
                        
        createOutBox(ide, 'Prospect');

        List<Outbox__c> out =  [Select Record_Id__c, Record_Type_Name__c from Outbox__c where Record_Id__c=:ide];
        String ric=out[0].Record_Id__c;
       // Id newide= out.Id;
        System.assertEquals(ide,ric);
    }


    /*@isTest static void updateAccToNonCreditTest(){
        try{
        List<Account> acc =SBR_3_0_TestDataFactory.createAccounts(1, True, 'Non_Credit');
        Id ide;
        System.debug(ide);
        for (Account sob:acc){
            sob.put('RM_Account_Number__c','112312312312');
            ide=sob.Id;
        }

        System.debug(ide);
        Update acc;
        
        createOutBox(ide, 'Non-Credit');

        Outbox__c out =  [Select Record_Id__c, Record_Type_Name__c from Outbox__c where Record_Type_Name__c='Non-Credit' order by Created_Date_GMT__c desc LIMIT 1];
        String ric=out.Record_Type_Name__c;
        System.debug(ric);
       // Id newide= out.Id;
        System.assertEquals('Non-Credit',ric);
       }
        catch(Exception e){
            system.debug('Execption:'+e);
        }
    }*/

    @isTest static void updateAccToCreditTest(){
        List<Account> acc =SBR_3_0_TestDataFactory.createAccounts(1, True, 'Prospect');
        
        // Create Contact
        Contact contact = SBR_3_0_TestDataFactory.createContacts(1, acc[0].Id, true)[0];
        // Create Order
        Pricebook2 priceBook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true,
            Name = 'Standard Price Book'
        );
        update priceBook;
        Id orderRecTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('Reservation Order').getRecordTypeId();
        Order order = SBR_3_0_TestDataFactory.createOrder(true, 'Test Order', orderRecTypeId);
        order.AccountId = acc[0].Id;
        order.Jobsite__c = null;
        update order;
        // Create Quote
        SBQQ__Quote__c quote = new SBQQ__Quote__c(
            Quote_Name__c = 'Test Quote',
            SBQQ__Account__c = acc[0].Id,
            SBQQ__DeliveryMethod__c = 'Delivery',
            Start_Date__c = datetime.now().addMonths(1),
            End_Date__c = datetime.now().addMonths(2),
            Delivery_Date__c = datetime.now().addMonths(3),
            Opt_Out_RPP__c = false,
            Opt_Out_Fuel_Charge__c = false,
            Selling_Channel__c = 'SBRB2B',
            Duration__c = 'Week'        
        );
        insert quote;
         
        RecordType rt = [SELECT Id, DeveloperName, IsActive, Name, SobjectType FROM RecordType
                    WHERE IsActive = true AND SobjectType =: SBR_3_0_Constants.ACCOUNT_API_NAME AND DeveloperName =: 'Credit'];
        Id ide;
        System.debug(ide);
        Test.startTest();
        for (Account sob:acc){
            sob.put('RM_Account_Number__c','112312312312');
            sob.RecordTypeId = rt.Id;
            ide=sob.Id;
        }

        System.debug(ide);
        Update acc;
        Test.stopTest();
        
        createOutBox(ide, 'Credit');

        Outbox__c out =  [Select Record_Id__c, Record_Type_Name__c from Outbox__c where Record_Type_Name__c='Credit' order by Created_Date_GMT__c desc LIMIT 1];
        String ric=out.Record_Type_Name__c;
        System.debug(ric);
       // Id newide= out.Id;
        System.assertEquals('Credit',ric);
    }

    @isTest static void updateSourceOfUpdateTest(){
        Profile p = [SELECT Id FROM Profile WHERE Name='Sales'];
        //create OSR user who will be related to the account
        String osrUserOneName = 'osrUserOne' + DateTime.now().getTime() + '@airrexusa.com';
        User osrUserOne = new User(Alias = 'osrOne', Email='ersuser1@airrexusa.com',RepId__c='1092346000000001',
        EmailEncodingKey='UTF-8', LastName='osrOne', LanguageLocaleKey='en_US',
        LocaleSidKey='en_US', ProfileId = p.Id,
        TimeZoneSidKey='America/Los_Angeles',
        UserName=osrUserOneName);
        insert osrUserOne;
        PermissionSetLicense license = [SELECT ID, Developername FROM PermissionSetLicense WHERE DeveloperName = 'SalesforceCPQ_CPQStandardPerm'];
        PermissionSetLicenseAssign psl = new PermissionSetLicenseAssign(AssigneeId = osrUserOne.Id, PermissionSetLicenseId = license.Id);
        insert psl;
        PermissionSet ps = [SELECT Id 
                    FROM PermissionSet 
                    WHERE Name = 'OSR_Outside_Sales_Rep'];
        insert new PermissionSetAssignment(AssigneeId = osrUserOne.id, PermissionSetId = ps.Id);

        System.runAs(osrUserOne){
            List<Account> acc =SBR_3_0_TestDataFactory.createAccounts(1, True, 'Prospect');
            Id ide;
            for (Account sob:acc){
                ide=sob.Id;
            }
            
            Account out =  [Select Id,Source_Of_Update__c from Account where Id=:ide];
            System.debug('out'+out.Source_Of_Update__c);
            out.Source_Of_Update__c='SF';
            update out;
            String sou = out.Source_Of_Update__c;
        // Id newide= out.Id;
            System.assertEquals('SF',sou);
        }
    }

    @isTest static void fetchLatLongSuccessTest(){
        List<Account> acc =SBR_3_0_TestDataFactory.createAccounts(1, True, 'Credit');
        Id ide;
        for (Account sob:acc){
            ide=sob.Id;
        }

        Account act =  [SELECT ID, ShippingStreet, Shipping_Street2__c, ShippingCity, ShippingState, ShippingPostalCode,Street_Address_LatLong_Status__c, Street_Address_LatLong__c, Street_Address_LatLong__Latitude__s, Street_Address_LatLong__Longitude__s, 
        BillingLatitude, BillingLongitude, BillingStreet, Billing_Street2__c, BillingCity, BillingPostalCode, BillingCountry, 
        BillingState, Override_Address_LatLong_Status__c, Override_Address__Street__s, Override_Address__City__s, Override_Address__StateCode__s, Override_Address__PostalCode__s, Override_Address__CountryCode__s, Override_Address__Latitude__s, Override_Address__Longitude__s FROM Account Where Id =: ide];
        act.ShippingStreet = '6300 singleplex Drive';
        act.ShippingCity = 'Centreville';
        act.ShippingState = 'VA';
        act.ShippingPostalCode = '20121';
        act.ShippingCountry = 'US';
        act.Override_Address__Street__s = '7000 Doubleplex Drive';
        act.Override_Address__City__s = 'Centreville';
        act.Override_Address__StateCode__s = 'VA';
        act.Override_Address__PostalCode__s = '20120';
        act.Override_Address__CountryCode__s = 'US';
        update act;

        Account oldAct = act.clone(true);
        oldAct.ShippingStreet = 'Test Street';
        oldAct.Override_Address__Street__s = 'Test Street';

        Map<Id, Account> newAccountMap = new Map<Id, Account>();
        newAccountMap.put(act.Id, act);
        Map<Id, Account> oldAccountMap = new Map<Id, Account>();
        oldAccountMap.put(act.Id, oldAct);
        
        Set<Id> changedStreetAddress = new Set<Id>();
        changedStreetAddress.add(act.Id);
        Set<Id> changedOverrideAddress = new Set<Id>();
        changedOverrideAddress.add(act.Id);
        Set<Id> changedBillingAddress = new Set<Id>();
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SuccessMockHttpResponseGenerator());
        SBR_3_0_AccountOperations.fetchAddressLatLong(oldAccountMap, newAccountMap);

        SBR_3_0_BatchAccountLatLongProcessor latLongBtch = new SBR_3_0_BatchAccountLatLongProcessor(changedStreetAddress, changedOverrideAddress, changedBillingAddress, newAccountMap.values());
        Database.executeBatch(latLongBtch, 1);
        Test.stopTest();

        Account act2 = [SELECT ID, Street_Address_LatLong_Status__c, Override_Address_LatLong_Status__c FROM Account Where Id =: ide];
        system.assertEquals('Success', act2.Street_Address_LatLong_Status__c, 'Street Address Lat Long Status is not set to Success');
        system.assertEquals('Success', act2.Override_Address_LatLong_Status__c, 'Override Address Lat Long Status is not set to Success');
    }

    @isTest static void fetchLatLongSuccessTestEmptyOldMap(){
        List<Account> acc =SBR_3_0_TestDataFactory.createAccounts(1, True, 'Credit');
        Id ide;
        for (Account sob:acc){
            ide=sob.Id;
        }

        Account act =  [SELECT ID, BillingLatitude, BillingLongitude, BillingStreet, Billing_Street2__c, BillingCity, BillingPostalCode, BillingCountry, 
        BillingState, ShippingStreet, Shipping_Street2__c, ShippingCity, ShippingState, ShippingPostalCode,
        Street_Address_LatLong_Status__c, Street_Address_LatLong__c, Street_Address_LatLong__Latitude__s,
         Street_Address_LatLong__Longitude__s, Override_Address_LatLong_Status__c, Override_Address__Street__s, 
         Override_Address__City__s, Override_Address__StateCode__s, Override_Address__PostalCode__s, Override_Address__CountryCode__s, 
         Override_Address__Latitude__s, Override_Address__Longitude__s FROM Account Where Id =: ide];
        act.ShippingStreet = '6300 singleplex Drive';
        act.ShippingCity = 'Centreville';
        act.ShippingState = 'VA';
        act.ShippingPostalCode = '20121';
        act.ShippingCountry = 'US';
        act.Override_Address__Street__s = '7000 Doubleplex Drive';
        act.Override_Address__City__s = 'Centreville';
        act.Override_Address__StateCode__s = 'VA';
        act.Override_Address__PostalCode__s = '20120';
        act.Override_Address__CountryCode__s = 'US';
        update act;

        Map<Id, Account> newAccountMap = new Map<Id, Account>();
        newAccountMap.put(act.Id, act);
        Map<Id, Account> oldAccountMap = new Map<Id, Account>();
        
        Set<Id> changedStreetAddress = new Set<Id>();
        changedStreetAddress.add(act.Id);
        Set<Id> changedOverrideAddress = new Set<Id>();
        changedOverrideAddress.add(act.Id);
        Set<Id> changedBillingAddress = new Set<Id>();
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SuccessMockHttpResponseGenerator());
        SBR_3_0_AccountOperations.fetchAddressLatLong(oldAccountMap, newAccountMap);

        SBR_3_0_BatchAccountLatLongProcessor latLongBtch = new SBR_3_0_BatchAccountLatLongProcessor(changedStreetAddress, changedOverrideAddress, changedBillingAddress, newAccountMap.values());
        Database.executeBatch(latLongBtch, 1);
        Test.stopTest();

        Account act2 = [SELECT ID, Street_Address_LatLong_Status__c, Override_Address_LatLong_Status__c FROM Account Where Id =: ide];
        system.assertEquals('Success', act2.Street_Address_LatLong_Status__c, 'Street Address Lat Long Status is not set to Success');
        system.assertEquals('Success', act2.Override_Address_LatLong_Status__c, 'Override Address Lat Long Status is not set to Success');
    }

    @isTest static void fetchLatLongErrorTest(){
        List<Account> acc =SBR_3_0_TestDataFactory.createAccounts(1, True, 'Credit');
        Id ide;
        for (Account sob:acc){
            ide=sob.Id;
        }

        Account act =  [SELECT ID, ShippingStreet, Shipping_Street2__c, ShippingCity, ShippingState, ShippingPostalCode,Street_Address_LatLong_Status__c, Street_Address_LatLong__c, Street_Address_LatLong__Latitude__s, Street_Address_LatLong__Longitude__s,
        BillingLatitude, BillingLongitude, BillingStreet, Billing_Street2__c, BillingCity, BillingPostalCode, BillingCountry, 
        BillingState,  Override_Address_LatLong_Status__c, Override_Address__Street__s, Override_Address__City__s, Override_Address__StateCode__s, Override_Address__PostalCode__s, Override_Address__CountryCode__s, Override_Address__Latitude__s, Override_Address__Longitude__s FROM Account Where Id =: ide];
        act.ShippingStreet = '100 Mainsecond Street';
        act.ShippingCity = 'test';
        act.ShippingState = 'VA';
        act.ShippingPostalCode = '10222';
        act.ShippingCountry = 'US';
        act.Override_Address__Street__s = '300 Submain Street';
        act.Override_Address__City__s = 'Overton';
        act.Override_Address__StateCode__s = 'VA';
        act.Override_Address__PostalCode__s = '20173';
        act.Override_Address__CountryCode__s = 'US';
        update act;

        Account oldAct = act.clone(true);
        oldAct.ShippingStreet = 'Test Street Changed';
        oldAct.Override_Address__Street__s = 'Test Street Changed';

        Map<Id, Account> newAccountMap = new Map<Id, Account>();
        newAccountMap.put(act.Id, act);
        Map<Id, Account> oldAccountMap = new Map<Id, Account>();
        oldAccountMap.put(act.Id, oldAct);
        
        Set<Id> changedStreetAddress = new Set<Id>();
        changedStreetAddress.add(act.Id);
        Set<Id> changedOverrideAddress = new Set<Id>();
        changedOverrideAddress.add(act.Id);
        Set<Id> changedBillingAddress = new Set<Id>();
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_FetchLatLong_MockFailed());
        SBR_3_0_AccountOperations.fetchAddressLatLong(oldAccountMap, newAccountMap);

        SBR_3_0_BatchAccountLatLongProcessor latLongBtch = new SBR_3_0_BatchAccountLatLongProcessor(changedStreetAddress, changedOverrideAddress, changedBillingAddress, newAccountMap.values());
        Database.executeBatch(latLongBtch, 1);
        Test.stopTest();

        Account act2 = [SELECT ID, Street_Address_LatLong_Status__c, Override_Address_LatLong_Status__c FROM Account Where Id =: ide];
        system.assertEquals('Error', act2.Street_Address_LatLong_Status__c, 'Street Address Lat Long Status is not set to Error');
        system.assertEquals('Error', act2.Override_Address_LatLong_Status__c, 'Override Address Lat Long Status is not set to Error');
    }
    
    @isTest static void getAccountTerritoryProspectTest(){

        List<Account> acc=SBR_3_0_TestDataFactory.createAccounts(1,true,'Prospect');
        Id ide;
        for (Account acco: acc){
            ide=acco.Id;
        }
        System.debug('RecordType ID '+acc[0].RecordTypeId);
        Account oldAct =  [SELECT ID,RecordTypeId, ShippingStreet, Shipping_Street2__c, ShippingCity, ShippingState, ShippingPostalCode,Street_Address_LatLong_Status__c, Street_Address_LatLong__c, Street_Address_LatLong__Latitude__s, Street_Address_LatLong__Longitude__s, Override_Address_LatLong_Status__c, Override_Address__Street__s, Override_Address__City__s, Override_Address__StateCode__s, Override_Address__PostalCode__s, Override_Address__CountryCode__s, Override_Address__Latitude__s, Override_Address__Longitude__s FROM Account Where Id =: ide ];


        Account newAct = oldAct.clone(true);

        newAct.Street_Address_LatLong__Latitude__s = 37.790291;
        newAct.Street_Address_LatLong__Longitude__s = -122.3972452;

        List<Account> newAccountMap = new List<Account>();
        newAccountMap.add(newAct);
        List<Account> oldAccountMap = new List<Account>();
        oldAccountMap.add(oldAct);
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_FetchTerritory_MockSuccess());
        SBR_3_0_AccountOperations.fetchterriFuture(oldAccountMap, newAccountMap);
        Test.stopTest();

        // Project_Relationship__c pro1=[Select Id, Project__c from Project_Relationship__c where Project__c =:ide limit 1];
        System.assertEquals(oldAct.Id, ide);
    } 

    @isTest static void getAccountTerritoryOfficeTest(){

        List<Account> acc=SBR_3_0_TestDataFactory.createAccounts(1,true,'Office');
        Id ide;
        for (Account acco: acc){
            ide=acco.Id;
        }
        System.debug('RecordType ID '+acc[0].RecordTypeId);
        Account oldAct =  [SELECT ID,RecordTypeId, ShippingStreet, Shipping_Street2__c, ShippingCity, ShippingState, ShippingPostalCode,Street_Address_LatLong_Status__c, Street_Address_LatLong__c, Street_Address_LatLong__Latitude__s, Street_Address_LatLong__Longitude__s, Override_Address_LatLong_Status__c, Override_Address__Street__s, Override_Address__City__s, Override_Address__StateCode__s, Override_Address__PostalCode__s, Override_Address__CountryCode__s, Override_Address__Latitude__s, Override_Address__Longitude__s FROM Account Where Id =: ide ];


        Account newAct = oldAct.clone(true);

        newAct.Street_Address_LatLong__Latitude__s = 37.790291;
        newAct.Street_Address_LatLong__Longitude__s = -122.3972452;

        List<Account> newAccountMap = new List<Account>();
        newAccountMap.add(newAct);
        List<Account> oldAccountMap = new List<Account>();
        oldAccountMap.add(oldAct);
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_FetchTerritory_MockSuccess());
        SBR_3_0_AccountOperations.fetchterriFuture(oldAccountMap, newAccountMap);
        Test.stopTest();

        // Project_Relationship__c pro1=[Select Id, Project__c from Project_Relationship__c where Project__c =:ide limit 1];
        System.assertEquals(oldAct.Id, ide);
    } 

    @isTest static void linkSalesRepIdsTest(){

        User osrOne = [Select Id,RepId__c,name FROM User WHERE LastName = 'osrOne' Limit 1];
        List<Account> testAccounts = SBR_3_0_TestDataFactory.createAccounts(1, false, SBR_3_0_Constants.ACCOUNT_REC_TYPE_PROSPECT);
        Account acc = testAccounts[0];    
                
        System.runAs(osrOne) {
            acc.RM_Account_Number__c='987654';
            acc.RepId__c=null;
            acc.Sales_Rep_Id__c = '1092345';
            insert acc;
            Test.startTest();
            SBR_3_0_AccountOperations.linkSalesRepIds(new List<Account> {acc});
            Test.stopTest();
            Account testAC = [Select Id,RepID__c From Account Where Sales_Rep_Id__c='1092345' Limit 1];
            System.assertEquals(acc.RepID__c, osrOne.Id);
        }    
    } 


    @isTest static void testPreventOSRUpdateOfReadinessFieldSuccess(){

    }

    @isTest static void testPreventOSRUpdateOfReadinessFieldFailure(){
        List<Account> testAccounts = SBR_3_0_TestDataFactory.createAccounts(1, false, SBR_3_0_Constants.ACCOUNT_REC_TYPE_PROSPECT);
        Account acc = testAccounts[0];
        acc.Name = 'OSR Test Account';
        upsert acc;
                        
        List<Account_Relationship__c> testARs = SBR_3_0_TestDataFactory.createAccountRelationships(1, acc.Id, true);
        User osrTwo = [SELECT Id FROM User WHERE LastName = 'osrTwo'];
        User osrOne = [Select Id FROM User WHERE LastName = 'osrOne'];
        Account testAccount = [SELECT Id, Plant_Ready_Required__c, OwnerId FROM ACCOUNT WHERE Name = 'OSR Test Account'];
        testAccount.OwnerId = osrTwo.Id;
        update testAccount;
        Account_Relationship__c ar = [SELECT Id, User_Account__c FROM Account_Relationship__c WHERE Account_ID__c =: testAccount.Id];
        ar.User_Account__c = osrOne.Id;
        update ar;

        System.debug('Account relationship: ' + ar);
        System.runAs(osrTwo) {
            try{
                testAccount.Drip_Diapers__c = true;
                Database.SaveResult sr = Database.update(testAccount);
                //Force the test to fail if update is successful
                System.assert(!sr.isSuccess(), 'Account updated successfully');
            } catch(DmlException e){
                system.debug('Error message: ' + e.getMessage());
                system.assert(e.getMessage().contains('User is not permitted to update Job Site Requirements Fields on this Account'), 'User is not permitted to update Job Site Requirements Fields on this Account');
            }
        }

        System.runAs(osrOne) {
            try{
                testAccount.Drip_Diapers__c = true;
                Database.SaveResult sr = Database.update(testAccount);
                System.assert(sr.isSuccess(), 'Account could not be updated');
            } catch(DmlException e){
                system.debug('Error message: ' + e.getMessage());
            }
        }
    }
    static void createOutBox(Id recordId, String recordTypeName){
        Outbox__c newOutbox = new Outbox__c(Record_Id__c        = recordId,
                                            Record_Type_Name__c = recordTypeName
                                           );
        insert newOutbox;
    }
    @future 
    static void setUpUsers(){
        List<User> userList = new List<User>();

        List<PermissionSetAssignment> psaList = new List<PermissionSetAssignment>();
        
        Profile p = [SELECT Id FROM Profile WHERE Name='Sales'];
        //create OSR user who will be related to the account
        String osrUserOneName = 'osrUserOne' + DateTime.now().getTime() + '@airrexusa.com';
        User osrUserOne = new User(Alias = 'osrOne', Email='ersuser1@airrexusa.com',RepId__c='1092345',
        EmailEncodingKey='UTF-8', LastName='osrOne', LanguageLocaleKey='en_US',
        LocaleSidKey='en_US', ProfileId = p.Id,
        TimeZoneSidKey='America/Los_Angeles',
        UserName=osrUserOneName);
        userList.add(osrUserOne);
        
        //create OSR user who will not be related to the account
        String osrUserTwoName = 'osrUserTwo' + DateTime.now().getTime() + '@airrexusa.com';
        User osrUserTwo = new User(Alias = 'osrTwo', Email='ersuser2@airrexusa.com',
        EmailEncodingKey='UTF-8', LastName='osrTwo', LanguageLocaleKey='en_US',
        LocaleSidKey='en_US', ProfileId = p.Id,
        TimeZoneSidKey='America/Los_Angeles',
        UserName=osrUserTwoName);
        userList.add(osrUserTwo);
        
        insert userList;
        
        PermissionSet osr = [SELECT Id FROM PermissionSet WHERE Name = 'OSR_Outside_Sales_Rep'];
        PermissionSetLicense psl = [SELECT Id FROM PermissionSetLicense WHERE DeveloperName = 'SalesforceCPQ_CPQStandardPerm'];
        
        PermissionSetAssignment osrOnePSA = new PermissionSetAssignment(
        PermissionSetId = osr.Id,
        AssigneeId = osrUserOne.Id);
        psaList.add(osrOnePSA);
        PermissionSetAssignment osrTwoPSA = new PermissionSetAssignment(
            PermissionSetId = osr.Id,
            AssigneeId = osrUserTwo.Id);
            psaList.add(osrTwoPSA);
                
        insert new PermissionSetLicenseAssign(
            AssigneeId = osrUserOne.Id,
            PermissionSetLicenseId = psl.Id);
                    
        insert new PermissionSetLicenseAssign(
            AssigneeId = osrUserTwo.Id,
            PermissionSetLicenseId = psl.Id);
                        
        insert psaList;
    }

    @isTest
    static void testValidateStateCountry(){
        // Create Integration User
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        String intUserName = 'IntegrationUser' + DateTime.now().getTime() + '@airrexusa.com';
        User intUser = new User(Alias = 'IntUser', Email='ersuser1@airrexusa.com',
        EmailEncodingKey='UTF-8', LastName='User', LanguageLocaleKey='en_US',
        LocaleSidKey='en_US', ProfileId = p.Id,
        TimeZoneSidKey='America/Los_Angeles',
        UserName=intUserName);
        insert intUser;

        PermissionSet intPerm = [SELECT Id FROM PermissionSet WHERE Name = 'Integration_API_Access'];
        PermissionSetLicense psl = [SELECT Id FROM PermissionSetLicense WHERE DeveloperName = 'SalesforceCPQ_CPQStandardPerm'];
        insert new PermissionSetLicenseAssign(
            AssigneeId = intUser.Id,
            PermissionSetLicenseId = psl.Id);
        PermissionSetAssignment intUserPSA = new PermissionSetAssignment(
        PermissionSetId = intPerm.Id,
        AssigneeId = intUser.Id);
        insert intUserPSA;
        // Run as Integration User
        System.runAs(intUser) {
            // Create Account
            List<Account> testAccounts = SBR_3_0_TestDataFactory.createAccounts(1, false, SBR_3_0_Constants.ACCOUNT_REC_TYPE_CREDIT);
            Account acc = testAccounts[0]; 
            acc.BillingCountry = '';
            acc.ShippingCountry = '';
            acc.BillingState = '';
            acc.ShippingState = '';
            acc.RM_Country__c = 'CA';
            acc.RM_State__c = 'ON';
            Test.startTest();
            insert acc;
            // Validate Correct State Country on Insert
            Account updatedAcc = [SELECT ID, RM_Country__c, RM_State__c, BillingState, BillingCountry FROM Account WHERE ID =: acc.Id];
            system.assertEquals(updatedAcc.BillingCountry,'CA', 'Billing Country did not change');
            system.assertEquals(updatedAcc.BillingState, 'ON', 'Billing State did not change');
            // Validate Correct State Country on Update
            updatedAcc.RM_Country__c = 'US';
            updatedAcc.RM_State__c = 'NY';
            update updatedAcc;
            updatedAcc = [SELECT ID, RM_Country__c, RM_State__c, BillingState, BillingCountry FROM Account WHERE ID =: acc.Id];
            system.assertEquals(updatedAcc.BillingCountry,'US', 'Billing Country did not change');
            system.assertEquals(updatedAcc.BillingState, 'NY', 'Billing State did not change');
            // Validate Invalid Country on Update
            updatedAcc.RM_Country__c = 'TR';
            updatedAcc.RM_State__c = 'NY';
            update updatedAcc;
            updatedAcc = [SELECT ID, RM_Country__c, RM_State__c, BillingState, BillingCountry FROM Account WHERE ID =: acc.Id];
            system.assertEquals(updatedAcc.BillingCountry,null, 'Billing Country did not change');
            system.assertEquals(updatedAcc.BillingState, null, 'Billing State did not change');
            // Validate Invalid State on Update
            updatedAcc.RM_Country__c = 'US';
            updatedAcc.RM_State__c = 'ZZ';
            update updatedAcc;
            updatedAcc = [SELECT ID, RM_Country__c, RM_State__c, BillingState, BillingCountry FROM Account WHERE ID =: acc.Id];
            system.assertEquals(updatedAcc.BillingCountry,null, 'Billing Country did not change');
            system.assertEquals(updatedAcc.BillingState, null, 'Billing State did not change');
            // Validate Invalid Country on Insert
            testAccounts = SBR_3_0_TestDataFactory.createAccounts(1, false, SBR_3_0_Constants.ACCOUNT_REC_TYPE_CREDIT);
            Account acc2 = testAccounts[0]; 
            acc2.BillingCountry = '';
            acc2.ShippingCountry = '';
            acc2.BillingState = '';
            acc2.ShippingState = '';
            acc2.RM_Country__c = 'ZZ';
            acc2.RM_State__c = 'ON';
            Insert acc2;
            Account insAcct = [SELECT ID, RM_Country__c, RM_State__c, BillingState, BillingCountry FROM Account WHERE ID =: acc2.Id];
            system.assertEquals(insAcct.BillingCountry,null, 'Billing Country did not change');
            system.assertEquals(insAcct.BillingState, null, 'Billing State did not change');
            // Validate Invalid State on Insert
            testAccounts = SBR_3_0_TestDataFactory.createAccounts(1, false, SBR_3_0_Constants.ACCOUNT_REC_TYPE_CREDIT);
            Account acc3 = testAccounts[0]; 
            acc3.BillingCountry = '';
            acc3.ShippingCountry = '';
            acc3.BillingState = '';
            acc3.ShippingState = '';
            acc3.RM_Country__c = 'CA';
            acc3.RM_State__c = 'ZZ';
            Insert acc3;
            insAcct = [SELECT ID, RM_Country__c, RM_State__c, BillingState, BillingCountry FROM Account WHERE ID =: acc3.Id];
            system.assertEquals(insAcct.BillingCountry,null, 'Billing Country did not change');
            system.assertEquals(insAcct.BillingState, null, 'Billing State did not change');
            // Validate Null State and Country on Insert
            testAccounts = SBR_3_0_TestDataFactory.createAccounts(1, false, SBR_3_0_Constants.ACCOUNT_REC_TYPE_CREDIT);
            Account acc4 = testAccounts[0]; 
            acc4.BillingCountry = '';
            acc4.ShippingCountry = '';
            acc4.BillingState = '';
            acc4.ShippingState = '';
            acc4.RM_Country__c = null;
            acc4.RM_State__c = null;
            Insert acc4;
            insAcct = [SELECT ID, RM_Country__c, RM_State__c, BillingState, BillingCountry FROM Account WHERE ID =: acc4.Id];
            system.assertEquals(insAcct.BillingCountry,null, 'Billing Country did not change');
            system.assertEquals(insAcct.BillingState, null, 'Billing State did not change');
            Test.stopTest();
        }
    }

    @isTest static void testValidateInboundAccount(){
        // Create Integration User
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        String intUserName = 'IntegrationUser' + DateTime.now().getTime() + '@airrexusa.com';
        User intUser = new User(Alias = 'IntUser', Email='ersuser@airrexusa.com',
        EmailEncodingKey='UTF-8', LastName='User', LanguageLocaleKey='en_US',
        LocaleSidKey='en_US', ProfileId = p.Id,
        TimeZoneSidKey='America/Los_Angeles',
        UserName=intUserName);
        insert intUser;

        PermissionSet intPerm = [SELECT Id FROM PermissionSet WHERE Name = 'Integration_API_Access'];
        PermissionSetLicense psl = [SELECT Id FROM PermissionSetLicense WHERE DeveloperName = 'SalesforceCPQ_CPQStandardPerm'];
        insert new PermissionSetLicenseAssign(
            AssigneeId = intUser.Id,
            PermissionSetLicenseId = psl.Id);
        PermissionSetAssignment intUserPSA = new PermissionSetAssignment(
        PermissionSetId = intPerm.Id,
        AssigneeId = intUser.Id);
        insert intUserPSA;
        // Run as Integration User
        System.runAs(intUser) {
            Test.startTest();
            // Create Account
            List<Account> testAccounts = SBR_3_0_TestDataFactory.createAccounts(1, false, SBR_3_0_Constants.ACCOUNT_REC_TYPE_CREDIT);
            Account acc = testAccounts[0]; 
            acc.Billing_Street2__c = 'Test Street';
            insert acc;
            // Validate Insert
            Account insAcct = [SELECT ID, Billing_Street1__c, BillingStreet FROM Account WHERE Id =: acc.Id];
            System.assertEquals(insAcct.BillingStreet, 'Test Street', 'Billing_Street2__c is not copied to BillingStreet');
            // Validate Update
            insAcct.Billing_Street1__c = 'Test Street2';
            update insAcct;
            insAcct = [SELECT ID, Billing_Street1__c, BillingStreet FROM Account WHERE Id =: acc.Id];
            System.assertEquals(insAcct.BillingStreet, 'Test Street2 Test Street', 'Billing_Street2__c is not copied to BillingStreet');
            Test.stopTest();
        }
    }

    @isTest static void updateDriverslicenseTest(){

        // Create Integration User
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        String intUserName = 'IntegrationUser' + DateTime.now().getTime() + '@airrexusa.com';
        User intUser = new User(Alias = 'IntUser', Email='ersuser1@airrexusa.com',
        EmailEncodingKey='UTF-8', LastName='User', LanguageLocaleKey='en_US',
        LocaleSidKey='en_US', ProfileId = p.Id,
        TimeZoneSidKey='America/Los_Angeles',
        UserName=intUserName);
        insert intUser;

        PermissionSet intPerm = [SELECT Id FROM PermissionSet WHERE Name = 'Integration_API_Access'];
        PermissionSetLicense psl = [SELECT Id FROM PermissionSetLicense WHERE DeveloperName = 'SalesforceCPQ_CPQStandardPerm'];
        insert new PermissionSetLicenseAssign(
            AssigneeId = intUser.Id,
            PermissionSetLicenseId = psl.Id);
        PermissionSetAssignment intUserPSA = new PermissionSetAssignment(
        PermissionSetId = intPerm.Id,
        AssigneeId = intUser.Id);
        insert intUserPSA;

        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_FetchLatLong_MockSuccess());

        System.runAs(intUser) {
            List<Account> acc =SBR_3_0_TestDataFactory.createAccounts(1, false, 'Non_Credit');
            Account accVar = acc[0]; 
            accVar.Name = accVar.Name + ', Test';
            accVar.RM_Country__c = 'CA';
            accVar.RM_State__c = 'ON';
            accVar.Billing_Street1__c = 'TestStreet';
            accVar.Company_Code__c = '01';
            insert accVar;
            
            Id ide;
            Account acctRecd = [SELECT ID,Drivers_License__c,Driver_s_License_State__c FROM Account WHERE Id =: acc[0].Id];
            acctRecd.Drivers_License__c='7650009990';
            update acctRecd;
            Assert.areEqual(acctRecd.Drivers_License__c, '7650009990');
            Assert.areEqual(acctRecd.Driver_s_License_State__c, 'GA');
    
            for (Account sob:acc){
                sob.put('RM_Account_Number__c','112312312312');
                sob.put('RM_Cash_State__c','SC');
                sob.put('RM_Cash_Number__c','7650009991');
                ide=sob.Id;
            }
    
            System.debug(ide);
            Update acc;
            
            createOutBox(ide, 'Non-Credit');
    
            Outbox__c out =  [Select Record_Id__c, Record_Type_Name__c from Outbox__c where Record_Type_Name__c='Non-Credit' order by Created_Date_GMT__c desc LIMIT 1];
            String ric=out.Record_Type_Name__c;
            
            System.debug(ric);
           // Id newide= out.Id;
            System.assertEquals('Non-Credit',ric);
    
            Account acctRec = [SELECT ID,Drivers_License__c,Driver_s_License_State__c FROM Account WHERE Id =: acc[0].Id];
            Assert.areEqual(acctRec.Drivers_License__c, '7650009991');
            Assert.areEqual(acctRec.Driver_s_License_State__c, 'SC');
        }
        
    }

    //Added for FRONT-3524
    @isTest static void updateDriverslicenseTestInsertForInvalidRMState(){

        // Create Integration User
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        String intUserName = 'IntegrationUser' + DateTime.now().getTime() + '@SBRtestorg.com';
        User intUser = new User(Alias = 'IntUser', Email='ersuser1@airrexusa.com',
        EmailEncodingKey='UTF-8', LastName='User', LanguageLocaleKey='en_US',
        LocaleSidKey='en_US', ProfileId = p.Id,
        TimeZoneSidKey='America/Los_Angeles',
        UserName=intUserName);
        insert intUser;

        PermissionSet intPerm = [SELECT Id FROM PermissionSet WHERE Name = 'Integration_API_Access'];
        PermissionSetLicense psl = [SELECT Id FROM PermissionSetLicense WHERE DeveloperName = 'SalesforceCPQ_CPQStandardPerm'];
        insert new PermissionSetLicenseAssign(
            AssigneeId = intUser.Id,
            PermissionSetLicenseId = psl.Id);
        PermissionSetAssignment intUserPSA = new PermissionSetAssignment(
        PermissionSetId = intPerm.Id,
        AssigneeId = intUser.Id);
        insert intUserPSA;

        System.runAs(intUser) {
            List<Account> acc =SBR_3_0_TestDataFactory.createAccounts(1, false, 'Non_Credit');
            acc[0].RM_Cash_State__c = 'WG';
            acc[0].Company_Code__c = '01';
            insert acc;

            Account acctRecd = [SELECT ID,Drivers_License__c,Driver_s_License_State__c FROM Account WHERE Id =: acc[0].Id];
            Assert.areEqual(acctRecd.Drivers_License__c, null);
            Assert.areEqual(acctRecd.Driver_s_License_State__c, null); 
        }
    }

    //Added for FRONT-3524
    @isTest static void updateDriverslicenseTestUpdateForInvalidRMState(){
        // Create Integration User
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        String intUserName = 'IntegrationUser' + DateTime.now().getTime() + '@SBRtestorg.com';
        User intUser = new User(Alias = 'IntUser', Email='ersuser1@airrexusa.com',
        EmailEncodingKey='UTF-8', LastName='User', LanguageLocaleKey='en_US',
        LocaleSidKey='en_US', ProfileId = p.Id,
        TimeZoneSidKey='America/Los_Angeles',
        UserName=intUserName);
        insert intUser;

        PermissionSet intPerm = [SELECT Id FROM PermissionSet WHERE Name = 'Integration_API_Access'];
        PermissionSetLicense psl = [SELECT Id FROM PermissionSetLicense WHERE DeveloperName = 'SalesforceCPQ_CPQStandardPerm'];
        insert new PermissionSetLicenseAssign(
            AssigneeId = intUser.Id,
            PermissionSetLicenseId = psl.Id);
        PermissionSetAssignment intUserPSA = new PermissionSetAssignment(
        PermissionSetId = intPerm.Id,
        AssigneeId = intUser.Id);
        insert intUserPSA;

        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_FetchLatLong_MockSuccess());

        System.runAs(intUser) {
            List<Account> acc =SBR_3_0_TestDataFactory.createAccounts(1, false, 'Non_Credit');
             //Do the above createAccount parameter as false and update the below fields.
            Account accVar = acc[0];
            accVar.Name = accVar.Name + ', Test'; //Added because of Flow SBR_3_0_SyncAccountandContactV19, LastName is needed which is before comma in Name
            accVar.RM_Country__c = 'CA';    // Added because of SBR_3_0_AccountOperations.validateStateCountry method which is setting BillingState as null
            accVar.RM_State__c = 'ON';      // Same as above
            accVar.Billing_Street1__c = 'TestStreet';   // Added because of SBR_3_0_AccountOperations.validateInboundAccount method which is setting BillingStreet as null
            accVar.Company_Code__c = '01';
            insert accVar;
            

            for (Account sob:acc){
                sob.put('RM_Account_Number__c','112312312312');
                sob.put('RM_Cash_State__c','WG');
                sob.put('RM_Cash_Number__c','10101011');
            }
            Update acc;

            Account acctRec = [SELECT ID,Drivers_License__c,Driver_s_License_State__c FROM Account WHERE Id =: acc[0].Id];
            Assert.areEqual(acctRec.Drivers_License__c, '7650009990');
            Assert.areEqual(acctRec.Driver_s_License_State__c, 'GA');
        }
    }
    
    public class SuccessMockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest request) {
            // Create a fake response
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            if(request.getEndpoint().endsWithIgnoreCase('token')){
                response.setBody('{"access_token":"test"}');
            }else{ 
                response.setBody('{"data": {"geoInfo": {"streetAddress": "Arizona Biltmore Estates","city": "Phoenix","province": "Arizona","country": "United States","latitude": 33.5160515,"longitude": -112.0222999},"timezone": {"id": "America/Phoenix","name": "Mountain Standard Time","dstOffset": 0,"rawOffset": -25200,"rmOffsetForStandardTime": -20,"rmOffsetForDaylightSavingTime": -30}}}');
            }
            response.setStatusCode(200);
            return response; 
        }
    }
}