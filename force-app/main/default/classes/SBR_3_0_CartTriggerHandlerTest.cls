/*********************************************************************************************************************
* Apex Class: SBR_3_0_CartTriggerHandler
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Test class for Cart Trigger
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Soni Pinjala         	2023-08-28          Initial version    
*********************************************************************************************************************/
@isTest
public class SBR_3_0_CartTriggerHandlerTest {

    @TestSetup
    static void makeData(){
        List<Account> acct = SBR_3_0_TestDataFactory.createAccounts(2, false);
        acct[0].Name = 'Test Account 1';
        acct[1].Name = 'Test Account 2';
        insert acct;
        
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        //create ers user clone
        String ersUserName = 'ersuser' + DateTime.now().getTime() + '@SBRtestorg.com';
        User ersu = new User(Alias = 'ers', Email='ersuser@testorg.com',
        EmailEncodingKey='UTF-8', LastName='erstest', LanguageLocaleKey='en_US',
        LocaleSidKey='en_US', ProfileId = p.Id,
        TimeZoneSidKey='America/Chicago',
        UserName=ersUserName);
        ersu.RepID__c = '1234';
        insert ersu;
     
        // Create Location
        Schema.Location jobLocation1 = new Schema.Location();
        jobLocation1.Name = 'Test Job Location';
        jobLocation1.Street_Address__c = '12 Main Street';
        jobLocation1.City__c = 'Toronto';
        jobLocation1.Zip_Code__c = 'M7N7B3';
        jobLocation1.State__c = 'ON';
        jobLocation1.Country__c = 'CA';
        jobLocation1.RecordTypeId = SBR_3_0_Constants.LOCATION_JOB_RT_ID;
        jobLocation1.OMS_Sourcing_Enabled__c = true;
        jobLocation1.Distance_Multiplier__c = 50;
        jobLocation1.Analysis_Region_Key__c = '001';
        jobLocation1.Company_Code__c = '01';
        insert jobLocation1;
    }
    
    @isTest
    static void testBeforeInsertandBeforeUpdate(){
        User runUser = [select Id, Email from User where Email = 'ersuser@testorg.com' and LastName = 'erstest' limit 1];
        Account acct = [select Id, Name from Account where Name = 'Test Account 1' LIMIT 1];
        // Create Branch
        Schema.Location branchLocation1 = new Schema.Location();
        branchLocation1.Branch_Location_Number__c = '720';
        branchLocation1.Name = 'Test Branch Location';
        branchLocation1.Street_Address__c = '12 Main Street';
        branchLocation1.City__c = 'Toronto';
        branchLocation1.Zip_Code__c = 'M7N7B3';
        branchLocation1.State__c = 'ON';
        branchLocation1.Country__c = 'CA';
        branchLocation1.Job_Number__c='332112';
        branchLocation1.RecordTypeId = SBR_3_0_Constants.LOCATION_BRANCH_RT_ID;
        branchLocation1.Company_Code__c = 'X';
        branchLocation1.Time_Zone_Name__c = 'America/Chicago';
        branchLocation1.Time_Zone__c = 3;
        branchLocation1.Time_Zone_Id__c = 'America/Chicago';
        branchLocation1.Analysis_Region_Key__c='003';
        insert branchLocation1;
        
        System.runAs(runUser) {
             Id cartOGRecordTypeId = Schema.SObjectType.cart__c.getRecordTypeInfosByName().get('Oil & Gas').getRecordTypeId();
             Cart__c cart = new Cart__c(
                 Account__c = acct.Id,
                 Branch__c = branchLocation1.Id, 
                 Rental_Start_Date__c = System.now().addDays(1),
                 Rental_End_Date__c = System.now().addDays(2),
                 Rental_Start_Time__c= System.now().addDays(2).time(),
                 Rental_Period__c = '1 Day',
                 RecordTypeId = cartOGRecordTypeId
             );
            insert cart;
            Account acc2 = [select Id, Name from Account where Name = 'Test Account 2' LIMIT 1];
            Test.startTest();
            
            Cart__c recToUpdate = [Select Id, Account__c FROM Cart__c WHERE Account__c =: acct.Id LIMIT 1];
            recToUpdate.Account__c = acc2.Id;
            update recToUpdate;
            
            Test.stopTest();
            
            System.assertEquals(acc2.Id, recToUpdate.Account__c);
            List<Cart__c> carts = [SELECT Id, Rental_Start_Date_Time_UTC__c, Rental_Start_Time__c,Rental_Start_Date__c FROM Cart__c WHERE Rental_Period__c = '1 Day' LIMIT 1];
            Assert.areEqual(carts[0].Rental_Start_Date_Time_UTC__c,
                            DateTime.newInstance(Date.valueOf(carts[0].Rental_Start_Date__c),carts[0].Rental_Start_Time__c),
                            'Values are not equal');
        }
    }
    
