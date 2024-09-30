/**
 * @description Test class for SBR_3_0_SalesHelper
 */
@isTest
private class SBR_3_0_SalesHelper_Test {
    
    @TestSetup
    static void makeData(){
        List<Account> acc = SBR_3_0_TestDataFactory.createAccounts(1,false,null);
        acc[0].Company_Code__c = '01';
        insert acc;

        Contact con = SBR_3_0_TestDataFactory.createContacts(1, acc[0].Id, true)[0];

        List<Schema.Location> branches = SBR_3_0_TestDataFactory.createLocations(1, True, SBR_3_0_Constants.LOCATION_REC_TYPE_BRANCH);
        Id branchId = branches[0].Id;
        List<Schema.Location> jobLocations = SBR_3_0_TestDataFactory.createLocations(1, True, SBR_3_0_Constants.LOCATION_REC_TYPE_JOB_LOC);
        Id jobLocationId = jobLocations[0].Id;
        List<AssociatedLocation> assLocation = SBR_3_0_TestDataFactory.createAssociatedLocations(1, acc[0].id, branchId, jobLocationId, true);
         // Create Price Book
        Pricebook2 priceBook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update priceBook;
        system.debug('priceBook::'+priceBook);
         // Create Job Site
        AssociatedLocation jobSite = new AssociatedLocation(
            Name__c = 'Test Job Site',
            ParentRecordId = acc[0].Id,
            LocationId = jobLocations[0].Id,
            Branch__c = branches[0].Id, 
            Job_Number__c = '20221004A'
        );
        insert jobSite;
       
       
        // Create Product
        List<Product2> products = new List<Product2>();
        for(Integer i = 0; i < 3; i++) {
            Product2 product = new Product2();
            product.Name = 'Test Product ' + i;
            if(i == 0) {
                product.Product_Type__c = 'Cat-Class';
                product.Product_SKU__c = '123456';
                product.Category__c = '32134';
                product.Class__c = '2039';
                product.ToolFlex__c = 'N';
                product.Company_code__c ='01';
                product.isSerialized = true;
                product.Stock_class__c = '';
                product.Bulk_Item__c=false;
                product.Status__c='A';
            } else if (i == 1) {
                product.Product_Type__c = 'Parts';
                product.Item_Number__c = '1234GH';
                product.Company_code__c ='01';
                product.Stock_Class__c = 'AIMFV';
                product.isSerialized = true;
            } else {
                product.Product_Type__c = '';
                product.Item_Number__c = '1285JC';
                product.Company_code__c ='01';
                product.Stock_Class__c = 'UJEKL';
            }
            products.add(product);
        }
        insert products;

        List<PricebookEntry> pbEntries = new List<PricebookEntry>();
        for(Product2 p1 : products) {
            PricebookEntry pbe = new PricebookEntry(Product2Id = p1.Id, IsActive = true, Pricebook2Id = Test.getStandardPricebookId(), UnitPrice = 100, currencyISOCode = 'USD');
            pbEntries.add(pbe);
        }
        insert pbEntries;
        
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

         // Create Order
         Order order = new Order(
            Quote_Name__c = 'Test Quote',
            AccountId = acc[0].Id,
            Jobsite__c = jobSite.Id,
            branch__c = branches[0].id,
            Deliverymethod__c = 'Delivery',
            Status = 'Draft',
            Pricebook2Id = priceBook.Id,
            Start_Date__c = date.valueOf('2022-10-07 12:00:00'),
            EffectiveDate = date.valueOf('2022-10-07 12:00:00'),
            EndDate = date.valueOf('2022-10-08 8:00:00'),
            Earliest_Delivery_Date__c = date.valueOf('2022-09-06 12:00:00'),
            Opt_Out_RPP__c = false,
            Opt_Out_Fuel_Charge__c = false,
            Selling_Channel__c = 'SBRB2B',
            Duration__c = 'Custom',
            Company_Code__c = '01',
            currencyISOCode = pbEntries[0].currencyISOCode
        );
        insert order;
        
        List<OrderItem> orderItems = new List<OrderItem>();
        OrderItem orderItem = new OrderItem();
        orderItem.OrderId = order.Id;
        orderItem.Product2Id = products[0].Id;
        orderItem.UnitPrice = 100;
        orderItem.Item_Number__c = 0;
        orderItem.PricebookEntryId = mapPBE.get(products[0].Id);        
        orderItem.Hourly_Rate__c = 2.0;
        orderItem.Min_Rate__c = 0;
        orderItem.Quantity = 5;
        orderItem.Free_Flag__c = false;
        orderItem.Suggested_Daily_Rate__c = 2.0;
        orderItem.Suggested_Weekly_Rate__c = 2.0;
        orderItem.Suggested_Monthly_Rate__c = 2.0;
        orderItem.Daily_Rate__c = 2.0;
        orderItem.Weekly_Rate__c = 4.0;
        orderItem.Monthly_Rate__c = 6.0;
        orderItem.Rates_Overriden__c = false;
        orderItems.add(orderItem);
        insert orderItems;
       
    
     }
    @isTest
    static void createJobLocFromShippingAddrTest(){
        List<Account> acc = [Select id,BillingCity,BillingState,BillingPostalCode,BillingCountry,
                             ShippingCity,ShippingState,ShippingPostalCode,BillingStreet,
                             ShippingCountry,ShippingStreet,ShippingLatitude,ShippingLongitude,BillingLatitude,
                             BillingLongitude, Override_Address__Street__s, Override_Address__City__s, Override_Address__Statecode__s, Override_Address__PostalCode__s,
                             Override_Address__Countrycode__s, Override_Address__Latitude__s,
                             Override_Address__Longitude__s from Account];
        acc[0].BillingStreet = '120 Sutton Ridge Ln';
        acc[0].BillingCity = 'Fort Mill';
        acc[0].BillingState = 'SC';
        acc[0].BillingPostalCode = '29708 ';
        acc[0].BillingCountry = 'US';
        update acc[0];
        List<Schema.Location> branch = [Select id from location];
        List<Schema.Location> Joblocation = [Select id from location];
        String branchId = branch[0].id;
        String locId = Joblocation[0].id;
        SBR_3_0_ContactWrap  conWrap = new SBR_3_0_ContactWrap();
        conWrap.email = 'test123@test.com';
        conWrap.firstName = 'Test';
        conWrap.lastName = 'check';
        conWrap.phone = '1234567898';
        Contact con = [Select Id, firstname, lastname, phone, email from contact limit 1];
        Test.startTest();
        Schema.Location createJobLocShip = SBR_3_0_SalesHelper.createJobLocFromShippingAddr(acc[0]);
        Schema.Location createJobLocShipWithNullAcc = SBR_3_0_SalesHelper.createJobLocFromShippingAddr(null);
        Schema.Location createBillingAddr = SBR_3_0_SalesHelper.createJobLocFromBillingAddr(acc[0]);
        Schema.Location createBillingAddrNull = SBR_3_0_SalesHelper.createJobLocFromShippingAddr(null);
        AssociatedLocation assLoc = SBR_3_0_SalesHelper.createJoSiteFromShippingAddr(acc[0],locId,branchId);
        AssociatedLocation jobSiteBill = SBR_3_0_SalesHelper.createJoSiteFromBillingAddr(acc[0],locId,branchId);
        AssociatedLocation jobSiteAddr = SBR_3_0_SalesHelper.createJoSiteFromAddress(new SBR_3_0_WrapAddress(),acc[0].Id,locId,branchId);
        AssociatedLocation jobSiteShip = SBR_3_0_SalesHelper.createJoSiteFromShippingAddr(null,locId,branchId);
        Schema.Location jobBilling = SBR_3_0_SalesHelper.createJobLocFromBillingAddr(null);
        SBR_3_0_WrapAddress useThisAddr = new SBR_3_0_WrapAddress();
        Schema.Location JobLoc = SBR_3_0_SalesHelper.createJobLocFromAddress(useThisAddr);
        Contact c = SBR_3_0_SalesHelper.findOrCreateContact(conWrap, useThisAddr,acc[0] );
        conWrap.email = con.Email;
        conWrap.firstName = con.firstName;
        conWrap.lastName = con.lastName;
        conWrap.phone = con.phone;
        c = SBR_3_0_SalesHelper.findOrCreateContact(conWrap, useThisAddr,acc[0] );
        Test.stopTest();
        System.assertEquals(acc.size(), 1, 'Account size');
    }
    
