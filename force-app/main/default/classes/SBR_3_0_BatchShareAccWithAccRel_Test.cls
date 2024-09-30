@isTest(seeAllData=false) 
public class SBR_3_0_BatchShareAccWithAccRel_Test {
    
    
    @TestSetup
    static void makeData(){
        
        Credential__c cred = SBR_3_0_TestDataFactory.createCredentials(1, false)[0];
        cred.Name = 'Mule_Token_Endpoint';
        cred.Key_Id__c = 'keyid';
        cred.Secret__c ='credSecret';
        insert cred;
    }
     
    @isTest
    static void getAccountRelsByUserIdTest() {
        User u = SBR_3_0_TestDataFactory.createUsers(1, false)[0];
        u.FirstName = 'AccountRelationship';
        u.LastName = 'Test1';
        insert u;
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SuccessMockHttpResponseGenerator());
        
        List<Account> acc =SBR_3_0_TestDataFactory.createAccounts(1, True, 'Credit');
        
        Account_Relationship__c accRel = new Account_Relationship__c() ;
        accRel.User_Account__c = u.Id;
        accRel.Account_ID__c=acc[0].Id;
        accRel.Type__c = 'Assigned';
        insert accRel;
        
        SBR_3_0_BatchShareAccWithAccRel bc = new SBR_3_0_BatchShareAccWithAccRel();
		Database.executeBatch(bc);
        Test.stopTest();

        List<AccountShare> accShareRecs = [SELECT Id FROM AccountShare WHERE AccountId=:acc[0].Id];
        System.assertEquals(true,accShareRecs.size()>0);
    }    
    
    public class SuccessMockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest request) {
            // Create a fake response
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            if(request.getEndpoint().endsWithIgnoreCase('token')){
                response.setBody('{"access_token":"test"}');
            }else{ 
                response.setBody('{"data": {"geoInfo": {"streetAddress": "Arizona Biltmore Estates","city": "Phoenix","province": "Arizona","country": "United States","latitude": 33.5160515,"longitude": -112.0222999},"timezone": {"id": "America/Phoenix","name": "Mountain Standard Time","dstOffset": 0,"rawOffset": -25200,"rmOffsetForStandardTime": -20,"rmOffsetForDaylightSavingTime": -30}}}');
            }
            response.setStatusCode(200);
            return response; 
        }
    }
}