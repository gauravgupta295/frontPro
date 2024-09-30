/**
 * @description       : Test class for SBR_3_0_API_PickupTicket
 * @author            : Hashem Abdul
 * @group             : 
 * @last modified on  : 02-07-2024
 * @last modified by  : Hashem Abdul
**/
@isTest
public with sharing class SBR_3_0_API_PickupTicket_Test Implements HttpCalloutMock{
    static Id ordItemDetailId;

    @testSetup
    public static void makeData(){
		
        Profile pfl = [SELECT id FROM Profile WHERE Name='System Administrator'];
        User admin = SBR_3_0_TestDataFactory.createUser(true, pfl);
        
        Profile p = [SELECT Id FROM Profile WHERE Name='Sales'];
        //create ers user clone
        String ersUserName = 'ersuser' + DateTime.now().getTime() + '@SBRtestorg.com';
        User ersu = new User(Alias = 'ers', Email='ersuser@testorg.com',
        EmailEncodingKey='UTF-8', LastName='erstest', LanguageLocaleKey='en_US',
        LocaleSidKey='en_US', ProfileId = p.Id,
        TimeZoneSidKey='America/Los_Angeles',
        UserName=ersUserName);
        ersu.RepID__c = '1122';
        insert ersu;
        
		// Create Account
        Account acct = new Account();
        acct.RM_Account_Number__c = '12345';
        acct.Company_Code__c = '01';
        acct.Name = 'Test Account';
        acct.Record_Type_Text__c = 'Credit';
        acct.E_mail_Address__c = '123@asdf.com';
        acct.Phone = '1234567899';
        acct.BillingStreet = '123 Main Street';
        acct.BillingCity = 'Toronto';
        acct.BillingPostalCode = 'M9N7V5';
        acct.BillingState = 'ON';
        acct.BillingCountry = 'CA';
        acct.Drivers_License__c = 'AKF';
        acct.Driver_s_License_State__c = 'AL';
        insert acct;
        
        // Create Branch
        Schema.Location branchLocation = new Schema.Location();
        branchLocation.Branch_Location_Number__c = '1234';
        branchLocation.Name = 'Test Branch Location';
        branchLocation.Street_Address__c = '12 Main Street';
        branchLocation.City__c = 'Toronto';
        branchLocation.Zip_Code__c = 'M7N7B3';
        branchLocation.State__c = 'ON';
        branchLocation.Country__c = 'CA';
        branchLocation.Job_Number__c='332112';
        branchLocation.RecordTypeId = SBR_3_0_Constants.LOCATION_BRANCH_RT_ID;
        branchLocation.Company_Code__c = 'X';
        branchLocation.Time_Zone_Name__c = 'America/Chicago';
        branchLocation.Time_Zone__c = 3;
        insert branchLocation;
        
        Pricebook2 priceBook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update priceBook;
        
        List<Product2> products = new List<Product2>();
        for(Integer i = 0; i < 3; i++) {
            Product2 product = new Product2();
            product.Name = 'Test Product ' + i;
            if(i == 0) {
                product.Product_Type__c = 'Cat-Class';
                product.Product_SKU__c = '123001';
                product.Category__c = '32134';
                product.Class__c = '2039';
                product.ToolFlex__c = 'N';
            } else if (i == 1) {
                product.Product_Type__c = 'Parts';
                product.Item_Number__c = '1234GH';
                product.Stock_Class__c = 'AIMFV';
            } else {
                product.Product_Type__c = '';
                product.Item_Number__c = '1285JC';
                product.Stock_Class__c = 'UJEKL';
            }
            products.add(product);
        }
        insert products;

        // Create Price Book Entry
        List<PricebookEntry> listPbe = new List<PricebookEntry>();
        Map<Id, Id> mapPBE = new Map<Id, Id>();
        for(PricebookEntry pbEntry : [SELECT Id,Product2Id FROM PricebookEntry WHERE Pricebook2Id = :Test.getStandardPricebookId()]) {
            if(pbEntry.Product2Id == products[0].Id){
                mapPBE.put(pbEntry.Product2Id, pbEntry.Id);
            }
            else if(pbEntry.Product2Id == products[1].Id){
                mapPBE.put(pbEntry.Product2Id, pbEntry.Id);
            }
            else if(pbEntry.Product2Id == products[2].Id){
                mapPBE.put(pbEntry.Product2Id, pbEntry.Id);
            }
        }
        
        
        Order ord = new Order(
            Name = 'Test Order',
            RecordTypeId = SBR_3_0_Constants.ORDER_REC_TYPE_CONTRACT_ORDER_ID,
            Contract_Order_Number__c = '12345',
            AccountId = acct.Id,
            Sourcing_Branch__c = branchLocation.Id,
            Status = 'Open',
            Pricebook2Id = priceBook.Id,
            EffectiveDate = Date.today()
        );
        insert ord;

         // SBR_3_0_TestDataFactory.createCredentials(1, true);
         Credential__c c = new Credential__c();
         c.Name = 'Mule_Token_Endpoint';
         c.Environment__c = SBR_3_0_Constants.SANDBOX;
         c.Key_Id__c = 'Mule_Token_Endpoint';
         insert c;
     //Mule_Token_Endpoint
        List<PricebookEntry> pbEntries = new List<PricebookEntry>();
        for(Product2 prod: products){
            PricebookEntry stdPbe = new PricebookEntry();
            stdPbe.Pricebook2Id = Test.getStandardPricebookId();
            stdPbe.Product2Id =prod.Id;
            stdPbe.IsActive = true;
            stdPbe.UnitPrice = 20;
            pbEntries.add(stdPbe);
        }
        
        insert pbEntries;
        PricebookEntry pbEntry = [SELECT Id FROM PricebookEntry WHERE Product2Id =: products[0].Id];
        
        List<Contact> lstContacts = SBR_3_0_TestDataFactory.createContacts(1, acct.id, true);
        List<Product2> lstProds = SBR_3_0_TestDataFactory.createProducts(1, true);
        //List<Asset> lstAsssets = SBR_3_0_TestDataFactory.createAssets(1,false,relatedAccount.id,lstContacts[0].id, branchLocation.id);
        RecordType rt = [SELECT Id, DeveloperName, IsActive, Name, SobjectType FROM RecordType
        WHERE IsActive = true AND SobjectType = 'Asset' AND Name = 'Rental Asset' ];
        Asset newAsset = new Asset();
        newAsset.RecordTypeId = rt.Id;
        newAsset.AccountID = acct.id;
        newAsset.ContactID = lstContacts[0].id;
        newAsset.SM_PS_Current_Location__c = branchLocation.id;
        newAsset.SM_PS_Assigned_Location__c = branchLocation.id;
        newAsset.Status = 'SCHEDULED FOR PICKUP';
        newAsset.Name = '112233';
        newAsset.SM_PS_Company_Code__c = '12';
        newAsset.SM_PS_Cat_Class__c = '112233AHIFODIFHDFHDIOFIFHDSSSSCCIIFODSIII';
        newAsset.SM_PS_Last_Transaction_Date__c = Date.today();
        insert newAsset;
        
        OrderItem ordItem = new OrderItem(
            OrderId = ord.Id,
            Product2Id = products[0].Id,
            UnitPrice = 100,
            Quantity = 55,
            PricebookEntryId = pbEntry.Id,
            SBQQ__Asset__c = newAsset.id
        );
        insert ordItem;
        
    }

   
    public HTTPResponse respond(HTTPRequest req) {
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type',SBR_3_0_Constants.APP_JSON);
        if(req.getEndpoint().endsWithIgnoreCase('token')){
            // Access Token Response
            res.setBody('{"access_token":"test"}');
        }else if(req.getEndpoint().endsWithIgnoreCase('pickupticket')){
            // Rates Response here
            res.setBody('{ "data": { "pickupTicketNumber": "123456" } }');
        }
        res.setStatusCode(200);
        return res;
    }

    @isTest
    static void testGetPickupTicketNumber() {
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_PickupTicket_Test());
        Test.startTest(); 
        SBR_3_0_API_PickupTicket.PickupDetails pckUpDtls = new SBR_3_0_API_PickupTicket.PickupDetails();
        pckUpDtls.pickupDate = String.valueOf(Date.today());
        User reqByUser = [SELECT ID FROM User WHERE Email = 'ersuser@testorg.com' LIMIT 1];
        pckUpDtls.requestedById = reqByUser.Id;
        pckUpDtls.comments = 'Test';
        SBR_3_0_API_PickupTicket.Equipment eqp = new SBR_3_0_API_PickupTicket.Equipment();
        Asset ast = [SELECT ID, Name FROM Asset Where Name = '112233' LIMIT 1];
        OrderItem ordItm = [SELECT ID, SBQQ__Asset__c FROM OrderItem WHERE SBQQ__Asset__c =: ast.Id LIMIT 1];
        eqp.quantity = '1';
        eqp.equipmentNumber = ast.Name;
        eqp.lineItemId = ordItm.Id;
        pckUpDtls.equipments = new List<SBR_3_0_API_PickupTicket.Equipment>();
        pckUpDtls.equipments.add(eqp);
        String jsonReq = JSON.serialize(pckUpDtls);
        SBR_3_0_API_PickupTicket.getpickupTicketNumberNew(jsonReq);
        ordItm = [SELECT ID, Order_Item_Detail__c, SBQQ__Asset__c FROM OrderItem WHERE SBQQ__Asset__c =: ast.Id LIMIT 1];
        Order_Item_Detail__c ordDetail = [SELECT Id, Pickup_Ticket__c, Asset_Number__c FROM Order_Item_Detail__c WHERE Id =: ordItm.Order_Item_Detail__c];
        system.assert(ordItm.Order_Item_Detail__c <> NULL);
        system.assertEquals('123456', ordDetail.Pickup_Ticket__c);
        Test.stopTest();
        
    }
    @isTest
    static void testupdateOrderItemDetail() {
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_PickupTicket_Test());
        Test.startTest(); 
        SBR_3_0_API_PickupTicket.PickupDetails pckUpDtls = new SBR_3_0_API_PickupTicket.PickupDetails();
        pckUpDtls.pickupDate = String.valueOf(Date.today());
        User reqByUser = [SELECT ID FROM User WHERE Email = 'ersuser@testorg.com' LIMIT 1];
        pckUpDtls.requestedById = reqByUser.Id;
        pckUpDtls.comments = 'Test';
        SBR_3_0_API_PickupTicket.Equipment eqp = new SBR_3_0_API_PickupTicket.Equipment();
        Asset ast = [SELECT ID, Name FROM Asset Where Name = '112233' LIMIT 1];
        OrderItem ordItm = [SELECT ID, SBQQ__Asset__c FROM OrderItem WHERE SBQQ__Asset__c =: ast.Id LIMIT 1];
        eqp.quantity = '1';
        eqp.equipmentNumber = ast.Name;
        eqp.lineItemId = ordItm.Id;
        pckUpDtls.equipments = new List<SBR_3_0_API_PickupTicket.Equipment>();
        pckUpDtls.equipments.add(eqp);
        String jsonReq = JSON.serialize(pckUpDtls);
        SBR_3_0_API_PickupTicket.getpickupTicketNumberNew(jsonReq);
        ordItm = [SELECT ID, Order_Item_Detail__c, SBQQ__Asset__c,Status_Pick_Created_Qty__c FROM OrderItem WHERE SBQQ__Asset__c =: ast.Id LIMIT 1];
        Order_Item_Detail__c ordDetail = [SELECT Id, Pickup_Ticket__c, Asset_Number__c FROM Order_Item_Detail__c WHERE Id =: ordItm.Order_Item_Detail__c];
        ordDetail.Cancelled_Qty__c = 1;
        ordDetail.Created_Qty__c = 1;
        Database.update(ordDetail);
        system.assert(ordItm.Order_Item_Detail__c <> NULL);
        system.assertEquals(0, ordItm.Status_Pick_Created_Qty__c);
        Test.stopTest();
        
    }
}