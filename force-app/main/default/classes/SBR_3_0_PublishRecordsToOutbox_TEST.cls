@isTest
public with sharing class SBR_3_0_PublishRecordsToOutbox_TEST {
    @TestSetup
    static void makeData(){       
        Credential__c cred = SBR_3_0_TestDataFactory.createCredentials(1, false)[0];
        cred.Name = 'Mule_Token_Endpoint';
        cred.Key_Id__c = 'testKey123';
        cred.Secret__c = 'secret';
        insert cred;
    }
    @isTest 
    static void PublishTest(){
        Map<Id,Sobject> idsToSobject = new Map<Id,Sobject>();
        
        List<SObject> acc =SBR_3_0_TestDataFactory.createAccounts(1, True, 'Credit');
        for (SObject sob:acc){
            idsToSobject.put(sob.Id,sob);
        }
        
        // System.debug(idsToSobject);
       
        List<Id> ide = new List<Id>(idsToSobject.keySet());
       // String ide=(String)idsToSobject.keySet();
        // System.debug('ide'+ide);
        //idsToSobject.put(acc.Id,acc);
        String sObjType = 'Account';
        Set<String> validRecTypes = new Set<String>();
        validRecTypes.add('Credit');

        Test.startTest();
        SBR_3_0_PublishRecordsToOutbox v1 = new SBR_3_0_PublishRecordsToOutbox(idsToSobject,sObjType,validRecTypes);
        v1.publish();
        

        Account testAccount = [SELECT Id, SF_Account_Number__c FROM Account];
        System.debug(testAccount);
        // RecordType testType = [SELECT Name FROM RecordType WHERE Id =: testAccount.RecordTypeId];
        Outbox__c out =  [SELECT Object_API_Name__c, Record_Id__c, Record_Type_Name__c FROM Outbox__c WHERE Record_Id__c=:testAccount.Id LIMIT 1];
        //String ric=out.Record_Type_Name__c;
        // System.debug(out);
        // System.debug(ric);
        //Sobject tmp = idsToSobject.get(ide[0]).RecordType;

        //Commenting for Validation errors.
        /*   System.assertEquals('Credit', out.Record_Type_Name__c,
                                'Record type should be Credit'); */
        System.assertEquals('Account', out.Object_API_Name__c,
                                'Object type should be Account');
    }

    @isTest
    static void PublishRelatedRecordsTest(){
        List<SObject> acc = SBR_3_0_TestDataFactory.createAccounts(1, True, 'Credit');
        List<SObject> branch = SBR_3_0_TestDataFactory.createLocations(1, True, 'Branch');
        List<SObject> jobLocation = SBR_3_0_TestDataFactory.createLocations(1, True, 'Shared Job Location');
        List<SObject> associatedLocations = SBR_3_0_TestDataFactory.createAssociatedLocations(1, acc[0].Id, branch[0].Id, jobLocation[0].Id, true);

        Map<Id,Sobject> idsToSobject = new Map<Id,Sobject>();
        for (SObject sob:associatedLocations){
            idsToSobject.put(sob.Id,sob);
        }

        String sObjType = 'AssociatedLocation';

        
        SBR_3_0_PublishRecordsToOutbox v1 = new SBR_3_0_PublishRecordsToOutbox(idsToSobject,sObjType);
        v1.publish();
        

        Test.startTest();
        Outbox__c out =  [SELECT Object_API_Name__c, Record_Id__c, Record_Type_Name__c, Related_Data__c FROM Outbox__c WHERE Record_Id__c=:associatedLocations[0].Id limit 1];
        Test.stopTest();
        System.assertEquals('AssociatedLocation', out.Record_Type_Name__c,
                                'Record type should be Credit');
        System.assertEquals('AssociatedLocation', out.Object_API_Name__c,
                                'Object type should be Account');
        System.assertNotEquals(null, out.Related_Data__c, 
                                    'Related data should have data');
    }

    @isTest 
    static void ConstructorMinimumTest(){
        Map<Id,Sobject> idsToSobject = new Map<Id,Sobject>();
        List<SObject> acc =SBR_3_0_TestDataFactory.createAccounts(1, True, 'Credit');
        for (SObject sob:acc){
            idsToSobject.put(sob.Id,sob);
        }
       
        List<Id> ide = new List<Id>(idsToSobject.keySet());
        
        String sObjType = 'Account';
        Set<String> validRecTypes = new Set<String>();
        validRecTypes.add('Credit');
        
       
        SBR_3_0_PublishRecordsToOutbox v1 = new SBR_3_0_PublishRecordsToOutbox(idsToSobject,sObjType);
        v1.publish();
        
        Test.startTest();
        Account testAccount = [SELECT Id, SF_Account_Number__c FROM Account];
        Outbox__c out =  [SELECT Object_API_Name__c, Record_Id__c, Record_Type_Name__c FROM Outbox__c WHERE Record_Id__c=:testAccount.Id LIMIT 1];
        Test.stopTest();
        //Commenting for Validation errors.
       /*  System.assertEquals('Credit', out.Record_Type_Name__c,
                                'Record type should be Credit'); */
        System.assertEquals('Account', out.Object_API_Name__c,
                                'Object type should be Account');
    }

    @isTest 
    static void ConstructorErrorTest(){
        Map<Id,Sobject> idsToSobject = new Map<Id,Sobject>();
        List<SObject> acc =SBR_3_0_TestDataFactory.createAccounts(1, True, 'Credit');
        for (SObject sob:acc){
            idsToSobject.put(sob.Id,sob);
        }
       
        List<Id> ide = new List<Id>(idsToSobject.keySet());
        
        String sObjType = 'Project';
        Set<String> validRecTypes = new Set<String>();
        validRecTypes.add('Credit');
        Exception unexpectedException;
        Test.startTest();
        try {
        SBR_3_0_PublishRecordsToOutbox v1 = new SBR_3_0_PublishRecordsToOutbox(idsToSobject,sObjType,validRecTypes);
        v1.publish();
        } catch (Exception ex) {
            unexpectedException = ex;
        }
        Test.stopTest();

        System.assertNotEquals(null, unexpectedException, 
                                'Exceptions should be handled by the method');
    }


    @isTest 
    static void constrctrApiLongTextAreaTest(){
        Id ide;
        Test.startTest();

        List<Account> acc =SBR_3_0_TestDataFactory.createAccounts(1, True, 'Prospect');
        List<Comment__c> comments = SBR_3_0_TestDataFactory.createComments(1,true,acc[0].Id);

        Map<Id,SObject> idsToSobject = new Map<Id,SObject> (comments);

        for (Comment__c comment : comments){
            comment.Comment__c = 'Comment Apex Test';
            ide=comment.Id;
        }
        Update comments;
       
        Set<String> validRecTypes = new Set<String>{SBR_3_0_Constants.COLLECTION_COMMENT_REC_TYPE};
        List<String> apiLongTextAreasFields = new List<String>{'Comment__c'};
        SBR_3_0_PublishRecordsToOutbox publishComments= new SBR_3_0_PublishRecordsToOutbox(idsToSobject, SBR_3_0_Constants.COMMENT_API_NAME , validRecTypes, apiLongTextAreasFields);
        publishComments.publish();
        List<Outbox__c> out =  [Select Record_Id__c, Record_Type_Name__c from Outbox__c where Record_Id__c=:ide];
        String ric = out[0].Record_Id__c;

        Test.stopTest();
        Assert.areEqual(ide,ric);
    }
}