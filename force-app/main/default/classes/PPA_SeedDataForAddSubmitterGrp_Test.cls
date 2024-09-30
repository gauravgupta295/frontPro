/*
Test Class for PPA_SeedDataForAddSubmitterGrp apex class
PPA Phase 2: DP-1025
*/
@isTest
public with sharing class PPA_SeedDataForAddSubmitterGrp_Test {
    @testSetup
    static void setUp() {
        string fName = 'Test';
        string lName = 'User';
        Integer usrCnt = 3;

        //Create new users
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator' LIMIT 1];
        List<User> usrList = new List<User>();
        for (Integer i = 1; i < usrCnt; i++) {
            User usr = new User();
            usr.FirstName = fName + '_' + i;
            usr.LastName = lName + '_' + i;
            usr.IsActive = true;
            usr.ProfileId = p.Id;
            usr.Username = 'testusr' + i + '@testsbr.com_' + System.currentTimeMillis();
            usr.Email='testusr@testorg.com';
            usr.EmployeeNumber = '000' + i;
            usr.TimeZoneSidKey = 'America/Los_Angeles';
            usr.EmailEncodingKey = 'UTF-8';
            usr.LanguageLocaleKey = 'en_US';
            usr.LocaleSidKey = 'en_US';
            usr.Alias = 'PPA';
            System.debug('usr: ' + usr);
            usrList.add(usr);
        }
        System.debug('usrList: ' + usrList);
        if(!usrList.isEmpty()) {
            Database.insert(usrList);
        }
    }

    @isTest
    static void addUserToGrp(){
        Set<ID> userIDs = New Set<ID>();
        List<User> testUsers = [SELECT Id FROM User WHERE Email = 'testusr@testorg.com' LIMIT 49999];
        Test.startTest();
        PPA_SeedDataForAddSubmitterGrp.addUserstoGrp();    
        
        for(GroupMember g : [SELECT UserorGroupId FROM GroupMember WHERE group.Name = 'PPA Additional Submitters' AND UserorGroupId IN :testUsers LIMIT 49999]){
            if(g.UserOrGroupID.getsObjectType() == Schema.User.sObjectType)
                    userIDs.add(g.UserOrGroupID);
        }
        Test.stopTest();
        Assert.isTrue(userIDs.size() == 2, 'Exact number of users were added in the public group');
    }
}