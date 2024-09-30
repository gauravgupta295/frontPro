/*********************************************************************************************************************
* Apex Class: SBR_3_0_GeneratePOPDFController_Test
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Test class for Apex Class SBR_3_0_GeneratePOPDFController
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         
---------------------------------------------------------------------------------------------------------------------------------------
Note:-
* 
*********************************************************************************************************************/
@isTest
public with sharing class SBR_3_0_GeneratePOPDFController_Test{

    @TestSetup
    static void makeData(){
        Credential__c cred = SBR_3_0_TestDataFactory.createCredentials(1, false)[0];
        cred.Name      = 'Mule_Token_Endpoint';
        cred.Key_Id__c = 'testKey123';
        cred.Secret__c = 'secret';
        insert cred;

        // Create Account
        Account acct =  SBR_3_0_ServiceTestDataFactory.createAccount(false,'33333');
        acct.E_mail_Address__c = '123@asdf.com';
        acct.Company_Code__c   = '01';
        acct.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Vendor').getRecordTypeId();
        acct.Email__c = 'test@test.com';
        insert acct;

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
        
        //PO with basic information
        Purchase_Order__c po3 = new Purchase_Order__c();
        po3.Name = '887796992';
        po3.Vendor__c = acct.id;
        po3.RecordTypeId = Schema.SObjectType.Purchase_Order__c.getRecordTypeInfosByDeveloperName().get(SBR_3_0_GeneratePOPDFUtility.PURCHASEORDER_RECORDTYPE_3RD).getRecordTypeId();
		pos.add(po3);
        insert pos;
    }

    @isTest
    public static void generatePDFCompleteTest(){
        Purchase_Order__c po = [SELECT Id FROM Purchase_Order__c WHERE Name = '887796990' LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_GeneratePOPDFController_Mock());
        Test.startTest();
            String response = SBR_3_0_GeneratePOPDFController.generatePDF(po.Id, true);
            SBR_3_0_GeneratePOPDF.WrappedResponse responseWrapper = (SBR_3_0_GeneratePOPDF.WrappedResponse)JSON.deserialize(response, SBR_3_0_GeneratePOPDF.WrappedResponse.class);
            Assert.areEqual(SBR_3_0_GeneratePOPDFUtility.RESPONSE_STATUS_COMPLETE, responseWrapper.status, 'PDF generated');
            Assert.isNotNull(responseWrapper.fileBody, 'PDF Body is not null');
        Test.stopTest();
    }

    @isTest
    public static void generatePDFCompleteEmailFailTest(){
        Purchase_Order__c po = [SELECT Id FROM Purchase_Order__c WHERE Name = '887796992' LIMIT 1];
        po.vendor__c = null;
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_GeneratePOPDFController_Mock());
        Test.startTest();
            String response = SBR_3_0_GeneratePOPDFController.generatePDF(po.Id, true);
            SBR_3_0_GeneratePOPDF.WrappedResponse responseWrapper = (SBR_3_0_GeneratePOPDF.WrappedResponse)JSON.deserialize(response, SBR_3_0_GeneratePOPDF.WrappedResponse.class);
            Assert.areEqual(SBR_3_0_GeneratePOPDFUtility.RESPONSE_STATUS_INCOMPLETE, responseWrapper.status, 'PDF generated but email not sent');
        Test.stopTest();
    }

    @isTest
    public static void generatePDFInProgressTest(){
        Purchase_Order__c po = [SELECT Id FROM Purchase_Order__c WHERE Name = '887796991' LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_GeneratePOPDFController_Mock());
        Test.startTest();
            String response = SBR_3_0_GeneratePOPDFController.generatePDF(po.Id, true);
            SBR_3_0_GeneratePOPDF.WrappedResponse responseWrapper = (SBR_3_0_GeneratePOPDF.WrappedResponse)JSON.deserialize(response, SBR_3_0_GeneratePOPDF.WrappedResponse.class);
            Assert.areEqual(SBR_3_0_GeneratePOPDFUtility.RESPONSE_STATUS_INPROGRESS, responseWrapper.status, 'PDF Generation In Progress');
            Assert.areEqual('123456', responseWrapper.repoId, 'Repo Id for Retrieve Call');
        Test.stopTest();
    }

    @isTest
    public static void generatePDFIncompleteTest(){
        Purchase_Order__c po = [SELECT Id FROM Purchase_Order__c WHERE Name = '887796992' LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_GeneratePOPDFController_Mock());
        Test.startTest();
            String response = SBR_3_0_GeneratePOPDFController.generatePDF(po.Id, true);
            SBR_3_0_GeneratePOPDF.WrappedResponse responseWrapper = (SBR_3_0_GeneratePOPDF.WrappedResponse)JSON.deserialize(response, SBR_3_0_GeneratePOPDF.WrappedResponse.class);
            Assert.areEqual(SBR_3_0_GeneratePOPDFUtility.RESPONSE_STATUS_INCOMPLETE, responseWrapper.status, 'PDF generation failed');
        Test.stopTest();
    }

    @isTest
    public static void generatePDFExceptionTest(){
        Purchase_Order__c po = [SELECT Id FROM Purchase_Order__c WHERE Name = '887796992' LIMIT 1];
        Test.startTest();
            try{
                String response = SBR_3_0_GeneratePOPDFController.generatePDF(po.Id, null);
            }catch(Exception ex){}
        Test.stopTest();
    }

    @isTest
    public static void retrievePDFCompleteTest(){
        Purchase_Order__c po = [SELECT Id FROM Purchase_Order__c WHERE Name = '887796990' LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_GeneratePOPDFController_Mock());
        Test.startTest();
            Map<String, Object> data = new Map<String, Object>{
                'repoId'=>'123456',
                'endPoint'=>'endpoint',
                'authToken'=> 'Bearer accesstoken',
                'purchaseOrderId'=> po.Id,
                'executionFrom'=> SBR_3_0_GeneratePOPDFUtility.EXECUTION_TYPE_AURA,
                'sendEmail'=> TRUE
            };
                System.debug('AAA='+JSON.serialize(data));
            String response = SBR_3_0_GeneratePOPDFController.retrievePDF(JSON.serialize(data));
            SBR_3_0_RetrievePOPDF.WrappedResponse responseWrapper = (SBR_3_0_RetrievePOPDF.WrappedResponse)JSON.deserialize(response, SBR_3_0_RetrievePOPDF.WrappedResponse.class);
            Assert.areEqual(SBR_3_0_GeneratePOPDFUtility.RESPONSE_STATUS_COMPLETE, responseWrapper.status, 'PDF generated');
            Assert.isNotNull(responseWrapper.fileBody, 'PDF Body is not null');
        Test.stopTest();
    }

    @isTest
    public static void retrievePDFExceptionTest(){
        Purchase_Order__c po = [SELECT Id FROM Purchase_Order__c WHERE Name = '887796992' LIMIT 1];
        Test.startTest();
            try{
                Map<String, Object> data = new Map<String, Object>{
                    'repoId'        => '123456',
                    'endPoint'      => 'endpoint',
                    'authToken'     => 'Bearer accesstoken',
                    'purchaseOrderId'   => po.Id,
                    'executionFrom' => SBR_3_0_GeneratePOPDFUtility.EXECUTION_TYPE_AURA,
                    'sendEmail'     => true
                };
                String response = SBR_3_0_GeneratePOPDFController.retrievePDF(JSON.serialize(data));
            } catch(Exception ex){}
        Test.stopTest();
    }
}