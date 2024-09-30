@isTest
public class SBR_3_0_UserTrigger_Test {
    @TestSetup
    static void makeData() {
      Schema.Location branch = SBR_3_0_TestDataFactory.createLocations(1, false, SBR_3_0_Constants.LOCATION_REC_TYPE_BRANCH)[0];
      branch.Name = 'Branch';
      branch.Company_Code__c = 'X';
      branch.Analysis_Region_Key__c = 'X';
      branch.Branch_Location_Number__c = '123';
      insert branch;

      Schema.Location branch2 = SBR_3_0_TestDataFactory.createLocations(1, false, SBR_3_0_Constants.LOCATION_REC_TYPE_BRANCH)[0];
      branch2.Name = 'Branch2';
      branch2.Company_Code__c = 'X';
      branch2.Analysis_Region_Key__c = 'X';
      branch2.Branch_Location_Number__c = '456'; 
      insert branch2;
    }

    @isTest
    static void upsertUserTest() {
        List<User> userList = new List<User>();

        Test.startTest();
            System.debug(+[Select id,Name,Branch_Location_Number__c from Location]);
            Profile p = [SELECT Id FROM Profile WHERE Name='Sales'];
            //create OSR user 
            String osrUserOneName = 'osrUserOne' + DateTime.now().getTime() + '@SBRtestorg.com';
            User osrUserOne = new User(Alias = 'osrOne', Email='ersuser@testorg.com',EmailEncodingKey='UTF-8', LastName='osrOne', LanguageLocaleKey='en_US',LocaleSidKey='en_US', ProfileId = p.Id,Department = '123',TimeZoneSidKey='America/Los_Angeles',UserName=osrUserOneName,CompanyName='X');
            insert osrUserOne;

            //Update User
            osrUserOne.Department = '456';
            update osrUserOne;
            
        Test.stopTest();
    }
    @isTest
    static void deactivateUserTest() {
        
        Account[] accts = SBR_3_0_TestDataFactory.createAccounts(2, true, SBR_3_0_Constants.ACCOUNT_REC_TYPE_CREDIT);
        for (Account a : accts)
        {
            SBR_3_0_TestDataFactory.createAccountRelationships(1, a.Id, true);
        }

        Territory__c t = new Territory__c(Territory_Id__c = '1-574-10-3');
        insert t;

        Profile p = [SELECT Id FROM Profile WHERE Name='Sales'];
        //create SM user 
        String smUserOneName = 'smUserOne' + DateTime.now().getTime() + '@SBRtestorg.com';
        User smUserOne = new User(Alias = 'smOne', Email='ersuser@testorg.com',EmailEncodingKey='UTF-8', LastName='smOne', LanguageLocaleKey='en_US',LocaleSidKey='en_US', ProfileId = p.Id,Department = '123',TimeZoneSidKey='America/Los_Angeles',UserName=smUserOneName,RepID__c='111111');
        insert smUserOne;
        //create OSR user 
        String osrUserOneName = 'osrUserOne' + DateTime.now().getTime() + '@SBRtestorg.com';
        User osrUserOne = new User(Alias = 'osrOne', Email='ersuser@testorg.com',EmailEncodingKey='UTF-8', LastName='osrOne', LanguageLocaleKey='en_US',LocaleSidKey='en_US', ProfileId = p.Id,Department = '123',TimeZoneSidKey='America/Los_Angeles',UserName=osrUserOneName,ManagerId=smUserOne.Id,RepID__c='222222');
        insert osrUserOne;
        
        Account_Relationship__c[] acct_rels = [select Id, Territory__c, User_Account__c from Account_Relationship__c order by CreatedDate desc limit 2];
        Integer counter = 1;
        for (Account_Relationship__c ar : acct_rels)
        {
            if (counter == 1)
            {
                ar.Territory__c = t.Id;
            }
            ar.User_Account__c = osrUserOne.Id;
        }
        if (acct_rels.size() > 0)
        {
            update acct_rels;
        }
            
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];    
            
        Test.startTest();
            System.runAs(thisUser){
                //Update User
                osrUserOne.isActive = false;
                update osrUserOne;
            }
        Test.stopTest();
    }
    @isTest
    static void testGetUsersById() {
    
        Profile p = [SELECT Id FROM Profile WHERE Name='Sales'];
        //create SM user 
        String smUserOneName = 'smUserOne' + DateTime.now().getTime() + '@SBRtestorg.com';
        User smUserOne = new User(Alias = 'smOne', Email='ersuser@testorg.com',EmailEncodingKey='UTF-8', LastName='smOne', LanguageLocaleKey='en_US',LocaleSidKey='en_US', ProfileId = p.Id,Department = '123',TimeZoneSidKey='America/Los_Angeles',UserName=smUserOneName,RepID__c='11223');
        insert smUserOne;
        //create OSR user 
        String osrUserOneName = 'osrUserOne' + DateTime.now().getTime() + '@SBRtestorg.com';
        User osrUserOne = new User(Alias = 'osrOne', Email='ersuser2@testorg.com',EmailEncodingKey='UTF-8', LastName='osrOne', LanguageLocaleKey='en_US',LocaleSidKey='en_US', ProfileId = p.Id,Department = '123',TimeZoneSidKey='America/Los_Angeles',UserName=osrUserOneName,ManagerId=smUserOne.Id,RepID__c='565656');
        insert osrUserOne;
            
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];    
            
        Test.startTest();
            System.runAs(thisUser){
                List<String> userIdList = new List<String>();
                userIdList.add(osrUserOne.Id);
                userIdList.add(smUserOne.Id);
                SBR_3_0_UserOperations.UserRequest uR = new SBR_3_0_UserOperations.UserRequest();
                uR.userIds = userIdList;
                List<SBR_3_0_UserOperations.UserRequest> uRList = new List<SBR_3_0_UserOperations.UserRequest>();
                uRList.add(uR);
                List<SBR_3_0_UserOperations.UserResponse> userList = SBR_3_0_UserOperations.fetchUsersById(uRList);
            }
        Test.stopTest();
    }
}