/*********************************************************************************************************************
* Apex Class: SBR_3_0_GeneratePOPDF_Test
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Test Class for SBR_3_0_GeneratePOPDF
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         
---------------------------------------------------------------------------------------------------------------------------------------
Note:-
* 
*********************************************************************************************************************/
@isTest
public class SBR_3_0_GeneratePOPDF_Test {
    
    @TestSetup
    static void makeData(){
        Credential__c cred = SBR_3_0_TestDataFactory.createCredentials(1, false)[0];
        cred.Name      = 'Mule_Token_Endpoint';
        cred.Key_Id__c = 'testKey123';
        cred.Secret__c = 'secret';
        insert cred;

        // Create Account
        List<Account> Accs= new List<Account>();        
        Account acct =  SBR_3_0_ServiceTestDataFactory.createAccount(false,'33333');
        acct.E_mail_Address__c = '123@asdf.com';
        acct.Company_Code__c   = '01';
        acct.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Vendor').getRecordTypeId();
        acct.Email__c = 'test@test.com';
        Accs.add(acct);
        
        Account acct1 =  SBR_3_0_ServiceTestDataFactory.createAccount(false,'33334');
        acct1.Company_Code__c   = '01';
        acct1.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Vendor').getRecordTypeId();
        Accs.add(acct1);        
        insert Accs;        
        //PO with basic information
        List<Purchase_Order__c> pos= new List<Purchase_Order__c>();
        Purchase_Order__c po1 = new Purchase_Order__c();
        po1.Name = '887796990';
        po1.Vendor__c = acct.id;
        po1.RecordTypeId = Schema.SObjectType.Purchase_Order__c.getRecordTypeInfosByDeveloperName().get(SBR_3_0_GeneratePOPDFUtility.PURCHASEORDER_RECORDTYPE_STANDARD).getRecordTypeId();		   
        pos.add(po1);
        
        Purchase_Order__c po2 = new Purchase_Order__c();
        po2.Name = '887796991';
        po2.Vendor__c = acct.id;
        po2.RecordTypeId = Schema.SObjectType.Purchase_Order__c.getRecordTypeInfosByDeveloperName().get(SBR_3_0_GeneratePOPDFUtility.PURCHASEORDER_RECORDTYPE_RERENT).getRecordTypeId();
		pos.add(po2);
        
        Purchase_Order__c po3 = new Purchase_Order__c();
        po3.Name = '887796992';
        po3.Vendor__c = acct.id;
        po3.RecordTypeId = Schema.SObjectType.Purchase_Order__c.getRecordTypeInfosByDeveloperName().get(SBR_3_0_GeneratePOPDFUtility.PURCHASEORDER_RECORDTYPE_3RD).getRecordTypeId();
		pos.add(po3);
        
        Purchase_Order__c po4 = new Purchase_Order__c();
        po4.Name = '887796993';
        //po4.Vendor__c = acct1.id;
        po4.RecordTypeId = Schema.SObjectType.Purchase_Order__c.getRecordTypeInfosByDeveloperName().get(SBR_3_0_GeneratePOPDFUtility.PURCHASEORDER_RECORDTYPE_3RD).getRecordTypeId();
		pos.add(po4);
        insert pos;
    }

