@isTest
public  class SBR_3_0_UserDeactivationBatchable_Test {
    @TestSetup
    static void makeData(){
        List<Account> listAccounts = SBR_3_0_TestDataFactory.createAccounts(10, false, 'Credit');
        for(Integer i = 0 ; i <  listAccounts.size() ; i ++){
            listAccounts[i].RM_Account_Number__c = '11231231231' + i;
        }
        Insert listAccounts;

        User managerUser = SBR_3_0_TestDataFactory.createUsers(1, false)[0];
        managerUser.FirstName = 'Manager';
        managerUser.Analysis_Region_Key__c = '920';
        managerUser.LastName = 'Test';
        Insert  managerUser;

        List<User> listUsers = new List<User>();
        User usr1 = SBR_3_0_TestDataFactory.createUsers(1, false)[0];
        usr1.FirstName = 'AccountRelationshipDA';
        usr1.LastName = 'Test';
        usr1.managerId = managerUser.Id;
        listUsers.add(usr1);

        User usr2 = SBR_3_0_TestDataFactory.createUsers(1, false)[0];
        usr2.FirstName = 'AccountRelationshipDA';
        usr2.LastName = 'Test';
        usr2.managerId = managerUser.Id;
        listUsers.add(usr2);

        Insert listUsers;

        List<Territory__c> listTerritories= new List<Territory__c>();
        Territory__c terri1 = new Territory__c();
        terri1.Name = 'Terri1';
        terri1.Territory_Id__c = '1';
        terri1.OwnerId =listUsers[0].Id;
        listTerritories.add(terri1);
        
        Territory__c terri2 = new Territory__c();
        terri2.Name = 'Terri1';
        terri2.Territory_Id__c = '2';
        terri2.OwnerId =listUsers[0].Id;
        listTerritories.add(terri2);
        insert listTerritories;
       
        //System.debug(u.Id);
        List<Account_Relationship__c> listAccountRelationShips = new List<Account_Relationship__c>();
        for(Integer i = 0; i < 10 ; i ++){
            Account_Relationship__c accRel = SBR_3_0_TestDataFactory.createAccountRelationships(1, listAccounts[i].Id, false)[0]; 
            accRel.User_Account__c = math.mod(i, 2) == 0  ? listUsers[0].Id : listUsers[1].Id;  
            accRel.Territory__c = math.mod(i, 2) == 0  ? listTerritories[0].Id : listTerritories[1].Id;  
            listAccountRelationShips.add(accRel); 
        }
        Insert listAccountRelationShips;
        
    }
    
    @isTest
    static void getAccountRelsByUserIdTest() {

        Map<Id, User> mapUsers = new Map<Id, User>([Select Id from User]);
        List<Id> listUsersIds = new List<Id>();
        listUsersIds.addAll(mapUsers.keyset());
        Test.startTest();
            SBR_3_0_UserDeactivationBatchable udb = new SBR_3_0_UserDeactivationBatchable(listUsersIds);
            Database.executeBatch(udb);
        Test.stopTest();

        List<Account_Relationship__c> listAccountRelationShips = [Select Id from Account_Relationship__c];
        system.assertEquals(listAccountRelationShips.size() , 5 );

    }
}