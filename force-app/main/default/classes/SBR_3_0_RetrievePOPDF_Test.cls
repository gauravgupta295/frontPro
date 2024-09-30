/*********************************************************************************************************************
* Apex Class: SBR_3_0_RetrievePOPDF_Test
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Test Class for SBR_3_0_RetrievePOPDF
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         
---------------------------------------------------------------------------------------------------------------------------------------
Note:-
* 
*********************************************************************************************************************/
@isTest
public class SBR_3_0_RetrievePOPDF_Test {
    
    @TestSetup
    static void makeData(){
        //Test.setMock(HttpCalloutMock.class, new SBR_3_0_GeneratePOPDFController_Mock());

        Credential__c cred = SBR_3_0_TestDataFactory.createCredentials(1, false)[0];
        cred.Name      = 'Mule_Token_Endpoint';
        cred.Key_Id__c = 'testKey123';
        cred.Secret__c = 'secret';
        insert cred;

        // Create Account
        Account acct =  SBR_3_0_ServiceTestDataFactory.createAccount(false,'33333');
        acct.E_mail_Address__c = '123@asdf.com';
        acct.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Vendor').getRecordTypeId();
        acct.Email__c = 'test@test.com'; 
        acct.Company_Code__c   = '01';
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

        Purchase_Order__c po3 = new Purchase_Order__c();
        po3.Name = '887796992';
        po3.Vendor__c = acct.id;
        po3.RecordTypeId = Schema.SObjectType.Purchase_Order__c.getRecordTypeInfosByDeveloperName().get(SBR_3_0_GeneratePOPDFUtility.PURCHASEORDER_RECORDTYPE_3RD).getRecordTypeId();
		pos.add(po3);
        insert pos;
    }

    @isTest
    public static void makeRequestCompleteTest(){
        Purchase_Order__c po = [SELECT Id FROM Purchase_Order__c WHERE Name = '887796990' LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_GeneratePOPDFController_Mock());
        Test.startTest();
            SBR_3_0_RetrievePOPDF.WrappedResponse response = SBR_3_0_RetrievePOPDF.makeRequest(new Map<String, Object>{
                'repoId'        => '123456',
                'endPoint'      => 'endpoint',
                'authToken'     => 'authToken',
                'purchaseOrderId'   => po.Id,
                'executionFrom' => SBR_3_0_GeneratePOPDFUtility.EXECUTION_TYPE_AURA,
                'sendEmail'     => true
            });
            Assert.areEqual(SBR_3_0_GeneratePOPDFUtility.RESPONSE_STATUS_COMPLETE, response.status, 'PDF generated');
            Assert.isNotNull(response.fileBody, 'PDF Body is not null');
        Test.stopTest();
    }

    @isTest
    public static void makeRequestCompleteEmailFailTest(){
        Purchase_Order__c po = [SELECT Id FROM Purchase_Order__c WHERE Name = '887796991' LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_GeneratePOPDFController_Mock());
        Test.startTest();
            SBR_3_0_RetrievePOPDF.WrappedResponse response = SBR_3_0_RetrievePOPDF.makeRequest(new Map<String, Object>{
                'repoId'        => '123458',
                'endPoint'      => 'endpoint',
                'authToken'     => 'authToken',
                'purchaseOrderId'   => po.Id,
                'executionFrom' => SBR_3_0_GeneratePOPDFUtility.EXECUTION_TYPE_AURA,
                'sendEmail'     => true
            });
            Assert.areEqual(SBR_3_0_GeneratePOPDFUtility.RESPONSE_STATUS_INCOMPLETE, response.status, 'PDF generated');
        Test.stopTest();
    }

    @isTest
    public static void makeRequestInProgressTest(){
        Purchase_Order__c po = [SELECT Id FROM Purchase_Order__c WHERE Name = '887796991' LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_GeneratePOPDFController_Mock());
        Test.startTest();
            SBR_3_0_RetrievePOPDF.WrappedResponse response = SBR_3_0_RetrievePOPDF.makeRequest(new Map<String, Object>{
                'repoId'        => '123457',
                'endPoint'      => 'endpoint',
                'authToken'     => 'authToken',
                'purchaseOrderId'   => po.Id,
                'executionFrom' => SBR_3_0_GeneratePOPDFUtility.EXECUTION_TYPE_AURA,
                'sendEmail'     => true
            });
            Assert.areEqual(SBR_3_0_GeneratePOPDFUtility.RESPONSE_STATUS_INPROGRESS, response.status, 'PDF is being generated');
        Test.stopTest();
    }

    @isTest
    public static void retrievePDFInProgressTest(){
        Purchase_Order__c po = [SELECT Id FROM Purchase_Order__c WHERE Name = '887796991' LIMIT 1];
        List<List<String>> data = new List<List<String>>();
        data.add(new List<String>{ '123457', 'endpoint', 'authToken', po.Id } );
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_GeneratePOPDFController_Mock());
        Test.startTest();
            List<SBR_3_0_RetrievePOPDF.WrappedResponse> response = SBR_3_0_RetrievePOPDF.retrievePDF(data);
            Assert.areEqual(SBR_3_0_GeneratePOPDFUtility.RESPONSE_STATUS_INPROGRESS, response[0].status, 'PDF is being generated');
        Test.stopTest();
    }

    @isTest
    public static void makeRequestIncompleteTest(){
        Purchase_Order__c po = [SELECT Id FROM Purchase_Order__c WHERE Name = '887796991' LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_GeneratePOPDFController_Mock());
        Test.startTest();
            SBR_3_0_RetrievePOPDF.WrappedResponse response = SBR_3_0_RetrievePOPDF.makeRequest(new Map<String, Object>{
                'repoId'        => '123458',
                'endPoint'      => 'endpoint',
                'authToken'     => 'authToken',
                'purchaseOrderId'   => po.Id,
                'executionFrom' => SBR_3_0_GenerateWOPDFUtility.EXECUTION_TYPE_AURA,
                'sendEmail'     => true
            });
            Assert.areEqual(SBR_3_0_GeneratePOPDFUtility.RESPONSE_STATUS_INCOMPLETE, response.status, 'Error during callout');
        Test.stopTest();
    }

    @isTest
    public static void retrievePDFExceptionTest(){
        Purchase_Order__c po = [SELECT Id FROM Purchase_Order__c WHERE Name = '887796991' LIMIT 1];
        List<List<String>> data = new List<List<String>>();
        data.add(new List<String>{ '123457', 'endpoint', 'authToken', po.Id } );
        Test.startTest();
            try{
                List<SBR_3_0_RetrievePOPDF.WrappedResponse> response = SBR_3_0_RetrievePOPDF.retrievePDF(data);
            } catch(Exception ex){}
        Test.stopTest();
    }
}