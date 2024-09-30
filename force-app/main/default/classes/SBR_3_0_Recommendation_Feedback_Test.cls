@isTest(seeAllData=false) 
public class SBR_3_0_Recommendation_Feedback_Test Implements HttpCalloutMock {
	public HTTPResponse respond(HTTPRequest oRequest) {
        HttpResponse oResponse = new HttpResponse();
        oResponse.setHeader('Content-Type',SBR_3_0_Constants.APP_JSON);
        System.debug('oRequest.getEndpoint()'+oRequest.getEndpoint());
        if(oRequest.getEndpoint() == 'callout:Product_Recommendation_Feedback_Callout'){
            System.debug('feedback : '+oRequest.getEndpoint());
            String JSONFeedback = '{"data":{"message":"Feedback created successfully"}}';
            oResponse.setBody(JSONFeedback);
            oResponse.setStatusCode(201);
        }
        else{
            System.debug('token');
            oResponse.setBody('{"token_type":"Bearer","expires_in":900,"access_token":"eyJraWQiOiI1Vk9qbHFHM2RiWktxX0RGQkJ6WEVVV0xWMU1hMGhVMEJhWWE5cm1LRzcwIiwiYWxnIjoiUlMyNTYifQ.eyJ2ZXIiOjEsImp0aSI6IkFULnR4VW1BbS1PZFhLQzNWZVJmLU03ckx0NjBHYVZjRGNSVGE5cnNETk8taTAiLCJpc3MiOiJodHRwczovL2xvZ2lucHJldmlldy5zdW5iZWx0cmVudGFscy5jb20vb2F1dGgyL2F1czFsZjMyMjZ6N1ZwekF0MWQ3IiwiYXVkIjoiaHR0cHM6Ly93d3cuc3VuYmVsdHJlbnRhbHMuY29tL29rdGEvdmVuZG9ycyIsImlhdCI6MTY5MDIwNjY2OSwiZXhwIjoxNjkwMjA3NTY5LCJjaWQiOiIwb2E0NDA0eDJxdmplWmtKcDFkNyIsInNjcCI6WyJNdWxlc29mdCJdLCJzdWIiOiIwb2E0NDA0eDJ","scope":"Mulesoft"}');
            oResponse.setStatusCode(200);
        }
        return oResponse;
    }
    /************************************************************* Cover SBR_3_0_Recommendation_Feedback_Cleanup Starts*************************************************************/
	public Static testMethod void SBR_3_0_Recommendation_Feedback_Cleanup(){
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_Recommendation_Feedback_Test());
        Profile oProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
		User oRunAsUser = SBR_3_0_TestDataFactory.createUser(FALSE,oProfile);
        oRunAsUser.RepID__c = '1234';
        INSERT oRunAsUser;
        Credential__c cred = SBR_3_0_TestDataFactory.createCredentials(1, false)[0];
        cred.Name = 'Mule_Token_Endpoint';
        cred.Key_Id__c = 'keyid';
        cred.Secret__c ='credSecret';
        insert cred;
        list<Account> lAccount = SBR_3_0_TestDataFactory.createAccounts(1,FALSE);
        lAccount[0].Company_Code__c = '01';
        lAccount[0].RM_Account_Number__c = '01-0030';
        INSERT lAccount;
        List<Account_Relationship__c> lAR = SBR_3_0_TestDataFactory.createAccountRelationships(10,lAccount[0].id,FALSE);
        User oUser = SBR_3_0_TestDataFactory.createUser(FALSE,oProfile);
        oUser.Analysis_Region_Key__c = '920';
        oUser.CompanyName = '1234';
        INSERT oUser;
        Product_Recommendation_Feedback__c oFeedback = new Product_Recommendation_Feedback__c();
        oFeedback.Cat_Class_Key__c = '007-0030';
        oFeedback.Feedback_Type__c = 'good';
        oFeedback.Name = '007-0030_'+lAccount[0].RM_Account_Number_Display__c+'_'+oRunAsUser.RepID__c;
        oFeedback.Model_Version__c = '28.0';
        oFeedback.Description__c = 'Test';
        oFeedback.Category__c = 'Test';
        oFeedback.Additional_comments__c = 'Test';
        oFeedback.Account_number__c = '1234';
        oFeedback.Rep_ID__c = oRunAsUser.RepID__c;
        oFeedback.Company_Code__c = Integer.valueOf(lAccount[0].Company_Code__c);
        oFeedback.Rep_Type__c = oRunAsUser.Rep_Type__c;
        oFeedback.User__c = oRunAsUser.id;
        oFeedback.Account__c= lAccount[0].id;
        INSERT oFeedback;
        Test.setCreatedDate(oFeedback.Id, System.Now().addDays(-190));
        System.runAs(oRunAsUser){
            Test.startTest();
            SBR_3_0_Recommendation_Feedback_Cleanup BC = new SBR_3_0_Recommendation_Feedback_Cleanup();
			Database.executeBatch(BC);
			Test.stopTest();
        }
    }    
    public Static testMethod void SBR_3_0_Recommendation_Feedback_Cleanup_Single(){
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_Recommendation_Feedback_Test());
        Profile oProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
		User oRunAsUser = SBR_3_0_TestDataFactory.createUser(FALSE,oProfile);
        oRunAsUser.RepID__c = '1234';
        INSERT oRunAsUser;
        Credential__c cred = SBR_3_0_TestDataFactory.createCredentials(1, false)[0];
        cred.Name = 'Mule_Token_Endpoint';
        cred.Key_Id__c = 'keyid';
        cred.Secret__c ='credSecret';
        insert cred;
        list<Account> lAccount = SBR_3_0_TestDataFactory.createAccounts(1,FALSE);
        lAccount[0].Company_Code__c = '01';
        lAccount[0].RM_Account_Number__c = '01-0030';
        INSERT lAccount;
        List<Account_Relationship__c> lAR = SBR_3_0_TestDataFactory.createAccountRelationships(10,lAccount[0].id,FALSE);
        User oUser = SBR_3_0_TestDataFactory.createUser(FALSE,oProfile);
        oUser.Analysis_Region_Key__c = '920';
        oUser.CompanyName = '1234';
        INSERT oUser;
        Product_Recommendation_Feedback__c oFeedback = new Product_Recommendation_Feedback__c();
        oFeedback.Cat_Class_Key__c = '007-0030';
        oFeedback.Feedback_Type__c = 'good';
        oFeedback.Name = '007-0030_'+lAccount[0].RM_Account_Number_Display__c+'_'+oRunAsUser.RepID__c;
        oFeedback.Model_Version__c = '28.0';
        oFeedback.Description__c = 'Test';
        oFeedback.Category__c = 'Test';
        oFeedback.Additional_comments__c = 'Test';
        oFeedback.Account_number__c = '1234';
        oFeedback.Rep_ID__c = oRunAsUser.RepID__c;
        oFeedback.Company_Code__c = Integer.valueOf(lAccount[0].Company_Code__c);
        oFeedback.Rep_Type__c = oRunAsUser.Rep_Type__c;
        oFeedback.User__c = oRunAsUser.id;
        oFeedback.Account__c= lAccount[0].id;
        INSERT oFeedback;
        Test.setCreatedDate(oFeedback.Id, System.Now().addDays(-190));
        System.runAs(oRunAsUser){
            Test.startTest();
            SBR_3_0_Recommendation_Feedback_Cleanup BC = new SBR_3_0_Recommendation_Feedback_Cleanup(oFeedback.id);
			Database.executeBatch(BC);
			Test.stopTest();
        }
    }    
    /************************************************************* Cover SBR_3_0_Recommendation_Feedback_Cleanup Ends*************************************************************/
}