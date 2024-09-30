/*********************************************************************************************************************
* Apex Class: SBR_3_0_JobsiteDA_Test
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Class to test SBR_3_0_JobsiteDA
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME                  DATE                    DETAIL FEATURES
1.0         Joelle Ramiandrisoa           2022-08-17                Initial version
1.1         Konrad Haight                 2022-10-20                Added AssociatedLocationTriggerHandler Bypass    
*********************************************************************************************************************/
@isTest public class SBR_3_0_JobsiteDA_Test {
    
    @TestSetup
    static void makeData(){
        
        // Create Price Book
        Pricebook2 priceBook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update priceBook;
        
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

        //Creating a user record
        Profile userProfile = [SELECT Id FROM Profile WHERE Name='Sales'];
        User testUser = SBR_3_0_TestDataFactory.createUser(TRUE,userProfile);
    }
    
    static testMethod void testGetJobsitesByAccounts(){
        SBR_3_0_TriggerHandler.bypass('SBR_3_0_AssociatedLocationTriggerHandler');
        List<Account> acc = SBR_3_0_TestDataFactory.createAccounts(1, true);
        List<Schema.Location> branch = SBR_3_0_TestDataFactory.createLocations(1, true, 'Branch');
        List<Schema.Location> jobLoc = SBR_3_0_TestDataFactory.createLocations(1, true, 'Shared Job Location');
        List<AssociatedLocation> al = SBR_3_0_TestDataFactory.createAssociatedLocations(1, acc[0].Id, branch[0].Id, jobLoc[0].Id, true);
        Set<Id> alSet = new Set<Id>();
        List<AssociatedLocation> result = new List<AssociatedLocation>();
        
        alSet.add(acc[0].Id);
        
        
        Test.startTest();
        result = SBR_3_0_JobsiteDA.getJobsitesByAccounts(alSet);
        Test.stopTest();
        System.assertEquals(acc[0].Id, result[0].ParentRecordId);
    }
    
    @isTest static void getRelatedAccountTest(){
        
        Test.startTest();
        
        SBR_3_0_TriggerHandler.bypass('SBR_3_0_AssociatedLocationTriggerHandler');
        List<Account> accList = SBR_3_0_TestDataFactory.createAccounts(1, false);
        Account acc =accList[0];
        acc.RM_Account_Number__c='01-3210';
        insert acc;

        Account result = SBR_3_0_JobsiteDA.getRelatedAccount('01-3210');
        Test.stopTest();
        
        System.assertEquals(accList[0].Id,result.Id);
    }
    
    @isTest static void getRelatedBranchLocationTest(){
        SBR_3_0_TriggerHandler.bypass('SBR_3_0_AssociatedLocationTriggerHandler');
        List<Schema.Location> branchList = SBR_3_0_TestDataFactory.createLocations(1, true, 'Branch');
        
        for (Schema.Location loc: branchList){
            loc.Branch_Location_Number__c='1234';
            loc.Company_Code__c='111';
            update loc;
        }
        Test.startTest();
        Schema.Location result = SBR_3_0_JobsiteDA.getRelatedBranchLocation('1234','111');
        Test.stopTest();
        
        System.assertEquals(branchList[0].Id,result.Id);
    }
    //987 Fountain Coin Loop, Orlando, FL 32828
    @isTest static void getRelatedJobLocation(){
        SBR_3_0_TriggerHandler.bypass('SBR_3_0_AssociatedLocationTriggerHandler');
        List<Schema.Location> jobLoc = SBR_3_0_TestDataFactory.createLocations(1, true, 'Shared Job Location');
        for (Schema.Location loc: jobloc){
            loc.Street_Address__c='987 Fountain Coin Loop';
            loc.City__c ='Orlando';
            loc.State__c='FL';
            loc.Zip_Code__c='32828';
            loc.Country__c='US';
            update loc;
        }
        
        SBR_3_0_WrapAddress a = new SBR_3_0_WrapAddress();
        a.street1='987 Fountain Coin Loop';
        a.city='Orlando';
        a.state='FL';
        a.country='US';
        a.zip='32828';
        
        Test.startTest();
        Schema.Location result = SBR_3_0_JobsiteDA.getRelatedJobLocation(a);
        Test.stopTest();
        
        System.assertEquals(jobloc[0].Id,result.Id);
    }
    