    @isTest
    public static void generatePDFCompleteFlowTest(){
        Purchase_Order__c po = [SELECT Id FROM Purchase_Order__c WHERE Name = '887796990' LIMIT 1];
        List<List<String>> data = new List<List<String>>();
        data.add(new List<String>{ po.Id, SBR_3_0_GeneratePOPDFUtility.EXECUTION_TYPE_FLOW} );
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_GeneratePOPDFController_Mock());
        Test.startTest();
            List<SBR_3_0_GeneratePOPDF.WrappedResponse> response = SBR_3_0_GeneratePOPDF.generatePDF(data);
            Assert.areEqual(SBR_3_0_GeneratePOPDFUtility.RESPONSE_STATUS_COMPLETE, response[0].status, 'PDF generated');
        Test.stopTest();
    }

    @isTest
    public static void generatePDFCompleteAuraTest(){
        Purchase_Order__c po = [SELECT Id FROM Purchase_Order__c WHERE Name = '887796990' LIMIT 1];
        List<List<String>> data = new List<List<String>>();
        data.add(new List<String>{ po.Id, SBR_3_0_GeneratePOPDFUtility.EXECUTION_TYPE_AURA, 'true'} );
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_GeneratePOPDFController_Mock());
        Test.startTest();
            List<SBR_3_0_GeneratePOPDF.WrappedResponse> response = SBR_3_0_GeneratePOPDF.generatePDF(data);
            Assert.areEqual(SBR_3_0_GeneratePOPDFUtility.RESPONSE_STATUS_COMPLETE, response[0].status, 'PDF generated');
            Assert.isNotNull(response[0].fileBody, 'PDF Body is not null');
        Test.stopTest();
    }

    @isTest
    public static void generatePDFCompleteAuraEmailFailTest(){
        Purchase_Order__c po = [SELECT Id FROM Purchase_Order__c WHERE Name = '887796992' LIMIT 1];
        List<List<String>> data = new List<List<String>>();
        data.add(new List<String>{ po.Id, SBR_3_0_GeneratePOPDFUtility.EXECUTION_TYPE_AURA, 'true'} );
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_GeneratePOPDFController_Mock());
        Test.startTest();
            List<SBR_3_0_GeneratePOPDF.WrappedResponse> response = SBR_3_0_GeneratePOPDF.generatePDF(data);
            Assert.areEqual(SBR_3_0_GeneratePOPDFUtility.RESPONSE_STATUS_INCOMPLETE, response[0].status, 'PDF generated but email not sent');
        Test.stopTest();
    }

    @isTest
    public static void generatePDFInProgressTest(){
        Purchase_Order__c po = [SELECT Id FROM Purchase_Order__c WHERE Name = '887796991' LIMIT 1];
        List<List<String>> data = new List<List<String>>();
        data.add(new List<String>{ po.Id, SBR_3_0_GeneratePOPDFUtility.EXECUTION_TYPE_FLOW} );
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_GeneratePOPDFController_Mock());
        Test.startTest();
            List<SBR_3_0_GeneratePOPDF.WrappedResponse> response = SBR_3_0_GeneratePOPDF.generatePDF(data);
            Assert.areEqual(SBR_3_0_GeneratePOPDFUtility.RESPONSE_STATUS_INPROGRESS, response[0].status, 'PDF Generation In Progress');
            Assert.areEqual('123456', response[0].repoId, 'Repo Id for Retrieve Call');
        Test.stopTest();
    }

    @isTest
    public static void generatePDFIncompleteTest(){
        Purchase_Order__c po = [SELECT Id FROM Purchase_Order__c WHERE Name = '887796992' LIMIT 1];
        List<List<String>> data = new List<List<String>>();
        data.add(new List<String>{ po.Id, SBR_3_0_GeneratePOPDFUtility.EXECUTION_TYPE_FLOW} );
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_GeneratePOPDFController_Mock());
        Test.startTest();
            List<SBR_3_0_GeneratePOPDF.WrappedResponse> response = SBR_3_0_GeneratePOPDF.generatePDF(data);
            Assert.areEqual(SBR_3_0_GeneratePOPDFUtility.RESPONSE_STATUS_INCOMPLETE, response[0].status, 'PDF generation failed');
        Test.stopTest();
    }

    @isTest
    public static void generatePDFEmailExceptionTest(){
        Purchase_Order__c po = [SELECT Id FROM Purchase_Order__c WHERE Name = '887796993' LIMIT 1];
        List<List<String>> data = new List<List<String>>();
        data.add(new List<String>{ po.Id, SBR_3_0_GeneratePOPDFUtility.EXECUTION_TYPE_AURA, 'true'} );
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_GeneratePOPDFController_Mock());
        Test.startTest();
            List<SBR_3_0_GeneratePOPDF.WrappedResponse> response = SBR_3_0_GeneratePOPDF.generatePDF(data);
            Assert.areEqual(SBR_3_0_GeneratePOPDFUtility.RESPONSE_STATUS_INCOMPLETE, response[0].status, 'Email not present');
            Assert.areEqual(System.Label.SBR_3_0_POPDFEmailError, response[0].errorMessage, 'Email not present');
        Test.stopTest();
    }

    @isTest
    public static void generatePDFExceptionTest(){
        Purchase_Order__c po = [SELECT Id FROM Purchase_Order__c WHERE Name = '887796990' LIMIT 1];
        List<List<String>> data = new List<List<String>>();
        data.add(new List<String>{ po.Id, SBR_3_0_GeneratePOPDFUtility.EXECUTION_TYPE_AURA, 'true'} );
        Test.startTest();
            try{
                List<SBR_3_0_GeneratePOPDF.WrappedResponse> response = SBR_3_0_GeneratePOPDF.generatePDF(data);
            }catch(Exception ex){}
        Test.stopTest();
    }
}