    @isTest
    static void testBeforeInsertMethod(){
        User runUser = [select Id, Email from User where Email = 'ersuser@testorg.com' and LastName = 'erstest' limit 1];
        Account acct = [select Id, Name from Account where Name = 'Test Account 1' LIMIT 1];
        Schema.Location branchLocation1 = new Schema.Location();
        branchLocation1.Branch_Location_Number__c = '720';
        branchLocation1.Name = 'Test Branch Location';
        branchLocation1.Street_Address__c = '12 Main Street';
        branchLocation1.City__c = 'Toronto';
        branchLocation1.Zip_Code__c = 'M7N7B3';
        branchLocation1.State__c = 'ON';
        branchLocation1.Country__c = 'CA';
        branchLocation1.Job_Number__c='332112';
        branchLocation1.RecordTypeId = SBR_3_0_Constants.LOCATION_BRANCH_RT_ID;
        branchLocation1.Company_Code__c = 'X';
        branchLocation1.Time_Zone_Name__c = 'America/Chicago';
        branchLocation1.Time_Zone__c = 3;
        branchLocation1.Time_Zone_Id__c = 'America/Chicago';
        branchLocation1.Analysis_Region_Key__c='003';
        insert branchLocation1;
        Id standard = Schema.SObjectType.cart__c.getRecordTypeInfosByName().get('Standard').getRecordTypeId();
        
        System.runAs(runUser){
            List<Cart__c> carts = new List<Cart__c>();
        	Cart__c cart = new Cart__c(
                Account__c = acct.Id,
                Branch__c = branchLocation1.Id,
            	Rental_Start_Date__c = System.now().addDays(1),
            	Rental_End_Date__c = System.now().addDays(2),
            	Rental_Period__c = '7 Days',
            	RecordTypeId = standard
        	);
        	carts.add(cart);
        	Cart__c cart1 = new Cart__c(
                Account__c = acct.Id,
                Branch__c = branchLocation1.Id,
            	Rental_Start_Date__c = System.now().addDays(1),
            	Rental_End_Date__c = System.now().addDays(2),
            	Rental_Period__c = 'Custom',
            	RecordTypeId = standard
        	);
        	carts.add(cart1);
            
        	Test.startTest();
        	insert carts;
        	Test.stopTest();
            
            List<Cart__c> cartCheck = [SELECT Id, Rental_Start_Time__c,Rental_Start_Date__c FROM Cart__c WHERE Rental_Period__c = '7 Days'];
            Assert.areEqual(cartCheck[0].Rental_Start_Time__c, cartCheck[0].Rental_Start_Date__c.time(),'Start time is not updated');
            
            List<Cart__c> cartCheck1 = [SELECT Id, Rental_Start_Time__c,Rental_Start_Date__c,Rental_End_Time__c,Rental_End_Date__c FROM Cart__c WHERE Rental_Period__c = 'Custom'];
            Assert.areEqual(cartCheck1[0].Rental_Start_Time__c, cartCheck1[0].Rental_Start_Date__c.time(),'Start time is not updated');
            Assert.areEqual(cartCheck1[0].Rental_End_Time__c, cartCheck1[0].Rental_End_Date__c.time(),'End time is not updated');
            
        }
        
    }
}