    @isTest static void getRelatedJobLocationLatLong(){
        SBR_3_0_TriggerHandler.bypass('SBR_3_0_AssociatedLocationTriggerHandler');
        List<Schema.Location> jobLoc = SBR_3_0_TestDataFactory.createLocations(1, true, 'Shared Job Location');
        for (Schema.Location loc: jobloc){
            loc.Latitude_Longitude__latitude__s=28.5498764;
            loc.Latitude_Longitude__longitude__s=-81.1554329;
            loc.Street_Address__c='987 Fountain Coin Loop';
            loc.City__c ='Orlando';
            loc.State__c='FL';
            loc.Zip_Code__c='32828';
            loc.Country__c='US';
            update loc;
        }
        
        SBR_3_0_WrapAddress a = new SBR_3_0_WrapAddress();
        a.latitude=28.5498764;
        a.longitude=-81.1554329;
        Test.startTest();
        Schema.Location result = SBR_3_0_JobsiteDA.getRelatedJobLocation(a);
        Test.stopTest();
        
        System.assertEquals(jobloc[0].Id,result.Id);
    }
    
    /*
    @isTest
    static void getFilteredJobLocation(){
        SBR_3_0_TriggerHandler.bypass('SBR_3_0_AssociatedLocationTriggerHandler');
        List<Account> acc = SBR_3_0_TestDataFactory.createAccounts(1, true);
        List<Schema.Location> branch = SBR_3_0_TestDataFactory.createLocations(1, true, 'Branch');
        List<Schema.Location> jobLoc = SBR_3_0_TestDataFactory.createLocations(1, true, 'Shared Job Location');
        List<AssociatedLocation> al = SBR_3_0_TestDataFactory.createAssociatedLocations(1, acc[0].Id, branch[0].Id, jobLoc[0].Id, true);
        
        Id contractOrderRecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('Contract_Order').getRecordTypeId();
        
        Product2 product = [SELECT Id FROM Product2 LIMIT 1];
       // PricebookEntry pbEntry = [SELECT Id,Product2Id FROM PricebookEntry WHERE Pricebook2Id = :Test.getStandardPricebookId() AND Product2Id =: product.Id LIMIT 1];
    
        Pricebook2 standardPricebook = new Pricebook2(
        Id = Test.getStandardPricebookId(),
        IsActive = true
        );

        update standardPricebook;

        User testUser = [SELECT Id FROM User WHERE Email LIKE '%@sunbeltrentals.com' AND Profile.Name = 'Sales' AND IsActive = true LIMIT 1];

        Order order1 = new Order(
            Quote_Name__c = 'Test Quote1',
            Name = 'Test Quote1',
            AccountId = acc[0].Id,
            Jobsite__c = al[0].Id,
            Deliverymethod__c = 'Delivery',
            Delivery_Charge__c = 10,
            Status = 'Open',
            Pricebook2Id = standardPricebook.Id,
            Start_Date__c = system.today() - 1,
            EffectiveDate = system.today() + 1,
            EndDate = system.today() +12,
            Return_Date__c = system.today() +30,
            Estimated_Return_Date__c = system.today() +30,
            Earliest_Delivery_Date__c = system.today()-2,
            Reservation_Order_Number__c = '12342',
            Branch__c = branch[0].Id,
            RecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('Reservation Order').getRecordTypeId(),
            Sales_Rep__c = testUser.Id
        );

        insert order1;
       System.debug('Print Account ' + acc[0]);
       System.debug('Print Order ' + order1);
       // PricebookEntry pbEntry = [SELECT Id,Product2Id FROM PricebookEntry WHERE Pricebook2Id = :Test.getStandardPricebookId() AND Product2Id =: product.Id LIMIT 1];
       PricebookEntry pbEntry = new PricebookEntry(
        Pricebook2Id = standardPricebook.Id,
        Product2Id = product.Id,
        UnitPrice = 1020,
        IsActive = true
            );
        insert pbEntry;

        //Create Asset 
        Asset ast = new Asset();
        ast.Status = 'ON RENT';
        ast.Name = 'Test Asset';
        ast.AccountId = acc[0].Id;
        insert ast;
    
        OrderItem orderItem = new OrderItem();
        orderItem.OrderId = order1.Id;
        orderItem.Product2Id = product.Id;
        orderItem.UnitPrice = 100;
        orderItem.Item_Number__c = 5;
        orderItem.Min_Rate__c = 2;
        orderItem.Daily_Rate__c = 2.0;
        orderItem.Weekly_Rate__c = 2.0;
        orderItem.Monthly_Rate__c = 2.0;
        orderItem.PricebookEntryId = pbEntry.Id;
        orderItem.Quantity = 1;
        orderItem.SBQQ__Asset__c = ast.Id;
        
        insert orderItem;
        System.debug('Print Account ' + acc[0].Id);
        System.debug('Print Order ' + order1);
        System.debug('Print Order Id ' + order1.Id);
        System.debug('Print Order Sales Rep ' + order1.Sales_Rep__c);
        System.debug('Print Asset ' + ast);
        System.debug('Print Order Item ' + orderItem);
        
        SBR_3_0_GoogleMapCmpController.FilterWrapper wrapper = new SBR_3_0_GoogleMapCmpController.FilterWrapper();
        wrapper.userTerritories = testUser.Id;
        wrapper.activeJobSites = true;
        wrapper.todayJobSites = false;
        
        Test.startTest();
        List<Schema.AssociatedLocation> results = SBR_3_0_JobsiteDA.getJobSitesFiltered(wrapper);
        Test.stopTest();
        
        System.assertEquals(results.size(), 0);
    }
	*/
    
