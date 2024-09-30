/*********************************************************************************************************************
* Apex Class: SBR_3_0_AssocLocationOperations_Test
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - SAL-1503
* - Test class for AssociatedLocationOperations class.
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME                      DATE                 DETAIL FEATURES
    1.0         Harry Rokad                        2022-04-11            Initial version   
    2.0         Konrad Haight                      2022-05-25            Added updateAddressTest 
*********************************************************************************************************************/


@isTest
public with sharing class SBR_3_0_AssocLocationOperations_Test {

    @isTest
    static void testpublishAssociatedLocations(){
        
      List<Account> acc =SBR_3_0_TestDataFactory.createAccounts(1, True, SBR_3_0_Constants.ACCOUNT_REC_TYPE_PROSPECT);
        Id accId;
        for (Account sob:acc){
            accId=sob.Id;
        }

        List<Schema.Location> loc = SBR_3_0_TestDataFactory.createLocations(1, True, SBR_3_0_Constants.LOCATION_REC_TYPE_JOB_LOC);
        Id locId;
        for (Schema.Location sob:loc){
            locId=sob.Id;
        }
        List<Schema.Location> branch = SBR_3_0_TestDataFactory.createLocations(1, True, SBR_3_0_Constants.LOCATION_REC_TYPE_BRANCH);
        Id branchId;
        for (Schema.Location sob:branch){
            branchId=sob.Id;
        }

        List<AssociatedLocation> assocLoc =SBR_3_0_TestDataFactory.createAssociatedLocations(1,accId, branchId, locId, True);
        Id assoLocId;
        for (AssociatedLocation sob:assocLoc){
            assoLocId=sob.Id;
        }
        
        Map<Id,AssociatedLocation> resMap = new Map<Id,AssociatedLocation>();
        for(AssociatedLocation aL:assocLoc){
        resMap.put(aL.Id,aL);
        }
        
        List<AssociatedLocation> newList = new List<AssociatedLocation>();
        for(AssociatedLocation aL:assocLoc){
        aL.Company_Code__c = '01';
        aL.CurrencyIsoCode = 'USD';
            newList.add(aL);
        }
        
        update newList;        
        Test.startTest();
        SBR_3_0_AssociatedLocationOperations.publishAssociatedLocations(resMap);
        Test.stopTest();
        Assert.isTrue([Select Record_Id__c from Outbox__c where Record_Id__c =: resMap.values()[0].Id].size() != 0);
      }
    
    @isTest
    static void validateNewJobSiteAddress(){
         List<Account> acc =SBR_3_0_TestDataFactory.createAccounts(1, True, SBR_3_0_Constants.ACCOUNT_REC_TYPE_PROSPECT);
        Id accId;
        Map<Id,Account> accMap = new Map<Id,Account>();
        for (Account sob:acc){
            accId=sob.Id;
            accMap.put(sob.Id,sob);
        }

        List<Schema.Location> loc = SBR_3_0_TestDataFactory.createLocations(1, True, SBR_3_0_Constants.LOCATION_REC_TYPE_JOB_LOC);
        Id locId;
        for (Schema.Location sob:loc){
            locId=sob.Id;
        }
        List<Schema.Location> branch = SBR_3_0_TestDataFactory.createLocations(1, True, SBR_3_0_Constants.LOCATION_REC_TYPE_BRANCH);
        Id branchId;
        Map<Id, Schema.Location> locMap = new Map<Id, Schema.Location>();
        for (Schema.Location sob:branch){
            branchId=sob.Id;
            locMap.put(sob.Id,sob);
        }
        
        List<AssociatedLocation> assocLoc = SBR_3_0_TestDataFactory.createAssociatedLocations(1,accId, branchId, locId, True);
        Id assoLocId;
        Map<Id,AssociatedLocation> associatedLocMap = new Map<Id,AssociatedLocation>();
        Map<Id,AssociatedLocation> associatedLocMap2 = new Map<Id,AssociatedLocation>();
        for (AssociatedLocation sob:assocLoc){
            sob.Latitude_Longitude__Latitude__s = 52.17080299;
            sob.Latitude_Longitude__Latitude__s = -106.653788;
            assoLocId=sob.Id;
            associatedLocMap.put(sob.Id,sob);
            sob.City__c = 'Test City1';
            associatedLocMap2.put(sob.Id,sob);
        }
        Credential__c cred = SBR_3_0_TestDataFactory.createCredentials(1, false)[0];
        cred.Name = 'Mule_Token_Endpoint';
        cred.Key_Id__c = 'keyid';
        cred.Secret__c ='credSecret';
        insert cred;
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_API_AccessToken_Test());
        SBR_3_0_HttpCallout httpCallout = new SBR_3_0_HttpCallout('Mule_Token_Endpoint');
        SBR_3_0_AssociatedLocationOperations.truncateJobNumber(assocLoc[0]);
        SBR_3_0_AssociatedLocationOperations.publishRelatedLocations(locMap);
        SBR_3_0_AssociatedLocationOperations.publishRelatedAccounts(accMap);
        SBR_3_0_AssociatedLocationOperations.validateNewJobSiteAddress(associatedLocMap);
        SBR_3_0_AssociatedLocationOperations.validateUpdateJobSiteAddress(associatedLocMap,associatedLocMap2);
         SBR_3_0_AssociatedLocationOperations.truncateLatLong(associatedLocMap2.values(), null);
        Test.stopTest();
        Assert.isTrue(assocLoc[0].Job_Number__c.length() <= 20);
        Assert.isTrue([Select Record_Id__c from Outbox__c where Record_Id__c =: locMap.values()[0].Id].size() != 0);
        Assert.isNotNull(associatedLocMap.values()[0].City__c);
    }
}