    @isTest
    static void getSalesHelperTest(){
        List<Account> acc1 = [Select id,BillingCity,BillingState,BillingPostalCode,BillingCountry,
                             ShippingCity,ShippingState,ShippingPostalCode,BillingStreet,
                             ShippingCountry,ShippingStreet,ShippingLatitude,ShippingLongitude,BillingLatitude,
                             BillingLongitude from Account];
        acc1[0].BillingStreet = '120 Sutton Ridge Ln';
        acc1[0].BillingCity = 'Fort Mill';
        acc1[0].BillingState = 'SC';
        acc1[0].BillingPostalCode = '29708 ';
        acc1[0].BillingCountry = 'US';
        update acc1[0];
        
        Test.startTest();
        SBR_3_0_SalesHelper.isAddressComplete(acc1[0]);
        SBR_3_0_WrapAddress WrapAccShipAddress = SBR_3_0_SalesHelper.WrapAccountShippingAddress(acc1[0]);
        SBR_3_0_WrapAddress WrapAccBillAddress = SBR_3_0_SalesHelper.WrapAccountBillingAddress(acc1[0]);
        Boolean isAddressComplete1 = SBR_3_0_SalesHelper.isBillingAddressComplete(acc1[0]);
        Order order = [SELECT Id, EndDate FROM Order];
        Product2 products =  [SELECT Id FROM Product2 WHERE Product_Type__c = 'Cat-Class'];
        PricebookEntry pbEntry = [SELECT Id,Product2Id FROM PricebookEntry 
                                  WHERE Pricebook2Id = :Test.getStandardPricebookId() 
                                  AND Product2Id = :products.Id LIMIT 1];
        List<OrderItem> orderItem = [Select id,OrderId,Product2Id,UnitPrice,Item_Number__c,
                                     PricebookEntryId,Hourly_Rate__c,Min_Rate__c,Weekly_Rate__c from OrderItem];
        Set<String> getSerialized = SBR_3_0_SalesHelper.getSerializedProducts(orderItem);
        Test.stopTest();
        System.assertEquals(acc1.size(), 1, 'Account size');
    }
    
