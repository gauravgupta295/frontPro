/*
Test Class for PPA_UpdatePriceListAssistantBatch apex class
PPA Phase 2: DP-1025
*/
@isTest
public with sharing class PPA_UpdatePriceListAssistantBatch_Test {
    @testSetup
    static void setUp() {
        //Create new users
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator' LIMIT 1];
        List<User> usrList = new List<User>();
        User mgrUsr = new User();
        //Manager
        mgrUsr.FirstName = 'Manager';
        mgrUsr.LastName = 'User';
        mgrUsr.IsActive = true;
        mgrUsr.ProfileId = p.Id;
        mgrUsr.Username = 'mgrusr@testorg.com_' + System.currentTimeMillis();
        mgrUsr.Email='mgrusr@testorg.com';
        mgrUsr.EmployeeNumber = '1000';
        mgrUsr.TimeZoneSidKey = 'America/Los_Angeles';
        mgrUsr.EmailEncodingKey = 'UTF-8';
        mgrUsr.LanguageLocaleKey = 'en_US';
        mgrUsr.LocaleSidKey = 'en_US';
        mgrUsr.Alias = 'PPA';
        System.debug('mgrUsr: ' + mgrUsr);
        usrList.add(mgrUsr);
        //Assistant
        User asstUsr = new User();
        asstUsr.FirstName = 'Assistant';
        asstUsr.LastName = 'User';
        asstUsr.IsActive = true;
        asstUsr.ProfileId = p.Id;
        asstUsr.Username = 'asstusr@testorg.com_' + System.currentTimeMillis();
        asstUsr.Email='asstusr@testorg.com';
        asstUsr.EmployeeNumber = '2000';
        asstUsr.TimeZoneSidKey = 'America/Los_Angeles';
        asstUsr.EmailEncodingKey = 'UTF-8';
        asstUsr.LanguageLocaleKey = 'en_US';
        asstUsr.LocaleSidKey = 'en_US';
        asstUsr.Alias = 'PPA';
        System.debug('asstUsr: ' + asstUsr);
        usrList.add(asstUsr);
        if(!usrList.isEmpty()) {
            insert usrList;
        }
        //Create Price Lists
        List<PPA_Price_List__c> priceLists = new List<PPA_Price_List__c>();
        //User mgrUsr = [SELECT Id, Name FROM User WHERE FirstName = 'Manager' AND LastName = 'User' LIMIT 1];
        PPA_Price_List__c priceList = new PPA_Price_List__c();
        priceList.Name = 'Test Price 1';
        priceList.PPA_ManagerId__c = mgrUsr.Id;
        priceLists.add(priceList);
        PPA_Price_List__c priceList2 = new PPA_Price_List__c();
        priceList2.Name = 'Test Price 2';
        priceList2.PPA_ManagerId__c = mgrUsr.Id;
        priceLists.add(priceList2);
        if(!priceLists.isEmpty()) {
            insert priceLists;
        }
        //Create custom setting
        PPA_Admin_Config__c admConfig = new PPA_Admin_Config__c(PPA_Admin_Group_Email__c='test@test.com');
        insert admConfig;
    }
    @isTest
    static void testBatchWithAsst(){
        User mgrUsr = [SELECT Id, Name FROM User WHERE FirstName = 'Manager' AND LastName = 'User' LIMIT 1];
        User asstUsr = [SELECT Id, Name FROM User WHERE FirstName = 'Assistant' AND LastName = 'User' LIMIT 1];
        Map<Id, Id> mgrAsstMap = new Map<Id, Id>();
        mgrAsstMap.put(mgrUsr.Id, asstUsr.Id);
        String uniqueUserName = 'posstandarduser' + DateTime.now().getTime() + '@SBRtestorg.com';
        // This code runs as the system user
        Profile prf = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User contextuser = new User(Alias = 'standt', Email='standarduser@testorg.com',
                                        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                                        LocaleSidKey='en_US', ProfileId = prf.Id,
                                        TimeZoneSidKey='America/Los_Angeles',
                                        UserName=uniqueUserName
                                    );

        Test.startTest();
        System.runAs(contextuser){
            PPA_UpdatePriceListAssistantBatch.updateFromSeedClassBatch(mgrAsstMap);
        }
        Test.stopTest();
        List<PPA_Price_List__c> priceLists = [SELECT Id, Name FROM PPA_Price_List__c WHERE PPA_AssistantId__c!='' LIMIT 100];
        Assert.isTrue(priceLists.size() == 2);
    }
    @isTest
    static void testBatchWithoutAsst(){
        User mgrUsr = [SELECT Id, Name FROM User WHERE FirstName = 'Manager' AND LastName = 'User' LIMIT 1];
        Map<Id, Id> mgrAsstMap = new Map<Id, Id>();
        mgrAsstMap.put(mgrUsr.Id, null);
        String uniqueUserName = 'posstandarduser' + DateTime.now().getTime() + '@SBRtestorg.com';
        // This code runs as the system user
        Profile prf = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User contextuser = new User(Alias = 'standt', Email='standarduser@testorg.com',
                                        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                                        LocaleSidKey='en_US', ProfileId = prf.Id,
                                        TimeZoneSidKey='America/Los_Angeles',
                                        UserName=uniqueUserName
                                    );

        Test.startTest();
        System.runAs(contextuser){
            PPA_UpdatePriceListAssistantBatch.updateFromSeedClassBatch(mgrAsstMap);
        }
        Test.stopTest();
        List<PPA_Price_List__c> priceLists = [SELECT Id, Name FROM PPA_Price_List__c WHERE PPA_AssistantId__c!='' LIMIT 100];
        Assert.isTrue(priceLists.size() == 0);
    }
    @isTest
    static void testBatchWithMap(){
        Map<Id, Id> mgrAsstMap = new Map<Id, Id>();
        User mgrUsr = [SELECT Id, Name FROM User WHERE FirstName = 'Manager' AND LastName = 'User' LIMIT 1];
        User asstUsr = [SELECT Id, Name FROM User WHERE FirstName = 'Assistant' AND LastName = 'User' LIMIT 1];
        mgrAsstMap.put(mgrUsr.Id, asstUsr.Id);
        String uniqueUserName = 'posstandarduser' + DateTime.now().getTime() + '@SBRtestorg.com';
        // This code runs as the system user
        Profile prf = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User contextuser = new User(Alias = 'standt', Email='standarduser@testorg.com',
                                        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                                        LocaleSidKey='en_US', ProfileId = prf.Id,
                                        TimeZoneSidKey='America/Los_Angeles',
                                        UserName=uniqueUserName
                                    );

        Test.startTest();
        System.runAs(contextuser){
            PPA_UpdatePriceListAssistantBatch.updateFromSeedClassBatch(mgrAsstMap);
        }
        Test.stopTest();
        List<PPA_Price_List__c> priceLists = [SELECT Id, Name FROM PPA_Price_List__c WHERE PPA_AssistantId__c!='' LIMIT 100];
        Assert.isTrue(priceLists.size() == 2);
    }
    @isTest
    static void testBatchWithFlow(){
        List<PPA_UpdatePriceListAssistantBatch.FlowInputs> flInpList = new List<PPA_UpdatePriceListAssistantBatch.FlowInputs>();
        User mgrUsr = [SELECT Id, Name FROM User WHERE FirstName = 'Manager' AND LastName = 'User' LIMIT 1];
        User asstUsr = [SELECT Id, Name FROM User WHERE FirstName = 'Assistant' AND LastName = 'User' LIMIT 1];
        PPA_UpdatePriceListAssistantBatch.FlowInputs flInp = new PPA_UpdatePriceListAssistantBatch.FlowInputs(); 
        flInp.mgrIdFromFlow = mgrUsr.Id;
        flInp.asstIdFromFlow = asstUsr.Id;
        flInpList.add(flInp);
        String uniqueUserName = 'flowstandarduser' + DateTime.now().getTime() + '@SBRtestorg.com';
        // This code runs as the system user
        Profile prf = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User contextuser = new User(Alias = 'standt', Email='flowstandarduser@testorg.com',
                                        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                                        LocaleSidKey='en_US', ProfileId = prf.Id,
                                        TimeZoneSidKey='America/Los_Angeles',
                                        UserName=uniqueUserName
                                    );

        Test.startTest();
        System.runAs(contextuser){
            PPA_UpdatePriceListAssistantBatch.updatePriceListAssistantBatch(flInpList);
        }
        Test.stopTest();
        List<PPA_Price_List__c> priceLists = [SELECT Id, Name FROM PPA_Price_List__c WHERE PPA_AssistantId__c!='' LIMIT 100];
        Assert.isTrue(priceLists.size() == 2);
    }
}