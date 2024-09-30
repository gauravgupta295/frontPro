@isTest
public with sharing class SBR_3_0_Queuable_AccountTerritoryTest implements HttpCalloutMock{
    @TestSetup
    static void makeData(){
        Credential__c cred = SBR_3_0_TestDataFactory.createCredentials(1, false)[0];
        cred.Name = 'Mule_Token_Endpoint';
        cred.Key_Id__c = 'keyid';
        cred.Secret__c ='credSecret';
        insert cred;
        
        Territory__c terri = new Territory__c();
        terri.Name = 'Terri1';
        terri.Territory_Id__c = '1';
        terri.OwnerId = UserInfo.getUserId();
        insert terri;
        
        List<Account> testParentAcc = SBR_3_0_TestDataFactory.createAccounts(1, false, SBR_3_0_Constants.ACCOUNT_REC_TYPE_PROSPECT);
        insert testParentAcc;
        
        List<Account> testProspectAccounts = SBR_3_0_TestDataFactory.createAccounts(1, false, SBR_3_0_Constants.ACCOUNT_REC_TYPE_PROSPECT);
        for(Integer i = 0; i < 1; i++) {
            testProspectAccounts[i].Name = 'Test Prospect Account ' + i;
            testProspectAccounts[i].Street_Address_LatLong__Latitude__s = 48.39433;
            testProspectAccounts[i].Street_Address_LatLong__Longitude__s = -118.62526;
        }
        insert testProspectAccounts;
        
        List<Account> testOfficeAccounts = SBR_3_0_TestDataFactory.createAccounts(3, false, SBR_3_0_Constants.ACCOUNT_REC_TYPE_OFFICE);
        for(Integer i = 0; i < 3; i++) {
            testOfficeAccounts[i].Name = 'Test Office Account ' + i;
            testOfficeAccounts[i].Street_Address_LatLong__Latitude__s = 30.39635;
            testOfficeAccounts[i].Street_Address_LatLong__Longitude__s = -83.71746;
            testOfficeAccounts[i].ParentId = testParentAcc[0].Id;
        }
        insert testOfficeAccounts;
        
        List<Account_Relationship__c> accRelLst = new List<Account_Relationship__c>();
        for(Account acc: testOfficeAccounts){
            Account_Relationship__c acr= new Account_Relationship__c(
                Name = 'Accrln'+acc.Id,
                Account_ID__c = acc.ParentId,
                Rank__c = 9879
            );
            accRelLst.add(acr);
        }
        insert accRelLst;
    }
    public HTTPResponse respond(HTTPRequest request) {
        // Create a fake response
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        if(request.getEndpoint().endsWithIgnoreCase('token')){
            response.setBody('{"access_token":"test"}');
        } else{
            response.setBody('{ "data": { "territories": [ { "pcId": 577, "territory": 21, "section": 1, "territoryId": 1, "mapSource": "PowerCom", "mapAnalysisRegion": 922, "salesRepId": 57713, "salesRepName": "CASLER, JACOB (577) " } ], "prospectType": "Project" } }');
        }
        response.setStatusCode(200);
        return response; 
    }
    
    @isTest
    static void executeProspectTest() {
        List<Account> accs = [SELECT Id, RecordTypeId, Street_Address_LatLong__Latitude__s, Street_Address_LatLong__Longitude__s,ParentId
                              FROM Account WHERE Name LIKE 'Test Prospect Account _'];
        //System.assertEquals(3, accs.size(), 'Did not get expected number of accounts');
        
        Test.startTest();
            Test.setMock(HttpCalloutMock.class, new SBR_3_0_Queuable_AccountTerritoryTest());
            System.enqueueJob(new SBR_3_0_Queuable_AccountTerritory(accs));
        Test.stopTest();
        
        Id accId = accs[0].Id;
        List<Account_Relationship__c> ar = [SELECT Id FROM Account_Relationship__c Where Account_ID__c =: accId];
        System.assert(ar.size() > 0, 'Did not create Account Relationships: ' + ar.size());
    }
    
    @isTest
    static void executeOfficeTest() {
        List<Account> accs = [SELECT Id, RecordTypeId, Street_Address_LatLong__Latitude__s, Street_Address_LatLong__Longitude__s,
                              ParentId FROM Account WHERE Name LIKE 'Test Office Account _'];
        System.assertEquals(3, accs.size(), 'Did not get expected number of accounts');
        
        Test.startTest();
            Test.setMock(HttpCalloutMock.class, new SBR_3_0_Queuable_AccountTerritoryTest());
            System.enqueueJob(new SBR_3_0_Queuable_AccountTerritory(accs));
        Test.stopTest();
        
        Id accId = accs[0].Id;
        List<Account_Relationship__c> ar = [SELECT Id FROM Account_Relationship__c Where Account_ID__c =: accId];
        System.assert(ar.size() > 0, 'Did not create Account Relationships: ' + ar.size());

    }
}