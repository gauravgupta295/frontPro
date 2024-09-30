/**
 * @description       : Test Class for SBR_3_0_OrderAssetController
 * @group             : 
 * @last modified on  : 02-05-2024
 * @last modified by  : Hashem Abdul
**/
@IsTest
public class SBR_3_0_OrderAssetController_Test {

    
    /**
    * Make Test Data
    **/
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
        ersu.RepID__c = '112233';
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
            RecordTypeId = SBR_3_0_Constants.ORDER_REC_TYPE_CONTRACT_ORDER_ID,
            Contract_Order_Number__c = '12345',
            AccountId = acct.Id,
            Sourcing_Branch__c = branchLocation.Id,
            Status = 'Open',
            Name = 'Test Order',
            EffectiveDate = Date.today()
        );
        insert ord;

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
        
        
        Order_Item_Detail__c ordItemDtl = new Order_Item_Detail__c(
            Line_Item__c = ordItem.Id,
            Service_Requested_Date__c = Datetime.now(),
            Pickup_Ticket_Requested_By__c = ersu.Id,
            Order_Item_Comments__c = 'Test Comment',
            Reason_Code__c = 'TR',
            Quantity__c = 5,
            Pickup_Ticket__c = '1234',
            Order_Type__c = 'ReturnOrder',
            Pickup_Requested_Date__c = System.today()
        );
        insert ordItemDtl;
        
        ordItem.Order_Item_Detail__c = ordItemDtl.id;
        update ordItem;
        
    }
    
    @isTest
    public static void testSetAssetstatus(){
        
        User admin = [SELECT Id FROM User WHERE Profile.Name='System Administrator' and isActive = true Limit 1];
        System.runAs(admin){
            Test.startTest();
            Datetime pickupDate = System.now();
            OrderItem ordItem = [SELECT id FROM OrderItem WHERE UnitPrice = 100 LIMIT 1];
            List<OrderItem> orderItemRecords = new List<OrderItem>();
            orderItemRecords.add(ordItem);
            String orderItemRecordsJson = JSON.serialize(orderItemRecords);
            SBR_3_0_OrderAssetController.orderItemRecord oir = new SBR_3_0_OrderAssetController.orderItemRecord();
            oir.Id = ordItem.id;
            oir.ticketNumber = '1234';
            SBR_3_0_OrderAssetController.SetAssetstatus(orderItemRecordsJson, 'pickupComment', pickupDate, admin.id );
            Test.stopTest();
            
        }
        
    }
    
    @isTest
    public static void testGetOrderDetailItems(){
        User admin = [SELECT Id FROM User WHERE Profile.Name='System Administrator' and isActive = true Limit 1];
        System.runAs(admin){
            Test.startTest();
            OrderItem ordItem = [SELECT id FROM OrderItem WHERE UnitPrice = 100 AND Quantity = 55 LIMIT 1];
            SBR_3_0_OrderAssetController.getOrderDetailItems(ordItem.id+'');
            Test.stopTest();
        }
        
    }
    
    @isTest
    public static void testCreateOrderItemDetail(){
        User admin = [SELECT Id FROM User WHERE Profile.Name='System Administrator' and isActive = true Limit 1];
        System.runAs(admin){
            Test.startTest();
            OrderItem ordItem = [SELECT id FROM OrderItem WHERE UnitPrice = 100 LIMIT 1];
            Asset ast = [SELECT Id FROM Asset WHERE Name='112233' LIMIT 1];
            Date pickupDate = System.today();
            SBR_3_0_OrderAssetController.CreateOrderItemDetail(ordItem.id+'', 'pickupComment', pickupDate, admin.id, ast.id+'', false );
            Test.stopTest();
        }
        
    }
}