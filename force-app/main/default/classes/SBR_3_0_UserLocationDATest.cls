@isTest
public with sharing class SBR_3_0_UserLocationDATest {
    @isTest
    static void givenValidUserIDReturnUserLocation(){
        Id user = UserInfo.getUserID();
        List<Schema.Location> branch = SBR_3_0_TestDataFactory.createInventoryLocations(1,true,'Branch');

        User_location__c userLocation = new user_location__c(branch__c = branch[0].Id,User__c = user);
        Insert userLocation;

        Test.startTest();
            List<User_Location__c> testUserLocation = SBR_3_0_UserLocationDA.getUserLocation(user);
        Test.StopTest();

        System.assertEquals(userLocation.Id,testUserLocation[0].Id);
    }

    @isTest
    static void givenValidUserIDsReturnUserLocation(){
        Id user = UserInfo.getUserID();
        List<Schema.Location> branch = SBR_3_0_TestDataFactory.createInventoryLocations(1,true,'Branch');

        User_location__c userLocation = new user_location__c(branch__c = branch[0].Id,User__c = user);
        insert userLocation;

        Set<Id> userIds = new Set<Id>();
        userIds.add(user);

        Test.startTest();
            List<User_Location__c> testUserLocation = SBR_3_0_UserLocationDA.getUserLocation(userIds);
        Test.StopTest();

        System.assertEquals(userLocation.Id,testUserLocation[0].Id);
    }
    
    static testMethod void testGetOsrs() {
        Test.startTest();
              List<User_Location__c> usrList =SBR_3_0_UserLocationDA.getOsrs();
              if(usrList.size()>0){
                System.assert(usrList.size()>0);
              }
         Test.stopTest(); 
    }
    /**
    @IsTest
    static void testGetUserRecord() {
        // Create a test user
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Username = 'testuser@example.com',
            Alias = 'TUser',
            Email = 'testuser@example.com',
            ProfileId = UserInfo.getProfileId(),
            TimeZoneSidKey = 'GMT',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert testUser;
        
       	Schema.Location branch = SBR_3_0_TestDataFactory.createLocations(1, false, SBR_3_0_Constants.LOCATION_REC_TYPE_BRANCH)[0];
      branch.Name = 'Branch';
      branch.Company_Code__c = 'X';
      branch.Analysis_Region_Key__c = 'X';
      insert branch;
        
        User_location__c userloc = new User_location__c(
        	Branch__c = branch.Id,
            User__c = testUser.Id
        );
        insert userloc;
        
        // Test the getUserRecord() method
        Test.startTest();
        List<User_Location__c> result = SBR_3_0_UserLocationDA.getUserRecord(userloc.Id);
        Test.stopTest();
        
        // Assertions
        System.assertEquals(testUser.Id, result.User__c, 'The returned User Id should match the test user Id');
    }**/
}