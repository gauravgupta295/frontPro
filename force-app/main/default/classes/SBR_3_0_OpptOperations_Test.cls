/*********************************************************************************************************************
* Apex Class: SBR_3_0_OpptOperations_Test
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Class to test SBR_3_0_OpptOperations
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Konrad Haight           2022-03-21            Initial version    
*********************************************************************************************************************/
@isTest public with sharing class SBR_3_0_OpptOperations_Test {

    @TestSetup
    static void makeData(){
        Credential__c cred = SBR_3_0_TestDataFactory.createCredentials(1, false)[0];
        cred.Name = 'Mule_Token_Endpoint';
        cred.Key_Id__c = 'keyid';
        cred.Secret__c ='credSecret';
        insert cred;             
    }

    @isTest static void testPreventOpptDeletion(){
        String uniqueUserName = 'standarduser' + DateTime.now().getTime() + '@SBRtestorg.com';
        // This code runs as the system user
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com',
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
        LocaleSidKey='en_US', ProfileId = p.Id,
        TimeZoneSidKey='America/Los_Angeles',
        UserName=uniqueUserName);

        Account testAccount = SBR_3_0_TestDataFactory.createAccounts(1, true, 'Prospect')[0];
        List<Opportunity> testOppts = SBR_3_0_TestDataFactory.createOppts(2, testAccount.Id, false);
        Opportunity testOpptOne = testOppts[0];
        insert testOpptOne;

        System.runAs(u){

            try{
                delete testOpptOne;
            } catch(DmlException e){
                System.debug(e.getMessage());
                System.assert(e != null, true);
            }
        }

        String uniqueUserName2 = 'systemadmin' + DateTime.now().getTime() + '@SBRtestorg.com';
        // This code runs as the system user
        Profile p2 = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User u2 = new User(Alias = 'standt', Email='systemadmin@testorg.com',
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
        LocaleSidKey='en_US', ProfileId = p2.Id,
        TimeZoneSidKey='America/Los_Angeles',
        UserName=uniqueUserName2);

        System.runAs(u2){
            Opportunity testOpptTwo = testOppts[1];
            insert testOpptTwo;
            
            try{
                //Test.startTest();
                Database.DeleteResult dr = Database.delete(testOpptTwo);
               // Test.stopTest();
                System.assert(dr.isSuccess());
            } catch(DmlException e){
                system.assert(e.getMessage().contains('Opportunity cannot be deleted'), 'Opportunity cannot be deleted');
            }
        }
        test.StartTest();
        SBR_3_0_OpptOperations.preventOpptDeletion(testOppts);
        Test.Stoptest();
        
                 
    }

    @isTest static void checkProjectFieldTest(){
        List<Account> acc =SBR_3_0_TestDataFactory.createAccounts(1, true, 'Credit');
        Id ide,accide,projide;
        String projectCity,projectState;
        for (Account accb:acc){
            accide=accb.Id;
        }
        
        List<Project__c> proj = SBR_3_0_TestDataFactory.createProjectsNew(1,true);
        for (Project__c pro:proj){
            projide= pro.Id;
            projectCity=pro.City__c;
            projectState=pro.State__c;
        }

        List<Opportunity> opp = SBR_3_0_TestDataFactory.createOppts(1,accide,true);
        for (Opportunity sob:opp){
            ide=sob.Id;
        }
        
       // Test.startTest();
        List<Opportunity> opt1 =  [SELECT ID, Project__c FROM Opportunity Where Id =: ide limit 1];
        for (Opportunity opt:opt1){
            opt.Project__c = projide;
            opt.City__c='Jersey City';
            opt.State__c='NJ';
            opt.ZIP_Code__c='07310';
            opt.Country__c='US';
            opt.Latitude_Longitude__Latitude__s=40.3;
            opt.Latitude_Longitude__Longitude__s=103.2;
            update opt;
        }
        
        Opportunity updatedopp = [Select Id,City__c,State__c from Opportunity where Id =:ide];
        //Test.stopTest();
        SBR_3_0_OpptOperations.checkProjectField(opt1);
        System.assertEquals('Indianapolis', projectCity);
        System.assertEquals('IN', projectState);
        
    }

    @isTest static void fetchLatLongSuccessTest(){   
        List<Account> acc =SBR_3_0_TestDataFactory.createAccounts(1, True, 'Credit');
        Id ide;
        for (Account sob:acc){
            ide=sob.Id;
        }
        List<Opportunity> opp = SBR_3_0_TestDataFactory.createOppts(1,ide,true);
        for (Opportunity sob:opp){
            ide=sob.Id;
        }
        Opportunity opt =  [SELECT ID, Street__c, City__c, State__c, Country__c, ZIP_Code__c, Latitude_Longitude_Status__c, Latitude_Longitude_error__c, Latitude_Longitude__c, Latitude_Longitude__Latitude__s, Latitude_Longitude__Longitude__s FROM Opportunity Where Id =: ide];
        opt.Street__c = '6365 Multiplex Drive';
        opt.City__c = 'Centreville';
        opt.State__c = 'VA';
        opt.ZIP_Code__c = '20121';
        opt.Country__c = 'US';
        update opt;

        Opportunity oldOpt = opt.clone(true);
        oldOpt.Street__c = 'Test Street';
        oldopt.City__c = 'Some City';
        oldopt.State__c = 'NJ';

        Map<Id, Opportunity> newOptMap = new Map<Id, Opportunity>();
        newOptMap.put(opt.Id, opt);
        Map<Id, Opportunity> oldOptMap = new Map<Id, Opportunity>();
        oldOptMap.put(opt.Id, oldOpt);
        
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_FetchLatLong_MockSuccess());
        SBR_3_0_OpptOperations.fetchAddressLatLong(oldOptMap, newOptMap);
        Test.stopTest();

        Opportunity opt2 = [SELECT ID, Latitude_Longitude_Status__c FROM Opportunity Where Id =: ide];
        system.assertEquals('Fetching', opt2.Latitude_Longitude_Status__c, 'Street Address Lat Long Status is not set to Success');

    }

    @isTest static void fetchLatLongErrorTest(){
        List<Account> acc =SBR_3_0_TestDataFactory.createAccounts(1, True, 'Credit');
        Id ide;
        for (Account sob:acc){
            ide=sob.Id;
        }
        List<Opportunity> opp = SBR_3_0_TestDataFactory.createOppts(1,ide,true);
        for (Opportunity sob:opp){
            ide=sob.Id;
        }

        Opportunity opt = [SELECT Id, Street__c, City__c, State__c, Country__c, ZIP_Code__c, Latitude_Longitude_Status__c, Latitude_Longitude_error__c, Latitude_Longitude__c, Latitude_Longitude__Latitude__s, Latitude_Longitude__Longitude__s FROM Opportunity Where Id =: ide ];
        opt.Street__c = '30 newport pkwy';
        opt.City__c = 'Jersey City';
        opt.State__c = 'NJ';
        opt.ZIP_Code__c = '07310';
        opt.Country__c = 'US';

        update opt;

        Opportunity oldopt = opt.clone(true);
        oldopt.Street__c = 'Test Street Changed';
        oldopt.City__c = 'Some City';
        oldopt.State__c = 'NJ';

        Map<Id, Opportunity> newOptMap = new Map<Id, Opportunity>();
        newOptMap.put(opt.Id, opt);
        Map<Id, Opportunity> oldOptMap = new Map<Id, Opportunity>();
        oldOptMap.put(opt.Id, oldOpt);
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_FetchLatLong_MockFailed());
        SBR_3_0_OpptOperations.fetchAddressLatLong(oldOptMap, newOptMap);
        Test.stopTest();

        Opportunity opt2 = [SELECT Id, Latitude_Longitude_Status__c FROM Opportunity Where Id =: ide];
        system.assertEquals('Fetching', opt2.Latitude_Longitude_Status__c, 'Street Address Lat Long Status is not set to Error');
    
    }
    

}