    @isTest static void getJobSiteByJobSiteIdtest(){
        Account testAccount = SBR_3_0_TestDataFactory.createAccounts(1, true, 'Credit')[0];
        Schema.Location branch = SBR_3_0_TestDataFactory.createLocations(1, false, SBR_3_0_Constants.LOCATION_REC_TYPE_BRANCH)[0];
        branch.Name = 'Branch';
        branch.Company_Code__c = 'X';
        branch.Analysis_Region_Key__c = 'X';
        insert branch;
        
        String accountId = [SELECT Id FROM Account][0].Id;
        Account relatedAccount = new Account();
        relatedAccount.RM_Account_Number__c = '01-12345';
        relatedAccount.Name = SBR_3_0_API_Web_Jobsite_DA.JOBSITEACCOUNTNAME;
        relatedAccount.BillingStreet = '123 Main Street';
        relatedAccount.BillingCity = 'Toronto';
        relatedAccount.BillingPostalCode = 'M9N7V5';
        relatedAccount.BillingState = 'ON';
        relatedAccount.BillingCountry = 'CA';
        relatedAccount.Phone = '2345656789';
        insert relatedAccount;
        // Create Location
        Schema.Location jobLocation = new Schema.Location();
        jobLocation.Name = 'Test Job Location';
        jobLocation.Street_Address__c = '12 Main Street';
        jobLocation.City__c = 'Toronto';
        jobLocation.Zip_Code__c = 'M7N7B3';
        jobLocation.State__c = 'ON';
        jobLocation.Country__c = 'CA';
        jobLocation.RecordTypeId = SBR_3_0_Constants.LOCATION_JOB_RT_ID;
        insert jobLocation;
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
        branchLocation.Company_Code__c = '01';
        insert branchLocation;
        AssociatedLocation jobSite = new AssociatedLocation(
            Name__c = 'Test Job Site',
            ParentRecordId = relatedAccount.Id,
            Branch__c = branchLocation.Id,
            Job_Number__c = '20221107A',
            Job_Site_Id__c = 'SF20221107A',
            Street_Address__c = '12 Main Street',
            City__c = 'Toronto',
            State__c = 'ON',
            Zip_Code__c = 'M9N7V3',
            LocationId = jobLocation.Id
        );
        insert jobSite;
        
        Set<String> setOfIds = new Set<String>();
        setOfIds.add('20221107A');
        
        Test.startTest();
        List<AssociatedLocation> res1 = SBR_3_0_JobsiteDA.getJobSitesByJobSiteId('SF20221107A');
        AssociatedLocation res2 = SBR_3_0_JobsiteDA.getJobSiteByJobSiteId('SF20221107A');
        List<AssociatedLocation> res3 = SBR_3_0_JobsiteDA.getJobsiteByJobNumber(setOfIds);
        Test.stopTest();
        
    }
    
