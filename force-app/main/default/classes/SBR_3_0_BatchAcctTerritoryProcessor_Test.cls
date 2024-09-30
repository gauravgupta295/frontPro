/*********************************************************************************************************************
* Apex Class: SBR_3_0_BatchAcctTerritoryProcessor_Test
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Class to test SBR_3_0_BatchAcctTerritoryProcessor_Test
* - 
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Saathvik Tulasi      2023-03-13             Initial version 
    2.0         Gopal Raj			 2024-06-26				FRONT-30850
*********************************************************************************************************************/
@isTest(seeAllData=false) 
public class SBR_3_0_BatchAcctTerritoryProcessor_Test Implements HttpCalloutMock{
    static Boolean SUCCESSTEST = true;
    @TestSetup
    static void makeData(){       
        Credential__c cred = SBR_3_0_TestDataFactory.createCredentials(1, false)[0];
        cred.Name = 'Mule_Token_Endpoint';
        cred.Key_Id__c = 'testKey123';
        cred.Secret__c = 'secret';
        insert cred;
    }
    public HTTPResponse respond(HTTPRequest req) {
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type',SBR_3_0_Constants.APP_JSON);
        if(req.getEndpoint().endsWithIgnoreCase('token')){
            res.setBody('{"access_token":"test"}');
        }else if (SUCCESSTEST) {
            res.setBody('{"data":{"territories":[{"pcId":574,"territory":10,"section":1,"territoryId":"1-574-10-1","mapSource":"GT","mapAnalysisRegion":920,"salesRepId":57402,"salesRepName":"CARLSTON, RONNIE  (574)"},{"pcId":577,"territory":31,"section":1,"territoryId":"1-577-31-1","mapSource":"PowerCom","mapAnalysisRegion":922,"salesRepId":57712,"salesRepName":"PINKEVICH, TEMA  (577)"},{"pcId":732,"territory":20,"section":1,"territoryId":"1-732-20-1","mapSource":"Climate-Comm","mapAnalysisRegion":934,"salesRepId":73207,"salesRepName":"MAYEDA, JASON  (732)"},{"pcId":645,"territory":10,"section":1,"territoryId":"1-645-10-1","mapSource":"Flooring","mapAnalysisRegion":936,"salesRepId":64503,"salesRepName":"PINTANE, JAMES (645)          "},{"pcId":652,"territory":20,"section":1,"territoryId":"1-652-20-1","mapSource":"Ground-Event","mapAnalysisRegion":939,"salesRepId":65202,"salesRepName":"LAKE, DAVID  (652)            "},{"pcId":652,"territory":30,"section":1,"territoryId":"1-652-30-1","mapSource":"Ground-Access","mapAnalysisRegion":939,"salesRepId":65204,"salesRepName":"SAUER, BRADLEY  (652)         "},{"pcId":1577,"territory":13,"section":1,"territoryId":"1-1577-13-1","mapSource":"PumpCiv","mapAnalysisRegion":941,"salesRepId":157701,"salesRepName":"VAN NAME, ADAM (1577)         "},{"pcId":333,"territory":15,"section":2,"territoryId":"1-333-15-2","mapSource":"INDTool","mapAnalysisRegion":944,"salesRepId":33318,"salesRepName":"CALKINS, KENDRICK  (333) "}],"prospectType":"Account"}}}');
        } else {
            res.setBody('{ "data": {} }');
        }
        res.setStatusCode(200);
        return res;
    }
	/************************************************************* Cover SBR_3_0_BatchAcctTerritoryProcessor Starts*************************************************************/
    public Static testMethod void SBR_3_0_BatchAcctTerritoryProcessor(){
        SUCCESSTEST = true;
		Profile oProfile = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User oUsers = SBR_3_0_TestDataFactory.createUser(FALSE,oProfile);
        //oUsers.RepID__c = '57402';
        INSERT oUsers;
        List<Account> lAccounts = SBR_3_0_TestDataFactory.createAccounts(10,false,SBR_3_0_Constants.ACCOUNT_REC_TYPE_PROSPECT);
    	INSERT lAccounts;

        List<Account_Relationship__c> testARs = SBR_3_0_TestDataFactory.createAccountRelationships(1, lAccounts[0].Id, true);

        Set<Id> sStreetAddresses = new Set<Id>();
        Set<Id> sOverrideAddresses = new Set<Id>();
        for(Account oAccount : lAccounts){
        	sStreetAddresses.add(oAccount.id); 
            sOverrideAddresses.add(oAccount.id);
        }
        System.runAs(oUsers){
            Test.setMock(HttpCalloutMock.class, new SBR_3_0_BatchAcctTerritoryProcessor_Test());
            Test.startTest();
            SBR_3_0_TestDataFactory.createTerritory(TRUE,'1-574-10-1');
            SBR_3_0_BatchAcctTerritoryProcessor oTerritoryProcessor = new SBR_3_0_BatchAcctTerritoryProcessor(lAccounts);
            Database.executeBatch(oTerritoryProcessor);
            Test.stopTest();
        }
    }
    /************************************************************* Cover SBR_3_0_BatchAcctTerritoryProcessor Ends*************************************************************/
}