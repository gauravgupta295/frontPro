/*********************************************************************************************************************
* Apex Class: SBR_3_0_LocationOperations_Test
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Test classClass to publish Location records of Branch record type to Outbox object
* - SAL-1424
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME                      DATE                 DETAIL FEATURES
    1.0         Harry Rokad                      2022-03-30            Initial version    
*********************************************************************************************************************/

@isTest
public with sharing class SBR_3_0_LocationOperations_Test {
    @TestSetup
    static void makeData(){

        List<User> usersToInsert = new List<User>();
        // Create admin User
        Profile adminProfile = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        String adminUserName = 'systemadmin' + DateTime.now().getTime() + '@SBRtestorg.com';
        User adminUser = new User(Alias = 'standt', Email='systemadmin@testorg.com',
        EmailEncodingKey='UTF-8', LastName='adminTest', LanguageLocaleKey='en_US',
        LocaleSidKey='en_US', ProfileId = adminProfile.Id,
        TimeZoneSidKey='America/Los_Angeles',
        UserName=adminUserName);
        usersToInsert.add(adminUser);
        
        String adminUserNameTwo = 'systemadminTwo' + DateTime.now().getTime() + '@SBRtestorg.com';
        User adminUserTwo = new User(Alias = 'standt2', Email='systemadminTwo@testorg.com',
        EmailEncodingKey='UTF-8', LastName='adminTestTwo', LanguageLocaleKey='en_US',
        LocaleSidKey='en_US', ProfileId = adminProfile.Id,
        TimeZoneSidKey='America/Los_Angeles',
        UserName=adminUserNameTwo, CompanyName = '01');
        usersToInsert.add(adminUserTwo);

        // Create Integration User
        Profile IntegrationProfile = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        String intUsername = 'intUser' + DateTime.now().getTime() + '@SBRtestorg.com';
        User intUser = new User(Alias = 'standInt', Email='intUser@testorg.com',
        EmailEncodingKey='UTF-8', LastName='intTest', LanguageLocaleKey='en_US',
        LocaleSidKey='en_US', ProfileId = adminProfile.Id,
        TimeZoneSidKey='America/Los_Angeles',
        UserName=intUsername);
        usersToInsert.add(intUser);

        insert usersToInsert;

        // Insert Integration Permission Set
        PermissionSetLicense cpqLicense = [SELECT MasterLabel, DeveloperName FROM PermissionSetLicense WHERE Developername = 'SalesforceCPQ_CPQStandardPerm'];
        PermissionSetLicenseAssign cpqLicenseAssign = new PermissionSetLicenseAssign(AssigneeId = intUser.Id, PermissionSetLicenseId = cpqLicense.Id);
        insert cpqLicenseAssign;

        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Integration_API_Access'];
        insert new PermissionSetAssignment(AssigneeId = intUser.id, PermissionSetId = ps.Id);
    }

    @isTest static void publishBranchLocationTest(){
        List<Schema.Location> acc =SBR_3_0_TestDataFactory.createLocations(1, True, 'Branch');
        Id ide;
        System.debug(ide);
        for (Schema.Location sob:acc){
            ide=sob.Id;
        }
        Outbox__c out =  [Select Record_Id__c, Record_Type_Name__c from Outbox__c where Record_Id__c=:ide];
        String rtn=out.Record_Type_Name__c;
        System.assertEquals('Branch',rtn);
    }

    @IsTest
    static void testProccessDeliveryFieldsUpdate(){
        List<Schema.Location> acc =SBR_3_0_TestDataFactory.createLocations(1, True, 'Branch');
        User intUser;
        user adminUser;
        for(User usr: [SELECT ID, Username, Lastname FROM USER WHERE LastName =: 'adminTest' OR Lastname =: 'intTest']){
            if(usr.Lastname == 'adminTest'){
                adminUser = usr;
            } else {
                intUser = usr;
            }
        }
        // Allow delivery time change for non External User
        System.runAs(adminUser){
            SBR_3_0_LocationTriggerHandler.beforeUpdateRecursiveCheck = false;
            acc[0].put('Delivery_Monday_Open_Time__c', Time.newInstance(07, 0, 0, 0));
            update acc[0];
            Schema.Location updatedLocation = [SELECT ID, Delivery_Times_Updated_by_SF__c FROM Location WHERE Id =: acc[0].Id];
            system.assertEquals(updatedLocation.Delivery_Times_Updated_by_SF__c, true);
        }

        // Do not allow delivery time change for External User
        System.runAs(intUser){
            SBR_3_0_LocationTriggerHandler.beforeUpdateRecursiveCheck = false;
            acc[0].put('Delivery_Monday_Open_Time__c', Time.newInstance(14, 0, 0, 0));
            update acc[0];
            Schema.Location updatedLocation = [SELECT ID, Delivery_Times_Updated_by_SF__c, Delivery_Monday_Open_Time__c FROM Location WHERE Id =: acc[0].Id];
            system.assertEquals(Time.newInstance(07, 0, 0, 0), updatedLocation.Delivery_Monday_Open_Time__c);
        }
    }

    @isTest static void fetchLatLongUpdateTest(){

        Credential__c cred = SBR_3_0_TestDataFactory.createCredentials(1, false)[0];
        cred.Name = 'Mule_Token_Endpoint';
        cred.Key_Id__c = 'keyid';
        cred.Secret__c ='credSecret';
        insert cred;
        
        Schema.Location jobLocation = new Schema.Location();
        jobLocation.Name = 'Test Job Location';
        jobLocation.Street_Address__c = '12 Main Street';
        jobLocation.City__c = 'Toronto';
        jobLocation.Zip_Code__c = 'M7N7B3';
        jobLocation.State__c = 'ON';
        jobLocation.Country__c = 'CA';
        jobLocation.RecordTypeId = SBR_3_0_Constants.LOCATION_JOB_RT_ID;
        jobLocation.OMS_Sourcing_Enabled__c = true;
        jobLocation.Distance_Multiplier__c = 50;
        jobLocation.Analysis_Region_Key__c = '001';
        jobLocation.Company_Code__c = '01';
        insert jobLocation;

        Schema.Location oldLoc = jobLocation.clone(true);
        oldLoc.Street_Address__c = 'Test Street';

        Map<Id, Schema.Location> newLocMap = new Map<Id, Schema.Location>();
        newLocMap.put(jobLocation.Id, jobLocation);
        Map<Id, Schema.Location> oldLocMap = new Map<Id, Schema.Location>();
        oldLocMap.put(jobLocation.Id, oldLoc);
        
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_FetchLatLong_MockSuccess());
        SBR_3_0_LocationOperations.fetchAddressLatLong(oldLocMap, newLocMap);
        Test.stopTest();

        Schema.Location loc2 = [SELECT ID, Latitude_Longitude__Latitude__s FROM Location WHERE Id =: jobLocation.Id];
        System.assertNotEquals(null, loc2.Latitude_Longitude__Latitude__s, 'Fetch Lat Long Status is not successful');
    }


    @isTest static void fetchLatLongEmptyTest(){

        Credential__c cred = SBR_3_0_TestDataFactory.createCredentials(1, false)[0];
        cred.Name = 'Mule_Token_Endpoint';
        cred.Key_Id__c = 'keyid';
        cred.Secret__c ='credSecret';
        insert cred;
        
        Schema.Location jobLocation = new Schema.Location();
        jobLocation.Name = 'Test Job Location';
        jobLocation.Street_Address__c = '12 Main Street';
        jobLocation.City__c = 'Toronto';
        jobLocation.Zip_Code__c = 'M7N7B3';
        jobLocation.State__c = 'ON';
        jobLocation.Country__c = 'CA';
        jobLocation.RecordTypeId = SBR_3_0_Constants.LOCATION_JOB_RT_ID;
        jobLocation.OMS_Sourcing_Enabled__c = true;
        jobLocation.Distance_Multiplier__c = 50;
        jobLocation.Analysis_Region_Key__c = '001';
        jobLocation.Company_Code__c = '01';
        insert jobLocation;

        Schema.Location oldLoc = jobLocation.clone(true);
        oldLoc.Street_Address__c = 'Test Street';

        Map<Id, Schema.Location> newLocMap = new Map<Id, Schema.Location>();
        newLocMap.put(jobLocation.Id, jobLocation);
        
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_FetchLatLong_MockSuccess());
        SBR_3_0_LocationOperations.fetchAddressLatLong(null, newLocMap);
        Test.stopTest();

        Schema.Location loc2 = [SELECT ID, Latitude_Longitude__Latitude__s FROM Location WHERE Id =: jobLocation.Id];
        System.assertNotEquals(null, loc2.Latitude_Longitude__Latitude__s, 'Fetch Lat Long Status is not successful');
    }
    
    @isTest static void setCompanyCodeTest() {
        User u = [SELECT ID, CompanyName FROM USER WHERE LastName = 'adminTestTwo'];
        System.runAs(u) {
            Test.startTest();
            Schema.Location newLocation = SBR_3_0_TestDataFactory.createLocations(1, false, SBR_3_0_Constants.LOCATION_REC_TYPE_JOB_LOC)[0];
            newLocation.Name = 'companyCodeTest';
            insert newLocation;
            Schema.Location testLocation = [SELECT Id, Company_Code__c FROM Location WHERE Name = 'companyCodeTest'];
            System.assertEquals(u.CompanyName, testLocation.Company_Code__c);
            Test.stopTest();
        }
    }

}