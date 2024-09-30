@isTest(seeAllData=false) 
public class SBR_3_0_Invocable_ARAuthority_Test Implements HttpCalloutMock{
    public static String JSON;
    public HTTPResponse respond(HTTPRequest oRequest) {
        HttpResponse oResponse = new HttpResponse();
        oResponse.setHeader('Content-Type',SBR_3_0_Constants.APP_JSON);
        System.debug('oRequest.getEndpoint()'+oRequest.getEndpoint());
        oResponse.setBody('{"token_type":"Bearer","expires_in":900,"access_token":"eyJraWQiOiI1Vk9qbHFHM2RiWktxX0RGQkJ6WEVVV0xWMU1hMGhVMEJhWWE5cm1LRzcwIiwiYWxnIjoiUlMyNTYifQ.eyJ2ZXIiOjEsImp0aSI6IkFULnR4VW1BbS1PZFhLQzNWZVJmLU03ckx0NjBHYVZjRGNSVGE5cnNETk8taTAiLCJpc3MiOiJodHRwczovL2xvZ2lucHJldmlldy5zdW5iZWx0cmVudGFscy5jb20vb2F1dGgyL2F1czFsZjMyMjZ6N1ZwekF0MWQ3IiwiYXVkIjoiaHR0cHM6Ly93d3cuc3VuYmVsdHJlbnRhbHMuY29tL29rdGEvdmVuZG9ycyIsImlhdCI6MTY5MDIwNjY2OSwiZXhwIjoxNjkwMjA3NTY5LCJjaWQiOiIwb2E0NDA0eDJxdmplWmtKcDFkNyIsInNjcCI6WyJNdWxlc29mdCJdLCJzdWIiOiIwb2E0NDA0eDJ","scope":"Mulesoft"}');
        oResponse.setStatusCode(200);
        return oResponse;
    } 
	/************************************************************* Cover authenticateUserHierarchy Starts*************************************************************/
      public Static testMethod void authenticateUserHierarchy(){
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_Invocable_ARAuthority_Test());
        Profile oProfile = [SELECT Id FROM Profile WHERE Name='System Administrator'];
		User oRunAsUser = SBR_3_0_TestDataFactory.createUser(TRUE,oProfile);
        list<Id> lARIDS = new list<Id>();
        list<Id> lUserIDS = new list<Id>();
        List<Account> lAccounts = SBR_3_0_TestDataFactory.createAccounts(1,TRUE,SBR_3_0_Constants.ACCOUNT_REC_TYPE_CREDIT);
        User oUser1 = SBR_3_0_TestDataFactory.createUser(TRUE,oProfile);
        lUserIDS.add(oUser1.id);
        User oUser2 = SBR_3_0_TestDataFactory.createUser(FALSE,oProfile);
        oUser2.ManagerId = oUser1.id;
        INSERT oUser2;
        lUserIDS.add(oUser2.id);
        User oUser3 = SBR_3_0_TestDataFactory.createUser(FALSE,oProfile);
        oUser3.ManagerId = oUser2.id;
        INSERT oUser3;
        lUserIDS.add(oUser3.id);
        List<Account_Relationship__c> lAR =  SBR_3_0_TestDataFactory.createAccountRelationships(10,lAccounts[0].id,FALSE);
        for(Account_Relationship__c oAR : lAR){
            oAR.User_Account__c = oUser1.id;
        }
        INSERT lAR;
        for(Account_Relationship__c oAR : lAR){
        	lARIDS.add(oAR.id);    
        }
        System.runAs(oRunAsUser){
            Test.startTest();
            List<SBR_3_0_Invocable_ARAuthority.ARRequest> lRequest = new List<SBR_3_0_Invocable_ARAuthority.ARRequest>();
            SBR_3_0_Invocable_ARAuthority.ARRequest oRequest = new SBR_3_0_Invocable_ARAuthority.ARRequest();
            oRequest.ARIds = lARIDS;
            oRequest.UserIds = lUserIDS;
            lRequest.add(oRequest);
            SBR_3_0_Invocable_ARAuthority.authenticateUserHierarchy(lRequest);
            Test.stopTest();
        }
    } 
      public Static testMethod void authenticateUserHierarchyNoUserIds(){
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_Invocable_ARAuthority_Test());
        Profile oProfile = [SELECT Id FROM Profile WHERE Name='System Administrator'];
		User oRunAsUser = SBR_3_0_TestDataFactory.createUser(TRUE,oProfile);
        list<Id> lARIDS = new list<Id>();
        list<Id> lUserIDS = new list<Id>();
        List<Account> lAccounts = SBR_3_0_TestDataFactory.createAccounts(1,TRUE,SBR_3_0_Constants.ACCOUNT_REC_TYPE_CREDIT);
        User oUser1 = SBR_3_0_TestDataFactory.createUser(FALSE,oProfile);
        oUser1.Analysis_Region_Key__c = '920';
        INSERT oUser1;
        lUserIDS.add(oUser1.id);
        User oUser2 = SBR_3_0_TestDataFactory.createUser(FALSE,oProfile);
        oUser2.ManagerId = oUser1.id;
        oUser2.Analysis_Region_Key__c = '920';
        INSERT oUser2;
        lUserIDS.add(oUser2.id);
        User oUser3 = SBR_3_0_TestDataFactory.createUser(FALSE,oProfile);
        oUser3.ManagerId = oUser2.id;
        oUser3.Analysis_Region_Key__c = '920';
        INSERT oUser3;
        lUserIDS.add(oUser3.id);
        List<Account_Relationship__c> lAR =  SBR_3_0_TestDataFactory.createAccountRelationships(10,lAccounts[0].id,FALSE);
        for(Account_Relationship__c oAR : lAR){
            oAR.User_Account__c = oUser1.id;
        }
        INSERT lAR;
        for(Account_Relationship__c oAR : lAR){
        	lARIDS.add(oAR.id);    
        }
        System.runAs(oRunAsUser){
            Test.startTest();
            List<SBR_3_0_Invocable_ARAuthority.ARRequest> lRequest = new List<SBR_3_0_Invocable_ARAuthority.ARRequest>();
            SBR_3_0_Invocable_ARAuthority.ARRequest oRequest = new SBR_3_0_Invocable_ARAuthority.ARRequest();
            oRequest.ARIds = lARIDS;
            lRequest.add(oRequest);
            SBR_3_0_Invocable_ARAuthority.authenticateUserHierarchy(lRequest);
            Test.stopTest();
        }
    }
      public Static testMethod void authenticateUserHierarchyOneRecord(){
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_Invocable_ARAuthority_Test());
        Profile oProfile = [SELECT Id FROM Profile WHERE Name='System Administrator'];
		User oRunAsUser = SBR_3_0_TestDataFactory.createUser(TRUE,oProfile);
        list<Id> lARIDS = new list<Id>();
        list<Id> lUserIDS = new list<Id>();
        List<Account> lAccounts = SBR_3_0_TestDataFactory.createAccounts(1,TRUE,SBR_3_0_Constants.ACCOUNT_REC_TYPE_CREDIT);
        User oUser1 = SBR_3_0_TestDataFactory.createUser(FALSE,oProfile);
        oUser1.Analysis_Region_Key__c = '920';
        INSERT oUser1;
        lUserIDS.add(oUser1.id);
        User oUser2 = SBR_3_0_TestDataFactory.createUser(FALSE,oProfile);
        oUser2.ManagerId = oUser1.id;
        oUser2.Analysis_Region_Key__c = '920';
        INSERT oUser2;
        lUserIDS.add(oUser2.id);
        User oUser3 = SBR_3_0_TestDataFactory.createUser(FALSE,oProfile);
        oUser3.ManagerId = oUser2.id;
        oUser3.Analysis_Region_Key__c = '920';
        INSERT oUser3;
        lUserIDS.add(oUser3.id);
        List<Account_Relationship__c> lAR =  SBR_3_0_TestDataFactory.createAccountRelationships(1,lAccounts[0].id,FALSE);
        for(Account_Relationship__c oAR : lAR){
            oAR.User_Account__c = oUser1.id;
        }
        INSERT lAR;
        for(Account_Relationship__c oAR : lAR){
        	lARIDS.add(oAR.id);    
        }
        System.runAs(oRunAsUser){
            Test.startTest();
            List<SBR_3_0_Invocable_ARAuthority.ARRequest> lRequest = new List<SBR_3_0_Invocable_ARAuthority.ARRequest>();
            SBR_3_0_Invocable_ARAuthority.ARRequest oRequest = new SBR_3_0_Invocable_ARAuthority.ARRequest();
            oRequest.ARIds = lARIDS;
            lRequest.add(oRequest);
            SBR_3_0_Invocable_ARAuthority.authenticateUserHierarchy(lRequest);
            Test.stopTest();
        }
    }
      public Static testMethod void authenticateUserHierarchySales(){
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_Invocable_ARAuthority_Test());
        Profile oProfile = [SELECT Id FROM Profile WHERE Name='System Administrator'];
		User oRunAsUser = SBR_3_0_TestDataFactory.createUser(TRUE,oProfile);
        list<Id> lARIDS = new list<Id>();
        list<Id> lUserIDS = new list<Id>();
        List<Account> lAccounts = SBR_3_0_TestDataFactory.createAccounts(1,TRUE,SBR_3_0_Constants.ACCOUNT_REC_TYPE_CREDIT);
        User oUser6 = SBR_3_0_TestDataFactory.createUser(FALSE,oProfile);
        oUser6.Analysis_Region_Key__c = '920';
        INSERT oUser6;
        User oUser5 = SBR_3_0_TestDataFactory.createUser(FALSE,oProfile);
        oUser5.Analysis_Region_Key__c = '920';
        oUser5.ManagerId = oUser6.id;
        INSERT oUser5;
        User oUser4 = SBR_3_0_TestDataFactory.createUser(FALSE,oProfile);
        oUser4.Analysis_Region_Key__c = '920';
        oUser4.ManagerId = oUser5.id;
        INSERT oUser4;
        User oUser3 = SBR_3_0_TestDataFactory.createUser(FALSE,oProfile);
        oUser3.Analysis_Region_Key__c = '920';
        oUser3.ManagerId = oUser4.id;
        INSERT oUser3;
        User oUser2 = SBR_3_0_TestDataFactory.createUser(FALSE,oProfile);
        oUser2.ManagerId = oUser3.id;
        oUser2.Analysis_Region_Key__c = '920';
        INSERT oUser2;
        User oUser1 = SBR_3_0_TestDataFactory.createUser(FALSE,oProfile);
        oUser1.Analysis_Region_Key__c = '920';
        oUser1.ManagerId = oUser2.id;
        INSERT oUser1;
        lUserIDS.add(oUser1.id);
        lUserIDS.add(oUser2.id);
        lUserIDS.add(oUser3.id);
        List<Account_Relationship__c> lAR =  SBR_3_0_TestDataFactory.createAccountRelationships(1,lAccounts[0].id,FALSE);
        for(Account_Relationship__c oAR : lAR){
            oAR.User_Account__c = oUser1.id;
        }
        INSERT lAR;
        for(Account_Relationship__c oAR : lAR){
        	lARIDS.add(oAR.id);    
        }
        System.runAs(oRunAsUser){
            Test.startTest();
            List<SBR_3_0_Invocable_ARAuthority.ARRequest> lRequest = new List<SBR_3_0_Invocable_ARAuthority.ARRequest>();
            SBR_3_0_Invocable_ARAuthority.ARRequest oRequest = new SBR_3_0_Invocable_ARAuthority.ARRequest();
            oRequest.ARIds = lARIDS;
            oRequest.UserIds = lUserIDS;
            lRequest.add(oRequest);
            SBR_3_0_Invocable_ARAuthority.authenticateUserHierarchy(lRequest);
            Test.stopTest();
        }
    }


    /************************************************************* Cover authenticateUserHierarchy Ends*************************************************************/
    
}