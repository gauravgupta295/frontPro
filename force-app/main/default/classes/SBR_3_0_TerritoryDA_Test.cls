/* Apex Class: SBR_3_0_TerritoryDA_Test
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Class to test SBR_3_0_TerritoryDA
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Rohan Dhavale          2023-09-01           Initial version    
*********************************************************************************************************************/
@isTest
public without sharing class SBR_3_0_TerritoryDA_Test {
    
    private static String territoryUserEmail = 'testUser@sunbeltrentals.com';

    @TestSetup
    static void makeData(){
        //Creating a user record
        Profile userProfile = [SELECT Id FROM Profile WHERE Name='Sales'];
        User testUser = SBR_3_0_TestDataFactory.createUser(false,userProfile);
        testUser.Email = territoryUserEmail;
        insert testUser;

        //Creating a territory record
        Territory__c userTerritory = new Territory__c();
        userTerritory.Name = 'Test User Territory';
        userTerritory.Territory_Id__c = '1-111-111';
        userTerritory.OwnerId = testUser.Id;
        
        insert userTerritory;
        
        
    }
    
    @isTest
    static void testGetTerritories() {
        User testUser = [SELECT Id FROM User WHERE Email =: territoryUserEmail AND Profile.Name='Sales' LIMIT 1];
        Set<Id> userIds = new Set<Id>{testUser.Id};
        Test.startTest();
        List<Territory__c> territoryRecs = SBR_3_0_TerritoryDA.getTerritories(userIds);
        Test.stopTest();

        System.assertEquals(1, territoryRecs.size(), 'Test User should have one territory assigned');
    }
}