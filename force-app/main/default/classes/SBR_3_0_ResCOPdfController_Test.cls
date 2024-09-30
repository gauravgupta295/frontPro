/*********************************************************************************************************************
* Apex Class: SBR_3_0_ResCOPdfController_Test
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Class to test SBR_3_0_ResContrctOrderPdfController
* - 
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Saathvik Tulasi      2023-01-11             Initial version    
*********************************************************************************************************************/
@isTest(seeAllData=false) 
public class SBR_3_0_ResCOPdfController_Test Implements HttpCalloutMock{
        @TestSetup
    static void makeData(){
        // Create Price Book
        Pricebook2 priceBook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update priceBook;
    }
    public HTTPResponse respond(HTTPRequest request) {
        // Create a fake response
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setBody('{"access_token":"test"}');
        response.setStatusCode(200);
        return response;
    }
    /************************************************************* Cover loadOrderFields Starts*************************************************************/
    public Static testMethod void loadOrderFields(){
		Profile oProfile = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User oUsers = SBR_3_0_TestDataFactory.createUser(TRUE,oProfile);
        System.runAs(oUsers){
            Test.startTest();
            Id ReservationOrderRTId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('Reservation_Order').getRecordTypeId();
            Order oOrder = SBR_3_0_TestDataFactory.createOrder(TRUE,'Test 1',ReservationOrderRTId);
            SBR_3_0_ResContrctOrderPdfController.loadOrderFields(oOrder.id);
            Test.stopTest();
        }
    }
    public Static testMethod void loadOrderFieldsContractOrder(){
		Profile oProfile = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User oUsers = SBR_3_0_TestDataFactory.createUser(TRUE,oProfile);
        System.runAs(oUsers){
            Test.startTest();
            Id ReservationOrderRTId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('Contract_Order').getRecordTypeId();
            Order oOrder = SBR_3_0_TestDataFactory.createOrder(FALSE,'Test 1',ReservationOrderRTId);
            oOrder.Contract_Order_Number__c = '12345';
            INSERT oOrder;
            SBR_3_0_ResContrctOrderPdfController.loadOrderFields(oOrder.id);
            //SBR_3_0_ResContrctOrderPdfController.loadOrderFields();
            Test.stopTest();
        }
    }
    public Static testMethod void loadOrderFieldsReservationOrderNumber(){
		Profile oProfile = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User oUsers = SBR_3_0_TestDataFactory.createUser(TRUE,oProfile);
        System.runAs(oUsers){
            Test.startTest();
            Id ReservationOrderRTId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('Reservation_Order').getRecordTypeId();
            Order oOrder = SBR_3_0_TestDataFactory.createOrder(FALSE,'Test 1',ReservationOrderRTId);
            oOrder.Reservation_Order_Number__c = '12345';
            INSERT oOrder;
            SBR_3_0_ResContrctOrderPdfController.loadOrderFields(oOrder.id);
            Test.stopTest();
        }
    }
    public Static testMethod void loadOrderFieldsRentalmanQuoteId(){
		Profile oProfile = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User oUsers = SBR_3_0_TestDataFactory.createUser(TRUE,oProfile);
        System.runAs(oUsers){
            Test.startTest();
            Id ReservationOrderRTId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('Reservation_Order').getRecordTypeId();
            Order oOrder = SBR_3_0_TestDataFactory.createOrder(FALSE,'Test 1',ReservationOrderRTId);
            oOrder.Rentalman_Quote_Id__c = '12345';
            INSERT oOrder;
            SBR_3_0_ResContrctOrderPdfController.loadOrderFields(oOrder.id);
            Test.stopTest();
        }
    }
    public Static testMethod void loadOrderFieldsNoRT(){
		Profile oProfile = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User oUsers = SBR_3_0_TestDataFactory.createUser(TRUE,oProfile);
        System.runAs(oUsers){
            Test.startTest();
            Id ReservationOrderRTId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('Canceled_Contract_Order').getRecordTypeId();
            Order oOrder = SBR_3_0_TestDataFactory.createOrder(FALSE,'Test 1',ReservationOrderRTId);
            INSERT oOrder;
            SBR_3_0_ResContrctOrderPdfController.loadOrderFields(oOrder.id);
            Test.stopTest();
        }
    }
    public Static testMethod void loadOrderFieldsNULL(){
		Profile oProfile = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User oUsers = SBR_3_0_TestDataFactory.createUser(TRUE,oProfile);
        System.runAs(oUsers){
            Test.startTest();
            Id ReservationOrderRTId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('Reservation_Order').getRecordTypeId();
            Order oOrder = SBR_3_0_TestDataFactory.createOrder(TRUE,'Test 1',ReservationOrderRTId);
            try{
            	SBR_3_0_ResContrctOrderPdfController.loadOrderFields(oOrder.id);
            }
            Catch(Exception e){
                
            }
            Test.stopTest();
        }
    }
	/************************************************************* Cover loadOrderFields Ends*************************************************************/
    /************************************************************* Cover buildRequest Starts*************************************************************/
    public Static testMethod void buildRequest(){
		Profile oProfile = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User oUsers = SBR_3_0_TestDataFactory.createUser(TRUE,oProfile);
        Credential__c cred = SBR_3_0_TestDataFactory.createCredentials(1, false)[0];
        cred.Name = 'Mule_Token_Endpoint';
        cred.Key_Id__c = 'testKey123';
        cred.Secret__c = 'secret';
        insert cred;
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_ResCOPdfController_Test());
        Map<String, Global_API_Settings__mdt> apiMap = SBR_3_0_APISettings.getAPIMap();
        System.debug(apiMap);
      	Global_API_Settings__mdt globalAPI = SBR_3_0_APISettings.getAPIDetails('AVS_Check');
        Id ReservationOrderRTId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('Reservation_Order').getRecordTypeId();
        Order oOrder = SBR_3_0_TestDataFactory.createOrder(TRUE,'Test 1',ReservationOrderRTId);
        System.runAs(oUsers){
            try{
            Test.startTest();
            String rentanlManId = '123';
            String companyCode = '01';
            String seqNum = '123';
            SBR_3_0_ResContrctOrderPdfController.buildRequest(rentanlManId,companyCode,seqNum);
            Test.stopTest();
            }catch(Exception ex){
                system.debug('Exception'+ex);
            }
        }
    }
	/************************************************************* Cover buildRequest Ends*************************************************************/
}