    @isTest
    static void createAddressTruncation(){
        List<Account> acc = [Select id,BillingCity,BillingState,BillingPostalCode,BillingCountry,
                             ShippingCity,ShippingState,ShippingPostalCode,BillingStreet,
                             ShippingCountry,ShippingStreet,ShippingLatitude,ShippingLongitude,BillingLatitude,
                             BillingLongitude, Override_Address__Street__s, Override_Address__City__s, Override_Address__Statecode__s, Override_Address__PostalCode__s,
                             Override_Address__Countrycode__s, Override_Address__Latitude__s,
                             Override_Address__Longitude__s from Account];
        acc[0].ShippingStreet = '2222222222222222222222222222221111111111111111111111111111110000000000000000000000000000000000000000';
        acc[0].BillingStreet = '111111111111111111111111111111222222222222222222222222222222333333333333333333334444444444444444444444444444445555555555';
        acc[0].BillingCity = 'Fort Mill';
        acc[0].BillingState = 'SC';
        acc[0].BillingPostalCode = '29708 ';
        acc[0].BillingCountry = 'US';
        update acc[0];
        
        List<Schema.Location> branch = [Select id from location];
        List<Schema.Location> Joblocation = [Select id from location];
        String branchId = branch[0].id;
        String locId = Joblocation[0].id;
        SBR_3_0_ContactWrap  conWrap = new SBR_3_0_ContactWrap();
        conWrap.email = 'test123@test.com';
        conWrap.firstName = 'Test';
        conWrap.lastName = 'check';
        conWrap.phone = '1234567898';
        Contact con = [Select Id, firstname, lastname, phone, email from contact limit 1];
        Test.startTest();
        
        Schema.Location createJobLocShip = SBR_3_0_SalesHelper.createJobLocFromShippingAddr(acc[0]);
        Schema.Location createBillingAddr = SBR_3_0_SalesHelper.createJobLocFromBillingAddr(acc[0]);
        AssociatedLocation assLoc = SBR_3_0_SalesHelper.createJoSiteFromShippingAddr(acc[0],locId,branchId);
        AssociatedLocation jobSiteBill = SBR_3_0_SalesHelper.createJoSiteFromBillingAddr(acc[0],locId,branchId);
        
        SBR_3_0_WrapAddress addrWrapper = new SBR_3_0_WrapAddress();
        addrWrapper.street1 = '99999999999999999999999999999988888888888888888888888888888888888888888888888888777';
        addrWrapper.street2 = '99999999999999999999999999999988888888888888888888888888888888888888888888888888';
        
        Schema.Location locFromAddr = SBR_3_0_SalesHelper.createJobLocFromAddress(addrWrapper);
        AssociatedLocation jobSiteAddr = SBR_3_0_SalesHelper.createJoSiteFromAddress(addrWrapper,acc[0].Id,locId,branchId);
        
        
        
        Test.stopTest();
        
        System.assertEquals('222222222222222222222222222222', assLoc.Street_Address__c, 'job site from shipping address, street 1 did not match expected value');
        System.assertEquals('111111111111111111111111111111', assLoc.Street_Address_2__c, 'job site from shipping address, street 2 did not match expected value');
        System.assertEquals('111111111111111111111111111111', jobSiteBill.Street_Address__c, 'job site from billing address, street 1 did not match expected value');
        System.assertEquals('222222222222222222222222222222', jobSiteBill.Street_Address_2__c, 'job site from billing address, street 2 did not match expected value');
        
        System.assertEquals('11111111111111111111111111111122222222222222222222222222222233333333333333333333', createBillingAddr.Street_Address__c, 'location from billing address, street 1 did not match expected value');
        System.assertEquals('444444444444444444444444444444', createBillingAddr.Street_Address_2__c, 'location from billing address, street 2 did not match expected value');
        System.assertEquals('22222222222222222222222222222211111111111111111111111111111100000000000000000000', createJobLocShip.Street_Address__c, 'location from shipping address, street 1 did not match expected value');
        System.assertEquals('00000000000000000000', createJobLocShip.Street_Address_2__c, 'location from shipping address, street 2 did not match expected value');
    
    	System.assertEquals('999999999999999999999999999999', jobSiteAddr.Street_Address__c, 'job site from addr wrapper, street 1 did not match expected value.');
        System.assertEquals('999999999999999999999999999999', jobSiteAddr.Street_Address_2__c, 'job site from addr wrapper, street 2 did not match expected value.');
        
        System.assertEquals('99999999999999999999999999999988888888888888888888888888888888888888888888888888', locFromAddr.Street_Address__c, 'location from addr wrapper, street 1 did not match expected value.');
        System.assertEquals('999999999999999999999999999999', locFromAddr.Street_Address_2__c, 'location from addr wrapper, street 2 did not match expected value.');
        
    }
    
