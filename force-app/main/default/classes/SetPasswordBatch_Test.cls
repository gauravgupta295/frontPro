/**
 * @description       : 
 * @author            : Hamza B
 * @group             : 
 * @last modified on  : 11-16-2023
 * @last modified by  :Hamza B
**/
@isTest
public class SetPasswordBatch_Test {

    @testSetup
    static void makeData(){        
        List<User> users = new List<User>();
        for(Integer i = 0; i < 150; i++) {
            User testUser = new User(
                LastName = 'testUser' + i,
                FirstName = 'Bruno' + i,
                Email = 'btest'+ i +'@test.com',
                Username = 'btest7645r'+ i +'@test.com',
                Alias = 'btest' + i,
                TimeZoneSidKey = 'GMT',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                ProfileId = UserInfo.getProfileId(),
                LanguageLocaleKey = 'en_US'
            );
            users.add(testUser);
        }
        insert users;
    }

    @isTest
    private static void setUsersPasswordBulkTest() {
        String prefex = 'testUser';
        String password = 'Test@1234';

        Test.startTest();
        Id batchprocessid = Database.executeBatch(new SetPasswordBatch(prefex, password));
        Test.stopTest();
    }
    
}