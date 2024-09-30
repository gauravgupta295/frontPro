/*********************************************************************************************************************
* Apex Class: SBR_3_0_LeadOperations_Test
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Class to test SBR_3_0_LeadOperations
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Konrad Haight           2022-03-21            Initial version    
*********************************************************************************************************************/
@isTest public with sharing class SBR_3_0_LeadOperations_Test {

    @TestSetup
    static void makeData(){
        Credential__c cred = SBR_3_0_TestDataFactory.createCredentials(1, false)[0];
        cred.Name = 'Mule_Token_Endpoint';
        cred.Key_Id__c = 'keyid';
        cred.Secret__c ='credSecret';
        insert cred;             
    }
    @isTest static void testPreventLeadDeletion(){
        String uniqueUserName = 'standarduser' + DateTime.now().getTime() + '@SBRtestorg.com';
        // This code runs as the system user
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com',
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
        LocaleSidKey='en_US', ProfileId = p.Id,
        TimeZoneSidKey='America/Los_Angeles',
        UserName=uniqueUserName);

        List<Lead> testLeads = SBR_3_0_TestDataFactory.createLeads(2, false);

        System.runAs(u){
            Lead testLeadOne = testLeads[0];
            insert testLeadOne;

            try{
                delete testLeadOne;
            } catch(DmlException e){
                System.debug(e.getMessage());
                system.assert(e.getMessage().contains('Lead cannot be deleted'), 'Lead cannot be deleted');
            }
        }

        String uniqueUserName2 = 'systemadmin' + DateTime.now().getTime() + '@SBRtestorg.com';
        // This code runs as the system user
        Profile p2 = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User u2 = new User(Alias = 'standt', Email='systemadmin@testorg.com',
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
        LocaleSidKey='en_US', ProfileId = p2.Id,
        TimeZoneSidKey='America/Los_Angeles',
        UserName=uniqueUserName2);

        System.runAs(u2){
            Lead testLeadTwo = testLeads[1];
            insert testLeadTwo;

            try{
                Database.DeleteResult dr = Database.delete(testLeadTwo);
                System.assert(dr.isSuccess());
            } catch(DmlException e){
                system.assert(e.getMessage().contains('Lead cannot be deleted'), 'Lead cannot be deleted');
            }
        }
    }

    @isTest static void fetchLatLongSuccessTest(){
        List<Lead> ldList =SBR_3_0_TestDataFactory.createLeads(1, true);
        Id ide;
        for (Lead sob:ldList){
            ide=sob.Id;
        }

        Lead ld =  [SELECT Id, Job_Address_Street__c, Job_Address_City__c, Job_Address_State__c, Job_Address_Zip_Code__c, Job_Address_Country__c, Latitude, Longitude, Address_LatLong_Status__c FROM Lead WHERE Id =: ide];
		ld.Job_Address_Street__c = '6365 Multiplex Drive';
        ld.Job_Address_City__c = 'Centreville';
        ld.Job_Address_State__c = 'VA';
        ld.Job_Address_Zip_Code__c = '20121';
        ld.Job_Address_Country__c = 'US';
        ld.Marketo_Lead__c = true;
        ld.Analysis_Region_Key__c = '921';
        update ld;

        Lead oldLd = ld.clone(true);
        oldLd.Job_Address_Street__c = 'Test Street';
		oldLd.Job_Address_City__c = 'Test City';
        oldLd.Job_Address_State__c = 'NW';
        oldLd.Job_Address_Zip_Code__c = '20122';
        oldLd.Job_Address_Country__c = 'UK';
        
        Map<Id, Lead> newLeadtMap = new Map<Id, Lead>();
        newLeadtMap.put(ld.Id, ld);
        Map<Id, Lead> oldLeadMap = new Map<Id, Lead>();
        oldLeadMap.put(ld.Id, oldLd);
        system.debug('oldLeadtMap::'+oldLeadMap.values());
        system.debug('newLeadtMap::'+newLeadtMap.values());
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_FetchLatLong_MockSuccess());
        SBR_3_0_LeadOperations.fetchAddressLatLong(oldLeadMap, newLeadtMap);
        SBR_3_0_BatchLeadtLatLongProcessor latLongBtch = new SBR_3_0_BatchLeadtLatLongProcessor(new Set<Id>{ld.Id});
        Database.executeBatch(latLongBtch, 1);
        Test.stopTest();

        Lead ld2 = [SELECT ID, Address_LatLong_Status__c FROM Lead WHERE Id =: ide];
        system.assertEquals('Success', ld2.Address_LatLong_Status__c, 'Lead Address Lat Long Status is not set to Success');
    }
    
        @isTest static void fetchLatLongSuccessTestNullOldMap(){
        List<Lead> ldList =SBR_3_0_TestDataFactory.createLeads(1, true);
        Id ide;
        for (Lead sob:ldList){
            ide=sob.Id;
        }

        Lead ld =  [SELECT Id, Job_Address_Street__c, Job_Address_City__c, Job_Address_State__c, Job_Address_Zip_Code__c, Job_Address_Country__c, Latitude, Longitude, Address_LatLong_Status__c FROM Lead WHERE Id =: ide];
		ld.Job_Address_Street__c = '6365 Multiplex Drive';
        ld.Job_Address_City__c = 'Centreville';
        ld.Job_Address_State__c = 'VA';
        ld.Job_Address_Zip_Code__c = '20121';
        ld.Job_Address_Country__c = 'US';
        update ld;

        Lead oldLd = ld.clone(true);
        oldLd.Job_Address_Street__c = NULL;
		oldLd.Job_Address_City__c = 'Test City';
        oldLd.Job_Address_State__c = 'NW';
        oldLd.Job_Address_Zip_Code__c = '20122';
        oldLd.Job_Address_Country__c = 'UK';
        
        Map<Id, Lead> newLeadtMap = new Map<Id, Lead>();
        newLeadtMap.put(ld.Id, ld);
        Map<Id, Lead> oldLeadMap = new Map<Id, Lead>();
        oldLeadMap.put(ld.Id, oldLd);
        system.debug('oldLeadtMap::'+oldLeadMap.values());
        system.debug('newLeadtMap::'+newLeadtMap.values());
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_FetchLatLong_MockSuccess());
        SBR_3_0_LeadOperations.fetchAddressLatLong(NULL, newLeadtMap);
        SBR_3_0_BatchLeadtLatLongProcessor latLongBtch = new SBR_3_0_BatchLeadtLatLongProcessor(new Set<Id>{ld.Id});
        Database.executeBatch(latLongBtch, 1);
        Test.stopTest();

        Lead ld2 = [SELECT ID, Address_LatLong_Status__c FROM Lead WHERE Id =: ide];
        system.assertEquals('Success', ld2.Address_LatLong_Status__c, 'Lead Address Lat Long Status is not set to Success');
    }


    @isTest static void fetchLatLongErrorTest(){
        List<Lead> ldList =SBR_3_0_TestDataFactory.createLeads(1, false);
        Lead ld = ldList[0];
        ld.Job_Address_Street__c = 'Fake Street';
        ld.Job_Address_City__c = 'Fake';
        ld.Job_Address_State__c = 'VA';
        ld.Job_Address_Zip_Code__c = '00000';
        ld.Job_Address_Country__c = 'US';
        insert ld;
		
        Map<Id, Lead> oldLeadMap = new Map<Id, Lead>();
        oldLeadMap.put(ld.Id, ld);
        ld.Job_Address_Street__c='New Fake Street';
        ld.Job_Address_City__c = 'New Fake';
        ld.Job_Address_State__c = 'AB';
        ld.Job_Address_Zip_Code__c = '00001';
        ld.Job_Address_Country__c = 'CA';
        update ld;
        
        Map<Id, Lead> newLeadtMap = new Map<Id, Lead>();
        newLeadtMap.put(ld.Id, ld);
        
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_FetchLatLong_MockFailed());
        //SBR_3_0_LeadOperations.fetchAddressLatLong(NULL, newLeadtMap);
        SBR_3_0_LeadOperations.fetchAddressLatLong(oldLeadMap, newLeadtMap);
        SBR_3_0_BatchLeadtLatLongProcessor latLongBtch = new SBR_3_0_BatchLeadtLatLongProcessor(new Set<Id>{ld.Id});
        Database.executeBatch(latLongBtch, 1);
        Test.stopTest();

        Lead ld2 = [SELECT ID, Address_LatLong_Status__c FROM Lead WHERE Id =: ld.Id];
        system.assertEquals('Error', ld2.Address_LatLong_Status__c, 'Lead Address Lat Long Status is not set to Error');
    }
}