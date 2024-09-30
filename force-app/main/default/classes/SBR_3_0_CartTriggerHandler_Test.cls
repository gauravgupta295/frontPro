@isTest
public with sharing class SBR_3_0_CartTriggerHandler_Test {
    
    @TestSetup
    static void makeData(){
        
        //Account Creation:
        List<Account> acc = SBR_3_0_TestDataFactory.createAccounts(1,true);
        //Branch Creation
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
        
        //Contact Creation
        List<Contact> cons = SBR_3_0_TestDataFactory.createContacts(1,acc[0].Id,true);
        Schema.Location jobLocation = new Schema.Location();
        jobLocation.Name = 'Test Job Location' + Integer.valueof((Math.random() * 100));
        jobLocation.Street_Address__c = '12 Main Street';
        jobLocation.City__c = 'Toronto';
        jobLocation.Zip_Code__c = 'M7N7B3';
        jobLocation.State__c = 'ON';
        jobLocation.Country__c = 'CA';
        jobLocation.RecordTypeId = SBR_3_0_Constants.LOCATION_JOB_RT_ID;
        jobLocation.OMS_Sourcing_Enabled__c = true;
        jobLocation.Distance_Multiplier__c = 50;
        jobLocation.Analysis_Region_Key__c = '001';
        jobLocation.Company_Code__c = '01';
        insert jobLocation;
        
        
        AssociatedLocation jobSite = new AssociatedLocation(
            Name__c = 'Test Job Site',
            ParentRecordId = acc[0].Id,
            LocationId = jobLocation.Id,
            Branch__c = branchLocation.Id,
            Job_Number__c = '2022221004A',
            Job_Site_Id__c = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123'
        );
        insert jobSite;        

    } 
    @isTest
    static void testSetStartAndReturnTime(){
        List<Account> acc = [Select Id from Account LIMIT 1];
        List<Contact> cons = [Select Id from Contact LIMIT 1];
        List<Schema.Location> branchLocation = [Select Id from Location limit 1];
        List<AssociatedLocation> AssociatedLocations = [Select Id from AssociatedLocation limit 1];
        Id cartOGRecordTypeId = Schema.SObjectType.cart__c.getRecordTypeInfosByName().get('Oil & Gas').getRecordTypeId();
        
        Cart__c c = new Cart__c();
        c.Account__c = acc[0].Id;
        c.Contact__c = cons[0].Id;
        c.Branch__c = branchLocation[0].Id;
        c.Rental_Start_Date__c = System.now() + 2;
        c.Rental_End_Date__c = System.now() + 36;
        c.Rental_Period__c = 'Custom'; 
        c.Job_Site__c = AssociatedLocations[0].id;
        c.RecordTypeId = cartOGRecordTypeId;
        insert c;
        
        c.Rental_Period__c = '1 Day';
        update c;
        
        Cart__c ct1 = [Select Id, Rental_End_Date__c,Rental_Start_Date__c FROM Cart__c where Id =: c.Id]; 
        system.assert(ct1.Rental_End_Date__c == ct1.Rental_Start_Date__c.adddays(1));
        
        c.Rental_Period__c = '7 Days';
        update c;
        
        Cart__c ct2 = [Select Id, Rental_End_Date__c,Rental_Start_Date__c FROM Cart__c where Id =: c.Id]; 
        system.assert(ct2.Rental_End_Date__c == ct2.Rental_Start_Date__c.adddays(7));
        
        c.Rental_Period__c = '28 Days';
        update c; 
        Cart__c ct3 = [Select Id, Rental_End_Date__c,Rental_Start_Date__c FROM Cart__c where Id =: c.Id]; 
        system.assert(ct3.Rental_End_Date__c == ct3.Rental_Start_Date__c.adddays(28));
    }
    
    
    @isTest
    static void testSetCartStatusToNull(){ //SF-5347
        List<Account> acc = [Select Id from Account LIMIT 1];
        List<Schema.Location> branchLocation = [Select Id from Location limit 1];
        Test.startTest();
         Id cartOGRecordTypeId = Schema.SObjectType.cart__c.getRecordTypeInfosByName().get('Oil & Gas').getRecordTypeId();
        Cart__c cart = new Cart__c(
        Account__c = acc[0].Id,
        Branch__c = branchLocation[0].Id, 
        Rental_Start_Date__c = System.now() + 5,
        Rental_End_Date__c = System.now() + 10,
        Rental_Period__c = 'Custom',
        RecordTypeId = cartOGRecordTypeId
        );
        insert cart;
        Cart__c ct = [Select Id, Account__c,Branch__c,Rental_Start_Date__c,Rental_End_Date__c,Rental_Period__c, RecordTypeId FROM Cart__c WHERE Account__c =: acc[0].Id]; 
        Cart__c clonedCart = ct.clone(false, true, false, false);
        insert clonedCart;
        Test.stopTest();
        Cart__c ctcl = [Select Id, Status__c FROM Cart__c WHERE Id =: clonedCart.Id]; 
        system.assert(ctcl.status__c == null);
    }

    


    @isTest
    static void testSetStartDateUserTimeZone(){
        List<Account> acc = [Select Id from Account LIMIT 1];
        List<Contact> cons = [Select Id from Contact LIMIT 1];
        List<Schema.Location> branchLocation = [Select Id from Location limit 1];
        List<AssociatedLocation> AssociatedLocations = [Select Id from AssociatedLocation limit 1];
        Id cartOGRecordTypeId = Schema.SObjectType.cart__c.getRecordTypeInfosByName().get('Oil & Gas').getRecordTypeId();
        
        Cart__c c = new Cart__c();
        c.Account__c = acc[0].Id;
        c.Contact__c = cons[0].Id;
        c.Branch__c = branchLocation[0].Id;
        c.Rental_Start_Date__c = System.now() + 2;
        c.Rental_End_Date__c = System.now() + 36;
        c.Rental_Period__c = 'Custom'; 
        c.Job_Site__c = AssociatedLocations[0].id;
        c.RecordTypeId = cartOGRecordTypeId;
        insert c;
        
        c.Rental_Period__c = '1 Day';
        //SADAPUR
        String uniqueUserName = 'testAdminUser' + DateTime.now().getTime() + '@SBRtestorg.com';
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User testUser = new User(Alias = 'standt', Email = 'standarduser@testorg.com', EmailEncodingKey = 'UTF-8', LastName = 'Testing', LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', ProfileId = p.Id, TimeZoneSidKey = 'America/Los_Angeles', UserName = uniqueUserName);
        insert testUser;
       
        System.runAs(testUser) {
            Test.startTest();            
            update c;           
            Test.stopTest();
        }
       
        Cart__c ct1 = [Select Id, Rental_End_Date__c,Rental_Start_Date__c FROM Cart__c where Id =: c.Id]; 
        Assert.areEqual(ct1.Rental_End_Date__c, ct1.Rental_Start_Date__c.adddays(1));
        
    }
}