     @isTest static void getJobSiteByNametest(){
        Account testAccount = SBR_3_0_TestDataFactory.createAccounts(1, true, 'Credit')[0];
        Schema.Location branch = SBR_3_0_TestDataFactory.createLocations(1, false, SBR_3_0_Constants.LOCATION_REC_TYPE_BRANCH)[0];
        branch.Name = 'Branch';
        branch.Company_Code__c = 'X';
        branch.Analysis_Region_Key__c = 'X';
        insert branch;
        
        String accountId = [SELECT Id FROM Account][0].Id;
         
        Account relatedAccount = new Account();
        relatedAccount.RM_Account_Number__c = '01-12345';
        relatedAccount.Name = SBR_3_0_API_Web_Jobsite_DA.JOBSITEACCOUNTNAME;
        relatedAccount.BillingStreet = '123 Main Street';
        relatedAccount.BillingCity = 'Toronto';
        relatedAccount.BillingPostalCode = 'M9N7V5';
        relatedAccount.BillingState = 'ON';
        relatedAccount.BillingCountry = 'CA';
        relatedAccount.Phone = '2345656789';
        insert relatedAccount;
        // Create Location
        Schema.Location jobLocation = new Schema.Location();
        jobLocation.Name = 'Test Job Location';
        jobLocation.Street_Address__c = '12 Main Street';
        jobLocation.City__c = 'Toronto';
        jobLocation.Zip_Code__c = 'M7N7B3';
        jobLocation.State__c = 'ON';
        jobLocation.Country__c = 'CA';
        jobLocation.RecordTypeId = SBR_3_0_Constants.LOCATION_JOB_RT_ID;
        insert jobLocation;
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
        branchLocation.Company_Code__c = '01';
        insert branchLocation;
        AssociatedLocation jobSite = new AssociatedLocation(
            Name__c = 'Test Job Site',
            ParentRecordId = relatedAccount.Id,
            Branch__c = branchLocation.Id,
            Job_Number__c = '20221107A',
            Job_Site_Id__c = 'SF20221107A',
            Street_Address__c = '12 Main Street',
            City__c = 'Toronto',
            State__c = 'ON',
            Zip_Code__c = 'M9N7V3',
            LocationId = jobLocation.Id
        );
        insert jobSite;
        
        Test.startTest();
        List<AssociatedLocation> result = SBR_3_0_JobsiteDA.getJobsiteByName('Test Job Site');
        Test.stopTest();
    }

    static testMethod void testGetJobsitesByExternalId(){
        SBR_3_0_TriggerHandler.bypass('SBR_3_0_AssociatedLocationTriggerHandler');
        List<Account> acc = SBR_3_0_TestDataFactory.createAccounts(1, true);
        List<Schema.Location> branch = SBR_3_0_TestDataFactory.createLocations(1, true, 'Branch');
        List<Schema.Location> jobLoc = SBR_3_0_TestDataFactory.createLocations(1, true, 'Shared Job Location');
        List<AssociatedLocation> al = SBR_3_0_TestDataFactory.createAssociatedLocations(1, acc[0].Id, branch[0].Id, jobLoc[0].Id, false);
        
        al[0].Job_Site_Id__c = 'abc123Ext';
        insert al;

        Test.startTest();
        Schema.Location result = SBR_3_0_JobsiteDA.getRelatedJobLocation('abc123Ext');
        Test.stopTest();
        System.assertEquals(jobLoc[0].Id, result.Id);

    }
}