    @isTest
    static void createAddressTruncationWithNullStreets(){
        List<Account> acc = [Select id,BillingCity,BillingState,BillingPostalCode,BillingCountry,
                             ShippingCity,ShippingState,ShippingPostalCode,BillingStreet,
                             ShippingCountry,ShippingStreet,ShippingLatitude,ShippingLongitude,BillingLatitude,
                             BillingLongitude, Override_Address__Street__s, Override_Address__City__s, Override_Address__Statecode__s, Override_Address__PostalCode__s,
                             Override_Address__Countrycode__s, Override_Address__Latitude__s,
                             Override_Address__Longitude__s from Account];
        acc[0].ShippingStreet = null;
        acc[0].BillingStreet = null;
        acc[0].BillingCity = 'Fort Mill';
        acc[0].BillingState = 'SC';
        acc[0].BillingPostalCode = '29708 ';
        acc[0].BillingCountry = 'US';
        update acc[0];
        
        List<Schema.Location> branch = [Select id from location];
        List<Schema.Location> Joblocation = [Select id from location];
        String branchId = branch[0].id;
        String locId = Joblocation[0].id;
        SBR_3_0_ContactWrap  conWrap = new SBR_3_0_ContactWrap();
        conWrap.email = 'test123@test.com';
        conWrap.firstName = 'Test';
        conWrap.lastName = 'check';
        conWrap.phone = '1234567898';
        Contact con = [Select Id, firstname, lastname, phone, email from contact limit 1];
        Test.startTest();
        
        Schema.Location createJobLocShip = SBR_3_0_SalesHelper.createJobLocFromShippingAddr(acc[0]);
        Schema.Location createBillingAddr = SBR_3_0_SalesHelper.createJobLocFromBillingAddr(acc[0]);
        AssociatedLocation assLoc = SBR_3_0_SalesHelper.createJoSiteFromShippingAddr(acc[0],locId,branchId);
        AssociatedLocation jobSiteBill = SBR_3_0_SalesHelper.createJoSiteFromBillingAddr(acc[0],locId,branchId);
        
        SBR_3_0_WrapAddress addrWrapper = new SBR_3_0_WrapAddress();
        addrWrapper.street1 = null;
        addrWrapper.street2 = null;
        
        Schema.Location locFromAddr = SBR_3_0_SalesHelper.createJobLocFromAddress(addrWrapper);
        AssociatedLocation jobSiteAddr = SBR_3_0_SalesHelper.createJoSiteFromAddress(addrWrapper,acc[0].Id,locId,branchId);
        Test.stopTest();
        
        System.assertEquals('', assLoc.Street_Address__c, 'job site from shipping address, street 1 did not match expected value');
        System.assertEquals('', assLoc.Street_Address_2__c, 'job site from shipping address, street 2 did not match expected value');
        System.assertEquals('', jobSiteBill.Street_Address__c, 'job site from billing address, street 1 did not match expected value');
        System.assertEquals('', jobSiteBill.Street_Address_2__c, 'job site from billing address, street 2 did not match expected value');
        
        System.assertEquals('', createBillingAddr.Street_Address__c, 'location from billing address, street 1 did not match expected value');
        System.assertEquals('', createBillingAddr.Street_Address_2__c, 'location from billing address, street 2 did not match expected value');
        System.assertEquals('', createJobLocShip.Street_Address__c, 'location from shipping address, street 1 did not match expected value');
        System.assertEquals('', createJobLocShip.Street_Address_2__c, 'location from shipping address, street 2 did not match expected value');
    
    	System.assertEquals('', jobSiteAddr.Street_Address__c, 'job site from addr wrapper, street 1 did not match expected value.');
        System.assertEquals('', jobSiteAddr.Street_Address_2__c, 'job site from addr wrapper, street 2 did not match expected value.');
        
        System.assertEquals('', locFromAddr.Street_Address__c, 'location from addr wrapper, street 1 did not match expected value.');
        System.assertEquals('', locFromAddr.Street_Address_2__c, 'location from addr wrapper, street 2 did not match expected value.');
        
    }
      @isTest
    static void testGetP2PContactWithNewContactAndBillingAddress(){
        Account acct = [Select id,BillingCity,BillingState,BillingPostalCode,BillingCountry,
                             ShippingCity,ShippingState,ShippingPostalCode,BillingStreet,
                             ShippingCountry,ShippingStreet,ShippingLatitude,ShippingLongitude,BillingLatitude,
                             BillingLongitude, Override_Address__Street__s, Override_Address__City__s, Override_Address__Statecode__s, Override_Address__PostalCode__s,
                             Override_Address__Countrycode__s, Override_Address__Latitude__s,
                             Override_Address__Longitude__s from Account];
        
        acct = new Account(
            Id = acct.Id,
            Name = 'Wayne Enterprises',
            Company_Name__c = '01',
            Status__c = SBR_3_0_Constants.ACCOUNT_STATUS_ACTIVE,
            Phone = '2028675309',
            //Override_Address__Street__s = '111 Batcave Ave',
            //Override_Address__City__s = 'Gotham City',
            //Override_Address__StateCode__s = 'IL',
            //Override_Address__PostalCode__s = '55022',
            //Override_Address__CountryCode__s = 'US',
            //ShippingStreet = '222 Batcave Ave',
            //ShippingCity = 'Rogers',
            //ShippingState = 'MN',
            //ShippingPostalCode = '55122',
            //ShippingCountry = 'US',
            BillingStreet = '333 Batcave Ave',
            BillingCity = 'Springfield',
            BillingState = 'KY',
            BillingPostalCode = '33422',
            BillingCountry = 'US',
            RM_Account_Number__c = '555444'
        );
        update acct;

        Test.startTest();
        SBR_3_0_ContactWrap cw = new SBR_3_0_ContactWrap();
        cw.firstName = 'Bruce';
        cw.lastName = 'Wayne';
        cw.email = 'brucewayne@wayneentprises.com';
        cw.phone = '3038675309';
        
        Contact result = SBR_3_0_SalesHelper.p2pFindOrCreateContact(cw, null, acct);
        Test.stopTest();
        
        Contact c = 
            [Select 
                 Id,
                 Firstname,
                 Lastname,
                 Email,
                 MailingStreet,
                 MailingCity,
                 MailingState,
                 MailingPostalCode,
                 MailingCountry,
                 Phone
             From 
                 Contact 
             Where 
                 Id = :result.Id
             WITH SECURITY_ENFORCED];
        System.assertEquals('brucewayne@wayneentprises.com', c.Email, 'Received unexpected email.');
        System.assertEquals('Bruce', c.firstname, 'Received unexpected first name.');
        System.assertEquals('Wayne', c.lastname, 'Received unexpected last name.');
        System.assertEquals('3038675309', c.phone, 'Received unexpected phone number.');
        System.assertEquals('333 Batcave Ave', c.MailingStreet, 'Received unexpected mailing street.');
        System.assertEquals('Springfield', c.MailingCity, 'Received unexpected mailing city.');
        System.assertEquals('KY', c.MailingState, 'Received unexpected mailing state.');
        System.assertEquals('33422', c.MailingPostalCode, 'Received unexpected mailing postal code.');
        System.assertEquals('US', c.MailingCountry, 'Received unexpected mailing country.');
    }

}