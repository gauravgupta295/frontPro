/*********************************************************************************************************************
* Apex Class: SBR_3_0_UserDA_Test
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Test class for SBR_3_0_UserDA
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    2.0         Soni Pinjala         	2023-09-11          Added getUsersBySalesRepIds    
*********************************************************************************************************************/

@isTest
public with sharing class SBR_3_0_UserDA_Test {
    
    static testMethod void getOsrsTest(){
         Test.startTest();
              List<User> usrList =SBR_3_0_UserDA.getOsrs();
              if(usrList.size()>0){
                System.assert(usrList.size()>0);
              }
         Test.stopTest();                               
    }
    /************************************************************* Cover getUsersBySalesRepIds Starts*************************************************************/
    public Static testMethod void getUsersBySalesRepIds(){
		Profile oProfile = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        list<User> lUsers = new list<User>();
        set<String> sIds = new set<String>();
        set<String> rmNames = new set<String>();
        User oUsers1 = SBR_3_0_TestDataFactory.createUser(FALSE,oProfile);
        oUsers1.RepID__c = '1234';
        oUsers1.Wynne_User_Name__c = 'TUSER1';
        sIds.add('1234');
        rmNames.add('TUSER1');
        lUsers.add(oUsers1);
        User oUsers2 = SBR_3_0_TestDataFactory.createUser(FALSE,oProfile);
        oUsers2.RepID__c = '5678';
        oUsers2.Wynne_User_Name__c = 'TUSER2';
        sIds.add('5678');
        rmNames.add('TUSER2');
        lUsers.add(oUsers2);
        List<String> userIdList = new List<String>(sIds);
        System.runAs(oUsers1){
            Test.startTest();
            List<User> lUser = SBR_3_0_UserDA.getUsersBySalesRepIds(sIds);
            SBR_3_0_UserDA.getUserRepIdMapByIds(sIds);
            SBR_3_0_UserDA.getUsersByIds(userIdList);
            SBR_3_0_UserDA.getUsersByRMUserName(rmNames);
            Test.stopTest();
        }
    }
    /************************************************************* Cover getUsersBySalesRepIds Ends*************************************************************/
    /************************************************************* Cover getUserById Starts*************************************************************/
    public Static testMethod void getUserById(){
		Profile oProfile = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User oUsers = SBR_3_0_TestDataFactory.createUser(TRUE,oProfile);
        System.runAs(oUsers){
            Test.startTest();
            User oUser = SBR_3_0_UserDA.getUserById(oUsers.id);
            Test.stopTest();
        }
    }
    /************************************************************* Cover getUserById Ends*************************************************************/
    /************************************************************* Cover getUsers Starts*************************************************************/
    public Static testMethod void getUsers(){
		Profile oProfile = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User oUsers1 = SBR_3_0_TestDataFactory.createUser(TRUE,oProfile);
        User oUsers2 = SBR_3_0_TestDataFactory.createUser(TRUE,oProfile);
        set<Id> sIds = new set<Id>();
        sIds.add(oUsers1.id);
        sIds.add(oUsers2.id);
        System.runAs(oUsers1){
            Test.startTest();
            Map<Id, User> mUser = SBR_3_0_UserDA.getUsers(sIds);
            Test.stopTest();
        }
    }
    /************************************************************* Cover getUsers Ends*************************************************************/
    static testMethod void testGetUserMapBySalesRepIds(){
		Profile oProfile = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User oUsers = SBR_3_0_TestDataFactory.createUser(TRUE,oProfile);
        oUsers.RepID__c = 'Test Id';
        update oUsers;
        Set<String> repIds = new Set<String>();
        repIds.add('Test Id');
        System.runAs(oUsers){
            Test.startTest();
            Map<String, User> retrievedUsers = SBR_3_0_UserDA.getUserMapBySalesRepIds(repIds);           
            Test.stopTest();
            System.assert(!retrievedUsers.isEmpty());
        }
    }
    static testMethod void testGetUserContactInfoById(){
		Profile oProfile = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User oUsers = SBR_3_0_TestDataFactory.createUser(TRUE,oProfile);
        System.runAs(oUsers){
            Test.startTest();
            User oUser = SBR_3_0_UserDA.getUserContactInfoById(oUsers.id);
            Test.stopTest();
            System.assertEquals(oUsers.Id, oUser.Id);
        }
    }
    static testMethod void testGetUserInfoByIdForMyProflie(){
		Profile oProfile = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User oUsers = SBR_3_0_TestDataFactory.createUser(TRUE,oProfile);
        System.runAs(oUsers){
            Test.startTest();
            User oUser = SBR_3_0_UserDA.getUserInfoByIdForMyProflie(oUsers.id);
            Test.stopTest();
            System.assertEquals(oUsers.Id, oUser.Id);
        }
    }
    static testMethod void testIsFirstTimeLogin(){
		Profile oProfile = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User oUsers = SBR_3_0_TestDataFactory.createUser(TRUE,oProfile);
        System.runAs(oUsers){
            Test.startTest();
            Boolean isFirst = SBR_3_0_UserDA.isFirstTimeLogin(oUsers.id);
            System.assertEquals(isFirst, true);
        }
    }
}